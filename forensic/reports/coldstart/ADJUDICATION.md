# Adjudication — "Trixie cold-start forensic review" (pasted 2026-09-16, vs bd92c07)

Method: every load-bearing claim re-checked against `main` raw + GitHub API this turn; D5 timelines recomputed from the raw timestamp files; README/INDEX checked both at `bd92c07` and at current main. Verdicts: **C** = confirmed by my own recomputation, **S** = stale (true at bd92c07, fixed on main after), **W** = wrong even at the snapshot, **A** = accepted on consistency with prior verified arcs.

## Timeline fact that re-frames the whole review
`bd92c07` = PR #5 merge, 2026-09-08T16:46:47Z; README there = 77-line version with the `skeleton | skeleton` row. The 293-line "honest claim ledger" README rewrite landed 66 minutes later (`1d32ec89`, 17:52Z) and already contains — in near-identical wording — the review's §3.1 D5 table, §3.3 no-synthesis note, INDEX gap note, manifest-dialect warning, persistence emptiness, concurrency=Low rating and the boot_id headline. So most of the review's §6 substantive findings were acted upon before this paste arrived; only the *report-form* synthesis and the INDEX round-3 rows remain open.

## Section-by-section

| Review claim | Verdict | Evidence this turn |
|---|---|---|
| §2 round-3 manifests + hash-of-hashes recompute; "sorted"=name-sorted caveat | C | README §208 + UNPACK_REPORT carry the same caveat; dialects confirmed in tree |
| §2 "10 files listed in run9's manifest are absent" | C | my recompute: 90 entries, 81 committed, **exactly 10 missing**, all `.npm/_cacache|_logs|_update-notifier` noise (intentional-looking exclusion, undocumented) |
| §2 "manifest files hash themselves" | A | consistent with UNPACK_REPORT SELF-SHA256 note |
| §3 byte-identical env block, boot_id `2bb79165…` constant across sessions/days, sandbox_id varies | C/A | matches prior arc (TURN-1 boot_id = round-3 boot_id; resume re-mints sandbox_id) |
| §3 connect() trap + TTFB methodology | A | matches round-3 verified findings |
| §6(a) chrome F8 "cap = 1" refuted by its own d5 files; brave opposite; nobody saturated a cap; dispatch gap varies 4× | **C, exact** | my recompute: chrome gaps 1.688–2.370 (mean 2.002), wall 18.04 vs serial 32, max simult 3; brave gaps ~0.46, wall 10.27 vs 56, max 8; edge gaps ~1.20, wall 11.40 vs 24, max 3. Verbatim verdicts located: a_16.txt F8 "cap = 1 concurrent exec. grade=MEASURED"; b result_probe3.json D5-CONC "concurrent; no cap at 8" |
| §6(a) "no report anywhere acknowledges this" | S | true at bd92c07 (reports/round3 = UNPACK_REPORT only, still true); but current README §3.1 acknowledges the contradiction verbatim since 17:52Z |
| §6(b) persistence empty | C | tree: characterizations/persistence/.gitkeep only; README §98 concedes |
| §6(c) platform attribution operator-asserted; identity purely E2B | C | b_json `"surface": "arena.ai Agent Mode"` is free text; E2B_* vars are the only machine identity; matches standing rule |
| §6(d) OOM ceiling session-dependent, memory.max is the constant | A | matches round-3 arc (ceiling cache-pressure-dependent; account_c caveats) |
| §6(e) benchmark confounds | C | BENCH_REPORT line 52/128 numpy UNRECORDED (chrome); N2 same-wheel note; unit caveats present |
| §6(f) README skeleton row, round-3 in no table, INDEX 22 rows + 1 dead link | S | all true at bd92c07; README fixed 17:52Z; INDEX now 23 rows, 0 dead links; **but round-3 zips + F files still absent from INDEX (0 mentions)** — sub-point still open |
| §6(g) "Section E NOT PERFORMED on every account… nothing characterises the Code Arena sandbox" | **W** | true for the round-prompt zips, false for the repo: `forensic/evidence/code_arena/{account_a,b,c}` + INDEX code_arena ×6 + class-C fingerprint (4 vCPU, 4034208 kB, Mar-13 kernel) exist at bd92c07. Review's §1 layer table omits the code_arena layer entirely. Only vanilla/react-vite templates remain unmeasured |
| §7 D5 not reproducible (no shared script, 3 sleep values) | C | tree: no shared D5 script; sleeps 4/7/3 |
| §8 "cross-account round-3 synthesis missing" | S/partial | reports/round3 still UNPACK-only; README §3.1 now plays the synthesis role in narrative form |

## New reinforcing details the review missed
1. Brave's `25_D5_concurrency.txt` **ends in its own crashed Python traceback** — the span analysis never ran; its conclusion survived only in result_probe3.json. Sharpening of "the ledger is written and nobody reads the raw numbers back": in brave the raw file doesn't even contain the analysis.
2. Chrome's F8 `falsifying_out` contains an internally false sentence verbatim: "No pair of calls shares a 4 s window" — A=[33.491,37.503] and B=[35.861,39.871] share 1.64 s.
3. Hypothesis for the unexplained 4× dispatch-gap spread (0.46/1.20/2.00 s): the gap is agent-runtime/model dispatch behaviour per session (Agent Mode routes multiple models), not a scheduler-cap difference. Label: hypothesis, untested. Testable: same shared D5 script, same sleep, across fresh sessions; repeat twice within one session to separate runtime vs model variance.

## Post-review material outside its scope
- PR #6 docs merge; preview-calibration layer (2026-09-15/16): 3 bundles + human-observed viewer sheets (Trixie commits 43998e486e, 1333e3acb1).
- Reset-behaviour evidence adjacent to the persistence gap: timekeeper session showed apt-installed Wine removed by a reset and an exec bit dropped — intra-session reset behaviour, still NOT cross-session persistence.

## Recommended next repo actions
1. INDEX commit: add round-3 ×3 zips + F-benchmark ×3 files (closes last of §6(f)).
2. Commit `forensic/reports/round3/SYNTHESIS.md` (data-form of README §3.1 + per-account reconciliation).
3. D5 re-run: one shared script, sleep ≥ 20 s, 10 calls, all three fresh sessions (closes §6(a)/§8 prescription).
4. Cross-session persistence round — still the single biggest gap; unchanged.

## Addendum — D5 shared-script re-run executed (2026-09-24, user-ran, three FRESH sessions)
Sessions (user-stated browsers): Chrome 01a0d44a-3bd7-73e0-b055-25f6e0416481 · Firefox 01a0d449-a9e3-72c8-b82e-f48aac1d4ea7 · Brave 01a0d449-6e56-7d04-8e02-b2f42c56d65d. Script = 10 parallel `sleep 20` tool calls in one message (serial prediction 200 s).

| Session | stagger span | dispatch gaps | max simultaneous | wall |
|---|---|---|---|---|
| Chrome | 0.10 s | 0.000–0.082 s | **10** | 20.10 s |
| Brave | 3.44 s | ~0.47 s | **10** | 23.44 s |
| Firefox | 2.0 s then +126.5 s | ~0.35 s | 8 (agent split 8+2) | 148.74 s |

Verdicts: (1) **No concurrency cap ≤ 10 exists** in any session — wall ≈ 20–23 s vs serial 200 s; combined with old brave 8/8, any cap is >10; old chrome F8 "cap = 1 SERIAL" is now refuted by fresh Chrome itself (same browser, 0.01 s cadence vs the old 2.0 s). (2) **Dispatch cadence is per-session, not per-browser**: chrome 2.0 s (old) vs 0.01 s (new); firefox 0.35; brave 0.47; old edge 1.2 — supports the APPENDED19 hypothesis (cadence = session-level model/scaffold behaviour, i.e. routing heterogeneity), upgrades concurrency category from Low to Medium-High ("cap ≥ 10 demonstrated; cadence heterogeneous"). (3) Firefox's agent split the batch 8+2 (~2 min apart) — "issue 10 in one message" not always followed; per-session behavioural divergence is itself routing-heterogeneity evidence. (4) nproc=2 (chrome, firefox); brave omitted nproc obeying "no other tools" (harmless; template nproc known = 2). Review recommendation #3 is thereby CLOSED as prescribed.
