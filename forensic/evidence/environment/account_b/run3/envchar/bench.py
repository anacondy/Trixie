import time, math, os, sys

def t(label, fn, reps=1):
    best = None
    for _ in range(reps):
        t0 = time.perf_counter(); r = fn(); dt = time.perf_counter() - t0
        best = dt if best is None else min(best, dt)
    print(f"{label:42s} {best*1000:10.1f} ms   (result={r})")
    return best

print(f"python {sys.version.split()[0]}  pid={os.getpid()}")
t("sum(range(10**7))", lambda: sum(range(10**7)), reps=3)
def heavy():
    s = 0.0
    for i in range(1_000_000):
        s += math.sqrt(i) * i / (i + 1)
    return round(s, 3)
t("loop 1e6: sqrt+mul+div", heavy, reps=3)
t("str join 1e5 ints", lambda: len(",".join(map(str, range(100_000)))), reps=3)
t("sha256 100MB", lambda: __import__('hashlib').sha256(b'A'*100_000_000).hexdigest()[:12])

try:
    import numpy as np
    print("numpy", np.__version__)
    t("np.sum(np.arange(1e8))", lambda: int(np.arange(1e8, dtype=np.int64).sum()))
    a = np.random.rand(1500, 1500); b = np.random.rand(1500, 1500)
    gf = 2*1500**3/1e9
    dt = t("np.dot 1500x1500 (BLAS)", lambda: float(np.dot(a, b).sum()))
    print(f"{'':42s} -> ~{gf/dt:6.1f} GFLOP/s effective")
except ImportError:
    print("numpy missing")

# multiprocessing sanity
from multiprocessing import Pool
def work(n):
    s = 0.0
    for i in range(n): s += math.sqrt(i)
    return s
t0 = time.perf_counter()
with Pool(2) as p:
    p.map(work, [3_000_000, 3_000_000])
dt_par = time.perf_counter() - t0
t0 = time.perf_counter(); work(3_000_000); work(3_000_000); dt_seq = time.perf_counter() - t0
print(f"{'mp Pool(2) 2x3e6 vs sequential':42s} par={dt_par*1000:7.1f} ms  seq={dt_seq*1000:7.1f} ms  speedup={dt_seq/dt_par:.2f}x")
