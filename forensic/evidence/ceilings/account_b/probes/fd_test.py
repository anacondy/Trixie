import os, resource, sys, time

soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
print(f"RLIMIT_NOFILE: soft={soft} hard={hard}", flush=True)

def open_loop(cap):
    fds = []
    t = time.time()
    try:
        while len(fds) < cap:
            fds.append(os.open('/dev/null', os.O_RDONLY))
    except OSError as e:
        print(f"  -> open FAILED after {len(fds)} fds: errno {e.errno} ({e.strerror}), {time.time()-t:.2f}s", flush=True)
    else:
        print(f"  -> reached cap {cap} without failure", flush=True)
    n = len(fds)
    for fd in fds:
        os.close(fd)
    return n

mode = sys.argv[1] if len(sys.argv) > 1 else 'soft'
if mode == 'soft':
    print("phase A: default soft limit, opening /dev/null in a loop:", flush=True)
    open_loop(200000)
else:
    target = int(sys.argv[2])
    try:
        resource.setrlimit(resource.RLIMIT_NOFILE, (target, hard))
        s, h = resource.getrlimit(resource.RLIMIT_NOFILE)
        print(f"setrlimit OK -> soft={s} hard={h}", flush=True)
    except (ValueError, OSError) as e:
        print(f"setrlimit to {target} FAILED: {e}", flush=True); sys.exit(1)
    print(f"phase B: soft raised to {target}, opening loop:", flush=True)
    open_loop(target + 100000)
