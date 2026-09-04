#!/usr/bin/env python3
"""Section 5 - TLS interception: cert chain, local CA discovery, MITM sweep (20 hosts).
These were originally run inline; saved here verbatim for reproducibility."""
import ssl, socket, subprocess, json, os, re

def sh(cmd):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return p.stdout + (("\n[stderr] " + p.stderr) if p.stderr.strip() else "")

print("===== curl -svI https://pypi.org =====")
print(sh(r"""curl -svI https://pypi.org 2>&1 | grep -iE 'issuer|subject|SSL|certificate|CApath|CAfile|TLS|ALPN|HTTP/|connected to|start date'"""))
print("===== openssl s_client pypi.org:443 =====")
print(sh("echo | timeout 20 openssl s_client -connect pypi.org:443 -servername pypi.org 2>/dev/null | openssl x509 -noout -issuer -subject -dates -serial -fingerprint"))
print("===== full chain =====")
print(sh("echo | timeout 20 openssl s_client -connect pypi.org:443 -servername pypi.org -showcerts 2>/dev/null | grep -E '^\\s*[0-9]+ s:|^\\s*[0-9]+ i:|s:|i:'"))
print("===== verify result =====")
print(sh("echo | timeout 20 openssl s_client -connect pypi.org:443 -servername pypi.org 2>&1 | grep -E 'Verify return code|verify error|depth=|Verification'"))

print("===== LOCAL CA STORE CHECK =====")
print(sh("ls -la /usr/local/share/ca-certificates/ 2>/dev/null || echo '(none)'"))
print(sh("ls /etc/ssl/certs/*.pem | wc -l"))
print(sh("openssl version -d"))

# how many certs in the active bundle, and is an e2b one among them?
bundle = open("/etc/ssl/certs/ca-certificates.crt").read()
certs = re.findall(r"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----", bundle, re.S)
print(f"certs in /etc/ssl/certs/ca-certificates.crt: {len(certs)}")
for i, c in enumerate(certs):
    o = subprocess.run(["openssl", "x509", "-noout", "-subject", "-issuer", "-dates"],
                       input=c, capture_output=True, text=True).stdout
    if "e2b" in o.lower():
        print(f"  MATCH #{i}: {o.strip()}")

HOSTS = ["pypi.org","google.com","github.com","huggingface.co","pastebin.com","webhook.site",
         "transfer.sh","ngrok.io","api.anthropic.com","openai.com","files.pythonhosted.org",
         "raw.githubusercontent.com","registry.npmjs.org","cloudflare.com","speed.cloudflare.com",
         "events.e2b.local","1.1.1.1","scanme.nmap.org","ubuntu.com","wikipedia.org"]
out = []
for h in HOSTS:
    try:
        ctx = ssl.create_default_context()
        with socket.create_connection((h, 443), timeout=8) as s:
            with ctx.wrap_socket(s, server_hostname=h) as ss:
                c = ss.getpeercert(); ver = ss.version()
        iss = dict(x[0] for x in c["issuer"]); sub = dict(x[0] for x in c["subject"])
        row = {"host": h, "tls": ver, "subject": sub.get("commonName"),
               "issuer_O": iss.get("organizationName"), "issuer_CN": iss.get("commonName"),
               "notAfter": c.get("notAfter"), "verified": "YES (default trust store)"}
    except Exception as e:
        row = {"host": h, "error": f"{type(e).__name__}: {str(e)[:150]}"}
    out.append(row)
    print(f"{h:26s} -> {row.get('issuer_CN') or row.get('error')}")
json.dump(out, open("results/s5_mitm.json", "w"), indent=1)
