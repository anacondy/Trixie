#!/bin/bash
# B1 discriminator: measure ACTUAL cpu busy-ness during the download, not load average.
read a b c d e f g h i j k <<< "$(grep '^cpu ' /proc/stat)"
idle0=$((e+f)); tot0=$((a+b+c+d+e+f+g+h+i+j+k))
t0=$(date +%s.%N)
curl -sS -m 60 -o /dev/null -w 'DURING_BURN: size=%{size_download} ttfb=%{time_starttransfer} total=%{time_total} speed=%{speed_download} B/s\n' 'https://speed.cloudflare.com/__down?bytes=50000000'
t1=$(date +%s.%N)
read a b c d e f g h i j k <<< "$(grep '^cpu ' /proc/stat)"
idle1=$((e+f)); tot1=$((a+b+c+d+e+f+g+h+i+j+k))
echo "window=$(echo "$t1-$t0"|bc)s  cpu_busy_pct=$(python3 -c "print('%.1f'%(100*(1-($idle1-$idle0)/max(1,($tot1-$tot0)))))")  (2 vCPUs => 100% = both fully busy)"
echo "cpu.stat: $(grep -E 'usage_usec|throttled_usec|nr_throttled' /sys/fs/cgroup/user/cpu.stat | tr '\n' ' ')"
