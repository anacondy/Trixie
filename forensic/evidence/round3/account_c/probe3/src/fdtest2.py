import resource, os, time
print("python", os.sys.version.split()[0])
print("os.setrlimit present:", hasattr(os, "setrlimit"))
print("resource.setrlimit present:", hasattr(resource, "setrlimit"))
def drive(label):
    fds=[]; n=0; t0=time.time()
    try:
        while True:
            fds.append(os.open("/dev/null", os.O_RDONLY)); n+=1
    except OSError as e:
        dt=time.time()-t0
        print("%s: opened %d fds in %.2fs then %r" % (label, n, dt, e))
        return n
    finally:
        for f in fds: os.close(f)
print("start rlimit:", resource.getrlimit(resource.RLIMIT_NOFILE))
drive("phaseA(soft inherited)")
r = resource.getrlimit(resource.RLIMIT_NOFILE)
try:
    resource.setrlimit(resource.RLIMIT_NOFILE, (r[1], r[1]))
    print("raised to hard:", resource.getrlimit(resource.RLIMIT_NOFILE))
    drive("phaseB(soft=hard)")
except OSError as e:
    print("setrlimit failed: %r" % e)
