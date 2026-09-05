import socket,ssl,time,json,statistics
# Clean 4-way split: DNS | TCP connect | TLS handshake | first app byte.
# Timer starts AFTER resolution so DNS can never pollute the connect number.
RAW=[("200.160.2.3","Brazil NIC.br"),("139.130.4.5","Australia Telstra"),
     ("196.10.52.58","South Africa TENET"),("168.95.1.1","Taiwan Chunghwa"),
     ("202.12.29.1","M-root"),("1.1.1.1","Cloudflare anycast"),
     ("192.0.2.1","CONTROL local events svc"),("198.51.100.1","TEST-NET-2"),
     ("203.0.113.1","TEST-NET-3"),("10.255.255.1","RFC1918"),("100.64.0.1","RFC6598")]
NAMES=[("www.google.com",443),("www.uol.com.br",443),("www.telstra.com.au",443),
       ("www.chinadaily.com.cn",443),("pypi.org",443),("github.com",443)]

def connect_many(target,port,n=7):
    ts=[]
    for _ in range(n):
        s=socket.socket();s.settimeout(3)
        t0=time.perf_counter()
        try: rc=s.connect_ex((target,port))
        except Exception: rc=-1
        dt=(time.perf_counter()-t0)*1000
        s.close()
        if rc==0: ts.append(dt)
    return (round(statistics.median(ts),3) if ts else None), f"{len(ts)}/{n}"

rows=[]
print(f"{'target':26s} {'note':22s} {'connect_ms':>11s} {'ok':>6s} {'appl_ms':>9s}  application-plane")
for ip,note in RAW:
    c,ok=connect_many(ip,80)
    # app-plane: send a byte and time the first response byte (real network crossing)
    t0=time.perf_counter();res="(no response)"
    try:
        s=socket.socket();s.settimeout(5);s.connect((ip,80))
        s.sendall(b"HEAD / HTTP/1.0\r\n\r\n")
        d=s.recv(64); res=d.split(b"\r\n")[0].decode("utf8","replace") or "(empty)"
        s.close()
    except Exception as e: res=f"{type(e).__name__}"
    a=round((time.perf_counter()-t0)*1000,1)
    rows.append(dict(target=ip,note=note,connect_ms=c,ok=ok,appl_ms=a,appl=res))
    print(f"{ip:26s} {note:22s} {str(c):>11s} {ok:>6s} {a:>9.1f}  {res}")

print()
for h,port in NAMES:
    t0=time.perf_counter()
    try: ip=socket.gethostbyname(h)
    except Exception as e: print(f"{h} DNS FAIL {e}"); continue
    dns=round((time.perf_counter()-t0)*1000,2)
    c,ok=connect_many(ip,port)
    t0=time.perf_counter()
    try:
        ctx=ssl.create_default_context();ctx.check_hostname=True
        with socket.create_connection((ip,port),timeout=10) as s:
            with ctx.wrap_socket(s,server_hostname=h) as ss:
                ss.sendall(f"HEAD / HTTP/1.1\r\nHost: {h}\r\nConnection: close\r\n\r\n".encode())
                d=ss.recv(60)
        res=d.split(b"\r\n")[0].decode("utf8","replace")
    except Exception as e: res=f"{type(e).__name__}: {str(e)[:60]}"
    a=round((time.perf_counter()-t0)*1000,1)
    rows.append(dict(target=f"{h} -> {ip}",note="hostname (TLS)",dns_ms=dns,connect_ms=c,ok=ok,appl_ms=a,appl=res))
    print(f"{h+' -> '+ip:26s} {'hostname (TLS)':22s} {str(c):>11s} {ok:>6s} {a:>9.1f}  {res}   [dns {dns} ms]")
json.dump(rows,open("results/s1d_v2.json","w"),indent=1)
