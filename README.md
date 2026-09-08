# Trixie — an empirical characterization of Arena.ai's sandboxes

Hash-verified artefacts from live **Arena Agent Mode** sessions, plus a cross-surface look at **Code Arena**.

Every number below is something you can open a file and see. Claims without a file in *this* repository are listed as **not in this repo**, not as findings.

> Independent research. Not affiliated with or endorsed by Arena / LMArena.

[Wiki](https://github.com/anacondy/Trixie/wiki) (the story) · [Apache-2.0](LICENSE)

---

## How to read this repo

| Rule | Meaning |
|------|---------|
| Browser string in filenames is ground truth | `chrome` / `brave` / `edge` in the name wins. `account_a/b/c` are aliases — see [`ACCOUNTS.md`](ACCOUNTS.md) (a = chrome, b = brave, c = edge). |
| Raw beats prose | Prefer redirected `.txt` and JSON over agent `.md`. Agent reports are commentary. |
| Disagreement is data | When three sessions disagree, that is the finding. Do not average it away. |
| History only moves forward | Append-only [`CHANGELOG.md`](CHANGELOG.md). No force-push. |
| Do not execute archives | Unpack and hash. Do not run extracted `.py` / `.sh`. |

---

## What is actually in the tree

| Path | Role | Status |
|------|------|--------|
| `zips/environment/` | Round-1 followup Agent zips (9) | present |
| `zips/ceilings/` `zips/egress/` `zips/provenance/` `zips/code_arena/` | Round-2 archives (3 each) | present |
| `zips/round3/` | Calibrated probe zips (3) | present |
| `zips/persistence/` `zips/benchmarks/` | reserved | **empty** (`.gitkeep` only) |
| `forensic/evidence/` | unpacked raws | **~843 files** |
| `forensic/evidence/benchmarks/` | F-run texts ×3 | present |
| `forensic/evidence/persistence/` | — | **empty** |
| `forensic/evidence/github_connect/` | — | **absent** |
| `characterizations/environment/` | round-1 agent reports (9) | present |
| `characterizations/{ceilings,egress,provenance,code_arena,benchmarks,persistence}/` | — | **empty** |
| `prompts/` | instruments, verbatim | round-1/2 present; round-3 falsification prompt present |
| `forensic/reports/` | unpack / verify / index | present (some indexes stale — see below) |
| `docs/wiki_home.md` | wiki Home seed | present |

---

## What the files show

### Agent Mode guest (class T)

Repeated across round-1 environment raws, provenance probes, round-3 A0 locks, and F-benchmark headers.

| Item | Value |
|------|--------|
| Distro | Debian 13 (trixie) |
| Kernel | `6.1.158+`, stamp `#1 … Fri Jul 17 14:31:34 UTC 2026` |
| Python | 3.13.14 |
| CPU | 2 vCPU, `Intel(R) Xeon(R) Processor @ 2.60GHz`, SMT siblings `0-1` (one physical core) |
| Memory | `MemTotal 2032608 kB` · cgroup `/user` `memory.max = 1947172864` · no swap |
| Disk | `/dev/root` ~25 G ext4 · `/tmp` tmpfs ~993 MiB (charges RAM) |
| Host | `e2b.local` · `E2B_SANDBOX=true` |
| Template / build | `nlhz8vlwyupq845jsdg9` / `f34a5416-ef30-4cb7-8e18-0fdecd6eb529` |

**Virt:** KVM guest, not Docker. `systemd-detect-virt=kvm`, no `/.dockerenv`, PID 1 is systemd, ACPI OEM `FIRECK`, kernel cmdline `pci=off virtio_mmio…`.

**Privilege:** `uid=1000` in group `sudo`. `sudo -n true` → root. User `Seccomp: 0`. User `CapEff` is **empty**; the bounding set / PID 1 is capable. Do not read that as “the user process has all capabilities”.

Evidence: `forensic/evidence/environment/`, `forensic/evidence/provenance/`, `forensic/evidence/round3/`.

### Identity (what changes, what does not)

| Signal | Behaviour |
|--------|-----------|
| `E2B_SANDBOX_ID` | new per session — this is the instance id |
| `boot_id` `2bb79165-136a-4b63-829d-17027b0a8e40` | **same** across accounts and sessions — image-constant, not a reboot detector |
| `/proc/uptime` at first command | often tens of seconds — fresh guest clock, not a long-lived VM you SSH into |
| In-guest services | timestamps from **2026-07-23** in September sessions — snapshot-resume of a long-lived image |

Agent 4 also recorded template `gujonb0q163l15z30yc7` next to the usual id (recorded quirk, not the lock).

Evidence: `prov_probe.txt`, round-1 ID comparison, round-3 A0 files.

### Ceilings — quote as ranges

Limits that **agree** across sessions:

| Resource | Measured |
|----------|----------|
| FDs | soft **1024** (EMFILE ~1018) · hard **524288** (child can raise to hard; not above) |
| Processes | `ulimit -u` **7917** · cgroup `pids.max = max` (unenforced) |
| CPU quota | `cpu.max = max 100000` · `nr_throttled = 0` |
| SMT | cpu0/cpu1 are siblings of **one** core |

OOM of a touched anonymous allocation **moves by session**. Do not quote one interval as *the* ceiling:

| Session | Last success | First kill |
|---------|--------------|------------|
| Round-3 chrome | 1600 MiB | 1632 MiB |
| Round-3 brave | 1632 MiB | 1664 MiB |
| Round-3 edge | 1624.85 MiB | 1653.86 MiB |
| Ceilings chrome (TSV) | 1632 MiB | 1664 MiB |
| Ceilings edge (markdown only) | 1637 MiB | 1638 MiB |

The child takes SIGKILL; the **session survives**. Account_c ceilings markdown argues host-global OOM rather than cgroup-max — left standing, not resolved.

Evidence: `forensic/evidence/ceilings/`, round-3 D1 files. Fork-to-7917 is well attested as an ulimit; the exact “7914 EAGAIN” figure is weaker (empty brave `fork_test.log`; edge ceilings is markdown without a probe log tree).

### Network

**Solid:**

- HTTPS to ordinary sites works (real HTTP codes, real TTFB).
- `connect()` to RFC5737 TEST-NET (`192.0.2.1`, `198.51.100.1`, `203.0.113.1`) succeeds in milliseconds. `curl` to the same addresses times out **or** hits a local JSON `404` in ~2 ms. **TCP connect is not reachability here.**
- Checked certificate leaves are public CAs (pypi.org → GlobalSign, github.com → Sectigo). System store verifies.
- Round-3 chrome: IPv6 `curl -6` fails; IPv4 to the same name works; DNS still returned AAAA.

**Nuance:** an `E2B Proxy CA` file exists on the guest. It was **not** the issuer of those checked leaves. “No MITM” means “not on the hosts we opened”, not “no proxy CA exists”.

**Unresolved:** round-2 egress write-ups talk about DNS-level blocks; round-3 chrome reports no public DNS blocklist (metadata endpoints only). Both are in the tree. Neither is promoted to a platform law.

Evidence: `forensic/evidence/egress/`, round-3 D3 / B3 files.

### Code Arena (class C) — a different product

Not Agent Mode. Five `/api/env` snapshots agree:

| Item | Value |
|------|--------|
| Template / build | `n93h7d3hf6qbdd07x3yo` / `62640bfa-…` |
| Guest OS | **Debian 12 (bookworm)** — not trixie |
| CPU / memory | 4 vCPU · `MemTotal 4034208 kB` · cgroup `memory.max 3996811264` |
| Database | Postgres on `127.0.0.1:5432` (same VM) |
| Persistence in snapshots | `/app` markers and DB rows survive across dates; `/tmp` marker does not |

Evidence: `forensic/evidence/code_arena/{chrome,brave,edge}/` snapshots. Packaged round-2 zips are Next.js skeletons; the env lock is in the snapshots.

### F benchmarks (2026-09-07)

Three self-describing texts, SHA-256 verified before and after placement.

- Same template, same cgroup shape, three sandbox ids.
- **Quote ranges, never a bare minimum.** Several tests swing 2–5× *inside one session*.
- Numpy is not held constant: brave **2.3.5**, edge **2.3.3**, chrome **unrecorded**. C3–C6 are confounded.
- Flag, do not treat as account properties: brave I2 (~4.9 GB/s, likely page-cache), edge N1 (rate-only, ~5× peers), edge I1 (seconds labelled as MB/s).

Usable cross-account: pure-Python C1 / C2 / C7, and N2 / N3.

Evidence: `forensic/evidence/benchmarks/` · report: `forensic/reports/benchmarks/BENCH_REPORT.md`.

### Round-3 calibration (models)

Same falsification prompt, three fresh sessions. **Self-reported** cutoffs:

| Browser | `cutoff_self` in the JSON |
|---------|---------------------------|
| edge | 2024-06 |
| chrome | ~2025-01 |
| brave | ~mid-2025 |

Factual calibration items often agreed. That is LLM text, not a sandbox knob. Agent Mode does not name the model in-session. Do not upgrade this table to “proven heterogeneous routing policy”.

Evidence: `forensic/evidence/round3/account_{a,b,c}/probe3/*.json`.

---

## Disagreements left standing

These are in the primary files. They are not bugs to paper over.

1. **Tool-call concurrency.** Round-3 chrome: 8 calls serial, ~2 s gaps, wall ~18 s. Round-3 brave: overlapped, wall ~10 s. Ceilings edge markdown: 8/8 parallel, ~5 s wall.
2. **DNS filtering.** Round-2 egress reports vs round-3 “no public DNS blocklist”.
3. **OOM mechanism.** Child cgroup kill vs account_c ceilings `global_oom` / `CONSTRAINT_NONE`.

---

## Not in this repo

| Topic | What is here instead |
|-------|----------------------|
| GitHub App identity, grants, workflows lag, screenshots | README/wiki text only. No `forensic/evidence/github_connect/`. |
| Agent Mode persistence campaign (128 MiB / 10k files / drop at 140 MiB) | Prompt exists (`prompts/round2/PersistencePROMPT.md`). Zips and evidence dirs are empty. |
| Class B session (bookworm / Py 3.11 / kernel `Mon May 11 18:48:24 UTC 2026` / ~3.8 GiB) | Used as a **negative discriminator** in round-3 (“0/4 B markers”). No raw session. |
| Non-Arena E2B control (“template is not an Arena fingerprint”) | Not archived. Sharing `nlhz8vlwyupq845jsdg9` across *Arena* sessions does not prove it is public E2B. |
| Characterizations for ceilings / egress / provenance / code_arena / benchmarks / persistence | Empty directories. |
| ICMP “blocked” as a measured result | Not established in the raws cited here. |

---

## VM classes — what this archive can fill in

| | T (Agent Mode, in this repo) | B (named, **not in this repo**) | C (Code Arena, in this repo) |
|---|---|---|---|
| Guest OS | Debian 13 trixie | bookworm / Py 3.11 — discriminator only | Debian 12 bookworm |
| Kernel stamp | `#1 … Fri Jul 17 14:31:34 UTC 2026` | `Mon May 11 18:48:24 UTC 2026` (unchecked here) | `#2 … Fri Mar 13 10:12:54 UTC 2026` |
| Python | 3.13.14 | 3.11.2 (unchecked here) | app-side (Node) |
| vCPU / MemTotal | 2 / 2 032 608 kB | 2 / ~3.8 GiB (unchecked here) | 4 / 4 034 208 kB |
| cgroup user memory.max | 1 947 172 864 B | — | 3 996 811 264 B |
| template / BUILD_ID | `nlhz8vlwyupq845jsdg9` / `f34a5416-…` | — | `n93h7d3hf6qbdd07x3yo` / `62640bfa-…` |

`INDEX_ALL.tsv` column `NEW` means **could not classify** from env-lock evidence (egress; provenance brave). It is not a fourth hardware class. `ID_COMPARISON_ROUND2.md` still says that column is blank — that paragraph is stale.

---

## Layout

| Path | What |
|------|------|
| `ACCOUNTS.md` | account ↔ browser ↔ acctN |
| `CHANGELOG.md` | append-only burst / PR log |
| `LICENSE` | Apache License 2.0 |
| `characterizations/environment/` | round-1 agent reports |
| `zips/` | immutable archives (persistence/benchmarks reserved empty) |
| `prompts/` | `round1/` `forensic/` `round2/` `round3/` |
| `forensic/evidence/` | unpacked raws (~843 files) |
| `forensic/reports/` | unpack reports, `summary/INDEX_ALL.tsv`, `benchmarks/BENCH_REPORT.md`, `round3/UNPACK_REPORT.md` |
| `docs/wiki_home.md` | wiki Home seed |
| `ceilings_prov_egress_extract_*/` `code_arena_extract_*/` | audit work trees, for humans |

---

## Verification (of files that exist)

| Set | Status |
|-----|--------|
| Round-1 environment | Inventory claims 363 SHA-256 entries / 17 manifests, 0 mismatches; outer zip SHAs 9/9 in `00_ROOT_INVENTORY.txt` |
| Round-2 zips | Light-verify PASS (hash, `unzip -t`, no traversal). See round-2 verify reports |
| Round-3 | 26 / 32 / 38 per-file PASS. Hash-of-hashes PASS **under each tree’s own method**. Brave/edge manifests say “sorted”; the digest that matches is **listed / filename order**, not sort-by-hash. See `forensic/reports/round3/UNPACK_REPORT.md` |
| F benchmarks | 3/3 SHA-256 MATCH pre- and post-move |
| GitHub-connect | **not performed** — no artefacts |

`00_ROOT_INVENTORY.txt` is Burst 16: it still lists benchmarks evidence as empty. F texts arrived later (Burst 20).

---

## Methods

1. **Raw layer first.** Shell redirection in-sandbox. Agent prose is secondary.
2. **Hash everything** that shipped as a tree. Re-verify before interpreting.
3. **Identical prompts, fresh sessions** where the prompt says so. Variance is signal.
4. **Never execute archive contents.**
5. **Report ranges.** Flag confounds (numpy version, method mismatch, page-cache, unit mislabels).
6. **Publish honest negatives:** `cannot verify`, `not performed`, `unrecorded`, empty directories.

---

## Still open

- Persistence turns 2/3 (Prompt B) — campaign not in the repo
- GitHub-connect evidence — not archived
- Class B session — not archived
- Non-Arena E2B control — not archived
- Probe G (connected-session egress), Probe H (workflows push)
- vanilla / react-vite Code Arena templates
- Host tenancy, SMT policy, sandbox TTL, per-turn wall-clock budget
- Section E on a live `arena.ai/code` session (snapshots exist; a full E run does not)

---

## Reproducing

Instruments are in `prompts/`.

1. Fresh Agent Mode session (or Code Arena, if that is the prompt).
2. Keep outputs verbatim.
3. Ship raws + manifest + hash-of-hashes (or one self-describing text, for F).
4. Diff against this repo. Do not re-read prose first.
5. Do not execute extracted scripts.

---

## License

Copyright 2026 Anuj Meena

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE).
