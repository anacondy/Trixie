import time, statistics, os, platform
def timed(fn, reps=3):
    ts=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); ts.append(time.perf_counter()-t0)
    return min(ts), statistics.median(ts), r
print(f"{'benchmark':38} {'min s':>8} {'med s':>8}  result/side-notes")
a,b,r = timed(lambda: sum(range(10**7)))
print(f"{'sum(range(10**7))':38} {a:8.3f} {b:8.3f}  {r:,}")
a,b,r = timed(lambda: sum(i*i for i in range(10**7)))
print(f"{'sum(i*i for i in range(10**7))':38} {a:8.3f} {b:8.3f}  generator+square")
def heavy():
    t=0.0
    for i in range(3_000_000):
        t += (i%97)**0.5 if i%2 else -(i%97)**0.5
    return t
a,b,r = timed(heavy)
print(f"{'float math loop 3M iters':38} {a:8.3f} {b:8.3f}  {r:.1f}")
def sieve(n=5_000_000):
    s=bytearray(b'\x01')*n; s[0]=s[1]=0
    import math
    for i in range(2,int(math.isqrt(n))+1):
        if s[i]: s[i*i::i]=bytearray(len(s[i*i::i]))
    return sum(s)
a,b,r = timed(sieve)
print(f"{'sieve primes < 5e6 (slice-assign)':38} {a:8.3f} {b:8.3f}  {r:,} primes")
def fib(n=30):
    if n<2: return n
    return fib(n-1)+fib(n-2)
a,b,r = timed(lambda: fib(30))
print(f"{'recursive fib(30)':38} {a:8.3f} {b:8.3f}  {r}")
import json
data={'k%d'%i:[i,i*2,'s'*20] for i in range(20000)}
s=json.dumps(data)
a,b,_ = timed(lambda: json.loads(s))
print(f"{'json.loads 4.7MB payload':38} {a:8.3f} {b:8.3f}  {len(s)/1e6:.1f} MB")
a,b,_ = timed(lambda: gzip_compress(s))
import gzip
print(f"{'gzip.compress 4.7MB (lvl9)':38} {a:8.3f} {b:8.3f}")
print()
print("=== numpy (if present) ===")
try:
    import numpy as np
    print("numpy", np.__version__, "| threading:", np.show_config('dicts')['Build Dependencies'].get('blas',{}).get('name','?'))
    a,b,r=timed(lambda: np.sum(np.arange(10**7)))
    print(f"{'np.sum(np.arange(10**7))':38} {a:8.3f} {b:8.3f}  {r:,}")
    x=np.random.rand(4096,4096)
    a,b,_=timed(lambda: x@x, reps=3)
    gf=2*4096**3/b/1e9
    print(f"{'matmul 4096^3 fp64':38} {a:8.3f} {b:8.3f}  -> {gf:5.1f} GFLOP/s")
    y=np.ascontiguousarray(np.random.rand(10**8//8))
    a,b,_=timed(lambda: y.sum())
    print(f"{'np.sum 100M float64 (mem-bound)':38} {a:8.3f} {b:8.3f}  -> {10**8*8/b/1e9:4.1f} GB/s")
    a,b,_=timed(lambda: np.sort(y))
    print(f"{'np.sort 100M float64':38} {a:8.3f} {b:8.3f}")
except ImportError as e: print("numpy unavailable:", e)
