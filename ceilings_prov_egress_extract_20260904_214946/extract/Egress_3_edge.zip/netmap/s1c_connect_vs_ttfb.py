import subprocess,json
# curl separates: time_connect (TCP handshake) vs time_starttransfer (first byte of DATA).
# If time_connect is ~0 for a host 300ms away but time_starttransfer is 300ms, the
# handshake is being completed LOCALLY by an interceptor.
HOSTS=["https://www.google.com/","https://pypi.org/","https://github.com/",
 "https://www.amazon.co.jp/","https://www.uol.com.br/","https://www.telstra.com.au/",
 "https://www.chinadaily.com.cn/","https://huggingface.co/","https://pastebin.com/",
 "https://webhook.site/","https://transfer.sh/","https://ngrok.io/",
 "https://api.anthropic.com/","https://openai.com/","https://files.pythonhosted.org/",
 "https://raw.githubusercontent.com/","https://registry.npmjs.org/",
 "https://scanme.nmap.org/","https://events.e2b.local/","https://192.0.2.1/"]
FMT='{"code":%{http_code},"dns":%{time_namelookup},"tcp":%{time_connect},"tls":%{time_appconnect},"ttfb":%{time_starttransfer},"total":%{time_total},"size":%{size_download}}'
rows=[]
print(f"{'HOST':38s} {'code':>5s} {'DNS_s':>7s} {'TCP_s':>7s} {'TLS_s':>7s} {'TTFB_s':>7s} {'TTL_s':>7s}  bytes")
for h in HOSTS:
    p=subprocess.run(["curl","-s","-o","/dev/null","--max-time","20","-w",FMT,h],
                     capture_output=True,text=True)
    try:
        d=json.loads(p.stdout)
    except Exception:
        d={"code":"ERR","err":p.stderr.strip()[:120]}
        print(f"{h:38s} ERROR {d['err']}"); rows.append({"host":h,**d}); continue
    rows.append({"host":h,**d})
    print(f"{h:38s} {str(d['code']):>5s} {d['dns']:>7.3f} {d['tcp']:>7.3f} {d['tls']:>7.3f} {d['ttfb']:>7.3f} {d['total']:>7.3f}  {d['size']:>9d}")
json.dump(rows,open("results/s1c.json","w"),indent=1)
