# env-probe — reproducible sandbox environment characterization

Raw-evidence probe kit. Produces **verbatim command transcripts** (no summarisation
layer), a **SHA-256 manifest**, and a **diff tool** so a third party can run the same
script and compare results against ours.

## Contents

| File | Purpose |
|---|---|
| `env_probe.sh` | Main probe. Emits 16 numbered `.txt` transcripts + `MANIFEST.json` + `SHA256SUMS.txt`. |
| `bench_cpu.py` | CPU / numpy / pandas / parallel-scaling microbenchmarks (invoked by section 11). |
| `diff_runs.sh` | Compares two runs: integrity check, host-identity table, per-section diff. |
| `runs/<UTC>_<sandbox_id>/` | One directory per run. |

## Usage

```bash
chmod +x env_probe.sh diff_runs.sh

./env_probe.sh              # standard run, ~2.5 min
QUICK=1 ./env_probe.sh      # skip 2 GiB write, sdist compile, sustained-CPU (~90 s)
FULL=1  ./env_probe.sh      # + unbounded npm-audit reproduction (can take ~15 min)
OUTDIR=/some/path ./env_probe.sh

./diff_runs.sh                          # auto-diff the two most recent runs
./diff_runs.sh runs/<runA> runs/<runB>  # explicit
```

Verify any run's integrity:

```bash
cd runs/<run_id> && sha256sum -c SHA256SUMS.txt
```

The script **always exits 0**. Probe failures are recorded as data (`[exit=N]` markers),
not treated as script errors — a blocked port or a missing binary is a finding.

## Output sections

| File | Contents |
|---|---|
| `01_runtime.txt` | uname, os-release, libc, boot_id, kernel cmdline |
| `02_isolation.txt` | virt detection, cgroup, capabilities, seccomp, namespaces, dmesg |
| `03_identity_limits.txt` | uid/gid, sudo, ulimits, cgroup v2 limit files, overcommit |
| `04_tooling.txt` | 70-tool availability matrix + versions |
| `05_python_env.txt` | interpreter paths, full distribution list, key-import probe, BLAS config |
| `06_filesystem.txt` | mounts, df, inodes, write/read/delete matrix across 9 paths |
| `07_dns.txt` | resolv.conf, routes, cold/warm resolution timing ×9 hosts |
| `08_net_latency.txt` | curl phase breakdown best-of-5, **est_rtt**, TLS/cert inspection |
| `09_net_matrix.txt` | throughput ×5 targets, egress port matrix (4 methods), UDP, IPv6, egress IP |
| `10_net_anomalies.txt` | ICMP, npm audit endpoints, POST/PUT control group |
| `11_bench_cpu.txt` | pure-Python, numpy (GFLOP/s), pandas, multiprocessing scaling |
| `12_bench_disk.txt` | dd sequential (fdatasync + O_DIRECT), cold/warm reads, metadata ops |
| `13_bench_install.txt` | pip (pure/wheel/sdist), gcc/g++, apt, npm, git clone — all timed |
| `14_memory_oom.txt` | allocation ceiling with page-touching, dmesg OOM records |
| `15_processes.txt` | ps, systemd services, listening sockets, background job, server bind, throttling |
| `16_env_config.txt` | env vars, platform config, persistence marker read/write |

## Methodology notes (important for interpreting results)

1. **`time_connect` is not RTT.** A local egress proxy terminates TCP, so connect time
   is ~1–2 ms to every host on Earth. Real RTT is estimated from the end-to-end TLS 1.3
   handshake: `est_rtt = (time_appconnect − time_connect) / 2`. Section 10's `sudo ping`
   provides independent ICMP corroboration.
2. **Bare `connect()` port scans produce false positives.** The proxy accepts
   optimistically. Section 09 therefore uses four methods: naive connect (Part A,
   unreliable), real protocol handshakes (Part B, authoritative), `portquiz.net` which
   listens on all ports (Part C), and UDP (Part D).
3. **Memory probes touch every 4096th byte** to defeat lazy overcommit. `rc=-9` is a
   kernel OOM SIGKILL, distinct from a Python `MemoryError` refusal.
4. **Timing** uses `time.perf_counter()` (1 ns resolution, monotonic) in Python and the
   bash `time` builtin with `TIMEFORMAT` in shell. `/usr/bin/time` and `bc` are **absent**
   on this image — scripts relying on them fail silently with empty output.
5. **Benchmarks report best-of-N and median.** Best-of-N approximates the unloaded
   machine; the gap to median indicates noisy-neighbour jitter.

## Known side effects

`env_probe.sh` **mutates the environment**:

- installs then uninstalls `tabulate`, `duckdb`, `polars`, `ujson` (pip)
- runs `apt-get update` and reinstalls `jq`
- writes/deletes up to 2 GiB temporarily under `/home/user`
- **overwrites** `/home/user/PERSISTENCE_MARKER.txt` and `/tmp/PERSISTENCE_MARKER_TMP.txt`
- briefly binds TCP port 877
- triggers a deliberate OOM kill (recorded in `dmesg`)

## Interpreting a diff

Most sections will show as CHANGED between any two runs — benchmark numbers never repeat
exactly. Only `04_tooling.txt` is typically byte-identical. When diffing, focus on
**structural** facts (tool presence, mount layout, capability sets, HTTP status codes,
OOM thresholds) rather than timing digits.

## Caveats

- Two runs on the same host is a weak sample. Network figures in particular vary with
  upstream conditions — see `ERRATA.md` for a finding that reproduced in run 1 and then
  **failed to reproduce** in run 2.
- `boot_id` was observed to be **identical across two different sandbox IDs** on this
  platform. Do not use it as a unique run identifier; use `run_utc` + `sandbox_id`.
