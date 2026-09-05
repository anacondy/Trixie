import os, resource, time

def say(*a):
    msg = ' '.join(str(x) for x in a)
    print(msg, flush=True)

soft, hard = resource.getrlimit(resource.RLIMIT_NPROC)
say(f"RLIMIT_NPROC: soft={soft} hard={hard}")
say(f"kernel pid_max: {open('/proc/sys/kernel/pid_max').read().strip()}")
say(f"cgroup pids.max: {open('/sys/fs/cgroup/user/pids.max').read().strip()}")

uid = os.getuid()
n_tasks = 0
for p in os.listdir('/proc'):
    if not p.isdigit():
        continue
    try:
        for t in os.listdir(f'/proc/{p}/task'):
            for line in open(f'/proc/{p}/task/{t}/status'):
                if line.startswith('Uid:'):
                    if int(line.split()[1]) == uid:
                        n_tasks += 1
                    break
    except Exception:
        pass
say(f"current tasks (threads) owned by uid {uid}: {n_tasks}")

children = []
t0 = time.time()
fail = None
try:
    while len(children) < 20000:
        try:
            pid = os.fork()
        except OSError as e:
            fail = (e.errno, e.strerror)
            say(f"FORK FAILED after {len(children)} children: errno {e.errno} ({e.strerror}), elapsed {time.time()-t0:.1f}s")
            break
        if pid == 0:
            try:
                import ctypes
                ctypes.CDLL(None).prctl(1, 9)  # PR_SET_PDEATHSIG -> SIGKILL if parent dies
            except Exception:
                pass
            import signal
            signal.pause()      # sleep in kernel; PDEATHSIG/parent SIGKILL releases us
            os._exit(0)
        children.append(pid)
        if len(children) % 250 == 0:
            say(f"  ...{len(children)} children alive, {time.time()-t0:.1f}s elapsed")
            time.sleep(0.2)
    if fail is None:
        say("reached safety cap 20000 without failure")
    say(f"PEAK child count: {len(children)}; peak user tasks approx: {n_tasks + len(children)}")
finally:
    say(f"cleanup: killing {len(children)} children...")
    for pid in children:
        try: os.kill(pid, 9)
        except ProcessLookupError: pass
    reaped = 0
    for pid in children:
        try:
            os.waitpid(pid, 0); reaped += 1
        except ChildProcessError: pass
    say(f"reaped {reaped} children, cleanup done")
