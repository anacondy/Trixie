import socket,ssl,time,json,statistics
# CONTROLLED PROOF: for the SAME destination measure
#   (a) TCP connect() latency  vs  (b) the first thing that MUST cross the real network
#       (TLS handshake / first application byte).
# A real TCP handshake to another continent cannot complete in <1 ms.
T=[("www.google.com",443,"HTTPS"),("www.uol.com.br",443,"HTTPS/Brazil"),
   ("www.telstra.com.au",443,"HTTPS/Australia"),("www.chinadaily.com.cn",443,"HTTPS/China"),
   ("pypi.org",443,"HTTPS"),
   ("200.160.2.3",80,"raw IP Brazil/NIC.br"),("139.130.4.5",53,"raw IP Australia/Telstra"),
   ("196.10.52.58",53,"raw IP South Africa/TENET"),("168.95.1.1",53,"raw IP Taiwan/Chunghwa"),
   ("192.0.2.1",80,"CONTROL: local events.e2b.local svc"),
   ("198.51.100.1",80,"TEST-NET-2"),("203.0.113.1",80,"TEST-NET-3"),
   ("10.255.255.1",80,"RFC1918"),("100.64.0.1",80,"RFC6598")]
rows=[]
print(f"{'target':24s} {'note':32s} {'connect_ms':>11s} {'appl_ms':>9s} {'appl':>22s}")
for host,port,note in T:
    r={"host":host,"port":port,"note":note}
    conns=[]
    for _ in range(5):
        s=socket.socket();s.settimeout(4)
        t0=time.perf_counter();rc=s.connect_ex((host,port));dt=(time.perf_counter()-t0)*1000
        s.close()
        if rc==0: conns.append(dt)
    r["connect_ms_median"]=round(statistics.median(conns),3) if conns else None
    r["connect_ok"]=f"{len(conns)}/5"
    # application-plane latency: TLS handshake (must reach the real server)
    t0=time.perf_counter();appl="n/a"
    try:
        ctx=ssl.create_default_context()
        with socket.create_connection((host,port),timeout=8) as s:
            with ctx.wrap_socket(s,server_hostname=host if not host[0].isdigit() else None) as ss:
                ss.sendall(b"HEAD / HTTP/1.0\r\nHost: x\r\n\r\n")
                d=ss.recv(64)
        appl=f"TLS+data {d[:20]!r}"
    except Exception as e:
        appl=f"{type(e).__name__}"
    r["appl_ms"]=round((time.perf_counter()-t0)*1000,1)
    r["appl"]=appl[:60]
    rows.append(r)
    print(f"{host:24s} {note:32s} {str(r['connect_ms_median']):>11s} {r['appl_ms']:>9.1f} {appl[:24]:>24s}")
json.dump(rows,open("results/s1d.json","w"),indent=1)
