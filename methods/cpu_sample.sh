#!/usr/bin/env bash
# cpu_sample.sh — Linux/bash twin of cpu_sample.ps1 (identical CSV schema)
# CPU column = % of one core averaged over all cores (same normalization as the PS twin)
# usage: cpu_sample.sh [out.csv] [interval_seconds]
set -u
CSV=${1:-cpu_sample.csv}; INTERVAL=${2:-2}
NPROC=$(nproc); CLK=$(getconf CLK_TCK)
echo "utc,chrome_cpu,brave_cpu,edge_cpu,firefox_cpu,net_rx_bytes_per_s" > "$CSV"

ticks() { # $1 = exact comm name -> sum(utime+stime) ticks over matching PIDs
  local t=0 f line comm rest
  for f in /proc/[0-9]*/stat; do
    [ -r "$f" ] || continue
    IFS= read -r line < "$f" 2>/dev/null || continue
    comm=${line#*(}; comm=${comm%)*}
    [ "$comm" = "$1" ] || continue
    rest=${line##*) }
    set -- $rest
    t=$(( t + ${12:-0} + ${13:-0} ))
  done
  echo "$t"
}

rxbytes() { # RX bytes summed over all interfaces except lo
  awk -F: 'NR>2 { if ($1 !~ /^ *lo$/) { split($2, a, " "); rx += a[1] } } END { printf "%.0f", rx+0 }' /proc/net/dev
}

declare -A PREV
PREVNET=$(rxbytes); PREVT=$(date +%s.%N)
while true; do
  sleep "$INTERVAL"
  NOWT=$(date +%s.%N); DT=$(awk -v a="$NOWT" -v b="$PREVT" 'BEGIN{printf "%.3f", a-b}')
  LINE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  for b in chrome brave msedge firefox; do
    T=$(ticks "$b")
    if [ -n "${PREV[$b]:-}" ]; then
      D=$(awk -v t="$T" -v p="${PREV[$b]}" -v dt="$DT" -v n="$NPROC" -v c="$CLK" \
          'BEGIN{ d=((t-p)/c)/dt*100/n; printf "%.1f", (d<0?0:d) }')
    else D="0.0"; fi
    PREV[$b]=$T; LINE="$LINE,$D"
  done
  N=$(rxbytes)
  ND=$(awk -v n="$N" -v p="$PREVNET" -v dt="$DT" 'BEGIN{ printf "%.0f", (n-p)/dt }')
  PREVNET=$N
  echo "$LINE,$ND" >> "$CSV"
  PREVT=$NOWT
done
