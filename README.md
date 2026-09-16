# Trixie

Forensic characterisation of the Agent-mode sandbox behind Code Arena / arena.ai.

Three independent sessions (one per browser profile), four rounds of probes, every archive hash-verified. Raw zips, original characterisation markdown, and original prompt files are **never** overwritten.

- Per-zip index: `forensic/reports/summary/INDEX_ALL.tsv`
- Outer SHA-256 inventory: `forensic/reports/summary/00_ROOT_INVENTORY.txt`
- Round-3 integrity report: `forensic/reports/round3/UNPACK_REPORT.md`
- Benchmark integrity + caveats: `forensic/reports/benchmarks/BENCH_REPORT.md`

---

## TL;DR

This repository characterises an **E2B microVM template**, thoroughly and reproducibly, at the level of kernel, cgroups, rlimits, filesystem and egress.

It does **not** establish anything about cross-session persistence, tool-call concurrency limits, or cross-account performance — and the platform branding is asserted by the operator, not measured by any probe.

Read §3 before quoting any number from this repo.

---

## 1. What this proves

All values below are **byte-identical across three independent sessions** unless marked otherwise.

### Runtime

```
OS                Debian GNU/Linux 13 (trixie), /etc/debian_version 13.6
Kernel            6.1.158+  #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026
Python            3.13.14
Hostname          e2b.local
```

### Isolation

KVM microVM with its own kernel and a real PID 1 — **not** a container, **not** bare metal. Established by exclusion, not assumption:

| Test | Result | Excludes |
|---|---|---|
| `systemd-detect-virt` | `kvm` | bare metal |
| `/proc/1/cgroup` | `0::/` with `system.slice`, no docker/lxc id | container |
| `/.dockerenv` | absent | container |
| `hypervisor` CPU flag | present | bare metal |
| kernel cmdline | `init=/sbin/init`, `root=/dev/vda`, virtio_mmio | — |

cgroup v2 limits live at **`/sys/fs/cgroup/user`**, not the cgroup root (the root has no `memory.max`).

### Resources

```
MemTotal                  2032608 kB   (1984.97 MiB / 1.938 GiB)
memory.max                1947172864 B (1856.97 MiB)
memory.swap.max           "max"  — but /proc/swaps is empty, so no swap exists
cpu.max                   "max 100000"  → no CPU quota (nr_throttled = 0)
pids.max                  "max"         → no PID cap
cpuset.cpus.effective     0-1
CPU topology              1 socket / 1 core / 2 threads, siblings "0-1"
RLIMIT_NOFILE             soft 1024, hard 524288
/tmp                      tmpfs, ~993 MiB (≈ MemTotal / 2)
/                         ext4 on /dev/vda
```

- **OOM is cgroup-scoped and the session survives it.** `memory.events:oom_kill` increments; subsequent commands still execute.
- **fd limits behave as documented POSIX.** A child can `setrlimit` soft → hard and open ~524 k fds; raising above hard fails with `ValueError: not allowed to raise maximum limit`. EMFILE lands at 1017–1018 with the default soft limit (the 1-fd spread is baseline descriptors).
- **`/tmp` is RAM, proven two ways:** `dd` hits ENOSPC at ~992 MiB, and `memory.current` rises by 1.0007× the bytes written, then falls back after `rm`.
- **SMT sibling adds ~0–1.4 % throughput.** `taskset -c 2` fails with EINVAL — there is only one physical core.

### Network

- **`connect()` is not evidence of reachability.** An accept-all gateway returns success for RFC 5737 TEST-NET addresses. Only TTFB / HTTP-status evidence is valid here. Corroborated on all three accounts.
  - `192.0.2.1` is genuinely local: `/etc/hosts` maps it to `events.e2b.local`, `E2B_EVENTS_ADDRESS` points at it, and it answers with an E2B JSON 404 in ~1.7 ms.
  - `198.51.100.1` / `203.0.113.1` accept the connection and then transfer **zero** bytes.
- **DNS is unfiltered.** `/etc/resolv.conf` → `nameserver 8.8.8.8`; every public hostname tested returned A and AAAA records.
- **IPv6 egress is blocked at `connect()`, not at the resolver** — AAAA records resolve fine, `curl -6` fails in ~10 ms while `curl -4` returns 200.
- **Cloud metadata is blocked:** `169.254.169.254` times out, `metadata.google.internal` is NXDOMAIN.
- **Public egress is otherwise open for the tested sets.** Origin-side 403s (reddit, crates.io) were separated from network-level blocks by User-Agent controls.

### Identity / provenance

```
E2B_TEMPLATE_ID / ENV_ID   nlhz8vlwyupq845jsdg9      constant, all sessions
BUILD_ID                   f34a5416-ef30-4cb7-8e18-0fdecd6eb529   constant
E2B_SANDBOX_ID             varies every session
boot_id                    2bb79165-136a-4b63-829d-17027b0a8e40   CONSTANT
```

The `boot_id` result is the sharpest finding in the archive. It is **identical across all three accounts, across round 2 and round 3, and across different days** while `sandbox_id` changes every session. A boot_id that survives distinct sessions is not a booted kernel — it is a **memory snapshot being restored**. Sessions are VM-forked from one template image, not cold-booted.

---

## 2. What this does **not** prove

| Claim you might expect here | Status |
|---|---|
| **Cross-session persistence** | **No evidence at all.** `zips/persistence/` and `forensic/evidence/persistence/` are skeleton-only. The round-3 "C1 liveness" probes show only that a session survived ~9 minutes and its own OOM kills. Nothing tests session boundaries, idle timeout, or reconnect. |
| **Tool-call concurrency cap** | **Not measured, and the accounts contradict each other.** See §3.1. |
| **Cross-account performance differences** | **Confounded.** numpy versions differ and one is unrecorded; units are mislabelled in one log; within-session spread is 2–5×, larger than most between-account deltas. `BENCH_REPORT.md` §5 documents this in full. |
| **That this is LMArena specifically** | **Operator-asserted, not measured.** No `ARENA_*` environment variable, no arena hostname, no arena-branded artefact exists anywhere in the evidence tree. Every occurrence of "arena.ai" is a free-text `surface:` field an agent typed into its own JSON. The machine-observable identity is *purely* E2B. |
| **Code Arena app sandbox vs Agent Mode** | Section E is `NOT PERFORMED` on every account, by the task's own scoping rule. The `code_arena/` evidence is scaffold snapshots only. |
| **A fixed "OOM ceiling"** | The ceiling is session-dependent, not a constant. See §3.2. |
| **Global egress policy** | Sample-bounded: 18 / 21 / ~45 hostnames, ports 22/53/80/443. Absence of a block in this sample is not absence of a blocklist. |

---

## 3. Known defects in this archive

Listed because they are load-bearing. Do not quote around them.

### 3.1 The D5 concurrency verdict is contradicted by its own raw data

`account_a`'s falsification ledger (F8) states *"no observed per-session parallelism; cap = 1 concurrent exec."* Rebuilding the timeline from its own `d5/A..H.txt` files:

| Account | sleep | dispatch gap | wall | serial prediction | **max simultaneous** |
|---|---|---|---|---|---|
| account_a (chrome) | 4 s | 2.00 s | 18.04 s | 32 s | **3** |
| account_b (brave) | 7 s | 0.47 s | 10.27 s | 56 s | **8** |
| account_c (edge) | 3 s | 1.20 s | 11.41 s | 24 s | **3** |

Chrome's calls overlap (A runs 0.000–4.012 s, B starts at 2.370 s) and its wall time is 18.04 s against a 32 s serial prediction. `account_b` concludes the opposite ("no cap at ≤ 8").

Neither is right in substance. All three used **different sleep durations**, so observed concurrency is simply `sleep ÷ dispatch_gap` — nobody saturated a ceiling, so **no account measured the cap.** The only genuinely measured quantity is the dispatch interval, and that varies 4× across sessions with no explanation.

Reproduce:

```bash
python3 - <<'PY'
import re, glob
from datetime import datetime
ev = []
for p in sorted(glob.glob("forensic/evidence/round3/account_a/probe3/d5/*.txt")):
    t = open(p).read()
    f = lambda x: datetime.strptime(x, "%Y-%m-%dT%H:%M:%S.%fZ")
    ev.append((f(re.search(r'start=(\S+)', t).group(1)),
               f(re.search(r'end=(\S+)',   t).group(1))))
pts = sorted([(s, 1) for s, _ in ev] + [(e, -1) for _, e in ev])
cur = mx = 0
for _, d in pts:
    cur += d; mx = max(mx, cur)
t0 = min(s for s, _ in ev)
print("max simultaneous:", mx,
      "| wall:", round((max(e for _, e in ev) - t0).total_seconds(), 3), "s",
      "| serial prediction: 32.0 s")
PY
```

### 3.2 OOM ceiling is reported as a constant but is baseline-dependent

| Account | baseline `memory.current` | last survive | first kill |
|---|---|---|---|
| account_a | 192 155 648 B | 1600 MiB | 1632 MiB |
| account_b | 80 023 552 B | 1632 MiB | 1664 MiB |
| account_c | 185 868 288 B | ~1624.85 MiB | ~1653.86 MiB |

`account_c` catches the reason — page cache counts against `memory.max`. Accounts a and b report their figure without that caveat.

**The stable constant is `memory.max = 1947172864`.** The ceiling is a derived, session-varying observation.

### 3.3 No cross-account round-3 synthesis exists

`forensic/reports/round3/` contains only `UNPACK_REPORT.md` — integrity and placement. The contradiction in §3.1 sits unreconciled in the evidence tree because nobody read the raw numbers back against the ledger.

### 3.4 Repo metadata lags the evidence

- Three round-3 zips are absent from `INDEX_ALL.tsv` (22 indexed vs 24 on disk).
- One `INDEX_ALL.tsv` row points at a file that is not committed.
- 10 files listed in `run9`'s manifest are absent from the committed tree.

---

## 4. Reliability by category

| Category | Rating | Basis |
|---|---|---|
| **Runtime** — OS, kernel, Python | **High** | Identical strings, 3/3 sessions, hash-verified, trivially re-checkable |
| **Isolation** — KVM, PID 1, cgroup path | **High** | Positive tests excluding both container and bare metal |
| **Resources** — limits | **High** | Byte-identical 3/3 |
| **Resources** — OOM ceiling | **Medium** | Real but session-dependent; see §3.2 |
| **Network** — method and findings | **Medium-High** | Controlled, with false-negative controls; sample-bounded |
| **Identity** — E2B template lineage | **High** | Constant IDs + constant boot_id across varying sandbox_ids |
| **Identity** — platform attribution | **Low** | Agent-asserted, zero machine grounding |
| **Concurrency** | **Low** | Internally contradictory, cap never saturated |
| **Persistence** | **None** | Category is empty |
| **Benchmarks** — as cross-account comparison | **Low** | Confounded; the report says so itself |
| **Benchmarks** — as single-session snapshots | **Medium** | Single run each, no repeats |

---

## 5. Reproducibility

### Fully reproducible — verification

Every hash, manifest and hash-of-hashes recomputes from this repository alone.

```bash
# outer zip hashes vs the index
awk -F'\t' 'NR>1 {print $NF"  "$1}' forensic/reports/summary/INDEX_ALL.tsv | sha256sum -c -

# round-3 archive integrity
for z in zips/round3/*.zip; do unzip -t "$z" >/dev/null && sha256sum "$z"; done

# per-file manifest check inside an extracted tree
cd forensic/evidence/round3/account_b/probe3 && sha256sum -c manifest3.txt --quiet
```

**Manifest dialect warning.** The three round-3 trees use three incompatible formats. Chrome is 4-column (`sha256  bytes  write_time  path`) with hash-of-hashes over **digests only**; brave and edge are `sha256sum` lines with hash-of-hashes over the **full lines**. In both brave and edge the word *"sorted"* in the footer means **name-sorted, not hash-sorted** — sorting lexicographically by hash yields a different, non-matching digest. Edge's `SELF-SHA256` is the hash of the file *with that line removed*. None of these are failures; all are documented in `forensic/reports/round3/UNPACK_REPORT.md`.

### Partially reproducible — re-measurement

Round 3 ships its probe sources, so these can be re-run inside an equivalent sandbox:

| Probe | Script |
|---|---|
| OOM bisect | `round3/account_a/probe3/d1_oom_bisect.py`, `account_b/probe3/scripts/oom_probe.py`, `account_c/probe3/src/oombisect.py` |
| fd ceiling | `account_a/probe3/d4_fd.py`, `account_c/probe3/src/fdtest.py` |
| SMT penalty | `account_c/probe3/src/smt.py`, `account_b/probe3/scripts/burn.py` |
| Manifest generation | `account_a/probe3/make_manifest.sh` (only tree that ships its own generator) |

### Not reproducible

- **The D5 concurrency test** — no shared script, three different sleep values. This is the direct cause of §3.1.
- **The benchmarks** — no scripts ship at all. Defended in `BENCH_REPORT.md` §5.6 on the grounds that the originating prompt deletes created files; defensible, but it means those numbers cannot be repeated by an outsider.
- **Anything requiring the sandbox itself** — re-running needs access to the same surface, which this repository cannot grant.

---

## 6. Layout

```
zips/
  environment/account_{a,b,c}/   9 zips   Agent 1-9, round 1 followup
  provenance/account_{a,b,c}/    3 zips
  ceilings/account_{a,b,c}/      3 zips
  egress/account_{a,b,c}/        3 zips
  code_arena/account_{a,b,c}/    3 zips
  round3/                        3 zips   falsification probes
  benchmarks/ persistence/       empty

forensic/
  evidence/
    environment/account_{a,b,c}/runN/
    provenance/ ceilings/ egress/ code_arena/ round3/account_{a,b,c}/
    benchmarks/account_{a,b,c}/          3 run logs, txt not zip
    persistence/                         EMPTY — see §2
  reports/
    round1_environment/                  unpack + crosscheck
    round2_ceilings_provenance_egress/
    round2_code_arena/
    round3/UNPACK_REPORT.md              integrity + placement only
    benchmarks/BENCH_REPORT.md           integrity + confound analysis
    summary/                             inventory, INDEX_ALL.tsv, ID comparison

characterizations/environment/           original round-1 narrative *.md
prompts/round{1,2,3}/                    instruction sets, unmodified
```

### Account mapping

Browser string in filenames is ground truth; `account_*` labels are aliases.

| account | browser | env run numbers |
|---|---|---|
| account_a | chrome | 1, 4, 5 |
| account_b | brave | 2, 3, 6 |
| account_c | edge | 7, 8, 9 |

---

## 7. Method

Collection and verification are performed by **separate agents**. The verifier's scope is `sha256sum` + `unzip -t` + `git mv`, and it explicitly does not execute payloads or analyse content. Every round-3 claim carries a **falsifying command** — the command that would have produced different output had the claim been false — and a grade of `MEASURED` or `NOT PERFORMED`.

Where earlier rounds were wrong, the retraction is in the record rather than edited away. Chrome's F13 retracts an earlier `1.894 GiB` figure and demonstrates it is unreproducible from `MemTotal` under any convention.

---

## 8. Safety

- Do **not** execute `.sh`, `.py`, `.c`, or binaries found inside zips or extract trees without review.
- No archive contains path traversal, absolute paths, symlinks, or nested zips. `unzip -t` clean on all 24.
- `code_arena` `drizzle.config.json` has `DATABASE_URL` redacted to scheme + host only. Per-account scrub records: `forensic/evidence/code_arena/account_*/SCRUB_REPORT.md`.
- Quarantine: none.

---

## 9. Open work

1. A genuine **cross-session persistence** round — the only wholly empty category.
2. A **D5 re-run** with one shared script and a sleep long enough to actually saturate the dispatcher, so the concurrency cap is measured rather than inferred.
3. A **cross-account round-3 synthesis** report, which would have caught §3.1.
4. Benchmark re-runs that print `numpy.__version__` and record byte counts alongside rates.
