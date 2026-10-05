# PersistenceCheckPROMPT — round 4 (2026-09-24)

**Purpose:** measure cross-turn `/home/user` persistence and session resumability at the
20-day boundary, inside the original round-1 sessions (opened 2026-09-04), without mutating
anything.

**Standing constraints:** READ-ONLY — run only the commands below; create, edit and delete
nothing; no installs. Report values verbatim.

**Executed:** 2026-09-24 in all three round-1 sessions (brave `01a06bd5-f0aa-7dcc-9fcc-03ab65718e14`,
chrome `01a06be4-48f4-7667-bc59-adea71991e3a`, edge `01a06c52-f3ee-77f7-839b-7616d291dd28`).
Results: `forensic/reports/persistence/PERSISTENCE_20DAY_20260924.md`.
This file is the canonical recompiled text; the executed pastes differed only in the
per-browser Sep-4 sandbox-id list in step 3.

```text
1) Identity and uptime of this sandbox, verbatim:
   printenv E2B_SANDBOX_ID E2B_TEMPLATE_ID ENV_ID
   cat /proc/sys/kernel/random/boot_id
   uptime -p && cat /proc/uptime

2) Workspace census, verbatim:
   ls -la /home/user

3) From your own records, no commands needed:
   - Is the current E2B_SANDBOX_ID one of the sandbox ids you recorded on Sep 4
     (<per-browser list>)?
   - Is any file you intentionally wrote on Sep 4 missing from the listing in step 2?
```

Sep-4 sandbox ids per browser (as corrected by the agents from their own records):

- brave: `i0v44lh3n78xffvhm6u5u`, `i4i7wdij5c7gh9absvtu8`, `i54yseeebo34z5jxzvoju`
- chrome: `i0m9mhony51frr3osghn0`
- edge: `ixwcucmrk55t9qy240sxo`

## Reading table (filled in by the operator after the paste)

| Observation | Regime (a): same VM resumed | Regime (b): fresh VM + snapshot remount |
|---|---|---|
| E2B_SANDBOX_ID | unchanged | new |
| uptime | ~20 days | seconds |
| /home/user mtimes | original Sep-4 stamps | one restore stamp, today |
| file hashes vs Sep-4 manifests | identical | identical (if (b), this proves snapshot persistence) |
| excluded paths | present | absent |

Expected exclusions under (b): `/tmp`, `/dev/shm`, `~/.cache`, `~/.npm`, `~/.local`, `~/.config`.
Observed outcome (all three browsers): regime (b) — see the report.
