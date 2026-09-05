#!/usr/bin/env python3
"""Write MANIFEST.txt + SHA256SUMS for a probe run."""
from __future__ import annotations

import hashlib
import os
import socket
import time
from pathlib import Path

PROBE_DIR = Path(__file__).resolve().parent
OUT = Path(os.environ.get("ENVCHAR_OUT", PROBE_DIR / "raw"))
STAMP = os.environ.get(
    "ENVCHAR_STAMP_UTC", time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
)

files = sorted(p for p in OUT.iterdir() if p.is_file() and not p.name.startswith("."))
rows = []
for p in files:
    h = hashlib.sha256()
    data = p.read_bytes()
    h.update(data)
    rows.append((p.name, p.stat().st_size, h.hexdigest(), data))

probe_sources = []
for name in ("probe.sh", "probe_bench.py", "make_manifest.py"):
    p = PROBE_DIR / name
    data = p.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    probe_sources.append((name, p.stat().st_size, digest))

sums_path = PROBE_DIR / "SHA256SUMS"
manifest_path = PROBE_DIR / "MANIFEST.txt"

with sums_path.open("w") as f:
    for name, size, digest, _ in rows:
        f.write(f"{digest}  raw/{name}\n")
    for name, size, digest in probe_sources:
        f.write(f"{digest}  {name}\n")

# Hash of SHA256SUMS itself
sums_digest = hashlib.sha256(sums_path.read_bytes()).hexdigest()

# Combined hash of all raw bytes in sorted filename order
combo = hashlib.sha256()
for name, size, digest, data in rows:
    combo.update(name.encode("utf-8") + b"\0")
    combo.update(digest.encode("ascii") + b"\0")
    combo.update(data)

lines = [
    "envchar verification manifest",
    "============================",
    f"generated_utc:     {STAMP}",
    f"manifest_utc:      {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}",
    f"hostname:          {socket.gethostname()}",
    f"sandbox_id:        {os.environ.get('E2B_SANDBOX_ID', 'unknown')}",
    f"template_id:       {os.environ.get('E2B_TEMPLATE_ID', 'unknown')}",
    f"e2b_sandbox_flag:  {os.environ.get('E2B_SANDBOX', 'unknown')}",
    f"probe_dir:         {PROBE_DIR}",
    f"raw_dir:           {OUT}",
    f"n_raw_files:       {len(rows)}",
    f"sha256sums_sha256: {sums_digest}",
    f"raw_combo_sha256:  {combo.hexdigest()}",
    "",
    "probe_sources:",
    f"{'name':28s} {'bytes':>10}  sha256",
]
for name, size, digest in probe_sources:
    lines.append(f"{name:28s} {size:10d}  {digest}")
lines.extend(
    [
        "",
        "raw_files:",
        f"{'name':28s} {'bytes':>10}  sha256",
    ]
)
for name, size, digest, _ in rows:
    lines.append(f"{name:28s} {size:10d}  {digest}")
lines.append("")
lines.append("Verify on a third-party copy:")
lines.append("  cd envchar && sha256sum -c SHA256SUMS")
lines.append("  ./probe.sh   # then diff -ru raw/ <their-raw>/")
lines.append("")
lines.append("Expected to CHANGE across runs (do not treat as failure):")
lines.append("  timestamps, sandbox_id, uptime, PIDs, RSS, latency/throughput,")
lines.append("  DNS addresses, cgroup memory.current/peak, dmesg, TLS notAfter.")
lines.append("Expected to be STABLE on the same template:")
lines.append("  OS/kernel/libc, vCPU count, memory.max, disk size, tool versions,")
lines.append("  IPv6 unreachable, ping-needs-sudo, /tmp=tmpfs, nofile soft=1024.")
lines.append("")

manifest_path.write_text("\n".join(lines))
print(f"[manifest] {manifest_path}")
print(f"[manifest] {sums_path}")
print(f"[manifest] combo={combo.hexdigest()}")
print(f"[manifest] n_files={len(rows)}")
