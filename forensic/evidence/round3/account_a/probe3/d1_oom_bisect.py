#!/usr/bin/env python3
"""D1: bisect the cgroup OOM ceiling using allocate-and-touch in a SUBPROCESS.
Step halves until <=32 MiB. Child prints MiB touched then exits 0. Parent records exit code."""
import subprocess, sys, os, time, textwrap

CG = "/sys/fs/cgroup/user"
def ev():
    d={}
    for line in open(f"{CG}/memory.events"):
        k,v=line.split(); d[k]=v
    return d
def cur():
    return int(open(f"{CG}/memory.current").read().strip())

CHILD = textwrap.dedent('''
    import sys
    mib = int(sys.argv[1])
    chunk = 1024*1024           # 1 MiB
    blocks = []
    for i in range(mib):
        b = bytearray(chunk)
        for j in range(0, chunk, 4096):
            b[j] = (i+j) & 0xFF     # TOUCH every page
        blocks.append(b)
    print("TOUCHED_MiB", mib, flush=True)
''')

def trial(mib):
    p = subprocess.run([sys.executable,"-c",CHILD,str(mib)],
                       capture_output=True, text=True, timeout=300)
    return p.returncode, p.stdout.strip(), p.stderr.strip().splitlines()[-1:] 

lo, hi = 256, 2048      # MiB brackets: 256 known-safe? test first
print("== D1 OOM bisect, cgroup /user memory.max =", open(f"{CG}/memory.max").read().strip(), flush=True)
print("memory.events BEFORE:", ev(), flush=True)
print("memory.current BEFORE:", cur(), flush=True)
# establish bracket
step = 256
mib = 256
last_ok = None; first_kill = None
while True:
    rc,out,err = trial(mib)
    print(f"  trial {mib} MiB -> rc={rc} out={out!r} err={err}", flush=True)
    if rc == 0:
        last_ok = mib
        mib += step
        if mib > 4096:
            print("  (no kill by 4 GiB, stopping coarse phase)"); break
    else:
        first_kill = mib
        break
print(f"coarse bracket: last_ok={last_ok} MiB, first_kill={first_kill} MiB", flush=True)
# bisect to <=32 MiB
if first_kill is not None and last_ok is not None:
    while first_kill - last_ok > 32:
        step = max(32, (first_kill-last_ok)//2)
        mid = last_ok + step
        rc,out,err = trial(mid)
        print(f"  bisect {mid} MiB -> rc={rc} out={out!r} err={err}", flush=True)
        if rc == 0: last_ok = mid
        else: first_kill = mid
print(f"RESULT last_success={last_ok} MiB  first_kill={first_kill} MiB  resolution={first_kill-last_ok} MiB", flush=True)
print("memory.events AFTER:", ev(), flush=True)
print("memory.current AFTER:", cur(), flush=True)
