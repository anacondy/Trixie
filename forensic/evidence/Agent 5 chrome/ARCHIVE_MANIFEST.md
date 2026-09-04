# Agent 5 chrome.zip — Archive Manifest & Provenance Record

**Archive name:** `Agent 5 chrome.zip`
**Assembled:** 2026-09-04 14:04:16 UTC (2026-09-04 19:34:16 IST)
**Subject:** Environment characterization of an E2B Firecracker microVM
**Assembled by:** Arena.ai Agent Mode

---

## 1. What this archive is

A complete, self-verifying evidence package from a three-phase environment
characterization exercise. It contains:

- **2 analysis documents** (the report, and an errata correcting it)
- **3 executable tools** (probe script, benchmark module, diff tool)
- **32 raw verbatim command transcripts** across 2 independent probe runs
- **4 integrity manifests** (SHA-256 per run + for the tool kit)
- **This provenance record**

The defining feature of this package is that **it corrects itself.** Phase 2 re-ran
Phase 1's claims as an archived script and **falsified two of them**. Both the original
report and the correction are included, so the reasoning chain is auditable end to end.

---

## 2. Directory tree

```
Agent 5 chrome.zip
├── ARCHIVE_MANIFEST.md                  ← you are here
├── environment_characterization.md      ← main report (corrected, banner-flagged)
│
├── env-probe/                           ← reproducible probe kit
│   ├── README.md                        ← kit usage + methodology notes
│   ├── ERRATA.md                        ← corrections to the main report
│   ├── env_probe.sh                     ← THE probe script (v1.1.1)
│   ├── bench_cpu.py                     ← CPU/numpy/pandas benchmarks
│   ├── diff_runs.sh                     ← run-to-run comparison tool
│   ├── KIT_SHA256SUMS.txt               ← checksums for the 5 files above
│   │
│   └── runs/
│       ├── 20260904T134652Z_i80n46q8w7lm0xch991wu/   ← Run 2a (probe v1.1.0)
│       │   ├── 01_runtime.txt … 16_env_config.txt    ← 16 raw transcripts
│       │   ├── MANIFEST.json                         ← run metadata + SHA-256
│       │   └── SHA256SUMS.txt                        ← sha256sum -c format
│       │
│       └── 20260904T134940Z_i80n46q8w7lm0xch991wu/   ← Run 2b (probe v1.1.1)
│           ├── 01_runtime.txt … 16_env_config.txt
│           ├── MANIFEST.json
│           └── SHA256SUMS.txt
│
└── envcheck/                            ← Phase-1 scratch artifacts (superseded)
    ├── cpubench.py                      ← original ad-hoc benchmark
    ├── hello.c / hello                  ← OpenMP compile test + binary
    ├── t.cpp / tcpp                     ← C++17 compile test + binary
    └── pypkgs_tail.txt                  ← tail of 180 preinstalled Python pkgs
```

---

## 3. What every file does

### 3.1 Top level

| File | Purpose |
|---|---|
| `ARCHIVE_MANIFEST.md` | This document: contents, provenance, timeline, prompts, metadata. |
| `environment_characterization.md` | **Main deliverable.** ~37 KB report: exec summary, 7 sections (runtime/isolation, tooling, filesystem, network, benchmarks, observations, verdict), tables for tool availability, network latency/throughput, benchmark timings, plus methodology and reproduction appendices. Carries a **superseded-in-part banner** pointing at `ERRATA.md`. |

### 3.2 `env-probe/` — the reproducible kit

| File | Purpose |
|---|---|
| `README.md` | Kit documentation: usage (`QUICK=1`/`FULL=1`), section index, 5 methodology notes explaining *why* naive measurements mislead here, known side effects, diff-interpretation guidance. |
| `ERRATA.md` | **Read alongside the report.** Documents 2 falsified claims (ICMP, npm audit), 1 resolved open question (persistence), 2 new findings (unstable egress IP, non-unique boot_id), and a revised hard-limitations list. |
| `env_probe.sh` | **The probe.** 28 KB bash. 16 sections, verbatim `$ cmd` → output → `[exit=N]` transcripts. Emits `MANIFEST.json` + `SHA256SUMS.txt`. Always exits 0 — probe failures are data. |
| `bench_cpu.py` | Benchmark module invoked by section 11. `perf_counter()`, best-of-N, reports GFLOP/s for matmul and M-iter/s for parallel scaling. |
| `diff_runs.sh` | Compares two runs: SHA-256 integrity, host-identity table (flags differing fields with `**`), per-section diff with changed-line counts. Auto-selects two most recent runs. |
| `KIT_SHA256SUMS.txt` | SHA-256 of the 5 files above. Verify: `sha256sum -c KIT_SHA256SUMS.txt` |

### 3.3 `env-probe/runs/*/` — raw evidence (16 transcripts per run)

| File | Captures |
|---|---|
| `01_runtime.txt` | uname, os-release, libc, arch, boot_id, kernel cmdline, uptime |
| `02_isolation.txt` | virt detection, cgroups, capabilities, seccomp, namespaces, dmesg, LSM |
| `03_identity_limits.txt` | uid/gid, sudo test, all ulimits, cgroup v2 limit files, overcommit, thread/pid max |
| `04_tooling.txt` | 70-tool availability matrix + version strings |
| `05_python_env.txt` | interpreter paths, **full 180-package list**, key-import probe, BLAS thread config |
| `06_filesystem.txt` | mounts, findmnt, df -hT, df -i, write/read/delete matrix across 9 paths, ro mounts |
| `07_dns.txt` | resolv.conf, hosts, routes, cold/warm resolution timing ×9 hosts |
| `08_net_latency.txt` | curl phase breakdown best-of-5 ×8 endpoints, **est_rtt**, HTTP version, TLS cert chain |
| `09_net_matrix.txt` | throughput ×5 targets; egress port matrix via **4 methods** (naive connect / real handshake / portquiz / UDP); IPv6; egress IP |
| `10_net_anomalies.txt` | ICMP (unprivileged + sudo), npm audit endpoints, POST/PUT control group |
| `11_bench_cpu.txt` | pure-Python, numpy (GFLOP/s), pandas, multiprocessing scaling 1/2/4 workers |
| `12_bench_disk.txt` | dd sequential (fdatasync + O_DIRECT), cold/warm reads ×3 filesystems, 2 GiB headroom, metadata ops |
| `13_bench_install.txt` | timed: pip pure/wheel/sdist-compile, gcc+OpenMP, g++, apt, npm, git clone |
| `14_memory_oom.txt` | allocation ceiling with page-touching, SIGKILL detection, dmesg OOM records |
| `15_processes.txt` | ps, systemd services, listening sockets, detached job, server bind test, throttling windows |
| `16_env_config.txt` | env vars, platform config, `/etc/ssl/certs` mount, persistence marker read/write |
| `MANIFEST.json` | **Verification manifest:** run_utc, sandbox_id, template_id, boot_id, hostname, uptime, kernel, os, arch, libc, nproc, mem_total_kb, egress_ip, mode, + `{name, sha256, bytes, lines}` per file |
| `SHA256SUMS.txt` | `sha256sum -c` compatible checksum list |

### 3.4 `envcheck/` — Phase-1 scratch (superseded, kept for completeness)

| File | Purpose |
|---|---|
| `cpubench.py` | Original ad-hoc benchmark. Superseded by `env-probe/bench_cpu.py`. |
| `hello.c` / `hello` | OpenMP reduction test (1e8 iters) + compiled binary. Proved `gcc -fopenmp` works and sees 2 threads. |
| `t.cpp` / `tcpp` | C++17 vector+sort test + compiled binary. |
| `pypkgs_tail.txt` | Last 100 of the 180 preinstalled Python distributions. |

> ⚠️ `hello` and `tcpp` are **compiled x86-64 ELF binaries**, not source. They will not run on ARM.

---

## 4. Creation timeline (exact, in sequence)

All times **UTC**. Your local timezone is Asia/Calcutta (UTC+5:30).

### ⚠️ Critical caveat on timestamps

**Phase-1 file mtimes are NOT their creation times.** Between Phase 1 and Phase 2 the
sandbox was torn down and `/home/user` was **restored from a snapshot into a fresh VM**,
which rewrote every mtime to the restore instant (13:43:53). This is itself a documented
finding (`ERRATA.md` §RESOLVED). Below, Phase-1 times are **reconstructed from the session
transcript** and marked *(recon)*; Phase-2/3 times are **filesystem-observed** and exact.

### PHASE 1 — Prompt 1 · sandbox `iyl5sbten1irtm0cfue4p`

| # | Time (UTC) | Event / file |
|---|---|---|
| 1 | 11:10:40 | Session start. VM cold-booted (uptime 17.6 s at first probe). |
| 2 | ~11:11 *(recon)* | `envcheck/pypkgs_tail.txt` — Python package inventory |
| 3 | ~11:22 *(recon)* | `envcheck/hello.c` + `hello` — OpenMP compile test |
| 4 | ~11:22 *(recon)* | `envcheck/t.cpp` + `tcpp` — C++17 compile test |
| 5 | ~11:33 *(recon)* | `envcheck/cpubench.py` — ad-hoc benchmark suite |
| 6 | 11:40:29 | `PERSISTENCE_MARKER.txt` (v1) — boot_id `2bb79165-…` |
| 7 | ~11:41 *(recon)* | **`environment_characterization.md` v1** — initial report |

### ⏸ GAP — sandbox teardown & snapshot restore

| # | Time (UTC) | Event |
|---|---|---|
| 8 | 13:43:53 | `/home/user` restored into **new sandbox `i80n46q8w7lm0xch991wu`**. All Phase-1 mtimes rewritten. `/tmp` marker lost. Uptime 11.7 s. |

### PHASE 2 — Prompt 2 · sandbox `i80n46q8w7lm0xch991wu`

| # | Time (UTC) | Event / file |
|---|---|---|
| 9 | ~13:46:40 | `env-probe/env_probe.sh` **v1.1.0** created |
| 10 | 13:46:47 | `env-probe/bench_cpu.py` created |
| 11 | 13:46:52 → 13:49:04 | **RUN 2a executes** (132 s) — 16 transcripts + manifest + checksums |
| | 13:46:52.705 | ↳ `01_runtime.txt` |
| | 13:46:52.765 | ↳ `02_isolation.txt` |
| | 13:46:52.821 | ↳ `03_identity_limits.txt` |
| | 13:46:53.881 | ↳ `04_tooling.txt` |
| | 13:47:00.873 | ↳ `05_python_env.txt` |
| | 13:47:00.925 | ↳ `06_filesystem.txt` |
| | 13:47:01.057 | ↳ `07_dns.txt` |
| | 13:47:04.541 | ↳ `08_net_latency.txt` |
| | 13:47:29.449 | ↳ `09_net_matrix.txt` |
| | 13:47:33.133 | ↳ `10_net_anomalies.txt` |
| | 13:47:43.313 | ↳ `11_bench_cpu.txt` |
| | 13:47:51.425 | ↳ `12_bench_disk.txt` |
| | 13:48:24.529 | ↳ `13_bench_install.txt` |
| | 13:48:28.033 | ↳ `14_memory_oom.txt` |
| | 13:49:04.265 | ↳ `15_processes.txt` |
| | 13:49:04.313 | ↳ `16_env_config.txt` |
| | 13:49:04.601 | ↳ `MANIFEST.json` + `SHA256SUMS.txt` |
| 12 | 13:49:34 | `env_probe.sh` **patched → v1.1.1** (fixed `getcwd` bug corrupting manifest `libc` field; wrapped `cd` in subshells) |
| 13 | 13:49:40 → 13:51:33 | **RUN 2b executes** (113 s) — 16 transcripts + manifest + checksums |
| | 13:49:40.345 | ↳ `01_runtime.txt` |
| | 13:49:40.389 | ↳ `02_isolation.txt` |
| | 13:49:40.441 | ↳ `03_identity_limits.txt` |
| | 13:49:41.777 | ↳ `04_tooling.txt` |
| | 13:49:48.769 | ↳ `05_python_env.txt` |
| | 13:49:48.813 | ↳ `06_filesystem.txt` |
| | 13:49:48.961 | ↳ `07_dns.txt` |
| | 13:49:52.661 | ↳ `08_net_latency.txt` |
| | 13:50:17.169 | ↳ `09_net_matrix.txt` |
| | 13:50:20.829 | ↳ `10_net_anomalies.txt` |
| | 13:50:29.193 | ↳ `11_bench_cpu.txt` |
| | 13:50:32.933 | ↳ `12_bench_disk.txt` |
| | 13:50:53.361 | ↳ `13_bench_install.txt` |
| | 13:50:56.985 | ↳ `14_memory_oom.txt` |
| | 13:51:33.121 | ↳ `15_processes.txt` |
| | 13:51:33.161 | ↳ `16_env_config.txt` |
| | 13:51:33.469 | ↳ `MANIFEST.json` + `SHA256SUMS.txt` |
| 14 | 13:51:33 | `PERSISTENCE_MARKER.txt` overwritten (v2) by run 2b |
| 15 | 13:52:35 | `env-probe/diff_runs.sh` created |
| 16 | 13:53:15 | `env-probe/README.md` created |
| 17 | 13:54:10 | `env-probe/ERRATA.md` created |
| 18 | 13:55:51 | **`environment_characterization.md` patched** — banner + corrected §3.4, §4.5 ×2, §7, Appendix B |
| 19 | 13:56:00 | `env-probe/KIT_SHA256SUMS.txt` created |

### PHASE 3 — Prompt 3 (this request)

| # | Time (UTC) | Event / file |
|---|---|---|
| 20 | ~13:58 | `ARCHIVE_MANIFEST.md` created (this file) |
| 21 | 14:04:16 | `Agent 5 chrome.zip` assembled |

---

## 5. The exact prompts

> **Transport note:** your messages arrived containing HTML-encoded artifacts —
> `&amp;amp;` for `&`, and auto-linkified bare domains such as
> `[[google.com](http://google.com)]([http://google.com](http://google.com))`.
> These were encoding/linkification artifacts, not intentional. Reproduced below with
> those artifacts normalised for readability; structure, wording and ordering are unchanged.

### Prompt 1 — 2026-09-04, ~11:10 UTC (~16:40 IST)

```
I'm setting up a long-running research + data pipeline that will involve mixed CPU work,
network I/O, package installs, and some file processing. Before I commit any real code or
data, I need a clear picture of what this environment can actually sustain.

Please treat this as serious environment characterization work. Do the following thoroughly
and keep notes as you go (you can use temporary files or just track things in memory, but
be systematic).

Required checks

**1. Runtime & Isolation**
- Exact OS, kernel version, architecture, libc
- Clear signals of containerization / VM / restricted sandbox (cgroup, /.dockerenv,
  mount info, process tree, capabilities, seccomp, etc.)
- Current user, uid/gid, sudo/root status
- Any obvious resource limits (ulimit, cgroup memory/cpu, process limits)

**2. Tooling & Language Runtimes**
- Availability + versions of: python3, pip, node, npm, git, curl, wget, ffmpeg, docker,
  make, gcc/clang, jq, etc.
- Which package managers work (apt, apk, yum, pip, conda, npm…) and whether they can
  actually install things
- Can you install pure-python packages? System packages? Compile anything?

**3. Filesystem & Persistence**
- Working directory, home, /tmp behavior
- Free disk space and inode situation
- Read-only mounts or protected paths
- Simple write + read + delete test in a few locations
- Whether files survive across "sessions" if possible to test

**4. Network Characterization (important)**
Run real measurements, not just "can I connect":
- DNS resolution speed
- Latency + rough throughput to several endpoints (at minimum):
  - google.com / 8.8.8.8
  - github.com
  - pypi.org
  - huggingface.co
  - A large file download (e.g. a few MB from a reliable CDN or GitHub release)
- Note any timeouts, blocks, captive portals, or asymmetric performance
- Outbound ports / protocols that appear restricted

**5. Performance Micro-benchmarks**
Keep them short but timed accurately:
- Pure Python CPU: sum(range(10**7)) and a slightly heavier loop or numpy if available
- Disk sequential write + read of a 50–100 MB file
- Small package install time (if pip works)
- Any other operation that feels unusually fast or slow

**6. Other observations**
- Memory pressure behavior
- Ability to run background processes or long-running tasks
- Anything that breaks, hangs, or is surprisingly restricted
- Any environment variables or injected configuration that looks sandbox-related

Deliverable

After finishing the checks, create a clean, well-structured Markdown file named something
like environment_characterization.md that contains:
- Executive summary (2–4 sentences)
- Detailed sections matching the categories above
- Tables for:
  - Tool availability + versions
  - Network latency / throughput results
  - Benchmark timings
- Raw notes or command outputs in collapsible sections or clearly marked appendix if useful
- Clear statements of what is fast, what is slow, and hard limitations

Be precise with numbers (include units and how you measured). Prefer real measured data
over guesses.

Start whenever you're ready and produce the final Markdown report when done.
```

*(The filename in the original arrived garbled by linkification as
`environment_[characterization5 chrome.md](http://characterization.md)`. I interpreted the
intent as `environment_characterization.md`.)*

### Prompt 2 — 2026-09-04, ~13:43 UTC (~19:13 IST)

```
1. **Publish the raw** `.txt` **outputs, not just the reports.** (IF U PRODUCED THEM
   ALREADY, IF NOT , THEN SEE IF THEY ARE NEEDED & PRODUCE THEM ) Your file 6 references
   `01_runtime.txt`, `09_net_matrix.txt` etc. Verbatim transcripts with no LLM
   summarisation layer are the primary evidence.
2. **Ship the probe script** so a third party runs *your* script and diffs the output.
3. **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of
   raw files.
```

*(Note: there was no "file 6," and I had not produced those `.txt` files. My Phase-1 report
cited only `cpubench.py`, `hello.c`, `t.cpp`, and `pypkgs_tail.txt`. This was flagged and
corrected at the top of my Phase-2 response.)*

### Prompt 3 — 2026-09-04, ~13:57 UTC (~19:27 IST)

```
now zip all of these files ? & save the zip as Agent 5 chrome.zip , with all the files u
have created , explaining, what the zip has, & what every file does, & when it was created
, exact time & date & in sequence, which file was created when & also with the exact
prompts i gave u , each time, & any imp metadata, that can be helpful
```

---

## 6. Important metadata

### 6.1 Host identity

| Field | Phase 1 | Phase 2 / 3 |
|---|---|---|
| **Sandbox ID** | `iyl5sbten1irtm0cfue4p` | `i80n46q8w7lm0xch991wu` |
| **Template ID** | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` (same) |
| **boot_id** | `2bb79165-136a-4b63-829d-17027b0a8e40` | `2bb79165-…` ⚠️ **identical — not unique** |
| **Egress IP** | `34.169.124.137` | `34.127.25.150` ⚠️ **not stable** |
| Hostname | `e2b.local` | `e2b.local` |
| OS | Debian GNU/Linux 13 (trixie), 13.6 | same |
| Kernel | `6.1.158+` SMP PREEMPT_DYNAMIC | same |
| Arch / libc | x86_64 / glibc 2.41-12+deb13u3 | same |
| CPU | 2 vCPU, Intel Xeon @ 2.60 GHz (Ice Lake-SP, family 6 model 106) | same |
| RAM | 2,032,608 kB (~1.94 GiB), **no swap** | same |
| Disk | 25 GB ext4 on `/dev/vda`, ~20 GB free | same |
| Virtualization | Firecracker microVM under KVM | same |
| Session timezone | UTC (user local: Asia/Calcutta, UTC+5:30) | same |

### 6.2 Headline technical findings

| Finding | Value |
|---|---|
| 🔴 **Hard memory ceiling** | 1500 MB OK → **1800 MB SIGKILL**. No swap. Reproduced identically in both runs. |
| 🔴 `/tmp` is **RAM-backed tmpfs** | 993 MB, competes with the same 2 GB budget |
| ✅ Privileges | Passwordless root; full `CapBnd` `000001ffffffffff`; **`Seccomp: 0`** |
| ✅ Persistence | `/home/user` **survives** across sessions & sandbox IDs; `/tmp` does not; **mtimes rewritten on restore** |
| ✅ Egress | Unrestricted — all tested ports 22→65000 reachable; UDP works; no TLS interception |
| ❌ No IPv6, no Docker/Podman | — |
| ⚡ Peak disk write | 945 MB/s (2 GiB, fdatasync) |
| ⚡ Peak download | ~114 MB/s (Cloudflare 50 MB) |
| 🐢 HuggingFace | ~15 MB/s — **7× slower** than PyPI |
| ⚡ numpy matmul | ~125 GFLOP/s (2000², OpenBLAS 2 threads, AVX-512) |
| 🐢 `pandas.to_csv` | 1.83 s / 10⁶ rows — **10× slower** than `read_csv` |
| ✅ Parallel scaling | 2.17× at 2 workers; **no gain at 4** |

### 6.3 Claims falsified between runs (full detail in `ERRATA.md`)

| Phase-1 claim | Phase-2 result | Verdict |
|---|---|---|
| "ICMP is completely blocked" | `sudo ping github.com` = **11.25 ms** | ❌ **WRONG** — local perms only (`ping` not setuid + `ping_group_range="1 0"`) |
| "npm audit black-holed, 420 s" | Same endpoint **HTTP 200 in 0.057 s**; `npm install` default **0.986 s** | ⚠️ **TRANSIENT**, not structural (427× swing) |
| "Persistence untestable" | Marker read back under new sandbox ID | ✅ **RESOLVED** — home persists |

### 6.4 Environment mutations caused by this work

The image is **no longer pristine**:

- `cmake` 3.31.6 and `sqlite3` 3.46.1 installed via apt (**left in place**)
- `tabulate`, `duckdb`, `polars`, `ujson` installed+uninstalled by each probe run
- `apt-get update` run; `jq` reinstalled
- Deliberate OOM kills recorded in `dmesg` (3 events)
- `PERSISTENCE_MARKER.txt` overwritten twice

### 6.5 Verifying this archive

```bash
unzip "Agent 5 chrome.zip"
cd env-probe && sha256sum -c KIT_SHA256SUMS.txt          # tool integrity
cd runs/20260904T134940Z_i80n46q8w7lm0xch991wu
sha256sum -c SHA256SUMS.txt                              # raw evidence integrity
```

Reproduce independently and compare:

```bash
cd env-probe && ./env_probe.sh && ./diff_runs.sh
```

> When re-running, expect **most sections to show as CHANGED** — benchmark digits never
> repeat. Only `04_tooling.txt` is typically byte-identical. Compare **structural** facts
> (tool presence, mount layout, capability sets, HTTP status codes, OOM thresholds), not
> timing digits.

### 6.6 Known limitations of this evidence

1. **n=2 runs, one host, ~5 minutes apart.** The npm case proves this is a weak sample for
   network claims.
2. **Phase-1 raw output was never archived** — it exists only in the conversation
   transcript. Only Phase 2 onward has checksummed evidence. Where the two disagree,
   **Phase 2 is authoritative.**
3. **Phase-1 file mtimes are restore times**, not creation times (§4).
4. **No cross-teardown persistence test.** Home survived a session change; survival across
   explicit sandbox deletion is untested.
5. **Benchmarks ran on a shared-tenancy cloud host.** ±5% jitter observed even with no
   throttling.
