import socket,struct,random,time,json
def dns_q(name="google.com"):
    tid=random.randint(0,65535)
    q=b''.join(bytes([len(x)])+x.encode() for x in name.split('.'))+b'\x00'
    return struct.pack('>HHHHHH',tid,0x0100,1,0,0,0)+q+struct.pack('>HH',1,1)
def ntp_q():
    p=bytearray(48);p[0]=0x1B;return bytes(p)
def quic_vn():
    dcid=bytes(random.getrandbits(8) for _ in range(8))
    body=b'\x00'+b'\x00'*1100
    pkt=bytes([0xC0])+struct.pack('>I',0x00000001)+bytes([len(dcid)])+dcid+b'\x00'+b'\x00'
    pkt+=struct.pack('>H',0x4000|len(body))+body
    return pkt+b'\x00'*max(0,1200-len(pkt))
def udp(host,port,payload,to=4,tries=2):
    for _ in range(tries):
        s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(to)
        t0=time.perf_counter()
        try:
            s.sendto(payload,(host,port));d,a=s.recvfrom(4096)
            return len(d),round((time.perf_counter()-t0)*1000,1),d[:4].hex()
        except socket.timeout: pass
        finally: s.close()
    return 0,round(to*1000),None
T=[
 ("208.67.222.222",53,   "OpenDNS  - DNS on STANDARD port",     dns_q()),
 ("208.67.222.222",5353, "OpenDNS  - DNS on ALT port 5353",     dns_q()),
 ("208.67.222.222",443,  "OpenDNS  - DNS payload to port 443",  dns_q()),
 ("9.9.9.9",53,          "Quad9    - DNS standard",             dns_q()),
 ("9.9.9.9",9953,        "Quad9    - DNS to alt port 9953",     dns_q()),
 ("216.239.35.0",123,    "time.google.com - REAL NTP server",   ntp_q()),
 ("216.239.35.4",123,    "time.google.com - REAL NTP server",   ntp_q()),
 ("162.159.200.1",123,   "time.cloudflare.com - REAL NTP",      ntp_q()),
 ("162.159.200.123",123, "time.cloudflare.com - REAL NTP",      ntp_q()),
 ("142.250.73.78",443,   "google.com - QUIC ver-negotiation",   quic_vn()),
 ("142.251.152.119",443, "google.com - QUIC ver-negotiation",   quic_vn()),
 ("104.16.0.34",443,     "cloudflare-hosted - QUIC",            quic_vn()),
 ("1.1.1.1",443,         "1.1.1.1 - QUIC ver-negotiation",      quic_vn()),
 ("8.8.8.8",443,         "8.8.8.8 - QUIC ver-negotiation",      quic_vn()),
 ("8.8.8.8",53,          "8.8.8.8 - DNS (positive control)",    dns_q()),
]
out=[]
print(f"{'destination':22s} {'port':>6s}  {'test':38s} {'rcvd':>5s} {'ms':>7s}  first4")
for h,p,desc,pl in T:
    n,ms,hex4=udp(h,p,pl)
    verdict = "DATA RECEIVED" if n else "no response"
    out.append({"host":h,"port":p,"test":desc,"rcvd":n,"ms":ms,"first4":hex4,"verdict":verdict})
    print(f"{h:22s} {p:>6d}  {desc:38s} {n:>5d} {ms:>7.1f}  {hex4}   {verdict}")
json.dump(out,open("results/s4c_udp_control.json","w"),indent=1)
