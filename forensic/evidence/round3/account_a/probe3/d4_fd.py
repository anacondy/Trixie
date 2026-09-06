import resource, os, sys, subprocess
def open_until_fail():
    r0 = resource.getrlimit(resource.RLIMIT_NOFILE)
    fds=[]; e=None
    try:
        while True:
            fds.append(os.open("/dev/null", os.O_RDONLY))
    except OSError as ex:
        e = ex
    n=len(fds)
    for f in fds: os.close(f)
    return r0, n, e
r0,n,e = open_until_fail()
print("parent soft/hard RLIMIT_NOFILE =", r0)
print("parent max simultaneously open /dev/null fds =", n, "(process starts with 3: stdin/out/err)")
print("failure was:", type(e).__name__ if e else None, getattr(e,'errno',None), getattr(e,'strerror',None))
child = '''
import resource, os
r0 = resource.getrlimit(resource.RLIMIT_NOFILE)
try:
    resource.setrlimit(resource.RLIMIT_NOFILE, (r0[1], r0[1]))
    ok = resource.getrlimit(resource.RLIMIT_NOFILE)
    fds=[]
    err=None
    try:
        while True: fds.append(os.open("/dev/null", os.O_RDONLY))
    except OSError as ex: err=ex
    print("CHILD inherited soft/hard =", r0, "-> after setrlimit(soft:=hard) =", ok)
    print("CHILD max simultaneously open fds =", len(fds), "failure:", type(err).__name__, err.errno, err.strerror)
except Exception as ex:
    print("CHILD setrlimit FAILED:", type(ex).__name__, ex)
'''
out = subprocess.run([sys.executable,"-c",child],capture_output=True,text=True)
print(out.stdout.strip() or out.stderr.strip())
try:
    resource.setrlimit(resource.RLIMIT_NOFILE, (r0[1]+1, r0[1]+1))
    print("raising ABOVE hard limit: SUCCEEDED (unexpected - would mean no cap)")
except Exception as ex:
    print("raising ABOVE hard limit fails as expected:", type(ex).__name__, ex)
print("ulimit -n soft/hard from shell:", subprocess.run(["bash","-c","ulimit -Sn; ulimit -Hn"],capture_output=True,text=True).stdout.replace("\n"," / "))
print("/proc/sys/fs/file-max =", open("/proc/sys/fs/file-max").read().strip())
print("openable? /proc/sys/fs/nr_open =", open("/proc/sys/fs/nr_open").read().strip())
