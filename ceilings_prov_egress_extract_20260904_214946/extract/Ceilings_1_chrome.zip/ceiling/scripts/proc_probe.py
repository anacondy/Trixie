import os, resource, time, json, errno, subprocess, signal

out = {}
def rd(p):
    try:
        with open(p) as f: return f.read().strip()
    except Exception as e: return f"ERR {e}"

soft, hard = resource.getrlimit(resource.RLIMIT_NPROC)
print(f"RLIMIT_NPROC soft={soft} hard={hard}")
out["rlimit_nproc"] = [soft, hard]
print("pids.max:", rd("/sys/fs/cgroup/user/pids.max"), " pids.current:", rd("/sys/fs/cgroup/user/pids.current"))
out["pids"] = [rd("/sys/fs/cgroup/user/pids.max"), rd("/sys/fs/cgroup/user/pids.current")]
print("kernel threads-max:", rd("/proc/sys/kernel/threads-max"))

# count processes with our uid (they all count vs RLIMIT_NPROC)
me = os.getuid()
uid_procs = sum(1 for p in os.listdir('/proc') if p.isdigit() and os.stat(f'/proc/{p}').st_uid == me)
print("current uid-1000 processes visible:", uid_procs)
out["uid_procs_before"] = uid_procs

# ---- FORK TEST ----
children = []
t0 = time.time()
forks = 0
err = None
try:
    while True:
        pid = os.fork()
        if pid == 0:                       # child: idle forever
            os.setsid()
            time.sleep(3600)
            os._exit(0)
        children.append(pid)
        forks += 1
        if forks % 500 == 0: print(f"  forked {forks} children...", flush=True)
except OSError as e:
    err = (e.errno, e.strerror)
dt = time.time() - t0
print(f"FORK: succeeded {forks} times in {dt:.1f}s, then {err}")
out["fork"] = {"count": forks, "errno": err[0], "msg": err[1], "sec": round(dt,1)}

# kill children, reap, verify
for p in children: 
    try: os.kill(p, signal.SIGKILL)
    except ProcessLookupError: pass
for p in children:
    try: os.waitpid(p, 0)
    except ChildProcessError: pass
time.sleep(0.5)
left = sum(1 for p in os.listdir('/proc') if p.isdigit() and os.stat(f'/proc/{p}').st_uid == me)
print("uid processes after cleanup:", left, " pids.current:", rd('/sys/fs/cgroup/user/pids.current'))
out["uid_procs_after"] = left

# ---- THREAD TEST (single process, max threads) ----
import threading
ev = threading.Event()
ts = []
t0 = time.time()
thr_err = None
try:
    while True:
        def waiter(): ev.wait()
        t = threading.Thread(target=waiter, daemon=True)
        t.start()
        ts.append(t)
        if len(ts) % 1000 == 0: print(f"  started {len(ts)} threads...", flush=True)
except Exception as e:
    thr_err = f"{type(e).__name__}: {e}"
dt = time.time() - t0
print(f"THREAD: created {len(ts)} threads in {dt:.1f}s, then {thr_err}")
out["threads"] = {"count": len(ts), "err": thr_err, "sec": round(dt,1)}
ev.set()
for t in ts: t.join(timeout=5)
print("threads joined. pids.current:", rd('/sys/fs/cgroup/user/pids.current'))

# sanity: can we still fork normally after all that?
p = os.fork()
if p == 0:
    os._exit(0)
os.waitpid(p, 0)
print("post-test fork: OK")
out["post_fork_ok"] = True

with open("/home/user/ceiling/out/proc_probe.json","w") as f: json.dump(out, f, indent=1)
