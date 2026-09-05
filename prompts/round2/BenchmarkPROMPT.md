Run this benchmark EXACTLY as specified. Do not substitute endpoints, sizes, dtypes or
timing methods. Report raw numbers only; no interpretation.

TIMING: python time.perf_counter(). REPEATS: 5 for all CPU tests, 3 for all I/O and
network tests. Report every individual run AND min/median/max. Use min as the headline.
WARMUP: one discarded run before every timed test.

CPU (all float64 unless stated; print dtype and n with each result):
  C1 sum(range(10**7))                              [pure python]
  C2 sum(i*i for i in range(10**7))                 [generator]
  C3 np.arange(10**7, dtype=np.float64).sum()
  C4 a=np.random.rand(1000,1000); a@a               -> report GFLOP/s using 2*n^3
  C5 np.sort(np.random.rand(5_000_000))
  C6 np.fft.fft(np.random.rand(2**22))
  C7 taskset -c 0 <C1>  and  taskset -c 0,1 <C1>    -> SMT scaling ratio

I/O:
  I1 write 256 MiB of os.urandom to /home/user, fsync, report MB/s   [NOT zeros]
  I2 read it back with O_DIRECT if available, else after dropping caches
  I3 write 256 MiB to /tmp; record MemAvailable before/after to prove it is RAM

NETWORK (report each run; do not average across different endpoints):
  N1 https://speed.cloudflare.com/__down?bytes=100000000   x3 sequential, x3 parallel
  N2 pip download --no-cache-dir numpy (16.7 MB wheel), cold, x3
  N3 curl -w '%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}'
     against pypi.org, github.com, huggingface.co  x3 each

ENVIRONMENT (print once, with the results, so the run is self-describing):
  date -u +%FT%TZ ; cat /.e2b ; echo $E2B_SANDBOX_ID ; grep MemTotal /proc/meminfo ;
  cat /sys/fs/cgroup/user/{memory.max,cpu.max,cpuset.cpus.effective} ;
  python3 -V ; python3 -c 'import numpy;print(numpy.__version__, numpy.show_config())' | head -20

Delete every file you create.
