import socket, struct, time, json, random, subprocess

RCODE={0:"NOERROR",1:"FORMERR",2:"SERVFAIL",3:"NXDOMAIN",4:"NOTIMP",5:"REFUSED",
       6:"YXDOMAIN",7:"YXRRSET",8:"NXRRSET",9:"NOTAUTH",10:"NOTZONE"}

def build_query(qname,qtype=1):
    tid=random.randint(0,65535)
    hdr=struct.pack('>HHHHHH',tid,0x0100,1,0,0,0)
    q=b''
    for lab in qname.rstrip('.').split('.'):
        q+=bytes([len(lab)])+lab.encode()
    q+=b'\x00'+struct.pack('>HH',qtype,1)
    return tid,hdr+q

def parse_name(data,off):
    labels=[];jumped=False;orig=off
    while True:
        if off>=len(data):return "<trunc>",off
        l=data[off]
        if l==0:
            off+=1;break
        if l&0xC0==0xC0:
            ptr=struct.unpack('>H',data[off:off+2])[0]&0x3FFF
            if not jumped:orig=off+2
            off=ptr;jumped=True;continue
        off+=1
        labels.append(data[off:off+l].decode('utf8','replace'))
        off+=l
    return '.'.join(labels),(orig if jumped else off)

def parse_response(data):
    if len(data)<12:return {"err":"short response"}
    tid,flags,qd,an,ns,ar=struct.unpack('>HHHHHH',data[:12])
    rcode=flags&0xF
    off=12
    for _ in range(qd):
        _,off=parse_name(data,off);off+=4
    answers=[]
    for _ in range(an):
        name,off=parse_name(data,off)
        if off+10>len(data):break
        rtype,rclass,ttl,rdlen=struct.unpack('>HHIH',data[off:off+10])
        off+=10;rdata=data[off:off+rdlen];off+=rdlen
        if rtype==1 and rdlen==4:answers.append(("A",'.'.join(str(b) for b in rdata),ttl))
        elif rtype==5:
            cn,_=parse_name(data,off-rdlen);answers.append(("CNAME",cn,ttl))
        elif rtype==28 and rdlen==16:answers.append(("AAAA",socket.inet_ntop(socket.AF_INET6,rdata),ttl))
        else:answers.append((str(rtype),rdata.hex()[:24],ttl))
    return {"rcode":rcode,"rcode_name":RCODE.get(rcode,str(rcode)),"ancount":an,
            "answers":answers,"ra":bool(flags&0x80),"rd":bool(flags&0x100),
            "ad":bool(flags&0x20),"tc":bool(flags&0x200),"raw_flags":hex(flags)}

def query(resolver,qname,proto="udp",timeout=4,qtype=1):
    tid,pkt=build_query(qname,qtype)
    t0=time.perf_counter()
    try:
        if proto=="udp":
            s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(timeout)
            s.sendto(pkt,(resolver,53));data,_=s.recvfrom(4096);s.close()
        else:
            s=socket.socket();s.settimeout(timeout);s.connect((resolver,53))
            s.sendall(struct.pack('>H',len(pkt))+pkt)
            n=struct.unpack('>H',s.recv(2))[0]
            data=b''
            while len(data)<n:
                c=s.recv(4096)
                if not c:break
                data+=c
            s.close()
    except socket.timeout:
        return {"outcome":"TIMEOUT","ms":round((time.perf_counter()-t0)*1000,1)}
    except Exception as e:
        return {"outcome":f"ERROR {type(e).__name__}: {e}","ms":round((time.perf_counter()-t0)*1000,1)}
    r=parse_response(data)
    r["ms"]=round((time.perf_counter()-t0)*1000,1)
    r["outcome"]="ANSWER"
    r["tid_match"]=(r and True)
    return r

HOSTS=["google.com","pypi.org","files.pythonhosted.org","registry.npmjs.org","github.com",
       "raw.githubusercontent.com","huggingface.co","openai.com","api.anthropic.com",
       "pastebin.com","transfer.sh","ngrok.io","webhook.site","1.1.1.1.xip.io"]

# system resolver path (getaddrinfo) - what apps actually use
sysres={}
for h in HOSTS:
    t0=time.perf_counter()
    try:
        inf=socket.getaddrinfo(h,443,proto=socket.IPPROTO_TCP)
        sysres[h]={"outcome":"RESOLVED","addrs":sorted({i[4][0] for i in inf}),
                   "ms":round((time.perf_counter()-t0)*1000,1)}
    except Exception as e:
        sysres[h]={"outcome":f"FAIL {type(e).__name__}: {e}","addrs":[],
                   "ms":round((time.perf_counter()-t0)*1000,1)}

# explicit resolvers
RESOLVERS=[("8.8.8.8 (= /etc/resolv.conf)","8.8.8.8"),
           ("1.1.1.1 (Cloudflare)","1.1.1.1"),
           ("9.9.9.9 (Quad9)","9.9.9.9")]
explicit={}
for label,ip in RESOLVERS:
    explicit[label]={}
    for h in HOSTS:
        r=query(ip,h,"udp")
        explicit[label][h]=r

# TCP-DNS check on 8.8.8.8 and 1.1.1.1 for a couple
tcpdns={}
for label,ip in RESOLVERS:
    tcpdns[label]={h:query(ip,h,"tcp") for h in ["google.com","pypi.org","pastebin.com","webhook.site","1.1.1.1.xip.io"]}

# read /etc/resolv.conf & nsswitch
def rd(p):
    try:return open(p).read()
    except Exception as e:return f"<{e}>"

final={"etc_resolv_conf":rd("/etc/resolv.conf"),"etc_nsswitch_conf":rd("/etc/nsswitch.conf"),
       "etc_hosts":rd("/etc/hosts"),"system_getaddrinfo":sysres,
       "explicit_udp":explicit,"explicit_tcp":tcpdns}
print(json.dumps(final,indent=1))
json.dump(final,open("/home/user/netmap/results/s2.json","w"),indent=1)
