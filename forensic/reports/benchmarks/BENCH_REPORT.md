# Burst 20 — F-benchmark evidence (placement + verification only)

**When:** 2026-09-08
**Scope:** verify the three `F_benchmark_*_run1.txt` run logs by SHA-256, move them (names unchanged) into
`forensic/evidence/benchmarks/{account_a,account_b,account_c}/`, and tabulate their headline numbers.
**Not done:** re-running any benchmark, executing any payload, editing the run logs, cross-round analysis,
README / `INDEX_ALL.tsv` updates.
**Safety:** `sha256sum` + `git mv` only. No file content was modified. Nothing installed, nothing executed.

Account mapping (browser string is ground truth): chrome = `account_a`, brave = `account_b`, edge = `account_c`.

---

## 1. Integrity gate (step 0)

Recomputed before the move; recomputed again after the move. Gate passed both times — no abort.

| File | Browser / account | Expected SHA-256 | Recomputed (pre-move) | Recomputed (post-move) | Verdict |
|---|---|---|---|---|---|
| `F_benchmark_chrome_run1.txt` | chrome / `account_a` | `fe9e2f0fc353ac467689308d46948874afb0b7b8db51aa34d3fc54dcf358b486` | `fe9e2f0f…358b486` | `fe9e2f0f…358b486` | **MATCH** |
| `F_benchmark_brave_run1.txt` | brave / `account_b` | `e1bbb51315c0249e1ac94ae180054a1b0a144f3518f445be2db2f8faf320a742` | `e1bbb513…f320a742` | `e1bbb513…f320a742` | **MATCH** |
| `F_benchmark_edge_run1.txt` | edge / `account_c` | `adf5f2917ba4ea40dd05079ce4368167e08940952c3b58b7e769395b22ae242d` | `adf5f291…b22ae242d` | `adf5f291…b22ae242d` | **MATCH** |

---

## 2. Placement (step 1)

`git mv`, filenames preserved exactly. Repository root no longer contains any `F_benchmark_*` file.

| Original location (root) | Moved to |
|---|---|
| `F_benchmark_chrome_run1.txt` | `forensic/evidence/benchmarks/account_a/F_benchmark_chrome_run1.txt` |
| `F_benchmark_brave_run1.txt` | `forensic/evidence/benchmarks/account_b/F_benchmark_brave_run1.txt` |
| `F_benchmark_edge_run1.txt` | `forensic/evidence/benchmarks/account_c/F_benchmark_edge_run1.txt` |

---

## 3. Per-file provenance

| Field | chrome | brave | edge |
|---|---|---|---|
| Browser | chrome | brave | edge |
| Account | `account_a` | `account_b` | `account_c` |
| `sandbox_id` | `io4itrltdn92q78m4cxm2` | `ialorgpy4povbxjcqk2ck` | `irknu94yo0jlb1bwwus10` |
| Date (UTC, from file) | 2026-09-07 (`2026-09-07T19:25:09Z`) | 2026-09-07 (`2026-09-07T19:19:39Z`) | 2026-09-07 (`2026-09-07T19:19:50Z`) |
| SHA-256 | `fe9e2f0fc353ac467689308d46948874afb0b7b8db51aa34d3fc54dcf358b486` | `e1bbb51315c0249e1ac94ae180054a1b0a144f3518f445be2db2f8faf320a742` | `adf5f2917ba4ea40dd05079ce4368167e08940952c3b58b7e769395b22ae242d` |
| Session type | **fresh** | **fresh** | **fresh** |
| Run | run1 | run1 | run1 |
| `ENV_ID` / `TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` |
| `BUILD_ID` | `f34a5416-ef30-4cb7-8e18-0fdecd6eb529` | `f34a5416-ef30-4cb7-8e18-0fdecd6eb529` | `f34a5416-ef30-4cb7-8e18-0fdecd6eb529` |
| Python | 3.13.14 | 3.13.14 | 3.13.14 |
| numpy | **UNRECORDED** | 2.3.5 | 2.3.3 |
| BLAS | OpenBLAS 0.3.30 (scipy-openblas) | OpenBLAS 0.3.30 (scipy-openblas) | OpenBLAS 0.3.30 |
| MemTotal | 2032608 kB | 2032608 kB | 2032608 kB |
| `memory.max` | 1947172864 | 1947172864 | 1947172864 |
| `cpu.max` | `max 100000` | `max 100000` | `max 100000` |
| cpuset effective | `0-1` | `0-1` | `0-1` |

All three runs share one template/build ID and identical CPU/memory/cpuset limits, so the sandbox *class* is
held constant; only the host instance (`sandbox_id`) differs.

---

## 4. Headline results (min-of-runs, as each file reports it)

"Headline" = the convention each log states: **minimum** elapsed time, and for throughput tests the maximum
rate implied by that minimum time (C4, I1, I2, I3, N1, N2). Warmup runs were discarded by all three logs
(CPU repeats = 5, I/O and network repeats = 3; `time.perf_counter()`; MB/s = bytes/s ÷ 1e6).

| Test | chrome (`account_a`) | brave (`account_b`) | edge (`account_c`) |
|---|---|---|---|
| **C1** `sum(range(10**7))` | 0.153807 s | 0.145776 s | 0.196916 s |
| **C2** `sum(i*i for i in range(10**7))` | 0.714286 s | 0.530672 s | 0.889237 s |
| **C3** `np.arange(10**7,f64).sum()` *(context only — see notes)* | 0.007584 s | 0.020370 s | 0.028046 s |
| **C4** `a@a`, 1000×1000 — time | 0.013742 s | 0.012202 s | not recorded *(implied 0.024946 s)* |
| **C4** — GFLOP/s | 145.54 | 163.914 | 80.174 |
| **C5** `np.sort(np.random.rand(5e6))` | 0.050835 s | 0.048968 s | 0.100249 s |
| **C6** `np.fft.fft(np.random.rand(2**22))` | 0.172572 s | 0.212679 s | 0.220665 s |
| **C7** SMT ratio (min `taskset -c 0` / min `taskset -c 0,1`) | 0.9735 | 0.979118 | 0.983682 |
| **I1** 256 MiB urandom write+fsync, `/home/user` | 0.194507 s / 1380.08 MB/s | 0.229218 s / 1171.09 MB/s | 0.289728 s *(unit mislabelled — see notes)* |
| **I2** 256 MiB read, O_DIRECT | 0.359573 s / 746.54 MB/s | 0.054513 s / 4924.26 MB/s | 557.81 MB/s |
| **I3** 256 MiB write to `/tmp` | 0.089638 s / 2994.68 MB/s | 0.108263 s / 2479.47 MB/s | 2370.63 MB/s |
| **N1** seq — 100 MB from Cloudflare | 0.404760 s / 247.06 MB/s | 0.381810 s / 261.91 MB/s | 1379.92 MB/s |
| **N1** parallel — 3×100 MB, wall | 0.612205 s / 490.03 MB/s agg. | 0.487624 s / 615.23 MB/s agg. | 1652.32 MB/s agg. |
| **N2** `pip download numpy` (cold), ×3 | 0.864193 s / 19.33 MB/s | 0.852796 s / 19.59 MB/s | 0.830319 s / 20.11 MB/s |
| **N3** pypi.org — `time_total` | 0.030848 s | 0.032837 s | 0.032333 s |
| **N3** github.com — `time_total` | 0.068668 s | 0.061534 s | 0.103320 s |
| **N3** huggingface.co — `time_total` | 0.049906 s | 0.048169 s | 0.051904 s |

Supporting detail not in the headline convention:

- **C7 sub-runs (min s):** chrome 0.150820 (`-c 0`) / 0.154918 (`-c 0,1`); brave 0.118543 / 0.121071;
  edge 0.190372 / 0.193531. All three ratios sit just below 1.0, i.e. pinning to one CPU is marginally
  *faster* than two — no SMT throughput gain is visible on any account, consistent with a 2-vCPU cpuset.
- **N2 wheel** is the same artifact on every account: `numpy-2.5.3-cp313-cp313-manylinux_2_27_x86_64…whl`,
  16708577 bytes. N2 therefore measures PyPI fetch, not the local numpy being benchmarked.
- **I3 `/tmp` is tmpfs** (RAM) per brave's `/proc/mounts`; MemAvailable drops by ≈236–262 MB after the write
  (chrome 236.00 MiB, brave −262048 kB, edge 1536712 → 1276168 kB). I3 is a memory-bandwidth number, not disk.
- **N1 parallel per-stream times** were recorded individually by chrome and brave; the aggregate figure above
  is total bytes ÷ wall time.

---

## 5. Notes and caveats

### 5.1 Brave N1 needed `curl` + `Referer` after 403s

Cloudflare rejected the plain-Python path on brave: **`urllib` was refused with HTTP 403**, then **bare `curl`
(no User-Agent) was also refused with HTTP 403** (`HTTP 403 size=1`), and the download only succeeded once a
**`Referer: https://speed.cloudflare.com/`** header was added. Brave's own log states:

> `note: curl without Referer -> HTTP 403 size=1; timed runs used Header Referer: https://speed.cloudflare.com/ ; HTTP 200 size=100000000 each`

Consequences:

- Brave's N1 is a **`curl` measurement**; chrome's and edge's N1 methods are not stated in their logs, so the
  three N1 numbers are **not method-matched** and must not be compared as a controlled three-way difference.
- Brave's N1 timings are noisier than its other network tests (sequential run spread 0.382 s – 1.574 s,
  parallel run spread 0.488 s – 1.086 s wall). The headline min is the cleanest of three; the median is a fairer
  central estimate for cross-account work.
- This is a per-site anti-abuse behaviour, not a sandbox egress block: the same endpoint returned HTTP 200 with
  100000000 bytes on every timed run once the header was present.

### 5.2 numpy versions are not held constant — C3–C6 are confounded

| Account | numpy | How known |
|---|---|---|
| chrome / `account_a` | **UNRECORDED** | log captures OpenBLAS/`show_config()` but never prints a numpy version |
| brave / `account_b` | **2.3.5** | log line `numpy 2.3.5` |
| edge / `account_c` | **2.3.3** | log line `numpy: 2.3.3` |

C3, C4, C5 and C6 all execute inside numpy (and its bundled OpenBLAS), so **the numpy version is an
uncontrolled variable across these four tests**. At minimum brave (2.3.5) vs edge (2.3.3) differ by a patch
release; chrome cannot be placed at all. Differences in C3–C6 between accounts therefore **cannot be attributed
to the sandbox** — they are confounded by the software stack.

C1, C2 and C7 are pure-Python and are **not** affected by this confound; they are the safer cross-account
comparisons in this round.

### 5.3 Chrome's unrecorded numpy is an honesty gap, not a data point

Chrome's log is the most detailed of the three on timing (it prints full run lists, medians and maxima for
every test) yet it **omits the numpy version entirely** — the one environment fact that decides whether its
C3–C6 numbers are comparable to the other two accounts. Two specific consequences:

- **Chrome's C3 is 2.7× faster than brave's and 3.7× faster than edge's** (0.007584 s vs 0.020370 s vs
  0.028046 s). All three are the same `np.arange(10**7).sum()` on the same Python 3.13.14 and the same
  OpenBLAS 0.3.30 build. A gap that large on a memory-bandwidth-bound reduction is far more consistent with a
  **different numpy version** than with host variance, but the log does not let us confirm it.
- We therefore **cannot say which numpy chrome ran**, and any claim that chrome's C3–C6 beat or lost to the
  other accounts is unsupported. The gap should be recorded as missing metadata and, if it matters, closed by
  a re-run that prints `numpy.__version__` — not inferred from the timings.

Treat chrome's C3–C6 as **unverifiable** rather than as a win or a loss.

### 5.4 Outliers — shared-host variance, so always report ranges

The three sandboxes share one template and one cgroup shape but not one physical host. Four numbers sit far
enough from their peers that they read as host/path effects rather than as account-level properties:

| Outlier | Observation | Reading |
|---|---|---|
| **edge C1 / C2 slow** | 0.196916 s / 0.889237 s vs chrome 0.153807 / 0.714286 and brave 0.145776 / 0.530672. Edge is ~1.28× chrome and ~1.35× brave on C1, and brave's C2 is ~1.68× faster than edge's. | C1/C2 are pure-Python and numpy-free, so this is not the numpy confound. It is either a genuinely slower host for the edge run or a noisier neighbour. Note that edge's own C7 pinned run (0.190372 s) reproduces its slow C1, so the effect is stable *within* the edge session — which is exactly why a single run cannot separate "slow host" from "slow measurement window". |
| **edge N1 fast** | 1379.92 MB/s sequential vs chrome 247.06 and brave 261.91 — roughly 5.6× and 5.3×. Edge's N1 parallel (1652.32 MB/s) is likewise ~3.4× chrome's 490.03. | Not credible as a 5× per-account bandwidth difference on one shared egress class. Most likely a different fetch method/flags, a cached or CDN-warm transfer, or a shorter measured byte count — edge's log records only a rate, with no byte count, HTTP code or wall time to check it against. **Flag as unverified.** |
| **brave I2 fast** | 4924.26 MB/s vs chrome 746.54 and edge 557.81 — ~6.6× and ~8.8×. Brave's I2 completed 256 MiB in 0.054513 s. | 0.054 s for 256 MiB implies the read never reached real storage: at 4.9 GB/s the data was almost certainly still in page cache, so the O_DIRECT path did not bypass it on brave. The other two accounts' I2 numbers look like true device reads. **Brave's I2 is not comparable.** |
| **chrome C3 fast** | 0.007584 s vs brave 0.020370 and edge 0.028046 (2.7× / 3.7× faster). | See §5.3 — unattributable while chrome's numpy version is unrecorded. |

**Rule for this round:** single head-line minima are not safe to compare across accounts. Every figure quoted
from these logs should be reported **as a range (min–max, with median where recorded)**, and any cross-account
difference smaller than the observed spread should be called noise. The spreads that justify this:

- chrome C1 0.153807 – 0.185903 s; C2 0.714286 – 0.756122 s; I2 582.32 – 746.54 MB/s
- brave C2 0.530672 – 0.601432 s; I2 4817.72 – 4924.26 MB/s; N1 sequential 0.381810 – 1.574313 s;
  N1 parallel 0.487624 – 1.085652 s
- edge I1 0.289728 – 1.472061 s; I2 557.81 – 3185.65 MB/s; N1 sequential 1379.92 – 2481.40 MB/s;
  N3 github.com 0.103320 – 0.132085 s

Several of these are 2–5× swings **within a single session**, which is larger than most of the between-account
differences the headline table invites.

### 5.5 Format and unit inconsistencies between the three logs

Recorded as-is; no log was edited.

- **edge I1 is labelled `MB/s` but the values are seconds** (`runs: 1.472061230 1.322323682 0.289727501`, `min:
  0.289727501`). 256 MiB ÷ 0.289728 s ≈ 885 MB/s, which is coherent; 0.29 MB/s is not. The table above records
  it as **seconds** with this caveat.
- **edge I2 / I3 / N1 report rates only** — no wall-clock times, so their elapsed times cannot be recovered.
- **edge C4 reports GFLOP/s only** — no times. The table's "implied 0.024946 s" is `2e9 ÷ 80.174 GFLOP/s`,
  derived by us, not measured by the run.
- **edge C6 is labelled `dtype=complex128`** (output dtype) where chrome and brave label the input `float64`;
  the test itself is the same `np.fft.fft(np.random.rand(2**22))`.
- **brave I1 separates urandom generation from the write** (generation untimed for the headline MB/s) and also
  reports a combined `urandom+write+fsync` figure (min 0.789463 s / 340.02 MB/s). Chrome's I1 headline does not
  state whether urandom generation was inside or outside the timed region, so I1 is **not method-matched**
  across accounts.
- **chrome and brave record full run lists**; edge records min/median/max only for most tests.

### 5.6 txt, not zip — by design

> "txt not zip by design: the prompt deletes created files; one self-describing text per run; integrity via
> recorded SHA-256"

Each run is committed as a **single plain-text file** rather than an archive, deliberately:

1. **The prompt deletes created files.** A run that finishes by deleting everything it wrote cannot leave a
   directory tree behind, so the only durable artifact is the text the agent emitted while it worked. Expecting
   a zip from these runs fights the protocol.
2. **One self-describing text per run.** Each file carries its own environment block (date, sandbox/template/
   build IDs, Python and numpy versions, cgroup limits), its stated timing convention, and its raw run lists —
   so it is readable standalone, greppable, diffable, and reviewable in a PR without extraction.
3. **Integrity via recorded SHA-256.** Because there is no manifest-of-many-files inside an archive to check,
   integrity rests on the whole-file SHA-256 recorded for each run and re-verified here (§1) — before and
   after the move. A single hash over a single file is a stronger and simpler guarantee than per-entry hashes
   over a tree that the run would have deleted anyway.

This is why these three files are the only benchmark artifacts, why there are no companion scripts or outputs,
and why no extraction step appears in this report.

---

## 6. Bottom line

- **Integrity:** 3 / 3 SHA-256 MATCH, verified twice (pre-move and post-move). Gate satisfied; no abort.
- **Placement:** 3 / 3 moved by `git mv`, names unchanged, into the correct account directories.
- **Usable as-is:** C1, C2, C7 (pure-Python, numpy-independent) and N2, N3 (same artifact / plain TLS timing).
- **Confounded — do not compare across accounts:** C3, C4, C5, C6 (numpy version uncontrolled; chrome's
  unrecorded).
- **Unverified — flag, do not quote as account properties:** brave N1 (method differs: `curl` + `Referer`),
  brave I2 (likely page-cache, ~5 GB/s), edge N1 (~5× peers, rate-only, no byte count), edge I1 (seconds
  mislabelled MB/s).
- **Reporting rule:** quote ranges (min–max, median where recorded), never a bare headline minimum.
