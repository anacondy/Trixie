# envchar probe

Third-party re-runnable environment characterization.

## Run

```bash
cd envchar
chmod +x probe.sh
./probe.sh
```

Writes verbatim transcripts to `raw/*.txt`, then `MANIFEST.txt` and `SHA256SUMS`.

Optional:

```bash
ENVCHAR_SKIP_DOWNLOADS=1 ENVCHAR_SKIP_MEMORY=1 ./probe.sh
ENVCHAR_OUT=/tmp/myraw ./probe.sh
```

## Verify a published run

```bash
cd envchar
sha256sum -c SHA256SUMS
```

## Diff against another machine / sandbox

```bash
./probe.sh
diff -ru raw/ /path/to/other/raw/
```

Latency, PIDs, sandbox IDs, and timestamps **will** differ. OS, CPU count, cgroup `memory.max`, tool versions, and hard restrictions should match on the same template.

## Files

| File | Contents |
|---|---|
| `01_runtime.txt` | OS, kernel, libc, clock |
| `02_isolation.txt` | VM/container signals, cgroup, LSM, E2B |
| `03_user_limits.txt` | user, sudo, ulimit, cpuinfo, meminfo |
| `04_cgroup.txt` | cgroup v2 memory/cpu/pids |
| `05_environment.txt` | env vars |
| `06_tools.txt` | tool presence + versions |
| `07_python_packages.txt` | pip list + imports |
| `08_filesystem.txt` | df, inodes, write tests |
| `09_net_matrix.txt` | DNS + TCP/UDP latency |
| `10_net_throughput.txt` | curl/wget downloads |
| `11_net_ports.txt` | outbound port probe + TLS certs |
| `12_cpu_bench.txt` | Python/numpy/gcc benches |
| `13_disk_bench.txt` | 80 MiB sequential I/O |
| `14_installs.txt` | apt/pip/npm/git timings |
| `15_memory.txt` | allocation pressure |
| `16_misc.txt` | ping, traceroute, bind, listeners |
| `MANIFEST.txt` | timestamp, sandbox/template IDs, SHA-256 of each raw file |
| `SHA256SUMS` | `sha256sum -c` compatible |
