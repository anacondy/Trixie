Find the exact hard ceilings of this sandbox by bisection. Report a table of every probe.

1. MEMORY CEILING
   - baseline: MemAvailable, and RSS of all non-agent processes (`ps -eo rss=,comm= | sort -rn | head -15`)
   - allocate-and-TOUCH in 128 MiB steps in a subprocess (so an OOM kill does not kill this session):
     `python3 -c "import sys;n=int(sys.argv[1]);b=bytearray(n*1024*1024);b[::4096]=bytes(len(b[::4096]));print('ok',n)"`
   - run via `subprocess` and capture returncode; a -9 return is the OOM boundary
   - bisect to ±32 MiB. Report: last success, first kill, and
     `cat /sys/fs/cgroup/user/memory.events` before and after
   - does an OOM kill terminate the session or only the child?

2. FILE-DESCRIPTOR CEILING
   - soft limit is 1024. Confirm it bites: open files in a loop until failure, report the count
   - does `ulimit -n 65536` raise it for a child process? Is the hard limit reachable?

3. PROCESS / THREAD CEILING
   - fork until failure; compare against RLIMIT_NPROC (7917) and cgroup pids.max
   - max threads in one process

4. DISK
   - write 1 GB, 5 GB, 15 GB of NON-ZERO data (`/dev/urandom`) to /home/user, then to /
     report MB/s for each and where each fails — your earlier 818 MB/s used zeros, which is not a real number
   - `sync` timing separately from write timing
   - confirm /tmp is RAM-backed by writing 900 MiB there and watching MemAvailable fall

5. CONCURRENCY
   - how many `bash` tool calls run in parallel? Issue 8 and time them
   - is there a per-session concurrency cap?

6. CPU
   - is `cpu.max` really unenforced? Burn both cores for 60 s and read
     /sys/fs/cgroup/user/cpu.stat (nr_throttled, throttled_usec) before and after
   - confirm SMT: `cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list`
     and core_id — state whether cpu0 and cpu1 are siblings on one physical core
   - measure the SMT penalty: pin a compute loop to cpu0 only vs cpu0+cpu1 with `taskset`

Clean up every large file you create. Report cleanup verification.
