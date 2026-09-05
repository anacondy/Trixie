#!/usr/bin/env bash
# probe_environment.sh – collect raw environment characterisation data
# Output files are written to /home/user (or the directory where the script runs)
# Run as: bash probe_environment.sh

set -euo pipefail

OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$OUT_DIR"

########################################
# 1. Runtime & Isolation
########################################
{
  echo "=== uname -a ==="
  uname -a
  echo ""
  echo "=== /etc/os-release ==="
  cat /etc/os-release
  echo ""
  echo "=== capabilities (from /proc/1/status) ==="
  awk '/^CapEff:/ {print "CapEff:", $2}' /proc/1/status
  awk '/^CapPrm:/ {print "CapPrm:", $2}' /proc/1/status
  echo ""
  echo "=== ulimit -a ==="
  ulimit -a
  echo ""
  echo "=== user info ==="
  whoami
  id
  echo ""
  echo "=== /.dockerenv check ==="
  if [ -f /.dockerenv ]; then cat /.dockerenv; else echo "no_dockerenv"; fi
  echo ""
  echo "=== cgroup info ==="
  cat /proc/self/cgroup | head -n 5
} > "01_runtime.txt"

########################################
# 2. Tooling & Language Runtimes
########################################
{
  echo "=== python3 ==="
  python3 --version
  echo ""
  echo "=== pip ==="
  pip --version
  echo ""
  echo "=== node ==="
  node --version
  echo ""
  echo "=== npm ==="
  npm --version
  echo ""
  echo "=== git ==="
  git --version
  echo ""
  echo "=== curl (first line) ==="
  curl --version | head -n 1
  echo ""
  echo "=== wget (first line) ==="
  wget --version | head -n 1
  echo ""
  echo "=== make ==="
  make --version | head -n 1
  echo ""
  echo "=== gcc ==="
  gcc --version | head -n 1
  echo ""
  echo "=== jq ==="
  jq --version
  echo ""
  echo "=== ffmpeg ==="
  ffmpeg -version 2>/dev/null | head -n 1 || echo "ffmpeg not found"
  echo ""
  echo "=== clang ==="
  clang --version 2>/dev/null | head -n 1 || echo "clang not found"
  echo ""
  echo "=== docker ==="
  docker --version 2>/dev/null || echo "docker not found"
  echo ""
  echo "=== apt-get ==="
  apt-get --version | head -n 1
} > "02_tooling.txt"

########################################
# 3. Filesystem & Persistence
########################################
{
  echo "=== df -h ==="
  df -h /
  echo ""
  echo "=== df -i ==="
  df -i /
  echo ""
  echo "=== free -h ==="
  free -h
  echo ""
  echo "=== /proc/meminfo (first lines) ==="
  head -n 5 /proc/meminfo
} > "03_filesystem.txt"

########################################
# 4. Network Characterization
########################################
{
  echo "=== DNS resolution (Python) ==="
  python3 -c "
import time, socket
hosts = ['google.com','github.com','pypi.org','huggingface.co']
for h in hosts:
    start = time.time()
    socket.gethostbyname(h)
    dur = time.time() - start
    print(f'{h}: {dur:.4f} seconds')
"
  echo ""
  echo "=== HTTP latency (curl HEAD, total time) ==="
  for url in "https://www.google.com" "https://github.com" "https://pypi.org" "https://huggingface.co"; do
    total=$(curl -o /dev/null -s -w "%{time_total}" --head "$url")
    printf "%s: %.3f s\n" "$url" "$total"
  done
  echo ""
  echo "=== Download throughput ==="
  python3 -c "
import urllib.request, time, os
url = 'https://httpbin.org/bytes/1000000'
local = '/tmp/probe_1mb.bin'
start = time.time()
urllib.request.urlretrieve(url, local)
dur = time.time() - start
size = os.path.getsize(local)
speed = size / dur / 1_000_000
print(f'Downloaded {size} bytes in {dur:.3f}s, speed {speed:.3f} MB/s')
os.remove(local)
"
} > "04_network.txt"

########################################
# 5. Performance Micro-benchmarks
########################################
{
  echo "=== Pure Python CPU: sum(range(10**7)) ==="
  python3 -c "import time; start=time.time(); _=sum(range(10**7)); print(f'time: {time.time()-start:.3f} seconds')"
  echo ""
  echo "=== Pure Python loop: sum(i*i for i in range(10**7)) ==="
  python3 -c "import time; start=time.time(); _=sum(i*i for i in range(10**7)); print(f'time: {time.time()-start:.3f} seconds')"
  echo ""
  echo "=== NumPy sum ==="
  python3 -c "import numpy, time; arr=numpy.arange(10**7,dtype=numpy.int64); start=time.time(); _=arr.sum(); print(f'time: {time.time()-start:.3f} seconds')"
  echo ""
  echo "=== Disk sequential read/write 50 MB ==="
  python3 -c "
import time, os
filepath='/tmp/probe_50mb.bin'
size=50*1024*1024
# write
start=time.time()
with open(filepath,'wb') as f: f.write(b'\\x00'*size)
write_dur=time.time()-start
# read
read_start=time.time()
with open(filepath,'rb') as f: _=f.read()
read_dur=time.time()-read_start
print(f'Write duration: {write_dur:.3f} seconds, speed {size/write_dur/1e6:.2f} MB/s')
print(f'Read duration: {read_dur:.3f} seconds, speed {size/read_dur/1e6:.2f} MB/s'
)
os.remove(filepath)
"
  echo ""
  echo "=== Small package install (pip) ==="
  timeout 120 python3 -m pip install --no-deps faker 2>&1 | tail -n 5
} > "05_benchmarks.txt"

########################################
# 6. Other Observations
########################################
{
  echo "=== Memory ==="
  free -h
  head -n 3 /proc/meminfo
  echo ""
  echo "=== Environment variables (relevant) ==="
  env | grep -E 'E2B_|SHELL|PWD|HOME|PATH|USER|SHLVL|PS1'
  echo ""
  echo "=== ping test (expected failure) ==="
  ping -c 3 google.com 2>&1 || echo "ping blocked / missing capability"
  echo ""
  echo "=== dig not installed ==="
  which dig 2>/dev/null || echo "dig not found"
} > "06_other.txt"

########################################
# Manifest generation
########################################
{
  echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ) (Asia/Calcutta)"
  echo "Sandbox ID: ${E2B_SANDBOX_ID:-unknown}"
  echo "Template ID: ${E2B_TEMPLATE_ID:-unknown}"
  echo ""
  echo "SHA-256 checksums:"
  sha256sum 01_runtime.txt 02_tooling.txt 03_filesystem.txt 04_network.txt 05_benchmarks.txt 06_other.txt
} > "MANIFEST.txt"

echo "Probe complete. Raw files and MANIFEST.txt written to $(pwd)"