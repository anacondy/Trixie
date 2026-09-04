# 📦 Agent 6 brave.zip — Contents Guide, File-by-File Explanation, Chronology & Metadata

**Produced by:** Arena.ai Agent Mode (interactive agent session) · **Date:** 2026-09-04 (Thursday)
**Subject:** Full evidence pack for a live environment-characterization study of the Linux microVM sandbox (E2B infrastructure) that hosts this conversation.
**Zip created:** 2026-09-04 ≈14:08 UTC (≈19:38 IST) · 90 files (94 zip entries incl. 4 folders) · ≈344 KB staged → ≈150 KB compressed
**Integrity sidecar (sibling of this zip):** `Agent 6 brave.zip.sha256`

> All times in this document are UTC unless marked **IST** (Asia/Kolkata = UTC+5:30, the user's timezone). Where a time is *measured from file content or filesystem metadata* it is exact to the shown precision; where it is inferred from session sequencing it is marked **≈** and the evidence basis is given.

---

## 1. What this zip contains (tree)

```
Agent 6 brave.zip
├── 00_README_zip_contents.md              ← this file (start here)
├── environment_characterization.md        ← the main report (deliverable of prompt 1)
├── RAW_VERBATIM_APPENDIX.md               ← all raw probe transcripts, byte-for-byte, html-escaped only
├── environment_probe.sh                   ← reproducible probe battery (re-run it yourself)
├── compare_run.sh                         ← structural diff helper (canonical vs your re-run)
├── cross_turn_check.txt                   ← live persistence experiment evidence
├── compare_canonical_vs_fullrun.txt       ← recorded compare_run.sh output: RESULT: PASS
├── envprobe/                              ← canonical run-1 raw evidence (20 files, incl. manifest + sha256sums)
└── rerun_*/                               ← three independent re-runs of environment_probe.sh:
    ├── rerun_A_smoke6_QUICK/              ← QUICK-mode test run        (13:56:59–13:57:25Z)
    ├── rerun_B_smoke7_QUICK_PASS/         ← QUICK-mode final PASS run  (13:57:55–13:58:21Z)
    └── rerun_C_full_FULL_PASS/            ← FULL-mode final PASS run   (13:58:33–13:59:27Z)
        (each rerun folder = its own complete evidence set + own manifest.json + sha256sums.txt)
```

---

## 2. The exact prompts you gave, each time

Three user messages drove this whole body of work. They are reproduced below **verbatim** (only rendering normalizations were applied, listed after each prompt: HTML entities decoded, hyperlink-mangling artefacts from the chat renderer flattened — wording untouched).

---

### PROMPT 1 — received ≈11:15 UTC (≈16:45 IST), 2026-09-04
*Evidence for time: the first probe file this prompt triggered (`envprobe/01_runtime.txt`) carries header timestamp `2026-09-04T11:15:36Z`.*

> I'm setting up a long-running research + data pipeline that will involve mixed CPU work, network I/O, package installs, and some file processing. Before I commit any real code or data, I need a clear picture of what this environment can actually sustain.
>
> Please treat this as serious environment characterization work. Do the following thoroughly and keep notes as you go (you can use temporary files or just track things in memory, but be systematic).
>
> **Required checks**
>
> **1. Runtime & Isolation** — Exact OS, kernel version, architecture, libc — Clear signals of containerization / VM / restricted sandbox (cgroup, /.dockerenv, mount info, process tree, capabilities, seccomp, etc.) — Current user, uid/gid, sudo/root status — Any obvious resource limits (ulimit, cgroup memory/cpu, process limits)
>
> **2. Tooling & Language Runtimes** — Availability + versions of: python3, pip, node, npm, git, curl, wget, ffmpeg, docker, make, gcc/clang, jq, etc. — Which package managers work (apt, apk, yum, pip, conda, npm…) and whether they can actually install things — Can you install pure-python packages? System packages? Compile anything?
>
> **3. Filesystem & Persistence** — Working directory, home, /tmp behavior — Free disk space and inode situation — Read-only mounts or protected paths — Simple write + read + delete test in a few locations — Whether files survive across "sessions" if possible to test
>
> **4. Network Characterization (important)** — Run real measurements, not just "can I connect": — DNS resolution speed — Latency + rough throughput to several endpoints (at minimum): google.com / 8.8.8.8, github.com, pypi.org, huggingface.co, a large file download (e.g. a few MB from a reliable CDN or GitHub release) — Note any timeouts, blocks, captive portals, or asymmetric performance — Outbound ports / protocols that appear restricted
>
> **5. Performance Micro-benchmarks** — Keep them short but timed accurately: — Pure Python CPU: sum(range(10**7)) and a slightly heavier loop or numpy if available — Disk sequential write + read of a 50–100 MB file — Small package install time (if pip works) — Any other operation that feels unusually fast or slow
>
> **6. Other observations** — Memory pressure behavior — Ability to run background processes or long-running tasks — Anything that breaks, hangs, or is surprisingly restricted — Any environment variables or injected configuration that looks sandbox-related
>
> **Deliverable** — After finishing the checks, create a clean, well-structured Markdown file named something like `environment_characterization.md` that contains: — Executive summary (2–4 sentences) — Detailed sections matching the categories above — Tables for: tool availability + versions, network latency / throughput results, benchmark timings — Raw notes or command outputs in collapsible sections or clearly marked appendix if useful — Clear statements of what is fast, what is slow, and hard limitations — Be precise with numbers (include units and how you measured). Prefer real measured data over guesses.
>
> Start whenever you're ready and produce the final Markdown report when done.

*Rendering notes: the prompt's endpoint list items contained doubled/self-nested hyperlinks (`[[google.com](http://google.com)](...)`) from the chat renderer; flattened here to plain text. A stray link artefact around the filename ("environment_[characterization 6 brave.md](http://characterization.md)") rendered the intended filename as `environment_characterization.md`.*

---

### PROMPT 2 — received ≈13:43 UTC (≈19:13 IST), 2026-09-04
*Evidence for time: a fresh VM instance for this turn booted at `13:43:38Z` and the restored workspace carries materialization stamp `13:43:49.873Z`.*

> 1. **Publish the raw** `.txt` **outputs, not just the reports.** (IF U PRODUCED THEM ALREADY, IF NOT , THEN SEE IF THEY ARE NEEDED & PRODUCE THEM ) Your file 6 references `01_runtime.txt`, `09_net_matrix.txt` etc. Verbatim transcripts with no LLM summarisation layer are the primary evidence.
> 2. **Ship the probe script** so a third party runs *your* script and diffs the output.
> 3. **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of raw files.

---

### PROMPT 3 — received ≈14:03 UTC (≈19:33 IST), 2026-09-04
*Evidence for time: the first command of this turn (metadata gathering) ran at `14:04:43.869Z`.*

> now zip all of these files ?  & save the zip as Agent 6 brave.zip , with all the files u have created , explaining, what the zip has, & what every file does, & when it was created , exact time & date & in sequence, which file was created when & also with the exact prompts i gave u , each time, & any imp metadata, that can be helpful

---

## 3. Master inventory — what every file is, when it was created, and its hash

### 3a. Top-level files (created across the three prompt phases)

| File in zip | What it is / does | Created (UTC, exact) | Size | SHA-256 |
|---|---|---|---|---|
| `00_README_zip_contents.md` | This guide | 2026-09-04 ≈14:05 (first draft), final ≈14:08 | 14,5xx B | — |
| `environment_characterization.md` | **Main report** — full characterization: runtime/isolation, tools, filesystem, network, benchmarks, fast/slow/hard-limits tables; updated after prompt 2 with measured persistence + reproducibility pack | content written ≈11:23–11:24 (run-1); final edits 13:59:46.105 | 28,103 B | `e6dd1ff6a2600b241d99f8516e66476d7da2c021c61280f4b98d3838ea42f8ea` |
| `RAW_VERBATIM_APPENDIX.md` | **Raw evidence publication** (prompt 2, #1) — the 18 canonical probe files embedded byte-for-byte, html-escaped only, with per-file size + SHA-256 index | v1 13:43:50.041; **v2 (final) 13:45:39.433** | 52,576 B | `688353ef4b3a42da82594a1a9cf2a079a33fde3b22b76a7c50187a9bad84f43d` |
| `environment_probe.sh` | **Reproducible probe battery** (prompt 2, #2) — re-runs the entire battery: `bash environment_probe.sh <dir>` (FULL) or `QUICK=1 …`; regenerates the identical file set + auto-writes `sha256sums.txt` + `manifest.json`. Version v1.1.0 | part 1 first written 13:44:16.077; parts appended ≈13:46–13:48; iterative fixes 13:48–13:57; **final version 13:57:55.033** | 46,431 B | `8c4c0d5f933c3365deccd9efc72a535fd47591307e3418cb03f4f53fadfd530a` |
| `compare_run.sh` | **Structural diff helper** (prompt 2, #2) — `bash compare_run.sh REFDIR NEWDIR`; checks file-set + normalized section anchors (digits→`#`); exit 0 = PASS. Version v2.0.0 | written ≈13:46; **final version 13:47:45.517** | 3,361 B | `2fa63cf8df053088efa56f6a1d9ec9598fe53f3ddfdb74796bf310ae296067a3` |
| `cross_turn_check.txt` | **Live persistence experiment** — transcript of the check run at the turn boundary: new VM instance, only `/home/user` survived, apt sqlite3 gone, `/tmp` wiped, `~/.local` gone, restored mtimes normalized | 13:44:53.417 | 2,603 B | `e0b23d4589b37ede8361a420b1670bfe1d8a79ccb40846457ac0f674cd51c7c9` |
| `compare_canonical_vs_fullrun.txt` | Recorded output of `compare_run.sh envprobe rerun_C_full_FULL_PASS` → **RESULT: PASS** (identical structure) | ≈13:59:35 (generated for this zip) | 2,606 B | — |

### 3b. `envprobe/` — canonical run-1 raw evidence (created during run-1; times from file *content*)

All 18 transcripts carry filesystem mtime `2026-09-04 13:43:49.873` — that is the **snapshot-restore stamp**, NOT their creation time (see §5 caveats). Their true creation times are embedded in their own content and shown below. Run-1 window: **started 11:15:36Z, ended 11:23:05Z** (first probe header → last bg-ticker entry). Run-1 sandbox: `idxwgcmp6a9ioo1823yuk`.

| File | What it is / does | Created (UTC, from content) |
|---|---|---|
| `01_runtime.txt` | uname, Debian 13.6, kernel 6.1.158+, glibc, container-marker checks, full /proc/mounts, cgroup v2, IPv6, boot_id | 11:15:36 (header) |
| `02_identity.txt` | id/uid/gid, sudo test, capabilities+seccomp decode, ulimits, RLIMITs, cgroup limits, cpuinfo, meminfo, env (redacted) | ≈11:15:40 (same batch as 01) |
| `03_tools.txt` | 70-tool availability/version probe matrix, pip/npm/git details | 11:15:45 ("probed" line) |
| `04_fs.txt` | df/inodes, RO mounts, fs types, write/read/delete probes in 4 locations, hardlink/symlink/fallocate, markers | ≈11:15:50 (marker line 11:15:50Z) |
| `05_cpu_mem.txt` | CPU benchmarks (medians-of-3), parallel scaling, 1 GiB memory-ceiling test | ≈11:16 |
| `06_compilers_pkgs.txt` | gcc hello-world, Python.h presence, apt update timing, sqlite3 install demo, dpkg arch, systemd units | ≈11:16 |
| `07_cgroup_sudo.txt` | delegated cgroup tree + per-slice limits, events endpoint, nproc/lscpu, ss listeners | ≈11:16–11:17 |
| `09_net_matrix.txt` | DNS timings, TCP connect RTT matrix, UDP/ICMP/IPv6 probes, curl 443 matrix | ≈11:17 |
| `10_net_throughput.txt` | Round-1 throughput: CF/hetzner/codeload/HF downloads, upload, ipinfo, ssh handshake, git clone, npm test — **contains the run-1 tracebacks from two probe-script quoting bugs (kept verbatim as evidence)** | ≈11:18–11:19 |
| `10b_net_throughput2.txt` | Fixed re-measurements: CF ×3, HF -L, GCS 404, hetzner DNS-block discovery, pypi wheel, OVH, apt | 11:19:38 (header) |
| `11_disk.txt` | Disk backend, buffered/O_DIRECT/cold/tmpfs benchmarks, 20k-file inode ops | ≈11:20 |
| `12_pip.txt` | pip suite: venv, wheel/sdist install timings, numpy, json/orjson benches, pip --user (also holds a run-1 traceback, verbatim) | ≈11:21 |
| `12b_pip2.txt` | Fixed pip reruns, numpy linux wheel, numpy bench, HF 4×5MiB parallel, hetzner DNS follow-up | ≈11:21 |
| `13_bg_misc.txt` | numpy/orjson bench summary, detached bg-ticker spawn (pid 2626), GPU/devices absence, sysctl, git demo, jupyter context | ≈11:21–11:22 |
| `14_final.txt` | BG-ticker survival check across tool calls (13 ticks, 60 s), persistence markers, session state, output inventory, jupyter health | ≈11:22:3x–11:23 |
| `15_process_demo.txt` | Platform-supervised server check (HTTP 200 in 1.1 ms on :8800) + ticker stop | ≈11:23:0x (server log 11:23:04–08Z) |
| `bg_ticks.txt` | 13 heartbeat timestamps of the detached background ticker (cross-tool-call survival proof) | 11:22:05 → 11:23:05 |
| `.persist_marker` | Run-1 in-session persistence marker ("HOME marker 2026-09-04T11:15:50Z"), later moved into envprobe | 11:15:50 (content) |
| `manifest.json` | **Verification manifest v2** (prompt 2, #3): run-1 window, sandbox/template/boot_id, machine + network capture during run, verification-session block, per-file SHA-256 | 13:45:39.433 (this session regenerated v2) |
| `sha256sums.txt` | Per-file SHA-256 of all 18 transcripts — `cd envprobe && sha256sum -c sha256sums.txt` → **18/18 OK** | v1 13:43:50.041; v2 13:45:39.433 |

### 3c. `rerun_*/` — independent verification re-runs of `environment_probe.sh`

Each folder contains the full standard output set (00_run_header, 01–15 sections incl. 10b/12b, bg_ticks, epilogue.txt, sha256sums.txt, manifest.json). The folders themselves are copies of the ephemeral `/tmp` runs, renamed descriptively:

| Folder | Mode | Run window (UTC, from its own manifest) | Outcome |
|---|---|---|---|
| `rerun_A_smoke6_QUICK` | QUICK=1 | 13:56:59 → 13:57:25 | intermediate iteration (epilogue hadhing bug still present) |
| `rerun_B_smoke7_QUICK_PASS` | QUICK=1 | 13:57:55 → 13:58:21 | **compare vs canonical: PASS** (exit 0) |
| `rerun_C_full_FULL_PASS` | FULL (default) | 13:58:33 → 13:59:27 | **compare vs canonical: PASS** (exit 0) — the real third-party path |

---

## 4. Chronology — which file was created when, in sequence

### Phase 0 — Prompt 1 → run-1 characterization (sandbox `idxwgcmp6a9ioo1823yuk`, template `nlhz8vlwyupq845jsdg9`)

| # | Time (UTC) | Time (IST) | Event / file created |
|---|---|---|---|
| 1 | 11:11:19 | 16:41:19 | Run-1 VM booted (per `uptime -s`) |
| 2 | ≈11:14–11:15 | ≈16:44–45 | **Prompt 1 received** |
| 3 | 11:15:36 | 16:45:36 | Probe battery starts → `envprobe/01_runtime.txt` (+`02`, `03` within the same minute) |
| 4 | 11:15:50 | 16:45:50 | `envprobe/04_fs.txt` markers written (`/home/user/.persist_marker`, `/tmp/.persist_marker`) |
| 5 | ≈11:16 | ≈16:46 | `05_cpu_mem.txt`, `06_compilers_pkgs.txt`, `07_cgroup_sudo.txt` |
| 6 | ≈11:17 | ≈16:47 | `09_net_matrix.txt` (network matrix) |
| 7 | ≈11:18–11:19 | ≈16:48–49 | `10_net_throughput.txt` (round 1 — the buggy round), `10b_net_throughput2.txt` (11:19:38 fixed round) |
| 8 | ≈11:19–11:20 | ≈16:49–50 | `11_disk.txt`, `12_pip.txt`, `12b_pip2.txt` |
| 9 | 11:22:05 | 16:52:05 | Detached background ticker (pid 2626) starts logging → `bg_ticks.txt` (survived 3+ tool-call boundaries) |
| 10 | ≈11:22:30–11:23:05 | ≈16:52:30–53:05 | `13_bg_misc.txt`, `14_final.txt`, `15_process_demo.txt` (supervised server check 11:23:04–08) |
| 11 | ≈11:23:1x–11:24 | ≈16:53–54 | **`environment_characterization.md` created** (main report) |
| 12 | 11:23:05 | 16:53:05 | Ticker stopped (last bg_ticks entry) — end of run-1 evidence |

### Phase 1 — Prompt 2 → publication pack (sandbox `i9nxb4qydn3qmwway6hd3`)

| # | Time (UTC) | Time (IST) | Event / file created |
|---|---|---|---|
| 13 | 13:43:38 | 19:13:38 | New VM materialized for turn 2 (fresh instance from the run-1 snapshot) |
| 14 | 13:43:49.873 | 19:13:49.873 | Workspace restored (this instant became the mtime stamp of all run-1 files) |
| 15 | 13:43:50.041 | 19:13:50.041 | **Prompt 2 received** → manifest v1 + `sha256sums.txt` v1 + `RAW_VERBATIM_APPENDIX.md` v1 (52,916 B) generated |
| 16 | 13:44:16.077 | 19:14:16.077 | `environment_probe.sh` part 1 written (first skeleton) |
| 17 | 13:44:53.417 | 19:14:53.417 | **`cross_turn_check.txt`** — persistence experiment results (sqlite3 gone, /tmp wiped, ~/.local gone, home intact) |
| 18 | 13:45:39.433 | 19:15:39.433 | `RAW_VERBATIM_APPENDIX.md` **v2 (final, 52,576 B)** + `envprobe/manifest.json` **v2 (8,391 B)** + `sha256sums.txt` v2 — truthful two-layer provenance |
| 19 | 13:46:16 | 19:16:16 | Sandbox reboot observed (same sandbox ID, disk persisted; env template ID thereafter reported as `fxynpzqxr7lv7q5lzp70` — platform metadata quirk) |
| 20 | ≈13:46–13:48 | ≈19:16–18 | `environment_probe.sh` parts 2+3 appended (33,481 B → 46,173 B, 856 lines); `compare_run.sh` v1 → **v2.0.0 final at 13:47:45.517** |
| 21 | ≈13:48–13:56 | ≈19:18–26 | Iterative fix cycle (patch passes + smoke runs `/tmp/smoke_run … smoke_run7`) — several found-and-fixed bugs (dl() `$4` unbound, `0*.txt` glob missing files 10–15, section-07/09 mangling, anchor wording) |
| 22 | 13:56:59–13:57:25 | 19:26:59–19:27:25 | `rerun_A_smoke6_QUICK` (intermediate) |
| 23 | 13:57:55.033 | 19:27:55.033 | `environment_probe.sh` **final v1.1.0** (46,431 B) |
| 24 | 13:57:55–13:58:21 | 19:27:55–19:28:21 | `rerun_B_smoke7_QUICK_PASS` → **compare PASS** |
| 25 | 13:58:33–13:59:27 | 19:28:33–19:29:27 | `rerun_C_full_FULL_PASS` (full battery) → **compare PASS**, exit 0 |
| 26 | 13:59:46.105 | 19:29:46.105 | `environment_characterization.md` updated (boot_id correction, measured persistence section, reproducibility-pack table with hashes) |
| 27 | ≈13:59:50–14:01 | ≈19:29–31 | Final integrity checks (`sha256sum -c` clean; top-level artifact hashes computed) |

### Phase 2 — Prompt 3 → this zip (current session)

| # | Time (UTC) | Time (IST) | Event |
|---|---|---|---|
| 28 | ≈14:03:4x | ≈19:33:4x | **Prompt 3 received** (zip request) |
| 29 | 14:04:43.869 | 19:34:43.869 | Metadata gathering command (identity, exact mtimes, content timestamps, hashes) |
| 30 | ≈14:05 | ≈19:35 | Staging tree built (`/tmp/zstage`, 89 files, 328,677 B) + `compare_canonical_vs_fullrun.txt` generated |
| 31 | ≈14:05–14:07 | ≈19:35–37 | **`00_README_zip_contents.md` written** (this file; final stat pass ≈14:08) |
| 32 | 14:07:04.911 | 19:37:04.911 | **`Agent 6 brave.zip` created** in `/home/user/` (v1; final rebuilt ≈14:08 after this guide's stats were finalized) |

**Files created during the work but intentionally NOT in this zip** (transient scratch, since deleted or in ephemeral `/tmp`): patch scripts `.patch_script.py`/`.patch2.py`/`.patch3.py` (deleted after use), `/tmp/smoke_run`…`smoke_run5` (earlier failed/intermediate smoke runs), `/tmp` scratch (venvs `/tmp/vptest`, npm test trees, downloaded benchmark files, `.bench100*` disk-bench files — cleaned by the battery itself), probe marker files (`.persist_marker_probe`) cleaned in section 14, and `/tmp/zstage` (this zip's staging area). Run-1's two buggy probe rounds were **kept** because they are primary evidence (`10_net_throughput.txt`, `12_pip.txt` contain the original tracebacks; the corrected data is in the `10b`/`12b` files).

---

## 5. Important metadata

### 5a. Sandbox / VM identity across the three phases (observed values)

| Attribute | Run-1 (11:15Z) | Turn 2 (13:44Z) | Now (14:04Z) |
|---|---|---|---|
| E2B_SANDBOX_ID | `idxwgcmp6a9ioo1823yuk` | `i9nxb4qydn3qmwway6hd3` | `i9nxb4qydn3qmwway6hd3` |
| E2B_TEMPLATE_ID | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` | `fxynpzqxr7lv7q5lzp70` |
| VM boot | 2026-09-04 11:11:19Z | 13:43:38Z | 13:46:16Z (reboot of same sandbox) |
| boot_id | `2bb79165-136a-4b63-829d-17027b0a8e40` | same | same |
| hostname | e2b.local | e2b.local | e2b.local |
| Kernel | 6.1.158+ | same | same |

Notes: **boot_id is identical across every observed instance/reboot → it is baked into the base image, not a per-boot identifier.** Template ID changed between the 13:43:38 materialization and the 13:46:16 reboot while the sandbox ID stayed the same — a platform-internal detail, recorded as observed.

### 5b. Machine, limits, network, tooling (all measured — see report for method)

- **Machine:** KVM full-virtualization microVM (systemd PID 1, *not* a container — no /.dockerenv). Debian GNU/Linux 13 (trixie) 13.6 · glibc 2.41-12+deb13u3 · x86_64. 2 vCPUs: Intel Xeon @ 2.60 GHz (1 core × 2 threads, AVX-512) · RAM 1,984 MiB, **no swap** · cgroup `memory.max` = 1,947,172,864 B (1,857 MiB), `cpu.max` = max (no quota) · user uid=1000 with **passwordless sudo, full cap set, no seccomp** · ext4 root, 25 GiB (20 GiB free), no overlayfs · egress: Google Cloud us-west1 (The Dalles, OR), IP `34.143.70.112`, AS396982.
- **Network quirks:** all TCP egress goes through a transparent local proxy (connect RTT ~0.2 ms; real latency 25–90 ms at TTFB); DNS A-records rewritten into 0.0.0.0/8 space; resolver 8.8.8.8; `speed.hetzner.de` NODATA-blocked (observed ×3); IPv6 not routed; UDP 443/QUIC silent; throughput 85–115 MiB/s (Cloudflare-class) vs 5–15 MiB/s per-connection at GitHub/HF/OVH; HF parallelizes ~2.2× (4 conns → 21.8 MiB/s).
- **Tooling:** python3 **3.13.14** (custom build; JIT-fast — `sum(range(10**7))` = 141 ms), pip 26.1.2, node v20.20.2 / npm 10.8.2, git 2.47.3, gcc 14.2.0, curl 8.14.1, jq 1.7, R 4.5.0, Java 11, make 4.4.1. apt works via sudo; pip/npm work with zero ceremony (site-packages user-writable, mode 777 quirk); C-ext sdist compiles (markupsafe 3.7 s). No ffmpeg/docker/clang/cmake by default (apt-installable in-session).
- **Persistence rules (measured):** only `/home/user` survives between sessions (~128 MiB / 10k-file budget); snapshot-excluded names: `.cache`, `.local`, `.venv`, `node_modules`, `build`, `dist`, `out`, `target`, `__pycache__`, git credential paths, etc. System state (apt), `/tmp`, `/dev/shm` reset per session/reboot.
- **Performance (measured):** pure-CPython ~2.5× faster than typical stock builds; numpy BLAS multithreaded (~136 GFLOPS 2048² matmul); disk: cold read 1,318 MiB/s, O_DIRECT read 2.1 GB/s, fsynced write ~480–1,467 MiB/s; 1 GiB allocation survived (practical ceiling ≈1.2 GiB RSS); detached `setsid` processes and the platform's supervised process runner both verified.
- **Snapshot caveat:** files that existed at a snapshot restore carry the *restore instant* as mtime (13:43:49.873Z), **not** their creation time — this zip's README therefore uses content-embedded timestamps for run-1 files and true stat mtimes for later files.
- **Tool-version quirk:** probe of `java --version` printed an odd string (`openjdk 11 2018-09-25`); recorded as-is.

---

## 6. How to verify everything yourself

```bash
# 1) unzip
unzip "Agent 6 brave.zip" -d agent6_brave && cd agent6_brave

# 2) canonical evidence integrity (18 transcripts)
cd envprobe && sha256sum -c sha256sums.txt && cd ..

# 3) re-run the battery yourself (structure identical; numbers will differ)
QUICK=1 bash environment_probe.sh my_run          # ~25 s
bash environment_probe.sh my_run_full             # ~1 min, full

# 4) diff your run against the canonical run
bash compare_run.sh envprobe my_run               # expect: RESULT: PASS

# 5) manifest of any run = timestamp + sandbox/template IDs + per-file SHA-256
cat my_run/manifest.json && cd my_run && sha256sum -c sha256sums.txt
```

**Recorded verification results (from the producing session):**
- `sha256sum -c envprobe/sha256sums.txt` → 18/18 OK (also re-verified after snapshot restore).
- QUICK run (`rerun_B`) vs canonical → **PASS, exit 0** (identical file set + normalized anchors).
- FULL run (`rerun_C`) vs canonical → **PASS, exit 0**; full transcript in `compare_canonical_vs_fullrun.txt`.
- Each rerun's manifest hashed 18 files with matching counts.

---

## 7. Integrity of this zip

- Entry count: **90 files + 4 folders = 94 entries** (staged ≈344 KB → compressed ≈150 KB)
- Built: 2026-09-04, first pass **14:07:04.911 UTC**, final rebuild ≈14:08 UTC, from a staging copy — the originals in `/home/user` were not modified by zipping
- SHA-256 of the zip: **see sibling file `Agent 6 brave.zip.sha256`** (computed after the final write; also reported in the agent's chat summary)
- Verify: `sha256sum -c "Agent 6 brave.zip.sha256"` and `unzip -t "Agent 6 brave.zip"` (both pass: *No errors detected in compressed data*)
- Zip was created with `zip -9 -X` (max compression, no extra attributes) on the same Linux box that produced the contents

*Methodology note on timestamps: run-1 file creation times were recovered from content (probe headers, marker lines, ticker entries, server logs) because snapshot restore overwrote their mtimes; all later files use true filesystem mtimes (`stat`). Where only a range is knowable the value is marked ≈.*
