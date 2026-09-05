# Sandbox Egress Policy Map

**Scope:** characterisation only. No attempt was made to evade, tunnel around, or defeat any control.
Every test below is a diagnostic probe; where a result was ambiguous I say so rather than infer a policy.

**Run window:** 2026-09-04 19:44 – 20:00 UTC (2026-09-05 01:14 – 01:30 IST).
**Host:** `e2b.local`, Debian GNU/Linux 13 (trixie), uid 1000 (`user`, member of `sudo`).
**Raw data:** `results/*.json`, `results/s6_raw.txt`. Scripts: `s1_*.py`, `dnsprobe.py`, `s3_*.py`, `s4_*.py`, `s6_bw.sh`.

---

## 0. Environment fingerprint (context for everything below)

| Property | Value | Evidence |
|---|---|---|
| Interface | `eth0` 169.254.0.21/30, MTU 1500, MAC `02:fc:00:00:00:05` | `ip -brief addr`, `ip link show eth0` |
| Default route | `default via 169.254.0.22 dev eth0` | `ip route` / `/proc/net/route` |
| Gateway L2 | `169.254.0.22 lladdr 02:fc:00:00:00:06 REACHABLE` | `ip neigh show`, `/proc/net/arp` (only entry) |
| Kernel | `Linux version 6.1.158+ (root@runnervm3jd5f)` | `/proc/version` |
| Hypervisor | **AWS Firecracker microVM** | `GET http://169.254.169.254/` → `HTTP/1.1 401`, `Server: Firecracker API`, body `No MMDS token provided…` |
| IPv6 | link-local only (`fe80::/64`), **no global route** | `ip -6 route` = `fe80::/64 dev eth0` only; IPv6 connects → `errno 101 ENETUNREACH` |
| Local firewall | no rules; `INPUT/FORWARD/OUTPUT` policy ACCEPT, 0 packets | `iptables -L -n -v` — **filtering is not in the guest** |
| Proxy env vars | none set | `env \| grep -i proxy` |
| `/etc/resolv.conf` | `nameserver 8.8.8.8` (single) | file contents |
| `/etc/nsswitch.conf` | `hosts: files dns` | file contents |
| `/etc/hosts` (non-standard) | `192.0.2.1 events.e2b.local`, `127.0.1.1 e2b.local` | file contents |
| Extra trust anchor | **`/usr/local/share/ca-certificates/e2b-ca.crt`** → `O=E2B, CN=E2B Proxy CA` | see §5 |

> The single most important structural fact: **`iptables` in the guest is empty, yet TCP connect() to another
> continent completes in 0.19 ms.** The policy therefore lives *outside* this VM, on the path to
> `169.254.0.22`.

---

## 1. Transparent-proxy behaviour

### 1.1 The command you asked for, plus RFC5737 + reserved ranges

`connect_ex()` with a 2 s socket timeout, then a real HTTP GET on a fresh socket.

| Target | Method | Outcome | Evidence |
|---|---|---|---|
| `192.0.2.1:9` (TEST-NET-1) | `connect_ex` | **rc=0 SUCCESS in 0.40 ms** | `peername ('192.0.2.1', 9)` |
| `192.0.2.1:9` | HTTP GET (raw socket) | **0 bytes, hung 4004 ms** | no banner, no RST, timeout |
| `192.0.2.1:9` | `curl --max-time 5` | exit 28 | `Operation timed out after 5002 ms with 0 bytes received` |
| `192.0.2.200:9` (TEST-NET-1, other host) | `connect_ex` | **rc=0 in 0.20 ms** | — |
| `192.0.2.200:9` | HTTP GET | 0 bytes, 4004 ms | timeout |
| `198.51.100.1:9` (TEST-NET-2) | `connect_ex` | **rc=0 in 0.16 ms** | — |
| `198.51.100.1:9` | HTTP GET | 0 bytes, 4004 ms | timeout |
| `203.0.113.1:9` (TEST-NET-3) | `connect_ex` | **rc=0 in 0.14 ms** | — |
| `203.0.113.1:9` | HTTP GET | 0 bytes, 4004 ms | timeout |
| `10.255.255.1:9` (RFC1918) | `connect_ex` | **rc=11 TIMEOUT at 2002 ms** | no SYN-ACK, retransmits |
| `10.255.255.1:9` | `curl` | exit 28 | `Connection timed out after 5002 ms` |
| `100.64.0.1:9` (RFC6598 CGNAT) | `connect_ex` | **rc=11 TIMEOUT at 2002 ms** | — |
| `100.64.0.1:9` | `curl` | exit 28 | `Connection timed out after 5002 ms` |
| `192.0.2.1:80` | `connect_ex` | rc=0 in 0.33 ms | — |
| `192.0.2.1:80` | HTTP GET | **192 bytes in 1.29 ms** | `HTTP/1.1 404 Not Found` … `{"error":"no matching operation was found"}` |
| `192.0.2.1:80` | `curl` | **HTTP 404** | matches `/etc/hosts` entry `192.0.2.1 events.e2b.local` — a real local service |
| `198.51.100.1:80` | `connect_ex` → HTTP GET | rc=0 in 0.16 ms → **0 bytes** | hangs 4004 ms |
| `203.0.113.1:80` | `connect_ex` → HTTP GET | rc=0 in 0.21 ms → **0 bytes** | hangs 4004 ms |
| `10.255.255.1:80` | `connect_ex` | rc=11 TIMEOUT | — |
| `100.64.0.1:80` | `connect_ex` | rc=11 TIMEOUT | — |
| `127.0.0.1:9` (control) | `connect_ex` | **rc=111 REFUSED in 0.05 ms** | real RST — proves the stack *can* report failure |
| `8.8.8.8:53` (control) | `connect_ex` → GET | rc=0 in 0.38 ms → 0 bytes (closed in 1.48 ms) | `curl` exit 52 `Empty reply from server` (we sent HTTP to a DNS port) |
| `1.1.1.1:443` (control) | `connect_ex` → GET | rc=0 in 0.19 ms → **414 bytes in 13.3 ms** | `HTTP/1.1 400 Bad Request`, `Server: cloudflare` |

### 1.2 Quantifying it: connect() latency is independent of distance

Median of 7 `connect_ex()` calls **by raw IP** (DNS excluded from the timer), then time to the first
byte that provably crossed the real network.

| Target | Location | connect() median | ok | First real byte | Ratio |
|---|---|---|---|---|---|
| `200.160.2.3` | Brazil (NIC.br) | **0.193 ms** | 7/7 | **340.5 ms** (`HTTP/1.1 301`) | 1764× |
| `196.10.52.58` | South Africa (TENET) | **0.191 ms** | 7/7 | **273.6 ms** | 1432× |
| `139.130.4.5` | Australia (Telstra) | **0.188 ms** | 7/7 | **161.7 ms** | 860× |
| `168.95.1.1` | Taiwan (Chunghwa) | **0.194 ms** | 7/7 | 5005 ms (no listener, no RST) | — |
| `202.12.29.1` | M-root | **0.235 ms** | 7/7 | **351.1 ms** (`HTTP/1.0 400`) | 1494× |
| `1.1.1.1` | Cloudflare anycast | **0.178 ms** | 7/7 | **19.0 ms** (`HTTP/1.1 403`) | 107× |
| `192.0.2.1` | **local control** (events svc) | 0.169 ms | 7/7 | **0.5 ms** (`HTTP/1.0 404`) | **3× — the only honest number** |
| `198.51.100.1` | TEST-NET-2 | 0.174 ms | 7/7 | 5005 ms (nothing behind it) | — |
| `203.0.113.1` | TEST-NET-3 | 0.205 ms | 7/7 | 5005 ms (nothing behind it) | — |
| `10.255.255.1` | RFC1918 | **no connect (0/7)** | 0/7 | 8017 ms timeout | not intercepted |
| `100.64.0.1` | RFC6598 | **no connect (0/7)** | 0/7 | 8016 ms timeout | not intercepted |

Same test by hostname (DNS timed separately so it cannot pollute the number):

| Target | DNS | connect() median | ok | TLS+first byte | Result |
|---|---|---|---|---|---|
| `www.google.com` → 142.251.152.119 | 3.0 ms | **0.233 ms** | 7/7 | 61.2 ms | `200 OK` |
| `www.uol.com.br` → 52.85.129.48 | 27.8 ms | **0.176 ms** | 7/7 | 49.9 ms | `200 OK` |
| `www.telstra.com.au` → 18.172.170.111 | 29.0 ms | **0.184 ms** | 7/7 | 186.7 ms | `403` |
| `www.chinadaily.com.cn` → 138.113.124.117 | 9.8 ms | **0.168 ms** | 7/7 | 170.8 ms | `200 OK` |
| `pypi.org` → 151.101.64.223 | 0.75 ms | **0.176 ms** | 7/7 | 77.0 ms | `200 OK` |
| `github.com` → 140.82.116.3 | 0.8 ms | **0.188 ms** | 7/7 | 44.7 ms | `200 OK` |

Corroborating evidence that a **SYN-ACK was actually received** (endianness-corrected `/proc/net/tcp` read):

| Target | state | tx/rx queue |
|---|---|---|
| `198.51.100.1:80` | `01 ESTABLISHED` | `00000000:00000000` / `00:00000000` |
| `203.0.113.1:80` | `01 ESTABLISHED` | empty |
| `192.0.2.1:80` | `01 ESTABLISHED` | empty |
| `1.1.1.1:443` | `01 ESTABLISHED` | empty |
| `200.160.2.3:80` | `01 ESTABLISHED` | empty |
| `8.8.8.8:53` | `01 ESTABLISHED` | empty |
| `10.255.255.1:80` | **`02 SYN_SENT`** | `00000001:00000000` (retransmitting) |

Also: `curl -w` shows `time_connect` ≈ `time_namelookup` for every host tested (e.g. chinadaily
`dns=0.073 tcp=0.073`), i.e. TCP connect contributes ~0 s; all the variance is DNS.

### 1.3 Which destination ranges get the local accept?

3 s timeout, port 80, 24 targets in parallel.

| Address | Range | rc | ms | Verdict |
|---|---|---|---|---|
| `192.0.2.1` / `192.0.2.7` | RFC5737 TEST-NET-1 | 0 | 0.27 | ACCEPTED |
| `198.51.100.7` | RFC5737 TEST-NET-2 | 0 | 0.39 | ACCEPTED |
| `203.0.113.7` | RFC5737 TEST-NET-3 | 0 | 0.38 | ACCEPTED |
| `198.18.0.1` | RFC2544 benchmark | 0 | 0.26 | ACCEPTED |
| `192.88.99.1` | 6to4 relay anycast | 0 | 0.27 | ACCEPTED |
| `240.0.0.1` | reserved 240/4 | 0 | 0.18 | ACCEPTED |
| `8.8.8.8` / `142.251.152.119` | public (control) | 0 | 0.16 / 0.49 | ACCEPTED |
| `169.254.169.254` | link-local **IMDS/MMDS** | 0 | 0.36 | ACCEPTED **and serves data** → `Server: Firecracker API` |
| `10.0.0.1`, `10.255.255.1` | RFC1918 10/8 | 11 | 3003 | **BLACKHOLED** |
| `172.16.0.1` | RFC1918 172.16/12 | 11 | 3002 | **BLACKHOLED** |
| `192.168.1.1` | RFC1918 192.168/16 | 11 | 3002 | **BLACKHOLED** |
| `100.64.0.1`, `100.127.255.254` | RFC6598 CGNAT | 11 | 3002 | **BLACKHOLED** |
| `169.254.0.20`, `169.254.0.22` | own /30 + gateway | 11 | 3003 | **BLACKHOLED** (gateway itself is not a TCP endpoint) |
| `169.254.170.2` | ECS task metadata | 11 | 3003 | **BLACKHOLED** |
| `127.0.0.2` | loopback | 111 | 0.22 | REFUSED |
| `169.254.0.21` | self (eth0) | 111 | 0.02 | REFUSED |
| `0.0.0.0` | this-network | 111 | 0.02 | REFUSED |

### 1.4 Conclusion — does TCP `connect()` report success independent of reachability?

**Yes, for every destination the interceptor claims; no for the ranges it declines.**

- For **all public / TEST-NET / benchmark / reserved / IMDS** destinations, `connect()` returns `0` in a
  flat **0.15 – 0.24 ms**, entirely independent of real reachability or geography. A TCP handshake to
  Brazil or Australia cannot physically complete in 0.19 ms, yet it does, and `/proc/net/tcp` confirms a
  genuine `ESTABLISHED` state. **Something on the path to `169.254.0.22` completes the handshake locally.**
- The **data plane** is where truth appears: 19 ms to Cloudflare, 340 ms to Brazil — i.e. the interceptor
  completes the handshake, *then* dials the real destination.
- Two distinct failure signatures: destinations the interceptor accepts but cannot reach
  (TEST-NET-2/3) hang forever with **no RST**, while destinations it declines
  (RFC1918, CGNAT, own /30) stay in `SYN_SENT` and time out.
- The control `192.0.2.1:80` is the only case where connect ≈ data-plane latency (0.17 / 0.5 ms) because
  it is a genuinely local service.
- **Consequence: `connect()`/`connect_ex()` is useless as a reachability oracle inside this sandbox.
  Only a data-plane round trip is meaningful.** Every "port scanner" result that stops at the handshake
  is 100% false-positive here.

---

## 2. DNS-level filtering

`dig`/`nslookup` are not installed; I wrote a raw DNS client (`dnsprobe.py`, RFC1035 wire format, UDP and TCP)
and compared three independent resolvers against the system resolver.

| Host | System (`getaddrinfo`) | `@8.8.8.8` (UDP) | `@1.1.1.1` (UDP) | `@9.9.9.9` (UDP) | Verdict |
|---|---|---|---|---|---|
| `google.com` | 74.125.142.100 … .139 (+v6) | NOERROR, 6 A | NOERROR | NOERROR | consistent |
| `pypi.org` | 151.101.0/64/128/192.223 (+v6) | NOERROR, 4 A | NOERROR, 4 A | NOERROR, 4 A | consistent |
| `files.pythonhosted.org` | 151.101.*.223 | NOERROR, CNAME→`dualstack.python.map.fastly.net` + 4 A | NOERROR | NOERROR | consistent |
| `registry.npmjs.org` | 104.16.0–11.34 (12) | NOERROR, 12 A | NOERROR | NOERROR | consistent |
| `github.com` | 140.82.116.3 | NOERROR, 1 A (140.82.116.4) | NOERROR (140.82.116.3) | NOERROR | consistent |
| `raw.githubusercontent.com` | 185.199.108–111.133 | NOERROR, 4 A | NOERROR, 4 A | NOERROR, 4 A | consistent |
| `huggingface.co` | 99.86.101.36/39/56/64 | NOERROR, 4 A | NOERROR, 4 A | NOERROR, 4 A | consistent |
| `openai.com` | 104.18.33.45, 172.64.154.211 | NOERROR, 2 A | NOERROR, 2 A | NOERROR, 2 A | consistent |
| `api.anthropic.com` | 160.79.104.10 (+v6 2607:6bc0::10) | NOERROR, 1 A | NOERROR, 1 A | NOERROR, 1 A | consistent |
| `pastebin.com` | 104.20.29.150, 172.66.171.73 | NOERROR, 2 A | NOERROR, 2 A | NOERROR, 2 A | consistent |
| `transfer.sh` | 144.76.136.153 | NOERROR, 1 A | NOERROR, 1 A | NOERROR, 1 A | consistent |
| `ngrok.io` | 6 A (52.8.87.87, 54.183.107.205, …) | NOERROR, 6 A | NOERROR, 6 A | NOERROR, 6 A | consistent |
| `webhook.site` | 178.63.67.106, 178.63.67.153 | NOERROR, 2 A | NOERROR, 2 A | NOERROR, 2 A | consistent |
| `1.1.1.1.xip.io` | **`gaierror -2` (NXDOMAIN)** | **NXDOMAIN, ancount 0, flags 0x8183** | **NXDOMAIN** | **NXDOMAIN** | consistent — genuine (xip.io service retired) |

Transport check (rules out a UDP-only path):

| Method | Target | Outcome | Evidence |
|---|---|---|---|
| TCP DNS :53 | `8.8.8.8` | NOERROR | `rcode=0`, 124 B |
| TCP DNS :53 | `1.1.1.1` | NOERROR | `rcode=0`, 44 B |
| TCP DNS :53 | `9.9.9.9` | NOERROR | `rcode=0`, 124 B |
| TCP :853 | `8.8.8.8`, `1.1.1.1` | connected, `rcode=2 SERVFAIL` (5 B) | raw TCP to a DoT port — expected, confirms the TCP path is open |
| UDP :53 | `8.8.8.8` / `1.1.1.1` / `9.9.9.9` / `208.67.222.222` | answered | 124 / 44 / 124 / 124 B |
| UDP :5353 | `208.67.222.222` | answered | 124 B — **you may query resolvers on non-standard ports** |
| UDP :9953 | `9.9.9.9` | answered | 124 B |
| UDP :443 | `208.67.222.222` (DNS payload) | answered | 124 B — **UDP is not port-restricted** |

**Conclusion: no DNS-level filtering.**
- 13/14 hosts resolve normally; the single NXDOMAIN is a genuinely dead zone, and it is NXDOMAIN
  identically on three unrelated resolvers — a filter would have to be synchronised across
  Google, Cloudflare and Quad9 to produce that.
- Zero `SERVFAIL`, zero timeouts, zero wildcard/`127.0.0.1` or `0.0.0.0` hijacks, no forced resolver:
  queries to `1.1.1.1` and `9.9.9.9` (neither is in `/etc/resolv.conf`) are answered normally over **both**
  UDP and TCP.
- `RA=1`, `AD=0`, TTLs vary resolver-to-resolver (e.g. `pypi.org` 8451 s vs 79588 s) — ordinary,
  unmodified recursive answers.

---

## 3. IP / SNI-level filtering (the decisive test)

For each host: (A) normal hostname TLS, (B) **connect directly by IP with SNI set to the hostname**,
(C) connect by IP with SNI set to the IP, (D) plain HTTP to the IP with `Host:` header,
(E) plain HTTP by hostname, (F/G) `curl` normal vs `curl --resolve` (IP-pinned).

| Host | Test | Outcome | Evidence |
|---|---|---|---|
| `pypi.org` (151.101.64.223) | A hostname | OK | TLSv1.3, GlobalSign Atlas R3 DV TLS CA 2025 Q4, `200 OK` |
| | **B IP + SNI=hostname** | **IDENTICAL** | same issuer, same cert, `200 OK` |
| | C IP + SNI=IP | cert for `www.python.org` | `421 Misdirected Request` — normal Fastly shared-IP behaviour |
| | D IP + `Host:` header | OK | `301 Moved Permanently`, 1042 B — same as hostname |
| | E hostname HTTP | OK | `301`, 1042 B |
| | F/G curl normal vs IP-pinned | both `200` | `connect=0.0014 / 0.0002 s`, `ttfb=0.029 / 0.033 s` |
| `github.com` (140.82.116.4) | A hostname | OK | Sectigo Public Server Authentication CA DV E36, `200 OK` |
| | **B IP + SNI=hostname** | **IDENTICAL** | same issuer, `200 OK` |
| | C IP + SNI=IP | cert for `github.com` | `301` — GitHub serves its cert regardless of SNI |
| | D IP + `Host:` | OK | `301`, 103 B — same as hostname |
| | F/G curl | both `200` | `ttfb=0.0282 / 0.0273 s` |
| `huggingface.co` (99.86.101.36) | A hostname | OK | Amazon RSA 2048 M01, `200 OK` |
| | **B IP + SNI=hostname** | **IDENTICAL** | same issuer, `200 OK` |
| | C IP + SNI=IP | `SSLV3_ALERT_HANDSHAKE_FAILURE` | origin rejects unknown SNI — server-side, not proxy |
| | D IP + `Host:` | OK | `301`, 561 B — same as hostname |
| | F/G curl | both `200` | `ttfb=0.0575 / 0.0276 s` |
| `pastebin.com` (172.66.171.73) | A hostname | OK | WE1 (Google Trust Services), `200 OK` |
| | **B IP + SNI=hostname** | **IDENTICAL** | same issuer, `200 OK` |
| | C IP + SNI=IP | `SSLV3_ALERT_HANDSHAKE_FAILURE` | origin rejects unknown SNI |
| | D IP + `Host:` | OK | `301`, 419 B |
| | F/G curl | both `200` | `ttfb=7.19 / 0.24 s` (origin-side variance, not filtering) |
| `webhook.site` (178.63.67.153) | A hostname | OK | YR2 (Let's Encrypt), `*.webhook.site`, `200 OK` |
| | **B IP + SNI=hostname** | **IDENTICAL** | same issuer, `200 OK` |
| | C IP + SNI=IP | cert for `11hookback.com` | unrelated co-tenant on a shared IP — normal |
| | D IP + `Host:` | OK | `200 OK`, 4096 B |
| | F/G curl | both `200` | `ttfb=0.620 / 0.626 s` |
| `transfer.sh` (144.76.136.153) | A/B/C TLS | `SSLEOFError` in **all three** | host's TLS is broken (service is defunct) — fails identically by name and by IP, so not filtering |
| | D/E HTTP | connects, **0 bytes** | TCP+data-plane reach the host; nothing served |

**Conclusion: no IP- or SNI-level filtering detected.**
Hostname and direct-IP-with-correct-SNI are byte-for-byte equivalent on all five hosts (same issuer,
same TLS version, same status, same body length). Where direct-IP diverges (test C) it is always
explained by ordinary shared-hosting behaviour (`421`, `301`, wrong-SNI rejection, co-tenant cert) and
occurs *identically* whether reached by name or by IP. There is no SNI-based allow/deny decision.

---

## 4. Port & protocol matrix

**Handshake-succeeded and data-received are reported as separate columns.** Given §1, the handshake
column is expected to be uninformative — which is itself the finding.

### 4.1 TCP — 17 ports × 4 hosts

`handshake` = `connect_ex()` rc==0 (4 s). `data` = ≥1 byte received after a protocol-appropriate probe (banner-read 1.5 s, then probe + 3 s).

| Host | Port | Handshake | hs ms | Data? | data ms | Evidence |
|---|---|---|---|---|---|---|
| portquiz.net (35.180.139.74) | 21 | ✓ | 0.2 | **✓** | 282.9 | `HTTP/1.1 200 OK` |
| portquiz.net | 22 | ✓ | 0.3 | **✓** | 281.5 | `HTTP/1.1 200 OK` |
| portquiz.net | 25 | ✓ | 0.2 | **✓** | 281.7 | `HTTP/1.1 200 OK` |
| portquiz.net | 53 | ✓ | 0.2 | **✓** | 281.0 | `HTTP/1.1 200 OK` |
| portquiz.net | 80 | ✓ | 0.2 | **✓** | 283.3 | `HTTP/1.1 200 OK` |
| portquiz.net | 110 | ✓ | 0.2 | **✓** | 281.1 | `HTTP/1.1 200 OK` |
| portquiz.net | 143 | ✓ | 0.2 | **✓** | 280.7 | `HTTP/1.1 200 OK` |
| portquiz.net | 443 | ✓ | 0.2 | **✓** | 280.8 | `HTTP/1.1 200 OK` |
| portquiz.net | 465 | ✓ | 0.3 | **✓** | 280.5 | `HTTP/1.1 200 OK` |
| portquiz.net | 587 | ✓ | 0.2 | **✓** | 280.7 | `HTTP/1.1 200 OK` |
| portquiz.net | 993 | ✓ | 0.2 | **✓** | 282.9 | `HTTP/1.1 200 OK` |
| portquiz.net | 995 | ✓ | 0.3 | **✓** | 282.7 | `HTTP/1.1 200 OK` |
| portquiz.net | 3306 | ✓ | 0.2 | **✓** | 282.7 | `HTTP/1.1 200 OK` |
| portquiz.net | 5432 | ✓ | 0.2 | **✓** | 280.5 | `HTTP/1.1 200 OK` |
| portquiz.net | 6379 | ✓ | 0.2 | **✓** | 282.6 | `HTTP/1.1 200 OK` |
| portquiz.net | 8080 | ✓ | 0.2 | **✓** | 281.4 | `HTTP/1.1 200 OK` |
| portquiz.net | 8443 | ✓ | 0.2 | **✓** | 282.4 | `HTTP/1.1 200 OK` |
| scanme.nmap.org (45.33.32.156) | 21 | ✓ | 0.6 | ✗ | 22.3 | closed, RST relayed in 21–22 ms |
| scanme.nmap.org | 22 | ✓ | 1.5 | **✓** | 45.6 | `SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2.13` |
| scanme.nmap.org | 25 | ✓ | 0.6 | ✗ | 21.0 | closed |
| scanme.nmap.org | 53 | ✓ | 0.7 | (probe err) | 21.6 | see TCP-DNS results below |
| scanme.nmap.org | 80 | ✓ | 0.3 | **✓** | 1544 | `HTTP/1.1 200 OK` |
| scanme.nmap.org | 110 | ✓ | 1.2 | ✗ | 20.7 | closed |
| scanme.nmap.org | 143 | ✓ | 0.6 | ✗ | 21.5 | closed |
| scanme.nmap.org | 443 | ✓ | 0.4 | ✗ | 31.9 | `SSLEOFError` |
| scanme.nmap.org | 465 | ✓ | 0.7 | ✗ | 20.7 | `ECONNRESET` |
| scanme.nmap.org | 587 | ✓ | 0.5 | ✗ | 21.3 | closed |
| scanme.nmap.org | 993 | ✓ | 3.5 | ✗ | 22.2 | `SSLEOFError` |
| scanme.nmap.org | 995 | ✓ | 0.7 | ✗ | 21.2 | `ECONNRESET` |
| scanme.nmap.org | 3306 | ✓ | 2.3 | ✗ | 22.0 | closed |
| scanme.nmap.org | 5432 | ✓ | 1.2 | ✗ | 22.3 | closed |
| scanme.nmap.org | 6379 | ✓ | 0.2 | ✗ | 21.9 | closed |
| scanme.nmap.org | 8080 | ✓ | 3.4 | ✗ | 20.2 | closed |
| scanme.nmap.org | 8443 | ✓ | 2.6 | ✗ | 21.9 | `ECONNRESET` |
| 1.1.1.1 | 21 | ✓ | 0.6 | ✗ | 4505 | silent drop |
| 1.1.1.1 | 22 | ✓ | 0.4 | ✗ | 4505 | silent drop |
| 1.1.1.1 | 25 | ✓ | 0.3 | ✗ | 4505 | silent drop |
| 1.1.1.1 | 53 | ✓ | 0.3 | (probe err) | 1502 | see TCP-DNS below (works) |
| 1.1.1.1 | 80 | ✓ | 0.6 | **✓** | 1520 | `HTTP/1.1 403 Forbidden` |
| 1.1.1.1 | 110 | ✓ | 0.4 | ✗ | 4505 | silent drop |
| 1.1.1.1 | 143 | ✓ | 0.8 | ✗ | 4504 | silent drop |
| 1.1.1.1 | 443 | ✓ | 0.3 | **✓** | 93.2 | `HTTP/1.1 301 Moved Permanently` |
| 1.1.1.1 | 465 | ✓ | 1.2 | ✗ | 4025 | TLS handshake timeout |
| 1.1.1.1 | 587 | ✓ | 0.7 | ✗ | 4504 | silent drop |
| 1.1.1.1 | 993 | ✓ | 2.5 | ✗ | 4024 | TLS handshake timeout |
| 1.1.1.1 | 995 | ✓ | 2.3 | ✗ | 4024 | TLS handshake timeout |
| 1.1.1.1 | 3306 | ✓ | 0.4 | ✗ | 4505 | silent drop |
| 1.1.1.1 | 5432 | ✓ | 1.1 | ✗ | 4503 | silent drop |
| 1.1.1.1 | 6379 | ✓ | 0.4 | ✗ | 4502 | silent drop |
| 1.1.1.1 | 8080 | ✓ | 1.1 | **✓** | 1511 | `HTTP/1.1 403 Forbidden` |
| 1.1.1.1 | 8443 | ✓ | 1.0 | **✓** | 123.1 | `HTTP/1.1 301 Moved Permanently` |
| 8.8.8.8 | 21 | ✓ | 0.5 | ✗ | 4506 | silent drop |
| 8.8.8.8 | 22 | ✓ | 0.4 | ✗ | 4505 | silent drop |
| 8.8.8.8 | 25 | ✓ | 0.5 | ✗ | 4504 | silent drop |
| 8.8.8.8 | 53 | ✓ | 0.4 | (probe err) | 1501 | see TCP-DNS below (works) |
| 8.8.8.8 | 80 | ✓ | 1.4 | ✗ | 4503 | silent drop |
| 8.8.8.8 | 110 | ✓ | 0.8 | ✗ | 4503 | silent drop |
| 8.8.8.8 | 143 | ✓ | 1.0 | ✗ | 4503 | silent drop |
| 8.8.8.8 | 443 | ✓ | 0.3 | **✓** | 60.7 | `HTTP/1.1 302 Found` |
| 8.8.8.8 | 465 | ✓ | 0.4 | ✗ | 4016 | TLS handshake timeout |
| 8.8.8.8 | 587 | ✓ | 0.9 | ✗ | 4504 | silent drop |
| 8.8.8.8 | 993 | ✓ | 0.9 | ✗ | 4020 | TLS handshake timeout |
| 8.8.8.8 | 995 | ✓ | 4.1 | ✗ | 4009 | TLS handshake timeout |
| 8.8.8.8 | 3306 | ✓ | 1.3 | ✗ | 4505 | silent drop |
| 8.8.8.8 | 5432 | ✓ | 7.7 | ✗ | 4505 | silent drop |
| 8.8.8.8 | 6379 | ✓ | 0.4 | ✗ | 4504 | silent drop |
| 8.8.8.8 | 8080 | ✓ | 0.4 | ✗ | 4504 | silent drop |
| 8.8.8.8 | 8443 | ✓ | 0.3 | ✗ | 4009 | TLS handshake timeout |

**Handshake success rate: 68/68 (100%).** Data-received: only where a real listener exists.
`portquiz.net` (a host that answers HTTP on every TCP port, run **sequentially** to avoid rate-limit
artefacts) returned `200 OK` on **all 17 ports** → **there is no TCP destination-port-based egress
restriction.** Note the shape of those rows once more: handshake 0.2 ms, first data byte **~281 ms** —
a 1400× split, on every single port.
`scanme.nmap.org` is the clean illustration of the handshake/data split: 15 ports return rc=0 and then
close ~21 ms later once the upstream RST comes back.

TCP DNS (fixing the port-53 probe bug above): `8.8.8.8:53` `rcode=0` 124 B · `1.1.1.1:53` `rcode=0` 44 B ·
`9.9.9.9:53` `rcode=0` 124 B — **TCP/53 open**.

### 4.2 UDP — protocol-appropriate payloads, 2 attempts, 4 s timeout

| Target | Port | Probe | Sent | Rcvd | ms | Outcome |
|---|---|---|---|---|---|---|
| `8.8.8.8` | 53 | DNS A? google.com | 28 | **124** | 0.8 | **DATA RECEIVED** |
| `1.1.1.1` | 53 | DNS A? google.com | 28 | **44** | 7.5 | **DATA RECEIVED** |
| `208.67.222.222` | 53 | DNS (OpenDNS) | 28 | **124** | 25.7 | **DATA RECEIVED** |
| `208.67.222.222` | 5353 | DNS on alt port | 28 | **124** | 28.5 | **DATA RECEIVED** — not port-restricted |
| `208.67.222.222` | 443 | DNS payload to :443 | 28 | **124** | 39.7 | **DATA RECEIVED** — UDP/443 open |
| `9.9.9.9` | 9953 | DNS on alt port | 28 | **124** | 6.8 | **DATA RECEIVED** |
| `216.239.35.0` | 123 | NTPv3 → real NTP server | 48 | **48** | 0.6 | **DATA RECEIVED** |
| `216.239.35.4` | 123 | NTPv3 → real NTP server | 48 | **48** | 0.6 | **DATA RECEIVED** |
| `162.159.200.1` | 123 | NTPv3 → time.cloudflare.com | 48 | **48** | 7.5 | **DATA RECEIVED** |
| `162.159.200.123` | 123 | NTPv3 → time.cloudflare.com | 48 | **48** | 7.1 | **DATA RECEIVED** |
| `8.8.8.8` | 123 | NTP → **not** an NTP server | 48 | 0 | 4004 | silent — correct, no synthesis |
| `1.1.1.1` | 123 | NTP → **not** an NTP server | 48 | 0 | 4004 | silent — correct |
| `208.67.222.222` / `104.16.0.34` / `151.101.64.223` / `9.9.9.9` | 123 | NTP → not NTP servers | 48 | 0 | 4004 | silent — correct |
| `8.8.8.8` / `1.1.1.1` | 500 | IKEv2 SA_INIT | 20 | 0 | 4004 | no IKE responder to test — **inconclusive** |
| `8.8.8.8` / `1.1.1.1` | 33434 | traceroute-style | 40 | 0 | 4004 | silent (expected) |
| `8.8.8.8` / `1.1.1.1` | 9999 | unassigned control | 5 | 0 | 4004 | silent (expected) |
| `8.8.8.8`, `1.1.1.1`, `104.16.0.34`, `142.250.73.78`, `142.251.152.119` | 443 | hand-built QUIC Initial | 1200 | 0 | 4000 | **probe artifact — see correction below** |
| `cloudflare-quic.com` | 443 | **`curl --http3`** | — | — | 77.8 | **`HTTP/3`, code 200** |
| `www.google.com` | 443 | **`curl --http3`** | — | — | 51.5 | **`HTTP/3`, code 200** |

**Correction I want to flag explicitly:** my hand-built QUIC packet produced silence from 5 different
QUIC-capable hosts, which *looked* like a UDP/443 block. It was not. `curl --http3` (nghttp3) negotiates
HTTP/3 successfully to two independent hosts, and OpenDNS answered a UDP datagram on port 443.
The probe was malformed; **UDP/443 and QUIC egress work.** I am reporting this rather than burying it.

**UDP conclusion:** egress is **not restricted by destination port** — 53, 123, 443, 5353 and 9953 all
returned data. No UDP response-synthesis (NTP probes to 6 non-NTP hosts were all silent). UDP/500 is
untested rather than blocked — I had no reachable IKE responder to use as a positive control.
Note UDP is silent-drop, so "no response" cannot distinguish *filtered* from *closed* the way TCP RST can.

### 4.3 Other protocols

| Protocol | Test | Outcome | Evidence |
|---|---|---|---|
| IPv6 | `connect_ex()` to `2001:4860:4860::8888:53`, `2606:4700:4700::1111:53`, `2400:cb00:…:443` | **all `errno 101 ENETUNREACH`** | no global IPv6 route; only `fe80::/64`. AAAA records resolve but are unroutable |
| ICMP | `ping 8.8.8.8`; raw `SOCK_RAW`/`IPPROTO_ICMP` | **cannot test** | `socket: Operation not permitted` — no `CAP_NET_RAW` for uid 1000 |
| Concurrency | 100 parallel TCP connects to `pypi.org:443` | **100/100 in 0.03 s** | no connection-rate limiting observed at this scale |
| HTTP/2 | `curl --http2 https://www.google.com/` | `200`, `httpver=2` | works |
| HTTP/3 | `curl --http3 https://www.google.com/` | `200`, `httpver=3` | works |

---

## 5. TLS interception

```
$ curl -svI https://pypi.org 2>&1 | grep -iE 'issuer|subject|SSL'
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / X25519MLKEM768 / RSASSA-PSS
*  subject: CN=pypi.org
*  issuer: C=BE; O=GlobalSign nv-sa; CN=GlobalSign Atlas R3 DV TLS CA 2025 Q4
*  SSL certificate verify ok.

$ openssl s_client -connect pypi.org:443 -servername pypi.org </dev/null 2>/dev/null | openssl x509 -noout -issuer -subject -dates
issuer=C=BE, O=GlobalSign nv-sa, CN=GlobalSign Atlas R3 DV TLS CA 2025 Q4
subject=CN=pypi.org
notBefore=Dec 28 04:33:08 2025 GMT
notAfter=Jan 29 04:33:07 2027 GMT

$ openssl s_client ... (full chain + verify)
depth=2 OU=GlobalSign Root CA - R3, O=GlobalSign, CN=GlobalSign
depth=1 C=BE, O=GlobalSign nv-sa, CN=GlobalSign Atlas R3 DV TLS CA 2025 Q4
depth=0 CN=pypi.org
Verification: OK
Verify return code: 0 (ok)
```

| Question | Answer | Evidence |
|---|---|---|
| Issuer for `pypi.org`? | **Public CA** — GlobalSign | `C=BE, O=GlobalSign nv-sa, CN=GlobalSign Atlas R3 DV TLS CA 2025 Q4`, chaining to `GlobalSign Root CA - R3`; SHA1 `36:0A:76:32:A6:8F:B2:9C:C6:C1:C4:25:66:45:BA:D2:D2:88:66:84`; serial `0131B6322158DA5785A38B0997C381F2` |
| Chain verified? | **Yes** | `Verify return code: 0 (ok)`, `Verification: OK`, 3 levels |
| Dates sane? | **Yes** | 2025-12-28 → 2027-01-29 — a normal ~13-month public DV cert, not a short-lived forged one |
| Any local CA in the chain? | **No** | full chain is `pypi.org ← GlobalSign Atlas R3 ← GlobalSign Root R3` |

**But a local CA *is* installed and trusted:**

| Property | Value |
|---|---|
| Path | `/usr/local/share/ca-certificates/e2b-ca.crt` |
| Subject = Issuer | `O=E2B, CN=E2B Proxy CA` (**self-signed**) |
| Key / sig | ECDSA P-256 / `ecdsa-with-SHA256` |
| Constraints | `CA:TRUE` (critical), `Key Usage: Certificate Sign` (critical) |
| Validity | `Sep 3 00:52:14 2026 GMT` → `Sep 3 01:52:14 2027 GMT` — **created ~2 days before this test, at sandbox build time** |
| Serial | `5B11EE1C9BE9DBE0068041AF3129FAB9` |
| SHA-256 | `5E:B5:82:C9:EF:3D:7F:16:69:CD:88:11:33:F5:FB:54:CC:87:CD:FB:C2:64:FC:E0:FC:A8:D3:FA:C0:20:CD:81` |
| **In active trust store?** | **YES** — cert #150 of 151 in `/etc/ssl/certs/ca-certificates.crt` (`update-ca-certificates` has been run) |
| Env overrides | none (`SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, `CURL_CA_BUNDLE` all unset) |

**Is it actually used?** I swept 53 mainstream domains (Google, Meta, Microsoft, Apple, Netflix, Reddit,
Wikipedia, GitHub, GitLab, Docker, crates.io, PyPI, npm, Debian, Ubuntu, Alpine, Arch, OpenAI, Anthropic,
HuggingFace, Pastebin, webhook.site, ngrok, Tailscale, Discord, Telegram, Proton, torproject, …):

| Metric | Result |
|---|---|
| Hosts tested | 53 |
| TLS handshakes succeeded | **53 / 53** (0 failures) |
| Hosts presenting an `E2B Proxy CA` certificate | **0** |
| Distinct CAs observed | Google Trust Services (WE1/WR2/WR3), Let's Encrypt (R1/E1/R2/E2), DigiCert, Amazon, GlobalSign, Sectigo, GeoTrust, Microsoft, Apple — **all public** |

**HTTP-level check:** no proxy-injected headers. `pypi.org` returns genuine Fastly/Varnish
(`X-Served-By: cache-bfi-kbfi7400093-BFI`, `X-Cache: HIT`); `example.com` returns genuine Cloudflare
(`cf-cache-status: HIT`, `CF-RAY: …-SEA`). No `Via`, `Proxy-Connection`, `X-Forwarded-For` or
synthetic `X-Cache` was added.

### Conclusion — is the issuer a public CA or a local one?

**Public. TLS is not being intercepted on any host I tested** — 53/53 hosts, plus `pypi.org` verified
to a 3-level public chain with `Verify return code: 0`. The proxy operates strictly below TLS.

**However, the capability is fully provisioned:** a self-signed `E2B Proxy CA` is installed in
`/usr/local/share/ca-certificates/` *and* merged into the system trust bundle, so every TLS client in
this sandbox (curl, openssl, Python, pip, npm) would silently accept a certificate it signs. The CA was
minted at sandbox build time. Interception was **not observed in operation** during this run, but the
prerequisite for turning it on is already in place and trusted. That distinction — *capability present,
not exercised* — is the honest answer, and I cannot enumerate the proxy's policy from inside the guest.

---

## 6. Bandwidth — standardised

**Method note (why the earlier numbers were unusable):** `https://speed.cloudflare.com/__down?bytes=100000000`
returns **HTTP 403 with a 1-byte body** to curl's default User-Agent. This is **Cloudflare's own bot check,
not the sandbox** — the 403 carries `Server-Timing: cfSpeedEdge;dur=2, cfSpeedWorker;dur=0` and
`Referrer-Policy: same-origin`, and it happens identically over HTTP/1.1, HTTP/2 and HTTP/3.
`bytes=1000 / 100000 / 10000000` all return 200; only 100 MB is gated. Adding a browser `User-Agent`
and `Referer: https://speed.cloudflare.com/` yields a clean `200` with exactly 100,000,000 bytes.
All numbers below use that endpoint, those headers, and `-o /dev/null`.

### 6.1 `https://speed.cloudflare.com/__down?bytes=100000000`

| Run | Size (B) | Speed (B/s) | Speed | Total (s) | Connect (s) | TTFB (s) | Code |
|---|---|---|---|---|---|---|---|
| **seq-1** | 100,000,000 | 169,935,084 | **170.0 MB/s = 1360 Mbit/s** | 0.5885 | 0.0017 | 0.0767 | 200 |
| **seq-2** | 100,000,000 | 233,529,731 | **233.5 MB/s = 1868 Mbit/s** | 0.4282 | 0.0016 | 0.0916 | 200 |
| **seq-3** | 100,000,000 | 170,585,004 | **170.6 MB/s = 1365 Mbit/s** | 0.5862 | 0.0017 | 0.0747 | 200 |
| **seq MEDIAN** | — | **170,585,004** | **170.6 MB/s = 1364.7 Mbit/s** | **0.586** | 0.0017 | 0.0767 | — |
| **par-1** | 100,000,000 | 204,046,236 | **204.0 MB/s = 1632 Mbit/s** | 0.4901 | 0.0371 | 0.1007 | 200 |
| **par-2** | 100,000,000 | 271,334,340 | **271.3 MB/s = 2171 Mbit/s** | 0.3685 | 0.0017 | 0.0760 | 200 |
| **par-3** | 100,000,000 | 209,628,663 | **209.6 MB/s = 1677 Mbit/s** | 0.4770 | 0.0017 | 0.0856 | 200 |
| **par MEDIAN** | — | **209,628,663** | **209.6 MB/s = 1677.0 Mbit/s** | **0.477** | 0.0017 | 0.0856 | — |
| **aggregate (3 concurrent)** | 300 MB (286.1 MiB) | — | **350.9 MB/s = 2807 Mbit/s** | **0.85** | — | — | 200 |

### 6.2 PyPI wheel (~16–18 MB), cold cache

| Method | Size | Speed | Evidence |
|---|---|---|---|
| `curl -w '%{speed_download}'` run 1 | 18,465,609 B | **90.4 MB/s** | `90395834` B/s, total 0.204 s, TTFB 0.045 s |
| `curl -w '%{speed_download}'` run 2 | 18,465,609 B | **100.8 MB/s** | `100827280` B/s, total 0.183 s, TTFB 0.041 s |
| `curl -w '%{speed_download}'` run 3 | 18,465,609 B | **103.6 MB/s** | `103633414` B/s, total 0.178 s, TTFB 0.040 s |
| **curl median** | 18.47 MB | **100.8 MB/s = 806 Mbit/s** | wheel: `numpy-2.5.2-cp313-cp313-musllinux_1_2_x86_64.whl` |
| `pip download --no-cache-dir --no-deps --dest /tmp/x numpy` (cold) #1 | 16,709,995 B (15.94 MiB) | **18.2 MB/s = 153.0 Mbit/s** | 0.87 s wall |
| `pip download --no-cache-dir --no-deps --dest /tmp/x numpy` (cold) #2 | 16,709,995 B (15.94 MiB) | **17.8 MB/s = 149.4 Mbit/s** | 0.89 s wall |

> The pip figure is **~5.5× lower than curl on the same CDN** (`files.pythonhosted.org`). That gap is
> pip's own overhead — interpreter start, index/metadata round trips, disk write and hash verification —
> not a network limit. Use the curl number for throughput; use the pip number for "what a real
> `pip install` feels like".

### 6.3 Bandwidth conclusion

- Single-flow throughput: **~1.36 Gbit/s median**; peak observed 1.87 Gbit/s.
- Three concurrent flows: **~2.81 Gbit/s aggregate** (1.68 Gbit/s per flow median) — scaling is roughly
  linear, so the ~1.4 Gbit/s single-flow figure is a **per-flow** characteristic, not a sandbox-wide cap.
- TTFB to Cloudflare is 75–100 ms while `connect()` reports 1.7 ms — the same split-proxy signature as §1.
- No rate limiting, shaping or quota was observed across ~1.0 GB transferred during this run.

---

## 7. Consolidated model of the egress policy

| Layer | Policy | Confidence | Evidence |
|---|---|---|---|
| **Guest firewall** | none | High | `iptables` empty, policy ACCEPT |
| **Interception point** | outside the guest, on the path to `169.254.0.22` | High | 0.19 ms connect to 4 continents; empty guest iptables |
| **Mechanism** | transparent TCP split-proxy: handshake completed **locally**, then upstream dialled | High | connect 0.19 ms vs first real byte 340 ms (Brazil); `/proc/net/tcp` ESTABLISHED with empty queues |
| **TCP destination ports** | **unrestricted** (17/17 ports carried data) | High | `portquiz.net` sequential `200 OK` on all 17 |
| **TCP destinations** | public / TEST-NET / benchmark / reserved → intercepted & forwarded; RFC1918, CGNAT 100.64/10, own /30 → **blackholed** | High | §1.3 range map |
| **DNS** | **unfiltered, unforced**; UDP+TCP to any resolver; NXDOMAIN is genuine | High | §2 — 3 resolvers agree, incl. non-configured ones |
| **SNI / IP** | **no filtering** | High | §3 — hostname ≡ direct-IP on 5/5 hosts |
| **TLS** | **not intercepted**; public CAs, chains verify | High | §5 — 53/53 hosts, `Verify return code: 0` |
| **…but** | a self-signed `E2B Proxy CA` is installed **and in the system trust bundle** | High | cert #150/151; minted at sandbox build |
| **HTTP** | no header injection, no body rewriting observed | Medium | genuine Fastly/Cloudflare headers only |
| **UDP** | open, **not port-restricted**; DNS, NTP, QUIC/HTTP3 all work | High | §4.2 + `curl --http3` = 200 |
| **IPv6** | **unroutable** (link-local only) | High | `ENETUNREACH` on all 3 targets; no global route |
| **ICMP** | **untestable** from uid 1000 (no `CAP_NET_RAW`) | High | `Operation not permitted` |
| **Bandwidth** | ~1.36 Gbit/s per flow, ~2.81 Gbit/s aggregate, no shaping seen | Medium | §6 |
| **Local services reachable** | `192.0.2.1:80` (events.e2b.local), `169.254.169.254` (Firecracker MMDS) | High | `404 {"error":"no matching operation was found"}`, `Server: Firecracker API` |

**One-line summary:** *A transparent TCP split-proxy outside the Firecracker guest completes every
handshake locally in ~0.19 ms, then forwards by real destination. It blocks nothing by port, DNS name or
SNI; it does blackhole RFC1918/CGNAT/own-subnet destinations and all IPv6. TLS passes through untouched,
but an `E2B Proxy CA` is pre-installed and trusted, so interception could be enabled without any client
noticing. `connect()` is not a reachability oracle here — only a data-plane round trip is.*

---

## 8. Questions that remain UNANSWERED

I am listing these explicitly rather than paper over them.

1. **What exactly performs the interception?** TPROXY/nftables on the host, a Firecracker device
   backend, or a user-space stack? I can only see that *something* on-link at `169.254.0.22` sends the
   SYN-ACK. The host network namespace is not visible from inside the guest. **Unresolvable from here.**
2. **Is the `E2B Proxy CA` ever used?** Zero of 53 hosts were intercepted. I cannot enumerate the
   proxy's policy table from inside the sandbox, so I cannot say whether it is "off", "on for categories
   I didn't sample", or "on only when a tenant configures it". I deliberately did not probe
   blocklist-bait categories to find out.
3. **ICMP egress.** Completely untested — uid 1000 lacks `CAP_NET_RAW`, so `ping` and raw sockets both
   fail with `EPERM`. I did not escalate with `sudo` because that changes the subject under test.
4. **UDP/500 (IKE) egress.** No response, but I had no reachable IKE responder as a positive control, so
   this is **inconclusive**, not "blocked".
5. **Is RFC1918/CGNAT blackholing deliberate policy or a routing artifact?** The behaviour is crisp and
   reproducible, but I cannot see the intent. Note the asymmetry: `169.254.169.254` (also link-local)
   *is* forwarded to the Firecracker MMDS, while `169.254.0.22` (the gateway) is not.
6. **Absolute bandwidth ceiling.** I measured ~2.81 Gbit/s aggregate with 3 flows and did not find a
   cap; I did not push beyond 3 concurrent flows, so the true ceiling is unbounded-by-measurement.
7. **Upload throughput.** Not measured — you specified download only, and I did not run
   `speed.cloudflare.com/__up`.
8. **Per-connection / per-destination rate limits, total transfer quota, and time-of-day variance.**
   Not measured. All bandwidth figures are a single ~15-minute sample on 2026-09-05.
9. **Does the proxy enforce any *content* policy?** I only tested transport- and name-layer reachability.
   Response-body inspection, if any, was not exercised.
10. **Connection idle-timeout behaviour** for long-lived flows (relevant to WebSockets/SSE). Not measured;
    I only ran short-lived requests.
11. **Whether the local `connect()` accept ever *fails* for a public destination.** 68/68 port tests and
    ~40 address tests all returned rc=0. I never found a public destination where the proxy refused the
    handshake, so I cannot characterise that failure mode.
