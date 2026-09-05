# Sandbox Hard-Ceiling Probe Report (bisection & stress)

Date: 2026-09-05 (Asia/Calcutta). All probes run as `uid=1000(user)` inside cgroup v2 `/sys/fs/cgroup/user`
(`0::/user`). Raw scripts/logs kept in `/home/user/probes/`. Every large file was deleted afterwards
(verification at the end).

---

## Baseline

| Fact | Value |
|---|---|
| MemTotal | 2032608 kB (**1984 MiB**) |
| MemAvailable (start) | 1530356 kB (~**1494 MiB**) |
| Swap | **0** (no swap; `memory.swap.max = max` but no swap device exists) |
| cgroup `memory.max` | **1947172864 B = 1856.75 MiB** (`memory.high` set equal) |
| cgroup `cpu.max` | `max 100000` (no quota) |
| cgroup `pids.max` | `max` (no limit) |
| CPUs | 2 (Intel Xeon @ 2.60 GHz) — SMT siblings, see §6 |
| Root fs | `/dev/vda` ext4, 25 GiB total, **20 GiB free**; `/home/user` is the same fs |
| `/tmp` | **tmpfs**, 993 MiB (RAM-backed) |
| RLIMIT_NOFILE | soft **1024**, hard **524288** |
| RLIMIT_NPROC | soft = hard = **7917** (per uid, counts threads) |
| kernel `pid_max` | 4194304 |

Top RSS processes (KiB, `ps -eo rss,comm | sort -rn | head -15`):

| RSS (KiB) | comm |
|---|---|
| 98260 | jupyter-server |
| 73436 | python3.13 |
| 66132 | uvicorn |
| 58328 | node |
| 39900 | node |
| 24784 | envd |
| 13988 | systemd |
| 10316 | systemd-network |
| 8952 | systemd-journal |
| 7732 | sshd |
| 7176 | systemd-logind |
| 3624 | dbus-daemon |
| 3560 | ps |
| 3164 | bash |
| 3028 | socat |

---

## 1. MEMORY CEILING

Method: child `python3` allocates `n MiB` bytearray and **touches one byte per 4096 B page**
(`b[::4096]=bytes(len(b[::4096]))`) so pages are actually committed; parent uses `subprocess`,
reads `returncode`; **-9 = SIGKILL by cgroup OOM killer**. Linear 128 MiB scan, then bisect to ±32 MiB.

| MiB | phase | returncode | wall s | result |
|---:|---|---:|---:|---|
| 256 | scan | 0 | 0.25 | OK |
| 384 | scan | 0 | 0.28 | OK |
| 512 | scan | 0 | 0.38 | OK |
| 640 | scan | 0 | 0.48 | OK |
| 768 | scan | 0 | 0.65 | OK |
| 896 | scan | 0 | 0.66 | OK |
| 1024 | scan | 0 | 0.67 | OK |
| 1152 | scan | 0 | 0.94 | OK |
| 1280 | scan | 0 | 1.11 | OK |
| 1408 | scan | 0 | 1.20 | OK |
| 1536 | scan | 0 | 1.08 | OK |
| **1664** | scan | **-9 (SIGKILL)** | 1.24 | **OOM kill** |
| 1600 | bisect | 0 | 1.30 | OK |
| **1632** | bisect | **0** | 1.13 | **OK — last success** |
| 1664 | (known) | -9 | — | **first kill (gap = 32 MiB)** |

**Result: last success = 1632 MiB, first kill = 1664 MiB — ceiling 1632–1664 MiB touched
(±32 MiB), consistent with `memory.max` = 1856.75 MiB minus ~200 MiB resident agent/runtime.**

`/sys/fs/cgroup/user/memory.events`:

| counter | before | after |
|---|---:|---:|
| low / high / max | 0 | 0 |
| oom | 0 | 0 |
| **oom_kill** | **0** | **1** |
| oom_group_kill | 0 | 0 |

`memory.current` returned to 16.6 MiB after the kill; MemAvailable recovered to 1665332 kB.

**Does an OOM kill terminate the session?** **No — only the child.** The probing parent
process, the `bash` tool shell, the jupyter/agent stack, and this conversation all survived
unchanged. Each allocation happened in a separate subprocess so the OOM killer reaped the
memory-hog child (SIGKILL → returncode -9) and nothing else.

---

## 2. FILE-DESCRIPTOR CEILING

Soft limit 1024. Opening `/dev/null` in a loop:

| Probe | Outcome |
|---|---|
| default (soft=1024) | `open()` fails with **EMFILE (errno 24) after 1018 fds** (Python already held 6) — soft limit **bites** |
| `setrlimit(NOFILE, 65536)` | succeeds; opens until **65530** fds then EMFILE |
| `setrlimit(NOFILE, 524288)` (= hard) | succeeds; opens until **524282** fds then EMFILE |
| `bash -c 'ulimit -n 65536; python3 …'` | child inherits **(65536, 65536)**; fails at 65530 fds — yes, `ulimit -n` raises it for children |

- **Hard limit = 524288 and it is fully reachable** by an unprivileged process (raising soft to
  hard works; opening 524282 fds takes ~0.5 s). Beyond 524288 is impossible without
  `CAP_SYS_RESOURCE`. The default 1024 is purely a soft-limit inconvenience.

---

## 3. PROCESS / THREAD CEILING

Constraints in play: cgroup `pids.max = max` (none), kernel `pid_max = 4194304`,
**RLIMIT_NPROC = 7917** (per uid; counts processes *and* threads).

| Probe | Result |
|---|---|
| **Threads in one process** (`threading.Thread`) | `RuntimeError: can't start new thread` at **7914 worker threads** (7915 tasks incl. main thread) |
| **Processes, fork+exec tiny `sleep 600`** | `OSError errno 11 (EAGAIN)` after spawning **7913 children**; total user tasks at failure = **7917** |
| Memory cost of tiny procs | +184 KiB/proc (mem.current 46 MiB @250 → 1449 MiB @7750); spawn rate ~1600 procs/s |
| Processes, **fork() without exec** (Python ~11 MiB image) | memory-bound: ~1.0–1.4 MiB committed per fork (page tables dup, no COW); fork rate collapsed after ~500 forks (250/1.0 s → 250/~180 s), severe reclaim thrash, OOM kills; ceiling not nproc but **RAM** |

- The hard task ceiling is exactly **RLIMIT_NPROC = 7917** for the uid (threads and processes
  share it); the cgroup imposes no PID limit.
- **Caveat found the hard way:** forking fat processes never reaches 7917 in a 1.86 GiB cgroup —
  ~1500 forks of the Python interpreter already saturate memory. During that first (buggy) test
  the tool's 600 s timeout orphaned ~1500 children; `oom_kill` in `memory.events` rose to 1349 as
  the kernel culled them, and the load hit 66 before recovery. The fork+exec test (tiny image)
  cleanly hit 7917 and self-cleaned (7913/7913 reaped).

---

## 4. DISK

All writes use **non-zero `/dev/urandom`** data. Write timing (dd → page cache) and `sync`
timing (device flush) measured separately. `/home/user` and `/` are the **same ext4 fs**
(`/dev/vda`); `/` root dir is not writable by `user` (EACCES) so root-fs probes ran via `sudo`.

| Path | Size | dd wall | dd-reported | sync wall | **End-to-end** |
|---|---:|---:|---:|---:|---:|
| /home/user | 1 GiB | 3.42 s | 314 MB/s | (merged)¹ | ~314 MB/s |
| /home/user | 5 GiB | 14.83 s | 362 MB/s | (merged)¹ | ~362 MB/s |
| /home/user | 15 GiB | 43.16 s | 373 MB/s | (merged)¹ | ~373 MB/s |
| `/` (sudo) | 1 GiB | 2.73 s | 394 MB/s | **0.39 s** | **327 MiB/s** |
| `/` (sudo) | 5 GiB | 14.59 s | 369 MB/s | 0.04 s | **350 MiB/s** |
| `/` (sudo) | 15 GiB | 43.38 s | 372 MB/s | 0.07 s | **354 MiB/s** |

¹ First wave used `conv=fdatasync` so flush was inside the dd time; the second wave
(`/`) separated them explicitly. `sync` costs ~nothing at the end because ext4 writeback
and dirty-page throttling already flush while dd runs.

- **Nothing failed at 1/5/15 GiB** — 15 GiB < 20 GiB free; the disk ceiling was not reached
  (would need >20 GiB to hit ENOSPC).
- **Real sustained write throughput ≈ 350–370 MB/s for non-zero data.** The earlier
  "818 MB/s" figure from zero-filled writes was indeed bogus (zero pages / compression / cache
  artefacts); urandom writes are the real number.

**`/tmp` is RAM-backed (tmpfs), confirmed:**

| Point | MemAvailable | Shmem/tmpfs use |
|---|---:|---:|
| before 900 MiB write | 1607.6 MiB | ~1 MiB |
| with 900 MiB resident | **705.6 MiB** (−**902 MiB**) | `/tmp` 91% full (901/993 MiB) |
| after `rm` | 1609.9 MiB | ~0 |

900 MiB of urandom wrote at 445 MiB/s into tmpfs and MemAvailable dropped by essentially the
full file size, recovering fully on delete → `/tmp` storage comes straight out of RAM (and
therefore competes with the 1857 MiB cgroup memory cap).

---

## 5. TOOL-CALL CONCURRENCY

Eight `bash` calls issued in a single response, two waves.

**Wave 1 — 8 calls × `sleep 8`** (epoch seconds, relative to c1 start):

| call | start offset | end offset | sleep observed |
|---|---:|---:|---:|
| c1 | 0.00 | 8.00 | 8.0 s |
| c2 | 1.43 | 9.42 | 8.0 s |
| c3 | 2.84 | 10.84 | 8.0 s |
| c4 | 5.02 | 13.02 | 8.0 s |
| c5 | 5.92 | 13.93 | 8.0 s |
| c6 | 7.32 | 15.32 | 8.0 s |
| c7 | 8.58 | 16.57 | 8.0 s |
| c8 | 10.24 | 18.24 | 8.0 s |

**Wave 2 — 8 calls × `sleep 20`**: all 8 dispatched within an 8.1 s window and every one
slept a full 20.0–20.3 s with zero queueing — all overlapped for ≥12 s of concurrent runtime.

- **At least 8 `bash` tool calls run in parallel**; with 20 s tasks there is no sign of a
  per-session concurrency cap (≥8, likely higher). Calls are dispatched with a ~0.9–2.2 s
  launch stagger (ramp-up cadence), not serialized execution.

---

## 6. CPU

### 6a. Is `cpu.max` enforced? — No.

60 s burn, 2 pinned busy processes (`taskset -c 0,1`), `/sys/fs/cgroup/user/cpu.stat`:

| counter | before | after |
|---|---:|---:|
| usage_usec | 612040868 | 731479501 |
| user_usec | 37133075 | 156000378 |
| system_usec | 574907792 | 575479122 |
| nr_periods | 0 | **0** |
| **nr_throttled** | 0 | **0** |
| **throttled_usec** | 0 | **0** |

User time rose **+118.9 s over 60 s wall = 1.98 cores fully busy** and **zero throttling**.
`cpu.max = max` is genuinely unenforced — you get both vCPUs at 100%.

### 6b. SMT topology — cpu0 and cpu1 ARE siblings on one physical core.

```
/sys/devices/system/cpu/cpu0/topology/thread_siblings_list -> 0-1
/sys/devices/system/cpu/cpu1/topology/thread_siblings_list -> 0-1
cpu0: core_id=0 physical_package_id=0
cpu1: core_id=0 physical_package_id=0
/proc/cpuinfo: cpu cores=1, siblings=2, flags include 'ht'
```

⇒ **1 physical core, 2 hyperthreads** (SMT), not 2 cores.

### 6c. SMT penalty (pure-ALU LCG compute loop, 30 s windows, work = loop batches)

| Configuration | Work done (batches) | vs. one thread alone |
|---|---:|---|
| 1 thread on cpu0, sibling idle | **1418** | 1.00× (baseline) |
| 2 threads both on cpu0+cpu1 (SMT pair) | **2682** (1330 + 1352) | **1.89× aggregate** |
| 2 threads confined to cpu0 only (timesharing 1 HT) | 1390 (696+694) | 0.98× |
| 2 threads confined to cpu1 only | 1396 (697+699) | 0.98× |

Per-thread throughput when the sibling is also busy: 1341 vs 1418 alone → **~5% per-thread
SMT penalty** for this workload; two hyperthreads deliver **~1.9×**, not 2×. (Penalty is
workload-dependent — larger for cache/branch-heavy code.)

---

## Summary of hard ceilings

| Resource | Hard ceiling | Enforced by |
|---|---|---|
| Memory (touched, in child) | **1632 MiB OK / 1664 MiB SIGKILL** (±32 MiB) | cgroup `memory.max` 1856.75 MiB; OOM kills child only, session survives |
| Open files (soft) | **1024** (EMFILE at 1018) | RLIMIT_NOFILE soft; raisable to hard |
| Open files (hard) | **524288** reachable (EMFILE at 524282) | RLIMIT_NOFILE hard |
| Threads/processes per uid | **7917 tasks** (threads failed @7915; procs @7917) | RLIMIT_NPROC; cgroup pids.max = unlimited |
| Fat-process fork limit | ~1500 Python forks before RAM thrash | cgroup memory (practical, not nominal) |
| Disk `/` (ext4 vda) | 20 GiB free; 15 GiB write OK; **~350–370 MB/s** urandom sustained | ext4 capacity; 818 MB/s zeros was fake |
| `/tmp` | tmpfs **993 MiB**, RAM-backed; counts against memory cap | tmpfs size |
| Tool-call parallelism | **≥8 concurrent** bash calls, no cap observed at 8 | harness dispatch |
| CPU | 2 vCPUs = **1 physical core + SMT sibling**, **unthrottled** (`nr_throttled=0`), SMT gives ~1.9× | `cpu.max = max` |

---

## Cleanup verification

- All large test files removed: `probe_{1g,5g,15g}.bin` in `/home/user` and `/` (sudo),
  `/tmp/probe_900m.bin`; `find` shows no `probe_*`/`*.bin` left.
- `df -h /`: back to **4.1 GiB used / 20 GiB free**; `/tmp` back to **72 KiB**.
- Memory: MemAvailable back to ~1.6 GiB; `memory.current` in cgroup back to ~16 MiB baseline.
- No stray processes: `cgroup.procs` = 3 (the shell harness only); all 7913 sleep children
  reaped; fork orphans killed/reaped; load back to ~0.3.
- Retained in `/home/user/probes/` (76 KiB total): the probe scripts and their logs
  (`mem_bisect.py/log`, `fd_test.py`, `fork_exec_test.py/log`, `fork_test.py`, `thread_test.py/log`,
  `disk_test*.sh/log`, `tmp_test.sh/log`, `cpu_burn.py`, `smt_penalty.py`) for reproducibility.
