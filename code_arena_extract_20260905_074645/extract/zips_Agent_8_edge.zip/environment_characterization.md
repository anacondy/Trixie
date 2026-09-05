# Environment Characterization Report

**Raw evidence (preferred):** `probe_raw/*.txt` produced by `probe_environment.sh`. Run identity + SHA-256: `VERIFICATION_MANIFEST.md` and `probe_raw/00_MANIFEST.txt`. This Markdown is a **summary**; do not treat it as the primary record.

**Date measured:** 2026-09-04 (first pass ~11:19–11:21; scripted re-probe **14:14:32Z**)  
**Hostname:** `e2b.local`  
**Sandbox ID:** `i87c7gwotry240rbx1u77`  
**Template ID:** `nlhz8vlwyupq845jsdg9`  
**Method:** live commands (`uname`, `lscpu`, `curl`, Python `perf_counter`, `pip`, `gcc`, `df`, etc.)

---

## Executive summary

This is a **KVM virtual machine** (not a Docker container) running **Debian 13 (trixie)** on **2× Intel Xeon @ 2.60 GHz** with **~1.9 GiB RAM, no swap**, and **~20 GiB free** on a 25 GiB ext4 root disk. User `user` (uid 1000) has **passwordless sudo** and a rich Python 3.13 + Node 20 + gcc toolchain. **Network HTTPS is fast** (single-digit to tens of milliseconds TTFB; ~5 MB/s download of an 11 MB GitHub archive). **ICMP ping is forbidden** (no `cap_net_raw`). IPv6 DNS works but **IPv6 connect fails**. TCP to RFC5737 TEST-NET (`192.0.2.1`) succeeds instantly, which is consistent with a **transparent outbound proxy / firewall that accepts TCP broadly**. CPU and disk sequential I/O are adequate for mixed research work; **RAM (~1.9 GiB, 0 swap) is the hard ceiling** for large in-memory datasets.

---

## 1. Runtime & isolation

| Item | Value |
|------|--------|
| OS | Debian GNU/Linux 13 (trixie), `DEBIAN_VERSION_FULL=13.6` |
| Kernel | `6.1.158+` `#1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026` |
| Arch | `x86_64`, 64-bit |
| libc | GNU C Library **2.41** (`ldd (Debian GLIBC 2.41-12+deb13u3) 2.41`) |
| Virtualization | `systemd-detect-virt`: **kvm**; CPU flag `hypervisor`; Hypervisor vendor **KVM**, type **full** |
| CPU | Intel(R) Xeon(R) Processor @ 2.60 GHz, **2 logical CPUs** (1 core, 2 threads), AVX-512 present, BogoMIPS 5200 |
| Memory | **MemTotal 1 982 MiB** (2032608 kB); **SwapTotal 0** |
| Disk | `/dev/root` ext4 **25G**, ~**20G avail** (17% used) |
| Hostname | `e2b.local` |
| Init | PID 1 is `/sbin/init` (systemd-style full VM, not `containerd`/`docker`) |
| `/.dockerenv` | **absent** |
| cgroup | `/proc/1/cgroup` → `0::/init.scope`; cgroup2 mounted; **no** `memory.max`/`cpu.max` files at `/sys/fs/cgroup/` (not a tight container quota at that path) |
| Capabilities (self) | `CapEff=0`, `CapPrm=0`; bounding set `000001ffffffffff` |
| Seccomp | `Seccomp: 0` (disabled), `Seccomp_filters: 0` |
| User | `uid=1000(user) gid=1000(user)` groups `user,sudo,users` |
| Root / sudo | **`sudo -n` succeeds** → `uid=0(root)` (passwordless) |
| SELinux fs | mounted (`selinuxfs` on `/sys/fs/selinux`) |

### Resource limits (`ulimit -a`)

| Limit | Value |
|-------|--------|
| open files (`-n`) | 1024 |
| max user processes (`-u`) | 7917 |
| pending signals | 7917 |
| stack | 8192 kB |
| locked memory | 8192 kB |
| core file size | 0 |
| cpu time | unlimited |
| virtual / data / file size | unlimited |

### Isolation signals (summary)

- **VM, not Docker:** KVM hypervisor, `/sbin/init` as PID 1, no `/.dockerenv`.
- **E2B sandbox:** `E2B_SANDBOX=true`, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, `E2B_EVENTS_ADDRESS=http://192.0.2.1`.
- **Not capability-restricted for ordinary user work**, but **no net_raw** (ICMP ping fails).
- Root via sudo is available; this is **not** an unprivileged-only jail.

---

## 2. Tooling & language runtimes

### Availability + versions

| Tool | Path | Version / notes |
|------|------|-----------------|
| python3 | `/usr/local/bin/python3` | **3.13.14** (GCC 14.2.0) |
| pip / pip3 | `/usr/local/bin/pip` | **26.1.2** |
| node | `/usr/bin/node` | **v20.20.2** |
| npm | `/usr/bin/npm` | **10.8.2** |
| git | `/usr/bin/git` | **2.47.3** |
| curl | `/usr/bin/curl` | **8.14.1** OpenSSL 3.5.6, HTTP/2+3 |
| wget | `/usr/bin/wget` | **1.25.0** |
| make | `/usr/bin/make` | **4.4.1** |
| gcc / g++ | `/usr/bin/gcc` | **14.2.0** (Debian 14.2.0-19) |
| jq | `/usr/bin/jq` | **1.7** / 1.7.1 (apt-installed during test) |
| apt | `/usr/bin/apt` | **3.0.3** |
| java | `/usr/bin/java` | **OpenJDK 11** (2018-09-25 build string) |
| perl | `/usr/bin/perl` | **5.40.1** |
| tar / gzip / bzip2 / xz / unzip | present | GNU tar 1.35, gzip 1.13, bzip2 1.0.8, xz 5.8.1 |
| ssh / scp | present | OpenSSH client |
| ffmpeg | — | **NOT FOUND** |
| docker | — | **NOT FOUND** |
| clang | — | **NOT FOUND** |
| conda / cargo / rustc / go | — | **NOT FOUND** |
| ruby / php / rsync / sqlite3 | — | **NOT FOUND** |

### Preinstalled Python scientific stack (site-packages under `/usr/local`)

| Package | Version |
|---------|---------|
| numpy | 2.3.5 |
| pandas | 2.2.3 |
| scikit-learn | 1.6.1 |
| Pillow (PIL) | 12.3.0 |
| requests | 2.33.0 (also re-installed during test) |
| torch | **not installed** |

### Package managers — what actually works

| Manager | Works? | Evidence |
|---------|--------|----------|
| **apt** (with sudo) | **Yes** | `sudo -n apt-get install -y jq` completed (configured `libjq1` + `jq`) |
| **pip** | **Yes** | `pip install requests` ~0.72 s; `tqdm` ~0.46 s; `httpx` ~0.43 s (small wheels; network + cache) |
| **npm** | Binary present | not exercised with a full install |
| apk / yum / conda | absent | — |

**Compile:** `gcc` compiled `int main(){return 0;}` in **0.28 s** wall time — native C compile works.

**Implication:** Pure-Python and many wheels install quickly. System packages need `sudo apt`. No Docker-in-sandbox. ffmpeg/clang/rust/go must be apt-installed if needed.

---

## 3. Filesystem & persistence

| Location | Size / type | Writable by `user`? |
|----------|-------------|---------------------|
| `/` (`/dev/vda`, ext4, discard) | 25G, 20G free, 6.76M inodes, 3% inodes used | **No** (PermissionError) |
| `/home/user` | on root fs | **Yes** (write/read/delete OK) |
| `/tmp` | **tmpfs ~993M** | **Yes** |
| `/var/tmp` | on root | **Yes** |
| `/usr/local` | on root | **Yes** (unusual; Python lives here) |
| `/opt` | | **No** |
| `/dev/shm` | tmpfs 993M | — |
| Credential ramfs under `/run/credentials/*` | | **ro** |

**Working directory / home:** `/home/user` (cwd of this session).

**Inodes:** plentiful (6.6M free on root).

**Persistence (from platform contract + this session):** files under `/home/user` persist across conversation messages. **`/tmp` is tmpfs** — do **not** store pipeline data there (lost on reboot; capped ~1 GiB). Snapshot excludes `.venv`, `node_modules`, `dist`, `.cache`, etc.

**Write test:** `/home/user`, `/tmp`, `/var/tmp`, `/usr/local` succeeded; `/` and `/opt` failed with EACCES.

---

## 4. Network characterization

ICMP **does not work**: `ping: socket: Operation not permitted` (`cap_net_raw` missing). Latency below is **TCP connect** and **HTTPS curl**.

### DNS

`getent hosts` wall times (stderr `time`): google.com **6 ms**, github.com **5 ms**, pypi.org **2 ms**, huggingface.co **30 ms**, 8.8.8.8 reverse **3 ms**.

Both A and AAAA records returned for google/pypi/HF. GitHub resolved to **140.82.116.3**.

### HTTPS curl (follow redirects, `--max-time 20`)

| Endpoint | DNS (s) | TCP connect (s) | TLS (s) | TTFB (s) | Total (s) | Bytes | HTTP |
|----------|---------|-----------------|---------|----------|-----------|-------|------|
| https://google.com | 0.0038 | 0.0045 | 0.0204 | 0.0648 | 0.0660 | 83 332 | 200 |
| https://github.com | 0.0104 | 0.0106 | 0.0318 | 0.0426 | 0.0881 | 576 127 | 200 |
| https://pypi.org | 0.0011 | 0.0014 | 0.0203 | 0.0288 | 0.0305 | 27 965 | 200 |
| https://huggingface.co | 0.0209 | 0.0212 | 0.0380 | 0.0474 | 0.0618 | 182 055 | 200 |

IPv4-only Google: total **0.020 s**. IPv6 Google: **Failed to connect** after 2 ms (`Could not connect to server`). **Prefer IPv4.**

### TCP connect RTT (Python `socket.connect`, 5 samples, port 443)

| Host | min (ms) | avg (ms) | max (ms) |
|------|----------|----------|----------|
| 8.8.8.8 | 0.17 | 0.22 | 0.29 |
| google.com | 1.20 | 1.32 | 1.48 |
| pypi.org | 0.77 | 0.90 | 0.99 |
| huggingface.co | 1.04 | 3.93 | 14.91 |
| github.com | 1.17 | 8.83 | 28.36 |

Very low min RTT (sub-ms to 8.8.8.8) suggests **nearby cloud / proxy path**, not a distant residential ISP.

### Throughput

| Test | Result |
|------|--------|
| `curl` GitHub release `git-2.45.0.tar.gz` | **11 119 139 bytes** in **2.124 s** → **~5.24 MB/s** (`speed_download` 5 235 568 B/s), HTTP 200 |

No captive portal. No HTTPS blocks on the four named sites.

### Ports / protocols

- **ICMP:** blocked for unprivileged sockets.
- **HTTPS/HTTP:** fine.
- **SSH to github.com:22:** TCP connect succeeded in ~1.8 ms (Git protocol possible if keys exist).
- **`connect_ex` to 1.1.1.1 on ports 22,53,80,443,587,993,3306,5432,8080,8443:** all returned **0 in ~0 ms**.
- **`192.0.2.1:9` (TEST-NET, should not exist):** also **connect_ex=0 in 0 ms**.

**Interpretation:** outbound TCP is likely **intercepted by a transparent proxy** that completes the handshake regardless of destination. Application-level HTTPS still works to real sites. Do **not** treat “TCP connect success” as proof a remote service is reachable; verify with application protocol (HTTP status, TLS, etc.).

---

## 5. Performance micro-benchmarks

Timed with Python `time.perf_counter()` unless noted (`time` builtin for pip/gcc).

| Benchmark | Result | How |
|-----------|--------|-----|
| `sum(range(10**7))` | **0.232 s** (result 49999995000000) | CPython 3.13 |
| Heavier loop: `x += i*i` for 5×10⁶ | **0.693 s** | CPython |
| numpy `arange(10**7, float64).sum()` | **0.0365 s** | numpy 2.3.5 |
| Sequential write 80 MiB + `fsync` to `/home/user` | **0.169 s → 495 MB/s** | 1 MiB chunks |
| Sequential read same 80 MiB | **0.018 s → 4594 MB/s** | **hot page cache**, not disk |
| `pip install requests` | **0.72 s** wall | already/near-cached wheel |
| `pip install tqdm` | **0.46 s** | |
| `pip install httpx` | **0.43 s** | |
| `gcc` hello world | **0.28 s** wall | |
| Large HTTPS download | **5.24 MB/s**, 11.1 MB in 2.12 s | GitHub |

**Fast:** DNS, TLS to PyPI/Google, small pip wheels, gcc trivial compile, cached disk reads, numpy vs pure Python (~6× on this sum).  
**Slow / constrained:** raw CPython loops (expected); **RAM 1.9 GiB / no swap**; ICMP unusable; IPv6 broken; `/tmp` only ~1 GiB tmpfs.

---

## 6. Other observations

- **Memory:** ~1.5 GiB available at idle; **no swap** → large pandas/numpy jobs will OOM rather than thrash. `ulimit` virtual memory unlimited, but physical RAM is the wall.
- **Background processes:** systemd + kernel threads present; platform supports long-running processes (this agent can start them). Tooling bash sessions themselves are **time-capped** (tens of seconds to ~30 min depending on the runner).
- **Load:** `uptime` ~1 minute after boot, load 0.18 — **fresh VM per session**.
- **Env injection:** `E2B_*` variables mark the sandbox. `PATH` is standard. No HTTP(S)_PROXY env vars set (proxy, if any, is transparent).
- **`/etc/ssl/certs` is tmpfs** — unusual; certs are present enough for curl TLS to work.
- **Root disk discard** (`relatime,discard`) — virtio/cloud volume.
- **Open files 1024** — watch for crawler/pipeline fd leaks.
- **Cannot docker**; cannot ping; sudo **can** apt-install (jq succeeded).
- Port-scan results are **not trustworthy** due to transparent TCP accept.

### What is fast vs slow vs hard-limited

| Fast | Slow / mediocre | Hard limits |
|------|-----------------|-------------|
| DNS, HTTPS TTFB (~30–90 ms) | CPython tight loops | **~1.9 GiB RAM, 0 swap** |
| Small pip installs (<1 s) | Large model weights vs 2 GB RAM | **No ICMP** |
| gcc present; numpy/pandas/sklearn already there | ~5 MB/s download (OK, not 100 MB/s LAN) | **No Docker / ffmpeg / rust / go** until apt |
| 20 GiB free disk on `/` | `/tmp` tmpfs 1 GiB | **IPv6 connect fails** |
| Passwordless sudo + apt | 2 vCPU only | Snapshot **drops** `.venv`/`node_modules` |

---

## Appendix — notable raw outputs

<details>
<summary>uname / os-release / user</summary>

```
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
uid=1000(user) gid=1000(user) groups=1000(user),27(sudo),100(users)
ldd (Debian GLIBC 2.41-12+deb13u3) 2.41
```

</details>

<details>
<summary>Memory / disk</summary>

```
Mem: 1.9Gi total, ~1.3Gi free idle, Swap: 0B
/dev/root ext4 25G  4.1G  20G  17% /
tmpfs     993M on /tmp
```

</details>

<details>
<summary>curl HTTPS timings (one-liners)</summary>

```
google.com   dns:0.003810s connect:0.004504s tls:0.020410s ttfb:0.064818s total:0.065981s size:83332 http:200
github.com   dns:0.010351s connect:0.010558s tls:0.031779s ttfb:0.042599s total:0.088116s size:576127 http:200
pypi.org     dns:0.001119s connect:0.001366s tls:0.020303s ttfb:0.028839s total:0.030545s size:27965 http:200
huggingface.co dns:0.020900s connect:0.021205s tls:0.038030s ttfb:0.047394s total:0.061778s size:182055 http:200
download: http:200 size:11119139 speed:5235568B/s total:2.123769s
```

</details>

---

*End of characterization. Re-run timings if the template ID changes; this snapshot is template `nlhz8vlwyupq845jsdg9`.*
