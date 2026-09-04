# Environment Characterization Report

**Date:** 2026-09-04 (all measurements taken this session; sandbox clock is UTC)
**Host:** `e2b.local` — E2B sandbox microVM (sandbox ID `iptxurfwauu23eb0ooerk`, template `nlhz8vlwyupq845jsdg9`)
**Method:** every number below was measured live in this sandbox (`time`, `dd`, `curl -w`, Python `time.perf_counter`, allocation-until-OOM). Nothing is estimated unless explicitly marked.

---

## Executive Summary

This is a **Firecracker-class microVM (E2B sandbox) running Debian 13.6 "trixie" on kernel 6.1.158+**, with **2 vCPUs (Xeon @ 2.60 GHz, AVX-512), 1.94 GiB RAM of which a cgroup hard-caps our workload at ~1.81 GiB, no swap, and a 25 GB ext4 rootfs (20 GB free)**. Networking is outstanding and unusual: all outbound TCP is intercepted by a nearby egress layer, giving **sub-millisecond TCP connects, ~1 ms DNS, and 69–376 MB/s sustained downloads** (upload ~46 MB/s) — but that also means measured "latency" does **not** reflect true internet RTT, and in-sandbox port scans are meaningless (even nonsense ports appear "open"). Package management fully works (`apt`, `pip`, `npm` all install in 0.6–2.3 s), compiling works, background/long-running processes work, and the main practical constraints for a data pipeline are the **1.8 GiB memory ceiling (OOM-kill, no swap), 2 vCPUs, 993 MB tmpfs `/tmp`, and a 1024 default open-file soft limit (raisable to 524 288)**.

---

## 1. Runtime & Isolation

### 1.1 OS / Kernel / Architecture

| Property | Value |
|---|---|
| OS | Debian GNU/Linux 13.6 (trixie) |
| Kernel | `6.1.158+ #1 SMP PREEMPT_DYNAMIC` (built 2026-07-17; `+` = custom/local build) |
| Architecture | x86_64 |
| libc | glibc 2.41 (Debian GLIBC 2.41-12+deb13u3) |
| CPU | Intel(R) Xeon(R) @ 2.60 GHz, **2 logical CPUs** (`nproc`=2, cpuset `0-1`), flags incl. `avx512f avx2 fma aes` |
| RAM | 1.94 GiB total (`MemTotal 2 032 608 kB`), **no swap** |
| Clock/TZ | UTC (Etc/UTC), NTP-consistent |

### 1.2 Virtualization / sandbox signals

This is a **VM, not a container** — but a managed, single-purpose one:

- **PID 1 is `/sbin/init` (systemd)** with a full kernel process tree (`kthreadd`, per-CPU kthreads). No `/.dockerenv`, no container overlayfs — rootfs is ext4 on a **virtio disk** (`jbd2/vda-8` ⇒ `/dev/vda`).
- `E2B_SANDBOX=true`, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID` env vars; hostname `e2b.local`; systemd units `envd.service` (E2B daemon), `code-interpreter.service`, `jupyter.service` (127.0.0.1:8888), plus `socat` forwarders on `eth0` (the platform's live-preview port proxying).
- Network: `eth0 = 169.254.0.21/30`, default gateway `169.254.0.22` — a **point-to-point link-local link to the hypervisor**, MTU 1500. `/etc/hosts` maps `events.e2b.local → 192.0.2.1`, which answers HTTP 404 in ~1.5 ms (sandbox control plane, in-VM).

### 1.3 Security posture

| Check | Result |
|---|---|
| User | `uid=1000(user) gid=1000(user)`, groups: `user`, **`sudo`**, `users` |
| Root | **`sudo -n id` → `uid=0(root)` — passwordless sudo works** |
| Seccomp | `Seccomp: 0`, `Seccomp_filters: 0` — **no seccomp filtering** |
| NoNewPrivs | 0 |
| Capabilities (as `user`) | `CapEff/Prm = 0` (none), `CapBnd = 0x1ffffffffff` (full bounding set) → root via sudo gets full caps |
| ICMP | **unprivileged `ping` fails** (`Operation not permitted`, no `CAP_NET_RAW`); works under sudo |

### 1.4 Resource limits

| Limit | Value | Source |
|---|---|---|
| Memory hard cap | **1 947 172 864 B = 1.81 GiB** (`memory.max` = `memory.high`) | cgroup v2 `/user` scope |
| CPU quota | **none** (`cpu.max = max 100000`); 2 vCPUs via cpuset | cgroup v2 |
| PIDs | `max` in `/user`; 2 375 in `init.scope` (system slice) | cgroup v2 |
| I/O limits | none (`io.max` empty) | cgroup v2 |
| Open files | soft **1024**, hard **524 288** — verified raise to 4096 works | `ulimit -n` |
| Max user processes | 7 917 | `ulimit -u` |
| Stack / memlock | 8 MiB / 8 MiB | `ulimit` |
| Core dumps | disabled (0 blocks) | `ulimit -c` |

---

## 2. Tooling & Language Runtimes

### 2.1 Availability matrix (verified by executing each binary)

| Tool | Status | Version | Tool | Status | Version |
|---|---|---|---|---|---|
| python3 / python | ✅ | **3.13.14** | pip / pip3 | ✅ | 26.1.2 |
| node | ✅ | **20.20.2** | npm / npx | ✅ | 10.8.2 |
| git | ✅ | 2.47.3 | curl | ✅ | 8.14.1 (OpenSSL 3.5.6) |
| wget | ✅ | 1.25.0 | make | ✅ | GNU Make 4.4.1 |
| gcc / g++ | ✅ | **14.2.0** | jq | ✅ | 1.7 |
| apt / apt-get | ✅ | 3.0.3 | openssl | ✅ | 3.5.6 |
| java | ✅ | OpenJDK 11 | tar / gzip / xz / unzip | ✅ | 1.35 / 1.13 / 5.8.1 |
| ssh / scp / socat | ✅ | — | ffmpeg | ❌ missing | — |
| docker / podman | ❌ missing | — | clang / cmake | ❌ missing | — |
| go / rustc / cargo | ❌ missing | — | conda / uv / pipx | ❌ missing | — |
| tmux / screen / htop | ❌ missing | — | strace / gdb / valgrind | ❌ missing | — |
| sqlite3 CLI | ❌ missing | (Python `sqlite3` module ✅) | rsync / rg* | ❌ (*installed during test: rg 14.1.1) | — |

All ❌ items are `apt-get install`-able (repo access confirmed working).

### 2.2 Preinstalled Python scientific stack

`numpy 2.3.5`, `pandas 2.2.3`, `scipy 1.17.1`, `scikit-learn 1.6.1`, `requests 2.33.0`, `aiohttp`, `psutil 7.2.2`, `bokeh`, `beautifulsoup4`, plus Jupyter stack. **No** `torch` / `transformers` (installable via pip, but mind the 1.8 GiB RAM ceiling). `python3 -m venv` works (2.2 s).

### 2.3 Do package managers actually install? (measured)

| Manager | Test | Result | Wall time |
|---|---|---|---|
| apt | `sudo apt-get update` | ✅ index refresh | **0.78 s** |
| apt | `apt-get install file` | ✅ `file-5.46` installed | **0.87 s** |
| apt | `apt-get install ripgrep` | ✅ `ripgrep 14.1.1` | **2.27 s** |
| pip | `pip install --target … six` (no cache) | ✅ pure-Python install | **0.73 s** |
| pip | `pip install tabulate` into fresh venv | ✅ | **0.58 s** |
| pip | `pip download numpy` (16.7 MB wheel) | ✅ | **0.90 s** (≈18.6 MB/s incl. resolver) |
| npm | `npm install left-pad` | ✅ | **0.91 s** |
| gcc | compile + run C program w/ libm | ✅ | **0.54 s** |

**Compiling works** (gcc 14.2, headers + libm present). C-extension builds should work; no `clang`/`cmake` by default.

---

## 3. Filesystem & Persistence

### 3.1 Layout & space

| Mount | FS | Size | Avail | Notes |
|---|---|---|---|---|
| `/` (incl. `/home/user`) | ext4 on virtio `/dev/vda` | **25 G** | **20 G** | 6.76 M inodes, 3 % used |
| `/tmp` | **tmpfs (RAM)** | **993 M** | 993 M | lost on reboot; counts against RAM budget |
| `/dev/shm` | tmpfs | 993 M | 993 M | usable for IPC/shared mem |
| `/run` | tmpfs | 397 M | — | |

Working dir = home = **`/home/user`** (the platform-persisted "workspace").

### 3.2 Write/read/delete tests (all passed unless noted)

`/home/user` ✅ · `/tmp` ✅ · `/var/tmp` ✅ · `/dev/shm` ✅ · `/usr/local/bin` ✅ (unusual, but writable) — while `/opt`, `/etc`, `/root`, `/mnt`, `/srv` ❌ for `user` (root-owned; all writable via sudo). **No read-only mounts** in `/proc/mounts`.

### 3.3 Persistence semantics

- **Across tool calls (this session):** verified — marker file written at 10:14:40Z was read back intact later (`envchar/persistence_marker.txt`).
- **Across sessions:** per platform design, **only `/home/user` is snapshot-persisted** (capped ≈128 MB / 10 000 files per snapshot; generated dirs like `node_modules`, `__pycache__`, `dist`, `.venv` and dotfile caches are excluded). Consequences: **apt/conda/system-pip installs, `/tmp` contents, and running processes do NOT survive** a session/sandbox restart — vendor wheels or install into `/home/user`-relative paths (e.g. `pip install --target ./pylibs`) if you need durability. *Not directly testable within a single session — stated from platform documentation, not measurement.*

---

## 4. Network Characterization

### 4.1 The big caveat: transparent egress interception

TCP connects to `8.8.8.8:443` complete in **0.4 ms** and ICMP RTT to both `8.8.8.8` and `google.com` is **~0.5 ms** — physically impossible from the real internet. Confirmation: connecting to **nonsense ports `8.8.8.8:12345` and `:59999` also "succeeds"** (SYN accepted), while an HTTP request to a port with nothing behind it just hangs. Conclusion: **all outbound TCP is proxied/accelerated by the sandbox's egress layer.** All latency figures below therefore measure *sandbox → nearby egress*, not sandbox → destination. Throughput figures are real end-to-end goodput (bytes actually received).

### 4.2 DNS (resolver = `8.8.8.8` directly in `/etc/resolv.conf`, no local cache daemon)

| Domain | 5× `getaddrinfo` (ms) | Avg | Notes |
|---|---|---|---|
| google.com | 5.6 / 2.4 / 1.5 / 1.2 / 1.6 | 2.4 ms | |
| github.com | **5 018** / 7.9 / 9.9 / 1.2 / 12.6 | (outlier) | **one-off 5 s first lookup**, then 1–13 ms steady; raw UDP/53 probes 0.8–27.7 ms |
| pypi.org | 0.8–1.0 | 0.9 ms | |
| huggingface.co | 17.0 / 15.9 / 1.1 / 1.6 / 1.6 | 7.4 ms | |
| cloudflare.com | 9.8 / 10.1 / 1.1 / 1.1 / 1.2 | 4.7 ms | |
| amazon.com | 0.9–2.2 | 1.3 ms | |

DNS is effectively ~1 ms warm. Watch for **occasional multi-second cold-lookup stalls** (single 5 s event observed for github.com) — set DNS/connect timeouts and retries in pipeline code.

### 4.3 HTTPS latency breakdown (`curl -w`, fresh TLS each time, seconds)

| URL | DNS | TCP | TLS done | TTFB | Total | HTTP |
|---|---|---|---|---|---|---|
| https://www.google.com | 0.0015 | 0.0019 | 0.019 | 0.054 | **0.055** | 200 |
| https://github.com | 0.0018 | 0.0020 | 0.031 | 0.044 | **0.112** | 200 |
| https://pypi.org | 0.0016 | 0.0020 | 0.021 | 0.031 | **0.033** | 200 |
| https://huggingface.co | 0.0221 | 0.0225 | 0.042 | 0.064 | **0.085** | 200 |
| https://www.cloudflare.com | 0.0279 | 0.0282 | 0.072 | 0.098 | **0.306** | 200 |
| https://8.8.8.8 (‑k) | – | 0.0004 | 0.009 | – | **0.013** | 302 |
| ICMP 8.8.8.8 (sudo ping) | – | – | – | – | **RTT 0.45–0.65 ms** | 0 % loss |

No captive portal: plain `http://example.com` returns 200 directly (edge IP `104.20.23.154`, 68 ms). No `HTTP(S)_PROXY` env vars set.

### 4.4 Throughput (real file transfers)

| Endpoint | Payload | Time | Throughput |
|---|---|---|---|
| **dl.google.com** (chrome .deb) | 141.2 MB | 0.376 s | **375.7 MB/s (≈3.0 Gbps)** |
| **huggingface.co** (all-MiniLM-L6-v2 safetensors) | 90.9 MB | 1.02–1.32 s (3 runs) | **68.9–89.4 MB/s (≈0.55–0.72 Gbps)** |
| **PyPI CDN** via pip (numpy wheel) | 16.7 MB | 0.90 s | ≈18.6 MB/s (incl. pip overhead) |
| **github.com release** (ripgrep tarball) | 2.57 MB | 0.29 s | 8.7 MB/s (small-file dominated) |
| huggingface.co (gpt2 tokenizer.json) | 1.36 MB | 0.20 s | 6.7 MB/s |
| **Upload** → speed.cloudflare.com | 26.2 MB | 0.57 s | **46.3 MB/s (≈0.37 Gbps)** |
| speed.cloudflare.com `__down` | — | — | **HTTP 403** (bot protection on that endpoint — not a network block; see §6) |

Performance is mildly asymmetric (down ≫ up) and per-connection speed varies by CDN edge (Google ≫ HF ≫ small GitHub assets). For a few-MB files expect latency-, not bandwidth-, dominated transfers.

### 4.5 Outbound ports

Every tested port accepted a connection — 21, 22, 25, 53, 80, 443, 465, 587, 873, 993, 3306 **and the nonsense 12345/59999** — because the egress layer accepts SYNs on the sandbox's behalf. Practical reading: **outbound TCP appears unrestricted** (SMTP/FTP/SSH included), a connection to a real service works normally, a connection to a non-service silently hangs (`httpbin.org:8080` → 8 s timeout, no RST). In-sandbox port scanning cannot distinguish open/filtered. Unprivileged ICMP is blocked (needs sudo).

---

## 5. Performance Micro-benchmarks

CPU tests: Python 3.13.14, best-of-3 where noted, single-threaded unless stated.

| Benchmark | Time | Derived rate |
|---|---|---|
| `sum(range(10**7))` | **154.6 ms** | 65 M elem/s |
| loop 10⁶ × (sqrt+mul+div) | **134.9 ms** | 7.4 M iter/s |
| `",".join(map(str, range(10**5)))` | 9.5 ms | — |
| SHA-256 of 100 MB | **133.4 ms** | 750 MB/s |
| `np.sum(np.arange(1e8))` | 388.5 ms | 257 M elem/s |
| `np.dot` 1500×1500 (BLAS, AVX-512) | **65.1 ms** | **≈104 GFLOP/s** |
| multiprocessing `Pool(2)` vs sequential (2×3 M iters) | 226.8 vs 367.1 ms | **1.62× speedup** (2 vCPUs, real parallelism) |

Disk tests: 100 MiB file via `dd`, `/home/user` (ext4/virtio) vs `/tmp` (tmpfs):

| Operation | Time | Rate |
|---|---|---|
| ext4 write, `conv=fdatasync` | 0.158 s | **664 MB/s** |
| ext4 write, `oflag=direct` | 0.171 s | 614 MB/s |
| ext4 read, caches dropped (`drop_caches`) | 0.067 s | **1.6 GB/s** |
| ext4 read, `iflag=direct` | 0.048 s | 2.2 GB/s |
| ext4 read, page cache warm | 0.018 s | 5.9 GB/s |
| tmpfs `/tmp` write / read | 0.033 / 0.020 s | 3.2 / 5.3 GB/s |
| 500 small files create+fsync+delete (ext4) | 274 ms | **0.55 ms/file** |

Install/compile timings: see §2.3 (apt ≤2.3 s, pip ≤0.9 s, npm 0.9 s, gcc 0.5 s, venv 2.2 s).

**Standouts:** disk I/O is exceptionally fast for a sandbox (NVMe-backed host); BLAS throughput is server-grade thanks to AVX-512. Nothing measured was pathologically slow — the only slow event in the whole session was the one 5 s cold DNS lookup.

---

## 6. Other Observations

- **Memory pressure:** allocating and touching 100 MB chunks → **1 500 MB OK, OOM-killed mid-way through 1 600 MB** (exit 137, kernel cgroup OOM). No swap, `memory.high == memory.max` so there's no throttling soft zone — you get killed, not slowed. System recovered instantly (1.6 GiB free right after). **Budget pipeline processes for ≲1.3–1.4 GiB working set** to leave headroom for Jupyter/envd overhead in the same cgroup.
- **Background/long-running tasks:** fully supported. A heartbeat loop ran 90 consecutive 1-second ticks until deliberately stopped; the platform exposes managed background processes and port-forwarded live previews (socat on `eth0`). Individual shell commands are subject to a 30 s–1800 s timeout — long jobs must use background execution.
- **Sandbox-related injected config:** `E2B_SANDBOX=true`, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, `E2B_EVENTS_ADDRESS=http://192.0.2.1` (control plane, answers 404 in 1.5 ms); `events.e2b.local` in `/etc/hosts`; no proxy vars.
- **Speed.cloudflare `__down` returns 403** even with a browser UA — that specific endpoint is bot-protected from this egress; not indicative of blocked connectivity (uploads to the same host work, and 141 MB from Google worked at 376 MB/s).
- **Quirks:** unprivileged `ping` blocked; `core` dumps disabled; `/usr/local/bin` writable by `user`; `rpcbind`/NFS client modules loaded (host template artifact); only 2 vCPUs so don't over-provision worker pools; `/tmp` is RAM — big scratch files there steal from your 1.8 GiB budget.
- **Untested (not possible/needed here):** GPU (none present), inbound internet connectivity (no public IP; only platform-proxied previews), true cross-session persistence (requires an actual restart).

---

## 7. Verdict: Fast / Slow / Hard Limits

**Fast**
- Egress network: 0.03–0.1 s HTTPS round trips; 69–376 MB/s downloads, 46 MB/s upload
- Disk: 0.6 GB/s synced writes, 1.6–2.2 GB/s reads, 0.55 ms small-file churn
- Package installs: apt/pip/npm all sub-second to ~2 s; gcc compiles instantly
- Vectorized CPU: ~104 GFLOP/s BLAS (AVX-512)

**Slow / watch out for**
- Pure-Python single-thread CPU is mid-range (154 ms for `sum(range(10**7))`)
- Occasional multi-second cold DNS stalls (one 5 s event) — always set timeouts + retries
- Small-file downloads are latency-bound (6–9 MB/s on 1–3 MB assets)
- `multiprocessing` scaling caps at 2 cores (measured 1.62× on 2 workers)

**Hard limitations**
- **RAM: 1.81 GiB cgroup hard cap, OOM-kill at ~1.5–1.6 GiB touched, zero swap**
- **2 vCPUs**; no GPU
- 25 GB rootfs (20 GB free); `/tmp` is a 993 MB tmpfs; workspace snapshot ≈128 MB / 10 k files
- Persistence: only `/home/user` survives; system packages and `/tmp` don't
- Unprivileged ICMP blocked; no docker-in-sandbox; measured network latency ≠ real RTT (egress-proxied)

---

## Appendix A — Selected Raw Outputs

<details>
<summary>uname / os-release / identity / cgroup</summary>

```
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"  DEBIAN_VERSION_FULL=13.6
ldd (Debian GLIBC 2.41-12+deb13u3) 2.41
uid=1000(user) gid=1000(user) groups=1000(user),27(sudo),100(users)
sudo -n id -> uid=0(root) gid=0(root) groups=0(root)
Seccomp: 0   Seccomp_filters: 0   NoNewPrivs: 0
CapEff: 0000000000000000   CapBnd: 000001ffffffffff
/proc/self/cgroup -> 0::/user
user/memory.max = 1947172864 ; user/memory.high = 1947172864 ; user/memory.swap.max = max
user/cpu.max = max 100000 ; user/cpu.weight = 50 ; user/pids.max = max
cpuset.cpus.effective = 0-1
PID 1 = /sbin/init (systemd); eth0 = 169.254.0.21/30, gw 169.254.0.22, MTU 1500
ulimit: -n 1024 (hard 524288), -u 7917, -s 8192k, -c 0
E2B_SANDBOX=true E2B_SANDBOX_ID=iptxurfwauu23eb0ooerk E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
E2B_EVENTS_ADDRESS=http://192.0.2.1 ; nameserver 8.8.8.8 ; no proxy vars
```
</details>

<details>
<summary>Network raw measurements</summary>

```
sudo ping 8.8.8.8:   4 sent 4 recv 0% loss  rtt min/avg/max/mdev = 0.450/0.570/0.646/0.076 ms
sudo ping google.com: 3 sent 3 recv 0% loss rtt = 0.444/0.479/0.526/0.034 ms
ping (unprivileged):  "socket: Operation not permitted" (no CAP_NET_RAW)

curl -w (s):  google    dns .0015 tcp .0019 tls .0190 ttfb .0538 total .0547 200
              github    dns .0018 tcp .0020 tls .0306 ttfb .0444 total .1121 200
              pypi      dns .0016 tcp .0020 tls .0214 ttfb .0310 total .0327 200
              hf.co     dns .0221 tcp .0225 tls .0415 ttfb .0640 total .0849 200
              cloudfl.  dns .0279 tcp .0282 tls .0720 ttfb .0976 total .3057 200
              8.8.8.8   tcp .0004 tls .0089 total .0127 302

downloads: dl.google.com 141157492 B in .375681 s = 375737639 B/s 200
           hf 90868376 B: .0853/.0835/.0689 GB/s over 3 runs 200
           upload 26214400 B in .565675 s = 46341804 B/s 200
           github ripgrep 2566310 B in .293766 s 200
           speed.cloudflare.com/__down -> 403 (1 byte) even w/ browser UA
ports: 21,22,25,53,80,443,465,587,873,993,3306,12345,59999 all "connect OK";
       httpbin.org:8080 timed out (8.0 s, http_code 000); plain http://example.com 200 via 104.20.23.154
```
</details>

<details>
<summary>Benchmark raw output</summary>

```
sum(range(10**7))                    154.6 ms   (result=49999995000000)
loop 1e6: sqrt+mul+div               134.9 ms
str join 1e5 ints                      9.5 ms
sha256 100MB                         133.4 ms
np.sum(np.arange(1e8))               388.5 ms
np.dot 1500x1500 (BLAS)               65.1 ms   -> ~103.6 GFLOP/s
mp Pool(2) 2x3e6: par=226.8 ms  seq=367.1 ms  speedup=1.62x

dd ext4 fdatasync write 100MiB: 0.157958 s, 664 MB/s
dd ext4 O_DIRECT write:         0.170705 s, 614 MB/s
dd ext4 read (caches dropped):  0.067076 s, 1.6 GB/s
dd ext4 O_DIRECT read:          0.047523 s, 2.2 GB/s
dd ext4 read (warm):            0.017711 s, 5.9 GB/s
dd tmpfs write/read:            3.2 / 5.3 GB/s
500 create+fsync+delete: 274 ms (0.55 ms/file)

memory: allocated 100..1500 MB ok; killed (exit 137) during 1600 MB chunk
installs: apt update .78 s | apt file .87 s | apt ripgrep 2.27 s | pip six .73 s |
          pip tabulate .58 s | pip download numpy .90 s | npm left-pad .91 s |
          git clone --depth 1 .95 s | gcc compile .54 s | venv 2.2 s
```
</details>

*Artifacts kept in workspace: `envchar/bench.py` (re-runnable CPU benchmark), `envchar/persistence_marker.txt`. All large test files were deleted after measurement.*
