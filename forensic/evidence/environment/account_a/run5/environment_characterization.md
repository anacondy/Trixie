# Environment Characterization Report

**Target:** E2B sandbox `iyl5sbten1irtm0cfue4p` (template `nlhz8vlwyupq845jsdg9`)
**Date of measurement:** 2026-09-04, 11:10–11:41 UTC
**Measured by:** direct in-sandbox instrumentation (no vendor documentation used)

> ### ⚠️ SUPERSEDED IN PART — read `env-probe/ERRATA.md` first
>
> A second, scripted run (`env-probe` v1.1.1, 2026-09-04 13:46–13:51 UTC, sandbox
> `i80n46q8w7lm0xch991wu`) **falsified two conclusions below** and answered one open question:
>
> 1. **§4.5 "ICMP is completely blocked" is WRONG.** ICMP works via `sudo` (github.com
>    11.25 ms). The cause is local: `ping` lacks setuid *and* `net.ipv4.ping_group_range`
>    = `1 0` (empty). Fixable with one sysctl.
> 2. **§4.5 "npm audit black-holed (420 s)" is TRANSIENT, not structural.** Run 2 measured
>    the same endpoint at **HTTP 200 in 0.057 s** and `npm install` (default flags) at
>    **0.986 s** — a 427× swing. The run-1 measurement was real but reflected upstream
>    congestion, not a platform block.
> 3. **Persistence (§3.4) is RESOLVED:** `/home/user` **does** survive across sessions and
>    across sandbox IDs; `/tmp` does not; file mtimes are rewritten on restore.
>
> Raw verbatim transcripts, the probe script, and SHA-256 manifests are in
> `/home/user/env-probe/`. Everything else in this report was independently reproduced.

---

## Executive Summary

This is a **Firecracker/KVM microVM running Debian 13 (trixie)** with **2 vCPU, 1.94 GiB RAM, and 25 GB of ext4 disk (~20 GB free)** — not a Docker container. You have **passwordless root via sudo**, an unrestricted capability bounding set, and **no seccomp filtering**, so apt, compilation, and privileged operations all work normally. **Disk and network are exceptionally fast** (945 MB/s–2.9 GB/s writes, ~100–120 MB/s sustained downloads, ~8–14 ms real RTT to major endpoints) because the VM sits inside Google Cloud behind a local egress proxy.

The binding constraint for your pipeline is **memory, not CPU or I/O**: the OOM killer terminates processes at roughly **1.6 GB RSS**, there is **zero swap**, and `/tmp` is a RAM-backed tmpfs that competes with that same 2 GB budget. Two other hard gotchas: **ICMP is blocked entirely** (no `cap_net_raw`), and **npm's audit endpoints hang for 420+ seconds**, which silently poisons every default `npm install` — always pass `--no-audit --no-fund`.

---

## 1. Runtime & Isolation

### 1.1 Operating System

| Property | Value |
|---|---|
| Distribution | Debian GNU/Linux 13 (trixie), `DEBIAN_VERSION_FULL=13.6` |
| Kernel | `6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026` |
| Architecture | `x86_64` / `amd64` |
| libc | GNU libc (Debian GLIBC) **2.41-12+deb13u3** |
| Hostname | `e2b.local` |
| Init | `systemd` (PID 1 = `/sbin/init`) |
| Timezone | UTC (host clock; your local tz is Asia/Calcutta) |

The kernel is a custom build (`gcc (Ubuntu 13.3.0)`, built by `root@runnervm3jd5f`), not a Debian stock kernel.

### 1.2 Virtualization: microVM, not a container

Evidence collected:

| Signal | Result | Interpretation |
|---|---|---|
| `systemd-detect-virt` | `kvm` | Hardware virtualization |
| `/.dockerenv` | **absent** | Not Docker |
| `/run/.containerenv` | **absent** | Not Podman |
| `/proc/1/cgroup` | `0::/init.scope` | Own cgroup root — not a container namespace |
| `lscpu` hypervisor | `KVM`, full virtualization | — |
| DMI | `DMI not present or invalid` | Firecracker signature |
| Kernel cmdline | `pci=off virtio_mmio.device=4K@0xc0001000:6 …`, `reboot=k`, `i8042.noaux` | **Classic Firecracker boot args** |
| Root device | `/dev/vda` (virtio-blk), ext4 | — |
| `dmesg` | `Hypervisor detected: KVM`, `kvm-clock` | — |
| Uptime at first probe | **0 minutes** | VM was cold-booted for this session |

**Conclusion:** a Firecracker microVM. This matters because you get a real kernel — you can load modules, use `iptables`-class functionality, mount filesystems, and run privileged workloads that a container would deny.

### 1.3 Identity & Privileges

```
uid=1000(user) gid=1000(user) groups=1000(user),27(sudo),100(users)
```

| Check | Result |
|---|---|
| Default user | `user` (uid 1000), home `/home/user` |
| `sudo -n true` | **Succeeds — passwordless root** |
| `sudo id` | `uid=0(root)` confirmed |
| `CapEff` (as user) | `0000000000000000` (none) |
| `CapBnd` (bounding set) | `000001ffffffffff` — **full, nothing dropped** |
| `Seccomp` | `0` (**disabled — no syscall filtering**) |
| SELinux | `selinuxfs` mounted, not enforcing |

The empty effective-capability set is normal for an unprivileged user; the **full bounding set** is the important signal — nothing is stripped, so `sudo` grants genuine, complete root.

### 1.4 Resource Limits

| Resource | Value | Notes |
|---|---|---|
| vCPU | **2** | Intel Xeon @ 2.60 GHz, family 6 model 106 (Ice Lake-SP) |
| CPU flags | AVX-512 (f/dq/cd/bw/vl/vnni/vbmi/bitalg), AES-NI, SHA-NI, BMI2 | Good for numeric work |
| Caches | L1d 48 KiB, L1i 32 KiB, L2 1.3 MiB, L3 **54 MiB** | L3 is host-shared |
| RAM | **1,984 MiB total** (`MemTotal: 2032608 kB`) | |
| Swap | **0 — none configured** | No overflow safety net |
| Disk | 25 GB ext4, 4.4 GB used, **~20 GB available** | |
| Inodes | 6,759,792 total, 136,292 used (**3%**) | Not a constraint |
| `ulimit -n` (open files) | **1024** | ⚠️ Low — raise for high-concurrency I/O |
| `ulimit -u` (processes) | 7,917 | |
| `ulimit -s` (stack) | 8,192 KiB | |
| `ulimit -c` (core dumps) | 0 | Disabled |
| `ulimit -l` (locked mem) | 8,192 KiB | |
| `threads-max` | 15,835 | |
| `pid_max` | 4,194,304 | |
| cgroup v2 limits | **none set** (`memory.max`, `cpu.max` all absent) | Limits are the VM's, not a cgroup's |

**Key point:** there is no cgroup memory limit — the ceiling is simply the VM's physical 2 GB, enforced by the kernel OOM killer.

---

## 2. Tooling & Language Runtimes

### 2.1 Availability & Versions

| Tool | Available | Version | Path |
|---|---|---|---|
| python3 | ✅ | **3.13.14** (GCC 14.2.0) | `/usr/local/bin/python3` |
| pip | ✅ | **26.1.2** | `/usr/local/bin/pip` |
| node | ✅ | **v20.20.2** | `/usr/bin/node` |
| npm | ✅ | **10.8.2** | `/usr/bin/npm` |
| npx | ✅ | 10.8.2 | `/usr/bin/npx` |
| git | ✅ | **2.47.3** | `/usr/bin/git` |
| curl | ✅ | **8.14.1** (OpenSSL 3.5.6, nghttp2/nghttp3, brotli, zstd) | `/usr/bin/curl` |
| wget | ✅ | 1.25.0 | `/usr/bin/wget` |
| gcc | ✅ | **14.2.0** (Debian 14.2.0-19) | `/usr/bin/gcc` |
| g++ | ✅ | 14.2.0 | `/usr/bin/g++` |
| make | ✅ | GNU Make 4.4.1 | `/usr/bin/make` |
| cmake | ⚠️ | **3.31.6** — installed by me via apt | `/usr/bin/cmake` |
| jq | ✅ | jq-1.7 | `/usr/bin/jq` |
| openssl | ✅ | 3.5.6 (7 Apr 2026) | `/usr/bin/openssl` |
| java | ✅ | present | `/usr/bin/java` |
| perl | ✅ | present | `/usr/bin/perl` |
| tar / zip / unzip | ✅ | GNU tar 1.35 | — |
| ssh | ✅ | OpenSSH | `/usr/bin/ssh` |
| ip / ss | ✅ | iproute2 | — |
| ping | ⚠️ | present but **non-functional** (see §4.4) | `/usr/bin/ping` |
| apt / apt-get / dpkg | ✅ | dpkg 1.22.22 | — |
| sqlite3 | ⚠️ | **3.46.1** — installed by me via apt | `/usr/bin/sqlite3` |
| **ffmpeg** | ❌ | not installed (apt-installable) | — |
| **docker / podman** | ❌ | **not available — no container runtime** | — |
| **rustc / cargo** | ❌ | not installed | — |
| **go** | ❌ | not installed | — |
| **clang** | ❌ | not installed (gcc available) | — |
| **uv / poetry / pipx / conda** | ❌ | not installed | — |
| **yarn / pnpm / bun / deno** | ❌ | not installed | — |
| **nc / dig / nslookup / traceroute** | ❌ | **absent — hampers network debugging** | — |
| **iptables** | ❌ | binary absent (kernel supports it) | — |
| **rsync** | ❌ | not installed | — |
| **bc** | ❌ | absent (bit me during timing scripts) | — |
| **/usr/bin/time** | ❌ | absent — use bash `time` builtin + `TIMEFORMAT` | — |
| **htop / tmux / screen / vim / nano** | ❌ | no editors or multiplexers preinstalled | — |
| apk / yum / dnf / snap / brew | ❌ | wrong distro / not present | — |

### 2.2 Preinstalled Python Stack

**180 distributions** preinstalled. This is a data-science-oriented image:

| Present | Version | | Present | Version |
|---|---|---|---|---|
| numpy | 2.3.5 | | scikit-learn | 1.6.1 |
| pandas | 2.2.3 | | scikit-image | 0.25.2 |
| scipy | 1.17.1 | | opencv-python | 4.11.0.86 |
| matplotlib | 3.10.9 | | pillow | 12.3.0 |
| seaborn | 0.13.2 | | spacy | 3.8.14 |
| plotly | 6.0.1 | | nltk | 3.10.0 |
| bokeh | 3.9.1 | | gensim | 4.4.0 |
| requests | 2.33.0 | | librosa | 0.11.0 |
| httpx | 0.28.1 | | numba | 0.66.0 |
| aiohttp | 3.14.1 | | sympy | 1.14.0 |
| beautifulsoup4 | 4.15.0 | | networkx | 3.6.1 |
| lxml | 6.1.1 | | xarray | 2025.4.0 |
| pydantic | 2.13.4 | | openpyxl / xlrd | 3.1.5 / 2.0.2 |
| jupyter_server | 2.20.0 | | python-docx | 1.1.2 |
| ipykernel | 6.31.0 | | pytest | 9.0.3 |

**Notably absent:** `torch`, `transformers`, `datasets`, `pyarrow`, `polars`, `duckdb`, `statsmodels`, `python-pptx`, `reportlab`. (I installed and then removed duckdb/polars during testing — both install cleanly in ~1.4 s.)

**BLAS:** OpenBLAS with **2 pthreads**, `OMP_NUM_THREADS` unset.

### 2.3 Can You Actually Install Things?

**Yes — all three tiers work.** Verified with real installs:

| Install type | Command tested | Result | Time |
|---|---|---|---|
| Pure-Python wheel | `pip install --no-cache-dir tabulate` | ✅ v0.10.0 | **0.78 s** |
| Binary wheel (~20 MB) | `pip install --no-cache-dir duckdb` | ✅ v1.5.5 | **1.42 s** |
| Binary wheel (~35 MB) | `pip install --no-cache-dir polars` | ✅ v1.44.1 | **1.34 s** |
| **C source build** | `pip install --no-binary :all: ujson` | ✅ v6.0.0 **compiled from sdist** | **7.30 s** |
| `pip download` numpy | resolve + fetch | ✅ | 0.88 s |
| **System package (apt)** | `apt-get install cmake` | ✅ v3.31.6 | **3.48 s** |
| apt reinstall | `apt-get install --reinstall jq` | ✅ | 1.95 s |
| `apt-get update` | full index refresh | ✅ | **0.80 s** |
| **npm (small)** | `npm install --no-audit --no-fund lodash` | ✅ v4.18.1 | **0.65 s** |
| **npm (tree)** | `npm install --no-audit --no-fund express` | ✅ v5.2.1, cold cache | **3.95 s** |
| ⚠️ **npm (default flags)** | `npm install express` | ✅ but **421 s** | see §4.5 |

Python C-extension headers are present (`/usr/local/include/python3.13/Python.h`), so building C extensions works out of the box.

**Compilation verified:**

| Test | Result | Time |
|---|---|---|
| `gcc -O2 -fopenmp hello.c` | ✅ compiles | **0.045 s** |
| OpenMP runtime (1e8 iterations, reduction) | ✅ `threads=2` | **0.087 s** |
| `g++ -O2 -std=c++17` (vector + sort) | ✅ | **0.411 s** |

**OpenMP works and correctly sees 2 threads.**

---

## 3. Filesystem & Persistence

### 3.1 Layout

| Path | Filesystem | Size | Backing | Persistent? |
|---|---|---|---|---|
| `/` , `/home/user` | ext4 on `/dev/vda` | 25 G (20 G free) | **virtio disk** | ✅ Yes |
| `/tmp` | **tmpfs** | 993 M | ⚠️ **RAM** | ❌ No |
| `/dev/shm` | tmpfs | 993 M | RAM | ❌ No |
| `/run` | tmpfs | 397 M | RAM | ❌ No |
| `/run/lock` | tmpfs | 5 M | RAM | ❌ No |
| `/dev` | devtmpfs | 990 M | RAM | ❌ No |

> ⚠️ **`/tmp` is RAM-backed, not disk.** Every byte written to `/tmp` or `/dev/shm` consumes your 2 GB memory budget. Writing a 1 GB intermediate file to `/tmp` will push you into the OOM zone. **For a data pipeline, use `/home/user/tmp` instead of `/tmp` for scratch space.**

### 3.2 Write / Read / Delete Test

| Location | Write | Read | Delete |
|---|---|---|---|
| `/home/user` | ✅ | ✅ | ✅ |
| `/tmp` | ✅ | ✅ | ✅ |
| `/dev/shm` | ✅ | ✅ | ✅ |
| `/var/tmp` | ✅ | ✅ | ✅ |
| `/usr/local` | ✅ | ✅ | ✅ |
| `/opt` | ❌ Permission denied | — | — |
| `/etc` | ❌ Permission denied | — | — |
| `/root` | ❌ Permission denied | — | — |
| `/` | ❌ Permission denied | — | — |

All denials are ordinary **Unix permissions as uid 1000, not read-only mounts** — `sudo` writes anywhere. The only genuinely read-only mounts are three `ramfs` systemd credential mounts under `/run/credentials/*` (irrelevant to workloads).

### 3.3 Disk Headroom

Wrote a **2 GiB** file to `/home/user` at **945 MB/s**; disk went 4.4 G → 6.4 G used and returned cleanly on delete. The full ~20 GB is genuinely usable.

### 3.4 Persistence — **RESOLVED (run 2)**

Run 2 answered this definitively by reading the markers back under a *different* sandbox ID:

| Signal | Run 1 | Run 2 | Meaning |
|---|---|---|---|
| Sandbox ID | `iyl5sbten1irtm0cfue4p` | **`i80n46q8w7lm0xch991wu`** | Genuinely different sandbox |
| Uptime at first probe | 17.6 s | **11.7 s** | Fresh boot, not a resume |
| `/home/user/PERSISTENCE_MARKER.txt` | written 11:40:29Z | ✅ **read back intact** | **Home persists** |
| `/tmp/PERSISTENCE_MARKER_TMP.txt` | written 11:40:29Z | ❌ **absent** | tmpfs cleared |
| `environment_characterization.md` | written 11:41Z | ✅ present, 33,576 B | Survives |
| File mtimes | 11:11–11:41 | **all rewritten to 13:43** | Restored from snapshot |

**Answer: `/home/user` persists across sessions and across sandbox IDs. `/tmp` does not.**

The uniform 13:43 mtime on every run-1 artifact shows home is **restored from a snapshot into a fresh VM** rather than the VM being resumed. ⚠️ **Original write times are not preserved — do not rely on mtime for pipeline bookkeeping.**

⚠️ **`boot_id` is not unique.** `2bb79165-136a-4b63-829d-17027b0a8e40` was byte-identical across both sandboxes and both boots (consistent with `KASLR disabled` + `random.trust_cpu=on` in the kernel cmdline). Use `run_utc` + `sandbox_id` as run identifiers instead.

**Recommendation:** home persisting is convenient, but still checkpoint pipeline state externally — persistence across *sandbox teardown* (as opposed to session change) has not been tested.

---

## 4. Network Characterization

### 4.1 Configuration

| Property | Value |
|---|---|
| Interface | `eth0` @ `169.254.0.21/30` (link-local) |
| Gateway | `169.254.0.22` |
| DNS resolver | `8.8.8.8` (single nameserver, `/etc/resolv.conf`) |
| **Public egress IP** | **`34.169.124.137`** (Google Cloud, us-west1) — ⚠️ **not stable**, run 2 measured `34.127.25.150` |
| IPv6 | ❌ **Not functional** (`curl -6` → code 000) |
| Proxy env vars | none set |
| TLS interception | ❌ **None** — `pypi.org` presents its genuine GlobalSign Atlas R3 cert, `Verify return code: 0 (ok)` |
| Protocols negotiated | **HTTP/2**, **TLS 1.3** (`TLS_AES_128_GCM_SHA256`) |

The `/30` link-local address with a NAT gateway confirms a **transparent egress proxy**, which has measurement consequences (§4.4).

### 4.2 DNS Resolution Speed

3 lookups per host via `socket.gethostbyname`:

| Host | Resolved IP | Cold | Warm |
|---|---|---:|---:|
| google.com | 142.251.188.113 | 11.40 ms | **0.84 ms** |
| github.com | 140.82.116.3 | 1.39 ms | 1.50 ms |
| pypi.org | 151.101.128.223 | 0.80 ms | 0.87 ms |
| huggingface.co | 3.165.160.61 | 30.73 ms | 1.29 ms |
| files.pythonhosted.org | 151.101.64.223 | 8.72 ms | 1.41 ms |
| objects.githubusercontent.com | 185.199.108.133 | 1.25 ms | 1.17 ms |
| cdn.jsdelivr.net | 104.17.208.5 | 10.36 ms | 1.47 ms |
| registry.npmjs.org | 104.16.1.34 | 19.60 ms | 1.22 ms |
| deb.debian.org | 151.101.194.132 | 1.44 ms | 1.28 ms |

**DNS is excellent** — cold 0.8–31 ms, warm consistently **~1.2 ms** (locally cached). Not a bottleneck; no need to build a resolver cache into your pipeline.

### 4.3 Latency (curl, best-of-5)

| Endpoint | DNS | TCP connect | TLS done | TTFB | Total | **Est. real RTT** |
|---|---:|---:|---:|---:|---:|---:|
| google.com/generate_204 | 1.2 ms | 1.5 ms | 12.7 ms | 13.6 ms | 13.6 ms | **~7.7 ms** |
| github.com | 1.5 ms | 1.7 ms | 21.2 ms | 30.0 ms | 67.5 ms | **~13.0 ms** |
| pypi.org/simple/ | 1.0 ms | 1.3 ms | 20.8 ms | 30.3 ms | 188.9 ms | **~13.5 ms** |
| huggingface.co | 1.3 ms | 1.6 ms | 19.5 ms | 28.8 ms | 43.2 ms | **~10.0 ms** |
| registry.npmjs.org | 1.1 ms | 1.4 ms | 59.5 ms | 82.8 ms | 82.9 ms | **~33.9 ms** |
| cdn.jsdelivr.net | 1.5 ms | 1.8 ms | 44.7 ms | 68.2 ms | 68.4 ms | **~21.5 ms** |
| deb.debian.org | 1.5 ms | 1.9 ms | 22.5 ms | 31.1 ms | 46.5 ms | — |
| files.pythonhosted.org | 1.8 ms | 2.1 ms | 22.6 ms | 30.7 ms | 30.9 ms | — |

**Methodology note — an important trap.** `time_connect` is **1.3–2.1 ms to every host on Earth**, which is physically impossible. The local proxy terminates TCP immediately, so `time_connect` measures the distance to the gateway, not the origin. The **TLS handshake is end-to-end**, so I estimate true RTT as `(time_appconnect − time_connect) / 2` (TLS 1.3 = 1 RTT). Those estimates are in the last column and are consistent with a GCP us-west1 origin.

**Takeaway:** real network latency is **~8–34 ms** to major endpoints — very good. Never use TCP connect time to measure latency here.

### 4.4 Throughput

| Target | Size | Time | **Throughput** |
|---|---:|---:|---:|
| Cloudflare speedtest | 10 MB | 0.301 s | **33.2 MB/s** |
| Cloudflare speedtest | 10 MB | 0.339 s | 29.5 MB/s |
| **Cloudflare speedtest** | **50 MB** | **0.437 s** | **🔥 114.4 MB/s** |
| Cloudflare speedtest | 50 MB | 0.451 s | **110.8 MB/s** |
| Cloudflare speedtest | 100 MB | — | ❌ HTTP 403 (endpoint caps at 50 MB) |
| **PyPI wheel** (numpy 2.5.2) | 16.7 MB | 0.146 s | **🔥 109.5 MB/s** |
| PyPI wheel (repeat) | 16.7 MB | 0.160 s | 99.7 MB/s |
| **GitHub release** (git-lfs tar.gz) | 4.97 MB | 0.151 s | **31.4 MB/s** |
| GitHub release (repeat) | 4.97 MB | 0.371 s | 12.8 MB/s |
| **HuggingFace** (bert-tiny `pytorch_model.bin`) | 17.8 MB | 1.133 s | **14.9 MB/s** |
| HuggingFace (`vocab.txt`) | 232 KB | 0.156 s | 1.4 MB/s (latency-dominated) |
| **git clone** `pallets/flask` --depth 1 | 3.3 MB | **0.698 s** | — |
| **git clone** `numpy/numpy` --depth 1 | 52 MB | **1.725 s** | ~30 MB/s |

**Asymmetry observed:** PyPI/Cloudflare reach **~110 MB/s**; **HuggingFace tops out at ~15 MB/s** — roughly **7× slower**. Budget HF model pulls accordingly (a 5 GB model ≈ 5–6 minutes). Small files are latency-bound, not bandwidth-bound — **parallelize small downloads**, don't serialize them.

### 4.5 Blocks, Restrictions & Anomalies

#### ⚠️ ICMP fails for the unprivileged user — but is NOT blocked *(corrected in run 2)*
```
$ ping -c 3 8.8.8.8                    # as uid 1000
ping: socket: Operation not permitted
ping: => missing cap_net_raw+p capability or setuid?

$ sudo ping -c 4 github.com            # WORKS
rtt min/avg/max/mdev = 11.161/11.250/11.308/0.064 ms
```
Run 1 tested only as uid 1000 and wrongly concluded the network blocks ICMP. Two **local** causes: `/usr/bin/ping` has no setuid bit (mode `0755`), and `net.ipv4.ping_group_range` is `1  0` — an empty range, disabling unprivileged ICMP sockets for every gid.

**Fix:** `sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"`

These real RTTs also **corroborate the TLS-delta estimates** in §4.3: github.com measures 11.25 ms by ICMP vs the 13.04 ms estimate. Still note that `traceroute`/`dig`/`nc` are absent, so debugging tooling remains thin.

#### ⚠️ Port scanning gives false positives
A naive TCP-connect scan reported **every** port open, including `google.com:3389` (RDP) and `google.com:8080` — services Google does not run. The proxy accepts optimistically. Validating with real protocol handshakes:

| Target | TCP connect | Data actually flows? | Evidence |
|---|---|---|---|
| github.com:22 | 1.1 ms "open" | ✅ **Yes** | `SSH-2.0-cb4a187` |
| smtp.gmail.com:25 | 2.6 ms "open" | ✅ **Yes** | `220 smtp.gmail.com ESMTP` |
| smtp.gmail.com:587 | 2.3 ms "open" | ✅ **Yes** | `220 smtp.gmail.com ESMTP` |
| irc.libera.chat:6667 | 21.8 ms "open" | ✅ **Yes** | `:silver.libera.chat NOTICE *` |
| google.com:80 | 3.1 ms "open" | ✅ **Yes** | `HTTP/1.0 301 Moved Permanently` |
| google.com:3389 | 1.6 ms "open" | ❌ **No** — 8 s timeout | proxy false positive |
| google.com:8080 | 2.7 ms "open" | ❌ **No** — 8 s timeout | proxy false positive |

**Always verify egress with a real handshake, never a bare `connect()`.**

#### ✅ Outbound egress is genuinely unrestricted
Tested against `portquiz.net`, which listens on **all** ports — every one returned **HTTP 200**:

| Port | 80 | 443 | 22 | 25 | 587 | 8080 | 3389 | 9418 | 1234 | 31337 | 65000 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Result | 200 | 200 | 200 | 200 | 200 | 200 | 200 | 200 | 200 | 200 | 200 |

**No port-based egress filtering, including SMTP/25 and high ports.** UDP works too — DNS queries to `8.8.8.8` (0.8 ms), `1.1.1.1` (18.2 ms), and `9.9.9.9` (6.8 ms) all returned valid responses. SSH to GitHub reaches auth (`Permission denied (publickey)` — expected without a key).

#### 🟡 npm audit hung for 420 seconds — but this did NOT reproduce *(corrected in run 2)*

Run 1's measurements were real: `npm install express` took **421.098 s wall / 1.315 s CPU**, and `npm audit` alone **420.658 s wall / 0.55 s CPU**. The POST to `registry.npmjs.org/-/npm/v1/security/advisories/bulk` completed TLS in 0.062 s then returned zero bytes until the 90 s timeout.

**Run 2, same probes, same template, ~2 hours later — the hang was gone:**

| Operation | Run 1 | **Run 2** |
|---|---:|---:|
| `POST …/advisories/bulk` | ⏱ timeout at 90 s | ✅ **200 in 0.057 s** (stable over 4 attempts) |
| `npm audit` (CLI) | 420.658 s | ✅ **0.433 s** |
| `npm install express` (**default flags**) | 421.098 s | ✅ **0.986 s** |
| `npm install --no-audit --no-fund` | 3.945 s | 0.986 s |

**Corrected conclusion:** this was **transient upstream congestion or rate-limiting at registry.npmjs.org**, not an egress-proxy block. It is *not* a hard limitation of this environment.

> **Guidance is unchanged, but the reason differs:** still set `--no-audit --no-fund` in automation — not because the endpoint is blocked, but because it is a network dependency with **unbounded tail latency and no default timeout**. A 7-minute stall in CI is worth defending against even at 1-in-N frequency.

#### ✅ POST is NOT blocked generally
I verified this is npm-specific, not a blanket write-method block:

| Request | Result |
|---|---|
| `POST httpbin.org/post` | ✅ 200, TTFB 0.326 s |
| `POST postman-echo.com/post` | ✅ 200, 0.180 s |
| `POST httpbingo.org/post` | ✅ 200, 0.188 s |
| `PUT httpbingo.org/put` | ✅ 200, 0.206 s |
| `POST api.github.com/graphql` (no auth) | ✅ 403 — *correct* auth rejection, request delivered |

**REST/GraphQL API pipelines will work fine.** No captive portal, no MITM, no method filtering.

---

## 5. Performance Micro-benchmarks

All timings via `time.perf_counter()`, **best-of-3** unless noted.

### 5.1 Pure Python CPU

| Benchmark | Best | Median |
|---|---:|---:|
| `sum(range(10**7))` | **183.3 ms** | 185.5 ms |
| `sum(range(10**7))` (2nd run, loaded) | 201.4 ms | 204.6 ms |
| Interpreted loop `x += i*i`, 10⁷ iters | **669.0 ms** | 699.6 ms |
| `fib(27)` recursive | 25.2 ms | 25.2 ms |
| `json.dumps` 50k dicts | 42.8 ms | 42.9 ms |
| `json.loads` 50k dicts | 48.2 ms | 49.2 ms |
| `hashlib.sha256` of 10 MiB | **8.5 ms** (≈1.18 GB/s) | 8.5 ms |
| `re.findall` over 1 M chars | 44.4 ms | 44.7 ms |

Single-core Python is **mid-range** — roughly what a 2.6 GHz Ice Lake core delivers. SHA-256 is hardware-accelerated (SHA-NI) and very fast.

### 5.2 NumPy / Pandas (OpenBLAS, 2 threads)

| Benchmark | Best | Median |
|---|---:|---:|
| numpy 1000×1000 matmul (float64) | **17.7 ms** (≈113 GFLOP/s) | 19.8 ms |
| numpy 2000×2000 matmul (float64) | **128.0 ms** (≈125 GFLOP/s) | 143.3 ms |
| numpy sum, 10⁷ float64 | 8.3 ms | 8.3 ms |
| numpy sort, 10⁷ float64 | 140.9 ms | 149.2 ms |
| numpy FFT, 2²² points | 233.2 ms | 244.4 ms |
| pandas groupby.mean, 10⁶ rows | **31.5 ms** | 31.7 ms |
| pandas sort_values, 10⁶ rows | 88.6 ms | 88.6 ms |
| **pandas `to_csv`, 10⁶ rows** | ⚠️ **1834.7 ms** | — |
| pandas `read_csv`, 10⁶ rows | 182.4 ms | 183.8 ms |

**~125 GFLOP/s** on 2 cores is excellent — AVX-512 is being used. **`to_csv` is 10× slower than `read_csv`** and is CPU-bound in pandas' formatter, not disk-bound (disk does 945 MB/s). **Use Parquet or Feather for intermediates** instead of CSV.

### 5.3 Parallel Scaling (2 vCPU)

| Workers | Wall time | Aggregate throughput |
|---|---:|---:|
| 1 process × 8 M iters | 0.63 s | 12.66 M-iter/s |
| **2 processes** × 8 M iters | **0.58 s** | **27.45 M-iter/s** |
| 4 processes × 8 M iters | 1.29 s | 24.81 M-iter/s |

**Near-perfect 2.17× scaling at 2 workers; oversubscribing to 4 gives no gain and adds overhead.** The 2 "cores" are 2 SMT threads on 1 physical core (`Thread(s) per core: 2`, `Core(s) per socket: 1`), yet still scale well. **Set pool size to exactly 2.**

### 5.4 Disk I/O

| Location | Sequential write (`conv=fdatasync`) | Read (cold) | Read (warm) |
|---|---:|---:|---:|
| **`/home/user`** (ext4, virtio) | **501 MB/s** | 1.4 GB/s | 4.6 GB/s |
| `/home/user` 2 GiB write | **945 MB/s** | — | — |
| `/home/user` O_DIRECT 100 MiB | **754 MB/s** | — | — |
| `/tmp` (tmpfs/RAM) | 2.9 GB/s | 5.5 GB/s | 4.2 GB/s |
| `/dev/shm` (tmpfs/RAM) | 3.1 GB/s | 5.2 GB/s | 4.6 GB/s |

| Metadata / random op | Result |
|---|---|
| 4 KiB random reads | **458,050 IOPS** (1789 MiB/s) — page-cache assisted; treat as upper bound |
| Create 5,000 small files | 0.379 s → **13,204 files/s** |
| Delete 5,000 files | 0.075 s |

**Disk is not a bottleneck for anything you're likely to do.** Note tmpfs "speed" is just RAM and costs you memory.

### 5.5 Sustained CPU — No Throttling

Six consecutive 10-second CPU-burn windows:

| Window | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---:|---:|---:|---:|---:|---:|
| Work units | 4401 | 4975 | 5065 | 4982 | 5029 | 4617 |

**Drift first→last: +4.9%** (window 1 is low due to warm-up). **No thermal or cgroup throttling over 60 s of full load.** Variance ~±5% is normal noisy-neighbor jitter on shared cloud hardware.

---

## 6. Other Observations

### 6.1 Memory Pressure & OOM Behavior — the Real Limit

Allocated and **touched** (not just reserved) increasing buffers in subprocesses:

| Requested | Outcome |
|---|---|
| 256 MB | ✅ allocated + touched |
| 512 MB | ✅ allocated + touched |
| 1024 MB | ✅ allocated + touched |
| **1500 MB** | ✅ allocated + touched — **highest success** |
| **1800 MB** | 🔴 **SIGKILL (rc=-9) — OOM killer** |
| 2500 MB | ❌ `MemoryError` (allocation refused) |
| 4000 MB | ❌ `MemoryError` |

Kernel log confirms:
```
oom-kill:constraint=CONSTRAINT_NONE,...,task=python3,pid=2687,uid=1000
Out of memory: Killed process 2687 (python3) total-vm:1855896kB, anon-rss:1615480kB
```

| Setting | Value |
|---|---|
| `vm.overcommit_memory` | `0` (heuristic) |
| `vm.overcommit_ratio` | `50` |
| Swap | **none** |

**Practical ceiling: ~1.5 GB RSS for a single process; ~1.6 GB is where the OOM killer fires.**

> ⚠️ **This is your hard limit.** With no swap, exceeding it means **instant SIGKILL with no warning and no traceback** — your pipeline just dies. Combined with RAM-backed `/tmp`, a 1 GB scratch file plus a 1 GB dataframe will kill you. **Stream and chunk everything; never load a full dataset into memory.**

### 6.2 Background & Long-Running Processes

| Capability | Result |
|---|---|
| `nohup` detached background job | ✅ **Works** — survived parent shell exit, 4 ticks logged in 4 s |
| Long-lived HTTP server (`python3 -m http.server 8000 --bind 0.0.0.0`) | ✅ **Works** — bound successfully |
| Reachable at `http://localhost:8000` | ✅ HTTP 200 in **1.4 ms** |
| Public proxy `https://8000-<sandbox-id>.e2b.app` | ⚠️ **HTTP 403** when called *from inside* the sandbox |
| Max processes | 7,917 |
| Max threads | 15,835 |

The 403 on the public URL is a loopback artifact of hitting the platform proxy from within the sandbox itself; externally-originated browser requests are the supported path. Servers must **bind `0.0.0.0`**, not `127.0.0.1`.

### 6.3 Injected / Sandbox-Related Configuration

Environment variables:
```
E2B_SANDBOX=true
E2B_SANDBOX_ID=iyl5sbten1irtm0cfue4p
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
E2B_EVENTS_ADDRESS=http://192.0.2.1
HOME=/home/user   USER=user   SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

`/etc/hosts` maps `192.0.2.1 → events.e2b.local` (192.0.2.0/24 is TEST-NET-1, a documentation range — telemetry sink).

**Pre-existing platform services** (via `systemctl`):

| Service | Purpose |
|---|---|
| `code-interpreter.service` | Code Interpreter Server |
| `jupyter.service` | Jupyter Server — listening on **127.0.0.1:8888** |
| `envd.service` | E2B env daemon |
| `ssh.service` | OpenSSH |
| `rpcbind` / `nfs-blkmap` | RPC portmap on **0.0.0.0:111**, pNFS mapper |

Several ephemeral ports (34675, 35105, 35769, 39379, 41435, 43501, 44461, 47945) are bound by Jupyter kernels on `127.0.0.1` and `169.254.0.21`.

> ⚠️ `rpcbind` listens on **0.0.0.0:111** — unnecessary attack surface. Also, an unusual mount is present: `sunrpc on /run/rpc_pipefs`. Neither should affect you, but avoid binding your own services to port 111 or 8888 (Jupyter).

Notably, `/etc/ssl/certs` is a **tmpfs mount** — CA certificates are injected at boot rather than baked into the image. Custom CAs added there **will not survive a reboot**.

### 6.4 Things That Broke or Surprised Me

| Surprise | Detail |
|---|---|
| 🔴 `npm audit` hangs 420 s | Silently makes default `npm install` unusable (§4.5) |
| 🔴 OOM at ~1.6 GB with no swap | Silent SIGKILL, no traceback |
| ⚠️ `/tmp` is RAM, not disk | Scratch files eat the memory budget |
| ⚠️ `ping` broken for unprivileged user | Breaks naive health checks |
| ⚠️ Port scans all false-positive | Proxy optimistic-accept |
| ⚠️ `pandas.to_csv` 10× slower than `read_csv` | 1.83 s per 10⁶ rows, CPU-bound |
| ⚠️ HuggingFace 7× slower than PyPI | 15 MB/s vs 110 MB/s |
| ⚠️ `ulimit -n` = 1024 | Low for concurrent I/O |
| ⚠️ IPv6 non-functional | v6-only endpoints unreachable |
| ⚠️ `/etc/ssl/certs` on tmpfs | Custom CAs lost on reboot |
| 😐 `bc`, `/usr/bin/time` absent | Broke my first two timing scripts |
| 😐 No `dig`/`nc`/`traceroute`/editors | Thin debugging toolkit |
| ✅ No TLS interception | Genuine certs; pinning works |
| ✅ Full capability set, no seccomp | More permissive than a typical container |

---

## 7. Verdict: Fast, Slow, and Hard Limits

### 🟢 Fast — exploit these
- **Disk I/O:** 501–945 MB/s writes, 1.4 GB/s cold reads, 13k files/s. Never a bottleneck.
- **Bulk downloads from PyPI/Cloudflare:** ~110 MB/s.
- **DNS:** ~1.2 ms warm.
- **Package installs:** pip wheels 0.8–1.4 s; `apt-get update` 0.80 s; apt install 3.5 s.
- **Compilation:** gcc 45 ms; full C-extension source builds 7.3 s.
- **NumPy/BLAS:** ~125 GFLOP/s on 2 threads, AVX-512 active.
- **git clone:** 52 MB numpy repo in 1.7 s.
- **CPU stability:** no throttling under sustained load.

### 🟡 Slow — plan around these
- **HuggingFace downloads:** ~15 MB/s, **7× slower** than PyPI. A 5 GB model ≈ 5–6 min.
- **`pandas.to_csv`:** 1.83 s/10⁶ rows. Use Parquet/Feather.
- **Pure-Python loops:** 669 ms for 10⁷ iterations — vectorize or use numba (installed).
- **Source builds:** 7.3 s for a small C extension; a large package could take minutes on 2 cores.
- **Small-file downloads:** latency-bound (~30 ms each) — parallelize.

### 🔴 Hard limitations — cannot be worked around
1. **~1.6 GB RAM ceiling, zero swap.** Silent SIGKILL. **The single most important constraint.**
2. **2 vCPU (1 physical core + SMT).** No gain past 2 workers.
3. **No Docker/Podman.** No containerized steps, no `docker-compose`, no DinD.
4. ~~**ICMP blocked** for the default user.~~ → **CORRECTED:** ICMP works via `sudo`; unprivileged `ping` is fixable with `sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"`. Not a limitation.
5. **No IPv6.**
6. **`/tmp` and `/dev/shm` are RAM** — 993 MB each, billed against your 2 GB.
7. **~20 GB disk.** Fine for most work, not for multi-model corpora.
8. ~~**npm audit endpoints black-holed.**~~ → **CORRECTED:** transient upstream latency, not a platform block (run 2: 0.057 s). Still use `--no-audit --no-fund` defensively against unbounded tail latency.
9. **Session-scoped VM, but `/home/user` DOES persist** across sessions and sandbox IDs (restored from snapshot; **mtimes are rewritten**).
10. **NEW — egress IP is not stable.** `34.169.124.137` (run 1) → `34.127.25.150` (run 2). **IP allowlisting upstream will break.**
11. **NEW — `boot_id` is not unique** across sandboxes. Unusable as a run identifier.

### ✅ Recommended Configuration for Your Pipeline

```bash
# 1. Kill the 420-second npm trap (~106x speedup)
npm config set audit false && npm config set fund false

# 2. Scratch space on DISK, not RAM-backed /tmp
mkdir -p /home/user/tmp
export TMPDIR=/home/user/tmp

# 3. Raise the low file-descriptor limit
ulimit -n 65536

# 4. Match parallelism to actual core count — do not oversubscribe
export OMP_NUM_THREADS=2 MKL_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2
#    multiprocessing.Pool(2)

# 5. Memory discipline (hard ceiling ~1.6 GB RSS, NO SWAP)
#    - stream/chunk all datasets; never load full frames
#    - Parquet/Feather for intermediates, NOT CSV (to_csv is 10x slower)
#    - guard rail: resource.setrlimit(RLIMIT_AS, 1_400_000_000)
#      -> converts a silent SIGKILL into a catchable MemoryError

# 6. Checkpoint to external storage — assume the VM is ephemeral
# 7. Health checks: use TCP/HTTP probes, never `ping`
```

---

## Appendix A: Measurement Methodology

- **Timing:** `time.perf_counter()` in Python (monotonic, ns resolution); bash `time` builtin with `TIMEFORMAT='%3R s real | %3U user | %3S sys'`. `/usr/bin/time` and `bc` are **not installed** — the first timing attempts silently produced empty values and were re-run.
- **CPU benchmarks:** best-of-3 reported alongside median to expose noisy-neighbor jitter.
- **Network latency:** `curl` write-out variables, best-of-5. True RTT estimated as `(time_appconnect − time_connect)/2`, since the local proxy makes `time_connect` meaningless (§4.3).
- **Throughput:** 2+ samples per target using `%{speed_download}`; real artifacts (numpy wheel, git-lfs release, HF model) preferred over synthetic endpoints where possible.
- **Port reachability:** validated with **real protocol handshakes** (SSH/SMTP/IRC/HTTP banners), plus `portquiz.net` which listens on all ports — bare `connect()` results were discarded as unreliable.
- **Memory limits:** subprocess allocation with **page touching** (`b[i]=1` every 4096 bytes) to defeat lazy overcommit; exit codes inspected for SIGKILL and cross-checked against `dmesg` OOM records.
- **Disk:** `dd` with `conv=fdatasync` (forces flush) and `oflag=direct` (bypasses page cache); caches dropped via `/proc/sys/vm/drop_caches` between cold/warm reads.
- **Caveat:** the 458k IOPS 4 KiB random-read figure used a sparse/truncated file and is page-cache-assisted — treat it as an upper bound, not a device measurement.

## Appendix B: Reproduction Artifacts

### Probe kit (run 2 onward) — `/home/user/env-probe/`

| Path | Contents |
|---|---|
| `env_probe.sh` | **The probe script.** 16 sections, verbatim transcripts, manifest + checksums. `QUICK=1` / `FULL=1` modes. |
| `bench_cpu.py` | CPU/numpy/pandas/scaling benchmarks (invoked by section 11) |
| `diff_runs.sh` | Compares two runs: integrity, host identity, per-section diff |
| `README.md` | Usage, section index, methodology notes, known side effects |
| `ERRATA.md` | **Corrections to this report** — read alongside it |
| `runs/20260904T134652Z_i80n46q8w7lm0xch991wu/` | Run 2a (probe v1.1.0) — 16 `.txt` + `MANIFEST.json` + `SHA256SUMS.txt` |
| `runs/20260904T134940Z_i80n46q8w7lm0xch991wu/` | Run 2b (probe v1.1.1) — 16 `.txt` + `MANIFEST.json` + `SHA256SUMS.txt` |

Reproduce and compare:
```bash
cd /home/user/env-probe
./env_probe.sh                          # ~2.5 min
./diff_runs.sh                          # diff vs previous run
cd runs/<run_id> && sha256sum -c SHA256SUMS.txt
```

> **Evidence provenance.** The numbers in *this* report (run 1) came from ad-hoc commands
> whose verbatim output was never written to disk — it exists only in the originating
> conversation transcript. Only run 2 onward has archived raw evidence. Where run 1 and
> run 2 disagree, **run 2 is authoritative** because it is reproducible and checksummed.

### Run-1 scratch artifacts — `/home/user/envcheck/`

| Path | Contents |
|---|---|
| `cpubench.py` | Original ad-hoc benchmark script (superseded by `env-probe/bench_cpu.py`) |
| `hello.c`, `t.cpp` | OpenMP / C++17 compile tests |
| `pypkgs_tail.txt` | Tail of the 180 preinstalled Python distributions |
| `/home/user/PERSISTENCE_MARKER.txt` | Cross-session persistence probe (now answered — see §3.4) |

Test artifacts removed after measurement: `/tmp/gc`, `/tmp/gc2`, `/tmp/nt*`, `/tmp/na`, `/tmp/nb`, `/tmp/pd`, `/home/user/_big.bin`, `/home/user/_rand.bin`, `/home/user/_manyfiles/`.

**Packages installed during testing (image is no longer pristine):** `cmake` 3.31.6 and `sqlite3` 3.46.1 via apt (left in place); `tabulate`, `duckdb`, `polars`, `ujson` via pip (installed and uninstalled by each probe run).
