#!/usr/bin/env python3
"""Test 3 — IP / SNI-level filtering (decisive)."""
import socket, ssl, time, struct, random

HOSTS = ["pypi.org", "github.com", "raw.githubusercontent.com", "huggingface.co", "google.com"]

def build_query(name, qtype=1):
    tid = random.randint(0, 0xFFFF)
    header = struct.pack(">HHHHHH", tid, 0x0100, 1, 0, 0, 0)
    q = b""
    for label in name.rstrip(".").split("."):
        q += bytes([len(label)]) + label.encode("ascii")
    q += b"\x00" + struct.pack(">HH", qtype, 1)
    return header + q

def skip_name(data, off):
    while True:
        ln = data[off]
        if ln == 0:
            return off + 1
        if ln & 0xC0 == 0xC0:
            return off + 2
        off += 1 + ln

def udp_query(server, name, timeout=3.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    try:
        s.sendto(build_query(name), (server, 53))
        resp, _ = s.recvfrom(4096)
        tid, flags, qd, an, ns, ar = struct.unpack(">HHHHHH", resp[:12])
        rcode = flags & 0x0F
        off = 12
        ips = []
        for _ in range(qd):
            off = skip_name(resp, off) + 4
        for _ in range(an):
            off = skip_name(resp, off)
            typ, cls, ttl, rdlen = struct.unpack(">HHIH", resp[off:off+10])
            off += 10
            rdata = resp[off:off+rdlen]
            off += rdlen
            if typ == 1 and rdlen == 4:
                ips.append(".".join(map(str, rdata)))
        return f"rcode={rcode}", ips
    except socket.timeout:
        return "TIMEOUT", []
    except Exception as e:
        return f"ERR:{type(e).__name__}", []
    finally:
        s.close()

def getaddrinfo_a(name):
    try:
        infos = socket.getaddrinfo(name, None, socket.AF_INET)
        return "ok", sorted({i[4][0] for i in infos})
    except Exception as e:
        return f"{type(e).__name__}: {e}", []

def tls_to(ip, hostname, port=443, timeout=6.0):
    t0 = time.time()
    try:
        s = socket.create_connection((ip, port), timeout=timeout)
    except Exception as e:
        return f"TCP ERR {type(e).__name__}: {e} ({(time.time()-t0)*1000:.0f}ms)"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    try:
        ss = ctx.wrap_socket(s, server_hostname=hostname)
        cert = ss.getpeercert() or {}
        san = cert.get("subjectAltName", ())
        names = [v for k, v in san if k == "DNS"][:3]
        return f"TLS OK {ss.version()} ({(time.time()-t0)*1000:.0f}ms) SAN={names}"
    except Exception as e:
        return f"TLS ERR {type(e).__name__}: {e} ({(time.time()-t0)*1000:.0f}ms)"
    finally:
        try:
            s.close()
        except Exception:
            pass

def http_to_ip(ip, host, port=80, timeout=6.0):
    t0 = time.time()
    try:
        s = socket.create_connection((ip, port), timeout=timeout)
    except Exception as e:
        return f"TCP ERR {type(e).__name__}: {e} ({(time.time()-t0)*1000:.0f}ms)"
    try:
        s.settimeout(timeout)
        s.sendall(f"GET / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n".encode())
        data = b""
        while len(data) < 120:
            c = s.recv(120 - len(data))
            if not c:
                break
            data += c
        return f"HTTP {data[:70]!r}"
    except Exception as e:
        return f"HTTP ERR {type(e).__name__}: {e} ({(time.time()-t0)*1000:.0f}ms)"
    finally:
        s.close()

for h in HOSTS:
    print("=" * 80)
    print(f"HOST: {h}")
    sstat, sips = getaddrinfo_a(h)
    rstat, rips = udp_query("8.8.8.8", h)
    print(f"  system resolver   : {sstat} {sips[:4]}")
    print(f"  @8.8.8.8 (ground) : {rstat} {rips[:4]}")
    print(f"  TLS by hostname   : {tls_to(h, h)}")
    for ip in rips[:2]:
        print(f"  TLS to {ip:15s} SNI={h:<28s}: {tls_to(ip, h)}")
    for ip in rips[:1]:
        print(f"  HTTP to {ip:15s} Host={h:<28s}: {http_to_ip(ip, h)}")
