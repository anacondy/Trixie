#!/usr/bin/env python3
"""Test 1 — Transparent-proxy behaviour on non-routable / reserved addresses."""
import socket, time, urllib.request

TARGETS = [
    ("192.0.2.1",    "RFC5737 TEST-NET-1 (192.0.2.0/24)"),
    ("198.51.100.1", "RFC5737 TEST-NET-2 (198.51.100.0/24)"),
    ("203.0.113.1",  "RFC5737 TEST-NET-3 (203.0.113.0/24)"),
    ("10.255.255.1", "RFC1918 private (10.0.0.0/8)"),
    ("100.64.0.1",   "RFC6598 CGNAT (100.64.0.0/10)"),
    ("1.1.1.1",      "CONTROL — real internet (Cloudflare)"),
    ("8.8.8.8",      "CONTROL — real internet (Google DNS)"),
]

def tcp_connect(ip, port, timeout=2.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    t0 = time.time()
    try:
        r = s.connect_ex((ip, port))
        dt = time.time() - t0
    except Exception as e:
        s.close()
        return {"res": f"ERR:{type(e).__name__}:{e}", "ms": (time.time()-t0)*1000}
    if r != 0:
        s.close()
        return {"res": f"{r}", "ms": dt*1000}
    banner = b""
    try:
        s.settimeout(2.0)
        banner = s.recv(128)
    except Exception:
        pass
    s.close()
    out = {"res": "0 (success)", "ms": dt*1000}
    if banner:
        out["banner"] = banner
    return out

def raw_http_get(ip, port=80, timeout=4.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((ip, port))
    except Exception as e:
        s.close()
        return f"connect ERR {type(e).__name__}: {e}"
    try:
        s.sendall(b"GET / HTTP/1.1\r\nHost: probe.test\r\nConnection: close\r\n\r\n")
        data = b""
        while len(data) < 400:
            try:
                chunk = s.recv(400 - len(data))
            except socket.timeout:
                break
            if not chunk:
                break
            data += chunk
        if not data:
            return "<no data within timeout>"
        return data[:280].decode("utf-8", "replace")
    except Exception as e:
        return f"recv ERR {type(e).__name__}: {e}"
    finally:
        s.close()

def urllib_get(url, timeout=6.0):
    t0 = time.time()
    try:
        r = urllib.request.urlopen(url, timeout=timeout)
        body = r.read(300)
        return f"HTTP {r.status} in {time.time()-t0:.2f}s body[:100]={body[:100]!r}"
    except Exception as e:
        return f"ERR {type(e).__name__}: {e} in {time.time()-t0:.2f}s"

print("=" * 80)
print("TEST 1 — TRANSPARENT-PROXY BEHAVIOUR (does connect() lie?)")
print("=" * 80)
for ip, label in TARGETS:
    print(f"\n[{label}]  {ip}")
    for port in (9, 80):
        r = tcp_connect(ip, port)
        extra = f"  banner={r['banner'][:60]!r}" if "banner" in r else ""
        print(f"  TCP connect_ex({ip},{port}) = {r['res']}  ({r['ms']:.1f} ms){extra}")

print("\n--- raw HTTP GET over the socket (port 80, Host: probe.test) ---")
for ip, label in TARGETS:
    print(f"  {ip:15s} {label:34s} -> {raw_http_get(ip, 80)}")

print("\n--- urllib HTTP GET (honours http_proxy/https_proxy env) ---")
for ip, label in TARGETS:
    print(f"  {ip:15s} {label:34s} -> {urllib_get('http://' + ip + '/')}")
