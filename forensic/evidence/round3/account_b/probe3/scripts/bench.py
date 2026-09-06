import sys, time, os
# bench.py <cpu_set_csv> <iterations> [--wait] 
# runs fixed integer work; prints elapsed. Optionally waits for a sibling already running.
cpus = sys.argv[1]
iters = int(sys.argv[2])
want_wait = len(sys.argv) > 3 and sys.argv[3] == "--wait"
os.sched_setaffinity(0, {int(c) for c in cpus.split(",")})
if want_wait:
    time.sleep(0.5)
t0 = time.time()
x = 0
for i in range(iters):
    x = (x + i) % 1000000007
dt = time.time() - t0
print(f"cpus={cpus} iters={iters} elapsed={dt:.3f}s x={x}", flush=True)
