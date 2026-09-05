#!/usr/bin/env bash
# =============================================================================
# env_probe.sh - Reproducible sandbox environment characterization probe
# =============================================================================
# Emits VERBATIM command output to numbered .txt files, plus a signed-ish
# manifest (SHA-256 per file) so a third party can run this and diff results.
#
# NO summarisation, NO interpretation - raw transcripts only.
#
# Usage:
#   ./env_probe.sh                  # standard run (~6 min)
#   QUICK=1 ./env_probe.sh          # skip slow probes (~90 s)
#   FULL=1  ./env_probe.sh          # include unbounded npm audit hang (~15 min)
#   OUTDIR=/path ./env_probe.sh     # override output location
#
# Exit code is always 0; probe failures are DATA, not errors.
# =============================================================================

PROBE_VERSION="1.1.1"
QUICK="${QUICK:-0}"
FULL="${FULL:-0}"

RUN_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
SBX="${E2B_SANDBOX_ID:-$(hostname)}"
BASE="${OUTDIR:-$HOME/env-probe}"
RUN="$BASE/runs/${RUN_UTC}_${SBX}"
mkdir -p "$RUN"

# ---------------------------------------------------------------------------
# helpers: every command is echoed verbatim before its raw output
# ---------------------------------------------------------------------------
CUR=""
sec() {                       # sec <file> <title>
  CUR="$RUN/$1"
  {
    echo "############################################################"
    echo "# $2"
    echo "# probe_version=$PROBE_VERSION"
    echo "# run_utc=$RUN_UTC  sandbox=$SBX"
    echo "# generated=$(date -u +%FT%TZ)"
    echo "############################################################"
    echo
  } > "$CUR"
}

run() {                       # run <command string>  -- captures stdout+stderr
  {
    echo "\$ $*"
    eval "$@" 2>&1
    echo "[exit=$?]"
    echo
  } >> "$CUR"
}

note() { echo "$*" >> "$CUR"; }

# timing helper: prints real/user/sys around a command
timed() {                     # timed <label> <command string>
  {
    echo "\$ $2"
    echo "--- timing (bash TIMEFORMAT, real|user|sys) ---"
    TIMEFORMAT='REAL=%3R s  USER=%3U s  SYS=%3S s'
    { time eval "$2" >/tmp/.probe_out 2>/tmp/.probe_err ; } 2>>"$CUR"
    echo "[exit=$?]"
    echo "--- stdout (last 20 lines) ---"; tail -20 /tmp/.probe_out
    echo "--- stderr (last 10 lines) ---"; tail -10 /tmp/.probe_err
    echo
  } >> "$CUR"
}

echo "env_probe v$PROBE_VERSION -> $RUN"

# ===========================================================================
sec 01_runtime.txt "RUNTIME: OS / kernel / arch / libc"
# ===========================================================================
run "uname -a"
run "cat /etc/os-release"
run "arch"
run "dpkg --print-architecture"
run "ldd --version"
run "getconf GNU_LIBPTHREAD_VERSION"
run "hostname"
run "cat /proc/uptime"
run "date -u"
run "cat /proc/sys/kernel/random/boot_id"
run "cat /proc/cmdline"
run "cat /proc/version"
echo "  [01] runtime"

# ===========================================================================
sec 02_isolation.txt "ISOLATION: container / VM / sandbox signals"
# ===========================================================================
run "systemd-detect-virt"
run "ls -la /.dockerenv"
run "ls -la /run/.containerenv"
run "cat /proc/1/cgroup"
run "cat /proc/self/cgroup"
run "cat /proc/1/comm"
run "tr '\\0' ' ' < /proc/1/cmdline; echo"
run "lscpu"
run "cat /sys/class/dmi/id/product_name"
run "cat /sys/class/dmi/id/sys_vendor"
run "sudo dmesg 2>/dev/null | head -40"
run "grep -Ei 'cap|seccomp|uid|gid|threads|nstgid' /proc/self/status"
run "capsh --print"
run "ls -la /proc/self/ns/"
run "cat /sys/kernel/security/lsm"
echo "  [02] isolation"

# ===========================================================================
sec 03_identity_limits.txt "IDENTITY & RESOURCE LIMITS"
# ===========================================================================
run "whoami"
run "id"
run "sudo -n true && echo SUDO_NOPASSWD_OK || echo SUDO_UNAVAILABLE"
run "sudo -n id"
run "ulimit -a"
run "nproc"
run "free -m"
run "head -5 /proc/meminfo"
run "cat /proc/swaps"
run "cat /proc/sys/vm/overcommit_memory"
run "cat /proc/sys/vm/overcommit_ratio"
run "cat /proc/sys/kernel/threads-max"
run "cat /proc/sys/kernel/pid_max"
note "--- cgroup v2 limit files (absent => no cgroup cap; VM-level only) ---"
for f in memory.max memory.high memory.current cpu.max pids.max io.max; do
  run "cat /sys/fs/cgroup/$f"
done
echo "  [03] identity/limits"

# ===========================================================================
sec 04_tooling.txt "TOOLING: availability matrix + versions"
# ===========================================================================
note "--- availability matrix (tool | present | resolved path) ---"
for t in python3 python pip pip3 node npm npx yarn pnpm bun deno git curl wget \
         ffmpeg docker podman make cmake gcc g++ clang jq rustc cargo go java \
         ruby perl php sqlite3 psql redis-cli aws gh rsync unzip zip tar openssl \
         ssh nc dig nslookup traceroute ip ss iptables htop tmux screen vim nano \
         uv poetry pipx conda mamba apt apt-get dpkg apk yum dnf snap brew bc \
         sha256sum capsh time ping; do
  p="$(command -v "$t" 2>/dev/null)"
  if [ -n "$p" ]; then printf '%-12s YES  %s\n' "$t" "$p"; else printf '%-12s NO\n' "$t"; fi
done >> "$CUR"
note ""
note "--- versions ---"
run "python3 -VV"
run "pip --version"
run "node --version"
run "npm --version"
run "git --version"
run "curl --version"
run "wget --version | head -1"
run "gcc --version | head -1"
run "g++ --version | head -1"
run "make --version | head -1"
run "jq --version"
run "openssl version"
run "dpkg --version | head -1"
run "java -version"
echo "  [04] tooling"

# ===========================================================================
sec 05_python_env.txt "PYTHON: interpreter + full distribution list"
# ===========================================================================
run "python3 -c 'import sys; print(sys.version); print(sys.executable); print(sys.prefix)'"
run "python3 -c 'import sysconfig,json; print(json.dumps(sysconfig.get_paths(),indent=2))'"
run "ls /usr/local/include/python3.13/Python.h"
note "--- full installed distribution list (name==version) ---"
run "python3 -c \"import importlib.metadata as m; ps=sorted((d.metadata['Name'] or '?', d.version) for d in m.distributions()); print('TOTAL:',len(ps)); [print(f'{n}=={v}') for n,v in ps]\""
note "--- key library import probe ---"
run "python3 -c \"
for mod in ['numpy','pandas','scipy','sklearn','torch','matplotlib','requests','bs4','lxml','PIL','cv2','transformers','datasets','polars','pyarrow','duckdb','sympy','statsmodels','networkx','openpyxl','docx','pptx','reportlab','yaml','httpx','aiohttp','numba']:
    try:
        m=__import__(mod); print(f'{mod:14s} OK      {getattr(m,\\\"__version__\\\",\\\"n/a\\\")}')
    except Exception as e: print(f'{mod:14s} MISSING {type(e).__name__}')
\""
note "--- BLAS / thread pool config ---"
run "python3 -c \"
try:
    from threadpoolctl import threadpool_info
    for i in threadpool_info(): print(i)
except Exception as e: print('threadpoolctl unavailable:',e)
import os
for v in ['OMP_NUM_THREADS','MKL_NUM_THREADS','OPENBLAS_NUM_THREADS']:
    print(v,'=',os.environ.get(v,'unset'))
\""
echo "  [05] python env"

# ===========================================================================
sec 06_filesystem.txt "FILESYSTEM: mounts, capacity, write/read/delete matrix"
# ===========================================================================
run "mount"
run "findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS"
run "df -hT"
run "df -i"
note "--- write/read/delete matrix ---"
for d in /home/user /tmp /dev/shm /var/tmp /opt /usr/local /etc /root /; do
  f="$d/.__probe_wtest_$$"
  if echo "probe-canary" > "$f" 2>/dev/null; then
    c="$(cat "$f" 2>/dev/null)"
    if rm -f "$f" 2>/dev/null; then del=OK; else del=FAIL; fi
    printf '%-12s WRITE=OK      READ=%-14s DELETE=%s\n' "$d" "$c" "$del"
  else
    err="$( { echo x > "$f"; } 2>&1 | head -1 )"
    printf '%-12s WRITE=DENIED  %s\n' "$d" "$err"
  fi
done >> "$CUR"
note ""
note "--- read-only mounts ---"
run "findmnt -o TARGET,FSTYPE,OPTIONS | grep -E '\\bro\\b' || echo '(none beyond credential ramfs)'"
note "--- tmpfs are RAM-backed: these consume the memory budget ---"
run "df -h /tmp /dev/shm /run /home/user"
echo "  [06] filesystem"

# ===========================================================================
sec 07_dns.txt "NETWORK: DNS resolution timing"
# ===========================================================================
run "cat /etc/resolv.conf"
run "cat /etc/hosts"
run "ip -br addr"
run "ip route"
run "python3 -c \"
import socket,time
hosts=['google.com','github.com','pypi.org','huggingface.co','files.pythonhosted.org','objects.githubusercontent.com','cdn.jsdelivr.net','registry.npmjs.org','deb.debian.org']
print(f'{\\\"host\\\":32s} {\\\"resolved\\\":20s} {\\\"cold_ms\\\":>9s} {\\\"warm_ms\\\":>9s}')
for h in hosts:
    ts=[]; res='?'
    for i in range(3):
        t0=time.perf_counter()
        try: res=socket.gethostbyname(h)
        except Exception as e: res='FAIL:'+type(e).__name__
        ts.append((time.perf_counter()-t0)*1000)
    print(f'{h:32s} {res:20s} {ts[0]:9.2f} {min(ts[1:]):9.2f}')
\""
echo "  [07] dns"

# ===========================================================================
sec 08_net_latency.txt "NETWORK: latency (curl phase breakdown, best-of-5)"
# ===========================================================================
note "METHOD NOTE: time_connect is measured to the LOCAL EGRESS PROXY, not the"
note "origin, so it is ~1-2 ms to every host worldwide and is NOT real RTT."
note "TLS 1.3 handshake is end-to-end => est_rtt = (appconnect - connect) / 2."
note ""
printf '%-42s %8s %8s %8s %8s %8s %10s\n' ENDPOINT DNSms TCPms TLSms TTFBms TOTALms EST_RTTms >> "$CUR"
for u in https://www.google.com/generate_204 https://github.com https://pypi.org/simple/ \
         https://huggingface.co https://registry.npmjs.org/ \
         https://cdn.jsdelivr.net/npm/lodash@4.17.21/package.json \
         https://deb.debian.org/debian/dists/trixie/Release https://files.pythonhosted.org/ ; do
  for i in 1 2 3 4 5; do
    curl -sS -o /dev/null -w '%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}\n' \
      --max-time 20 "$u" 2>/dev/null
  done | awk -v u="$u" '
    {n++; for(i=1;i<=5;i++){ if(m[i]==""||$i<m[i]) m[i]=$i }}
    END{ if(n>0) printf "%-42s %8.2f %8.2f %8.2f %8.2f %8.2f %10.2f\n", substr(u,1,42),
         m[1]*1000,m[2]*1000,m[3]*1000,m[4]*1000,m[5]*1000,(m[3]-m[2])*1000/2;
         else printf "%-42s   ALL-FAILED\n", substr(u,1,42) }' >> "$CUR"
done
note ""
note "--- negotiated protocol / TLS ---"
for h in https://www.google.com https://github.com https://huggingface.co; do
  run "curl -sS -o /dev/null -w 'http_version=%{http_version} ssl_verify=%{ssl_verify_result}\n' --max-time 15 $h"
done
run "echo | openssl s_client -connect pypi.org:443 2>/dev/null | grep -E 'Protocol|Cipher|Verify return|^ *[01] s:|issuer' | head -8"
run "env | grep -i proxy || echo 'no *_proxy env vars set'"
echo "  [08] latency"

# ===========================================================================
sec 09_net_matrix.txt "NETWORK: throughput + egress port reachability matrix"
# ===========================================================================
note "=== THROUGHPUT (real artifacts, 2 samples each) ==="
printf '%-46s %12s %10s %12s %6s\n' TARGET BYTES TIME_s MBps HTTP >> "$CUR"
dl() {  # dl <label> <url>
  for i in 1 2; do
    curl -sSL -o /dev/null -w "$1|%{size_download}|%{time_total}|%{speed_download}|%{http_code}\n" \
      --max-time 180 "$2" 2>/dev/null
  done | awk -F'|' '{printf "%-46s %12d %10.3f %12.2f %6s\n", $1, $2, $3, $4/1048576, $5}' >> "$CUR"
}
dl "cloudflare-50MB"        "https://speed.cloudflare.com/__down?bytes=52428800"
dl "cloudflare-10MB"        "https://speed.cloudflare.com/__down?bytes=10485760"
dl "pypi-numpy-wheel"       "$(curl -sS --max-time 30 https://pypi.org/pypi/numpy/json 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print([u['url'] for u in d['urls'] if 'cp313' in u['filename'] and 'manylinux' in u['filename'] and 'x86_64' in u['filename']][0])" 2>/dev/null || echo https://pypi.org/)"
dl "github-release-gitlfs"  "https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-linux-amd64-v3.5.1.tar.gz"
dl "huggingface-bert-tiny"  "https://huggingface.co/prajjwal1/bert-tiny/resolve/main/pytorch_model.bin"

note ""
note "=== EGRESS PORT MATRIX ==="
note "PART A - naive TCP connect() -- UNRELIABLE, proxy accepts optimistically."
note "Reported 'OPEN' here does NOT prove end-to-end reachability."
run "python3 -c \"
import socket,time
tests=[('8.8.8.8',53),('1.1.1.1',53),('google.com',80),('google.com',443),('github.com',22),('github.com',9418),('smtp.gmail.com',25),('smtp.gmail.com',587),('irc.libera.chat',6667),('google.com',8080),('google.com',3389)]
for host,port in tests:
    t0=time.perf_counter()
    try:
        s=socket.create_connection((host,port),timeout=6); s.close(); r='OPEN'
    except Exception as e: r='FAIL:'+type(e).__name__
    print(f'{host:24s}:{port:<6d} {r:20s} {(time.perf_counter()-t0)*1000:8.1f} ms')
\""
note "PART B - REAL protocol handshake (does data actually flow?) -- AUTHORITATIVE"
run "python3 -c \"
import socket,time
def probe(host,port,label,send=None,timeout=8):
    t0=time.perf_counter()
    try:
        s=socket.create_connection((host,port),timeout=timeout); s.settimeout(timeout)
        if send: s.send(send)
        data=s.recv(120); s.close()
        print(f'{label:22s} {host}:{port:<6d} DATA_OK {(time.perf_counter()-t0)*1000:8.1f} ms  {data[:58]!r}')
    except Exception as e:
        print(f'{label:22s} {host}:{port:<6d} NO_DATA {(time.perf_counter()-t0)*1000:8.1f} ms  {type(e).__name__}')
probe('github.com',22,'SSH banner')
probe('smtp.gmail.com',25,'SMTP banner')
probe('smtp.gmail.com',587,'submission banner')
probe('irc.libera.chat',6667,'IRC banner',send=b'NICK p\\r\\nUSER p 0 * :p\\r\\n')
probe('google.com',80,'HTTP',send=b'HEAD / HTTP/1.0\\r\\nHost: google.com\\r\\n\\r\\n')
probe('google.com',3389,'RDP (ctrl: no svc)',send=b'\\x03\\x00\\x00\\x13')
probe('google.com',8080,'HTTP-alt (ctrl)',send=b'HEAD / HTTP/1.0\\r\\n\\r\\n')
\""
note "PART C - portquiz.net listens on ALL ports => true egress filter test"
for p in 80 443 22 25 587 8080 3389 9418 1234 31337 65000; do
  r="$(timeout 12 curl -sS -o /dev/null -w '%{http_code}' --max-time 10 "http://portquiz.net:$p/" 2>&1)"
  printf 'portquiz.net:%-6s -> %s\n' "$p" "$r" >> "$CUR"
done
note "PART D - UDP egress"
run "python3 -c \"
import socket,time
q=b'\\xaa\\xbb\\x01\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x06google\\x03com\\x00\\x00\\x01\\x00\\x01'
for dns in ['8.8.8.8','1.1.1.1','9.9.9.9']:
    s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(5); t0=time.perf_counter()
    try:
        s.sendto(q,(dns,53)); d,_=s.recvfrom(512)
        print(f'UDP/53 -> {dns:10s} OK   {(time.perf_counter()-t0)*1000:7.1f} ms  {len(d)} bytes')
    except Exception as e: print(f'UDP/53 -> {dns:10s} FAIL {type(e).__name__}')
    s.close()
\""
note "PART E - IPv6 + egress identity"
run "curl -6 -sS -o /dev/null -w 'ipv6 http=%{http_code}\n' --max-time 10 https://ipv6.google.com"
run "curl -sS --max-time 15 https://api.ipify.org; echo"
echo "  [09] net matrix"

# ===========================================================================
sec 10_net_anomalies.txt "NETWORK ANOMALIES: ICMP, npm audit black-hole, POST"
# ===========================================================================
note "=== ICMP (expected: blocked for unprivileged uid, no cap_net_raw) ==="
for h in 8.8.8.8 google.com; do run "timeout 12 ping -c 3 -W 3 $h"; done
run "sudo timeout 12 ping -c 3 -W 3 8.8.8.8"
run "getcap /usr/bin/ping"

note "=== npm audit endpoint black-hole ==="
note "Run 1 (2026-09-04) observed: 'npm audit' = 420.658 s wall / 0.55 s CPU."
note "Probe below is BOUNDED to 60 s unless FULL=1. TLS completes, body never arrives."
NPM_T=60; [ "$FULL" = "1" ] && NPM_T=480
run "curl -sS -o /dev/null -w 'audit-bulk POST http=%{http_code} connect=%{time_connect}s tls=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s\n' --max-time $NPM_T -X POST -H 'Content-Type: application/json' -d '{\"lodash\":[\"4.17.21\"]}' https://registry.npmjs.org/-/npm/v1/security/advisories/bulk"
run "curl -sS -o /dev/null -w 'registry GET  http=%{http_code} ttfb=%{time_starttransfer}s total=%{time_total}s\n' --max-time 60 https://registry.npmjs.org/lodash"
run "curl -sS -o /dev/null -w 'tarball GET   http=%{http_code} ttfb=%{time_starttransfer}s total=%{time_total}s size=%{size_download}\n' --max-time 60 https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"
run "npm config get registry; npm config get audit; npm config get fund"

note "=== Is POST blocked generally? (control group) ==="
for spec in "POST-httpbin|-X POST -d {\"a\":1} -H Content-Type:application/json https://httpbin.org/post" ; do :; done
run "curl -sS -o /dev/null -w 'POST httpbin.org      http=%{http_code} ttfb=%{time_starttransfer}s\n' --max-time 25 -X POST -d '{\"a\":1}' -H 'Content-Type: application/json' https://httpbin.org/post"
run "curl -sS -o /dev/null -w 'POST postman-echo     http=%{http_code} ttfb=%{time_starttransfer}s\n' --max-time 25 -X POST -d '{\"a\":1}' -H 'Content-Type: application/json' https://postman-echo.com/post"
run "curl -sS -o /dev/null -w 'POST httpbingo.org    http=%{http_code} ttfb=%{time_starttransfer}s\n' --max-time 25 -X POST -d '{\"a\":1}' -H 'Content-Type: application/json' https://httpbingo.org/post"
run "curl -sS -o /dev/null -w 'PUT  httpbingo.org    http=%{http_code} ttfb=%{time_starttransfer}s\n' --max-time 25 -X PUT -d '{\"a\":1}' https://httpbingo.org/put"
run "curl -sS -o /dev/null -w 'POST api.github.com   http=%{http_code} ttfb=%{time_starttransfer}s (403=auth reject, request DID arrive)\n' --max-time 25 -X POST -d '{\"query\":\"{viewer{login}}\"}' https://api.github.com/graphql"
echo "  [10] anomalies"

# ===========================================================================
sec 11_bench_cpu.txt "BENCHMARK: CPU (pure python, numpy, pandas, scaling)"
# ===========================================================================
note "Method: time.perf_counter(), best-of-3 unless noted. Units: milliseconds."
run "python3 $BASE/bench_cpu.py"
echo "  [11] cpu bench"

# ===========================================================================
sec 12_bench_disk.txt "BENCHMARK: disk sequential / random / metadata"
# ===========================================================================
note "Method: dd with conv=fdatasync (forces flush) and oflag=direct (bypass cache)."
note "Page cache dropped between cold/warm reads via /proc/sys/vm/drop_caches."
for d in /home/user /tmp /dev/shm; do
  note "--- $d : 100 MiB ---"
  run "dd if=/dev/zero of=$d/_ddtest bs=1M count=100 conv=fdatasync 2>&1 | tail -1"
  run "sync; sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null; dd if=$d/_ddtest of=/dev/null bs=1M 2>&1 | tail -1"
  run "dd if=$d/_ddtest of=/dev/null bs=1M 2>&1 | tail -1"
  run "rm -f $d/_ddtest"
done
note "--- O_DIRECT 100 MiB on /home/user (bypasses page cache) ---"
run "dd if=/dev/zero of=/home/user/_odirect bs=1M count=100 oflag=direct 2>&1 | tail -1; rm -f /home/user/_odirect"
if [ "$QUICK" != "1" ]; then
  note "--- 2 GiB sequential write on /home/user (headroom check) ---"
  run "df -h /home/user | tail -1"
  run "dd if=/dev/zero of=/home/user/_big.bin bs=1M count=2048 conv=fdatasync 2>&1 | tail -1"
  run "df -h /home/user | tail -1; rm -f /home/user/_big.bin"
fi
note "--- metadata ops: 5000 small file create/delete ---"
run "python3 -c \"
import os,time,shutil
d='/home/user/_probe_manyfiles'; shutil.rmtree(d,ignore_errors=True); os.makedirs(d)
t0=time.perf_counter()
for i in range(5000): open(f'{d}/f{i}','wb').write(b'x'*512)
el=time.perf_counter()-t0; print(f'create 5000 files: {el:.3f} s = {5000/el:,.0f} files/s')
t0=time.perf_counter(); shutil.rmtree(d); print(f'delete 5000 files: {time.perf_counter()-t0:.3f} s')
\""
echo "  [12] disk bench"

# ===========================================================================
sec 13_bench_install.txt "BENCHMARK: package install / compile timings"
# ===========================================================================
note "NOTE: these MUTATE the image. Packages are uninstalled afterwards where possible."
run "pip uninstall -y -q tabulate duckdb polars ujson"
timed "pip-pure"    "pip install -q --no-cache-dir tabulate"
timed "pip-wheel"   "pip install -q --no-cache-dir duckdb"
timed "pip-wheel2"  "pip install -q --no-cache-dir polars"
if [ "$QUICK" != "1" ]; then
  timed "pip-sdist-compile" "pip install -q --no-cache-dir --no-binary :all: ujson"
fi
run "python3 -c 'import tabulate,duckdb,polars; print(\"installed:\",tabulate.__version__,duckdb.__version__,polars.__version__)'"
run "pip uninstall -y -q tabulate duckdb polars ujson"

note "--- compilation ---"
cat > /tmp/_probe_omp.c <<'CEOF'
#include <stdio.h>
#include <omp.h>
int main(){ double s=0;
#pragma omp parallel for reduction(+:s)
for(long i=0;i<100000000L;i++) s+=1.0/(i+1);
printf("sum=%f threads=%d\n",s,omp_get_max_threads()); return 0;}
CEOF
timed "gcc-openmp-compile" "gcc -O2 -fopenmp /tmp/_probe_omp.c -o /tmp/_probe_omp"
timed "gcc-openmp-run"     "/tmp/_probe_omp"
echo 'int main(){return 0;}' > /tmp/_probe.cpp
timed "gpp-compile" "g++ -O2 -std=c++17 /tmp/_probe.cpp -o /tmp/_probe_cpp"

note "--- apt (system packages) ---"
timed "apt-update" "sudo apt-get update -qq"
timed "apt-reinstall-jq" "sudo DEBIAN_FRONTEND=noninteractive apt-get install --reinstall -y -qq jq"

note "--- npm: default flags vs --no-audit --no-fund ---"
note "Run 1 measured 421.098 s (default) vs 3.945 s (--no-audit --no-fund), cold cache."
run "rm -rf /tmp/_np && mkdir -p /tmp/_np && echo '{\"name\":\"p\",\"version\":\"1.0.0\"}' > /tmp/_np/package.json"
timed "npm-no-audit" "(cd /tmp/_np && npm install --silent --no-audit --no-fund express)"
if [ "$FULL" = "1" ]; then
  run "rm -rf /tmp/_np2 && mkdir -p /tmp/_np2 && echo '{\"name\":\"p\",\"version\":\"1.0.0\"}' > /tmp/_np2/package.json"
  timed "npm-DEFAULT-flags-SLOW" "(cd /tmp/_np2 && npm install --silent express)"
else
  note "[skipped npm-with-audit: set FULL=1 to reproduce the ~420 s hang]"
fi
run "rm -rf /tmp/_np /tmp/_np2"

note "--- git clone ---"
timed "git-clone-flask"  "rm -rf /tmp/_gc && git clone -q --depth 1 https://github.com/pallets/flask /tmp/_gc"
timed "git-clone-numpy"  "rm -rf /tmp/_gc2 && git clone -q --depth 1 https://github.com/numpy/numpy /tmp/_gc2"
run "du -sh /tmp/_gc /tmp/_gc2 2>/dev/null; rm -rf /tmp/_gc /tmp/_gc2"
echo "  [13] install bench"

# ===========================================================================
sec 14_memory_oom.txt "MEMORY: allocation ceiling and OOM behaviour"
# ===========================================================================
note "Method: subprocess allocates AND TOUCHES every 4096th byte to defeat lazy"
note "overcommit. rc=-9 means SIGKILL by the kernel OOM killer."
run "free -m"
run "python3 -c \"
import subprocess,sys
code='''
import sys
mb=int(sys.argv[1])
try:
    b=bytearray(mb*1024*1024)
    for i in range(0,len(b),4096): b[i]=1
    print(f'  {mb} MB: ALLOCATED+TOUCHED OK')
except MemoryError:
    print(f'  {mb} MB: MemoryError (refused)')
'''
for mb in [256,512,1024,1500,1800,2500,4000]:
    p=subprocess.run([sys.executable,'-c',code,str(mb)],capture_output=True,text=True,timeout=300)
    if p.returncode!=0: print(f'  {mb} MB: KILLED rc={p.returncode} (SIGKILL=-9)')
    else: print((p.stdout or '').rstrip())
\""
run "sudo dmesg 2>/dev/null | grep -iE 'oom|killed process|out of memory' | tail -8"
run "free -m"
echo "  [14] memory"

# ===========================================================================
sec 15_processes.txt "PROCESSES: background jobs, servers, platform services"
# ===========================================================================
run "ps aux | head -30"
run "systemctl list-units --type=service --state=running --no-pager"
run "ss -ltnp"
note "--- detached background job survives parent exit? ---"
run "rm -f /tmp/_probe_bg.log; nohup bash -c 'for i in \$(seq 1 20); do echo tick \$i \$(date +%s) >> /tmp/_probe_bg.log; sleep 1; done' >/dev/null 2>&1 & echo launched pid \$!"
run "sleep 4; echo \"lines after 4 s: \$(wc -l < /tmp/_probe_bg.log)\"; cat /tmp/_probe_bg.log"
note "--- bind a server on 0.0.0.0 and hit it ---"
run "(python3 -m http.server 877 --bind 0.0.0.0 >/tmp/_probe_srv.log 2>&1 &) ; sleep 2; curl -sS -o /dev/null -w 'localhost:877 http=%{http_code} time=%{time_total}s\n' --max-time 10 http://localhost:877/"
run "pkill -f 'http.server 877'; echo server_stopped"
if [ "$QUICK" != "1" ]; then
  note "--- sustained CPU: throttling check, 3 x 10 s windows ---"
  run "python3 -c \"
import time
def burn(sec):
    t0=time.perf_counter(); n=0
    while time.perf_counter()-t0 < sec:
        for i in range(100000): pass
        n+=1
    return n
res=[burn(10) for _ in range(3)]
for i,r in enumerate(res): print(f'  window {i+1}: {r} units')
print(f'drift first->last: {100*(res[-1]-res[0])/res[0]:+.1f}%')
\""
fi
echo "  [15] processes"

# ===========================================================================
sec 16_env_config.txt "ENVIRONMENT: injected variables & platform config"
# ===========================================================================
run "env | sort"
run "cat /etc/hosts"
run "ls -la /home/user"
run "ls -la /home/user/.config 2>/dev/null"
run "findmnt -o TARGET,SOURCE,FSTYPE /etc/ssl/certs"
note "NOTE: /etc/ssl/certs on tmpfs => custom CAs do NOT survive reboot."
run "cat /home/user/PERSISTENCE_MARKER.txt 2>/dev/null || echo '(no prior marker)'"
run "cat /tmp/PERSISTENCE_MARKER_TMP.txt 2>/dev/null || echo '(tmpfs marker absent - expected after reboot)'"
note "--- writing fresh persistence markers for the NEXT run ---"
run "echo \"written_at=$(date -u +%FT%TZ) boot_id=$(cat /proc/sys/kernel/random/boot_id) sandbox=$SBX uptime=$(cut -d' ' -f1 /proc/uptime)\" | tee /home/user/PERSISTENCE_MARKER.txt"
run "echo \"tmp_written_at=$(date -u +%FT%TZ) sandbox=$SBX\" | tee /tmp/PERSISTENCE_MARKER_TMP.txt"
echo "  [16] env config"

# ===========================================================================
# MANIFEST
# ===========================================================================
cd "$BASE" || cd / # cwd may be a deleted dir after clone/npm probes
MAN="$RUN/MANIFEST.json"
{
  echo "{"
  echo "  \"probe_version\": \"$PROBE_VERSION\","
  echo "  \"run_utc\": \"$RUN_UTC\","
  echo "  \"generated_utc\": \"$(date -u +%FT%TZ)\","
  echo "  \"sandbox_id\": \"${E2B_SANDBOX_ID:-unknown}\","
  echo "  \"template_id\": \"${E2B_TEMPLATE_ID:-unknown}\","
  echo "  \"boot_id\": \"$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)\","
  echo "  \"hostname\": \"$(hostname)\","
  echo "  \"uptime_s_at_start\": \"$(cut -d' ' -f1 /proc/uptime)\","
  echo "  \"kernel\": \"$(uname -r)\","
  echo "  \"os\": \"$(. /etc/os-release; echo "$PRETTY_NAME")\","
  echo "  \"arch\": \"$(uname -m)\","
  echo "  \"libc\": \"$(ldd --version 2>&1 | head -1)\","
  echo "  \"nproc\": $(nproc),"
  echo "  \"mem_total_kb\": $(awk '/MemTotal/{print $2}' /proc/meminfo),"
  echo "  \"egress_ip\": \"$(curl -sS --max-time 15 https://api.ipify.org 2>/dev/null || echo unknown)\","
  echo "  \"mode\": \"$([ "$QUICK" = 1 ] && echo quick || { [ "$FULL" = 1 ] && echo full || echo standard; })\","
  echo "  \"files\": ["
  first=1
  for f in $(ls "$RUN"/*.txt 2>/dev/null | sort); do
    b="$(basename "$f")"
    h="$(sha256sum "$f" | cut -d' ' -f1)"
    sz="$(stat -c%s "$f")"
    ln="$(wc -l < "$f")"
    [ $first -eq 0 ] && echo ","
    first=0
    printf '    {"name": "%s", "sha256": "%s", "bytes": %s, "lines": %s}' "$b" "$h" "$sz" "$ln"
  done
  echo ""
  echo "  ]"
  echo "}"
} > "$MAN"

# plain-text checksum file (easy to diff / sha256sum -c)
( cd "$RUN" && sha256sum *.txt > SHA256SUMS.txt )

echo
echo "=========================================="
echo "Run complete: $RUN"
echo "Files:"
ls -la "$RUN"
echo
echo "Verify integrity with:  cd $RUN && sha256sum -c SHA256SUMS.txt"
exit 0
