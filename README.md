# Trixie — an empirical characterization of Arena.ai's sandboxes

An evidence-first research archive: every claim about Arena's execution environments in this repository is backed by raw, hash-verified artifacts produced inside live sessions and re-verified externally. **Independent research; not affiliated with or endorsed by Arena / LMArena.**

## What this repo is

Three coordinated measurement rounds over Arena's **Agent Mode** sandbox (plus a cross-surface study of **Code Arena**), each run as identical prompts across three accounts/browsers, with raw outputs shipped as zips or self-describing texts, SHA-256 manifests, and hash-of-hashes. The `forensic/` tree is the unpacked, cross-checked evidence; `characterizations/` holds the agents' original reports; `prompts/` holds every instrument we ran.

**Ground-truth rules used throughout:**
- The **browser string in filenames** is ground truth; `account_a/b/c` are aliases (see `ACCOUNTS.md`: a = chrome = acct1, b = brave = acct2, c = edge = acct3).
- **Raw evidence is never overwritten or edited**; disagreements between agents are retained as findings.
- History moves forward only: append-only `CHANGELOG.md`, no force-pushes, no history rewrites.

## Headline findings

| # | Finding | Evidence |
|---|---|---|
| 1 | Agent Mode runs in **E2B Firecracker microVMs** (KVM, `e2b.local`, `E2B_*` env) — measured in-guest, not from docs | round-1 raws, `zips/environment/` |
| 2 | Template `nlhz8vlwyupq845jsdg9` is **E2B's shared code-interpreter base, not an Arena fingerprint** (an unrelated non-Arena sandbox carries the same baked `/.e2b`) | provenance runs, control probe |
| 3 | **Three VM classes**: T (trixie / Py 3.13 / 2 vCPU / 1985 MiB), B (bookworm-class / Py 3.11 / ~3.8 GiB), C (Code Arena nextjs-postgresql / 4 vCPU / ~3.85 GiB) | `INDEX_ALL.tsv` vm_class column |
| 4 | **Egress effectively open** (TCP 80/443, no MITM) through a **transparent local proxy**; `connect()` is hijacked by an accept-all gateway, so connect()-based probes are untrustworthy | `zips/egress/`, round-3 |
| 5 | **Persistence = snapshot-resume per turn**: only `/home/user` survives (~128 MiB / 10 k files, exclusion list); budget enforced by dropping files (verbatim platform message at 140 MiB); fresh VM + new sandbox id each turn | persistence runs |
| 6 | Hard ceilings measured: OOM anon **[1624.85, 1653.86] MiB**, child-scoped SIGKILL; fork EAGAIN at **7914** (RLIMIT_NPROC 7917); fds soft 1024 → hard 524288; `cpu.max` unenforced; the two vCPUs are **SMT siblings of one core** | `zips/ceilings/`, round-3 |
| 7 | **Heterogeneous model routing**: identical prompts drew models with divergent self-reported cutoffs (2024-06 / ~2025-01 / ~mid-2025) while factual calibration converged; Agent Mode never names models | round-3 JSONs |
| 8 | **Code Arena is a different product template** (`n93h7d3hf6qbdd07x3yo`, class C) with Postgres; resume mints fresh boots; `/app` persists, `/tmp` does not, DB rows do | `zips/code_arena/`, snapshots |
| 9 | **Benchmarks must be quoted as ranges**: within-session swings of 2–5× exceed most between-account deltas; numpy version drift (2.3.5 vs 2.3.3 vs *unrecorded* chrome) confounds C3–C6 | `forensic/reports/benchmarks/BENCH_REPORT.md` |
| 10 | **GitHub-connect**: identity chain dev account `arena-agent` → App "Arena AI Coding Agent" (id 4187077) → bot `arena-ai-coding-agent[bot]`; installation grants matched API observations exactly; `workflows` arrived via app-level change (2026-09-01) + user acceptance (2026-09-08) — a documented **permission propagation lag**; no `administration`; sandbox tokens are a subset of installation grants | `forensic/evidence/github_connect/` |

## VM classes at a glance

| | T (Agent Mode common) | B (Agent Mode variant) | C (Code Arena fullstack) |
|---|---|---|---|
| guest OS | Debian 13 trixie | Debian-12-class bookworm | trixie-family |
| kernel stamp | `#1 … Fri Jul 17 14:31:34 UTC 2026` | `… Mon May 11 18:48:24 UTC 2026` | `#2 … Fri Mar 13 10:12:54 UTC 2026` |
| Python | 3.13.14 | 3.11.2 | (app-side) |
| vCPU / MemTotal | 2 / 2 032 608 kB | 2 / ~3.8 GiB | 4 / 4 034 208 kB |
| cgroup user memory.max | 1 947 172 864 B | — | 3 996 811 264 B |
| template / BUILD_ID | `nlhz8vlwyupq845jsdg9` / `f34a5416-…` | — | `n93h7d3hf6qbdd07x3yo` / `62640bfa-…` |

## Layout

```
ACCOUNTS.md                  account ↔ browser ↔ acctN mapping (ground truth statement)
CHANGELOG.md                 append-only burst/PR log
characterizations/           agents' reports, per category; environment/ = round-1 originals
zips/                        immutable archives: environment (round-1 followup), provenance,
                             ceilings, egress, code_arena, persistence, benchmarks, round3/
prompts/                     round1/ forensic/ round2/ round3/ — every instrument, verbatim
forensic/
  evidence/                  unpacked raws per account (969 files): environment, provenance,
                             ceilings, egress, code_arena (+5 api_env snapshots), round3/,
                             benchmarks/ (F runs ×3), github_connect/ (permission screenshots)
  reports/                   per-round unpack reports + summary/ (INDEX_ALL.tsv, inventories,
                             ID comparisons) + benchmarks/BENCH_REPORT.md + round3/UNPACK_REPORT.md
ceilings_prov_egress_extract_*/   audit work trees, kept for human review
code_arena_extract_*/             (same)
```

## Verification status

- Round-1: **363 SHA-256 entries across 17 manifests, 0 mismatches**; outer zip SHAs 9/9 match independent recomputation.
- Round-2 zips: per-manifest PASS for every account; `INDEX_ALL.tsv` vm_class column closed (env 10×T, prov T/NEW/T, egress 3×NEW, code_arena 3×C).
- Round-3: 26/32/38 per-file PASS; each manifest's hash-of-hashes reproduces under its own stated method; outer SHAs equal the agents' pasted reports.
- F benchmarks: 3/3 SHA-verified pre- and post-placement (PR #5); report cross-checked line-by-line against raws.
- GitHub-connect: API-verified (grants, PR create+merge, net-diff workflows rule, administration absent) + settings-page screenshots archived with SHA-256.

## Methods (why this corpus is trustworthy)

1. **Raw layer first.** Raw `.txt` outputs are produced by shell redirection in-sandbox (zero LLM in the bytes); agent prose is secondary commentary.
2. **Hash everything.** Per-file SHA-256 + hash-of-hashes per manifest; external re-verification entry-by-entry before any analysis.
3. **Identical prompts, fresh sessions** for characterization categories (A/C/D/F fresh; B multi-turn by design; E on Code Arena) — variance between identical runs is itself data (routing, scaffolding, host steal).
4. **Never execute archive contents**; read-only unpacking; quarantine thresholds for traversal/symlinks/oversized nests; ≤5000-insertion bursts with push-per-burst.
5. **Report ranges, never bare minima**; flag confounds (numpy version, method mismatch, page-cache reads) instead of smoothing them.
6. **Honest negatives**: "cannot verify", "not performed", "unrecorded" are published as results (e.g., chrome's missing numpy line; A3's honest refusal).

## Open questions

Probe G (connected-session egress two-curl) pending · Probe H (post-acceptance workflows push) pending · B turns 2/3 (cross-turn survival) pending · vanilla/react-vite Code Arena templates unmeasured · host tenancy / SMT policy / sandbox TTL unknown · Section E still to run in an arena.ai/code session.

## Reproducing

Everything needed is in `prompts/`. Run each prompt in a **fresh** Agent Mode session per the routing notes inside; keep outputs verbatim; ship raws + manifest + hash-of-hashes; then diff against this repo instead of re-reading prose.
