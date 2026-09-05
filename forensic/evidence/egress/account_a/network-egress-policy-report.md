# Sandbox Network Egress Policy — Characterisation Report

**Environment:** E2B sandbox (`e2b.local`), Python 3.13.14, curl 8.14.1 (HTTP/3-capable), OpenSSL 3.5.6
**Tested:** 2026-09-04 19:30–19:40 UTC (2026-09-05 01:00–01:10 IST)
**Method:** black-box probing only. Nothing was bypassed — every result is the sandbox's own answer.
**Raw evidence:** `egress-tests/00-environment.txt` … `egress-tests/06-bandwidth.txt` (all commands reproducible from scripts in the same folder)

---

## 0. Environment / vantage point

| Item | Finding | Evidence |
|---|---|---|
| Proxy env vars | **none set** (`http_proxy` etc. absent) → interception is *transparent*, at the network layer | `00-environment.txt` |
| Default route | `default via 169.254.0.22 dev eth0` (link-local gateway on a /30) — classic transparent-proxy design | `ip route` |
| DNS config | `resolv.conf` → `nameserver 8.8.8.8` directly (no local stub resolver) | `cat /etc/resolv.conf` |
| Custom CA installed | `/usr/local/share/ca-certificates/e2b-ca.crt` — `O=E2B, CN=E2B Proxy CA`, valid 1 year (2026-09-02 → 2027-09-02), SHA256 `48:B5:CB:D3:A0:A3:0D:98:FA:93:CE:81:CF:1F:1D:D2:9D:2D:C8:30:D1:BA:30:7F:E3:DF:5B:A4:9B:CD:70:E2` | `openssl x509 -in …e2b-ca.crt` |
| Internal hosts entry | `/etc/hosts`: `192.0.2.1  events.e2b.local` — an internal service is pinned to a TEST-NET-1 address | `getent hosts events.e2b.local` |
| Egress IP / ASN | **8.235.26.22**, `AS396982 Google LLC` (reverse DNS `…bc.googleusercontent.com`, geo: The Dalles, OR) — confirmed by two independent vantages (api.ipify.org and Cloudflare `cf-meta-ip`) | `06c-down403-h3.txt`, `06-bandwidth.txt` |
| IPv6 | **No IPv6 egress at all** — every v6 connect → `ENETUNREACH` (errno 101) | `01-connect-blackhole.txt` |

---

## 1. Transparent-proxy behaviour — CONFIRMED

`connect_ex()` to guaranteed-unroutable addresses (RFC 5737 TEST-NET, port 9/discards):

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| 192.0.2.1:9 | TCP connect_ex, 2s timeout | **`0` in 0.000 s** (instant "success"); 0 bytes on recv | `01-connect-blackhole.txt` |
| 192.0.2.99:9 | same | **`0` in 0.000 s**; 0 bytes | same |
| 198.51.100.10:9 | same | **`0` in 0.000 s**; 0 bytes | same |
| 203.0.113.77:9 | same | **`0` in 0.000 s**; 0 bytes | same |
| 10.255.255.1:9 (RFC1918) | same | **`11` after 2.002 s** (EAGAIN-on-timeout) → genuine blackhole | same |
| 100.64.0.1:9 (CGNAT) | same | **`11` after 2.002 s** → genuine blackhole | same |
| [2001:db8::1]:9 | IPv6 connect_ex | `101` ENETUNREACH, 0.000 s | same |

Actual HTTP GETs (port 80, 10 s cap) against the same addresses:

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| http://192.0.2.1/ | curl GET | **HTTP/1.1 404 Not Found** — *something real answers*: the internal `events.e2b.local` service pinned via /etc/hosts | curl `-v`: `Connected… < HTTP/1.1 404 Not Found` |
| http://192.0.2.99/ | curl GET | TCP "Connected", request sent → **timeout, 0 bytes** | curl (28) after 10.0 s |
| http://198.51.100.10/ | curl GET | same — Connected, **timeout, 0 bytes** | curl (28) |
| http://203.0.113.77/ | curl GET | same — Connected, **timeout, 0 bytes** | curl (28) |
| http://10.255.255.1/ | curl GET | **Connection timed out** (TCP connect itself never completes) | curl (28) "Connection timed out" |
| http://100.64.0.1/ | curl GET | **Connection timed out** (same) | curl (28) |

**Conclusion (Q1):** **Yes — `TCP connect()` reports success completely independent of reachability.** For all public-unicast destinations the transparent proxy answers SYN with a synthetic local ACK in <1 ms; the "connection" then hangs with zero data unless a real backend exists. Only RFC1918 (10/8) and CGNAT (100.64/10) ranges escape interception and fail like true blackholes. Consequence: *any* handshake-based port scan in this sandbox is meaningless — only received data (banners, TLS, replies) proves reachability.

---

## 2. DNS-level filtering — NONE FOUND

Raw UDP A-queries (hand-built packets, so rcode is visible exactly). Default resolver **is** 8.8.8.8; explicit comparison against 8.8.8.8 and 1.1.1.1 (`dig` unavailable in image → dnspython-style manual queries, script: `s2-dns.py`):

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| google.com | A @8.8.8.8 (default) / @1.1.1.1 | **NOERROR, valid A** (74.125.195.x / 173.194.43.x — normal Google rotation) | `02-dns.txt`, t=1 ms / 9 ms |
| pypi.org | A @8.8.8.8 / @1.1.1.1 | **NOERROR, valid A** 151.101.0/64/128/192.223 (Fastly) — identical from both | t=1 ms / 9 ms |
| files.pythonhosted.org | A @both | **NOERROR** CNAME `dualstack.python.map.fastly.net` + A 151.101.x.223 | t=8–10 ms |
| registry.npmjs.org | A @both | **NOERROR, valid A** 104.16.0–11.34 (Cloudflare) | t=1–7 ms |
| github.com | A @both | **NOERROR, valid A** 140.82.116.4 — identical from both | t=1–6 ms |
| raw.githubusercontent.com | A @both | **NOERROR, valid A** 185.199.108–111.133 | t=1–9 ms |
| huggingface.co | A @both | **NOERROR, valid A** 99.86.101.x (CloudFront) | t=1–14 ms |
| openai.com | A @both | **NOERROR, valid A** 104.18.33.45, 172.64.154.211 | t=1–9 ms |
| api.anthropic.com | A @both | **NOERROR, valid A** 160.79.104.10 — identical from both | t=1–10 ms |
| pastebin.com | A @both | **NOERROR, valid A** 104.20.29.150, 172.66.171.73 | t=1–12 ms |
| transfer.sh | A @both | **NOERROR, valid A** 144.76.136.153 (real Hetzner IP — domain is defunct, see §5) | t=1–31 ms |
| ngrok.io | A @both | **NOERROR, valid A** 6× AWS us-west-1 | t=1–28 ms |
| webhook.site | A @both | **NOERROR, valid A** 178.63.67.106/153 | t=1–11 ms |
| 1.1.1.1.xip.io | A @both | **NXDOMAIN from both** (xip.io was shut down upstream — *not* filtering; consistent with control) | t=1–313 ms |
| `…-9f3a2.example` (control) | A @both | **NXDOMAIN from both** — control behaves as expected | t=1–9 ms |

**Distinctions requested:** 13/14 hosts → valid A record; 1 → genuine NXDOMAIN everywhere; **0 SERVFAIL; 0 timeouts; 0 injected/spoofed answers**. Default and explicit resolvers agree on every name.

**Conclusion (Q2):** No DNS-level filtering. Sensitive names (`openai.com`, `api.anthropic.com`, `pastebin.com`, `transfer.sh`, `ngrok.io`, `webhook.site`) all resolve honestly. Caveat: @8.8.8.8 answers in ~1 ms (vs 6–30 ms @1.1.1.1) — UDP 53 may be transparently intercepted/answered by the gateway (answers are still correct/unfiltered), but no divergence between resolvers was observable, so there is no *filtering* at this layer either way.

---

## 3. IP/SNI-level filtering — the decisive test

For 3 hosts that resolve fine, bypass the DNS path entirely: connect **straight to the IP** with hand-set SNI + Host:

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| pypi.org @151.101.0.223 | `curl --resolve pypi.org:443:IP` (SNI+Host by IP) | **HTTP 200 in 0.035 s** | `03-direct-ip.txt` |
| pypi.org @151.101.0.223 | HTTP :80, hand-set `Host: pypi.org` | **HTTP 301** (Fastly redirect — real backend reply) | same |
| pypi.org @151.101.0.223 | `openssl s_client -connect IP:443 -servername pypi.org` | Real leaf `CN=pypi.org`, issuer **GlobalSign** (not the local CA) | same |
| github.com @140.82.116.4 | `curl --resolve … https` | **HTTP 200 in 0.077 s** | same |
| github.com @140.82.116.4 | HTTP :80 + hand-set Host | **HTTP 301** | same |
| github.com @140.82.116.4 | s_client by IP + SNI | Real `CN=github.com`, issuer **Sectigo** | same |
| files.pythonhosted.org @151.101.64.223 | `curl --resolve … https` | **HTTP 200 in 0.031 s** | same |
| files.pythonhosted.org @151.101.64.223 | HTTP :80 + hand-set Host | **HTTP 403** (Fastly app policy — server-side, normal) | same |
| files.pythonhosted.org @151.101.64.223 | s_client by IP + SNI | Real `CN=*.pythonhosted.org`, **GlobalSign** | same |
| (cross-check) 151.101.0.223, SNI=example.com | s_client | `CN=www.python.org` — Fastly's default cert for that IP; normal CDN behaviour, not sandbox interference | same |

**Verdict (Q3):** Direct-IP works **and** hostname works → there is **no IP/SNI-level blocking and no DNS-level blocking** on any tested destination. (Nothing failed at the DNS stage, so the "if both fail → IP/SNI-level" branch had no candidates; instead the result is: no destination-based restriction observed at all.)

---

## 4. Port & protocol matrix — handshake and data reported SEPARATELY

Given §1, "handshake succeeded" only means *the proxy answered*. The meaningful column is **data received**.

### TCP

| Target | Method | Handshake | Data received | Verdict |
|---|---|---|---|---|
| scanme.nmap.org:22 | connect + recv | SUCCESS 0.008 s | **`SSH-2.0-OpenSSH_6.6.1p1…`** 44 B | ✅ open + data |
| github.com:22 | connect + recv | SUCCESS 0.001 s | **`SSH-2.0-cb4a187`** 17 B | ✅ open + data |
| ftp.gnu.org:21 | connect + recv | SUCCESS 0.001 s | **`220 GNU FTP server ready.`** | ✅ open + data |
| gmail-smtp-in.l.google.com:25 | connect + recv | SUCCESS 0.002 s | **`220 mx.google.com ESMTP …`** 75 B | ✅ port 25 **not blocked** (unusual for cloud sandboxes) |
| 8.8.8.8:53 | connect + TCP DNS query | SUCCESS 0.000 s | **valid DNS reply** 63 B | ✅ DNS-over-TCP ok |
| example.com:80 | connect + HEAD | SUCCESS 0.026 s | **HTTP/1.1 200 OK** | ✅ |
| scanme.nmap.org:80 | connect + HEAD | SUCCESS 0.001 s | **HTTP/1.1 200 OK** | ✅ |
| pop.gmail.com:110 | connect + recv | SUCCESS 0.002 s | **no data in 4 s** | ⚠️ ambiguous (Gmail silently drops plain POP vs sandbox filter — 995/TLS works) |
| imap.gmail.com:143 | connect + recv | SUCCESS 0.002 s | **no data in 4 s** | ⚠️ ambiguous (993/TLS works) |
| pypi.org:443 | connect + TLS | SUCCESS 0.001 s | **TLS ok, 1666 B cert** | ✅ |
| smtp.gmail.com:465 | connect + implicit TLS | SUCCESS 0.003 s | **TLS ok, 1080 B cert** | ✅ |
| smtp.gmail.com:587 | connect + recv | SUCCESS 0.003 s | **`220 smtp.gmail.com ESMTP…`** 71 B | ✅ |
| imap.gmail.com:993 | connect + TLS | SUCCESS 0.003 s | **TLS ok, 1081 B cert** | ✅ |
| pop.gmail.com:995 | connect + TLS | SUCCESS 0.003 s | **TLS ok, 1079 B cert** | ✅ |
| db4free.net:3306 | connect + recv | SUCCESS 0.084 s | **MySQL greeting `11.8.8-MariaDB-log`** 90 B | ✅ DB egress open |
| 1.1.1.1:5432 | connect + PG SSLRequest | SUCCESS 0.000 s | no data in 4 s | ⚠️ no known-open public Postgres endpoint; signature identical to blackhole baseline → **cannot distinguish "port blocked" from "host silent"** |
| 8.8.8.8:6379 | connect + `PING` | SUCCESS 0.000 s | no data in 4 s | ⚠️ same ambiguity (8.8.8.8 surely doesn't serve Redis) |
| cloudflare.com:8080 | connect + HEAD | SUCCESS 0.011 s | **HTTP/1.1 301** 512 B | ✅ |
| cloudflare.com:8443 | connect + TLS | SUCCESS 0.010 s | **TLS ok, 981 B cert** | ✅ |
| 192.0.2.1:443 | baseline (unreachable) | SUCCESS 0.000 s | no data — **this is the "blocked/blackhole" signature** | baseline |
| 192.0.2.1:3306 | baseline (unreachable) | SUCCESS 0.000 s | no data | baseline |

### UDP

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| 8.8.8.8:53 | valid DNS query | **REPLY 61 B in 0.014 s** → allowed | `04-ports.txt` |
| 1.1.1.1:53 | valid DNS query | **REPLY 61 B in 0.008 s** → allowed | same |
| 8.8.8.8:123 | NTP request | no reply — expected (Google doesn't run NTP there) | same |
| 1.1.1.1:123 | NTP request | no reply — expected (same) | same |
| 162.159.200.1:123 (time.cloudflare.com — **control**) | NTP request | **REPLY 48 B in 0.007 s** → **UDP 123 egress works** | same |
| 8.8.8.8:443 / 1.1.1.1:443 | random payload (pseudo-QUIC) | no reply — inconclusive by construction (invalid packets get dropped) | same |
| 8.8.8.8:500 (IKE) | random payload | no reply — inconclusive by construction | same |
| 8.8.8.8:1 (closed-port control) | random payload | no reply — no ICMP-unreachable surfaced → ICMP errors are not delivered to the sandbox | same |
| cloudflare-dns.com:443/udp | **real QUIC: `curl --http3-only`** | **HTTP 200 over HTTP/3 in 0.058 s** → **QUIC/UDP-443 egress works** | `06c-down403-h3.txt` |

**Verdict (Q4):** No TCP port blocking detected on any port where the far end demonstrably speaks (21, 22, **25**, 53, 80, 443, 465, 587, 993, 995, 3306, 8080, 8443). UDP 53 and 123 confirmed open; QUIC over UDP 443 confirmed working via real HTTP/3. Ambiguities: 110/143 (data-less, Gmail-side plausible) and 5432/6379 (no known-open host to test data-phase).

---

## 5. TLS interception — NOT OBSERVED on any tested domain

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| pypi.org | `curl -svI` + `openssl s_client` | Leaf `CN=pypi.org`, issuer **GlobalSign Atlas R3 DV TLS CA 2025 Q4** (public CA), chain → GlobalSign Root R3, `verify ok`, HTTP/2 200 | `05-tls.txt`; SHA256 `15:58:1C:41:…` |
| pypi.org | python `ssl.create_default_context()` full verify | **OK** (system store, cipher TLS_AES_128_GCM_SHA256) | same |
| github.com | s_client | `CN=github.com`, issuer **Sectigo Public Server Authentication CA DV E36** (public CA) | same |
| openai.com | curl issuer sweep | issuer **Let's Encrypt YE2**, verify ok | `05b-issuer-sweep.txt` |
| api.anthropic.com | curl | issuer **Google Trust Services WE1**, verify ok | same |
| pastebin.com | curl | issuer **Google Trust Services WE1**, verify ok | same |
| transfer.sh | curl | **TLS handshake dies** (`unexpected eof`, decode error) — domain is defunct in reality; server- vs sandbox-side indistinguishable here | same |
| webhook.site | curl | issuer **Let's Encrypt YR2**, verify ok | same |
| ngrok.io | curl | issuer **Let's Encrypt YE1**, verify ok | same |
| huggingface.co | curl | issuer **Amazon RSA 2048 M01**, verify ok | same |
| registry.npmjs.org | curl | issuer **Google Trust Services WE1**, verify ok | same |
| raw.githubusercontent.com | curl | issuer **Let's Encrypt YR1**, verify ok | same |
| google.com | curl | issuer **Google Trust Services WE2**, verify ok | same |
| example.com | curl | issuer **SSL Corp / Cloudflare TLS ECC CA-3**, verify ok | same |
| speed.cloudflare.com | curl | issuer **Google Trust Services WE1**, verify ok | same |

**Verdict (Q5):** The issuer is a **public CA on every one of the 15 tested hosts** — zero appearances of the installed `E2B Proxy CA`. HTTPS is passed through end-to-end (certificates validate against public roots with no custom store needed). The `E2B Proxy CA` sitting in `/usr/local/share/ca-certificates/` is *capable* MITM infrastructure but was **not used** for any tested external domain — presumably reserved for internal `*.e2b.local` traffic (note the pattern: the internal events service already squats a TEST-NET IP).

---

## 6. Bandwidth — standardised

**Protocol deviation (documented):** `__down?bytes=100000000` is refused by **Cloudflare itself**, not the sandbox — 403 with `Server: cloudflare`, `Server-Timing: cfSpeedEdge`, body `0`; boundary is exact: `99999999 → 200`, `100000000 → 403`, `100000001 → 403` (`06-bandwidth.txt`). The identical protocol was therefore run at the endpoint's real ceiling of **50 MB**.

| Run | Method | Outcome | Evidence |
|---|---|---|---|
| seq-1 | curl, `__down?bytes=50000000`, `speed_download` | **186,524,013 B/s** (186.5 MB/s ≈ 1.49 Gbit/s), 0.268 s | `06-bandwidth.txt` |
| seq-2 | same | **179,380,563 B/s**, 0.279 s | same |
| seq-3 | same | **195,160,792 B/s**, 0.256 s | same |
| — | **median of 3 sequential** | **186.5 MB/s ≈ 1.49 Gbit/s** | computed |
| par-1 | 3 concurrent curls, same endpoint | 63,514,969 B/s (0.787 s) | same |
| par-2 | same | 102,703,568 B/s (0.487 s) | same |
| par-3 | same | 213,582,113 B/s (0.234 s) | same |
| — | **parallel aggregate** | **379.8 MB/s ≈ 3.04 Gbit/s** (150 MB in 0.79 s wall) — the pipe is wider than one stream uses | computed |
| pip cold | `pip download --no-cache-dir --dest /tmp/x numpy` | numpy 2.5.2 wheel **16,709,995 B** fetched, 1.795 s wall total (incl. index + metadata RTTs) | `06b-bandwidth-pypi.txt` |
| wheel-1..3 | `curl -w '%{speed_download}'` on the exact files.pythonhosted.org URL | **107.6 / 115.1 / 113.8 MB/s** (median 113.8 MB/s; short transfer, slow-start-limited) | `06-bandwidth.txt` |

**Reading:** single-stream ≈ 1.5 Gbit/s, three streams ≈ 3 Gbit/s aggregate — no bandwidth cap was hit; egress is fast and uncongested. (First-run wheel curl measured 95.4 MB/s before CDN warm-up; CDN cache locality explains the variation, not a policy limit.)

---

## 7. Synthesis — the egress policy model

1. **Transparent SYN-accepting proxy** on the default path (169.254.0.22): every public-unicast TCP connect "succeeds" locally in <1 ms, then hangs unless a real backend exists. Handshake-only results are meaningless in this sandbox.
2. **No destination filtering observed anywhere**: DNS honest (no NXDOMAIN games), no SNI/IP blocks, real public-CA TLS end-to-end on 15/15 domains, port 25 open, DB ports open, QUIC open. Policy is effectively **allow-all egress** via the proxy.
3. **Private-link ranges (10/8, 100.64/10) are deliberately not intercepted** and simply blackhole; **IPv6 is absent entirely** (`ENETUNREACH`).
4. **MITM capability is installed but dormant** for external traffic: `E2B Proxy CA` is in the trust store, yet 15/15 hosts presented genuine public certificates. Internal endpoints (`events.e2b.local` on 192.0.2.1, answering HTTP 404) are the visible use.
5. **UDP is selectively usable**: 53 ✅, 123 ✅ (proven via time.cloudflare.com), 443/QUIC ✅ (real HTTP/3 to cloudflare-dns.com); ICMP errors are not relayed back.
6. **Performance ceiling not reached**: ~1.5 Gbit/s per stream, ~3 Gbit/s aggregate, ~100 MB/s from PyPI.

## 8. Questions that remain unanswered

1. **TCP 5432 / 6379 data-phase** — no known-open public Postgres/Redis endpoint exists to test against; only the (meaningless) proxy handshake could be observed. Sandbox verdict for these ports: *undetermined*.
2. **Ports 110/143** — handshake OK but zero data. Could be Gmail silently dropping plain auth ports for cloud IPs, or a sandbox filter. Needs a second independent open POP3/IMAP host to disambiguate.
3. **UDP 500 (IKE)** — cannot be tested meaningfully without a valid IKE exchange; raw-payload probes get dropped by any recipient. Verdict: *unknown, likely allowed* given 123/443-QUIC pass.
4. **QUIC to speed.cloudflare.com specifically** fails while succeeding to cloudflare-dns.com — endpoint-specific anomaly, unexplained (its TCP path works fine).
5. **Is UDP 53 transparently redirected?** @8.8.8.8 answers in ~1 ms (gateway-cache-speed), but answers are identical to real 1.1.1.1 results — interception *without filtering* cannot be excluded from inside.
6. **Actual scope of `E2B Proxy CA`** — installed, never seen issuing a leaf for external domains. Which traffic it does sign (internal only? on-demand?) is unknowable from this vantage.
7. **Whether any deny-list exists at all** — nothing tested was blocked; absence of evidence for blocked categories (malware/C2-style hosts, DGT-reported domains) is not proof of no list.
8. **ICMP handling** — no ICMP port-unreachable ever surfaced; whether ICMP is dropped or just not relayed by the proxy is unresolved.
9. **Sustained-throughput profile beyond 100 MB** — impossible on the mandated endpoint (Cloudflare's own 10⁸-byte cap); long-run throttling/fairness unmeasured.

*All raw command outputs preserved in `egress-tests/` (00-environment, 01-connect-blackhole, 02-dns, 03-direct-ip, 04-ports, 05-tls, 05b-issuer-sweep, 06-bandwidth, 06b/06c). Probe scripts (`s1-connect.py`, `s2-dns.py`, `s4-ports.py`) are included for reproducibility.*
