import socket,time,subprocess,os,json
# If connect() RTT to a host on another continent is sub-millisecond, something
# local is terminating the handshake.
FAR=[("1.1.1.1","Cloudflare anycast (nearest PoP)"),
     ("8.8.8.8","Google anycast (nearest PoP)"),
     ("9.9.9.9","Quad9 anycast"),
     ("168.95.1.1","Chunghwa Telecom, Taiwan"),
     ("200.160.2.3","NIC.br, Brazil"),
     ("196.10.52.58","TENET, South Africa"),
     ("202.12.29.1","M-root (US/JP)"),
     ("139.130.4.5","Telstra, Australia"),
     ("192.0.2.1","TEST-NET-1 (has /etc/hosts entry)"),
     ("192.0.2.200","TEST-NET-1 other addr"),
     ("198.51.100.1","TEST-NET-2"),
     ("203.0.113.1","TEST-NET-3"),
     ]
res=[]
for ip,note in FAR:
    best=None
    for _ in range(3):
        s=socket.socket();s.settimeout(3)
        t0=time.perf_counter()
        rc=s.connect_ex((ip,80)) if ip not in("139.130.4.5","196.10.52.58") else s.connect_ex((ip,53))
        dt=(time.perf_counter()-t0)*1000
        s.close()
        best=dt if best is None else min(best,dt)
    res.append({"ip":ip,"note":note,"min_connect_ms":round(best,3),"rc":rc})
    print(f"{ip:16s} {note:42s} min_connect={best:8.3f} ms  rc={rc}")
json.dump(res,open("results/s1b.json","w"),indent=1)

print()
print("=== TCP STATE AFTER connect() to 198.51.100.1:80 ===")
def sock_state_check(ip,port):
    s=socket.socket();s.settimeout(3)
    rc=s.connect_ex((ip,port))
    la,lp=s.getsockname()
    hexip=socket.inet_aton(ip).hex()
    hexport=f"{port:04X}"
    # read /proc/net/tcp
    st="unknown"
    for line in open("/proc/net/tcp").read().splitlines()[1:]:
        f=line.split()
        loc=f[1];rem=f[2];state=f[3]
        if rem.upper().endswith(f":{hexport}") and int(rem.split(":")[0],16)==int(hexip,16):
            st=state
    s.close()
    return rc,st
TCPST={"01":"ESTABLISHED","02":"SYN_SENT","03":"SYN_RECV","04":"FIN_WAIT1","05":"FIN_WAIT2",
       "06":"TIME_WAIT","07":"CLOSE","08":"CLOSE_WAIT","09":"LAST_ACK","0A":"LISTEN","0B":"CLOSING"}
for ip,port in [("198.51.100.1",80),("203.0.113.1",80),("1.1.1.1",443),("192.0.2.1",80),("200.160.2.3",53)]:
    try:
        rc,st=sock_state_check(ip,port)
        print(f"  {ip}:{port:6d} connect_rc={rc:4d}  tcp_state={st} ({TCPST.get(st,'?')})")
    except Exception as e:
        print(f"  {ip}:{port} ERR {e}")

print()
print("=== ARP / NEIGH ===")
print(subprocess.run(["ip","neigh","show"],capture_output=True,text=True).stdout or "(empty)")
print("=== /proc/net/arp ===")
print(open("/proc/net/arp").read() if os.path.exists("/proc/net/arp") else "(none)")
print("=== /proc/net/route ===")
print(open("/proc/net/route").read())
