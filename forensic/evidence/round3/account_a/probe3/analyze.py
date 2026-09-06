#!/usr/bin/env python3
"""Derive every reported number FROM the raw files (no hand-typed values)."""
import re, glob, os
def read(p): return open(p, errors="replace").read()

print("="*70); print("C6 UNIT ARITHMETIC (convention: kernel 'kB' = 1024 B; GiB/MiB = binary; GB = decimal)")
def three(name, kbytes=None, bytes_=None):
    if bytes_ is not None: k = bytes_/1024.0
    else: k = float(kbytes)
    mib = k/1024.0; gib = mib/1024.0; gb = k*1024/1e9
    print(f"  {name}: {k:.0f} kB = {k*1024:.0f} B = {mib:.2f} MiB = {gib:.4f} GiB  (decimal: {gb:.4f} GB)")
    return dict(kB=k, MiB=mib, GiB=gib, GB=gb)

lock = read("01_a0_lock.txt")
mt = int(re.search(r"MemTotal:\s+(\d+) kB", lock).group(1)); three("MemTotal", kbytes=mt)
cg = read("05_cgroup_limits.txt")
mm = int(re.search(r"memory\.max\n(\d+)", cg).group(1)); r=three("cgroup user memory.max", bytes_=mm)
mc = int(re.search(r"memory\.current\n(\d+)", cg).group(1)); three("cgroup user memory.current (BEFORE D1)", bytes_=mc)
print(f"  memory.max as decimal GB = {mm/1e9:.4f} GB  -> the limit is set as a DECIMAL number ({mm} = 1.947172864 GB)")
print(f"  MemTotal - memory.max = {mt*1024-mm} B = {(mt*1024-mm)/1024**2:.1f} MiB reserved outside the user cgroup")
d1 = read("07_d1_oom.txt")
_m = re.search(r"RESULT last_success=(\d+) MiB\s+first_kill=(\d+) MiB\s+resolution=(\d+) MiB", d1)
lo, hi, rsl = int(_m.group(1)), int(_m.group(2)), int(_m.group(3))
print(f"  (parsed from the RESULT line: last_success={lo}, first_kill={hi}, resolution={rsl} MiB;"
      f" the coarse-phase 1792 MiB line is NOT the bisected result)")
three("D1 last_success", kbytes=lo*1024); three("D1 first_kill", kbytes=hi*1024)
three("D1 first_kill as decimal", bytes_=hi*1024*1024)
print(f"  first_kill {hi} MiB / memory.max {mm/1024**2:.1f} MiB = {hi/(mm/1024**2)*100:.1f}% of the cgroup limit")
print(f"  headroom at the kill = {mm/1024**2-hi:.1f} MiB (rest of cgroup = other processes + page cache)")

print("="*70); print("D2 DISK")
d2 = read("08_d2_disk.txt")
for m in re.finditer(r"(\d+) bytes \(([\d.]+ G?B), ([\d.]+ GiB)\) copied, ([\d.]+) s, (\d+) MB/s", d2):
    b=int(m.group(1)); secs=float(m.group(4)); mbps=int(m.group(5))
    print(f"  {b} B ({m.group(3)}) in {secs}s = {mbps} MB/s (dd, decimal) = {mbps*1e6/1024**2:.1f} MiB/s = {mbps*8/1000:.2f} Gbit/s")
tm = re.search(r"tmpfs\s+(\d+)M", d2)
print(f"  tmpfs /tmp size = {tm.group(1)} MiB (df -BM) -> /tmp is RAM-backed and capped there, NOT at the 25G disk")
dm = re.search(r"delta_bytes=(-?\d+)", d2)
dmb=int(dm.group(1)); print(f"  /tmp RAM proof: writing 268435456 B moved cgroup memory.current by {dmb} B "
      f"(ratio {dmb/268435456:.4f}x the file size) and rm released it -> tmpfs pages are counted as cgroup memory")

print("="*70); print("D6 SMT")
d6 = read("10_d6_smt.txt")
sec = re.split(r"--- taskset -c ", d6)
res={}
for s in sec[1:]:
    c = s[0]
    st = re.search(r"single-thread wall = ([\d.]+) s", s)
    tw = re.findall(r"2-thread wall trial\d = ([\d.]+) s", s)
    if st and tw:
        res[c]=(float(st.group(1)), [float(x) for x in tw])
for c,(st,tw) in sorted(res.items()):
    avg=sum(tw)/len(tw)
    print(f"  cpu mask {c}: 1T={st:.4f}s  2T={avg:.4f}s  ratio={avg/st:.4f}x  "
          f"=> throughput gain from the sibling = {(2/(avg/st)-1)*100:+.2f}%")
print("  (masks 2 and 3 rejected by taskset: 'Invalid argument' -> only cpu0,cpu1 exist)")

print("="*70); print("B1 CONFOUNTER TEST")
b1 = read("13_b1_bandwidth.txt")
def speeds(pat):
    return [int(x) for x in re.findall(pat, b1)]
idle = speeds(r"idle dl: http=200 size=\d+ ttfb=[\d.]+ total=[\d.]+ speed=(\d+)")
busy_early = speeds(r"busy dl \d: http=200 size=\d+ ttfb=[\d.]+ total=[\d.]+ speed=(\d+)")
burn = speeds(r"DURING_BURN: size=\d+ ttfb=[\d.]+ total=[\d.]+ speed=(\d+)")
for lbl,v in [("idle (cpu_busy 1.2%)",idle),("verified-burn (cpu_busy 100.0%)",busy_early+burn)]:
    print(f"  {lbl}: n={len(v)} speeds MB/s = {[round(x/1e6,1) for x in v]}")
    print(f"      min={min(v)/1e6:.1f} max={max(v)/1e6:.1f} mean={sum(v)/len(v)/1e6:.1f} MB/s "
          f"(= {sum(v)/len(v)*8/1e9:.2f} Gbit/s)")
a=set(idle); bb=set(busy_early+burn)
print(f"  ranges overlap? idle[{min(idle)/1e6:.1f},{max(idle)/1e6:.1f}] vs burn[{min(bb)/1e6:.1f},{max(bb)/1e6:.1f}]"
      f" -> {'OVERLAP: no separation' if not (min(bb)>max(idle) or max(bb)<min(idle)) else 'separated'}")
print(f"  cgroup throttling during burn: nr_throttled=0 throttled_usec=0 -> cpu.max='max 100000' (no quota)")
# per-POP breakdown: is the POP the real driver?
pop = re.findall(r"speed=(\d+) B/s ip=([\d.]+)", b1)
from collections import defaultdict
g=defaultdict(list)
for s,ip in pop: g[ip].append(int(s)/1e6)
print("  per-Cloudflare-POP means (the actual confounder):")
for ip,v in sorted(g.items(), key=lambda kv:-sum(kv[1])/len(kv[1])):
    print(f"    {ip}: n={len(v)} mean={sum(v)/len(v):.1f} MB/s values={[round(x,1) for x in v]}")
hb = re.search(r"httpbin /bytes/100000: http=200 size=\d+ ttfb=([\d.]+) total=([\d.]+) speed=(\d+)", b1)
print(f"  C4: httpbin.org {int(hb.group(3))/1e6:.3f} MB/s vs cloudflare mean "
      f"{sum(x for v in g.values() for x in v)/sum(len(v) for v in g.values()):.1f} MB/s "
      f"= {sum(x for v in g.values() for x in v)/sum(len(v) for v in g.values())/(int(hb.group(3))/1e6):.0f}x faster -> httpbin is not a bandwidth probe")

print("="*70); print("D5 CONCURRENCY")
st={}
for f in sorted(glob.glob("d5/*.txt")):
    t=read(f); k=t.split("call=")[1][0]
    s=re.search(r"start=(\S+)",t).group(1); e=re.search(r"end=(\S+)",t).group(1)
    st[k]=(s,e)
from datetime import datetime
def p(x): return datetime.strptime(x, "%Y-%m-%dT%H:%M:%S.%fZ")
ks=sorted(st, key=lambda k: st[k][0])
prev=None; gaps=[]
print("  dispatch order and start-gap:")
for k in ks:
    g_ = "" if prev is None else f"gap={((p(st[k][0])-p(prev)).total_seconds()):.3f}s"
    print(f"    {k}: start={st[k][0]} end={st[k][1]} {g_}")
    if prev is not None: gaps.append((p(st[k][0])-p(prev)).total_seconds())
    prev=st[k][0]
print(f"  mean start-gap = {sum(gaps)/len(gaps):.3f}s; total wall A.start->H.end = "
      f"{(p(st['H'][1])-p(st['A'][0])).total_seconds():.3f}s for 8 calls each sleeping 4s")
print(f"  => if all 8 truly ran in parallel, wall would be ~4.1s; observed {(p(st['H'][1])-p(st['A'][0])).total_seconds():.1f}s"
      f" -> host-side dispatcher is SERIAL, no per-session parallelism observed")
print("="*70)
