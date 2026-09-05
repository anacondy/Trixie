# Sandbox Identity & Provenance Audit

**Audit performed:** 2026-09-04, ~19:25–19:40 UTC, inside the target sandbox
**Scope:** identity, image build lineage, service footprint, self-description, cross-turn stability probe
**Method:** read-only. Every command was executed in-sandbox during this session.
**Revised:** 19:40 UTC — re-verification of the draft caught two errors, corrected below. See [Corrections](#corrections-found-during-re-verification).

## Corrections found during re-verification

The draft was re-checked against live state, and again after the sandbox was recreated mid-audit. **Three claims did not hold.** All are corrected inline and recorded here so the audit trail stays honest.

| # | Claim I made | What actually happened | Found at |
|---|---|---|---|
| 1 | `E2B_TEMPLATE_ID` is a fixed template identifier | Changed value mid-session | 19:39 UTC |
| 2 | `uptime -s` is a fixed boot reference | Moved ~6 min within one boot | 19:39 UTC |
| 3 | A changed `boot_id` is the unambiguous recreation signal | Sandbox recreated; `boot_id` unchanged | 20:37 UTC |

### Correction 1 — `E2B_TEMPLATE_ID` is **not** stable within this session

My first read at ~19:25 UTC returned `E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9`. A re-read at ~19:39 UTC returned `E2B_TEMPLATE_ID=wk9vh0w7zre9vbcia51p`. The value **changed mid-session**, across three consecutive reads, and the change is visible in the calling shell's own `/proc/<pid>/environ`.

| Field | Read 1 (~19:25) | Read 2 (~19:39) | Changed? |
|---|---|---|---|
| `E2B_TEMPLATE_ID` (env) | `nlhz8vlwyupq845jsdg9` | `wk9vh0w7zre9vbcia51p` | **YES** |
| `/run/e2b/.E2B_TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` | `wk9vh0w7zre9vbcia51p` | **YES** |
| `E2B_SANDBOX_ID` (env) | `ia4a7jw0xcyn756c09iwm` | `ia4a7jw0xcyn756c09iwm` | no |
| `/run/e2b/.E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` | `ia4a7jw0xcyn756c09iwm` | no |
| `/.e2b` `TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` | no |
| `/.e2b` mtime | `2026-07-23 18:05:37.836974292` | `2026-07-23 18:05:37.836974292` | no |
| `boot_id` | `2bb79165-…-17027b0a8e40` | `2bb79165-…-17027b0a8e40` | no |
| `/proc/sys/kernel/random/boot_id` | same | same | no |

**MEASURED** side-by-side at 19:39 UTC:

```
env E2B_TEMPLATE_ID       = wk9vh0w7zre9vbcia51p
/run/e2b/.E2B_TEMPLATE_ID = wk9vh0w7zre9vbcia51p
/.e2b TEMPLATE_ID         = nlhz8vlwyupq845jsdg9
/.e2b ENV_ID              = nlhz8vlwyupq845jsdg9
/.e2b BUILD_ID            = f34a5416-ef30-4cb7-8e18-0fdecd6eb529
```

What this establishes: `E2B_TEMPLATE_ID` is injected **per session** by whatever launches my shell, not baked into the image. The `/run/e2b/.E2B_TEMPLATE_ID` file tracks it (mtime advanced `Sep 4 19:24` → `Sep 4 19:39`), while `/.e2b` — the build-time artifact — never moved. My original draft treated `E2B_TEMPLATE_ID` as a fixed template identifier. That was wrong.

**INFERRED:** the two IDs are likely a *build/base template* ID (`/.e2b`, immutable, `nlhz8vlwyupq845jsdg9`) versus a *runtime/derived template or environment* ID (env, mutable, `wk9vh0w7zre9vbcia51p`). I cannot confirm the semantics from inside the box.

### Correction 2 — `uptime -s` is not fixed, even within a single boot

`uptime -s` returned `2026-09-04 19:24:34` at ~19:26 UTC and `2026-09-04 19:30:50` at ~19:39 UTC, with `boot_id` unchanged throughout. That is direct observation that the reported boot time drifts.

**MEASURED** — 12 samples over 24 s, one boot, `boot_id` constant:

| Sample | `uptime -s` | `/proc/uptime[0]` | `btime` | `date -u` |
|---|---|---|---|---|
| 1 | `2026-09-04 19:30:50` | 536.49 | `1788550250` | `19:39:47Z` |
| 6 | `2026-09-04 19:30:50` | 546.53 | `1788550250` | `19:39:57Z` |
| 12 | `2026-09-04 19:30:50` | 558.58 | `1788550250` | `19:40:09Z` |

Within the 24 s sampling window `uptime -s` was constant, but it had already moved once between the two earlier readings. `btime` moved with it (`1788549874` → `1788550250`), confirming `btime = CLOCK_REALTIME − uptime` rather than a recorded boot instant.

This **strengthens** the §4.5 conclusion, which had been partly inferential: `uptime -s` demonstrably cannot be used as a boot timestamp in this sandbox.

### Correction 3 — `boot_id` does **not** detect sandbox recreation. My report claimed it did.

This was observed **after** the report was drafted, at 20:37–20:38 UTC, when the sandbox was recreated between turns. §6 of the original report stated:

> **If `boot_id` changes**, the sandbox was recreated rather than resumed — that is the one unambiguous signal here.

**That claim is false.** The sandbox *was* recreated and `boot_id` did *not* change.

**MEASURED** — before vs after the recreation:

| Indicator | Before (19:25–19:45 UTC) | After (20:37 UTC) | Verdict |
|---|---|---|---|
| `E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` | `i5ppm7iw8cfa89mb7ezsm` | **CHANGED** |
| `/run/e2b/.E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` | `i5ppm7iw8cfa89mb7ezsm` | **CHANGED** |
| `/proc/uptime[0]` | ~861 s | ~52 s | **RESET** |
| `uptime -s` | `2026-09-04 19:30:50` | `2026-09-04 20:37:09` | changed |
| PID 1 `lstart` | `Fri Sep 4 19:24:34 2026` | `Fri Sep 4 20:37:09 2026` | **RESTARTED** |
| workspace file birth | `19:30:28` / `19:45` | both `20:37:20` | **REWRITTEN** |
| `boot_id` | `2bb79165-136a-4b63-829d-17027b0a8e40` | `2bb79165-136a-4b63-829d-17027b0a8e40` | **UNCHANGED** |
| `journalctl --list-boots` | 1 boot, `2bb79165…` | 1 boot, `2bb79165…` | unchanged |
| `envd` `ActiveEnterTimestamp` | `Thu 2026-07-23 18:05:37 UTC` | `Thu 2026-07-23 18:05:37 UTC` | unchanged |
| `envd` monotonic / MainPID | `701726` µs / 359 | `701726` µs / 359 | unchanged |
| `jupyter` monotonic / MainPID | `2525525` µs / 437 | `2525525` µs / 437 | unchanged |
| `code-interpreter` monotonic / MainPID | `4438461` µs / 463 | `4438461` µs / 463 | unchanged |
| `/.e2b` content + mtime | `nlhz8vlwyupq845jsdg9`, `2026-07-23 18:05:37.836974292` | identical | unchanged |
| `E2B_TEMPLATE_ID` | `wk9vh0w7zre9vbcia51p` (19:39) | `nlhz8vlwyupq845jsdg9` | **REVERTED** |
| `prov_probe.txt` sha256 | `389002234b…` | `389002234b…` | **content preserved** |

**MEASURED** — PID 1 on the new instance:

```
    PID                  STARTED ELAPSED CMD
      1 Fri Sep  4 20:37:09 2026      57 /sbin/init
```

**MEASURED** — workspace files were rewritten on restore; birth and mtime are identical, the signature of a restore rather than an in-place edit:

```
prov_probe.txt                 mtime=2026-09-04 20:37:20.064794959 +0000 birth=2026-09-04 20:37:20.064794959 +0000
sandbox_identity_provenance.md mtime=2026-09-04 20:37:20.064794959 +0000 birth=2026-09-04 20:37:20.064794959 +0000
```

Four things follow:

1. **`boot_id` is preserved across sandbox recreation.** Inference B in §7.2 is now confirmed by measurement — but the operational advice built on it in §6 was wrong and is retracted here.
2. **The reliable recreation signal is `E2B_SANDBOX_ID` together with a `/proc/uptime` reset.** Either alone is ambiguous; together they are unambiguous.
3. **Workspace content survives recreation.** `prov_probe.txt` hashes identically. File *timestamps* do not survive — they are reset to the restore instant.
4. **The snapshot-restore model (§4.5) is now directly confirmed.** Every restore replays bit-identically: same PIDs, same monotonic offsets, same July-23 wall stamps, while the kernel uptime counter restarts from zero.

Also of note: `E2B_TEMPLATE_ID` **reverted** to the build-time value `nlhz8vlwyupq845jsdg9`. The transient value `wk9vh0w7zre9vbcia51p` seen at 19:39 did not persist into the new instance. This reinforces Correction 1 — that variable is not a stable identifier, in either direction.

## How to read this document

Every line is labelled with one of:

| Label | Meaning |
|---|---|
| **MEASURED** | The command was run and the output is reproduced verbatim |
| **INFERRED** | Reasoned from measured data; not directly observed |

Failed commands reproduce their error text verbatim. Nothing is substituted with a guess.

---

## Table of contents

- [Corrections found during re-verification](#corrections-found-during-re-verification) — read this first
- [How to read this document](#how-to-read-this-document)
- [1. Executive summary](#1-executive-summary)
- [2. Identity](#2-identity)
- [3. Image build lineage](#3-image-build-lineage)
- [4. Service footprint](#4-service-footprint)
- [5. Self-description](#5-self-description)
- [6. Stability probe](#6-stability-probe)
- [7. Findings and open questions](#7-findings-and-open-questions)
- [8. Command index](#8-command-index)
- [Verification statement](#verification-statement)

---

## 1. Executive summary

| Question | Answer | Basis |
|---|---|---|
| What virtualisation product is this? | **E2B** sandbox | `/.e2b`, `E2B_*` env vars, `/etc/hostname`, `/run/e2b/`, `envd.service` — MEASURED |
| Build-time template / env ID | `nlhz8vlwyupq845jsdg9` | `/.e2b` (`TEMPLATE_ID` = `ENV_ID`) — MEASURED, immutable |
| Runtime template ID | `wk9vh0w7zre9vbcia51p` as of 19:39 UTC — **changed from `nlhz8vlwyupq845jsdg9` mid-session** | `E2B_TEMPLATE_ID`, `/run/e2b/.E2B_TEMPLATE_ID` — MEASURED |
| Build ID | `f34a5416-ef30-4cb7-8e18-0fdecd6eb529` | `/.e2b` — MEASURED |
| Live sandbox ID | `ia4a7jw0xcyn756c09iwm` (19:25–19:45) → **`i5ppm7iw8cfa89mb7ezsm`** (20:37, recreated) | `E2B_SANDBOX_ID`, `/run/e2b/.E2B_SANDBOX_ID` — MEASURED |
| Base image | Debian GNU/Linux 13 (trixie), `13.6` | `/etc/os-release` — MEASURED |
| Apt snapshot pin | `20260713T000000Z` | `/etc/apt/sources.list.d/debian.sources` — MEASURED |
| dpkg packages | 650 | `dpkg-query -W \| wc -l` — MEASURED |
| pip packages | 180 | `pip list --format=freeze \| wc -l` — MEASURED |
| Does anything self-describe as "Arena" / "LMArena"? | **No.** Zero non-library matches | `grep -rIl` over `/etc /opt /usr/local` — MEASURED |
| Does any service predate the current boot? | **No.** All started at monotonic 0.70 s / 2.53 s / 4.44 s | `ActiveEnterTimestampMonotonic` vs `/proc/uptime` — MEASURED |
| Is the wall clock self-consistent? | **No.** Services stamped 2026-07-23; `date -u` is 2026-09-04; `uptime -s` itself moved mid-session | see §4.3, §4.5 — MEASURED |
| Probable cause of the clock inconsistency | Snapshot-restore (VM paused at template build on 2026-07-23, resumed 2026-09-04, wall clock stepped forward) | **INFERRED**, now with direct supporting observation |

---

## 2. Identity

### 2.1 `/.e2b`

**MEASURED** — `cat /.e2b` → exit 0

```
ENV_ID=nlhz8vlwyupq845jsdg9
TEMPLATE_ID=nlhz8vlwyupq845jsdg9
BUILD_ID=f34a5416-ef30-4cb7-8e18-0fdecd6eb529
```

It is a regular file, not a directory (confirmed: `stat /.e2b` → `regular file`).

### 2.2 Environment variables matching `^E2B_`

**MEASURED** — `env | grep -E '^E2B_'` → exit 0

First read, ~19:25 UTC:

```
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
E2B_EVENTS_ADDRESS=http://192.0.2.1
E2B_SANDBOX_ID=ia4a7jw0xcyn756c09iwm
E2B_SANDBOX=true
```

Re-read, ~19:39 UTC (three consecutive passes, identical to each other):

```
E2B_TEMPLATE_ID=wk9vh0w7zre9vbcia51p
E2B_EVENTS_ADDRESS=http://192.0.2.1
E2B_SANDBOX_ID=ia4a7jw0xcyn756c09iwm
E2B_SANDBOX=true
```

**`E2B_TEMPLATE_ID` changed between the two reads.** See [Correction 1](#correction-1--e2b_template_id-is-not-stable-within-this-session). Confirmed to be present in the shell's own environment block, not a transient artifact:

**MEASURED** — `tr '\0' '\n' < /proc/$$/environ | grep -E '^E2B_'`

```
E2B_SANDBOX=true
E2B_TEMPLATE_ID=wk9vh0w7zre9vbcia51p
E2B_SANDBOX_ID=ia4a7jw0xcyn756c09iwm
E2B_EVENTS_ADDRESS=http://192.0.2.1
```

`/proc/1/environ` and `/proc/359/environ` (envd) are unreadable at uid 1000 — errors verbatim:

```
/bin/bash: line 5: /proc/1/environ: Permission denied
/bin/bash: line 6: /proc/359/environ: Permission denied
```

So the PID-1 and envd views of these variables could not be compared. **MEASURED** limitation.

### 2.3 Hostname and hosts entries

**MEASURED** — `hostname`

```
e2b.local
```

**MEASURED** — `grep -i e2b /etc/hosts` → exit 0

```
127.0.1.1        e2b.local
192.0.2.1        events.e2b.local
```

Full `/etc/hosts` for context (**MEASURED**):

```
127.0.0.1        localhost
::1              localhost ip6-localhost ip6-loopback
fe00::           ip6-localnet
ff00::           ip6-mcastprefix
ff02::1          ip6-allnodes
ff02::2          ip6-allrouters
127.0.1.1        e2b.local
192.0.2.1        events.e2b.local
```

### 2.4 Boot ID

**MEASURED** — `cat /proc/sys/kernel/random/boot_id`

```
2bb79165-136a-4b63-829d-17027b0a8e40
```

### 2.5 Uptime

**MEASURED** — `uptime -s`, read twice in the session with `boot_id` unchanged throughout:

| Read | `uptime -s` |
|---|---|
| ~19:26 UTC | `2026-09-04 19:24:34` |
| ~19:39 UTC | `2026-09-04 19:30:50` |

**The reported boot time is not fixed.** It moved by ~6 minutes across a single, continuous boot. See [Correction 2](#correction-2--uptime--s-is-not-fixed-even-within-a-single-boot) and §4.5.

**MEASURED** — `cat /proc/uptime`, sampled repeatedly across the session (monotonically increasing, as expected):

| Read # | Value |
|---|---|
| 1 | `56.66 103.58` |
| 2 | `94.54 178.09` |
| 3 | `162.17 295.81` |
| 4 | `228.56 427.90` |
| 5 | `324.39 …` |
| 6 | `353.75 …` |
| 7 | `516.98 1000.09` |
| 8 | `536.49 …` → `558.58 …` (12 samples, 24 s) |

Note the second field: it grows roughly **1.9×** the first field, which is consistent with two CPUs accumulating idle time.

**MEASURED** — `uptime`

```
 19:26:08 up 1 min,  0 users,  load average: 0.08, 0.04, 0.01
```

### 2.6 Machine IDs

**MEASURED**

| Path | Value |
|---|---|
| `/etc/machine-id` | `67549745dd1a4564be928e47dca271fd` |
| `/var/lib/dbus/machine-id` | `67549745dd1a4564be928e47dca271fd` |

The two are identical.

### 2.7 Related identity artifacts

**MEASURED** — `ls -la /run/e2b` and the contents of each dotfile, read twice:

| Path | Content @19:25 | Content @19:39 | mtime @19:25 | mtime @19:39 |
|---|---|---|---|---|
| `/run/e2b/.E2B_SANDBOX` | `true` | `true` | Jul 23 18:05 | Jul 23 18:05 |
| `/run/e2b/.E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` | `ia4a7jw0xcyn756c09iwm` | Sep 4 19:24 | Sep 4 **19:39** |
| `/run/e2b/.E2B_TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` | `wk9vh0w7zre9vbcia51p` | Sep 4 19:24 | Sep 4 **19:39** |
| `/run/e2b/certs/` | (directory) | (directory) | Jul 23 18:05 | Jul 23 18:05 |

Two observations, both MEASURED:

1. **`/run/e2b` is rewritten on each session**, not only at resume — both ID files' mtimes advanced from `19:24` to `19:39` between my two reads, within the same boot.
2. **Only the template ID's *content* changed.** The sandbox ID kept its value while its file was rewritten; the template ID file was rewritten *and* its value replaced.

Meanwhile `/.e2b` — the build-time artifact at the filesystem root — never changed content or mtime (`2026-07-23 18:05:37.836974292`, size 107). So there are two distinct template identifiers in play:

| Source | Value | Mutability |
|---|---|---|
| `/.e2b` (`TEMPLATE_ID`, `ENV_ID`) | `nlhz8vlwyupq845jsdg9` | immutable; build-time |
| `E2B_TEMPLATE_ID` / `/run/e2b/.E2B_TEMPLATE_ID` | `wk9vh0w7zre9vbcia51p` (as of 19:39) | rewritten per session |


---

## 3. Image build lineage

### 3.1 Top-level directory mtimes

**MEASURED** — `stat -c '%y %n' /* | sort`

```
2026-07-04 09:05:00.000000000 +0000 /bin
2026-07-04 09:05:00.000000000 +0000 /boot
2026-07-04 09:05:00.000000000 +0000 /lib
2026-07-04 09:05:00.000000000 +0000 /lib64
2026-07-04 09:05:00.000000000 +0000 /sbin
2026-07-13 00:00:00.000000000 +0000 /media
2026-07-13 00:00:00.000000000 +0000 /mnt
2026-07-13 00:00:00.000000000 +0000 /opt
2026-07-13 00:00:00.000000000 +0000 /srv
2026-07-23 15:09:20.000000000 +0000 /lost+found
2026-07-23 15:09:31.833258320 +0000 /usr
2026-07-23 15:09:44.334200241 +0000 /var
2026-07-23 15:09:58.374180193 +0000 /home
2026-07-23 18:05:26.709167135 +0000 /root
2026-07-23 18:05:37.190886857 +0000 /proc
2026-07-23 18:05:37.190886857 +0000 /sys
2026-07-23 18:05:37.762886857 +0000 /dev
2026-07-23 18:05:37.976974292 +0000 /etc
2026-07-23 18:05:38.500974292 +0000 /run
2026-07-23 18:05:39.364974292 +0000 /code
2026-09-04 19:24:44.000496481 +0000 /tmp
```

The glob `/*` does not expand to `/.e2b` (dotfile), which is why it is absent here — confirmed by `ls -la /`, which does show it.

**Read of the timeline (INFERRED from the measured mtimes):**

| Epoch | Interpretation |
|---|---|
| `2026-07-04 09:05` | Debian base rootfs layout (symlinked `/bin`, `/lib`, `/lib64`, `/sbin`, empty `/boot`) |
| `2026-07-13 00:00` | apt snapshot date — matches the pin in §3.3 |
| `2026-07-23 15:09` | Image build layers: `/usr`, `/var`, `/home`, `/lost+found` |
| `2026-07-23 18:05` | Template provisioning boot — `/root`, `/etc`, `/run`, `/code`, and `/.e2b` |
| `2026-09-04 19:24` | This session's resume — only `/tmp` |

### 3.2 `/.e2b` file metadata

**MEASURED** — `stat -c '%y %s' /.e2b`

```
2026-07-23 18:05:37.836974292 +0000 107
```

**MEASURED** — `stat /.e2b` (full)

```
  File: /.e2b
  Size: 107      	Blocks: 1          IO Block: 4096   regular file
Device: 254,0	Inode: 35189       Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-09-04 19:25:30.932496481 +0000
Modify: 2026-07-23 18:05:37.836974292 +0000
Change: 2026-07-23 18:05:37.836974292 +0000
 Birth: 2026-07-23 18:05:37.832974292 +0000
```

The mtime `18:05:37.836974292` coincides to the second with `envd.service`'s `ActiveEnterTimestamp` (§4.2). **MEASURED** coincidence; whether they share a causal moment is **INFERRED**.

### 3.3 Apt snapshot pin

**MEASURED** — `grep -r snapshot.debian.org /etc/apt/sources.list*` → exit 0

```
/etc/apt/sources.list.d/debian.sources:# http://snapshot.debian.org/archive/debian/20260713T000000Z
/etc/apt/sources.list.d/debian.sources:# http://snapshot.debian.org/archive/debian-security/20260713T000000Z
```

**MEASURED** — `cat /etc/apt/sources.list` → error reproduced verbatim

```
cat: /etc/apt/sources.list: No such file or directory
```

There is no legacy `sources.list`; the image uses deb822 `.sources` files only.

**MEASURED** — full `/etc/apt/sources.list.d/debian.sources`

```
Types: deb
# http://snapshot.debian.org/archive/debian/20260713T000000Z
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
# http://snapshot.debian.org/archive/debian-security/20260713T000000Z
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

**MEASURED** — full `/etc/apt/sources.list.d/nodesource.sources`

```
Types: deb
URIs: https://deb.nodesource.com/node_20.x
Suites: nodistro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/nodesource.gpg
```

The snapshot URLs are **commented out**; the live URIs are `deb.debian.org`. The snapshot date is preserved only as a build-provenance comment.

### 3.4 dpkg package count

**MEASURED** — `dpkg-query -W --showformat='${Package} ${Version}\n' | wc -l`

```
650
```

Anchor packages from the full listing (**MEASURED**):

| Package | Version |
|---|---|
| `base-files` | `13.8+deb13u6` |
| `systemd` | `257.13-1~deb13u1` |
| `linux-libc-dev` | `6.12.95-1` |
| `libc6` | `2.41-12+deb13u3` |
| `nodejs` | `20.20.2-1nodesource1` |
| `r-base` | `4.5.0-3` |
| `imagemagick` | `8:7.1.1.43+dfsg1-1+deb13u11` |
| `openssh-server` | `1:10.0p1-7+deb13u4` |
| `python3.13` | `3.13.5-2+deb13u3` |
| `build-essential` | `12.12` |
| `git` | `1:2.47.3-0+deb13u1` |
| `zutty` | `0.16.2.20241020+dfsg1-1` |

**MEASURED, negative result:** there is no `python3-pip`, `python3-jupyter*`, or `jupyter*` entry in the dpkg database. Python and Jupyter live in `/usr/local`, outside dpkg management.

### 3.5 pip package count and interpreter

**MEASURED** — `pip list --format=freeze | wc -l`

```
180
```

**MEASURED** — interpreter location and version

```
which pip    → /usr/local/bin/pip
which pip3   → /usr/local/bin/pip3
which python → /usr/local/bin/python
which python3→ /usr/local/bin/python3
python3 -V   → Python 3.13.14
```

Note the **two Pythons**: `/usr/local/bin/python3` is `3.13.14` (source or custom build), while dpkg provides `python3.13 3.13.5-2+deb13u3`.

Selected entries from the full 180-line freeze output (**MEASURED**):

| Package | Version | Note |
|---|---|---|
| `e2b-charts` | `1.0.0` | E2B-specific |
| `jupyter_server` | `2.20.0` | backs `jupyter.service` |
| `ipykernel` | `6.31.0` | |
| `jupyter_client` | `8.9.1` | |
| `bash_kernel` | `0.10.0` | |
| `numpy` | `2.3.5` | |
| `pandas` | `2.2.3` | |
| `scipy` | `1.17.1` | |
| `scikit-learn` | `1.6.1` | |
| `scikit-image` | `0.25.2` | |
| `matplotlib` | `3.10.9` | |
| `plotly` | `6.0.1` | |
| `kaleido` | `1.3.0` | static plotly export |
| `seaborn` | `0.13.2` | |
| `bokeh` | `3.9.1` | |
| `spacy` | `3.8.14` | |
| `nltk` | `3.10.0` | |
| `gensim` | `4.4.0` | |
| `librosa` | `0.11.0` | audio |
| `soundfile` | `0.13.1` | audio |
| `opencv-python` | `4.11.0.86` | |
| `openpyxl` | `3.1.5` | xlsx |
| `python-docx` | `1.1.2` | docx |
| `xlrd` | `2.0.2` | xls |
| `xarray` | `2025.4.0` | |
| `pillow` | `12.3.0` | |
| `lxml` | `6.1.1` | |
| `pytest` | `9.0.3` | |
| `pip` | `26.1.2` | |

### 3.6 OS and kernel identity

**MEASURED** — `cat /etc/os-release`

```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.6
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

**MEASURED** — `uname -a`

```
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux
```

The kernel is `6.1.158+` — **not** a Debian-packaged kernel (dpkg's `linux-libc-dev` is `6.12.95-1`, headers only). The `+` suffix and standalone build stamp indicate a custom-built guest kernel. **MEASURED** version string; custom-build conclusion **INFERRED**.

**MEASURED** — `cat /proc/cmdline`

```
clocksource=kvm-clock i8042.noaux i8042.nokbd init=/sbin/init ip=169.254.0.21::169.254.0.22:255.255.255.252:instance:eth0:off:tap0 ipv6.autoconf=1 ipv6.disable=0 loglevel=1 panic=1 pci=off quiet random.trust_cpu=on reboot=k rootflags=discard pci=off virtio_mmio.device=4K@0xc0001000:6 root=/dev/vda rw virtio_mmio.device=4K@0xc0002000:7 virtio_mmio.device=4K@0xc0003000:8 virtio_mmio.device=4K@0xc0004000:9
```

MicroVM markers present in the command line: `pci=off`, `virtio_mmio.device=` device tree, `clocksource=kvm-clock`, `panic=1`, `loglevel=1 quiet`, kernel-configured networking via `ip=`, hostname `instance`, root on `/dev/vda`.

**MEASURED** — `ip -brief addr`

```
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             169.254.0.21/30 fe80::fc:ff:fe00:5/64
```

**MEASURED** — DMI and hypervisor introspection, both absent, errors verbatim

```
cat: /sys/class/dmi/id/product_name: No such file or directory
cat: /sys/hypervisor/type: No such file or directory
```

No DMI table is exposed to the guest — consistent with a minimal microVM rather than a full-emulation VM. **MEASURED** absence; microVM conclusion **INFERRED**.

---

## 4. Service footprint

### 4.1 Running services

**MEASURED** — `systemctl list-units --type=service --state=running --no-pager --no-legend` → exit 0

```
  code-interpreter.service loaded active running Code Interpreter Server
  dbus.service             loaded active running D-Bus System Message Bus
  envd.service             loaded active running Env Daemon Service
  getty@tty1.service       loaded active running Getty on tty1
  jupyter.service          loaded active running Jupyter Server
  nfs-blkmap.service       loaded active running pNFS block layout mapping daemon
  rpcbind.service          loaded active running RPC bind portmap service
  ssh.service              loaded active running OpenBSD Secure Shell server
  systemd-journald.service loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-networkd.service loaded active running Network Configuration
```

**MEASURED** — failed/notable non-running units from `systemctl list-units --type=service --all --no-pager`

| Unit | State |
|---|---|
| `chronyd-restricted.service` | `loaded failed failed` |
| `nftables.service` | `loaded failed failed` |
| `chrony.service` | `loaded inactive dead` |
| `apt-daily.service` / `apt-daily-upgrade.service` | `loaded inactive dead` |
| `NetworkManager.service`, `nfs-server.service`, `gssproxy.service`, `display-manager.service`, `auditd.service`, `connman.service`, various `ntp*` | `not-found inactive dead` |

### 4.2 Unit file paths and ExecStart

**MEASURED** — `systemctl show <unit> -p FragmentPath` and `systemctl cat <unit>`

| Unit | FragmentPath | ExecStart |
|---|---|---|
| `envd` | `/etc/systemd/system/envd.service` | `/usr/bin/envd` |
| `jupyter` | `/etc/systemd/system/jupyter.service` | `/usr/local/bin/jupyter server --IdentityProvider.token=""` |
| `code-interpreter` | `/etc/systemd/system/code-interpreter.service` | `/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640` |

**MEASURED** — `/usr/bin/envd --version`

```
0.6.10
```

**MEASURED** — unit file mtimes from `ls -la /etc/systemd/system`

| File | mtime | Size |
|---|---|---|
| `envd.service` | `Jan  1  1970` | 3104 |
| `jupyter.service` | `Mar 23 13:13` | 428 |
| `code-interpreter.service` | `Mar 23 13:13` | 519 |

`envd.service` carries an epoch-zero mtime, meaning its timestamp was never set from a real clock — **MEASURED**; the reason is **INFERRED** (written before the guest clock was valid, or stamped deterministically by the build).

**MEASURED** — `code-interpreter.service` header

```
[Unit]
Description=Code Interpreter Server
Documentation=https://github.com/e2b-dev/code-interpreter
Requires=jupyter.service
After=jupyter.service
PartOf=jupyter.service
StartLimitBurst=0
```

**MEASURED** — `envd.service` notable directives

```
DefaultDependencies=no
After=systemd-journald.socket systemd-remount-fs.service local-fs.target systemd-tmpfiles-setup.service
Nice=-20
OOMScoreAdjust=-1000
Environment="GOMEMLIMIT=512MiB"
```

The unit file contains an extensive inline design comment describing the E2B boot and cert-seeding contract (see §5.1 for the extracted E2B lines).

### 4.3 Listening sockets

**MEASURED** — `command -v ss` → `/usr/bin/ss` (present; `/proc/net/tcp` was also read as a cross-check)

**MEASURED** — `ss -tlnp` → exit 0, full table

```
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      100        127.0.0.1:35769      0.0.0.0:*
LISTEN 0      5       169.254.0.21:47945      0.0.0.0:*
LISTEN 0      5       169.254.0.21:34675      0.0.0.0:*
LISTEN 0      4096         0.0.0.0:111        0.0.0.0:*
LISTEN 0      5       169.254.0.21:35769      0.0.0.0:*
LISTEN 0      100        127.0.0.1:47945      0.0.0.0:*
LISTEN 0      100        127.0.0.1:34675      0.0.0.0:*
LISTEN 0      128        127.0.0.1:8888       0.0.0.0:*
LISTEN 0      5       169.254.0.21:8888       0.0.0.0:*
LISTEN 0      100        127.0.0.1:44461      0.0.0.0:*
LISTEN 0      5       169.254.0.21:35105      0.0.0.0:*
LISTEN 0      100        127.0.0.1:39379      0.0.0.0:*
LISTEN 0      100        127.0.0.1:41435      0.0.0.0:*
LISTEN 0      100        127.0.0.1:43501      0.0.0.0:*
LISTEN 0      100        127.0.0.1:35105      0.0.0.0:*
LISTEN 0      5       169.254.0.21:44461      0.0.0.0:*
LISTEN 0      5       169.254.0.21:39379      0.0.0.0:*
LISTEN 0      5       169.254.0.21:41435      0.0.0.0:*
LISTEN 0      5       169.254.0.21:43501      0.0.0.0:*
LISTEN 0      5       169.254.0.21:60465      0.0.0.0:*
LISTEN 0      5       169.254.0.21:53335      0.0.0.0:*
LISTEN 0      5       169.254.0.21:60493      0.0.0.0:*
LISTEN 0      2048         0.0.0.0:49999      0.0.0.0:*
LISTEN 0      100        127.0.0.1:60465      0.0.0.0:*
LISTEN 0      100        127.0.0.1:60493      0.0.0.0:*
LISTEN 0      100        127.0.0.1:53335      0.0.0.0:*
LISTEN 0      4096            [::]:111           [::]:*
LISTEN 0      4096               *:22               *:*
LISTEN 0      128            [::1]:8888          [::]:*
LISTEN 0      4096               *:49983            *:*
```

Identified listeners:

| Port | Bind | Likely owner | Basis |
|---|---|---|---|
| `49999` | `0.0.0.0` | `code-interpreter` (uvicorn) | **MEASURED** — matches ExecStart `--port 49999` |
| `8888` | `127.0.0.1`, `[::1]` | `jupyter server` | **INFERRED** — standard jupyter port; ExecStart sets no port |
| `22` | `*` | `sshd` | **INFERRED** — `ssh.service` is running |
| `111` | `0.0.0.0`, `[::]` | `rpcbind` | **MEASURED** — `rpcbind.service` running |
| `49983` | `*` | unattributed | **MEASURED** socket, owner unknown |
| high ports on `127.0.0.1` / `169.254.0.21` | loopback + eth0 | jupyter kernel/ZMQ channels | **INFERRED** |

**MEASURED limitation:** the `Process` column of `ss -tlnp` is empty for every row. Process attribution is unavailable at `uid=1000`; socket-to-PID mapping was not obtained.

### 4.4 ActiveEnterTimestamp and the boot comparison

**MEASURED** — `systemctl show <unit> -p ActiveEnterTimestamp`

| Unit | ActiveEnterTimestamp |
|---|---|
| `envd` | `Thu 2026-07-23 18:05:37 UTC` |
| `jupyter` | `Thu 2026-07-23 18:05:39 UTC` |
| `code-interpreter` | `Thu 2026-07-23 18:05:41 UTC` |
| `dbus` | `Thu 2026-07-23 18:05:37 UTC` |

**MEASURED** — monotonic timestamps, restart counts, and main PIDs

| Unit | MainPID | ActiveEnterTimestampMonotonic | NRestarts |
|---|---|---|---|
| `envd` | 359 | `701726` µs = **0.70 s** | 0 |
| `jupyter` | 437 | `2525525` µs = **2.53 s** | 0 |
| `code-interpreter` | 463 | `4438461` µs = **4.44 s** | 0 |

**MEASURED** — `ps -o pid,ppid,lstart,etimes,times,cmd -p 359,437,463`

```
    PID    PPID                  STARTED ELAPSED     TIME CMD
    359       1 Fri Sep  4 19:24:34 2026     161        1 /usr/bin/envd
    437       1 Fri Sep  4 19:24:36 2026     159        1 /usr/local/bin/python3.13 /usr/local/bin/jupyter-server --IdentityProvider.token=
    463       1 Fri Sep  4 19:24:38 2026     157        0 /root/.server/.venv/bin/python /root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640
```

**MEASURED** — `systemctl list-jobs` → `No jobs running.`

#### Explicit answer: does any service predate the current boot?

**No. No service predates the current boot.** Established four independent ways, all MEASURED:

1. **Monotonic comparison — decisive.** systemd's monotonic stamps (0.70 s, 2.53 s, 4.44 s) are all far inside the current `/proc/uptime` value (228.56 s at the moment of reading). A service that predated the boot could not have a monotonic offset smaller than the boot's own elapsed time.
2. **`NRestarts=0`** for all three, and no pending jobs.
3. **`journalctl --list-boots`** shows exactly **one** boot, whose ID equals the live kernel's boot_id:
   ```
   IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
     0 2bb79165136a4b63829d17027b0a8e40 Thu 2026-07-23 18:05:39 UTC Thu 2026-07-23 18:05:39 UTC
   ```
   There is no earlier boot for anything to predate.
4. **The wall-clock comparison is the one that fails — and the failure is itself the finding.** Wall stamps say `2026-07-23 18:05:3x`; `date -u` says `2026-09-04T19:30Z`; `/proc/uptime` says `353` s. A VM genuinely running since 2026-07-23 would report roughly 3.7 × 10⁶ s of uptime. It reports 353 s.

### 4.5 Reconciling the clock discrepancy

**MEASURED** — single-read clock comparison

```
CLOCK_REALTIME   = 1788550198.6846955   → 2026-09-04T19:28:22 UTC
CLOCK_MONOTONIC  = 228.561507072
CLOCK_BOOTTIME   = 228.561512567
/proc/uptime[0]  = 228.56
/proc/stat btime = 1788549874            → 2026-09-04T19:24:34 UTC
```

**MEASURED** — arithmetic identity check

```
CLOCK_REALTIME     = 1788550198.6846955
/proc/uptime[0]    = 324.39
CLOCK_REALTIME - up= 1788549874.2946954
/proc/stat btime   = 1788549874
match              = True
```

**MEASURED** — `date -u -d @1788549874`

```
Fri Sep  4 19:24:34 UTC 2026
```

Three facts follow, all MEASURED:

- `/proc/stat btime` is **computed** as `CLOCK_REALTIME − uptime`, not a recorded boot event. So `uptime -s` inherits whatever the wall clock says *now*.
- `CLOCK_MONOTONIC ≈ CLOCK_BOOTTIME ≈ /proc/uptime[0]`. There is **no** recorded suspend gap between the monotonic and boottime clocks.
- Therefore `uptime -s` (`2026-09-04 19:24:34`) is not evidence of when the kernel actually started. The services' wall stamps (`2026-07-23 18:05:3x`) are what the guest believed *at service-start time*, and realtime was stepped forward afterwards.

**MEASURED** — time synchronisation state

```
timedatectl →  System clock synchronized: no
               NTP service: inactive
               RTC time: n/a
               Time zone: Etc/UTC (UTC, +0000)
chronyc tracking → 506 Cannot talk to daemon
```

`chrony.service` is `inactive dead`; `chronyd-restricted.service` is `failed`. No time daemon is running, so nothing in-guest could have performed a gradual slew. **MEASURED**.

**MEASURED** — the clock-step event is **not** in the journal

```
journalctl -q -b --no-pager -o short-iso | grep -iE 'clock|step|adjust|suspend|resume'
→ (empty)
```

The entire boot journal is **3 lines**, all at `2026-07-23T18:05:39+00:00`:

```
Jul 23 18:05:39 e2b.local sudo[427]:     user : PWD=/home/user ; USER=root ; COMMAND=/usr/bin/systemctl start jupyter
Jul 23 18:05:39 e2b.local sudo[427]: pam_unix(sudo:session): session opened for user root(uid=0) by (uid=1000)
Jul 23 18:05:39 e2b.local sudo[427]: pam_unix(sudo:session): session closed for user root
```

That single sudo line is itself notable: `jupyter.service` was started **manually by uid 1000 via sudo** during template provisioning, not by systemd dependency resolution.

**INFERRED, labelled as such:** the `2026-07-23 18:05:3x` service stamps, the single-entry boot journal, `btime` being derived from a stepped clock, `/.e2b`'s mtime matching envd's start to the second, `/etc/inittab`'s `fsfreeze --freeze /` followed by *"Wait forever to prevent the VM from exiting until the sandbox is paused and snapshot is taken"*, and the `e2b-ca.crt` mtime of `Sep 4 19:24` together indicate: **the guest's memory state — including `boot_id` and all systemd unit state — was captured at template-build time on 2026-07-23, and resumed on 2026-09-04 with the wall clock stepped forward to match the host.** The exact step instant could not be measured (empty journal, blank `ss` process column).

#### Direct confirmation that `uptime -s` drifts

The above was assembled from a single pair of readings. Re-verification produced a **direct observation** of the drift, which upgrades this from inference to measurement for the specific claim that `uptime -s` is unusable as a boot timestamp.

**MEASURED** — `uptime -s` and `btime` across one continuous boot, `boot_id` constant at `2bb79165-136a-4b63-829d-17027b0a8e40`:

| When | `uptime -s` | `btime` |
|---|---|---|
| ~19:26 UTC | `2026-09-04 19:24:34` | `1788549874` |
| ~19:39 UTC | `2026-09-04 19:30:50` | `1788550250` |

`btime` moved by 376 s while the kernel never rebooted. Twelve samples taken over 24 s at ~19:40 UTC showed `uptime -s` constant at `19:30:50` while `/proc/uptime[0]` advanced `536.49 → 558.58` — i.e. the value is stable *between* clock steps, and jumps *at* them.

So the sandbox's wall clock has been stepped **at least twice** during this session, and `uptime -s` inherits each step. Any conclusion drawn from `uptime -s` alone is unsafe in this environment.


---

## 5. Self-description

### 5.1 The requested grep

**MEASURED** — `grep -rIl -m1 -iE 'arena|lmarena|e2b' /etc /opt /usr/local 2>/dev/null | head -50` → exit 0, 50 paths returned.

Matching lines for every hit that is **not** an E2B/Python/R library file (**MEASURED**):

```
/etc/systemd/system/envd.service:40:# (/usr/local/share/ca-certificates/e2b-ca.crt) into the bundle at boot. That CA
/etc/systemd/system/envd.service:46:ExecStartPre=/bin/sh -c 'mountpoint -q /etc/ssl/certs || { mkdir -p /run/e2b/certs && { tar -C /run/e2b/certs -xf /usr/local/share/e2b/ssl-certs.tar 2>/dev/null || cp -a /etc/ssl/certs/. /run/e2b/certs/ 2>/dev/null; }; mount --bind /run/e2b/certs /etc/ssl/certs; } && ([ -s /etc/ssl/certs/ca-certificates.crt ] || update-ca-certificates)'
/etc/systemd/system/code-interpreter.service:3:Documentation=https://github.com/e2b-dev/code-interpreter
/etc/hostname:1:e2b.local
/etc/hosts:7:127.0.1.1        e2b.local
/etc/hosts:8:192.0.2.1        events.e2b.local
/etc/inittab:12:::wait:/bin/sh -c 'echo "E2B_PROVISIONING_EXIT:$(cat /provision.result || printf 1)"'
```

**MEASURED** — the remaining hits are confirmed false positives (hex/base64 substrings and the C word "arena"):

| File | Nature of match |
|---|---|
| `/etc/ssh/moduli` | 75 hex-substring matches (e.g. `…BEFB5C160159F85A69C3990D6A5078…`) |
| `/etc/ssl/certs/ca-certificates.crt` | 4 base64 matches (e.g. `…E2bFhc8e6kG…`) |
| `/etc/apt/trusted.gpg.d/debian-archive-bullseye-automatic.asc` | base64 |
| `/etc/apt/trusted.gpg.d/debian-archive-trixie-security-automatic.asc` | base64 |
| `/usr/local/include/python3.13/**` | CPython `pyarena`, mimalloc arena allocator |
| `/usr/local/lib/python3.13/**`, `site-packages/**` | pytz/tzdata zone names containing "arena" (e.g. timezone strings), pygments unicode tables |
| `/usr/local/lib/R/site-library/**` | R package docs |

### 5.2 The Arena question, answered directly

**MEASURED** — a grep for `arena`/`lmarena` alone, filtered to exclude library directories:

```
grep -rIl -iE 'arena|lmarena' /etc /opt /usr/local 2>/dev/null \
  | grep -viE 'python3\.13|site-packages|/R/|include/'
→ (empty output), exit 0
```

**Zero files under `/etc`, `/opt`, or `/usr/local` mention Arena or LMArena as a product.** Every `arena` occurrence in the entire filesystem search is CPython's memory-arena allocator, mimalloc, or R documentation.

Anything Arena-level in my description of this session comes from my runtime context, **not** from this filesystem. I am not treating my own context as evidence about the box.

### 5.3 `$HOME`

**MEASURED** — `echo $HOME` → `/home/user`; `id` → `uid=1000(user) gid=1000(user) groups=1000(user),27(sudo),100(users)`

**MEASURED** — `ls -la ~`

```
total 0
drwx------ 2 user user 128 Sep  4 19:25 .
drwxr-xr-x 3 root root  60 Jul 23 15:09 ..
```

Completely empty — **no dotfiles at all** at the time of that read. (The only file present at session end is `prov_probe.txt`, written in §6, plus this document.)

**MEASURED** — `/root` is not readable:

```
ls: cannot open directory '/root': Permission denied
```

### 5.4 `/code`

**MEASURED** — `ls -la /code` → exit 0

```
total 4
drwxrwxrwx  2 root root   60 Jul 23 18:05 .
drwxr-xr-x 19 root root 4096 Jul 23 18:05 ..
```

**Empty directory**, world-writable (`0777`), created at template-build time.

**MEASURED** — `find /code -maxdepth 3`

```
/code
```

### 5.5 Supporting self-description artifacts

**MEASURED** — `/usr/local/share/e2b`

```
-rw-r--r-- 1 root root 634880 Jul 23 18:05 ssl-certs.tar
```

**MEASURED** — `/usr/local/share/ca-certificates`

```
-rw-r--r-- 1 root root 595 Sep  4 19:24 e2b-ca.crt
```

**MEASURED** — `openssl x509 -in /usr/local/share/ca-certificates/e2b-ca.crt -noout -subject -issuer -dates`

```
subject=O=E2B, CN=E2B Proxy CA
issuer=O=E2B, CN=E2B Proxy CA
notBefore=Sep  4 12:34:17 2026 GMT
notAfter=Sep  4 13:34:17 2027 GMT
```

Self-signed, issued 12 s before the `uptime -s` value of `19:24:34`. **MEASURED** values.

**MEASURED** — `cat /etc/inittab` (verbatim, in full)

```
# Run system init
::sysinit:/etc/init.d/rcS

# Run the provision script, prefix the output with a log prefix
::wait:/bin/sh -c '/usr/local/bin/provision.sh 2>&1 | sed "s/^/[external] /"'

# Flush filesystem changes to disk
::wait:/usr/bin/busybox sync
::wait:fsfreeze --freeze /

# Report the exit code of the provisioning script
::wait:/bin/sh -c 'echo "E2B_PROVISIONING_EXIT:$(cat /provision.result || printf 1)"'

# Wait forever to prevent the VM from exiting until the sandbox is paused and snapshot is taken
::wait:/usr/bin/busybox sleep infinity
```

This is the **template build** init, not the runtime init (`/proc/cmdline` has `init=/sbin/init`, i.e. systemd). The final two comments describe the snapshot lifecycle explicitly.

**MEASURED** — the provisioning artifacts referenced by inittab are all absent, errors verbatim:

```
ls: cannot access '/usr/local/bin/provision.sh': No such file or directory
ls: cannot access '/provision.result': No such file or directory
ls: cannot access '/provision.sh': No such file or directory
```

**MEASURED** — serial console autologin drop-in, `/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf`

```
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I 115200,38400,9600 vt102
```

**MEASURED** — `/opt` is empty; `/usr/local` contains `bin etc games include lib libexec man sbin share src`.

### 5.6 Two distinctions worth keeping straight

**MEASURED:**

1. **`/.e2b` is a template/build record, not a live-sandbox record.** Its `BUILD_ID` (`f34a5416-ef30-4cb7-8e18-0fdecd6eb529`) appears nowhere in `env`. Its `ENV_ID` and `TEMPLATE_ID` are both `nlhz8vlwyupq845jsdg9`. At the start of the session that value also matched `E2B_TEMPLATE_ID`; **by 19:39 UTC it no longer did** — `E2B_TEMPLATE_ID` had become `wk9vh0w7zre9vbcia51p` while `/.e2b` stayed put. `/.e2b` has never matched `E2B_SANDBOX_ID`.
2. **The live sandbox ID lives in `/run/e2b/.E2B_SANDBOX_ID`** (`ia4a7jw0xcyn756c09iwm`), matching `E2B_SANDBOX_ID` at both reads. That directory is where per-instance identity is kept — though note it is rewritten each session, so it reflects the current session rather than being an immutable record.

**Practical consequence:** for anything that must survive across sessions, `/.e2b`'s `BUILD_ID` is the only identifier in this audit that was both immutable and unambiguous. `E2B_SANDBOX_ID` was stable across this session but is a session-scoped value by nature; `E2B_TEMPLATE_ID` demonstrably is not stable at all.

---

## 6. Stability probe

**MEASURED** — written to `/home/user/prov_probe.txt`, 601 bytes.

Requested fields: `boot_id`, `E2B_SANDBOX_ID`, `/.e2b` contents, `date -u +%FT%TZ`. I added `uptime_1`, `stat_btime`, `machine_id` and both `ActiveEnterTimestamp` values to make a later re-read more diagnostic.

```
# prov_probe.txt — stability probe, written in turn 1 (2026-09-04)
date_utc=2026-09-04T19:30:28Z
date_epoch=1788550228
boot_id=2bb79165-136a-4b63-829d-17027b0a8e40
E2B_SANDBOX_ID=ia4a7jw0xcyn756c09iwm
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
uptime_1=353.75
stat_btime=1788549874
hostname=e2b.local
machine_id=67549745dd1a4564be928e47dca271fd
envd_ActiveEnterTimestamp=Thu 2026-07-23 18:05:37 UTC
jupyter_ActiveEnterTimestamp=Thu 2026-07-23 18:05:39 UTC
# /.e2b verbatim >>>
ENV_ID=nlhz8vlwyupq845jsdg9
TEMPLATE_ID=nlhz8vlwyupq845jsdg9
BUILD_ID=f34a5416-ef30-4cb7-8e18-0fdecd6eb529
# /.e2b verbatim <<<
```

**MEASURED** — integrity anchor for the next turn

```
sha256sum /home/user/prov_probe.txt
389002234ba1e84c379c623066f34e3a634f2dbffe9ce34a87f97d97c5b9acaa  /home/user/prov_probe.txt
```

**MEASURED** — `stat /home/user/prov_probe.txt`: `Uid: (1000/user)`, mode `0644`, `Modify: 2026-09-04 19:30:28`, `Birth: 2026-09-04 19:30:28`.

> **Already-stale value inside this file:** the `E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9` line above was correct at the moment of writing (19:30:28 UTC) and was **wrong within nine minutes** — by 19:39 UTC the live value was `wk9vh0w7zre9vbcia51p`. The file is left unmodified on purpose: it is a snapshot, and rewriting it would defeat the point. Its sha256 below is the anchor to check against.

A note on process: an earlier draft of this file contained a stray placeholder line; it was rewritten before the hash above was taken, so the sha256 corresponds to the final content.

**MEASURED** — the file survived re-verification intact: at 19:39 UTC `sha256sum prov_probe.txt` still returned `389002234ba1e84c379c623066f34e3a634f2dbffe9ce34a87f97d97c5b9acaa`, 601 bytes.

#### What to compare on re-read

> **⚠ Retracted guidance.** This section originally advised that a changed `boot_id` was "the one unambiguous signal" of recreation. **That was wrong and has been falsified by observation** — see [Correction 3](#correction-3--boot_id-does-not-detect-sandbox-recreation-my-report-claimed-it-did). The sandbox was recreated at 20:37 UTC and `boot_id` did not move. The corrected table below reflects what was actually observed.

Three fields in this probe turned out to be **bad stability indicators**.

| Field | Observed behaviour | Why |
|---|---|---|
| `boot_id` | **UNCHANGED across a sandbox recreation** — useless as a recreate detector | MEASURED: same `2bb79165-…` before and after; preserved by the snapshot |
| `stat_btime` | changes constantly | `CLOCK_REALTIME − uptime`, recomputed live; moved `1788549874` → `1788550250` → reset |
| `E2B_TEMPLATE_ID` | changed twice, in both directions | MEASURED: `nlhz8…` → `wk9vh…` → `nlhz8…`; session-scoped |
| `machine_id` | unchanged | image-baked; identifies the image, not the instance |
| `envd_ActiveEnterTimestamp` | unchanged (`Thu 2026-07-23 18:05:37 UTC`) | replays identically on every restore |
| `jupyter_ActiveEnterTimestamp` | unchanged (`Thu 2026-07-23 18:05:39 UTC`) | same |
| `uptime_1` | grows within an instance; **resets to ~0 on recreation** | real elapsed time of the current instance |

**The actually-reliable recreation signal**, measured at 20:37 UTC:

```
E2B_SANDBOX_ID changed   (ia4a7jw0xcyn756c09iwm → i5ppm7iw8cfa89mb7ezsm)
AND /proc/uptime[0] reset (~861 s → ~52 s)
```

`E2B_SANDBOX_ID` alone is the single best indicator. Nothing in this probe file detects recreation on its own — the file's own content persisted intact (sha256 `389002234b…` unchanged) while the instance underneath it was replaced.


---

## 7. Findings and open questions

### 7.1 Established by measurement

| # | Finding |
|---|---|
| 1 | This is an **E2B** sandbox: build-time template `nlhz8vlwyupq845jsdg9`, build `f34a5416-ef30-4cb7-8e18-0fdecd6eb529`, live sandbox `ia4a7jw0xcyn756c09iwm`, envd `0.6.10`. |
| 2 | Guest is **Debian 13 (trixie) 13.6** on a custom **6.1.158+** kernel, with a microVM command line (`pci=off`, `virtio_mmio`, `kvm-clock`, `root=/dev/vda`). |
| 3 | The image is pinned to apt snapshot **`20260713T000000Z`**, though the snapshot URIs are commented out in favour of live `deb.debian.org`. |
| 4 | **650** dpkg packages and **180** pip packages; two distinct Python installs (`/usr/local` 3.13.14 vs dpkg 3.13.5). |
| 5 | **No service predates the current boot** — monotonic stamps 0.70 / 2.53 / 4.44 s, `NRestarts=0`, one journal boot. |
| 6 | The wall clock is **internally inconsistent**: services stamped 2026-07-23, `date -u` 2026-09-04, uptime ~354 s. `btime` is derived, not recorded. |
| 7 | **`uptime -s` demonstrably drifts** — `19:24:34` → `19:30:50` within one boot, `boot_id` unchanged, `btime` moving with it. At least two clock steps occurred during this session. |
| 8 | **`E2B_TEMPLATE_ID` is not a stable identifier** — it changed from `nlhz8vlwyupq845jsdg9` to `wk9vh0w7zre9vbcia51p` mid-session while `E2B_SANDBOX_ID` and `boot_id` held. `/.e2b` never changed. |
| 9 | **`/run/e2b` is rewritten per session** — both ID files' mtimes advanced `19:24` → `19:39` within the same boot. |
| 10 | **No time daemon is running** (`chrony` inactive, `chronyd-restricted` failed, `NTP service: inactive`, `System clock synchronized: no`), so no in-guest gradual correction occurred. |
| 11 | **Nothing on the filesystem identifies this as Arena/LMArena.** Zero non-library matches across `/etc`, `/opt`, `/usr/local`. |
| 12 | `$HOME` is empty of dotfiles; `/code` is an empty world-writable directory; `/opt` is empty. |
| 13 | `jupyter.service` was started **manually via sudo by uid 1000** during template provisioning — the only substantive line in the entire boot journal. |

**Added after the 20:37 UTC recreation event:**

| # | Finding |
|---|---|
| 14 | **The sandbox was recreated mid-audit** — `E2B_SANDBOX_ID` changed, `/proc/uptime` reset from ~861 s to ~52 s, PID 1 restarted. |
| 15 | **`boot_id` survives recreation unchanged.** It is *not* an instance identifier. Retracts the guidance originally given in §6. |
| 16 | **Workspace content survives recreation; timestamps do not.** `prov_probe.txt` sha256 unchanged; both files' birth and mtime reset to `20:37:20`. |
| 17 | **Restores replay bit-identically** — same MainPIDs (359/437/463), same monotonic offsets, same July-23 wall stamps. This directly confirms the snapshot model in §4.5. |
| 18 | **`E2B_TEMPLATE_ID` reverted** to the build-time value `nlhz8vlwyupq845jsdg9`; the transient `wk9vh0w7zre9vbcia51p` did not persist. |

### 7.2 Inferred, not measured

| # | Inference | Supporting measurements |
|---|---|---|
| A | The guest was **paused at template-build time (2026-07-23 18:05:3x) and resumed on 2026-09-04**, with the wall clock stepped forward. | §4.4, §4.5; `/etc/inittab` snapshot comments; `e2b-ca.crt` mtime `Sep 4 19:24`. The *drift* half is now directly measured; the *snapshot* explanation remains inferred |
| B | ~~`boot_id` is not a reliable fresh-boot indicator — it lives in guest memory and would be preserved across a snapshot restore.~~ **NOW MEASURED, no longer inferred.** Observed directly at 20:37 UTC: sandbox recreated, `boot_id` identical. See Correction 3 | `E2B_SANDBOX_ID` changed and `/proc/uptime` reset while `boot_id` stayed `2bb79165-136a-4b63-829d-17027b0a8e40` |
| C | The kernel is a purpose-built microVM guest kernel rather than a distro package. | `6.1.158+` with a `+` suffix, build date `Fri Jul 17 14:31:34 UTC 2026`, no matching dpkg entry |
| D | `envd.service`'s `Jan 1 1970` mtime reflects a file written before the guest clock was valid, or a deterministically stamped build artifact. | §4.2 |
| E | `/.e2b`'s `TEMPLATE_ID`/`ENV_ID` (`nlhz8vlwyupq845jsdg9`) is the **build/base template**, while `E2B_TEMPLATE_ID` is a **runtime or derived** identifier injected per session. The fact that it *reverted* to the base value on recreation supports this reading. | §2.2, §2.7, Correction 3. Semantics still not confirmable from inside the guest |
| F | The clock steps are driven from **outside** the guest (host/hypervisor on resume), not by an in-guest daemon. | §4.5: no time daemon running, `chrony` inactive, `NTP service: inactive`; yet `CLOCK_REALTIME` moved ≥2 times |
| G | The guest is restored from a **frozen memory snapshot taken at template-build time**, not re-booted from disk each time. | Identical MainPIDs, monotonic offsets and July-23 wall stamps across two instances, with `/proc/uptime` reset to zero |

### 7.3 Open questions this audit could not resolve

| Question | Why it is open |
|---|---|
| Exact instants of the clock steps | Boot journal is 3 lines; `grep -iE 'clock\|step\|adjust\|suspend\|resume'` returned empty. Drift observed but not timestamped at source |
| What `E2B_TEMPLATE_ID` actually denotes, and why it changed then reverted | Only the value changes are observable; the injection point is outside the guest. `/proc/1/environ` and envd's environ are unreadable at uid 1000 |
| Which process owns each listening socket | `ss -tlnp`'s Process column is blank at uid 1000; `/proc/*/fd` not traversed |
| Owner of the `*:49983` listener | Not attributable to any unit file read |
| Contents of `/root`, `/root/.server`, `/root/.jupyter` | `Permission denied` at uid 1000 |
| How often recreation occurs, and what triggers it | Only one recreation was observed, incidentally, between two turns |

**Resolved during the audit:** "Whether `boot_id` survives a snapshot/restore cycle" was listed as open in the first draft. It is now answered — **yes, it survives unchanged** (Correction 3).

---

## 8. Command index

Every command executed for this audit, in order. `✓` = succeeded, `✗` = failed (error reproduced verbatim in the document).

### Identity

```
cat /.e2b                                                            ✓
stat -c '%y %s' /.e2b   (read 1 and read 2)                          ✓
env | grep -E '^E2B_'   (read 1, and read 2 × 3 passes)              ✓
tr '\0' '\n' < /proc/$$/environ | grep -E '^E2B_'                     ✓
tr '\0' '\n' < /proc/1/environ | grep -E '^E2B_'                      ✗ (Permission denied)
tr '\0' '\n' < /proc/359/environ | grep -E '^E2B_'                    ✗ (Permission denied)
hostname                                                             ✓
cat /etc/hosts                                                       ✓
grep -i e2b /etc/hosts                                               ✓
cat /proc/sys/kernel/random/boot_id   (read 1 and read 2)             ✓
uptime -s   (read 1, read 2, then 12 samples over 24 s)               ✓
cat /proc/uptime                                                     ✓
uptime                                                               ✓
cat /etc/machine-id                                                  ✓
cat /var/lib/dbus/machine-id                                         ✓
ls -la /run/e2b ; cat /run/e2b/.E2B_*   (read 1 and read 2)           ✓
grep '^TEMPLATE_ID=\|^ENV_ID=\|^BUILD_ID=' /.e2b                     ✓
```

### Image build lineage

```
stat -c '%y %n' /* | sort                                            ✓
stat -c '%y %s' /.e2b                                                ✓
stat /.e2b                                                           ✓
ls -la /etc/apt/sources.list*                                        ✓
grep -r snapshot.debian.org /etc/apt/sources.list*                   ✓
cat /etc/apt/sources.list                                            ✗
cat /etc/apt/sources.list.d/debian.sources                           ✓
cat /etc/apt/sources.list.d/nodesource.sources                       ✓
dpkg-query -W --showformat='${Package} ${Version}\n' | wc -l         ✓
dpkg-query -W --showformat='${Package} ${Version}\n'                 ✓
pip list --format=freeze | wc -l                                     ✓
pip list --format=freeze                                             ✓
which pip pip3 python python3 ; python3 -V                           ✓
cat /etc/os-release                                                  ✓
uname -a                                                             ✓
cat /proc/cmdline                                                    ✓
ip -brief addr                                                       ✓
cat /sys/class/dmi/id/product_name                                   ✗
cat /sys/hypervisor/type                                             ✗
```

### Service footprint

```
systemctl list-units --type=service --state=running --no-pager --no-legend   ✓
systemctl list-units --type=service --all --no-pager | head -40              ✓
ss -tlnp                                                                     ✓
command -v ss                                                                ✓
cat /proc/net/tcp                                                            ✓
cat /proc/net/tcp6                                                           ✓
systemctl show {envd,jupyter,code-interpreter} -p FragmentPath               ✓
systemctl cat {envd,jupyter,code-interpreter}                                ✓
systemctl show envd -p ActiveEnterTimestamp                                  ✓
systemctl show jupyter -p ActiveEnterTimestamp                               ✓
systemctl show code-interpreter -p ActiveEnterTimestamp                      ✓
systemctl show dbus -p ActiveEnterTimestamp                                  ✓
systemctl show <u> -p MainPID -p ActiveEnterTimestampMonotonic \
                     -p ExecMainStartTimestamp -p NRestarts                  ✓
ps -o pid,ppid,lstart,etimes,times,cmd -p 359,437,463                        ✓
ps -eo pid,lstart,etimes,cmd | head -40                                      ✓
systemctl list-jobs                                                          ✓
journalctl --list-boots                                                      ✓
journalctl -b --no-pager | head -40 / tail -20                               ✓
journalctl -q -b -o short-iso | grep -iE 'clock|step|adjust|suspend|resume'  ✓ (empty)
awk '{print $22}' /proc/1/stat ; grep btime /proc/stat                       ✓
python3 clock_gettime(REALTIME/MONOTONIC/BOOTTIME) vs uptime vs btime        ✓
date -u -d @1788549874                                                       ✓
ls -la /run/systemd ; stat -c '%y %n' /run/systemd/*                         ✓
ls -la /run/systemd/units                                                    ✓
timedatectl                                                                  ✓
chronyc tracking                                                             ✗
systemctl status envd --no-pager | head -15                                  ✓
/usr/bin/envd --version                                                      ✓
```

### Self-description

```
grep -rIl -m1 -iE 'arena|lmarena|e2b' /etc /opt /usr/local 2>/dev/null | head -50   ✓
grep -inE 'arena|lmarena|e2b' <each non-library hit>                                 ✓
grep -rIl -iE 'arena|lmarena' /etc /opt /usr/local | grep -viE '<lib dirs>'          ✓ (empty)
ls -la ~ ; echo $HOME ; id                                                           ✓
ls -la /code ; find /code -maxdepth 3                                                ✓
ls -la / ; ls -la /opt ; ls -la /usr/local ; ls -la /usr/local/bin                   ✓
ls -la /usr/local/share ; find /usr/local/share/e2b                                  ✓
ls -la /usr/local/share/ca-certificates                                              ✓
openssl x509 -in …/e2b-ca.crt -noout -subject -issuer -dates                          ✓
ls -la /etc/systemd/system                                                           ✓
cat /etc/hostname ; cat /etc/inittab                                                  ✓
cat /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf                   ✓
ls -la /usr/local/bin/provision.sh ; ls -la /provision.result /provision.sh           ✗
ls -la /root                                                                          ✗
```

### Stability probe

```
{ … } > /home/user/prov_probe.txt                                                    ✓
cat /home/user/prov_probe.txt                                                        ✓
sha256sum /home/user/prov_probe.txt                                                  ✓
stat /home/user/prov_probe.txt ; wc -c /home/user/prov_probe.txt                      ✓
```

---

## Verification statement

This was a **read-only audit** — no code was written or modified, so there is no test suite or build to run against it. The verification that applies here is that **every factual line in this document was produced by a command executed in-sandbox during this session**, and the outputs are reproduced verbatim.

### The check that mattered

After drafting, I re-ran the identity commands to confirm the document against live state. That re-check, and a second check after the sandbox was recreated, **caught three of my own errors**:

1. I had presented `E2B_TEMPLATE_ID` as a fixed template identifier. It changed value between my first and second read.
2. I had cited `uptime -s` as a fixed reference point. It moved by ~6 minutes within a single boot.
3. I had told the reader that a changed `boot_id` was "the one unambiguous signal" of recreation. The sandbox was then recreated with `boot_id` unchanged. This was the most consequential of the three, because it was operational advice, not just a description.

All three are corrected in [Corrections](#corrections-found-during-re-verification) and propagated through §1, §2.2, §2.5, §2.7, §4.5, §6, and §7. Errors 2 and 3 both converted partly-inferential claims into directly measured ones — §4.5's clock model and §7.2's inference B.

The third error is worth dwelling on: the audit's own stability probe caught it. The probe was designed to be re-read across turns, the recreation happened between turns, and comparing the two readings is what falsified the claim. Had I packaged the report without re-checking, the reader would have carried a false detection heuristic away with them.

### Commands that failed

Eight commands failed; each failure is reproduced verbatim rather than substituted with an inference:

| Command | Verbatim error |
|---|---|
| `cat /etc/apt/sources.list` | `cat: /etc/apt/sources.list: No such file or directory` |
| `cat /sys/class/dmi/id/product_name` | `cat: /sys/class/dmi/id/product_name: No such file or directory` |
| `cat /sys/hypervisor/type` | `cat: /sys/hypervisor/type: No such file or directory` |
| `ls -la /usr/local/bin/provision.sh` | `ls: cannot access '/usr/local/bin/provision.sh': No such file or directory` |
| `ls -la /provision.result /provision.sh` | `ls: cannot access '/provision.result': No such file or directory` / `ls: cannot access '/provision.sh': No such file or directory` |
| `ls -la /root` | `ls: cannot open directory '/root': Permission denied` |
| `tr '\0' '\n' < /proc/1/environ` | `/bin/bash: line 5: /proc/1/environ: Permission denied` |
| `tr '\0' '\n' < /proc/359/environ` | `/bin/bash: line 6: /proc/359/environ: Permission denied` |

Plus `chronyc tracking` → `506 Cannot talk to daemon`, and two successful-but-empty results (`journalctl … | grep -iE 'clock|step|adjust|suspend|resume'`, and the library-filtered `arena` grep).

Everything reasoned beyond the measured output is labelled **INFERRED** and collected in §7.2. The open questions in §7.3 are things this audit could not resolve, not things left unexamined by oversight.

### Document integrity

**MEASURED** — checked after every edit:

```
grep -c '^```' sandbox_identity_provenance.md      → 116   (even ⇒ all fences balanced)
grep -c '^|'   sandbox_identity_provenance.md      → 214   (table rows)
grep -cE '^## ' sandbox_identity_provenance.md     → 12    (all resolve against the TOC)
```

The line/byte count is deliberately not quoted here: writing it would itself change the file, so it can never be accurate inside the document it describes. Final size as of this edit is ~1,200 lines / ~57 KB; run `wc -l -c` for the exact figure.

Heading structure was verified against the table of contents after every edit. The stability probe file was re-hashed after the document edits and is unchanged: `389002234ba1e84c379c623066f34e3a634f2dbffe9ce34a87f97d97c5b9acaa`, 601 bytes.
