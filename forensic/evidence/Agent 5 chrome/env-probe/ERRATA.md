# ERRATA — corrections to `environment_characterization.md`

**Report under correction:** `environment_characterization.md` (run 1, 2026-09-04 11:10–11:41 UTC)
**Corrected by:** `env-probe` v1.1.0 / v1.1.1 (run 2, 2026-09-04 13:46–13:51 UTC) + targeted retests
**Sandbox (run 1):** `iyl5sbten1irtm0cfue4p` · **Sandbox (run 2):** `i80n46q8w7lm0xch991wu` · **Template (both):** `nlhz8vlwyupq845jsdg9`

Run 1's numbers were produced by ad-hoc tool calls whose output was never written to disk —
it existed only in the conversation transcript. Re-running the same probes as a scripted,
archived suite falsified **two** run-1 conclusions and answered **one** open question.

---

## 🔴 CORRECTION 1 — "ICMP is completely blocked" is WRONG

### What run 1 claimed
> **❌ ICMP is completely blocked.** Fails for **every** target. […] Hard limitation #4: **ICMP blocked** for the default user.

I tested only as uid 1000, saw `Operation not permitted` against every target, and generalised to "the network blocks ICMP." I never tried `sudo`.

### What is actually true
ICMP works fine. It is a **local permission issue on the `ping` binary**, not a network block:

```
$ sudo ping -c 4 8.8.8.8
rtt min/avg/max/mdev = 0.415/0.512/0.671/0.097 ms

$ sudo ping -c 4 1.1.1.1
rtt min/avg/max/mdev = 6.478/6.553/6.677/0.078 ms

$ sudo ping -c 3 github.com
rtt min/avg/max/mdev = 11.161/11.250/11.308/0.064 ms
```

Two independent causes, both local:

| Cause | Evidence |
|---|---|
| `ping` has no setuid bit | `-rwxr-xr-x 1 root root 156136 /usr/bin/ping` → mode `0o100755`, setuid `False` |
| Unprivileged ICMP sockets disabled kernel-wide | `/proc/sys/net/ipv4/ping_group_range` = `1  0` — an **empty range** (low > high), so no gid may open `SOCK_DGRAM`/ICMP |

### Fix (either works)
```bash
sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"   # allow all gids
# or
sudo setcap cap_net_raw+p /usr/bin/ping                    # needs libcap2-bin
```

### Bonus: this validates the RTT estimation method
Run 1 estimated RTT as `(time_appconnect − time_connect)/2` because the proxy made
`time_connect` meaningless. Real ICMP now independently confirms those estimates:

| Host | Run-1 TLS-delta estimate | Run-2 measured ICMP RTT | Delta |
|---|---:|---:|---:|
| github.com | 13.04 ms | **11.25 ms** | +1.8 ms |
| google.com / 8.8.8.8 | ~7.7 ms | **0.51 ms** (8.8.8.8 is inside GCP) | n/a |
| 1.1.1.1 | — | 6.55 ms | — |

The github.com agreement (13.0 vs 11.3 ms) is close, and the small positive bias is
expected — TLS-delta includes server-side crypto processing, not just propagation.
**The estimation method was sound.**

---

## 🔴 CORRECTION 2 — the npm audit "black-hole" is TRANSIENT, not structural

### What run 1 claimed
> 🔴 **npm audit endpoints hang — 420 seconds.** […] The request is silently black-holed, not refused. Hard limitation #8: **npm audit endpoints black-holed** — mitigable via flags, not fixable.

### What run 1 actually measured (these numbers were real)
| Operation | Wall | CPU |
|---|---:|---:|
| `npm install express` (defaults) | 421.098 s | 1.315 s |
| `npm audit` alone | 420.658 s | 0.55 s |
| `POST …/advisories/bulk` | timeout at 90 s, 0 bytes | — |

### What run 2 measures — the same probes, same template
| Operation | Run 1 | **Run 2** | Change |
|---|---:|---:|---|
| `POST …/security/advisories/bulk` | ⏱ timeout 90 s | ✅ **HTTP 200 in 0.057 s** | fixed |
| Same POST, 3 further attempts | — | ✅ 200 in 0.068 / 0.085 / 0.059 s | stable |
| `npm audit` (CLI) | 420.658 s | ✅ **0.433 s** | **971× faster** |
| `npm install express` (**default flags**) | 421.098 s | ✅ **0.986 s** | **427× faster** |

Verbatim, `runs/20260904T134940Z_i80n46q8w7lm0xch991wu/10_net_anomalies.txt`:
```
audit-bulk POST http=200 connect=0.002229s tls=0.027695s ttfb=0.057206s total=0.057291s
```

### Corrected conclusion
The 420 s hang was **real but transient** — most likely upstream congestion or
rate-limiting at `registry.npmjs.org`, not an egress-proxy block by this platform.
It must **not** be listed as a hard environmental limitation.

**Practical guidance is unchanged, but for a different reason:** still pass
`--no-audit --no-fund` in automation. Not because the endpoint is permanently blocked,
but because it is a **network dependency with unbounded, occasionally catastrophic tail
latency** and no default timeout. Defensive, not corrective.

### Methodological lesson
A single observation of a network failure cannot distinguish a *structural block* from
*transient congestion*. Run 1 saw one 420 s hang and inferred a permanent property. The
correct inference required a second run. **Network findings need repeat measurement
across time before being called limitations.**

---

## ✅ RESOLVED — the persistence question run 1 left open

Run 1 could not answer this from inside a single session and left markers. They have now
been read back under a genuinely different sandbox:

| Signal | Run 1 | Run 2 | Meaning |
|---|---|---|---|
| Sandbox ID | `iyl5sbten1irtm0cfue4p` | **`i80n46q8w7lm0xch991wu`** | Different sandbox |
| Uptime at first probe | 17.6 s | **11.7 s** | Fresh boot, not resumed |
| `/home/user/PERSISTENCE_MARKER.txt` | written 11:40:29Z | ✅ **read back intact** | **Home persists** |
| `/tmp/PERSISTENCE_MARKER_TMP.txt` | written 11:40:29Z | ❌ **absent** | tmpfs cleared |
| `environment_characterization.md` | written 11:41Z | ✅ present (33,576 B) | Survives |
| File mtimes | 11:11–11:41 | **all rewritten to 13:43** | Restored, not in-place |

**Answer: `/home/user` persists across sessions and across sandbox IDs. `/tmp` does not.**

The uniform 13:43 mtime on every run-1 artifact shows the home directory is **restored
from a snapshot into a fresh VM**, rather than the same VM being resumed. Original write
times are not preserved — **do not rely on mtime for pipeline bookkeeping.**

### ⚠️ New finding: `boot_id` is not unique
`boot_id = 2bb79165-136a-4b63-829d-17027b0a8e40` is **byte-identical** across two
different sandbox IDs and two separate boots. Normally kernel-random per boot, it is
evidently deterministic here (consistent with `KASLR disabled` + `random.trust_cpu=on` in
the kernel cmdline). **Never use `boot_id` as a run identifier** — use
`run_utc` + `sandbox_id`, as `MANIFEST.json` does.

---

## 🟡 MINOR — egress IP is not stable

| Run | Egress IP |
|---|---|
| Run 1 | `34.169.124.137` |
| Run 2 | `34.127.25.150` |

Both GCP. Any upstream service you IP-allowlist will break. **Do not assume a stable
egress IP.** (Run 1 reported the address without flagging this.)

---

## Unchanged findings (independently reproduced in run 2)

These held up and are corroborated by archived transcripts:

| Finding | Run 1 | Run 2 | File |
|---|---|---|---|
| OOM ceiling: 1500 MB OK, 1800 MB SIGKILL | ✅ | ✅ identical thresholds | `14_memory_oom.txt` |
| `anon-rss` at kill | 1,615,480 kB | 1,679,380 kB | `14_memory_oom.txt` |
| Firecracker microVM, KVM, no `/.dockerenv` | ✅ | ✅ | `02_isolation.txt` |
| Passwordless root, full `CapBnd`, `Seccomp: 0` | ✅ | ✅ | `02/03` |
| 2 vCPU, 2,032,608 kB RAM | ✅ | ✅ | `MANIFEST.json` |
| Proxy optimistic-accept → false-positive port scans | ✅ | ✅ | `09_net_matrix.txt` |
| All portquiz ports reachable (no egress filter) | ✅ | ✅ | `09_net_matrix.txt` |
| No TLS interception (genuine certs) | ✅ | ✅ | `08_net_latency.txt` |
| POST/PUT unrestricted | ✅ | ✅ | `10_net_anomalies.txt` |
| `/tmp` is RAM-backed tmpfs | ✅ | ✅ | `06_filesystem.txt` |
| No Docker/Podman | ✅ | ✅ | `04_tooling.txt` |
| IPv6 non-functional | ✅ | ✅ | `09_net_matrix.txt` |
| pip pure/wheel/sdist all install; gcc+OpenMP builds | ✅ | ✅ | `13_bench_install.txt` |

---

## Revised hard-limitations list

Superseding §7 of the main report:

1. **~1.6 GB RAM ceiling, zero swap** — silent SIGKILL. Unchanged, still the dominant constraint.
2. **2 vCPU** (1 physical core + SMT); no gain beyond 2 workers.
3. **No Docker/Podman.**
4. ~~ICMP blocked~~ → **ICMP works via `sudo`**; unprivileged `ping` needs a one-line sysctl.
5. **No IPv6.**
6. **`/tmp` and `/dev/shm` are RAM** (993 MB each, billed against the 2 GB).
7. **~20 GB disk.**
8. ~~npm audit black-holed~~ → **transient upstream latency**; use `--no-audit` defensively.
9. **Session-scoped VM, but `/home/user` DOES persist** (restored from snapshot; mtimes rewritten).
10. **NEW: egress IP is not stable** — IP allowlisting will break.
11. **NEW: `boot_id` is not unique across sandboxes** — unusable as a run identifier.
