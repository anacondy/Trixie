#!/usr/bin/env bash
# =============================================================================
# probe_environment.sh — reproducible environment characterization probe
#
# Produces verbatim raw transcripts (NN_*.txt) of every check, a SHA256SUMS
# file (machine-checkable via `sha256sum -c`), and verification_manifest.txt
# (timestamp, sandbox/template IDs, host facts, SHA-256 of every raw file).
#
# Usage:
#   bash probe_environment.sh [--stress] [--light] [--outdir DIR]
#
#   (default)  non-destructive probes + benchmarks + network measurements
#   --stress   additionally runs: package-install tests (apt --reinstall,
#              pip, npm, git clone) and the memory allocation-until-OOM test
#              (its python child is expected to be OOM-killed, exit 137)
#   --light    skips the large (>50 MB) downloads and the upload test
#
# All raw files are written by direct shell redirection: no post-processing.
# Safe to re-run; cleans up its own scratch files. Requires: curl, python3.
# Optional: sudo (ping/ports/drop_caches degrade gracefully without it).
# =============================================================================
set -u
export LC_ALL=C

MODE="default"; OUTDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --stress) MODE="stress" ;;
    --light)  MODE="light" ;;
    --outdir) OUTDIR="$2"; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -z "$OUTDIR" ] && OUTDIR="raw_$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUTDIR" || { echo "cannot create $OUTDIR" >&2; exit 1; }
OUTDIR="$(cd "$OUTDIR" && pwd)"

START_UTC="$(date -u +%FT%TZ)"
RUN_ID="$(basename "$OUTDIR")"
SCRIPT="$(readlink -f "$0")"   # absolute path; sections may cd around
SUDO=""
sudo -n true 2>/dev/null && SUDO="sudo -n"

begin() {  # begin <file> <title>
  local f="$OUTDIR/$1"
  {
    echo "# ============================================================"
    echo "# probe_environment.sh :: $2"
    echo "# run_id: $RUN_ID   mode: $MODE"
    echo "# host: $(hostname)   user: $(id -un)($(id -u))"
    echo "# date_utc: $(date -u +%FT%TZ)"
    echo "# ============================================================"
    echo
  } > "$f"
}
say() { echo "$@"; }   # progress to stdout only

# ---------------------------------------------------------------- 01 runtime
say "[01] runtime"; begin 01_runtime.txt "01 runtime (OS / kernel / CPU / RAM)"
{
  echo '$ uname -a';            uname -a; echo
  echo '$ cat /etc/os-release'; cat /etc/os-release; echo
  echo '$ ldd --version | head -2'; ldd --version 2>/dev/null | head -2; echo
  echo '$ arch'; arch; echo
  echo '$ nproc'; nproc; echo
  echo '$ grep -m1 "model name" /proc/cpuinfo'; grep -m1 'model name' /proc/cpuinfo; echo
  echo '$ cpu flags of interest'
  grep -m1 flags /proc/cpuinfo | tr ' ' '\n' | grep -E '^(avx|avx2|avx512f|sse4_2|aes|fma|sha_ni)$' | sort; echo
  echo '$ head -5 /proc/meminfo'; head -5 /proc/meminfo; echo
  echo '$ free -h'; free -h; echo
  echo '$ uptime'; uptime; echo
  echo '$ hostname'; hostname; echo
  echo '$ date; timedatectl (TZ)'; date; timedatectl 2>/dev/null | head -4
} >> "$OUTDIR/01_runtime.txt" 2>&1

# -------------------------------------------------------------- 02 isolation
say "[02] isolation"; begin 02_isolation.txt "02 isolation (VM/container signals, identity, network topology)"
{
  echo '$ ls -la /.dockerenv'; ls -la /.dockerenv 2>&1; echo
  echo '$ cat /proc/1/cgroup'; cat /proc/1/cgroup; echo
  echo '$ PID1 cmdline'; tr '\0' ' ' < /proc/1/cmdline; echo; echo
  echo '$ ps -eo pid,ppid,user,comm (first 25)'; ps -eo pid,ppid,user,comm 2>/dev/null | head -25; echo
  echo '$ ps (non-kernel processes)'; ps -eo pid,ppid,user,rss,args 2>/dev/null | grep -vE '\[' | head -30; echo
  echo '$ grep -E "^Cap" /proc/self/status'; grep -E '^Cap' /proc/self/status; echo
  echo '$ grep -E "Seccomp|NoNewPrivs" /proc/self/status'; grep -E 'Seccomp|NoNewPrivs' /proc/self/status; echo
  echo '$ id'; id; echo
  echo '$ sudo -n id'; sudo -n id 2>&1; echo
  echo '$ ip -4 addr'; ip -4 addr 2>/dev/null; echo
  echo '$ ip route'; ip route 2>/dev/null; echo
  echo '$ cat /etc/resolv.conf'; cat /etc/resolv.conf 2>/dev/null; echo
  echo '$ cat /etc/hosts'; cat /etc/hosts 2>/dev/null; echo
  echo '$ systemctl list-units --type=service --state=running'
  systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print $1}'
} >> "$OUTDIR/02_isolation.txt" 2>&1

# ----------------------------------------------------------------- 03 limits
say "[03] limits"; begin 03_limits.txt "03 resource limits (ulimit + cgroup v2)"
{
  echo '$ ulimit -a'; ulimit -a; echo
  echo '$ ulimit -Hn (hard fd limit)'; ulimit -Hn; echo
  echo '$ cat /proc/self/cgroup'; cat /proc/self/cgroup; echo
  echo '$ cgroup files (/sys/fs/cgroup and our scope)'
  for p in /sys/fs/cgroup /sys/fs/cgroup/user /sys/fs/cgroup/init.scope /sys/fs/cgroup/system.slice; do
    for f in memory.max memory.high memory.current memory.swap.max cpu.max cpu.weight pids.max pids.current io.max; do
      [ -f "$p/$f" ] && echo "$p/$f = $(head -1 "$p/$f")"
    done
  done; echo
  echo '$ cpuset'; echo "cpus=$(cat /sys/fs/cgroup/cpuset.cpus.effective 2>/dev/null) mems=$(cat /sys/fs/cgroup/cpuset.mems.effective 2>/dev/null)"; echo
  echo '$ head -6 /sys/fs/cgroup/cpu.stat'; head -6 /sys/fs/cgroup/cpu.stat 2>/dev/null
} >> "$OUTDIR/03_limits.txt" 2>&1

# ---------------------------------------------------------------- 04 tooling
say "[04] tooling"; begin 04_tooling.txt "04 tooling (binaries, versions, python stack)"
{
  echo '$ version matrix (command --version | head -1)'
  for c in python3 python pip pip3 node npm npx git curl wget ffmpeg docker podman make cmake \
           gcc g++ clang jq rg apt-get apk yum dnf conda mamba uv pipx go rustc cargo java tar \
           gzip unzip xz ssh rsync screen tmux htop strace gdb valgrind sqlite3 openssl nc socat; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '%-12s OK      %s\n' "$c" "$("$c" --version 2>&1 | head -1 | cut -c1-80)"
    else
      printf '%-12s MISSING\n' "$c"
    fi
  done; echo
  echo '$ python module availability'
  python3 - <<'PY'
mods = ['numpy','pandas','requests','urllib3','scipy','sklearn','torch','transformers',
        'sqlite3','ssl','ctypes','multiprocessing','asyncio','venv','lzma','bz2','psutil']
import importlib
for m in mods:
    try:
        mod = importlib.import_module(m)
        print(f"{m:15s} OK   {getattr(mod,'__version__','(stdlib)')}")
    except Exception as e:
        print(f"{m:15s} MISSING ({type(e).__name__})")
PY
  echo
  echo '$ pip list'; pip list 2>/dev/null; echo
  echo '$ python3 -m venv smoke test (timed)'
  { time python3 -m venv /tmp/.probe_venv ; } 2>&1; rm -rf /tmp/.probe_venv
} >> "$OUTDIR/04_tooling.txt" 2>&1

# ------------------------------------------------------------- 05 filesystem
say "[05] filesystem"; begin 05_filesystem.txt "05 filesystem (space, mounts, write tests)"
{
  echo '$ pwd; echo $HOME'; pwd; echo "$HOME"; echo
  echo '$ df -h'; df -h; echo
  echo '$ df -i'; df -i; echo
  echo '$ cat /proc/mounts'; cat /proc/mounts; echo
  echo '$ write+read+delete tests'
  for d in /home/user /tmp /var/tmp /dev/shm /usr/local/bin /opt /etc /root /mnt /srv; do
    f="$d/.probe_wtest_$$"
    if echo hello > "$f" 2>/dev/null && [ "$(cat "$f" 2>/dev/null)" = "hello" ] && rm -f "$f" 2>/dev/null; then
      echo "$d: write+read+delete OK"
    else
      rm -f "$f" 2>/dev/null; echo "$d: FAILED (read-only or no permission for $(id -un))"
    fi
  done
} >> "$OUTDIR/05_filesystem.txt" 2>&1

# ------------------------------------------------------------- 06 persistence
say "[06] persistence"; begin 06_persistence.txt "06 persistence markers"
{
  echo 'NOTE: true cross-session persistence cannot be tested by a single script run.'
  echo 'This writes run-unique markers to persistent ($HOME) and volatile (/tmp) locations'
  echo 'and reads them back; compare across runs/sessions externally.'; echo
  echo '$ write+read markers'
  for d in "$HOME" /tmp; do
    m="$d/.probe_persistence_marker.txt"
    echo "marker run=$RUN_ID written=$(date -u +%FT%TZ) host=$(hostname)" > "$m"
    printf '%s -> %s\n' "$m" "$(cat "$m")"
  done
} >> "$OUTDIR/06_persistence.txt" 2>&1

# --------------------------------------------------------------------- 07 dns
say "[07] dns"; begin 07_dns.txt "07 DNS resolution timing"
{
  echo '$ python3 getaddrinfo timing (5x per domain, ms) + raw UDP/53 probes'
  python3 - <<'PY'
import socket, time
domains = ['google.com','github.com','pypi.org','huggingface.co','cloudflare.com','amazon.com']
print('getaddrinfo (ms per lookup):')
for d in domains:
    times=[]; err=None
    for i in range(5):
        t0=time.perf_counter()
        try: socket.getaddrinfo(d, 443, socket.AF_INET)
        except Exception as e: err=repr(e); break
        times.append((time.perf_counter()-t0)*1000)
    if err: print(f"  {d:20s} ERROR {err}")
    else: print(f"  {d:20s} " + " ".join(f"{t:7.1f}" for t in times) + f"   avg {sum(times)/len(times):.1f}")
print('resolved IPs:')
for d in domains[:4]:
    print(f"  {d:20s} -> {socket.gethostbyname(d)}")
def udp_query(name, server='8.8.8.8'):
    q = b'\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'
    for part in name.split('.'): q += bytes([len(part)]) + part.encode()
    q += b'\x00\x00\x01\x00\x01'
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(4)
    t0=time.perf_counter(); s.sendto(q,(server,53)); s.recvfrom(4096)
    ms=(time.perf_counter()-t0)*1000; s.close(); return ms
print('raw UDP/53 to 8.8.8.8 (3x, ms):')
for h in ['google.com','github.com','huggingface.co']:
    print(f"  {h:20s} " + " ".join(f"{udp_query(h):.1f}" for _ in range(3)))
PY
} >> "$OUTDIR/07_dns.txt" 2>&1

# ----------------------------------------------------------------- 08 latency
say "[08] latency"; begin 08_latency.txt "08 connection latency (curl -w breakdown, ICMP)"
{
  echo '$ curl timing breakdown, seconds (dns tcp tls ttfb total http)'
  for url in https://www.google.com https://github.com https://pypi.org https://huggingface.co \
             https://www.cloudflare.com https://8.8.8.8/ http://example.com/; do
    w=$(curl -o /dev/null -s -k -L -m 25 -w '%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total} %{http_code} %{remote_ip}' "$url") || w="FAILED - - - - - - -"
    echo "$url | $w"
  done; echo
  echo '$ ICMP (needs CAP_NET_RAW; sudo used if available)'
  for t in 8.8.8.8 google.com; do
    echo "--- ping -c 4 -W 2 $t ---"
    if [ -n "$SUDO" ]; then $SUDO ping -c 4 -W 2 "$t" 2>&1 | tail -2
    else ping -c 4 -W 2 "$t" 2>&1 | tail -2; fi
  done
} >> "$OUTDIR/08_latency.txt" 2>&1

# ------------------------------------------------------------- 09 net matrix
say "[09] net matrix"; begin 09_net_matrix.txt "09 outbound port matrix + egress-interception checks"
{
  echo '$ python3 TCP connect matrix (5s timeout)'
  python3 - <<'PY'
import socket, time
targets = [
    ('8.8.8.8',53,'DNS/TCP'), ('8.8.8.8',443,'DoH'), ('8.8.8.8',80,'http-on-8.8.8.8'),
    ('8.8.8.8',3306,'nonsense-service'), ('8.8.8.8',12345,'nonsense-port-1'),
    ('8.8.8.8',59999,'nonsense-port-2'),
    ('one.one.one.one',443,'cloudflare-TLS'), ('one.one.one.one',80,'cloudflare-HTTP'),
    ('github.com',22,'github-SSH'), ('github.com',443,'github-TLS'),
    ('gmail-smtp-in.l.google.com',25,'SMTP-25'), ('smtp.gmail.com',587,'SMTP-587'),
    ('smtp.gmail.com',465,'SMTPS-465'), ('imap.gmail.com',993,'IMAPS-993'),
    ('ftp.gnu.org',21,'FTP-21'), ('mirror.nforce.com',873,'rsync-873'),
]
for host, port, label in targets:
    try:
        t0=time.perf_counter(); s=socket.create_connection((host,port),timeout=5)
        ms=(time.perf_counter()-t0)*1000; s.close()
        print(f"  {label:18s} {host}:{port:<5} OPEN    connect {ms:7.1f} ms")
    except socket.timeout:
        print(f"  {label:18s} {host}:{port:<5} TIMEOUT (>5s)")
    except Exception as e:
        print(f"  {label:18s} {host}:{port:<5} FAIL    {type(e).__name__}: {e}")
PY
  echo
  echo '$ HTTP to an accepted-but-dead port (expect hang/timeout if proxied)'
  curl -s -m 6 -o /dev/null -w 'http://8.8.8.8:3306/ -> http:%{http_code} time:%{time_total}s\n' http://8.8.8.8:3306/ 2>&1 || echo 'no HTTP response (accepted but nothing behind it)'
  echo '$ plain HTTP sanity (captive-portal check)'
  curl -s -m 10 -o /dev/null -w 'http://example.com/ -> http:%{http_code} ip:%{remote_ip} time:%{time_total}s\n' http://example.com/
} >> "$OUTDIR/09_net_matrix.txt" 2>&1

# ------------------------------------------------------------- 10 throughput
say "[10] throughput"; begin 10_throughput.txt "10 throughput (real transfers)"
{
  echo '$ curl download/upload measurements (time_total s, speed B/s, size B, http)'
  echo '--- dl.google.com chrome .deb (~141 MB) ---'
  if [ "$MODE" != "light" ]; then
    curl -o /dev/null -sL -m 180 -w "total:%{time_total}s speed:%{speed_download}B/s size:%{size_download} http:%{http_code}\n" \
      'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' || echo FAILED
  else echo 'SKIPPED (--light)'; fi; echo
  echo '--- huggingface.co all-MiniLM-L6-v2 model.safetensors (~90.9 MB) x2 ---'
  if [ "$MODE" != "light" ]; then
    for i in 1 2; do
      curl -o /dev/null -sL -m 120 -w "run$i: total:%{time_total}s speed:%{speed_download}B/s size:%{size_download} http:%{http_code}\n" \
        'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/model.safetensors' || echo FAILED
    done
  else echo 'SKIPPED (--light)'; fi; echo
  echo '--- github.com release asset (ripgrep 14.1.1, ~2.6 MB) ---'
  curl -o /dev/null -sL -m 60 -w "total:%{time_total}s speed:%{speed_download}B/s size:%{size_download} http:%{http_code}\n" \
    'https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz' || echo FAILED
  echo
  echo '--- huggingface.co gpt2 tokenizer.json (~1.4 MB) ---'
  curl -o /dev/null -sL -m 60 -w "total:%{time_total}s speed:%{speed_download}B/s size:%{size_download} http:%{http_code}\n" \
    'https://huggingface.co/openai-community/gpt2/resolve/main/tokenizer.json' || echo FAILED
  echo
  echo '--- PyPI CDN via pip download (numpy wheel) ---'
  tmpd=$(mktemp -d)
  { time pip download --no-cache-dir --no-deps -q -d "$tmpd" numpy ; } 2>&1
  ls -la "$tmpd" | grep -v '^total\|^d'; rm -rf "$tmpd"; echo
  echo '--- upload 26.2 MB -> speed.cloudflare.com/__up ---'
  if [ "$MODE" != "light" ]; then
    up=$(mktemp); head -c 26214400 /dev/urandom > "$up"
    curl -o /dev/null -s -m 120 --data-binary @"$up" -H 'Content-Type: application/octet-stream' \
      -w "total:%{time_total}s up_speed:%{speed_upload}B/s http:%{http_code}\n" 'https://speed.cloudflare.com/__up' || echo FAILED
    rm -f "$up"
  else echo 'SKIPPED (--light)'; fi; echo
  echo '--- speed.cloudflare.com/__down 100MB (known to 403; documents bot protection) ---'
  curl -o /dev/null -s -m 60 -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' \
    -w "total:%{time_total}s speed:%{speed_download}B/s size:%{size_download} http:%{http_code}\n" \
    'https://speed.cloudflare.com/__down?bytes=100000000' || echo FAILED
} >> "$OUTDIR/10_throughput.txt" 2>&1

# ------------------------------------------------------------- 11 cpu bench
say "[11] cpu bench"; begin 11_cpu_bench.txt "11 CPU micro-benchmarks (python3, best-of-3)"
{
  python3 - <<'PY'
import time, math, os, sys
def t(label, fn, reps=1):
    best=None
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); dt=time.perf_counter()-t0
        best=dt if best is None else min(best,dt)
    print(f"{label:42s} {best*1000:10.1f} ms   (result={r})")
    return best
print(f"python {sys.version.split()[0]}  pid={os.getpid()}")
t("sum(range(10**7))", lambda: sum(range(10**7)), reps=3)
def heavy():
    s=0.0
    for i in range(1_000_000): s+=math.sqrt(i)*i/(i+1)
    return round(s,3)
t("loop 1e6: sqrt+mul+div", heavy, reps=3)
t("str join 1e5 ints", lambda: len(",".join(map(str, range(100_000)))), reps=3)
t("sha256 100MB", lambda: __import__('hashlib').sha256(b'A'*100_000_000).hexdigest()[:12])
try:
    import numpy as np
    print("numpy", np.__version__)
    t("np.sum(np.arange(1e8))", lambda: int(np.arange(1e8, dtype=np.int64).sum()))
    a=np.random.rand(1500,1500); b=np.random.rand(1500,1500)
    gf=2*1500**3/1e9
    dt=t("np.dot 1500x1500 (BLAS)", lambda: float(np.dot(a,b).sum()))
    print(f"{'':42s} -> ~{gf/dt:6.1f} GFLOP/s effective")
except ImportError:
    print("numpy missing")
from multiprocessing import Pool
def work(n):
    s=0.0
    for i in range(n): s+=math.sqrt(i)
    return s
t0=time.perf_counter()
with Pool(2) as p: p.map(work,[3_000_000,3_000_000])
dt_par=time.perf_counter()-t0
t0=time.perf_counter(); work(3_000_000); work(3_000_000); dt_seq=time.perf_counter()-t0
print(f"{'mp Pool(2) 2x3e6 vs sequential':42s} par={dt_par*1000:7.1f} ms  seq={dt_seq*1000:7.1f} ms  speedup={dt_seq/dt_par:.2f}x")
PY
} >> "$OUTDIR/11_cpu_bench.txt" 2>&1

# ------------------------------------------------------------ 12 disk bench
say "[12] disk bench"; begin 12_disk_bench.txt "12 disk benchmarks (dd 100 MiB, small-file churn)"
{
  SC="${HOME}/.probe_scratch"; mkdir -p "$SC"
  echo '$ dd ext4 write 100MiB conv=fdatasync'; sync
  dd if=/dev/zero of="$SC/d100.bin" bs=1M count=100 conv=fdatasync 2>&1 | tail -1
  echo '$ drop caches + read back'
  [ -n "$SUDO" ] && $SUDO sh -c 'echo 3 > /proc/sys/vm/drop_caches' || echo '(no sudo; cache not dropped)'
  dd if="$SC/d100.bin" of=/dev/null bs=1M 2>&1 | tail -1
  echo '$ read back again (warm cache)'
  dd if="$SC/d100.bin" of=/dev/null bs=1M 2>&1 | tail -1
  echo '$ O_DIRECT write'; dd if=/dev/zero of="$SC/ddir.bin" bs=1M count=100 oflag=direct 2>&1 | tail -1
  echo '$ O_DIRECT read';  dd if="$SC/ddir.bin" of=/dev/null bs=1M iflag=direct 2>&1 | tail -1
  rm -rf "$SC"
  echo '$ tmpfs /tmp write+read 100MiB'
  dd if=/dev/zero of=/tmp/.probe_t100.bin bs=1M count=100 conv=fdatasync 2>&1 | tail -1
  dd if=/tmp/.probe_t100.bin of=/dev/null bs=1M 2>&1 | tail -1
  rm -f /tmp/.probe_t100.bin
  echo '$ small-file churn: 500 x (create 4KiB + fsync + delete) on ext4'
  python3 - <<'PY'
import os, time
d=os.path.expanduser('~/.probe_churn'); os.makedirs(d, exist_ok=True)
t0=time.perf_counter()
for i in range(500):
    p=f'{d}/f{i}'
    with open(p,'wb') as f: f.write(b'x'*4096); f.flush(); os.fsync(f.fileno())
for i in range(500): os.remove(f'{d}/f{i}')
os.rmdir(d)
dt=time.perf_counter()-t0
print(f"500 create+fsync+delete: {dt*1000:.0f} ms total ({dt/500*1000:.2f} ms/file)")
PY
} >> "$OUTDIR/12_disk_bench.txt" 2>&1

# ---------------------------------------------------------- 13 installs (stress)
begin 13_installs.txt "13 package-install tests (STRESS mode only)"
if [ "$MODE" = "stress" ]; then
  say "[13] installs"
  {
    tmpd=$(mktemp -d)
    echo '$ apt-get update (timed)'
    if [ -n "$SUDO" ]; then { time $SUDO apt-get update -qq ; } 2>&1 | tail -4
    else echo '(no sudo; skipped)'; fi; echo
    echo '$ apt-get install --reinstall file ripgrep (timed; --reinstall so re-runs still download)'
    if [ -n "$SUDO" ]; then { time $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --reinstall file ripgrep ; } 2>&1 | tail -4
    else echo '(no sudo; skipped)'; fi; echo
    echo '$ pip install --no-cache-dir --target <tmp> six (timed)'
    { time pip install --no-cache-dir -q --target "$tmpd/pip" six ; } 2>&1 | grep -vE '^\[notice\]|^$'; echo
    echo '$ pip download numpy wheel (timed)'
    { time pip download --no-cache-dir --no-deps -q -d "$tmpd/dl" numpy ; } 2>&1; ls -la "$tmpd/dl" 2>/dev/null | grep -v '^total\|^d'; echo
    echo '$ npm install left-pad in empty dir (timed)'
    mkdir -p "$tmpd/npm" && cd "$tmpd/npm"
    { time npm install --no-save --silent left-pad ; } 2>&1 | tail -3; echo
    echo '$ git clone --depth 1 octocat/Hello-World (timed)'
    { time git clone --depth 1 -q https://github.com/octocat/Hello-World "$tmpd/clone" ; } 2>&1; echo
    echo '$ gcc compile+run (timed)'
    printf '#include <stdio.h>\n#include <math.h>\nint main(){double s=0;for(long i=0;i<1000000;i++)s+=sqrt(i);printf("ok s=%%.2f\\n",s);}\n' > "$tmpd/h.c"
    { time gcc -O2 -o "$tmpd/h" "$tmpd/h.c" -lm && "$tmpd/h" ; } 2>&1
    cd /; rm -rf "$tmpd"
  } >> "$OUTDIR/13_installs.txt" 2>&1
else
  echo 'SKIPPED: run with --stress to execute package-install tests.' >> "$OUTDIR/13_installs.txt"
fi

# ---------------------------------------------------------- 14 memory (stress)
begin 14_memory.txt "14 memory pressure: allocate+touch 100MB chunks until OOM (STRESS only)"
if [ "$MODE" = "stress" ]; then
  say "[14] memory"
  {
    echo 'expect: child python3 OOM-killed (exit 137) at cgroup memory.max; this is the intended result'
    python3 -u - <<'PY'
chunks=[]; total=0
try:
    while True:
        b=bytearray(100*1024*1024)
        for i in range(0,len(b),4096): b[i]=1
        chunks.append(b); total+=100
        print(f"allocated {total:5d} MB ok")
except MemoryError:
    print(f"MemoryError at ~{total} MB")
PY
    echo "python exit code: $? (137 = OOM-killed at cgroup hard limit)"
    free -h | head -2
  } >> "$OUTDIR/14_memory.txt" 2>&1
else
  echo 'SKIPPED: run with --stress to execute the memory OOM test.' >> "$OUTDIR/14_memory.txt"
fi

# ------------------------------------------------------------- 15 background
say "[15] background"; begin 15_background.txt "15 background/long-running process test"
{
  echo '$ nohup heartbeat (0.2s ticks), verify alive after 7s, then terminate'
  bglog="$OUTDIR/15_background_heartbeat.log"
  nohup bash -c 'echo "heartbeat started pid=$$"; for i in $(seq 1 100); do echo "tick $i $(date +%s)"; sleep 0.2; done' > "$bglog" 2>&1 &
  bgpid=$!
  sleep 7
  if kill -0 "$bgpid" 2>/dev/null; then echo "process $bgpid alive after 7s: YES"; else echo "process $bgpid alive after 7s: NO (died early)"; fi
  kill "$bgpid" 2>/dev/null; sleep 0.5
  echo "ticks recorded in 15_background_heartbeat.log: $(grep -c '^tick' "$bglog")"
  head -3 "$bglog"
} >> "$OUTDIR/15_background.txt" 2>&1

# --------------------------------------------------------- 16 env & services
say "[16] env/services"; begin 16_env_services.txt "16 environment variables, listening sockets, sandbox plane"
{
  echo '$ env | sort (token-like values redacted)'
  env | sort | sed -E 's/=(sk-[A-Za-z0-9_-]{8,})/=<REDACTED>/; s/((KEY|TOKEN|SECRET|PASS)[A-Z_]*)=.{4,}/\1=<REDACTED>/I'
  echo
  echo '$ proxy vars'; env | grep -iE 'proxy' || echo 'none set'; echo
  echo '$ listening sockets'; ($SUDO ss -tlnp 2>/dev/null || ss -tln 2>/dev/null) | head -25; echo
  echo '$ E2B control-plane probe (E2B_EVENTS_ADDRESS)'
  if [ -n "${E2B_EVENTS_ADDRESS:-}" ]; then
    curl -s -m 2 -o /dev/null -w "http:%{http_code} total:%{time_total}s\n" "$E2B_EVENTS_ADDRESS/" || echo 'no response within 2s'
  else echo 'E2B_EVENTS_ADDRESS not set (not an E2B sandbox?)'; fi
} >> "$OUTDIR/16_env_services.txt" 2>&1

# ------------------------------------------------------------------ manifest
say "[manifest]"
SHA_FILE="$OUTDIR/SHA256SUMS"
( cd "$OUTDIR" && sha256sum ./*.txt ./*.log 2>/dev/null | grep -v -e 'verification_manifest.txt' -e 'SHA256SUMS' ) > "$SHA_FILE"
MAN="$OUTDIR/verification_manifest.txt"
{
  echo "verification manifest"
  echo "====================="
  echo "run_id:            $RUN_ID"
  echo "run_started_utc:   $START_UTC"
  echo "run_finished_utc:  $(date -u +%FT%TZ)"
  echo "mode:              $MODE"
  echo "hostname:          $(hostname)"
  echo "sandbox_id:        ${E2B_SANDBOX_ID:-not-an-e2b-sandbox}"
  echo "template_id:       ${E2B_TEMPLATE_ID:-not-an-e2b-sandbox}"
  echo "kernel:            $(uname -r)"
  echo "os:                $(. /etc/os-release && echo "$PRETTY_NAME")"
  echo "user:              $(id -un)($(id -u))"
  echo "probe_script:      $(basename "$SCRIPT")"
  echo "probe_script_sha256: $(sha256sum "$SCRIPT" | cut -d' ' -f1)"
  echo
  echo "## raw file checksums (sha256, also in SHA256SUMS for 'sha256sum -c')"
  cat "$SHA_FILE"
  echo
  echo "## caveats for third-party diffing"
  echo "- Volatile by design (will differ between runs): all timings/throughputs, DNS jitter,"
  echo "  PIDs, ephemeral listen ports, memory.current, free space, load averages."
  echo "- Stable and should match on identical infrastructure: versions, cgroup/ulimit values,"
  echo "  CPU model/flags, mount layout, port-matrix OPEN/TIMEOUT pattern, OOM ceiling (+/-1 chunk)."
  echo "- 13_installs/14_memory only populated in --stress mode; 10_throughput honors --light."
  echo "- apt in 13 uses --reinstall so re-runs perform real downloads on already-installed pkgs."
  echo "- First cold DNS lookup of a domain may spike to seconds (observed once for github.com)."
} > "$MAN"

echo
echo "done. outputs in: $OUTDIR"
echo "verify checksums:  (cd '$OUTDIR' && sha256sum -c SHA256SUMS)"
