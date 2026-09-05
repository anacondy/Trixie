# Agent 8 edge.zip — contents, prompts, timeline, metadata

**Archive filename:** `Agent 8 edge.zip`  
**Packed (UTC):** 2026-09-04T14:20:33Z (this README written immediately before zip; zip mtime will be a few seconds later)  
**Packed timezone context:** sandbox clock UTC; user local timezone Asia/Calcutta (IST, UTC+5:30)  
**Purpose:** Environment characterization of an Arena.ai / E2B Agent Mode sandbox so a long-running research + data pipeline can be planned against real limits.

This file is **inside the zip**. It records *what* is packed, *why* each file exists, *when* it was created (filesystem mtime, UTC), *in what order*, the **exact user prompts** that produced the work, and extra metadata.

---

## Exact user prompts (verbatim, in conversation order)

### Prompt 1 — first message (characterization request)

> I’m setting up a long-running research + data pipeline that will involve mixed CPU work, network I/O, package installs, and some file processing. Before I commit any real code or data, I need a clear picture of what this environment can actually sustain.  
>   
> Please treat this as serious environment characterization work. Do the following thoroughly and keep notes as you go (you can use temporary files or just track things in memory, but be systematic).  
>   
> Required checks  
>   
> **1. Runtime & Isolation**  
> (OS, kernel, arch, libc, container/VM signals, user, limits)  
>   
> **2. Tooling & Language Runtimes**  
> (python3, pip, node, npm, git, curl, wget, ffmpeg, docker, make, gcc/clang, jq, package managers, install/compile)  
>   
> **3. Filesystem & Persistence**  
> (cwd, home, /tmp, disk, inodes, write tests, persistence)  
>   
> **4. Network Characterization**  
> (DNS, latency/throughput to google.com / 8.8.8.8, github.com, pypi.org, huggingface.co, large download, blocks, ports)  
>   
> **5. Performance Micro-benchmarks**  
> (Python CPU, disk 50–100 MB, pip install time)  
>   
> **6. Other observations**  
>   
> Deliverable: a clean Markdown file named something like environment_characterization 8 [edge.md](http://edge.md)

*(HTML entities `&amp;` appeared in the tool-facing copy of headings; the intent was “Runtime & Isolation”, “Tooling & Language Runtimes”, “Filesystem & Persistence”.)*

**Agent action:** Live measurements, then `environment_characterization.md`. First-pass sandbox ID was `i87c7gwotry240rbx1u77`. Approximate wall clock of first measurements: **2026-09-04 ~11:19–11:21 UTC** (uptime “1 min” at 11:21:03). Those first-pass command outputs were **not** saved as `.txt` at the time (in-memory / report only).

### Prompt 2 — second message (raw transcripts + script + manifest)

> 1. **Publish the raw** `.txt` **outputs, not just the reports.** (IF U PRODUCED THEM ALREADY, IF NOT , THEN SEE IF THEY ARE NEEDED & PRODUCE THEM ) Your file 6 references `01_runtime.txt`, `09_net_matrix.txt` etc. Verbatim transcripts with no LLM summarisation layer are the primary evidence.  
> 2. **Ship the probe script** so a third party runs *your* script and diffs the output.  
> 3. **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of raw files.

**Agent action:** Wrote `probe_environment.sh`, ran it into `probe_raw/`, wrote `VERIFICATION_MANIFEST.md`, patched the Markdown report to point at raw files. Scripted re-probe **2026-09-04T14:14:32Z**. Sandbox ID on this boot: `iitws4rrop6j50j2hed7r` (template unchanged).

### Prompt 3 — this message (zip)

> now zip all of these files ? & save the zip as Agent 8 edge.zip , with all the files u have created , explaining, what the zip has, & what every file does, & when it was created , exact time & date & in sequence, which file was created when & also with the exact prompts i gave u , each time, & any imp metadata, that can be helpful

**Agent action:** This README + zip.

---

## Creation sequence (filesystem mtime, UTC)

Times from `stat -c '%y'` on the sandbox. Nanoseconds included as stored.

| Seq | UTC mtime | File | Bytes | Role |
|----:|-----------|------|------:|------|
| 1 | 2026-09-04 **14:14:20.320622826** +0000 | `probe_environment.sh` | 13694 | Reproducible probe (bash). Created in prompt-2 turn **before** the run. |
| 2 | 2026-09-04 **14:14:23.848622826** +0000 | `probe_raw/01_runtime.txt` | 1556 | OS / kernel / libc / virt transcript |
| 3 | 2026-09-04 **14:14:23.904622826** +0000 | `probe_raw/02_isolation.txt` | 11077 | dockerenv, cgroup, mounts, caps, seccomp, ps |
| 4 | 2026-09-04 **14:14:23.940622826** +0000 | `probe_raw/03_identity_limits.txt` | 1966 | uid, sudo, ulimit |
| 5 | 2026-09-04 **14:14:23.956622826** +0000 | `probe_raw/04_cpu_mem.txt` | 7646 | lscpu, meminfo, uptime |
| 6 | 2026-09-04 **14:14:25.176622826** +0000 | `probe_raw/05_tools.txt` | 3996 | tool versions matrix |
| 7 | 2026-09-04 **14:14:27.576622826** +0000 | `probe_raw/06_python_pkgs.txt` | 615 | numpy/pandas/sklearn/… |
| 8 | 2026-09-04 **14:14:27.780622826** +0000 | `probe_raw/07_filesystem.txt` | 1637 | df + write tests |
| 9 | 2026-09-04 **14:14:27.788622826** +0000 | `probe_raw/08_env.txt` | 343 | `env \| sort` |
| 10 | 2026-09-04 **14:14:30.520622826** +0000 | `probe_raw/09_net_matrix.txt` | 3501 | DNS, curl, TCP, download, ports |
| 11 | 2026-09-04 **14:14:31.828622826** +0000 | `probe_raw/10_benches.txt` | 480 | CPU / disk / gcc timings |
| 12 | 2026-09-04 **14:14:32.668622826** +0000 | `probe_raw/11_pip_sample.txt` | 260 | timed `pip install charset-normalizer` |
| — | 2026-09-04 **14:14:32.676622826** +0000 | `probe_raw/` directory | — | dir mtime after last transcript |
| 13 | 2026-09-04 **14:14:38.860622826** +0000 | `probe_raw/00_MANIFEST.txt` | 1576 | hashes + E2B IDs (written then appended with script SHA) |
| 14 | 2026-09-04 **14:15:00.148622826** +0000 | `VERIFICATION_MANIFEST.md` | 3813 | Human-readable run identity + SHA-256 table |
| 15 | 2026-09-04 **14:15:05.604622826** +0000 | `environment_characterization.md` | 13251 | Narrative report (first written ~11:20 UTC on earlier boot, **mtime is last edit** in prompt-2 when a pointer to raw files was added) |
| 16 | ~2026-09-04 **14:20:33Z** | `README_ZIP.md` (this file) | — | Packing list + prompts + timeline |
| 17 | seconds after 16 | `Agent 8 edge.zip` | — | This archive |

**Important about seq 15:** `environment_characterization.md` was **first created in prompt 1** (~11:19–11:21 UTC, sandbox `i87c7gwotry240rbx1u77`). The inode mtime above is the **last modification** (prompt 2). Original first-write timestamp was not preserved.

**IST equivalents (UTC+5:30):** 14:14 UTC = 19:44 IST; 14:15 UTC = 19:45 IST; 11:19 UTC ≈ 16:49 IST.

---

## What each file does

### Top level

| Path | What it is |
|------|------------|
| `README_ZIP.md` | This packing document: prompts, sequence, metadata. |
| `environment_characterization.md` | LLM-structured report (tables, interpretation). **Secondary.** Use for reading; do not treat as primary evidence. |
| `VERIFICATION_MANIFEST.md` | Frozen SHA-256 table + sandbox/template IDs + how to re-run/diff. |
| `probe_environment.sh` | Third-party probe. `bash probe_environment.sh [outdir]`. SHA-256 at pack time of script: `fcae745dd2c5a4cc917a8821c84e113b5fb47c51684db40c522190452a411524`. |

### `probe_raw/` — primary evidence (verbatim command output)

| Path | What it is |
|------|------------|
| `00_MANIFEST.txt` | Machine-readable hashes + `E2B_*` for the **scripted** run |
| `01_runtime.txt` | `uname`, os-release, ldd, systemd-detect-virt |
| `02_isolation.txt` | Isolation signals |
| `03_identity_limits.txt` | Identity and ulimits |
| `04_cpu_mem.txt` | CPU and memory |
| `05_tools.txt` | Tool availability/versions |
| `06_python_pkgs.txt` | Preinstalled Python modules |
| `07_filesystem.txt` | Disk and write tests |
| `08_env.txt` | Environment variables (includes E2B) |
| `09_net_matrix.txt` | Network measurements |
| `10_benches.txt` | Microbenchmarks |
| `11_pip_sample.txt` | Sample pip install timing |

SHA-256 of transcripts (scripted run) are in `VERIFICATION_MANIFEST.md` / `00_MANIFEST.txt`. Do not expect a third-party rerun to match hashes (clocks, sandbox ID, jitter).

---

## Environment metadata (scripted run, 14:14Z)

| Field | Value |
|--------|--------|
| Hostname | `e2b.local` |
| `E2B_SANDBOX` | `true` |
| `E2B_SANDBOX_ID` | `iitws4rrop6j50j2hed7r` |
| `E2B_TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` |
| Kernel | `Linux e2b.local 6.1.158+ … x86_64` |
| OS | Debian 13 (trixie) |
| Virt | KVM |
| CPU | 2 × Intel Xeon @ 2.60 GHz |
| RAM | ~1.9 GiB, **0 swap** |
| User | uid 1000 `user`, passwordless sudo |
| Prompt-1 sandbox ID (earlier boot, same template) | `i87c7gwotry240rbx1u77` |

Headline limits (from report): no ICMP, IPv6 connect fail, transparent TCP accept (TEST-NET connects), ~5 MB/s sample download, no docker/ffmpeg by default, `/tmp` is tmpfs ~1 GiB, `/home/user` persists across messages.

---

## What is *not* in the zip

- OS packages, Python site-packages, `/tmp` bench blobs (deleted after tests)
- First-pass (~11:19 UTC) raw stdout (never written to disk; only folded into the Markdown)
- Arena/E2B platform internals beyond `E2B_*` env vars

---

## Suggested unzip layout

```
Agent 8 edge.zip
├── README_ZIP.md
├── VERIFICATION_MANIFEST.md
├── environment_characterization.md
├── probe_environment.sh
└── probe_raw/
    ├── 00_MANIFEST.txt
    ├── 01_runtime.txt
    ├── …
    └── 11_pip_sample.txt
```

Re-run: `bash probe_environment.sh /tmp/probe_raw_rerun && diff -ru probe_raw /tmp/probe_raw_rerun`
