import subprocess, sys, time, os
LIMIT = int(open('/sys/fs/cgroup/user/memory.max').read())
def cur():
    return int(open('/sys/fs/cgroup/user/memory.current').read())
child = ("import sys\n"
         "n=int(sys.argv[1])\n"
         "b=bytearray(n)\n"
         "for i in range(0,n,4096): b[i]=1\n"
         "print('TOUCHED_OK size=%d' % n)\n")
def trial(n):
    t0=time.time()
    p=subprocess.run([sys.executable,'-c',child,str(n)],capture_output=True,timeout=240)
    dt=time.time()-t0
    out=p.stdout.decode().strip()[-200:]; err=p.stderr.decode().strip()[-200:]
    return p.returncode, out, err, dt, cur()
print("memory.max bytes =", LIMIT)
print("memory.max MiB =", LIMIT/1048576)
print("start memory.current =", cur())
low, high = 0, LIMIT   # low must survive, high must die
# establish high
rc,out,err,dt,c = trial(high)
print("probe high=%d -> rc=%s out=%r err=%r dt=%.2fs" % (high, rc, out[-60:], err[-60:], dt))
if rc == 0:
    print("WARNING: maximum allocation survived; ceiling above limit?")
    sys.exit(0)
import math
steps=0
while high - low > 64*1024*1024:
    mid=(low+high)//2
    rc,out,err,dt,c = trial(mid)
    steps+=1
    print("step %d mid=%d (%.1f MiB) rc=%s out=%r dt=%.2fs memcur_before≈%d" % (steps, mid, mid/1048576, rc, out[:40], dt, c))
    if rc == 0: low = mid
    else: high = mid
print("FINAL low(ok)=%d (%.3f MiB)  high(kill)=%d (%.3f MiB)  gap=%d MiB" % (low, low/1048576, high, high/1048576, (high-low)/1048576))
print("final memory.current =", cur())
