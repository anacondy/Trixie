import os, signal, sys, time
path = "/home/user/ceiling/out/fork_pids.txt"
if not os.path.exists(path):
    print("no pid file"); sys.exit(0)
killed = 0
for line in open(path):
    line = line.strip()
    if not line: continue
    try:
        os.kill(int(line), signal.SIGKILL); killed += 1
    except ProcessLookupError: pass
    except ValueError: pass
print("sent SIGKILL to", killed, "recorded pids")
time.sleep(1)
