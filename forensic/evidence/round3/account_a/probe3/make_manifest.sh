#!/bin/bash
# make_manifest: SHA-256 per raw file + a hash-of-hashes. Zero LLM involvement: pure shell.
set -e
cd "$(dirname "$0")"
OUT=manifest3.txt
{
  echo "# probe3 manifest  generated_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# sandbox_id=$E2B_SANDBOX_ID template_id=$E2B_TEMPLATE_ID boot_id=$(cat /proc/sys/kernel/random/boot_id)"
  echo "# uptime_at_manifest=$(cut -d' ' -f1 /proc/uptime)s  host=$(hostname)"
  echo "# NOTE (C1): mtimes are NOT trusted; each raw file carries its own write-time in its content."
  echo "# format: sha256  bytes  content_write_time_utc  path"
  for f in $(ls [0-9][0-9]_*.txt d5/*.txt c1_probe.txt | sort); do
    h=$(sha256sum "$f" | cut -d' ' -f1)
    b=$(stat -c %s "$f")
    wt=$(grep -o -m1 -E '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z' "$f" | head -1)
    [ -z "$wt" ] && wt="no-embedded-time"
    echo "$h  $b  $wt  $f"
  done
} > "$OUT"
HASHES=$(awk '{print $1}' "$OUT" | grep -E '^[0-9a-f]{64}$')
HOH=$(printf '%s\n' "$HASHES" | sha256sum | cut -d' ' -f1)
{
  echo "# ---- hash-of-hashes ----"
  echo "# n_files=$(printf '%s\n' "$HASHES" | wc -l)"
  echo "# hash_of_hashes_sha256=$HOH"
  echo "# (computed as sha256 of the newline-joined per-file digests in listed order)"
} >> "$OUT"
cat "$OUT"
