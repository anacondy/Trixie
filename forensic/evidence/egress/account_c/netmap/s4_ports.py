import socket,ssl,json,time,struct,random
from concurrent.futures import ThreadPoolExecutor
PORTS=[21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,6379,8080,8443]
TLSPORTS={443,465,993,995,8443}
def resolve(h):
    try:return socket.gethostbyname(h)
    except Exception as e:return None
TARGETS=[("portquiz.net","all TCP ports open by design (egress test host)"),
         ("scanme.nmap.org","Nmap's authorised scan target"),
         ("1.1.1.1","Cloudflare"),("8.8.8.8","Google")]
def dnsquery():
    tid=random.randint(0,65535)
    q=b''.join(bytes([len(x)])+x.encode() for x in b"google.com".split(b'.'))+b'\x00'
    p=struct.pack('>HHHHHH',tid,0x0100,1,0,0,0)+q+struct.pack('>HH',1,1)
    return struct.pack('>H',len(p))+p
def probe(port):
    b=b""
    if port==53: b=dnsquery()
    elif port==6379: b=b"PING\r\n"
    elif port not in TLSPORTS:
        b=f"GET / HTTP/1.1\r\nHost: probe\r\nConnection: close\r\n\r\n".encode()
    return b
def one(host,ip,port):
    r={"port":port,"handshake":None,"hs_ms":None,"data":None,"data_ms":None,"snippet":None}
    t0=time.perf_counter()
    s=socket.socket();s.settimeout(4)
    try: rc=s.connect_ex((ip,port))
    except Exception as e: rc=-999
    r["hs_ms"]=round((time.perf_counter()-t0)*1000,1)
    r["handshake"]= (rc==0)
    if rc!=0:
        r["data"]=False;r["snippet"]=f"connect errno {rc}";s.close();return r
    # ---- data plane ----
    t1=time.perf_counter();buf=b""
    try:
        if port in TLSPORTS:
            ctx=ssl.create_default_context();ctx.check_hostname=False;ctx.verify_mode=ssl.CERT_NONE
            t=ctx.wrap_socket(s,server_hostname=host if not host[0].isdigit() else None)
            t.sendall(f"GET / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n".encode())
            try: buf=t.recv(400)
            except Exception: pass
            try: r["cert_issuer"]=dict(x[0] for x in t.getpeercert()["issuer"]).get("commonName")
            except Exception: r["cert_issuer"]="(none)"
        else:
            try:
                s.settimeout(1.5);buf=s.recv(400)          # banner-first services
            except socket.timeout: buf=b""
            if not buf:
                s.sendall(probe(port));s.settimeout(3)
                try: buf=s.recv(400)
                except socket.timeout: buf=b""
    except Exception as e:
        buf=b"";r["snippet"]=f"{type(e).__name__}: {str(e)[:70]}"
    r["data_ms"]=round((time.perf_counter()-t1)*1000,1)
    r["data"]=len(buf)>0
    if r["data"]:
        r["snippet"]=buf[:90].decode("utf8","replace").replace("\r\n","|").replace("\n","|")
    try:s.close()
    except Exception:pass
    return r
out={}
for host,note in TARGETS:
    ip=resolve(host)
    if not ip: print(f"{host}: resolution FAILED");continue
    out[host]={"ip":ip,"note":note,"ports":{}}
    with ThreadPoolExecutor(max_workers=17) as ex:
        futs={ex.submit(one,host,ip,p):p for p in PORTS}
        for f in futs: out[host]["ports"][str(futs[f])]=f.result()
    print(f"\n=== {host} ({ip}) — {note} ===")
    print(f"{'port':>6s} {'handshake':>10s} {'hs_ms':>7s} {'data?':>6s} {'d_ms':>8s}  evidence")
    for p in PORTS:
        r=out[host]["ports"][str(p)]
        print(f"{p:>6d} {str(r['handshake']):>10s} {r['hs_ms']:>7.1f} {str(r['data']):>6s} {r['data_ms']:>8.1f}  {str(r['snippet'])[:60]}")
json.dump(out,open("results/s4_tcp.json","w"),indent=1)
