#!/usr/bin/env bash
# Reproducible environment characterization probe.
# Produces verbatim command transcripts under runs/<UTC timestamp>/raw plus
# SHA256SUMS, manifest.txt, and manifest.json. No report/summarization is generated.
set -uo pipefail
export LC_ALL=C
export TZ=UTC

MODE=full
OUTPUT_ROOT=""
MEM_TEST_MIB="${MEM_TEST_MIB:-512}"
DISK_TEST_MIB="${DISK_TEST_MIB:-100}"

usage() {
  cat <<'EOF'
Usage: probe_environment.sh [--full|--quick] [--output-root DIR]

  --full          Run all probes (default): ~45 MB downloads, 10 MB upload,
                  temporary pip/npm installs, reversible apt install if sudo
                  works, 100 MiB disk test, and controlled memory allocation.
  --quick         Skip large transfers, apt/pip/npm install tests, and the
                  controlled memory allocation. System inspection still runs.
  --output-root   Parent directory for timestamped run directories.

Environment overrides:
  DISK_TEST_MIB   Sequential disk-test size (default: 100)
  MEM_TEST_MIB    Controlled memory allocation size (default: 512)
EOF
}

while (($#)); do
  case "$1" in
    --full) MODE=full; shift ;;
    --quick) MODE=quick; shift ;;
    --output-root) OUTPUT_ROOT=${2:?missing directory after --output-root}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd)
if [[ -z "$OUTPUT_ROOT" ]]; then OUTPUT_ROOT="$SCRIPT_DIR/runs"; fi
RUN_START_UTC=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
RUN_TAG=$(date -u +%Y%m%dT%H%M%SZ)-$$
RUN_DIR="$OUTPUT_ROOT/$RUN_TAG"
RAW="$RUN_DIR/raw"
mkdir -p "$RAW"
# Freeze the exact probe source beside every run so later edits to the canonical
# script cannot invalidate that run's script hash.
cp "$SCRIPT_PATH" "$RUN_DIR/probe_environment.sh"
chmod +x "$RUN_DIR/probe_environment.sh"

# A direct transcript helper. It prints the exact shell text, merges stdout and
# stderr, and records the command's exit status without aborting the run.
run_sh() {
  local text=$1 rc
  printf '\n$ %s\n' "$text"
  set +e
  bash -o pipefail -c "$text" 2>&1
  rc=$?
  set -e 2>/dev/null || true
  printf '[exit_code=%d]\n' "$rc"
  return 0
}

raw_header() {
  printf 'probe_run_start_utc=%s\n' "$RUN_START_UTC"
  printf 'probe_mode=%s\n' "$MODE"
  printf 'probe_script=%s\n' "$SCRIPT_PATH"
  printf 'raw_file=%s\n' "$1"
}

# The global same-run sentinel is checked again by 14_persistence.txt.
SENTINEL="$RUN_DIR/persistence_sentinel.txt"
printf 'run_tag=%s\ncreated_utc=%s\npid=%s\n' "$RUN_TAG" "$RUN_START_UTC" "$$" > "$SENTINEL"

{
  raw_header 01_runtime.txt
  run_sh 'date --iso-8601=ns'
  run_sh 'date -u --iso-8601=ns'
  run_sh 'pwd; printf "HOME=%s\\nSHELL=%s\\nUSER=%s\\nLOGNAME=%s\\n" "${HOME-<unset>}" "${SHELL-<unset>}" "${USER-<unset>}" "${LOGNAME-<unset>}"'
  run_sh 'id; whoami; groups; umask; hostname'
  run_sh 'uname -a; uname -r; uname -m; uname -p'
  run_sh 'cat /etc/os-release'
  run_sh 'getconf GNU_LIBC_VERSION; ldd --version | head -n 4; getconf LONG_BIT; getconf PAGE_SIZE'
  run_sh 'python3 -c '\''import platform,sys; print(sys.version); print(platform.platform()); print(platform.libc_ver()); print(sys.executable)'\'''
  run_sh 'uptime; cat /proc/uptime; cat /proc/loadavg'
  run_sh 'timedatectl'
  run_sh 'printf "E2B_SANDBOX=%s\\n" "${E2B_SANDBOX-<unset>}"; env | cut -d= -f1 | sort'
} > "$RAW/01_runtime.txt"

{
  raw_header 02_isolation.txt
  run_sh 'for f in /.dockerenv /run/.containerenv; do if test -e "$f"; then ls -l "$f"; else echo "$f absent"; fi; done'
  run_sh 'systemd-detect-virt; systemd-detect-virt --container; systemd-detect-virt --vm'
  run_sh 'findmnt -n -o SOURCE,FSTYPE,OPTIONS /; stat -f -c "%T" /'
  run_sh 'cat /proc/1/cgroup; cat /proc/self/cgroup'
  run_sh 'grep -E "^(Name|Pid|PPid|Uid|Gid|NSpid|NoNewPrivs|Seccomp|Seccomp_filters|Cap(Inh|Prm|Eff|Bnd|Amb)):" /proc/1/status'
  run_sh 'grep -E "^(Name|Pid|PPid|Uid|Gid|NSpid|NoNewPrivs|Seccomp|Seccomp_filters|Cap(Inh|Prm|Eff|Bnd|Amb)):" /proc/$$/status'
  run_sh 'sudo -n sh -c '\''grep -E "^(Name|Pid|PPid|Uid|Gid|NSpid|NoNewPrivs|Seccomp|Seccomp_filters|Cap(Inh|Prm|Eff|Bnd|Amb)):" /proc/$$/status'\'''
  run_sh 'sudo -n ls -l /proc/1/ns /proc/$$/ns'
  run_sh 'ps -ef --forest'
  run_sh 'lsns'
  run_sh 'printf "lsm="; cat /sys/kernel/security/lsm; printf "selinux_enforce="; cat /sys/fs/selinux/enforce'
  run_sh 'unshare -Ur true'
  run_sh 'sudo -n unshare -m true'
  run_sh 'for p in /dev/kvm /dev/fuse /var/run/docker.sock /run/docker.sock /run/containerd/containerd.sock; do if test -e "$p"; then ls -l "$p"; else echo "$p absent"; fi; done'
  run_sh 'sudo -n dmesg | grep -Ei "hypervisor|kvm|virtio|e2b" | head -n 80'
} > "$RAW/02_isolation.txt"

{
  raw_header 03_resources.txt
  run_sh 'ulimit -a'
  run_sh 'prlimit --pid $$'
  run_sh 'nproc; nproc --all; lscpu'
  run_sh 'free -b; cat /proc/meminfo'
  run_sh 'CG=$(awk -F: '\''$1=="0"{print $3}'\'' /proc/self/cgroup); echo "cgroup=$CG"; D="/sys/fs/cgroup$CG"; for f in cgroup.controllers cgroup.events cpu.max cpu.max.burst cpu.weight cpu.stat cpuset.cpus cpuset.cpus.effective cpuset.mems.effective memory.max memory.high memory.current memory.peak memory.swap.max memory.swap.current memory.events memory.stat pids.max pids.current pids.events io.max io.stat cpu.pressure memory.pressure io.pressure; do echo "[$f]"; cat "$D/$f" 2>&1; done'
  run_sh 'for f in /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io; do echo "[$f]"; cat "$f" 2>&1; done'
  run_sh 'echo "before soft=$(ulimit -Sn) hard=$(ulimit -Hn)"; ulimit -Sn "$(ulimit -Hn)"; echo "after soft=$(ulimit -Sn) hard=$(ulimit -Hn)"'
  run_sh 'command -v nvidia-smi && nvidia-smi'
} > "$RAW/03_resources.txt"

{
  raw_header 04_tooling.txt
  # Each probe is independent so absent tools are recorded rather than hidden.
  for spec in \
    'python3 --version' 'python --version' 'pip3 --version' 'pip --version' \
    'node --version' 'npm --version' 'npx --version' 'corepack --version' \
    'git --version' 'curl --version' 'wget --version' \
    'ffmpeg -version' 'ffprobe -version' 'docker --version' 'podman --version' \
    'make --version' 'gcc --version' 'g++ --version' 'clang --version' 'clang++ --version' \
    'cmake --version' 'ninja --version' 'pkg-config --version' 'jq --version' \
    'apt --version' 'apt-get --version' 'dpkg --version' 'apk --version' 'yum --version' 'dnf --version' \
    'conda --version' 'mamba --version' 'micromamba --version' 'uv --version' 'pipx --version' 'poetry --version' \
    'go version' 'rustc --version' 'cargo --version' 'java -version' 'javac -version' 'R --version' \
    'ruby --version' 'perl -v' 'php --version' 'sqlite3 --version' \
    'tar --version' 'unzip -v' 'rsync --version' '7z' 'aria2c --version' \
    'ssh -V' 'openssl version' 'ping -V' 'dig -v' 'host -V' 'nslookup -version' 'nc -h' 'socat -V' \
    'fio --version' 'hyperfine --version' 'stress-ng --version' 'pandoc --version'; do
      tool=${spec%% *}
      run_sh "command -v $tool; $spec"
  done
} > "$RAW/04_tooling.txt"

{
  raw_header 05_packages.txt
  run_sh 'python3 -m pip list --format=freeze'
  run_sh 'python3 - <<'\''PY'\''
import importlib.util, importlib.metadata as md
for name in ["numpy","pandas","scipy","requests","httpx","aiohttp","pyarrow","polars","torch","tensorflow","sklearn","matplotlib","PIL","bs4","lxml","jupyter","notebook"]:
    spec=importlib.util.find_spec(name)
    print(name, "origin="+(str(spec.origin) if spec else "ABSENT"))
    if spec:
        dist={"sklearn":"scikit-learn","PIL":"Pillow","bs4":"beautifulsoup4"}.get(name,name)
        try: print(name,"version="+md.version(dist))
        except Exception as e: print(name,"version_error="+repr(e))
PY'
  run_sh 'npm list -g --depth=0'
  run_sh 'find /etc/apt -maxdepth 2 -type f -name "*.list" -o -name "*.sources" | sort | while read f; do echo "### $f"; cat "$f"; done'
} > "$RAW/05_packages.txt"

{
  raw_header 06_filesystem.txt
  run_sh 'pwd; printf "HOME=%s TMPDIR=%s\\n" "${HOME-<unset>}" "${TMPDIR-<unset>}"'
  run_sh 'df -hT / "$HOME" /tmp /var/tmp /dev/shm; df -B1 / "$HOME" /tmp /var/tmp /dev/shm; df -i / "$HOME" /tmp /var/tmp /dev/shm'
  run_sh 'findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS'
  run_sh 'findmnt -rn -o TARGET,SOURCE,FSTYPE,OPTIONS | awk '\''$4 ~ /(^|,)ro(,|$)/ {print}'\'''
  run_sh 'for d in / /home "$HOME" /tmp /var/tmp /dev/shm /root /usr/local /etc /proc /sys; do echo "[$d]"; stat -c "mode=%A (%a) owner=%U:%G size=%s dev=%d inode=%i" "$d" 2>&1; findmnt -n -T "$d" -o TARGET,SOURCE,FSTYPE,OPTIONS 2>&1; done'
  run_sh 'python3 - <<'\''PY'\''
from pathlib import Path
import uuid
payload=("envprobe-"+uuid.uuid4().hex).encode()
for loc in [str(Path.home()),"/tmp","/var/tmp","/dev/shm","/","/root","/usr/local","/proc","/sys"]:
    p=Path(loc)/(".envprobe_"+uuid.uuid4().hex)
    try:
        p.write_bytes(payload); got=p.read_bytes(); p.unlink()
        print(loc,"WRITE_READ_DELETE_OK",len(got),got==payload)
    except Exception as e:
        try: p.unlink(missing_ok=True)
        except Exception: pass
        print(loc,"FAILED",type(e).__name__,str(e))
PY'
  run_sh 'for d in /root /usr/local /etc /sys /proc; do f="$d/.envprobe_sudo_$$"; if sudo -n sh -c "printf test > '\''$f'\'' && test \"\$(cat '\''$f'\'')\" = test && rm -f '\''$f'\''"; then echo "$d ROOT_WRITE_READ_DELETE_OK"; else echo "$d ROOT_TEST_FAILED rc=$?"; sudo -n rm -f "$f" 2>/dev/null; fi; done'
} > "$RAW/06_filesystem.txt"

{
  raw_header 07_dns.txt
  run_sh 'cat /etc/resolv.conf; cat /etc/hosts; ip -brief address; ip route; ip -6 route'
  run_sh 'python3 - <<'\''PY'\''
import socket,time,random,struct
hosts=["google.com","github.com","pypi.org","huggingface.co"]
for host in hosts:
    for i in range(5):
        t=time.perf_counter_ns()
        try:
            ans=socket.getaddrinfo(host,443,type=socket.SOCK_STREAM)
            ips=sorted({x[4][0] for x in ans}); status="ok"
        except Exception as e:
            ips=[];status=type(e).__name__+":"+str(e)
        print("getaddrinfo",host,i+1,status,f"{(time.perf_counter_ns()-t)/1e6:.3f} ms",",".join(ips))

def query(server,name="google.com"):
    tid=random.randrange(65536)
    q=struct.pack("!HHHHHH",tid,0x100,1,0,0,0)+b"".join(bytes([len(x)])+x.encode() for x in name.split("."))+b"\0"+struct.pack("!HH",1,1)
    s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(2);t=time.perf_counter_ns()
    try:
        s.sendto(q,(server,53));data,peer=s.recvfrom(4096)
        h=struct.unpack("!HHHHHH",data[:12])
        print("udp_dns",server,f"{(time.perf_counter_ns()-t)/1e6:.3f} ms",f"bytes={len(data)} answers={h[3]} rcode={h[1]&15} peer={peer[0]}")
    except Exception as e: print("udp_dns",server,f"{(time.perf_counter_ns()-t)/1e6:.3f} ms",type(e).__name__,str(e))
    finally:s.close()
for _ in range(3): query("8.8.8.8")
PY'
  run_sh 'for h in google.com 8.8.8.8 github.com pypi.org huggingface.co; do echo "### $h"; sudo -n ping -n -4 -c 3 -W 2 "$h"; done'
} > "$RAW/07_dns.txt"

{
  raw_header 08_http_latency.txt
  run_sh 'for n in HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy; do eval "v=\${$n-}"; if test -n "$v"; then echo "$n=set"; else echo "$n=unset"; fi; done'
  run_sh 'for u in http://google.com/generate_204 http://example.com/ http://github.com/; do echo "### $u"; curl -4 -sS -D - -o /dev/null --max-time 12 "$u"; done'
  run_sh 'python3 - <<'\''PY'\''
import subprocess
probes=[
("google.com","https://www.google.com/robots.txt",[]),
("github.com","https://github.com/robots.txt",[]),
("pypi.org","https://pypi.org/simple/pip/",[]),
("huggingface.co","https://huggingface.co/robots.txt",[]),
("8.8.8.8-DoH","https://dns.google/resolve?name=example.com&type=A",["--resolve","dns.google:443:8.8.8.8"]),
]
fmt="code=%{http_code} http=%{http_version} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects} verify=%{ssl_verify_result}"
for label,url,extra in probes:
    for i in range(1,4):
        p=subprocess.run(["curl","-4","-sS","-L","--compressed","--connect-timeout","6","--max-time","30","-H","Cache-Control: no-cache",*extra,"-o","/dev/null","-w",fmt,url],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        print(label,i,"rc="+str(p.returncode),p.stdout)
PY'
} > "$RAW/08_http_latency.txt"

{
  raw_header 09_net_matrix.txt
  run_sh 'python3 - <<'\''PY'\''
import socket,time
T=[("google.com",80),("google.com",443),("8.8.8.8",53),("8.8.8.8",443),("github.com",22),("github.com",80),("github.com",443),("github.com",9418),("pypi.org",80),("pypi.org",443),("huggingface.co",80),("huggingface.co",443)]
for host,port in T:
  for i in range(2):
    t=time.perf_counter_ns()
    try:
      with socket.create_connection((host,port),timeout=3) as s: print(host,port,i+1,"connected",f"{(time.perf_counter_ns()-t)/1e6:.3f} ms","peer="+s.getpeername()[0])
    except Exception as e: print(host,port,i+1,"failed",f"{(time.perf_counter_ns()-t)/1e6:.3f} ms",type(e).__name__,str(e))
PY'
  run_sh 'GIT_TERMINAL_PROMPT=0 timeout 30 git -c credential.helper= ls-remote https://github.com/git/git.git HEAD'
  run_sh 'GIT_TERMINAL_PROMPT=0 timeout 30 git ls-remote git://github.com/git/git.git HEAD'
  run_sh 'timeout 15 ssh -4 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -T git@github.com'
  run_sh 'for h in google.com github.com pypi.org huggingface.co; do echo "### $h"; curl -6 -sS -o /dev/null --connect-timeout 3 --max-time 5 -w "code=%{http_code} remote=%{remote_ip} connect=%{time_connect} total=%{time_total}\\n" "https://$h/"; echo rc=$?; done'
} > "$RAW/09_net_matrix.txt"

{
  raw_header 10_throughput.txt
  if [[ "$MODE" == quick ]]; then
    echo 'SKIPPED: large transfer tests disabled by --quick'
  else
    TMPBASE=$(mktemp -d /tmp/envprobe-downloads.XXXXXX)
    trap 'rm -rf "$TMPBASE"' EXIT
    run_sh 'curl -4 -sS -L --range 0-4999999 --max-filesize 10000000 --connect-timeout 10 --max-time 120 -o '"$TMPBASE"'/google.bin -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects}\\n" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; stat -c "size=%s blocks=%b" '"$TMPBASE"'/google.bin; sha256sum '"$TMPBASE"'/google.bin; file '"$TMPBASE"'/google.bin'
    run_sh 'curl -4 -sS -L --max-filesize 30000000 --connect-timeout 10 --max-time 120 -o '"$TMPBASE"'/git.tar.gz -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects}\\n" https://codeload.github.com/git/git/tar.gz/refs/tags/v2.46.0; stat -c "size=%s blocks=%b" '"$TMPBASE"'/git.tar.gz; sha256sum '"$TMPBASE"'/git.tar.gz; gzip -t '"$TMPBASE"'/git.tar.gz; echo gzip_rc=$?'
    run_sh 'curl -4 -sS --max-time 30 -o '"$TMPBASE"'/numpy.json https://pypi.org/pypi/numpy/2.3.5/json; URL=$(jq -r '\''.urls[] | select(.packagetype=="bdist_wheel") | select(.filename|contains("cp313")) | select(.filename|contains("manylinux")) | select(.filename|contains("x86_64")) | .url'\'' '"$TMPBASE"'/numpy.json | head -n1); echo "URL=$URL"; curl -4 -sS -L --max-filesize 30000000 --connect-timeout 10 --max-time 120 -o '"$TMPBASE"'/numpy.whl -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects}\\n" "$URL"; stat -c "size=%s blocks=%b" '"$TMPBASE"'/numpy.whl; sha256sum '"$TMPBASE"'/numpy.whl; python3 -m zipfile -t '"$TMPBASE"'/numpy.whl'
    run_sh 'curl -4 -sS -L --max-filesize 10000000 --connect-timeout 10 --max-time 120 -o '"$TMPBASE"'/hf.bin -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects}\\n" "https://huggingface.co/sshleifer/tiny-gpt2/resolve/main/pytorch_model.bin?download=true"; stat -c "size=%s blocks=%b" '"$TMPBASE"'/hf.bin; sha256sum '"$TMPBASE"'/hf.bin; file '"$TMPBASE"'/hf.bin'
    run_sh 'curl -4 -sS -L --max-filesize 12000000 --connect-timeout 10 --max-time 120 -o '"$TMPBASE"'/cf.bin -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s bytes=%{size_download} speed_Bps=%{speed_download} redirects=%{num_redirects}\\n" "https://speed.cloudflare.com/__down?bytes=10000000"; stat -c "size=%s blocks=%b" '"$TMPBASE"'/cf.bin; sha256sum '"$TMPBASE"'/cf.bin'
    run_sh 'head -c 10000000 /dev/zero > '"$TMPBASE"'/upload.bin; curl -4 -sS --connect-timeout 10 --max-time 120 -X POST --data-binary @'"$TMPBASE"'/upload.bin -o /dev/null -w "code=%{http_code} remote=%{remote_ip} dns=%{time_namelookup}s tcp=%{time_connect}s tls_ready=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s upload_bytes=%{size_upload} speed_upload_Bps=%{speed_upload} download_bytes=%{size_download}\\n" https://speed.cloudflare.com/__up'
    rm -rf "$TMPBASE"
    trap - EXIT
  fi
} > "$RAW/10_throughput.txt"

{
  raw_header 11_benchmarks.txt
  run_sh 'DISK_TEST_MIB='"$DISK_TEST_MIB"' python3 - <<'\''PY'\''
import os,time,statistics,tempfile,subprocess,pathlib,gc
try:
 a=sorted(os.sched_getaffinity(0));os.sched_setaffinity(0,{a[0]});print("affinity_before",a,"after",sorted(os.sched_getaffinity(0)))
except Exception as e: print("affinity_error",repr(e))
ts=[]
for i in range(5):
 t=time.perf_counter_ns();v=sum(range(10**7));s=(time.perf_counter_ns()-t)/1e9;ts.append(s);print("sum_run",i+1,f"{s:.9f}",v)
print("sum_median_s",f"{statistics.median(ts):.9f}")
ts=[]
for r in range(3):
 x=0;t=time.perf_counter_ns()
 for i in range(10_000_000): x=(x+(i^(i>>3)))&0xffffffffffffffff
 s=(time.perf_counter_ns()-t)/1e9;ts.append(s);print("loop_run",r+1,f"{s:.9f}",x)
print("loop_median_s",f"{statistics.median(ts):.9f}")
try:
 import numpy as np
 a=np.arange(10_000_000,dtype=np.int64);ts=[]
 for r in range(3):
  t=time.perf_counter_ns();v=int(np.sum((a*a)%97));s=(time.perf_counter_ns()-t)/1e9;ts.append(s);print("numpy_run",r+1,f"{s:.9f}",v)
 print("numpy_median_s",f"{statistics.median(ts):.9f}");del a;gc.collect()
except Exception as e: print("numpy_error",repr(e))
size=int(os.environ.get("DISK_TEST_MIB","100"))*1024*1024
p=pathlib.Path(os.environ.get("HOME","/tmp"))/(".envprobe_disk_"+str(os.getpid()))
chunk=os.urandom(4*1024*1024);n=size//len(chunk);rem=size%len(chunk)
try:
 t=time.perf_counter_ns()
 with open(p,"wb",buffering=0) as f:
  for _ in range(n):f.write(chunk)
  if rem:f.write(chunk[:rem])
  os.fsync(f.fileno())
 s=(time.perf_counter_ns()-t)/1e9;print("disk_write_fsync",size,f"{s:.9f}",f"{size/s:.3f} Bps")
 fd=os.open(p,os.O_RDONLY)
 try:os.posix_fadvise(fd,0,0,os.POSIX_FADV_DONTNEED);print("fadvise","ok")
 except Exception as e:print("fadvise",repr(e))
 os.close(fd)
 b=bytearray(4*1024*1024);mv=memoryview(b);seen=0;t=time.perf_counter_ns()
 with open(p,"rb",buffering=0) as f:
  while True:
   z=f.readinto(mv)
   if not z:break
   seen+=z
 s=(time.perf_counter_ns()-t)/1e9;print("disk_read_after_fadvise",seen,f"{s:.9f}",f"{seen/s:.3f} Bps")
 seen=0;t=time.perf_counter_ns()
 with open(p,"rb",buffering=0) as f:
  while True:
   z=f.readinto(mv)
   if not z:break
   seen+=z
 s=(time.perf_counter_ns()-t)/1e9;print("disk_read_warm",seen,f"{s:.9f}",f"{seen/s:.3f} Bps")
 for r in range(2):
  t=time.perf_counter_ns();q=subprocess.run(["dd",f"if={p}","of=/dev/null","bs=4M","iflag=direct","status=none"],capture_output=True,text=True);s=(time.perf_counter_ns()-t)/1e9
  print("disk_read_direct",r+1,"rc",q.returncode,"seconds",f"{s:.9f}","Bps",f"{size/s:.3f}","stderr",repr(q.stderr))
finally:
 try:p.unlink()
 except FileNotFoundError:pass
PY'
} > "$RAW/11_benchmarks.txt"

{
  raw_header 12_install_compile.txt
  if [[ "$MODE" == quick ]]; then
    echo 'SKIPPED: install/compile mutation tests disabled by --quick'
  else
    TMPBASE=$(mktemp -d /tmp/envprobe-installs.XXXXXX)
    trap 'rm -rf "$TMPBASE"' EXIT
    run_sh 'TMPBASE='"$(printf %q "$TMPBASE")"' python3 - <<'\''PY'\''
import subprocess,time,os,json
base=os.environ["TMPBASE"]
def r(label,cmd,cwd=None):
 t=time.perf_counter_ns();p=subprocess.run(cmd,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True);s=(time.perf_counter_ns()-t)/1e9
 print("###",label,"seconds",f"{s:.9f}","rc",p.returncode);print(p.stdout)
r("venv_create",["python3","-m","venv",base+"/venv"])
r("pip_install",[base+"/venv/bin/python","-m","pip","install","--disable-pip-version-check","--no-cache-dir","pyfiglet==1.0.2"])
r("pip_verify",[base+"/venv/bin/python","-c","import pyfiglet; print(pyfiglet.__version__)"])
os.mkdir(base+"/npm");json.dump({"name":"envprobe","version":"1.0.0","private":True},open(base+"/npm/package.json","w"))
r("npm_install",["npm","install","--ignore-scripts","--no-audit","--no-fund","is-number@7.0.0"],base+"/npm")
js="const f=require("+repr("is-number")+"); console.log(f(42),f("+repr("x")+"))"
r("npm_verify",["node","-e",js],base+"/npm")
PY'
    run_sh 'mkdir -p '"$TMPBASE"'/c; cat > '"$TMPBASE"'/c/probe.c <<'\''EOF'\''
#include <stdio.h>
#include <stdint.h>
int main(void){uint64_t x=0;for(uint64_t i=0;i<1000000;i++)x=x*33u+i;printf("%llu\n",(unsigned long long)x);return 0;}
EOF
cat > '"$TMPBASE"'/c/Makefile <<'\''EOF'\''
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra
probe: probe.c
	$(CC) $(CFLAGS) -o $@ $<
EOF
python3 - <<'\''PY'\''
import subprocess,time,os
base="'"$TMPBASE"'/c"
for label,cmd in [("gcc",["gcc","-O2","-Wall","-Wextra","-o","probe-gcc","probe.c"]),("gcc_binary",[base+"/probe-gcc"]),("make",["make","CC=gcc"]),("make_binary",[base+"/probe"])]:
 t=time.perf_counter_ns();p=subprocess.run(cmd,cwd=base,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True);s=(time.perf_counter_ns()-t)/1e9;print(label,"seconds",f"{s:.9f}","rc",p.returncode);print(p.stdout)
PY'
    if command -v sudo >/dev/null && sudo -n true >/dev/null 2>&1; then
      TREE_WAS_PRESENT=0; command -v tree >/dev/null 2>&1 && TREE_WAS_PRESENT=1
      run_sh 'export DEBIAN_FRONTEND=noninteractive; time sudo -n -E apt-get -o Acquire::Retries=0 update'
      run_sh 'export DEBIAN_FRONTEND=noninteractive; time sudo -n -E apt-get -o Acquire::Retries=0 install -y --no-install-recommends tree; tree --version'
      if [[ "$TREE_WAS_PRESENT" == 0 ]]; then run_sh 'export DEBIAN_FRONTEND=noninteractive; time sudo -n -E apt-get purge -y tree'; else echo 'tree pre-existed; not purged'; fi
    else
      echo 'SKIPPED apt mutation: passwordless sudo unavailable'
    fi
    rm -rf "$TMPBASE"
    trap - EXIT
  fi
} > "$RAW/12_install_compile.txt"

{
  raw_header 13_memory_process.txt
  if [[ "$MODE" == quick ]]; then
    echo 'SKIPPED: controlled allocation disabled by --quick'
  else
    run_sh 'MEM_TEST_MIB='"$MEM_TEST_MIB"' python3 - <<'\''PY'\''
import os,time,resource,pathlib,gc
mib=int(os.environ.get("MEM_TEST_MIB","512"));amount=mib*1024*1024
cg=pathlib.Path("/sys/fs/cgroup")/next((x.split(":",2)[2].lstrip("/") for x in pathlib.Path("/proc/self/cgroup").read_text().splitlines() if x.startswith("0::")),"")
def show(label):
 print(label,"ru_maxrss_KiB",resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
 for f in ["memory.current","memory.peak","memory.max","memory.high","memory.swap.current","memory.events"]:
  try:print(label,f,(cg/f).read_text().strip().replace("\\n",";"))
  except Exception as e:print(label,f,repr(e))
show("before");t=time.perf_counter_ns();b=bytearray(amount);print("allocation_bytes",amount,"seconds",f"{(time.perf_counter_ns()-t)/1e9:.9f}")
p=os.sysconf("SC_PAGE_SIZE");t=time.perf_counter_ns()
for i in range(0,amount,p):b[i]=(i//p)&255
print("page_touch_seconds",f"{(time.perf_counter_ns()-t)/1e9:.9f}");show("touched");time.sleep(1);show("held");del b;gc.collect();time.sleep(.5);show("freed")
PY'
  fi
  run_sh '(echo "child_start BASHPID=$BASHPID"; for i in 1 2 3 4 5 6; do echo "heartbeat $i epoch_ns=$(date +%s%N)"; sleep 1; done) & child=$!; echo "parent BASHPID=$BASHPID child=$child"; wait "$child"; rc=$?; echo "child_returncode=$rc"; exit "$rc"'
} > "$RAW/13_memory_process.txt"

{
  raw_header 14_persistence.txt
  run_sh 'stat -c "path=%n mode=%a owner=%U:%G size=%s mtime=%y" '"$(printf %q "$SENTINEL")"'; cat '"$(printf %q "$SENTINEL")"''
  run_sh 'find '"$(printf %q "$RAW")"' -maxdepth 1 -type f -printf "%f %s bytes %TY-%Tm-%TdT%TH:%TM:%TS%Tz\\n" | sort'
  run_sh 'df -hT / /tmp; df -i / /tmp'
} > "$RAW/14_persistence.txt"

RUN_END_UTC=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
SANDBOX_ID=${E2B_SANDBOX_ID-<unset>}
TEMPLATE_ID=${E2B_TEMPLATE_ID-<unset>}
SCRIPT_COPY="$RUN_DIR/probe_environment.sh"
SCRIPT_SHA256=$(sha256sum "$SCRIPT_COPY" | awk '{print $1}')
(
  cd "$RUN_DIR" || exit 1
  find raw -maxdepth 1 -type f -name '*.txt' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)
RAW_COUNT=$(wc -l < "$RUN_DIR/SHA256SUMS" | tr -d ' ')

{
  echo 'manifest_format=environment-probe-v1'
  echo "run_tag=$RUN_TAG"
  echo "run_start_utc=$RUN_START_UTC"
  echo "run_end_utc=$RUN_END_UTC"
  echo "mode=$MODE"
  echo "sandbox_id=$SANDBOX_ID"
  echo "template_id=$TEMPLATE_ID"
  echo "hostname=$(hostname)"
  echo "probe_script_source=$SCRIPT_PATH"
  echo "probe_script_copy=probe_environment.sh"
  echo "probe_script_sha256=$SCRIPT_SHA256"
  echo "raw_file_count=$RAW_COUNT"
  echo 'sha256_file=SHA256SUMS'
  echo
  echo '[raw_file_sha256]'
  cat "$RUN_DIR/SHA256SUMS"
} > "$RUN_DIR/manifest.txt"

RUN_DIR="$RUN_DIR" RUN_TAG="$RUN_TAG" RUN_START_UTC="$RUN_START_UTC" RUN_END_UTC="$RUN_END_UTC" MODE="$MODE" SANDBOX_ID="$SANDBOX_ID" TEMPLATE_ID="$TEMPLATE_ID" SCRIPT_PATH="$SCRIPT_PATH" SCRIPT_SHA256="$SCRIPT_SHA256" python3 - <<'PY'
import os,json,pathlib
r=pathlib.Path(os.environ['RUN_DIR'])
hashes=[]
for line in (r/'SHA256SUMS').read_text().splitlines():
    digest,path=line.split(None,1);hashes.append({'path':path.strip(),'sha256':digest})
data={
 'manifest_format':'environment-probe-v1',
 'run_tag':os.environ['RUN_TAG'],
 'run_start_utc':os.environ['RUN_START_UTC'],
 'run_end_utc':os.environ['RUN_END_UTC'],
 'mode':os.environ['MODE'],
 'sandbox_id':os.environ['SANDBOX_ID'],
 'template_id':os.environ['TEMPLATE_ID'],
 'hostname':os.uname().nodename,
 'probe_script_source':os.environ['SCRIPT_PATH'],
 'probe_script_copy':'probe_environment.sh',
 'probe_script_sha256':os.environ['SCRIPT_SHA256'],
 'raw_files':hashes,
}
(r/'manifest.json').write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY

printf 'run_dir=%s\n' "$RUN_DIR"
printf 'manifest=%s\n' "$RUN_DIR/manifest.txt"
printf 'verify_command=(cd %q && sha256sum -c SHA256SUMS)\n' "$RUN_DIR"
