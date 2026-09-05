#!/usr/bin/env python3
"""Section 7 / unanswered - gap-closing probes: ICMP, IPv6, MTU, concurrency headroom."""
import socket, os, time
from concurrent.futures import ThreadPoolExecutor

print("=== ICMP ===")
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    print("  RAW ICMP socket OPENED (CAP_NET_RAW present)")
except Exception as e:
    print(f"  RAW ICMP socket: {type(e).__name__}: {e} -> ICMP untestable as uid 1000")

print("=== IPv6 ===")
try:
    inf = socket.getaddrinfo("google.com", 443, socket.AF_INET6)
    print("  AAAA resolved:", sorted({i[4][0] for i in inf})[:4])
except Exception as e:
    print("  AAAA resolve:", e)
for t in [("2001:4860:4860::8888", 53), ("2606:4700:4700::1111", 53),
          ("2400:cb00:2048:1::6810:7b2c", 443)]:
    s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM); s.settimeout(3)
    try: print(f"  IPv6 {t[0]}:{t[1]} connect_rc={s.connect_ex(t)}")
    except Exception as e: print(f"  IPv6 {t[0]}:{t[1]} {type(e).__name__}: {e}")
    s.close()

print("=== concurrency headroom: 100 parallel TCP to pypi.org:443 ===")
def c(i):
    try:
        s = socket.create_connection(("pypi.org", 443), timeout=10); s.close(); return True
    except Exception as e:
        return f"{type(e).__name__}"
t0 = time.perf_counter()
with ThreadPoolExecutor(max_workers=100) as ex: r = list(ex.map(c, range(100)))
ok = sum(1 for x in r if x is True)
print(f"  {ok}/100 succeeded in {time.perf_counter()-t0:.2f}s  failures: {set(x for x in r if x is not True)}")
