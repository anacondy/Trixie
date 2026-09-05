import socket, time, json, ssl

TARGETS = [
 ("192.0.2.1",   9,  "TEST-NET-1 (RFC5737) [has /etc/hosts entry -> events.e2b.local]"),
 ("192.0.2.200", 9,  "TEST-NET-1 (RFC5737) other host"),
 ("198.51.100.1",9,  "TEST-NET-2 (RFC5737)"),
 ("203.0.113.1", 9,  "TEST-NET-3 (RFC5737)"),
 ("10.255.255.1",9,  "RFC1918 private"),
 ("100.64.0.1",  9,  "RFC6598 CGNAT"),
 ("192.0.2.1",   80, "TEST-NET-1 port 80 [hosts entry]"),
 ("198.51.100.1",80, "TEST-NET-2 port 80"),
 ("203.0.113.1", 80, "TEST-NET-3 port 80"),
 ("10.255.255.1",80, "RFC1918 port 80"),
 ("100.64.0.1",  80, "RFC6598 port 80"),
 ("127.0.0.1",   9,  "CONTROL loopback closed port"),
 ("8.8.8.8",     53, "CONTROL real internet host"),
 ("1.1.1.1",     443,"CONTROL real internet host"),
]

out=[]
for host,port,note in TARGETS:
    row={"target":f"{host}:{port}","note":note}
    s=socket.socket(); s.settimeout(2)
    t0=time.perf_counter()
    try:
        rc=s.connect_ex((host,port))
    except Exception as e:
        rc=f"EXC:{type(e).__name__}:{e}"
    dt=(time.perf_counter()-t0)*1000
    row["connect_rc"]=rc
    row["connect_ms"]=round(dt,2)
    row["connect_result"]=("SUCCESS" if rc==0 else ("TIMEOUT" if rc in (110,10060,11) else f"ERRNO {rc}"))
    # did we get a real peer? check getpeername + local
    try:
        row["peername"]=str(s.getpeername())
    except Exception as e:
        row["peername"]=f"unavailable ({type(e).__name__})"
    s.close()
    out.append(row)

# ---- phase 2: actual data-plane attempt on the ones that "connect" ----
for row in out:
    host,port = row["target"].split(":")
    port=int(port)
    res={"http":"skipped (connect failed)"}
    if row["connect_rc"]==0:
        # raw socket: send a HTTP GET, try to read
        try:
            s=socket.socket(); s.settimeout(4)
            s.connect((host,port))
            s.sendall(f"GET / HTTP/1.1\r\nHost: {host}\r\nUser-Agent: netmap-probe/1.0\r\nConnection: close\r\n\r\n".encode())
            t0=time.perf_counter()
            data=b""
            try:
                while True:
                    c=s.recv(4096)
                    if not c: break
                    data+=c
                    if len(data)>65536: break
            except socket.timeout:
                pass
            dt=(time.perf_counter()-t0)*1000
            res={"bytes_recv":len(data),"ms":round(dt,2),
                 "snippet":data[:200].decode("utf8","replace").replace("\r\n","|")}
            s.close()
        except Exception as e:
            res={"raw_socket_error":f"{type(e).__name__}: {e}"}
        row["dataplane"]=res
    else:
        row["dataplane"]=res

    # curl as independent oracle
    import subprocess
    t0=time.perf_counter()
    p=subprocess.run(["curl","-sS","-o","/dev/null","-w","%{http_code} %{exitcode}","--max-time","5",
                      f"http://{host}:{port}/"],capture_output=True,text=True)
    row["curl_http"]={"stdout":p.stdout.strip(),"stderr":p.stderr.strip()[:160],
                      "ms":round((time.perf_counter()-t0)*1000,1)}
    out2=None

print(json.dumps(out,indent=1))
json.dump(out,open("/home/user/netmap/results/s1.json","w"),indent=1)
