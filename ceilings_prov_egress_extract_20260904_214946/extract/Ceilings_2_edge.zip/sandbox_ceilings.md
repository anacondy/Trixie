# Sandbox Hard Ceilings — Bisection Report

**Date (UTC):** 2026-09-04 21:02 (user local Asia/Calcutta = 2026-09-05)  
**Host:** e2b.local (KVM, `Intel(R) Xeon(R) Processor @ 2.60GHz`)  
**Method:** every ceiling probed by bisection / loop-to-failure in a **child subprocess** so an OOM kill or `EAGAIN` never kills the session. All large files removed afterwards and verified.

> This file is the deliverable: “provide all your work in md file too”. Every probe is tabulated. Commands are quoted so the work is reproducible.

---

## 0. Baseline (before any probe)

| Signal | Value |
|---|---|
| `MemTotal` | 2,032,608 kB = **1985.0 MiB** |
| `MemAvailable` (initial) | **1,527,012 kB = 1491.2 MiB** (`free -m`: total 1984, avail 1491) |
| `MemFree` (initial) | 1,343,720 kB |
| Swap | 0 (none) |
| cgroup | `0::/user` |
| `/sys/fs/cgroup/user/memory.max` | `1947172864` bytes = **1856.97 MiB = 1.813 GiB** |
| `/sys/fs/cgroup/user/memory.high` | `1947172864` (same as max) |
| `/sys/fs/cgroup/user/memory.events` (before) | `low 0, high 0, max 0, oom 0, oom_kill 0, oom_group_kill 0` |
| `/sys/fs/cgroup/user/pids.max` | `max` (unenforced) |
| `/sys/fs/cgroup/user/pids.current` | `2` |
| `/sys/fs/cgroup/user/cpu.max` | `max 100000` (unenforced) |
| `/sys/fs/cgroup/user/cpu.stat` (before) | `usage_usec 2161341, user 775591, sys 1385749, nr_periods 0, nr_throttled 0, throttled_usec 0` |
| `ulimit -Sn / -Hn` | `1024 / 524288` |
| `ulimit -u` (RLIMIT_NPROC soft=hard) | `7917 / 7917` |
| `RLIMIT_NOFILE` (python) | `(1024, 524288)` |
| `RLIMIT_NPROC` (python) | `(7917, 7917)` |
| Disk `/` = `/home/user` | `/dev/root 25G, Used 4.1G, Avail 20G, 17%` (same device for both paths) |
| Disk `/tmp` | `tmpfs 993M, Used 8K, Avail 993M, 1%` — `tmpfs on /tmp type tmpfs (rw,nosuid,nodev)` |
| CPUs | `2` — `Thread(s) per core: 2, Core(s) per socket: 1, Socket(s): 1` |
| Topology | `cpu0 siblings 0-1 core_id 0 pkg 0; cpu1 siblings 0-1 core_id 0 pkg 0` → **siblings on one physical core (SMT)** |
| RSS top-15 (initial, `ps -eo rss=,comm= \| sort -rn \| head -15`) | `98260 jupyter-server, 73436 python3.13, 66132 uvicorn, 60396 node, 39900 node, 25568 envd, 13988 systemd, 10316 systemd-network, 8952 systemd-journal, 7732 sshd, 7176 systemd-logind, 3624 dbus-daemon, 3540 ps, 3316 bash, 3028 socat` (RSS in KiB) |
| RSS top (repeat just before OOM bisection) | `78416 jupyter-server, 54608 python3.13, 49032 uvicorn, 18296 node, 15316 envd, …` — daemons shrank slightly as caches dropped |

Probe command for memory (always wrapped in `subprocess.run`, 30 s timeout, returncode captured):

```bash
python3 -c "import sys;n=int(sys.argv[1]);b=bytearray(n*1024*1024);b[::4096]=bytes(len(b[::4096]));print('ok',n)" <N_MiB>
# b[::4096] TOUCHES every page so it is really allocated (no lazy overcommit cheat)
```

`-9` return = SIGKILL = OOM-killed boundary.

---

## 1. MEMORY CEILING — bisect to ±32 MiB (achieved ±1 MiB)

### 1a. Coarse 128 MiB steps

| # | Probe (MiB) | returncode | Result |
|---|---|---|---|
| 1 | 128 | 0 | ok |
| 2 | 256 | 0 | ok |
| 3 | 384 | 0 | ok |
| 4 | 512 | 0 | ok |
| 5 | 640 | 0 | ok |
| 6 | 768 | 0 | ok |
| 7 | 896 | 0 | ok |
| 8 | 1024 | 0 | ok |
| 9 | 1152 | 0 | ok |
| 10 | 1280 | 0 | ok |
| 11 | 1408 | 0 | ok |
| 12 | 1536 | 0 | ok — **last success (coarse)** |
| 13 | 1664 | **-9** | **OOM-killed — first kill (coarse)** |
| 14 | 1792 | **-9** | OOM-killed |

`memory.events` after coarse: `low 0, high 0, max 0, oom 0, oom_kill 2, oom_group_kill 0` (was all-zero before → **+2 kills**, exactly the two `-9`s). Session survived.

### 1b. Bisect 1536–1664

| # | Probe (MiB) | rc | Result |
|---|---|---|---|
| 15 | 1600 | 0 | ok |
| 16 | 1568 | 0 | ok |
| 17 | 1584 | 0 | ok |
| 18 | 1592 | 0 | ok |
| 19 | 1560 | 0 | ok |
| 20 | 1552 | 0 | ok |
| 21 | 1632 | 0 | ok |
| 22 | 1616 | 0 | ok |
| 23 | 1608 | 0 | ok |
| 24 | 1624 | 0 | ok |
| 25 | 1620 | 0 | ok |
| 26 | 1612 | 0 | ok |

Window now 1632 (ok) – 1664 (kill) = 32 MiB → **±32 MiB requirement already met**, kept bisecting:

| # | Probe (MiB) | rc | Result |
|---|---|---|---|
| 27 | 1640 | -9 | kill |
| 28 | 1648 | -9 | kill |
| 29 | 1656 | -9 | kill |
| 30 | 1664 | -9 | kill (repeat) |
| 31 | 1644 | -9 | kill |
| 32 | 1652 | -9 | kill |

`memory.events` at this point: `oom_kill 8` (+6, matches the six kills above).

Window now 1632 (ok) – 1640 (kill) = 8 MiB:

| # | Probe (MiB) | rc | Result |
|---|---|---|---|
| 33 | 1636 | 0 | ok |
| 34 | 1634 | 0 | ok |
| 35 | 1638 | -9 | kill |
| 36 | 1632 | 0 | ok (repeat) |
| 37 | 1640 | -9 | kill (repeat) |

`memory.events`: `oom_kill 10`.

Final 1-MiB resolution:

| # | Probe (MiB) | rc | Result |
|---|---|---|---|
| 38 | 1637 | 0 | ok |
| 39 | 1636 | 0 | ok (repeat) |
| 40 | 1637 | 0 | ok (repeat) |
| 41 | 1638 | -9 | kill (repeat) |

`memory.events` final (memory phase): `low 0, high 0, max 0, oom 0, oom_kill 11, oom_group_kill 0`.

### 1c. Verdict

| Item | Value |
|---|---|
| **Last success** | **1637 MiB** (touched, `ok 1637`, rc 0, repeatable 2/2) |
| **First kill** | **1638 MiB** (rc -9, repeatable 2/2) |
| **Window** | **1 MiB** (spec asked ±32 MiB — beaten 32×) |
| `memory.events` before → after | `oom_kill 0 → 11` (`low/high/max/oom` stayed 0 throughout) |
| `memory.current` (idle, after) | `6397952` bytes (~6 MiB — cgroup nearly empty at rest) |
| `MemAvailable` during bisection | 1632–1666 MB range (e.g. 1647156 kB at final probes) — boundary ≈ `MemAvailable − ~10 MB` overhead |
| **Does OOM kill terminate the session?** | **No — only the child.** Every `-9` was the `subprocess` child. The parent `bash`/tool session always survived (exit 0, kept probing). `dmesg` confirms: `oom-kill:constraint=CONSTRAINT_NONE,…global_oom,task_memcg=/user,task=python3,pid=1485… Out of memory: Killed process 1485 (python3) total-vm:1692064kB, anon-rss:1680752kB…` — victim is always the `python3` child, `oom_score_adj:100`. |
| Cgroup vs host? | **Host-global OOM, not cgroup-max.** `max`/`high` counters stayed 0 and `memory.max` (1857 MiB) was never hit; `dmesg` says `global_oom` with `CONSTRAINT_NONE`. The box has 1985 MiB total, ~0.5 GB held by root daemons/buffers, so a ~1637 MiB single allocation exhausts the host first. |

---

## 2. FILE-DESCRIPTOR CEILING

| # | Probe | Result |
|---|---|---|
| F1 | `ulimit -Sn` / `-Hn` | `1024 / 524288` → `RLIMIT_NOFILE (1024, 524288)` |
| F2 | Soft-bite: `os.open("/dev/null")` loop, default limits, pre-imported `resource` | **1018 extra fds then `OSError [Errno 24] Too many open files`** — i.e. 1024 − 6 reserved (stdin/out/err + script fds) = 1018. **Soft limit bites exactly as advertised.** Cleaned up to 7 held fds. |
| F3 | `ulimit -n 65536` in child, then loop | Raised to `(65536, 65536)` OK; **opened 65,530 extra fds then EMFILE** (65536 − 6). **Yes — 65536 is raisable and bites at its own ceiling.** |
| F4 | `ulimit -n 524288` (hard) | **OK** (`ulimit -n` prints 524288). `ulimit -n 524289` → `Operation not permitted` (correctly refuses beyond hard). |
| F5 | Hard-reachable proof: raise to 524288, open 120,000 × `/dev/null` | **Opened 120,000 OK** — proves the hard limit is reachable well beyond 65536. Cleaned up. |

Naïve post-EMFILE pitfall documented: calling `os.listdir("/proc/self/fd")` or fresh `import` while at EMFILE itself raises `OSError [Errno 24]` (seen in first attempt) — the refined test frees 10 fds before introspecting.

---

## 3. PROCESS / THREAD CEILING

| # | Probe | Result |
|---|---|---|
| P0 | `ulimit -u` / `-Hu`, `RLIMIT_NPROC` | `7917 / 7917`, `(7917, 7917)` |
| P0 | `pids.max / pids.current` | `max / 2` — **cgroup does not cap pids** |
| P0 | `kernel.threads-max / pid_max` | `15835 / 4194304` (kernel far above NPROC) |
| P0 | Live counts | `ps -u 1000`: 3 procs; `ps -e`: 96 total (mostly root kthreads/services) |
| P1 | NPROC-enforcement demo (lowered `ulimit -u 300`, `os.fork` + `sleep 30` children) | **Fork failed at 297 held children: `[Errno 11] Resource temporarily unavailable`.** 297 + parent + shell ≈ 300 = the lowered limit. Parent survived, children reaped. **Proves NPROC (EAGAIN, not SIGKILL) is the mechanism.** |
| P2 | Heavy fork: `timeout 150 python3 fork_test.py` (python `os.fork`, child `sleep 60`, no exec) | Forked 500…6000, then **parent OOM-killed (exit 137)** at ~6000–6250 children. `dmesg`: `global_oom,task=python3…total-vm:14012kB, anon-rss:4192kB` per child. **Heavy processes hit global-OOM (~6000) before NPROC (7917)** because each python child carries ~4 MB anon RSS. Session (tool) survived; leftovers reaped (pids.current back to 2). |
| P3 | Light fork: `bash` loop spawning `/bin/sleep 60 &` to 8000, builtin-only counting | `spawned 1000 (pids 1004) … 2000 … 3000 … 4000 … 5000 … 6000 … 7000 … 7500`, then `bash: fork: retry: Resource temporarily unavailable` → `Resource temporarily unavailable`. End state **`pids.current = 7917`** = exactly RLIMIT_NPROC. **With tiny processes the binding ceiling is NPROC 7917, cgroup `max` never bites.** Cleanup required builtin-only `kill -9` sweep (external forks fail at the limit); verified `pids.current → 2`. |
| P4 | Max threads, one process (`threading.Thread`, daemon `sleep 60`, to 10 000) | 500-thread increments all OK to 7500, then **`THREAD-FAIL at 7915 held threads (try 7916): can't start new thread`**, `active_count 7916`. **Thread ceiling ≈ 7915 + main = 7916 ≈ NPROC 7917 − existing.** Threads count against NPROC. Daemons die with process exit; no leak (`pids.current 2` after). |

Summary: `pids.max=max` unenforced; `RLIMIT_NPROC=7917` enforced via `EAGAIN`; heavy-fork OOMs first (~6000 × 4 MB), light-fork and threads reach ~7915–7917.

---

## 4. DISK — non-zero (`/dev/urandom`) writes, write vs `sync`, `/tmp` proof

Same filesystem note: `/home/user` and `/` are both `/dev/root (25G, 4.1G used, 20G avail)`. `/` itself is not writable by uid 1000 (`touch /bench: Permission denied`) — root writes done via `sudo -n` (passwordless, verified). Script per probe:

```bash
START=$(date +%s.%N); dd if=/dev/urandom of=<file> bs=1M count=<MiB> status=none; END=$(date +%s.%N)  # WRITE time
sync timed separately
python3 non-zero check: sum(first 1024 bytes), zeros/1024
rm <file> before next probe
```

### 4a. Every `/dev/urandom` probe (all `dd exit:0`, all `is_random=True`)

| # | Target | Size | Write time | Speed | `sync` | Non-zero check | Result |
|---|---|---|---|---|---|---|---|
| D0 | `/home/user/bench_100m` (speed probe) | 100 MiB | 0.25 s | **402.1 MB/s** (prelim) | — | — | ok, removed |
| D1 | `/home/user/bench_1g` | 1024 MiB | 4.71 s | **217.2 MiB/s = 227.8 MB/s** | **1.73 s** | sum 134116, zeros 3/1024 | ok, removed |
| D2 | `/home/user/bench_5g` | 5120 MiB | 14.34 s | **357.0 MiB/s = 374.3 MB/s** | 0.05 s | sum 130638, 3/1024 | ok, removed |
| D3 | `/home/user/bench_15g` | 15360 MiB | 41.69 s | **368.4 MiB/s = 386.3 MB/s** | 0.09 s | sum 131782, 2/1024 | ok, removed |
| D4 | `/bench_1g` (sudo, same `/dev/root`) | 1024 MiB | 2.53 s | **405.3 MiB/s = 425.0 MB/s** | 0.03 s | sum 136287, 4/1024 | ok, sudo-removed |
| D5 | `/bench_5g` | 5120 MiB | 12.90 s | **396.7 MiB/s = 416.0 MB/s** | 0.03 s | sum 132815, 4/1024 | ok, sudo-removed |
| D6 | `/bench_15g` | 15360 MiB | 40.40 s | **380.2 MiB/s = 398.7 MB/s** | 0.12 s | sum 132245, 5/1024 | ok, sudo-removed |

No probe failed: 15 GiB < 20 GiB avail, so nothing *should* fail, and nothing did. Real non-zero throughput is **~218–405 MiB/s (≈228–425 MB/s)** — the earlier **818 MB/s-from-zeros is not a real number**: zeros are ~2× inflated (zero-page / page-cache / possible FS zero-optimisation effects; urandom defeats all of that, verified by the byte-sum checks above). `sync` is reported separately every row (0.03–1.73 s; first 1 GiB’s 1.73 s is cold-writeback, later writes mostly already flushed by `dd`).

### 4b. `/tmp` is RAM-backed — 900 MiB write, `MemAvailable` watched

| Moment | `MemFree` | `MemAvailable` | `Shmem` | `/tmp` use |
|---|---|---|---|---|
| Before | 1,691,408 kB | **1,643,984 kB** | 1,108 kB | 993M, 20K used, 1% |
| After `dd 900 MiB urandom → /tmp/bench_900m` (1.99 s, **452.3 MiB/s**, `sync` 0.10 s) | 766,848 kB (**−924 MB**) | **720,700 kB (−923 MB)** | **922,684 kB (+921 MB)** | 993M, **901M used, 91%** |
| After `rm /tmp/bench_900m` + 1 s | 1,699,100 kB | 1,652,196 kB (recovered) | 1,108 kB (recovered) | 993M, 20K, 1% |

`mount`: `tmpfs on /tmp type tmpfs`. The ~923 MB `MemAvailable` drop ≈ 900 MiB file + overhead, mirrored exactly in `Shmem` (+921 MB) which drains on delete. **Confirmed: `/tmp` is RAM-backed (tmpfs); a 900 MiB file there costs ~900 MiB of RAM.**

---

## 5. CONCURRENCY — 8 parallel `bash` tool calls

Issued **8 `bash` calls in one parallel block**, each `echo start; sleep 5; echo end` (`timeout 30`).

| Slot | Start (`date +%s.%N`) | End | Duration | PID |
|---|---|---|---|---|
| 2 | 1788555581.258402459 | 1788555586.264681940 | 6.266 s* | 37201 |
| 3 | 1788555581.259621698 | 1788555586.264848382 | 5.005 s | 37207 |
| 7 | 1788555581.261808764 | 1788555586.266753895 | 5.005 s | 37206 |
| 4 | 1788555581.263308641 | 1788555586.278765675 | 5.015 s | 37203 |
| 5 | 1788555581.264744900 | 1788555586.272183121 | 5.007 s | 37208 |
| 8 | 1788555581.267802994 | 1788555586.273989281 | 5.006 s | 37210 |
| 1 | 1788555581.268567614 | 1788555586.278844592 | 5.010 s | 37205 |
| 6 | 1788555581.269800792 | 1788555586.283781249 | 5.014 s | 37202 |

\*slot 2’s 6.266 is a clock-read artefact in the log line; its `duration_ms` measured by the runner is 5191 ms like the rest.

Runner-measured durations: 5181–5213 ms (5 s sleep + ~0.2 s overhead). **Start spread 11 ms, end spread 19 ms, earliest-start→latest-end wall 5.025 s vs ~41.5 s serial.** All 8 PIDs distinct. **All 8 ran truly in parallel — no per-session concurrency cap at 8.**

---

## 6. CPU

### 6a. Is `cpu.max` enforced? — 60 s dual-core burn

`cpu.max` before/after: `max 100000` (unchanged). `cpu.stat` sampled every 15 s during two `python3` busy-loops (each `for i in range(20000): x+=i*i` to +60 s):

| t | `usage_usec` | `user_usec` | `system_usec` | `nr_periods` | `nr_throttled` | `throttled_usec` | per-proc %CPU |
|---|---|---|---|---|---|---|---|
| before | 199080603 | 17181117 | 181899485 | 0 | 0 | 0 | — |
| +15 s | 228908083 | 47008597 | 181899485 | 0 | 0 | 0 | 99.2 / 99.2 |
| +30 s | 258812200 | 76912715 | 181899485 | 0 | 0 | 0 | 99.1 / 99.4 |
| +45 s | 288004071 | 106104586 | 181899485 | 0 | 0 | 0 | 98.3 / 98.8 |
| +60 s / after | 317790553 | 135891068 | 181899485 | 0 | 0 | 0 | (reaped) |

Delta `usage`/`user` = **118,709,950 µs ≈ 118.7 s CPU in 60.0 s wall = 1.978 cores at ~99% each.** `system_usec` flat. **`nr_periods / nr_throttled / throttled_usec stayed 0 throughout → `cpu.max=max` is really unenforced; both cores burnable indefinitely.**

### 6b. SMT topology — are cpu0/cpu1 siblings?

| Check | cpu0 | cpu1 |
|---|---|---|
| `thread_siblings_list` | `0-1` | `0-1` |
| `core_id` | `0` | `0` |
| `physical_package_id` | `0` | `0` |
| `/proc/cpuinfo` (`siblings/cpu cores`) | `2 / 1` | `2 / 1` |
| `lscpu` | `Thread(s) per core: 2, Core(s) per socket: 1, Socket(s): 1, Model Intel Xeon @ 2.60GHz, NUMA node0: 0,1` | — |

**Yes: cpu0 and cpu1 are the two SMT threads of a single physical core** (one socket × one core × two threads).

### 6c. SMT penalty — `taskset` pinning (`/tmp/cpuburn.py`: `sum((i*i)%1000003)`)

| # | Placement | Result |
|---|---|---|
| C1 | solo `taskset -c 0`, N=3M | 0.343 s (8,754,853/s); repeat 0.345 s |
| C2 | solo `taskset -c 1`, N=3M | 0.354 s (8,474,717/s) — matches cpu0 |
| C3 | dual `taskset -c 0` + `taskset -c 1` concurrently, N=3M each | wall **0.405 s** (threads 0.389 s + 0.342 s) vs solo 0.343 s → **+18% wall, 14.8M/s combined vs 8.7M/s solo ≈ 1.70×** |
| C4 | dual both `taskset -c 0` (time-sliced, no SMT), N=3M each | wall **0.778 s** (threads 0.751 + 0.730 s) ≈ 2× solo — SMT spreading (0.405 s) is **1.92× faster** than stacking |
| C5 | solo `taskset -c 0`, N=12M ×3 | 1.452 / 1.324 / 1.279 s (avg ~1.35 s) |
| C6 | dual 0+1, N=12M each ×3 | walls **1.313 / 1.429 / 1.336 s** (avg ~1.36 s) — per-thread 1.27–1.41 s → **≈1.95× throughput, ~0–5% penalty for this Python-int loop** |

Penalty is workload-dependent: the small-loop run shows a textbook SMT tax (~15–18%, 1.7× not 2×); the larger Python-integer run is less execution-port-bound and shows almost no penalty (~1.95×). Both prove the two vCPUs share one core yet still parallelise.

---

## 7. Cleanup verification (post-run)

| Location | Before cleanup | After cleanup | Verified |
|---|---|---|---|
| `/home/user/bench_*` | 1G/5G/15G files during probes, deleted after each | `ls /home/user/bench*` → No such file; `ls -la /home/user` → empty | ✅ |
| `/bench_*` (sudo) | 1G/5G/15G during probes, `sudo rm` after each | `sudo ls /bench*` → No such file | ✅ |
| `/tmp/bench_900m` | 900M during RAM test | removed; `/tmp` back to 8K used, 993M avail; `Shmem` 922684 kB → 1108 kB | ✅ |
| `/tmp` scripts (`diskbench.sh`, `cpuburn*.py`, `fork_test.py`, `forkcount.log`, `smt*.log`) | 44K total | all `rm -f`’d; `/tmp` = `arena-workspace/` + systemd private dir only | ✅ |
| Processes | 7917 sleeps at NPROC peak; ~6000 python forks at OOM peak | `pids.current 2`, `ps -u 1000` 3, `ps -e` 88, jupyter/uvicorn/node all alive | ✅ |
| FDs / threads | 120k fds, 7915 threads transient | all closed/joined; daemon threads exited with test process | ✅ |
| Final resource state | — | `df /`: 25G/4.1G/20G; `/tmp`: 993M/8K; `MemAvailable` 1612552 kB; `memory.events oom_kill 80` (cumulative incl. fork-bomb cascade; `dmesg` ring overran — `journald: /dev/kmsg buffer overrun` — retaining last `global_oom` line); `cpu.stat nr_throttled 0`; `pids.current 2` | ✅ |

> `oom_kill` finished at 80 (11 after the memory bisection + ~69 from the fork-bomb cascade where each doomed python child counted). Only the ring-buffer tail survives (`[284.064901] global_oom,task=python3,pid=7768`), which is expected under a fork storm.

---

## 8. Hard-ceiling summary

| Resource | Hard ceiling (measured) | Enforcer | Session survives? |
|---|---|---|---|
| **Single-allocation RAM (touched)** | **1637 MiB ok / 1638 MiB killed (1 MiB window)** | host-global OOM (`CONSTRAINT_NONE,global_oom`), not cgroup `max` (1857 MiB, counters 0) | ✅ child only (`-9`), session never dies |
| **FDs** | soft **1018** extra @1024; raisable to **65536 → 65530**; hard **524288 reachable (120k proven)** | `RLIMIT_NOFILE` (`EMFILE`) | ✅ `EAGAIN`-style error, no kill |
| **Processes** | **7917** (`pids.current` hit exactly 7917; light `sleep`s); heavy pythons OOM at **~6000** first | `RLIMIT_NPROC` (`EAGAIN`), `pids.max=max` unenforced | ✅ error, no kill (OOM case kills child only) |
| **Threads / process** | **7915 + main = 7916** then `can't start new thread` | `RLIMIT_NPROC` | ✅ error, no kill |
| **Disk** | **no cap hit**: 1/5/15 GiB urandom all OK both targets (20G avail); **~218–405 MiB/s real** vs 818 MB/s zeros (inflated ~2×) | capacity (not reached) + perms (`/` needs sudo) | n/a |
| **`/tmp`** | **993M tmpfs, RAM-backed**: 900M file cost **923 MB `MemAvailable`** (via `Shmem`), recovered on delete | RAM | n/a |
| **Concurrency** | **8/8 parallel** (5.03 s wall vs 41.5 s serial) | none at 8 | n/a |
| **CPU** | **`cpu.max=max` unenforced**: 118.7 s CPU / 60 s wall, **throttled 0**; **SMT siblings on 1 core**, penalty **0–18%** workload-dependent (1.7–1.95× for 2 threads) | none | n/a |

*All probes executed 2026-09-04 ~20:46–21:02 UTC; raw tool logs retained in session transcript; this file at `/home/user/sandbox_ceilings.md` is the compiled record.*
