# Environment Characterization Report

**Target:** Research/data-pipeline sandbox — Linux microVM (E2B infra)
**Probed:** 2026-09-04, ~11:15–11:24 UTC (VM boot 11:11:19 UTC, `uptime` 5–13 min during probes)
**Sandbox ID:** `idxwgcmp6a9ioo1823yuk` (env: `E2B_SANDBOX=true`, template `nlhz8vlwyupq845jsdg9`)
**Method:** All numbers below were measured live with the tools named in each row (wire-level DNS queries, socket-level connect timers, `curl -w` timing fields, `perf_counter` medians-of-3, `dd`/`os.write` with fsync). Raw probe transcripts: `/home/user/envprobe/*.txt` (see Appendix).

---

## Executive Summary

This is **not a container**: it is a full KVM-backed Linux microVM running systemd (Debian 13, kernel 6.1.158) in which the agent user has **passwordless sudo to unrestricted root** (all 40 capabilities, no seccomp), so apt, pip, npm, git, and native compilation all work out of the box. Compute is small but quick — 2 exposed vCPUs (Xeon @2.6 GHz, AVX-512, ~2× parallel scaling measured), ~1.94 GiB RAM with a 1.86 GiB cgroup cap and **no swap**, and SSD-backed ext4 delivering 0.5–2 GB/s. The network egress is a transparent, locally-proxied path (TCP "connect" appears as ~0.2 ms while real latency shows up at 25–90 ms TTFB) with excellent throughput to package/CDN endpoints (85–115 MiB/s Cloudflare; pypi 20–52 MiB/s) but per-connection caps elsewhere (~6–10 MiB/s GitHub/HuggingFace single-conn) and a handful of DNS-blocked domains. Persistence is limited to the `/home/user` subtree (~128 MiB / 10k-file snapshot budget, several excluded directory names), so system packages and `/usr/local` changes must be re-applied by a bootstrap script each session — but a data pipeline with ≤ ~1.2 GiB working set fits comfortably.

---

## 1. Runtime & Isolation

| Attribute | Measured value |
|---|---|
| OS | Debian GNU/Linux 13 (trixie), full `13.6` |
| Kernel | `6.1.158+` SMP PREEMPT_DYNAMIC x86_64 (custom build, dated 2026-07-17) |
| libc | glibc `2.41-12+deb13u3` |
| Hostname / clock | `e2b.local`; UTC; fresh `boot_id` per session |
| Virtualization | **KVM, full virtualization** (`systemd-detect-virt: kvm`, `hypervisor` flag, "Hypervisor vendor: KVM"). PID 1 = systemd `/sbin/init` |
| Container markers | None: no `/.dockerenv`, no `/run/.containerenv`; not Docker/Podman (binaries absent) |
| cgroups | v2, systemd-managed; our processes in slice `0::/user` (controllers: cpuset, cpu, io, memory, pids) |
| Physical host | Google Cloud **us-west1 (The Dalles, OR)**, egress IP `34.143.70.112`, AS396982 |
| Root services (own cgroups) | systemd, `envd` (E2B daemon), `jupyter-server` (:8888), `uvicorn` code-interpreter API (:49999), sshd, node kernel (ijskernel), rpcbind. `chronyd-restricted` + `nftables` units show *failed* (cosmetic) |

**Isolation summary (measured):** unprivileged `user` (uid/gid 1000, groups `sudo`,`users`) with `CapEff=0` and no seccomp; but `sudo -n` grants **root with full capability set `0x1ffffffffff` (all 40 caps), `Seccomp: 0`, `Seccomp_filters: 0`, `NoNewPrivs: 0`** — e.g. `echo 3 > /proc/sys/vm/drop_caches` succeeded as root. AppArmor attr read returned an unparsable "kernel\0" string (no confinement strings seen). Practical reading: the *VM boundary* is the sandbox; inside it, root is effectively unrestricted (subject to whatever the kernel/hypervisor denies; nested `/dev/kvm` is absent).

**Resource limits (measured):**

| Resource | Limit |
|---|---|
| CPUs exposed / allowed | 2 logical (`cpuset.cpus.effective: 0-1`); lscpu topology: 1 socket, 1 core, 2 threads |
| CPU quota | `cpu.max = max 100000` → **no quota**; no throttling events; stable 2.60 GHz |
| RAM | `MemTotal` 1,984 MiB (~1.94 GiB); **no swap**; idle `MemAvailable` ~1.41–1.55 GiB |
| cgroup memory | `memory.max = 1,947,172,864 B` (1,857 MiB) for our `/user` slice; `memory.high` same; events all 0 during probes |
| Processes | `ulimit -u` 7,917 (SigQ `0/7917`); cgroup `pids.max = max` |
| Open files | soft 1,024 → hard 524,288 (raisable) |
| Other ulimits | stack 8 MiB; core dumps 0; memlock 8 MiB; CPU time/virtual mem/file size unlimited |
| Kernel knobs | `pid_max` 4,194,304; `fs.file-max` = 2⁶³−1; `ip_forward=0` |

Environment variables carrying sandbox config: `E2B_SANDBOX=true`, `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, `E2B_EVENTS_ADDRESS=http://192.0.2.1` (internal endpoint; HTTP 404 in ~2.4 ms). No proxy env vars, no injected secrets found; `/var/run/secrets` absent; empty `~/.ssh`, `~/.aws`, `~/.config`.

---

## 2. Tooling & Language Runtimes

### Availability + versions (probe: `tool --version | head -1`, or first line of `-V`/`-version`)

| Tool | Status / version |
|---|---|
| python3 / python3.13 | **3.13.14** (custom build in `/usr/local`, GCC 14.2.0; dev headers at `/usr/local/include/python3.13`, `Python.h` present; standard GIL build `Py_GIL_DISABLED=0`) |
| pip / pip3 | 26.1.2 (bundled `ensurepip`); default index pypi.org, no overrides |
| node / npm / npx | v20.20.2 / 10.8.2 / 10.8.2 (registry.npmjs.org default) |
| git | 2.47.3 (local init/commit verified) |
| curl | 8.14.1 (HTTP/2 + HTTP/3 libs, OpenSSL 3.5.6) |
| wget | 1.25.0 |
| gcc / g++ / make | 14.2.0 (Debian) / 14.2.0 / GNU Make 4.4.1 — C compile+run verified |
| jq | 1.7 |
| openssl | 3.5.6 |
| R (Rscript) | 4.5.0 |
| perl | 5.40.1 |
| Java | `openjdk 11` (probe printed odd string `openjdk 11 2018-09-25`) |
| util binaries | tar, zip, unzip, xz, gzip, bzip2, pkg-config, sqlite3 (3.46.1 — I installed it via apt during probing), socat, iproute2, ping, vmstat, getent, ssh/scp, file, timeout, busybox, xxd-absent |
| autotools | autoconf 2.72, automake 1.17 |
| **Missing** | ffmpeg, docker/podman, clang, cmake, ninja, yarn/pnpm/bun/deno, go/rustc/cargo, dig/nslookup/host, tmux/screen/vim/nano/htop/strace, rsync, aria2c, zstd, redis-cli, julia, ruby, php, sqlite3(was) |

Missing-but-needed tools are mostly **apt-installable within a session** (verified: `ffmpeg` candidate `7:7.1.5-0+deb13u1`; `sqlite3` installed in 2.2 s).

### Package managers — do they actually work?

| Manager | Verdict (measured) |
|---|---|
| apt (Debian 13, dpkg backend) | **Works** via passwordless sudo. `apt-get update` 0.7–0.9 s (deb.debian.org + nodesource repos); `apt-get install sqlite3` 2.2 s. Only dpkg/apt present (no yum/dnf/apk/pacman/conda/brew) |
| pip | **Works with zero ceremony**: default target `/usr/local/lib/python3.13/site-packages` is **user-writable (mode 777)**. Verified: venv creation 2.1 s; wheel installs `rich` 1.41 s, `orjson` (Rust wheel) 0.67 s; `numpy 2.5.2` linux wheel downloaded 0.84 s + installed 2.33 s; **C-extension sdist compiled** (`markupsafe --no-binary :all:` w/ build isolation) 3.72 s; legacy `six` sdist 0.42 s; `pip install --user idna` 1.11 s |
| npm | **Works**: registry.npmjs.org reachable; `npm install express@4` completed (2.2 MiB tree in `/tmp/npmtest`) |
| Native compile | **Works**: gcc/g++ hello-world verified; Python C-extension toolchain complete (headers, `python3-config`) |
| docker | Not available and not installable-in-spirit (no daemon path; VM is not nested-container-ready — no `/dev/kvm`) |

**Notable:** CPython 3.13.14 here is unusually fast for a stock interpreter (see §5) — pure-Python loops run ~2.5× faster than typical CPython baselines, consistent with an optimized/JIT-enabled build. numpy's bundled BLAS runs multithreaded on both vCPUs (~136 GFLOPS on 2048² matmul).

---

## 3. Filesystem & Persistence

### Layout (from `/proc/mounts` + `df`)

| Path | FS | Size | Used/Avail | Notes |
|---|---|---|---|---|
| `/` (`/dev/root`, major:minor 254:0) | ext4, rw | 25 GiB | 4.1 GiB / **20 GiB free** (17%) | **plain ext4, no overlayfs** — the "disk" |
| `/tmp` | tmpfs | 993 MiB | ~11% at probe | RAM-backed scratch |
| `/dev/shm` | tmpfs | 993 MiB | ~0% | RAM-backed |
| `/run` | tmpfs | 397 MiB | 1% | — |
| `/etc/ssl/certs` | tmpfs | 397 MiB | — | template mount (certs) |
| `/run/credentials/*` | ramfs | — | — | only **read-only** mounts (3) |
| Inodes | — | 6.76 M free on `/` (3% used); `/tmp` 1,048,575 free | — | no inode pressure |

### Capability probes (all as uid 1000)

- Write → read → chmod → delete: **OK** in `/home/user`, `/tmp`, `/dev/shm`, `/var/tmp` (1 MiB random file each).
- Hardlink, symlink, `fallocate` 10 MiB: **OK**.
- `/etc`, `/usr`, `/var/log`, `/root`, `/boot`, `/proc/sys`: not writable by user (sudo available; `drop_caches` succeeded as root).
- Virtual disk is fast SSD-class storage (see §5): rotational flag reports `1` but 1.3–2.1 GB/s reads rule out a mechanical device; 8 dormant loop devices exist.

### Persistence (what survives)

- **Within a session:** everything survives across tool calls — markers written at 11:15 UTC in both `/home/user` and `/tmp` were still present at 11:23 UTC; the same VM instance runs the whole conversation.
- **Across sessions (documented platform contract, not directly testable here):** only the `/home/user` subtree is snapshotted, best-effort **~128 MiB / ~10,000 files**, excluding a fixed list of directory names — importantly `.cache`, `.local`, `.venv`, `node_modules`, `build`, `dist`, `out`, `target`, `__pycache__`, git credential files etc. Consequences measured/derived:
  - `pip install --user` lands in `/home/user/.local/...` → **excluded → will not persist**. Use a project-local venv under a *non-excluded* name (e.g. `/home/user/pyenv/proj`) or plain `pip install` (site-packages is user-writable).
  - System state (apt packages, `/usr/local`, services, kernel) and `/tmp`/`/dev/shm` content reset each session (template services restart; fresh boot_id; `uptime` in minutes at probe time). Encode setup as a bootstrap script and keep it in `/home/user`.
  - Watch the 128 MiB budget: model files/datasets belong in object storage or a data dir sized deliberately; the workspace was ~29 MiB after all probing (npm cache + a pip --user package).

---

## 4. Network Characterization

### Egress architecture (important!)

The path to the internet is **not** a direct public route. Measured evidence:

- TCP connect RTT is **0.12–0.32 ms to every endpoint**, including literal `8.8.8.8:443`, `github.com:22`, `huggingface.co:443` — physically impossible on a public path.
- DNS A-records are **rewritten into 0.0.0.0/8 space** and answered by a near-VM cache: `pypi.org → 0.4.151.101`, `www.hetzner.com → 0.4.213.133`, `speedtest.net → 0.4.151.101` (first octet zeroed from real 151.101.x/213.x ranges) — i.e. TCP goes to a local forwarder that terminates/relays it.
- Real internet latency appears at the TLS/TTFB stage: **~25–90 ms** depending on target (below).
- ICMP is answered locally too (0.4–0.6 ms); UDP 53 and UDP 123 get replies; UDP 443 (QUIC) does not.

**Operational consequence:** treat TCP-RTT numbers as meaningless; budget per-request latency at the TTFB values (~25–90 ms). HTTP/2 works; do not rely on HTTP/3/QUIC. IPv6 is **not routed** (immediate connection failure).

### DNS timing (raw UDP stub queries to `8.8.8.8`, 5 reps, median)

| Host | Median | Min–max |
|---|---|---|
| google.com | 2.3 ms | 1.1–18.8 ms |
| github.com | 9.0 ms | 1.1–19.7 ms |
| pypi.org | 0.7 ms | 0.5–0.8 ms (cached) |
| huggingface.co | 15.0 ms | 0.9–23.3 ms |
| files.pythonhosted.org | 1.4 ms | 1.1–10.2 ms |
| registry.npmjs.org | 0.7 ms | 0.6–0.8 ms |
| deb.debian.org | 1.1 ms | 1.1–1.3 ms |
| (NXDOMAIN sample) | 21.8 ms | 1.4–26.4 ms |

DNS **filtering exists**: `speed.hetzner.de` returns `NOERROR` with **0 answers (NODATA) on 3/3 probes** (and curl fails with "Could not resolve host"), while a nonexistent subdomain (`random123.hetzner.de`) correctly returns NXDOMAIN and `www.hetzner.com`/`download.hetzner.de` resolve fine — i.e. a targeted blocklist, not a resolver fault. Assume bandwidth-test domains may be blocked.

### Connectivity + protocol matrix (measured)

| Endpoint | Result | dns | conn | TLS | TTFB (real latency) | total |
|---|---|---|---|---|---|---|
| https://www.google.com/ | 200 | 1.7 ms | 2.1 ms | 11.8 ms | 47 ms | 48 ms |
| https://github.com/ | 200 | 1.5 ms | 1.7 ms | 17.9 ms | 25 ms | 63 ms |
| https://pypi.org/ | 200 | 1.2 ms | 1.4 ms | 20.4 ms | 29 ms | 31 ms |
| https://huggingface.co/ | 200 | 22.3 ms | 22.7 ms | 42.1 ms | 52 ms | 69 ms |
| https://registry.npmjs.org/ | 200 | 2.8 ms | 3.1 ms | 64.3 ms | 90 ms | 90 ms |
| https://deb.debian.org/ | 200 | 1.9 ms | 2.2 ms | 24.2 ms | 37 ms | 37 ms |

(2 runs each; table shows run 2. run-1 TTFBs: 28–49 ms range for the same set. Plain HTTP :80 works — google 301, deb.debian.org 200.)

| Protocol test | Result |
|---|---|
| TCP 443 / 80 / 22 / 53 outbound | All reachable (7/7 connects, 0.12–0.32 ms) |
| SSH egress | Full handshake to `github.com:22` (ED25519 banner; `Permission denied (publickey)` = expected) |
| ICMP echo to 8.8.8.8 | 3/3, 0.41–0.62 ms |
| UDP 53 to 8.8.8.8 / 1.1.1.1 | Replies (61 B, ~18–21 ms) |
| UDP 123 NTP | Reply in 0.7 ms (locally answered) |
| UDP 443 (QUIC probe) | No reply in 1.2 s → treat QUIC/HTTP3 as unavailable |
| IPv6 | No route (curl fails in ~3 ms) |

### Throughput (real transfers, `curl -w`, MiB = 2²⁰ B)

| Source (size) | Rate | Notes |
|---|---|---|
| speed.cloudflare.com 50 MiB (3 runs) | **84.9 / 103.0 / 106.4 MiB/s** | run-of-session first hit once measured 18.4 MiB/s (warmup anomaly) |
| speed.cloudflare.com upload 20 MiB | 15.6 MiB/s | asymmetric: upload ≈ 7× slower than download |
| files.pythonhosted.org (numpy wheel, 16.1 MiB) | 52.0 MiB/s | TTFB 40 ms |
| pip download numpy 2.5.2 (16.7 MiB, 0.84 s) | ≈19.9 MiB/s | incl. metadata round-trips |
| huggingface.co `gpt2/pytorch_model.bin`, 5 MiB range, 1 conn | **9.96 MiB/s** | TTFB 255 ms (includes 302 redirect + X-Linked token) |
| huggingface.co, 4 × 5 MiB parallel ranges | 21.8 MiB/s | 20 MiB in 0.92 s → **parallelism helps ~2.2×** |
| codeload.github.com (git tarball, 10.9 MiB) | **5.9 MiB/s** | per-connection cap territory |
| proof.ovh.net (EU), 100 MiB | 14.5 MiB/s | TTFB 860 ms |
| apt-get update | 0.7–0.9 s | ~2 MB of index metadata |
| git clone (shallow, tiny repo) | 0.70 s | — |
| npm install express (tree) | completed | 2.2 MiB tree |

**Reading:** per-connection speed caps of roughly **5–15 MiB/s at several CDNs** (GitHub/HF/OVH-class) vs 85–115 MiB/s Cloudflare-class. For large HuggingFace/model pulls, parallelize (ranges or files) — measured ~22 MiB/s at 4 connections. Egress location is Google us-west1 (The Dalles), consistent with 25–50 ms real latencies to US/EU services. GCS same-cloud path I tried 404'd (inconclusive; not counted).

---

## 5. Performance Micro-benchmarks

### CPU / compute (python 3.13.14 in `/usr/local`; medians of 3, `time.perf_counter`)

| Benchmark | Result | Method/context |
|---|---|---|
| `sum(range(10**7))` | **140.6 ms** (~71 M iterations/s) | pure CPython — ~2.5× faster than typical stock 3.11–3.13 builds |
| int loop 3 × 10⁶ (mod+add) | 341 ms | pure CPython |
| `json.dumps` ×200k | 481–539 ms | small dict; warm spread across runs |
| `orjson.dumps` ×200k | 36.2 ms | Rust wheel — 13× faster than stdlib json |
| numpy `arange(1e7,f64).sum()` | 47.5 ms | incl. allocation |
| numpy 2048² matmul (warm) | 125.9 ms/op | ≈ **136 GFLOPS**, BLAS multithreaded on both vCPUs |
| 4 × `sum(range(10**7))` in parallel | 0.33 s wall vs 0.68 s serial | ≈ **2.05× scaling** on the 2 exposed vCPUs |

Treat the box as ~2 effective compute units (topology says 1 core × 2 SMT threads, but wall-clock scaling behaved near-2× for independent CPython processes). Single-threaded Python performance is a highlight; GIL is enabled (no free-threading).

### Memory ceiling (deliberate pressure test)

- Allocated + touched **1,024 MiB in one process: succeeded**, no OOM; `memory.events`: `oom 0`, `oom_kill 0`; survived with `MemAvailable` dropping to ~490 MiB.
- Hard ceiling: cgroup `memory.max` 1,857 MiB; host total 1,984 MiB **with no swap**; root services (jupyter/envd/code-interpreter) live in other cgroups and consume ~250–400 MiB host-wide.
- **Practical guidance: keep pipeline RSS ≤ ~1.2 GiB** to avoid host-wide OOM risk.

### Disk (100 MiB file unless noted)

| Operation | Rate | Method |
|---|---|---|
| Buffered sequential write + fsync | 1,467 MiB/s write (fsync +78 ms; 100 MiB total incl. fsync in 0.15 s) | python `os.write`-style 1 MiB blocks |
| O_DIRECT write + fdatasync | 482 MiB/s | `dd oflag=direct conv=fdatasync` |
| Warm read | 3,991 MiB/s | page-cache hit |
| **Cold read** | **1,318 MiB/s** | after `sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'` |
| O_DIRECT read | 2.09 GB/s (1.99 GiB/s) | `dd iflag=direct` |
| tmpfs `/tmp` (RAM) | 2,395 MiB/s write, 4,629 MiB/s read | incl. fsync on write |
| tmpfs `/dev/shm` (RAM) | 3,318 / 5,591 MiB/s | incl. fsync |
| 20k small-file create / delete | 151,420 / 476,802 files/s | ext4, `/tmp` |

Disk is emphatically **not a bottleneck**: even cold reads are ~1.3 GB/s and fsynced writes ~0.5–1.5 GB/s; 20 GiB free.

### Install timings (wall clock)

venv creation 2.1 s · rich wheel 1.4 s · orjson wheel 0.7 s · numpy wheel dl 0.8 s + install 2.3 s · markupsafe **C-ext sdist (full compile)** 3.7 s · six sdist 0.4 s · `pip --user` idna 1.1 s · apt-get update 0.7–0.9 s · apt install sqlite3 2.2 s.

---

## 6. Other Observations

- **Nothing hung**: every probe completed within its timeout; the only non-responses were intentional/expected (IPv6, UDP 443 QUIC, DNS-blocked domain, HF/GCS dead paths). No captive portal, no TLS interception issues (all certs valid, TLS 1.3-capable handshakes in 12–64 ms).
- **Background / long-running work — two verified mechanisms:**
  1. Detached processes (`setsid … &`) **survive across tool-call boundaries**: a ticker writing every 5 s ran 60+ s across several calls (13 ticks, span 11:22:05→11:23:05 UTC, alive at final check).
  2. A supervised process runner started a `python3 -m http.server` on 0.0.0.0:8800 that served HTTP 200 in 1.1 ms and stayed managed (PID 2738, ppid 1). This is the supported pattern for servers/long jobs — bind to **0.0.0.0**; external access comes through the platform preview/proxy, so services should expect proxied host/origin headers.
- **Memory-pressure behavior:** no swap anywhere; cgroup limits protect our slice only — host-wide oversubscription of the 1.94 GiB could OOM-kill *any* slice (including template services). Observed all-zero OOM counters; no kills during testing.
- **Quirks worth knowing:** `LANG`/`LC_ALL` unset (POSIX locale) — set `LC_ALL=C.UTF-8` explicitly for text pipelines; timezone UTC; `/usr/local/bin/python3.13` binaries are mode 777 and `site-packages` is world-writable (template quirk — convenient for pip, slightly unusual security posture); `/proc/sys` values are not user-readable (`sysctl -n` silent) but are as root; `java --version` prints an odd string; R 4.5 and perl present but no ruby/php; `dig`/`nslookup` absent (raw-socket DNS scripts work fine); jupyter-server :8888 and the code-interpreter API :49999 belong to the template — leave them running.
- **Environment summary:** no GPU (`/dev/dri`, `/dev/nvidia*` absent), no `/dev/kvm` (no nested virtualization), no seccomp/AppArmor confinement detected at our level, no module visibility (`lsmod` empty), host clock stable, load average ~0.0–0.4 idle, ~140 threads system-wide.

---

## Bottom line — Fast / Slow / Hard limits

**Fast ✅**
- Single-threaded CPython (custom 3.13 build) and multithreaded numpy BLAS (~136 GFLOPS)
- Disk: 0.5–2 GB/s with fsync; RAM-backed `/tmp` at multi-GB/s
- Package ecosystem: apt/pip/npm installs complete in seconds; pypi/npm/apt metadata near-instantly; Cloudflare-class downloads 85–115 MiB/s
- Environment bootstrap: passwordless sudo, working compilers + Python headers, venv 2 s

**Slow ⚠️**
- HuggingFace/GitHub-CDN single-connection pulls: ~6–10 MiB/s (parallelize: 4× conns → ~22 MiB/s HF)
- EU CDNs ~14.5 MiB/s; upload ~15.6 MiB/s; first-request warmup dips to ~18 MiB/s
- Real per-request latency 25–90 ms (despite 0.2 ms local TCP connects) — concurrency, not pipelining, wins

**Hard limitations 🔒**
- RAM: ~1.86 GiB cgroup cap, 1.94 GiB host, **no swap** → keep working sets ≤ ~1.2 GiB
- 2 vCPUs total (≈2× scaling max); GIL build; no GPU; no nested KVM; no IPv6; no QUIC/HTTP3
- DNS blocklist on some domains (observed: `speed.hetzner.de`); assume bandwidth-test endpoints unreliable
- Persistence = `/home/user` only: ~128 MiB / 10k-file snapshot budget; excluded names (`.local`, `.cache`, `.venv`, `node_modules`, …) don't persist; apt/system/`/usr/local` state resets every session → **write a bootstrap script**
- No docker/podman (KVM microVM, not container host); ffmpeg/clang etc. only via apt within-session
- Python parallelism across processes only (GIL); free-threaded build unavailable

---

## Appendix — raw notes & evidence

Every probe was written verbatim to `/home/user/envprobe/NN_*.txt` during the run (total ~46 KB, kept as evidence):

| File | Contents |
|---|---|
| `01_runtime.txt` | uname, os-release, glibc, container markers, full `/proc/mounts`, cgroup v2, IPv6, boot_id |
| `02_identity.txt` | id, sudo test, `/proc/self/status` caps/seccomp, ulimit -a, RLIMITs, cgroup files, env (redacted) |
| `03_tools.txt` | full 70-tool availability/version probe matrix |
| `04_fs.txt` | df/inodes, RO mounts, write/read/delete probes, fs types, persistence markers |
| `05_cpu_mem.txt` | CPU benchmarks (medians), parallel probe, 1 GiB memory ceiling test, memory.events |
| `06_compilers_pkgs.txt` | gcc run, Python.h, apt update timing, sqlite3 install demo |
| `07_cgroup_sudo.txt` | delegated cgroup tree, per-slice limits, symlinks, ss listeners, uptime |
| `09_net_matrix.txt` | DNS timings, TCP RTT matrix, UDP/ICMP/IPv6 probes, curl connectivity matrix |
| `10_net_throughput.txt` / `10b_net_throughput2.txt` | CDN download rates, upload, ipinfo, ssh handshake, git clone, npm test |
| `11_disk.txt` | disk backend, buffered/O_DIRECT/cold/tmpfs benchmarks, inode ops |
| `12_pip.txt` / `12b_pip2.txt` | venv, wheel + sdist installs, numpy/orison bench, DNS blocklist follow-up |
| `13_bg_misc.txt` | numpy pip run, orjson-vs-json, bg ticker spawn, GPU/devices, git demo |
| `14_final.txt` | ticker survival check, persistence markers, session state, inventory |
| `15_process_demo.txt` | supervised-process server check (HTTP 200), ticker final count |
| `bg_ticks.txt` | timestamp stream of the detached background ticker |

<details>
<summary>Representative raw output: cgroup + rlimits (02/07)</summary>

```
Uid:    1000    1000    1000    1000
CapEff: 0000000000000000   (as uid 1000)
CapBnd: 000001ffffffffff   (all 40 caps when root via sudo)
Seccomp: 0   Seccomp_filters: 0   NoNewPrivs: 0
-- sudo -> root: uid=0  CapEff: 000001ffffffffff
/sys/fs/cgroup/user/memory.max : 1947172864
/sys/fs/cgroup/user/memory.current : ~337 MiB (idle, incl. page cache)
/sys/fs/cgroup/user/cpu.max    : max 100000
/sys/fs/cgroup/user/pids.max   : max
ulimit: -u 7917 | -n soft 1024 hard 524288 | stack 8192 KB | core 0
```
</details>

<details>
<summary>Representative raw output: network evidence (09)</summary>

```
TCP connect RTT medians (7 reps):  8.8.8.8:443 0.21ms | github.com:443 0.16ms
                                    pypi.org:443 0.17ms | huggingface.co:443 0.17ms
ICMP 8.8.8.8: rtt min/avg/max/mdev = 0.406/0.529/0.617/0.089 ms
DNS rewritten answers: pypi.org -> 0.4.151.101 ; www.hetzner.com -> 0.4.213.133
speed.hetzner.de: rcode=0 answers=0 (NODATA) x3 ; random123.hetzner.de: rcode=3 (NXDOMAIN)
IPv6: curl: (7) Failed to connect ... after 3 ms
```
</details>

<details>
<summary>Representative raw output: disk numbers (11)</summary>

```
write 100MiB buffered+fsync : 1467 MiB/s (fsync +78ms)
dd O_DIRECT write           : 482 MB/s
read warm                   : 3991 MiB/s
read COLD (drop_caches)     : 1318 MiB/s
dd O_DIRECT read            : 2.1 GB/s
/tmp tmpfs                  : write 2395 MiB/s / read 4629 MiB/s
/dev/shm tmpfs              : write 3318 MiB/s / read 5591 MiB/s
20k files                   : create 151,420/s  delete 476,802/s
```
</details>
