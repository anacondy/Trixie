# Sandbox Network Egress Policy — Characterisation Map

**Date:** 2026-09-05 (UTC 2026-09-04T19:44Z start) · **Location context:** Jaipur, IN (user tz)
**Host:** `/home/user` sandbox · Python 3.13.14 · curl 7.x · OpenSSL · no `dig`/`nslookup`/`nc` (pure-Python DNS client used instead)
**Scope:** characterise only — no bypassing, no circumvention attempted at any point.

---

## TL;DR — conclusions

| # | Question | Answer |
|---|----------|--------|
| 1 | Transparent proxy on the egress path? | **YES, partial.** TCP `connect()` succeeds locally (~0.2 ms) for RFC5737 TEST-NET addresses and for *any* port on public IPs, but NOT for RFC1918 `10/8` or CGNAT `100.64/10` (those time out). A local terminator completes the SYN. |
| 2 | DNS-level filtering? | **NO.** Every host resolves with a clean, unique, real A record (NOERROR) from 8.8.8.8 / 1.1.1.1. No NXDOMAIN/SERVFAIL spoofing, no wildcard sinkhole. Only dead `xip.io` returns NXDOMAIN — honestly, from 8.8.8.8. |
| 3 | IP / SNI-level filtering? | **NO.** Direct-IP TLS (SNI) and direct-IP HTTP (Host header) both work for all 5 tested hosts. |
| 4 | Port blocking? | **No port is refused.** Every TCP port 21–8443 completes a handshake in ~0 ms (SYN answered locally). Real data flows only on ports where a real backend exists (53, 80, 443). UDP 53 works; UDP 123/443/500 unanswered (ambiguous — see §8). |
| 5 | TLS interception / MITM? | **NO.** Public CA chains (GlobalSign/Sectigo/Google Trust Services), `ssl_verify_result=0`. |
| 6 | Bandwidth | **≈ 1.5–2.1 Gbps** (sequential median **260 MB/s** = 2.08 Gbps on Cloudflare's speed CDN; 100 MB/s on the Fastly PyPI CDN). Cloudflare's `__down` endpoint returns **403 exactly at 100,000,000 bytes** (99 MB works). |

**Key environmental facts (drive most of the above):**

- `/etc/resolv.conf` = `nameserver 8.8.8.8` (so "system resolver" ≡ 8.8.8.8).
- Default route gateway = **169.254.0.22 (link-local)** — egress is via a NAT/proxy on the local link, not a real routed gateway.
- **IPv4-only** sandbox: only `::1` + `fe80::…` exist; `curl -6` fails. No global IPv6.
- No `http_proxy`/`https_proxy`/`all_proxy` env vars set.

---

## 1. Transparent-proxy behaviour (does `connect()` lie?)

Method: raw `socket.connect_ex()` (2 s timeout) to RFC5737 TEST-NET + reserved ranges + real-internet controls, on TCP ports 9 and 80; then a raw HTTP `GET /` with `Host:` and a `urllib` GET over the same socket path. RFC5737 addresses are guaranteed unrouteable on the public internet — a success here can only come from the local egress path.

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| 192.0.2.1 (TEST-NET-1) | TCP connect_ex :9 | **success rc=0** | 0.3 ms — SYN answered locally |
| 192.0.2.1 | TCP connect_ex :80 | **success rc=0** | 0.2 ms |
| 192.0.2.1 | raw HTTP GET :80 (`Host: probe.test`) | **HTTP 404 from a proxy** | body `{"error":"no matching operation was found"}`, `Content-Type: application/json` — a local gateway answered |
| 192.0.2.1 | urllib HTTP GET | HTTP 404 | `HTTP Error 404: Not Found` in 0.01 s |
| 198.51.100.1 (TEST-NET-2) | TCP connect_ex :9 / :80 | **success rc=0** | 0.3 ms / 0.2 ms |
| 198.51.100.1 | raw HTTP GET :80 | no data | TCP accepted, HTTP layer silent (recv timeout) |
| 198.51.100.1 | urllib HTTP GET | timeout | `TimeoutError` after 6 s |
| 203.0.113.1 (TEST-NET-3) | TCP connect_ex :9 / :80 | **success rc=0** | 0.3 ms / 0.3 ms |
| 203.0.113.1 | raw HTTP GET :80 | no data | TCP accepted, no HTTP response |
| 203.0.113.1 | urllib HTTP GET | timeout | `TimeoutError` after 6 s |
| 10.255.255.1 (RFC1918 10/8) | TCP connect_ex :9 | **failure rc=11 (EAGAIN)** | 2002 ms — *not* intercepted |
| 10.255.255.1 | TCP connect_ex :80 | failure rc=11 | 2002 ms |
| 10.255.255.1 | raw HTTP GET :80 | connect timeout | `TimeoutError: timed out` |
| 100.64.0.1 (RFC6598 CGNAT) | TCP connect_ex :9 | **failure rc=11** | 2002 ms |
| 100.64.0.1 | TCP connect_ex :80 | failure rc=11 | 2002 ms |
| 100.64.0.1 | raw HTTP GET :80 | connect timeout | `TimeoutError: timed out` |
| 1.1.1.1 (control, real) | TCP connect_ex :9 | **success rc=0** | 0.4 ms — even "discard" port 9 "connects" |
| 1.1.1.1 | raw HTTP GET :80 | HTTP 409 (real Cloudflare) | `HTTP/1.1 409 Conflict`, `X-Frame-Options: SAMEORIGIN` — genuine internet |
| 8.8.8.8 (control, real) | TCP connect_ex :9 | success rc=0 | 0.3 ms |
| 8.8.8.8 | raw HTTP GET :80 | no data | Google's DNS IP serves no HTTP (real behaviour) |

Literal `time` runs (bash keyword, port 9):

| target | `time python3 -c "…connect_ex(('ip',9))"` | real time |
|--------|-------------------------------------------|-----------|
| 192.0.2.1 | rc= 0 | 0m0.022 s (python startup dominated) |
| 198.51.100.1 | rc= 0 | 0m0.022 s |
| 203.0.113.1 | rc= 0 | 0m0.022 s |
| 10.255.255.1 | rc= 11 | 0m2.026 s |
| 100.64.0.1 | rc= 11 | 0m2.024 s |

**Conclusion:** `connect()` reports success **independent of reachability for the TEST-NET ranges (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24) and for arbitrary ports on public IPs** — a transparent TCP terminator in the egress path completes the handshake locally (~0.2–0.4 ms, far below any real RTT). It is **not** universal: RFC1918 `10/8` and CGNAT `100.64/10` are *not* intercepted and time out. The JSON 404 from `192.0.2.1` proves the terminator is a real L7 proxy that routes by Host/SNI ("no matching operation was found").

---

## 2. DNS-level filtering

Method: A-record lookups via (a) the system resolver (`getaddrinfo`), (b) direct UDP DNS query to `8.8.8.8`, (c) to `1.1.1.1`, (d) to the configured default NS (≡ 8.8.8.8). `dig` unavailable — used a minimal pure-Python DNS client. Reported statuses are actual DNS rcode (NOERROR/NXDOMAIN/SERVFAIL) or TIMEOUT.

| host | outcome | evidence (rcode + A records) |
|------|---------|------------------------------|
| google.com | NOERROR, valid A | system 173.194.202.100/101/102 (3 ms) · @8.8.8.8 74.125.20.100/138/102 · @1.1.1.1 142.251.45.142 — all real Google, all agree |
| pypi.org | NOERROR, valid A | 151.101.0/64/128/192.223 (Fastly) — identical across all resolvers |
| files.pythonhosted.org | NOERROR, valid A | 151.101.x.223 (Fastly) — identical across resolvers |
| registry.npmjs.org | NOERROR, valid A | 104.16.0–11.34 (Cloudflare) — identical |
| github.com | NOERROR, valid A | 140.82.116.4 — identical across resolvers |
| raw.githubusercontent.com | NOERROR, valid A | 185.199.108–111.133 (GitHub Pages) — identical |
| huggingface.co | NOERROR, valid A | 99.86.101.36/39/56/64 (AWS CloudFront) — identical |
| openai.com | NOERROR, valid A | 104.18.33.45, 172.64.154.211 (Cloudflare) — identical |
| api.anthropic.com | NOERROR, valid A | 160.79.104.10 — identical |
| pastebin.com | NOERROR, valid A | 104.20.29.150, 172.66.171.73 (Cloudflare) — identical |
| transfer.sh | NOERROR, valid A | 144.76.136.153 (Hetzner) — identical |
| ngrok.io | NOERROR, valid A | 13.56.217.111 / 184.72.44.51 / 50.18.8.146 (AWS) — identical |
| webhook.site | NOERROR, valid A | 178.63.67.106 / .153 — identical |
| 1.1.1.1.xip.io | **NXDOMAIN** | @8.8.8.8 NXDOMAIN (162 ms), @1.1.1.1 NXDOMAIN (204 ms) — xip.io was retired (2021); honest NXDOMAIN, not injected |

**Wildcard / sinkhole check:** A-record histogram across all 14 hosts shows **45 unique addresses, no IP reused for ≥3 hosts** → no wildcard sinkhole.

**Conclusion:** **No DNS-level filtering.** The configured resolver *is* 8.8.8.8 (plaintext UDP, no DNAT redirection detected — answers match direct 1.1.1.1 queries). NXDOMAIN appears only for a genuinely-dead domain and is returned identically by both public resolvers, ruling out resolver spoofing. No SERVFAIL/timeouts, no divergence between default and explicit resolvers.

---

## 3. IP / SNI-level filtering (decisive test)

Method: resolve each host via 8.8.8.8 (ground truth), then (a) TLS by hostname, (b) TLS to the **raw IP with SNI set to the hostname**, (c) plain HTTP to the **raw IP with `Host:` header**. If direct-IP works where hostname fails → DNS-level; if both fail → IP/SNI-level.

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| pypi.org | TLS by hostname | works | TLSv1.3, 42 ms |
| pypi.org (151.101.192.223 / 151.101.64.223) | TLS direct-IP + SNI=pypi.org | works | TLSv1.3, 25 / 26 ms |
| pypi.org (151.101.192.223) | HTTP direct-IP + `Host: pypi.org` | works | `HTTP/1.1 301 Moved Permanently` |
| github.com | TLS by hostname | works | TLSv1.3, 24 ms |
| github.com (140.82.116.3) | TLS direct-IP + SNI=github.com | works | TLSv1.3, 23 ms |
| github.com (140.82.116.3) | HTTP direct-IP + `Host: github.com` | works | `301 → Location: https://github.com` |
| raw.githubusercontent.com | TLS by hostname | works | TLSv1.3, 29 ms |
| raw.githubusercontent.com (185.199.110/111.133) | TLS direct-IP + SNI | works | TLSv1.3, 27 / 24 ms |
| raw.githubusercontent.com (185.199.110.133) | HTTP direct-IP + Host | works | `301 Moved Permanently` |
| huggingface.co | TLS by hostname | works | TLSv1.3, 47 ms |
| huggingface.co (99.86.101.64 / .39) | TLS direct-IP + SNI | works | TLSv1.3, 22 / 25 ms |
| huggingface.co (99.86.101.64) | HTTP direct-IP + Host | works | `301`, `Server: CloudFront` |
| google.com | TLS by hostname | works | TLSv1.3, 13 ms |
| google.com (74.125.20.101 / .113) | TLS direct-IP + SNI | works | TLSv1.3, 10 ms |
| google.com (74.125.20.101) | HTTP direct-IP + Host | works | `301 → http://www.google.com/` |

**Conclusion:** **No IP-level and no SNI-level filtering.** All three methods succeed everywhere; hostname and direct-IP paths are equivalent. (Filtering, if any, sits below L7 in the SYN-termination behaviour of §1.)

---

## 4. Port & protocol matrix — handshake vs data, reported separately

Method: TCP `connect_ex` to `1.1.1.1` (and control `8.8.8.8`) with a 3 s handshake + 3 s data window; **handshake outcome and data outcome recorded independently** (your earlier runs conflated these — a 0 ms "handshake OK" here does *not* mean the port is open to the internet).

### TCP → 1.1.1.1

| port | handshake | data received? | evidence |
|------|-----------|----------------|----------|
| 21 (FTP) | OK, 0 ms | **none** | recv timeout (no banner) |
| 22 (SSH) | OK, 0 ms | none | recv timeout |
| 25 (SMTP) | OK, 0 ms | none | recv timeout |
| 53 (DNS/TCP) | OK, 0 ms | **YES — 66 B** | real DNS answer for `cloudflare.com` |
| 80 (HTTP) | OK, 0 ms | **YES — 389 B** | `HTTP/1.1 301 Moved Permanently` (Cloudflare) |
| 110 (POP3) | OK, 0 ms | none | recv timeout |
| 143 (IMAP) | OK, 0 ms | none | recv timeout |
| 443 (HTTPS) | OK, 0 ms | **YES** | TLSv1.3 handshake OK, 20 ms |
| 465 (SMTPS) | OK, 0 ms | none | recv timeout |
| 587 (submission) | OK, 0 ms | none | recv timeout |
| 993 (IMAPS) | OK, 0 ms | none | recv timeout |
| 995 (POP3S) | OK, 0 ms | none | recv timeout |
| 3306 (MySQL) | OK, 0 ms | none | recv timeout |
| 5432 (Postgres) | OK, 0 ms | none | recv timeout |
| 6379 (Redis) | OK, 0 ms | none | recv timeout |
| 8080 | OK, 0 ms | none | recv timeout |
| 8443 | OK, 0 ms | none | recv timeout |

### TCP control → 8.8.8.8

| port | handshake | data | evidence |
|------|-----------|------|----------|
| 53 | OK, 0 ms | YES — 66 B | real DNS answer |
| 80 | OK, 0 ms | none | Google DNS serves no HTTP |
| 443 | OK, 0 ms | YES | TLSv1.3 OK, 5 ms |

### UDP

| target | port | outcome | evidence |
|--------|------|---------|----------|
| 8.8.8.8 | 53 | **response** | 61 B DNS, rcode=0 |
| 8.8.8.8 | 123 (NTP) | no response | timeout (8.8.8.8 runs no NTP — ambiguous) |
| 8.8.8.8 | 443 (QUIC) | no response | timeout (ambiguous) |
| 8.8.8.8 | 500 (IKE) | no response | timeout (ambiguous) |
| 1.1.1.1 | 53 | **response** | 61 B DNS, rcode=0 |
| 1.1.1.1 | 123 / 443 / 500 | no response | timeout (ambiguous) |

**Conclusion:** The egress path **accepts every TCP SYN locally (0 ms) regardless of port** — "handshake succeeded" is not evidence of reachability. Actual end-to-end data was observed only on 53/80/443, i.e. ports where the real destination (Cloudflare/Google) actually serves. **UDP egress exists** (DNS/53 answered); whether 123/443/500 are filtered cannot be determined because those servers don't answer those protocols in the first place.

---

## 5. TLS interception

Method: `curl -svI https://pypi.org` (grep issuer/subject/SSL), `openssl s_client … | openssl x509 -noout -issuer -subject -dates`, plus `curl -w %{ssl_verify_result}` (0 = chain validates against the system CA store).

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| pypi.org | curl -vI | **public CA, verify ok** | `issuer: C=BE; O=GlobalSign nv-sa; CN=GlobalSign Atlas R3 DV TLS CA 2025 Q4`, `SSL certificate verify ok.`, TLSv1.3 |
| pypi.org | openssl s_client | **public CA** | issuer=GlobalSign Atlas R3 DV, subject=CN=pypi.org, notBefore 2025-12-28 → notAfter 2027-01-29 |
| pypi.org | curl `ssl_verify_result` | **0 (valid chain)** | `ssl_verify_result=0` |
| github.com | openssl s_client | public CA | issuer=Sectigo Public Server Auth CA DV E36, subject=CN=github.com |
| github.com | curl `ssl_verify_result` | 0 | `ssl_verify_result=0` |
| google.com | openssl s_client | public CA | issuer=Google Trust Services WR2, subject=CN=*.google.com |
| google.com | curl `ssl_verify_result` | 0 | `ssl_verify_result=0` |

**Conclusion:** **No TLS interception.** All issuers are public CAs; certificates validate end-to-end. No local/self-signed CA in the path.

---

## 6. Bandwidth — standardised

Endpoint as specified: `https://speed.cloudflare.com/__down?bytes=100000000`.

**⚠ First observation:** that exact URL returns **HTTP 403 with 1-byte body `"0"`**, from **Cloudflare's own edge** (`Server: cloudflare`, `CF-RAY`, `Report-To: cf-nel`). Size probe:

| bytes requested | http code | bytes received | note |
|-----------------|-----------|----------------|------|
| 1,000,000 | 200 | 1,000,000 | ok |
| 10,000,000 | 200 | 10,000,000 | ok |
| 25,000,000 | 200 | 25,000,000 | ok |
| 50,000,000 | 200 | 50,000,000 | ok |
| 75,000,000 | 200 | 75,000,000 | ok |
| 99,000,000 | 200 | 99,000,000 | ok |
| **100,000,000** | **403** | 1 | Cloudflare-side cap exactly at 100 MB |

So the requested 100 MB test is impossible from *any* client on this CDN path (Cloudflare refuses it, not the sandbox). **Substituted the largest permitted size (99,000,000 bytes) for the standardised protocol.** The three 100 MB attempts (3 seq + 3 par) are documented below as 403 rows for completeness.

### Standardised runs @ 99,000,000 bytes

| target | method | outcome | evidence (B/s) |
|--------|--------|---------|----------------|
| speed.cloudflare.com 99 MB | sequential run 1 | 200, complete | 164,271,728 B/s = 164 MB/s |
| speed.cloudflare.com 99 MB | sequential run 2 | 200, complete | 266,875,854 B/s = 267 MB/s |
| speed.cloudflare.com 99 MB | sequential run 3 | 200, complete | 260,171,660 B/s = 260 MB/s |
| — | **sequential median** | | **260,171,660 B/s ≈ 260 MB/s = 2.08 Gbps** |
| speed.cloudflare.com 99 MB | parallel run 1 | 200, complete | 188,272,702 B/s = 188 MB/s |
| speed.cloudflare.com 99 MB | parallel run 2 | 200, complete | 216,972,034 B/s = 217 MB/s |
| speed.cloudflare.com 99 MB | parallel run 3 | 200, complete | 229,460,397 B/s = 229 MB/s |
| — | **parallel median (per-flow)** | | **216,972,034 B/s ≈ 217 MB/s** |
| — | **parallel aggregate** | | 634,505,133 B/s ≈ 635 MB/s = 5.08 Gbps |

### The blocked 100 MB attempts (documented)

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| speed.cloudflare.com 100 MB | sequential ×3 | 403 | 1-byte body, 21–24 B/s, 0.04–0.07 s each |
| speed.cloudflare.com 100 MB | parallel ×3 | 403 | 1-byte body, 21–25 B/s |

### Cold-cache 16 MB PyPI wheel (`pip download --no-cache-dir --dest /tmp/x numpy`)

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| files.pythonhosted.org (numpy 2.5.2 cp313, 16.7 MB) | `pip download --no-cache-dir` (cold) | success | **184.1 MB/s** (pip-reported), wheel saved, 16,709,995 B |
| files.pythonhosted.org (same wheel URL) | `curl -w '%{speed_download}'` run 1 | 200 | 100,332,008 B/s = 100 MB/s |
| same URL | curl run 2 | 200 | 105,900,215 B/s = 106 MB/s |
| same URL | curl run 3 | 200 | 103,606,030 B/s = 104 MB/s |
| — | **wheel median** | | **103,606,030 B/s ≈ 104 MB/s = 0.83 Gbps** |

### Cross-check (substitute 100 MB endpoint)

| target | method | outcome | evidence |
|--------|--------|---------|----------|
| speed.hetzner.de/100MB.bin | curl | failed | `Could not resolve host` — **0 A and 0 AAAA records** from both 8.8.8.8 and 1.1.1.1 (rcode=0, ancount=0); the domain itself is unresolvable today, not a sandbox block (both resolvers agree) |

**Conclusion:** Effective single-flow throughput **≈ 1.5–2.1 Gbps** (Cloudflare CDN ~2 Gbps, Fastly/PyPI ~0.8–1.5 Gbps). Aggregate parallel throughput ~5 Gbps. No throttling observed at ≤99 MB. The only hard limit found is Cloudflare's own 100 MB `__down` cap (403), plus the sandbox's lack of IPv6.

---

## 7. Environment facts (supporting evidence)

| fact | value | implication |
|------|-------|-------------|
| resolv.conf | `nameserver 8.8.8.8` | system DNS = Google's resolver, unfiltered |
| default gateway | 169.254.0.22 (link-local) | egress via local NAT/proxy fabric, not a routed gateway |
| proxy env vars | none set | no explicit forward proxy |
| IPv6 | only `::1` + `fe80::` | sandbox is IPv4-only; `curl -6` → http=000 |
| CA bundle | `/etc/ssl/certs/ca-certificates.crt` | standard public store |

---

## 8. Questions that remain unanswered

1. **Who/what terminates the SYNs?** The 0 ms handshakes + JSON 404 from `192.0.2.1` prove an L7 egress proxy exists, but its implementation (Envoy/API-gateway/SNAT fabric) and its routing table are not observable from inside.
2. **Asymmetry within the intercepted ranges:** `192.0.2.1` answered HTTP with a JSON 404, while `198.51.100.1` / `203.0.113.1` accepted the TCP handshake but stayed silent at L7 — why these TEST-NET ranges differ is unexplained.
3. **UDP 123/443/500:** "no response" is ambiguous — the test servers don't answer those protocols, so UDP filtering vs. silent-server cannot be distinguished without a controlled UDP-echo host.
4. **Why 100 MB exactly?** Cloudflare's `__down` 403 fires precisely at 100,000,000 bytes; not characterised further (server-side, outside sandbox scope).
5. **>99 MB transfer behaviour / rate-limiting:** not tested beyond 100 MB; no evidence of sandbox-side throttling, but not proven absent.
6. **Connection-count / rate limits:** not measured (would need sustained parallel connection stress).
7. **IPv6 egress:** untestable — the sandbox has no global IPv6 address.
8. **TCP connect to `10/8` and `100.64/10`:** times out (EAGAIN) — whether silently dropped by the fabric or unrouted is not distinguishable from inside.

---

## Appendix — raw logs (workspace)

`/home/user/egress-map/logs/` — `t1.log`, `t1_time.log`, `t2.log`, `t3.log`, `t4.log`, `t5_tls.log`, `t6_403.log`, `t6_threshold.log`, `t6_seq.log`, `t6_par.log`, `t6_std.log`, `t6_pip.log`, `t6_wheel.log`, `t6_hetzner.log`, `t6_ipv6.log` · scripts `t1_proxy.py`, `t2_dns.py`, `t3_ip_sni.py`, `t4_ports.py`.
