# Round 2 identity comparison (`boot_id`, `template_id`, `sandbox_id`)

**Compiled:** 2026-09-05 UTC  
**Sources:** already-copied evidence under `forensic/evidence/{provenance,ceilings,egress}/` and round-1 `forensic_reports/04_ID_COMPARISON.txt`.  
**No zip was re-opened or executed for this file.** Values are quoted from reports that already passed light verification.

Account mapping used throughout: **chrome = account_a**, **edge = account_b**, **brave = account_c**.

## 1. Round-2 Provenance (IDs actually present)

| Account | Browser | `boot_id` | `E2B_SANDBOX_ID` | `E2B_TEMPLATE_ID` / `/.e2b TEMPLATE_ID` | Notes |
|---|---|---|---|---|---|
| account_a | chrome (Provenance 3) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `i9aekzbsq1tymcft2o0e1` | `nlhz8vlwyupq845jsdg9` | From `prov_probe.txt` |
| account_b | edge (Provenance 1) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `ia4a7jw0xcyn756c09iwm` → **`i5ppm7iw8cfa89mb7ezsm`** after 20:37 UTC recreation | `nlhz8vlwyupq845jsdg9` → transient `wk9vh0w7zre9vbcia51p` at ~19:39 → reverted to `nlhz8…` on recreation | `boot_id` **unchanged** across recreation |
| account_c | brave (Provenance 2) | `2bb79165-136a-4b63-829d-17027b0a8e40` | `ibbwxrhn0lpoi9ybz9fru` | `nlhz8vlwyupq845jsdg9` | From `prov_probe.txt` |

### What differs vs what does not

- **`boot_id` is identical** across all three provenance accounts, and survived a measured sandbox recreation on account_b. It is **not** an instance identifier and **cannot** map onto account_a/b/c.
- **Build/template id `nlhz8vlwyupq845jsdg9` is shared** (also matches round-1 agents). A second value `wk9vh0w7zre9vbcia51p` appeared only as a mid-session env injection on account_b and reverted.
- **`E2B_SANDBOX_ID` is the discriminator.** Three distinct IDs for the three browsers, plus a fourth ID after account_b was recreated. Together with a `/proc/uptime` reset it was the recreation signal (account_b report, Correction 3).

## 2. Round-2 Ceilings and Egress

Read-only grep of `forensic/evidence/ceilings/**` and `forensic/evidence/egress/**` (`*.md`, `*.txt`, `*.json`, `*.log`) found **no** `E2B_SANDBOX_ID`, `E2B_TEMPLATE_ID`, or `boot_id` claims.

Those families characterise resource ceilings and network egress. Identity was not recorded in the packaged reports. Account assignment for those zips is therefore **filename-browser based** (chrome/edge/brave), as documented in `00_ROOT_INVENTORY.txt`.

## 3. Round-1 environment agents (for cross-round context)

From `forensic_reports/04_ID_COMPARISON.txt` (already verified in PR #2):

| Agent | Browser | Sandbox IDs (as recorded) | Template IDs | Boot IDs |
|---|---|---|---|---|
| 1 | chrome | `iim386kr3aoo4j3svsogz`, `ijwc38wq18p7cu57ydxvn` | `nlhz8vlwyupq845jsdg9` | (none found) |
| 2 | brave | `i0v44lh3n78xffvhm6u5u`, `i4i7wdij5c7gh9absvtu8`, `i54yseeebo34z5jxzvoju` | `nlhz8vlwyupq845jsdg9` | `2bb79165136a4b63829d17027b0a8e40` |
| 3 | brave | `iptxurfwauu23eb0ooerk`, `iq0hfwsxhi5bhzqv4auur` | `nlhz8vlwyupq845jsdg9` | (none found) |
| 4 | chrome | `i0m9mhony51frr3osghn0`, `im7pcmogyi4h8g6mpiqba` | `gujonb0q163l15z30yc7`, `nlhz8vlwyupq845jsdg9` | (none found) |
| 5 | chrome | `i80n46q8w7lm0xch991wu`, `iyl5sbten1irtm0cfue4p` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 6 | brave | `i9nxb4qydn3qmwway6hd3`, `idxwgcmp6a9ioo1823yuk` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 7 | edge | `i07vrt7m23evfzhmemmqh`, `ilvohmgrk3rcbvrgm79be` | `nlhz8vlwyupq845jsdg9` | `2bb79165-136a-4b63-829d-17027b0a8e40` |
| 8 | edge | `i87c7gwotry240rbx1u77`, `iitws4rrop6j50j2hed7r` | `nlhz8vlwyupq845jsdg9` | `2bb79165136a4b63829d17027b0a8e40` |
| 9 | edge | `ixwcucmrk55t9qy240sxo` | `nlhz8vlwyupq845jsdg9` | (none found) |

Same picture as round 2: **template and boot_id are shared (or hyphenation variants of the same UUID)**; **sandbox IDs are per-session and do not collapse onto three accounts**. Agent 4 additionally recorded template `gujonb0q163l15z30yc7`.

Round-1 Agent zips remain at `zips/Agent {1..9} *.zip` (not folded into `account_{a,b,c}`). Extracted trees remain at `forensic/evidence/Agent {1..9} *`.

## 4. code_arena characterization zips

Light verification (`unzip -l`/`-t` only) shows Next.js app skeletons. Identity fields were **not extracted** from those zips in this reorg (no payload unpack, no execution). They are placed by browser token: chrome→account_a, edge→account_b, brave→account_c.

The older tree `code_arena_extract_20260905_074645/` is Agent 1–9 environment content, not this family.

## 5. Practical mapping rule (locked)

| Want | Use |
|---|---|
| Which *account* / browser | Filename browser token (`chrome`/`edge`/`brave`) |
| Which *sandbox instance* | `E2B_SANDBOX_ID` (changes on recreation) |
| Which *image / template* | `/.e2b TEMPLATE_ID` ≈ `nlhz8vlwyupq845jsdg9` (do **not** trust session `E2B_TEMPLATE_ID` alone) |
| Fresh boot vs restore | **Not** `boot_id`. Use `E2B_SANDBOX_ID` change **and** `/proc/uptime` reset together |
