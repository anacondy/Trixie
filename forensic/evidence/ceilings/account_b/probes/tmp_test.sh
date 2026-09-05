#!/bin/bash
echo "=== /tmp mount ==="; df -T /tmp; mount | grep 'on /tmp '
memavail() { grep MemAvailable /proc/meminfo | awk '{print $2/1024" MiB"}'; }
shm=$(awk '/Shmem/{print $2/1024" MiB"}' /proc/meminfo)
echo "BEFORE: MemAvailable=$(memavail)  Shmem=$shm  free=$(free -m | awk '/Mem:/{print $4}')"
echo "--- writing 900 MiB of /dev/urandom to /tmp (tmpfs) ---"
t0=$(date +%s%N)
dd if=/dev/urandom of=/tmp/probe_900m.bin bs=1M count=900 2>/tmp/tmperr
t1=$(date +%s%N)
grep copied /tmp/tmperr
python3 -c "w=($t1-$t0)/1e9; print(f'dd wall={w:.2f}s -> {900/w:.0f} MiB/s')"
sync
echo "DURING (900 MiB resident): MemAvailable=$(memavail)  Shmem=$(awk '/Shmem/{print $2/1024\" MiB\"}' /proc/meminfo)  free=$(free -m | awk '/Mem:/{print $4}')"
df -h /tmp
echo "--- removing file ---"
rm -f /tmp/probe_900m.bin /tmp/tmperr; sync
sleep 1
echo "AFTER:  MemAvailable=$(memavail)  Shmem=$(awk '/Shmem/{print $2/1024\" MiB\"}' /proc/meminfo)"
echo "=== TMP TEST COMPLETE ==="
