#!/usr/bin/env python3
"""Sections 4: TCP + UDP port/protocol matrix. Reports handshake and data-received SEPARATELY."""
import socket, ssl, struct, time, json

def build_dns_query(name, qtype=1):
    qn = b"".join(bytes([len(p)]) + p.encode("ascii") for p in name.split(".")) + b"\x00"
    return struct.pack(">HHHHHH", 0x1234, 0x0100, 1, 0, 0, 0) + qn + struct.pack(">HH", qtype, 1)

DNS_POKE = struct.pack(">H", len(build_dns_query("example.com"))) + build_dns_query("example.com")
HTTP_POKE = b"HEAD / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n"
PG_SSLREQ = b"\x00\x00\x00\x08\x04\xd2\x16\x2f"   # PostgreSQL SSLRequest
REDIS_POKE = b"PING\r\n"

def tcp_probe(host, port, poke=None, tls=False, timeout=6, read_wait=4):
    out = {"target": f"{host}:{port}", "connect": None, "data": None, "t_connect": None}
    s = socket.socket(); s.settimeout(timeout)
    t0 = time.perf_counter()
    try:
        s.connect((host, port))
        out["connect"] = "SUCCESS"; out["t_connect"] = round(time.perf_counter() - t0, 3)
    except Exception as e:
        out["connect"] = f"{type(e).__name__}: {e}"; out["t_connect"] = round(time.perf_counter() - t0, 3)
        print(json.dumps(out)); return
    try:
        if tls:
            ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
            ts = ctx.wrap_socket(s, server_hostname=host)
            der = ts.getpeercert(True)
            out["data"] = f"TLS handshake ok, {len(der)}B cert received"
            ts.close()
        else:
            s.settimeout(read_wait)
            if poke:
                s.sendall(poke.replace(b"{host}", host.encode()) if b"{host}" in poke else poke)
            try:
                d = s.recv(512)
                out["data"] = f"{len(d)}B {d[:80]!r}" if d else "clean EOF / RST -> 0 bytes"
            except socket.timeout:
                out["data"] = f"no data within {read_wait}s"
            s.close()
    except Exception as e:
        out["data"] = f"{type(e).__name__}: {e}"
    print(json.dumps(out))

def udp_probe(host, port, payload, timeout=4):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(timeout)
    t0 = time.perf_counter()
    try:
        s.sendto(payload, (host, port))
        data, _ = s.recvfrom(2048)
        print(json.dumps({"target": f"udp {host}:{port}",
                          "result": f"REPLY {len(data)}B t={time.perf_counter()-t0:.3f}s"}))
    except socket.timeout:
        print(json.dumps({"target": f"udp {host}:{port}", "result": f"no reply in {timeout}s"}))
    except OSError as e:
        print(json.dumps({"target": f"udp {host}:{port}", "result": f"{type(e).__name__}: {e}"}))
    finally:
        s.close()

print("### TCP matrix (connect + data phase reported separately)")
PROBES = [
    # (host, port, poke, tls)
    ("scanme.nmap.org", 22, None, False),            # authorized test host, SSH banner
    ("github.com", 22, None, False),
    ("ftp.gnu.org", 21, None, False),
    ("gmail-smtp-in.l.google.com", 25, None, False), # MX banner
    ("8.8.8.8", 53, DNS_POKE, False),                # DNS over TCP
    ("example.com", 80, HTTP_POKE, False),
    ("scanme.nmap.org", 80, HTTP_POKE, False),
    ("pop.gmail.com", 110, None, False),
    ("imap.gmail.com", 143, None, False),
    ("pypi.org", 443, None, True),
    ("smtp.gmail.com", 465, None, True),             # implicit TLS
    ("smtp.gmail.com", 587, None, False),            # STARTTLS banner
    ("imap.gmail.com", 993, None, True),
    ("pop.gmail.com", 995, None, True),
    ("db4free.net", 3306, None, False),              # MySQL greeting
    ("1.1.1.1", 5432, PG_SSLREQ, False),             # closed-port comparator
    ("8.8.8.8", 6379, REDIS_POKE, False),            # closed-port comparator
    ("cloudflare.com", 8080, HTTP_POKE, False),      # CF edge serves 8080 for proxied zones
    ("cloudflare.com", 8443, None, True),            # CF edge serves 8443 for proxied zones
    ("192.0.2.1", 443, None, False),                 # BASELINE: guaranteed-unreachable
    ("192.0.2.1", 3306, None, False),                # BASELINE: guaranteed-unreachable
]
for h, p, poke, tls in PROBES:
    tcp_probe(h, p, poke=poke, tls=tls)

print("\n### UDP matrix")
ntp = b"\x1b" + b"\x00" * 47
garbage = bytes(64)
UDP_PROBES = [
    ("8.8.8.8", 53, build_dns_query("example.com")),      # valid DNS query
    ("1.1.1.1", 53, build_dns_query("example.com")),      # valid DNS query
    ("8.8.8.8", 123, ntp),                                 # 8.8.8.8 does not run NTP -> no reply expected
    ("1.1.1.1", 123, ntp),                                 # 1.1.1.1 does not run NTP -> no reply expected
    ("162.159.200.1", 123, ntp),                           # time.cloudflare.com CONTROL (does run NTP)
    ("8.8.8.8", 443, garbage),                             # QUIC-ish; no valid packet -> no reply expected
    ("1.1.1.1", 443, garbage),
    ("8.8.8.8", 500, garbage),                             # IKE; no reply expected
    ("8.8.8.8", 1, garbage),                               # closed port -> ICMP unreachable if ICMP passes
]
for h, p, pay in UDP_PROBES:
    udp_probe(h, p, pay)
