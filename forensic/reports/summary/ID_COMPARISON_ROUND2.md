# Round 2 identity comparison (`boot_id`, `template_id`, `sandbox_id`)

**Compiled:** 2026-09-05 UTC (regenerated in burst 16 for the **final** mapping)  
**Mapping:** chrome = `account_a` / acct1 / runs 1,4,5; brave = `account_b` / acct2 / runs 2,3,6; edge = `account_c` / acct3 / runs 7,8,9.  
Browser string in filenames is ground truth; `account_*` labels are aliases (`ACCOUNTS.md`).  
**Sources:** copied evidence under `forensic/evidence/{provenance,ceilings,egress,environment}/` and `forensic/reports/round1_environment/04_ID_COMPARISON.txt`.  
No zip was executed for this file. Burst 11’s swapped brave/edge labels are superseded.

## 1. Round-2 Provenance (IDs actually present)

| Account | Browser | `boot_id` | `E2B_SANDBOX_ID` | `TEMPLATE_ID` (`/.e2b`) | Notes |
|---|---|---|---|---|---|
| account_a | chrome (Provenance 3) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `i9aekzbsq1tymcft2o0e1` | `nlhz8vlwyupq845jsdg9` | `prov_probe.txt` |
| account_b | brave (Provenance 2) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `ibbwxrhn0lpoi9ybz9fru` | `nlhz8vlwyupq845jsdg9` | `prov_probe.txt` |
| account_c | edge (Provenance 1) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `ia4a7jw0xcyn756c09iwm` → **`i5ppm7iw8cfa89mb7ezsm`** after 20:37 UTC recreation | `nlhz8vlwyupq845jsdg9` (transient env `wk9vh0w7zre9vbcia51p` ~19:39, then reverted) | `boot_id` **unchanged** across recreation |

### What differs vs what does not

- **`boot_id` is identical** across all three provenance accounts and survived a measured sandbox recreation on account_c (edge). It is **not** an instance identifier.
- **Build/template id `nlhz8vlwyupq845jsdg9` is shared** (also matches followup environment agents).
- **`E2B_SANDBOX_ID` is the discriminator.** Distinct per browser; a fourth ID appears after account_c was recreated. Together with a `/proc/uptime` reset it was the recreation signal.

## 2. Round-2 Ceilings and Egress

Read-only grep of `forensic/evidence/ceilings/**` and `forensic/evidence/egress/**` found **no** `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, or `boot_id` claims. Account assignment is filename-browser based.

## 3. Followup environment agents (round 1)

From `forensic/reports/round1_environment/04_ID_COMPARISON.txt`:

| Agent | Account | Browser | Sandbox IDs | Template IDs | Boot IDs |
|---|---|---|---|---|---|
| 1 | account_a | chrome | `iim386kr3aoo4j3svsogz`, `ijwc38wq18p7cu57ydxvn` | `nlhz8vlwyupq845jsdg9` | (none found) |
| 4 | account_a | chrome | `i0m9mhony51frr3osghn0`, `im7pcmogyi4h8g6mpiqba` | `gujonb0q163l15z30yc7`, `nlhz8vlwyupq845jsdg9` | (none found) |
| 5 | account_a | chrome | `i80n46q8w7lm0xch991wu`, `iyl5sbten1irtm0cfue4p` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 2 | account_b | brave | `i0v44lh3n78xffvhm6u5u`, `i4i7wdij5c7gh9absvtu8`, `i54yseeebo34z5jxzvoju` | `nlhz8vlwyupq845jsdg9` | `2bb79165136a4b63829d17027b0a8e40` |
| 3 | account_b | brave | `iptxurfwauu23eb0ooerk`, `iq0hfwsxhi5bhzqv4auur` | `nlhz8vlwyupq845jsdg9` | (none found) |
| 6 | account_b | brave | `i9nxb4qydn3qmwway6hd3`, `idxwgcmp6a9ioo1823yuk` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 7 | account_c | edge | `i07vrt7m23evfzhmemmqh`, `ilvohmgrk3rcbvrgm79be` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 8 | account_c | edge | `i87c7gwotry240rbx1u77`, `iitws4rrop6j50j2hed7r` | `nlhz8vlwyupq845jsdg9` | `2bb79165136a4b63829d17027b0a8e40` |
| 9 | account_c | edge | `ixwcucmrk55t9qy240sxo` | `nlhz8vlwyupq845jsdg9` | (none found) |

Template and `boot_id` (when present) are shared; sandbox IDs are per-session. Agent 4 additionally recorded template `gujonb0q163l15z30yc7`.

## 4. code_arena characterization zips

Extracted (burst 15) Next.js skeletons. No measured sandbox/template/boot IDs in the packaged reports. Placed by browser token.

## 5. `vm_class`

No report in this archive stamps a `T` / `B` / `C` / `NEW` class letter. Guests that do publish OS/kernel lines report Debian 13 (trixie), Linux 6.1.158+, Python 3.13, Firecracker microVM. `INDEX_ALL.tsv` `vm_class` column is therefore **blank** (not invented).

## 6. Practical mapping rule (locked)

| Want | Use |
|---|---|
| Which *account* / browser | Filename browser token (`chrome`/`brave`/`edge`) |
| Which *sandbox instance* | `E2B_SANDBOX_ID` (changes on recreation) |
| Which *image / template* | `/.e2b TEMPLATE_ID` ≈ `nlhz8vlwyupq845jsdg9` (do **not** trust session `E2B_TEMPLATE_ID` alone) |
| Fresh boot vs restore | **Not** `boot_id`. Use `E2B_SANDBOX_ID` change **and** `/proc/uptime` reset together |
