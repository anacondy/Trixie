#!/usr/bin/env python3
"""Test 4 — TCP/UDP port & protocol matrix. Handshake vs data, reported separately."""
import socket, ssl, struct, random, time

TCP_HOST = "1.1.1.1"
TCP_PORTS = [21, 22, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995, 3306, 5432, 6379, 8080, 8443]

def dns_query_bytes(name="cloudflare.com", qtype=1):
    tid = random.randint(0, 0xFFFF)
    hdr = struct.pack(">HHHHHH", tid, 0x0100, 1, 0, 0, 0)
    q = b"".join(bytes([len(l)]) + l.encode() for l in name.split(".")) + b"\x00"
    q += struct.pack(">HH", qtype, 1)
    return hdr + q

def tcp_probe(host, port, timeout=3.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    t0 = time.time()
    try:
        r = s.connect_ex((host, port))
    except Exception as e:
        s.close()
        return f"no handshake (ERR {type(e).__name__})", "-", "-"
    if r != 0:
        s.close()
        return f"no handshake (rc={r})", "-", f"{(time.time()-t0)*1000:.0f} ms"
    hs = f"handshake OK ({(time.time()-t0)*1000:.0f} ms)"
    try:
        s.settimeout(3.0)
        if port == 80:
            s.sendall(b"GET / HTTP/1.1\r\nHost: one.one.one.one\r\nConnection: close\r\n\r\n")
        elif port == 53:
            q = dns_query_bytes()
            s.sendall(struct.pack(">H", len(q)) + q)
        elif port == 443:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            t1 = time.time()
            try:
                ss = ctx.wrap_socket(s, server_hostname="one.one.one.one")
                return hs, f"TLS {ss.version()} OK ({(time.time()-t1)*1000:.0f} ms)", ""
            except Exception as e:
                return hs, f"TLS ERR {type(e).__name__}: {e}", ""
        data = s.recv(512)
        if data:
            return hs, f"data: {len(data)}B {data[:28]!r}", ""
        return hs, "no data (closed, no banner)", ""
    except socket.timeout:
        return hs, "NO DATA (recv timeout)", ""
    except Exception as e:
        return hs, f"ERR {type(e).__name__}: {e}", ""
    finally:
        try:
            s.close()
        except Exception:
            pass

def udp_probe(host, port, timeout=2.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    if port == 53:
        payload = dns_query_bytes("example.com")
    elif port == 123:
        payload = bytes([0x1B]) + b"\x00" * 47
    else:
        payload = b"\x00" * 32
    try:
        s.sendto(payload, (host, port))
        try:
            data, addr = s.recvfrom(1024)
            if port == 53 and len(data) >= 4:
                return f"response {len(data)}B (DNS rcode={data[3] & 0x0F})"
            return f"response {len(data)}B"
        except socket.timeout:
            return "no response (timeout)"
    except Exception as e:
        return f"ERR {type(e).__name__}: {e}"
    finally:
        s.close()

print("=" * 80)
print(f"TCP matrix -> {TCP_HOST}")
print("=" * 80)
print(f"{'port':<6} | {'handshake':<26} | {'data':<45}")
print("-" * 82)
for p in TCP_PORTS:
    hs, data, _ = tcp_probe(TCP_HOST, p)
    print(f"{p:<6} | {hs:<26} | {data:<45}")

print()
print("TCP control -> 8.8.8.8 (ports 53, 80, 443)")
for p in (53, 80, 443):
    hs, data, _ = tcp_probe("8.8.8.8", p)
    print(f"{p:<6} | {hs:<26} | {data:<45}")

print()
print("=" * 80)
print("UDP matrix")
print("=" * 80)
print(f"{'target':<10} | {'port':<5} | {'result'}")
print("-" * 50)
for host, ports in [("8.8.8.8", [53, 123, 443, 500]), ("1.1.1.1", [53, 123, 443, 500])]:
    for p in ports:
        print(f"{host:<10} | {p:<5} | {udp_probe(host, p)}")
