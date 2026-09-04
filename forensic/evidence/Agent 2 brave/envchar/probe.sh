#!/usr/bin/env bash
# envchar probe — third-party re-runnable environment characterization.
# Writes verbatim command transcripts under ./raw/ (or $ENVCHAR_OUT).
# Usage: ./probe.sh
# Optional: ENVCHAR_OUT=/path/to/dir ENVCHAR_SKIP_DOWNLOADS=1 ENVCHAR_SKIP_MEMORY=1
set -u
set +e

PROBE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${ENVCHAR_OUT:-$PROBE_DIR/raw}"
STAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$OUT"

# Each section file starts with a header; every command is wrapped so the
# transcript is: banner, command text, exit code, wall time, stdout+stderr.
run() {
  local banner="$1"
  shift
  local t0 t1 rc
  t0=$(date +%s.%N)
  echo ""
  echo "================================================================"
  echo "=== ${banner}"
  echo "=== CMD: $*"
  echo "=== UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "================================================================"
  "$@"
  rc=$?
  t1=$(date +%s.%N)
  printf "=== EXIT: %s  WALL_S: %s ===\n" "$rc" "$(python3 -c "print(f'{float('$t1')-float('$t0'):.4f}')" 2>/dev/null || echo "?")"
  return 0
}

header() {
  local f="$1"
  local title="$2"
  cat > "$f" <<EOF
# envchar raw transcript
# file: $(basename "$f")
# title: ${title}
# generated_utc: ${STAMP_UTC}
# host: $(hostname 2>/dev/null)
# sandbox: ${E2B_SANDBOX_ID:-unknown}
# template: ${E2B_TEMPLATE_ID:-unknown}
# probe: ${PROBE_DIR}/probe.sh
# NOTE: This file is a verbatim command transcript. Do not summarize.
EOF
}

echo "[probe] writing transcripts to $OUT  utc=$STAMP_UTC"

###############################################################################
# 01 runtime
###############################################################################
F="$OUT/01_runtime.txt"
header "$F" "OS / kernel / libc / clock"
{
  run "uname -a" uname -a
  run "uname fields" uname -s -r -v -m -o
  run "os-release" cat /etc/os-release
  run "debian version" cat /etc/debian_version
  run "arch" uname -m
  run "dpkg architecture" dpkg --print-architecture
  run "ldd --version" ldd --version
  run "getconf GNU_LIBC_VERSION" getconf GNU_LIBC_VERSION
  run "libc.so.6" /lib/x86_64-linux-gnu/libc.so.6
  run "dpkg libc6" dpkg -l libc6
  run "hostname" hostname
  run "hostnamectl" hostnamectl
  run "uptime" uptime
  run "proc uptime" cat /proc/uptime
  run "date local" date
  run "date utc" date -u
  run "timedatectl" timedatectl
  run "timezone file" cat /etc/timezone
  run "localtime" ls -l /etc/localtime
  run "locale" locale
  run "kernel cmdline" cat /proc/cmdline
} >> "$F" 2>&1
echo "[probe] 01_runtime.txt"

###############################################################################
# 02 isolation
###############################################################################
F="$OUT/02_isolation.txt"
header "$F" "Container / VM / LSM / namespaces / E2B markers"
{
  run "dockerenv ls" ls -la /.dockerenv
  run "e2b root marker" ls -la /.e2b
  run "e2b root cat" cat /.e2b
  run "run e2b" ls -la /run/e2b
  run "E2B_SANDBOX file" cat /run/e2b/.E2B_SANDBOX
  run "E2B_SANDBOX_ID file" cat /run/e2b/.E2B_SANDBOX_ID
  run "E2B_TEMPLATE_ID file" cat /run/e2b/.E2B_TEMPLATE_ID
  run "proc1 cgroup" cat /proc/1/cgroup
  run "self cgroup" cat /proc/self/cgroup
  run "proc1 comm" cat /proc/1/comm
  run "proc1 exe" ls -l /proc/1/exe
  run "systemd-detect-virt" systemd-detect-virt
  run "systemd-detect-virt --vm" systemd-detect-virt --vm
  run "systemd-detect-virt --container" systemd-detect-virt --container
  run "lscpu" lscpu
  run "dmi sys_vendor" cat /sys/class/dmi/id/sys_vendor
  run "dmi product_name" cat /sys/class/dmi/id/product_name
  run "dmi bios_vendor" cat /sys/class/dmi/id/bios_vendor
  run "dmi bios_version" cat /sys/class/dmi/id/bios_version
  run "dev kvm/vda" ls -l /dev/kvm /dev/vda /dev/vda* /dev/root
  run "self status caps/seccomp" grep -E '^(Cap|Seccomp|NoNewPrivs|Name|Uid|Gid|NStgid)' /proc/self/status
  run "self namespaces" ls -l /proc/self/ns
  run "apparmor current" cat /proc/self/attr/current
  run "selinux enforce" cat /sys/fs/selinux/enforce
  run "mountinfo" cat /proc/self/mountinfo
  run "proc mounts" cat /proc/mounts
  run "findmnt" findmnt
  run "systemd running services" systemctl list-units --type=service --state=running --no-pager
  run "envd.service" systemctl cat envd.service
  run "jupyter.service" systemctl cat jupyter.service
} >> "$F" 2>&1
echo "[probe] 02_isolation.txt"

###############################################################################
# 03 user + ulimit + cpu/mem
###############################################################################
F="$OUT/03_user_limits.txt"
header "$F" "User identity, sudo, ulimit, cpuinfo, meminfo"
{
  run "id" id
  run "whoami" whoami
  run "groups" groups
  run "getent passwd" getent passwd "$(whoami)"
  run "sudo -n true" sudo -n true
  run "sudo -l" sudo -l
  run "ls sudo binary" ls -l /usr/bin/sudo
  run "ulimit -a" bash -c 'ulimit -a'
  run "ulimit -Ha" bash -c 'ulimit -Ha'
  run "nproc" nproc
  run "cpuinfo" cat /proc/cpuinfo
  run "meminfo" cat /proc/meminfo
  run "swaps" cat /proc/swaps
  run "loadavg" cat /proc/loadavg
  run "proc stat cpu" head -5 /proc/stat
  run "vmstat 1 3" vmstat 1 3
  run "limits.d" ls -la /etc/security/limits.d
  run "limits.conf" cat /etc/security/limits.conf
} >> "$F" 2>&1
echo "[probe] 03_user_limits.txt"

###############################################################################
# 04 cgroup
###############################################################################
F="$OUT/04_cgroup.txt"
header "$F" "cgroup v2 memory/cpu/pids"
{
  run "cgroup root listing" ls -la /sys/fs/cgroup
  run "cgroup.controllers" cat /sys/fs/cgroup/cgroup.controllers
  run "user listing" ls -la /sys/fs/cgroup/user
  for p in memory.max memory.high memory.low memory.min memory.current memory.peak \
           memory.swap.max memory.swap.current memory.events memory.stat \
           cpu.max cpu.weight cpu.stat \
           pids.max pids.current pids.peak \
           cpuset.cpus cpuset.cpus.effective cpuset.mems.effective; do
    run "user/$p" cat "/sys/fs/cgroup/user/$p"
  done
  run "root cpu.max" cat /sys/fs/cgroup/cpu.max
  run "root memory.max" cat /sys/fs/cgroup/memory.max
} >> "$F" 2>&1
echo "[probe] 04_cgroup.txt"

###############################################################################
# 05 environment
###############################################################################
F="$OUT/05_environment.txt"
header "$F" "Environment variables and PATH"
{
  run "env sorted" bash -c 'env | sort'
  run "PATH" bash -c 'printf "%s\n" "$PATH"'
  run "pwd" pwd
  run "HOME" bash -c 'printf "%s\n" "$HOME"'
  run "SHELL" bash -c 'printf "%s\n" "$SHELL"'
  run "python sys.path" python3 -c "import sys,site; print('exe',sys.executable); print('ver',sys.version); print('path',sys.path); print('USER_SITE',site.USER_SITE); print('ENABLE_USER_SITE',site.ENABLE_USER_SITE); print('sitepkgs',site.getsitepackages())"
} >> "$F" 2>&1
echo "[probe] 05_environment.txt"

###############################################################################
# 06 tools
###############################################################################
F="$OUT/06_tools.txt"
header "$F" "Tool availability and versions"
{
  run "which list" bash -c '
    for cmd in python3 python pip pip3 python3.13 node npm npx yarn pnpm git curl wget ffmpeg docker podman make gcc g++ clang clang++ jq rustc cargo go java javac ruby php perl R conda mamba uv pixi poetry pipx cmake ninja meson pkg-config ldd strace gdb lsof ss ip iptables nft nc ncat socat openssl ssh scp rsync tar unzip zip gzip bzip2 xz zstd 7z tmux screen htop vim nano emacs awk sed grep find xargs parallel pigz aria2c httpie apt apt-get dpkg; do
      if command -v "$cmd" >/dev/null 2>&1; then
        loc=$(command -v "$cmd")
        printf "YES\t%s\t%s\n" "$cmd" "$loc"
      else
        printf "NO\t%s\n" "$cmd"
      fi
    done
  '
  for cmd in python3 pip node npm git curl wget make gcc g++ jq java javac perl R openssl ssh tar gzip xz pkg-config; do
    if command -v "$cmd" >/dev/null 2>&1; then
      run "$cmd --version" "$cmd" --version
    fi
  done
  run "java -version" java -version
  run "g++ --version" g++ --version
  run "apt --version" apt --version
  run "apt sources.list.d" ls -la /etc/apt/sources.list.d
  run "debian.sources" cat /etc/apt/sources.list.d/debian.sources
} >> "$F" 2>&1
echo "[probe] 06_tools.txt"

###############################################################################
# 07 python packages
###############################################################################
F="$OUT/07_python_packages.txt"
header "$F" "Python package inventory"
{
  run "pip --version" python3 -m pip --version
  run "pip list" python3 -m pip list --disable-pip-version-check
  run "pip list freeze count" bash -c 'python3 -m pip list --format=freeze --disable-pip-version-check | wc -l'
  run "key imports" python3 - << 'PY'
import importlib
mods = ["numpy","pandas","scipy","sklearn","torch","tensorflow","cv2","PIL","requests","httpx","aiohttp","bs4","lxml","yaml","tqdm","rich","orjson","pydantic","fastapi","flask","sqlalchemy","boto3","openai","transformers","datasets","huggingface_hub","matplotlib","seaborn","plotly","networkx","sympy","numba","pytest","IPython","jupyter","joblib","nltk","spacy","gensim","librosa"]
for m in mods:
    try:
        mod = importlib.import_module(m)
        print(f"YES  {m:20s} {getattr(mod,'__version__','?')}")
    except Exception as e:
        print(f"NO   {m:20s} {type(e).__name__}")
PY
  run "numpy config" python3 -c "import numpy as np; np.__config__.show()"
  run "spacy info" python3 -c "import spacy, json; print(spacy.info())"
} >> "$F" 2>&1
echo "[probe] 07_python_packages.txt"

###############################################################################
# 08 filesystem
###############################################################################
F="$OUT/08_filesystem.txt"
header "$F" "Filesystem, disk space, write tests"
{
  run "df -hT" df -hT
  run "df -i" df -i
  run "lsblk" lsblk -a
  run "findmnt -D" findmnt -D
  run "du top" du -sh /usr /var /home /opt /tmp /root /usr/local 2>/dev/null
  run "ls -la /home/user" ls -la /home/user
  run "ls -ld tmp paths" ls -ld /tmp /var/tmp /home/user /usr/local
  run "write tests" bash -c '
    set +e
    echo "test-home" > /home/user/.envchar_w && cat /home/user/.envchar_w && rm /home/user/.envchar_w && echo HOME=OK || echo HOME=FAIL
    echo "test-tmp" > /tmp/.envchar_w && cat /tmp/.envchar_w && rm /tmp/.envchar_w && echo TMP=OK || echo TMP=FAIL
    echo "test-vartmp" > /var/tmp/.envchar_w && cat /var/tmp/.envchar_w && rm /var/tmp/.envchar_w && echo VARTMP=OK || echo VARTMP=FAIL
    echo "test-usrlocal" > /usr/local/.envchar_w && echo USRLOCAL=OK && rm -f /usr/local/.envchar_w || echo USRLOCAL=FAIL
    echo "test-root" > /envchar_w 2>&1 && echo ROOT=OK || echo ROOT=FAIL
    echo "test-opt" > /opt/.envchar_w 2>&1 && echo OPT=OK || echo OPT=FAIL
    echo "test-etc" > /etc/.envchar_w 2>&1 && echo ETC=OK || echo ETC=FAIL
    touch /bin/envchar 2>&1 || true
    touch /usr/bin/envchar 2>&1 || true
    ls -ld /usr/local/lib/python3.13/site-packages
    touch /usr/local/lib/python3.13/site-packages/.wtest && echo SITEPACKAGES=OK && rm -f /usr/local/lib/python3.13/site-packages/.wtest || echo SITEPACKAGES=FAIL
  '
} >> "$F" 2>&1
echo "[probe] 08_filesystem.txt"

###############################################################################
# 09-15 via python bench script
###############################################################################
export ENVCHAR_OUT="$OUT"
export ENVCHAR_STAMP_UTC="$STAMP_UTC"
python3 "$PROBE_DIR/probe_bench.py"
echo "[probe] python benches done"

###############################################################################
# 16 misc (shell leftovers)
###############################################################################
F="$OUT/16_misc.txt"
header "$F" "Background processes, bind, listeners, traceroute, ping"
{
  run "ss -tulpn" ss -tulpn
  run "ps aux head" bash -c 'ps aux | head -80'
  run "ps -e count" bash -c 'ps -e --no-headers | wc -l'
  run "ip -br addr" ip -br addr
  run "ip route" ip route
  run "resolv.conf" cat /etc/resolv.conf
  run "sudo ping 8.8.8.8" sudo ping -c 3 -W 2 8.8.8.8
  run "unprivileged ping" ping -c 1 -W 1 8.8.8.8
  run "ensure traceroute" bash -c 'command -v traceroute >/dev/null || sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y traceroute'
  run "sudo traceroute 8.8.8.8" sudo traceroute -n -w 1 -q 1 -m 12 8.8.8.8
  run "sudo traceroute github" sudo traceroute -n -w 1 -q 1 -m 12 github.com
  run "sudo tcp traceroute github 443" sudo traceroute -T -p 443 -n -w 1 -q 1 -m 8 github.com
  run "background sleep" bash -c '
    rm -f /tmp/envchar_bg.log
    nohup bash -c "echo start \$(date -u +%Y-%m-%dT%H:%M:%SZ) \$\$ >> /tmp/envchar_bg.log; sleep 3; echo end \$(date -u +%Y-%m-%dT%H:%M:%SZ) \$\$ >> /tmp/envchar_bg.log" >/dev/null 2>&1 &
    echo spawned $!
    sleep 4
    cat /tmp/envchar_bg.log
    rm -f /tmp/envchar_bg.log
  '
  run "bind 18080" python3 -c "import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind((\"0.0.0.0\",18080)); s.listen(1); print(\"bind 0.0.0.0:18080 OK\"); s.close()"
  run "bind 80 user" python3 -c "import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
try:
    s.bind((\"0.0.0.0\",80)); print(\"bind :80 OK\")
except Exception as e:
    print(type(e).__name__, e)
s.close()"
  run "sudo bind 80" sudo python3 -c "import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind((\"0.0.0.0\",80)); s.listen(1); print(\"sudo bind 0.0.0.0:80 OK\"); s.close()"
  run "entropy" cat /proc/sys/kernel/random/entropy_avail
  run "dmesg tail" bash -c 'sudo dmesg -T | tail -n 80'
} >> "$F" 2>&1
echo "[probe] 16_misc.txt"

###############################################################################
# MANIFEST
###############################################################################
python3 "$PROBE_DIR/make_manifest.py"
echo "[probe] done"
echo "[probe] manifest: $PROBE_DIR/MANIFEST.txt"
