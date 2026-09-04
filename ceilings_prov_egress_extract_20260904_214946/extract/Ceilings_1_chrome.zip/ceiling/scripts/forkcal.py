import os, time, signal, subprocess, sys

def spawn_kid():
    pid = os.fork()
    if pid == 0:
        os.setsid()
        signal.pause()

kids = []
t0 = time.time()
marks = []
for i in range(100):
    kids.append(spawn_kid())
    if (i + 1) % 10 == 0: marks.append(round(time.time() - t0, 2))
dtA = time.time() - t0
print(f"A: 100 sequential forks in {dtA:.2f}s -> {dtA:.2f} s/fork; cumulative marks every 10: {marks}", flush=True)
for p in kids:
    os.kill(p, signal.SIGKILL)
for p in kids:
    os.waitpid(p, 0)
print("A cleaned", flush=True)

worker = '''import os, time, signal, sys
kids = []
t0 = time.time()
for i in range(25):
    pid = os.fork()
    if pid == 0:
        os.setsid(); signal.pause()
    kids.append(pid)
print(round(time.time() - t0, 3), flush=True)
with open("/home/user/ceiling/out/forkcal_pids.txt", "a") as f:
    f.write(" ".join(map(str, kids)) + "\\n")
time.sleep(3600)
'''
procs = [subprocess.Popen([sys.executable, "-c", worker], stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, text=True) for _ in range(4)]
t0 = time.time()
outs = [p.stdout.readline().strip() for p in procs]
dtB = time.time() - t0
print(f"B: 4 parallel workers x 25 forks: wall={dtB:.2f}s, workers took {outs}s -> {100/dtB:.1f} forks/s aggregate", flush=True)
pids = []
for line in open("/home/user/ceiling/out/forkcal_pids.txt"):
    pids += line.split()
for p in pids:
    try: os.kill(int(p), signal.SIGKILL)
    except (ProcessLookupError, ValueError): pass
for p in procs: p.kill()
for p in procs: p.wait()
print("B cleaned", flush=True)
