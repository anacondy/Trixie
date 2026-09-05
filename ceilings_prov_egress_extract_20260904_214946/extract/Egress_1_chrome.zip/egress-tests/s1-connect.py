#!/usr/bin/env python3
"""Section 1: transparent-proxy behaviour — TCP connect() to unroutable addresses."""
import socket, time

TARGETS = [
    ("192.0.2.1", 9),      # TEST-NET-1  (RFC 5737)
    ("192.0.2.99", 9),     # TEST-NET-1
    ("198.51.100.10", 9),  # TEST-NET-2  (RFC 5737)
    ("203.0.113.77", 9),   # TEST-NET-3  (RFC 5737)
    ("10.255.255.1", 9),   # RFC1918 private
    ("100.64.0.1", 9),     # RFC 6598 CGNAT
]

print(f"{'target':<16} {'connect_ex':>10} {'elapsed_s':>10}  post-connect recv")
for ip, port in TARGETS:
    s = socket.socket()
    s.settimeout(2)
    t0 = time.perf_counter()
    rc = s.connect_ex((ip, port))
    dt = time.perf_counter() - t0
    try:
        s.settimeout(2)
        d = s.recv(64)
        r = f"{len(d)}B {d[:40]!r}"
    except socket.timeout:
        r = "no data (2s read timeout)"
    except OSError as e:
        r = f"{type(e).__name__}"
    s.close()
    print(f"{ip+':'+str(port):<16} {rc:>10} {dt:>10.3f}  {r}")

# IPv6 side-note
try:
    s6 = socket.socket(socket.AF_INET6); s6.settimeout(2)
    t0 = time.perf_counter()
    rc = s6.connect_ex(("2001:db8::1", 9))   # RFC 3849 doc range
    print(f"{'[2001:db8::1]:9':<16} {rc:>10} {time.perf_counter()-t0:>10.3f}  (IPv6)")
    s6.close()
except OSError as e:
    print(f"IPv6 socket/connect: {type(e).__name__}: {e}")
