Map this sandbox's network egress POLICY. Do not attempt to bypass anything —
characterise only. Report every result as a table row: target | method | outcome | evidence.

1. TRANSPARENT-PROXY BEHAVIOUR (confirm and quantify)
   - `time python3 -c "import socket;s=socket.socket();s.settimeout(2);print(s.connect_ex(('192.0.2.1',9)))"`
   - repeat for 3 RFC5737 TEST-NET addresses and 2 reserved ranges (10.255.255.1, 100.64.0.1)
   - for each, ALSO attempt an actual HTTP GET and report the real outcome
   - conclusion: does TCP connect() report success independent of reachability?

2. DNS-LEVEL FILTERING
   - resolve each: google.com, pypi.org, files.pythonhosted.org, registry.npmjs.org,
     github.com, raw.githubusercontent.com, huggingface.co, openai.com, api.anthropic.com,
     pastebin.com, transfer.sh, ngrok.io, webhook.site, 1.1.1.1.xip.io
   - report NXDOMAIN vs SERVFAIL vs timeout vs valid A record — the distinction identifies the mechanism
   - compare against an explicit resolver: `dig @8.8.8.8 <host>` and `dig @1.1.1.1 <host>` if available,
     else python dnspython/socket with a manual query. If results differ from the default resolver,
     filtering is DNS-level.

3. IP/SNI-LEVEL FILTERING (the decisive test)
   - for 3 hosts that resolve fine, connect directly by IP with a hand-set Host header / SNI
   - if direct-IP works but hostname fails → DNS-level. If both fail → IP/SNI-level.

4. PORT & PROTOCOL MATRIX
   - TCP: 21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,6379,8080,8443 to a known-open host
   - UDP: 53,123,443,500 to 8.8.8.8 and 1.1.1.1
   - report handshake-succeeded vs data-received SEPARATELY (your earlier runs conflated these)

5. TLS INTERCEPTION
   - `curl -svI https://pypi.org 2>&1 | grep -iE 'issuer|subject|SSL'`
   - `openssl s_client -connect pypi.org:443 -servername pypi.org </dev/null 2>/dev/null | openssl x509 -noout -issuer -subject -dates`
   - is the issuer a public CA or a local one?

6. BANDWIDTH — STANDARDISED (your earlier numbers were unusable, see protocol below)
   - one endpoint only: https://speed.cloudflare.com/__down?bytes=100000000
   - 3 sequential runs, 3 parallel runs, report each individually plus median
   - also `curl -o /dev/null -w '%{speed_download}' ` on a 16 MB PyPI wheel, cold cache
     (`pip download --no-cache-dir --dest /tmp/x numpy`)

State explicitly which questions remain unanswered.
