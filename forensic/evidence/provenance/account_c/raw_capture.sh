#!/bin/bash
# raw_capture.sh — re-runs the full provenance command set and logs verbatim output.
# Usage: bash raw_capture.sh > raw_evidence_<timestamp>.txt
# Every section prints the exact command, then its stdout+stderr, then its exit code.

run() {
  printf '\n$ %s\n' "$1"
  eval "$1" 2>&1
  printf '[exit=%s]\n' "$?"
}

printf 'PROVENANCE RAW CAPTURE\n'
printf 'captured_at=%s\n' "$(date -u +%FT%TZ)"
printf 'instance_uptime_at_start=%s\n' "$(cut -d' ' -f1 /proc/uptime)"
printf 'NOTE: this is a re-capture, not the original session output.\n'
printf '      Compare against sandbox_identity_provenance.md for the original readings.\n'

printf '\n================ 1. IDENTITY ================\n'
run 'cat /.e2b'
run 'env | grep -E "^E2B_"'
run 'tr "\0" "\n" < /proc/$$/environ | grep -E "^E2B_"'
run 'hostname'
run 'cat /etc/hosts'
run 'grep -i e2b /etc/hosts'
run 'cat /proc/sys/kernel/random/boot_id'
run 'uptime -s'
run 'cat /proc/uptime'
run 'uptime'
run 'cat /etc/machine-id'
run 'cat /var/lib/dbus/machine-id'
run 'ls -la /run/e2b'
run 'cat /run/e2b/.E2B_SANDBOX'
run 'cat /run/e2b/.E2B_SANDBOX_ID'
run 'cat /run/e2b/.E2B_TEMPLATE_ID'
run 'ps -o pid,lstart,etimes,cmd -p 1'

printf '\n================ 2. IMAGE BUILD LINEAGE ================\n'
run 'stat -c "%y %n" /* | sort'
run 'stat -c "%y %s" /.e2b'
run 'stat /.e2b'
run 'ls -la /etc/apt/sources.list*'
run 'grep -r snapshot.debian.org /etc/apt/sources.list*'
run 'cat /etc/apt/sources.list'
run 'cat /etc/apt/sources.list.d/debian.sources'
run 'cat /etc/apt/sources.list.d/nodesource.sources'
run 'dpkg-query -W --showformat="${Package} ${Version}\n" | wc -l'
run 'pip list --format=freeze | wc -l'
run 'pip list --format=freeze'
run 'which pip pip3 python python3'
run 'python3 -V'
run 'cat /etc/os-release'
run 'uname -a'
run 'cat /proc/cmdline'
run 'ip -brief addr'
run 'cat /sys/class/dmi/id/product_name'
run 'cat /sys/hypervisor/type'

printf '\n================ 3. SERVICE FOOTPRINT ================\n'
run 'systemctl list-units --type=service --state=running --no-pager --no-legend'
run 'systemctl list-units --type=service --all --no-pager'
run 'ss -tlnp'
run 'cat /proc/net/tcp'
for u in envd jupyter code-interpreter; do
  run "systemctl show $u -p FragmentPath"
  run "systemctl cat $u"
  run "systemctl show $u -p MainPID -p ActiveEnterTimestamp -p ActiveEnterTimestampMonotonic -p ExecMainStartTimestamp -p NRestarts"
done
run 'systemctl show dbus -p ActiveEnterTimestamp'
run 'systemctl list-jobs'
run 'journalctl --list-boots --no-pager'
run 'journalctl -q -b --no-pager -o short-iso'
run 'timedatectl'
run 'chronyc tracking'
run '/usr/bin/envd --version'
run 'cat /etc/inittab'
run 'ls -la /etc/systemd/system'

printf '\n================ 4. SELF-DESCRIPTION ================\n'
run 'grep -rIl -m1 -iE "arena|lmarena|e2b" /etc /opt /usr/local 2>/dev/null | head -50'
run 'grep -rIl -iE "arena|lmarena" /etc /opt /usr/local 2>/dev/null | grep -viE "python3\.13|site-packages|/R/|include/"'
run 'ls -la ~'
run 'echo $HOME'
run 'id'
run 'ls -la /code'
run 'find /code -maxdepth 3'
run 'ls -la /'
run 'ls -la /opt'
run 'ls -la /usr/local/share'
run 'ls -la /usr/local/share/e2b'
run 'ls -la /usr/local/share/ca-certificates'
run 'openssl x509 -in /usr/local/share/ca-certificates/e2b-ca.crt -noout -subject -issuer -dates'
run 'ls -la /provision.result /provision.sh /usr/local/bin/provision.sh'
run 'ls -la /root'

printf '\n================ 5. CLOCK MODEL ================\n'
python3 - <<'PY'
import time, datetime
for name in ("CLOCK_REALTIME","CLOCK_MONOTONIC","CLOCK_BOOTTIME"):
    v = time.clock_gettime(getattr(time, name))
    print(f"{name}={v!r}  as_utc={datetime.datetime.fromtimestamp(v, datetime.timezone.utc).isoformat()}")
print("uptime_file=", open("/proc/uptime").read().strip())
for line in open("/proc/stat"):
    if line.startswith("btime"):
        b = int(line.split()[1])
        print("btime=", b, "as_utc=", datetime.datetime.fromtimestamp(b, datetime.timezone.utc).isoformat())
rt = time.clock_gettime(time.CLOCK_REALTIME)
up = float(open("/proc/uptime").read().split()[0])
print("btime == REALTIME - uptime ?", abs((rt-up)-b) < 1.0)
PY

printf '\n================ 6. STABILITY PROBE ================\n'
run 'cat /home/user/prov_probe.txt'
run 'sha256sum /home/user/prov_probe.txt'
run 'wc -c /home/user/prov_probe.txt'

printf '\n================ END OF CAPTURE ================\n'
printf 'captured_at_end=%s\n' "$(date -u +%FT%TZ)"
printf 'instance_uptime_at_end=%s\n' "$(cut -d' ' -f1 /proc/uptime)"
