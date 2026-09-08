# Cross-Verification of Two Trixie Reviews

**Audited trees:** `anacondy/Trixie` @ `123965e3` (Review A) and @ `95eb5fb3`/`d43f7be` (Review B)
**This report verified against:** working tree at `d43f7beb91cab26f3437d1762f97d36675654884`,
branch `arena/01a08240-trixie`, plus the GitHub source tree for four commits (see §2).
**Method:** every number and path re-derived with `find` / `grep` / `git ls-files` / `sha256sum`
/ `gh api`. No claim taken from either review on trust. No archived payload executed.

---

## 1. Verdict

**Review A (no GitHub access) is the better review, and by a wider margin than I first reported.**

An earlier draft of this report scored Review B higher on the grounds that Review A critiqued
files "that do not exist in this checkout." **That judgement was wrong.** Going to the GitHub
source proves Review A audited a real tree — `main` at `123965e3`, committed 51 minutes before
the merge that replaced it — and that **all fifteen of its line-level claims verify exactly
against that commit.** Review A made no substantive factual error.

Review B, by contrast, contains one arithmetic error that is wrong at *every* commit in the
repository's history, one false negative about class B, and one imprecise concurrency
comparison.

| | Review A | Review B |
|---|---|---|
| Substantive factual errors | **0** | **3** (archive count, class B, concurrency) |
| Line-level claims verified against its tree | **15 / 15** | 7 / 8 quoted phrases verified |
| Conceptual framework | weaker | **stronger** |
| Recommendations actually adopted | superseded before merge | **adopted** |

Review B still contributes the better *method* (§7) and its rewrite is what shipped. But on
accuracy — the axis the reviews are actually meant to be judged on — Review A wins.

---

## 2. The timeline, reconstructed from source

This is the fact that resolves the disagreement between the two reviews. Retrieved via
`gh api repos/anacondy/Trixie/...`; all times 2026-09-08 UTC.

| Commit | Time | Root docs | `zips/` | `forensic/evidence` |
|---|---|---|---|---|
| `123965e3` "Burst 21" | 17:06:03 | `README.md` · **`README_NEW.md`** · **`WIKI_HOME.md`** — no `docs/`, no `LICENSE` | **24** | **849** |
| `ee33aba2` "Burst 21 — docs landing" | 17:08:34 | — | 24 | 849 |
| `95eb5fb3` "Reformat wiki Home seed" | 17:24:22 | `README.md` · **`docs/wiki_home.md`** (180 lines) — no `LICENSE` | **24** | **849** |
| `1d32ec89` "Rewrite README and wiki as an honest claim ledger" | 17:52:49 | + `LICENSE` | 24 | 849 |
| `d43f7beb` merge PR #6 (`merged_at` 17:57:05Z) | 17:57:04 | root `WIKI_HOME.md` + `README_NEW.md` **deleted**; `docs/wiki_home.md` + `LICENSE` | **24** | **849** |

Two consequences:

1. **Review A audited `123965e3`.** That tree has root `WIKI_HOME.md` and `README_NEW.md` and
   no `docs/` — precisely Review A's inventory. Its branch label `arena/01a08225-trixie` is not
   a remote branch (source branches are `01a06d74`, `01a06e63`, `01a070c2`, `01a077da`,
   `01a08084`, `01a081fc`, `main`), so it was a local sandbox branch off `main` — but the
   *content* it described is real and exactly right.
2. **`zips/` held 24 archives at all four commits**, and `forensic/evidence` held 849 blobs at
   all four. Review B's "21" is not a stale-tree artefact. It is simply wrong.

---

## 3. Review A's line-level claims — all fifteen verified

Retrieved from `123965e3` via `gh api .../contents/<path>?ref=123965e3...`.

### `README.md` @ `123965e3`

| Review A claim | File content at that line | |
|---|---|---|
| "Line 5 has the old branch `arena/01a070c2-trixie`" | L5: ``Working branch: `arena/01a070c2-trixie`. Raw zips, …`` | ✅ exact line |
| "Line 36 says the benchmark zip directories are empty" | L36: `benchmarks/account_{a,b,c}/      # empty` (under `zips/`) | ✅ exact line |
| "Line 55 says `forensic/evidence/benchmarks/` is empty; that is false" | L55: `benchmarks/ persistence/       # empty` (under `forensic/evidence/`) — and `forensic/evidence/benchmarks/` holds 3 real logs | ✅ exact line, and the falsity is real |
| "Layout omits `zips/round3/`, `forensic/evidence/round3/`" | Neither `round3/` appears in the `zips/` or `forensic/evidence/` layout blocks | ✅ |

### `README_NEW.md` @ `123965e3`

| Review A claim | File content | |
|---|---|---|
| "the false 969-file count" | L50: `evidence/  unpacked raws per account (969 files)` | ✅ |
| "the nonexistent `forensic/evidence/github_connect/`" | L27, L52 both cite that path | ✅ |
| "unsupported GitHub-connect claims" | L27: full chain `arena-agent` → App id `4187077` → `arena-ai-coding-agent[bot]`, grants, `workflows` lag, "no `administration`" | ✅ |

### `WIKI_HOME.md` @ `123965e3`

| Review A claim | File content at that line | |
|---|---|---|
| L15 "`all capabilities` is false for the ordinary user; `ICMP blocked` too broad" | L15: "…**all capabilities**, no seccomp, passwordless sudo; … **ICMP blocked**, IPv6 unrouted." | ✅ exact line, both items |
| L16 "'AI service error' causation + '180-second timeout folklore' not established" | L16: "Adjudicated the 'AI service error'… the folklore '180 s timeout' was confabulated (real constants: 30 s default / 1800 s max)." | ✅ exact line |
| L17 "'DNS-level blocks' and persistence-budget proof too broad" | L17: "egress mapped (**DNS-level blocks**…)" … "Persistence TURN 1 **proved** the ~128 MiB / 10 k-file budget… (**verbatim platform message at 140 MiB**)" | ✅ exact line, both items |
| L18 "'~53% ambient sidecar CPU explains benchmark variance' over-causal" | L18: "…**~53% ambient sidecar CPU explains benchmark variance**…" | ✅ exact line |
| L19 "'convergent bands confirm one hardware class' too strong" | L19: "**Convergent bands confirm one hardware class**; outliers itemized…" | ✅ exact line |
| L24 remove "fresh VM each turn", "boot_id baked into the image", "full capabilities", comparison-surface claim | L24: "a **fresh VM id and reset uptime each turn**… **`boot_id` baked into the image**. The VM *is* the isolation boundary — no seccomp, **full capabilities**… **comparison surfaces reveal names only after completion/vote**" | ✅ exact line, all four items |
| L26–33 "the entire GitHub-connect chapter" | L26 is the heading `## The GitHub-connect chapter`; the chapter runs through L33 | ✅ exact range |
| L37 "'64,000× spread' not supported by a primary artifact" | L37: "A **64 000×** spread in pooled 'throughput' numbers…" | ✅ exact line |
| L45 "replace `969 files`; remove the nonexistent GitHub evidence path" | L45: "Evidence: `forensic/evidence/**` (**969 files**)… Permission screenshots: **`forensic/evidence/github_connect/`**." | ✅ exact line, both items |

**15 / 15, including exact line numbers and exact line ranges.** This is a high-precision audit.

---

## 4. Review B's errors

### 4.1 "21 real archives" — wrong at every commit in history

```
gh api repos/anacondy/Trixie/git/trees/<ref>?recursive=1
  123965e3 → zips/*.zip = 24        d43f7beb → zips/*.zip = 24
  95eb5fb3 → zips/*.zip = 24        1d32ec89 → zips/*.zip = 24
git ls-files 'zips/*.zip' | wc -l → 24
```

9 environment + 3 each ceilings / egress / provenance / code_arena / round3 = **24**. Review B's
own directory list sums to 24. Round-3 landed in PR #4 (Burst 19, merged 2026-09-06), so no
tree Review B could have seen had 21. **Review A's 24 is correct.**

Review A also derives the related figure correctly:

```
git ls-files '*.zip' | wc -l → 26
git ls-files '*.zip' | grep -v '^zips/' → exactly the two nested Agent 9 copies
```

### 4.2 "No class-B raw session in this repo" — false

Review B lists class B under **Not in this repo**, twice.
`forensic/reports/round1_environment/02_UNPACK_REPORT.md` §1 "Execution Environment Snapshot
(Phase 0)" contains:

```
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Mon May 11 18:48:24 UTC 2026 x86_64 GNU/Linux
Python 3.11.2
Mem:           3.8Gi       227Mi       3.7Gi       1.0Mi       113Mi       3.6Gi
uid=1001(user) gid=1001(user) groups=1001(user),27(sudo),100(users)
```

**Three of the four class-B markers verbatim** — exact kernel stamp, exact Python, exact
memory — from a live `e2b.local` guest. Review A caught this and supplied the correct narrower
statement (*no packaged Agent Mode class-B characterization exists*). Review B's flat denial is
false as written.

Minor caveat on Review A: that file does not literally print "Debian 12"; the distro is
inferred. Review A is slightly over-precise on one word but substantively right.

### 4.3 "brave/ceilings overlapped" — imprecise; three distinct behaviours exist

| Session | Start pattern | Behaviour |
|---|---|---|
| round-3 `account_a` (chrome) | `33.491 → 35.861 → 37.519` (gaps 2.370 s, 1.658 s) | serial, ~2 s stagger |
| round-3 `account_b` (brave) | `21.28 … 24.55`, ends `31.55` | overlapped, wall ≈10.27 s |
| round-3 `account_c` (edge) | `704.18 → 705.38 → … → 712.59` (≈1.21 s, 3.005 s spans) | overlapped 3–5 deep, window 11.41 s |
| ceilings `account_c` (edge) | start spread **11 ms**, end spread 19 ms | 8/8 truly parallel, wall 5.025 s |

`account_c/probe3/probe3.json:183` self-documents: *"staggered ~1.21s apart … p1 ended 707.19
AFTER p2 and p3 started => 3-way overlap … total window 11.41s"*. Ceilings-edge (simultaneous)
and round-3-edge (staggered) are different phenomena; Review B collapses them. Review A's
replacement wording matches the files exactly. **This defect is still live at
`README.md:168`**, which omits the round-3 `account_c` overlap.

### 4.4 Two smaller overstatements

- *"No file in the repo matches `4187077`, `arena-agent`, or `arena-ai-coding-agent` except the
  README/wiki text itself"* — at `d43f7be` only **`docs/wiki_home.md`** matches; `README.md`
  does not.
- Review B's own inventory row (`README.md`, `LICENSE`, `docs/wiki_home.md`) describes
  `1d32ec89`/`d43f7be`, while the content it critiques (`64 000×`, `969`, `53%`, "all
  capabilities", "ICMP blocked", "comparison surfaces", "resume mints fresh boots") is the
  **`95eb5fb3`** 180-line wiki. All seven phrases verified present at `95eb5fb3`. The critique
  is a correct retrospective on its own superseded draft, but the inventory table and the
  critique table describe two different commits.

---

## 5. Review A's only imprecisions

None are substantive.

1. **"a repository-wide `*.zip` search finds 26 files"** — true for *tracked* files
   (`git ls-files` = 26); a filesystem `find` returns **45**, because the extract work trees
   hold 19 further untracked copies. Someone re-running `find` would disagree.
2. **"Debian 12"** attributed to `02_UNPACK_REPORT.md` — that file shows Python 3.11.2 + 3.8 GiB
   + the May-11 kernel; the distro string itself is not printed.
3. **"C1, C2, C7, N2, N3 are the more defensible comparisons identified by `BENCH_REPORT.md`"** —
   the report does not name that set. It is a fair inference from the report's numpy/method
   findings, but it is Review A's synthesis.

---

## 6. Claims both reviews got right

Independently confirmed at `d43f7be`.

| Claim | Result |
|---|---|
| `forensic/evidence/` = 849 total / 843 substantive / 6 `.gitkeep` | ✅ 849 / 843 / 6 |
| No `forensic/evidence/github_connect/`; App IDs in no evidence file | ✅ absent; `docs/wiki_home.md` only |
| Persistence dirs skeleton-only | ✅ 7 `.gitkeep`, nothing else |
| 13 prompt files | ✅ |
| Characterizations = environment only | ✅ 9 `.md` + 6 `.gitkeep` |
| `CapEff=0` user / `CapBnd=000001ffffffffff` / `Seccomp=0` / `sudo -n`→root | ✅ `run4/envcheck/raw/02_isolation.txt:91-99` |
| `MemTotal 2032608 kB` · cgroup `1947172864` · FD 1024/524288 · NPROC 7917 · `/tmp` 993 MiB | ✅ |
| `boot_id 2bb79165-136a-4b63-829d-17027b0a8e40`; Agent 4 quirk `gujonb0q163l15z30yc7` | ✅ |
| OOM round-3: a 1600/1632 · b 1632/1664 · c 1624.848/1653.863 | ✅ |
| OOM ceilings: a 1632/1664 · b 1632/1664 · c 1637/1638 | ✅ |
| Code Arena: **bookworm**, `n93h7d3hf6qbdd07x3yo`, `62640bfa-cdcd-4733-a74d-1e50fa668e68`, `4034208 kB`, `3996811264`, PostgreSQL 15.16 — **five** snapshots agree | ✅ |
| numpy: brave 2.3.5 · edge 2.3.3 · **chrome UNRECORDED** | ✅ |
| `cutoff_self`: chrome `~2025-01` · brave `~mid-2025 (undisclosed)` · edge `2024-06` | ✅ |
| Round-3 chrome: IPv6 connect fails, DNS unfiltered, blocklist = metadata only | ✅ `results3.json:291,294` |
| E2B Proxy CA on guest; checked leaves GlobalSign / Sectigo | ✅ `05-tls.txt:24,37,43` |
| `INDEX_ALL.tsv` = 22 data rows; omits round-3 + benchmarks; includes nested Agent 9 row | ✅ |
| GitHub-connect, persistence budget, non-Arena control: **no primary evidence** | ✅ |

---

## 7. What neither reviewer checked

1. **Hash verification at scale.** Review B spot-checked one outer zip; Review A recomputed
   none. This report recomputed all of them:
   ```
   INDEX_ALL.tsv outer SHA-256:  rows=22  OK=22  MISMATCH=0  MISSING=0
   F_benchmark_chrome_run1.txt  fe9e2f0f…358b486  MATCH
   F_benchmark_brave_run1.txt   e1bbb513…f320a742 MATCH
   F_benchmark_edge_run1.txt    adf5f291…b22ae242d MATCH
   ```
2. **`.gitignore` contradiction.** `.gitignore` contains `*extract*/`, yet **777 files** inside
   those trees are tracked (`ceilings_prov_egress_extract_*` 162 + `code_arena_extract_*` 615).
   This is the concrete reason `find` and `git ls-files` disagree — and very likely the source
   of Review B's miscount. Neither review noticed.
3. **`CHANGELOG.md:3`** still reads *"on branch `arena/01a070c2-trixie`"* at `d43f7be`. Review A
   flagged it; Review B never mentions it. Still unfixed.

---

## 8. Assessment

### Scorecard (revised against source-verified ground truth)

| Dimension | Review A | Review B |
|---|---|---|
| Verifiable counts correct | **10 / 10** | 6 / 10 |
| Technical catches | **10 / 10** (class B present; three-way concurrency; ceilings-vs-round-3 conflation) | 6 / 10 |
| Accurate for the tree it audited | **10 / 10** (15/15 line-level) | 9 / 10 |
| Conceptual framework | 6 / 10 (wording patches, no method) | **9 / 10** |
| Honesty about limits | **9 / 10** | 8 / 10 |
| Recommendations adopted | superseded before merge | **9 / 10** |
| **Overall** | **≈ 9.1 / 10** | **≈ 7.5 / 10** |

### Reading of the two agents

- **Review A is the stronger forensic analyst.** Its precision is unusual: fifteen line-level
  claims, all exact, including a line *range* for the GitHub chapter. Its best catch — noticing
  that a verification report's own Phase-0 environment header is itself platform evidence, and
  that this makes "no class-B environment anywhere" false — requires reasoning across evidence
  tiers rather than within one file. Its only weaknesses are cosmetic (a `find`-vs-`git`
  phrasing slip, one inferred distro string) and it produced replacement wording rather than a
  method.
- **Review B is the stronger architect who did not check its own sums.** The evidence
  hierarchy, the "a hash proves integrity, not truth" table, and the offline-reproducible vs
  requires-live-session split are the best structural material in either review, and they are
  what shipped in `1d32ec89`. But it wrote "21" while listing six directories summing to 24, and
  it denied class B's presence without grepping the reports tree for the class-B kernel stamp.
  Both are unforced errors, not reasoning failures — a sum it did not perform and a grep it did
  not run.

**Put plainly: Review A is more accurate and more honest; Review B is more useful.** Review A
tells you what is true. Review B tells you how to keep the repository from becoming untrue
again — and its advice was acted on. For adjudicating the archive, Review A. For governing it,
Review B.

---

## 9. Clearly sayable / not sayable

**Clearly established**

- `zips/` = 24 canonical archives at every commit checked; 26 tracked `*.zip` repo-wide.
- Review A audited `123965e3`; all 15 of its line-level claims verify against that commit.
- Review B's "21" is wrong at every commit; its "no class-B raw session" is false.
- A class-B-fingerprinted environment exists at `02_UNPACK_REPORT.md` §1 Phase 0.
- Concurrency genuinely splits three ways; ceilings-edge ≠ round-3-edge.
- No GitHub-connect, persistence-campaign, or non-Arena-control evidence exists in the repo.
- All 22 indexed outer zip hashes and all 3 benchmark hashes verify.
- `docs/wiki_home.md` and `README.md` at `d43f7be` are the honest rewrite; root `WIKI_HOME.md`
  and `README_NEW.md` were deleted by the PR #6 merge.

**Not established from here**

- Whether the GitHub App claims are true *of the real world*. The identity and token class are
  now corroborated (§9b), but **App id `4187077`, the grant list, the `workflows` propagation
  lag, and the absence of `administration` remain unestablished** — `gh api user` and the
  installation endpoint both refuse this token, so grants could not be read.
- Whether round-2 DNS-filtering reports or round-3 "no blocklist" reflects current platform
  behaviour. Both are in the tree; both reviews correctly decline to promote either.
- The OOM mechanism (child cgroup kill vs `global_oom` / `CONSTRAINT_NONE`). Unresolved.
- Any current live sandbox behaviour. This is an archive; every runtime figure is a historical
  sample.
- The exact PR #6 merge mechanics. `merged_at` is `17:57:05Z` with `merge_commit_sha`
  `d43f7beb`, but `gh pr list` displayed `17:08:44`; commit timestamps were treated as
  authoritative and the discrepancy is left unresolved.

---

## 9b. New primary evidence found while committing this report

Both reviews state that no GitHub-connector evidence exists. Committing this file produced one
piece of previously unrecorded evidence — in the *environment*, not the repository:

```
$ cat .git/hooks/commit-msg
#!/bin/sh
MSG_FILE="$1"
TRAILER='Co-authored-by: arena-agent <297053741+arena-agent@users.noreply.github.com>'
grep -Fqx "$TRAILER" "$MSG_FILE" 2>/dev/null && exit 0
printf '\n%s\n' "$TRAILER" >> "$MSG_FILE"
```

An untracked `commit-msg` hook appends `Co-authored-by: arena-agent
<297053741+arena-agent@users.noreply.github.com>` to every commit. Corroborating details:

- Commits on `main` are authored by `arena-ai-coding-agent[bot]
  <298482267+arena-ai-coding-agent[bot]@users.noreply.github.com>`.
- `gh api user` returns `403 Resource not accessible by integration`; `gh api
  repos/anacondy/Trixie/installation` returns `401 A JSON web token could not be decoded`.
  Both are the signature of a GitHub App **installation** token rather than a user PAT.
- The credential is Arena-issued, with a non-GitHub-native prefix (`arena-egress-…`), not a
  `ghp_` / `ghs_` token.

**What this does and does not establish.** It confirms that an `arena-agent` identity and an
`arena-ai-coding-agent[bot]` author both exist in the live toolchain, and that this session
authenticates as a GitHub App installation. It does **not** confirm App id `4187077`, the
grant list, the `workflows` propagation lag, or the absence of `administration`. The numeric
IDs also differ (297053741 vs 298482267), so `arena-agent` and `arena-ai-coding-agent[bot]` are
distinct accounts — consistent with the deleted `WIKI_HOME.md` chain, but not proof of it.

Because `.git/` is never tracked, this evidence cannot be archived into the repository. It is
recorded here so it is not lost, and it slightly narrows the "not established" entry for
GitHub connector permissions from "no evidence at all" to "identity and token class
corroborated; grant list still unestablished."

---

## 10. Defects remaining in the shipped docs

1. `CHANGELOG.md:3` — stale branch `arena/01a070c2-trixie`.
2. `README.md:168` — omits the round-3 `account_c` staggered-overlap result and lumps
   ceilings-edge in as "parallel".
3. `.gitignore` declares `*extract*/` while 777 extract-tree files are tracked.
4. `forensic/reports/summary/INDEX_ALL.tsv` — omits round-3 and benchmark rows; double-counts
   the nested Agent 9 archive.
5. `forensic/reports/round1_environment/02_UNPACK_REPORT.md` §1 — the only class-B-shaped
   environment in the tree; should be labelled in place as the verifier's own sandbox.
