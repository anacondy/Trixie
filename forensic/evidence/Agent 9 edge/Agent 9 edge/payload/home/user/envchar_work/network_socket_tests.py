import socket, time, statistics, random, struct, csv
from pathlib import Path
hosts=['google.com','github.com','pypi.org','huggingface.co']
rows=[]
for host in hosts:
    for i in range(5):
        t=time.perf_counter_ns()
        err=''; ips=[]
        try:
            res=socket.getaddrinfo(host,443,type=socket.SOCK_STREAM)
            ips=sorted({r[4][0] for r in res})
            status='ok'
        except Exception as e:
            status='error'; err=f'{type(e).__name__}: {e}'
        ms=(time.perf_counter_ns()-t)/1e6
        rows.append([host,i+1,status,f'{ms:.3f}',','.join(ips),err])
with open('/home/user/envchar_work/dns_getaddrinfo.tsv','w',newline='') as f:
    w=csv.writer(f,delimiter='\t'); w.writerow(['host','iteration','status','elapsed_ms','addresses','error']);w.writerows(rows)

# Minimal direct UDP DNS A query, to configured resolver(s) and 8.8.8.8.
def dns_query(server,name='google.com',timeout=2.0):
    tid=random.randrange(65536)
    flags=0x0100
    header=struct.pack('!HHHHHH',tid,flags,1,0,0,0)
    qname=b''.join(bytes([len(x)])+x.encode() for x in name.split('.'))+b'\0'
    query=header+qname+struct.pack('!HH',1,1)
    family=socket.AF_INET6 if ':' in server else socket.AF_INET
    s=socket.socket(family,socket.SOCK_DGRAM); s.settimeout(timeout)
    t=time.perf_counter_ns()
    try:
        s.sendto(query,(server,53)); data,peer=s.recvfrom(4096)
        ms=(time.perf_counter_ns()-t)/1e6
        if len(data)<12: raise RuntimeError('short DNS reply')
        rid,rflags,qd,an,ns,ar=struct.unpack('!HHHHHH',data[:12])
        if rid!=tid: raise RuntimeError('transaction ID mismatch')
        return 'ok',ms,f'bytes={len(data)} answers={an} rcode={rflags&15} peer={peer[0]}'
    except Exception as e:
        ms=(time.perf_counter_ns()-t)/1e6
        return 'error',ms,f'{type(e).__name__}: {e}'
    finally:s.close()
servers=[]
try:
    for line in Path('/etc/resolv.conf').read_text().splitlines():
        if line.strip().startswith('nameserver '): servers.append(line.split()[1])
except Exception: pass
if '8.8.8.8' not in servers: servers.append('8.8.8.8')
udprows=[]
for server in servers:
    for i in range(3):
        status,ms,note=dns_query(server)
        udprows.append([server,i+1,status,f'{ms:.3f}',note])
with open('/home/user/envchar_work/dns_udp.tsv','w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['server','iteration','status','elapsed_ms','note']);w.writerows(udprows)

# Direct TCP probes (not HTTP proxy aware): two attempts each.
targets=[
 ('google.com',80),('google.com',443),
 ('8.8.8.8',53),('8.8.8.8',443),
 ('github.com',22),('github.com',80),('github.com',443),('github.com',9418),
 ('pypi.org',80),('pypi.org',443),('huggingface.co',80),('huggingface.co',443),
]
tcprows=[]
for host,port in targets:
    for i in range(2):
        t=time.perf_counter_ns(); peer=''; err=''
        try:
            with socket.create_connection((host,port),timeout=3.0) as s:
                peer=s.getpeername()[0]; status='connected'
        except Exception as e:
            status='failed';err=f'{type(e).__name__}: {e}'
        ms=(time.perf_counter_ns()-t)/1e6
        tcprows.append([host,port,i+1,status,f'{ms:.3f}',peer,err])
with open('/home/user/envchar_work/tcp_ports.tsv','w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['host','port','iteration','status','elapsed_ms','peer','error']);w.writerows(tcprows)

print('=== getaddrinfo ==='); print(Path('/home/user/envchar_work/dns_getaddrinfo.tsv').read_text())
print('=== UDP DNS ==='); print(Path('/home/user/envchar_work/dns_udp.tsv').read_text())
print('=== TCP ports ==='); print(Path('/home/user/envchar_work/tcp_ports.tsv').read_text())
