#!/bin/bash
EP="https://speed.cloudflare.com/__down?bytes=100000000"
FMT='%{size_download} %{speed_download} %{time_total} %{time_connect} %{time_starttransfer} %{http_code}'
run_seq () {
  curl -s -o /dev/null --max-time 300 -w "$FMT\n" "$EP"
}
echo "=== SEQUENTIAL (3 runs, one at a time) ==="
for i in 1 2 3; do printf "seq-%d: " $i; run_seq; done
echo
echo "=== PARALLEL (3 concurrent runs) ==="
for i in 1 2 3; do ( printf "par-%d: " $i; curl -s -o /dev/null --max-time 300 -w "$FMT\n" "$EP" ) & done
wait
echo
echo "=== AGGREGATE PARALLEL THROUGHPUT (3 concurrent, total wall time) ==="
S=$(date +%s.%N)
for i in 1 2 3; do curl -s -o /dev/null --max-time 300 "$EP" & done
wait
E=$(date +%s.%N)
python3 -c "d=$E-$S;print(f'  3x100MB in {d:.2f}s -> aggregate {300*8/d:.1f} Mbit/s  ({300/d:.1f} MB/s)')"
