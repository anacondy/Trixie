import resource, threading, time

soft, hard = resource.getrlimit(resource.RLIMIT_NPROC)
print(f"RLIMIT_NPROC: soft={soft} hard={hard}")
print(f"cgroup pids.max: {open('/sys/fs/cgroup/user/pids.max').read().strip()}")

ev = threading.Event()
def worker():
    ev.wait()

n = 0
t0 = time.time()
try:
    while n < 20000:
        threading.Thread(target=worker, daemon=True).start()
        n += 1
except (RuntimeError, OSError) as e:
    print(f"THREAD SPAWN FAILED at {n} threads: {type(e).__name__}: {e} (elapsed {time.time()-t0:.1f}s)")
else:
    print("reached safety cap 20000 without failure")
print(f"peak thread count: {n} (main thread + {n} workers = {n+1} tasks)")
ev.set()
time.sleep(3)
print("workers released, done")
