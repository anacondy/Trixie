#!/usr/bin/env python3
"""Test 2 — DNS-level filtering. System resolver vs 8.8.8.8 vs 1.1.1.1 vs default-ns."""
import socket, struct, random, re, time
from collections import Counter

HOSTS = [
    "google.com", "pypi.org", "files.pythonhosted.org", "registry.npmjs.org",
    "github.com", "raw.githubusercontent.com", "huggingface.co", "openai.com",
    "api.anthropic.com", "pastebin.com", "transfer.sh", "ngrok.io",
    "webhook.site", "1.1.1.1.xip.io",
]

RCODE = {0:"NOERROR",1:"FORMERR",2:"SERVFAIL",3:"NXDOMAIN",4:"NOTIMP",5:"REFUSED"}

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

def parse(data):
    if len(data) < 12:
        return "short", []
    tid, flags, qd, an, ns, ar = struct.unpack(">HHHHHH", data[:12])
    rcode = flags & 0x0F
    a_records = []
    off = 12
    try:
        for _ in range(qd):
            off = skip_name(data, off) + 4
        for _ in range(an):
            off = skip_name(data, off)
            typ, cls, ttl, rdlen = struct.unpack(">HHIH", data[off:off+10])
            off += 10
            rdata = data[off:off+rdlen]
            off += rdlen
            if typ == 1 and rdlen == 4:
                a_records.append(".".join(map(str, rdata)))
    except Exception as e:
        return f"parse-err {e}", a_records
    return RCODE.get(rcode, str(rcode)), a_records

def udp_query(server, name, timeout=2.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    t0 = time.time()
    try:
        s.sendto(build_query(name), (server, 53))
        resp, _ = s.recvfrom(4096)
        status, a = parse(resp)
        return f"{status} ({(time.time()-t0)*1000:.0f}ms)", a
    except socket.timeout:
        return "TIMEOUT", []
    except Exception as e:
        return f"ERR:{type(e).__name__}", []
    finally:
        s.close()

def getaddrinfo_a(name):
    t0 = time.time()
    try:
        infos = socket.getaddrinfo(name, None, socket.AF_INET)
        ips = sorted({i[4][0] for i in infos})
        return f"NOERROR ({(time.time()-t0)*1000:.0f}ms)", ips
    except socket.gaierror as e:
        return f"gaierror:{e}", []
    except Exception as e:
        return f"ERR:{type(e).__name__}", []

def read_resolv():
    try:
        return re.findall(r"^\s*nameserver\s+(\S+)", open("/etc/resolv.conf").read(), re.M)
    except Exception as e:
        return [f"ERR:{e}"]

def show(stat, ips):
    ipstr = ",".join(ips[:3])
    return f"{stat} [{ipstr}]"

def main():
    ns = read_resolv()
    print("resolv.conf nameservers:", ns)
    print()
    hdr = f"{'host':<24} | {'system':<34} | {'@8.8.8.8':<30} | {'@1.1.1.1':<30} | {'@default-ns':<30}"
    print(hdr)
    print("-" * len(hdr))
    def_ns = ns[0] if ns and not ns[0].startswith("ERR") else None
    for h in HOSTS:
        sys = getaddrinfo_a(h)
        g = udp_query("8.8.8.8", h)
        c = udp_query("1.1.1.1", h)
        d = udp_query(def_ns, h) if def_ns else ("n/a", [])
        print(f"{h:<24} | {show(*sys):<34} | {show(*g):<30} | {show(*c):<30} | {show(*d):<30}")

    print("\n=== SUMMARY ===")
    hist = Counter()
    for h in HOSTS:
        _, ips = getaddrinfo_a(h)
        hist.update(ips)
    print("system-resolver A-record histogram:", dict(hist))
    sink = [ip for ip, n in hist.items() if n >= 3]
    if sink:
        print("POSSIBLE WILDCARD/SINKHOLE (>=3 hosts resolve to same IP):", sink)

if __name__ == "__main__":
    main()
