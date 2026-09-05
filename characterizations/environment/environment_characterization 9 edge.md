# Environment characterization

**Measurement window:** 2026-09-04 12:11–12:18 UTC (17:41–17:48 IST)  
**Working directory tested:** `/home/user`  
**Scope:** point-in-time measurements in this sandbox; network and shared-host performance can change between runs.

## Executive summary

This is a full KVM guest/microVM rather than a conventional Docker container: Debian 13.6, kernel 6.1.158+, x86-64/glibc 2.41, with 2 vCPUs, a 1.813 GiB user-cgroup memory ceiling, and 19.751 GiB free on the live ext4 filesystem. Python, Node.js, Git, curl/wget, GCC/Make, `jq`, and `apt` are usable, and real isolated `pip`, local `npm`, native compilation, and system-package installation tests all succeeded; Docker, FFmpeg, Clang, Conda, and a GPU are absent initially. IPv4 Internet access is generally fast but highly endpoint-dependent (roughly 2.785–126.926 MiB/s in the tested downloads); there is no working global IPv6 route, and native Git protocol on port 9418 connected at TCP level but then timed out. The largest operational risk is persistence: live disk capacity is much larger than the best-effort workspace snapshot allowance, while `/tmp`, running processes, system package installs, and common dependency/build directories must be treated as ephemeral.

## 1. Runtime and isolation

### 1.1 Exact runtime identity

| Item | Observed value |
|---|---|
| Distribution | Debian GNU/Linux 13 (trixie), `DEBIAN_VERSION_FULL=13.6` |
| Kernel | `6.1.158+` — build `#1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026` |
| Architecture | `x86_64`, 64-bit, little-endian, 4 KiB pages |
| libc | glibc 2.41 (`Debian GLIBC 2.41-12+deb13u3`) |
| CPU | 2 logical CPUs; generic Intel Xeon Processor @ 2.60 GHz; 1 core / 2 threads; AVX2 and AVX-512 exposed |
| Hostname | `e2b.local` |
| PID 1 | `/sbin/init` (`systemd`) |
| Environment time zone | `Etc/UTC` |
| GPU | None exposed; `nvidia-smi` absent |

### 1.2 VM/container/sandbox signals

The evidence strongly identifies a **KVM virtual machine or microVM**, not a nested Docker-style container:

- `systemd-detect-virt` returned `kvm`; `--container` returned `none` and `--vm` returned `kvm`.
- Kernel boot logs say `Hypervisor detected: KVM`, use `kvm-clock`, and expose a virtio block device as `/dev/vda`.
- `/` is a directly mounted ext4 filesystem on `/dev/vda`, not overlayfs.
- `/.dockerenv` and `/run/.containerenv` are absent; Docker/containerd sockets are absent.
- PID 1 is a real systemd instance, kernel threads are visible, and the tested shell shares PID, mount, network, IPC, UTS, user, time, and cgroup namespace IDs with PID 1.
- The guest uses a link-local virtual interface (`169.254.0.21/30`) and gateway (`169.254.0.22`), consistent with sandbox orchestration.
- Sandbox-specific environment variable names are present: `E2B_SANDBOX`, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, and `E2B_EVENTS_ADDRESS`. Values were deliberately not copied into the report.
- Nested KVM is not exposed (`/dev/kvm` absent), although `/dev/fuse` is present.

The effective isolation boundary is therefore primarily the **hypervisor and platform lifecycle/network layer**, not a restrictive container profile inside the guest.

### 1.3 User, privilege, capabilities, and security filters

| Check | Result |
|---|---|
| Current identity | `user`, UID 1000, GID 1000 |
| Supplementary groups | `sudo`, `users` |
| Direct root login | No; normal commands start as UID 1000 |
| Sudo | `/usr/bin/sudo`; `sudo -n true` succeeded (passwordless, noninteractive root) |
| Normal-user capabilities | Effective/permitted sets empty |
| Root capabilities | Full bounding/permitted/effective set through `CAP_CHECKPOINT_RESTORE` (`0x1ffffffffff`) |
| Seccomp | Mode 0, zero filters for both tested user and sudo-root processes |
| `NoNewPrivs` | 0 |
| SELinux | LSM present but enforcement disabled (`/sys/fs/selinux/enforce = 0`) |
| User namespaces | `unshare -Ur true` succeeded |
| Root mount namespaces | `sudo unshare -m true` succeeded |

A normal-user `ping` fails because the process has no `CAP_NET_RAW`; the same ICMP tests work with `sudo`. Since passwordless sudo has full capabilities, this is an inconvenience rather than a hard restriction inside the VM.

### 1.4 Resource limits

| Resource | Limit / observation |
|---|---|
| CPU allocation | CPUs `0-1` effective; `cpu.max = max 100000` (no quota); `cpu.weight = 50` |
| Guest RAM | 2,081,390,592 bytes reported by `free` (about 1.938 GiB) |
| User-cgroup memory | `memory.max = memory.high = 1,947,172,864` bytes = 1,856.969 MiB = **1.813 GiB** |
| Swap | Guest has 0 bytes of swap; effective swap capacity is therefore none |
| User-cgroup PIDs | `pids.max = max`; shell `RLIMIT_NPROC = 7,917` |
| Open files | Soft 1,024, hard 524,288; a child shell successfully raised the soft limit to 524,288 |
| Stack | 8 MiB soft, unlimited hard |
| Locked memory | 8 MiB soft/hard |
| Core files | Disabled (`RLIMIT_CORE = 0`) |
| File size / virtual memory / CPU time | Unlimited at the rlimit layer |
| Cgroup I/O throttle | No entries in `io.max` |
| Cgroup CPU throttling at initial survey | None recorded (`nr_throttled = 0`) |
| Pressure Stall Information | `/proc/pressure/*` and per-cgroup pressure files unavailable |

There is no hard CPU quota, but the weight of 50 can matter if other cgroups compete for CPU. The memory ceiling and absence of swap are the much more important limits.

## 2. Tooling and language runtimes

### 2.1 Availability and versions

| Tool/runtime | Available | Version / path |
|---|:---:|---|
| Python 3 | Yes | CPython **3.13.14**, `/usr/local/bin/python3` |
| `pip` / `pip3` | Yes | **26.1.2**, Python 3.13 |
| Node.js | Yes | **v20.20.2**, `/usr/bin/node` |
| npm / npx | Yes | **10.8.2** |
| Corepack | Yes | **0.34.6**; Yarn/pnpm shims not initially activated |
| Git | Yes | **2.47.3** |
| curl | Yes | **8.14.1**, OpenSSL 3.5.6, HTTP/2 and HTTP/3 libraries compiled in |
| wget | Yes | **1.25.0** |
| FFmpeg / ffprobe | **No** | Not installed initially |
| Docker / Podman | **No** | No CLI and no daemon socket |
| GNU Make | Yes | **4.4.1** |
| GCC / G++ | Yes | **14.2.0** |
| Clang / Clang++ | **No** | Not installed initially |
| CMake / Ninja | **No** | Not installed initially |
| `pkg-config` | Yes | **1.8.1** |
| `jq` | Yes | **1.7** |
| SQLite CLI | **No** | `sqlite3` command absent (Python may still provide its stdlib module) |
| apt / apt-get | Yes | **3.0.3**, amd64 |
| dpkg | Yes | **1.22.22** |
| apk / yum / dnf | **No** | Not applicable on this Debian image |
| Conda / Mamba / Micromamba | **No** | Not installed |
| uv / pipx / Poetry | **No** | Not installed |
| Go | **No** | Not installed |
| Rust / Cargo | **No** | Not installed |
| Java / javac | Yes | OpenJDK **11** / `javac 11` |
| R | Yes | **4.5.0** |
| Perl | Yes | **5.40.1** |
| Ruby / PHP | **No** | Not installed |
| OpenSSH client | Yes | **10.0p2 Debian-7+deb13u4** |
| OpenSSL | Yes | **3.5.6** |
| tar / unzip | Yes | GNU tar **1.35** / Info-ZIP **6.00** |
| rsync / 7-Zip / aria2 | **No** | Not installed |
| ping | Yes | iputils **20240905**; requires sudo in this guest |
| dig / host / nslookup / netcat | **No** | Not installed initially |
| socat | Yes | Available |
| fio / hyperfine / stress-ng | **No** | Not installed |
| External `/usr/bin/time` | **No** | Bash `time` remains available |
| Pandoc | **No** | Not installed |

The Python installation already has 180 distributions. Relevant preinstalled data packages include NumPy 2.3.5, pandas 2.2.3, SciPy 1.17.1, Requests 2.33.0, HTTPX 0.28.1, aiohttp 3.14.1, scikit-learn 1.6.1, Matplotlib 3.10.9, Pillow 12.3.0, Beautiful Soup 4.15.0, and lxml 6.1.1. PyArrow, Polars, PyTorch, and TensorFlow are absent.

### 2.2 Real package/install and compilation tests

| Test | Result | Wall time | Notes |
|---|:---:|---:|---|
| `python3 -m venv` | Pass | 2.265217 s | Isolated venv in `/tmp` |
| `pip --no-cache-dir` pure-Python install | Pass | **0.587873 s** | Installed and imported `pyfiglet==1.0.2`; 1.1 MB wheel; test venv removed |
| Local npm install | Pass | **0.574799 s** | Installed and required `is-number@7.0.0`; local tree removed |
| `apt-get update` | Pass | 0.926034 s | Debian and NodeSource repositories reachable; mostly cached indexes |
| Actual system package install | Pass | **2.071882 s** | Installed `tree` 2.2.1, ran it, then purged it |
| Direct GCC compile | Pass | **0.225725 s** | C program compiled with `-O2 -Wall -Wextra` and ran correctly |
| Make-driven GCC compile | Pass | 0.042270 s | Independent output binary ran correctly |

**Conclusion:** pure-Python packages, local npm packages, Debian system packages, and native C compilation all work. `apt` has real network access and passwordless root; missing tools such as FFmpeg or Clang can likely be installed during a live VM session. System installations and temporary dependency trees should not be assumed to survive a recreated sandbox, so a reproducible bootstrap script or lockfile remains necessary.

## 3. Filesystem and persistence

### 3.1 Mounts, capacity, and inodes

| Location | Backing / options | Capacity | Free at test | Inodes free |
|---|---|---:|---:|---:|
| `/`, `/home/user`, `/var/tmp` | `/dev/vda`, ext4, `rw,relatime,discard` | 25,860,014,080 B = 24.084 GiB | 21,207,183,360 B = **19.751 GiB** | 6,623,483 / 6,759,792 |
| `/tmp` | tmpfs, `rw,nosuid,nodev` | 1,040,695,296 B (~992.5 MiB) | 1,040,683,008 B | 1,048,564 / 1,048,576 |
| `/dev/shm` | tmpfs, `rw,nosuid,nodev` | 1,040,695,296 B (~992.5 MiB) | essentially all free | 254,075 / 254,076 |

Important consequences:

- `/tmp` is **RAM-backed**, not disk-backed. Large temporary downloads or extraction there consume the same scarce memory budget and are bounded at about 993 MiB.
- `/var/tmp` is on the ext4 disk and is preferable to `/tmp` for large live-session scratch data, but it is not the durable workspace boundary.
- `/home/user` is mode `0700`; `/usr/local` is unusually mode `0777` and directly writable by the normal user.
- Only systemd credential ramfs mounts were explicitly read-only. `/proc` and `/sys` are virtual filesystems; arbitrary file creation there failed even as root despite their top-level mount being shown as `rw`.

### 3.2 Write/read/delete tests

| Location | Normal user | Sudo/root |
|---|---|---|
| `/home/user` | Pass | Not needed |
| `/tmp` | Pass | Not needed |
| `/var/tmp` | Pass | Not needed |
| `/dev/shm` | Pass | Not needed |
| `/usr/local` | Pass | Pass |
| `/` | Permission denied | Not modified in the root test |
| `/root` | Permission denied | Pass |
| `/etc` | Not attempted as user | Pass |
| `/sys` | Permission denied | Arbitrary creation failed |
| `/proc` | Arbitrary creation failed | Arbitrary creation failed |

All successful tests wrote a unique payload, read it back byte-for-byte, and deleted it.

### 3.3 Persistence characterization

A 31-byte sentinel created in `/home/user` and another in `/tmp` both survived more than five minutes and many independent command invocations in the same running VM. That only proves **same-VM** persistence, not survival through VM recreation. The `/tmp` probe was deleted; `/home/user/.environment_characterization_persistence_probe` was intentionally retained so a later message/session can test the workspace boundary again.

Operationally, use the following persistence model:

- Treat ordinary files under `/home/user` as the workspace persistence boundary.
- Treat `/tmp`, `/var/tmp`, process state, installed apt packages, and changes outside the workspace as ephemeral across recreated sessions.
- Common generated/cache directory names—including `.venv`, `node_modules`, `build`, `dist`, `out`, `target`, `coverage`, `.cache`, `.npm`, `.next`, `.vite`, and `__pycache__`—are excluded from workspace snapshots. Do not place irreplaceable data there.
- Workspace snapshotting is best-effort and approximately capped around **128 MB or 10,000 files**. This limit was not destructively stress-tested. The 19.751 GiB live free-space figure therefore must not be confused with cross-session durable capacity.

For a research pipeline, checkpoint compact results as normal files under `/home/user`, keep raw/large data in an external durable store, and recreate package environments from lockfiles at startup.

## 4. Network characterization

### 4.1 Method

- `/etc/resolv.conf` points directly to `8.8.8.8`; no HTTP(S), SOCKS, or `NO_PROXY` environment variables were set.
- DNS timings are five `socket.getaddrinfo()` calls per hostname. Direct 8.8.8.8 DNS is three hand-built UDP A queries.
- ICMP values are five IPv4 packets run under `sudo`, because unprivileged raw sockets are denied.
- HTTPS values are medians of three fresh IPv4 curl processes. Columns are cumulative from request start: DNS complete, TLS ready, first byte, and total. These were small real GETs, not HEAD-only probes.
- Download speed is curl's whole-transfer average, including connection setup and server wait. It is endpoint/object/CDN specific, not a guaranteed line rate.

### 4.2 DNS, ICMP, and HTTPS latency

| Target | DNS median (range), ms | ICMP avg, ms | TLS-ready median, ms | TTFB median, ms | HTTPS total median, ms | HTTPS probe payload |
|---|---:|---:|---:|---:|---:|---:|
| `google.com` | 2.051 (1.005–3.266) | **0.555** | 17.377 | 20.902 | **21.338** | 1,527 B |
| `8.8.8.8` | 1.436 (0.663–1.504), direct UDP DNS | **0.490** | 11.352 | 17.105 | **17.385** | 160–185 B DoH response, TLS forced to 8.8.8.8 |
| `github.com` | 1.082 (0.970–1.347) | 9.749 | 21.800 | 31.322 | **31.442** | 623 B |
| `pypi.org` | **0.926** (0.750–1.055) | 7.802 | 21.116 | 28.714 | **30.663** | 32,803 B |
| `huggingface.co` | **30.883** (2.155–32.894) | 6.538 | 35.041 | 142.928 | **143.022** | 68 B |

All ICMP probes had 0% loss. One of three GitHub HTTPS requests had a 124 ms first-byte outlier; the other two completed in about 29–31 ms. Hugging Face was consistently slower at the HTTP layer even though its ICMP RTT was only 6.5 ms, and its DNS timing was unusually variable.

The sub-millisecond Google/8.8.8.8 guest-visible RTTs and very short TCP setup times likely reflect a nearby edge and/or accelerated virtual egress; they should not be interpreted as physical distance. One Cloudflare response identified an `SJC` edge, so this VM's egress is not behaving like a Jaipur residential connection.

### 4.3 Real download and upload throughput

| Endpoint/object | Bytes | Total time | Average throughput | Validation / note |
|---|---:|---:|---:|---|
| Google CDN: first 5,000,000 B of current Chrome `.deb` | 5,000,000 (4.768 MiB) | **37.568 ms** | **126.926 MiB/s (1,064.74 Mbit/s)** | HTTP 206; range and Debian package header verified |
| GitHub codeload: `git` v2.46.0 tarball | 11,255,537 (10.734 MiB) | **1.750932 s** | **6.131 MiB/s (51.43 Mbit/s)** | Gzip integrity passed |
| PyPI files CDN: NumPy 2.3.5 CPython 3.13 wheel | 16,597,430 (15.829 MiB) | **1.016078 s** | **15.578 MiB/s (130.68 Mbit/s)** | Size matched PyPI metadata; ZIP test passed |
| Hugging Face: `sshleifer/tiny-gpt2` model | 2,514,146 (2.398 MiB) | **0.488611 s** | **4.907 MiB/s (41.16 Mbit/s)** | One redirect followed |
| Cloudflare speed endpoint download | 10,000,000 (9.537 MiB) | **3.424626 s** | **2.785 MiB/s (23.36 Mbit/s)** | Exact requested byte count |
| Cloudflare speed endpoint upload | 10,000,000 (9.537 MiB) | **0.408041 s** | **23.372 MiB/s (196.06 Mbit/s)** | HTTP 200; exact upload count |

The Cloudflare sample was strongly asymmetric: upload was about **8.4× faster** than download. Because the Google sample was much faster and the relevant package/CDN endpoints landed between them, this looks endpoint/path/throttling dependent rather than a simple sandbox-wide bandwidth cap. The required large-file test succeeded with the 11.26 MB GitHub tarball; all bulky artifacts were removed afterward.

### 4.4 Protocols, ports, failures, and restrictions

| Probe | Result |
|---|---|
| IPv4 DNS over UDP/53 to 8.8.8.8 | Pass; three valid replies |
| TCP/53 to 8.8.8.8 | Connected |
| HTTP/80 | Pass to Google, GitHub, PyPI, and Hugging Face |
| HTTPS/443 | Pass to all required targets |
| SSH/22 to GitHub | Transport reached in 0.478603 s; expected `Permission denied (publickey)` without credentials |
| Git HTTPS | `git ls-remote` succeeded in 0.750388 s |
| Native Git/9418 | TCP handshake succeeded, but `git ls-remote git://...` produced no result and timed out at 30 s; treat as unusable |
| ICMP | Works with sudo; normal user lacks raw-socket capability |
| IPv6 | **Unavailable**: only link-local IPv6 exists, no default route; all four `curl -6` probes failed immediately |
| Plain-HTTP captive portal check | No captive portal seen: Google returned 204, example.com 200, GitHub a normal 301 to HTTPS |

No restriction was observed for tested IPv4 UDP DNS, HTTP, HTTPS, or SSH. Port 9418's application-level timeout cannot be conclusively assigned to the sandbox versus the remote service, but HTTPS Git is the reliable choice.

## 5. Performance micro-benchmarks

The CPU process was pinned to one vCPU; initial load average was 0.08/0.08/0.03. Timings use `time.perf_counter_ns()` around only the described operation unless noted.

| Benchmark | Runs / data | Time | Effective rate |
|---|---|---:|---:|
| `sum(range(10**7))` on CPython 3.13 | Median of 5; result 49,999,995,000,000 | **0.194683 s** | 51.365 million integers/s |
| Explicit Python integer loop | Median of 3 × 10,000,000 iterations; shift/XOR/add/mask | **2.079108 s** | 4.810 million iterations/s |
| NumPy `sum((a*a) % 97)` | Median of 3 × 10,000,000 elements; input preallocated | **0.085346 s** | 117.170 million elements/s |
| ext4 sequential write + `fsync` | 100 MiB, 4 MiB repeated-random blocks | **0.106183 s** | **941.773 MiB/s** |
| ext4 sequential read after `POSIX_FADV_DONTNEED` | 100 MiB | **0.035718 s** | **2,799.739 MiB/s (2.734 GiB/s)** |
| ext4 immediate warm-cache read | 100 MiB | **0.020580 s** | **4,859.007 MiB/s (4.745 GiB/s)** |
| ext4 direct-I/O read (`dd iflag=direct`) | 2 runs, 100 MiB each | 0.024663–0.026367 s | 3.704–3.960 GiB/s; midpoint **3.827 GiB/s** |
| Isolated pure-Python pip install | `pyfiglet==1.0.2`, no pip cache | **0.587873 s** | Overall install time; pip reported 38.6 MB/s for the wheel |
| Local npm install | `is-number@7.0.0` | **0.574799 s** | npm reported 507 ms internally |
| Actual apt package install | `tree`, 59.4 kB download | **2.071882 s** | Includes dpkg work |
| GCC compile | Small C program, `-O2 -Wall -Wextra` | **0.225725 s** | Compile and link |

**Fast:** burst filesystem I/O, Google-edge download, PyPI delivery, package metadata operations, and NumPy vector work.  
**Relatively slow or variable:** interpreter-level Python loops, Hugging Face first-byte time, GitHub codeload throughput, and especially the tested Cloudflare download path. Creating an otherwise empty Python venv took 2.265 s, substantially longer than the subsequent package install.

The disk numbers are burst measurements on a small 100 MiB file. `fsync` completed at the guest block-device layer and direct I/O bypassed the guest page cache, but a hypervisor/host cache may still dominate; these results do **not** establish sustained physical-storage performance for multi-gigabyte jobs.

## 6. Other observations

### 6.1 Controlled memory-pressure test

A process allocated and explicitly touched **512 MiB** (one write per 4 KiB page):

| State | User-cgroup `memory.current` | `memory.peak` | OOM/high/max events |
|---|---:|---:|---:|
| Before allocation | 418.340 MiB | 657.105 MiB | 0 |
| Allocated and touched | 931.258 MiB | 931.258 MiB | 0 |
| Held for 1 second | 931.465 MiB | 931.465 MiB | 0 |
| Released | 418.457 MiB | 931.465 MiB | 0 |

The `bytearray` allocation took 0.454651 s and the explicit page-touch loop 0.038381 s. There was no OOM, throttling, or swap activity at this level. The 1.813 GiB hard ceiling was intentionally **not** approached destructively; with no swap, exceeding it should be expected to invoke cgroup OOM behavior rather than graceful paging.

### 6.2 Background and long-running processes

A managed Python background process emitted a heartbeat every two seconds and remained alive across multiple independent calls and benchmark operations. Heartbeats 1 through 30 covered 58.008 seconds, or about one minute of observed runtime, after which the process was intentionally stopped. This verifies background-process support within the running sandbox, but it does **not** establish a maximum job/sandbox lifetime or guarantee survival across VM recreation.

For a genuinely long pipeline, use the platform's managed-process mechanism rather than assuming a detached child from a one-shot shell will survive, and checkpoint progress externally or under the durable workspace boundary.

### 6.3 Miscellaneous observations

- A root-owned Jupyter server/kernel and platform control services were already running outside the tested user process tree/cgroup.
- The system clock showed the expected UTC time, but `timedatectl` reported `System clock synchronized: no` and NTP inactive. Do not use this VM as a high-precision time source without your own check.
- Environment variable values were not dumped to avoid leaking credentials or control-plane addresses. Only sandbox-related variable names were recorded.
- The VM had been up about eight minutes at the end of testing; this run cannot characterize multi-hour or multi-day stability.
- One initial Google Cloud Storage candidate returned HTTP 403 because that chosen object was unavailable; a stable `dl.google.com` range download then succeeded. This is not evidence of a Google-wide block.

## 7. Practical suitability and hard limitations

**Reasonable fit:** moderate two-core Python/Node research jobs, scraping/API work over IPv4, package-driven ETL, compilation of small native extensions, and file processing that stays well below the memory and live-disk ceilings.

**Hard or operational limits:**

1. **Durability is much smaller than live disk:** best-effort workspace snapshots are around 128 MB / 10,000 files, while the live filesystem has ~19.75 GiB free. Use external object/database storage for substantial datasets.
2. **1.813 GiB user memory ceiling and no swap:** avoid large in-memory frames/models and large `/tmp` files; stream/chunk data.
3. **Only 2 vCPUs:** CPU multiprocessing beyond two workers will mostly contend. CPU weight is 50 under cgroup contention.
4. **No GPU, Docker daemon, FFmpeg, Clang, Conda, Go, or Rust initially:** apt/pip/npm can bootstrap tools, but installs should be scripted and considered session-local.
5. **No global IPv6:** use IPv4-capable services and force IPv4 where clients otherwise stall on AAAA records.
6. **Native Git protocol is unreliable here:** use HTTPS or SSH.
7. **Default file-descriptor soft limit is only 1,024:** raise it in high-concurrency network workers; the tested hard limit is 524,288.
8. **Maximum process/sandbox lifetime is unknown:** a one-minute background test passed, not a multi-day endurance test.
9. **Endpoint throughput varies by more than 40×:** use retries, resumable downloads, checksums, and per-host concurrency controls.

## Appendix A — Raw notes and machine-readable results

All retained raw artifacts are under [`envchar_work/`](envchar_work/). The most useful files are:

- [`system_survey.txt`](envchar_work/system_survey.txt) — OS, process tree, mounts, initial limits
- [`resource_detail.txt`](envchar_work/resource_detail.txt) — current cgroup files and security status
- [`isolation_extra.txt`](envchar_work/isolation_extra.txt) — namespace comparison, capability decode, KVM boot evidence
- [`tool_inventory.tsv`](envchar_work/tool_inventory.tsv) — complete tool probe table
- [`runtime_packages.txt`](envchar_work/runtime_packages.txt) and [`pip_list.json`](envchar_work/pip_list.json)
- [`filesystem_survey.txt`](envchar_work/filesystem_survey.txt) and [`persistence_recheck.txt`](envchar_work/persistence_recheck.txt)
- [`dns_getaddrinfo.tsv`](envchar_work/dns_getaddrinfo.tsv), [`dns_udp.tsv`](envchar_work/dns_udp.tsv), and [`tcp_ports.tsv`](envchar_work/tcp_ports.tsv)
- [`curl_latency.tsv`](envchar_work/curl_latency.tsv), [`large_downloads.tsv`](envchar_work/large_downloads.tsv), [`google_download_retry.tsv`](envchar_work/google_download_retry.tsv), and [`cloudflare_upload.tsv`](envchar_work/cloudflare_upload.tsv)
- [`sudo_ping_ipv6.txt`](envchar_work/sudo_ping_ipv6.txt) and [`git_network_notes.txt`](envchar_work/git_network_notes.txt)
- [`install_compile_results.json`](envchar_work/install_compile_results.json) and [`apt_install_results.json`](envchar_work/apt_install_results.json)
- [`microbenchmark_results.json`](envchar_work/microbenchmark_results.json) and [`memory_pressure_result.json`](envchar_work/memory_pressure_result.json)
- [`background_process_test.txt`](envchar_work/background_process_test.txt)

<details>
<summary>Selected raw identity and cgroup values</summary>

```text
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
DEBIAN_VERSION_FULL=13.6
glibc 2.41
systemd-detect-virt=kvm
systemd-detect-virt --container=none
root mount=/dev/vda ext4 rw,relatime,discard
current cgroup=/user
cpu.max=max 100000
cpuset.cpus.effective=0-1
memory.max=1947172864
memory.high=1947172864
pids.max=max
Seccomp=0
```

</details>

<details>
<summary>Benchmark reproducibility notes</summary>

- CPU: `perf_counter_ns`; one-vCPU affinity; five runs for `sum(range(10**7))`, three for the explicit loop and NumPy expression.
- Disk: 100 MiB in `/home/user`, 4 MiB chunks, repeated randomly generated block, final `fsync`; advisory cache eviction followed by warm read; two `dd iflag=direct` reads.
- Network: curl 8.14.1, IPv4, no configured proxy, explicit connection and total timeouts; output discarded or deleted only after byte count/hash/type/integrity checks.
- Installs: pip venv and npm project isolated under `/tmp`; apt installed and then purged `tree`; compiled test trees removed.
- No intentionally destructive OOM, disk-fill, inode-fill, fork-bomb, firewall scan, or maximum-lifetime test was performed.

</details>
