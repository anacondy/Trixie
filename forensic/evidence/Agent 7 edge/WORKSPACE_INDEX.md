# WORKSPACE INDEX — "Agent 7 edge" deliverable

**Generated:** 2026-09-04T14:26:14Z (inside the sandbox that produced all artefacts)

This index explains the archive end to end: what it contains, what every file does, when every file was created (exact UTC, in sequence), the exact prompts that drove each phase, and the environment metadata needed to interpret the measurements.

---

## 1. What the zip contains

```
Agent 7 edge.zip
├── environment_characterization.md        # main report (the summarisation layer)
├── WORKSPACE_INDEX.md                     # THIS file (inside + outside the zip)
├── ZIP_CONTENTS_MANIFEST.txt              # sha256 + size of every entry in the zip
├── Agent 7 edge.zip.sha256                # sidecar sha256 of the zip (outside the zip)
└── envcheck/
    ├── probe_environment.sh               # reproducible probe (live v2)
    ├── README.md                          # runner's guide
    ├── diskbench.sh                       # scratch script behind the disk benchmark
    ├── notes/                             # 26 verbatim transcripts of run #1 + heartbeat.log + nohup_result.txt
    └── raw/
        ├── run_20260904T1116Z_original/   # run #1: published byte-copies (26 txt) + backfilled MANIFEST.txt/.sha256 + nohup_result.txt
        └── run_20260904T141747Z/          # run #2 (canonical): 17 section transcripts + MANIFEST.txt/.sha256 + archived exact probe script
```

**81 files** are tracked in the creation sequence (section 3) — every file produced during this engagement, nothing else (system caches `.npm`/`.cache` etc. excluded, `_file_times.txt` collection scratch excluded). The zip adds this index plus `ZIP_CONTENTS_MANIFEST.txt`: **83 files / 88 zip entries** in total.

---

## 2. The exact prompts (verbatim) and when they arrived

| # | Prompt (verbatim) | Received ≈ | Work log |
|---|---|---|---|
| P1 | See block below | 2026-09-04T11:15Z (first recorded action 11:16:10Z) | run #1 probes 11:16:10–11:22:56Z; report written ~11:23Z |
| P2 | See block below | between 11:22:56Z and 14:17:47Z (not logged; inferred from work log) | probe script written ~14:16Z; canonical probe run 14:17:47–14:18:44Z; raw copies + manifests 14:2xZ |
| P3 | See block below | 2026-09-04T14:24Z (first recorded action 14:24:27Z) | this archive: index + zip 14:2xZ |

### P1 (verbatim) - received ≈2026-09-04T11:15Z
> I'm setting up a long-running research + data pipeline that will involve mixed CPU work, network I/O, package installs, and some file processing. Before I commit any real code or data, I need a clear picture of what this environment can actually sustain.
>
> Please treat this as serious environment characterization work. Do the following thoroughly and keep notes as you go (you can use temporary files or just track things in memory, but be systematic).
>
> Required checks
>
> 1. Runtime & Isolation
> - Exact OS, kernel version, architecture, libc
> - Clear signals of containerization / VM / restricted sandbox (cgroup, /.dockerenv, mount info, process tree, capabilities, seccomp, etc.)
> - Current user, uid/gid, sudo/root status
> - Any obvious resource limits (ulimit, cgroup memory/cpu, process limits)
>
> 2. Tooling & Language Runtimes
> - Availability + versions of: python3, pip, node, npm, git, curl, wget, ffmpeg, docker, make, gcc/clang, jq, etc.
> - Which package managers work (apt, apk, yum, pip, conda, npm...) and whether they can actually install things
> - Can you install pure-python packages? System packages? Compile anything?
>
> 3. Filesystem & Persistence
> - Working directory, home, /tmp behavior
> - Free disk space and inode situation
> - Read-only mounts or protected paths
> - Simple write + read + delete test in a few locations
> - Whether files survive across "sessions" if possible to test
>
> 4. Network Characterization (important)
> Run real measurements, not just "can I connect":
> - DNS resolution speed
> - Latency + rough throughput to several endpoints (at minimum):
>   - google.com / 8.8.8.8
>   - github.com
>   - pypi.org
>   - huggingface.co
>   - A large file download (e.g. a few MB from a reliable CDN or GitHub release)
> - Note any timeouts, blocks, captive portals, or asymmetric performance
> - Outbound ports / protocols that appear restricted
>
> 5. Performance Micro-benchmarks
> Keep them short but timed accurately:
> - Pure Python CPU: sum(range(10**7)) and a slightly heavier loop or numpy if available
> - Disk sequential write + read of a 50-100 MB file
> - Small package install time (if pip works)
> - Any other operation that feels unusually fast or slow
>
> 6. Other observations
> - Memory pressure behavior
> - Ability to run background processes or long-running tasks
> - Anything that breaks, hangs, or is surprisingly restricted
> - Any environment variables or injected configuration that looks sandbox-related
>
> Deliverable
> After finishing the checks, create a clean, well-structured Markdown file named something like environment_characterization.md that contains:
> - Executive summary (2-4 sentences)
> - Detailed sections matching the categories above
> - Tables for:
>   - Tool availability + versions
>   - Network latency / throughput results
>   - Benchmark timings
> - Raw notes or command outputs in collapsible sections or clearly marked appendix if useful
> - Clear statements of what is fast, what is slow, and hard limitations
>
> Be precise with numbers (include units and how you measured). Prefer real measured data over guesses.
>
> Start whenever you're ready and produce the final Markdown report when done.

### P2 (verbatim) - received between 11:22:56Z and 14:17:47Z
> 1. **Publish the raw** `.txt` **outputs, not just the reports.** (IF U PRODUCED THEM ALREADY, IF NOT , THEN SEE IF THEY ARE NEEDED & PRODUCE THEM ) Your file 6 references `01_runtime.txt`, `09_net_matrix.txt` etc. Verbatim transcripts with no LLM summarisation layer are the primary evidence.
> 2. **Ship the probe script** so a third party runs *your* script and diffs the output.
> 3. **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of raw files.

### P3 (verbatim) - received ≈2026-09-04T14:24Z
> now zip all of these files ?  &  save the zip as Agent 7 edge.zip , with all the files u have created , explaining, what the zip has, & what every file does, & when it was created , exact time & date & in sequence, which file was created when & also with the exact prompts i gave u , each time, & any imp metadata, that can be helpful

---

## 3. Creation sequence — every file, exact UTC time (birth time on ext4; `mtime` noted where birth is unavailable)

| # | Created (UTC) | File | Size | What it is |
|---|---|---|---|---|
| 1 | 2026-09-04T14:17:31Z | `environment_characterization.md` | 30755 | MAIN REPORT (v3): environment characterization - exec summary, runtime/isolation, tooling, filesystem, network, benchmarks, observations, hard limits, appendix + new section 0 (evidence integrity & reproducibility) |
| 2 | 2026-09-04T14:17:31Z | `envcheck/diskbench.sh` | 1649 | scratch script used to produce notes/11_disk_bench.txt (dd 200 MB + small-file rates; re-written after a quoting bug in the first attempt) |
| 3 | 2026-09-04T14:17:31Z | `envcheck/notes/01_system.txt` | 1314 | uname, /etc/os-release, arch/bits, libc (ldd), CPU model+nproc+SIMD flags, free/meminfo, cgroup version & mounts |
| 4 | 2026-09-04T14:17:31Z | `envcheck/notes/02_isolation.txt` | 4018 | PID 1 + process tree head, container marker files, cgroup paths, mount table, seccomp/caps status, ulimit -a, hostname, swap, full env var dump (incl. E2B_*) |
| 5 | 2026-09-04T14:17:31Z | `envcheck/notes/02b_isolation.txt` | 3018 | deeper isolation: cgroup v2 controller files & subdirs, namespace IDs, uid/gid maps, id/groups, sudo presence, /sys writability probes, boot_id, clocksource, hypervisor CPU flag, kvm-clock |
| 6 | 2026-09-04T14:17:31Z | `envcheck/notes/03_tools.txt` | 7258 | availability+version of ~55 tools (python/node/git/curl/gcc/java/apt...), full MISSING list |
| 7 | 2026-09-04T14:17:31Z | `envcheck/notes/04_limits_sudo_apt.txt` | 2262 | cgroup limits under /sys/fs/cgroup/user (memory.max=1947172864, cpu.max=max, pids.max), cpu.stat, memory.stat, sudo -n test (root OK), apt-get update as non-root (lock failure) |
| 8 | 2026-09-04T14:17:31Z | `envcheck/notes/05_fs.txt` | 4812 | df -hT, df -i, full mount list, /tmp vs /var/tmp vs /dev/shm sizes & fs types, root & home listings, /workspace absence |
| 9 | 2026-09-04T14:17:31Z | `envcheck/notes/06_fs_tests.txt` | 1247 | 1 MiB write+read+delete integrity tests (5 locations, sha1 MATCH), 200 MB tmpfs fdatasync write (2.0 GB/s), unicode filename, 20k-file tmpfs stress (timing lost - no bc), RO probes |
| 10 | 2026-09-04T14:17:31Z | `envcheck/notes/07_network_dns_ports.txt` | 1232 | /etc/resolv.conf, getaddrinfo timing (5 samples x 6 hosts), raw UDP:53 to 8.8.8.8/1.1.1.1/9.9.9.9, ICMP as user (EPERM), TCP connect RTT matrix (11 endpoints), IPv6 test (no route) |
| 11 | 2026-09-04T14:17:31Z | `envcheck/notes/08_network_latency.txt` | 1529 | curl -w breakdown (dns/conn/TLS/TTFB/total/speed) x 2 for google/github/pypi/huggingface HTTPS + HTTP:80 + google.com redirect |
| 12 | 2026-09-04T14:17:31Z | `envcheck/notes/09_network_throughput.txt` | 693 | first throughput pass: Cloudflare __down 100MB (HTTP 403), codeload cpython tarball (7.9 MB/s), HF config.json, 4x25MB parallel, TCP probes on 8080/8443 |
| 13 | 2026-09-04T14:17:31Z | `envcheck/notes/10_cpu_bench.txt` | 706 | CPython micro-benches (sum(range(1e7)) 0.2209 s, sine loop, multiprocessing 2-proc 0.2591 s), Node 1e7 loop (0.0824 s), gcc compile+run of 1e9-add C program, java -version startup |
| 14 | 2026-09-04T14:17:31Z | `envcheck/notes/11_disk_bench.txt` | 698 | dd 200 MB x ext4 (/home/user) and tmpfs: fdatasync write 830 MB/s vs 3.0 GB/s, page-cache read 5.2/5.3 GB/s, O_DIRECT 3.2/1.6 GB/s (unsupported on tmpfs); 20k small-file create/read/delete rates (4585/85397/78461 files/s) |
| 15 | 2026-09-04T14:17:31Z | `envcheck/notes/12_pip_bench.txt` | 709 | pip index versions idna, pip install idna 0.91 s (no-op), pip install numpy 0.63 s (no-op - preinstalled!), numpy matmul 1000^3 = 0.0283 s, numpy sum 1e7 = 0.0096 s |
| 16 | 2026-09-04T14:17:31Z | `envcheck/notes/13_apt_bench.txt` | 1343 | apt sources, sudo apt-get update 0.78 s (342 kB), sudo apt-get install sqlite3 2.10 s, sudo ping (cap_net_raw via sudo - 0.674 ms) |
| 17 | 2026-09-04T14:17:31Z | `envcheck/notes/14_pkg_installs.txt` | 2079 | preinstalled inventory (~182 pkgs incl. numpy/pandas/scipy/spacy), true pip force-reinstall numpy 2.88 s, npm install typescript 1.45 s, shallow git clones 0.60/0.99 s |
| 18 | 2026-09-04T14:17:31Z | `envcheck/notes/15_network_extra.txt` | 1792 | eth0 169.254.0.21/30 + MTU 1500 + routes, egress IP 34.187.218.115 (Google, The Dalles OR), E2B 192.0.2.1 probe (buggy f-string), 4x codeload parallel 11.98 s, release asset/HF range without -L (302s), uploads: httpbin 405, cloudflare 17.1 MB/s up |
| 19 | 2026-09-04T14:17:31Z | `envcheck/notes/15b_network_fixed.txt` | 1320 | corrected follow-redirect probes: pypi wheel 97.0 MB/s, 4x10MB parallel 0.18 s, GitHub release asset 162.8 MB/s, HF 50MB range 59.9 MB/s, gated llama 401, httpbin POST 1.6 MB/s, npm registry TTFB 95 ms, 192.0.2.1 all ports CONNECT |
| 20 | 2026-09-04T14:17:31Z | `envcheck/notes/16_memory.txt` | 1827 | first (buggy) memory ramp - os.getrusage AttributeError, dmesg via sudo, 3 GB bytearray -> MemoryError |
| 21 | 2026-09-04T14:17:31Z | `envcheck/notes/16b_memory_extra.txt` | 1546 | proper OOM ramp (SIGKILL exit 137, oom_kill=1, memory.current 7.9 MB after), tmpfs small-file rates (77619/344475 files/s), site-packages world-writable, 192.0.2.1 HTTP 404 JSON |
| 22 | 2026-09-04T14:17:31Z | `envcheck/notes/17_compile_system.txt` | 3400 | gcc -O0/-O2/-O3/-march=native timings (3.334/0.365/0.446/0.377 s), lscpu (2 vCPU, KVM), full capability bounding set decode, /.e2b IDs, systemd services (jupyter, envd, code-interpreter, sshd) |
| 23 | 2026-09-04T14:17:31Z | `envcheck/notes/18_ffmpeg_apt.txt` | 776 | sudo apt-get install ffmpeg (63.8 MB fetched @ 120 MB/s, 10.58 s), ffmpeg 7.1.5 verified, df after |
| 24 | 2026-09-04T14:17:31Z | `envcheck/notes/19_services_nohup.txt` | 2329 | ss listening sockets (8888=jupyter etc.), root caps via sudo, service briefs (envd, code-interpreter), nohup 90 s spawn (pid 3598), process count 91 |
| 25 | 2026-09-04T14:17:31Z | `envcheck/notes/20_background.txt` | 2540 | heartbeat server alive across tool calls (3 requests), cpu.stat before/after 2-core burn (0 throttling), server responsive during burn, GitHub SSH banner, nohup still running |
| 26 | 2026-09-04T14:17:31Z | `envcheck/notes/21_final_checks.txt` | 2423 | no /dev/kvm, no /dev/dri, no nvidia-smi, binutils 2.44, nohup result timing, heartbeat alive (uptime 466 s), final file inventory |
| 27 | 2026-09-04T14:17:31Z | `envcheck/notes/22_venv_nohup.txt` | 200 | nohup survival CONFIRMED (completed 11:22:56 UTC across sessions), python venv works (pip 26.1.2) |
| 28 | 2026-09-04T14:17:31Z | `envcheck/notes/23_preinstalled.txt` | 734 | 182 pip packages; version check of 47 key libs (numpy 2.5.2, pandas 2.2.3, scipy 1.17.1, matplotlib 3.10.9, spacy 3.8.14...; torch/transformers/sklearn absent) |
| 29 | 2026-09-04T14:17:31Z | `envcheck/notes/heartbeat.log` | 70 | heartbeat server log: SERVER STARTED pid=3614 port=8765 at 11:21:29 |
| 30 | 2026-09-04T14:17:31Z | `envcheck/notes/nohup_result.txt` | 35 | background-survival proof: 'survived and completed at 11:22:56' |
| 31 | 2026-09-04T14:17:31Z | `envcheck/probe_environment.sh` | 33472 | REPRODUCIBLE PROBE (live v2): one script producing 17 verbatim section transcripts + per-run SHA-256 manifest; --full/--skip-apt/--skip-oom/--dir flags; exits 1 if manifest check fails. v2 delta vs archived v1: nohup survival probe now writes into the run dir |
| 32 | 2026-09-04T14:17:47Z | `envcheck/raw/run_20260904T141747Z/00_meta.txt` | 997 | run identity: runid, UTC, hostname, kernel, arch, OS, user/uid/gid, E2B_SANDBOX_ID, E2B_TEMPLATE_ID, boot_id, flags, probe script sha256 |
| 33 | 2026-09-04T14:17:47Z | `envcheck/raw/run_20260904T141747Z/01_runtime.txt` | 2824 | OS/kernel/arch/libc/CPU model+flags/lscpu/clocksource/memory/uptime |
| 34 | 2026-09-04T14:17:47Z | `envcheck/raw/run_20260904T141747Z/02_isolation.txt` | 1757 | PID 1 + tree, container markers, cgroup paths, namespaces, uid/gid maps, capabilities, seccomp, virt detect, boot_id, sudo test, write probes |
| 35 | 2026-09-04T14:17:47Z | `envcheck/raw/run_20260904T141747Z/03_tools.txt` | 8236 | tool availability+versions table, pip package count + 36 key package versions (incl. what's absent) |
| 36 | 2026-09-04T14:17:50Z | `envcheck/raw/run_20260904T141747Z/04_limits.txt` | 3150 | ulimit -a, /proc/self/limits, cgroup limits (memory.max 1947172864, cpu.max max, pids.max max), cpu.stat, memory.events, memory.stat |
| 37 | 2026-09-04T14:17:50Z | `envcheck/raw/run_20260904T141747Z/05_filesystem.txt` | 5108 | df -hT, df -i, mounts, tmp/shm/run details, fs types of key paths, workspace & root listings |
| 38 | 2026-09-04T14:17:50Z | `envcheck/raw/run_20260904T141747Z/06_fs_tests.txt` | 1349 | 1 MiB write/read/delete integrity + sha1 compare (ext4 scratch, tmpfs, /var/tmp, /dev/shm, HOME), 200 MB fdatasync, unicode names, RO probes |
| 39 | 2026-09-04T14:17:50Z | `envcheck/raw/run_20260904T141747Z/07_dns.txt` | 1180 | resolv.conf, getaddrinfo timing (5 samples x 8 hosts), raw UDP:53 x 3 resolvers |
| 40 | 2026-09-04T14:17:51Z | `envcheck/raw/run_20260904T141747Z/08_http_latency.txt` | 1794 | curl -w HTTPS breakdown x2 (google/github/pypi/huggingface), HTTP:80, redirect behavior |
| 41 | 2026-09-04T14:17:51Z | `envcheck/raw/run_20260904T141747Z/09_net_matrix.txt` | 2018 | TCP connect matrix (19 endpoints incl. 192.0.2.1), ICMP (user+sudo), IPv6, interfaces/MTU/routes, egress IP 136.67.146.242 + geo |
| 42 | 2026-09-04T14:17:53Z | `envcheck/raw/run_20260904T141747Z/10_download_throughput.txt` | 1764 | PyPI wheel 105.2 MB/s, GitHub release asset 198.6 MB/s, codeload 6.9 MB/s, HF 50MB range 66.2 MB/s, 4x10MB parallel 0.16 s, 4x codeload parallel 4.41 s, uploads (cloudflare 17 MB/s, httpbin) |
| 43 | 2026-09-04T14:18:07Z | `envcheck/raw/run_20260904T141747Z/11_cpu_bench.txt` | 1050 | CPython benches, node loop, gcc -O0..march=native compile+run, numpy matmul/sum |
| 44 | 2026-09-04T14:18:13Z | `envcheck/raw/run_20260904T141747Z/12_disk_bench.txt` | 1347 | dd 200 MB ext4+tmpfs (write 830 MB/s / 3.0 GB/s, read 5.2/5.3 GB/s, O_DIRECT 3.2/1.6 GB/s), small-file rates ext4+tmpfs |
| 45 | 2026-09-04T14:18:18Z | `envcheck/raw/run_20260904T141747Z/13_pkg_installs.txt` | 1379 | pip index idna, fresh venv pip install idna 0.56 s + numpy 3.64 s, npm typescript 1.57 s, git clone pip 1.09 s, apt update 0.80 s, apt install sqlite3 2.14 s + ffmpeg 9.10 s |
| 46 | 2026-09-04T14:18:40Z | `envcheck/raw/run_20260904T141747Z/14_memory_pressure.txt` | 2115 | 3 GB bytearray -> MemoryError; 200 MB-step OOM ramp: steps 1-7 OK (1.63 GB), killed at step 8, oom-ramp-exit=137, memory.events oom_kill 1, current 117 MB after |
| 47 | 2026-09-04T14:18:43Z | `envcheck/raw/run_20260904T141747Z/15_services_processes.txt` | 4603 | process count/tree, ss listening sockets, systemd services, dmesg via sudo, nohup 90 s background-survival probe spawn |
| 48 | 2026-09-04T14:18:43Z | `envcheck/raw/run_20260904T141747Z/16_envconfig.txt` | 1125 | sorted env vars, /.e2b, resolv.conf, locale/timezone, /etc/hosts |
| 49 | 2026-09-04T14:18:43Z | `envcheck/raw/run_20260904T141747Z/MANIFEST.sha256` | 1424 | machine-checkable manifest (sha256sum -c -> all OK, 17/17) |
| 50 | 2026-09-04T14:18:43Z | `envcheck/raw/run_20260904T141747Z/MANIFEST.txt` | 2633 | hash-anchored at capture: run id, started/finished UTC, hostname, kernel, arch, OS, user, E2B IDs, boot_id, egress IP, flags, probe script sha256, per-file size+sha256; self-check PASS |
| 51 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/01_system.txt` | 1314 | byte-identical published copy of notes/01_system.txt (sha256-verified at copy time); see notes/ entry above for content |
| 52 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/02_isolation.txt` | 4018 | byte-identical published copy of notes/02_isolation.txt (sha256-verified at copy time); see notes/ entry above for content |
| 53 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/02b_isolation.txt` | 3018 | byte-identical published copy of notes/02b_isolation.txt (sha256-verified at copy time); see notes/ entry above for content |
| 54 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/03_tools.txt` | 7258 | byte-identical published copy of notes/03_tools.txt (sha256-verified at copy time); see notes/ entry above for content |
| 55 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/04_limits_sudo_apt.txt` | 2262 | byte-identical published copy of notes/04_limits_sudo_apt.txt (sha256-verified at copy time); see notes/ entry above for content |
| 56 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/05_fs.txt` | 4812 | byte-identical published copy of notes/05_fs.txt (sha256-verified at copy time); see notes/ entry above for content |
| 57 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/06_fs_tests.txt` | 1247 | byte-identical published copy of notes/06_fs_tests.txt (sha256-verified at copy time); see notes/ entry above for content |
| 58 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/07_network_dns_ports.txt` | 1232 | byte-identical published copy of notes/07_network_dns_ports.txt (sha256-verified at copy time); see notes/ entry above for content |
| 59 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/08_network_latency.txt` | 1529 | byte-identical published copy of notes/08_network_latency.txt (sha256-verified at copy time); see notes/ entry above for content |
| 60 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/09_network_throughput.txt` | 693 | byte-identical published copy of notes/09_network_throughput.txt (sha256-verified at copy time); see notes/ entry above for content |
| 61 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/10_cpu_bench.txt` | 706 | byte-identical published copy of notes/10_cpu_bench.txt (sha256-verified at copy time); see notes/ entry above for content |
| 62 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/11_disk_bench.txt` | 698 | byte-identical published copy of notes/11_disk_bench.txt (sha256-verified at copy time); see notes/ entry above for content |
| 63 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/12_pip_bench.txt` | 709 | byte-identical published copy of notes/12_pip_bench.txt (sha256-verified at copy time); see notes/ entry above for content |
| 64 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/13_apt_bench.txt` | 1343 | byte-identical published copy of notes/13_apt_bench.txt (sha256-verified at copy time); see notes/ entry above for content |
| 65 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/14_pkg_installs.txt` | 2079 | byte-identical published copy of notes/14_pkg_installs.txt (sha256-verified at copy time); see notes/ entry above for content |
| 66 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/15_network_extra.txt` | 1792 | byte-identical published copy of notes/15_network_extra.txt (sha256-verified at copy time); see notes/ entry above for content |
| 67 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/15b_network_fixed.txt` | 1320 | byte-identical published copy of notes/15b_network_fixed.txt (sha256-verified at copy time); see notes/ entry above for content |
| 68 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/16_memory.txt` | 1827 | byte-identical published copy of notes/16_memory.txt (sha256-verified at copy time); see notes/ entry above for content |
| 69 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/16b_memory_extra.txt` | 1546 | byte-identical published copy of notes/16b_memory_extra.txt (sha256-verified at copy time); see notes/ entry above for content |
| 70 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/17_compile_system.txt` | 3400 | byte-identical published copy of notes/17_compile_system.txt (sha256-verified at copy time); see notes/ entry above for content |
| 71 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/18_ffmpeg_apt.txt` | 776 | byte-identical published copy of notes/18_ffmpeg_apt.txt (sha256-verified at copy time); see notes/ entry above for content |
| 72 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/19_services_nohup.txt` | 2329 | byte-identical published copy of notes/19_services_nohup.txt (sha256-verified at copy time); see notes/ entry above for content |
| 73 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/20_background.txt` | 2540 | byte-identical published copy of notes/20_background.txt (sha256-verified at copy time); see notes/ entry above for content |
| 74 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/21_final_checks.txt` | 2423 | byte-identical published copy of notes/21_final_checks.txt (sha256-verified at copy time); see notes/ entry above for content |
| 75 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/22_venv_nohup.txt` | 200 | byte-identical published copy of notes/22_venv_nohup.txt (sha256-verified at copy time); see notes/ entry above for content |
| 76 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/23_preinstalled.txt` | 734 | byte-identical published copy of notes/23_preinstalled.txt (sha256-verified at copy time); see notes/ entry above for content |
| 77 | 2026-09-04T14:19:15Z | `envcheck/raw/run_20260904T1116Z_original/nohup_result.txt` | 35 | copy of the background-survival artifact (same content as notes/nohup_result.txt) |
| 78 | 2026-09-04T14:19:39Z | `envcheck/raw/run_20260904T1116Z_original/MANIFEST.txt` | 6195 | backfilled human-readable manifest: run id, time window, IDs (transcribed; pre-dates probe script), transcript->section mapping, per-file size+sha256 |
| 79 | 2026-09-04T14:19:39Z | `envcheck/raw/run_20260904T1116Z_original/MANIFEST.sha256` | 2289 | machine-checkable manifest (sha256sum -c MANIFEST.sha256 -> all OK, 26/26) |
| 80 | 2026-09-04T14:20:37Z | `envcheck/README.md` | 5134 | runner's guide: verify commands, reproducibility, diff guidance (stable vs unstable identity fields), section->subject table, caveats |
| 81 | 2026-09-04T14:20:58Z | `envcheck/raw/run_20260904T141747Z/probe_environment.sh` | 33205 | ARCHIVED exact copy of the probe script that generated this run (sha256 c0ced58...); verified by reconstructing the live script's single-edits delta |

---

## 4. Metadata

### 4.1 Environment (at capture)

| Key | Value |
|---|---|
| OS / kernel / arch / libc | Debian GNU/Linux 13 (trixie) 13.6 / 6.1.158+ / x86_64 / glibc 2.41 |
| CPU | Intel Xeon (sanitized) ~2.60 GHz, 2 vCPU (1 socket, 1 core, 2 threads), AVX-512 + AVX2 + FMA |
| RAM | MemTotal 1,932,608 kB (~1.94 GiB), no swap; cgroup memory.max 1,947,172,864 B (1.81 GiB) |
| Disk | 25 GB ext4 on /dev/vda (virtio), 20 GB free, 6.62M free inodes; /tmp = 993 MB tmpfs (RAM) |
| Virtualization | KVM micro-VM (Firecracker-style, E2B) — systemd PID 1, cgroup v2, no seccomp, caps dropped as user, full caps via passwordless sudo |
| Hostname / boot_id | e2b.local / 2bb79165-136a-4b63-829d-17027b0a8e40 (stable VM identity) |
| Template / build | E2B_TEMPLATE_ID nlhz8vlwyupq845jsdg9 / BUILD_ID f34a5416-ef30-4cb7-8e18-0fdecd6eb529 |
| E2B_SANDBOX_ID (run #1) | i07vrt7m23evfzhmemmqh (observed; rotates per session of same VM) |
| E2B_SANDBOX_ID (run #2) | ilvohmgrk3rcbvrgm79be (observed) |
| Egress IP (run #1) | 34.187.218.115 — AS396982 Google LLC, The Dalles, Oregon US |
| Egress IP (run #2) | 136.67.146.242 |
| User | user uid=1000 gid=1000, groups: user,sudo,users; passwordless sudo -> root |
| Services | jupyter (127.0.0.1:8888), sshd, envd (E2B), code-interpreter (E2B), journald, dbus |
| Locale | C/POSIX, LANG unset |

### 4.2 Runs & artifacts

| Run | UTC window | How produced | Transcripts | Verification |
|---|---|---|---|---|
| run_20260904T1116Z_original | 11:16:10 – 11:22:56 | manually, pre-probe-script | 26 (+ nohup_result.txt) | backfilled MANIFEST (sha256sum -c: 26/26 OK) |
| run_20260904T141747Z | 14:17:47 – 14:18:44 | probe_environment.sh --full | 17 | hash-anchored at capture; self-check PASS; re-verified 17/17 OK |

| Artifact | sha256 |
|---|---|
| main report | `81fd804444153b758d91b82fa3be9e27bf841c43610410249f3565654afbd559` |
| live probe script (v2) | `a35d9d9bf11c292cbd32476eeebf1e835f7e412cee6aeb88c6913936d8458540` |
| archived probe script used for run #2 (v1) | `c0ced58296a72444707fc17b919c29d8908bac0fd4381a0529e9b9aac7e4857e` |
| zip sidecar | see `Agent 7 edge.zip.sha256` (computed at zip creation, not stored inside the zip) |

### 4.3 Provenance notes

- Run #1's MANIFEST is **backfilled** (run predates the probe script): hashes are real and verifiable, identity fields were transcribed post-hoc. Run #2's MANIFEST is hash-anchored at capture time.
- The probe script that produced run #2 is **archived inside the run directory** (sha256 c0ced58296a72444707fc17b919c29d8908bac0fd4381a0529e9b9aac7e4857e); the live copy is a documented one-hunk revision (a35d9d9bf11c292cbd32476eeebf1e835f7e412cee6aeb88c6913936d8458540): the 90 s nohup survival probe now writes `nohup_result.txt` into the run dir instead of a scratch dir cleaned up at exit.
- All shell transcripts were captured by redirecting stdout/stderr of live commands (`> notes/NN.txt 2>&1`) — no summarisation; the markdown report is the only summarisation layer.
- `envcheck/notes/` = historic originals; `envcheck/raw/run_20260904T1116Z_original/` = byte-identical published copies (sha256-verified at copy time).
- Measurements that were re-derived (best-of): OOM ceiling pinned to 1.52–1.72 GiB cgroup usage by the canonical run's step ramp; GitHub release-asset throughput 198.6 MB/s in run #2 vs 162.8 MB/s in run #1 (CDN variance).
- Zip creation: `zip -r` from /home/user at 2026-09-04T14:2xZ (see `ZIP_CONTENTS_MANIFEST.txt` for per-entry sha256; verify with `unzip -t` and `sha256sum -c "Agent 7 edge.zip.sha256"`).

---

## 5. Verification commands

```bash
# 1. zip integrity
unzip -t "Agent 7 edge.zip"
# 2. zip hash
sha256sum -c "Agent 7 edge.zip.sha256"
# 3. per-entry manifest
unzip -p "Agent 7 edge.zip" ZIP_CONTENTS_MANIFEST.txt > /tmp/zcm.txt && (cd /tmp && sha256sum -c zcm.txt)
# 4. verification manifests inside the archive
cd envcheck/raw/run_20260904T141747Z && sha256sum -c MANIFEST.sha256
cd envcheck/raw/run_20260904T1116Z_original && sha256sum -c MANIFEST.sha256
```
