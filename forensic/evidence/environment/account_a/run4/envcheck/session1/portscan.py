import socket, time
# test outbound TCP ports against hosts that should answer on some
tests = {
 "github.com": [22,80,443,8080,8443,3000,5432,9000],
 "1.1.1.1":    [53,80,443,123,853,443,54321],
 "8.8.8.8":    [53,443],
 "speed.cloudflare.com": [80,443,8080],
 "scanme.nmap.org": [21,22,23,25,53,80,110,135,139,443,445,993,995,1433,3306,3389,5900,8000,8080,8888,9999],
}
print(f"{'host:port':32} {'result':>10}  {'ms':>8}  detail")
for h, ports in tests.items():
    for p in sorted(set(ports)):
        t0=time.perf_counter()
        try:
            s=socket.create_connection((h,p),timeout=5)
            ms=(time.perf_counter()-t0)*1000
            try:
                s.settimeout(2); data=s.recv(80)
            except Exception: data=b''
            s.close()
            print(f"{h+':'+str(p):32} {'OPEN':>10}  {ms:8.2f}  {data[:40]!r}")
        except socket.timeout:
            print(f"{h+':'+str(p):32} {'TIMEOUT':>10}  {(time.perf_counter()-t0)*1000:8.1f}")
        except ConnectionRefusedError:
            print(f"{h+':'+str(p):32} {'REFUSED':>10}  {(time.perf_counter()-t0)*1000:8.2f}  (filtered=NO -> host reachable, port closed)")
        except OSError as e:
            print(f"{h+':'+str(p):32} {'ERR':>10}  {(time.perf_counter()-t0)*1000:8.2f}  {type(e).__name__} {e.errno}")
