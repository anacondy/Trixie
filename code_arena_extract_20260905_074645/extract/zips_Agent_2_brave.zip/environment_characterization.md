# Environment Characterization Report

This Markdown file is a **human summary**. Primary evidence is the verbatim probe transcripts — no LLM layer:

| Role | Path |
|---|---|
| Probe (re-run this) | [`envchar/probe.sh`](envchar/probe.sh) + [`envchar/probe_bench.py`](envchar/probe_bench.py) |
| How to run / diff | [`envchar/README.md`](envchar/README.md) |
| This run’s manifest | [`envchar/MANIFEST.txt`](envchar/MANIFEST.txt) |
| `sha256sum -c` file | [`envchar/SHA256SUMS`](envchar/SHA256SUMS) |
| Raw transcripts | [`envchar/raw/`](envchar/raw/) (`01_runtime.txt` … `16_misc.txt`) |

**Published run (probe, not the earlier exploratory session):**  
sandbox `i4i7wdij5c7gh9absvtu8` · template `nlhz8vlwyupq845jsdg9` · `generated_utc=2026-09-04T13:45:05Z` · `raw_combo_sha256=891ecbd96758ea79019d8ae2b02829e713b3042d20f0f4cac313fa89bedd8e06`

Third party: `cd envchar && sha256sum -c SHA256SUMS && ./probe.sh` then `diff -ru raw/ <their-raw>/`.

---

**Exploratory session (pre-probe, 09:53–09:59 UTC):** sandbox `i0v44lh3n78xffvhm6u5u`, same template. Numbers below mix that session with the published probe run; **when they disagree, trust `envchar/raw/`**.  
**Method:** live commands (`uname`, `/proc`, `python3` `perf_counter`, `curl -w`, `pip`/`apt` installs, sequential I/O).

---

## Executive summary

This is a **fresh E2B Firecracker-style KVM microVM** (not a Docker container): Debian 13 (trixie) on Linux 6.1.158+, **2 vCPUs** (Intel Xeon @ 2.60 GHz, 1 core / 2 threads, AVX-512), **~2 GiB RAM with no swap**, and a **25 GiB virtio root disk (~20 GiB free)**. The unprivileged user `user` (uid 1000) has **passwordless sudo**, so system packages and compilers work; outbound IPv4 is **fast and largely unrestricted** (Cloudflare 50 MiB download ≈ **83 MB/s / 665 Mbps**), while **IPv6 is unreachable** and **ICMP ping requires sudo**. It is a strong environment for mixed CPU + network + install work **as long as the working set stays under ~1.2–1.4 GiB**, large files stay off `/tmp` (tmpfs, counts as RAM), and snapshot-excluded dirs (`.local`, `.venv`, `node_modules`, `.cache`) are not used as the source of truth.

---

## 1. Runtime & isolation

### Identity

| Item | Value |
|---|---|
| OS | Debian GNU/Linux 13.6 (trixie) |
| Kernel | `6.1.158+` `#1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026` |
| Arch | `x86_64` / `amd64` |
| libc | glibc **2.41** (`Debian GLIBC 2.41-12+deb13u3`) |
| Hostname | `e2b.local` |
| Timezone / locale | `Etc/UTC`; locale is **POSIX** (no `LANG`) |
| Clock | systemd reports **NTP inactive / not synchronized**; RTC n/a |
| Init | `systemd` is PID 1 (`/proc/1/comm=systemd`) |

### Virtualization (not a container)

Clear **KVM microVM**, Firecracker-like:

- `systemd-detect-virt` → `kvm` (container: `none`)
- CPU flag `hypervisor`; `lscpu` hypervisor vendor **KVM**, virtualization type **full**
- **No** `/.dockerenv`
- cgroup v2; `/proc/1/cgroup` is `0::/init.scope` (machine-like, not `docker/…`)
- Kernel cmdline: `clocksource=kvm-clock pci=off root=/dev/vda virtio_mmio.device=… ip=169.254.0.21::169.254.0.22:255.255.255.252:instance:eth0:off:tap0`
- Root disk `/dev/vda` (virtio); **no `/dev/kvm`** (no nested VMs)
- Link-local nic: `eth0 169.254.0.21/30`, gateway `169.254.0.22`
- E2B markers: `E2B_SANDBOX=true`, `/.e2b`, `/run/e2b`, envd + Jupyter systemd units

This is a **full userspace Linux VM**, not an unshare/namespace-only sandbox.

### User, privileges, LSM

| Item | Value |
|---|---|
| User | `user` uid=1000 gid=1000 groups=`user,sudo,users` |
| Home / shell | `/home/user` `/bin/bash` |
| sudo | **NOPASSWD: ALL** (setuid `/usr/bin/sudo`) |
| Effective caps | **none** (`CapEff=0`); bounding set is full (`000001ffffffffff`, 41 bits) |
| Seccomp | **off** (`Seccomp=0`, no filters) |
| NoNewPrivs | 0 |
| AppArmor | `/proc/self/attr/current` = `kernel` (not enforcing a profile) |
| SELinux | filesystem present, enforce=`0` |
| ICMP | user **cannot** ping (`cap_net_raw` missing); `sudo ping` works |

### Resource limits

**CPU**

- `nproc` = **2**; `cpuset.cpus.effective` = `0-1`
- Topology: 1 socket, 1 core, 2 threads; advertised `Intel(R) Xeon(R) Processor @ 2.60GHz` (family 6, model 106, stepping 6 — Ice Lake-class)
- L1d 48 KiB, L1i 32 KiB, L2 1.3 MiB, **L3 54 MiB** (slice of a large Xeon)
- cgroup `cpu.max` = `max 100000` (no quota); `cpu.weight=50`
- `vmstat` steal time **0%** during idle sample
- AVX2 + AVX-512 (F/DQ/BW/VL/VNNI/VBMI/…) present — numpy reports AVX512_ICL usable

**Memory**

| Metric | Value |
|---|---|
| `MemTotal` | 2,032,608 kB (**1.94 GiB**) |
| `MemAvailable` at start | ~1.53 GiB |
| Swap | **none** (`SwapTotal=0`) |
| cgroup `user/memory.max` | **1,947,172,864 B (1.813 GiB)** |
| cgroup `user/memory.high` | same as max |
| `memory.swap.max` | `max` (but host has no swap) |

**ulimit (soft / hard)**

| Limit | Soft | Hard | Notes |
|---|---|---|---|
| open files (`-n`) | **1024** | 524288 | **pipeline hazard** — raise in long jobs |
| max user processes (`-u`) | 7917 | 7917 | |
| stack | 8192 kB | unlimited | |
| cpu time | unlimited | unlimited | |
| virtual / data | unlimited | unlimited | |
| core | 0 | 0 | |
| locked memory | 8192 kB | 8192 kB | |

cgroup `pids.max=max`. Observed `pids.peak` in `user` cgroup during this session: 20; ~90 processes system-wide.

### Sandbox-injected environment

```
E2B_SANDBOX=true
E2B_SANDBOX_ID=i0v44lh3n78xffvhm6u5u
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
E2B_EVENTS_ADDRESS=http://192.0.2.1
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

No HTTP(S)_PROXY. Extra listeners: Jupyter on `:8888` (token empty), `envd` / code-interpreter, ssh `:22`, several envd helper ports on `127.0.0.1` and `169.254.0.21`. `/etc/ssl/certs` is a tmpfs bind of `/run/e2b/certs`.

---

## 2. Tooling & language runtimes

### Availability and versions

| Tool | Present | Path | Version |
|---|---|---|---|
| python / python3 | yes | `/usr/local/bin/python3` | **3.13.14** (GCC 14.2.0) |
| pip / pip3 | yes | `/usr/local/bin/pip` | **26.1.2** |
| node | yes | `/usr/bin/node` | **v20.20.2** |
| npm / npx | yes | `/usr/bin/npm` | **10.8.2** |
| git | yes | `/usr/bin/git` | **2.47.3** |
| curl | yes | `/usr/bin/curl` | **8.14.1** (OpenSSL 3.5.6, HTTP/2+3) |
| wget | yes | `/usr/bin/wget` | **1.25.0** |
| gcc / g++ | yes | `/usr/bin/gcc` | **14.2.0** (`build-essential` installed) |
| make | yes | `/usr/bin/make` | **4.4.1** |
| jq | yes | `/usr/bin/jq` | **1.7** |
| java / javac | yes | `/usr/bin/java` | **OpenJDK 11** (18.9, 11+28) |
| perl | yes | `/usr/bin/perl` | **5.40.1** |
| R | yes | `/usr/bin/R` | **4.5.0** |
| openssl | yes | `/usr/bin/openssl` | **3.5.6** |
| ssh / scp | yes | `/usr/bin/ssh` | OpenSSH **10.0p2** |
| tar / gzip / xz / bzip2 / zip / unzip | yes | | GNU tar 1.35, gzip 1.13, xz 5.8.1 |
| pkg-config | yes | | 1.8.1 |
| socat / ip / ss | yes | | iproute2 6.15.0 |
| awk / sed / grep / find | yes | | mawk 1.3.4, GNU sed 4.9, grep 3.11 |
| **ffmpeg** | **no** | | Debian package `ffmpeg 7:7.1.5` is installable via apt |
| **docker / podman** | **no** | | `docker.io` exists in apt; **no `/dev/kvm`** |
| clang / rustc / go / ruby / php | no | | |
| conda / mamba / uv / poetry / pipx | no | | |
| cmake / ninja / meson | no | | |
| yarn / pnpm | no | | |
| vim / nano / tmux / htop / strace / gdb | no | | |
| rsync / zstd / 7z / parallel / aria2c | no | | |
| `/usr/bin/time` | no | | use `date`/`perf_counter` |

npm globals: `npm`, `corepack`, `ijavascript`.

### Package managers — do they actually install?

| Manager | Works? | Evidence |
|---|---|---|
| **apt / apt-get / dpkg** | **yes** (via sudo) | `apt-get update` **0.76 s**; `apt-get install tree` **1.95 s** (59.4 kB, 1776 kB/s from `deb.debian.org`). tree 2.2.1 runs. 37 packages “not upgraded”. |
| apk / yum / dnf / pacman / brew | no | not present |
| **pip** | **yes** | `tabulate==0.9.0` **0.96 s**; manylinux wheel `simplejson==3.19.3` **1.11 s**. `/usr/local/lib/python3.13/site-packages` is **mode 777** (world-writable). |
| **npm** | **yes** | `npm install left-pad` **1.29 s** |
| conda | no | |
| docker | not installed | nested virt unlikely |

**Compile:** `gcc -O2 hello.c -lm` **0.756 s**; `g++ -O2 -std=c++17` **1.002 s**; 1e7 `sin()` loop ran in **0.079 s**. `javac`/`java` hello-world OK.

### Preinstalled Python stack (181 packages)

Present and useful for research: **numpy 2.3.5** (OpenBLAS 0.3.30, Haswell kernel, AVX-512), **pandas 2.2.3**, **scipy 1.17.1**, **scikit-learn 1.6.1**, **opencv-python 4.11.0**, **Pillow 12.3.0**, matplotlib / seaborn / plotly / bokeh, networkx, sympy, **numba 0.66.0**, nltk, **spacy 3.8.14 (no language pipelines)**, gensim, librosa, scikit-image, jupyter_server, IPython 9.15.0, requests / httpx / aiohttp, pydantic 2.13.4, orjson, tqdm, pytest.

**Not present (must install if needed):** torch, tensorflow, transformers, datasets, huggingface_hub, tokenizers, fastapi/flask/django, sqlalchemy, boto3, openai/anthropic, polars, pyarrow, cryptography, tiktoken. No spaCy `en_core_*` model on disk.

---

## 3. Filesystem & persistence

### Layout and space

| Mount | Type | Size | Avail | Inodes (used/free) | Notes |
|---|---|---|---|---|---|
| `/` (`/dev/vda`) | ext4, rw,discard | **25 G** (24.1 G) | **~20 G** (17% used) | 136k / 6.62M (3%) | persist for VM lifetime |
| `/tmp` | **tmpfs** | **993 M** | ~986 M | 1,048,576 | **RAM-backed**; lost on reboot |
| `/dev/shm` | tmpfs | 993 M | 993 M | | |
| `/run` | tmpfs | 397 M | | | |
| `/etc/ssl/certs` | tmpfs bind (`/run/e2b/certs`) | 397 M | | | E2B CA bundle |

`du` snapshot: `/usr` 3.9 G, `/var` 45 M, `/home` ≈ 0 before tests. No disk quota.

### Write tests

| Path | Result |
|---|---|
| `/home/user` | write / read / delete **OK** |
| `/tmp` | **OK** (tmpfs) |
| `/var/tmp` | **OK** (on root ext4) |
| `/usr/local` | **OK as user** (no sudo) |
| `/usr/local/lib/python3.13/site-packages` | **OK as user** (777) |
| `/`, `/opt`, `/etc`, `/bin`, `/usr/bin`, `/lib` | **Permission denied** as user (sudo can write) |

### Persistence — what will survive

Documented platform behavior + observed mounts:

1. **Inside this VM / conversation:** `/home/user`, `/var/tmp`, `/usr/local`, and the root ext4 persist. `/tmp` is tmpfs (lives until reboot, **not** across VM recreate).
2. **Workspace snapshots** persist files under `/home/user` but **exclude** `.local`, `.cache`, `.venv`, `node_modules`, `__pycache__`, `build`, `dist`, `.npm`, etc.
3. **Implication for a pipeline:** do **not** rely on `pip install --user` (lands in `~/.local`, snapshot-excluded). Prefer:
   - project-local installs into a **non-excluded** directory (e.g. `/home/user/venv` is still named `.venv` if you use the default — **avoid the name `.venv`**), or
   - `sudo pip install` / write into `/usr/local` for the life of **this** VM only.
4. A marker was written to `/home/user/_envchar/session_marker.txt` (`created_utc=2026-09-04T09:59:50Z`) for a later session to verify survival.
5. This VM was **cold-booted** for this session (uptime 18 s at first command).

---

## 4. Network characterization

### L3 / DNS

- Resolver: `/etc/resolv.conf` → `nameserver 8.8.8.8`
- IPv4 default route via `169.254.0.22`
- **IPv6:** AAAA records resolve, but `connect()` → `Network is unreachable`. Treat as **IPv4-only**.
- UDP/53 to 8.8.8.8: **0.9 ms**, 124-byte reply; to 1.1.1.1: **17.8 ms**
- UDP/123 NTP to `time.google.com`: **2.4 ms** (works)
- UDP/443 (QUIC probe) to 1.1.1.1 and 8.8.8.8: **timeout 3 s** (QUIC likely unused/blocked or no service)

**DNS `getaddrinfo` (5 samples each, includes cache effects):**

| Host | min | mean | max | Notes |
|---|---|---|---|---|
| google.com | 1.4 ms | 2.5 ms | 4.0 ms | A+AAAA |
| github.com | 1.5 ms | 7.0 ms | 11.5 ms | A only here |
| pypi.org | 0.9 ms | 1.2 ms | 1.3 ms | Fastly |
| huggingface.co | 1.6 ms | 19.0 ms | 28.4 ms | CloudFront, first lookups slower |
| files.pythonhosted.org | 1.6 ms | 8.2 ms | 10.5 ms | |
| registry.npmjs.org | 1.2 ms | 5.4 ms | 20.8 ms | |
| cloudflare.com | 8.4 ms | 9.6 ms | 10.6 ms | |
| wikipedia.org (uncached / cached) | 24.7 / 1.4 ms | | | |

No captive portal. TLS certs are real (Google WR2, GitHub/Sectigo) — **no MITM intercept**.

### ICMP vs TCP latency

Unprivileged `ping`: **Operation not permitted**. `sudo ping -c 2 8.8.8.8`: **0.454 / 0.522 ms**, ttl=116.

**TCP connect, 5 samples (`python socket.connect`, 5 s timeout):**

| Target | min | mean | max |
|---|---|---|---|
| 8.8.8.8:443 / :53 | 0.1 ms | 0.2 ms | 0.3 ms |
| 1.1.1.1:443 | 0.2 ms | 0.2 ms | 0.3 ms |
| www.google.com:443 | 1.2 ms | 1.2 ms | 1.3 ms |
| google.com:443 | 1.3 ms | 1.5 ms | 1.8 ms |
| pypi.org:443 | 1.1 ms | 1.2 ms | 1.4 ms |
| files.pythonhosted.org:443 | 1.3 ms | 3.1 ms | 10.2 ms |
| registry.npmjs.org:443 | 1.3 ms | 1.5 ms | 1.8 ms |
| github.com:443 | 1.2 ms | 9.2 ms | 20.3 ms |
| huggingface.co:443 | 1.4 ms | 5.1 ms | 18.9 ms |
| cdn.jsdelivr.net:443 | 1.1 ms | 7.4 ms | 21.2 ms |

Sub-millisecond RTT to 8.8.8.8/1.1.1.1 plus traceroute hop 1 = `169.254.0.22` (~0.5 ms) and hop 2 = `10.12.0.92` is consistent with a **nearby cloud POP** (very likely GCP given 8.8.8.8 anycast). GitHub TCP traceroute reached `20.29.134.23` in **0.50 ms** (2 hops) — also local-region.

### HTTPS throughput (`curl -w`, `--http1.1` unless noted)

| Label | URL / source | Bytes | TTFB | Total | Speed |
|---|---|---|---|---|---|
| Google HTML | https://www.google.com/ | 83,443 (capped) | 57 ms | 0.058 s | (latency-bound) |
| GitHub HTML | https://github.com/ | 262,144 (capped) | 43 ms | 0.092 s | |
| PyPI simple/pip | https://pypi.org/simple/pip/ | 107,453 | 27 ms | 0.037 s | |
| HF homepage | https://huggingface.co/ | 182,060 | 77 ms | 0.094 s | |
| HF `config.json` | huggingface.co/bert-base-uncased | 570 | 211 ms | 0.211 s | |
| HF `tokenizer.json` | same repo | 466,062 | 112 ms | 0.215 s | 2.17 MB/s (small) |
| GitHub release | jq-linux-amd64 | **2,319,424** | 60 ms | **0.123 s** | **18.9 MB/s (151 Mbps)** |
| PyPI wheel | pip-25.0 py3 | 1,841,506 | 112 ms | 0.172 s | 10.7 MB/s (86 Mbps) |
| nodejs.org tarball | headers 8.1 MiB | 8,472,492 | 107 ms | 0.446 s | 19.0 MB/s (152 Mbps) |
| Cloudflare 1 MB | speed.cloudflare.com | 1,000,000 | 148 ms | 0.254 s | 3.9 MB/s (TTFB-bound) |
| Cloudflare 10 MB | same | 10,000,000 | 144 ms | 0.384 s | **26.1 MB/s (209 Mbps)** |
| **Cloudflare 50 MB** | same | **50,000,000** | 167 ms | **0.601 s** | **83.2 MB/s (665 Mbps)** |
| wget jq 2.3 MB | GitHub | 2,319,424 | — | 0.325 s | ~7.1 MB/s (cold DNS+TLS) |

HTTP/2 to pypi.org works (`http=2`, TTFB 33 ms). Parallel 4×5 MB to Cloudflare returned **HTTP 403** (bot/rate filter on `urllib` UA), not a connectivity failure.

**Saturated bulk download is on the order of 0.5–0.7 Gbps** to a nearby CDN. GitHub/PyPI small artifacts are typically **10–20 MB/s** because they never fill the pipe.

### Outbound ports / protocols

TCP connect (4 s timeout) — **all succeeded**, no evidence of an egress allowlist:

| Port | Destination | Result | Time |
|---|---|---|---|
| 22 | github.com, scanme.nmap.org | OPEN | 9–11 ms |
| 25 / 465 / 587 | smtp.gmail.com | OPEN | 1.4–2.6 ms |
| 53 | 8.8.8.8, 1.1.1.1 | OPEN | 0.3–0.5 ms |
| 80 / 443 | github, pypi, 1.1.1.1, example.com | OPEN | 0.2–21 ms |
| 853 | 1.1.1.1 DoT | OPEN | 0.2 ms |
| 9418 | github git-daemon | OPEN | 12.6 ms |

Host iptables policy ACCEPT (empty). Bind `0.0.0.0:18080` as user **OK**; bind `:80` needs sudo (works). Inbound from the public Internet was not tested; preview/proxy is a platform concern (`0.0.0.0` bind required for live preview).

**Restricted:** IPv6 data plane; unprivileged ICMP; UDP/443 (QUIC) no reply. Nothing else obvious.

---

## 5. Performance micro-benchmarks

Times are `time.perf_counter()` wall clock, 3 repeats unless noted. First-run numpy is inflated by page faults / OpenBLAS init — **use min**.

### CPU

| Benchmark | min | mean | max |
|---|---|---|---|
| Pure Python `sum(range(10**7))` | **175.1 ms** | 217.5 ms | 284.2 ms |
| Heavier Python loop 2×10^6 (`i*i ^ (i<<1)`) | 292.4 ms | 312.4 ms | 324.9 ms |
| `math.sin`+`sqrt` × 1e6 | 118.9 ms | 160.0 ms | 180.6 ms |
| numpy `arange(1e7, int64).sum()` | **34.2 ms** | 364.3 ms* | 1020 ms* |
| numpy 800×800 `float64` matmul | **17.3 ms** | 60.4 ms | 144.4 ms |
| numpy sort 5e6 `float64` | 66.5 ms | 74.3 ms | 79.4 ms |
| SHA-256 50 MiB in-memory | 26.9 ms | 27.7 ms | 28.6 ms (~1.8 GiB/s) |
| gcc -O2 1e7 `sin()` (compiled) | — | **79 ms** | — |
| 2-process vs 1-process tiny CPU loop | 0.194 s vs 0.173 s | | spawn overhead dominated |

\*numpy first call pays init; subsequent ~34 ms.

**Read:** CPython is fine but not fast (≈ 5.7e7 adds/s on `sum(range)`). Numpy/OpenBLAS is the right tool; AVX-512 is live. Only **two** logical CPUs — parallel jobs beyond 2 contend. No GPU / no torch.

### Disk (80 MiB random payload, `write` + `fsync`, then `drop_caches`, then read)

| Path | Write+fsync | Uncached read | Cached re-read |
|---|---|---|---|
| `/home/user` (ext4) | **0.274 s → 292 MiB/s** | **0.593 s → 135 MiB/s** | 0.024 s → 3.4 GiB/s |
| `/var/tmp` (ext4) | 0.302 s → 265 MiB/s | 0.141 s → 569 MiB/s | 0.023 s → 3.5 GiB/s |
| `/tmp` (tmpfs) | 0.039 s → **2.07 GiB/s** | 0.291 s → 275 MiB/s† | 0.028 s → 2.9 GiB/s |

†tmpfs read after `drop_caches` still competes with RAM reclaim; tmpfs **consumes the 2 GiB RAM budget**.

Virtio ext4 sequential write ≈ **250–300 MiB/s**; uncached read **135–570 MiB/s** (noisy on a 80 MiB sample). Fine for 50–100 MB intermediates; not a local NVMe workstation.

### Install timings

| Operation | Time |
|---|---|
| `apt-get update` | 0.76 s |
| `apt-get install tree` (59 kB) | 1.95 s |
| `pip install tabulate==0.9.0` | 0.96 s |
| `pip install simplejson==3.19.3` (wheel) | 1.11 s |
| `npm install left-pad` | 1.29 s |
| `git clone --depth 1` jqlang/jq | 1.07 s (7.3 M) |
| `gcc -O2` tiny C | 0.76 s |
| `g++ -O2` tiny C++ | 1.00 s |

Package installs are **fast** (Debian + PyPI + npm all nearby). A heavy apt set (ffmpeg + codecs) will be dominated by archive size, not latency; dry-run shows many media deps (Installed-Size ffmpeg itself 2680 kB plus libs).

### Memory pressure

Allocated 50 MiB `bytearray` chunks until `MemAvailable < 80 MiB`:

- Reached **~1500 MiB RSS** (`ru_maxrss=1,543,784 kB`)
- `MemAvailable` 70,628 kB; **no OOM**, `memory.events.oom=0`
- cgroup `memory.peak` during session: **1,636,802,560 B (1.52 GiB)**
- After `del` + `gc`: `MemAvailable` back to ~1.58 GiB

Crossing ~1.8 GiB cgroup max **will OOM-kill** (no swap). `/tmp` files count against RAM.

### Background / long-running

- `nohup sleep 8` survived independently of the parent wait; completed as expected.
- Agent `bash` tool: default 30 s, **max 1800 s**, then killed. Use `start_process` for servers / multi-hour jobs.
- systemd user services not required; root can `systemctl`.
- Soft `nofile=1024` will bite crawlers, TF/torch data loaders, and many-small-file unpackers — `ulimit -n 65536` at job start.

---

## 6. Other observations

### What is fast

- Cold-start of the VM itself (ready in seconds).
- DNS + TLS + small HTTPS (PyPI/GitHub TTFB 30–80 ms).
- Bulk IPv4 download (**~0.6–0.7 Gbps** to Cloudflare).
- `apt`/`pip`/`npm` of small packages (**~1–2 s**).
- Numpy / OpenBLAS / SHA-256.
- ext4 write of tens of MB (hundreds of MiB/s).
- Compiling small C/C++.

### What is slow or tight

- **RAM: 2 GiB, no swap.** Pandas + spacy + a few MB images will fit; pytorch models, big dataframes, and `/tmp` staging will not.
- **2 vCPUs** — multiprocessing beyond 2 is negative; numpy OpenBLAS `MAX_THREADS=64` should be capped (`OMP_NUM_THREADS=2`).
- Pure Python loops (~175 ms for `sum(range(1e7))` is typical CPython, not a VM tax).
- Hugging Face **first** DNS/TTFB is the slowest of the measured origins (20–80+ ms, sometimes 200 ms for tiny files).
- Locale POSIX / no NTP — timestamps are UTC but not advertised as synced.
- Tooling gaps: no ffmpeg, docker, cmake, clang, rust, uv, polars, torch, huggingface_hub.

### Hard limitations

| Limit | Detail |
|---|---|
| Memory | **1.81 GiB cgroup max**, 1.94 GiB host, **0 swap** |
| CPU | **2** logical CPUs, no quota but no more cores |
| Disk | **~20 GiB free**; `/tmp` only **993 MiB tmpfs** |
| IPv6 | DNS yes, **packets no** |
| ICMP | needs sudo |
| Nested virt / Docker | no `/dev/kvm`; docker not installed |
| GPU | none |
| nofile | **1024** soft |
| Snapshots | `~/.local`, `.venv`, `node_modules`, `.cache` **dropped** |
| Network | IPv4 appears open; QUIC/UDP-443 not useful |
| Clock | NTP inactive |
| Preview servers | must bind `0.0.0.0`, not `127.0.0.1` |

### What broke / surprised

- `ping` as user fails; `sudo ping` RTT to 8.8.8.8 is **<1 ms**.
- Parallel Cloudflare downloads via Python `urllib` got **403**; `curl` with default UA was fine.
- `/usr/local` and Python site-packages are **writable without sudo**.
- Jupyter runs **without a token** on 8888 (local to the VM).
- `example.com` IPv4 TCP connect was 0.2 ms — anycast/edge proximity, not a broken stack (TLS to real Google/GitHub certs).
- numpy 800×800 matmul min 17 ms is healthy for 2.6 GHz; the 144 ms max is warmup.

### Pipeline recommendations

1. Cap threads: `export OMP_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2 MKL_NUM_THREADS=2`.
2. `ulimit -n 65536` (hard is 524288).
3. Stage large files on **`/home/user/...` or `/var/tmp`**, never `/tmp`.
4. Keep process RSS **< ~1.2 GiB** to leave kernel/cache headroom.
5. Install Python deps into a directory **not** named `.venv`/`.local` if they must survive snapshots; or reinstall at session start (pip is fast).
6. `sudo apt-get install -y ffmpeg cmake` is viable; skip docker unless you only need the CLI against a remote daemon.
7. Hugging Face: install `huggingface_hub` at runtime; expect CloudFront TTFB variance; no IPv6 fallback.
8. Long jobs: `start_process` / systemd, not a single `bash` call (1800 s cap).
9. Do not assume persistence of `/tmp`, `~/.cache`, or `~/.local`.

---

## Appendix A — Selected raw outputs

<details>
<summary>uname, os-release, libc</summary>

```
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
VERSION_ID="13"
DEBIAN_VERSION_FULL=13.6
ldd (Debian GLIBC 2.41-12+deb13u3) 2.41
```

</details>

<details>
<summary>Kernel cmdline</summary>

```
clocksource=kvm-clock i8042.noaux i8042.nokbd init=/sbin/init
ip=169.254.0.21::169.254.0.22:255.255.255.252:instance:eth0:off:tap0
ipv6.autoconf=1 ipv6.disable=0 loglevel=1 panic=1 pci=off quiet
random.trust_cpu=on reboot=k rootflags=discard pci=off
virtio_mmio.device=4K@0xc0001000:6 root=/dev/vda rw
virtio_mmio.device=4K@0xc0002000:7 virtio_mmio.device=4K@0xc0003000:8
virtio_mmio.device=4K@0xc0004000:9
```

</details>

<details>
<summary>curl -w large downloads</summary>

```
github jq-linux-amd64
  http_code=200 size=2319424 speed=18874138
  namelookup=0.003475 connect=0.004476 tls=0.040643 ttfb=0.060314 total=0.122889
  remote_ip=185.199.110.133

pypi pip-25.0 wheel
  http_code=200 size=1841506 speed=10713032
  namelookup=0.009318 connect=0.009566 tls=0.028870 ttfb=0.111664 total=0.171894
  remote_ip=151.101.0.223

cloudflare 50MB
  http_code=200 size=50000000 speed_Bps=83172256
  namelookup=0.039188 connect=0.039428 tls=0.108118 ttfb=0.167277 total=0.601162
  ip=162.159.140.220
```

</details>

<details>
<summary>df / meminfo (start of session)</summary>

```
/dev/root  ext4  25G  4.1G  20G  17% /
tmpfs      tmpfs 993M 8.0K 993M   1% /tmp

MemTotal:        2032608 kB
MemAvailable:    1525464 kB
SwapTotal:             0 kB
```

</details>

<details>
<summary>cgroup user memory/cpu</summary>

```
memory.max   = 1947172864
memory.high  = 1947172864
memory.peak  = 1636802560   # during 1.5 GiB alloc test
memory.events oom=0 oom_kill=0
cpu.max      = max 100000
cpu.weight   = 50
pids.max     = max
```

</details>

---

*End of report. Marker file: `/home/user/_envchar/session_marker.txt`.*
