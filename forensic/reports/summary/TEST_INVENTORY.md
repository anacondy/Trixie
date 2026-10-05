# Test inventory — what we tested, why, what it cleared (2026-09-08)

Method note: "unclear then" = the specific doubt that motivated each test; "cleared" = what the test empirically settled. Tally at the end is my count of discrete questions.

## A. Test families

| # | Test (when) | Why / unclear then | What it cleared | Status |
|---|---|---|---|---|
| 1 | Round-1 environment characterization ×9 (3 browsers × 3 accounts, 2026-09-04) | No public sandbox spec; is code really executed? what vendor/primitive/resources? | E2B Firecracker microVM measured in-guest (kvm, e2b.local, E2B_* vars); full class-T envelope (2 vCPU Xeon 2.60, 1985 MiB / cgroup 1857 MiB, no swap, 25 GB disk, fd 1024, NPROC 7917); toolchain pin; egress open w/ transparent proxy | cleared |
| 2 | Round-1 forensic audit (Appendix C) | can the 9 agent reports be trusted? | 363 SHA-256 across 17 manifests, 0 mismatches; outer SHAs 9/9; disagreements are findings not corruption | cleared |
| 3 | Forensic unpack + overload adjudication (Appendix D) | what causes "The AI service encountered an error" — VM class? timeouts? | NOT timeout, NOT VM class; turn-level service failure correlated with +51k-line workspace diffs, gone after shrinking; "180 s timeout" was confabulated (real 30/1800); boot_id template-constant; second VM class B found | cleared |
| 4 | B persistence TURN 1 (2026-09-04/05) | is the persistence contract real? is the 128 MB budget enforced? | budget enforced by dropping files (verbatim UI message at 140 MiB); markers planted; agent rightly refused to simulate turns 2/3 | partial — turns 2/3 pending |
| 5 | Round-2 A provenance ×3 fresh | is the template ID Arena-specific? BUILD_ID? VM-class lock? | NO — nlhz… is E2B's shared code-interpreter base; BUILD_ID f34a5416; boot_id 2bb79165 template-constant; class T locked per run | cleared |
| 6 | Round-2 C egress ×3 fresh | where does filtering happen? MITM? | transparent proxy quantified; DNS-level blocks (few domains); no TLS interception; SSH-22 banner byte-level; standardized bandwidth | cleared |
| 7 | Round-2 D ceilings ×3 fresh | exact OOM threshold? fd/fork ceilings? real disk speed? SMT? | OOM anon ceiling [1624.85,1653.86] MiB, SIGKILL child-scoped, session survives; fork EAGAIN at 7914; fds 1024→524288; SMT siblings one physical core; cpu.max unenforced | cleared |
| 8 | Round-2 E Code Arena + capture round (5 snapshots) | same environment as Agent Mode? | NO — template n93h7d3hf6qbdd07x3yo, class C (4 vCPU, ~3.85 GiB, Mar-13 kernel, BUILD_ID 62640bfa), Postgres; resume mints NEW sandbox IDs (fresh boot); /app YES /tmp NO / DB rows YES persistence; provider badged post-vote (Max via Moonshot) | cleared |
| 9 | Round-2 F benchmarks ×3 fresh | are performance numbers comparable? same hardware? | convergent bands ⇒ same hardware class; numpy drift (2.3.5 vs 2.3.3) confounds C4; outliers itemized; chrome numpy unrecorded (honesty gap) ⇒ C3–C6 confounded | cleared w/ confounds |
| 10 | Round-3 calibrated probe3 ×3 + calibration analysis | same model each session? are connect()-probes trustworthy? what explains variance? | cutoffs DIVERGE (edge 2024-06, chrome ~2025-01, brave ~mid-2025) ⇒ heterogeneous routing; A1/A2 facts converge, A3 honest "cannot verify"; connect() hijacked by accept-all gateway; ~53% ambient sidecar CPU explains variance; B1 CPU→speed causation falsified; local PQC profile | cleared |
| 11 | Reorg Bursts 0–19 + PR #3/#4 | can evidence land in the repo intact? | PR #3 cabc0c0, PR #4 77ad2ea merged verified; INDEX/ACCOUNTS/CHANGELOG consistent; zero strays; vm_class column closed (T/B/C) | cleared |
| 12 | GitHub-connect characterization (Debloat, API-verified) | what does connect grant the agent? | contents+pull-requests+metadata; workflows = net-diff rule (branch AND tag pushes refused iff delta adds .github/workflows); no administration; bot created AND merged PR #1; egress anomaly (curl 000) left open | cleared except egress |
| 13 | Disclosure-mechanism web fetches | when are model names revealed? | comparison surfaces reveal names only after completion/vote; hidden-phase votes rank only; Agent Mode no-naming is platform boilerplate | cleared |
| 14 | THIS TURN: sleep-limit experiments + Probe G control | min/max sleep? does plain egress still hold? | min 0 (µs fractions OK, negative rejected); binary unbounded (inf accepted); per-call cap 1800 s (kill demonstrated at 12 s; 600 s field-proven in Debloat screenshots); plain egress 200/200 <0.1 s | cleared; background-lifetime canaries pending |

## B. Answered questions (35)

1. Code really executes in real VMs (E2B Firecracker/KVM), not simulated.
2. Class-T resource envelope (2 vCPU, 1985/1857 MiB, no swap, 25 GB, fd/NPROC limits).
3. Egress policy: open TCP 80/443, transparent proxy, no MITM, ICMP blocked, IPv6 unrouted, few DNS blocks.
4. Toolchain pin (Py 3.13.14, Node 20.20.2, image numpy 2.3.5).
5. Template ID NOT Arena-specific (shared E2B base; /.e2b vs env var can disagree).
6. BUILD_ID/boot_id fingerprints + image build lineage.
7. VM classes not universal (T, B in Agent Mode; C in Code Arena).
8. Evidence authenticity (363 SHAs, 0 mismatches; outer 9/9).
9. "AI service error" ≠ timeout ≠ VM class; diff-size correlation; 180 s confabulation.
10. Snapshot budget enforced by dropping files (verbatim platform message).
11. Exact OOM ceiling + child-scoped SIGKILL semantics.
12. Fork/fd ceilings live-confirmed.
13. SMT topology (siblings, one core) + scaling ratios.
14. cpu.max unenforced under burn.
15. Code Arena = different template + class C + Postgres (per-product templates proven).
16. Resume/turn = fresh boot, not unfreeze (new sandbox IDs, uptime reset).
17. Code Arena persistence split (/app YES, /tmp NO, DB rows YES).
18. Model-name disclosure only post-completion/vote on comparison surfaces.
19. Heterogeneous per-session model routing (divergent cutoffs).
20. Calibration facts converge; honest "cannot verify" as a replicable negative result.
21. connect()-based reachability probes untrustworthy (accept-all gateway).
22. Variance explainer (ambient sidecar steal); B1 causation falsified.
23. F benchmarks comparable under fixed protocol; confounds identified.
24. GitHub-connect grant set (contents/PRs/metadata; no administration).
25. Workflows net-diff push rule.
26. Connected agent can create AND merge PRs.
27. Repo pipeline integrity (PRs #3/#4 verified merged).
28. Sleep minimum = 0 (fractional µs OK; negative rejected).
29. Sleep binary unbounded; per-call cap 1800 s (demonstrated + field-proven ≥600 s).
30. Plain-session egress re-confirmed today (200/200).
31. Burst-20 placement byte-identical on PR #5 (branch raws sha-match staged hashes; BENCH_REPORT cross-checked line-by-line against raws).
32. Background processes die across user turns on this platform (canaries dead at next turn, no marker).
33. GitHub-connect two-layer token model (sandbox token contents:write; platform layer holds pull-requests:write; workflows refusal = GitHub-standard scope rule).
34. Full GitHub App identity chain + app-level permission set (API /apps/arena-ai-coding-agent + developer account; events pull_request/push).
35. Permission propagation lag documented: app gained workflows:write 2026-09-01T17:53Z; our Debloat measurement caught the pre-sync installation; user acceptance 2026-09-08 synced it.

## C. Open questions (13 listed; #3 cleared => 12 open)

1. Connect-session egress anomaly → Probe G fresh-connected run pending (control done).
2. B TURN 2/3: cross-turn & cross-session survival + cross-account control (user-triggered).
3. ~~Background-process lifetime horizon~~ **CLEARED 2026-09-08 -> answered #32.** Both canaries dead at the next turn (registry not_found, no sleep in pgrep, no 1 h marker at +17 min) => killed at the turn boundary; horizon = one turn, same as Arena.
4. Per-turn wall-clock budget (unpublished; a Debloat turn ran >~20 min; ceiling unknown).
5. Chrome F numpy version (honesty gap) ⇒ C3–C6 confounded until a pinned-numpy re-run.
6. Post-merge capability drift in the old connected session (optional third cell of Probe G).
7. vanilla + react-vite Code Arena templates unmeasured.
8. Host tenancy / CPU pinning / host SMT policy (side-channel exposure) unknown.
9. Sandbox TTL / idle-timeout numbers unpublished and unmeasured.
10. Whether the model draw correlates with account/browser/VM-class draw (identities hidden by design).
11. Round-3 characterization write-up into repo docs (pending).
12. Section E must still run in an arena.ai/code session (standing requirement).
13. Probe H (post-accept): does a fresh connected session now push a .github/workflows delta successfully (sandbox token inherits installation grants) or still refused (scoped subset)?

**Tally: 35 answered, 12 open** (2026-09-08, permission-surface turn).
