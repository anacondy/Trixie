import os, time, statistics
MB=1024*1024
def bench(path, size_mb=100, chunk=4*MB):
    res={}
    payload=os.urandom(chunk)
    # --- buffered write ---
    t0=time.perf_counter(); fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o644)
    for _ in range(size_mb*1024*1024//chunk): os.write(fd,payload)
    tw=os.time=None
    res['write_buffered']=(time.perf_counter()-t0)
    # --- fsync cost ---
    t0=time.perf_counter(); os.fsync(fd); res['fsync']=time.perf_counter()-t0
    os.close(fd)
    sz=os.path.getsize(path)
    # --- cached read ---
    t0=time.perf_counter(); fd=os.open(path,os.O_RDONLY); n=0
    while True:
        b=os.read(fd,chunk)
        if not b: break
        n+=len(b)
    res['read_cached']=time.perf_counter()-t0; os.close(fd)
    # --- mmap read + checksum (touches all pages) ---
    import mmap, hashlib
    t0=time.perf_counter(); fd=os.open(path,os.O_RDONLY); m=mmap.mmap(fd,0,access=mmap.ACCESS_READ); h=hashlib.sha256(m).hexdigest(); m.close(); os.close(fd)
    res['mmap_sha256']=time.perf_counter()-t0
    # --- small file rewrite (fsync per file) ---
    os.unlink(path)
    return res, sz, n, h[:12]

for label,d in [("ext4 /home/user","/home/user/envcheck"),("tmpfs /tmp","/tmp"),("tmpfs /dev/shm","/dev/shm")]:
    print(f"\n### {label} ({d})")
    allr=[]
    for rep in range(3):
        r,sz,n,h = bench(f"{d}/bench_{os.getpid()}.bin")
        allr.append(r)
    print(f"  size on disk: {sz/MB:.0f} MB, read back {n/MB:.0f} MB, sha256[:12]={h}")
    for k in allr[0]:
        ts=[r[k] for r in allr]; med=statistics.median(ts)
        thr=sz/1e6/med if k!='fsync' else None
        print(f"  {k:16} med={med*1000:8.1f} ms  (min {min(ts)*1000:7.1f} / max {max(ts)*1000:7.1f})" + (f"  = {thr:6.0f} MB/s" if thr else ""))

print("\n### Many-small-files (relevant for shard-heavy pipelines)")
for label,d in [("ext4 /home/user/envcheck","/home/user/envcheck/small"),("tmpfs /tmp/small","/tmp/small")]:
    os.makedirs(d,exist_ok=True)
    t0=time.perf_counter()
    for i in range(2000):
        with open(f"{d}/f{i:05d}.dat","wb") as f: f.write(b"x"*1024)
    t1=time.perf_counter()
    tot=0
    for i in range(2000):
        with open(f"{d}/f{i:05d}.dat","rb") as f: tot+=len(f.read())
    t2=time.perf_counter()
    # fsync-per-file variant (100 files)
    t3=time.perf_counter()
    for i in range(100):
        fd=os.open(f"{d}/s{i:03d}.dat",os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o644); os.write(fd,b"y"*1024); os.fsync(fd); os.close(fd)
    t4=time.perf_counter()
    print(f"  {label:28} write 2000x1KB: {t1-t0:6.3f}s ({2000/(t1-t0):6.0f} files/s) | read: {t2-t1:6.3f}s | write+fsync 100 files: {t4-t3:6.3f}s ({(t4-t3)/100*1000:5.1f} ms/op)")
    import shutil; shutil.rmtree(d)
