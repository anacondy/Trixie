import sys, time, os
cpu = int(sys.argv[1])
secs = float(sys.argv[2])
os.sched_setaffinity(0, {cpu})
end = time.time() + secs
x = 0
while time.time() < end:
    x = (x + 1) % 1000000007
print(x)
