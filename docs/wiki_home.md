# Trixie Wiki — measuring Arena.ai's sandboxes from the inside

This wiki is the story. The evidence lives in [`anacondy/Trixie`](https://github.com/anacondy/Trixie).

- **Repo** — source of truth (raws, hashes, reports). If a sentence here has no file there, it is not a finding.
- **Wiki** — why the rounds were run, in order.

> Independent research. Not affiliated with Arena / LMArena.

---

## The question

Arena.ai runs Agent Mode (and Code Arena) in per-session cloud sandboxes and publishes no sandbox specification.

Can the **guest** be characterized from inside — OS, CPU, memory, IDs, network primitives — with hashes, not folklore?

**Yes.** That part is in the repo.

Can every **platform** behaviour (persistence budget, GitHub grants, model routing, “the” OOM number) be treated as settled?

**Only where a file exists.** Several headline stories were written ahead of the artefacts. They are listed below as not in the repo, not as results.

---

## Method

Identical paste-ready prompts, three accounts, three browsers (`chrome` / `brave` / `edge`). The browser string in the filename is ground truth.

Each run that shipped as a tree produced:

- raw command output (shell redirection — no LLM in those bytes)
- a SHA-256 manifest
- a hash-of-hashes

F-benchmarks shipped as one self-describing text per run, hashed as a whole file.

An external workspace re-hashed before interpreting. Disagreements were kept. Empty reserved directories were left empty on purpose. Archive scripts were not executed.

---

## Timeline

**2026-09-04 — Round 1 (environment ×9)**

Nine Agent Mode sessions. The guest lock that every later round reproduces:

- E2B / KVM / Firecracker-class (hostname `e2b.local`, ACPI `FIRECK`, virtio-mmio, no Docker)
- Debian 13 trixie · Python 3.13.14 · 2 vCPU Xeon @ 2.60 GHz (SMT pair on one core)
- `MemTotal 2032608 kB` · cgroup cap `1947172864` · ~25 G disk · `/tmp` tmpfs
- fd soft 1024 · NPROC 7917 · `cpu.max` unenforced
- passwordless sudo · user seccomp off · user `CapEff` empty
- template `nlhz8vlwyupq845jsdg9`

**2026-09-04/05 — Forensic unpack**

Hashes of the environment trees were recomputed. Template and sandbox IDs pulled out. `boot_id` already looked image-constant.

Not in the repo from this chapter: a non-Arena E2B control, a class-B session, a timeout bisection. Agent prose that says “30 s default / 1800 s max” is still prose.

**2026-09-05 — Round 2**

| Track | What the files support | What they do not |
|-------|------------------------|------------------|
| **Provenance** | `BUILD_ID f34a5416-…` · `boot_id` identical across three accounts · `E2B_SANDBOX_ID` is the instance | — |
| **Egress** | HTTPS works · `connect()` is a lying primitive · checked leaves are public CAs | “DNS-level blocks” as a general law (round-3 disagrees) |
| **Ceilings** | FD / NPROC / SMT / `cpu.max` · OOM as a **range across sessions** · child kill, session lives | One interval `[1624.85, 1653.86]` as *the* ceiling |
| **Code Arena** | Different template `n93h7d3hf6qbdd07x3yo` · 4 vCPU · **Debian 12 bookworm** · Postgres on loopback · `/app` + DB persist in snapshots, `/tmp` does not | Calling that guest “trixie-family” |
| **Persistence** | The **prompt** is in `prompts/round2/PersistencePROMPT.md` | The campaign. Zips and evidence dirs are empty. No 140 MiB drop message in this repo. |

**2026-09-06 — Round 3 (same prompt ×3)**

Class T lock confirmed again (0/4 class-B markers — B itself is still unseen).

Self-reported model cutoffs diverged:

| Browser | `cutoff_self` |
|---------|----------------|
| edge | 2024-06 |
| chrome | ~2025-01 |
| brave | ~mid-2025 |

That is LLM text. Agent Mode does not name the model. Treat it as a routing *hint*, not a measured router.

Also measured: `connect()` hijack (all three), IPv6 fail (chrome), local OpenSSH/OpenSSL PQC-hybrid KEX (edge), per-session egress IPs.

Also **disagreed:** whether eight tool calls run serial or overlapping.

**2026-09-07 — F benchmarks ×3**

One fresh run per account, fixed protocol. Integrity 3/3. Same template and cgroup shape.

Usable: pure-Python C1/C2/C7 and N2/N3. Confounded: C3–C6 (numpy 2.3.5 vs 2.3.3 vs chrome unrecorded). Unverified as account properties: brave I2, edge N1, edge I1 unit label.

Rule that survived contact with the logs: **quote ranges, never a bare minimum.**

**2026-09-08 — Docs**

Wiki created. F-benchmark texts placed (PR #5). GitHub-connector **evidence was not archived** in this repository.

---

## The guest, condensed

Agent Mode sessions in this corpus are snapshot-resumed E2B/KVM microVMs of **one** measured class (T).

| Fact | In the files |
|------|----------------|
| Per session | new `E2B_SANDBOX_ID`, low `/proc/uptime` |
| `boot_id` | baked into the image — same everywhere |
| In-guest services | older than the session (e.g. 2026-07-23 vs September) |
| User | uid 1000, passwordless sudo, seccomp 0, empty `CapEff` |
| Isolation | you are in a VM; host-side isolation is not measured from inside |
| Code Arena | other template, bookworm, 4 vCPU, live Postgres |
| Model name | not disclosed in Agent Mode |

Not in the files: `/home/user` as a ~128 MiB snapshot with a 10 k-file cap.

---

## Not archived here

Say these out loud so they stop travelling as results:

- GitHub App chain (`arena-agent` → App id 4187077 → `arena-ai-coding-agent[bot]`), grants, workflows lag, screenshots
- Agent Mode persistence TURN 1–3 (128 MiB / 10k / 140 MiB drop)
- A class-B Agent Mode session
- A non-Arena sandbox proving the template is public E2B
- Characterizations for any category except environment

---

## Open

- Persistence turns 2/3 (Prompt B)
- GitHub-connect artefacts
- Class B session and non-Arena control
- Probe G (connected-session egress), Probe H (workflows push)
- vanilla / react-vite Code Arena templates
- Host tenancy, SMT policy, sandbox TTL, per-turn wall-clock
- Full Section E on a live `arena.ai/code` session

---

## Where to look

| What | Path |
|------|------|
| Navigator (claim ledger) | `README.md` |
| Accounts | `ACCOUNTS.md` |
| Changelog | `CHANGELOG.md` |
| Index | `forensic/reports/summary/INDEX_ALL.tsv` (`NEW` = unclassified) |
| Reports | `forensic/reports/` |
| Evidence (~843 files) | `forensic/evidence/` |
| Instruments | `prompts/` |
| License | `LICENSE` (Apache-2.0) |
