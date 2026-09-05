# Burst 10 — code_arena zip light verification

**When:** 2026-09-05 09:05 UTC  
**Method:** outer SHA-256, `unzip -l`, `unzip -t`, `zipfile` metadata scan.  
**Not done:** payload extraction, execution of any script/binary inside the archives.  
**Work dir:** `code_arena_extract_20260905_090530/` (logs only).  
**Account mapping:** chrome = `account_a`, edge = `account_b`, brave = `account_c`.

## Scope note

`code_arena_extract_20260905_074645/` is the round-2 unpack of **Agent 1–9 environment** zips. Those trees already live under `forensic/evidence/Agent {1..9} *` from round 1. They are **environment** evidence, not this characterization family, and were **not** copied into `forensic/evidence/code_arena/`.

This burst verifies only the three round-2 code-arena characterization zips moved in burst 4.

## Results

| Zip | Bytes | SHA-256 vs burst-0 | unzip -t | Integrity issues | Uncompressed | File entries | Verdict |
|---|---:|---|---|---|---:|---:|---|
| `zips/code_arena/account_b/code-arena-sandbox-characterization 1 edge.zip` | 52550 | `b7272928…fb685e21` YES | OK | none | 49890 | 16 | **PASS** |
| `zips/code_arena/account_c/characterize-code-arena-environment 2 brave.zip` | 25451 | `90691ee3…bef1acf` YES | OK | none | 23273 | 14 | **PASS** |
| `zips/code_arena/account_a/characterize-code-arena-environment 3 chrome.zip` | 25532 | `c9b00727…3c6c68a` YES | OK | none | 23152 | 15 | **PASS** |

Contents are Next.js / drizzle app skeletons (e.g. `src/app/page.tsx`, `package.json`, `.persistence-marker`). No nested zips, no `../`, no absolute paths, no symlinks. Total uncompressed well under 50 MB.

**Quarantine:** none.

Full transcripts: `00_INVENTORY.txt` in this directory.
