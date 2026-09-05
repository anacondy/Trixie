# Forensic Unpack Report – Trixie Agent Zips

Generated: Fri Sep  4 18:06:24 UTC 2026

Extraction directory: `trixie_extract_20260904_172945`

## 1. Execution Environment Snapshot (Phase 0)

```
=== PHASE 0 – Environment lock ===
date -u:
Fri Sep  4 17:29:45 UTC 2026

uname -a:
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Mon May 11 18:48:24 UTC 2026 x86_64 GNU/Linux

whoami:
user

pwd:
/home/user/Trixie

df -h .:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        21G  816M   20G   4% /

free -h:
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       227Mi       3.7Gi       1.0Mi       113Mi       3.6Gi
Swap:             0B          0B          0B

id:
uid=1001(user) gid=1001(user) groups=1001(user),27(sudo),100(users)

=== Tool availability ===
zip: /usr/bin/zip
Copyright (c) 1990-2008 Info-ZIP - Type 'zip "-L"' for software license.
unzip: /usr/bin/unzip
caution:  both -n and -o specified; ignoring -o
sha256sum: /usr/bin/sha256sum
sha256sum (GNU coreutils) 9.1
find: /usr/bin/find
find (GNU findutils) 4.9.0
file: MISSING
python3: /usr/bin/python3
Python 3.11.2

```

Tool availability note: `file` command was MISSING in this sandbox. Used python fallback for type detection. All other tools (zip, unzip, sha256sum, find, python3) were available.

## 2. Per-Zip Table

| Filename | Size (bytes) | Outer SHA-256 | Entry Count | Uncompressed | Internal SHA Check | Exec/Script Count | Extraction Status |
|---|---|---|---|---|---|---|---|
| Agent 1 chrome.zip | 10863 | 52880dad6738d951ad51a255347297ea54905b282e1456f70ef97e576266dee7 | 10 | 20077 | 4 PASS, 0 FAIL (OK) | 1 | EXTRACTED OK |
| Agent 2 brave.zip | 78729 | 55302d915b3c07b1f11bed29738c458ae78e349a417b9dae22281c2cd6d444fa | 29 | 253558 | 5 PASS, 0 FAIL (OK) | 3 | EXTRACTED OK |
| Agent 3 brave.zip | 47044 | 066b4eb2764eea3f7543ad575a637f3c8d83e7d742ab81385d2fc17c09e8e62d | 27 | 106674 | 5 PASS, 0 FAIL (OK) | 2 | EXTRACTED OK |
| Agent 4 chrome.zip | 282299 | 0f01d761ded3ddf9ec755bc7ce289029e093e172748f72a179e7054da769662b | 151 | 742557 | 4 PASS, 0 FAIL (OK) | 15 | EXTRACTED OK |
| Agent 5 chrome.zip | 119842 | cfd0179b38fe6e6edce5b56205a38a3b5d6660b6f3fa88b46e54530fda151466 | 56 | 293407 | 6 PASS, 0 FAIL (OK) | 4 | EXTRACTED OK |
| Agent 6 brave.zip | 153569 | dea4ec47ac81a2e65606778aa4da6895cbce03094d2f47845d4b8fc25e7e53d0 | 94 | 353977 | 6 PASS, 0 FAIL (OK) | 2 | EXTRACTED OK |
| Agent 7 edge.zip | 130614 | 5c0f02b35a2f43c633a92e16fed9daa5bf77cd018bfed8fdb084734aa4eac13c | 88 | 300759 | 4 PASS, 0 FAIL (OK) | 3 | EXTRACTED OK |
| Agent 8 edge.zip | 30820 | 7fe13f8118d625420a55a2ea14a66b61715acc4be9bf7249666ba2193841c898 | 17 | 75027 | 2 PASS, 0 FAIL (OK) | 1 | EXTRACTED OK |
| Agent 9 edge.zip | 247182 | 2007bbee89d81a92d4b3fecdf5c06c6f7ba2f53f86c599dbfc18da4c2e3e10a2 | 92 | 675295 | 2 PASS, 0 FAIL (OK) | 10 | EXTRACTED OK |

## 3. Integrity Failures or Anomalies

- **No path traversal or absolute paths detected** in any zip listing (checked via `unzip -l` grep for `../` or `:/`).
- **No symlinks** found in any extracted tree (verified via `find -type l`).
- **No nested zips >50MB**: Largest extracted tree is ~727KB (Agent 9 edge), well below 50MB threshold. One nested zip exists inside Agent 9 edge (`environment_evidence_20260904T142002Z-2576.zip`, 61KB) – size OK, not quarantined.
- **Outer SHA-256 matches** for all zips with published claims: Agent 2,3,4,5,6,7,8 all MATCH. Agent 1 and 9 had no published claim – computed SHA recorded.
- **Internal SHA checks**: All internal SHA256SUMS that could be resolved showed PASS (0 FAIL). Agent 9 documentation/SHA256SUMS had 82 MISSING/UNRESOLVED because it references files outside the payload directory structure – not a failure, but partial verification. No bold failures.
- **Executable/script presence**: All zips contain .sh/.py probe scripts by design (expected for environment characterization). These were NOT executed (per safety rule). Flagged but not quarantined.
- **file command missing**: Noted as anomaly in Phase 0, but not blocking.

No zip was quarantined – all passed integrity and structure checks.

## 4. Side-by-Side Comparison of Claimed vs Observed IDs and Timestamps

```
=== Sandbox/Template/Boot ID Comparison ===

--- Agent 1 chrome ---
Sandbox IDs found (2): iim386kr3aoo4j3svsogz, ijwc38wq18p7cu57ydxvn
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (0): 
Timestamps found (1): 2026-09-04T13:44:06Z

--- Agent 2 brave ---
Sandbox IDs found (3): i0v44lh3n78xffvhm6u5u, i4i7wdij5c7gh9absvtu8, i54yseeebo34z5jxzvoju
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (1): 2bb79165136a4b63829d17027b0a8e40
Timestamps found (222): 2026-09-04T09:59:50Z, 2026-09-04T13:45:05Z, 2026-09-04T13:45:06Z, 2026-09-04T13:45:07Z, 2026-09-04T13:45:09Z, 2026-09-04T13:45:10Z, 2026-09-04T13:45:11Z, 2026-09-04T13:45:12Z, 2026-09-04T13:45:21Z, 2026-09-04T13:45:22Z

--- Agent 3 brave ---
Sandbox IDs found (2): iptxurfwauu23eb0ooerk, iq0hfwsxhi5bhzqv4auur
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (0): 
Timestamps found (22): 2026-09-04T10:14:40Z, 2026-09-04T13:46:52Z, 2026-09-04T13:46:59Z, 2026-09-04T13:47:00Z, 2026-09-04T13:47:06Z, 2026-09-04T13:47:13Z, 2026-09-04T13:47:17Z, 2026-09-04T13:47:20Z, 2026-09-04T13:47:27Z, 2026-09-04T13:47:29Z

--- Agent 4 chrome ---
Sandbox IDs found (2): i0m9mhony51frr3osghn0, im7pcmogyi4h8g6mpiqba
Template IDs found (2): gujonb0q163l15z30yc7, nlhz8vlwyupq845jsdg9
Boot IDs found (0): 
Timestamps found (57): 2026-09-04T14:04:58Z, 2026-09-04T14:05:00Z, 2026-09-04T14:05:05Z, 2026-09-04T14:05:06Z, 2026-09-04T14:09:05Z, 2026-09-04T14:11:39Z, 2026-09-04T14:11:40Z, 2026-09-04T14:12:03Z, 2026-09-04T14:12:29Z, 2026-09-04T14:12:44Z

--- Agent 5 chrome ---
Sandbox IDs found (2): i80n46q8w7lm0xch991wu, iyl5sbten1irtm0cfue4p
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (1): 2bb79165-136a-4b63-829d-17027b0a8e40
Timestamps found (46): 2026-09-04T11:40:29Z, 2026-09-04T13:46:52Z, 2026-09-04T13:46:53Z, 2026-09-04T13:47:00Z, 2026-09-04T13:47:01Z, 2026-09-04T13:47:04Z, 2026-09-04T13:47:29Z, 2026-09-04T13:47:33Z, 2026-09-04T13:47:43Z, 2026-09-04T13:47:51Z

--- Agent 6 brave ---
Sandbox IDs found (2): i9nxb4qydn3qmwway6hd3, idxwgcmp6a9ioo1823yuk
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (1): 2bb79165-136a-4b63-829d-17027b0a8e40
Timestamps found (124): 2026-09-04T11:11:19Z, 2026-09-04T11:15:36Z, 2026-09-04T11:15:45Z, 2026-09-04T11:15:50Z, 2026-09-04T11:22:05Z, 2026-09-04T11:22:10Z, 2026-09-04T11:22:15Z, 2026-09-04T11:22:20Z, 2026-09-04T11:22:25Z, 2026-09-04T11:22:30Z

--- Agent 7 edge ---
Sandbox IDs found (2): i07vrt7m23evfzhmemmqh, ilvohmgrk3rcbvrgm79be
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (1): 2bb79165-136a-4b63-829d-17027b0a8e40
Timestamps found (120): 2026-09-04T11:16:10Z, 2026-09-04T11:22:56Z, 2026-09-04T14:17:31Z, 2026-09-04T14:17:47Z, 2026-09-04T14:17:50Z, 2026-09-04T14:17:51Z, 2026-09-04T14:17:53Z, 2026-09-04T14:18:07Z, 2026-09-04T14:18:13Z, 2026-09-04T14:18:18Z

--- Agent 8 edge ---
Sandbox IDs found (2): i87c7gwotry240rbx1u77, iitws4rrop6j50j2hed7r
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (1): 2bb79165136a4b63829d17027b0a8e40
Timestamps found (17): 2026-09-04T14:14:23Z, 2026-09-04T14:14:25Z, 2026-09-04T14:14:27Z, 2026-09-04T14:14:30Z, 2026-09-04T14:14:31Z, 2026-09-04T14:14:32Z, 2026-09-04T14:14:38Z, 2026-09-04T14:20:33Z

--- Agent 9 edge ---
Sandbox IDs found (1): ixwcucmrk55t9qy240sxo
Template IDs found (1): nlhz8vlwyupq845jsdg9
Boot IDs found (0): 
Timestamps found (201): 2026-09-04T12:11:04.583543938Z, 2026-09-04T12:11:20.477149742Z, 2026-09-04T12:11:21Z, 2026-09-04T12:12:06.937042370Z, 2026-09-04T12:12:32.344273914Z, 2026-09-04T12:12:32Z, 2026-09-04T12:13:02.080782593Z, 2026-09-04T12:13:02Z, 2026-09-04T12:15:37Z, 2026-09-04T12:16:40.349253785Z


```

### Key Observations:
- Template ID `nlhz8vlwyupq845jsdg9` is consistent across all 9 zips (except Agent 4 which also shows `gujonb0q163l15z30yc7` – documented as platform quirk after reboot).
- Sandbox IDs rotate per run, as expected for E2B ephemeral VMs. Examples:
  - Agent 1: ijwc38wq18p7cu57ydxvn, iim386kr3aoo4j3svsogz
  - Agent 2: i0v44lh3n78xffvhm6u5u, i4i7wdij5c7gh9absvtu8, i54yseeebo34z5jxzvoju
  - Agent 9: ixwcucmrk55t9qy240sxo (single)
- Boot ID `2bb79165-136a-4b63-829d-17027b0a8e40` (or without dashes `2bb79165136a4b63829d17027b0a8e40`) appears in Agents 2,5,6,7,8 – indicates same underlying host across those runs.
- Creation timestamps: All zips show 2026-09-04 dates, with logical sequence preserved despite snapshot restores resetting mtimes. Internal README files document true creation times from file headers and session logs.

## 5. Exact Commands Run (Reproducible)

```bash
# Phase 0 – Environment lock
date -u; uname -a; whoami; pwd; df -h .; free -h; id
which zip unzip sha256sum find file python3

# Phase 1 – Inventory
for zip in Agent*.zip; do
  stat -c %s "$zip"
  sha256sum "$zip"
  unzip -l "$zip"
done > trixie_extract_YYYYMMDD_HHMMSS/00_INVENTORY.txt

# Phase 2 – Controlled extraction
mkdir -p trixie_extract_YYYYMMDD_HHMMSS/extract
for zip in Agent*.zip; do
  name=${zip%.zip}
  mkdir -p "trixie_extract_.../extract/$name"
  unzip -o -d "trixie_extract_.../extract/$name" "$zip"
  find ".../extract/$name" -type f -exec sha256sum {} + | sort > ".../EXTRACTED_SHA256SUMS.txt"
  find ".../extract/$name" -type l -ls
  find ".../extract/$name" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.bin" -o -perm /111 \) -ls
done

# Phase 3 – Cross-check
sha256sum -c <internal SHA file>  (run from its own directory, python fallback used for spaces)
Compare outer SHA vs claimed values from conversation log

# Phase 4 – Structural
find extract -type f | sort > 01_ALL_FILES.txt
find extract -type f | wc -l; du -sb extract
Check duplicate filenames across zips
head -n 30 README / MANIFEST / INDEX files

# Phase 5 – Final report
cat 00_PHASE0_ENV.txt 00_INVENTORY.txt 02_CROSSCHECK.txt 04_ID_COMPARISON.txt > 02_UNPACK_REPORT.md
```

## 6. Recommendation

- **Clean and ready for further analysis**: All 9 archives
  - Agent 1 chrome.zip
  - Agent 2 brave.zip
  - Agent 3 brave.zip
  - Agent 4 chrome.zip
  - Agent 5 chrome.zip
  - Agent 6 brave.zip
  - Agent 7 edge.zip
  - Agent 8 edge.zip
  - Agent 9 edge.zip
- **Quarantined**: None. No integrity failures requiring quarantine.
- Next steps: Safe to analyze characterization reports (`environment_characterization.md`) and raw transcripts. Do NOT execute any .sh/.py until explicit review.

---
Extraction trees left intact under `trixie_extract_.../extract/` as required.
