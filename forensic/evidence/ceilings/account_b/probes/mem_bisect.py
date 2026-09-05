import subprocess, sys, time

# Child: allocate n MiB and TOUCH one byte per page (4096 B) so pages are committed.
CODE = ('import sys;n=int(sys.argv[1]);'
        'b=bytearray(n*1024*1024);'
        'b[::4096]=bytes(len(b[::4096]));'
        'print("ok",n,flush=True)')

def read(path):
    try:
        with open(path) as f: return f.read().strip()
    except Exception as e:
        return f'<{e}>'

def memavail_kb():
    for l in open('/proc/meminfo'):
        if l.startswith('MemAvailable'): return int(l.split()[1])

def probe(n):
    t = time.time()
    try:
        p = subprocess.run([sys.executable, '-c', CODE, str(n)],
                           capture_output=True, text=True, timeout=180)
        dt = time.time() - t
        return p.returncode, (p.stdout.strip() + ' | ' + p.stderr.strip()[-160:]), dt
    except subprocess.TimeoutExpired:
        return 'TIMEOUT', '', time.time() - t

print('=== memory.events BEFORE ===')
print(read('/sys/fs/cgroup/user/memory.events'))
print(f"memory.current BEFORE: {read('/sys/fs/cgroup/user/memory.current')} B")
print(f"MemAvailable BEFORE: {memavail_kb()} kB\n")

log = []
print(f"{'MiB':>6} {'rc':>7} {'sec':>7}  phase   result")
sys.stdout.flush()

# Phase 1: linear scan in 128 MiB steps, starting at 256
last_ok, first_fail = None, None
n = 256
while n <= 4096:
    rc, out, dt = probe(n)
    phase = 'scan'
    ok = (rc == 0)
    log.append((n, rc, dt, 'scan'))
    print(f"{n:>6} {str(rc):>7} {dt:>7.2f}  {phase:6}  {'OK' if ok else 'FAIL'}  {out}")
    sys.stdout.flush()
    if ok: last_ok = n
    else:  first_fail = n; break
    n += 128

# Phase 2: bisection to +/-32 MiB
lo, hi = last_ok, first_fail
while hi - lo > 32:
    mid = ((lo + hi) // 2 // 32) * 32
    if mid <= lo: mid = lo + 32
    rc, out, dt = probe(mid)
    ok = (rc == 0)
    log.append((mid, rc, dt, 'bisect'))
    print(f"{mid:>6} {str(rc):>7} {dt:>7.2f}  bisect  {'OK' if ok else 'FAIL'}  {out}")
    sys.stdout.flush()
    if ok: lo = mid
    else:  hi = mid

print(f"\n=== RESULT: last success = {lo} MiB, first kill = {hi} MiB (gap {hi-lo} MiB) ===")
print('\n=== memory.events AFTER ===')
print(read('/sys/fs/cgroup/user/memory.events'))
print(f"memory.current AFTER: {read('/sys/fs/cgroup/user/memory.current')} B")
print(f"MemAvailable AFTER: {memavail_kb()} kB")
