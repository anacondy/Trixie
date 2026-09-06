import sys, time, os
# Allocate `mib` MiB, touch every page, report RSS. Exit 0 if survived.
mib = int(sys.argv[1])
size = mib * 1048576
b = bytearray(size)
step = 4096
for i in range(0, size, step):
    b[i] = 0x5A
# force read-sum over touched pages so RSS is fully accounted
s = 0
for i in range(0, size, step):
    s += b[i]
rss = 0
with open('/proc/self/status') as f:
    for line in f:
        if line.startswith('VmRSS:'):
            rss = line.split()[1]
print(f"SURVIVED mib={mib} len={size} checksum={s} VmRSS_kB={rss}", flush=True)
time.sleep(0.2)
