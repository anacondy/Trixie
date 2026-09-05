# Burst 9 — Egress and Provenance zip light verification

**When:** 2026-09-05 09:04 UTC  
**Method:** outer SHA-256, `unzip -l`, `unzip -t`, `zipfile` metadata scan.  
**Not done:** payload extraction, execution of any script/binary inside the archives.  
**Work dirs:** `egress_extract_20260905_090400/`, `provenance_extract_20260905_090400/` (logs only).  
**Account mapping:** chrome = `account_a`, edge = `account_b`, brave = `account_c`.

## Egress

| Zip | Bytes | SHA-256 vs burst-0 | unzip -t | Integrity issues | Uncompressed | Verdict |
|---|---:|---|---|---|---:|---|
| `zips/egress/account_a/Egress 1 chrome.zip` | 22380 | `3c1a7f82…fab50f7` YES | OK | none | 53312 | **PASS** |
| `zips/egress/account_c/Egress 2 brave.zip` | 23093 | `72a2990c…5eb2a82` YES | OK | none | 53873 | **PASS** |
| `zips/egress/account_b/Egress 3 edge.zip` | 55619 | `1ce470c3…87182a9` YES | OK | none | 172809 | **PASS** |

## Provenance

| Zip | Bytes | SHA-256 vs burst-0 | unzip -t | Integrity issues | Uncompressed | Verdict |
|---|---:|---|---|---|---:|---|
| `zips/provenance/account_b/Provenance 1 edge.zip` | 39165 | `9f671397…bf0c250` YES | OK | none | 123025 | **PASS** |
| `zips/provenance/account_c/Provenance 2 brave.zip` | 8071 | `df0f9fa7…d87aed6` YES | OK | none | 23281 | **PASS** |
| `zips/provenance/account_a/Provenance 3 chrome.zip` | 5743 | `32775e06…ae8e1f1` YES | OK | none | 16437 | **PASS** |

Fail thresholds: path `../`, absolute entry, unexpected symlink, nested zip uncompressed > 10 MB, total uncompressed > 50 MB, CRC error, outer-hash drift.

**Quarantine:** none. All six PASS.

Full transcripts: `00_INVENTORY_EGRESS_PROVENANCE.txt`.
