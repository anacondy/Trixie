import os,sys,resource
out=open('/home/user/envcheck/mem_progress.log','w',buffering=1)
lim=int(open('/sys/fs/cgroup/user/memory.max').read())
def cur(): return int(open('/sys/fs/cgroup/user/memory.current').read())
out.write(f"cgroup memory.max={lim/2**20:.0f} MiB, start current={cur()/2**20:.0f} MiB\n")
chunks=[]; step=128*1024*1024
try:
    for i in range(40):
        try:
            b=bytearray(step)
            for j in range(0,step,4096): b[j]=1   # touch every page so it's really charged
            chunks.append(b)
        except MemoryError:
            out.write(f"MemoryError at chunk {i} (allocated {len(chunks)*128} MiB)\n"); break
        out.write(f"  allocated {(i+1)*128:4d} MiB  | cgroup current {cur()/2**20:6.0f} MiB  | rss {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1024:.0f} MiB\n")
        if cur() > lim*0.92: out.write("  (approaching limit, stopping)\n"); break
except Exception as e:
    out.write(f"exception {e}\n")
out.write(f"FINAL: survived, allocated {len(chunks)*128} MiB\n"); out.close()
