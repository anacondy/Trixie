# session1 — provenance of the first (interactive) characterization pass

These are the ad-hoc one-off scripts from the exploratory session that produced
`../../environment_characterization.md`. They are kept **only** so the specific numbers quoted in
§5–§7 of the report can be traced to the exact code that printed them; they are superseded by
`../probe.sh`, which is parameterised, self-manifesting and re-runnable.

| file | produced | cited in report |
|---|---|---|
| ~~`dns_bench.py`~~ | **deleted during cleanup of the first session** — its stdout survives verbatim in `../legacy_raw/dns.txt`, but the script itself is gone; `../probe.sh` section `10_net_dns.txt` is the re-runnable equivalent | §5 Latency |
| `tcp_bench.py` | TCP connect medians + per-host TLS handshake split | §5 Latency |
| `portscan.py` | outbound TCP port matrix | §5 Blocks/anomalies |
| `net_throughput.py` | single-stream medians, stream scaling, upload | §5 Throughput |
| `net_workload.py` | 40x PyPI JSON API at 1/8/16/32 workers | §5 Throughput |
| `disk_bench.py` | 100 MiB ext4/tmpfs + many-small-files | §6 Disk I/O |
| `cpu_bench.py` / `cpu_bench2.py` | pure-python + numpy/pandas CPU | §6 CPU |
| `memtest.py` + `mem_progress.log` | OOM drive; log survived the SIGKILL | §7 memory pressure |
| `bg_start.txt` | start stamp for the nohup/setsid survival test | §7 background |

Notes on honesty: `cpu_bench.py` (first draft) aborted on a `gzip_compress` NameError and its
`sum(range(10**7))`/sieve numbers were re-taken by `cpu_bench2.py`; `net_throughput.py`'s upload block
never executed because a Cloudflare 429 aborted it — those upload figures come from the separate
`curl --data-binary` runs recorded in §5 (see `legacy_raw/throughput.txt` for the partial `tee` capture of that pass). `disk_bench.py` measured warm reads only; the cold/O_DIRECT
numbers in the report were added by a follow-up `drop_caches` + `pread` script not kept here.
