import os, resource, time
def rl(): return resource.getrlimit(resource.RLIMIT_NOFILE)
print("whoami:", os.popen("whoami").read().strip())
print("start rlimit:", rl())
print("nr_open:", open('/proc/sys/fs/nr_open').read().strip())
print("fs.file-max:", open('/proc/sys/fs/file-max').read().strip())
print("-- phase A: inherit soft limit, open fds until EMFILE --")
fds=[]; n=0; t0=time.time()
try:
    while True:
        fds.append(os.open("/dev/null", os.O_RDONLY)); n+=1
except OSError as e:
    print("phaseA: opened %d fds, then %r (%.2fs)" % (n, e, time.time()-t0))
for f in fds: os.close(f)
print("-- phase B: raise soft->hard (child of this shell; rlimit is per-process) --")
soft, hard = rl()
os.setrlimit(resource.RLIMIT_NOFILE, (hard, hard))
print("after raise:", rl())
fds=[]; n=0; t0=time.time()
try:
    while True:
        fds.append(os.open("/dev/null", os.O_RDONLY)); n+=1
except OSError as e:
    print("phaseB: opened %d fds, then %r (%.2fs)" % (n, e, time.time()-t0))
print("phaseB result: %d fds opened with hard limit %d" % (n, hard))
print("open fds now:", len(os.listdir('/proc/self/fd')))
for f in fds[:50]: os.close(f)
