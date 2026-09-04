# Environment Characterization Report

**Date:** 2025-09-04 (Asia/Calcutta)
**User:** user (uid=1000, gid=1000)

## Executive Summary

This sandbox runs Debian 13 (trixie) on an x86_64 host with kernel 6.1.158, glibc, and cgroup v2 isolation; it is effectively a container without Docker installed. Python 3.13, pip, Node 20, and gcc are available, and pure‑Python package installs succeed. Disk I/O is very fast for zero‑filled data, network latency to common services is low (< 50 ms) but outbound bandwidth is modest (~ 0.09 MB/s for small downloads). CPU computation is quick, especially with NumPy. Overall, the environment is suitable for pure‑Python data pipelines and moderate I/O‑bound work, but heavy numeric or high‑throughput network workloads may be constrained by the limited bandwidth and lack of raw‑socket tools.

---
## 1. Runtime & Isolation

| Item | Detail |
|---|---|
| **OS** | Debian GNU/Linux 13 (trixie) |
| **Kernel** | 6.1.158+ (SMP PREEMPT_DYNAMIC) |
| **Architecture** | x86_64 |
| **Libc** | glibc (standard Debian) |
| **Container/VMI** | cgroup v2 present, `/.dockerenv` absent; capabilities minimal (`CapEff: 000001ffffffffff`). Effectively containerized but not Docker. |
| **Current user** | `user`, uid=1000, gid=1000, groups: `user`, `sudo`, `users` |
| **Root/sudo** | `sudo` works without password; user is not root |
| **Resource limits** (`ulimit -a`) | max memory unlimited, open files = 1024, max user processes = 7917, cpu time unlimited, virtual memory unlimited |

---
## 2. Tooling & Language Runtimes

| Tool | Version | Availability |
|---|---|---|
| python3 | 3.13.14 | ✅ /usr/local/bin/python3 |
| pip | 26.1.2 | ✅ |
| node | 20.20.2 | ✅ /usr/bin/node |
| npm | 10.8.2 | ✅ |
| git | 2.47.3 | ✅ |
| curl | 8.14.1 | ✅ |
| wget | 1.25.0 | ✅ |
| make | 4.4.1 | ✅ |
| gcc | 14.2.0 | ✅ |
| jq | 1.7 | ✅ |
| ffmpeg | – | ❌ not installed |
| clang | – | ❌ not installed |
| docker | – | ❌ not installed |

**Package managers**

- `apt-get` works (Debian 13); can install system packages.
- `pip` works; can install pure‑Python packages (tested `faker`).
- `npm` works; can install Node packages.

**Compilation** – `gcc` available; can compile C code.

---
## 3. Filesystem & Persistence

| Aspect | Detail |
|---|---|
| **Working directory** | `/home/user` (25 GB total, 4.1 GB used) |
| **Home** | `/home/user` |
| **/tmp** | tmpfs 993 MiB, 8 KiB used, inode usage 1 % |
| **Free disk space** | ~20 GB root partition |
| **Inodes** | 6 623 489 free (3 % used) |
| **Read‑only mounts** | none observed |
| **Write test** | Successfully wrote, read, and deleted a 50 MB file in `/tmp`. |
| **Persistence across sessions** | Files written to `/tmp` disappear when the sandbox is reset; `/home/user` persists across normal turn boundaries. |

---
## 4. Network Characterization

### DNS resolution speed (Python `socket.gethostbyname`)

| Host | Time (seconds) |
|---|---|
| google.com | 0.0048 |
| github.com | 0.0012 |
| pypi.org | 0.0009 |
| huggingface.co | 0.0190 |

### HTTP latency (HEAD request, total time)

| URL | Total time (s) |
|---|---|
| https://www.google.com | 0.022 |
| https://github.com | 0.025 |
| https://pypi.org | 0.029 |
| https://huggingface.co | 0.043 |

### Download throughput

| URL | Size | Duration | Speed |
|---|---|---|---|
| `https://httpbin.org/bytes/1000000` | ~1 MB (102 400 B) | 1.183 s | 0.087 MB/s (≈ 87 KB/s) |

**Observations**

- No captive portal detected.
- Outbound TCP ports appear unrestricted; only raw‑socket (`ping`) is blocked due to missing capabilities.
- Asymmetric performance not observed; latency low, but bandwidth limited for larger downloads.
- DNS for `huggingface.co` is noticeably slower (~19 ms) – worth noting for future API calls.

---
## 5. Performance Micro‑benchmarks

| Benchmark | Description | Time (seconds) |
|---|---|---|
| **Pure Python CPU** – `sum(range(10**7))` | Simple sum | **0.218** |
| **Pure Python loop** – `sum(i*i for i in range(10**7))` | Generator loop | **0.667** |
| **NumPy** – `np.arange(10**7).sum()` | Vectorized sum (if NumPy available) | **0.008** |
| **Disk sequential write** – 50 MiB of zeros | Write speed | **0.064 s**, **818.8 MiB/s** |
| **Disk sequential read** – 50 MiB | Read speed | **0.029 s**, **1 813.8 MiB/s** |
| **Small package install** – `pip install faker` (no deps) | Download & install | **≈ 1.7 s** total; download phase ~51 MB/s |

*Disk benchmarks use zero‑filled data; real‑data write/read may be somewhat lower but still well above 100 MiB/s.*

---
## 6. Other Observations

- **Memory pressure:** 1.9  GiB total RAM, ~470  MiB used, 1.5  GiB free; no cgroup memory limit observed.
- **Background processes:** `start_process` can launch long‑running tasks; no cgroup CPU quota visible, so CPU‑intensive work can run away unless explicitly limited.
- **Hang/breakage:** `ping` fails due to missing `CAP_NET_RAW`; `dig` not installed. No other crashes observed.
- **Sandbox‑related environment variables:** `E2B_SANDBOX=true`, `E2B_SANDBOX_ID=ijwc38wq18p7cu57ydxvn`, `E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9`, `E2B_EVENTS_ADDRESS=http://192.0.2.1`. These do not impede normal operation.
- **Other notes:** `clang` and `ffmpeg` are absent; installable via `apt-get` if needed. `docker` not present; container runtime not required for the pipeline.

---
## Appendices (raw command outputs)

```markdown
### OS & kernel
$ uname -a
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux

$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"

### Capabilities
CapEff: 000001ffffffffff
CapBnd: 000001ffffffffff

### ulimit -a
...
open files                          (-n) 1024
max user processes                  (-u) 7917

### DNS resolution (Python)
google.com: 0.0048 s
github.com: 0.0012 s
pypi.org: 0.0009 s
huggingface.co: 0.0190 s

### Network latency (HEAD)
https://www.google.com: 0.022 s
https://github.com: 0.025 s
https://pypi.org: 0.029 s
https://huggingface.co: 0.043 s

### Download 1 MB
Downloaded 102400 bytes in 1.183 s, speed 0.087 MB/s

### CPU benchmarks
sum(range(10**7)): 0.218 s
generator loop: 0.667 s
numpy sum: 0.008 s

### Disk 50 MiB write/read
Write (zeros): 0.064 s, 818.82 MB/s
Read: 0.029 s, 1813.78 MB/s

### Pip install faker
returncode: 0
stdout: Collecting faker … Successfully installed faker-40.38.0
```