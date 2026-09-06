import subprocess, sys, time, threading
LIMIT = int(open('/sys/fs/cgroup/user/memory.max').read())
def cur(): return int(open('/sys/fs/cgroup/user/memory.current').read())
child = ("import sys\nn=int(sys.argv[1])\nb=bytearray(n)\n"
         "for i in range(0,n,4096): b[i]=1\nprint('TOUCHED_OK size=%d' % n)\n")
def trial(n, sample=True):
    peak=[0]; stop=[False]
    p=subprocess.Popen([sys.executable,'-c',child,str(n)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    def samp():
        while not stop[0]:
            c=cur()
            if c>peak[0]: peak[0]=c
            time.sleep(0.005)
    t=threading.Thread(target=samp); t.start()
    out,err=p.communicate(timeout=300)
    stop[0]=True; t.join()
    return p.returncode, out.decode().strip()[-80:], err.decode().strip()[-80:], peak[0]
print("memory.max =", LIMIT, "=", LIMIT/1048576, "MiB")
# continued bisect from first pass: low ok=1703776256, high kill=1764625408
low, high = 1703776256, 1764625408
steps=0
while high - low > 32*1024*1024:
    mid=(low+high)//2
    rc,out,err,peak = trial(mid)
    steps+=1
    print("step%d size=%d (%.2f MiB) rc=%s peak_memcurrent=%d (%.1f MiB) out=%s" %
          (steps, mid, mid/1048576, rc, peak, peak/1048576, out[:30]))
    if rc==0: low=mid
    else: high=mid
print("FINAL last_ok=%d (%.3f MiB) first_kill=%d (%.3f MiB) gap=%.1f MiB" % (low, low/1048576, high, high/1048576, (high-low)/1048576))
# two confirmatory runs at the final bounds
rc,out,err,peak = trial(low);  print("confirm last_ok  rc=%s peak=%.1f MiB" % (rc, peak/1048576))
rc,out,err,peak = trial(high); print("confirm first_kill rc=%s peak=%.1f MiB" % (rc, peak/1048576))
print("events after:"); print(open('/sys/fs/cgroup/user/memory.events').read())
print("session alive: yes, this shell still running; current=%.1f MiB" % (cur()/1048576))
