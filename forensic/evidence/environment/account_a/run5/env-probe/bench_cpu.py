#!/usr/bin/env python3
"""
bench_cpu.py - CPU / numpy / pandas microbenchmarks for env_probe.sh
Method: time.perf_counter(), best-of-N. All timings in milliseconds.
Emits raw numbers only - no interpretation.
"""
import time, statistics, json, hashlib, re, platform, sys


def bench(label, fn, reps=3):
    ts = []
    for _ in range(reps):
        t0 = time.perf_counter()
        fn()
        ts.append(time.perf_counter() - t0)
    print(f"{label:44s} best={min(ts)*1000:10.2f} ms  median={statistics.median(ts)*1000:10.2f} ms  n={reps}")
    return min(ts)


print(f"python={platform.python_version()} impl={platform.python_implementation()} exe={sys.executable}")
print(f"perf_counter resolution={time.get_clock_info('perf_counter').resolution:g} s")
print()
print("=== PURE PYTHON ===")


def loop():
    x = 0
    for i in range(10**7):
        x += i * i
    return x


def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)


bench("sum(range(10**7))", lambda: sum(range(10**7)))
bench("pure-python loop 10**7 (x+=i*i)", loop)
bench("recursive fib(27)", lambda: fib(27))

d = [{"a": i, "b": "x" * 20, "c": [1, 2, 3]} for i in range(50000)]
s = json.dumps(d)
bench("json.dumps 50k dicts", lambda: json.dumps(d))
bench("json.loads 50k dicts", lambda: json.loads(s))

buf = b"a" * (10 * 1024 * 1024)
bench("sha256 of 10 MiB", lambda: hashlib.sha256(buf).hexdigest())
txt = "hello world foo bar " * 50000
bench("regex findall on 1M chars", lambda: re.findall(r"\w+o\w*", txt))

print()
print("=== NUMPY (BLAS-backed) ===")
try:
    import numpy as np
    print(f"numpy={np.__version__}")
    try:
        from threadpoolctl import threadpool_info
        for i in threadpool_info():
            print(f"  BLAS: api={i.get('internal_api')} threads={i.get('num_threads')} layer={i.get('threading_layer')}")
    except Exception:
        print("  (threadpoolctl unavailable)")

    a = np.random.rand(1000, 1000); b = np.random.rand(1000, 1000)
    t = bench("numpy 1000x1000 matmul float64", lambda: a @ b)
    print(f"{'':44s}  -> {2*1000**3/t/1e9:.1f} GFLOP/s")
    a2 = np.random.rand(2000, 2000); b2 = np.random.rand(2000, 2000)
    t = bench("numpy 2000x2000 matmul float64", lambda: a2 @ b2, reps=2)
    print(f"{'':44s}  -> {2*2000**3/t/1e9:.1f} GFLOP/s")
    v = np.random.rand(10**7)
    bench("numpy sum 1e7 float64", lambda: v.sum())
    bench("numpy sort 1e7 float64", lambda: np.sort(v), reps=2)
    bench("numpy FFT 2**22", lambda: np.fft.fft(np.random.rand(2**22)), reps=2)
except ImportError as e:
    print("numpy unavailable:", e)

print()
print("=== PANDAS ===")
try:
    import pandas as pd, numpy as np
    print(f"pandas={pd.__version__}")
    df = pd.DataFrame({
        "a": np.random.rand(10**6),
        "b": np.random.randint(0, 100, 10**6),
        "c": np.random.choice(list("abcde"), 10**6),
    })
    bench("pandas groupby.mean 1e6 rows", lambda: df.groupby("c", observed=True)["a"].mean())
    bench("pandas sort_values 1e6 rows", lambda: df.sort_values("a"))
    bench("pandas to_csv 1e6 rows", lambda: df.to_csv("/tmp/_probe_bench.csv", index=False), reps=1)
    bench("pandas read_csv 1e6 rows", lambda: pd.read_csv("/tmp/_probe_bench.csv"), reps=2)
    try:
        bench("pandas to_parquet 1e6 rows", lambda: df.to_parquet("/tmp/_probe_bench.pq"), reps=1)
        bench("pandas read_parquet 1e6 rows", lambda: pd.read_parquet("/tmp/_probe_bench.pq"), reps=2)
    except Exception as e:
        print(f"{'parquet':44s} UNAVAILABLE ({type(e).__name__}: pyarrow/fastparquet missing)")
    import os
    for f in ("/tmp/_probe_bench.csv", "/tmp/_probe_bench.pq"):
        if os.path.exists(f):
            os.remove(f)
except ImportError as e:
    print("pandas unavailable:", e)

print()
print("=== PARALLEL SCALING (multiprocessing) ===")
import multiprocessing as mp, os


def work(n):
    x = 0
    for i in range(n):
        x += i * i
    return x


if __name__ == "__main__":
    N = 8_000_000
    for procs in (1, 2, 4):
        t0 = time.perf_counter()
        with mp.Pool(procs) as p:
            p.map(work, [N] * procs)
        el = time.perf_counter() - t0
        print(f"{procs} proc x {N:,} iters: {el:6.3f} s  aggregate={procs*N/el/1e6:7.2f} M-iter/s")
    print(f"cpu_count={mp.cpu_count()}  sched_affinity={len(os.sched_getaffinity(0))}")
