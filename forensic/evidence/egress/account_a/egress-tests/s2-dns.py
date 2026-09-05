#!/usr/bin/env python3
"""Section 2: DNS-level filtering — raw UDP queries, rcode classification, default vs explicit resolvers."""
import socket, struct, time

HOSTS = [
    "google.com", "pypi.org", "files.pythonhosted.org", "registry.npmjs.org",
    "github.com", "raw.githubusercontent.com", "huggingface.co", "openai.com",
    "api.anthropic.com", "pastebin.com", "transfer.sh", "ngrok.io",
    "webhook.site", "1.1.1.1.xip.io",
    # control: guaranteed-nonexistent
    "definitely-not-a-real-host-9f3a2.example",
]
TXID = 0x4a11

def build_query(name, qtype=1):
    qn = b"".join(bytes([len(p)]) + p.encode("ascii") for p in name.split(".")) + b"\x00"
    hdr = struct.pack(">HHHHHH", TXID, 0x0100, 1, 0, 0, 0)
    return hdr + qn + struct.pack(">HH", qtype, 1)

def read_name(msg, off):
    labels = []; end = -1; jumps = 0
    while True:
        if jumps > 10: break
        l = msg[off]
        if l & 0xC0 == 0xC0:
            ptr = struct.unpack(">H", msg[off:off+2])[0] & 0x3FFF
            if end == -1: end = off + 2
            off = ptr; jumps += 1; continue
        off += 1
        if l == 0:
            if end == -1: end = off
            break
        labels.append(msg[off:off+l].decode("ascii", "replace")); off += l
    return ".".join(labels), end

RCODES = {0: "NOERROR", 1: "FORMERR", 2: "SERVFAIL", 3: "NXDOMAIN", 4: "NOTIMP", 5: "REFUSED"}

def parse(msg):
    rcode = msg[3] & 0xF
    qd, an = struct.unpack(">HH", msg[4:8])
    off = 12
    for _ in range(qd):
        _, off = read_name(msg, off); off += 4
    answers = []
    for _ in range(an):
        _, off = read_name(msg, off)
        t, c, ttl, rdl = struct.unpack(">HHIH", msg[off:off+10]); off += 10
        if t == 1 and rdl == 4:
            answers.append("A:" + ".".join(str(b) for b in msg[off:off+4]))
        elif t == 5:
            cname, _ = read_name(msg, off); answers.append("CNAME:" + cname)
        off += rdl
    return rcode, answers

def query(name, server, timeout=3.0):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(timeout)
    t0 = time.perf_counter()
    try:
        s.sendto(build_query(name), (server, 53))
        while True:
            data, _ = s.recvfrom(4096)
            if len(data) >= 12 and struct.unpack(">H", data[:2])[0] == TXID:
                dt = time.perf_counter() - t0
                rcode, ans = parse(data)
                return f"{RCODES.get(rcode, 'RCODE'+str(rcode)):<9} ans={','.join(ans) if ans else '-'} t={dt:.3f}s"
    except socket.timeout:
        return "TIMEOUT"
    except OSError as e:
        return f"OSERR {e}"
    finally:
        s.close()

def getaddr(name):
    try:
        return sorted({ai[4][0] for ai in socket.getaddrinfo(name, 443, socket.AF_INET, socket.SOCK_STREAM)})
    except socket.gaierror as e:
        return f"gaierror({e.errno}): {e}"

def nameservers():
    ns = []
    for line in open("/etc/resolv.conf"):
        line = line.split("#")[0].strip()
        if line.startswith("nameserver"):
            ns.append(line.split()[1])
    return ns or ["127.0.0.1"]

local_ns = nameservers()
servers = local_ns + ["8.8.8.8", "1.1.1.1"]
print("resolv.conf nameservers:", local_ns)
print("querying servers:", servers)
for h in HOSTS:
    print(f"\n== {h}")
    print(f"  system-getaddrinfo     : {getaddr(h)}")
    for srv in servers:
        print(f"  UDP A @{srv:<15}: {query(h, srv)}")
