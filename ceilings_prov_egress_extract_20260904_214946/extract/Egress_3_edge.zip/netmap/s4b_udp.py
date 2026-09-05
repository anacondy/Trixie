import socket,struct,random,time,json
def dns_q(name="google.com"):
    tid=random.randint(0,65535)
    q=b''.join(bytes([len(x)])+x.encode() for x in name.split('.'))+b'\x00'
    return struct.pack('>HHHHHH',tid,0x0100,1,0,0,0)+q+struct.pack('>HH',1,1)
def ntp_q():
    # NTPv3 client mode, 48-byte header
    p=bytearray(48);p[0]=0x1B;return bytes(p)
def quic_initial():
    # long header, Initial, version 0x00000001 (unsupported -> Version Negotiation)
    dcid=bytes(random.getrandbits(8) for _ in range(8))
    body=b'\x00'+b'\x00'*1100           # pkt num 0 + padding
    pkt=bytes([0xC0])+struct.pack('>I',0x00000001)+bytes([len(dcid)])+dcid+b'\x00'+b'\x00'
    ln=len(body)
    pkt+=struct.pack('>H',0x4000|ln)+body
    return pkt+b'\x00'*(1200-len(pkt)) if len(pkt)<1200 else pkt
def ike_sa_init():
    spi=bytes(8);nxt=43;ver=0x20;exch=34;flags=0x08
    msgid=bytes(4);ln=28
    return spi+bytes([nxt,ver,exch,flags])+msgid+struct.pack('>I',ln)
TESTS=[(53,"DNS A? google.com",dns_q()),(123,"NTPv3 client",ntp_q()),
       (443,"QUIC Initial (bogus ver)",quic_initial()),(500,"IKEv2 SA_INIT",ike_sa_init()),
       (33434,"traceroute-style probe",b"probe"*8),(9999,"UDP control (unassigned)",b"hello")]
HOSTS=["8.8.8.8","1.1.1.1"]
out=[]
print(f"{'host':9s} {'port':>6s} {'test':28s} {'sent':>5s} {'rcvd':>5s} {'ms':>7s}  result")
for h in HOSTS:
    for port,desc,payload in TESTS:
        got=b"";ms=None
        for attempt in range(2):
            s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(4)
            t0=time.perf_counter()
            try:
                s.sendto(payload,(h,port));got,addr=s.recvfrom(4096)
                ms=round((time.perf_counter()-t0)*1000,1);break
            except socket.timeout:
                ms=round((time.perf_counter()-t0)*1000,1)
            except Exception as e:
                got=f"EXC:{type(e).__name__}".encode()
            finally: s.close()
        if isinstance(got,bytes) and got.startswith(b"EXC:"):
            verdict=got.decode()
        elif got:
            kind=("DNS reply" if port==53 else "NTP" if port==123 else
                  "QUIC VerNeg" if (got[0]&0x80 and port==443) else "QUIC/other" if port==443
                  else "IKE" if port==500 else "data")
            verdict=f"RECEIVED {len(got)}B ({kind}) first3={got[:3].hex()}"
        else:
            verdict="NO RESPONSE (silent drop - note: UDP gives no RST, so drop==filtered==closed)"
        out.append({"host":h,"port":port,"test":desc,"sent":len(payload),
                    "rcvd":len(got) if not isinstance(got,str) else 0,"ms":ms,"result":verdict})
        print(f"{h:9s} {port:>6d} {desc:28s} {len(payload):>5d} {(len(got) if isinstance(got,bytes) and not got.startswith(b'EXC:') else 0):>5d} {str(ms):>7s}  {verdict}")
json.dump(out,open("results/s4b_udp.json","w"),indent=1)
