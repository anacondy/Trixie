import os,time,json,statistics,subprocess,hashlib,pathlib,gc,resource,platform
OUT=pathlib.Path('/home/user/envchar_work')
results=[]; notes=[]
def add(name,seconds,units,amount,detail,result=None):
    rec={'benchmark':name,'seconds':seconds,'amount':amount,'units':units,'rate_per_second':(amount/seconds if seconds else None),'detail':detail}
    if result is not None: rec['result']=result
    results.append(rec)

notes.append(f'timestamp={time.strftime("%Y-%m-%dT%H:%M:%S%z")}')
notes.append(f'python={platform.python_version()} implementation={platform.python_implementation()}')
notes.append('loadavg_before='+pathlib.Path('/proc/loadavg').read_text().strip())
try:
    before=sorted(os.sched_getaffinity(0)); os.sched_setaffinity(0,{before[0]}); after=sorted(os.sched_getaffinity(0))
    notes.append(f'CPU affinity before={before}; pinned benchmark process to={after}')
except Exception as e: notes.append(f'CPU affinity pin failed: {type(e).__name__}: {e}')

# Required built-in sum benchmark, five independent runs.
sum_times=[]; expected=49_999_995_000_000
for i in range(5):
    t=time.perf_counter_ns(); val=sum(range(10**7)); sec=(time.perf_counter_ns()-t)/1e9
    if val!=expected: raise RuntimeError((val,expected))
    sum_times.append(sec)
add('CPython sum(range(10**7)) median',statistics.median(sum_times),'integers',10_000_000,f'5 runs; individual_s={[round(x,9) for x in sum_times]}; process pinned to one vCPU',val)

# Explicit interpreter-level arithmetic loop, three runs of ten million iterations.
loop_times=[]; vals=[]
for rep in range(3):
    acc=0; t=time.perf_counter_ns()
    for i in range(10_000_000):
        acc=(acc + (i ^ (i >> 3))) & 0xffffffffffffffff
    sec=(time.perf_counter_ns()-t)/1e9; loop_times.append(sec);vals.append(acc)
if len(set(vals))!=1: raise RuntimeError(vals)
add('CPython explicit integer loop median',statistics.median(loop_times),'iterations',10_000_000,f'3 runs; per iteration: shift, XOR, add, mask; individual_s={[round(x,9) for x in loop_times]}; one vCPU',vals[0])

# NumPy vector operation if present.
try:
    import numpy as np
    np_times=[]; np_val=None
    a=np.arange(10_000_000,dtype=np.int64)
    for rep in range(3):
        t=time.perf_counter_ns(); np_val=int(np.sum((a*a)%97)); sec=(time.perf_counter_ns()-t)/1e9; np_times.append(sec)
    add('NumPy vector expression median',statistics.median(np_times),'elements',len(a),f'numpy={np.__version__}; sum((a*a)%97), preallocated input, 3 runs; individual_s={[round(x,9) for x in np_times]}',np_val)
    del a;gc.collect()
except Exception as e: notes.append(f'NumPy benchmark failed: {type(e).__name__}: {e}')

# Sequential filesystem benchmark: 100 MiB, 4 MiB chunks, fsync included.
path=OUT/'disk_benchmark_100MiB.tmp'; total=100*1024*1024; chunk=os.urandom(4*1024*1024); count=total//len(chunk)
try:
    t=time.perf_counter_ns()
    with open(path,'wb',buffering=0) as f:
        for _ in range(count): f.write(chunk)
        os.fsync(f.fileno())
    sec=(time.perf_counter_ns()-t)/1e9
    add('ext4 sequential write + fsync',sec,'bytes',total,'/home/user, 100 MiB, repeated random 4 MiB block, unbuffered Python writes; includes final fsync')
    st=path.stat(); notes.append(f'disk_file size={st.st_size} blocks_512={st.st_blocks}')

    # Ask kernel to evict this file from page cache; advisory, not guaranteed.
    advise_note=''
    try:
        fd=os.open(path,os.O_RDONLY); os.posix_fadvise(fd,0,0,os.POSIX_FADV_DONTNEED); os.close(fd); advise_note='POSIX_FADV_DONTNEED issued before read'
    except Exception as e: advise_note=f'fadvise unavailable/failed: {e}'
    buf=bytearray(4*1024*1024); view=memoryview(buf); seen=0
    t=time.perf_counter_ns()
    with open(path,'rb',buffering=0) as f:
        while True:
            n=f.readinto(view)
            if not n: break
            seen += n
    sec=(time.perf_counter_ns()-t)/1e9
    add('ext4 sequential read (cache-drop advisory)',sec,'bytes',seen,f'/home/user, 100 MiB, 4 MiB readinto; {advise_note}')

    # Immediate second read is expected to benefit from page cache.
    seen2=0;t=time.perf_counter_ns()
    with open(path,'rb',buffering=0) as f:
        while True:
            n=f.readinto(view)
            if not n: break
            seen2 += n
    sec=(time.perf_counter_ns()-t)/1e9
    add('ext4 sequential read (warm page cache)',sec,'bytes',seen2,'immediate second read, 4 MiB readinto')

    # Linux direct I/O read, independently timed. Does not use page cache; dd itself reports success/failure.
    for rep in range(2):
        t=time.perf_counter_ns()
        p=subprocess.run(['dd',f'if={path}','of=/dev/null','bs=4M','iflag=direct','status=none'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        sec=(time.perf_counter_ns()-t)/1e9
        if p.returncode==0: add(f'ext4 direct-I/O sequential read run {rep+1}',sec,'bytes',total,'dd bs=4M iflag=direct; process-launch overhead included')
        else: notes.append(f'direct I/O read {rep+1} failed rc={p.returncode} stderr={p.stderr!r}')
finally:
    try:path.unlink()
    except FileNotFoundError:pass

notes.append('loadavg_after='+pathlib.Path('/proc/loadavg').read_text().strip())
notes.append(f'maxrss_process_KiB={resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}')
OUT.joinpath('microbenchmark_results.json').write_text(json.dumps(results,indent=2))
OUT.joinpath('microbenchmark_notes.txt').write_text('\n'.join(notes)+'\n')
print(json.dumps(results,indent=2));print('\n'.join(notes))
