# Sandbox Hard-Ceiling Probe Report

**Host:** Linux e2b.local 6.1.158+ x86_64 (kernel `PREEMPT_DYNAMIC`), 2 vCPUs, ~1.94 GiB RAM VM
**Date of run:** 2026-09-05 (sandbox clock 2026-09-04/05 UTC in `date` epoch terms)
**Method:** bisection of allocate-and-TOUCH subprocesses, C fork/thread counters, `dd` from `/dev/urandom`, `taskset` pinning, cgroup event snapshots. Raw probe logs: `ceiling/out/*.json|.tsv|.txt`, probe sources in `ceiling/scripts/`.

---

## 0. Environment reconnaissance (baseline)

| Quantity | Value |
|---|---|
| CPU count | 2 (`nproc`=2) |
| CPU topology | cpu0 & cpu1: `thread_siblings_list=0-1` on both, `core_id=0`, `physical_package_id=0` → one physical core, SMT pair (see §6) |
| MemTotal | 2,032,608 kB = **1,984.9 MiB** |
| MemAvailable (idle) | ~1,525–1,620 MiB (agent daemons outside our cgroup hold ~350–400 MB RSS: jupyter-server 98 MB, python3.13 73 MB, uvicorn 66 MB, node ×2 ~98 MB, envd 25 MB …) |
| Swap | none (SwapTotal 0) |
| cgroup of session | `/sys/fs/cgroup/user` (v2) |
| `memory.max` | **1,947,172,864 B = 1,857.0 MiB**; `memory.swap.max=max` |
| `cpu.max` | `max 100000` (no quota) |
| `pids.max` | `max` (no cgroup pids cap) |
| Overcommit | `/proc/sys/vm/overcommit_memory=0` (heuristic) |
| Filesystem | single ext4 `/dev/vda` (25 GB, 4.1 GB used, ~20 GB avail) mounted at `/`; **`/home/user` is NOT a separate mount** (same device, `df -T` shows `/dev/root` for both) |
| `/tmp` | tmpfs 993 MB (RAM) |
| rlimits | `nofile` soft **1024** / hard **524288**; `nproc` soft=hard **7917**; `max locked memory` 8192 kB; stack 8192 kB |
| uid | 1000 `user`, groups include `sudo` (passwordless `sudo -n` works); agents run outside our cgroup |

---

## 1. MEMORY CEILING — allocate-and-touch, bisected

**Method.** Every probe ran as a **subprocess** (`subprocess.run`) that allocates `n` MiB as `bytearray` and touches every 4 KiB page; parent records returncode. `rc=-9` ⇒ OOM kill. Steps of 128 MiB upward until first kill, then binary bisect to a ≤32 MiB window, then both boundary points confirmed again. `memory.events` and `MemAvailable` snapshotted around each probe. Driver stays alive throughout — it *is* the "session survives?" test.

**Table of every probe** (`ceiling/out/memory_probes.json/.tsv`):

| # | phase | size | rc | outcome | time (s) | cgrp mem.cur pre (MiB) | MemAvail pre (MiB) | oom_kill pre→post |
|---|---|---|---|---|---|---|---|---|
| 1 | STEP | 128 MiB | 0 | ok | 0.10 | 182.3 | 1489.7 | 0→0 |
| 2 | STEP | 256 MiB | 0 | ok | 0.17 | 182.7 | 1484.9 | 0→0 |
| 3 | STEP | 384 MiB | 0 | ok | 0.24 | 182.7 | 1492.0 | 0→0 |
| 4 | STEP | 512 MiB | 0 | ok | 0.33 | 182.9 | 1473.8 | 0→0 |
| 5 | STEP | 640 MiB | 0 | ok | 0.40 | 183.3 | 1494.7 | 0→0 |
| 6 | STEP | 768 MiB | 0 | ok | 0.49 | 183.5 | 1505.8 | 0→0 |
| 7 | STEP | 896 MiB | 0 | ok | 0.72 | 183.6 | 1498.0 | 0→0 |
| 8 | STEP | 1024 MiB | 0 | ok | 0.79 | 184.0 | 1495.8 | 0→0 |
| 9 | STEP | 1152 MiB | 0 | ok | 0.86 | 184.5 | 1499.5 | 0→0 |
| 10 | STEP | 1280 MiB | 0 | ok | 1.04 | 184.7 | 1500.0 | 0→0 |
| 11 | STEP | 1408 MiB | 0 | ok | 1.09 | 180.6 | 1495.3 | 0→0 |
| 12 | STEP | 1536 MiB | 0 | ok | 1.19 | 87.3 | 1513.0 | 0→0 |
| 13 | STEP | 1664 MiB | −9 | **SIGKILL (OOM)** | 1.19 | 22.1 | 1578.3 | **0→1** |
| 14 | BISECT | 1600 MiB | 0 | ok | 1.20 | 11.6 | 1603.8 | 1→1 |
| 15 | BISECT | 1632 MiB | 0 | ok | 1.16 | 16.8 | 1581.2 | 1→1 |
| 16 | CONFIRM | 1632 MiB | 0 | ok | 1.15 | 16.4 | 1602.3 | 1→1 |
| 17 | CONFIRM | 1664 MiB | −9 | **SIGKILL (OOM)** | 1.16 | 15.8 | 1601.5 | **1→2** |

**Result: last success 1632 MiB · first kill 1664 MiB (window ±16 MiB, tighter than the ±32 target; kill reproduced twice).**

`memory.events` **before** (all-zero baseline):

```
low 0  high 0  max 0  oom 0  oom_kill 0  oom_group_kill 0
```

`memory.events` **after** the two kills:

```
low 0  high 0  max 0  oom 0  oom_kill 2  oom_group_kill 0
```

**Answers:**
- **Does an OOM kill terminate the session or only the child?** *Only the child.* The driver kept running through both kills (17 probes in one process), printed its summary, and the whole tool session stayed alive. Kill is charged to the cgroup (`oom_kill` 0→2) but the cgroup keeps working.
- **Mechanism.** `memory.max` = 1,857 MiB but `max`/`oom` events never fired → the kills are **not** cgroup-limit-triggered; with VM RAM at 1,985 MiB, ~180 MiB cgroup baseline + ~350–400 MB out-of-cgroup daemons + a 1.66 GiB touching child ≈ 2.2 GiB, the trigger is best explained as **total-VM (host) OOM**, which kills the largest anon consumer — the child — and is credited to the victim's cgroup `oom_kill`. Effective practical ceiling for one allocate-and-touch process: **≈1.63 GiB (1,664 MiB kills); hard cgroup cap is 1,857 MiB but never reachable in one allocation because host RAM (1,985 MiB) minus ~0.4 GiB of resident agent daemons binds first.** No swap exists to soften it. Small allocations are unaffected (any single-process total ≥1,664 MiB of *touched* memory is the kill zone; untouched/`malloc`-only allocations do not count — the ceiling is on resident, touched memory).
- *Caveat observed:* the 17-probe driver's own cgroup `memory.current` slumped from ~182 MiB to ~12–22 MiB between kills (kernel reclaimed file cache under pressure); the kill boundary was stable regardless (±16 MiB).

---

## 2. FILE-DESCRIPTOR CEILING

`RLIMIT_NOFILE`: soft **1024**, hard **524288**. Probes: `dup(1)` in a loop until `EMFILE` (errno 24).

| Phase | soft limit in effect | fds opened before EMFILE | total at failure | verdict |
|---|---|---|---|---|
| fresh process, default | 1024 | **1018** (baseline 6–7 fds) | 1024 | soft limit bites **exactly** at 1024 |
| child via `bash -c 'ulimit -n 65536'` | 65536 | **65533** | 65536 | raise works unprivileged (soft ≤ hard); new limit binds exactly |
| child via `bash -c 'ulimit -n 524288'` | 524288 (hard) | **524285** | 524288 | **hard limit reachable** and equally binding |
| child `ulimit -n 700000` | >hard | — | — | `ulimit: cannot modify limit: Operation not permitted` (rc 1) |

**Answers:** yes, a child can `ulimit -n 65536` (and up to 524288) — soft may be raised to any value ≤ hard by the unprivileged user. The hard limit 524,288 is fully reachable and enforced. It cannot be exceeded (EPERM). So the true FD ceiling of one process is **524,288**, with the session default at 1,024. (The 818 MB/s "zeros" from earlier probing was about disk, not FDs — see §4.)

---

## 3. PROCESS / THREAD CEILING

Constraints present: `RLIMIT_NPROC` soft=hard=**7917** (per-uid task count, includes threads); cgroup `pids.max = max` (no cgroup cap). Kernel `threads-max` = 15,835 (irrelevant; rlimit binds first).

**Fork test** (C binary, children `setsid()+pause()`):

```
RLIMIT_NPROC soft=7917 hard=7917    pids.max=max  pids.current=3
  500 children ... 0.0s    ...    7500 children ... 0.5s
FORK_FAIL after 7914 children this run: errno=11 (Resource temporarily unavailable)
FORK TOTAL 7914 children in 1.7s (cum avg 0.22 ms/fork)
```

- **Ceiling: 7,914 simultaneous children** (1.7 s, fork rate ≈ 0.07–0.22 ms/fork, essentially hardware speed), then `fork()` returns **EAGAIN (errno 11)**.
- 7,914 = 7,917 (RLIMIT_NPROC) − 3 tasks already running (forktest + bash + watchdog). Exactly the rlimit, not `pids.max` (which is `max`).
- Children were all SIGKILLed from the recorded pid file afterwards; `pids.current` returned to 2 and uid-1000 process count to ~1–4.

**Thread test** (C/pthread, 128 KiB stacks, one process):

```
1000 threads 0.1s ... 7000 threads 1.3s
THREAD_FAIL after 7914 threads: 11 (Resource temporarily unavailable)
THREAD TOTAL 7914 threads in 8.5s (avg 1.08 ms/thread) — all 7914 joined cleanly
```

- **Ceiling: 7,914 threads in one process** — same RLIMIT_NPROC counter (threads are tasks). `pthread_create` fails with EAGAIN (11) at the same global count.

**Answers:** process ceiling **7,914 live tasks** (fork or clone), enforced by **RLIMIT_NPROC = 7917** minus whatever your session already runs; `pids.max` is `max` and plays no role. 7,917 is therefore the theoretical cap of total uid-1000 tasks including the session itself.
- *Observation worth recording:* a python-driven fork loop was pathologically slow (~2,500 forks in ~10 min) while the C fork loop hit the ceiling in 1.7 s. The slowdown was environmental pressure (forked CPython interpreters carrying multi-GB address spaces under a 1.9 GB RAM cap → reclaim storms; the stray `oom_kill` counter increments from 2 to 20 accumulated exactly during those stress phases), **not** a platform fork-rate throttle — C forking proves the kernel path is unthrottled.

---

## 4. DISK — non-zero data, write vs sync

All data from `/dev/urandom` (via a 1 GiB random seed file; seed generation measured separately). Same physical device for `/` and `/home/user` (single ext4 `/dev/vda`, 25 GB, ~20 GB avail). Files deleted between runs so 15 GiB could fit; no ENOSPC was ever hit. **Write time** = `dd` wall clock (buffered); **sync time** = separate `sync` after each run (dirty-page flush).

| target | size | write wall | write rate | sync wall | durable rate (incl. sync) |
|---|---|---|---|---|---|
| seed gen: `/dev/urandom` → file | 1 GiB | 3.4 s | ~300 MiB/s (urandom+first write) | 0.1 s | — |
| `/home/user` (ext4 /dev/vda) | **15 GiB** | 48.0 s | **320 MiB/s** | 0.3 s | 318 MiB/s |
| `/home/user` | **5 GiB** | 21.5 s | **238 MiB/s** | 0.2 s | 236 MiB/s |
| `/home/user` | **1 GiB** | 2.2 s | 472 MiB/s | 0.3 s | 421 MiB/s |
| `/` (root dir, via sudo — same device) | 1 GiB | 0.9 s | 1,157 MiB/s (seed pages cache-warm) | 0.1 s | 1,088 MiB/s |

- **Real (non-zero) sustained numbers: 238–472 MiB/s** with writes, 0.2–0.3 s sync tails (writeback keeps up during long runs); the earlier **818 MiB/s figure was indeed meaningless** (all-zero pages: writeback of zero pages is nearly free on this stack). Sustained 15 GiB run ≈ **320 MiB/s** is the most representative device number; short/cache-warm runs read higher (470–1,150 MiB/s) because of page-cache absorption and host-disk variance.
- `/home/user` and `/` are the **same filesystem** (`df -T`: `/dev/root` on both) — "write to /" cannot be slower/faster than "write to /home/user"; 20 GB free is the shared hard ceiling (25 GB device, 4.1 GB used by the image).
- **Disk ceiling: 20 GB free (25 GB raw)**; every large file created (1+5+15 GiB + 2×1 GiB seeds + 900 MiB tmpfs file) was deleted — see §7.

### `/tmp` is RAM-backed — confirmed

| step | MemAvailable | cgroup memory.current | note |
|---|---|---|---|
| before 900 MiB write | 1,548 MiB | 1,597 MiB | |
| after 900 MiB to `/tmp/ramtest_900m` | **662 MiB (−886)** | 1,609 MiB (+12) | write took 0.6 s ≈ 1.5 GiB/s (RAM speed); tmpfs pages are un-reclaimable so MemAvailable falls ~1:1; cgroup delta small only because clean file cache was reclaimed in the same instant |
| after `rm` | 1,563 MiB (+16) | 708 MiB | fully released |

tmpfs cap: 993 MiB (`df /tmp`), so ~900 MiB is near its ceiling. Yes — `/tmp` is RAM.

---

## 5. CONCURRENCY — parallel tool calls

**Wave 1 — 8 identical `sleep 6` bash calls in one message:**

| call | START (s offset) | END | wall |
|---|---|---|---|
| 1 | +0.000 | +6.0035 | 6.138 s |
| 2 | +0.340 | +6.343 | 6.135 s |
| 3 | +0.727 | +6.731 | 6.139 s |
| 4 | +1.002 | +7.005 | 6.137 s |
| 5 | +1.359 | +7.363 | 6.162 s |
| 6 | +1.685 | +7.688 | 6.138 s |
| 7 | +2.019 | +8.023 | 6.171 s |
| 8 | +2.365 | +8.369 | 6.176 s |

All 8 overlapped in execution (call 8 started while call 1 was still running) and **every call took ~6.14 s = sleep 6 + ~0.15 s overhead — zero queuing.** No cap at 8.

**Wave 2 — 12 calls, atomic `flock` counter of live calls (sleep 8):**

observed `ACTIVE=` values at start: 1,2,3,4,5,6,7,8,9,10,10,10 → **peak 10 simultaneously live**; every call wall 8.10–8.19 s (sleep 8 + overhead) → again **zero queuing**.

**Answers:**
- Bash tool calls run **in parallel**; 10 simultaneous executions observed (12 issued; the last two saw 10 because the first finishers had already left — no slot starvation).
- **No per-session concurrency cap found up to 12 issued / 10 concurrent.** The only serialization is *dispatch*: calls launch ~0.35–0.9 s apart (orchestrator startup per call; pids increment ~5/call), but once launched they never wait for a slot. Practical throughput ≈ 1–3 call launches/s with unbounded overlap; wall-clock of an N-sleep wave ≈ N×0.35–0.9 s + sleep, not N×sleep.

---

## 6. CPU

### 6.1 `cpu.max` unenforced — confirmed

`cpu.max` = `max 100000`. 60 s burn with 2 busy threads pinned to both CPUs (`taskset -c 0-1`):

| cpu.stat | before burn | after burn | Δ |
|---|---|---|---|
| usage_usec | 139,670,883 | 258,868,020 | **+119,197,137 µs = 119.2 CPU-s** |
| user_usec | 9,677,510 | 128,874,647 | +119.2 CPU-s |
| nr_periods / nr_throttled / throttled_usec | 0 / 0 / 0 | 0 / 0 / 0 | **never throttled** |

119.2 of an ideal 120.0 CPU-s (2 cores × 60 s) = **99.3% of both cores for the whole minute**; `nr_throttled=0`, `throttled_usec=0` before and after. **`cpu.max` really is unenforced — there is no CPU ceiling; both cores are 100% usable.**

### 6.2 SMT topology vs measured penalty

Per `/sys`: cpu0 and cpu1 are **siblings on one physical core** (`thread_siblings_list = 0-1` on both, `core_id = 0` both, `physical_package_id = 0` both; total 2 CPUs).

`taskset`-pinned xorshift-loop measurements (8 s each, iterations/s):

| pin | threads | rate | vs single |
|---|---|---|---|
| cpu0 | 1 | 143.7 M it/s | 1.00× |
| cpu1 | 1 | 148.2 M it/s | 1.03× (run variance) |
| cpu0+cpu1 | 2 | 293.6 M it/s | **2.01×** of cpu0-single / 1.98× of cpu1-single |
| cpu0 only | 2 | 148.8 M it/s | 1.04× (two threads time-slice one vCPU — no gain, as expected) |

**Answer: per the topology files, cpu0 and cpu1 are SMT siblings on one physical core — but the SMT penalty is unmeasurable (zero):** two busy threads on the sibling pair run at a perfectly linear 2.0× single-thread throughput, i.e. the vCPUs behave like independent cores (guest topology is virtualized; the hypervisor is evidently backing them with separate host cores — true co-scheduled SMT typically yields only ~1.3–1.9×). 2 threads pinned to a *single* vCPU gain nothing (1.04×) as expected.

---

## 7. Cleanup — verification

| artifact | state |
|---|---|
| 15 GiB + 5 GiB + 1 GiB disk files, 2×1 GiB seeds, 900 MiB `/tmp` file, 1 GiB root test dir | **all deleted** |
| files >10 MB anywhere under `/home/user` after suite | **0** |
| `df /` | 4.1 G used / 20 G avail (exact pre-test state) |
| `/tmp` | 8.0 K used of 993 M |
| orphaned probe processes (7,914 fork children, 7,914 joined threads, 250 leaked python sleepers) | all killed & reaped (kill-by-pidfile + re-verify; `pids.current`=2, uid procs 1–4) |
| workspace footprint left behind | `ceiling/` dir: 66 KB of probe scripts + JSON/TSV logs + this report |
| `memory.events` (session end) | `low 0 high 0 max 0 oom 0 oom_kill 20 oom_group_kill 0` (2 from the bisection + 18 accumulated during python fork-stress phases; no probe was ever lost to them) |
| `cpu.stat` (session end) | `nr_throttled 0 throttled_usec 0` |
| rlimits | still `1024` / `7917` |

---

## 8. Executive summary of hard ceilings

| resource | hard ceiling (measured) | binding constraint |
|---|---|---|
| memory (one touched allocation) | **1,632 MiB ok / 1,664 MiB OOM-killed** (session survives; only child dies) | VM RAM 1,985 MiB − ~0.4 GiB resident agents; cgroup `memory.max` 1,857 MiB unreachable in a single allocation |
| file descriptors (per process) | **524,288** (session default 1,024) | `RLIMIT_NOFILE` hard; soft raisable to hard, not beyond |
| processes (fork) | **7,914** live children (EAGAIN after) | `RLIMIT_NPROC` 7,917 − running tasks; `pids.max=max` |
| threads (one process) | **7,914** (EAGAIN after) | same RLIMIT_NPROC |
| disk | ~20 GB free of 25 GB ext4 `/dev/vda`; sustained **~320 MiB/s** real random data (238–472 MiB/s range); `/home/user` = `/` | device size; writeback keeps sync ≤0.3 s |
| `/tmp` | 993 MiB RAM-backed tmpfs (MemAvailable drops 1:1) | tmpfs size |
| parallel bash tool calls | **≥10 concurrent, no queuing** at 12 issued | none found (dispatch ~0.35–0.9 s/call serialized) |
| CPU | **no ceiling** — 99.3% of 2×60 s achieved, `nr_throttled 0` | `cpu.max=max` truly unenforced |
| SMT | topology says 1 core / 2 siblings; **zero measured co-scheduling penalty** (linear 2.0×) | vCPUs behave as independent cores |

*Probe sources & raw data: `ceiling/scripts/{mem_probe,fd_probe,forktest,thrtest,burn,dup_loop,forkcal}.{py,c}` · `ceiling/out/{memory_probes.json,memory_probes.tsv,fd_probe.json,fd_ph*.txt}`*
