# Trixie — an empirical characterization of Arena.ai's sandboxes

An evidence-first research archive: every claim about Arena's execution environments is backed by raw, hash-verified artifacts produced inside live sessions and re-verified externally. Claims whose primaries are not yet in the repo are labelled with where the primary lives (workspace note, API record, transcript) - see Verification status.

> Independent research; not affiliated with or endorsed by Arena / LMArena.

Story: [Trixie wiki](https://github.com/anacondy/Trixie/wiki) · License: [Apache-2.0](LICENSE)

---

## What this repo is

Three coordinated measurement rounds over Arena's **Agent Mode** sandbox (plus a cross-surface study of **Code Arena**). Each round ran as identical prompts across three accounts / browsers, with raw outputs shipped as zips or self-describing texts, SHA-256 manifests, and hash-of-hashes.

| Tree | Role |
|------|------|
| `forensic/` | unpacked, cross-checked evidence |
| `characterizations/` | agents' original reports |
| `prompts/` | every instrument we ran |

**Ground-truth rules used throughout:**

- The **browser string in filenames** is ground truth; `account_a` / `account_b` / `account_c` are aliases (see [`ACCOUNTS.md`](ACCOUNTS.md): a = chrome = acct1, b = brave = acct2, c = edge = acct3).
- **Raw evidence is never overwritten or edited**; disagreements between agents are retained as findings.
- History moves forward only: append-only [`CHANGELOG.md`](CHANGELOG.md), no force-pushes, no history rewrites.

---

## Headline findings

**1. E2B Firecracker microVMs**

Agent Mode runs in E2B Firecracker microVMs (KVM, `e2b.local`, `E2B_*` env) — measured in-guest, not from docs.

Evidence: round-1 raws, `zips/environment/`

**2. Shared E2B template, not an Arena fingerprint**

Template `nlhz8vlwyupq845jsdg9` is E2B's shared code-interpreter base. An unrelated non-Arena sandbox carries the same baked `/.e2b`.

Evidence: provenance runs; control = a non-Arena E2B sandbox observed from this research workspace (verbatim `/.e2b` in `forensic/evidence/provenance/control_probe_note.md`)

**3. Three VM classes**

| Class | Who | Guest | Spec |
|-------|-----|-------|------|
| **T** | Agent Mode common | trixie / Py 3.13 | 2 vCPU / 1985 MiB |
| **B** | Agent Mode variant (single env-lock) | bookworm-class / Py 3.11 | 2 vCPU / ~3.8 GiB |
| **C** | Code Arena nextjs-postgresql | **Debian 12 bookworm** | 4 vCPU / ~3.85 GiB |

Evidence: `INDEX_ALL.tsv` `vm_class` column

**4. Egress effectively open**

TCP 80/443, no MITM, through a **transparent local proxy**. `connect()` is hijacked by an accept-all gateway, so `connect()`-based probes are untrustworthy. DNS behaviour is **session-dependent**: one brave session's raw shows A-records rewritten into `0.0.0.0/8` plus a NODATA answer, while round-2 and round-3 sweeps in other sessions find no DNS filtering; the robust blocklist is cloud-metadata only.

Evidence: `zips/egress/`, round-3

**5. Persistence = snapshot-resume per turn**

Only `/home/user` survives (~128 MiB / 10 k files, exclusion list). Budget enforced by dropping files (verbatim platform message at 140 MiB). Fresh VM + new sandbox id each turn.

Evidence: per-turn fresh-VM facts are in the raws; the 140 MiB drop is a platform-message observation (chat transcript, `forensic/evidence/persistence/turn1_provenance_note.md`, landing via Burst 22); cross-turn survival re-measured at the 20-day boundary (2026-09-24): fresh VM + byte-identical `/home/user` in all three accounts (`forensic/reports/persistence/PERSISTENCE_20DAY_20260924.md`)

**6. Hard ceilings**

- OOM anon boundary **session-dependent: ~1600-1664 MiB** across single-session bisects (chrome 1600/1632; brave 1632/1664; edge 1624.85/1653.86; ceilings-c 1637/1638 with a host-global reading); SIGKILL child-scoped; `memory.high` set equal to `memory.max` (no soft band: killed, not slowed)
- fork EAGAIN at **7914** (`RLIMIT_NPROC` 7917) - rests on the account_c write-up + ulimit raws; brave's `fork_test.log` is empty
- fds soft 1024 → hard 524288
- unprivileged ICMP fails for lack of `CAP_NET_RAW` while `sudo ping` works - a capability failure, not a proven network policy
- `cpu.max` unenforced
- the two vCPUs are **SMT siblings of one core** - ~0 latency gain for one process (C7 = 0.97-0.98), ~1.7-2.0x aggregate for two processes

Evidence: `zips/ceilings/`, round-3

**7. Heterogeneous model routing**

Identical prompts drew models with divergent self-reported cutoffs while factual calibration converged. Agent Mode never names models.

| Browser | Self-reported cutoff |
|---------|----------------------|
| edge | 2024-06 |
| chrome | ~2025-01 |
| brave | ~mid-2025 |

Evidence: round-3 JSONs

**8. Code Arena is a different product template**

Template `n93h7d3hf6qbdd07x3yo`, class C, with Postgres. Resume mints fresh boots. `/app` persists, `/tmp` does not, DB rows do.

Evidence: `zips/code_arena/`, snapshots

**9. Benchmarks must be quoted as ranges**

Within-session swings of 2–5× exceed most between-account deltas. Numpy version drift (2.3.5 vs 2.3.3 vs *unrecorded* chrome) confounds C3–C6.

Evidence: `forensic/reports/benchmarks/BENCH_REPORT.md`

**10. GitHub-connect**

Identity chain: dev account `arena-agent` → App "Arena AI Coding Agent" (id 4187077) → bot `arena-ai-coding-agent[bot]`.

- Installation grants matched API observations exactly
- `workflows` arrived via app-level change (2026-09-01) + user acceptance (2026-09-08) — a documented **permission propagation lag**
- no `administration`
- sandbox tokens are a subset of installation grants

Evidence: GitHub API records + settings-page screenshots (`forensic/evidence/github_connect/`, landing via Burst 22)

---

## VM classes at a glance

| | T (Agent Mode common) | B (Agent Mode variant) | C (Code Arena fullstack) |
|---|---|---|---|
| guest OS | Debian 13 trixie | Debian-12-class bookworm | **Debian 12 bookworm** |
| kernel stamp | `#1 … Fri Jul 17 14:31:34 UTC 2026` | `… Mon May 11 18:48:24 UTC 2026` | `#2 … Fri Mar 13 10:12:54 UTC 2026` |
| Python | 3.13.14 | 3.11.2 | (app-side) |
| vCPU / MemTotal | 2 / 2 032 608 kB | 2 / ~3.8 GiB | 4 / 4 034 208 kB |
| cgroup user memory.max | 1 947 172 864 B | — | 3 996 811 264 B |
| template / BUILD_ID | `nlhz8vlwyupq845jsdg9` / `f34a5416-…` | — | `n93h7d3hf6qbdd07x3yo` / `62640bfa-…` |

---

## Layout

| Path | What |
|------|------|
| `ACCOUNTS.md` | account ↔ browser ↔ acctN mapping (ground truth statement) |
| `CHANGELOG.md` | append-only burst / PR log |
| `LICENSE` | Apache License 2.0 |
| `characterizations/` | agents' reports, per category; `environment/` = round-1 originals |
| `zips/` | immutable archives: environment (round-1 followup), provenance, ceilings, egress, code_arena, round3/, previews/ (Sep-15 preview bundles); persistence and benchmarks are (placeholders, awaiting future zips) |
| `prompts/` | `round1/` `forensic/` `round2/` `round3/` `preview/` `round4/` — every instrument, verbatim |
| `forensic/evidence/` | unpacked raws per account (**843 files**, 849 with `.gitkeep`): environment, provenance, ceilings, egress, code_arena (+5 api_env snapshots), round3/, benchmarks/ (F runs x3); `github_connect/` + two provenance notes land via Burst 22 |
| `forensic/reports/` | per-round unpack reports + `summary/` (`INDEX_ALL.tsv`, inventories, ID comparisons) + `benchmarks/BENCH_REPORT.md` + `round3/UNPACK_REPORT.md` + `previews/MASTER_SHEET.md` + `coldstart/ADJUDICATION.md` + `persistence/` + `mpx/` |
| `methods/` | cross-verification kit, CPU-attribution kit + samplers, zip-audit tooling |
| `docs/wiki_home.md` | wiki Home seed (source of truth the wiki mirrors) |
| `ceilings_prov_egress_extract_*/` | audit work trees, kept for human review |
| `code_arena_extract_*/` | same |

*15 placeholder dirs (intentional, `.gitkeep`-only, awaiting future zips): `characterizations/{benchmarks, ceilings, code_arena, egress, persistence, provenance}`, `zips/benchmarks/account_{a,b,c}`, `zips/persistence/account_{a,b,c}`, `forensic/evidence/persistence/account_{a,b,c}`.*

---

## Verification status

| Round | Status |
|-------|--------|
| Round-1 | **all manifests recompute with 0 FAIL** (crosscheck: 324 resolved OK + 82 unresolved external refs); outer zip SHAs 9/9 match independent recomputation |
| Round-2 zips | per-manifest PASS for every account; `INDEX_ALL.tsv` `vm_class` column closed (env 10×T, prov T/NEW/T, egress 3×NEW, code_arena 3×C) |
| Round-3 | 26/32/38 per-file PASS; each manifest's hash-of-hashes reproduces under its own stated method; outer SHAs equal the agents' pasted reports |
| F benchmarks | 3/3 SHA-verified pre- and post-placement (PR #5); report cross-checked line-by-line against raws |
| GitHub-connect | API-verified (grants, PR create+merge, net-diff workflows rule, administration absent) + settings-page screenshots archived with SHA-256 |
| Viewer round (2026-09-15) | 29-row master sheet, human-observed verdicts, 3 browsers; bundle SHAs verified repo↔upload; row-28 ~10 MB crash closed by operator decision after 3rd reproduction (`forensic/reports/previews/MASTER_SHEET.md`) |
| D5 re-run (2026-09-24) | 3 browsers (chrome, firefox, brave): stagger 0.10–3.44 s, 8–10 processes simultaneously resident on 2 vCPU, walls ≈ 20–23 s ⇒ no hard concurrency cap; round-3 "cap=1" was a dispatch artifact (`forensic/evidence/d5_rerun_20260924/`) |
| 20-day persistence (2026-09-24) | 3/3 round-1 sessions resumed after 20 days idle: fresh sandbox + byte-identical `/home/user` (Brave manifest SHA; Chrome 148/148 re-hash + zip SHA; Edge top-level + Sep-4-verified zip) (`forensic/reports/persistence/PERSISTENCE_20DAY_20260924.md`) |
| MPX cross-surface (2026-09-24) | template + BUILD_ID equivalence, boot_id lineage across surfaces (`forensic/reports/mpx/MPX_SESSION_SANDBOX_FINDINGS.md`) |
| INDEX_ALL | completed to 28 data rows: +3 round-3 zips, +3 preview bundles, SHAs re-verified against freshly downloaded bytes |
| Known stale indexes | `00_ROOT_INVENTORY.txt` predates the F landing; `ID_COMPARISON_ROUND2.md` §5 predates the Burst-17 vm_class fill; both superseded by `INDEX_ALL.tsv` + this README |

---

## Methods (why this corpus is trustworthy)

1. **Raw layer first.** Raw `.txt` outputs are produced by shell redirection in-sandbox (zero LLM in the bytes); agent prose is secondary commentary.

2. **Hash everything.** Per-file SHA-256 + hash-of-hashes per manifest; external re-verification entry-by-entry before any analysis.

3. **Identical prompts, fresh sessions** for characterization categories (A/C/D/F fresh; B multi-turn by design; E on Code Arena) — variance between identical runs is itself data (routing, scaffolding, host steal).

4. **Never execute archive contents**; read-only unpacking; quarantine thresholds for traversal / symlinks / oversized nests; ≤5000-insertion bursts with push-per-burst.

5. **Report ranges, never bare minima**; flag confounds (numpy version, method mismatch, page-cache reads) instead of smoothing them.

6. **Honest negatives:** `cannot verify`, `not performed`, `unrecorded` are published as results (e.g., chrome's missing numpy line; A3's honest refusal).

7. **Label confidence per claim.** In-guest raws = high; single-session bisects, agent self-reports and platform transcripts are labelled as such; primaries not yet in the repo are cited with their external record (API, workspace note, transcript).

---

## Open questions

- Probe G (connected-session egress two-curl) pending
- Probe H (post-acceptance workflows push) pending
- ~~B turns 2/3 (cross-turn survival)~~ — resolved 2026-09-24 at the 20-day boundary, 3/3 accounts (`forensic/reports/persistence/PERSISTENCE_20DAY_20260924.md`)
- run9 evidence tree is 10 files short of its own zip (npm-cache files; manifest NOFILE rows) - quote the zip for run9
- canonical `zips/code_arena/` archives retain the starter's localhost Postgres credential (scrub touched evidence copies only; placeholder value, rotate nothing)
- QUIC/HTTP-3 egress is narrative-only (the cited success output is not in the tree)
- `ceilings/` and `egress/` trees carry no session ids (unjoinable to sessions); backfill `E2B_SANDBOX_ID` lines in future rounds
- vanilla / react-vite Code Arena templates unmeasured
- host tenancy / SMT policy / sandbox TTL unknown
- Section E core: ran 2026-09-05 in arena.ai/code (Direct+Max; template `n93h7d3hf6qbdd07x3yo`, 4 vCPU / 3.85 GiB) — only the vanilla / react-vite item remains

---

## Reproducing

Everything needed is in `prompts/`.

1. Run each prompt in a **fresh** Agent Mode session per the routing notes inside.
2. Keep outputs verbatim.
3. Ship raws + manifest + hash-of-hashes.
4. Diff against this repo instead of re-reading prose.

---

## License

Copyright 2026 Anuj Meena

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE).
