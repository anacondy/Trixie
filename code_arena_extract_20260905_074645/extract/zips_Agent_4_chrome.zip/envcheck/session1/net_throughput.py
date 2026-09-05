import urllib.request, time, statistics, socket, ssl, threading, concurrent.futures as cf
import http.client, urllib.parse
UA={'User-Agent':'curl/8.14.1'}
def fetch(url, nbytes=None):
    t0=time.perf_counter()
    req=urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        data=r.read()
    el=time.perf_counter()-t0
    return len(data), el
def stats(name, results):
    mbps=[b*8/el/1e6 for b,el in results]
    print(f"{name:38} n={len(results)} med={statistics.median(mbps):7.1f} Mbps  min={min(mbps):7.1f}  max={max(mbps):7.1f}  med_bytes={int(statistics.median([r[0] for r in results])):>11}")

print("=== single-stream, 6 samples each (warm) ===")
for label,url in [("CF 25MB","https://speed.cloudflare.com/__down?bytes=25000000"),
                  ("CF 100MB","https://speed.cloudflare.com/__down?bytes=100000000"),
                  ("cachefly 100MB","https://cachefly.cachefly.net/100mb.test"),
                  ("Fastly(pyPI whl) ~12MB","https://files.pythonhosted.org/packages/source/r/requests/requests-2.32.3.tar.gz")]:
    try:
        res=[fetch(url) for _ in range(6)]
        stats(label,res)
    except Exception as e:
        print(f"{label:38} FAIL {type(e).__name__} {str(e)[:60]}")

print()
print("=== parallel scaling, CF 25MB per stream, 3 reps ===")
def dl(url):
    t0=time.perf_counter()
    with urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=60) as r:
        b=len(r.read())
    return b, time.perf_counter()-t0
for n in [1,2,4,8,16]:
    url=f"https://speed.cloudflare.com/__down?bytes=25000000"
    reps=[]
    for rep in range(3):
        t0=time.perf_counter()
        with cf.ThreadPoolExecutor(max_workers=n) as ex:
            rs=list(ex.map(lambda _: dl(url), range(n)))
        el=time.perf_counter()-t0
        tot=sum(b for b,_ in rs)
        reps.append(tot*8/el/1e6)
    print(f"  streams={n:<3} aggregate Mbps: med={statistics.median(reps):8.1f}  reps={[round(x,1) for x in reps]}")

print()
print("=== upload scaling, CF __up ===")
def up(size):
    body=b'x'*size
    t0=time.perf_counter()
    p=urllib.parse.urlparse("https://speed.cloudflare.com/__up")
    ctx=ssl.create_default_context()
    s=socket.create_connection((p.hostname,443),timeout=60)
    ss=ctx.wrap_socket(s,server_hostname=p.hostname)
    hdr=f"POST {p.path} HTTP/1.1\r\nHost: {p.hostname}\r\nContent-Type: application/octet-stream\r\nContent-Length: {len(body)}\r\nConnection: close\r\n\r\n"
    ss.sendall(hdr.encode()+body)
    resp=ss.recv(200); ss.close()
    return size, time.perf_counter()-t0, resp[:12]
for sz in [1_000_000,10_000_000,50_000_000]:
    rs=[up(sz) for _ in range(3)]
    mbps=[r[0]*8/r[1]/1e6 for r in rs]
    print(f"  {sz:>11} bytes  med={statistics.median(mbps):7.1f} Mbps  reps={[round(x,1) for x in mbps]}")
