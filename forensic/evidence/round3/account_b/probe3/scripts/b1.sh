#!/bin/bash
# B1 discriminator: does OUR cpu load cause slow downloads, or is it confounded?
URL='https://speed.cloudflare.com/__down?bytes=33554432'
measure() {
  label="$1"
  t0=$(date +%s.%N)
  curl -s -o /dev/null --max-time 90 "$URL"
  rc=$?
  t1=$(date +%s.%N)
  d=$(echo "$t1 - $t0" | awk '{printf "%.3f", $1-$3}')
  mb=$(echo "33.554432 $d" | awk '{printf "%.2f", $1/$2}')
  echo "$label rc=$rc wall=${d}s effective_MBps=${mb}"
}
catcpu() { echo "  cpu.stat: $(grep -E 'usage_usec|nr_periods|nr_throttled|throttled_usec' /sys/fs/cgroup/user/cpu.stat | tr '\n' ' ')"; }
BURN=/home/user/probe3/scripts/burn.py

echo "== cpu.stat BEFORE =="; catcpu
echo "== warm-up download =="; curl -s -o /dev/null --max-time 60 "$URL"; echo "warmup rc=$?"
echo "== run 1: CPU idle =="; measure "idle_cpu_download"
echo "== cpu.stat after idle run =="; catcpu
echo "== starting 30s burn on both CPUs (background) =="
taskset -c 0 python3 "$BURN" 0 31 >/tmp/burn0.log 2>&1 &
P0=$!
taskset -c 1 python3 "$BURN" 1 31 >/tmp/burn1.log 2>&1 &
P1=$!
sleep 4
echo "== burners running; cpu.stat =="; catcpu
echo "== run 2: download WHILE both CPUs pegged =="; measure "cpu_pegged_download"
echo "== run 3: second download while still pegged =="; measure "cpu_pegged_download_2"
wait $P0 $P1 2>/dev/null
echo "== cpu.stat AFTER =="; catcpu
