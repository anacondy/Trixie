import socket, ssl, time, statistics
HOSTS = {
 "google.com": ("google.com",80), "1.1.1.1 (tcp80)": ("1.1.1.1",80),
 "8.8.8.8:53 (dns)": ("8.8.8.8",53), "github.com:443": ("github.com",443),
 "pypi.org:443": ("pypi.org",443), "huggingface.co:443": ("huggingface.co",443),
 "registry.npmjs.org:443": ("registry.npmjs.org",443),
 "files.pythonhosted.org:443": ("files.pythonhosted.org",443),
 "objects.githubusercontent.com:443": ("objects.githubusercontent.com",443),
 "cdn.jsdelivr.net:443": ("cdn.jsdelivr.net",443),
}
def tcp_rt(host, port, n=7):
    ts=[]
    for _ in range(n):
        t0=time.perf_counter()
        try:
            s=socket.create_connection((host,port),timeout=8); s.close(); ts.append((time.perf_counter()-t0)*1000)
        except Exception as e:
            return type(e).__name__, []
    return "OK", ts
print(f"{'endpoint':38} {'res':>12} {'n':>2} {'min ms':>7} {'med ms':>7} {'max ms':>7}")
for name,(h,p) in HOSTS.items():
    r,ts = tcp_rt(h,p)
    if ts: print(f"{name:38} {r:>12} {len(ts):>2} {min(ts):7.2f} {statistics.median(ts):7.2f} {max(ts):7.2f}")
    else:  print(f"{name:38} {r:>12} {'-':>2}")
print()
print("=== full TLS handshake (connect + handshake + close) ===")
ctx=ssl.create_default_context()
for h in ["google.com","github.com","pypi.org","huggingface.co","registry.npmjs.org","cdn.jsdelivr.net"]:
    ts=[]
    for _ in range(5):
        t0=time.perf_counter()
        try:
            s=socket.create_connection((h,443),timeout=8)
            t1=time.perf_counter()
            ss=ctx.wrap_socket(s,server_hostname=h)
            t2=time.perf_counter()
            ver=ss.version
            ss.close()
            ts.append(((t1-t0)*1000,(t2-t1)*1000,(t2-t0)*1000))
        except Exception as e:
            print(f"{h:32} FAIL {type(e).__name__}: {str(e)[:60]}"); break
    if ts:
        tcp=[x[0] for x in ts]; hs=[x[1] for x in ts]; tot=[x[2] for x in ts]
        print(f"{h:32} {ver:9} tcp_med={statistics.median(tcp):6.2f}ms  tls_med={statistics.median(hs):6.2f}ms  total_med={statistics.median(tot):6.2f}ms  total_min={min(tot):6.2f}ms")
