#!/usr/bin/env bash
# Environment probe — emit verbatim transcripts for third-party diff.
# Usage: ./probe_environment.sh [OUTPUT_DIR]
# Default OUTPUT_DIR: ./probe_raw next to this script (or $PWD/probe_raw).
set -u
set -o pipefail

OUT="${1:-}"
if [[ -z "$OUT" ]]; then
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/probe_raw"
  else
    OUT="${PWD}/probe_raw"
  fi
fi
mkdir -p "$OUT"
TS_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo unknown)"
HOST="$(hostname 2>/dev/null || echo unknown)"

log() { printf '[probe] %s\n' "$*" >&2; }

run_to() {
  local dest="$1"
  shift
  {
    echo "===== CMD: $* ====="
    echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
    echo "===== PWD: $PWD ====="
    echo
    "$@" 2>&1
    echo
    echo "===== EXIT: $? ====="
  } > "$dest"
}

# ---------------------------------------------------------------------------
log "01 runtime"
{
  echo "===== UTC: $TS_UTC ====="
  echo "===== hostname: $HOST ====="
  echo
  echo "===== uname -a ====="
  uname -a 2>&1
  echo
  echo "===== /etc/os-release ====="
  cat /etc/os-release 2>&1
  echo
  echo "===== arch / getconf ====="
  arch 2>&1
  getconf LONG_BIT 2>&1
  echo
  echo "===== ldd --version ====="
  ldd --version 2>&1 | head -5
  echo
  echo "===== hostnamectl (if any) ====="
  hostnamectl 2>&1 | head -20 || true
  echo
  echo "===== systemd-detect-virt ====="
  systemd-detect-virt 2>&1 || true
  echo
  echo "===== /proc/version ====="
  cat /proc/version 2>&1
} > "$OUT/01_runtime.txt"

# ---------------------------------------------------------------------------
log "02 isolation"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  echo "===== ls -la /.dockerenv ====="
  ls -la /.dockerenv 2>&1 || true
  echo
  echo "===== /proc/1/cgroup ====="
  cat /proc/1/cgroup 2>&1 || true
  echo
  echo "===== /proc/1/comm ====="
  cat /proc/1/comm 2>&1 || true
  echo
  echo "===== ps aux | head -40 ====="
  ps aux 2>&1 | head -40
  echo
  echo "===== mount ====="
  mount 2>&1
  echo
  echo "===== findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS ====="
  findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS 2>&1 || true
  echo
  echo "===== /proc/self/status Caps/Seccomp/NSpid ====="
  grep -E '^(Cap|Seccomp|NSpid|Uid|Gid|Name)' /proc/self/status 2>&1 || true
  echo
  echo "===== capsh --print (if any) ====="
  capsh --print 2>&1 | head -40 || true
  echo
  echo "===== cgroup controllers ====="
  ls -la /sys/fs/cgroup 2>&1 | head -40
  echo
  echo "===== memory.max cpu.max pids.max (if present) ====="
  for f in /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max /sys/fs/cgroup/pids.max \
           /sys/fs/cgroup/memory.current /sys/fs/cgroup/cgroup.controllers; do
    echo "--- $f ---"
    cat "$f" 2>&1 || true
  done
} > "$OUT/02_isolation.txt"

# ---------------------------------------------------------------------------
log "03 identity_limits"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  echo "===== id ====="
  id 2>&1
  echo
  echo "===== whoami ====="
  whoami 2>&1
  echo
  echo "===== groups ====="
  groups 2>&1
  echo
  echo "===== sudo -n true ====="
  sudo -n true 2>&1
  echo "sudo_exit:$?"
  echo
  echo "===== sudo -n id ====="
  sudo -n id 2>&1 || true
  echo
  echo "===== ulimit -a ====="
  ulimit -a 2>&1
  echo
  echo "===== ulimit -aH ====="
  ulimit -aH 2>&1 || true
} > "$OUT/03_identity_limits.txt"

# ---------------------------------------------------------------------------
log "04 cpu_mem"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  echo "===== nproc ====="
  nproc 2>&1
  echo
  echo "===== lscpu ====="
  lscpu 2>&1
  echo
  echo "===== /proc/cpuinfo (head) ====="
  cat /proc/cpuinfo 2>&1 | head -80
  echo
  echo "===== free -h ====="
  free -h 2>&1
  echo
  echo "===== /proc/meminfo ====="
  cat /proc/meminfo 2>&1
  echo
  echo "===== uptime ====="
  uptime 2>&1
} > "$OUT/04_cpu_mem.txt"

# ---------------------------------------------------------------------------
log "05 tools"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  for c in python3 pip pip3 node npm git curl wget ffmpeg docker make gcc g++ clang jq apt apk yum conda cargo rustc go java ruby php perl unzip tar gzip bzip2 xz ssh scp rsync sqlite3; do
    echo "===== $c ====="
    if command -v "$c" >/dev/null 2>&1; then
      command -v "$c"
      "$c" --version 2>&1 | head -3 || "$c" -version 2>&1 | head -3 || true
    else
      echo "NOT FOUND"
    fi
    echo
  done
  echo "===== python3 -c sys ====="
  python3 -c 'import sys; print(sys.executable); print(sys.version); print(sys.prefix)' 2>&1
  echo
  echo "===== java -version ====="
  java -version 2>&1 || true
} > "$OUT/05_tools.txt"

# ---------------------------------------------------------------------------
log "06 python_pkgs"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  python3 - <<'PY' 2>&1
import importlib.util
mods = ["numpy","pandas","sklearn","PIL","torch","requests","tqdm","httpx"]
for m in mods:
    s = importlib.util.find_spec(m)
    if not s:
        print(f"{m}: NOT INSTALLED")
        continue
    try:
        mod = __import__(m if m != "PIL" else "PIL")
        ver = getattr(mod, "__version__", "?")
        print(f"{m}: {ver} origin={s.origin}")
    except Exception as e:
        print(f"{m}: present but import failed: {e}")
PY
} > "$OUT/06_python_pkgs.txt"

# ---------------------------------------------------------------------------
log "07 filesystem"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  echo "===== pwd ====="
  pwd
  echo
  echo "===== df -hT ====="
  df -hT 2>&1
  echo
  echo "===== df -i ====="
  df -i 2>&1
  echo
  echo "===== ls -la /home/user ====="
  ls -la /home/user 2>&1 | head -30
  echo
  echo "===== write/read/delete tests ====="
  python3 - <<'PY' 2>&1
import os
paths=['/home/user','/tmp','/var/tmp','/opt','/usr/local','/']
for p in paths:
    f=os.path.join(p, f'.envchar_test_{os.getpid()}')
    try:
        with open(f,'w') as fh: fh.write('ok')
        with open(f) as fh: d=fh.read()
        os.remove(f)
        print(f'{p}: WRITE+READ+DELETE OK data={d!r}')
    except Exception as e:
        print(f'{p}: FAIL {type(e).__name__}: {e}')
PY
} > "$OUT/07_filesystem.txt"

# ---------------------------------------------------------------------------
log "08 env"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo "===== env | sort ====="
  env | sort
} > "$OUT/08_env.txt"

# ---------------------------------------------------------------------------
log "09 net_matrix"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo
  echo "===== DNS getent ====="
  for h in google.com github.com pypi.org huggingface.co 8.8.8.8; do
    echo "--- $h ---"
    TIMEFORMAT='real %R'
    { time getent hosts "$h"; } 2>&1
  done
  echo
  echo "===== ping -c 3 (expect fail without cap_net_raw) ====="
  ping -c 3 -W 2 8.8.8.8 2>&1 | head -8 || true
  echo
  echo "===== curl HTTPS timings ====="
  for u in https://google.com https://github.com https://pypi.org https://huggingface.co; do
    echo "--- $u ---"
    curl -o /dev/null -s -w 'dns:%{time_namelookup}s connect:%{time_connect}s tls:%{time_appconnect}s ttfb:%{time_starttransfer}s total:%{time_total}s size:%{size_download} http:%{http_code} ip:%{remote_ip}\n' -L --max-time 20 "$u" 2>&1
  done
  echo
  echo "===== curl -4 / -6 google ====="
  curl -4 -o /dev/null -s -w 'ipv4 total:%{time_total} http:%{http_code}\n' --max-time 10 https://google.com 2>&1
  curl -6 -o /dev/null -s -w 'ipv6 total:%{time_total} http:%{http_code} err:%{errormsg}\n' --max-time 5 https://google.com 2>&1 || true
  echo
  echo "===== TCP connect samples (python) ====="
  python3 - <<'PY' 2>&1
import socket, time
hosts=[('8.8.8.8',443),('google.com',443),('github.com',443),('pypi.org',443),('huggingface.co',443)]
for h,p in hosts:
    times=[]
    for i in range(5):
        s=socket.socket(); s.settimeout(5)
        t0=time.perf_counter()
        try:
            s.connect((h,p))
            times.append((time.perf_counter()-t0)*1000)
        except Exception as e:
            print(h,p,'ERR',e)
        finally:
            s.close()
    if times:
        print(f'{h}:{p}  samples_ms={[round(t,2) for t in times]}  min={min(times):.2f} avg={sum(times)/len(times):.2f} max={max(times):.2f}')
PY
  echo
  echo "===== large download ====="
  curl -L -o /tmp/probe_large.bin --max-time 60 -w 'http:%{http_code} size:%{size_download} speed:%{speed_download}B/s total:%{time_total}s\n' \
    https://github.com/git/git/archive/refs/tags/v2.45.0.tar.gz 2>&1 | tail -5
  ls -lh /tmp/probe_large.bin 2>&1 || true
  rm -f /tmp/probe_large.bin
  echo
  echo "===== port probe 1.1.1.1 ====="
  python3 - <<'PY' 2>&1
import socket, time
for port in [22,53,80,443,587,993,3306,5432,8080,8443]:
    s=socket.socket(); s.settimeout(2)
    t0=time.perf_counter()
    try:
        r=s.connect_ex(('1.1.1.1',port))
        dt=(time.perf_counter()-t0)*1000
        print(f'1.1.1.1:{port} connect_ex={r} {dt:.0f}ms')
    except Exception as e:
        print(port,e)
    finally:
        s.close()
print('--- TEST-NET 192.0.2.1:9 ---')
s=socket.socket(); s.settimeout(3)
t0=time.perf_counter()
r=s.connect_ex(('192.0.2.1',9))
print(f'192.0.2.1:9 connect_ex={r} {(time.perf_counter()-t0)*1000:.0f}ms')
s.close()
print('--- github.com:22 ---')
s=socket.socket(); s.settimeout(3)
t0=time.perf_counter()
try:
    s.connect(('github.com',22))
    print('github:22 connected', (time.perf_counter()-t0)*1000)
except Exception as e:
    print('github:22', e, (time.perf_counter()-t0)*1000)
s.close()
PY
} > "$OUT/09_net_matrix.txt"

# ---------------------------------------------------------------------------
log "10 benches"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  python3 - <<'PY' 2>&1
import time, os
print("=== CPU sum(range(10**7)) ===")
t0=time.perf_counter()
s=sum(range(10**7))
print(f"sum={s} seconds={time.perf_counter()-t0:.6f}")
print("=== heavier loop 5e6 ===")
t0=time.perf_counter()
x=0
for i in range(5_000_000):
    x += i*i
print(f"x={x} seconds={time.perf_counter()-t0:.6f}")
print("=== numpy ===")
try:
    import numpy as np
    t0=time.perf_counter()
    a=np.arange(10**7, dtype=np.float64)
    b=a.sum()
    print(f"numpy_sum={b} seconds={time.perf_counter()-t0:.6f}")
except Exception as e:
    print("numpy:", e)
print("=== disk 80MiB seq write+fsync+read /home/user ===")
path='/home/user/_probe_bench.bin'
data=b'A'*1024*1024
t0=time.perf_counter()
with open(path,'wb') as f:
    for _ in range(80):
        f.write(data)
    f.flush(); os.fsync(f.fileno())
tw=time.perf_counter()-t0
t0=time.perf_counter()
with open(path,'rb') as f:
    while f.read(1024*1024):
        pass
tr=time.perf_counter()-t0
sz=os.path.getsize(path)
print(f"write_bytes={sz} write_s={tw:.6f} write_MBps={sz/tw/1e6:.3f}")
print(f"read_bytes={sz} read_s={tr:.6f} read_MBps={sz/tr/1e6:.3f} (likely page cache)")
os.remove(path)
PY
  echo
  echo "===== gcc hello ====="
  echo 'int main(){return 0;}' > /tmp/probe_hello.c
  TIMEFORMAT='real %R user %U sys %S'
  { time gcc /tmp/probe_hello.c -o /tmp/probe_hello; } 2>&1
  /tmp/probe_hello && echo compile_run_ok
  rm -f /tmp/probe_hello.c /tmp/probe_hello
} > "$OUT/10_benches.txt"

# ---------------------------------------------------------------------------
log "11 pip_sample"
{
  echo "===== UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ====="
  echo "===== pip install charset-normalizer (timing) ====="
  TIMEFORMAT='real %R user %U sys %S'
  { time pip install charset-normalizer --quiet; } 2>&1
  python3 -c 'import charset_normalizer as c; print("charset_normalizer", c.__version__)' 2>&1
} > "$OUT/11_pip_sample.txt"

# ---------------------------------------------------------------------------
log "manifest"
MANIFEST="$OUT/00_MANIFEST.txt"
{
  echo "probe_utc_start_approx=$TS_UTC"
  echo "probe_utc_end=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "hostname=$HOST"
  echo "pwd=$(pwd)"
  echo "E2B_SANDBOX=${E2B_SANDBOX:-}"
  echo "E2B_SANDBOX_ID=${E2B_SANDBOX_ID:-}"
  echo "E2B_TEMPLATE_ID=${E2B_TEMPLATE_ID:-}"
  echo "uname=$(uname -a)"
  echo
  echo "===== sha256 ====="
  # hash all except this manifest if rewriting; hash transcripts
  if command -v sha256sum >/dev/null; then
    (cd "$OUT" && sha256sum 0*.txt 1*.txt 2>/dev/null || true)
  else
    python3 - <<PY
import hashlib, glob, os
os.chdir("$OUT")
for p in sorted(glob.glob("*.txt")):
    if p.startswith("00_"): continue
    h=hashlib.sha256(open(p,"rb").read()).hexdigest()
    print(f"{h}  {p}")
PY
  fi
} > "$MANIFEST"

# rewrite manifest with hashes including listing
python3 - <<PY
import hashlib, os, glob, datetime
out = "$OUT"
files = sorted(f for f in os.listdir(out) if f.endswith(".txt") and f != "00_MANIFEST.txt")
lines = []
lines.append("probe_script=probe_environment.sh")
lines.append(f"output_dir={out}")
lines.append(f"hostname=$(hostname)")
lines.append(f"utc_end={datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}")
for k in ("E2B_SANDBOX","E2B_SANDBOX_ID","E2B_TEMPLATE_ID"):
    lines.append(f"{k}={os.environ.get(k,'')}")
try:
    import subprocess
    lines.append("uname=" + subprocess.check_output(["uname","-a"], text=True).strip())
except Exception:
    pass
lines.append("")
lines.append("file  bytes  sha256")
for f in files:
    p = os.path.join(out, f)
    b = open(p, "rb").read()
    h = hashlib.sha256(b).hexdigest()
    lines.append(f"{f}  {len(b)}  {h}")
open(os.path.join(out, "00_MANIFEST.txt"), "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
PY

log "done -> $OUT"
ls -l "$OUT" >&2
