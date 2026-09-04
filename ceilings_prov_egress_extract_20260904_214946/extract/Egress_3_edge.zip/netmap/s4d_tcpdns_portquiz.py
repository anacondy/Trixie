#!/usr/bin/env python3
"""Section 4 - fixes: (a) TCP DNS on :53/:853 after the s4_ports.py probe bug,
   (b) portquiz.net run SEQUENTIALLY (the concurrent run hit the host's rate limiting)."""
import socket, struct, random, time, json

def q(name="google.com"):
    tid = random.randint(0, 65535)
    qq = b''.join(bytes([len(x)]) + x.encode() for x in name.split('.')) + b'\x00'
    return struct.pack('>HHHHHH', tid, 0x0100, 1, 0, 0, 0) + qq + struct.pack('>HH', 1, 1)

print("=== TCP DNS ===")
for host in ["8.8.8.8", "1.1.1.1", "9.9.9.9"]:
    for port in (53, 853):
        try:
            s = socket.create_connection((host, port), timeout=6)
            p = q("google.com"); s.sendall(struct.pack('>H', len(p)) + p)
            n = struct.unpack('>H', s.recv(2))[0]; d = s.recv(n)
            print(f"  {host}:{port}  TCP DNS OK  rcode={d[3] & 0xF}  bytes={len(d)}")
            s.close()
        except Exception as e:
            print(f"  {host}:{port}  {type(e).__name__}: {str(e)[:70]}")

print("=== portquiz.net SEQUENTIAL (17 ports) ===")
PORTS = [21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,6379,8080,8443]
ip = socket.gethostbyname("portquiz.net"); print("portquiz.net ->", ip)
res = []
for p in PORTS:
    s = socket.socket(); s.settimeout(5)
    t0 = time.perf_counter()
    try: rc = s.connect_ex((ip, p))
    except Exception: rc = -1
    hs = round((time.perf_counter() - t0) * 1000, 1)
    ok = False; dms = None; snip = ""
    if rc == 0:
        t1 = time.perf_counter()
        try:
            s.sendall(b"GET / HTTP/1.1\r\nHost: portquiz.net\r\nConnection: close\r\n\r\n")
            d = s.recv(200); dms = round((time.perf_counter() - t1) * 1000, 1)
            ok = len(d) > 0; snip = d.split(b"\r\n")[0].decode("utf8", "replace")
        except Exception as e: snip = type(e).__name__
    s.close()
    res.append({"port": p, "hs": rc == 0, "hs_ms": hs, "data": ok, "data_ms": dms, "snip": snip})
    print(f"  {p:>6d} handshake={rc == 0!s:5s} {hs:>5.1f}ms  data={ok!s:5s} {str(dms):>7s}ms  {snip}")
json.dump(res, open("results/s4_portquiz.json", "w"), indent=1)
