# Environment Characterization Report

**Date:** 2026-09-04 (UTC) · **Method:** live measurement inside the environment (~20 separate exec sessions, one background-process test, real downloads/installs/benchmarks)
**Sandbox identifiers:** `E2B_SANDBOX_ID=i07vrt7m23evfzhmemmqh`, template `nlhz8vlwyupq845jsdg9`, build `f34a5416-ef30-4cb7-8e18-0fdecd6eb529`
**Raw logs:** `/home/user/envcheck/notes/*.txt` (25 numbered files mirroring each step; key excerpts reproduced in the Appendix)

---

## Executive summary

This is an **E2B sandbox**: a single-user **KVM/Firecracker micro-VM** (Debian 13 "trixie", kernel 6.1.158+, x86_64, glibc 2.41) with **2 vCPUs (AVX-512-capable Xeon-class, ~2.6 GHz), 1.94 GiB RAM (hard cgroup cap 1.81 GiB, no swap)**, a 25 GB ext4 root disk (+ ~1 GB tmpfs `/tmp`), and full `root` via **passwordless sudo**. Tooling is strong: Python 3.13.14 (182 packages preinstalled incl. pandas/scipy/matplotlib/spacy), Node 20 + npm, gcc 14

/ make, apt + pip + npm all functional, and a clean C toolchain. The network is a **Google Cloud (The Dalles, Oregon) egress NAT with excellent international bandwidth**: downloads run ~60–163 MB/s single-stream (only `codeload.github.com` archives are slow at ~8 MB/s), uploads ~17 MB/s, DNS 1–19 ms, all TCP ports probed open. The **hard limits** to plan around are memory (≤1.81 GiB, OOM-kills, no swap → CPU-only/vectorized workloads must fit ~1.4 GiB), the ephemeral sandbox lifecycle (fresh VM per session; `/tmp` is RAM), and the absence of GPU, docker, IPv6, and ping (without sudo).

---

## 1. Runtime & Isolation

| Property | Value | Source |
|---|---|---|
| OS | Debian GNU/Linux 13 "trixie" (13.6) | `/etc/os-release` |
| Kernel | 6.1.158+ `#1 SMP PREEMPT_DYNAMIC`, `x86_64` | `uname -a` |
| libc | glibc **2.41** (Debian 2.41-12+deb13u3) | `ldd --version` |
| Hostname | `e2b.local` | `hostname` |
| Virtualization | **KVM** micro-VM (`kvm` per `systemd-detect-virt`; `kvm-clock`; `hypervisor` CPU flag; virtio disk `/dev/vda`) — **not Docker** (no `/.dockerenv`, no `/.containerenv`; the process tree and `/proc/1/comm` are the real init) | cpuinfo, mounts, proc |
| CPU | Intel Xeon **2.60 GHz** (sanitized model string — likely Ice Lake-class), **2 vCPUs** (lscpu: 1 socket, 1 core, 2 threads), AVX2 + **AVX-512** (f, bw, cd, dq, vl, ifma, vbmi, vbmi2, vnni, bitalg, vpopcntdq), FMA, AES-NI, SHA-NI | `/proc/cpuinfo`, `lscpu` |
| Turbo/cpufreq | No cpufreq interface exposed (fixed-frequency, no turbo reporting) | `/sys/devices/system/cpu/*/cpufreq` absent |
| Memory | `MemTotal 2,032,608 kB` (**1.94 GiB**); **no swap** (`SwapTotal 0`); `MemAvailable 1.53 GiB` at idle | `free -m`, `/proc/meminfo` |
| Measured "up" time | VM boots fresh per session (uptime was 1 min at first probe) | `uptime` |

### Containment / isolation signals

- **cgroup v2** mounted at `/sys/fs/cgroup`; this session lives in **`/sys/fs/cgroup/user`** (own cgroup namespace `cgroup:[4026531835]`); `systemd` (PID 1) runs it (`init.scope`).
- **Cgroup limits (the real resource budget):** `memory.max = 1,947,172,864 B` (**1.81 GiB**, hard), `memory.swap.max = max` (irrelevant — no swap), `cpu.max = max 100000` (unlimited up to the 2 vCPUs), `cpu.weight = 50`, `cpuset.cpus.effective = 0-1`, `pids.max = max`.
- **Dropped user privileges but unrestricted root:** as `user`, `CapEff = 0` and **seccomp: 0 filters**, `NoNewPrivs` unset. The **capability bounding set is complete** (all 41 caps: chown, dac_override, dac_read_search, fowner, fsetid, kill, setgid, setuid, setpcap, linux_immutable, net_bind_service, net_broadcast, net_admin, net_raw, ipc_lock, ipc_owner, sys_module, sys_rawio, sys_chroot, sys_ptrace, sys_pacct, sys_admin, sys_boot, sys_nice, sys_resource, sys_time, sys_tty_config, mknod, lease, audit_write, audit_control, setfcap, mac_override, mac_admin, syslog, wake_alarm, block_suspend, audit_read, perfmon, bpf, checkpoint_restore). **`sudo -n` is passwordless and grants full root** (`CapEff = 0x000001ffffffffff`).
- User namespace: initial NS (full `uid_map` `0 0 4294967295`, `gid` same). No user namespaces indirection.
- **Only real privilege gap as user:** ICMP ping fails without sudo (`SOCK_RAW: Operation not permitted` — needs `CAP_NET_RAW`); **ping works under sudo** (0.674 ms to 8.8.8.8).
- `/.e2b` contains `ENV_ID`/`TEMPLATE_ID`/`BUILD_ID`; env declares `E2B_SANDBOX=true`, `E2B_SANDBOX_ID`, `E2B_EVENTS_ADDRESS=http://192.0.2.1` (see §6).
- Services running under the sandbox's systemd: `envd.service` (E2B Env Daemon — also bind-mounts a cert bundle over `/etc/ssl/certs`), `code-interpreter.service` (E2B code interpreter agent), **`jupyter.service` (Jupyter listening on 127.0.0.1:8888 and the link-local IP)**, `ssh.service`, `journald`, `dbus`, `getty`. `systemctl is-system-running` → `degraded` (nothing broken observed in practice).
- No `/dev/kvm`, no `/dev/dri`, no `nvidia-smi` → **no GPU, no nested virtualization**. `dmesg` readable only via sudo (readable — audit logs confirmed).

### Resource limits (ulimit / per-process)

| Limit | Soft | Hard | Notes |
|---|---|---|---|
| open files | 1024 | 524288 | OK for the tested loads (pip, git, curl fine) |
| max user processes | 7917 | 7917 | ~91 processes present |
| stack size | 8192 kB | unlimited | |
| core file size | 0 | 0 | no core dumps |
| max locked memory | 8192 kB | 8192 kB | |
| pending signals | 7917 | 7917 | |
| max msgqueue | 819200 B | 819200 B | |
| CPU time / file size / data / address space / nice / rtprio | unlimited / unlimited / unlimited / unlimited / 0 / 0 | | |

---

## 2. Tooling & Language Runtimes

### Availability & versions

| Tool | Version | Path | Notes |
|---|---|---|---|
| python3 / python | **3.13.14** | /usr/local/bin/python3 | custom build under /usr/local |
| pip / pip3 | **26.1.2** | /usr/local/bin/pip | works as plain user (see below) |
| node | **v20.20.2** | /usr/bin/node | NodeSource apt repo configured |
| npm / npx | 10.8.2 | /usr/bin/npm | works |
| git | 2.47.3 | /usr/bin/git | works |
| curl | 8.14.1 | /usr/bin/curl | OpenSSL 3.5.6, zlib 1.3.1, brotli, zstd, nghttp2/3 |
| wget | 1.25.0 | /usr/bin/wget | |
| **ffmpeg** | **7.1.5** | /usr/bin/ffmpeg | ⚠️ installed by me via apt during testing (was NOT preinstalled) |
| docker / podman | — missing | — | no container runtime (no /dev/kvm either) |
| make | 4.4.1 | /usr/bin/make | |
| gcc / g++ / cc | **14.2.0** (Debian 14.2.0-19) | /usr/bin/gcc | works, incl. -O3/-march=native (AVX-512) |
| clang | — missing | | |
| ld / binutils | GNU ld 2.44 | | |
| jq | 1.7 | /usr/bin/jq | |
| zip / unzip | Info-ZIP | | |
| tar / gzip / xz | 1.35 / 1.13 / 5.8.1 | | zstd & rsync missing |
| ssh / scp / sftp | OpenSSH (client) | /usr/bin/ssh | outbound SSH verified working |
| openssl | 3.5.6 | /usr/bin/openssl | |
| socat | present | /usr/bin/socat | nc/ncat absent, socat present |
| apt-get / dpkg | 3.0.3 / 1.22.22 | | **works via sudo** |
| systemctl | systemd 257 | | running init |
| **sqlite3** | **3.46.1** | | ⚠️ installed by me via apt; not preinstalled |
| java / javac | OpenJDK **11** (2018-09-25) | | startup measured 0.050 s |
| perl | present | | |
| timeout, lscpu, id, ss | coreutils etc. | | `bc`, `dig`, `nslookup`, `strace`, `tcpdump`, `htop`, `tmux`, `screen`, `gh`, `conda`, `mamba`, `zstd`, `cmake`, `ninja`, `go`, `rustc`, `cargo`, `ruby`, `php` | — **missing** (installable via apt if needed) |

### Package managers — what actually works

| Manager | Works? | Evidence |
|---|---|---|
| **pip** | ✅ yes, as plain user | `/usr/local/lib/python3.13` is **world-writable** (`drwxrwxrwx`), so no venv/sudo needed; `python3 -m venv` also works (pip 26.1.2 inside venv). `pip install --no-cache-dir --force-reinstall numpy` = **2.88 s total** (17 MB wheel). |
| **npm** | ✅ yes | `npm install --prefix /tmp typescript@5.8.3` = **1.45 s** (23 MB incl. deps), import verified. |
| **apt** | ✅ yes, **via sudo** | sources: `debian.sources` + `nodesource.sources`; `apt-get update` = 0.78 s (342 kB @ 2.4 MB/s), `sqlite3` install = 2.10 s, `ffmpeg` install = **10.6 s** (63.8 MB fetched @ **120 MB/s**); installed binaries run. |
| conda / mamba / apk / yum | ❌ n/a (Debian; not installed) | |
| Compile anything? | ✅ yes | gcc 14.2.0: trivial program compiles in 0.054–0.18 s; C loop (1e9 int adds + 3e8 fp divs) runs in 0.365 s (-O2). |

**Preinstalled Python stack (182 packages).** Verified: numpy 2.3.5 → *2.5.2 after my reinstall test* (matmul benchmark below ran on 2.3.5), pandas 2.2.3, scipy 1.17.1, matplotlib 3.10.9, seaborn 0.13.2, plotly 6.0.1, spacy 3.8.14, nltk 3.10.0, networkx 3.6.1, sympy 1.14.0, openpyxl 3.1.5, psutil 7.2.2, pydantic 2.13.4, requests 2.33.0, aiohttp 3.14.1, httpx 0.28.1, ipython 9.15.0, pytest 9.0.3, tqdm 4.69.0, jinja2 3.1.6. **Not present:** torch, transformers, sklearn (n/a), datasets, pyarrow, polars, duckdb, fastapi, flask, django, jupyterlab, black, ruff, mypy, boto3.

---

## 3. Filesystem & Persistence

### Mounts, capacity, inodes

| Path | FS | Size | Free | Inodes free | Notes |
|---|---|---|---|---|---|
| `/` (incl. `/home/user`) | **ext4** (`/dev/vda`, virtio) | 25 GB | **20 GB** (17–18 % used) | 6.62M (3 % used) | the only real disk |
| `/tmp` | tmpfs | 993 MB | 993 MB | 1,048,565 | **RAM-backed — wiped on VM restart** |
| `/dev/shm` | tmpfs | 993 MB | 993 MB | | |
| `/run` | tmpfs | 397 MB | | | |
| `/etc/ssl/certs` | tmpfs (bind-mounted from `/run/e2b/certs` by `envd`) | 397 MB | | | sandbox-managed CA bundle |
| `/proc`, `/sys`, `/sys/kernel/{debug,security,tracing}`, `/dev` | proc / sysfs / debugfs / devtmpfs | | | | noexec/rw but **not writable as user** |

No read-only mounts prevented our writes; `/workspace` does **not** exist (use `/home/user`). `touch /proc/x`, `/sys/x` and `/proc/sys` → `Permission denied` as user (kernel params not exposed for writing).

### Write / read / delete integrity test (1 MiB random, sha1 compare) — all PASS

| Location | Result | Read-back hash |
|---|---|---|
| `/tmp` | ✅ write+read+delete | MATCH |
| `/home/user` | ✅ | MATCH |
| `/home/user/envcheck` | ✅ | MATCH |
| `/var/tmp` | ✅ | MATCH |
| `/dev/shm` | ✅ | MATCH |

Unicode/space filenames (`weird "name" 日本語.txt`) ✅. 200 MB file write ✅.

### Disk performance & small-file behavior

| Operation | ext4 (`/home/user`) | tmpfs (`/tmp`) |
|---|---|---|
| 200 MB sequential write (fdatasync) | **830 MB/s** | **3.0 GB/s** |
| 200 MB read (page cache) | **5.2 GB/s** | 5.3 GB/s |
| 200 MB read (O_DIRECT) | **3.2 GB/s** | not supported (EINVAL) |
| 200 MB write (O_DIRECT) | **1.6 GB/s** | not supported |
| create+write 20 k small files | **4,585 files/s** | **77,619 files/s** |
| read 20 k small files | 85,397 files/s | — |
| delete 20 k small files | 78,461 files/s | **344,475 files/s** |

(20 k small files: trivial impact — inode use 3 %.)

### Persistence semantics (as tested)

- **Across exec sessions in the same VM: YES.** `/home/user/envcheck/notes/` (25 files) and all installed artifacts survived ~20 separate tool sessions; a `nohup`'d process started in one session **completed across 3+ session boundaries** (wrote its result file at 11:22:56 UTC).
- **Across a VM restart: not directly testable from inside** — no `/dev/kvm`, and rebooting would destroy the session; deliberately not attempted. Structure-wise: `/home/user` + `/` are on the persistent virtio ext4 disk for the sandbox lifetime; **`/tmp`, `/dev/shm`, `/run` are tmpfs (RAM) and are lost on restart**. Plan: keep all durable state under `/home/user`; treat `/tmp` as scratch.
- Sandbox lifetime is bounded (fresh boot per session; first probe saw `up 1 min`), so schedule long pipelines so intermediates are checkpointed to the persisted workspace, not only `/tmp`.

---

## 4. Network Characterization

**Topology:** egress = NAT via `eth0 169.254.0.21/30` (gateway `.22`), **MTU 1500**; public IP **34.187.218.115** = `*.bc.googleusercontent.com`, **Google LLC AS396982, The Dalles, Oregon, US** (GCP). No captive portal or HTTP proxy detected; no IPv6 route (curl `-6` fails immediately).

### DNS

resolv.conf → `8.8.8.8` (direct public resolver, not a stub); `python socket.gethostbyname`, 5 samples each:

| Host | Median | Min | Max |
|---|---|---|---|
| google.com | 2.4 ms | 1.5 | 4.3 |
| github.com | 10.5 ms | 1.5 | 11.9 |
| pypi.org | **1.1 ms** | 1.0 | 1.1 |
| huggingface.co | 18.8 ms | 1.6 | 22.3 |
| files.pythonhosted.org | 9.0 ms | 1.2 | 12.0 |
| objects.githubusercontent.com | 1.3 ms | 1.0 | 1.6 |

Raw UDP:53 (0x20 query): 8.8.8.8 → **1.8 ms**, 9.9.9.9 → 6.0 ms, 1.1.1.1 → 18.5 ms. No DNS failures or timeouts.

### Latency (TCP connect + HTTPS phases, curl)

| Endpoint | TCP connect | TLS handshake | TTFB | Total |
|---|---|---|---|---|
| https://www.google.com/ | 2.3 ms | 14–29 ms | 50–67 ms | 52–68 ms |
| https://github.com/ | 1.8–2.6 ms | 22–28 ms | 32–40 ms | 76–101 ms |
| https://pypi.org/ | 1.7 ms | 21–23 ms | 31–32 ms | **32–34 ms** |
| https://huggingface.co/ | 16–23 ms | 36–42 ms | 46–52 ms | 63–68 ms |
| https://registry.npmjs.org/ | 2.0 ms | — | **95 ms** (TTFB) | 330 ms (small file) |

TCP connect probes: github.com 10.3 ms (443) / 2.2 ms (22) / 21.6 ms (80) / 20.3 ms (9418); `raw.githubusercontent.com` **1.4 ms**; `api.github.com` 21.0 ms; **pypi.org 1.5 ms**; **huggingface.co 1.8 ms**; 8.8.8.8 → 0.3 ms (53), 0.4 ms (443). Plain HTTP(:80) works (200/301 redirects — normal, no injection/TLS-stripping noticed). **Outbound SSH verified end-to-end** (github.com:22 banner `SSH-2.0-cb4a187`).

### Throughput (curl, one shot each, `size_download/time_total`)

| Endpoint / object | Bytes | Time | **Rate** |
|---|---|---|---|
| files.pythonhosted.org (Fastly) numpy wheel | 16.90 MB | 0.174 s | **97.0 MB/s** (~780 Mbps) |
| GitHub release asset (`release-assets…`) — prometheus 114 MB | 114.16 MB | 0.701 s | **162.8 MB/s** (~1.30 Gbps) |
| **codeload.github.com** cpython source tarball | 29.98 MB | 3.785 s | **7.9 MB/s** ← slow outlier |
| huggingface.co gpt2 `pytorch_model.bin`, 50 MB range (206) | 50.0 MB | 0.875 s | **59.9 MB/s** |
| Debian apt mirror (ffmpeg fetch) | 63.8 MB | ~1 s | **~120 MB/s** |
| npm registry (typescript install, incl. metadata) | 23 MB | 1.45 s | ~16 MB/s effective |
| **Upload** — Cloudflare `__up` 10 MB | 10 MB up | 0.615 s | **17.1 MB/s** (~137 Mbps up) |
| Upload — httpbin.org POST 5 MB | 5 MB up | 3.25 s | 1.6 MB/s (httpbin server is slow; not our link) |
| Parallel: 4×10 MB ranges, Fastly | 40 MB | **0.18 s** | **~222 MB/s aggregate** |
| Parallel: 4× codeload (~30 MB each) | 120 MB | 11.98 s | ~10 MB/s aggregate → bottleneck is GitHub's archive CDN, not the sandbox |

**Asymmetry:** down ≫ up (≈163 vs ≈17 MB/s); per-connection downloads saturate far below the link only on `codeload.github.com`.

### Blocks, restrictions, oddities

- ICMP blocked without sudo (needs `CAP_NET_RAW`); **works via sudo** (0.67 ms).
- IPv6: no connectivity.
- `speed.cloudflare.com/__down` → **HTTP 403** (endpoint refused for this egress IP) — the only blocked HTTP endpoint observed; the `__up` sibling works.
- HuggingFace **gated** repos → 401 without token (e.g. `meta-llama/Llama-3.1-8B`), as expected; open repos (`gpt2`) fully downloadable.
- `E2B_EVENTS_ADDRESS=http://192.0.2.1` is an **internal endpoint that accepts TCP on every port tested (22/80/443/4444/8080)** and answers HTTP with `404`, JSON — the sandbox's control/events proxy; HTTPS to it hangs.
- No port-filtering observed on any outbound host: 22, 80, 443, 9418, 8080, 8443, UDP 53 all connect.
- No timeouts, no throttling, no retry storms in any test.

---

## 5. Performance Micro-benchmarks

Timing tool: Python `time.perf_counter()` / bash `time`; single-run unless noted.

### CPU

| Benchmark | Result | Note |
|---|---|---|
| `sum(range(10**7))` (CPython 3.13.14) | **0.2209 s** | 45.3 M int/s |
| genexpr `sum(i*i for i in 10**6)` | 0.0745 s | |
| empty `for` loop, 2e6 iterations | 0.0752 s | |
| 2e6 × `math.sin(i)` loop | 0.3168 s | 6.3 M ops/s |
| 1 MB string allocation | 0.37 ms | |
| 2× `sum(range(10**7))` on 2 processes | **0.2591 s wall** | ≈**1.7× speedup** over 0.4418 s serial — real 2-core parallelism |
| Node 20: `for(i<1e7) s+=i` | **0.0824 s** | 121 M ops/s (JIT) |
| numpy 2.3.5: 1000×1000 float64 `a@b` | **0.0283 s** | ~35 GFLOP/s (n³ convention) |
| numpy: `sum()` of 1e7 floats | 0.0096 s | 1.05 G elem/s |
| gcc 14 `-O2`, 1e9 int adds + 3e8 fp divs | **0.365 s** | `-O0` 3.334 s, `-O3` 0.446 s, `-O3 -march=native` 0.377 s |
| gcc trivial compile | 0.054–0.18 s | |
| Java 11 `-version` JVM start | 0.050 s | |

### Disk (see §3 table) — ext4 sequential write 830 MB/s, page-cache read 5.2 GB/s; tmpfs 3.0 / 5.3 GB/s.

### Package installs & clones

| Operation | Wall time |
|---|---|
| `apt-get update` (sudo) | 0.78 s |
| `apt install sqlite3` (sudo) | 2.10 s |
| `apt install ffmpeg` (sudo, 63.8 MB) | **10.58 s** |
| `pip install idna` (already satisfied — no-op) | 0.91 s |
| `pip install --no-cache-dir --force-reinstall numpy` (**fresh 17 MB wheel**) | **2.88 s** |
| `npm install typescript@5.8.3` (23 MB) | 1.45 s |
| `git clone --depth 1` Hello-World | 0.60 s |
| `git clone --depth 1` pypa/pip (27 MB) | 0.99 s |

---

## 6. Other Observations

**Memory pressure & OOM.** Baseline cgroup usage ≈ 425 MB (systemd, Jupyter, envd, code-interpreter agent). A ramp test allocating 200 MB steps with page-touching was **SIGKILLed (exit 137) by the cgroup OOM killer** (between 1.4 and 1.8 GB allocated; output buffering lost the exact step — `memory.events` recorded `oom_kill 1`). After the kill: `memory.current` dropped to 7.9 MB (page cache reclaimed), the VM stayed fully healthy, and everything resumed normally. An immediate 3 GB `bytearray` gets a clean `MemoryError` (overcommit heuristic refuses; no kill). **Practical headroom: ~1.35–1.4 GiB of allocatable memory; nothing survives a breach — the killed process is destroyed. A 2 GB working set is impossible; expect OOM-kills (not straggling swap) past ~1.81 GiB.**

**CPU accounting.** `cpu.max = max`, and after a 2-process × 15 s burn, `cpu.stat` showed `nr_periods 0 / nr_throttled 0` — **no CPU throttling**; usage rose by ~30 s CPU over 15 s wall (both vCPUs saturated). A long-running HTTP server remained responsive during the burn.

**Background / long-running tasks.** ✅ Both mechanisms work:
- Managed background process (start_process): a small HTTP server bound `0.0.0.0:8765`, ran across 4+ subsequent tool calls, served requests with sub-ms latency, logged heartbeats, stayed healthy through CPU burns and OOM-adjacent load; cleanly stopped at the end.
- Orphaned `nohup bash -c 'sleep 90; …'` spawned in one call **survived 3+ call boundaries and completed**, writing its result file. (Bash-level `&` job control is the same mechanism.)
- 91 processes running at baseline; `pids.max = max`.

**Sandbox-related environment / config.**

| Key | Value | Meaning |
|---|---|---|
| `E2B_SANDBOX` | `true` | E2B sandbox |
| `E2B_SANDBOX_ID` / `E2B_TEMPLATE_ID` | `i07vrt7m23evfzhmemmqh` / `nlhz8vlwyupq845jsdg9` | instance/template IDs |
| `E2B_EVENTS_ADDRESS` | `http://192.0.2.1` | internal event/control proxy (accepts all ports, 404 JSON) |
| `HOME` / `USER` / `LOGNAME` / `SHELL` | `/home/user` / `user` / `user` / `/bin/bash` | |
| `PATH` | `/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games` | /usr/local first (custom Python build) |
| `LANG` / `LC_CTYPE` | empty / `POSIX` | C locale |
| `/.e2b` | ENV/TEMPLATE/BUILD IDs | image provenance |
| `/.sudo_as_admin_successful` | present in $HOME | pre-provisioned sudo |

**Odd/slow/notable.** `codeload.github.com` (source archives) ~8 MB/s vs 163 MB/s for release assets; `httpbin.org` slow (its server); Cloudflare `__down` 403; `systemctl is-system-running` = `degraded` (still fully functional); Jupyter + sshd + E2B agents consume ~425 MB and several ports at baseline; `/proc/1/environ` unreadable (procfs pointer-restriction, even via a normal `sudo tr` redirect — minor); `ping` needs sudo; npm TTFB 95 ms (slower than the rest, still fine).

---

## 7. What is fast / slow / hard limits

**Fast ✅**
- **Download bandwidth: 60–163 MB/s** single-stream (Fastly / PyPI / GitHub release-assets / Debian mirrors / HuggingFace); ~222 MB/s aggregate; a 114 MB download finished in 0.7 s.
- **Disk:** ext4 fsync'd writes 830 MB/s, O_DIRECT 3.2 GB/s reads; tmpfs 3–5 GB/s; 20 k small files in 4.4 s (ext4) or 0.26 s (tmpfs).
- **Package installation:** numpy wheel fully installed in 2.9 s; `ffmpeg` (63.8 MB suite) in 10.6 s; `typescript` in 1.45 s.
- **DNS/latency:** 1–20 ms DNS; sub-2 ms connects to PyPI/CDNs; TLS ~20–40 ms; overall page TTFB 30–110 ms.
- **Compilation & vectorized math:** gcc 14 with AVX-512; numpy matmul 1000³ in 28 ms.
- **Everything pipe-related:** real 2-core parallelism, no CPU throttling, no seccomp, full root, no cap drops.

**Slow / limited 🐌**
- **codeload.github.com archives: 7.9–10 MB/s** (~20× slower than other GitHub endpoints) — for large source tarballs, prefer `git clone --depth 1` (fast) or release assets.
- **Uploads: ~17 MB/s** (fine for metadata, slow for pushing GB-scale artifacts).
- `httpbin.org`, npm TTFB (95 ms), IPv6 absent, `speed.cloudflare.com/__down` blocked.
- Python pure loops ~6–45 M ops/s (normal); heavy loops should use numpy/vectorization (or C, ✕40 faster).
- Idle baseline ~425 MB consumed by sandbox tooling (Jupyter etc.).

**Hard limits 🚧**
- **Memory: 1.81 GiB hard cap, zero swap, hard OOM-kill** → largest realistic working set ~1.4 GiB. No GPU (no `/dev/dri`, no `nvidia-smi`). No `/dev/kvm` (no nested VMs / docker-in-docker).
- **No docker/podman**; no clang/rust/go/conda (all apt-installable, but no container runtime).
- **Ephemeral lifecycle:** fresh VM per session (booted 1 min before first probe), `/tmp` & `/dev/shm` are RAM and vanish on restart; durable state belongs under `/home/user` (on the 25 GB ext4 disk). Sandbox lifetime is time-bounded — checkpoint long-running work.
- **ICMP/ping requires sudo**; seccomp=0 and full capability bounding set mean the isolation boundary is the microVM itself (as designed for this sandbox product).

---

## Appendix — method & raw evidence

**Method notes.** All timings were taken inside the environment: `time.perf_counter()` (Python), bash `time`, and curl `-w` macros (`time_namelookup/time_connect/time_appconnect/time_starttransfer/time_total/speed_download`). Throughput = `size_download / time_total`. cgroup readouts from `/sys/fs/cgroup/user/*`. One-time *note*: the "fast" `pip install numpy` (0.63 s) turned out to be a no-op because numpy ships preinstalled; the honest fresh-install number (2.88 s, `--force-reinstall --no-cache-dir`) is what's reported. No reboot test was performed (would destroy the session); restart persistence is inferred from filesystem types (ext4 vs tmpfs).

**Full raw logs:** `/home/user/envcheck/notes/01_system.txt … 23_preinstalled.txt` (each numbered stage; contents verbatim). Selected excerpts:

<details>
<summary>Isolation & limits (excerpts)</summary>

<pre>
# /proc/self/cgroup
0::/user
# /sys/fs/cgroup/user/
memory.max = 1947172864     cpu.max = max 100000     cpuset.cpus.effective = 0-1
memory.current = 235917312  cpu.weight = 50          pids.max = max
# capabilities (user)
CapEff: 0000000000000000    CapBnd: 000001ffffffffff      # all 41 caps in bounding set
# seccomp
Seccomp: 0  Seccomp_filters: 0
# sudo -n id  ->  uid=0(root) gid=0(root)
# as root: CapEff = 000001ffffffffff
# nohup cross-call completion
survived and completed at 11:22:56
</pre>
</details>

<details>
<summary>OOM test (excerpt)</summary>

<pre>
baseline memory.current = 425467904
... 200MB steps, page-touched ...
/bin/bash: Killed  python3 ...   exit=137
memory.events: oom_kill 1
memory.current after: 7925760
# direct 3GB alloc: MemoryError (no kill); VM healthy after
</pre>
</details>

<details>
<summary>Network throughput (excerpts)</summary>

<pre>
# Fastly wheel (16.9 MB):        http=200 bytes=16897903 total=0.174222s avg=96990638B/s
# GitHub release asset (114 MB):http=200 bytes=114163078 total=0.701228s avg=162804505B/s
# codeload tarball (30 MB):      http=200 bytes=29982213 total=3.785437s avg=7920409B/s
# HF 50 MB range (206):          http=200 bytes=52428800 total=0.875396s avg=59891523B/s
# Upload CF __up 10 MB:          http=200 sent=10485760 total=0.614697s upload_speed=17058420B/s
# 4x10MB Fastly parallel:        0.18s wall ; 4x codeload: 11.98s wall
# egress: 34.187.218.115  AS396982 Google LLC  The Dalles, Oregon US   MTU 1500
# ICMP as user: ping: socket: Operation not permitted   |  sudo ping: 0.674 ms
# github.com:22 banner: SSH-2.0-cb4a187
</pre>
</details>

<details>
<summary>Benchmarks (excerpts)</summary>

<pre>
sum(range(10**7))           : 0.2209s  (45.3 M elem/s)
2x sum(range(10**7)) 2 procs: 0.2591s wall
node sum(1e7): 0.0824s (121 Mops/s) ; gcc -O2 loop: 0.365s
numpy matmul 1000x1000: 0.0283s ; numpy sum 1e7: 0.0096s
ext4: write(fdatasync) 830 MB/s, read(cache) 5.2 GB/s, O_DIRECT r/w 3.2/1.6 GB/s
tmpfs: write 3.0 GB/s, read 5.3 GB/s, O_DIRECT unsupported
small files ext4: 4585 create/s, 85397 read/s ; tmpfs: 77619 create/s
apt update 0.78s | apt sqlite3 2.10s | apt ffmpeg 10.58s | pip numpy fresh 2.88s | npm typescript 1.45s | git clone pip-repo 0.99s
</pre>
</details>

<details>
<summary>Tool availability probe (excerpts)</summary>

<pre>
python3 3.13.14 /usr/local/bin/python3 ; pip 26.1.2 ; node v20.20.2 ; npm 10.8.2
git 2.47.3 ; curl 8.14.1 ; wget 1.25.0 ; gcc 14.2.0 ; make 4.4.1 ; jq 1.7
ffmpeg MISSING (installed via apt: 7.1.5) ; docker/podman MISSING ; clang MISSING
java: OpenJDK 11 ; sqlite3 MISSING (installed via apt: 3.46.1)
conda/mamba/rust/go/ruby/php/zstd/rsync/dig/tmux/gh : MISSING
preinstalled pip packages: 182 (numpy, pandas 2.2.3, scipy 1.17.1, matplotlib,
seaborn, plotly, spacy 3.8.14, nltk, sympy, openpyxl, aiohttp, requests, ...)
</pre>
</details>

---

*Report generated 2026-09-04 from raw measurements in `/home/user/envcheck/notes/`. Every number above was measured live in this environment; no values are estimates except the two explicitly flagged (OOM step granularity, reboot persistence semantics).*
