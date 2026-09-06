import os, time, hashlib, sys, multiprocessing as mp
def worker(units):
    buf = os.urandom(1024*1024)
    h = hashlib.sha512()
    t0 = time.time()
    for i in range(units):
        h.update(buf)
        # re-init occasionally to keep CPU-mix steady
        if i % 256 == 255: h = hashlib.sha512()
    return time.time()-t0
UNITS = 4096
def run_cfg(name, pin):
    t0 = time.time()
    procs = []
    for p in pin:
        procs.append(mp.Process(target=worker, args=(UNITS,)))
    for j,p in enumerate(procs):
        p.start()
        os.sched_setaffinity(p.pid, {pin[j]})
    for p in procs: p.join()
    dt = time.time()-t0
    return dt
print("cpu0 sched_affinity of self:", os.sched_getaffinity(0))
print("smt siblings again:", open('/sys/devices/system/cpu/cpu0/topology/thread_siblings_list').read().strip())
# warmup
run_cfg("warm", [0])
tA = run_cfg("A: 1 proc on cpu0", [0])
tB = run_cfg("B: 2 procs on cpu0,cpu1", [0,1])
tC = run_cfg("C: 2 procs both on cpu0 (contention)", [0,0])
tA2 = run_cfg("A2: repeat 1 proc on cpu0", [0])
print("tA (1 proc, cpu0)        = %.3fs" % tA)
print("tA2 (repeat)             = %.3fs" % tA2)
print("tB (2 procs, cpu0+cpu1)  = %.3fs" % tB)
print("tC (2 procs, both cpu0)  = %.3fs" % tC)
print("SMT throughput speedup (2x work in tB vs 1x in tA): %.3fx" % (2*tA/tB))
print("same-core contention ratio tC/tA (expect ~2.0 if threads share core): %.3f" % (tC/tA))
import glob
g = glob.glob('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor')
if g: print("cpufreq governor:", open(g[0]).read().strip())
else: print("cpufreq: no scaling_governor exposed (VM, fixed freq?)")
