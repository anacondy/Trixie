import time, statistics, gzip, json, os
def timed(fn, reps=3):
    ts=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); ts.append(time.perf_counter()-t0)
    return min(ts), statistics.median(ts), r
rows=[]
a,b,r=timed(lambda: sum(range(10**7))); rows.append(("sum(range(10**7))",a,b,f"{r:,}"))
a,b,r=timed(lambda: sum(i*i for i in range(10**7))); rows.append(("sum(i*i for i in range(10**7))  [genexpr]",a,b,""))
a,b,r=timed(lambda: sum(map(abs,range(-5_000_000,5_000_000)))); rows.append(("sum(map(abs, 10M range))",a,b,""))
s=json.dumps({'k%d'%i:[i,i*2,"s"*20] for i in range(20000)})
a,b,_=timed(lambda: json.loads(s)); rows.append((f"json.loads {len(s)/1e6:.1f}MB",a,b,""))
a,b,_=timed(lambda: gzip.compress(s.encode(),9)); rows.append((f"gzip.compress {len(s)/1e6:.1f}MB lvl9",a,b,""))
print(f"{'benchmark':42} {'min s':>8} {'med s':>8}  notes")
for n,a,b,x in rows: print(f"{n:42} {a:8.3f} {b:8.3f}  {x}")
print("\n=== numpy/scipy ===")
import numpy as np
print("numpy",np.__version__)
try:
    import threadpoolctl
    with threadpoolctl.threadpool_info() as i: print("BLAS threads:",[ (d['internal_api'],d['num_threads']) for d in i])
except Exception as e: print("threadpoolctl n/a:",type(e).__name__)
a,b,r=timed(lambda: np.sum(np.arange(10**7))); print(f"{'np.sum(np.arange(10**7))':42} {a:8.3f} {b:8.3f}  {r:,}")
x=np.random.rand(4096,4096); a,b,_=timed(lambda: x@x); print(f"{'matmul 4096x4096 fp64':42} {a:8.3f} {b:8.3f}  -> {2*4096**3/b/1e9:.1f} GFLOP/s")
x32=np.random.rand(3072,3072).astype(np.float32); a,b,_=timed(lambda: x32@x32); print(f"{'matmul 3072x3072 fp32':42} {a:8.3f} {b:8.3f}  -> {2*3072**3/b/1e9:.1f} GFLOP/s")
y=np.random.rand(10**7//1); a,b,_=timed(lambda: y.sum()); print(f"{'np.sum 10M float64':42} {a:8.3f} {b:8.3f}")
big=np.random.rand(50_000_000); a,b,_=timed(lambda: big.sum()); print(f"{'sum 50M float64 (400MB stream)':42} {a:8.3f} {b:8.3f}  -> {50e6*8/b/1e9:.1f} GB/s")
a,b,_=timed(lambda: np.sort(big)); print(f"{'np.sort 50M float64':42} {a:8.3f} {b:8.3f}")
import hashlib
a,b,_=timed(lambda: hashlib.sha256(big.astype(np.float64).view(np.uint8)).hexdigest()); print(f"{'sha256 of 400MB':42} {a:8.3f} {b:8.3f}  -> {400e6/b/1e6:.0f} MB/s")
print("\n=== pandas / polars ===")
import pandas as pd
df=pd.DataFrame({"a":np.random.rand(2_000_000),"b":np.random.randint(0,100,2_000_000)})
a,b,_=timed(lambda: df.groupby("b")["a"].mean()); print(f"{'pandas groupby 2M rows,100 keys':42} {a:8.3f} {b:8.3f}")
csv="/home/user/envcheck/t.csv"; df.to_csv(csv,index=False); print("  csv size:",os.path.getsize(csv)/1e6,"MB")
a,b,_=timed(lambda: pd.read_csv(csv)); print(f"{'pandas read_csv 2M rows':42} {a:8.3f} {b:8.3f}")
os.unlink(csv)
try:
    import polars; print("polars:",polars.__version__)
except ImportError: print("polars: not installed")
try:
    import scipy; print("scipy:",scipy.__version__)
except ImportError: print("scipy: no")
