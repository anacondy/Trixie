# Trixie Wiki — measuring Arena.ai's sandboxes from the inside

This wiki narrates the investigation whose evidence lives in the [`anacondy/Trixie`](https://github.com/anacondy/Trixie) repository.

- **Repo** — source of truth (raw artifacts, hashes, reports)
- **Wiki** — the story

> Independent research; not affiliated with Arena / LMArena.

---

## The question

Arena.ai runs its coding leaderboards and Agent Mode inside per-session cloud sandboxes, but publishes no sandbox specification.

Can the environment nevertheless be characterized rigorously — and can the *platform's* behaviour (routing, persistence, permissions) be measured rather than guessed?

**Answer:** yes, if you treat variance as signal and hash everything.

---

## Method in one paragraph

Identical paste-ready prompts were run in fresh Arena sessions across three accounts and three browsers (`chrome` / `brave` / `edge`; browser string in filenames is ground truth).

Each run produced:

- **raw byte-level outputs** (shell redirection, no LLM in the raws)
- a SHA-256 manifest
- a hash-of-hashes
- shipped as zips or single texts

An external workspace re-verified every hash entry-by-entry before any interpretation. Disagreements between agents were kept as findings; honest negatives (`cannot verify`, `not performed`) were published as results.

Repository history moves forward only (append-only changelog, no force-push).

---

## Timeline

**2026-09-04 — Round 1**

Nine environment characterizations (3 browsers × 3 accounts). Established the substrate:

- E2B Firecracker microVMs
- 2 vCPU Xeon @ 2.60 GHz
- MemTotal `2 032 608 kB` with cgroup cap `1 947 172 864 B`
- zero swap, 25 GB disk
- fd soft 1024, NPROC 7917
- all capabilities, no seccomp, passwordless sudo
- egress open through a transparent local proxy
- ICMP blocked, IPv6 unrouted

**2026-09-04/05 — Forensic audit**

- 363 SHA-256 entries across 17 manifests, **0 mismatches**
- template ID `nlhz8vlwyupq845jsdg9` is **not Arena-specific** (an unrelated E2B sandbox shares the baked `/.e2b`)
- second VM class discovered (bookworm-class, Py 3.11, ~3.8 GiB)
- “AI service error” adjudicated: a turn-level failure correlated with huge workspace diffs — not a timeout, not the VM class
- folklore “180 s timeout” was confabulated (real constants: 30 s default / 1800 s max)

**2026-09-05 — Round 2 (A–F)**

- **Provenance** — `BUILD_ID` `f34a5416-…`, `boot_id` template-constant
- **Egress** — DNS-level blocks; no TLS interception; SSH-22 banner at byte level
- **Ceilings** — OOM anon `[1624.85, 1653.86]` MiB child-scoped; fork EAGAIN at 7914; SMT siblings on one physical core; `cpu.max` unenforced
- **Code Arena** — different template (`n93h7d3hf6qbdd07x3yo`) and third VM class C (4 vCPU, `4 034 208 kB`, Postgres; resume mints fresh boots; `/app` persists, `/tmp` doesn't, DB rows do)
- **Persistence TURN 1** — the ~128 MiB / 10 k-file budget is enforced by dropping files (verbatim platform message at 140 MiB)

**2026-09-06 — Round 3 (calibrated)**

Identical prompts, three fresh sessions: factual calibration converged while **self-reported cutoffs diverged**.

| Browser | Self-reported cutoff |
|---------|----------------------|
| edge | 2024-06 |
| chrome | ~2025-01 |
| brave | ~mid-2025 |

⇒ heterogeneous per-session model routing.

Also observed:

- `connect()` hijacked by an accept-all gateway (`connect()`-probes untrustworthy)
- ~53% ambient sidecar CPU explains benchmark variance
- local PQC profile
- per-sandbox egress IPs

**2026-09-07 — F benchmarks ×3**

Fixed-protocol CPU / I-O / network benchmarks, one fresh run per account.

- convergent bands confirm one hardware class
- outliers itemized
- **rule adopted: quote ranges, never bare minima**
- numpy version drift (and chrome's unrecorded numpy) flagged as confounds

**2026-09-08 — GitHub-connect**

First empirical characterization of Arena's GitHub connector (below), plus Burst-20 placement of the F evidence (PR #5) and this documentation pass.

---

## The substrate, condensed

Arena Agent Mode sessions are snapshot-resumed E2B Firecracker microVMs.

| Fact | Measurement |
|------|-------------|
| Per turn | fresh VM id, reset uptime |
| `/home/user` | re-materialized from a ~128 MiB snapshot |
| In-guest services | older than the boot |
| `boot_id` | baked into the image |
| Isolation | the VM *is* the boundary — no seccomp, full capabilities, passwordless sudo inside |
| Code Arena | separate template and VM class, with a live Postgres |
| Model identity | never disclosed in Agent Mode; comparison surfaces reveal names only after completion / vote |
| Routing | round-3 cutoff divergence shows it genuinely varies per session |

---

## The GitHub-connect chapter

The connector is a GitHub App:

```
developer account  arena-agent
        ↓
App  "Arena AI Coding Agent"
     id 4187077 · slug arena-ai-coding-agent
        ↓
installation bot  arena-ai-coding-agent[bot]
     (authors commits and PRs)
```

Measured facts, each verified twice (GitHub API + settings-page screenshots):

- **Installation grants (pre-Sept-8)** — read `actions` / `checks` / `statuses` / `issues` / `metadata`; write `contents` / `pull-requests` / `repository-hooks`. Matches every observed capability. **No `administration`** (About panel untouched, triple-confirmed).
- **Workflows rule** — pushes whose net diff adds `.github/workflows` were refused (branches and tags alike). GitHub-standard enforcement for tokens lacking `workflows`. The app added `workflows: write` at app level on **2026-09-01**; existing installations lagged until each user accepted (**2026-09-08**) — a live observation of GitHub's permission-propagation model.
- **Sandbox token** — observed as a **subset** (contents-only) of the installation grants; PR create / merge happens at the platform layer.
- **Installation scope** — **all repositories**, current and future.

---

## Benchmark etiquette (lessons)

A 64 000× spread in pooled “throughput” numbers was nine agents measuring nine different things under one label.

Fixes that worked:

1. Fixed protocol (sizes, dtypes, endpoints, timing)
2. Min-of-runs headlines **plus full ranges**
3. Method-matching before cross-account comparison
4. Flag confounds (numpy versions, page-cache reads, rate-only logs, unit mislabels such as edge's I1 seconds-as-MB/s)

---

## Open questions

- Connected-session egress (Probe G)
- Post-acceptance workflows push (Probe H)
- Cross-turn survival, turns 2/3 (Prompt B)
- vanilla / react-vite templates
- Host tenancy & SMT policy
- Sandbox TTL
- Per-turn wall-clock budget

---

## Where to look

| What | Path |
|------|------|
| Navigator | `README.md` |
| Accounts | `ACCOUNTS.md` |
| Changelog | `CHANGELOG.md` |
| Index | `forensic/reports/summary/INDEX_ALL.tsv` |
| Reports | `forensic/reports/**` |
| Evidence (969 files) | `forensic/evidence/**` |
| Instruments | `prompts/**` |
| Permission screenshots | `forensic/evidence/github_connect/` |
