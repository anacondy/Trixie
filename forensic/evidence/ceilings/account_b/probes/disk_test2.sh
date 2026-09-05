#!/bin/bash
# Non-zero (/dev/urandom) write probes; write time and sync time measured separately (no bc; python math).
set -u
run() {
  local label="$1" path="$2" size_mb="$3" prefix="${4:-}"
  echo "=== $label: ${size_mb} MiB urandom -> $path (prefix:'$prefix') ==="
  $prefix sync 2>/dev/null || sync
  local t0 t1
  t0=$(date +%s%N)
  $prefix dd if=/dev/urandom of="$path" bs=1M count="$size_mb" 2>/tmp/dderr_$$
  local w_rc=$?
  t1=$(date +%s%N)
  grep -E 'records out|copied' /tmp/dderr_$$
  python3 - "$size_mb" "$t0" "$t1" <<'EOF'
import sys
mb=int(sys.argv[1]); w=(int(sys.argv[3])-int(sys.argv[2]))/1e9
print(f"dd (page-cache write) wall={w:.2f}s -> {mb/w:.0f} MiB/s write-call speed")
EOF
  if [ "$w_rc" != "0" ]; then
    echo "WRITE FAILED (rc=$w_rc)"; tail -1 /tmp/dderr_$$; $prefix rm -f "$path" 2>/dev/null; rm -f /tmp/dderr_$$; echo; return
  fi
  local sz=$($prefix stat -c %s "$path" 2>/dev/null || echo 0)
  echo "file size: $sz bytes"
  local s0 s1
  s0=$(date +%s%N); $prefix sync 2>/dev/null || sync; s1=$(date +%s%N)
  python3 - "$size_mb" "$t0" "$t1" "$s0" "$s1" <<'EOF'
import sys
mb=int(sys.argv[1])
w=(int(sys.argv[3])-int(sys.argv[2]))/1e9
s=(int(sys.argv[5])-int(sys.argv[4]))/1e9
print(f"sync (device flush) wall={s:.2f}s")
print(f"EFFECTIVE end-to-end: {w+s:.2f}s -> {mb/(w+s):.0f} MiB/s (urandom source + real disk)")
EOF
  $prefix rm -f "$path"; rm -f /tmp/dderr_$$
  echo "removed $path"; sync; echo
}

echo "##### ROOT FS (/): sudo dd, timed write + timed sync #####"
df -T / | tail -1
run "root-1G"  /probe_1g.bin  1024 "sudo -n"
run "root-5G"  /probe_5g.bin  5120 "sudo -n"
run "root-15G" /probe_15g.bin 15360 "sudo -n"
sudo -n rm -f /probe_*.bin
echo "##### ROOT PROBES COMPLETE #####"
df -h /
ls -la /probe_*.bin 2>&1 | head -2
