#!/usr/bin/env python3
"""Build the requested 'Agent 9 edge.zip' evidence archive.

The archive mirrors all persistent files created by the environment-characterization
work, including direct outputs, scripts, manifests, side-effect logs, prior bundle,
and archive-specific documentation. Temporary artifacts that were deliberately
deleted are documented but cannot be embedded.
"""
from __future__ import annotations

import csv
import hashlib
import json
import mimetypes
import os
import platform
import shutil
import subprocess
import sys
import time
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

HOME = Path("/home/user")
OUTPUT = HOME / "Agent 9 edge.zip"
SIDECAR = HOME / "Agent 9 edge.zip.sha256"
STAGE = HOME / ".agent9_archive_staging"
ARCHIVE_ROOT_NAME = "Agent 9 edge"
ROOT = STAGE / ARCHIVE_ROOT_NAME
DOC = ROOT / "documentation"
PAYLOAD = ROOT / "payload" / "home" / "user"
BUILD_START = datetime.now(timezone.utc)

PROMPTS = [
    {
        "sequence": 1,
        "receipt_timestamp": "UNAVAILABLE: message timestamps are not exposed to the assistant",
        "text": """I’m setting up a long-running research + data pipeline that will involve mixed CPU work, network I/O, package installs, and some file processing. Before I commit any real code or data, I need a clear picture of what this environment can actually sustain.    
    
Please treat this as serious environment characterization work. Do the following thoroughly and keep notes as you go (you can use temporary files or just track things in memory, but be systematic).    
    
Required checks    
    
**1. Runtime &amp;amp;amp; Isolation**    
    
- Exact OS, kernel version, architecture, libc    
- Clear signals of containerization / VM / restricted sandbox (cgroup, /.dockerenv, mount info, process tree, capabilities, seccomp, etc.)    
- Current user, uid/gid, sudo/root status    
- Any obvious resource limits (ulimit, cgroup memory/cpu, process limits)    
    
**2. Tooling &amp;amp;amp; Language Runtimes**    
    
- Availability + versions of: python3, pip, node, npm, git, curl, wget, ffmpeg, docker, make, gcc/clang, jq, etc.    
- Which package managers work (apt, apk, yum, pip, conda, npm…) and whether they can actually install things    
- Can you install pure-python packages? System packages? Compile anything?    
    
**3. Filesystem &amp;amp;amp; Persistence**    
    
- Working directory, home, /tmp behavior    
- Free disk space and inode situation    
- Read-only mounts or protected paths    
- Simple write + read + delete test in a few locations    
- Whether files survive across “sessions” if possible to test    
    
**4. Network Characterization (important)**      
Run real measurements, not just “can I connect”:    
    
- DNS resolution speed    
- Latency + rough throughput to several endpoints (at minimum):    
  - [[[google.com](http://google.com)]([http://google.com)]([http://google.com](http://google.com)](http://google.com)]([http://google.com](http://google.com))) / 8.8.8.8    
  - [[[github.com](http://github.com)]([http://github.com)]([http://github.com](http://github.com)](http://github.com)]([http://github.com](http://github.com)))    
  - [[[pypi.org](http://pypi.org)]([http://pypi.org)]([http://pypi.org](http://pypi.org)](http://pypi.org)]([http://pypi.org](http://pypi.org)))    
  - [[[huggingface.co](http://huggingface.co)]([http://huggingface.co)]([http://huggingface.co](http://huggingface.co)](http://huggingface.co)]([http://huggingface.co](http://huggingface.co)))    
  - A large file download (e.g. a few MB from a reliable CDN or GitHub release)    
- Note any timeouts, blocks, captive portals, or asymmetric performance    
- Outbound ports / protocols that appear restricted    
    
**5. Performance Micro-benchmarks**      
Keep them short but timed accurately:    
    
- Pure Python CPU: sum(range(10**7)) and a slightly heavier loop or numpy if available    
- Disk sequential write + read of a 50–100 MB file    
- Small package install time (if pip works)    
- Any other operation that feels unusually fast or slow    
    
**6. Other observations**    
    
- Memory pressure behavior    
- Ability to run background processes or long-running tasks    
- Anything that breaks, hangs, or is surprisingly restricted    
- Any environment variables or injected configuration that looks sandbox-related    
    
Deliverable    
    
After finishing the checks, create a clean, well-structured Markdown file named something like environment_characterization[.md](http://chrome.md)that contains:    
    
- Executive summary (2–4 sentences)    
- Detailed sections matching the categories above    
- Tables for:    
  - Tool availability + versions    
  - Network latency / throughput results    
  - Benchmark timings    
- Raw notes or command outputs in collapsible sections or clearly marked appendix if useful    
- Clear statements of what is fast, what is slow, and hard limitations    
    
Be precise with numbers (include units and how you measured). Prefer real measured data over guesses.    
    
Start whenever you’re ready and produce the final Markdown report when done.""",
    },
    {
        "sequence": 2,
        "receipt_timestamp": "UNAVAILABLE: message timestamps are not exposed to the assistant",
        "text": """1. **Publish the raw** `.txt` **outputs, not just the reports.** (IF U PRODUCED THEM ALREADY, IF NOT , THEN SEE IF THEY ARE NEEDED &amp;amp; PRODUCE THEM  ) Your file 6 references `01_runtime.txt`, `09_net_matrix.txt` etc. Verbatim transcripts with no LLM summarisation layer are the primary evidence.  
2. **Ship the probe script** so a third party runs *your* script and diffs the output.  
3. **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of raw files.""",
    },
    {
        "sequence": 3,
        "receipt_timestamp": "UNAVAILABLE: message timestamps are not exposed to the assistant",
        "text": """now zip all of these files ?  &amp; save the zip as Agent 9 edge.zip , with all the files u have created , explaining, what the zip has, &amp; what every file does, &amp; when it was created , exact time &amp; date &amp; in sequence, which file was created when &amp; also with the exact prompts i gave u , each time, &amp; any imp metadata, that can be helpful""",
    },
]

# Source files generated by this work. Cache/log/marker files are included because
# they were side effects of the requested probes. The output archive cannot contain
# itself, and staging is excluded.
EXPLICIT_FILES = [
    HOME / "environment_characterization.md",
    HOME / ".environment_characterization_persistence_probe",
    HOME / ".sudo_as_admin_successful",
    HOME / "environment_evidence_20260904T142002Z-2576.zip",
    HOME / "environment_evidence_20260904T142002Z-2576.zip.sha256",
    HOME / "build_agent9_archive.py",
]
RECURSIVE_DIRS = [
    HOME / "envchar_work",
    HOME / "environment_evidence",
    HOME / ".npm",
]

DESCRIPTIONS = {
    "environment_characterization.md": "Human-readable environment characterization report; later amended to point to the reproducible evidence bundle.",
    ".environment_characterization_persistence_probe": "31-byte workspace sentinel retained to test persistence across later messages/sessions.",
    ".sudo_as_admin_successful": "Empty marker created as a side effect of successful sudo use in the characterization tests.",
    "environment_evidence_20260904T142002Z-2576.zip": "Earlier compact evidence bundle containing the canonical full probe run and its documentation.",
    "environment_evidence_20260904T142002Z-2576.zip.sha256": "External SHA-256 sidecar for the earlier compact evidence bundle.",
    "build_agent9_archive.py": "Self-contained builder used to create this comprehensive Agent 9 edge archive and its metadata.",
    "envchar_work/system_survey.txt": "Initial verbatim OS, identity, process-tree, mount, isolation, limits, and environment-name survey.",
    "envchar_work/resource_detail.txt": "Detailed current-cgroup limits, memory statistics, process security state, filesystems, and kernel knobs.",
    "envchar_work/isolation_extra.txt": "Namespace comparison, capability decoding, LSM state, KVM boot evidence, device checks, and time configuration.",
    "envchar_work/tool_inventory.py": "Python driver that probed installed command paths and versions.",
    "envchar_work/tool_inventory.tsv": "Machine-readable tool availability/version output produced by tool_inventory.py.",
    "envchar_work/runtime_packages.txt": "Python implementation, selected import/package versions, pip configuration locations, and npm global packages.",
    "envchar_work/pip_list.json": "Complete pip distribution list in JSON at the initial characterization time.",
    "envchar_work/pip_list_stderr.txt": "Captured stderr from pip-list generation; empty indicates no stderr.",
    "envchar_work/filesystem_survey.txt": "Filesystem capacities, inodes, mount metadata, read-only checks, and write/read/delete test transcript.",
    "envchar_work/persistence_recheck.txt": "Later same-VM recheck of workspace and /tmp persistence sentinels plus capacity/cleanup status.",
    "envchar_work/final_runtime_state.txt": "Final uptime and load snapshot from the initial characterization run.",
    "envchar_work/environment_variable_names.txt": "Sorted environment-variable names only; values intentionally omitted to avoid credential leakage.",
    "envchar_work/network_config_ping.txt": "Proxy-state, resolver, interfaces/routes, unprivileged ping failures, and plain-HTTP captive-portal checks.",
    "envchar_work/network_socket_tests.py": "Python driver for getaddrinfo, direct UDP DNS, and TCP port probes.",
    "envchar_work/dns_getaddrinfo.tsv": "Per-attempt system resolver timing and returned addresses for required hosts.",
    "envchar_work/dns_udp.tsv": "Per-attempt direct UDP DNS timing/results against 8.8.8.8.",
    "envchar_work/tcp_ports.tsv": "Per-attempt direct TCP-connect matrix for required endpoints and representative ports.",
    "envchar_work/curl_latency.tsv": "Three-run curl timing matrix for Google, GitHub, PyPI, Hugging Face, and 8.8.8.8 DoH.",
    "envchar_work/curl_latency_errors.txt": "Captured curl-latency stderr; empty indicates no errors in that probe.",
    "envchar_work/sudo_ping_ipv6.txt": "Root ICMP latency/loss results and failed IPv6 connectivity probes.",
    "envchar_work/large_downloads.tsv": "Measured large-object download sizes, timings, speeds, redirects, hashes, and curl status.",
    "envchar_work/large_download_notes.txt": "Object-selection and integrity/type validation notes for large downloads.",
    "envchar_work/large_download_errors.txt": "Captured stderr from large-download tests; empty indicates no stderr.",
    "envchar_work/google_download_retry.tsv": "Successful 5,000,000-byte Google Chrome package range-download timing after the first object returned 403.",
    "envchar_work/google_download_retry_headers.txt": "Selected raw HTTP headers proving the successful Google byte-range response.",
    "envchar_work/google_download_retry_error.txt": "Captured stderr from the successful Google retry; empty indicates no stderr.",
    "envchar_work/cloudflare_upload.tsv": "Measured 10,000,000-byte Cloudflare upload timing and average upload rate.",
    "envchar_work/cloudflare_upload_error.txt": "Captured Cloudflare-upload stderr; empty indicates no stderr.",
    "envchar_work/git_network_tests.py": "Python driver for Git HTTPS, native Git protocol, and GitHub SSH transport tests.",
    "envchar_work/git_network_results.json": "Structured status/timing results for Git transport probes.",
    "envchar_work/git_network_notes.txt": "Raw Git transport outputs, including the native-protocol timeout and expected SSH public-key denial.",
    "envchar_work/install_compile_tests.py": "Driver for isolated venv/pip, local npm, GCC, Make, and binary verification tests.",
    "envchar_work/install_compile_results.json": "Structured timings and statuses from pip/npm/native compilation tests.",
    "envchar_work/install_compile_notes.txt": "Raw outputs from pip/npm/native compilation and verification tests.",
    "envchar_work/apt_install_test.py": "Driver for apt update, real tree-package install/verification, purge, and cleanup check.",
    "envchar_work/apt_install_results.json": "Structured timings/statuses for apt update/install/verify/purge operations.",
    "envchar_work/apt_install_notes.txt": "Raw apt source configuration and apt operation transcript.",
    "envchar_work/microbenchmarks.py": "Driver for CPU, NumPy, buffered disk, cache-advised disk, and direct-I/O benchmarks.",
    "envchar_work/microbenchmark_results.json": "Structured timings/rates from the initial CPU and disk micro-benchmarks.",
    "envchar_work/microbenchmark_notes.txt": "Benchmark timestamp, affinity, load, file allocation, and maximum-RSS notes.",
    "envchar_work/memory_pressure_test.py": "Controlled 512 MiB allocation/page-touch test driver.",
    "envchar_work/memory_pressure_result.json": "Detailed cgroup memory snapshots and timings from the controlled allocation test.",
    "envchar_work/background_process_test.txt": "Record of the approximately one-minute managed heartbeat-process survival test.",
    "envchar_work/limit_adjustment_test.txt": "Proof that the open-file soft limit could be raised from 1,024 to 524,288.",
    "environment_evidence/README.md": "Index for the reproducible evidence package, raw files, manifests, verification commands, and diff instructions.",
    "environment_evidence/probe_environment.sh": "Canonical reusable full/quick environment probe script.",
}

RAW_DESCRIPTIONS = {
    "01_runtime.txt": "Direct runtime/identity/OS/libc/time/environment-name command transcript.",
    "02_isolation.txt": "Direct VM/container, cgroup, capabilities, namespaces, process tree, LSM, devices, and dmesg transcript.",
    "03_resources.txt": "Direct rlimit, CPU, memory, cgroup, pressure, descriptor-limit, and GPU transcript.",
    "04_tooling.txt": "Direct command-path and version probes for all requested tools and runtimes.",
    "05_packages.txt": "Direct pip package list, selected Python import metadata, npm globals, and apt source transcript.",
    "06_filesystem.txt": "Direct capacity/inode/mount/stat and user/root write-test transcript.",
    "07_dns.txt": "Direct resolver configuration, getaddrinfo, UDP DNS, and sudo ICMP transcript.",
    "08_http_latency.txt": "Direct proxy, captive-portal, and repeated curl HTTP/TLS/TTFB timing transcript.",
    "09_net_matrix.txt": "Direct TCP port matrix, Git HTTPS/native/SSH, and IPv6 transcript.",
    "10_throughput.txt": "Direct Google/GitHub/PyPI/Hugging Face/Cloudflare download and upload throughput transcript.",
    "11_benchmarks.txt": "Direct CPU, NumPy, sequential disk, warm-cache, and direct-I/O benchmark transcript.",
    "12_install_compile.txt": "Direct venv/pip/npm/GCC/Make/apt install and cleanup transcript.",
    "13_memory_process.txt": "Direct controlled-memory-allocation and local background heartbeat transcript.",
    "14_persistence.txt": "Direct run-sentinel, raw-file listing, and final capacity transcript.",
}

PHASES = {
    "system_survey.txt": (1, "2026-09-04T12:11:04.583543938Z"),
    "environment_variable_names.txt": (1, "2026-09-04T12:11:04.583543938Z"),
    "resource_detail.txt": (2, "2026-09-04T12:11:20.477149742Z"),
    "tool_inventory.py": (3, "2026-09-04T12:11:21Z (order known; exact original file birth lost on snapshot restore)"),
    "tool_inventory.tsv": (3, "2026-09-04T12:11:21Z (order known; exact original file birth lost on snapshot restore)"),
    "runtime_packages.txt": (4, "2026-09-04T12:11Z (order known; exact original time unavailable)"),
    "pip_list.json": (4, "2026-09-04T12:11Z (order known; exact original time unavailable)"),
    "pip_list_stderr.txt": (4, "2026-09-04T12:11Z (order known; exact original time unavailable)"),
    "filesystem_survey.txt": (5, "2026-09-04T12:12:06.937042370Z"),
    "network_config_ping.txt": (6, "2026-09-04T12:12:32.344273914Z"),
    "network_socket_tests.py": (6, "2026-09-04T12:12:32Z (parallel probe group)"),
    "dns_getaddrinfo.tsv": (6, "2026-09-04T12:12:32Z (parallel probe group)"),
    "dns_udp.tsv": (6, "2026-09-04T12:12:32Z (parallel probe group)"),
    "tcp_ports.tsv": (6, "2026-09-04T12:12:32Z (parallel probe group)"),
    "curl_latency.tsv": (7, "2026-09-04T12:13:02Z (parallel probe group)"),
    "curl_latency_errors.txt": (7, "2026-09-04T12:13:02Z (parallel probe group)"),
    "sudo_ping_ipv6.txt": (7, "2026-09-04T12:13:02.080782593Z"),
    "large_downloads.tsv": (8, "2026-09-04T12:13Z (order known; exact original time unavailable)"),
    "large_download_notes.txt": (8, "2026-09-04T12:13Z (order known; exact original time unavailable)"),
    "large_download_errors.txt": (8, "2026-09-04T12:13Z (order known; exact original time unavailable)"),
    "google_download_retry.tsv": (9, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "google_download_retry_headers.txt": (9, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "google_download_retry_error.txt": (9, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "install_compile_tests.py": (10, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "install_compile_results.json": (10, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "install_compile_notes.txt": (10, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "apt_install_test.py": (11, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "apt_install_results.json": (11, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "apt_install_notes.txt": (11, "2026-09-04T12:14Z (order known; exact original time unavailable)"),
    "microbenchmarks.py": (12, "2026-09-04T12:15:37Z"),
    "microbenchmark_results.json": (12, "2026-09-04T12:15:37Z"),
    "microbenchmark_notes.txt": (12, "2026-09-04T12:15:37Z"),
    "memory_pressure_test.py": (13, "2026-09-04T12:15Z (order known; exact original time unavailable)"),
    "memory_pressure_result.json": (13, "2026-09-04T12:15Z (order known; exact original time unavailable)"),
    "background_process_test.txt": (14, "2026-09-04T12:16Z (created after managed-process test)"),
    "isolation_extra.txt": (15, "2026-09-04T12:16:40.349253785Z"),
    "git_network_tests.py": (16, "2026-09-04T12:16Z (order known; exact original time unavailable)"),
    "git_network_results.json": (16, "2026-09-04T12:16Z (order known; exact original time unavailable)"),
    "git_network_notes.txt": (16, "2026-09-04T12:16Z (order known; exact original time unavailable)"),
    "persistence_recheck.txt": (17, "2026-09-04T12:17:27.258746175Z"),
    "limit_adjustment_test.txt": (18, "2026-09-04T12:17Z (order known; exact original time unavailable)"),
    "final_runtime_state.txt": (19, "2026-09-04T12:18:25.866920674Z"),
    "cloudflare_upload.tsv": (20, "2026-09-04T12:18Z (order known; exact original time unavailable)"),
    "cloudflare_upload_error.txt": (20, "2026-09-04T12:18Z (order known; exact original time unavailable)"),
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def run_text(args: list[str]) -> str:
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT).strip()
    except Exception as e:
        return f"UNAVAILABLE: {type(e).__name__}: {e}"


def stat_times(path: Path) -> dict[str, str]:
    return {
        "filesystem_birth_utc": run_text(["stat", "-c", "%w", str(path)]),
        "filesystem_mtime_utc": run_text(["stat", "-c", "%y", str(path)]),
        "filesystem_ctime_utc": run_text(["stat", "-c", "%z", str(path)]),
    }


def description_for(rel: str) -> str:
    if rel in DESCRIPTIONS:
        return DESCRIPTIONS[rel]
    name = Path(rel).name
    if "/raw/" in rel and name in RAW_DESCRIPTIONS:
        return RAW_DESCRIPTIONS[name]
    if rel.endswith("/manifest.txt"):
        return "Human-readable per-run verification manifest with timestamps, sandbox/template IDs, script hash, and raw-file hashes."
    if rel.endswith("/manifest.json"):
        return "Machine-readable JSON form of the per-run verification manifest."
    if rel.endswith("/SHA256SUMS"):
        return "GNU sha256sum-compatible checksums for all raw transcript files in that evidence run."
    if rel.endswith("/probe_environment.sh"):
        return "Exact probe script frozen beside its run so later canonical-script edits cannot change provenance."
    if rel.endswith("/persistence_sentinel.txt"):
        return "Per-run sentinel used by the final persistence probe."
    if rel.startswith(".npm/_logs/"):
        return "npm debug log created as a side effect of npm list/install probes; retained for complete provenance."
    if rel.startswith(".npm/_cacache/content-v2/"):
        return "Opaque npm content-addressed cache blob created by the is-number package-install probe."
    if rel.startswith(".npm/_cacache/index-v5/"):
        return "npm cache index entry created by the package-install probe."
    if rel == ".npm/_update-notifier-last-checked":
        return "Zero-byte npm update-notifier marker created as an npm side effect."
    return "Retained generated artifact; inspect the file contents and neighboring manifest/catalog entry for context."


def logical_time_and_phase(rel: str, path: Path) -> tuple[int, str, str]:
    name = path.name
    if rel.startswith("envchar_work/") and name in PHASES:
        phase, logical = PHASES[name]
        return phase, logical, "Original inode creation metadata was replaced when the workspace snapshot was restored; logical time/order comes from embedded timestamps and the recorded command sequence."
    if "/runs/20260904T142002Z-2576/" in rel:
        return 30, "2026-09-04T14:20:02.722079460Z to 2026-09-04T14:21:11.259311599Z", "Exact full-run interval from the hash-verified manifest; per-file current inode birth/mtime is also recorded."
    if rel == "environment_characterization.md":
        return 21, "Initial report produced after 2026-09-04T12:18 UTC; last amended 2026-09-04T14:22:21.433118737Z", "Initial exact birth was replaced by snapshot restore; current mtime records the evidence-link amendment."
    if rel.startswith("environment_evidence/"):
        return 29, "2026-09-04T14:15:19Z onward", "Current inode birth/mtime available; canonical full-run timestamps are in its manifest."
    if rel.startswith(".npm/"):
        return 28, stat_times(path)["filesystem_mtime_utc"], "Side-effect log/cache time from current filesystem metadata and, for logs, timestamped filename/content."
    if rel.startswith("environment_evidence_20260904"):
        return 31, stat_times(path)["filesystem_mtime_utc"], "Current inode birth/mtime available."
    if rel == "build_agent9_archive.py":
        return 40, stat_times(path)["filesystem_birth_utc"], "Current inode birth/mtime available."
    return 25, stat_times(path)["filesystem_mtime_utc"], "Best available current filesystem metadata; see notes for snapshot caveat."


def collect_sources() -> list[Path]:
    files: set[Path] = set()
    for p in EXPLICIT_FILES:
        if p.is_file():
            files.add(p)
    for d in RECURSIVE_DIRS:
        if d.is_dir():
            files.update(p for p in d.rglob("*") if p.is_file())
    files.discard(OUTPUT)
    files.discard(SIDECAR)
    return sorted(files, key=lambda p: str(p.relative_to(HOME)))


def write_prompts() -> None:
    lines = [
        "EXACT USER PROMPTS — VERBATIM AS RECEIVED BY THE ASSISTANT",
        "==========================================================",
        "",
        "The API does not expose user-message receipt timestamps to the assistant.",
        "Therefore no prompt timestamp is fabricated. Sequence is exact: 1, 2, 3.",
        "Text between each BEGIN/END marker is copied verbatim, including HTML entities,",
        "punctuation, capitalization, links, spacing, and line breaks visible to the assistant.",
        "",
    ]
    for p in PROMPTS:
        lines += [
            f"----- BEGIN USER PROMPT {p['sequence']} -----",
            p["text"],
            f"----- END USER PROMPT {p['sequence']} -----",
            "",
        ]
    (DOC / "01_USER_PROMPTS_EXACT.txt").write_text("\n".join(lines), encoding="utf-8")


def metadata(source_count: int) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "archive_schema": "agent9-edge-comprehensive-v1",
        "requested_archive_name": OUTPUT.name,
        "archive_pack_start_utc": BUILD_START.isoformat(timespec="microseconds").replace("+00:00", "Z"),
        "metadata_generated_utc": now.isoformat(timespec="microseconds").replace("+00:00", "Z"),
        "metadata_generated_ist": now.astimezone(ZoneInfo("Asia/Kolkata")).isoformat(timespec="microseconds"),
        "creator": "Helpful agent on Arena.ai Agent Mode",
        "sandbox_id": os.environ.get("E2B_SANDBOX_ID", "<unset>"),
        "template_id": os.environ.get("E2B_TEMPLATE_ID", "<unset>"),
        "hostname": platform.node(),
        "working_directory": str(HOME),
        "os_release": run_text(["bash", "-c", ". /etc/os-release; printf '%s' \"$PRETTY_NAME; full=$DEBIAN_VERSION_FULL\""]),
        "kernel": platform.release(),
        "architecture": platform.machine(),
        "libc": list(platform.libc_ver()),
        "python_used_to_build": sys.version,
        "source_file_count_before_archive_docs": source_count,
        "user_prompt_count": len(PROMPTS),
        "prompt_receipt_timestamps": "not exposed by API; intentionally not fabricated",
        "initial_characterization_window_utc": "2026-09-04T12:11:04.583543938Z to approximately 2026-09-04T12:18:25.866920674Z",
        "canonical_reproducible_run_utc": "2026-09-04T14:20:02.722079460Z to 2026-09-04T14:21:11.259311599Z",
        "canonical_run_tag": "20260904T142002Z-2576",
        "canonical_probe_sha256": "870774e553380dd881964cfb09cc74871349e8b3b3ac2d00a53214022568046b",
        "canonical_sandbox_id": "ixwcucmrk55t9qy240sxo",
        "canonical_template_id": "nlhz8vlwyupq845jsdg9",
        "archive_self_inclusion": "Impossible by definition; Agent 9 edge.zip is not nested inside itself.",
        "external_checksum_sidecar": str(SIDECAR),
        "sensitive_data_policy": "Environment-variable values were not bulk-dumped. Sandbox/template IDs were included because the user explicitly requested them.",
    }


def main() -> None:
    if STAGE.exists():
        shutil.rmtree(STAGE)
    DOC.mkdir(parents=True)
    PAYLOAD.mkdir(parents=True)

    source_paths = collect_sources()
    source_records = []
    for src in source_paths:
        rel = str(src.relative_to(HOME))
        dst = PAYLOAD / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        phase, logical, fidelity = logical_time_and_phase(rel, src)
        times = stat_times(src)
        source_records.append({
            "phase": phase,
            "source_rel": rel,
            "archive_path": str(dst.relative_to(STAGE)),
            "source_path": str(src),
            "size_bytes": src.stat().st_size,
            "sha256": sha256(src),
            "mime_guess": mimetypes.guess_type(src.name)[0] or run_text(["file", "-b", "--mime-type", str(src)]),
            **times,
            "logical_evidence_time_utc": logical,
            "timestamp_fidelity": fidelity,
            "description": description_for(rel),
        })

    write_prompts()
    meta = metadata(len(source_records))
    (DOC / "02_IMPORTANT_METADATA.json").write_text(json.dumps(meta, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    (DOC / "03_DELETED_OR_EPHEMERAL_ARTIFACTS.md").write_text("""# Deleted or ephemeral artifacts

The archive contains every persistent workspace file attributable to this task that was present when packaging began. It cannot include objects deliberately removed earlier:

- `/tmp` network payloads (`envchar_google*`, GitHub tarball, NumPy wheel, Hugging Face model, Cloudflare download/upload payloads).
- Temporary venv, npm project, C sources/binaries, and install trees under `/tmp/envchar_*` and `/tmp/envprobe-*`.
- The 100 MiB temporary disk benchmark files, deleted after each benchmark.
- Transient Python `__pycache__` bytecode generated while syntax-checking archive/probe builders; source scripts are included instead.
- The `/tmp` persistence sentinel, deleted after the same-VM recheck.
- The Debian `tree` package, installed to prove apt capability and then purged.
- Managed/local heartbeat processes, intentionally stopped or allowed to exit after verification.
- Two development-only evidence runs (`20260904T141557Z-1419` and `20260904T141758Z-1924`) removed after they exposed quoting defects in early script revisions. The corrected canonical full run is `20260904T142002Z-2576`.
- One inaccessible Google Cloud Storage response body (HTTP 403); the successful Google Chrome range retry is retained as metrics/headers rather than as a 5 MB payload.

System package-manager state outside `/home/user`, live process state, and other VM-global mutations are not portable files and cannot be represented faithfully in a ZIP. Their direct transcripts are included.
""", encoding="utf-8")

    (DOC / "04_CONVERSATION_AND_ARTIFACT_SEQUENCE.md").write_text("""# Conversation and artifact sequence

1. **User prompt 1** requested systematic runtime, isolation, tooling, filesystem, network, benchmark, memory, and background-process characterization plus a Markdown report. User-message receipt time was not exposed.
2. **Initial measurements** ran from `2026-09-04T12:11:04.583543938Z` through approximately `2026-09-04T12:18:25.866920674Z`. Ad-hoc scripts and direct outputs were retained in `envchar_work/`.
3. **Initial report** `environment_characterization.md` was produced after those checks. Workspace snapshot restoration later replaced the original inode birth times of older files; embedded timestamps remain the better origin evidence.
4. **User prompt 2** required raw `.txt` transcripts, a rerunnable probe, and per-run verification manifests.
5. The canonical script was developed and syntax/quick-tested. Two development runs were deleted after testing; they are disclosed in `03_DELETED_OR_EPHEMERAL_ARTIFACTS.md`.
6. **Canonical full evidence run** `20260904T142002Z-2576` ran exactly from `2026-09-04T14:20:02.722079460Z` to `2026-09-04T14:21:11.259311599Z`, producing 14 numbered raw transcripts plus script/manifests/checksums.
7. `environment_evidence/README.md` and the earlier compact evidence ZIP were created. The report was amended at `2026-09-04T14:22:21.433118737Z` to point to the raw evidence.
8. **User prompt 3** requested this comprehensive ZIP, exact prompts, per-file explanations, creation metadata, and chronology.
9. `build_agent9_archive.py` generated archive-specific documentation, copied all persistent generated files and side-effect logs, calculated per-file SHA-256 hashes, and packed `Agent 9 edge.zip`.

For exact per-file current filesystem times and the best recoverable logical origin time, use `05_FILE_CATALOG.csv` and `06_CREATION_TIMELINE.csv`.
""", encoding="utf-8")

    readme = f"""# Agent 9 edge — read this first

## What this ZIP contains

This is the comprehensive evidence package requested in user prompt 3. It contains:

- The final characterization report.
- All retained initial raw notes, TSV/JSON results, and ad-hoc probe scripts under `payload/home/user/envchar_work/`.
- The canonical rerunnable probe and its full run under `payload/home/user/environment_evidence/`.
- All 14 numbered, direct stdout/stderr `.txt` transcripts (`01_runtime.txt` through `14_persistence.txt`).
- Per-run manifests containing UTC timestamps, sandbox ID, template ID, raw-file SHA-256 hashes, and the frozen script hash.
- The earlier compact evidence ZIP and its checksum.
- Relevant persistent side effects: npm cache/log files, sudo-success marker, and persistence sentinel.
- The exact three user prompts as received by the assistant.
- A per-file catalog, creation timeline, important machine/provenance metadata, deleted-artifact disclosure, and archive-wide checksums.
- The exact Python builder used to assemble this archive.

## Important identity

- Requested filename: `{OUTPUT.name}`
- Packaging began (UTC): `{BUILD_START.isoformat(timespec='microseconds').replace('+00:00','Z')}`
- Packaging began (IST): `{BUILD_START.astimezone(ZoneInfo('Asia/Kolkata')).isoformat(timespec='microseconds')}`
- Sandbox ID: `{os.environ.get('E2B_SANDBOX_ID','<unset>')}`
- Template ID: `{os.environ.get('E2B_TEMPLATE_ID','<unset>')}`
- Canonical evidence run: `20260904T142002Z-2576`
- Canonical probe SHA-256: `870774e553380dd881964cfb09cc74871349e8b3b3ac2d00a53214022568046b`

## Directory layout

```text
Agent 9 edge/
├── 00_READ_ME_FIRST.md
├── documentation/
│   ├── 01_USER_PROMPTS_EXACT.txt
│   ├── 02_IMPORTANT_METADATA.json
│   ├── 03_DELETED_OR_EPHEMERAL_ARTIFACTS.md
│   ├── 04_CONVERSATION_AND_ARTIFACT_SEQUENCE.md
│   ├── 05_FILE_CATALOG.csv
│   ├── 06_CREATION_TIMELINE.csv
│   ├── 07_ARCHIVE_FILE_LIST.txt
│   └── SHA256SUMS.txt
└── payload/home/user/
    ├── environment_characterization.md
    ├── envchar_work/
    ├── environment_evidence/
    ├── .npm/
    ├── .environment_characterization_persistence_probe
    ├── .sudo_as_admin_successful
    ├── build_agent9_archive.py
    └── earlier compact evidence ZIP + sidecar
```

## What every file does

`documentation/05_FILE_CATALOG.csv` has one row for every copied payload file and every non-self-referential documentation file. Each row supplies source/archive path, purpose, size, SHA-256, current inode birth/mtime/ctime, logical evidence time, and timestamp-fidelity notes. `documentation/06_CREATION_TIMELINE.csv` presents the same records in recoverable chronological order.

Archive-control files are necessarily handled separately to avoid recursive self-description:

| File | Purpose |
|---|---|
| `05_FILE_CATALOG.csv` | Per-file purpose, path, size, hash, exact current filesystem times, best logical origin time, and timestamp-fidelity caveat. |
| `06_CREATION_TIMELINE.csv` | Catalog records reordered into the best recoverable creation sequence. |
| `07_ARCHIVE_FILE_LIST.txt` | Pre-pack member path, byte size, and SHA-256 listing. |
| `08_ARCHIVE_BUILD_LOG.txt` | Builder start time, source/catalog counts, staging/output paths, and pack method. |
| `SHA256SUMS.txt` | GNU-compatible checksum index for every other archive member; it cannot hash itself. |

These control files are all listed in the ZIP central directory with their stored modification times. Every control file except `SHA256SUMS.txt` is itself covered by `SHA256SUMS.txt`.

## Timestamp caveat

For files from the first characterization, workspace snapshot restoration reset current inode birth times to around 14:15 UTC. It is impossible to recover an exact original inode birth time after that reset. This archive does not fabricate one: it records the exact current inode times and separately records embedded command timestamps / known phase order, with an explicit fidelity field. Files from the canonical full run have exact run-manifest and current inode timing.

The API did not expose exact user-message receipt timestamps. Prompt order and text are exact; prompt times are explicitly marked unavailable.

## Verification

From the extracted `Agent 9 edge/` directory:

```bash
sha256sum -c documentation/SHA256SUMS.txt
```

`SHA256SUMS.txt` intentionally cannot hash itself. The outer ZIP's SHA-256 is written beside the archive as `Agent 9 edge.zip.sha256` after packaging.

## Self-inclusion limitation

A ZIP cannot contain its final own bytes or final own checksum without recursion. Therefore `Agent 9 edge.zip` and its external checksum sidecar are not members of themselves. The earlier compact evidence ZIP is included because it existed before this archive was assembled.
"""
    (ROOT / "00_READ_ME_FIRST.md").write_text(readme, encoding="utf-8")

    # Add archive documentation records that already exist; the catalog and later
    # control files are explained in README and checksum-covered after finalization.
    doc_records = []
    doc_desc = {
        "00_READ_ME_FIRST.md": "Primary archive guide: scope, layout, verification, timestamp fidelity, and self-inclusion caveat.",
        "documentation/01_USER_PROMPTS_EXACT.txt": "Exact user prompts in conversation order, with explicit notice that receipt timestamps were unavailable.",
        "documentation/02_IMPORTANT_METADATA.json": "Machine-readable archive, environment, provenance, run, and identifier metadata.",
        "documentation/03_DELETED_OR_EPHEMERAL_ARTIFACTS.md": "Disclosure of temporary/deleted files and nonportable state that cannot be included.",
        "documentation/04_CONVERSATION_AND_ARTIFACT_SEQUENCE.md": "Human-readable sequence linking prompts, measurement runs, reports, scripts, and this archive.",
    }
    for p in [ROOT / "00_READ_ME_FIRST.md", *sorted(DOC.glob("0[1-4]_*"))]:
        rel = str(p.relative_to(STAGE))
        t = stat_times(p)
        doc_records.append({
            "phase": 50,
            "source_rel": "[archive-generated]",
            "archive_path": rel,
            "source_path": "[generated while packaging]",
            "size_bytes": p.stat().st_size,
            "sha256": sha256(p),
            "mime_guess": mimetypes.guess_type(p.name)[0] or "text/plain",
            **t,
            "logical_evidence_time_utc": BUILD_START.isoformat(timespec="microseconds").replace("+00:00", "Z"),
            "timestamp_fidelity": "Exact current inode metadata from archive staging; generated during packaging.",
            "description": doc_desc[str(p.relative_to(ROOT))],
        })

    all_records = source_records + doc_records
    all_records.sort(key=lambda r: (int(r["phase"]), r["logical_evidence_time_utc"], r["archive_path"]))
    for i, rec in enumerate(all_records, 1):
        rec["sequence"] = i

    fieldnames = [
        "sequence", "phase", "archive_path", "source_path", "source_rel", "description",
        "size_bytes", "sha256", "mime_guess", "filesystem_birth_utc",
        "filesystem_mtime_utc", "filesystem_ctime_utc", "logical_evidence_time_utc",
        "timestamp_fidelity",
    ]
    with (DOC / "05_FILE_CATALOG.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader(); w.writerows(all_records)

    with (DOC / "06_CREATION_TIMELINE.csv").open("w", newline="", encoding="utf-8") as f:
        fields = ["sequence", "phase", "logical_evidence_time_utc", "filesystem_birth_utc", "filesystem_mtime_utc", "archive_path", "description", "timestamp_fidelity"]
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader(); w.writerows({k: r[k] for k in fields} for r in all_records)

    # Create a deterministic file list before the checksum file. It includes a
    # documented planned entry for SHA256SUMS itself.
    existing = sorted(p for p in ROOT.rglob("*") if p.is_file())
    list_lines = [
        "ARCHIVE MEMBER LIST BEFORE FINAL ZIP PACKING",
        f"generated_utc={datetime.now(timezone.utc).isoformat(timespec='microseconds').replace('+00:00','Z')}",
        "All paths are relative to the extracted Agent 9 edge directory.",
        "",
    ]
    for p in existing:
        list_lines.append(f"{p.relative_to(ROOT)}\t{p.stat().st_size} bytes\tsha256={sha256(p)}")
    list_lines.append("documentation/SHA256SUMS.txt\t[generated after this list]\t[self-excluded checksum index]")
    (DOC / "07_ARCHIVE_FILE_LIST.txt").write_text("\n".join(list_lines) + "\n", encoding="utf-8")

    build_log = [
        "Agent 9 edge archive build log",
        f"build_start_utc={BUILD_START.isoformat(timespec='microseconds').replace('+00:00','Z')}",
        f"source_file_count={len(source_records)}",
        f"catalog_record_count={len(all_records)}",
        f"staging_root={STAGE}",
        f"output={OUTPUT}",
        "copy_mode=shutil.copy2 (source mtimes preserved in staging)",
        "zip_mode=ZIP_DEFLATED with mirrored payload paths",
        "status_before_pack=all source copies and documentation generated",
    ]
    (DOC / "08_ARCHIVE_BUILD_LOG.txt").write_text("\n".join(build_log) + "\n", encoding="utf-8")

    # Archive-wide checksum index. Standard practice excludes only itself.
    checksum_path = DOC / "SHA256SUMS.txt"
    members_to_hash = sorted(p for p in ROOT.rglob("*") if p.is_file() and p != checksum_path)
    checksum_path.write_text("".join(f"{sha256(p)}  {p.relative_to(ROOT)}\n" for p in members_to_hash), encoding="utf-8")

    # Replace any previous requested archive only after staging is complete.
    if OUTPUT.exists(): OUTPUT.unlink()
    if SIDECAR.exists(): SIDECAR.unlink()
    pack_start = datetime.now(timezone.utc)
    with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9, allowZip64=True) as z:
        for p in sorted(x for x in ROOT.rglob("*") if x.is_file()):
            z.write(p, p.relative_to(STAGE))
        z.comment = (
            "Agent 9 edge comprehensive environment-characterization evidence archive; "
            f"packed UTC {pack_start.isoformat(timespec='microseconds').replace('+00:00','Z')}"
        ).encode("utf-8")

    digest = sha256(OUTPUT)
    sidecar_time = datetime.now(timezone.utc)
    # Keep the external .sha256 file strictly GNU sha256sum-compatible. Exact
    # pack time remains in the ZIP comment and internal metadata/build records.
    SIDECAR.write_text(f"{digest}  {OUTPUT.name}\n", encoding="utf-8")

    # Verify both container integrity and every internal checksum before cleanup.
    with zipfile.ZipFile(OUTPUT) as z:
        bad = z.testzip()
        if bad is not None:
            raise RuntimeError(f"ZIP CRC failure: {bad}")
    check = subprocess.run(["sha256sum", "-c", str(checksum_path)], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if check.returncode:
        raise RuntimeError("Internal SHA verification failed:\n" + check.stdout)

    archive_stat = stat_times(OUTPUT)
    print(json.dumps({
        "output": str(OUTPUT),
        "size_bytes": OUTPUT.stat().st_size,
        "sha256": digest,
        "sidecar": str(SIDECAR),
        "archive_pack_start_utc": pack_start.isoformat(timespec="microseconds").replace("+00:00", "Z"),
        "checksum_recorded_utc": sidecar_time.isoformat(timespec="microseconds").replace("+00:00", "Z"),
        "source_files": len(source_records),
        "zip_members": len(zipfile.ZipFile(OUTPUT).infolist()),
        "internal_checksum_entries": len(members_to_hash),
        "zip_crc_test": "pass",
        "internal_sha256_test": "pass",
        **archive_stat,
    }, indent=2))

    shutil.rmtree(STAGE)


if __name__ == "__main__":
    main()
