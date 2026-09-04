#!/usr/bin/env bash
# ============================================================================
# probe_environment.sh -- reproducible raw-logging probe for sandboxed Linux
# compute environments. Written and verified on an E2B Firecracker micro-VM
# (Debian 13, kernel 6.1.158+, 2 vCPU, 1.94 GiB RAM), 2026-09-04.
#
# What it does
# ------------
# Runs a fixed battery of read-only (plus, with --full) probes and writes
# VERBATIM command transcripts -- no summarisation -- into a timestamped
# run directory, then writes a SHA-256 verification manifest that records
# sandbox/template IDs, boot ID, kernel, user, flags and a hash of this very
# script, so a third party can run the same script and diff the outputs.
#
# Usage
# -----
#   bash probe_environment.sh                    # non-destructive probes
#   bash probe_environment.sh --full             # + apt installs + OOM ramp
#   bash probe_environment.sh --dir /somewhere   # override output directory
#
# Flags
# -----
#   --full      add: sudo apt-get INSTALL sqlite3 + ffmpeg, and the cgroup
#               OOM-kill ramp (deliberately allocates until the kernel kills
#               a process -- it kills only the allocating child, the script
#               and other processes survive).
#   --skip-apt  never touch apt, even with --full
#   --skip-oom  never run the OOM ramp, even with --full
#
# Layout of a run directory
# -------------------------
#   00_meta.txt                    run id, IDs, kernel, script hash
#   01_runtime.txt                 OS/kernel/arch/libc/CPU/memory overview
#   02_isolation.txt               container markers, cgroup, caps, seccomp
#   03_tools.txt                   tool availability + versions
#   04_limits.txt                  ulimit + cgroup limits + usage counters
#   05_filesystem.txt              mounts, capacity, inodes
#   06_fs_tests.txt                write/read/delete integrity tests
#   07_dns.txt                     resolver config + DNS timing
#   08_http_latency.txt            HTTPS connect/TLS/TTFB breakdown
#   09_net_matrix.txt              TCP-connect matrix (hosts x ports), ping,
#                                  IPv6, egress IP
#   10_download_throughput.txt     real downloads/parallel + upload test
#   11_cpu_bench.txt               Python/Node/C/numpy micro-benchmarks
#   12_disk_bench.txt              dd throughput + small-file rates
#   13_pkg_installs.txt            pip (fresh venv), npm, git clone, apt
#   14_memory_pressure.txt         OOM ramp (--full) + MemoryError probe
#   15_services_processes.txt      process tree, listening sockets, services,
#                                  background-process survival probe
#   16_envconfig.txt               environment variables, /.e2b, resolv.conf
#   MANIFEST.txt / MANIFEST.sha256 verification manifest (per run)
#
# Exit codes: 0 on completed run; 1 if the manifest self-check fails.
# ============================================================================
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

FULL=0; SKIP_APT=0; SKIP_OOM=0; OUTDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --full)      FULL=1 ;;
    --skip-apt)  SKIP_APT=1 ;;
    --skip-oom)  SKIP_OOM=1 ;;
    --dir)       shift; OUTDIR=${1:-} ;;
    -h|--help)   sed -n '2,90p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

T0=$(date -u +%Y%m%dT%H%M%SZ)
RUNID=run_${T0}
OUT=${OUTDIR:-$SCRIPT_DIR/raw/$RUNID}
mkdir -p "$OUT" || { echo "ERROR: cannot create output dir $OUT"; exit 1; }

PROBE_SHA=$(sha256sum "$0" | awk '{print $1}')

# scratch areas (cleaned up on exit)
DISK_SCRATCH=$(mktemp -d "$HOME/.probe_disk_XXXXXX")   # ext4 (under $HOME)
TMP_SCRATCH="/tmp/probe_tmp_$RANDOM$$"; mkdir -p "$TMP_SCRATCH" /var/tmp 2>/dev/null
[[ -d /var/tmp ]] || true
CGROUP_DIR="/sys/fs/cgroup/user"; [ -d "$CGROUP_DIR" ] || CGROUP_DIR="/sys/fs/cgroup"
trap 'rm -rf "$DISK_SCRATCH" "$TMP_SCRATCH"' EXIT

# ---------------------------------------------------------------------------
# helper: run a section function into its file with markers
# ---------------------------------------------------------------------------
sec() { # $1 = filename, $2 = function name
  local fn="$OUT/$1"
  : > "$fn"
  {
    echo "################################################################"
    echo "# SECTION: $1   (probe run $RUNID)"
    echo "# STARTED : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "################################################################"
    "$2"
    rc=$?
    echo
    echo "# section rc=$rc   FINISHED: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } >> "$fn" 2>&1
}

# ---------------------------------------------------------------------------
sec00_meta() {
  echo "runid          : $RUNID"
  echo "started_utc    : $T0"
  echo "hostname       : $(hostname)"
  echo "kernel         : $(uname -r)"
  echo "uname          : $(uname -a)"
  echo "arch           : $(uname -m) / bits=$(getconf LONG_BIT)"
  echo "os             : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
  echo "user/uid/gid   : $(id -un)/$(id -u)/$(id -g)"
  echo "e2b_sandbox_id : ${E2B_SANDBOX_ID:-unset}"
  echo "e2b_template_id: ${E2B_TEMPLATE_ID:-unset}"
  echo "boot_id        : $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unreadable)"
  echo "flags          : full=$FULL skip_apt=$SKIP_APT skip_oom=$SKIP_OOM"
  echo "probe_script   : $0"
  echo "probe_sha256   : $PROBE_SHA"
  echo "output_dir     : $OUT"
}

# ---------------------------------------------------------------------------
sec01_runtime() {
  echo "### uname -a"; uname -a
  echo; echo "### /etc/os-release"; cat /etc/os-release 2>/dev/null
  echo; echo "### architecture"; uname -m; getconf LONG_BIT
  echo; echo "### libc"; ldd --version 2>&1 | head -2
  echo; echo "### CPU"
  grep -m1 'model name' /proc/cpuinfo
  echo "nproc=$(nproc)"
  echo -n "SIMD/special flags: "; grep -m1 '^flags' /proc/cpuinfo | tr ' ' '\n' | grep -E 'avx512|avx2?|fma|ssse3|aes|sha_ni' | sort -u | tr '\n' ' '; echo
  echo; echo "### lscpu (selected)"
  if command -v lscpu >/dev/null; then
    lscpu | grep -E 'Architecture|CPU\(s\)|Model name|Hypervisor|Virtualization|Thread|Core|Socket|NUMA node0 CPU'
  else echo "lscpu missing"; fi
  echo; echo "### hypervisor flag"; grep -m1 -i hypervisor /proc/cpuinfo
  echo; echo "### clocksource"; cat /sys/devices/system/clocksource/clocksource0/current_clocksource 2>/dev/null
  echo; echo "### memory"; free -m; grep -E '^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree)' /proc/meminfo
  echo; echo "### uptime / date"; uptime; date -u
}

# ---------------------------------------------------------------------------
sec02_isolation() {
  echo "### PID 1 and process tree head"
  cat /proc/1/comm 2>/dev/null
  ps -eo pid,ppid,comm,args 2>/dev/null | head -12
  echo; echo "### container marker files"
  for f in /.dockerenv /run/.containerenv /.flatpak-info; do
    [ -e "$f" ] && echo "$f EXISTS" || echo "$f absent"
  done
  echo; echo "### cgroup"
  stat -fc %T /sys/fs/cgroup 2>/dev/null
  echo "self: $(cat /proc/self/cgroup)"
  echo "pid1: $(cat /proc/1/cgroup)"
  echo; echo "### namespace ids"
  for n in user mnt pid cgroup; do readlink /proc/self/ns/$n 2>/dev/null; done
  echo; echo "### uid/gid maps"; cat /proc/self/uid_map /proc/self/gid_map 2>/dev/null
  echo; echo "### capabilities (effective process)"
  grep -E 'Cap(Inh|Prm|Eff|Bnd|Amb)' /proc/self/status
  echo; echo "### seccomp / no_new_privs"
  grep -iE 'seccomp|no_new_privs' /proc/self/status
  echo; echo "### virtualization detect"
  if command -v systemd-detect-virt >/dev/null; then systemd-detect-virt; else echo "n/a"; fi
  echo; echo "### boot_id"; cat /proc/sys/kernel/random/boot_id 2>/dev/null
  echo; echo "### sudo (passwordless non-interactive?)"
  command -v sudo || echo "sudo missing"
  sudo -n true 2>&1; echo "sudo -n true rc=$?"
  echo; echo "### write probes"
  touch /sys/fs/cgroup/probe_write_test 2>&1
  touch /proc/sys/kernel/hostname 2>&1
}

# ---------------------------------------------------------------------------
sec03_tools() {
  echo "### availability + version of common tools (path per tool, first version line)"
  for t in python3 python pip3 pip node npm npx bun deno git curl wget ffmpeg \
           docker podman make gcc cc clang g++ jq tar gzip xz zstd rsync ssh \
           nc ncat socat dig nslookup openssl perl ruby php go rustc cargo java \
           javac cmake ninja sqlite3 zip unzip htop tmux screen systemctl \
           apt-get dpkg apk yum dnf zypper conda mamba gh timeout lsof strace \
           tcpdump iperf3 aria2c; do
    p=$(command -v "$t" 2>/dev/null)
    if [ -n "$p" ]; then
      out=$(timeout 6 "$t" --version 2>&1 | head -1)
      printf '%-10s | %-40s | %s\n' "$t" "$p" "${out:-<no version output>}"
    else
      printf '%-10s | %-40s | MISSING\n' "$t" "-" ""
    fi
  done
  echo; echo "### python package inventory (pip list count + key packages)"
  if command -v pip >/dev/null; then
    echo "total pip packages: $(pip list 2>/dev/null | tail -n +3 | wc -l)"
    python3 - <<'PY'
import importlib.metadata as md
wanted = ["numpy","pandas","scipy","matplotlib","seaborn","plotly","spacy","nltk",
          "networkx","sympy","openpyxl","psutil","pydantic","requests","aiohttp",
          "httpx","ipython","pytest","tqdm","jinja2","torch","transformers",
          "datasets","pyarrow","polars","duckdb","fastapi","flask","django",
          "sklearn","statsmodels","jupyterlab","black","ruff","mypy","boto3"]
for p in sorted(wanted):
    try: print(f"  {p}: {md.version(p)}")
    except Exception: print(f"  {p}: -")
PY
  else echo "pip missing"; fi
}

# ---------------------------------------------------------------------------
sec04_limits() {
  echo "### ulimit -a"; ulimit -a
  echo; echo "### /proc/self/limits"; cat /proc/self/limits
  echo; echo "### cgroup limits (dir: $CGROUP_DIR)"
  for f in memory.max memory.current memory.swap.max cpu.max cpu.weight cpuset.cpus.effective pids.max pids.current; do
    if [ -e "$CGROUP_DIR/$f" ]; then echo "$f = $(cat "$CGROUP_DIR/$f" 2>&1)"; else echo "$f = (absent)"; fi
  done
  echo; echo "### cpu.stat"; cat "$CGROUP_DIR/cpu.stat" 2>&1
  echo; echo "### memory.events"; cat "$CGROUP_DIR/memory.events" 2>&1
  echo; echo "### memory.stat (selected)"; grep -E '^(anon|file|slab|inactive_file|active_file|pgfault|pgmajfault|oom)' "$CGROUP_DIR/memory.stat" 2>&1
}

# ---------------------------------------------------------------------------
sec05_filesystem() {
  echo "### df -hT"; df -hT 2>/dev/null
  echo; echo "### df -i (inodes)"; df -i 2>/dev/null
  echo; echo "### mounts"; mount 2>/dev/null
  echo; echo "### tmp/shm/run details"
  ls -ld /tmp /var/tmp /dev/shm /run 2>&1
  df -T /tmp /var/tmp /dev/shm | tail -4
  echo; echo "### filesystem types of key paths"
  for d in "$HOME" /tmp /var/tmp /dev/shm /etc/ssl/certs; do
    echo "$d -> $(stat -f -c '%T %b blocksize' "$d" 2>/dev/null)"
  done
  echo; echo "### workspace dirs"
  ls -ld /workspace "$HOME" 2>&1
  echo; echo "### root listing"; ls -la / 2>&1 | head -25
}

# ---------------------------------------------------------------------------
sec06_fs_tests() {
  echo "### 1MiB write+read+delete integrity tests (sha1 compare) at $(date -u +%H:%M:%S)"
  for d in "$DISK_SCRATCH" "$TMP_SCRATCH" /var/tmp /dev/shm "$HOME"; do
    f="$d/wtest.$$.bin"
    if dd if=/dev/urandom of="$f" bs=1024 count=1024 2>/dev/null && [ -f "$f" ]; then
      s1=$(stat -c%s "$f"); h1=$(sha1sum "$f" 2>/dev/null | cut -d' ' -f1)
      h2=$(sha1sum < "$f" 2>/dev/null | cut -d' ' -f1)
      rm -f "$f"
      echo "$d : OK ($s1 bytes, sha1=$h1 reread=$h2 $([ "$h1" = "$h2" ] && echo MATCH || echo MISMATCH))"
    else
      echo "$d : write test FAILED"; rm -f "$f"
    fi
  done
  echo; echo "### 200MB write to tmpfs /tmp with fdatasync"
  dd if=/dev/zero of="$TMP_SCRATCH/big.bin" bs=1M count=200 conv=fdatasync 2>&1 | tail -1
  ls -l "$TMP_SCRATCH/big.bin" | awk '{print "size:", $5}'
  rm -f "$TMP_SCRATCH/big.bin"
  echo; echo "### special (unicode/spaces) filename"
  : > "$TMP_SCRATCH/weird \"name\" 日本語.txt" && echo "OK created" ; rm -f "$TMP_SCRATCH/weird \"name\" 日本語.txt"
  echo; echo "### read-only probes"
  touch /proc/version 2>&1; touch /sys/kernel/config 2>&1
}

# ---------------------------------------------------------------------------
sec07_dns() {
  echo "### /etc/resolv.conf"; cat /etc/resolv.conf
  echo; echo "### python socket.gethostbyname timing (5 samples/host)"
  python3 - <<'PY'
import socket, time, statistics
hosts = ["google.com","github.com","pypi.org","huggingface.co",
         "files.pythonhosted.org","objects.githubusercontent.com",
         "registry.npmjs.org","api.ipify.org"]
print(f"{'host':30s} {'resolved':>16s} {'min':>7s} {'med':>7s} {'max':>7s}  [ms]")
for h in hosts:
    times=[]; last=None
    for _ in range(5):
        t0=time.perf_counter()
        try:
            last=socket.gethostbyname(h); times.append((time.perf_counter()-t0)*1000)
        except Exception as e:
            print(f"{h:30s} FAILED: {e}"); break
    if times:
        print(f"{h:30s} {last:>16s} {min(times):7.1f} {statistics.median(times):7.1f} {max(times):7.1f}")
PY
  echo; echo "### raw UDP:53 to public resolvers (hand-built query)"
  python3 - <<'PY'
import socket, struct, time
def q(ip, name="google.com", timeout=3):
    pkt = struct.pack(">HHHHHH", 0x1234, 0x0100, 1,0,0,0)
    for part in name.split("."):
        pkt += bytes([len(part)]) + part.encode()
    pkt += b"\x00" + struct.pack(">HH", 1, 1)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(timeout)
    t0=time.perf_counter()
    try:
        s.sendto(pkt, (ip, 53)); data,_=s.recvfrom(512)
        return f"{(time.perf_counter()-t0)*1000:.1f} ms, {len(data)} bytes"
    except Exception as e:
        return f"FAIL: {e}"
for ip in ["8.8.8.8","1.1.1.1","9.9.9.9"]:
    print(f"UDP:53 {ip} -> {q(ip)}")
PY
}

# ---------------------------------------------------------------------------
sec08_http_latency() {
  fmt='http=%{http_code} dns=%{time_namelookup} conn=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total} speed=%{speed_download}B/s\n'
  echo "### HTTPS latency breakdown (curl -w, 2 runs each)"
  for u in https://www.google.com/ https://github.com/ https://pypi.org/ https://huggingface.co/; do
    echo "--- $u"
    curl -s -o /dev/null --max-time 25 -w "$fmt" "$u" 2>&1 | tail -1
    curl -s -o /dev/null --max-time 25 -w "$fmt" "$u" 2>&1 | tail -1
  done
  echo; echo "### plain HTTP (port 80)"
  for u in http://www.google.com/ http://github.com/ http://pypi.org/ http://huggingface.co/; do
    echo "--- $u"
    curl -s -o /dev/null --max-time 15 -w "$fmt" "$u" 2>&1 | tail -1
  done
  echo; echo "### redirect behavior"
  curl -s -o /dev/null --max-time 15 -w "$fmt" http://google.com/ 2>&1 | tail -1
}

# ---------------------------------------------------------------------------
sec09_net_matrix() {
  echo "### TCP connect matrix (ms to establish; 6s timeout per probe)"
  echo "host:port -> connect RTT"
  for hp in google.com:443 github.com:22 github.com:80 github.com:443 github.com:9418 \
            raw.githubusercontent.com:443 api.github.com:443 codeload.github.com:443 \
            pypi.org:443 pypi.org:80 files.pythonhosted.org:443 huggingface.co:443 \
            registry.npmjs.org:443 8.8.8.8:53 8.8.8.8:443 1.1.1.1:53 \
            192.0.2.1:80 192.0.2.1:443 192.0.2.1:4444; do
    h=${hp%:*}; p=${hp#*:}
    r=$(timeout 8 python3 -c "
import socket, sys, time
s = socket.socket(); s.settimeout(6)
t0 = time.perf_counter()
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
    print(f'{(time.perf_counter()-t0)*1000:.1f} ms')
except Exception as e:
    print(type(e).__name__ + ': ' + str(e))
finally:
    s.close()" "$h" "$p" 2>&1 | tail -1)
    echo "$hp -> ${r:-(timeout/no-output)}"
  done
  echo; echo "### ICMP (may need root/CAP_NET_RAW)"
  timeout 8 ping -c 2 -W 2 8.8.8.8 2>&1 | head -3
  if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    echo "--- with sudo:"; sudo -n timeout 8 ping -c 2 -W 2 8.8.8.8 2>&1 | tail -2
  fi
  echo; echo "### IPv6"
  timeout 8 curl -6 -s -o /dev/null -w 'v6 https://www.google.com http=%{http_code} total=%{time_total}s\n' https://www.google.com 2>&1 | tail -1
  echo; echo "### interface / MTU / routes / egress IP"
  ip addr 2>/dev/null | grep -E '^[0-9]+:|inet ' | head -10
  ip route 2>/dev/null | head -4
  echo -n "egress ip: "; curl -s --max-time 12 https://api.ipify.org 2>/dev/null || echo "unreachable"
  echo; echo "### egress geo (ipinfo.io)"
  curl -s --max-time 12 https://ipinfo.io/json 2>/dev/null | head -12 || echo "unreachable"
}

# ---------------------------------------------------------------------------
sec10_download_throughput() {
  echo "### locating a real PyPI wheel (numpy 2.3.5, cp313 manylinux x86_64) via JSON API"
  WHEEL=$(python3 - <<'PY'
import json, urllib.request, sys
try:
    d = json.load(urllib.request.urlopen("https://pypi.org/pypi/numpy/2.3.5/json", timeout=20))
    us = [u["url"] for u in d["urls"] if "cp313" in u["filename"] and "manylinux" in u["filename"] and "x86_64" in u["filename"]]
    print(us[0] if us else "")
except Exception as e:
    print("", file=sys.stderr)
PY
)
  if [ -n "$WHEEL" ]; then echo "wheel: $WHEEL"; else echo "wheel lookup FAILED - skipping pypi download"; fi
  dl() {
    echo "--- $2 ($1)"
    curl -sL -o /dev/null --max-time 120 -w 'http=%{http_code} bytes=%{size_download} ttfb=%{time_starttransfer}s total=%{time_total}s avg=%{speed_download}B/s\n' "$1" 2>&1 | tail -1
  }
  [ -n "$WHEEL" ] && dl "$WHEEL" "PyPI/Fastly numpy wheel (~17MB)"
  dl "https://github.com/prometheus/prometheus/releases/download/v3.2.1/prometheus-3.2.1.linux-amd64.tar.gz" "GitHub release asset (~114MB)"
  dl "https://codeload.github.com/python/cpython/tar.gz/refs/tags/v3.13.5" "codeload.github.com cpython tarball (~30MB, expected slow)"
  echo "--- HuggingFace gpt2 pytorch_model.bin, 50MB range request"
  curl -sL -o /dev/null --max-time 120 -r 0-52428799 -w 'http=%{http_code} bytes=%{size_download} ttfb=%{time_starttransfer}s total=%{time_total}s avg=%{speed_download}B/s\n' "https://huggingface.co/gpt2/resolve/main/pytorch_model.bin" 2>&1 | tail -1
  echo; echo "### parallel: 4 x 10MB ranges from the wheel host"
  if [ -n "$WHEEL" ]; then
    T0=$(date +%s.%N)
    for i in 0 1 2 3; do curl -sL -o /dev/null --max-time 60 -r $((i*10485760))-$((i*10485760+10485759)) "$WHEEL" & done
    wait
    T1=$(date +%s.%N)
    echo "4x10MB parallel wall=$(python3 -c "print(f'{$T1-$T0:.2f}')")s -> ~40MB/(wall) MB/s"
  fi
  echo; echo "### parallel: 4 x codeload tarball (~30MB each, per-connection limit check)"
  T0=$(date +%s.%N)
  for i in 1 2 3 4; do curl -s -o /dev/null --max-time 120 "https://codeload.github.com/python/cpython/tar.gz/refs/tags/v3.12.${i}" & done
  wait
  T1=$(date +%s.%N)
  echo "4x codeload wall=$(python3 -c "print(f'{$T1-$T0:.2f}')")s"
  echo; echo "### uploads"
  head -c 10485760 /dev/urandom > "$TMP_SCRATCH/up.bin"
  curl -s -o /dev/null --max-time 60 -H "Content-Type: application/octet-stream" -w 'cloudflare __up 10MB: http=%{http_code} sent=%{size_upload} total=%{time_total}s upload_speed=%{speed_upload}B/s\n' --data-binary @"$TMP_SCRATCH/up.bin" "https://speed.cloudflare.com/__up?bytes=10485760" 2>&1 | tail -1
  head -c 5242880 /dev/urandom > "$TMP_SCRATCH/up2.bin"
  curl -s -o /dev/null --max-time 60 -w 'httpbin POST 5MB: http=%{http_code} sent=%{size_upload} total=%{time_total}s upload_speed=%{speed_upload}B/s\n' --data-binary @"$TMP_SCRATCH/up2.bin" "https://httpbin.org/post" 2>&1 | tail -1
  rm -f "$TMP_SCRATCH/up.bin" "$TMP_SCRATCH/up2.bin"
}

# ---------------------------------------------------------------------------
sec11_cpu_bench() {
  echo "### Python 3.x CPU micro-benchmarks"
  python3 - <<'PY'
import time, sys
print("python", sys.version.split()[0])
t0=time.perf_counter(); s=sum(range(10**7)); t1=time.perf_counter()
print(f"sum(range(10**7))          : {t1-t0:.4f}s  ({10**7/(t1-t0)/1e6:.1f} M elem/s, result={s})")
t0=time.perf_counter(); s=sum(i*i for i in range(10**6)); t1=time.perf_counter()
print(f"genexpr sum(i*i 1e6)       : {t1-t0:.4f}s")
t0=time.perf_counter()
for i in range(2_000_000): pass
t1=time.perf_counter()
print(f"empty for-loop 2e6 iters  : {t1-t0:.4f}s")
t0=time.perf_counter()
for i in range(1_000_000): pass
t1=time.perf_counter()
try:
    t0=time.perf_counter(); acc=0.0
    for i in range(2_000_000): acc+=math.sin(i)*0.5
    t1=time.perf_counter()
    print(f"2e6 math.sin loop          : {t1-t0:.4f}s")
except Exception: print("math missing?")
from multiprocessing import Pool
def work(n): return sum(range(n))
t0=time.perf_counter()
with Pool(2) as p: r=p.map(work,[10**7,10**7])
t1=time.perf_counter()
print(f"2x sum(range(1e7)) 2 procs : {t1-t0:.4f}s wall")
PY
  echo; echo "### Node (if present)"
  if command -v node >/dev/null; then
    node --version
    node -e "let t=process.hrtime.bigint(); let s=0; for(let i=0;i<1e7;i++) s+=i; let d=Number(process.hrtime.bigint()-t)/1e9; console.log('node sum(1e7) loop:', d.toFixed(4)+'s', (1e7/d/1e6).toFixed(1)+'M ops/s')"
  else echo "node missing"; fi
  echo; echo "### gcc (if present)"
  if command -v gcc >/dev/null; then
    cat > "$TMP_SCRATCH/bench.c" <<'CEOF'
#include <stdio.h>
#include <stdint.h>
int main(void){
  uint64_t x=0; for(uint64_t i=0;i<1000000000ULL;i++) x+=i;
  double y=0; for(uint64_t i=1;i<300000000ULL;i++) y+=1.0/i;
  printf("%llu %.10f\n", x, y); return 0;
}
CEOF
    python3 - "$TMP_SCRATCH/bench.c" <<'PY'
import subprocess, sys, time
src = sys.argv[1]
for opts in (["-O0"], ["-O2"], ["-O3"], ["-O3","-march=native"]):
    t0=time.perf_counter()
    subprocess.run(["gcc"]+opts+["-o","/tmp/probe_bench","-x","c",src],check=True)
    tc=time.perf_counter()-t0
    t0=time.perf_counter()
    subprocess.run(["/tmp/probe_bench"],check=True,capture_output=True)
    tr=time.perf_counter()-t0
    print(f"gcc {' '.join(opts):15s}: compile {tc:.3f}s | 1e9 adds + 3e8 fp divs: {tr:.3f}s")
PY
  else echo "gcc missing"; fi
  echo; echo "### numpy (if present)"
  python3 - <<'PY'
try:
    import numpy as np, time
    print("numpy", np.__version__)
    a=np.random.rand(1000,1000); b=np.random.rand(1000,1000)
    t0=time.perf_counter(); c=np.matmul(a,b); t1=time.perf_counter()
    print(f"matmul 1000x1000 float64  : {t1-t0:.4f}s ({1000**3/(t1-t0)/1e9:.1f} GFLOP/s naive)")
    v=np.random.rand(10_000_000)
    t0=time.perf_counter(); s=v.sum(); t1=time.perf_counter()
    print(f"sum of 1e7 floats         : {t1-t0:.4f}s ({1e7/(t1-t0)/1e9:.2f} G elem/s)")
except ImportError:
    print("numpy not installed")
PY
}

# ---------------------------------------------------------------------------
sec12_disk_bench() {
  echo "### dd throughput, 200MB files (fs report: $(stat -f -c '%T' "$DISK_SCRATCH") for EXT4 dir)"
  for loc in "$DISK_SCRATCH" "$TMP_SCRATCH"; do
    echo "--- $loc  (fs: $(stat -f -c '%T' "$loc"))"
    echo -n "  write 200MB (fdatasync):  "; dd if=/dev/zero of="$loc/dd.img" bs=1M count=200 conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
    sync
    echo -n "  read 200MB (page cache):  "; dd if="$loc/dd.img" of=/dev/null bs=1M 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
    echo -n "  read 200MB (O_DIRECT):    "; dd if="$loc/dd.img" of=/dev/null bs=1M iflag=direct 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
    echo -n "  write 200MB (O_DIRECT):   "; dd if=/dev/zero of="$loc/dd2.img" bs=1M count=200 oflag=direct conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
    rm -f "$loc/dd.img" "$loc/dd2.img"
  done
  echo; echo "### small-file create/read/delete rates (N=20000)"
  for d in "$DISK_SCRATCH" "$TMP_SCRATCH"; do
    python3 - "$d" <<'PY'
import os, sys, time
d = sys.argv[1]; N = 20000
os.makedirs(d + "/many", exist_ok=True)
t0=time.perf_counter()
for i in range(N):
    with open(f"{d}/many/f{i}","w") as f: f.write(str(i))
t1=time.perf_counter()
print(f"{d}: create+write {N} files: {t1-t0:.2f}s ({N/(t1-t0):.0f} files/s)")
t0=time.perf_counter()
for i in range(N):
    with open(f"{d}/many/f{i}") as f: f.read()
t1=time.perf_counter()
print(f"{d}: read {N} files         : {t1-t0:.2f}s ({N/(t1-t0):.0f} files/s)")
t0=time.perf_counter()
for i in range(N): os.unlink(f"{d}/many/f{i}")
t1=time.perf_counter()
print(f"{d}: delete {N} files       : {t1-t0:.2f}s ({N/(t1-t0):.0f} files/s)")
os.rmdir(d + "/many")
PY
  done
  echo; echo "### inode/space state after test"; df -i "$HOME" | tail -1; df -h "$HOME" | tail -1
}

# ---------------------------------------------------------------------------
sec13_pkg_installs() {
  echo "### pip: index reachability"
  if command -v pip >/dev/null; then
    timeout 30 pip index versions idna 2>&1 | head -3
  else echo "pip missing"; fi
  echo; echo "### pip: fresh-venv install of idna (purge python, tiny) -- timed"
  if command -v python3 >/dev/null; then
    python3 -m venv "$TMP_SCRATCH/venv1" >/dev/null 2>&1
    { time timeout 120 "$TMP_SCRATCH/venv1/bin/pip" install -q --no-cache-dir idna; } 2>&1 | tail -3
    "$TMP_SCRATCH/venv1/bin/python" -c "import idna; print('idna', idna.__version__)" 2>&1 | tail -1
    echo; echo "### pip: fresh-venv install of numpy (17MB wheel) -- timed"
    { time timeout 300 "$TMP_SCRATCH/venv1/bin/pip" install -q --no-cache-dir numpy; } 2>&1 | tail -3
    "$TMP_SCRATCH/venv1/bin/python" -c "import numpy; print('numpy', numpy.__version__)" 2>&1 | tail -1
  fi
  echo; echo "### npm: install typescript into tmp prefix -- timed"
  if command -v npm >/dev/null; then
    { time timeout 180 npm install --no-audit --no-fund --prefix "$TMP_SCRATCH/npmtest" typescript@5.8.3; } 2>&1 | tail -3
    du -sh "$TMP_SCRATCH/npmtest/node_modules" 2>/dev/null
  else echo "npm missing"; fi
  echo; echo "### git: shallow clone pypa/pip -- timed"
  if command -v git >/dev/null; then
    { time timeout 180 git clone --depth 1 -q https://github.com/pypa/pip "$TMP_SCRATCH/pipclone"; } 2>&1 | tail -3
    du -sh "$TMP_SCRATCH/pipclone" 2>/dev/null
    rm -rf "$TMP_SCRATCH/pipclone"
  else echo "git missing"; fi
  echo; echo "### apt"
  if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    echo "--- apt-get update (timed):"
    { time timeout 180 sudo -n apt-get update; } 2>&1 | tail -4
    if [ "$FULL" = 1 ] && [ "$SKIP_APT" = 0 ]; then
      echo "--- apt-get install sqlite3 (timed):"
      { time timeout 180 sudo -n apt-get install -y --no-install-recommends -q -o Dpkg::Use-Pty=0 sqlite3; } 2>&1 | tail -4
      echo "--- apt-get install ffmpeg (timed):"
      { time timeout 300 sudo -n apt-get install -y --no-install-recommends -q -o Dpkg::Use-Pty=0 ffmpeg; } 2>&1 | tail -4
      command -v ffmpeg >/dev/null && ffmpeg -version 2>&1 | head -1
    else
      echo "(apt installs skipped: --full not given, or --skip-apt)"
    fi
  else echo "sudo unavailable - apt section skipped"; fi
}

# ---------------------------------------------------------------------------
sec14_memory_pressure() {
  echo "### baseline"
  echo "memory.current = $(cat "$CGROUP_DIR/memory.current" 2>&1)"
  echo "memory.max     = $(cat "$CGROUP_DIR/memory.max" 2>&1)"
  echo "memory.events  = $(cat "$CGROUP_DIR/memory.events" 2>&1)"
  echo; echo "### single 3GB bytearray (expect MemoryError, not OOM-kill)"
  python3 -c "x=bytearray(3*10**9); print('survived')" 2>&1 | tail -1
  echo "exit=$?  (python MemoryError expected; kernel-OOM would be 137)"
  echo; echo "### cgroup OOM ramp: allocate 200MB steps, touch pages, until killed"
  if [ "$FULL" = 1 ] && [ "$SKIP_OOM" = 0 ]; then
    python3 -u - <<'PY' 2>&1
import time
def cur():
    with open("/sys/fs/cgroup/user/memory.current") as f: return f.read().strip()
bufs=[]
for step in range(1, 13):
    print(f"step {step}: allocating 200MB (total ~{step*200}MB)...", flush=True)
    b = bytearray(200 * 1024 * 1024)
    for i in range(0, len(b), 4096): b[i] = 1
    bufs.append(b)
    print(f"step {step}: done, memory.current={cur()}", flush=True)
    time.sleep(0.2)
print("survived all steps (unexpected if cap < 2.4GB)", flush=True)
PY
    echo "oom-ramp-exit=$?   (137 = SIGKILL by cgroup OOM killer; 0 = survived)"
    echo "memory.events after: $(cat "$CGROUP_DIR/memory.events" 2>&1)"
    echo "memory.current after: $(cat "$CGROUP_DIR/memory.current" 2>&1)"
  else
    echo "(OOM ramp skipped: --full not given, or --skip-oom)"
  fi
  echo; echo "### post-checks"
  uptime
  echo "process count: $(ps -e --no-headers 2>/dev/null | wc -l)"
}

# ---------------------------------------------------------------------------
sec15_services_processes() {
  echo "### process count"; echo "$(ps -e --no-headers 2>/dev/null | wc -l) processes"
  echo; echo "### process tree head"; ps -eo pid,ppid,comm,args 2>/dev/null | head -15
  echo; echo "### listening sockets (ss -ltn)"
  if command -v ss >/dev/null; then ss -ltn 2>/dev/null | head -20; else echo "ss missing"; fi
  echo; echo "### systemd services"
  if command -v systemctl >/dev/null; then
    echo "is-system-running: $(systemctl is-system-running 2>&1)"
    systemctl list-units --type=service --state=running --no-pager 2>/dev/null | head -12
  else echo "systemctl missing"; fi
  echo; echo "### kernel log tail (dmesg)"
  if [ "$(id -u)" = 0 ]; then dmesg 2>&1 | tail -5
  elif command -v sudo >/dev/null && sudo -n true 2>/dev/null; then sudo -n dmesg 2>&1 | tail -5
  else echo "dmesg unreadable without root"; fi
  echo; echo "### background-process survival probe (nohup, 90s)"
  nohup bash -c 'sleep 90; echo "survived at $(date -u +%H:%M:%S)" > "$1"' _ "$OUT/nohup_result.txt" >/dev/null 2>&1 &
  echo "spawned nohup pid=$!"
  echo "it writes $OUT/nohup_result.txt after ~90s."
  echo "If this sandbox/session is still alive then, verify with:  cat $OUT/nohup_result.txt"
  echo "(nohup_result.txt is intentionally NOT part of MANIFEST.sha256: it is produced ~90s"
  echo " after the run finishes, i.e. after manifest generation. It documents cross-session"
  echo " background survival, not section output.)"
}

# ---------------------------------------------------------------------------
sec16_envconfig() {
  echo "### environment variables (sorted)"
  env | sort
  echo; echo "### /.e2b (image provenance)"
  cat /.e2b 2>/dev/null || echo "absent"
  echo; echo "### /etc/resolv.conf"; cat /etc/resolv.conf
  echo; echo "### locale/timezone"
  locale 2>/dev/null | head -4
  cat /etc/timezone 2>/dev/null
  echo; echo "### /etc/hosts"; cat /etc/hosts 2>/dev/null | head -8
}

# ---------------------------------------------------------------------------
gen_manifest() { # $@ = original args
  ( cd "$OUT" && ls [0-9]*.txt 2>/dev/null | sort | xargs -r sha256sum > MANIFEST.sha256 )
  local script_sha sha
  script_sha=$(sha256sum "$0" | awk '{print $1}')
  {
    echo "PROBE RUN MANIFEST"
    echo "=================="
    echo "RUNID             : $RUNID"
    echo "STARTED_UTC       : $T0"
    echo "FINISHED_UTC      : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "HOSTNAME          : $(hostname)"
    echo "KERNEL            : $(uname -r)"
    echo "ARCH              : $(uname -m)"
    echo "OS                : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
    echo "USER/UID/GID      : $(id -un)/$(id -u)/$(id -g)"
    echo "E2B_SANDBOX_ID    : ${E2B_SANDBOX_ID:-unset}"
    echo "E2B_TEMPLATE_ID   : ${E2B_TEMPLATE_ID:-unset}"
    echo "BOOT_ID           : $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unreadable)"
    echo -n "EGRESS_IP         : "; curl -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "unreachable"; echo
    echo "FLAGS             : $*"
    echo "PROBE_SCRIPT_SHA256: $script_sha"
    echo
    echo "FILES (name, size_bytes, sha256)"
    echo "-------------------------------"
    ( cd "$OUT" && for f in $(ls [0-9]*.txt | sort); do printf '%-28s %10s %s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f" | awk '{print $1}')"; done )
    echo "-------------------------------"
    echo "MANIFEST.sha256 is the machine-checkable file:  sha256sum -c MANIFEST.sha256"
    echo "This MANIFEST.txt is its human-readable copy (same hashes)."
  } > "$OUT/MANIFEST.txt"
}

# ---------------------------------------------------------------------------
echo "== probe_environment.sh  run=$RUNID  out=$OUT  full=$FULL =="

sec 00_meta.txt             sec00_meta
sec 01_runtime.txt          sec01_runtime
sec 02_isolation.txt        sec02_isolation
sec 03_tools.txt            sec03_tools
sec 04_limits.txt           sec04_limits
sec 05_filesystem.txt       sec05_filesystem
sec 06_fs_tests.txt         sec06_fs_tests
sec 07_dns.txt              sec07_dns
sec 08_http_latency.txt     sec08_http_latency
sec 09_net_matrix.txt       sec09_net_matrix
sec 10_download_throughput.txt sec10_download_throughput
sec 11_cpu_bench.txt        sec11_cpu_bench
sec 12_disk_bench.txt       sec12_disk_bench
sec 13_pkg_installs.txt     sec13_pkg_installs
sec 14_memory_pressure.txt  sec14_memory_pressure
sec 15_services_processes.txt sec15_services_processes
sec 16_envconfig.txt        sec16_envconfig

gen_manifest "$@"

# self-check
if ( cd "$OUT" && sha256sum -c --quiet MANIFEST.sha256 >/dev/null 2>&1 ); then
  echo "== manifest self-check: PASS"
  echo "== run dir: $OUT"
  echo "== files: $(ls "$OUT"/*.txt 2>/dev/null | wc -l)  (section transcripts + MANIFEST)"
  exit 0
else
  echo "== manifest self-check: FAIL"
  exit 1
fi
