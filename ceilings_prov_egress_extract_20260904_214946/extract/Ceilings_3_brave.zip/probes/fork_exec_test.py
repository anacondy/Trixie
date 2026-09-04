import os, resource, time, subprocess

def say(*a):
    print(f"[{time.strftime('%H:%M:%S')}]", *a, flush=True)

soft, hard = resource.getrlimit(resource.RLIMIT_NPROC)
say(f"RLIMIT_NPROC: soft={soft} hard={hard}")
say(f"cgroup pids.max: {open('/sys/fs/cgroup/user/pids.max').read().strip()}")

uid = os.getuid()
def count_user_tasks():
    n = 0
    for p in os.listdir('/proc'):
        if not p.isdigit(): continue
        try:
            for t in os.listdir(f'/proc/{p}/task'):
                for line in open(f'/proc/{p}/task/{t}/status'):
                    if line.startswith('Uid:'):
                        if int(line.split()[1]) == uid: n += 1
                        break
        except Exception: pass
    return n

say(f"user tasks at start: {count_user_tasks()}")

children = []
t0 = time.time()
fail = None
try:
    while len(children) < 9000:
        try:
            p = subprocess.Popen(['sleep', '600'],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError as e:
            fail = (e.errno, e.strerror)
            say(f"SPAWN FAILED after {len(children)} children: errno {e.errno} ({e.strerror})")
            break
        children.append(p)
        if len(children) % 250 == 0:
            mc = int(open('/sys/fs/cgroup/user/memory.current').read()) // 1048576
            say(f"  {len(children)} children, {time.time()-t0:.1f}s, mem.current={mc} MiB, loadavg={open('/proc/loadavg').read().split()[0]}")
    if fail is None:
        say("reached safety cap 9000 without failure")
    say(f"PEAK: {len(children)} sleep children; user tasks approx {count_user_tasks()}")
    time.sleep(2)
finally:
    say(f"cleanup: terminating {len(children)} children")
    for p in children:
        try: p.kill()
        except Exception: pass
    gone = 0
    for p in children:
        try:
            p.wait(timeout=5); gone += 1
        except Exception:
            try: os.waitpid(p.pid, 0); gone += 1
            except Exception: pass
    say(f"reaped {gone}/{len(children)}, done")
