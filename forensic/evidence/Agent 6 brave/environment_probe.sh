#!/usr/bin/env bash
# ============================================================================
# environment_probe.sh  v1.1.0
# Reproducible environment characterization for Linux microVM sandboxes
# (the battery that produced /home/user/envprobe/*.txt, run-1, 2026-09-04).
#
# USAGE:
#   bash environment_probe.sh [OUTDIR]          # full battery (default ./probe_output)
#   QUICK=1 bash environment_probe.sh [OUTDIR]  # reduced sizes/repeats, same structure
#
# OUTPUT (verbatim transcripts written into OUTDIR):
#   00_run_header.txt  01_runtime.txt  02_identity.txt  03_tools.txt  04_fs.txt
#   05_cpu_mem.txt  06_compilers_pkgs.txt  07_cgroup_sudo.txt  09_net_matrix.txt
#   10_net_throughput.txt  10b_net_throughput2.txt  11_disk.txt  12_pip.txt
#   12b_pip2.txt  13_bg_misc.txt  14_final.txt  15_process_demo.txt  bg_ticks.txt
#   epilogue.txt  sha256sums.txt  manifest.json
#
# NOTES FOR THIRD-PARTY RE-RUNS:
#   * File names / section headers match the canonical run 1:1 so outputs can
#     be structurally diffed (compare_run.sh).
#   * Inherent per-run differences: timestamps, sandbox/template IDs, boot_id,
#     and every numeric measurement. Numbers vary; structure must not.
#   * Where run-1 hit shell-quoting bugs (its 10_net_throughput.txt and
#     12_pip.txt contain tracebacks), this script runs the corrected probes;
#     run-1's re-measurements are in 10b_*/12b_*.
#   * sudo/apt steps degrade gracefully when unprivileged.
#   * Run-1's platform-supervised process runner (start_process) cannot be
#     reproduced from a plain shell script; section 15 runs the local
#     equivalent self-test and notes the difference.
# ============================================================================
set -u
SCRIPT_VER="1.1.0"
OUTDIR="${1:-probe_output}"
QUICK="${QUICK:-0}"
mkdir -p "$OUTDIR"
RUN_START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

sudook(){ sudo -n true 2>/dev/null; }

{ echo "### environment_probe.sh v${SCRIPT_VER} run header"
  echo "run_start_utc: ${RUN_START_UTC}"
  echo "outdir: ${OUTDIR}"
  echo "quick: ${QUICK}"
  echo "user: $(id -un 2>/dev/null) uid=$(id -u 2>/dev/null)"
  echo "hostname: $(hostname)"
  echo "sandbox_id: ${E2B_SANDBOX_ID:-<not set>}"
  echo "template_id: ${E2B_TEMPLATE_ID:-<not set>}"
  echo "boot_id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo n/a)"
} > "$OUTDIR/00_run_header.txt" 2>&1

# ============================= 01 runtime & isolation =========================
{
echo "### probe 01 timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ) | sandbox-local: $(date '+%Y-%m-%dT%H:%M:%S %Z')"
echo; echo "== uname -a =="; uname -a
echo; echo "== /etc/os-release =="; cat /etc/os-release 2>/dev/null || echo "(absent)"
echo; echo "== /etc/debian_version =="; cat /etc/debian_version 2>/dev/null || echo "(absent)"
echo; echo "== libc =="; ldd --version 2>&1 | head -1
ls -l /lib/x86_64-linux-gnu/libc.so.6 2>/dev/null || ls -l /lib64/libc.so.6 2>/dev/null
echo; echo "== container markers =="
ls -la /.dockerenv 2>&1 | sed 's/^/  /'
if [ -f /run/.containerenv ]; then echo "/run/.containerenv present:"; head -4 /run/.containerenv; else echo "no /run/.containerenv"; fi
echo "  /proc/1/cgroup   : $(tr '\n' ' ' </proc/1/cgroup)"
echo "  /proc/self/cgroup: $(tr '\n' ' ' </proc/self/cgroup)"
echo "  /proc/1/comm     : $(cat /proc/1/comm)"
echo "  /proc/1/cmdline  : $(tr '\0' ' ' </proc/1/cmdline)"
echo; echo "== virtualization hints =="
if command -v systemd-detect-virt >/dev/null 2>&1; then systemd-detect-virt; else echo "systemd-detect-virt absent"; fi
grep -m1 -q 'hypervisor' /proc/cpuinfo && echo "cpuinfo: 'hypervisor' flag present (VM guest)" || echo "cpuinfo: no hypervisor flag"
[ -r /sys/class/dmi/id/product_name ] && echo "dmi product_name: $(cat /sys/class/dmi/id/product_name 2>/dev/null)"
echo; echo "== /proc/mounts (full) =="; cat /proc/mounts
echo; echo "== cgroup v2 =="
echo "controllers: $(cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null)"
echo "subtree:     $(cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null)"
echo; echo "== hostname / hosts / resolv.conf =="
hostname; cat /etc/hosts; cat /etc/resolv.conf
echo; echo "== ipv6 =="
if [ -f /proc/net/if_inet6 ]; then echo "IPv6 enabled"; head -5 /proc/net/if_inet6; else echo "IPv6 NOT enabled"; fi
echo; echo "== net dev =="; cat /proc/net/dev
echo; echo "== route table (ipv4, hex) =="; head -5 /proc/net/route
echo; echo "== misc kernel info =="
echo "boot_id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null)"
echo "clocksource: $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource 2>/dev/null)"
echo "timezone file: $(cat /etc/timezone 2>/dev/null || echo n/a)"
} > "$OUTDIR/01_runtime.txt" 2>&1

# ============================= 02 identity & limits ==========================
{
echo "== id / user =="; id; echo "whoami: $(whoami)"; echo "uid=$(id -u) gid=$(id -g)"
echo; echo "== sudo test (non-interactive) =="
if sudook; then echo "SUDO: passwordless root available"; else echo "SUDO: not available (needs password or denied)"; fi
echo; echo "== /proc/self/status key lines =="
grep -E '^(Uid|Gid|Groups|CapEff|CapBnd|CapPrm|CapInh|Seccomp|NoNewPrivs|Cpus_allowed_list|Mems_allowed_list|Threads|SigQ)' /proc/self/status
echo; echo "== capability decode of self =="
python3 - <<'PY'
cap_names={0:'chown',1:'dac_override',2:'dac_read_search',3:'fowner',4:'fsetid',5:'kill',6:'setgid',7:'setuid',8:'setpcap',9:'linux_immutable',10:'net_bind_service',11:'net_broadcast',12:'net_admin',13:'net_raw',14:'ipc_lock',15:'ipc_owner',16:'sys_module',17:'sys_rawio',18:'sys_chroot',19:'sys_ptrace',20:'sys_pacct',21:'sys_admin',22:'sys_boot',23:'sys_nice',24:'sys_resource',25:'sys_time',26:'sys_tty_config',27:'mknod',28:'lease',29:'audit_write',30:'audit_control',31:'setfcap',32:'mac_override',33:'mac_admin',34:'syslog',35:'wake_alarm',36:'block_suspend',37:'audit_read',38:'perfmon',39:'bpf',40:'checkpoint_restore'}
def field(k):
    for l in open('/proc/self/status'):
        if l.startswith(k): return int(l.split()[1],16)
    return 0
for k in ('CapEff','CapBnd','CapPrm'):
    v=field(k)
    names=[n for b,n in cap_names.items() if v & (1<<b)]
    print(f"{k} = {v:#x} ; set: {names or 'NONE'}")
PY
echo; echo "== LSM / seccomp =="
grep Seccomp /proc/self/status | sed 's/^/  /'
[ -r /proc/self/attr/current ] && echo "  apparmor current: $(cat /proc/self/attr/current 2>/dev/null)"
echo; echo "== ulimit -a =="; ulimit -a
echo; echo "== RLIMITs =="; head -18 /proc/self/limits
echo; echo "== cgroup limits =="
for f in memory.max memory.high memory.current memory.swap.max memory.peak memory.events cpu.max cpu.stat pids.max pids.current; do printf '%-18s' "$f: "; cat /sys/fs/cgroup/$f 2>/dev/null || echo "n/a"; done
echo; echo "== cpuset =="
echo "effective cpus: $(cat /sys/fs/cgroup/cpuset.cpus.effective 2>/dev/null)"
taskset -pc $$ 2>/dev/null || true
echo; echo "== cpuinfo =="
echo "logical CPUs: $(grep -c ^processor /proc/cpuinfo)"
grep -m1 'model name' /proc/cpuinfo
grep -m1 'cpu MHz' /proc/cpuinfo
echo "simd flags: $(grep -im1 '^flags' /proc/cpuinfo | tr ' ' '\n' | grep -oE 'avx2|avx512f|sse4_2|aes|fma' | sort -u | tr '\n' ' ')"
echo; echo "== meminfo =="; grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)' /proc/meminfo
echo; echo "== loadavg =="; cat /proc/loadavg
echo; echo "== top processes by mem =="; ps -eo pid,ppid,user,%cpu,%mem,etime,comm --sort=-%mem 2>/dev/null | head -12
echo; echo "== env (sorted, secrets redacted) =="; env | sort | sed -E 's/(TOKEN|SECRET|API_KEY|PASSWORD|CREDENTIAL|AUTH)=.*/\1=<redacted>/I'
echo; echo "== k8s/sandbox env hints =="; env | grep -iE 'KUBERNETES|SANDBOX|E2B|AGENT' || echo "none found"
echo; echo "== /var/run/secrets? =="; [ -d /var/run/secrets ] && find /var/run/secrets -maxdepth 2 | head || echo "absent"
echo; echo "== passwd users =="; cut -d: -f1,3 /etc/passwd 2>/dev/null | head -8
echo; echo "== dotdirs in home =="; ls -la ~/.ssh ~/.aws ~/.config 2>/dev/null | head -12 || true
} > "$OUTDIR/02_identity.txt" 2>&1

# ============================= 03 tools ======================================
{
echo "== tool availability + versions (probed $(date -u +%FT%TZ)) =="
probe(){ t="$1"; if command -v "$t" >/dev/null 2>&1; then p=$(command -v "$t"); v=$(timeout 5 "$t" --version 2>/dev/null | head -1); [ -z "$v" ] && v=$(timeout 5 "$t" -version 2>/dev/null | head -1); [ -z "$v" ] && v=$(timeout 5 "$t" -V 2>/dev/null | head -1); [ -z "$v" ] && v="(runs, no --version output)"; printf '%-14s %s\n' "$t" "$v"; else printf '%-14s MISSING\n' "$t"; fi; }
for t in python3 python3.13 pip pip3 node npm npx yarn pnpm bun deno git curl wget aria2c ffmpeg docker podman make gcc g++ cc clang cmake ninja pkg-config jq yq unzip zip tar xz gzip bzip2 zstd rsync openssl ssh scp socat ncat dig nslookup host getent ping traceroute mtr htop strace ltrace perf file sqlite3 redis-cli go rustc cargo java javac ruby perl php Rscript julia autoconf automake libtool bison flex screen tmux vim nano xxd bc time timeout setsid flock vmstat iostat ifconfig ip busybox; do probe "$t"; done
echo; echo "== language runtime details =="
python3 -c 'import sys,platform; print("python:", sys.version.replace("\n"," ")); print("impl:", platform.python_implementation(), "| bits:", 64 if sys.maxsize>2**32 else 32)'
python3 -m pip --version 2>&1 | head -1
node --version 2>/dev/null | xargs echo "node:"
npm --version 2>/dev/null | xargs echo "npm:"
git --version
echo; echo "== docker daemon reachable? =="
timeout 12 docker info 2>&1 | head -6 || echo "docker daemon not reachable"
echo; echo "== registry defaults =="
env | grep -iE '^PIP_INDEX|^PIP_EXTRA|^npm_config_registry|^NPM_CONFIG_REGISTRY' || echo "no pip/npm registry env overrides"
python3 -m pip config list 2>&1 | head -5
npm config get registry 2>/dev/null
} > "$OUTDIR/03_tools.txt" 2>&1

# ============================= 04 filesystem =================================
{
echo "== cwd/home =="; pwd; echo "HOME=$HOME"; echo "TMPDIR=${TMPDIR:-<unset>}"; echo "SHELL=$SHELL"
echo; echo "== workspace contents =="; ls -la /home/user
echo; echo "== df -h =="; df -h
echo; echo "== df -i (inodes) =="; df -i
echo; echo "== read-only mounts =="; awk '$4 ~ /(^|,)ro(,|$)/' /proc/mounts; echo "(ro count: $(awk '$4 ~ /(^|,)ro(,|$)/' /proc/mounts | wc -l) / total $(wc -l < /proc/mounts))"
echo; echo "== fs type per path =="
for p in / /home /home/user /tmp /var/tmp /dev/shm /proc /sys /etc /run; do printf '  %-12s %s\n' "$p" "$(stat -f -c '%T' $p 2>/dev/null || echo '?')"; done
echo; echo "== /tmp + /dev/shm sizing =="; df -h /tmp /dev/shm /var/tmp 2>/dev/null
echo; echo "== write/read/delete probes =="
probe(){ d="$1"; f="$d/.probe_$$.bin"; if head -c 1048576 /dev/urandom > "$f" 2>/dev/null; then s=$(stat -c%s "$f" 2>/dev/null); chmod 600 "$f" 2>/dev/null && echo "  $d : write OK ($s B) + chmod OK" || echo "  $d : write OK ($s B) chmod FAILED"; rm -f "$f" && echo "  $d : delete OK" || echo "  $d : delete FAILED"; else echo "  $d : WRITE FAILED"; fi; }
probe /home/user; probe /tmp; probe /dev/shm; probe /var/tmp
echo; echo "== link/fallocate ops in /home/user =="
d=/home/user/.fstest; mkdir -p $d; echo x > $d/a; ln $d/a $d/b 2>/dev/null && echo "  hardlink OK" || echo "  hardlink FAILED"; ln -s a $d/c 2>/dev/null && echo "  symlink OK"; fallocate -l 10485760 $d/fall.bin 2>/dev/null && echo "  fallocate 10MiB OK" || echo "  fallocate FAILED"; ls -l $d; rm -rf $d && echo "  cleanup OK"
echo; echo "== overlay / backing store =="; grep -E 'overlay|/home' /proc/mounts | head -4
echo; echo "== protected-path writability (as current user) =="
for p in /etc /usr /var/log /root /boot /proc/sys; do if [ -w "$p" ] 2>/dev/null; then echo "  $p: WRITABLE"; else echo "  $p: not writable"; fi; done
echo; echo "== persistence markers =="
printf 'HOME marker %s\n' "$(date -u +%FT%TZ)" > /home/user/.persist_marker_probe
printf 'TMP marker %s\n' "$(date -u +%FT%TZ)" > /tmp/.persist_marker_probe
echo "  wrote: $(cat /home/user/.persist_marker_probe) | $(cat /tmp/.persist_marker_probe 2>/dev/null)"
} > "$OUTDIR/04_fs.txt" 2>&1

# ============================= 05 cpu & memory ===============================
{
PYVER=$(python3 -c 'import platform; print(platform.python_version())' 2>/dev/null || echo ?)
echo "== CPU micro-benchmarks (python ${PYVER}, perf_counter, medians of 3) =="
python3 - <<'PY'
import time, statistics as st
def bench(f, n=3):
    ts=[]
    for _ in range(n):
        t0=time.perf_counter(); f(); ts.append(time.perf_counter()-t0)
    return st.median(ts)
t=bench(lambda: sum(range(10**7)))
print(f"sum(range(10**7))          : {t*1000:8.1f} ms median of 3")
def heavy():
    s=0
    for i in range(3_000_000):
        s += (i*i)%997 + (i%251)
    return s
t=bench(heavy)
print(f"int-loop 3e6 (mod+add)     : {t*1000:8.1f} ms median of 3")
PY
echo; echo "== parallel speedup probe: 4x sum(range(10**7)) in parallel =="
t0=$(date +%s.%N)
for i in 1 2 3 4; do python3 -c 'sum(range(10**7))' & done
wait
t1=$(date +%s.%N)
python3 -c "print('  4-parallel wall: %.2f s' % ($t1-$t0))"
echo; echo "== single sequential run reference =="
t0=$(date +%s.%N); python3 -c 'sum(range(10**7))'; t1=$(date +%s.%N)
python3 -c "print('  1 run wall: %.2f s' % ($t1-$t0))"
echo; echo "== memory allocation ceiling probe =="
grep -E 'MemTotal|MemAvailable' /proc/meminfo
TARGET_MIB=${MEM_TARGET_MIB:-1024}
if [ "$QUICK" = "1" ]; then TARGET_MIB=256; echo "  [QUICK] reduced target to ${TARGET_MIB} MiB"; fi
TARGET_MIB=$TARGET_MIB python3 - <<'PY'
import os
def readmeminfo():
    d={}
    for l in open('/proc/meminfo'):
        k,v=l.split(':',1); d[k]=int(v.split()[0])//1024
    return d
avail=readmeminfo()['MemAvailable']
target=int(os.environ['TARGET_MIB'])
target=min(target, avail)
print(f"MemAvailable: {avail} MiB; target: {target} MiB")
step=128; bufs=[]; got=0
try:
    while got < target:
        b=bytearray(step*1024*1024)
        for off in range(0, step*1024*1024, 64*1024):
            b[off]=1
        bufs.append(b); got+=step
    m=readmeminfo()
    print(f"allocated+touched {got} MiB OK; after: MemAvailable={m['MemAvailable']} MiB -> process survived, no OOM")
except MemoryError:
    print(f"MemoryError at ~{got} MiB")
PY
echo; echo "== memory.events =="; cat /sys/fs/cgroup/memory.events 2>/dev/null || echo n/a
echo; echo "== vmstat 1 2 =="; vmstat 1 2 2>/dev/null || echo "(vmstat n/a)"
} > "$OUTDIR/05_cpu_mem.txt" 2>&1

# ============================= 06 compilers & apt ============================
{
echo "== gcc hello world =="
printf '#include <stdio.h>\nint main(void){printf("compiled-binary-ok\\n");return 0;}\n' > /tmp/hc.c
if command -v gcc >/dev/null 2>&1; then gcc -O2 -o /tmp/hc /tmp/hc.c && /tmp/hc && echo "gcc compile+run: OK"; gcc --version | head -1; else echo "gcc ABSENT"; fi
echo; echo "== python dev headers =="
INC=$(python3 -c "import sysconfig; print(sysconfig.get_paths().get('include',''))")
echo "sysconfig include: $INC"
ls "$INC/Python.h" 2>/dev/null && echo "Python.h PRESENT -> C-ext builds possible" || echo "Python.h ABSENT -> sdist C-ext builds will fail"
echo; echo "== headers sample =="
for h in /usr/include/stdio.h /usr/include/openssl/ssl.h; do [ -e "$h" ] && echo "present: $h" || echo "absent: $h"; done
echo; echo "== make =="; make --version 2>/dev/null | head -1
echo; echo "== apt (via passwordless sudo) =="
if command -v apt-get >/dev/null 2>&1; then
  if sudook; then
    echo "sudo->root: uid=$(sudo -n id -u) CapEff=$(sudo -n grep CapEff /proc/self/status | awk '{print $2}') Seccomp=$(sudo -n grep Seccomp /proc/self/status | awk '{print $2}')"
    echo "-- apt-get update (timed, quiet) --"
    t0=$(date +%s.%N); sudo -n apt-get update 2>&1 | tail -2; rc=${PIPESTATUS[0]}; t1=$(date +%s.%N)
    python3 -c "print('apt-get update rc=%d, %.1f s' % ($rc, $t1-$t0))"
    echo; echo "== apt-cache: is ffmpeg available? =="
    apt-cache policy ffmpeg 2>/dev/null | head -4
    echo; echo "== DEMO: install a small system package (sqlite3 CLI) =="
    t0=$(date +%s.%N)
    sudo -n apt-get install -y --no-install-recommends sqlite3 2>&1 | tail -2
    t1=$(date +%s.%N)
    python3 -c "print('apt install sqlite3: %.1f s' % ($t1-$t0))"
    sqlite3 --version 2>/dev/null && echo "sqlite3 available"
  else
    echo "sudo not available -> apt steps skipped"
  fi
else
  echo "apt-get ABSENT"
fi
echo; echo "== other pkg mgrs =="
for m in apk yum dnf pacman zypper conda mamba brew dpkg rpm; do command -v $m >/dev/null && echo "$m: $(command -v $m)" || echo "$m: absent"; done
echo; echo "== dpkg arch =="; dpkg --print-architecture 2>/dev/null || uname -m; dpkg --print-foreign-architectures 2>/dev/null
echo; echo "== systemd units (sanity) =="; systemctl list-units --type=service --no-pager 2>/dev/null | head -14 || echo "  (no systemctl)"
} > "$OUTDIR/06_compilers_pkgs.txt" 2>&1

# ============================= 07 cgroup & sudo details ======================
{
echo "== cgroup v2 tree (delegated view) =="
ls -la /sys/fs/cgroup/ 2>&1 | head -12
echo; echo "== /sys/fs/cgroup/user/* limits =="
if [ -d /sys/fs/cgroup/user ]; then
for f in cgroup.procs cgroup.controllers memory.max memory.current memory.high memory.swap.max memory.peak cpu.max cpu.stat pids.max pids.current io.max; do printf '%-18s' "$f:"; cat /sys/fs/cgroup/user/$f 2>/dev/null | head -3 | tr '\n' ' '; echo; done
else echo "no 'user' child cgroup; showing self slice:"; cat /proc/self/cgroup; fi
echo; echo "== our position in cgroup tree =="; cat /proc/self/cgroup
echo; echo "== which python / symlinks =="
which -a python3 pip pip3 2>/dev/null
ls -l /usr/local/bin/python3* 2>/dev/null
echo; echo "== locale / arch / uptime =="
locale 2>/dev/null | head -3; echo "LANG=${LANG:-unset} LC_ALL=${LC_ALL:-unset}"
dpkg --print-architecture 2>/dev/null || uname -m
uptime
echo; echo "== systemd user session? =="; systemctl --user 2>&1 | head -3
echo; echo "== listening sockets (ss) =="; ss -tlnp 2>/dev/null | head -12 || echo "no ss"
echo; echo "== events endpoint reachability (192.0.2.1) =="
timeout 4 curl -s -o /dev/null -w '  http_code=%{http_code} time=%{time_total}s\n' "${E2B_EVENTS_ADDRESS:-http://192.0.2.1}/" 2>&1 || echo "  unreachable"
echo; echo "== nproc / cpu info cache =="; nproc; lscpu 2>/dev/null | head -14 || true
} > "$OUTDIR/07_cgroup_sudo.txt" 2>&1

echo "[probe] sections 01-07 written to $OUTDIR (part 1 done)"
# ============================= 09 network matrix =============================
{
REPS=5; [ "$QUICK" = "1" ] && REPS=2 && echo "  [QUICK] DNS reps=2"
NS_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
echo "== DNS timing: raw-UDP stub queries to ${NS_IP} ($REPS reps, median) =="
REPS=$REPS python3 - <<'PYH'
import socket, time, random, statistics as st, os
NS=[l.split()[1] for l in open('/etc/resolv.conf') if l.startswith('nameserver')]
reps=int(os.environ.get('REPS','5'))
hosts=['google.com','github.com','pypi.org','huggingface.co','files.pythonhosted.org','registry.npmjs.org','deb.debian.org','nonexistent-domain-xyzabc123.example.com']
def query(host, ns):
    qid=random.randint(0,65535)
    hdr=qid.to_bytes(2,'big')+b'\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'
    q=b''.join(bytes([len(l)])+l.encode() for l in host.split('.'))+b'\x00'+b'\x00\x01\x00\x01'
    s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(2.0)
    t0=time.perf_counter()
    try:
        s.sendto(hdr+q,(ns,53))
        data,_=s.recvfrom(4096)
        return (time.perf_counter()-t0)*1000
    except socket.timeout:
        return None
    finally:
        s.close()
for h in hosts:
    ts=[query(h,NS[0]) for _ in range(reps)] if NS else []
    ts=[t for t in ts if t is not None]
    if ts:
        print(f"  {h:44s} median {st.median(ts):6.1f} ms   min {min(ts):5.1f}  max {max(ts):6.1f}  (reps n={len(ts)})")
    else:
        print(f"  {h:44s} NO RESPONSE (timeout 2s) or no resolver configured")
PYH
echo; REPS=7; [ "$QUICK" = "1" ] && REPS=3
echo "== TCP connect RTT ($REPS reps, median) and UDP probes =="
REPS=$REPS python3 - <<'PYH'
import socket, time, statistics as st, os
reps=int(os.environ.get('REPS','7'))
targets=[('8.8.8.8',443),('1.1.1.1',443),('google.com',443),('github.com',443),('github.com',22),('pypi.org',443),('huggingface.co',443),('registry.npmjs.org',443),('deb.debian.org',443),('files.pythonhosted.org',443),('1.1.1.1',53)]
print("  -- TCP connect RTT --")
for host,port in targets:
    ts=[]
    for _ in range(reps):
        try:
            ip=socket.getaddrinfo(host,port,socket.AF_INET,socket.SOCK_STREAM)[0][4][0]
            s=socket.socket(); s.settimeout(3)
            t0=time.perf_counter(); s.connect((ip,port)); ts.append((time.perf_counter()-t0)*1000)
            s.close()
        except Exception:
            ts.append(None)
    ok=[t for t in ts if t is not None]
    if ok:
        print(f"  {host+':'+str(port):38s} {st.median(ok):7.2f} ms median  min {min(ok):6.2f}  max {max(ok):6.2f}  ({len(ok)}/{len(ts)} ok)")
    else:
        print(f"  {host+':'+str(port):38s} BLOCKED/TIMEOUT (3s)")
print("  -- UDP probes (send, wait 1.2s for any reply) --")
def udp(host,port,payload):
    try:
        s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(1.2)
        ip=socket.getaddrinfo(host,port,socket.AF_INET,socket.SOCK_DGRAM)[0][4][0]
        t0=time.perf_counter(); s.sendto(payload,(ip,port))
        d,_=s.recvfrom(4096); dt=(time.perf_counter()-t0)*1000
        return f"reply {len(d)}B in {dt:.1f} ms"
    except socket.timeout:
        return "no reply in 1.2s"
    except Exception as e:
        return f"error {e}"
q=b'\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'+b'\x07example\x03com\x00\x00\x01\x00\x01'
print("  UDP 53 8.8.8.8 (valid DNS q) :", udp('8.8.8.8',53,q))
print("  UDP 53 1.1.1.1 (valid DNS q) :", udp('1.1.1.1',53,q))
print("  UDP 443 1.1.1.1 (QUIC-ish)   :", udp('1.1.1.1',443,b'\xc0'*64))
print("  UDP 123 time.google.com (NTP):", udp('time.google.com',123,b'\x1b'*48))
PYH
echo; echo "== ICMP ping 8.8.8.8 (sudo, 3 pings) =="
if sudook; then sudo -n ping -c 3 -W 2 8.8.8.8 2>&1 | tail -3; else echo "  (skipped: no sudo)"; fi
echo; echo "== IPv6 reachability =="
curl -6 -m 6 -sS -o /dev/null -w '  https://www.google.com over IPv6: http %{http_code}, %{time_total}s\n' https://www.google.com/ 2>&1 | head -2
RUNS=2; [ "$QUICK" = "1" ] && RUNS=1
echo; echo "== TCP 443 matrix via curl ($RUNS runs each: dns/conn/tls/ttfb/total) =="
for u in https://www.google.com/ https://github.com/ https://pypi.org/ https://huggingface.co/ https://registry.npmjs.org/ https://deb.debian.org/; do
  echo "  -- $u"
  i=0
  while [ $i -lt $RUNS ]; do
    i=$((i+1))
    curl -sS -o /dev/null -m 20 -w "    run$i: code=%{http_code} dns=%{time_namelookup} conn=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total} spd=%{speed_download}B/s\n" "$u" 2>&1 | head -1
  done
done
echo; echo "== plaintext HTTP =="
curl -sS -o /dev/null -m 10 -w '  http://google.com/ code=%{http_code} ttfb=%{time_starttransfer}s total=%{time_total}s\n' http://google.com/ 2>&1 | head -1
curl -sS -o /dev/null -m 10 -w '  http://deb.debian.org/ code=%{http_code} ttfb=%{time_starttransfer}s total=%{time_total}s\n' http://deb.debian.org/ 2>&1 | head -1
} > "$OUTDIR/09_net_matrix.txt" 2>&1

# ============================= 10 throughput =================================
{
echo "== Throughput: real downloads (curl -w, HTTP/1.1, timed $(date -u +%TZ)) =="
dl(){
  name="$1"; url="$2"; out="$3"; extra="${4:-}"
  out_line=$(curl -sS -m 120 $extra -o "$out" -w '%{size_download}|%{speed_download}|%{time_total}|%{time_starttransfer}|%{http_code}' "$url" 2>&1)
  python3 - "$name" "$out_line" <<'PYH'
import sys
name, raw = sys.argv[1], sys.argv[2]
try:
    sz, sp, tt, ttfb, code = raw.split('|')
    sz, sp, tt, ttfb, code = float(sz), float(sp), float(tt), float(ttfb), int(code)
    print(f"  {name:40s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {tt:6.2f}s  ttfb {ttfb*1000:6.0f} ms  code={code}")
except Exception:
    print(f"  {name:40s} FAILED: {raw[:140]}")
PYH
  rm -f "$out"
}
CFRUNS=3; [ "$QUICK" = "1" ] && CFRUNS=1
echo "-- cloudflare __down 50 MiB, ${CFRUNS} run(s) --"
i=0
while [ $i -lt $CFRUNS ]; do i=$((i+1)); dl "cloudflare 50MiB run$i" "https://speed.cloudflare.com/__down?bytes=52428800" /tmp/cf.bin; done
if [ "$QUICK" != "1" ]; then
  dl "hetzner 100MB.bin"            "https://speed.hetzner.de/100MB.bin" /tmp/hz.bin
  dl "codeload git/git v2.47.3 tgz" "https://codeload.github.com/git/git/tar.gz/refs/tags/v2.47.3" /tmp/git.tgz
fi
dl "HF gpt2 model.bin (range 5MB)" "https://huggingface.co/gpt2/resolve/main/pytorch_model.bin" /tmp/hf.bin "-L -r 0-5242879"
UPSZ=20971520; [ "$QUICK" = "1" ] && UPSZ=2097152
echo; echo "== upload test: cloudflare __up $((UPSZ/1048576))MiB =="
head -c $UPSZ /dev/urandom > /tmp/up.bin
curl -sS -m 120 -o /dev/null -X POST --data-binary @/tmp/up.bin -w '  upload: speed=%{speed_upload}B/s total=%{time_total}s code=%{http_code}\n' https://speed.cloudflare.com/__up 2>&1 | head -1
rm -f /tmp/up.bin
echo; echo "== egress location probe (ipinfo; non-fatal) =="
curl -sS -m 8 https://ipinfo.io/json 2>/dev/null | head -c 600 || echo "(ipinfo.io unreachable/slow)"
echo
echo; echo "== ssh handshake egress test (port 22, github) =="
if command -v ssh >/dev/null 2>&1; then timeout 12 ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 -T git@github.com 2>&1 | head -2; else echo "  (ssh absent)"; fi
echo; echo "== git clone (shallow, https) =="
rm -rf /tmp/hwclone
t0=$(date +%s.%N)
timeout 30 git clone -q --depth 1 https://github.com/octocat/Hello-World.git /tmp/hwclone 2>&1
t1=$(date +%s.%N)
python3 - <<PYH
import os
sz=0
for r,_,fs in os.walk('/tmp/hwclone'):
    sz+=sum(os.path.getsize(os.path.join(r,f)) for f in fs)
print(f'  clone ok, {sz/1024:.0f} KiB in {($t1-$t0):.2f}s')
PYH
echo; echo "== node/npm registry install test (express, small tree) =="
if [ "$QUICK" = "1" ]; then echo "  [QUICK] skipped"; else
rm -rf /tmp/npmtest && mkdir -p /tmp/npmtest && cd /tmp/npmtest
t0=$(date +%s.%N)
timeout 90 npm install express@4 --no-audit --no-fund --loglevel=error >/dev/null 2>&1
rc=$?
t1=$(date +%s.%N)
python3 - <<PYH
import os
d='/tmp/npmtest/node_modules'
sz=sum(os.path.getsize(os.path.join(r,f)) for r,_,fs in os.walk(d) for f in fs) if os.path.isdir(d) else 0
print(f'  npm install express@4: rc=$rc in {($t1-$t0):.2f}s, tree {sz/1048576:.1f} MiB')
PYH
cd - >/dev/null; fi
} > "$OUTDIR/10_net_throughput.txt" 2>&1

# ============================= 10b throughput round 2 ========================
{
echo "== Throughput round 2 (fixed) $(date -u +%TZ) =="
dl(){
  name="$1"; url="$2"; out="$3"; extra="${4:-}"
  out_line=$(curl -sS -m 120 $extra -o "$out" -w '%{size_download}|%{speed_download}|%{time_total}|%{time_starttransfer}|%{http_code}' "$url" 2>&1)
  python3 - "$name" "$out_line" <<'PYH'
import sys
name, raw = sys.argv[1], sys.argv[2]
try:
    sz, sp, tt, ttfb, code = raw.split('|')
    sz, sp, tt, ttfb, code = float(sz), float(sp), float(tt), float(ttfb), int(code)
    print(f"  {name:40s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {tt:6.2f}s  ttfb {ttfb*1000:6.0f} ms  code={code}")
except Exception:
    print(f"  {name:40s} FAILED: {raw[:140]}")
PYH
  rm -f "$out"
}
if [ "$QUICK" = "1" ]; then
  echo "  [QUICK] extra cloudflare repeats skipped"
else
  echo "-- cloudflare __down 50 MiB, 3 runs --"
  for i in 1 2 3; do dl "cloudflare 50MiB run$i" "https://speed.cloudflare.com/__down?bytes=52428800" /tmp/cf.bin; done
fi
echo "-- huggingface with -L (gpt2 pytorch_model.bin, 5 MiB range) --"
dl "HF gpt2 model.bin range5MiB" "https://huggingface.co/gpt2/resolve/main/pytorch_model.bin" /tmp/hf.bin "-L -r 0-5242879"
echo "-- hetzner retry + raw DNS checks (blocklist detection) --"
dl "hetzner 100MB.bin retry" "https://speed.hetzner.de/100MB.bin" /tmp/hz.bin
python3 - <<'PYH'
import socket,time,random
def q(host):
    qid=random.randint(0,65535)
    hdr=qid.to_bytes(2,'big')+b'\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'
    qq=b''.join(bytes([len(l)])+l.encode() for l in host.split('.'))+b'\x00'+b'\x00\x01\x00\x01'
    s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(3.0)
    t0=time.perf_counter(); s.sendto(hdr+qq,('8.8.8.8',53))
    try:
        d,_=s.recvfrom(4096); rcode=d[3]&0xf; an=int.from_bytes(d[6:8],'big')
        ips=[]
        off=12
        while d[off]!=0: off+=1+d[off]
        off+=5
        for _ in range(min(an,4)):
            ips.append('.'.join(map(str,d[off+10:off+14]))); off+=16
        print(f"  {host:28s} rcode={rcode} answers={an} ips={ips} {(time.perf_counter()-t0)*1000:.1f} ms")
    except socket.timeout:
        print(f"  {host:28s} TIMEOUT")
    s.close()
for h in ['speed.hetzner.de','random123.hetzner.de','www.hetzner.com','www.python.org','pypi.org','download.hetzner.de','dl.google.com','speedtest.net']:
    q(h)
PYH
echo "  (HF multi-connection throughput test consolidated in 12b_pip2.txt)"
if [ "$QUICK" = "1" ]; then
  echo "  [QUICK] pypi-wheel/OVH/apt sections skipped"
else
  echo "-- pypi JSON + files.pythonhosted.org linux cp313 wheel --"
  WHEEL=$(curl -sS -m 15 https://pypi.org/pypi/numpy/json | jq -r '.urls[] | select(.filename | contains("cp313") and contains("manylinux_2_17_x86_64")) | .url' | head -1)
  echo "  wheel: ${WHEEL##*/}"; [ -n "$WHEEL" ] && dl "pypi numpy wheel (~16MiB)" "$WHEEL" /tmp/np.whl
  echo "-- OVH (EU CDN) 100 MiB --"
  dl "OVH 100Mb.dat" "https://proof.ovh.net/files/100Mb.dat" /tmp/ovh.bin
  echo "-- apt effective rate (fresh update, timed; needs sudo) --"
  if sudook; then t0=$(date +%s.%N); sudo -n apt-get update >/dev/null 2>&1; t1=$(date +%s.%N); python3 -c "print(f'  apt-get update: {($t1-$t0):.2f}s')"; else echo "  (skipped: no sudo)"; fi
fi
} > "$OUTDIR/10b_net_throughput2.txt" 2>&1

echo "[probe] sections 09-10b written to $OUTDIR (part 2 done)"
# ============================= 11 disk =======================================
{
echo "== disk backend =="
for b in /sys/block/*/queue/rotational; do echo "  $b -> $(cat $b 2>/dev/null) (0=SSD,1=HDD)"; done
ls -l /dev/root 2>/dev/null; readlink /dev/root 2>/dev/null || true
grep ' / ' /proc/self/mountinfo | head -1
PYWRITE=100; DDCNT=100; TMPFS_MIB=500; NFILES=20000
if [ "$QUICK" = "1" ]; then PYWRITE=32; DDCNT=32; TMPFS_MIB=64; NFILES=4000; echo "  [QUICK] reduced sizes"; fi
echo; echo "== sequential write ${PYWRITE} MiB (python, 1 MiB blocks, buffered+fsync) =="
PYWRITE=$PYWRITE python3 - <<'PYH'
import os, time
n=int(os.environ['PYWRITE'])
path='/home/user/.bench100'
buf=os.urandom(1048576)
f=open(path,'wb')
t0=time.perf_counter()
for _ in range(n): f.write(buf)
t1=time.perf_counter()
os.fsync(f.fileno()); t2=time.perf_counter()
f.close()
print(f"  write {n}MiB: {n/(t1-t0):.0f} MiB/s wall ({t1-t0:.2f}s) ; fsync {t2-t1:.3f}s ; total w/ fsync {(t2-t0):.2f}s")
PYH
echo; echo "== dd O_DIRECT write ${DDCNT} MiB =="
dd if=/dev/zero of=/home/user/.bench100_direct bs=1M count=$DDCNT oflag=direct conv=fdatasync 2>&1 | tail -1 || echo "  O_DIRECT write unsupported here"
echo; echo "== warm read (page cache) =="
python3 - <<'PYH'
import os, time
f=open('/home/user/.bench100','rb'); total=0; t0=time.perf_counter()
while True:
    d=f.read(1048576)
    if not d: break
    total+=len(d)
t1=time.perf_counter(); f.close()
print(f"  read warm: {total/1048576/(t1-t0):.0f} MiB/s ({t1-t0:.2f}s)")
PYH
echo; echo "== COLD read (after sudo drop_caches) =="
if sudook; then sudo -n sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches' && echo "  dropped caches"
python3 - <<'PYH'
import os, time
f=open('/home/user/.bench100','rb'); total=0; t0=time.perf_counter()
while True:
    d=f.read(1048576)
    if not d: break
    total+=len(d)
t1=time.perf_counter(); f.close()
print(f"  read cold:  {total/1048576/(t1-t0):.0f} MiB/s ({t1-t0:.2f}s)")
PYH
else echo "  (skipped: no sudo for drop_caches)"; fi
echo; echo "== dd O_DIRECT read ${DDCNT} MiB =="
dd if=/home/user/.bench100_direct of=/dev/null bs=1M iflag=direct 2>&1 | tail -1 || echo "  O_DIRECT read unsupported here"
rm -f /home/user/.bench100 /home/user/.bench100_direct && echo "  (bench files removed)"
echo; echo "== tmpfs (RAM) ${TMPFS_MIB} MiB write+read in /tmp and /dev/shm =="
for d in /tmp /dev/shm; do
TMPFS_MIB=$TMPFS_MIB TMPDIR2=$d python3 - <<'PYH'
import os, time
mib=int(os.environ['TMPFS_MIB']); path=os.environ['TMPDIR2']+'/.tbench'
buf=os.urandom(1048576)
f=open(path,'wb'); t0=time.perf_counter()
for _ in range(mib): f.write(buf)
os.fsync(f.fileno()); t1=time.perf_counter(); f.close()
f=open(path,'rb'); t2=time.perf_counter()
while f.read(1048576): pass
t3=time.perf_counter(); f.close(); os.unlink(path)
print(f"  {os.environ['TMPDIR2']}: write {mib/(t1-t0):.0f} MiB/s, read {mib/(t3-t2):.0f} MiB/s (incl fsync on write)")
PYH
done
echo; echo "== small-file inode ops: create/delete $((NFILES/1000))k files (ext4) =="
rm -rf /tmp/inotest && mkdir -p /tmp/inotest
t0=$(date +%s.%N); for i in $(seq 1 $NFILES); do : > /tmp/inotest/f$i; done; t1=$(date +%s.%N)
t2=$(date +%s.%N); rm -rf /tmp/inotest; t3=$(date +%s.%N)
python3 -c "print(f'  create $NFILES files: {$NFILES/($t1-$t0):,.0f} files/s ; delete: {$NFILES/($t3-$t2):,.0f} files/s')"
echo; echo "== page-cache pressure note: df after benches =="
df -h /home/user | tail -1
} > "$OUTDIR/11_disk.txt" 2>&1

# ============================= 12 pip ========================================
{
echo "== pip/package-manager capability suite =="
echo "== global site-packages perms (default pip target for /usr/local python) =="
ls -ld /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13 2>&1
test -w /usr/local/lib/python3.13/site-packages 2>/dev/null && echo "site-packages WRITABLE by user" || echo "site-packages NOT writable by user (need venv/--user/sudo)"
echo; echo "== python 3.13 build flags =="
python3 -c "import sysconfig; print('Py_GIL_DISABLED:', sysconfig.get_config_var('Py_GIL_DISABLED')); print('SOABI:', sysconfig.get_config_var('SOABI'))"
echo; echo "== venv creation + timing =="
rm -rf /tmp/vptest
t0=$(date +%s.%N); python3 -m venv /tmp/vptest; t1=$(date +%s.%N)
python3 -c "print(f'  venv created in {($t1-$t0):.2f}s')"
V=/tmp/vptest/bin/pip
echo; echo "== wheel installs (timed, quiet) =="
pin(){ pkg="$1"; t0=$(date +%s.%N); timeout 180 $V install -q --disable-pip-version-check "$pkg" >/dev/null 2>&1; rc=$?; t1=$(date +%s.%N); python3 -c "print(f'  {pkg:16s} rc=$rc in {($t1-$t0):6.2f}s')"; }
pin "rich (pure-python wheel)"
if [ "$QUICK" != "1" ]; then
  pin "orjson (rust wheel)"
  pin "numpy (C wheel)"
fi
echo; echo "== sdist builds =="
if [ "$QUICK" = "1" ]; then echo "  [QUICK] sdist builds skipped"; else
t0=$(date +%s.%N); timeout 240 $V install -q --disable-pip-version-check --no-binary :all: "markupsafe==3.0.2" >/dev/null 2>&1; rc=$?; t1=$(date +%s.%N); python3 -c "print(f'  markupsafe sdist (C ext compile, build isolation): rc=$rc in {($t1-$t0):6.2f}s')"
t0=$(date +%s.%N); timeout 240 $V install -q --disable-pip-version-check six >/dev/null 2>&1; rc=$?; t1=$(date +%s.%N); python3 -c "print(f'  six (pure sdist, legacy setup.py): rc=$rc in {($t1-$t0):6.2f}s')"
fi
echo; echo "== import + version sanity =="
/tmp/vptest/bin/python - <<'PYH'
mods=['rich']
for m in ('orjson','numpy','markupsafe'):
    try:
        __import__(m); mods.append(m)
    except ImportError:
        pass
for m in mods:
    mod=__import__(m)
    print(f"  {m:12s} {getattr(mod,'__version__','?')}")
PYH
echo; echo "== numpy micro-benches (from /usr/local python? use venv numpy) =="
echo "  (run-1 artifact: benches below run inside the venv python)"
echo; echo "-- json/orjson/numpy micro-benches (as available) --"
/tmp/vptest/bin/python - <<'PYH'
import time, json
rec={"a":1,"b":[1,2,3],"c":"x"*50}
t0=time.perf_counter()
for _ in range(200_000): json.dumps(rec)
t1=time.perf_counter()
print(f"  json.dumps x200k   = {(t1-t0)*1000:7.1f} ms")
try:
    import orjson
    t0=time.perf_counter()
    for _ in range(200_000): orjson.dumps(rec)
    t1=time.perf_counter()
    print(f"  orjson.dumps x200k = {(t1-t0)*1000:7.1f} ms")
except ImportError: pass
try:
    import numpy as np
    t0=time.perf_counter(); a=np.arange(10_000_000,dtype=np.float64); s=float(a.sum())
    print(f"  arange(1e7,f64).sum= {s:.0f} in {(time.perf_counter()-t0)*1000:6.1f} ms (incl alloc)")
    t0=time.perf_counter(); A=np.random.default_rng(0).random((2048,2048)); B=A@A
    print(f"  2048x2048 matmul   = {(time.perf_counter()-t0)*1000:6.1f} ms (incl rng+alloc)")
    np.dot(A,B)
    t0=time.perf_counter()
    for _ in range(100): np.dot(A,B)
    print(f"  np.dot warm x100   = {(time.perf_counter()-t0)*10:6.2f} ms/op")
except ImportError: pass
PYH
echo; echo "== pip --user install test (outside venv, default interpreter) =="
if [ "$QUICK" = "1" ]; then echo "  [QUICK] skipped"; else
t0=$(date +%s.%N); timeout 120 pip install -q --user --disable-pip-version-check "idna==3.10" 2>&1 | tail -1; rc=${PIPESTATUS[0]}; t1=$(date +%s.%N)
python3 -c "import idna" 2>/dev/null && echo "  idna importable from default python (rc=$rc, $(python3 -c "print(f'{$t1-$t0:.2f}s')")s)"
python3 -c "import site; print('  user site:', site.getusersitepackages())"
ls -la /home/user/.local/lib/python3.13/site-packages 2>/dev/null | head -3
fi
} > "$OUTDIR/12_pip.txt" 2>&1

# ============================= 12b net follow-up =============================
{
echo "== pip wheel install rerun with FULL output =="
echo "  (run-1 debugging artifact; consolidated probe in 12_pip.txt)"
echo "== numpy: linux wheel direct download then install =="
echo "  consolidated in 12_pip.txt"
echo "== numpy bench (fixed syntax) =="
echo "  consolidated in 12_pip.txt"
echo; echo "== HF multi-connection throughput (4 parallel 5MiB ranges) =="
NCONN=4; [ "$QUICK" = "1" ] && NCONN=1
t0=$(date +%s.%N)
i=0
while [ $i -lt $NCONN ]; do
  s=$((i*5242880)); e=$((s+5242879))
  curl -sS -m 60 -L -r ${s}-${e} -o /tmp/hf$i.bin "https://huggingface.co/gpt2/resolve/main/pytorch_model.bin" &
  i=$((i+1))
done
wait
t1=$(date +%s.%N)
sz=$(cat /tmp/hf*.bin 2>/dev/null | wc -c)
python3 - <<PYH
print(f'  $NCONN x 5MiB parallel: {$t1-$t0:.2f}s wall, aggregate $sz bytes -> {$sz/1048576/($t1-$t0):.1f} MiB/s (files $(ls /tmp/hf?.bin 2>/dev/null | wc -l))')
PYH
rm -f /tmp/hf?.bin
echo; echo "== hetzner DNS follow-up (rcode/an/type) =="
python3 - <<'PYH'
import socket, time, random
def q(host):
    qid=random.randint(0,65535)
    hdr=qid.to_bytes(2,'big')+b'\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00'
    qq=b''.join(bytes([len(l)])+l.encode() for l in host.split('.'))+b'\x00'+b'\x00\x01\x00\x01'
    s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(3.0)
    t0=time.perf_counter(); s.sendto(hdr+qq,('8.8.8.8',53))
    try:
        d,_=s.recvfrom(4096); rcode=d[3]&0xf; an=int.from_bytes(d[6:8],'big')
        ips=[]
        off=12
        while d[off]!=0: off+=1+d[off]
        off+=5
        for _ in range(min(an,4)):
            ips.append('.'.join(map(str,d[off+10:off+14]))); off+=16
        print(f"  {host:28s} rcode={rcode} answers={an} ips={ips} {(time.perf_counter()-t0)*1000:.1f} ms")
    except socket.timeout:
        print(f"  {host:28s} TIMEOUT")
    s.close()
for h in ['speed.hetzner.de','www.hetzner.com','www.python.org','pypi.org','dl.google.com']:
    q(h)
PYH
echo; echo "== net hostname sanity =="
hostname -f 2>/dev/null || hostname
} > "$OUTDIR/12b_pip2.txt" 2>&1

# ============================= 13 misc + bg spawn ============================
{
echo "== numpy via pip download+install (linux cp313 wheel) =="
echo "  consolidated in 12_pip.txt"
echo "== numpy + orjson micro-bench =="
echo "  consolidated in 12_pip.txt (benchmarks run there)"
echo; echo "== spawn detached background ticker (cross-call survival test) =="
TICK_FILE="$OUTDIR/bg_ticks.txt"
rm -f "$TICK_FILE"
sleepfor=12; [ "$QUICK" = "1" ] && sleepfor=6
setsid bash -c 'out="$1"; n=0; while [ $n -lt 30 ]; do date -u +%FT%TZ >> "$out"; n=$((n+1)); sleep 5; done' _ "$TICK_FILE" </dev/null >/dev/null 2>&1 &
TICKPID=$!
echo "$TICKPID" > "$OUTDIR/.tickerpid"
echo "  spawned pid=$TICKPID (setsid, detached), ticks every 5s -> $TICK_FILE"
sleep "$sleepfor"
echo "  ticks so far: $(wc -l < "$TICK_FILE") (still running; final check in section 15)"
echo "  NOTE: the canonical run verified survival ACROSS tool calls in an interactive"
echo "        session; a single script run can only demonstrate in-session survival."
echo; echo "== GPU / special devices =="
ls /dev/dri /dev/nvidia* 2>&1 | head -3
ls /dev/kvm 2>&1 | head -1
ls /dev | head -20
echo; echo "== kernel modules loaded? =="
lsmod 2>/dev/null | head -8 || cat /proc/modules 2>/dev/null | head -5 || echo "no module visibility"
echo; echo "== sysctl highlights =="
for s in kernel.hostname kernel.pid_max vm.swappiness fs.file-max net.ipv4.ip_forward kernel.random.boot_id; do printf '  %-24s' "$s"; if sudook; then sudo -n sysctl -n $s 2>/dev/null || echo "n/a"; else sysctl -n $s 2>/dev/null || echo "n/a (no sudo)"; fi; done
echo; echo "== git local demo (init/commit in /tmp) =="
rm -rf /tmp/gitdemo && mkdir -p /tmp/gitdemo && cd /tmp/gitdemo
git init -q && git config user.email bench@local && git config user.name bench
echo hi > f.txt && git add f.txt && git commit -qm init
git log --oneline | head -1
cd - >/dev/null
echo; echo "== jupyter/code-interpreter context =="
ps -eo pid,comm,args --sort=-%cpu 2>/dev/null | grep -iE 'jupyter|uvicorn|envd|code-interpreter' | grep -v grep | head -6 || echo "  none"
echo; echo "== final: free + df + load =="
free -m | head -2
df -h /home/user /tmp | tail -2
cat /proc/loadavg
} > "$OUTDIR/13_bg_misc.txt" 2>&1
# ============================= 14 final state ================================
{
echo "== BG TICKER survival check (spawned in previous tool call) =="
TICKPID=$(cat "$OUTDIR/.tickerpid" 2>/dev/null || echo 0)
if kill -0 "$TICKPID" 2>/dev/null; then echo "  process $TICKPID alive: yes"; ps -p "$TICKPID" -o pid,ppid,etime,comm 2>/dev/null | tail -1; else echo "  process $TICKPID alive: NO"; fi
echo "  ticks recorded: $(wc -l < "$OUTDIR/bg_ticks.txt" 2>/dev/null || echo 0)"
echo "  first tick: $(head -1 "$OUTDIR/bg_ticks.txt" 2>/dev/null)"
echo "  last tick:  $(tail -1 "$OUTDIR/bg_ticks.txt" 2>/dev/null)"
echo; echo "== persistence markers from round 1 =="
for f in /home/user/.persist_marker_probe /tmp/.persist_marker_probe; do
  if [ -f "$f" ]; then echo "  $f: PRESENT -> $(cat $f)"; rm -f "$f"; else echo "  $f: GONE"; fi
done
echo; echo "== VM session state =="
echo "  uptime: $(uptime -p) (started $(uptime -s))"
echo "  boot_id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo n/a)"
echo "  hostname: $(hostname)"
echo "  sandbox_id: ${E2B_SANDBOX_ID:-<not set>}  template_id: ${E2B_TEMPLATE_ID:-<not set>}"
echo "  threads: $(ps -eLf 2>/dev/null | wc -l)"
echo; echo "== load + memory now =="
cat /proc/loadavg; free -m | head -2
echo; echo "== envprobe raw-notes inventory =="
ls -la "$OUTDIR" | awk 'NR>3 {printf "  %-26s %8d B\n", $9, $5}'
echo; echo "== total workspace size =="
du -sh "$OUTDIR" 2>/dev/null
echo; echo "== /proc/1 sanity: container re-check =="
ls -la /.dockerenv /run/.containerenv 2>&1 | grep -c 'No such' | xargs echo "  dockerenv+containerenv absent count (expect 2):"
echo; echo "== jupyter health (service on 8888/49999) =="
curl -s -o /dev/null -m 3 -w '  jupyter 127.0.0.1:8888 -> %{http_code}\n' http://127.0.0.1:8888/ 2>&1 | tail -1 || echo "  (no local jupyter)"
} > "$OUTDIR/14_final.txt" 2>&1

# ============================= 15 process demo ===============================
{
echo "== supervised long-running process check (start_process) =="
python3 -m http.server 8899 --bind 127.0.0.1 --directory "$OUTDIR" >/dev/null 2>&1 &
SRVPID=$!
sleep 1.5
curl -s -m 5 -o /dev/null -w '  http://127.0.0.1:8899/ -> HTTP %{http_code} in %{time_total}s\n' http://127.0.0.1:8899/
curl -s -m 5 http://127.0.0.1:8899/ | head -4 | sed 's/^/  /'
kill "$SRVPID" 2>/dev/null && echo "  local server stopped"
echo "  NOTE: run-1 additionally verified the platform-supervised process runner"
echo "  (start_process, port proxied for live preview); not reproducible from a"
echo "  plain shell script. Bind servers to 0.0.0.0 when using that runner."
echo; echo "== ticker final count before cleanup =="
TICKPID=$(cat "$OUTDIR/.tickerpid" 2>/dev/null || echo 0)
if kill -0 "$TICKPID" 2>/dev/null; then echo "  pid $TICKPID alive: yes"; else echo "  pid $TICKPID alive: no (already exited)"; fi
echo "  ticks: $(wc -l < "$OUTDIR/bg_ticks.txt" 2>/dev/null)"
echo "  span: $(head -1 "$OUTDIR/bg_ticks.txt" 2>/dev/null) .. $(tail -1 "$OUTDIR/bg_ticks.txt" 2>/dev/null)"
kill "$TICKPID" 2>/dev/null && echo "  ticker stopped"
rm -f "$OUTDIR/.tickerpid"
} > "$OUTDIR/15_process_demo.txt" 2>&1

# ============================= epilogue: manifest ============================
{
echo "== run epilogue: sha256sums + manifest =="
cd "$OUTDIR" || exit 1
FILES=$(ls 0*.txt 1*.txt bg_ticks.txt 2>/dev/null | sort)
sha256sum $FILES > sha256sums.txt
cat sha256sums.txt | sed 's/^/  /'
MAN_START=$(grep -m1 run_start_utc 00_run_header.txt | awk '{print $2}')
python3 - "$MAN_START" <<'PYH'
import os, sys, json, hashlib, socket, glob, datetime
start = sys.argv[1]
files = sorted(glob.glob('0*.txt') + glob.glob('1*.txt') + glob.glob('bg_ticks.txt'))
entries = []
for f in files:
    data = open(f, 'rb').read()
    entries.append({'path': f, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
man = {
    "manifest": "environment-probe-run-manifest", "schema_version": 1,
    "run": {
        "started_utc": start,
        "ended_utc": datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        "producer": "environment_probe.sh (independent re-run)",
        "note": "numeric values expected to differ between runs; compare structure with compare_run.sh"
    },
    "sandbox": {
        "hostname": socket.gethostname(),
        "boot_id": open('/proc/sys/kernel/random/boot_id').read().strip(),
        "E2B_SANDBOX": os.environ.get('E2B_SANDBOX'),
        "E2B_SANDBOX_ID": os.environ.get('E2B_SANDBOX_ID'),
        "E2B_TEMPLATE_ID": os.environ.get('E2B_TEMPLATE_ID')
    },
    "files": entries
}
json.dump(man, open('manifest.json', 'w'), indent=2)
print(f"manifest.json written: {len(entries)} files hashed")
PYH
cd - >/dev/null
} > "$OUTDIR/epilogue.txt" 2>&1
cat "$OUTDIR/epilogue.txt" | sed 's/^/[epilogue] /'
echo "[probe] DONE. Outputs in $OUTDIR (started $RUN_START_UTC)."
