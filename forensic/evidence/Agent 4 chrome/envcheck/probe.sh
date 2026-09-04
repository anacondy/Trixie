#!/usr/bin/env bash
# probe.sh — reproducible environment characterization probe (E2B/Debian sandbox).
#
#   Usage:  ./probe.sh [OUTDIR] [--fast] [--with-oom] [--reps N]
#
#   OUTDIR      directory for numbered raw transcripts (default: ./raw)
#   --fast      fewer repetitions / smaller payloads (~40 s instead of ~4 min)
#   --with-oom  actually drive the cgroup to OOM (kills a child process; off by default)
#   --reps N    override repetition count for timed measurements
#
# Design rules (so a third party can diff my output against theirs):
#   * Every section writes ONE file, verbatim, with a self-identifying header.
#   * No summarization: raw command lines are echoed before their output, prefixed "$ ".
#   * Deterministic ordering: lists are sorted; nothing depends on locale (LC_ALL=C).
#   * Missing tools are recorded as "ABSENT", never silently skipped, so structure diffs cleanly.
#   * Timings vary by nature; `diff_run.sh` masks them so you diff structure + verdicts.
#
# Exit status: 0 = completed, 1 = a required probe could not run at all.

set -u
export LC_ALL=C TZ=UTC

OUTDIR="./raw"; REPS=3; FAST=0; WITH_OOM=0
while [ $# -gt 0 ]; do
  case "$1" in
    --fast)    FAST=1; REPS=1 ;;
    --with-oom) WITH_OOM=1 ;;
    --reps)    shift; REPS="${1:-3}" ;;
    --reps=*)  REPS="${1#*=}" ;;
    *)         OUTDIR="$1" ;;
  esac
  shift
done

VER="1.0.0"
PROBE_START_NS=$(date +%s%N)
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$OUTDIR"

SID="${E2B_SANDBOX_ID:-none}"; TID="${E2B_TEMPLATE_ID:-none}"
KERN=$(uname -r); HOST=$(uname -n)

# ---------------------------------------------------------------- helpers
# cur() opens a new transcript; hdr() writes the self-identifying header.
CUR=""
cur() {
  CUR="$OUTDIR/$1"
  {
    echo "================================================================"
    echo " probe.sh v$VER   section: $1"
    echo " run_id:    $RUN_ID"
    echo " started:   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo " sandbox:   $SID"
    echo " template:  $TID"
    echo " host:      $HOST   kernel: $KERN   arch: $(uname -m)"
    echo " effective: ${E2B_SANDBOX:+E2B_SANDBOX=$E2B_SANDBOX}${E2B_SANDBOX:-non-E2B host}"
    echo " user:      $(id -un 2>/dev/null || echo '?') uid=$(id -u) mode=$([ "$FAST" = 1 ] && echo fast || echo full) reps=$REPS oom=$WITH_OOM"
    echo "================================================================"
    echo
  } > "$CUR"
}
# sh_ : run a shell snippet, echoing it first (verbatim transcript style)
sh_() {
  printf '$ %s\n' "$*" >> "$CUR"
  # awk 1 guarantees a trailing newline so records never run together
  bash -c "$*" 2>&1 | awk '{print}' >> "$CUR"
  rc=${PIPESTATUS[0]}
  [ "$rc" = 0 ] || printf '  [exit=%s]\n' "$rc" >> "$CUR"
  echo >> "$CUR"
}
# shn_ : same but normalize nothing, mark absent binary clearly
have() { command -v "$1" >/dev/null 2>&1; }

py() { # run inline python into the current file
  printf '$ python3 - <<PY\n' >> "$CUR"
  cat "$1" >> "$CUR"
  printf '\n[PY]\n' >> "$CUR"
  python3 "$1" >> "$CUR" 2>&1 || printf '  [python exit=%d]\n' "$?" >> "$CUR"
  echo >> "$CUR"
}

TMPD=$(mktemp -d 2>/dev/null || echo /tmp/probe.$$); mkdir -p "$TMPD"
trap 'rm -rf "$TMPD"' EXIT

probe_start_epoch=$(date +%s)

# ================================================================ 00 meta
cur 00_meta.txt
sh_ "date -u '+%Y-%m-%dT%H:%M:%SZ'; date -u +%s"
sh_ "echo RUN_ID=$RUN_ID"
{ printf '$ echo probe.sh metadata\n'
  printf '  probe.sh version=%s  mode=%s  reps=%s  with_oom=%s  run_id=%s\n' "$VER" "$([ "$FAST" = 1 ] && echo fast || echo full)" "$REPS" "$WITH_OOM" "$RUN_ID"
  echo; } >> "$CUR"
sh_ "cat /etc/os-release"
sh_ "uname -a"
sh_ "cat /proc/uptime; cat /proc/loadavg"
sh_ "env | sort | grep -iE '^E2B_|^SANDBOX|^ARENA|^CI=' || echo '(no E2B_*/SANDBOX env vars)'"
sh_ "nproc; getconf _NPROCESSORS_ONLN; getconf _NPROCESSORS_CONF"

# ================================================================ 01 runtime
cur 01_runtime.txt
sh_ "cat /etc/os-release"
sh_ "uname -a; uname -r; uname -m; arch"
sh_ "ldd --version 2>&1 | head -2"
sh_ "/lib/x86_64-linux-gnu/libc.so.6 2>&1 | head -2 || echo 'libc.so.6 path not present'"
sh_ "ls -la /etc/debian_version 2>/dev/null && cat /etc/debian_version || echo 'not debian'"
sh_ "grep -m1 'model name' /proc/cpuinfo; grep -m1 'cpu MHz' /proc/cpuinfo; grep -c ^processor /proc/cpuinfo"
sh_ "grep -m1 flags /proc/cpuinfo | tr ' ' '\n' | grep -E '^(avx|avx2|avx512f|fma|aes|sse4_2|vmx|svm|rdrand)$' | sort | tr '\n' ' '; echo"
sh_ "head -8 /proc/meminfo"
sh_ "free -b; echo '---'; free -h"
sh_ "for f in /sys/devices/system/cpu/vulnerabilities/*; do printf '%-28s %s\n' \"\$(basename \$f)\" \"\$(cat \$f)\"; done | sort"
sh_ "cat /proc/sys/kernel/ostype /proc/sys/kernel/osrelease; getconf GNU/libc/version 2>/dev/null"
sh_ "date -u; ls -la /bin/sh"
have lscpu && sh_ "lscpu | sed 's/  */ /g'" || sh_ "echo 'lscpu: ABSENT'"

# ================================================================ 02 isolation
cur 02_isolation.txt
sh_ "ls -la /.dockerenv /run/.containerenv 2>&1"
sh_ "cat /proc/1/cgroup; echo '--- self ---'; cat /proc/self/cgroup"
sh_ "grep -E 'cgroup' /proc/mounts"
sh_ "cat /sys/fs/cgroup/cgroup.controllers 2>&1; cat /sys/fs/cgroup/cgroup.subtree_control 2>&1"
sh_ "ls /sys/fs/cgroup/ | sort"
sh_ "CG=/sys/fs/cgroup\$(awk -F: '\$1==0{print \$3}' /proc/self/cgroup); echo \"cgroup dir: \$CG\"; for f in cpu.max cpu.weight cpuset.cpus.effective memory.max memory.high memory.current memory.swap.max pids.max io.max; do printf '%-24s %s\n' \$f \"\$(cat \$CG/\$f 2>&1 | head -1)\"; done"
sh_ "CG=/sys/fs/cgroup\$(awk -F: '\$1==0{print \$3}' /proc/self/cgroup); echo '--- cpu.stat ---'; cat \$CG/cpu.stat 2>&1; echo '--- memory.events ---'; cat \$CG/memory.events 2>&1"
sh_ "grep -E 'Cap(Inh|Prm|Eff|Bnd|Amb)|NoNewPrivs|Seccomp' /proc/self/status"
sh_ "grep -E 'CapEff' <(sudo -n grep CapEff /proc/self/status 2>/dev/null) || echo 'sudo unavailable or no output'"
sh_ "for f in /proc/self/ns/*; do printf '%-24s %s\n' \$(basename \$f) \"\$(readlink \$f)\"; done | sort"
sh_ "ls /proc/self/ns -la | head -3"
sh_ "cat /proc/mounts | sort"
sh_ "awk '(\$4 ~ /(^|,)ro(,|\$)/) {print \$2, \$3, \$4}' /proc/mounts | sort; echo '[end read-only list]'"
sh_ "cat /proc/partitions; ls -la /dev/vda /dev/sda /dev/nvme0n1 2>&1 | head -4"
sh_ "ls /sys/class/dmi/id/ 2>&1 | head -5; cat /sys/class/dmi/id/product_name 2>&1; cat /sys/class/dmi/id/sys_vendor 2>&1"
sh_ "ps -eo pid,ppid,user,etime,rss,comm --sort=pid | head -30"
sh_ "ps -eo comm= | grep -cE '^\[|kworker|ksoftirqd' ; echo '(count of kernel-ish threads visible in ps -> nonzero means own kernel = VM, not container)'"
sh_ "dmesg 2>&1 | tail -3 || echo 'dmesg not readable'"
sh_ "cat /proc/net/fib_trie 2>/dev/null | head -2 > /dev/null && echo ok; ss -tulnp 2>/dev/null | head -5 || netstat -tuln | head -5"
sh_ "cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo 'no root cpu.max'"
have capsh && sh_ "capsh --print 2>&1 | head -12" || sh_ "echo 'capsh: ABSENT (decode CapBnd 000001ffffffffff = full set)'"; :

# ================================================================ 03 limits
cur 03_limits.txt
sh_ "ulimit -a"
sh_ "echo \"soft_nofile=\$(ulimit -Sn) hard_nofile=\$(ulimit -Hn)\"; echo \"soft_nproc=\$(ulimit -Su) hard_nproc=\$(ulimit -Hu)\""
sh_ "echo 'raise test:'; bash -c 'ulimit -n 65536 && echo \"  65536 OK -> \$(ulimit -n)\"'; bash -c 'ulimit -n 700000 2>/dev/null && echo \"  700000 OK\" || echo \"  700000 rejected (hard cap)\"'"
sh_ "cat /proc/sys/kernel/threads-max /proc/sys/kernel/pid_max /proc/sys/vm/max_map_count /proc/sys/user/max_user_namespaces 2>&1"
sh_ "cat /proc/sys/vm/swappiness /proc/sys/vm/overcommit_memory /proc/sys/vm/dirty_ratio /proc/sys/vm/dirty_background_ratio 2>&1"
sh_ "(swapon --show 2>/dev/null || cat /proc/swaps 2>/dev/null) | head -3; echo '--- /proc/meminfo ---'; awk '/SwapTotal|SwapFree/{print}' /proc/meminfo"
sh_ "ls /etc/security/limits.d/ 2>&1; cat /etc/security/limits.conf 2>/dev/null | grep -vE '^\s*#|^\s*$' | head -10; cat /etc/security/limits.d/* 2>/dev/null | grep -vE '^\s*#|^\s*$'"
sh_ "python3 -c 'import resource;print({n:resource.getrlimit(getattr(resource,n)) for n in [\"RLIMIT_NOFILE\",\"RLIMIT_NPROC\",\"RLIMIT_STACK\",\"RLIMIT_CORE\",\"RLIMIT_MEMLOCK\"]})' 2>&1 || echo 'python3/resource unavailable'"

# ================================================================ 04 users
cur 04_users.txt
sh_ "id; whoami; groups; echo HOME=\$HOME SHELL=\$SHELL"
sh_ "sudo -n true 2>&1; echo \"sudo -n true exit=\$?\""
sh_ "sudo -n id 2>&1"
sh_ "sudo -n grep CapEff /proc/self/status 2>&1"
sh_ "sudo -n touch /etc/.probe_wtest 2>&1 && sudo -n rm -f /etc/.probe_wtest && echo 'ROOT WRITE /etc: OK (test file removed)'"
sh_ "touch /root/.probe_wtest 2>&1 || echo 'user write /root: DENIED (expected)'"
sh_ "grep -hE 'NOPASSWD|%sudo|^root' /etc/sudoers 2>/dev/null || sudo -n cat /etc/sudoers 2>/dev/null | grep -E 'NOPASSWD|%sudo|^root|use_pty|env_reset'"
sh_ "getent passwd 1000; echo '--- non-system users ---'; awk -F: '\$3>=1000 && \$3<65536 {print \$1, \$3, \$4, \$7}' /etc/passwd | sort"
sh_ "id nobody 2>&1; sudo -n -u nobody id 2>&1"

# ================================================================ 05 tools
cur 05_tools.txt
TOOLS="python3 python pip pip3 pipx conda mamba micromamba uv node npm npx yarn pnpm bun deno
git git-lfs curl wget rsync scp sftp ssh ffmpeg ffprobe imagemagick convert
make cmake ninja gcc g++ cc clang clang++ ld gdb lldb pkg-config
jq yq rg grep sed awk gawk mawk sort find tar gzip bzip2 xz zstd zip unzip 7z
htop top vmstat iostat sar strace ltrace perf lsof ps pgrep pkill tmux screen
sqlite3 psql mysql redis-cli duckdb mongosh
docker podman nerdctl runc crun bwrap kubectl helm terraform
aws gcloud az vault
openssl ping traceroute dig nslookup host nc netcat ncat ss ip iptables nft tcpdump tshark
time bc pv parallel xargs watch crontab systemctl findmnt lsblk blkid
apt apt-get dpkg dpkg-query gcc-ar ar objdump readelf nm strings file"
printf '%s\n' $TOOLS | sort -u > "$TMPD/tools.list"
echo "# format: TOOL | PATH | version-first-line (or ABSENT)" >> "$CUR"
echo "# raw command executed per line: \$ <tool> --version" >> "$CUR"
while read -r t; do
  p=$(command -v "$t" 2>/dev/null || true)
  # command -v also matches shell keywords/builtins (e.g. `time`); require a real executable path
  case "$p" in /*) [ -x "$p" ] || p="" ;; *) p="" ;; esac
  if [ -n "$p" ]; then
    v=$("$t" --version 2>&1 | head -1 | tr -d '\r' | cut -c1-110)
    printf '%-16s | %-26s | %s\n' "$t" "$p" "${v:-'(no --version output)'}" >> "$CUR"
  else
    printf '%-16s | %-26s | %s\n' "$t" "ABSENT" "-" >> "$CUR"
  fi
done < "$TMPD/tools.list"

# ================================================================ 06 pkg & compile
cur 06_pkg_and_compile.txt
sh_ "pip --version; echo '--- config ---'; pip config list 2>&1; echo '--- index/externally-managed ---'; ls /usr/local/lib/python3*/EXTERNALLY-MANAGED /usr/lib/python3*/EXTERNALLY-MANAGED 2>&1 | head -2"
sh_ "python3 -c \"import sys,sysconfig;print('exe',sys.executable);print('ver',sys.version.split()[0]);print('prefix',sys.prefix);print('base',sys.base_prefix);print('purelib',sysconfig.get_path('purelib'));print('user_site',sysconfig.get_path('purelib','posix_user'));print('CC',sysconfig.get_config_var('CC'));print('CFLAGS',sysconfig.get_config_var('CFLAGS'))\""
sh_ "python3 -c \"import importlib.util as u;print('\n'.join(f'{m:12} ' + ('PRESENT' if u.find_spec(m) else 'ABSENT') for m in ['numpy','pandas','scipy','sklearn','matplotlib','requests','httpx','aiohttp','psutil','yaml','pyarrow','polars','duckdb','torch','pytest','Cython','wheel','sqlite3','venv','ctypes']))\""
sh_ "python3 -m pip list 2>/dev/null | tail -n +3 | wc -l | xargs echo 'pip installed distribution count:'"
sh_ "python3 -m pip list 2>/dev/null | tail -n +3 | awk '{print \$1\"==\"\$2}' | sort > $TMPD/pkgs.txt && echo 'package list written; first 15:' && head -15 $TMPD/pkgs.txt"
cp "$TMPD/pkgs.txt" "$OUTDIR/06b_pip_freeze_sorted.txt" 2>/dev/null && echo "# 06b_pip_freeze_sorted.txt = sorted name==version list for diffing" >> "$CUR"
sh_ "cat /etc/os-release | grep ^ID=; ls /etc/apt/sources.list.d/ 2>&1; grep -hE '^(URIs|Suites|Types|deb )' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null | head -10"
sh_ "sudo -n apt-get update -qq 2>&1 | tail -3; echo \"apt-get update exit=\$?\""
PKG=$( (command -v rg >/dev/null && echo "none-check-rg-present") || echo ripgrep )
sh_ "for p in \$([ -x /usr/bin/rg ] && echo 'skip') ; do :; done; if have_test=\$(command -v rg || true); then echo 'ripgrep already present, testing zstd instead'; PKG=zstd; else PKG=ripgrep; fi; t0=\$(date +%s%N); sudo -n apt-get install -y -qq \$PKG >/dev/null 2>&1; rc=\$?; t1=\$(date +%s%N); echo \"apt-get install \$PKG: exit=\$rc in \$(( (t1-t0)/1000000 )) ms\"; command -v \$PKG || echo '  (binary not on PATH)'"
sh_ "echo '--- compile chain ---'; gcc --version | head -1; ld --version | head -1; python3 -c \"import sysconfig,os;h=sysconfig.get_paths()['include'];print('headers dir',h,'exists',os.path.isdir(h));print('Python.h',os.path.exists(os.path.join(h,'Python.h')))\""
# real C-extension build test
D="$TMPD/cext"; mkdir -p "$D"
cat > "$D/probe_ext.c" <<'CEOF'
#include <Python.h>
static PyObject *probe(PyObject *self, PyObject *args) {
    unsigned long n = 100000, i, t = 0;
    if (!PyArg_ParseTuple(args, "k", &n)) return NULL;
    for (i = 0; i < n; i++) t += i * i;
    return PyLong_FromUnsignedLong(t);
}
static PyMethodDef M[] = {{"probe", probe, METH_VARARGS, ""}, {NULL, NULL, 0, NULL}};
static struct PyModuleDef mod = {PyModuleDef_HEAD_INIT, "probe_ext", NULL, -1, M};
PyMODINIT_FUNC PyInit_probe_ext(void) { return PyModule_Create(&mod); }
CEOF
cat > "$D/build.sh" <<'BEOF'
set -e
INC=$(python3 -c "import sysconfig;print(sysconfig.get_paths()['include'])")
EXT=$(python3 -c "import sysconfig;print(sysconfig.get_config_var('EXT_SUFFIX'))")
CFLAGS=$(python3 -c "import sysconfig;print(sysconfig.get_config_var('CFLAGS'))")
cd "$(dirname "$0")"
# shellcheck disable=SC2086
gcc -shared -fPIC -O2 $CFLAGS -I"$INC" probe_ext.c -o probe_ext$EXT
python3 -c "import sys;sys.path.insert(0,'$(pwd)');import probe_ext;print('  compiled module result:',probe_ext.probe(1000000))"
BEOF
printf '$ bash %s\n' "$D/build.sh" >> "$CUR"
t0=$(date +%s%N); bash "$D/build.sh" >> "$CUR" 2>&1 || printf '  [compile FAIL exit=%s]\n' "$?" >> "$CUR"
t1=$(date +%s%N); printf '  gcc C-extension build+import: %s ms\n\n' "$(( (t1-t0)/1000000 ))" >> "$CUR"
sh_ "node --version; npm --version 2>&1; npm config get registry 2>&1; python3 -c \"print('venv module:', __import__('importlib.util',fromlist=['x']).find_spec('venv') is not None)\""
sh_ "t0=\$(date +%s%N); python3 -m venv $TMPD/venv 2>&1 | tail -2; t1=\$(date +%s%N); echo \"  python3 -m venv: \$(( (t1-t0)/1000000 )) ms\"; $TMPD/venv/bin/python -c 'import sys;print(\"  venv works:\",sys.prefix!=sys.base_prefix)' 2>&1"

# ================================================================ 07 filesystem
cur 07_filesystem.txt
sh_ "pwd; echo HOME=\$HOME; echo; df -hT . /tmp /var/tmp /dev/shm 2>&1; echo '--- inodes ---'; df -i . /tmp /var/tmp /dev/shm 2>&1"
sh_ "findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS 2>/dev/null | sort | head -30 || mount | sort | head -30"
sh_ "stat -f -c 'fstype=%T namemax=%l' ."
for d in "$PWD" /tmp /var/tmp /dev/shm /run /opt /usr/local /srv /root /mnt /media /etc; do
  f="$d/.probe_rw_$$"
  {
  printf '$ write/read/delete test in %s\n' "$d"
    if echo "probe-$(date +%s%N)" > "$f" 2>/dev/null; then
      got=$(cat "$f" 2>/dev/null)
      if rm -f "$f" 2>/dev/null; then r="write+read+delete OK"; else r="write OK, DELETE FAILED"; fi
      case "$got" in probe-*) v="readback OK";; *) v="READ MISMATCH";; esac
      fs=$(stat -f -c %T "$d" 2>/dev/null)
      ex="no"; printf '#!/bin/sh\necho ok\n' > "$d/.probe_x_$$" 2>/dev/null && chmod +x "$d/.probe_x_$$" 2>/dev/null && [ "$("$d/.probe_x_$$" 2>/dev/null)" = ok ] && ex="yes"; rm -f "$d/.probe_x_$$"
      printf '  %-22s fs=%-10s %s  %s  exec=%s\n' "$d" "$fs" "$v" "$r" "$ex"
    else
      mkdir -p "$d" 2>/dev/null
      if echo "probe-1" > "$f" 2>/dev/null; then printf '  %-22s writable only after mkdir -p\n' "$d"; rm -f "$f"; else printf '  %-22s NOT writable by %s (root can: %s)\n' "$d" "$(id -un)" "$(sudo -n test -w "$d" 2>/dev/null && echo yes || echo unknown)"; fi
    fi
  } >> "$CUR" 2>&1
done
echo >> "$CUR"

PYF="$TMPD/fs_features.py"
cat > "$PYF" <<'PEOF'
import os, sys, mmap, fcntl, errno, shutil, struct
base = sys.argv[1]
os.makedirs(base, exist_ok=True)
def chk(label, fn):
    try:
        r = fn()
        print(f"  {label:34} OK   {r if r is not None else ''}")
    except Exception as e:
        print(f"  {label:34} FAIL {type(e).__name__} {getattr(e,'errno','')} {getattr(e,'strerror','') or e}")
p = os.path.join(base, "a.bin")
def _falloc():
    fd = os.open(p, os.O_CREAT | os.O_RDWR, 0o644); os.posix_fallocate(fd, 0, 1 << 20)
    sz = os.fstat(fd).st_size; os.close(fd); os.unlink(p); return f"{sz>>20} MiB sparse"
chk("posix_fallocate (sparse)", _falloc)
h1 = os.path.join(base, "h1")
open(h1, "w").write("x")
chk("hardlink (os.link)", lambda: (os.link(h1, h1 + ".2"), os.path.getsize(h1 + ".2"))[1])
chk("symlink + readlink", lambda: (os.symlink(h1, os.path.join(base, "s1")), os.readlink(os.path.join(base, "s1")))[1])
def _xa():
    os.setxattr(h1, b"user.probe", b"v1"); v = os.getxattr(h1, b"user.probe"); os.removexattr(h1, b"user.probe"); return v
chk("xattr user.* (set/get/remove)", _xa)
def _flock():
    f = open(os.path.join(base, "lock"), "w"); fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    r = "exclusive acquired"; fcntl.flock(f, fcntl.LOCK_UN); f.close(); return r
chk("flock advisory lock", _flock)
def _mmap():
    fd = os.open(p, os.O_CREAT | os.O_RDWR, 0o644); os.write(fd, b"AB" * 2048)
    m = mmap.mmap(fd, 4096, access=mmap.ACCESS_READ); r = m[0:2]; m.close(); os.close(fd); os.unlink(p); return r
chk("mmap ACCESS_READ", _mmap)
def _odirect():
    fd = os.open(p, os.O_CREAT | os.O_WRONLY | os.O_DIRECT, 0o644); os.write(fd, b"z" * 4096); os.close(fd); os.unlink(p); return "4KiB aligned write"
chk("O_DIRECT open+write", _odirect)
chk("os.statvfs f_bavail", lambda: f"{os.statvfs(base).f_bavail * os.statvfs(base).f_frsize >> 30} GiB")
for name, attr in (("NAME_MAX", "PC_NAME_MAX"), ("PATH_MAX", "PC_PATH_MAX")):
    try: print(f"  {name:34} {os.pathconf(base, attr)}")
    except Exception as e: print(f"  {name:34} FAIL {e}")
def _unicode():
    n = os.path.join(base, "é中文_ünïçødé.dat"); open(n, "w").write("ok"); r = open(n).read(); os.unlink(n); return r
chk("unicode filename create/read", _unicode)
def _namemax():
    ok = None
    for L in (255, 256):
        f = os.path.join(base, "n" * L)
        try:
            open(f, "w").write("x"); os.unlink(f); ok = L
        except OSError: pass
    return f"max accepted = {ok}"
chk("filename length boundary", _namemax)
def _inotify():
    import ctypes, threading, time
    libc = ctypes.CDLL("libc.so.6", use_errno=True)
    fd = libc.inotify_init1(0)
    if fd < 0: raise OSError(ctypes.get_errno(), "inotify_init1")
    wd = libc.inotify_add_watch(fd, base.encode(), 0x00000002 | 0x00000010 | 0x00000040)
    if wd < 0: raise OSError(ctypes.get_errno(), "inotify_add_watch")
    got = {}
    def w():
        got["n"] = len(os.read(fd, 4096))
    t = threading.Thread(target=w, daemon=True); t.start()
    time.sleep(0.25); open(os.path.join(base, "inot_probe"), "w").write("x"); t.join(3)
    os.close(fd)
    return f"event bytes={got.get('n')}"
chk("inotify create event", _inotify)
def _epoll():
    import select, socket
    e = select.epoll(); s = socket.socket(); e.register(s, 0); r = type(__import__('selectors').DefaultSelector()).__name__
    e.close(); s.close(); return r
chk("epoll / selectors backend", _epoll)
def _uring():
    import ctypes
    libc = ctypes.CDLL("libc.so.6", use_errno=True); libc.syscall.restype = ctypes.c_long
    class P(ctypes.Structure): _fields_ = [("raw", ctypes.c_uint32 * 40)]
    prm = P(); r = libc.syscall(425, 8, ctypes.byref(prm))
    if r >= 0:
        os.close(r); return "io_uring_setup returned fd (allowed)"
    raise OSError(ctypes.get_errno(), f"errno {ctypes.get_errno()} ({os.strerror(ctypes.get_errno())})")
chk("io_uring_setup", _uring)
shutil.rmtree(base, ignore_errors=True)
PEOF
printf '$ python3 fs_features.py %s\n' "$TMPD/fs" >> "$CUR"
python3 "$PYF" "$TMPD/fs" >> "$CUR" 2>&1 || printf '  [python exit=%s]\n' "$?" >> "$CUR"

# ================================================================ 08 persistence
cur 08_persistence.txt
sh_ "mkdir -p '$OUTDIR/.persist'; printf '%s %s\n' '$RUN_ID' \$(date -u +%s) > '$OUTDIR/.persist/writer.txt'; echo '  marker written (diff against your own run to compare):'; cat '$OUTDIR/.persist/writer.txt'"
sh_ "printf '%s %s\n' \"$RUN_ID\" \$(date -u +%s) > /tmp/probe_persist_$RUN_ID.tmp && echo '  /tmp marker written: /tmp/probe_persist_$RUN_ID.tmp'"
sh_ "printf '%s %s\n' \"$RUN_ID\" \$(date -u +%s) > /var/tmp/probe_persist_$RUN_ID.tmp && echo '  /var/tmp marker written: /var/tmp/probe_persist_$RUN_ID.tmp'"
sh_ "echo 'tmpfiles ages (governs /tmp and /var/tmp sweeping):'; grep -hE '^\s*[qQvdD]\s+/(tmp|var/tmp)(\s|$)' /usr/lib/tmpfiles.d/*.conf /etc/tmpfiles.d/*.conf 2>/dev/null | sort -u"
sh_ "systemctl list-timers --all --no-legend 2>&1 | awk '{print \$1,\$2,\$NF}' | sort; echo '---'; systemctl status systemd-tmpfiles-clean.timer --no-pager 2>&1 | grep -E 'Active|Loaded' | sed 's/^ *//'"
sh_ "echo 'workspace snapshot exclusions are a policy of the harness, not the guest fs; verifiable names:'; echo '  .venv node_modules dist build out target coverage __pycache__ .cache .next .pytest_cache .ruff_cache .local .output'"
sh_ "df -h \$PWD | tail -1; df -i \$PWD | tail -1"
sh_ "echo 'inode/dir durability probes:'; sync; cat /proc/sys/vm/dirty_ratio /proc/sys/vm/dirty_expire_centisecs 2>&1 | tr '\n' ' '; echo"

# ================================================================ 09 network matrix
cur 09_net_matrix.txt
sh_ "cat /etc/resolv.conf; echo '--- nsswitch ---'; grep hosts /etc/nsswitch.conf; echo '--- hosts file ---'; cat /etc/hosts"
sh_ "ip addr 2>&1 | sed 's/  */ /g'; echo '--- routes ---'; ip route 2>&1; echo '--- neigh ---'; ip neigh 2>&1"
sh_ "ip link show 2>&1 | grep -E '^[0-9]+:|mtu' ; cat /sys/class/net/*/mtu 2>/dev/null | tr '\n' ' '; echo; cat /sys/class/net/eth0/operstate 2>/dev/null"
sh_ "cat /proc/net/dev"
have netns_test || :
sh_ "sudo -n iptables -S 2>&1 | head -5; echo '--- nft ---'; sudo -n nft list ruleset 2>&1 | head -10"
sh_ "echo '--- proxy env ---'; env | grep -iE 'proxy|no_proxy|ssl_cert|requests_ca|node_extra' || echo '(none set)'; echo '--- ca bundle ---'; ls /etc/ssl/certs/*.pem 2>/dev/null | wc -l | xargs echo 'certs in /etc/ssl/certs:'; grep -c 'BEGIN CERTIFICATE' /etc/ssl/certs/ca-certificates.crt 2>/dev/null"
printf '$ python3 port/protocol matrix\n' >> "$CUR"
cat > "$TMPD/matrix.py" <<'MEOF'
import socket, ssl, subprocess, sys, time
TIMEOUT = 6
print("  format: HOST:PORT  VERDICT  connect_ms  detail")
print("  NOTE: a sandboxed egress proxy can answer the TCP handshake for EVERY destination/port,")
print("        so 'OPEN' below does NOT imply a reachable service. The detail column (first bytes,")
print("        or the post-connect error) is the only real signal.")
targets = {
    "github.com": [22, 80, 443, 3000, 5432, 8080, 9999],
    "example.com": [21, 22, 25, 53, 80, 110, 143, 443, 445, 465, 587, 993, 995, 1433, 1521, 3306, 3389, 5432, 5672, 5984, 6379, 7001, 8000, 8080, 8443, 9092, 9200, 11211, 27017],
    "1.1.1.1": [53, 80, 123, 443, 853, 2053, 54321],
    "8.8.8.8": [53, 443, 853],
    "speed.cloudflare.com": [80, 443, 8080],
}
for host, ports in targets.items():
    for p in sorted(set(ports)):
        t0 = time.perf_counter()
        try:
            s = socket.create_connection((host, p), timeout=TIMEOUT)
            ms = (time.perf_counter() - t0) * 1000
            banner = b""
            try:
                s.settimeout(3); banner = s.recv(48)
            except Exception as e:
                banner = f"<no bytes: {type(e).__name__}>".encode()
            s.close()
            print(f"  {host+':'+str(p):31} {'CONNECTED':9} {ms:8.2f}  {banner[:46]!r}")
        except socket.timeout:
            print(f"  {host+':'+str(p):31} {'TIMEOUT':9} {(time.perf_counter()-t0)*1000:8.1f}  no SYN/ACK within {TIMEOUT}s")
        except ConnectionRefusedError:
            print(f"  {host+':'+str(p):31} {'REFUSED':9} {(time.perf_counter()-t0)*1000:8.2f}")
        except OSError as e:
            print(f"  {host+':'+str(p):31} {'ERROR':9} {(time.perf_counter()-t0)*1000:8.2f}  {type(e).__name__} errno={e.errno} {e.strerror}")
print()
print("  --- ICMP ---")
print(f"  ping_group_range: {open('/proc/sys/net/ipv4/ping_group_range').read().strip()}")
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP); print("  SOCK_RAW ICMP:      ALLOWED"); s.close()
except OSError as e:
    print(f"  SOCK_RAW ICMP:      DENIED (errno {e.errno} {e.strerror})")
r = subprocess.run(["ping", "-c", "2", "-W", "2", "1.1.1.1"], capture_output=True, text=True)
print(f"  `ping 1.1.1.1`: exit={r.returncode} {r.stderr.strip().splitlines()[-1] if r.stderr.strip() else r.stdout.strip().splitlines()[-1:]}")
print()
print("  --- IPv6 ---")
try:
    ai = socket.getaddrinfo("google.com", None, socket.AF_INET6, socket.SOCK_STREAM)
    print(f"  AAAA for google.com:  {ai[0][4][0] if ai else 'none'}")
except Exception as e:
    print(f"  AAAA for google.com:  {type(e).__name__}")
try:
    s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM); s.settimeout(4)
    s.connect(("2606:4700:4700::1111", 53)); print("  IPv6 TCP connect:     ALLOWED"); s.close()
except OSError as e:
    print(f"  IPv6 TCP connect:     BLOCKED (errno {e.errno} {e.strerror})")
print()
print("  --- UDP ---")
def udp(server, port, payload, name):
    t0 = time.perf_counter()
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(5)
        s.sendto(payload, (server, port)); d, _ = s.recvfrom(512)
        print(f"  UDP {name:26} -> {server}:{port:<5} OK {len(d)} bytes in {(time.perf_counter()-t0)*1000:7.2f} ms")
    except Exception as e:
        print(f"  UDP {name:26} -> {server}:{port:<5} {type(e).__name__} after {(time.perf_counter()-t0)*1000:7.1f} ms")
dns = bytes.fromhex("123401000001000000000000") + b"\x07example\x03com\x00\x00\x01\x00\x01"
for srv in ["8.8.8.8", "1.1.1.1", "208.67.222.222", "169.254.0.22"]:
    udp(srv, 53, dns, "DNS query example.com")
import struct
ntp = struct.pack("!B3B11I", 0x1b, 0, 0, 0, *([0] * 11))
udp("162.159.200.1", 123, ntp, "NTP mode3")
udp("1.1.1.1", 443, b"\xc0\x00" + b"\x00" * 12, "QUIC Initial-ish")
print()
print("  --- TLS leaf cert issuer (MITM check) ---")
ctx = ssl.create_default_context()
for h in ["google.com", "github.com", "pypi.org", "huggingface.co", "registry.npmjs.org"]:
    try:
        with socket.create_connection((h, 443), timeout=8) as s0:
            with ctx.wrap_socket(s0, server_hostname=h) as s:
                d = s.getpeercert()
                def flat(t):
                    # issuer/subject nest as ((('organizationName','X'),),) or ((k,v),...) - flatten both
                    for e in t:
                        if isinstance(e, tuple) and e and isinstance(e[0], tuple):
                            yield from flat(e)
                        elif isinstance(e, tuple) and len(e) == 2:
                            yield e[0], e[1]
                iss = dict(flat(d.get("issuer", ())))
                sub = dict(flat(d.get("subject", ())))
                print(f"  {h:26} {s.version():9} subject={sub.get('commonName','?')[:20]:22} issuer_org={iss.get('organizationName','?')[:30]:32} issuer_cn={iss.get('commonName','?')[:34]:36} valid_to={d['notAfter']}")
    except Exception as e:
        print(f"  {h:26} FAILED {type(e).__name__} {str(e)[:60]}")
MEOF
python3 "$TMPD/matrix.py" >> "$CUR" 2>&1 || printf '  [matrix exit=%s]\n' "$?" >> "$CUR"

# ================================================================ 10 DNS timing
cur 10_net_dns.txt
cat > "$TMPD/dns.py" <<'DEOF'
import socket, time, statistics, sys
REPS = int(sys.argv[1])
hosts = ["google.com", "www.google.com", "github.com", "pypi.org", "files.pythonhosted.org",
         "huggingface.co", "cdn.huggingface.co", "registry.npmjs.org", "objects.githubusercontent.com",
         "raw.githubusercontent.com", "cdn.jsdelivr.net", "security.debian.org", "deb.debian.org",
         "archive.ubuntu.com", "crates.io", "gcr.io", "quay.io", "docker.io", "kaggle.com",
         "www.kaggle.com", "example.com", "nonexistent-host-zzz-12345.invalid"]
print(f"  {'host':38} {'status':10} {'n':>2} {'min ms':>8} {'med ms':>8} {'p95 ms':>8} {'max ms':>8}")
for h in hosts:
    ts = []; err = "OK"
    for i in range(REPS):
        t0 = time.perf_counter()
        try:
            socket.getaddrinfo(h, None, socket.AF_INET, socket.SOCK_STREAM)
        except Exception as e:
            err = type(e).__name__
        ts.append((time.perf_counter() - t0) * 1000)
    s = sorted(ts)
    print(f"  {h:38} {err:10} {len(ts):>2} {min(ts):8.2f} {statistics.median(ts):8.2f} {s[int(len(s)*0.95)]:8.2f} {max(ts):8.2f}")
print("\n  cold-cache behaviour: the tail values are uncached lookups through the egress resolver;")
print("  medians ~<2 ms mean answers are served from a local cache, NOT from a remote recursive resolver.")
DEOF
printf '$ python3 dns.py %s\n' "$REPS" >> "$CUR"
python3 "$TMPD/dns.py" "$REPS" >> "$CUR" 2>&1

# ================================================================ 11 latency
cur 11_net_latency.txt
cat > "$TMPD/lat.py" <<'LEOF'
import socket, ssl, time, statistics, sys
REPS = int(sys.argv[1])
ENDPOINTS = {"google.com:80": ("google.com", 80), "1.1.1.1:80": ("1.1.1.1", 80),
             "8.8.8.8:53": ("8.8.8.8", 53), "github.com:443": ("github.com", 443),
             "pypi.org:443": ("pypi.org", 443), "files.pythonhosted.org:443": ("files.pythonhosted.org", 443),
             "huggingface.co:443": ("huggingface.co", 443), "registry.npmjs.org:443": ("registry.npmjs.org", 443),
             "cdn.jsdelivr.net:443": ("cdn.jsdelivr.net", 443), "deb.debian.org:443": ("deb.debian.org", 443),
             "objects.githubusercontent.com:443": ("objects.githubusercontent.com", 443)}
print(f"  TCP connect only (median of {REPS} fresh sockets; no TLS)")
print(f"  {'endpoint':32} {'res':>10} {'min ms':>7} {'med ms':>7} {'max ms':>7}")
for name, (h, p) in ENDPOINTS.items():
    ts = []
    for _ in range(REPS):
        t0 = time.perf_counter()
        try:
            socket.create_connection((h, p), timeout=8).close(); ts.append((time.perf_counter() - t0) * 1000)
        except Exception as e:
            print(f"  {name:32} {type(e).__name__:>10}"); ts = None; break
    if ts:
        print(f"  {name:32} {'OK':>10} {min(ts):7.2f} {statistics.median(ts):7.2f} {max(ts):7.2f}")
ctx = ssl.create_default_context()
print(f"\n  TLS: tcp / handshake / total (median of {REPS}); negotiated version + cipher")
print(f"  {'host':30} {'ver':9} {'tcp ms':>7} {'tls ms':>7} {'tot ms':>7}  cipher")
for h in ["google.com", "github.com", "pypi.org", "files.pythonhosted.org", "huggingface.co", "registry.npmjs.org", "cdn.jsdelivr.net", "deb.debian.org"]:
    rows = []
    for _ in range(REPS):
        try:
            t0 = time.perf_counter()
            s = socket.create_connection((h, 443), timeout=8); t1 = time.perf_counter()
            w = ctx.wrap_socket(s, server_hostname=h); t2 = time.perf_counter()
            rows.append(((t1 - t0) * 1000, (t2 - t1) * 1000, (t2 - t0) * 1000, w.version(), w.cipher()[0])); w.close()
        except Exception as e:
            print(f"  {h:30} FAILED {type(e).__name__} {str(e)[:50]}"); rows = []; break
    if rows:
        print(f"  {h:30} {rows[0][3]:9} {statistics.median([r[0] for r in rows]):7.2f} {statistics.median([r[1] for r in rows]):7.2f} {statistics.median([r[2] for r in rows]):7.2f}  {rows[0][4]}")
print("\n  Interpretation aid: if tcp-connect medians to geographically distant CDNs are nearly identical,")
print("  the handshake is being terminated by a nearby proxy rather than the remote host.")
LEOF
printf '$ python3 lat.py %s\n' "$REPS" >> "$CUR"
python3 "$TMPD/lat.py" "$REPS" >> "$CUR" 2>&1

# ================================================================ 12 throughput
cur 12_net_throughput.txt
cat > "$TMPD/tp.py" <<'TEOF'
import urllib.request, urllib.parse, time, statistics, sys, socket, ssl, concurrent.futures as cf
REPS = int(sys.argv[1])
UA = {"User-Agent": "probe.sh/1.0"}
def get(url):
    t0 = time.perf_counter()
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        b = len(r.read())
    return b, time.perf_counter() - t0
print(f"  single-stream download ({REPS} reps each; median Mbps reported)")
print(f"  {'source':34} {'med Mbps':>9} {'min':>8} {'max':>8} {'bytes':>11}")
for label, url in [("cloudflare __down 25MB", "https://speed.cloudflare.com/__down?bytes=25000000"),
                  ("cachefly 100MB", "https://cachefly.cachefly.net/100mb.test"),
                  ("cachefly 10MB", "https://cachefly.cachefly.net/10mb.bin"),
                  ("github raw (small file)", "https://raw.githubusercontent.com/git/git/master/README.md")]:
    try:
        res = [get(url) for _ in range(REPS)]
        mb = [b * 8 / el / 1e6 for b, el in res]
        print(f"  {label:34} {statistics.median(mb):9.1f} {min(mb):8.1f} {max(mb):8.1f} {int(statistics.median([r[0] for r in res])):>11}")
    except Exception as e:
        print(f"  {label:34} {'FAILED':>9}  {type(e).__name__} {str(e)[:44]}")
print("\n  sustained (6 consecutive 100MB pulls; look for decay => a cap)")
sp = []
for i in range(6):
    try:
        b, el = get("https://cachefly.cachefly.net/100mb.test"); sp.append(b / el / 1e6)
        print(f"    pull {i+1}: {b/el/1e6:7.1f} MB/s")
    except Exception as e:
        print(f"    pull {i+1}: FAIL {type(e).__name__}")
if sp: print(f"    -> median {statistics.median(sp):.1f} MB/s, first-vs-last delta {sp[-1]-sp[0]:+.1f} MB/s")
print("\n  concurrency scaling (10MB per stream, threads)")
def one(_):
    return get("https://cachefly.cachefly.net/10mb.bin")
print(f"  {'streams':>8} {'agg MB/s':>9} {'agg Mbps':>9} {'per-stream MB/s':>16}")
for n in [1, 2, 4, 8, 16]:
    try:
        t0 = time.perf_counter()
        with cf.ThreadPoolExecutor(max_workers=n) as ex:
            rs = list(ex.map(one, range(n)))
        el = time.perf_counter() - t0
        tot = sum(b for b, _ in rs)
        per = statistics.median([b / e / 1e6 for b, e in rs])
        print(f"  {n:>8} {tot/el/1e6:9.1f} {tot*8/el/1e6:9.1f} {per:16.1f}")
    except Exception as e:
        print(f"  {n:>8} FAILED {type(e).__name__} {str(e)[:40]}")
print("\n  upload (POST to cloudflare __up)")
def up(size):
    body = b"x" * size
    ctx = ssl.create_default_context()
    t0 = time.perf_counter()
    s = socket.create_connection(("speed.cloudflare.com", 443), timeout=60)
    w = ctx.wrap_socket(s, server_hostname="speed.cloudflare.com")
    w.sendall(f"POST /__up HTTP/1.1\r\nHost: speed.cloudflare.com\r\nContent-Type: application/octet-stream\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode() + body)
    r = w.recv(64); w.close()
    return size / (time.perf_counter() - t0) / 1e6, r[:12]
print(f"  {'payload':>12} {'MB/s':>8}  first bytes of response")
for sz in [1_000_000, 10_000_000, 50_000_000]:
    try:
        mbps, r = up(sz); print(f"  {sz:>12} {mbps:8.1f}  {r!r}")
    except Exception as e:
        print(f"  {sz:>12} FAILED {type(e).__name__}")
print("\n  download/upload asymmetry is a real link property; record both.")
TEOF
printf '$ python3 tp.py %s\n' "$REPS" >> "$CUR"
python3 "$TMPD/tp.py" "$REPS" >> "$CUR" 2>&1
sh_ "curl -sS -o /dev/null -m 60 -w '  curl cf25MB: http=%{http_code} dns=%{time_namelookup}s tcp=%{time_connect}s tls=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s size=%{size_download} speed=%{speed_download}B/s ver=%{http_version} remote_ip=%{remote_ip}\n' 'https://speed.cloudflare.com/__down?bytes=25000000'"
sh_ "curl -sS --http3 -o /dev/null -m 15 -w '  curl --http3 cloudflare: http=%{http_code} ver=%{http_version} total=%{time_total}s  (QUIC/UDP-443 probe)\n' https://cloudflare.com/ 2>&1 | tail -2"
sh_ "curl -sS -o /dev/null -m 15 -w '  curl http  : http=%{http_code} ver=%{http_version} total=%{time_total}s\n' https://example.com/ 2>&1; curl -sS -o /dev/null -m 15 -w '  curl https://example.com:3000 (nonstandard port): http=%{http_code} connect=%{time_connect}s\n' https://example.com:3000 2>&1 | tail -2"

# ================================================================ 13 egress proof
cur 13_net_egress_proof.txt
cat > "$TMPD/proof.py" <<'PEOF'
import socket, time
print("  These addresses must NEVER answer a TCP SYN on the public internet.")
print("  A successful connect() therefore proves a local transparent proxy is terminating handshakes.\n")
tests = [("203.0.113.45", 9999, "RFC5737 TEST-NET-3 (documentation, unroutable)"),
         ("240.0.0.1", 12345, "RFC1112 reserved Class-E (must not be routable)"),
         ("192.0.2.1", 80, "RFC5737 TEST-NET-1"),
         ("10.255.255.1", 54321, "RFC1918 private, no local route"),
         ("198.51.100.0", 443, "RFC5737 TEST-NET-2"),
         ("1.1.1.1", 54321, "Cloudflare on an absurd port"),
         ("github.com", 5432, "GitHub on PostgreSQL port (no such service)")]
print(f"  {'target':22} {'verdict':>14} {'ms':>8}  label")
for h, p, label in tests:
    t0 = time.perf_counter()
    try:
        s = socket.create_connection((h, p), timeout=8)
        ms = (time.perf_counter() - t0) * 1000
        try:
            s.settimeout(3); d = s.recv(16); post = f"recv={d[:16]!r}" if d else "recv=EOF"
        except Exception as e:
            post = f"recv={type(e).__name__}"
        s.close()
        print(f"  {h+':'+str(p):22} {'CONNECTED':>14} {ms:8.2f}  {label}")
        print(f"  {'':22} {'':>14} {'':>8}  then {post}")
    except Exception as e:
        print(f"  {h+':'+str(p):22} {type(e).__name__.upper():>14} {(time.perf_counter()-t0)*1000:8.1f}  {label}")
print("\n  Verdict rule: if any unroutable/reserved target CONNECTS, then")
print("    (a) port scanning from inside this sandbox is meaningless, and")
print("    (b) application code must not treat 'socket connected' as reachability.")
PEOF
printf '$ python3 proof.py\n' >> "$CUR"
python3 "$TMPD/proof.py" >> "$CUR" 2>&1

# ================================================================ 14 CPU bench
cur 14_bench_cpu.txt
cat > "$TMPD/cpu.py" <<'CEOF'
import time, statistics, sys, os, json, gzip
REPS = max(1, int(sys.argv[1]))
def timed(fn, reps=None):
    reps = reps or REPS; ts = []
    for _ in range(reps):
        t0 = time.perf_counter(); r = fn(); ts.append(time.perf_counter() - t0)
    return min(ts), statistics.median(ts), r
rows = []
def add(label, fn, note=""):
    a, b, r = timed(fn)
    rows.append((label, a, b, note if not callable(note) else note(r)))
add("sum(range(10**7))", lambda: sum(range(10 ** 7)), lambda r: f"= {r:,}")
add("sum(i*i for i in range(10**7))", lambda: sum(i * i for i in range(10 ** 7)))
add("sum(map(abs, range(-5e6,5e6)))", lambda: sum(map(abs, range(-5_000_000, 5_000_000))))
def _sieve(n=5_000_000):
    import math
    s = bytearray(b"\x01") * n; s[0] = s[1] = 0
    for i in range(2, int(math.isqrt(n)) + 1):
        if s[i]: s[i * i::i] = bytearray(len(s[i * i::i]))
    return sum(s)
add("sieve primes < 5e6 (bytearray slice)", _sieve, "pure-python fast path")
def _fib(n=29):
    return n if n < 2 else _fib(n - 1) + _fib(n - 2)
add("recursive fib(29)", lambda: _fib(29))
_s = json.dumps({"k%d" % i: [i, i * 2, "s" * 20] for i in range(20000)})
add(f"json.loads {len(_s)/1e6:.1f}MB", lambda: json.loads(_s))
add(f"gzip.compress {len(_s)/1e6:.1f}MB lvl9", lambda: gzip.compress(_s.encode(), 9))
import hashlib
_b = os.urandom(100 * 1024 * 1024)
add("sha256 100 MiB", lambda: hashlib.sha256(_b).hexdigest(), lambda r: f"digest[:12]={r[:12]}")
print(f"  {'benchmark':42} {'min s':>8} {'med s':>8}  notes")
for l, a, b, n in rows:
    print(f"  {l:42} {a:8.3f} {b:8.3f}  {n}")
print("\n  numeric libraries:")
try:
    import numpy as np
    print(f"  numpy {np.__version__}")
    a, b, r = timed(lambda: np.sum(np.arange(10 ** 7))); print(f"  {'np.sum(np.arange(10**7))':42} {a:8.3f} {b:8.3f}  = {r:,}")
    x = np.random.rand(1024 if REPS == 1 else 4096) ** 1
    n = x.shape[0]
    X = x.reshape(n, 1)
    a, b, _ = timed(lambda: np.dot(x, x))
    print(f"  {'dot 1D':42} {a:8.3f} {b:8.3f}")
    if REPS > 1:
        m = np.random.rand(4096, 4096)
        a, b, _ = timed(lambda: m @ m, reps=2); print(f"  {'matmul 4096^2 fp64':42} {a:8.3f} {b:8.3f}  -> {2*4096**3/b/1e9:.1f} GFLOP/s")
        m32 = m.astype(np.float32)
        a, b, _ = timed(lambda: m32 @ m32, reps=2); print(f"  {'matmul 4096^2 fp32':42} {a:8.3f} {b:8.3f}  -> {2*4096**3/b/1e9:.1f} GFLOP/s")
        big = np.random.rand(20_000_000)
        a, b, _ = timed(lambda: big.sum(), reps=2); print(f"  {'sum 20M fp64 (160MB stream)':42} {a:8.3f} {b:8.3f}  -> {20e6*8/b/1e9:.1f} GB/s")
        a, b, _ = timed(lambda: np.sort(big), reps=2); print(f"  {'np.sort 20M fp64':42} {a:8.3f} {b:8.3f}")
except ImportError as e:
    print("  numpy: ABSENT", e)
try:
    import pandas as pd
    df = pd.DataFrame({"a": np.random.rand(2_000_000), "b": np.random.randint(0, 100, 2_000_000)})
    a, b, _ = timed(lambda: df.groupby("b")["a"].mean()); print(f"  {'pandas groupby 2M rows':42} {a:8.3f} {b:8.3f}")
    p = os.path.join(os.environ.get("TMPDIR", "/tmp"), "probe_pd.csv"); df.to_csv(p, index=False)
    a, b, _ = timed(lambda: pd.read_csv(p)); print(f"  {'pandas read_csv '+str(os.path.getsize(p)//10**6)+'MB':42} {a:8.3f} {b:8.3f}"); os.unlink(p)
except Exception as e:
    print("  pandas bench skipped:", type(e).__name__, e)
print("\n  scaling:")
print(f"  os.cpu_count()={os.cpu_count()}  sched_getaffinity={len(os.sched_getaffinity(0))}  gil_enabled={getattr(__import__('sys'),'_is_gil_enabled', lambda: True)()}")
def burn(k):
    t = 0
    for i in range(k): t += i * i
    return t
solo, _, _ = timed(lambda: burn(3_000_000), reps=2)
print(f"  {'1 process (baseline)':42} {solo:8.3f}")
import multiprocessing as mp
for w in [2, 3, 4]:
    t0 = time.perf_counter()
    try:
        with mp.Pool(w) as p: p.map(burn, [3_000_000] * w)
        el = time.perf_counter() - t0
        sp = solo * w / el
        print(f"  {w} processes (same work each)".ljust(44) + f" {el:8.3f}  speedup={sp:5.2f}x  eff={100*sp/w:3.0f}%")
    except Exception as e:
        print(f"  {w} processes: FAIL {type(e).__name__} {e}")
t0 = time.perf_counter()
ths = [__import__('threading').Thread(target=burn, args=(3_000_000,)) for _ in range(2)]
[x.start() for x in ths]; [x.join() for x in ths]
print(f"  {'2 CPU-bound threads (GIL)':42} {time.perf_counter()-t0:8.3f}")
t0 = time.perf_counter()
ths = [__import__('threading').Thread(target=burn, args=(3_000_000,)) for _ in range(8)]
[x.start() for x in ths]; [x.join() for x in ths]
print(f"  {'8 CPU-bound threads (GIL)':42} {time.perf_counter()-t0:8.3f}   <- worse = GIL thrash, use processes")
CEOF
printf '$ python3 cpu.py %s\n' "$REPS" >> "$CUR"
python3 "$TMPD/cpu.py" "$REPS" >> "$CUR" 2>&1

# ================================================================ 15 disk bench
cur 15_bench_disk.txt
cat > "$TMPD/disk.py" <<'DEOF'
import os, time, statistics, sys, shutil, mmap, hashlib
REPS = max(1, int(sys.argv[1])); SZ = (30 if REPS == 1 else 100) * 1024 * 1024
MB = 1024 * 1024
def one(d):
    p = os.path.join(d, "bench.bin"); blk = os.urandom(4 * MB); res = {}
    t0 = time.perf_counter(); fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
    for _ in range(SZ // (4 * MB)): os.write(fd, blk)
    res["write_buffered"] = time.perf_counter() - t0
    t0 = time.perf_counter(); os.fsync(fd); res["fsync_after_write"] = time.perf_counter() - t0
    os.close(fd)
    t0 = time.perf_counter(); fd = os.open(p, os.O_RDONLY)
    while os.read(fd, 4 * MB): pass
    res["read_cached"] = time.perf_counter() - t0; os.close(fd)
    t0 = time.perf_counter(); fd = os.open(p, os.O_RDONLY)
    m = mmap.mmap(fd, 0, access=mmap.ACCESS_READ); h = hashlib.sha256(m).hexdigest(); m.close(); os.close(fd)
    res["mmap_plus_sha256"] = time.perf_counter() - t0
    t0 = time.perf_counter(); os.unlink(p); res["unlink"] = time.perf_counter() - t0
    return res, h[:12]
def direct(d):
    p = os.path.join(d, "odirect.bin"); SZ2 = (20 if REPS == 1 else 60) * MB
    t0 = time.perf_counter(); fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_DIRECT, 0o644)
    b = os.urandom(4 * MB)
    for _ in range(SZ2 // (4 * MB)):
        try: os.write(fd, b)
        except OSError: break
    os.close(fd); w = time.perf_counter() - t0
    r = None
    try:
        import ctypes
        libc = ctypes.CDLL("libc.so.6")
        buf = ctypes.c_char_p(); libc.posix_memalign(ctypes.byref(buf), 4096, ctypes.c_size_t(4 * MB))
        fd = os.open(p, os.O_RDONLY | os.O_DIRECT); off = 0; n = 0
        t1 = time.perf_counter()
        while n < SZ2:
            got = libc.pread(fd, buf, ctypes.c_size_t(4 * MB), off)
            if got <= 0: break
            n += got; off += got
        r = (n, time.perf_counter() - t1); os.close(fd); libc.free(buf)
    except Exception as e:
        r = None
    os.unlink(p)
    return w, r
print(f"  payload per test: {SZ//MB} MiB, reps: {REPS}")
for label, d in [("ext4 $PWD", os.environ.get("PROBE_FS_DIR", os.getcwd())), ("tmpfs /tmp", "/tmp"), ("tmpfs /dev/shm", "/dev/shm")]:
    if not os.access(d, os.W_OK): print(f"\n  ### {label} ({d}): NOT WRITABLE, skipped"); continue
    print(f"\n  ### {label}  ({d})  fs={os.statvfs(d).f_fsid if False else ''} fstype={os.popen('stat -f -c %%T %s 2>/dev/null' % d).read().strip()}")
    acc = {}
    for _ in range(REPS):
        r, h = one(d)
        for k, v in r.items(): acc.setdefault(k, []).append(v)
    for k, vs in acc.items():
        med = statistics.median(vs)
        extra = f"  = {SZ/1e6/med:6.0f} MB/s"
        if k == "fsync_after_write":
            wb = statistics.median(acc["write_buffered"])
            extra = f"  <- durability tax: {med*1000:.1f} ms to make {SZ//MB} MiB crash-safe ({SZ/1e6/med:.0f} MB/s effective)"
        if k in ("unlink",):
            extra = ""
        print(f"    {k:20} med={med*1000:8.1f} ms (min {min(vs)*1000:7.1f} max {max(vs)*1000:7.1f}){extra}")
    try:
        w, r = direct(d)
    except OSError as e:
        print(f"    {'O_DIRECT':20} not supported on this fs ({e.strerror}) - expected on tmpfs")
        w, r = None, None
    if w is not None:
        print(f"    {'O_DIRECT write':20} med={w*1000:8.1f} ms  = {(20 if REPS==1 else 60)*MB/1e6/w:6.0f} MB/s")
    if r: print(f"    {'O_DIRECT read':20} {r[0]/1e6/r[1]:8.0f} MB/s ({r[0]//(1024*1024)} MiB in {r[1]*1000:.1f} ms) - page cache bypassed")
    else: print(f"    {'O_DIRECT read':20} unavailable on this fs")
print("\n  many small files (shard-heavy pipelines):")
for label, d in [("ext4", os.environ.get("PROBE_FS_DIR", os.getcwd())), ("tmpfs /tmp", "/tmp")]:
    sub = os.path.join(d, "probe_small"); shutil.rmtree(sub, ignore_errors=True); os.makedirs(sub, exist_ok=True)
    t0 = time.perf_counter()
    for i in range(2000):
        with open(f"{sub}/f{i:05d}.dat", "wb") as f: f.write(b"x" * 1024)
    t1 = time.perf_counter()
    n = 0
    for i in range(2000):
        with open(f"{sub}/f{i:05d}.dat", "rb") as f: n += len(f.read())
    t2 = time.perf_counter()
    t3 = time.perf_counter()
    for i in range(100):
        fd = os.open(f"{sub}/s{i:03d}.dat", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644); os.write(fd, b"y" * 1024); os.fsync(fd); os.close(fd)
    t4 = time.perf_counter()
    print(f"    {label:10} write 2000x1KiB: {t1-t0:6.3f}s ({2000/(t1-t0):6.0f} files/s) | read-back {t2-t1:6.3f}s | write+fsync 100: {(t4-t3):6.3f}s ({(t4-t3)/100*1000:5.1f} ms/op)")
    shutil.rmtree(sub, ignore_errors=True)
print("\n  note: reads above are page-cache warm unless O_DIRECT; that gap IS the finding for caching design.")
DEOF
printf '$ PROBE_FS_DIR=%s python3 disk.py %s\n' "$PWD" "$REPS" >> "$CUR"
PROBE_FS_DIR="$PWD" python3 "$TMPD/disk.py" "$REPS" >> "$CUR" 2>&1
sh_ "dd if=/dev/zero of=./probe_dd.bin bs=1M count=$([ "$FAST" = 1 ] && echo 50 || echo 200) conv=fsync 2>&1 | tail -1; rm -f probe_dd.bin"
sh_ "dd if=/dev/zero of=./probe_dd2.bin bs=1M count=$([ "$FAST" = 1 ] && echo 50 || echo 200) oflag=direct 2>&1 | tail -1; rm -f probe_dd2.bin"
sh_ "if sudo -n sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null; then dd if=/dev/zero of=./probe_c.bin bs=1M count=100 conv=fsync >/dev/null 2>&1; sync; sudo -n sh -c 'echo 3 > /proc/sys/vm/drop_caches'; dd if=./probe_c.bin of=/dev/null bs=1M 2>&1 | tail -1; echo '  (above = COLD read, caches dropped)'; rm -f probe_c.bin; else echo '  drop_caches unavailable (no sudo) - cold-read test skipped'; fi"

# ================================================================ 16 installs
cur 16_bench_installs.txt
cat > "$TMPD/installs.py" <<'IEOF'
import subprocess, time, sys
REPS = max(1, int(sys.argv[1]))
def run(label, cmd, timeout=180, shell=True, reps=1):
    best = None; last = ""
    for _ in range(reps):
        t0 = time.perf_counter()
        p = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=timeout)
        el = time.perf_counter() - t0
        best = el if best is None else min(best, el)
        last = (p.stdout + p.stderr).strip().splitlines()
        if p.returncode != 0:
            print(f"  {label:44} exit={p.returncode} {el:7.2f}s  {last[-1][:60] if last else ''}")
            return None
    print(f"  {label:44} {'ok':>5} {best:7.2f}s  {(last[-1][:58] if last else '')}")
    return best
run("pip download --no-deps requests", "python3 -m pip download --no-deps -q -d /tmp/probe_pipdl requests", reps=REPS)
run("pip install --user rich (pure python)", "python3 -m pip install -q --user rich && python3 -c 'import rich'")
run("pip install --user ujson (C++/meson)", "python3 -m pip install -q --user ujson && python3 -c 'import ujson'")
run("npm install --no-audit --no-fund ms", f"cd {sys.argv[2]} && npm install --no-audit --no-fund --silent ms")
r = None
for _ in range(min(3, REPS + 1)):
    t0 = time.perf_counter()
    p = subprocess.run(f"cd {sys.argv[2]} && npm install --silent ms", shell=True, capture_output=True, text=True, timeout=70)
    el = time.perf_counter() - t0
    print(f"  {'npm install ms (audit ON, attempt)':44} exit={p.returncode} {el:7.2f}s  <-- audit path is the variable one")
    if el > 60: print("      (hit the 60s cap: this is the intermittent audit hang; --no-audit is immune)"); break
IEOF
mkdir -p "$TMPD/npm" && printf '{"name":"probe","version":"1.0.0"}' > "$TMPD/npm/package.json"
printf '$ python3 installs.py %s %s\n' "$REPS" "$TMPD/npm" >> "$CUR"
python3 "$TMPD/installs.py" "$REPS" "$TMPD/npm" >> "$CUR" 2>&1
sh_ "echo '--- apt install of a real system package (timed) ---'; PKG=\$(command -v zstd >/dev/null && echo libzstd1 || echo zstd); t0=\$(date +%s%N); sudo -n apt-get install -y -qq \$PKG >/dev/null 2>&1; echo \"  \$PKG: exit=\$? in \$(( (\$(date +%s%N)-t0)/1000000 )) ms\""
sh_ "echo '--- venv + install into it (isolation path) ---'; t0=\$(date +%s%N); python3 -m venv $TMPD/v2 >/dev/null 2>&1; $TMPD/v2/bin/pip install -q numpy >/dev/null 2>&1; echo \"  venv + pip install numpy: \$(( (\$(date +%s%N)-t0)/1000000 )) ms; result=\"; $TMPD/v2/bin/python -c 'import numpy;print(\"   \",numpy.__version__)' 2>&1"
rm -rf "$TMPD/gc" 2>/dev/null
sh_ "echo '--- git clone over https (real-world bulk) ---'; t0=\$(date +%s%N); git clone -q --depth 1 https://github.com/git/git $TMPD/gc 2>&1 | tail -2; echo \"  shallow clone of git/git: \$(( (\$(date +%s%N)-t0)/1000000 )) ms, size \$(du -sh $TMPD/gc 2>/dev/null | cut -f1)\""

# ================================================================ 17 memory pressure
cur 17_mem_pressure.txt
sh_ "CG=/sys/fs/cgroup\$(awk -F: '\$1==0{print \$3}' /proc/self/cgroup); echo 'limit/current/events:'; for f in memory.max memory.high memory.current memory.events memory.stat; do echo \"-- \$f\"; cat \$CG/\$f 2>&1 | head -8; done"
sh_ "echo 'memory.stat key fields:'; CG=/sys/fs/cgroup\$(awk -F: '\$1==0{print \$3}' /proc/self/cgroup); grep -E '^(anon|file|slab|kernel_stack|pagetables|sock|shmem|dirty|writeback|inactive_anon|active_anon|workingset_refault)' \$CG/memory.stat 2>&1 | sort"
sh_ "echo 'swap:'; awk '/SwapTotal|SwapFree/{print}' /proc/meminfo"
if [ "$WITH_OOM" = 1 ]; then
  printf '$ python3 oom_probe.py  (DRIVES TO OOM - child is SIGKILLed by design)\n' >> "$CUR"
  cat > "$TMPD/oom.py" <<'OEOF'
import os, sys, resource
log = open(sys.argv[1], "w", buffering=1)   # line-buffered: survives the kill
def cg(field):
    rel = [l.split(":", 2)[2].strip() for l in open("/proc/self/cgroup") if l.startswith("0:")]
    base = "/sys/fs/cgroup" + (rel[0] if rel and rel[0] != "/" else "")
    try:
        txt = open(f"{base}/{field}").read().strip()
        return None if txt == "max" else int(txt)
    except Exception:
        return None
lim = cg("memory.max"); cur = cg("memory.current")
log.write(f"  memory.max={lim} ({lim/2**20:.0f} MiB)  start current={cur/2**20:.0f} MiB\n")
keep = []; step = 128 * 1024 * 1024
try:
    for i in range(40):
        b = bytearray(step)
        for j in range(0, step, 4096): b[j] = 1     # touch pages so it is really charged
        keep.append(b)
        log.write(f"  allocated {(i+1)*128:5d} MiB | cgroup current {cg('memory.current')/2**20:6.0f} MiB | rss {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1024:6.0f} MiB\n")
        if (cg('memory.current') or 0) > lim * 0.97: log.write("  stopped just below the cap (no kill)\n"); break
except MemoryError:
    log.write(f"  MemoryError was raised at {len(keep)*128} MiB -> graceful\n")
log.write(f"  reached end alive with {len(keep)*128} MiB held\n"); log.close()
OEOF
  python3 "$TMPD/oom.py" "$TMPD/oom.log"; rc=$?
  cat "$TMPD/oom.log" >> "$CUR"
  if [ "$rc" = 137 ] || [ "$rc" = 135 ] || [ "$rc" = 2 ] || [ "$rc" -gt 128 ] 2>/dev/null; then
    printf '\n  >>> process was SIGKILLed (exit %s) -> OOM killer, NOT a catchable MemoryError\n' "$rc" >> "$CUR"
    printf '  >>> consequence: buffered stdout of a killed process is lost; flush progress to disk\n' >> "$CUR"
  else
    printf '\n  >>> exited rc=%s (MemoryError path or stopped below cap)\n' "$rc" >> "$CUR"
  fi
  CGF=/sys/fs/cgroup$(awk -F: '$1==0{print $3}' /proc/self/cgroup)/memory.events
  printf '\n  post-test memory.events: %s\n' "$(tr '\n' ' ' < $CGF 2>/dev/null)" >> "$CUR"
else
  echo "  OOM-driving test SKIPPED by default (it kills a process). Re-run with --with-oom to reproduce." >&2
  printf '  [Oom-driving test skipped: pass --with-oom]\n' >> "$CUR"
  printf '  Evidence from a run that did use --with-oom is kept in the published transcript.\n' >> "$CUR"
fi

# ================================================================ 18 background
cur 18_background.txt
printf '$ background survival protocol (must be run in TWO invocations to be meaningful)\n' >> "$CUR"
{
  echo "  This probe writes a tick file and exits; use probe_background.sh to test survival."
  echo "  Verbatim check of detached-process support, run inline now:"
} >> "$CUR"
BGF="$OUTDIR/.bg_ticks"
nohup bash -c "for i in \$(seq 1 20); do date -u +%H:%M:%S; sleep 1; done" > "$BGF" 2>&1 &
BGPID=$!
disown 2>/dev/null
sleep 1
sh_ "ps -o pid,ppid,etime,stat,cmd -p $BGPID 2>&1 | tail -2"
sh_ "echo '  parent shell exit does not wait for it; the point is whether it is still alive on the NEXT probe run'"
printf '%s %s\n' "$BGPID" "$(date -u +%s)" > "$OUTDIR/.bg_pid"
( setsid bash -c "for i in \$(seq 1 20); do date -u +%H:%M:%S >> '$BGF.setsid'; sleep 1; done" </dev/null >/dev/null 2>&1 & )
sleep 0.2
sh_ "echo 'setsid variant:'; pgrep -fa 'BG' 2>/dev/null | head -3; pgrep -c -f '$BGF.setsid' 2>/dev/null | xargs echo '  setsid loops alive:'"
sh_ "echo 'process/thread ceilings:'; CG=/sys/fs/cgroup\$(awk -F: '\$1==0{print \$3}' /proc/self/cgroup); cat \$CG/pids.max 2>&1; ulimit -u; echo '  open files:'; ulimit -n; echo '  inotify instances (fs.inotify.max_user_instances):'; cat /proc/sys/fs/inotify/max_user_instances /proc/sys/fs/inotify/max_user_watches 2>&1"
sh_ "echo 'pty availability:'; ls -la /dev/ptmx 2>&1 | head -1; python3 -c \"import pty;print('  pty.openpty:',pty.openpty()[0]>0)\" 2>&1"

# ================================================================ 19 services
cur 19_services.txt
sh_ "ss -tulnp 2>/dev/null | sort | head -30"
sh_ "ps -eo pid,ppid,user,etime,rss,cmd --sort=pid 2>&1 | grep -vE '\[' | head -25"
sh_ "echo '--- sandbox infra env vars ---'; env | sort | grep -iE '^E2B|^SANDBOX|^ARENA' || echo '(none)'"
sh_ "echo '--- systemd services enabled ---'; systemctl list-unit-files --state=enabled --no-legend 2>&1 | awk '{print \$1}' | sort"
sh_ "echo '--- timers armed (can perturb benchmarks!) ---'; systemctl list-timers --all --no-legend 2>&1 | awk 'NF{print \$1,\$2,\$NF}' | sort"
sh_ "echo '--- tmpfiles sweep ages ---'; grep -hE '^\s*[qQvdD]\s+/(tmp|var/tmp)(\s|$)' /usr/lib/tmpfiles.d/*.conf 2>/dev/null | sort -u"
sh_ "echo '--- journald available? ---'; journalctl -n 2 2>&1 | tail -2"
sh_ "echo '--- ports bound by infra on the eth0 IP (preview exposure) ---'; ss -tlnp 2>/dev/null | awk '/169.254|0.0.0.0/ {print \$4, \$6}' | sort -u | head -20"

# ================================================================ 20 GPU / PCI
cur 20_accelerators.txt
sh_ "ls /dev/nvidia* /dev/dri /dev/infiniband 2>&1 | head -3"
sh_ "ls /sys/bus/pci/devices/ 2>&1 | head -5; echo '--- class scan ---'; found=0; for d in /sys/bus/pci/devices/*; do [ -r \"\$d/class\" ] || continue; c=\$(cat \$d/class); case \"\$c\" in 0x03*) echo \"  display ctrl \$d \$(cat \$d/vendor): \$(cat \$d/device)\"; found=1;; esac; done; [ \$found -eq 0 ] && echo '  no PCI display controller'"
sh_ "grep -icE 'nvidia|drm' /proc/devices | xargs echo 'drm/nvidia major devices in /proc/devices:'"
have lspci && sh_ "lspci 2>&1 | head" || sh_ "echo 'lspci: ABSENT'"
sh_ "echo '--- opencl/cuda libs ---'; ls /usr/local/cuda /opt/cuda 2>&1 | head -2; ldconfig -p 2>/dev/null | grep -icE 'cuda|opencl|nvidia' | xargs echo '  cuda/opencl shared objects:'"
sh_ "python3 -c \"import importlib.util as u;print('  torch:', 'present' if u.find_spec('torch') else 'ABSENT')\""


# ================================================================ 99 finish
# Write the run id, normalize, then build the verification manifest. Each step is
# explicit and non-duplicated: an earlier draft of this script carried a second copy
# of sections 10-20 below this point, which silently overwrote the first pass.
printf '%s\n' "$RUN_ID" > "$OUTDIR/.run_id"
printf '\n$ END\n  total wall time: %s s\n' "$(( $(date +%s) - probe_start_epoch ))" >> "$OUTDIR/00_meta.txt"
echo "  probe finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)  duration $(( $(date +%s) - probe_start_epoch ))s -> $OUTDIR"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
for helper in normalize.py make_manifest.py; do
  if [ ! -f "$SCRIPT_DIR/$helper" ] && [ -f "$OUTDIR/../$helper" ]; then SCRIPT_DIR="$OUTDIR/.."; fi
done
for helper in normalize.py make_manifest.py; do
  [ -f "$SCRIPT_DIR/$helper" ] || { echo "  WARNING: $helper not found next to probe.sh - skipping that step"; continue; }
  case "$helper" in
    normalize.py)    python3 "$SCRIPT_DIR/normalize.py" "$OUTDIR"/*.txt >/dev/null 2>&1 \
                     && echo "  normalized copies -> $OUTDIR/normalized/" ;;
    make_manifest.py) python3 "$SCRIPT_DIR/make_manifest.py" "$OUTDIR" \
                     && echo "  manifest -> $OUTDIR/MANIFEST.txt" ;;
  esac
done

exit 0
