# Index — Sandbox Egress Policy Map

**Main report:** [`egress-policy-map.md`](egress-policy-map.md) — 570 lines, 301 table rows, §0–§8.
Start there. Everything below is the reproducible evidence behind it.

Run window: 2026-09-04 19:44 – 20:00 UTC (2026-09-05 01:14 – 01:30 IST).
Host: `e2b.local`, Debian 13 (trixie), AWS Firecracker microVM, uid 1000.
`dig`/`nslookup`/`nc` are not installed, so DNS and raw-socket work is done by hand-rolled Python.

## Contents

| File | Section | What it does |
|---|---|---|
| `egress-policy-map.md` | all | **The report.** §0 environment · §1 transparent proxy · §2 DNS · §3 IP/SNI · §4 port & protocol matrix · §5 TLS interception · §6 bandwidth · §7 consolidated model · §8 unanswered questions |
| `INDEX.md` | — | this file |

### Scripts

| Script | Section | Purpose | Writes |
|---|---|---|---|
| `s1_tcp.py` | §1.1 | `connect_ex()` + real HTTP GET to RFC5737 TEST-NETs (192.0.2.x, 198.51.100.x, 203.0.113.x), RFC1918 `10.255.255.1`, CGNAT `100.64.0.1`, plus loopback/real-host controls | `results/s1.json` |
| `s1b_rtt.py` | §1.2 | connect() latency to 8 geographically distant IPs + `/proc/net/tcp` state + ARP/route dump | `results/s1b.json` |
| `s1c_connect_vs_ttfb.py` | §1.2 | `curl -w` splitting DNS / TCP connect / TLS / TTFB across 20 URLs | `results/s1c.json` |
| `s1d_proof.py` | §1.2 | first (flawed) connect-vs-application-plane attempt — DNS time leaked into the connect number | `results/s1d.json` |
| `s1d_v2.py` | §1.2 | **decisive test**: resolves first, then times 7 connects, then times the first byte that provably crossed the real network | `results/s1d_v2.json` |
| `s1e_rangemap.py` | §1.3 | 24 destinations in parallel: which ranges get a local accept vs blackhole vs RST | `results/s1e.json` |
| `dnsprobe.py` | §2 | hand-written RFC1035 DNS client (UDP **and** TCP, no dnspython). Compares system resolver against 8.8.8.8 / 1.1.1.1 / 9.9.9.9 | `results/s2.json` |
| `s3_direct_ip.py` | §3 | for 6 hosts: hostname TLS vs **direct-by-IP with SNI=hostname** vs SNI=IP vs plain HTTP with `Host:` vs `curl --resolve` | `results/s3.json` |
| `s4_ports.py` | §4.1 | TCP matrix, 17 ports × 4 hosts, **handshake and data recorded separately** | `results/s4_tcp.json` |
| `s4b_udp.py` | §4.2 | UDP probes: 53 (DNS), 123 (NTP), 443 (QUIC), 500 (IKE), 33434, 9999 to 8.8.8.8 and 1.1.1.1 | `results/s4b_udp.json` |
| `s4c_udp_control.py` | §4.2 | **controls that corrected a false conclusion** — real NTP servers, DNS on alt ports 5353/9953/443, NTP to non-NTP hosts (synthesis check) | `results/s4c_udp_control.json` |
| `s4d_tcpdns_portquiz.py` | §4.1 | fixes the port-53 probe bug in `s4_ports.py`; re-runs portquiz.net **sequentially** (the concurrent run hit rate limiting) | `results/s4_portquiz.json` |
| `s5_tls_intercept.py` | §5 | `curl -svI` / `openssl s_client` chain + local-CA discovery + 20-host MITM sweep | `results/s5_mitm.json` |
| `s5_sweep.py` | §5 | 53-domain TLS-issuer sweep: any `E2B Proxy CA` certs? (answer: 0) | `results/s5_sweep.json` |
| `s6_bw.sh` | §6 | first bandwidth attempt — produced unusable numbers (Cloudflare 403); kept for the record | `results/s6_cloudflare.txt` |
| `s7_gaps.py` | §7/§8 | ICMP (no `CAP_NET_RAW`), IPv6 (`ENETUNREACH`), concurrency (100 parallel connects) | — |

### Raw results

| File | Contents |
|---|---|
| `results/s1.json` | connect_ex + raw-socket HTTP + curl, per target |
| `results/s1b.json` | min connect latency per distant IP |
| `results/s1c.json` | per-URL `dns / tcp / tls / ttfb / total` |
| `results/s1d_v2.json` | **median connect ms vs application-plane ms** — the core §1 evidence |
| `results/s1e.json` | range accept/blackhole/refuse map |
| `results/s2.json` | system `getaddrinfo` + explicit UDP/TCP queries to 3 resolvers, rcodes and A records |
| `results/s3.json` | hostname vs direct-IP vs SNI variants, 6 hosts |
| `results/s4_tcp.json` | 68 (host, port) results, handshake and data columns separate |
| `results/s4_portquiz.json` | 17 ports sequential, with data-plane latency |
| `results/s4b_udp.json` / `s4c_udp_control.json` | UDP probe results and controls |
| `results/s5_mitm.json` / `s5_sweep.json` | per-host TLS issuer |
| `results/s6_cloudflare.txt` | the 403s that invalidated the first bandwidth run |
| `results/s6_raw.txt` | standardised 100 MB runs: `label\|size\|speed\|total\|connect\|ttfb\|code` |

## Three findings worth restating

1. **`connect()` is not a reachability oracle here.** It returns `0` in a flat 0.15–0.24 ms for every
   destination the interceptor claims, regardless of geography — 0.19 ms to Brazil, whose first real
   byte took 340 ms. Only a data-plane round trip is meaningful.
2. **TLS is not intercepted, but the capability is pre-installed and trusted.** `E2B Proxy CA` is
   self-signed, minted at sandbox build time, present in `/usr/local/share/ca-certificates/` **and**
   merged into `/etc/ssl/certs/ca-certificates.crt` (cert #150 of 151). Zero of 53 hosts were actually
   intercepted during this run.
3. **Two of my own results were wrong before they were right**, and both corrections are in the record:
   the Cloudflare 403 (their bot check, not the sandbox — it silently invalidated the first bandwidth
   numbers), and the hand-built QUIC probe (silence from 5 hosts looked like a UDP/443 block;
   `curl --http3` then got HTTP/3 200, so the probe was simply malformed).

## Reproducing

```bash
python3 s1e_rangemap.py      # ~10 s   range accept/blackhole map
python3 s1d_v2.py            # ~60 s   the decisive connect-vs-data-plane test
python3 dnsprobe.py          # ~2 s    DNS across 3 resolvers, UDP + TCP
python3 s3_direct_ip.py      # ~15 s   hostname vs direct-IP vs SNI
python3 s4_ports.py          # ~15 s   17 ports x 4 hosts
python3 s4c_udp_control.py   # ~40 s   UDP controls
python3 s5_sweep.py          # ~4 s    53-host TLS-issuer sweep
```

Bandwidth is not scripted (it needs a browser `User-Agent` or Cloudflare returns 403):

```bash
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'
curl -s -o /dev/null --max-time 300 -A "$UA" -H 'Referer: https://speed.cloudflare.com/' \
  -w '%{size_download}|%{speed_download}|%{time_total}|%{time_connect}|%{time_starttransfer}|%{http_code}\n' \
  'https://speed.cloudflare.com/__down?bytes=100000000'
```

## Not included

`/tmp/x` (the `pip download` test artifacts) — outside `/home/user`, not persisted, and not part of the
analysis. The §6 pip timings are recorded in the report.
