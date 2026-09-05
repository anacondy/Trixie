import socket,ssl,json,subprocess,time
HOSTS=["pypi.org","github.com","huggingface.co","pastebin.com","webhook.site","transfer.sh"]
def tls(sni,ip,port=443,timeout=10,hosthdr=None,verify=True):
    ctx=ssl.create_default_context();ctx.check_hostname=verify
    if not verify: ctx.verify_mode=ssl.CERT_OPTIONAL;ctx.check_hostname=False
    try:
        with socket.create_connection((ip,port),timeout=timeout) as s:
            with ctx.wrap_socket(s,server_hostname=sni) as ss:
                c=ss.getpeercert();ver=ss.version();cert=ss.getpeercert(binary_form=False)
                ss.sendall(f"HEAD / HTTP/1.1\r\nHost: {hosthdr or sni}\r\nConnection: close\r\n\r\n".encode())
                d=ss.recv(120)
        iss=dict(x[0] for x in c["issuer"]);sub=dict(x[0] for x in c["subject"])
        return {"ok":True,"tls":ver,"sni_used":sni,"issuer_CN":iss.get("commonName"),
                "subject_CN":sub.get("commonName"),"http":d.split(b"\r\n")[0].decode("utf8","replace")}
    except Exception as e:
        return {"ok":False,"sni_used":sni,"error":f"{type(e).__name__}: {str(e)[:130]}"}
def plain(ip,hosthdr,port=80,timeout=10):
    try:
        s=socket.create_connection((ip,port),timeout=timeout)
        s.sendall(f"GET / HTTP/1.1\r\nHost: {hosthdr}\r\nConnection: close\r\n\r\n".encode())
        s.settimeout(timeout);d=b""
        try:
            while True:
                c=s.recv(4096)
                if not c:break
                d+=c
                if len(d)>4000:break
        except socket.timeout:pass
        s.close()
        return {"ok":True,"bytes":len(d),"status":d.split(b"\r\n")[0].decode("utf8","replace")}
    except Exception as e:
        return {"ok":False,"error":f"{type(e).__name__}: {str(e)[:110]}"}
def curl(url,resolve=None,timeout=12):
    cmd=["curl","-s","-o","/dev/null","--max-time",str(timeout),"-w",
         "%{http_code}|connect=%{time_connect}|tls=%{time_appconnect}|ttfb=%{time_starttransfer}",url]
    if resolve: cmd[1:1]=["--resolve",resolve]
    p=subprocess.run(cmd,capture_output=True,text=True)
    e=p.stderr.strip().replace("\n"," ")[:90]
    return (p.stdout.strip() or "no-stdout")+(f"  ERR[{e}]" if e else "")

out=[]
for h in HOSTS:
    try: ip=socket.gethostbyname(h)
    except Exception as e:
        print(f"{h}: DNS FAIL {e}");continue
    r={"host":h,"ip":ip,
       "A_hostname_https":tls(h,h),
       "B_ip_sni_hostname":tls(h,ip),
       "C_ip_sni_ip":tls(ip,ip,verify=False),
       "D_ip_http_hosthdr":plain(ip,h),
       "E_hostname_http":plain(h,h),
       "F_curl_normal":curl(f"https://{h}/"),
       "G_curl_pinned_ip":curl(f"https://{h}/",f"{h}:443:{ip}")}
    out.append(r)
    print(f"--- {h}  ({ip}) ---")
    for k,v in r.items():
        if k in("host","ip"):continue
        print(f"   {k:20s} {v if not isinstance(v,dict) else (v if v.get('ok') else v.get('error'))}")
json.dump(out,open("results/s3.json","w"),indent=1)
