#!/bin/bash
{
echo "### Disk benchmarks (dd, 200MB, fsync where noted)"
for loc in /home/user/envcheck /tmp; do
  echo "--- $loc  (fs: $(stat -f -c '%T' $loc))"
  echo -n "  write 200MB (fdatasync):  "; dd if=/dev/zero of=$loc/dd.img bs=1M count=200 conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
  sync
  echo -n "  read 200MB (page cache):  "; dd if=$loc/dd.img of=/dev/null bs=1M 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
  echo -n "  read 200MB (O_DIRECT):    "; dd if=$loc/dd.img of=/dev/null bs=1M iflag=direct 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
  echo -n "  write 200MB (O_DIRECT):   "; dd if=/dev/zero of=$loc/dd2.img bs=1M count=200 oflag=direct conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [kMG]?B/s' | tail -1
  rm -f $loc/dd.img $loc/dd2.img
done
echo
echo "### Small-file ops on ext4 (/home/user/envcheck)"
mkdir -p /home/user/envcheck/manysmall
python3 - <<'PYEOF'
import os, time
N = 20000
d = "/home/user/envcheck/manysmall"
t0 = time.perf_counter()
for i in range(N):
    with open(f"{d}/f{i}", "w") as f: f.write(str(i))
t1 = time.perf_counter()
print(f"create+write {N} small files : {t1-t0:.2f}s  ({N/(t1-t0):.0f} files/s)")
t0 = time.perf_counter(); n = 0
for i in range(N):
    with open(f"{d}/f{i}") as f: n += len(f.read())
t1 = time.perf_counter()
print(f"read {N} small files          : {t1-t0:.2f}s  ({N/(t1-t0):.0f} files/s, {n} bytes)")
t0 = time.perf_counter()
for i in range(N): os.unlink(f"{d}/f{i}")
t1 = time.perf_counter()
print(f"delete {N} small files        : {t1-t0:.2f}s  ({N/(t1-t0):.0f} files/s)")
os.rmdir(d)
PYEOF
echo
echo "### inode state after test"
df -i /home/user | tail -1
}