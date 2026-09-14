# Measuring a black box with a stopwatch: what the Trixie repository actually proves about Arena.ai's sandboxes

*A repository-only audit of `anacondy/Trixie` at pinned commit `d43f7beb91cab26f3437d1762f97d36675654884`.*

---

## Audit note

This article was produced from the repository `https://github.com/anacondy/Trixie` only, pinned at commit **`d43f7beb91cab26f3437d1762f97d36675654884`** (merge of PR #6, authored 2026-09-08 17:57:04 UTC, branch `main`, clean working tree, 70 commits, no tags). No GitHub wiki pages, issues, pull-request discussions, screenshots, external documentation, or prior knowledge were used. Every number below is traceable to a file in the pinned tree; permalink citations point at that commit.

During the audit I re-hashed, but never executed, archive payloads. Static inspection only: `sha256sum`, `unzip -l`/`-t`, manifest re-verification, and parsing of committed JSON/TXT. My independent checks: all 22 archives listed in `forensic/reports/summary/00_ROOT_INVENTORY.txt` re-hash MATCH; all 3 round-3 archives re-hash MATCH against `forensic/reports/round3/UNPACK_REPORT.md`; all 3 benchmark texts re-hash MATCH against `forensic/reports/benchmarks/BENCH_REPORT.md`; per-file manifests re-verified OK for ceilings (17/18/1 files), provenance-edge (5/5), and round-3 chrome/brave/edge (26/32/38); the round-3 chrome hash-of-hashes reproduces; the round-3 edge hash-of-hashes reproduces in listed filename order (not sort-by-hash, exactly as the unpack report warns). Two caveats found by me, not by the repo: the brave round-3 hash-of-hashes did not reproduce under either of my two join methods, and the ceilings manifests use paths from the original extraction work tree (`extract/Ceilings_1_chrome.zip/…`) that do not resolve inside `forensic/evidence/` without stripping a prefix.

**Citation convention:** repository paths below are given relative to the repo root; each one resolves as a permalink of the form `https://github.com/anacondy/Trixie/blob/d43f7beb91cab26f3437d1762f97d36675654884/<path>`. For example, the guest-lock raw cited most often below is [forensic/evidence/environment/account_a/run1/01_runtime.txt](https://github.com/anacondy/Trixie/blob/d43f7beb91cab26f3437d1762f97d36675654884/forensic/evidence/environment/account_a/run1/01_runtime.txt), the identity comparison is [forensic/reports/summary/ID_COMPARISON_ROUND2.md](https://github.com/anacondy/Trixie/blob/d43f7beb91cab26f3437d1762f97d36675654884/forensic/reports/summary/ID_COMPARISON_ROUND2.md), and the benchmark report is [forensic/reports/benchmarks/BENCH_REPORT.md](https://github.com/anacondy/Trixie/blob/d43f7beb91cab26f3437d1762f97d36675654884/forensic/reports/benchmarks/BENCH_REPORT.md).

---

## 1. What this repository is

Trixie is a forensic evidence archive: three personal accounts, three browsers (Chrome, Brave, Edge), and several rounds of "characterize the sandbox you are running in" prompts, whose raw command transcripts, manifests, and hash files were collected into one git repository. The repo self-describes as "an empirical characterization of Arena.ai's sandboxes" and as independent research, not affiliated with Arena/LMArena (`README.md`, `docs/wiki_home.md`). It is Apache-2.0 licensed, copyright line "Copyright 2026 Anuj Meena" (`LICENSE`).

Treat that self-description as narrative. What the tree actually contains is checkable: 1,709 files (my count, excluding `.git`), about 14 MB, of which 849 files sit under `forensic/evidence/`, plus 24 canonical evidence archives under `zips/`, 13 prompt files under `prompts/`, and 19 verification reports under `forensic/reports/`.

One vocabulary note before anything else: the labels **T**, **B**, **C**, and **NEW** are repository-local analytical classes defined in the repo's own instruments (`prompts/round3/FalsificationPROMPT.md` defines T and B by four markers each). They are not official provider product classes, and nothing in this tree shows a provider using them.

**Evidence strength: NARRATIVE ONLY for the self-description; PRIMARY/REPEATED for the inventory facts above.**

Sources: `README.md`; `docs/wiki_home.md`; `LICENSE`; `ACCOUNTS.md`; `CHANGELOG.md`.

---

## 2. Evidence hierarchy and collection method

The repo's own rules are committed as instruments, which is what makes it auditable (`prompts/forensic/FORENSIC_UNPACK_PROMPT.md`):

- Raw command output captured by shell redirection into `.txt` — "zero LLM in raw files" is the stated design (`prompts/round3/FalsificationPROMPT.md`, output section).
- Every tree ships with a SHA-256 manifest and, where possible, a hash-of-hashes; F-benchmark runs ship as single self-describing texts hashed whole (`forensic/reports/benchmarks/BENCH_REPORT.md` §6).
- Archives are unpacked and hashed, never executed — a rule stated in `README.md`, the unpack prompt ("Never execute any script, binary, or .sh/.py file found inside any zip"), and every verify report.
- Identical prompts across three accounts; disagreement is kept, not averaged (`README.md`, "How to read this repo").
- Falsification controls are built into the round-3 instrument: B2 (prove your probe works before claiming "blocked"), B3 (prove your probe fails against a target that should fail before claiming "works"), C7 (TCP `connect()` lies under a transparent proxy — measure TTFB, not RTT) (`prompts/round3/FalsificationPROMPT.md`).

For this article I apply a four-level hierarchy: (a) primary raw artifacts (redirected transcripts, JSON, snapshots), (b) integrity artifacts (manifests, hash reports — these establish file integrity, not the truth of the underlying output), (c) derived analysis (reports and tables computed from raws), (d) narrative (agent-authored reports and README/wiki prose — claims that need corroboration).

**Evidence strength: PRIMARY/REPEATED for the instruments; the method description above is itself narrative until you re-run it — which I did for the integrity layer.**

Sources: `prompts/forensic/FORENSIC_UNPACK_PROMPT.md`; `prompts/round3/FalsificationPROMPT.md`; `prompts/round2/README.md`; `forensic/reports/benchmarks/BENCH_REPORT.md`.

---

## 3. What is actually in the tree

| Path | Contents (my count) | Status |
|---|---|---|
| `zips/environment/` | 9 archives ("Agent 1–9", three per account) | present |
| `zips/ceilings/`, `zips/egress/`, `zips/provenance/`, `zips/code_arena/` | 3 archives each (round 2) | present |
| `zips/round3/` | 3 archives ("probe3_evidence") | present |
| `zips/persistence/`, `zips/benchmarks/` | `.gitkeep` only | **empty, reserved** |
| `forensic/evidence/` | 849 files, of which 6 are `.gitkeep` | present |
| `forensic/evidence/persistence/` | `.gitkeep` only | **empty** |
| `forensic/evidence/github_connect/` | — | **absent (no directory at all)** |
| `characterizations/environment/` | 9 agent-authored reports | present |
| `characterizations/{ceilings,egress,provenance,code_arena,benchmarks,persistence}/` | `.gitkeep` only | **empty** |
| `prompts/` | 13 files (round1, round2, round3, forensic) | present |
| `forensic/reports/` | 19 files (unpack/verify/index) | present |
| `ceilings_prov_egress_extract_20260904_214946/`, `code_arena_extract_20260905_074645/` | audit work trees kept "for humans" | present |

Archive accounting: 26 zip *files* total — 24 canonical under `zips/` plus 2 copies of one nested archive (`environment_evidence_20260904T142002Z-2576.zip`, shipped inside "Agent 9 edge" and retained as an inert file). There are also 19 zip-named *directories* (extraction trees inside the two work-tree folders) that are not archives. Eighteen `.gitkeep` placeholders mark reserved-but-empty directories.

Integrity state, independently re-verified by me at the pinned commit: the 22 archives covered by `00_ROOT_INVENTORY.txt` all re-hash to their committed SHA-256 values; the three round-3 archives and three benchmark texts re-hash to the values in their placement reports. The round-1 cross-check report records 19 internal-manifest verifications: 18 PASS and 1 PARTIAL (the Agent 9 documentation manifest: 8 entries OK, 0 FAIL, 82 entries pointing at files documented as deliberately deleted/ephemeral) (`forensic/reports/round1_environment/02_CROSSCHECK.txt`; `forensic/evidence/environment/account_c/run9/Agent 9 edge/documentation/03_DELETED_OR_EPHEMERAL_ARTIFACTS.md`). Note that the README's verification table summarizes round 1 as "363 SHA-256 entries / 17 manifests, 0 mismatches" — I could not find those exact counts in the committed round-1 reports; the committed cross-check is the file to quote.

**Evidence strength: PRIMARY/REPEATED (inventory and hashes reproduce offline).**

Sources: `forensic/reports/summary/00_ROOT_INVENTORY.txt`; `forensic/reports/round1_environment/02_CROSSCHECK.txt`; `forensic/reports/round3/UNPACK_REPORT.md`; `forensic/reports/benchmarks/BENCH_REPORT.md`; `ACCOUNTS.md`.

---

## 4. Agent Mode guest — repository-local T label

Every Agent Mode session in this corpus that recorded an environment lock measured the same profile. Across round-1 environment raws (9 archives), round-2 provenance probes (3), round-3 locks (3), and F-benchmark headers (3), the lock repeats:

| Item | Value | Firsthand source (example) |
|---|---|---|
| OS | Debian GNU/Linux 13 (trixie), `DEBIAN_VERSION_FULL=13.6` | `forensic/evidence/environment/account_a/run1/01_runtime.txt` |
| Kernel | `6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026` | same, and `forensic/evidence/round3/account_b/probe3/08_uname_a.txt` |
| Python | 3.13.14 | `forensic/evidence/provenance/account_c/raw_evidence_2026-09-04T2037Z_instance2.txt` |
| CPU | 2 vCPU, `Intel(R) Xeon(R) Processor @ 2.60GHz`, siblings `0-1` on one core | `forensic/evidence/environment/account_c/run7/envcheck/raw/run_20260904T1116Z_original/01_system.txt` |
| Memory | `MemTotal 2032608 kB`; cgroup `/user` `memory.max = 1947172864`; no swap | `forensic/evidence/round3/account_a/probe3/05_cgroup_limits.txt` |
| Disk | `/dev/root` 25G ext4; `/tmp` tmpfs ~993M | `forensic/evidence/round3/account_a/probe3/04_df_root.txt` and `08_d2_disk.txt` |
| Host markers | hostname `e2b.local`; `E2B_SANDBOX=true`; `/.e2b` = `ENV_ID/TEMPLATE_ID nlhz8vlwyupq845jsdg9`, `BUILD_ID f34a5416-ef30-4cb7-8e18-0fdecd6eb529` | `forensic/evidence/provenance/account_b/prov_probe.txt` |

Virtualization: a KVM guest, not a container. Committed raws show `systemd-detect-virt` → `kvm`, `/proc/cpuinfo` "Hypervisor vendor: KVM", kernel command line with `virtio_mmio.device=…` and `root=/dev/vda`, no `/.dockerenv`, and a boot log whose ACPI tables carry OEM id `FIRECK` (`forensic/evidence/round3/account_a/probe3/06_cpu_topology.txt`; `forensic/evidence/round3/account_a/probe3/16_falsifications.txt`; `forensic/evidence/environment/account_a/run5/env-probe/runs/20260904T134652Z_i80n46q8w7lm0xch991wu/02_isolation.txt`). "Firecracker-class" is an interpretation from that OEM string — the raws show `FIRECK`; they do not name a product.

Privilege, stated carefully because the distinction matters:

- The interactive user is `uid=1000(user)`, group `sudo`, and `sudo -n true` exits 0 — passwordless sudo works (`forensic/evidence/environment/account_a/run4/envcheck/raw/04_users.txt`).
- The user shell reports `CapEff: 0000000000000000` (empty effective set) and `CapBnd: 000001ffffffffff` (full bounding set); under `sudo`, `CapEff` reads `000001ffffffffff`; PID 1 reads `000001ffffffffff`; user `Seccomp: 0` (`forensic/evidence/environment/account_a/run4/envcheck/raw/02_isolation.txt`).

Observation: those are the measured bytes. Interpretation (and the reason the repo keeps warning about it — its own round-1 narrative report quoted `000001ffffffffff` as "capabilities minimal" without noting the value came from `/proc/1/status`): a full bounding set plus passwordless sudo is *not* the same as an ordinary-user process holding capabilities, and `CapEff` is not `CapBnd`.

The "T" letter itself comes from the repo's round-3 prompt, which classifies T by four markers (trixie / Python 3.13 / the Jul 17 2026 kernel stamp / 2032608 kB) and reports round-3 results as "4/4 T markers present, 0/4 B markers" (`forensic/evidence/round3/account_a/probe3/results3.json`). It is a repo-local label, nothing more.

**Evidence strength: PRIMARY/REPEATED.**

Sources: `forensic/evidence/environment/` (9 run trees); `forensic/evidence/provenance/`; `forensic/evidence/round3/account_{a,b,c}/probe3/`; `forensic/evidence/benchmarks/` (environment headers).

---

## 5. Identity signals — what changes and what does not

**Changes every session:** `E2B_SANDBOX_ID`. The committed index lists 18 distinct sandbox ids across the nine round-1 environment runs alone (`forensic/reports/summary/INDEX_ALL.tsv`); add the provenance, Code Arena, round-3, and benchmark sessions and the corpus holds more than 30 distinct ids, with every later round adding new ones (round-3: `i3xgkkubxoiw2bi4vlqkx`, `i8h6fqsmx2z4wfzs4klkk`, `ids70tfd987wffpjczbai` in the three `results*.json`).

**Does not change, ever, in this corpus:** `/proc/sys/kernel/random/boot_id` = `2bb79165-136a-4b63-829d-17027b0a8e40`. It appears in 54 committed files spanning round 1, round 2 provenance, and round 3, across all three accounts (my grep at the pinned commit).

The strongest single identity dataset is the edge provenance capture, which includes a measured sandbox recreation *inside* one audit: the sandbox id changed `ia4a7jw0xcyn756c09iwm` → `i5ppm7iw8cfa89mb7ezsm`, `/proc/uptime` reset, and boot_id **did not change**. The same capture falsified two of the author's own earlier claims: `E2B_TEMPLATE_ID` changed mid-session to `wk9vh0w7zre9vbcia51p` and reverted, while `/.e2b` never moved; and `uptime -s` drifted ~6 minutes within one boot (`forensic/evidence/provenance/account_c/raw_evidence_2026-09-04T2037Z_instance2.txt`; summary in `forensic/reports/summary/ID_COMPARISON_ROUND2.md`).

Other identity observations, with their session scope:

- In-guest services carry **2026-07-23** start timestamps in sessions run on 2026-09-04 — e.g. `envd ActiveEnterTimestamp=Thu 2026-07-23 18:05:37 UTC` against a session uptime of minutes. Seen in edge provenance (single detailed capture) and corroborated by chrome run 4 and edge run 7 service listings (`forensic/evidence/environment/account_a/run4/envcheck/raw/08_persistence.txt`, `.../run7/envcheck/notes/19_services_nohup.txt`). This is *consistent with* snapshot-resume of a long-lived image; it is not a direct measurement of the resume mechanism.
- `/etc/machine-id` = `67549745dd1a4564be928e47dca271fd` in the same edge capture — single session in this tree.
- Top-level mtimes cluster at 2026-07-04/13/23 while `/tmp` is session-fresh — single detailed capture (same file). The repo's own C1 trap note says mtimes are restore-stamped and must not be trusted as write times (`prompts/round3/FalsificationPROMPT.md`).
- One quirk: chrome run 4 recorded `template_id: gujonb0q163l15z30yc7` as "this build's env" next to the measured `nlhz8vlwyupq845jsdg9` — recorded as an anomaly, not resolved (`forensic/evidence/environment/account_a/run4/README_START_HERE.md`).

Interpretation, kept at interpretation strength: a boot_id constant across accounts, rounds, and a measured recreation is *consistent with* an image-baked identifier, and the repo's own checklist treats it that way ("C2 boot_id is template-constant"). The files cannot distinguish "baked into the image" from any other mechanism that survives recreation — that mechanism is not measured here. Per-session uptime of tens of seconds at first command (22.26 s in round-3 chrome's lock) is an observation about clock state, not about host tenancy.

**Evidence strength: PRIMARY/REPEATED for sandbox-id-per-session and boot_id-constant; PRIMARY/SINGLE SESSION for the recreation event, the transient template-id change, machine-id, and the mtime capture.**

Sources: `forensic/reports/summary/ID_COMPARISON_ROUND2.md`; `forensic/evidence/provenance/account_{a,b,c}/prov_probe.txt`; `forensic/evidence/provenance/account_c/raw_evidence_2026-09-04T2037Z_instance2.txt`; `forensic/reports/round1_environment/04_ID_COMPARISON.txt`.

---

## 6. Resource ceilings — ranges and session disagreement

The limits that *agree* across sessions:

| Resource | Measured (agreement) | Sources |
|---|---|---|
| File descriptors | soft 1024, ~1018 usable before EMFILE; a child can raise to 65536 or to hard 524288 and then bites at its own ceiling; raising beyond hard refused | `forensic/evidence/ceilings/account_a/ceiling/out/fd_probe.json`; `forensic/evidence/round3/account_c/probe3/24_fd_retry.txt`; `.../account_b/probe3/22_D4_fd_discovery.txt` |
| Processes | `ulimit -u` 7917 (soft=hard); cgroup `pids.max = max` (unenforced); threads count against NPROC (brave raw log: spawn fails at 7914; edge narrative: 7915+main) | `forensic/evidence/ceilings/account_b/probes/thread_test.log`; `forensic/evidence/ceilings/account_c/sandbox_ceilings.md` (narrative) |
| CPU quota | `cpu.max = max 100000`, `nr_throttled = 0` during a 60 s dual-core burn (narrative: ~1.98 cores busy) | `forensic/evidence/ceilings/account_c/sandbox_ceilings.md` §6a (narrative; counters corroborated in `forensic/evidence/round3/account_a/probe3/13_b1_bandwidth.txt`) |
| SMT topology | cpu0/cpu1 are the two threads of one physical core, 1 socket × 1 core × 2 threads | `forensic/evidence/round3/account_a/probe3/06_cpu_topology.txt`; `forensic/evidence/ceilings/account_c/sandbox_ceilings.md` §6b |
| `/tmp` | tmpfs, RAM-charged: 256–900 MiB writes move `MemAvailable`/`Shmem`/cgroup `memory.current` by the written amount and release on delete | `forensic/evidence/benchmarks/account_a/F_benchmark_chrome_run1.txt` (I3); `forensic/evidence/round3/account_a/probe3/08_d2_disk.txt`; `ceilings/account_c/sandbox_ceilings.md` §4b (narrative) |

The number that does **not** agree: the touched-allocation OOM boundary. Each session's last success / first kill, preserved separately (no averaging):

| Session (account/browser/source) | Last success | First kill | Backing |
|---|---|---|---|
| Round-3 chrome, 2026-09-06 | 1600 MiB | 1632 MiB (±32 resolution) | `forensic/evidence/round3/account_a/probe3/07_d1_oom.txt`, `results3.json` |
| Round-3 brave, 2026-09-06 | 1632 MiB | 1664 MiB | `forensic/evidence/round3/account_b/probe3/28_D1_oom_bisect.txt` |
| Round-3 edge, 2026-09-06 | 1624.85 MiB | 1653.86 MiB (29.0 MiB gap) | `forensic/evidence/round3/account_c/probe3/19_oom_bisect.txt`, `20_oom_refine.txt` |
| Round-2 ceilings chrome | 1632 MiB | 1664 MiB | `forensic/evidence/ceilings/account_a/ceiling/out/memory_probes.tsv` (raw TSV) |
| Round-2 ceilings edge | 1637 MiB | 1638 MiB | `forensic/evidence/ceilings/account_c/sandbox_ceilings.md` — **markdown only, no probe-log tree in the archive** |

So the honest cross-session statement is a range: last-success 1600–1637 MiB, first-kill 1632–1664 MiB, cgroup `memory.max` 1856.97 MiB. There is no universal OOM threshold in these files. In every raw-backed session the SIGKILL hits the child and the session survives; `memory.events` `oom_kill` increments.

A real disagreement about *mechanism* is left standing, and should stay standing until someone commits a decisive artifact: the edge ceilings markdown argues a host-global OOM (`CONSTRAINT_NONE`, `global_oom` in quoted dmesg; `max`/`oom` counters stayed 0), while round-3 chrome's falsification ledger verdict reads "cgroup-scoped OOM kill" with `oom_kill 0→3` (`ceilings/account_c/sandbox_ceilings.md` §1c vs `round3/account_a/probe3/16_falsifications.txt` F3). Both are in the tree; neither is promoted here.

Weak-evidence flags, exactly as the repo flags them: the brave `fork_test.log` is empty (0 bytes — I checked), so any "EAGAIN at exactly 7914 forks" figure is weaker than the NPROC ulimit itself; and the edge ceilings session shipped no raw probe tree, so its 1-MiB OOM resolution and its disk numbers (~218–405 MiB/s urandom) are narrative-only. Raw-backed disk numbers that do exist move across sessions: round-3 chrome 275–301 MB/s (urandom, `/home/user`), round-3 edge 276.7–333.8 MiB/s (O_DIRECT/buffered/tmpfs), brave round-3 reports ~0.97 GiB/s only for a RAM-sourced "unbottlenecked" variant — a method artifact, not a comparable number (`round3/account_a/probe3/08_d2_disk.txt`; `round3/account_c/probe3/23_disk.txt`; `round3/account_b/probe3/23_D2_unbottlenecked.txt`).

Tool-call concurrency is a three-way disagreement, preserved by session:

| Session | Observation | Source |
|---|---|---|
| Round-3 chrome | 8 calls strictly serial, mean start-gap 2.002 s, wall 18.040 s (vs ~4.1 s if parallel) | `forensic/evidence/round3/account_a/probe3/15_analysis_derived.txt` |
| Round-3 brave | 8 calls overlap (each ~7 s, staggered ~0.48 s), wall ≈ 10.3 s; "concurrent, no cap at 8" | `forensic/evidence/round3/account_b/probe3/25_D5_concurrency.txt`, `result_probe3.json` |
| Round-3 edge | dispatcher staggers ~1.2 s, overlap 3–5 deep, "no per-session cap at 8" | `forensic/evidence/round3/account_c/probe3/28_d5_p1..p8.txt`, `probe3.json` |
| Round-2 ceilings edge | 8/8 parallel, wall ~5.03 s (narrative) | `forensic/evidence/ceilings/account_c/sandbox_ceilings.md` §5 |

**Evidence strength: PRIMARY/REPEATED for FD/NPROC/cpu.max/SMT/tmpfs and for the OOM range across four raw-backed sessions; PRIMARY/SINGLE SESSION for edge round-3's 1-MiB refinement; NARRATIVE ONLY for the edge ceilings markdown and its disk/concurrency figures; the OOM *mechanism* is DISPUTED IN-TREE.**

Sources: `forensic/evidence/ceilings/` (3 accounts); `forensic/evidence/round3/account_{a,b,c}/probe3/` (D1/D2/D4/D5/D6 files); `forensic/reports/round3/UNPACK_REPORT.md`.

---

## 7. Network behaviour — observed data plane and open questions

The most replicated network finding in the repo is a *negative* one about a common tool: TCP `connect()` is not evidence of reachability here. All three round-2 egress sessions and all three round-3 sessions show `connect_ex()` succeeding in ~0.14–0.40 ms to RFC 5737 TEST-NET addresses (`192.0.2.1`, `198.51.100.1`, `203.0.113.1`) that cannot route on the public internet, while real HTTP against the same addresses times out — with one instructive exception: `GET http://192.0.2.1/` returns a local JSON 404 (`{"error":"no matching operation was found"}`) in ~1.3–2 ms, because `/etc/hosts` maps `192.0.2.1 events.e2b.local` (`forensic/evidence/egress/account_a/egress-tests/01-connect-blackhole.txt`; `forensic/evidence/egress/account_b/egress-map/EGRESS_POLICY_MAP.md` §1; `forensic/evidence/egress/account_c/netmap/results/s1d_v2.json`; `forensic/evidence/round3/account_b/probe3/12_B3_rfc5737.txt`). Private ranges behave differently — `10.255.255.1` and `100.64.0.1` time out with `rc=11` — so the terminator is selective, not universal. The edge netmap adds the sharpest control: `connect()` to Brazil completes in 0.193 ms but the first real application byte takes 340.5 ms — a ~1764× ratio (`forensic/evidence/egress/account_c/netmap/results/s1d_v2.json`).

What the data plane actually serves, repeatedly:

- **HTTPS to ordinary sites works.** Round-3 edge fetched 45+ hosts with real status codes and TTFBs (200s from google, pypi, github, x.com, torproject…; a 403 from reddit that did *not* clear with a browser User-Agent, while the wikipedia control stayed 200 — suggesting an origin-side decision, not a sandbox block) (`forensic/evidence/round3/account_c/probe3/26_dns_sites.txt`, `27_egress_ladder.txt`; `forensic/evidence/round3/account_b/probe3/27_D3_ua_test.txt`).
- **Checked TLS leaves are public CAs.** pypi.org → GlobalSign; github.com → Sectigo; google.com → Google Trust Services; huggingface.co → Amazon; `ssl_verify_result=0` against the system store. Three sessions, three method styles (`forensic/evidence/egress/account_a/egress-tests/05-tls.txt`, `05b-issuer-sweep.txt`; `forensic/evidence/egress/account_c/netmap/results/s5_mitm.json`; `forensic/evidence/round3/account_c/probe3/27_egress_ladder.txt` §A).
- **DNS looks unfiltered in everything committed.** Brave's round-2 map: every tested host resolves NOERROR identically via 8.8.8.8 and 1.1.1.1, no sinkhole; edge's round-3 sample found no public DNS blocklist; chrome's round-3 run resolved A *and* AAAA for all public hosts (`egress/account_b/egress-map/EGRESS_POLICY_MAP.md` §2; `round3/account_c/probe3/26_dns_sites.txt`; `round3/account_a/probe3/16_falsifications.txt` F4).
- **IPv6 egress fails while DNS returns AAAA** — chrome round-3 `curl -6` fails, `curl -4` to the same name succeeds; brave's map and edge's netmap agree (link-local only, ENETUNREACH) (`round3/account_a/probe3/16_falsifications.txt` F5; `egress/account_b/egress-map/EGRESS_POLICY_MAP.md`; `egress/account_c/netmap/egress-policy-map.md` §0).
- **SSH to github.com:22** reached a real host-key banner and a publickey rejection in one round-3 retest, while the TEST-NET control timed out at banner exchange — a properly controlled positive datapoint (`forensic/evidence/round3/account_c/probe3/29_ssh_retest.txt`).

The proxy-CA nuance, stated precisely: a self-signed `O=E2B, CN=E2B Proxy CA` certificate exists on the guest at `/usr/local/share/ca-certificates/e2b-ca.crt` (notBefore Sep 4 2026 11:38:43 GMT — the session day), and the committed `envd` unit text describes re-merging a "persisted egress-proxy CA" at boot. But it was **not** the issuer of any leaf the sessions checked. "No TLS interception observed" means exactly that — on the hosts opened, in these sessions (`forensic/evidence/provenance/account_c/raw_evidence_2026-09-04T2037Z_instance2.txt` §2/§3). An installed CA is not proof of interception; absence of interception on checked hosts is not proof of absence everywhere.

Two open disagreements, preserved:

1. **Cloud metadata.** Round-2 edge netmap: `GET http://169.254.169.254/` → `HTTP/1.1 401`, `Server: Firecracker API` — *serves data*. Round-3 chrome: `169.254.169.254` connect-times out and `metadata.google.internal` NXDOMAINs — *blocked*. Both committed, both single-session on this point (`egress/account_c/netmap/egress-policy-map.md` §0 vs `round3/account_a/probe3/11_d3_egress.txt`). Also note the semantic guard: a 401 from a metadata service is not host access, and the guest seeing `iptables` empty (edge round-2) does not mean filtering is absent — the same file argues the policy lives outside the VM, which is an interpretation.
2. **Bandwidth.** Cloudflare's own `__down` endpoint returns 403 at exactly 100,000,000 bytes in two sessions (a CDN-side cap, not a sandbox block — 99,999,999 bytes succeeds), so published numbers are not method-matched: brave round-2 164–267 MB/s sequential at 99 MB; edge round-2 raws ~170–271 MB/s; round-3 chrome 218–247 MB/s; round-3 brave noisy (0.38–1.57 s wall) after needing `curl` + a Referer header; round-3 edge reported 1380–2481 MB/s with no byte count — flagged in the repo's own benchmark report as unverified (`egress/account_a/egress-tests/06-bandwidth.txt`, `06c-down403-h3.txt`; `egress/account_b/egress-map/logs/t6_std.log`; `egress/account_c/netmap/results/s6_raw.txt`; `benchmarks/*/F_benchmark_*.txt`; `forensic/reports/benchmarks/BENCH_REPORT.md` §5.1/§5.4). The one stable, method-matched comparison: `pip download numpy` (the same ~16.7 MB wheel) at headline minima of 19.33 / 19.59 / 20.11 MB/s across the three F-runs.

Egress IP addresses observed, one per named session (n=4, all distinct): `8.235.26.22` (chrome round-2, reverse-DNS `…googleusercontent.com`, The Dalles OR), `34.82.237.153` (edge round-3), `34.187.183.171` and `34.145.126.103` (two Code Arena snapshots). Observation: per-session addresses differ. That is not evidence about the size or nature of any platform-wide pool — one egress IP is not a platform IP.

**Evidence strength: PRIMARY/REPEATED for connect()-vs-TTFB, public-CA leaves, IPv6, and pip/N2 throughput; PRIMARY/SINGLE SESSION for the metadata endpoints, the proxy-CA file details, individual egress IPs, and iptables state; DERIVED for bandwidth medians; DISPUTED IN-TREE on metadata reachability.**

Sources: `forensic/evidence/egress/` (3 account trees); `forensic/evidence/round3/account_{a,b,c}/probe3/` (B2/B3/D3 files); `forensic/evidence/provenance/account_c/raw_evidence_2026-09-04T2037Z_instance2.txt`.

---

## 8. Code Arena — a separate observed surface

Round 2 also characterized a different product surface, `arena.ai/code`, and it is *not* Agent Mode. Five committed `/api/env` snapshots (chrome ×1, brave ×1, edge ×3) agree on a second environment lock, labeled "C" in the repo's own index:

| Item | Value (Code Arena) | Agent Mode (T) for contrast |
|---|---|---|
| `/.e2b` template / build | `n93h7d3hf6qbdd07x3yo` / `62640bfa-cdcd-4733-a74d-1e50fa668e68` | `nlhz8vlwyupq845jsdg9` / `f34a5416-…` |
| Guest OS | **Debian GNU/Linux 12 (bookworm)** | Debian 13 (trixie) |
| Kernel | `6.1.158 #2 … Fri Mar 13 10:12:54 UTC 2026` | `6.1.158+ #1 … Fri Jul 17 14:31:34 UTC 2026` |
| CPU / RAM | 4 vCPU; `MemTotal 4034208 kB`; cgroup `memory.max 3996811264` | 2 vCPU; `2032608 kB`; `1947172864` |
| User | `uid=1001` | `uid=1000` |
| App runtime | Node `v22.22.1`, Next.js `nextjs-postgresql-template`, cwd `/app` | Python 3.13.14 tool-session |
| Database | PostgreSQL 15.16 on `127.0.0.1:5432` — same VM (plus a socat forwarder on 169.254.0.21) | none in snapshots |
| Preview | `localhost:3000`, HTTP, self-fetch 200 | n/a |

(`forensic/evidence/code_arena/chrome/api_env_snapshot.txt`; `brave/api_env_snapshot.txt`; `edge/option_a_api_env_snapshot.txt`, `edge/option_b_api_env_snapshot.txt`, `edge/max_api_env_snapshot.txt`.)

Two details worth underlining. First, the snapshots carry a `referenceId` field equal to `nlhz8vlwyupq845jsdg9` — the Agent Mode template — with `matchesReference: false` / `verdict: "different"`. That is a recorded field naming the Agent template as a reference point; what the platform does with it is not established here. Second, the snapshots contain the round's best persistence observations: an `/app/.arena-marker.log` holding three lines spanning 2026-09-04T21:16:58Z → 2026-09-05T10:29:57Z, and a database table with three rows over the same window — while `/tmp/arena-marker.log` contains only the current session's line. Observation: `/app` and DB state survived across snapshots and a ~13-hour gap; `/tmp` did not. Implication, at interpretation strength: the persistence domain on this surface is the project directory plus the database, not ephemeral paths. `DATABASE_URL` is reported as set with scheme `postgresql`, host `127.0.0.1` only — credentials were redacted when this evidence was extracted, per the committed changelog (`CHANGELOG.md`, Burst 15).

The three round-2 Code Arena *zips*, by contrast, are just Next.js app skeletons; the light-verify reports PASS them for integrity but find no environment data in them (`forensic/reports/round2_code_arena/02_VERIFY_REPORT.md`). The env lock lives entirely in the committed snapshots. And whatever "class C" implies about other Arena surfaces is beyond this tree — Section E of the round-3 prompt, scoped to a live `arena.ai/code` session, is recorded as `NOT PERFORMED` in all three round-3 JSONs.

**Evidence strength: PRIMARY/REPEATED for the environment lock (5 snapshots, 5 distinct sandbox ids); PRIMARY/REPEATED for the `/app`+DB persistence pattern (independent snapshots); NOT ESTABLISHED IN THIS REPOSITORY for anything about other Code Arena templates (vanilla/react-vite) or a full live-session Section E run.**

Sources: `forensic/evidence/code_arena/{chrome,brave,edge}/`; `forensic/reports/round2_code_arena/02_VERIFY_REPORT.md`; `prompts/round2/CodeArenaPROMPT.md`; `forensic/reports/summary/INDEX_ALL.tsv`.

---

## 9. Benchmarks — usable results and confounds

Three self-describing benchmark texts, one fresh session per account on 2026-09-07, SHA-256 verified before and after placement (3/3 MATCH — I re-verified) (`forensic/reports/benchmarks/BENCH_REPORT.md` §1).

What is usable cross-account — pure-Python C1/C2/C7 and the network N2/N3 (min-of-runs as each log reports):

| Test | chrome (`account_a`) | brave (`account_b`) | edge (`account_c`) |
|---|---|---|---|
| C1 `sum(range(10**7))` | 0.1538 s | 0.1458 s | 0.1969 s |
| C2 `sum(i*i …)` | 0.7143 s | 0.5307 s | 0.8892 s |
| C7 SMT ratio (min c0 / min c0+1) | 0.9735 | 0.9791 | 0.9837 |
| N2 pip download numpy (cold) | 19.33 MB/s | 19.59 MB/s | 20.11 MB/s |
| N3 pypi.org time_total (min) | 0.0308 s | 0.0328 s | 0.0323 s |

Sources: `forensic/evidence/benchmarks/account_a/F_benchmark_chrome_run1.txt`, `account_b/F_benchmark_brave_run1.txt`, `account_c/F_benchmark_edge_run1.txt`.

What is confounded, by the repo's own derived report: C3–C6 all run inside numpy, and numpy was not held constant — brave logged 2.3.5, edge 2.3.3, chrome unrecorded. Chrome's C3 is 2.7–3.7× "faster" than the others, which the report correctly declines to attribute to anything. Three more flags: brave's N1 needed `curl` plus a `Referer` header after 403s (method differs); brave's I2 read at ~4.9 GB/s, which is page-cache territory, not disk; edge's N1 reported rates only (~5× peers, no byte count), and edge's I1 printed seconds under an `MB/s` label. The reporting rule that survives contact with these logs: **quote ranges, never a bare minimum** — several tests swing 2–5× *within* one session (chrome I2 582–747 MB/s; edge N1 1380–2481 MB/s; brave N1 wall 0.38–1.57 s).

**Evidence strength: PRIMARY/SINGLE SESSION per account (one run each, by design), plus a DERIVED cross-account report. The C3–C6 cross-account comparisons are confounded and should not be quoted as host properties.**

Sources: `forensic/evidence/benchmarks/`; `forensic/reports/benchmarks/BENCH_REPORT.md` (esp. §4, §5.2–5.5); `prompts/round2/BenchmarkPROMPT.md`.

---

## 10. Reproducibility: what an independent verifier can do

**Offline from this tree (I did all of these at the pinned commit):**

1. Re-hash all 24 canonical archives and compare against `forensic/reports/summary/00_ROOT_INVENTORY.txt` (22 listed there: all MATCH) and `forensic/reports/round3/UNPACK_REPORT.md` (3: all MATCH).
2. Re-verify per-file manifests inside `forensic/evidence/` — ceilings 17/18/1 OK, provenance edge 5/5 OK, round-3 26/32/38 OK — and reproduce the round-3 chrome hash-of-hashes (newline-joined digest list, trailing newline) and edge's (hash+filename lines in listed order). Caveats to carry: brave's hash-of-hashes did not reproduce under my two methods (the unpack report itself documents the ambiguous "sorted" wording); ceilings manifests reference the old `extract/…` work-tree paths.
3. `unzip -l` / `unzip -t` every archive; compare archive listings against the unpacked evidence trees; read the instrument prompts; re-derive the ID comparison table by grepping sandbox/template/boot ids.
4. Re-parse the committed JSON summaries (`results3.json` etc.) and confirm each quoted number has a raw `.txt` sibling.

**Fresh-session replication (needs live sessions; not reproducible from the tree):** run the committed instruments (`prompts/round1/ORIGINALworkPROMPT.md`, `prompts/round2/*.md`, `prompts/round3/FalsificationPROMPT.md`, `prompts/round2/BenchmarkPROMPT.md`) in fresh sessions and diff the raws against this tree. The strongest replication targets are the class-T lock, boot_id constancy, the connect()/TEST-NET behavior, FD/NPROC ceilings, and the OOM *range* — where a new session should be expected to land somewhere in (or beyond) the recorded intervals, not on any single number.

**Not reproducible from this tree, no matter how good the offline tooling:** the absent evidence sets listed in §12; model identity (Agent Mode sessions expose no model name in any committed artifact); and the truth of narrative-only numbers whose raw logs were never committed (edge ceilings' 1-MiB OOM window, its 8/8-parallel concurrency trial, its dmesg quotes).

**Evidence strength: PRIMARY/REPEATED for the offline layer (hashes and manifests re-verified independently); NOT ESTABLISHED IN THIS REPOSITORY for live replication of future sessions.**

Sources: `README.md` ("Reproducing"); `prompts/`; `forensic/reports/round3/UNPACK_REPORT.md`; `forensic/reports/summary/00_ROOT_INVENTORY.txt`.

---

## 11. What is unresolved

Kept open by the files themselves:

- **OOM mechanism.** Host-global OOM vs cgroup-max kill — two committed verdicts in tension (§6). Unresolved in this tree.
- **Concurrency semantics.** Serial-with-2-s-gaps (chrome), overlapping (brave), staggered-3–5-deep (edge), fully parallel (edge, narrative). Whether a per-session cap exists at higher call counts is unmeasured.
- **Metadata-endpoint reachability.** Firecracker API 401 (edge, round 2) vs connect-timeout (chrome, round 3). Both single-session.
- **The `mn0k6lgvyo6q8utbj8jh` template.** The round-2 verifier sandbox that unpacked the ceilings/provenance/egress archives recorded a third template id, different from both T and the Agent-4 quirk id (`ceilings_prov_egress_extract_20260904_214946/02_UNPACK_AND_VERIFY_REPORT.md` §1). No characterization of that environment exists beyond its Phase-0 lock.
- **What performs the egress interception**, where the IP pool begins and ends, SMT/host tenancy policy, sandbox TTL, and any per-turn wall-clock budget — no artifact measures any of these.
- **Model identity and routing.** Self-reported cutoffs differ across round-3 sessions (edge: 2024-06; chrome: ~2025-01; brave: undisclosed, bracketed ~mid-2025 by its own recall-horizon item). These are LLM self-reports in the JSONs — not model metadata — and nothing committed establishes a routing policy (`forensic/evidence/round3/*/probe3/results*.json`, `probe3.json`).
- **Round-1 README arithmetic.** The "363 entries / 17 manifests" summary does not match anything I could find verbatim in the committed round-1 reports (the cross-check shows 19 verifications: 18 PASS + 1 PARTIAL, 0 FAIL). Minor, but it means the README table should not be cited where the underlying report can be.
- **Stale internal docs.** `ID_COMPARISON_ROUND2.md` §5 says the `vm_class` column is blank; `INDEX_ALL.tsv` actually carries T/C/NEW values. The README flags this; the stale paragraph is still there. Round-2 verify reports also use the pre-Burst-12 account mapping in their headers.

**Evidence strength: mixed; every item above is either DISPUTED IN-TREE, PRIMARY/SINGLE SESSION, or NOT ESTABLISHED IN THIS REPOSITORY.**

Sources: `forensic/evidence/ceilings/account_c/sandbox_ceilings.md`; `forensic/evidence/round3/account_a/probe3/16_falsifications.txt`; `forensic/reports/summary/ID_COMPARISON_ROUND2.md`; `ceilings_prov_egress_extract_20260904_214946/02_UNPACK_AND_VERIFY_REPORT.md`; `forensic/evidence/round3/*/probe3/*.json`.

---

## 12. What is not in this repository

Empty is not evidence of absence elsewhere — it is evidence of nothing, here:

| Missing topic | What exists instead |
|---|---|
| **Agent Mode persistence campaign** (the rumored 128 MiB snapshot / 10k-file caps / "140 MiB drop" behavior) | Only the instrument: `prompts/round2/PersistencePROMPT.md`. `zips/persistence/` and `forensic/evidence/persistence/` are `.gitkeep`-empty. No turn-2/turn-3 result exists here. Within-session notes from round 1 (system `sqlite3` install gone after a turn boundary, `~/.local` pip packages retained) are incidental observations, not the campaign (`forensic/evidence/environment/account_b/run6/cross_turn_check.txt`). |
| **GitHub-connect forensics** (App identity, grants, workflow lag, screenshots) | Nothing. No `forensic/evidence/github_connect/`. README/wiki mention it only as not-archived. |
| **A characterized class-B target session** (bookworm / Py 3.11 / `Mon May 11 18:48:24 UTC 2026` / ~3.8 GiB) | Used only as a negative discriminator: round-3 sessions report "0/4 B markers". A class-B-looking *verifier* environment does appear in this tree — the sandbox that unpacked round-1/round-2 evidence recorded a Phase-0 lock with that exact kernel stamp, Python 3.11.2, ~3.8 GiB, uid 1001, and (in round 2) template `mn0k6lgvyo6q8utbj8jh` — but a verifier Phase-0 lock is not a characterized target session: **the environment exists in these files as an unpacking workbench; target-session provenance for class B is absent.** |
| **A non-Arena E2B control** (would the template id match a vanilla public E2B sandbox?) | Not archived. Sharing `nlhz8vlwyupq845jsdg9` across Arena sessions says nothing about whether it is Arena-exclusive. |
| **Characterizations** for ceilings / egress / provenance / code_arena / benchmarks / persistence | Six empty directories with `.gitkeep` (only `characterizations/environment/` has content). |
| **"ICMP is blocked"** | Falsified inside the tree: the run-5 ERRATA shows ICMP works under `sudo` and that the original "blocked" claim was a local `ping`-binary permission artifact (`forensic/evidence/environment/account_a/run5/env-probe/ERRATA.md`). |
| **Model names, screenshots, wiki pages, PR/issue text, live dashboards** | Absent; the wiki exists only as a one-page seed committed at `docs/wiki_home.md`. |
| **Persistence-turn artifacts** (big.bin, marker files, "140 MiB drop message") | No artifact, no transcript. Not established here — which is not a claim the events never happened. |

**Evidence strength: NOT ESTABLISHED IN THIS REPOSITORY (each row).**

Sources: `README.md` ("Not in this repo"); `prompts/round2/PersistencePROMPT.md`; `forensic/reports/round1_environment/02_UNPACK_REPORT.md` §1; `ceilings_prov_egress_extract_20260904_214946/02_UNPACK_AND_VERIFY_REPORT.md` §1; `find` inventory of `zips/` and `forensic/evidence/` at the pinned commit.

---

## 13. Practical takeaways

For anyone characterizing opaque cloud sandboxes — the practices this archive demonstrates, each backed by files above:

1. **Redirect, don't summarize.** Every load-bearing number in this repo traces to a redirected `.txt` or JSON, not to prose. The round-1 ERRATA shows exactly how narrative fails: two of its conclusions died on re-run.
2. **Build falsifiers into the probe.** B2/B3 (prove the probe works; prove it fails against a should-fail target) are what turned "connect() works" into "connect() lies" — the single most transferable finding here.
3. **Never trust `connect()`, `uptime -s`, mtimes, or `boot_id` as identity/state signals in snapshot-resumed guests.** Use sandbox id + uptime together; embed write-times inside file contents.
4. **Quote ranges.** OOM boundaries move by ~30 MiB across sessions; benchmark figures swing 2–5× within one. A single ceiling number from this corpus would be wrong the day it was written.
5. **Hold the software stack constant** before attributing benchmark deltas to hardware — the numpy confound invalidated four of seven CPU tests in the F round.
6. **Hash at capture time, re-verify at interpretation time**, and keep the hash method unambiguous — one of three hash-of-hashes didn't reproduce under its own stated method.
7. **Label evidence strength, and leave disagreements standing.** Three committed sessions disagree about concurrency; that's the dataset, not noise to average.
8. **Never execute archive contents**; static inspection plus CRC checks caught everything worth catching here, and nothing needed to run.
9. **An installed CA, a successful handshake, or a passwordless sudo each prove exactly one thing — themselves.** The semantic gap between "CapBnd full" and "CapEff full", or "connect() OK" and "data plane reachable", is where most sandbox folklore is born.

---

## 14. Closing: what this archive can and cannot establish

**It can establish**, to a replayable hash standard: that every Agent Mode session committed here — nine round-1 runs, three provenance probes, three ceilings sessions, three egress sessions, three round-3 falsification runs, three benchmark runs — drew the same guest profile (trixie, Python 3.13.14, 2 vCPU/2 GiB-class, KVM, E2B markers, one template id); that identity is per-session while boot_id is not; that the resource envelope has stable *shapes* (fd soft 1024, NPROC 7917, unenforced cpu quota, one-core SMT pair, tmpfs `/tmp`) and moving *edges* (an OOM band of roughly 1600–1664 MiB across five sessions); that TCP connect() success is not reachability on this path while TLS leaves checked as public; that a second, clearly different environment serves `arena.ai/code` (bookworm, 4 vCPU, local Postgres, `/app`+DB persistence); and that three self-reported model cutoffs diverge while nothing names a model.

**It cannot establish**: anything about persistence across Agent Mode sessions (the campaign directory is empty); anything about GitHub integration (no artifacts); the existence or shape of a class-B target (only B-markers-as-absence and a B-shaped verifier lock); any platform-wide network policy (three sessions, sampled domain sets, one disputed metadata endpoint); any model-routing policy; the true OOM mechanism; or the meaning of template ids outside Arena.

That division — a precisely measured guest, an honestly absent platform — is the actual result. The repo's own standard is the right one to end on: *claims without a file in this repository are listed as not in this repo, not as findings.*

---

## Confidence summary

- **High confidence** (primary, repeated across ≥3 independent sessions and hash-verified): the class-T guest lock (Debian 13 trixie, kernel `6.1.158+` stamp `Fri Jul 17 14:31:34 UTC 2026`, Python 3.13.14, 2 vCPU Xeon @ 2.60 GHz on one SMT core, `MemTotal 2032608 kB`, cgroup `memory.max 1947172864`, no swap, `/tmp` tmpfs, `e2b.local`/E2B markers, template `nlhz8vlwyupq845jsdg9`, build `f34a5416-…`); KVM-guest-not-container; passwordless sudo for uid 1000 with empty user `CapEff` vs full `CapBnd`; fd soft 1024 / hard 524288 with child-raisable-to-hard; `ulimit -u` 7917 with cgroup `pids.max = max`; `cpu.max` unenforced with `nr_throttled 0`; per-session `E2B_SANDBOX_ID` vs constant boot_id `2bb79165-…`; TCP `connect()` false positives on TEST-NET with real L7 timeouts/404; public-CA TLS leaves on checked hosts; IPv6 connect failure with AAAA resolution; Code Arena class-C lock (bookworm, kernel stamp `Fri Mar 13 10:12:54 UTC 2026`, 4 vCPU, `MemTotal 4034208 kB`, cgroup `3996811264`, local PostgreSQL 15.16) across five snapshots; file-integrity of the archive itself.
- **Medium confidence** (primary, 1–2 sessions or method-qualified): the OOM *band* as a range (four raw-backed sessions; five including the narrative-only edge markdown); OOM-kills-child-session-survives; `/tmp` RAM-charging quantification; DNS-unfiltered finding (sample-bounded in all sessions); per-session egress-IP variance (n=4); pure-Python benchmark ordering C1/C2/C7 and N2/N3; the `/app`+DB-persistence pattern on Code Arena.
- **Single-session or partial**: the sandbox-recreation event and boot_id non-change; the mid-session `E2B_TEMPLATE_ID` flip; `uptime -s` drift; machine-id and mtime clustering; the Firecracker-API 401 from 169.254.169.254 (vs chrome's timeout); iptables-empty-in-guest; the `gujonb0q163l15z30yc7` template quirk; the SSH-22 github datapoint; round-1 cross-turn persistence notes (sqlite3 gone, `~/.local` kept).
- **Narrative only** (no raw logs committed): the edge ceilings markdown's 1-MiB OOM window (1637/1638), its host-global-OOM dmesg argument, its disk speeds, its 8/8-parallel concurrency trial; round-1 characterization-report claims not re-verified by raws.
- **Absent from this repository** (not established here, and no claim is made either way about events elsewhere): the Agent Mode persistence campaign and its 128 MiB/10k-file/140 MiB folklore; GitHub-connect evidence; a characterized class-B target session (B-shaped *verifier* locks exist; target-session provenance does not); a non-Arena E2B control; model names or any routing policy; host tenancy, SMT policy, sandbox TTL, and per-turn wall-clock budgets; a full Section E Code Arena run; screenshots and any wiki/issue/PR text.
