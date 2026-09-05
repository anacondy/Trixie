# envcheck — reproducible environment probe

This directory contains the probe, its raw (verbatim) output, and the verification
manifests behind `environment_characterization.md` (one level up).

```
envcheck/
├── probe_environment.sh         # the probe: writes verbatim transcripts + SHA-256 manifest
├── README.md                    # this file
├── raw/
│   ├── run_20260904T1116Z_original/   # historic run, produced manually BEFORE the probe existed
│   │   ├── 01_system.txt ... 23_preinstalled.txt   (26 verbatim transcripts + nohup_result.txt)
│   │   ├── MANIFEST.txt        # backfilled (may be informational; hashes are real, see note)
│   │   └── MANIFEST.sha256     # machine-checkable: sha256sum -c MANIFEST.sha256
│   └── run_20260904T141747Z/   # canonical run, produced by probe_environment.sh --full
│       ├── 00_meta.txt ... 16_envconfig.txt           (17 verbatim section transcripts)
│       ├── MANIFEST.txt        # run identity + per-file hashes (hash-anchored at capture)
│       └── MANIFEST.sha256     # machine-checkable: sha256sum -c MANIFEST.sha256   -> all OK
└── notes/                      # the original historic transcripts (unchanged, kept for lineage)
```

## Verify the published evidence

```bash
cd raw/run_20260904T141747Z && sha256sum -c MANIFEST.sha256   # expect all "OK"
cd raw/run_20260904T1116Z_original && sha256sum -c MANIFEST.sha256  # backfilled, all OK
```

## Reproduce

```bash
bash probe_environment.sh              # non-destructive default
bash probe_environment.sh --full       # + apt installs (sqlite3, ffmpeg) + OOM-kill ramp
bash probe_environment.sh --dir /tmp/myrun   # custom output location
bash probe_environment.sh --skip-apt --skip-oom --full   # full but touchless
```

Every run creates `raw/run_<UTC>/` with 17 numbered `NN_*.txt` transcripts
(`00_meta` … `16_envconfig`) plus `MANIFEST.txt` + `MANIFEST.sha256`, and finishes
with a self-check that fails (exit 1) if the manifest does not match the files.

Run metadata captured per run (in `00_meta.txt` and `MANIFEST.txt`):
hostname, kernel, arch, OS, user/uid/gid, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`,
`boot_id`, egress IP, flags, and the SHA-256 of the probe script itself.

## What to diff between runs

| Field | Stable in-place? | Notes |
|---|---|---|
| `boot_id` (`/proc/sys/kernel/random/boot_id`) | **Yes — the VM identity anchor** | constant across sessions of the same boot |
| kernel (`uname -r`), `/etc/os-release` | Yes (same template) | changes only if image/kernel updated |
| `E2B_SANDBOX_ID` env var | **No** | observed to round-robin between sessions of the same VM |
| egress IP (`api.ipify.org`) | No | NAT pool; may rotate |
| section measurements (latency, throughput, bench timings) | ~Yes with noise | compare per section; expect small jitter, not order-of-magnitude shifts |

## Sections ↔ subjects

| File | What it measures |
|---|---|
| `00_meta.txt` | run identity, IDs, probe hash |
| `01_runtime.txt` | OS/kernel/arch/libc/CPU flags/memory |
| `02_isolation.txt` | container markers, cgroup, namespaces, capabilities, seccomp, sudo |
| `03_tools.txt` | tool availability + versions, pip inventory |
| `04_limits.txt` | ulimits + cgroup limits/events |
| `05_filesystem.txt` | mounts, capacity, inodes, fs types |
| `06_fs_tests.txt` | write/read/delete integrity, 200 MB fdatasync, unicode names, RO probes |
| `07_dns.txt` | resolver, getaddrinfo timing, raw UDP:53 |
| `08_http_latency.txt` | HTTPS/HTTP connect+TLS+TTFB breakdown |
| `09_net_matrix.txt` | TCP connect matrix (18 endpoints), ICMP, IPv6, MTU, egress IP/geo |
| `10_download_throughput.txt` | real downloads (PyPI wheel, GitHub release asset, codeload, HF), parallel, uploads |
| `11_cpu_bench.txt` | CPython, Node, gcc (-O0/-O2/-O3/march=native), numpy |
| `12_disk_bench.txt` | dd (fdatasync / page-cache / O_DIRECT), small-file rates |
| `13_pkg_installs.txt` | pip (fresh venv), npm, git clone, apt (update + installs under `--full`) |
| `14_memory_pressure.txt` | 3 GB `MemoryError` probe + cgroup OOM ramp (`--full` only) |
| `15_services_processes.txt` | processes, sockets, systemd services, dmesg, nohup survival probe |
| `16_envconfig.txt` | environment variables, `/.e2b`, resolv.conf, locale |

## Caveats

- `14_memory_pressure.txt` deliberately trips the cgroup OOM killer under `--full`.
  It kills only the allocating child process; the shell and the VM survive (verified).
- `10_download_throughput.txt` fetches a ~17 MB wheel, a ~114 MB GitHub release asset
  and a ~30 MB codeload archive (plus a ~50 MB HF range and uploads). At the measured
  60–200 MB/s this is a few seconds of traffic, but it is real network egress.
- `13_pkg_installs.txt` under `--full` runs `sudo apt-get install sqlite3 ffmpeg`
  (~75 MB). Both were already installed in the environment that produced the report,
  so verification runs should not alter results.
- `nohup_result.txt` (in `15_services_processes.txt`'s run dir) is generated ~90 s
  after the run and is deliberately excluded from the manifest.
