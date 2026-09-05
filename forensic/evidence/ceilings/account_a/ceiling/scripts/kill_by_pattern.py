import os, signal, sys, time
pat = open("/home/user/ceiling/scripts/.target_name").read().strip()
me = os.getpid()
ppid = os.getppid()
killed = []
for p in os.listdir("/proc"):
    if not p.isdigit(): continue
    pid = int(p)
    if pid in (me, ppid): continue
    try:
        with open(f"/proc/{p}/cmdline", "rb") as f:
            cl = f.read().replace(b"\x00", b" ").decode(errors="replace")
    except Exception:
        continue
    if pat in cl:
        try:
            os.kill(pid, signal.SIGKILL); killed.append(pid)
        except ProcessLookupError: pass
print("killed:", len(killed))
time.sleep(1)
