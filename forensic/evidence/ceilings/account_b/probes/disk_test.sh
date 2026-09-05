#!/bin/bash
# Non-zero data (/dev/urandom) write probes.
# dd writes to page cache (timed), then `sync` flushes to device (timed separately).
set -u
run() {
  local label="$1" path="$2" size_mb="$3"
  echo "=== $label: ${size_mb} MiB of /dev/urandom -> $path ==="
  sync
  local t0=$(date +%s.%N)
  dd if=/dev/urandom of="$path" bs=1M count="$size_mb" 2> /tmp/dd_err_$$
  local w_rc=$?
  local t1=$(date +%s.%N)
  local dd_wall=$(echo "$t1-$t0" | bc)
  grep -E 'records|bytes' /tmp/dd_err_$$ | tail -2
  echo "dd(pages only) wall=${dd_wall}s -> $(echo "scale=0; $size_mb/$dd_wall" | bc) MiB/s (cache-write speed)"
  if [ "$w_rc" != "0" ]; then
    echo "WRITE FAILED at this size (rc=$w_rc)"; tail -2 /tmp/dd_err_$$; rm -f "$path"; echo; return
  fi
  local sz=$(stat -c %s "$path" 2>/dev/null || echo 0)
  echo "file size: $sz bytes"
  local s0=$(date +%s.%N); sync; local s1=$(date +%s.%N)
  local sync_wall=$(echo "$s1-$s0" | bc)
  local total=$(echo "$dd_wall + $sync_wall" | bc)
  echo "sync(flush to device) wall=${sync_wall}s"
  echo "EFFECTIVE end-to-end: ${total}s -> $(echo "scale=1; $size_mb/$total" | bc) MiB/s (real disk speed)"
  rm -f "$path" /tmp/dd_err_$$
  echo "removed $path"; sync; echo
}

echo "##### Filesystem facts #####"
df -T /home/user / | sort -u
echo

echo "##### /home/user (ext4 /dev/vda) #####"
run "home-1G"  /home/user/probe_1g.bin  1024
run "home-5G"  /home/user/probe_5g.bin  5120
run "home-15G" /home/user/probe_15g.bin 15360

echo "##### / root fs via sudo (if available) #####"
if sudo -n true 2>/dev/null; then
  run "root-1G"  /probe_1g.bin  1024
  run "root-5G"  /probe_5g.bin  5120
  run "root-15G" /probe_15g.bin 15360
  sudo rm -f /probe_*.bin
else
  echo "no passwordless sudo; trying direct write to /:"
  ( echo test > /probe_write_test 2>&1 ) && echo "direct write OK" || echo "direct write to / DENIED (EACCES)"
fi

echo "##### DISK PROBES COMPLETE #####"
df -h /
