# Provenance 1 — edge

Sandbox identity and provenance audit, packaged 2026-09-04.

## Contents

| File | What it is |
|---|---|
| `sandbox_identity_provenance.md` | **The report.** 12 sections, every line labelled MEASURED or INFERRED, exact commands, verbatim output. Start here. |
| `prov_probe.txt` | Stability probe, written 19:30:28 UTC. Snapshot of boot_id, sandbox/template IDs, uptime and clock state at one instant. Left unmodified on purpose — one value in it is already stale, which is the point. |
| `raw_evidence_2026-09-04T2037Z_instance2.txt` | Primary evidence: 76 commands re-run and logged verbatim on the **second** instance. Unfiltered, including failures. |
| `raw_capture.sh` | The script that produced the above. Re-runnable: `bash raw_capture.sh > out.txt` |
| `README.md` | This file. |

## Read this first: three corrections

The report was re-checked against live state after drafting, and again after the sandbox was recreated mid-audit. **Three claims in the original draft were wrong.** They are corrected in the report and listed in its "Corrections found during re-verification" section. Summarised:

| # | Original claim | Reality |
|---|---|---|
| 1 | `E2B_TEMPLATE_ID` is a fixed template identifier | Changed value mid-session (`nlhz8…` → `wk9vh…`), then reverted on recreation |
| 2 | `uptime -s` is a fixed boot reference | Moved ~6 minutes within a single boot; it is `CLOCK_REALTIME − uptime`, recomputed live |
| 3 | A changed `boot_id` is the unambiguous signal of sandbox recreation | **Falsified.** The sandbox was recreated and `boot_id` did not change |

Correction 3 is the important one. It was operational advice, not description, and it was wrong. The audit's own stability probe caught it.

## Headline findings

- **E2B sandbox.** Build-time template `nlhz8vlwyupq845jsdg9`, build `f34a5416-ef30-4cb7-8e18-0fdecd6eb529`, envd `0.6.10`.
- **Debian 13 (trixie) 13.6** on a custom microVM kernel `6.1.158+`; apt pinned to snapshot `20260713T000000Z`.
- **650** dpkg packages, **180** pip packages, two distinct Python installs.
- **Nothing on the filesystem identifies this as Arena/LMArena.** Zero non-library matches across `/etc`, `/opt`, `/usr/local`. Every `arena` hit is CPython's memory-arena allocator or R docs.
- **No service predates the current boot** — monotonic offsets 0.70 / 2.53 / 4.44 s, `NRestarts=0`, one journal boot.
- **The wall clock is not self-consistent.** Services stamped 2026-07-23; `date -u` is 2026-09-04. Cause: the guest is restored from a frozen snapshot taken at template-build time, with the clock stepped forward afterwards.

## The recreation event (20:37 UTC)

The sandbox was replaced between turns. Measured before/after:

| Indicator | Before | After | Verdict |
|---|---|---|---|
| `E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` | `i5ppm7iw8cfa89mb7ezsm` | **CHANGED** |
| `/proc/uptime[0]` | ~861 s | ~52 s | **RESET** |
| PID 1 start | `19:24:34` | `20:37:09` | **RESTARTED** |
| `boot_id` | `2bb79165-…-17027b0a8e40` | `2bb79165-…-17027b0a8e40` | **UNCHANGED** |
| systemd MainPIDs | 359 / 437 / 463 | 359 / 437 / 463 | unchanged |
| `/.e2b` | `2026-07-23 18:05:37.836974292` | identical | unchanged |
| `prov_probe.txt` sha256 | `389002234b…` | `389002234b…` | **content preserved** |
| workspace file timestamps | `19:30` / `19:45` | both `20:37:20` | **reset** |

Two practical takeaways:

1. **`E2B_SANDBOX_ID` is the reliable instance identifier**, together with a `/proc/uptime` reset. `boot_id` is not — it survives recreation.
2. **Workspace content survives recreation; file timestamps do not.** Content is restored intact; birth and mtime are both reset to the restore instant.

## Verifying this archive

```
sha256sum *
```

Expected at packaging time:

```
389002234ba1e84c379c623066f34e3a634f2dbffe9ce34a87f97d97c5b9acaa  prov_probe.txt
```

The other hashes are recorded in `MANIFEST.sha256`.

## Known limits

Everything the audit could not resolve is listed in §7.3 of the report — socket-to-process attribution (blank at uid 1000), `/root` contents (permission denied), the exact instants of the clock steps, and the semantics of `E2B_TEMPLATE_ID`. Eight commands failed outright; every failure is reproduced verbatim in both the report and the raw capture rather than substituted with a guess.

This was a **read-only** audit. No system state was modified beyond writing these files into `/home/user`.
