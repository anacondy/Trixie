import time,statistics,json,hashlib,re
def bench(label,fn,reps=3):
    ts=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); ts.append(time.perf_counter()-t0)
    print(f"{label:44s} best={min(ts)*1000:9.1f} ms  median={statistics.median(ts)*1000:9.1f} ms")
def loop():
    x=0
    for i in range(10**7): x+=i*i
    return x
def fib(n): return n if n<2 else fib(n-1)+fib(n-2)
bench("sum(range(10**7))", lambda: sum(range(10**7)))
bench("pure-python loop 10**7 (x+=i*i)", loop)
bench("recursive fib(27)", lambda: fib(27))
d=[{"a":i,"b":"x"*20,"c":[1,2,3]} for i in range(50000)]
s=json.dumps(d)
bench("json.dumps 50k dicts", lambda: json.dumps(d))
bench("json.loads 50k dicts", lambda: json.loads(s))
buf=b"a"*(10*1024*1024)
bench("sha256 of 10 MiB", lambda: hashlib.sha256(buf).hexdigest())
txt="hello world foo bar "*50000
bench("regex findall on 1M chars", lambda: re.findall(r"\w+o\w*", txt))
print()
import numpy as np
print("numpy", np.__version__, "| threads via BLAS below")
a=np.random.rand(1000,1000); b=np.random.rand(1000,1000)
bench("numpy 1000x1000 matmul (float64)", lambda: a@b)
a2=np.random.rand(2000,2000); b2=np.random.rand(2000,2000)
bench("numpy 2000x2000 matmul (float64)", lambda: a2@b2, reps=2)
v=np.random.rand(10**7)
bench("numpy sum 1e7 float64", lambda: v.sum())
bench("numpy sort 1e7 float64", lambda: np.sort(v), reps=2)
bench("numpy FFT 2^22", lambda: np.fft.fft(np.random.rand(2**22)), reps=2)
print()
import pandas as pd
df=pd.DataFrame({'a':np.random.rand(10**6),'b':np.random.randint(0,100,10**6),'c':np.random.choice(list('abcde'),10**6)})
bench("pandas groupby.mean 1e6 rows", lambda: df.groupby('c',observed=True)['a'].mean())
bench("pandas sort_values 1e6 rows", lambda: df.sort_values('a'))
bench("pandas to_csv 1e6 rows", lambda: df.to_csv('/tmp/_bench.csv',index=False), reps=1)
bench("pandas read_csv 1e6 rows", lambda: pd.read_csv('/tmp/_bench.csv'), reps=2)
