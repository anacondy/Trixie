#!/usr/bin/env python3
"""Section 5 - broad TLS-issuer sweep: does ANY host present an 'E2B Proxy CA' cert?"""
import ssl, socket, json
from concurrent.futures import ThreadPoolExecutor
from collections import Counter

HOSTS = ["google.com","youtube.com","facebook.com","twitter.com","instagram.com","linkedin.com",
 "amazon.com","microsoft.com","apple.com","netflix.com","reddit.com","wikipedia.org",
 "stackoverflow.com","gitlab.com","bitbucket.org","docker.io","quay.io","cdn.jsdelivr.net",
 "unpkg.com","fonts.googleapis.com","pypi.org","npmjs.com","crates.io","rubygems.org",
 "maven.org","debian.org","archive.ubuntu.com","alpinelinux.org","archlinux.org",
 "openai.com","anthropic.com","api.anthropic.com","claude.ai","huggingface.co","kaggle.com",
 "pastebin.com","gist.github.com","webhook.site","requestbin.com","ngrok.io","tailscale.com",
 "warp.dev","discord.com","telegram.org","signal.org","proton.me","torproject.org",
 "speed.cloudflare.com","cloudflare.com","example.com","iana.org","icann.org"]

def chk(h):
    try:
        ctx = ssl.create_default_context()
        with socket.create_connection((h, 443), timeout=10) as s:
            with ctx.wrap_socket(s, server_hostname=h) as ss:
                c = ss.getpeercert(); v = ss.version()
        iss = dict(x[0] for x in c["issuer"])
        return (h, "OK", v, iss.get("organizationName", "") + " / " + iss.get("commonName", ""))
    except Exception as e:
        return (h, "FAIL", f"{type(e).__name__}", str(e)[:70])

with ThreadPoolExecutor(max_workers=20) as ex:
    rows = list(ex.map(chk, HOSTS))
e2b = [r for r in rows if "E2B" in str(r[3]).upper()]
ok  = [r for r in rows if r[1] == "OK"]
print(f"tested={len(rows)}  tls-ok={len(ok)}  failed={len(rows)-len(ok)}")
print(f"hosts presenting an 'E2B Proxy CA' certificate: {len(e2b)}")
for r in e2b: print("  !!!", r)
print("--- distinct CAs seen (top 15) ---")
for ca, n in Counter(r[3] for r in ok).most_common(15): print(f"  {n:>3d}  {ca}")
print("--- failures ---")
for r in rows:
    if r[1] == "FAIL": print(f"  {r[0]:26s} {r[2]:22s} {r[3][:60]}")
json.dump([{"host": r[0], "status": r[1], "tls": r[2], "issuer": r[3]} for r in rows],
          open("results/s5_sweep.json", "w"), indent=1)
