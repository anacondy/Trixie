# Burst 8 — Ceilings zip light verification

**When:** 2026-09-05 09:03:18 UTC  
**Method:** outer SHA-256, `unzip -l`, `unzip -t`, `zipfile` metadata scan.  
**Not done:** payload extraction, execution of any `.py` / `.sh` / `.c` / binary inside the archives.  
**Work dir:** `ceilings_extract_20260905_090246/` (listing/CRC logs only).  
**Account mapping:** chrome = `account_a`, edge = `account_b`, brave = `account_c`.

## Results

| Zip (after burst 1 placement) | Bytes | SHA-256 (matches burst-0 inventory) | unzip -t | Traversal / abs / symlink / nested | Uncompressed | Verdict |
|---|---:|---|---|---|---:|---|
| `zips/ceilings/account_a/Ceilings 1 chrome.zip` | 19730 | `83faeeda…b1a3b6` YES | OK | none | 38678 | **PASS** |
| `zips/ceilings/account_b/Ceilings 2 edge.zip` | 8756 | `484e0d1b…03ffa5` YES | OK | none | 19824 | **PASS** |
| `zips/ceilings/account_c/Ceilings 3 brave.zip` | 18542 | `16013673…2231f0` YES | OK | none | 35830 | **PASS** |

Fail thresholds (any one → stop + quarantine): path `../`, absolute entry, unexpected symlink, nested zip uncompressed > 10 MB, total uncompressed > 50 MB, CRC error, outer-hash drift.

**Quarantine:** none.

Full `unzip -l` / `-t` transcripts: `00_INVENTORY.txt` in this directory.

Scripts observed inside chrome/brave archives (`ceiling/scripts/*`, `probes/*.py|*.sh|*.c`) were **not executed**.
