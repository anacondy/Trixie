import socket,json,time
from concurrent.futures import ThreadPoolExecutor
# Which destination ranges does the interceptor accept the handshake for,
# vs silently blackhole, vs refuse?
RANGES=[("127.0.0.2","loopback non-.1"),("169.254.0.20","link-local subnet base (our /30)"),
 ("169.254.0.21","SELF (eth0 addr)"),("169.254.0.22","GATEWAY (default route / ARP neighbour)"),
 ("169.254.169.254","cloud IMDS (link-local metadata)"),("169.254.170.2","ECS task metadata"),
 ("10.0.0.1","RFC1918 10/8"),("10.255.255.1","RFC1918 10/8"),("172.16.0.1","RFC1918 172.16/12"),
 ("192.168.1.1","RFC1918 192.168/16"),("100.64.0.1","RFC6598 CGNAT start"),
 ("100.127.255.254","RFC6598 CGNAT end"),("192.0.2.1","RFC5737 TEST-NET-1 (has /etc/hosts entry)"),
 ("192.0.2.7","RFC5737 TEST-NET-1 other"),("198.51.100.7","RFC5737 TEST-NET-2 other"),
 ("203.0.113.7","RFC5737 TEST-NET-3 other"),("198.18.0.1","RFC2544 benchmark"),
 ("192.88.99.1","6to4 relay anycast"),("224.0.0.1","multicast"),("240.0.0.1","reserved 240/4"),
 ("0.0.0.0","this-network"),("255.255.255.255","broadcast"),
 ("8.8.8.8","CONTROL: real public anycast"),("142.251.152.119","CONTROL: real public unicast")]
def t(item):
    ip,note=item
    if ip.startswith(("224.","255.")):
        return {"ip":ip,"note":note,"rc":"n/a (non-connectable special)","ms":None,"verdict":"SKIPPED"}
    s=socket.socket();s.settimeout(3)
    t0=time.perf_counter()
    try: rc=s.connect_ex((ip,80))
    except Exception as e: rc=f"EXC:{type(e).__name__}"
    ms=round((time.perf_counter()-t0)*1000,2)
    try:s.close()
    except Exception:pass
    if rc==0: v="ACCEPTED (handshake completed locally)"
    elif rc in (11,110,10060): v="BLACKHOLED (packets dropped, no RST)"
    elif rc in (111,113): v="REFUSED (real RST from something)"
    else: v=f"errno {rc}"
    return {"ip":ip,"note":note,"rc":rc,"ms":ms,"verdict":v}
with ThreadPoolExecutor(max_workers=24) as ex:
    res=list(ex.map(t,RANGES))
print(f"{'address':18s} {'note':38s} {'rc':>6s} {'ms':>7s}  verdict")
for r in res:
    print(f"{r['ip']:18s} {r['note']:38s} {str(r['rc']):>6s} {str(r['ms']):>7s}  {r['verdict']}")
json.dump(res,open("results/s1e.json","w"),indent=1)
