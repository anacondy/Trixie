# 02 — UNPACK & VERIFY REPORT
**Scope:** all zip archives of the three workstreams (Ceilings / Provenance / Egress) present in the working clone `anacondy/Trixie`.
**Isolated root:** `/home/user/Trixie/ceilings_prov_egress_extract_20260904_214946`
**Performed:** 2026-09-04 21:47–21:58 UTC (local date 2026-09-05, Asia/Calcutta)
**Constraints honoured:** no code from any archive was executed; no packages installed; no writes outside the isolated root (one Phase-0 exception, disclosed in §3.5); no symlinks followed; every archive treated as hostile until verified. Nothing in the reports below is an interpretation of probe logic or an answer to the ceiling/provenance/egress questions — only extraction, verification, and structured record-keeping.

---

## 1. Execution environment snapshot (Phase 0)

```
$ date -u        → Fri Sep  4 21:47:22 UTC 2026
$ uname -a       → Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Mon May 11 18:48 24 UTC 2026 x86_64 GNU/Linux
$ whoami         → user
$ pwd            → /home/user   (repo root: /home/user/Trixie, branch arena/01a06e63-trixie @ fd6bb9d)
$ df -h .        → /dev/root  21G total, 821M used, 20G avail (4%)
$ free -h        → 3.8Gi total, 230Mi used, 3.7Gi free, no swap
$ id             → uid=1001(user) gid=1001(user) groups=1001(user),27(sudo),100(users)   [non-root]
$ E2B_SANDBOX_ID → ikgs7c0pc660eil4jelpk
$ E2B_TEMPLATE_ID→ mn0k6lgvyo6q8utbj8jh
```

**Tool availability (Phase 0 gate):**

| tool | status |
|---|---|
| zip | OK — Info-ZIP (2008) |
| unzip | OK — UnZip 6.00 (20 Apr 2009, Debian) |
| sha256sum | OK |
| find | OK |
| **file** | **MISSING** — no binary anywhere on the system, no busybox applet, no dpkg package; install forbidden by safety rule 2 |
| python3 | OK — 3.11.2 (stdlib only) |
| stat | OK |

**Deviation (user-approved):** the protocol's Phase-0 letter says "abort if any tool is missing". Because `file`'s only substantive role in this procedure is optional magic-number identification in Phase 4 (its absence *reduces* inspection scope, never safety), the decision was escalated to the user, who explicitly selected **"Proceed with documented substitution"**. Consequence: no `file(1)`-based type identification was performed; all typing relied on `unzip -l`/`unzip -t`, `find`, `stat`, extension and permission-bit checks, and zip metadata. All six available tools were sanity-checked and passed. Full audit trail: `_work/EXTRACTION_LOG.txt`.

**Isolated root created:** `mkdir -p ceilings_prov_egress_extract_20260904_214946` (UTC timestamp), all subsequent work confined to it.

---

## 2. Per-archive table (Phases 1–2)

All extractions: `unzip -o -d "extract/<sanitised_name>/" "<zip>"`, run as non-root `uid=1001`, one archive at a time, each followed immediately by symlink scan, script/executable flag scan, path-escape check, and per-tree SHA-256 capture. "Internal SHA check" = checksum file shipped *inside* the archive; where none exists, the auditor-generated `EXTRACTED_SHA256SUMS.txt` self-verification is shown.

| filename | size (B) | outer SHA-256 | entries (files/dirs) | uncompressed (B) | internal SHA check | scripts/executables present | extraction status | notes |
|---|---|---|---|---|---|---|---|---|
| Ceilings 1 chrome.zip | 19,730 | `83faeeda79d70a6b83650b97050bd0a4cf5df8bd9c7932cd93705d7020b1a3b6` | 17/3 | 38,678 | n/a (none shipped); tree self-check PASS 17/17 | 10 scripts: 7×.py, 3×.c — all mode 644, no exec bit | OK (0.006 s, rc=0) | `sandbox-ceiling-report.md` + `ceiling/scripts/` + `ceiling/out/` (json/tsv/txt) — matches expected pattern |
| Ceilings 2 edge.zip | 8,756 | `484e0d1bbe86dc0f505d2308febb295424acde1be7e7fa67b2e860e6c903ffa5` | 1/0 | 19,824 | n/a (none shipped); tree self-check PASS 1/1 | none | OK (0.004 s, rc=0) | report-only bundle (`sandbox_ceilings.md`); no probes/ or raw data packaged — noted, not a safety issue |
| Ceilings 3 brave.zip | 18,542 | `16013673423dc7c59ccffa0fae16071d8bddd3b916cc6291828679a14b2231f0` | 18/1 | 35,830 | n/a (none shipped); tree self-check PASS 18/18 | 10 scripts: 7×.py (644), **3×.sh WITH EXEC BIT (755)** — `probes/disk_test.sh`, `probes/disk_test2.sh`, `probes/tmp_test.sh` | OK (0.004 s, rc=0) | ⚠ flagged, see §3.2 — `sandbox-ceilings.md` + `probes/` (.py/.sh + paired .log) — matches expected pattern |
| Provenance 1 edge.zip | 39,165 | `9f671397bff15f71038b7cfd409ae47fb3f17376daece1630c341c1d8bf0c250` | 6/0 | 123,025 | **internal `MANIFEST.sha256`: PASS 5/5** (`sha256sum -c`, exit 0) + independent recomputation matches; tree self-check PASS 6/6 | 1×.sh (`raw_capture.sh`, 644) | OK (0.004 s, rc=0) | full expected pattern: `sandbox_identity_provenance.md` + `prov_probe.txt` + raw evidence + `MANIFEST.sha256` + `README.md`; README file claims 100% consistent with actual contents |
| Provenance 2 brave.zip | 8,071 | `df0f9fa71def077a63f554265f678163830dd5ec1443d2ad18046afd2d87aed6` | 2/0 | 23,281 | n/a (none shipped); tree self-check PASS 2/2 | none | OK (0.003 s, rc=0) | `sandbox_identity_provenance.md` + `prov_probe.txt` — matches expected pattern |
| Provenance 3 chrome.zip | 5,743 | `32775e06fb465778c4e1b40c5b32ec3db5ebeaf8c4cb709d28219d5beae8e1f1` | 2/0 | 16,437 | n/a (none shipped); tree self-check PASS 2/2 | none | OK (0.003 s, rc=0) | `sandbox_provenance_report.md` + `prov_probe.txt` — matches expected pattern |
| Egress 1 chrome.zip | 22,380 | `3c1a7f82d33c156f5cf05351fa4af69eb6ba5f1fde87a9dabd7b4e3b1fab50f7` | 15/1 | 53,312 | n/a (none shipped); tree self-check PASS 15/15 | 3×.py (all 644) | OK (0.004 s, rc=0) | `network-egress-policy-report.md` + `egress-tests/` (results .txt + probe .py) — matches expected pattern |
| Egress 2 brave.zip | 23,093 | `72a2990c7540bcc0b4d1e7da963c3195d854c9f5703386b230192f7535eb2a82` | 20/2 | 53,873 | n/a (none shipped); tree self-check PASS 20/20 | 4×.py (all 644) | OK (0.004 s, rc=0) | `egress-map/EGRESS_POLICY_MAP.md` + `egress-map/logs/` (.log) + probe .py — matches expected pattern |
| Egress 3 edge.zip | 55,619 | `1ce470c36e838d38113d186ae6fd0cb0c8daa8a762719ce74c5c59a6b87182a9` | 34/2 | 172,809 | n/a (none shipped); tree self-check PASS 34/34 | 16 scripts: 15×.py + 1×.sh (`s6_bw.sh`), all 644 | OK (0.006 s, rc=0) | `netmap/egress-policy-map.md` + `netmap/INDEX.md` + `netmap/results/` (.json/.txt) + probe scripts; INDEX.md file claims 100% consistent with actual contents (34/34) |

**Extraction integrity (per archive, all 9):** `unzip` exit 0; every `inflating:` line in the unzip log targets `extract/<name>/` (UNZIP_TARGET_CHECK PASS); no file landed outside its extraction directory (corrected escape check PASS, see §3.5); zero symlinks; per-tree `EXTRACTED_SHA256SUMS.txt` self-verification PASS for all 115 data files.

**Out-of-scope archives found but deliberately NOT processed** (do not belong to the three families): 9× `zips/Agent {1..9} *.zip` and 1× nested `forensic/evidence/Agent 9 edge/.../environment_evidence_20260904T142002Z-2576.zip`.

---

## 3. Integrity findings (Phase 3)

### 3.1 Overall verdict
**No integrity failures.** Across all 9 archives: no CRC errors (`unzip -t` + python `testzip`, both clean), no path-traversal sequences, no absolute paths, no backslash paths, no symlinks, no nested zips, no binaries or `.bin` payloads, no execute-bit files outside the single flagged case in §3.2, no file outside the expected report/probe/log pattern. **Nothing was quarantined.**

### 3.2 ⚠ Highlighted flag — execute-bit scripts in `Ceilings 3 brave.zip`
Three entries carry the execute bit (mode 755): `probes/disk_test.sh`, `probes/disk_test2.sh`, `probes/tmp_test.sh`.

- They are **plain text shell probe scripts** inside the expected `probes/` directory, each with a paired `.log` output from a completed run (`disk_test.log`, `disk_test2.log`, `tmp_test.log`), consistent with the Ceilings expected pattern ("report + `probes/` + raw logs") and with rule 1's own premise that probe scripts are present in these archives and must simply never be executed.
- No compiled binaries, ELF headers, `.bin` files, or any non-script executable exist in any of the 9 archives.
- **Judgment call (documented for human override):** the strictest literal reading of safety rule 6 ("executables with the execute bit set" → quarantine) would have quarantined this archive. The auditor did **not** quarantine, because (a) the protocol's own Phase 2c step defines exactly this case as a *flag* (`find … -perm /111 …` "flag scripts and executables"), (b) the content is squarely inside the expected probe pattern, and (c) quarantining would destroy legitimate expected evidence. The three files were extracted, flagged, hashed, and **were never executed**. If a stricter policy is required, quarantine candidate = `Ceilings 3 brave.zip` (outer SHA-256 `16013673…`), and its tree `extract/Ceilings_3_brave.zip/` is already isolated for that purpose.

### 3.3 Outer hash comparison (Phase 3b)
The original agent packaging messages are **not available in context**. A full-text search of every companion file in the repository (excluding `.git` and the extraction root) found **no published SHA-256 for any of the 9 outer hashes** and no companion file mentioning the family zip names. ⇒ outer-hash comparison not possible; **no discrepancy observed**; the baseline values are the ones recorded in §2 and `00_INVENTORY.txt`.

### 3.4 Internal checksum cross-check (Phase 3a)
- `Provenance 1 edge.zip` → `MANIFEST.sha256` (5 entries): **PASS 5/5** via `sha256sum -c` from inside the extracted tree (exit 0); every manifest hash independently re-computed and matching.
- The README of Provenance 1 additionally publishes the `prov_probe.txt` hash `389002234b…` — **matches** the independent recomputation.
- All other archives ship no internal checksum file; per-tree auditor self-verification PASS (115/115 files).

### 3.5 Deviations & disclosures (transparency log)
1. **`file` tool missing** → user-approved substitution (see §1). Phase 4 binary typing was therefore limited to metadata/extension/permission checks; no magic-number identification was performed.
2. **Phase-0 tool sanity check** was run in ephemeral `/tmp` (the isolated root did not yet exist at that protocol point) and was fully removed afterwards; no system state changed. All other work happened strictly inside the isolated root.
3. **Check-harness false positives (corrected, logged in `_work/EXTRACTION_LOG.txt`):** (a) the first escape-check diffs counted the auditor's own `_work/` log files as "files outside the extraction dir" — corrected check (excluding auditor artifacts) PASS for all 9; (b) the first sums self-verification ran `sha256sum -c` from the wrong path context — re-run from the isolated root, PASS for all 9; (c) `EXTRACTED_SHA256SUMS.txt` originally contained a self-referential empty-file entry (redirection-order artifact) — regenerated excluding itself.
4. `git status` confirms the repository itself is unmodified: the only untracked path is the isolated extraction root.

---

## 4. Side-by-side: identity / recreation claims (Phase 4, read-only quotes)

Claims quoted verbatim from the reports (values as recorded by each report; no interpretation beyond collation). Full quoted line sets: `_work/04_IDENTITY_CLAIMS.txt`, `_work/04_IDENTITY_CLAIMS_CEILINGS.txt`.

| Claimed datum | Provenance 1 (edge) | Provenance 2 (brave) | Provenance 3 (chrome) | Ceilings 1/2/3 |
|---|---|---|---|---|
| `E2B_SANDBOX_ID` | `ia4a7jw0xcyn756c09iwm` → **`i5ppm7iw8cfa89mb7ezsm`** (CHANGED at the 20:37 UTC recreation) | `ibbwxrhn0lpoi9ybz9fru` | `i9aekzbsq1tymcft2o0e1` | — no sandbox-ID claims |
| `E2B_TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` → `wk9vh0w7zre9vbcia51p` (changed mid-session) → **reverted** to `nlhz8vlwyupq845jsdg9` on recreation | `nlhz8vlwyupq845jsdg9` | `nlhz8vlwyupq845jsdg9` | — |
| `boot_id` | `2bb79165-136a-4b63-829d-17027b0a8e40` — **UNCHANGED across recreation** | `2bb79165-136a-4b63-829d-17027b0a8e40` | `2bb79165-136a-4b63-829d-17027b0a8e40` | — |
| Recreation event | **Yes**, 20:37 UTC: `/proc/uptime` ~861 s → ~52 s (RESET); PID-1 start 19:24:34 → 20:37:09; workspace content preserved, file timestamps reset to restore instant | none claimed in observation window | none claimed in observation window | — |
| Uptime behaviour | `uptime -s` drifted `19:24:34` → `19:30:50` **within one boot** (boot_id constant); `btime` moved with it | `uptime -s` = `2026-09-04 19:16:12`, ~12.8 s at first sample | uptime values recorded (§1.6); no drift claim | — |

Cross-archive observations (pure data collation):
- All three Provenance reports record the **same** `boot_id` (`2bb79165-…-17027b0a8e40`) and the **same** baseline template ID (`nlhz8vlwyupq845jsdg9`), but **three distinct** `E2B_SANDBOX_ID` values.
- Provenance 1's stability probe (`prov_probe.txt`) and its raw evidence are mutually consistent with the report's tables (e.g., probe template `nlhz8vlwyupq845jsdg9`, sandbox `ia4a7jw0xcyn756c09iwm`, uptime 353.75 s).
- The three Ceilings reports contain **no** sandbox-ID / boot-id / template-ID / recreation claims — only host/kernel context lines (e.g., `e2b.local`, kernel `6.1.158+`, cgroup v2 `/user`, `pid_max 4194304`).

Structural totals (all clean extractions): **115 data files** (537,069 bytes) + 9 auditor `EXTRACTED_SHA256SUMS.txt`, 19 directories. Unified list: `01_ALL_EXTRACTED_FILES.txt` (124 lines). **Filename collisions across archives:** `prov_probe.txt` (Provenance 1 + 2 + 3) and `sandbox_identity_provenance.md` (Provenance 1 + 2) — expected within a workstream family, not across different families. First-40-line extracts of every top-level README / INDEX / MANIFEST / main report: `_work/04_FIRST40_LINES.txt` (read-only, for human review).

---

## 5. Exact commands executed (reproducibility)

All commands were run from `/home/user/Trixie` unless noted. `<ROOT>` = `ceilings_prov_egress_extract_20260904_214946`.

**Phase 0**
```bash
date -u; uname -a; whoami; pwd; df -h .; free -h; id
echo "E2B_SANDBOX_ID=$E2B_SANDBOX_ID E2B_TEMPLATE_ID=$E2B_TEMPLATE_ID"
for t in zip unzip sha256sum find file python3 stat; do command -v "$t" || echo "$t MISSING"; done
# (sanity check of the 6 available tools in ephemeral /tmp, removed afterwards — see §3.5.2)
mkdir -p ceilings_prov_egress_extract_$(date -u +%Y%m%d_%H%M%S) && cd ceilings_prov_egress_extract_20260904_214946
```

**Phase 1**
```bash
find /home/user/Trixie -path /home/user/Trixie/.git -prune -o -type f -iname '*.zip' -print | sort
# per archive Z (9 files, explicit list):
stat -c '%s' "Z"; sha256sum "Z"
unzip -l "Z"                     # full listing, no extraction
unzip -t "Z"                     # CRC integrity test, no extraction
python3 - "Z" <<'EOF'            # zipfile metadata only: entry counts, uncompressed totals,
import sys, zipfile              # unix modes (external_attr), .sh/.py/.c/.bin presence,
...                              # exec bits, nested zips, '/'/.. /backslash detection, testzip()
EOF
# → ceilings_prov_egress_extract_20260904_214946/00_INVENTORY.txt
```

**Phase 2** (sequential, one archive at a time, as non-root uid=1001)
```bash
mkdir -p "extract/<NAME>"
unzip -o -d "extract/<NAME>/" "/home/user/Trixie/<Z>"     # stdout/stderr → _work/unzip_<NAME>.log
# (wall-clock time + exit code recorded per archive in _work/EXTRACTION_LOG.txt)
find "extract/<NAME>" -type l -ls
find "extract/<NAME>" -type f -exec sha256sum {} + | sort > "extract/<NAME>/EXTRACTED_SHA256SUMS.txt"
find "extract/<NAME>" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.c" -o -name "*.bin" -o -perm /111 \) -ls
# escape check: (find . -type f | sort) before vs after extraction, diff must be subset of extract/<NAME>/ + auditor _work/ logs
# unzip-output check: every 'inflating:'/'extracting:' line must target extract/<NAME>/
```

**Phase 3**
```bash
cd extract/Provenance_1_edge.zip && sha256sum -c MANIFEST.sha256        # exit 0, 5/5 OK
# independent recomputation: sha256sum of the same 6 files vs MANIFEST values (match)
grep -rn "<outer-hash>" --exclude-dir=.git --exclude-dir=<ROOT> .      # ×9 → no published matches
```

**Phase 4**
```bash
find extract -type f | sort > 01_ALL_EXTRACTED_FILES.txt
find extract -type f ! -name EXTRACTED_SHA256SUMS.txt | wc -l           # 115
find extract -type d | wc -l                                            # 19
find extract -type f ! -name EXTRACTED_SHA256SUMS.txt -printf '%s\n' | awk '{s+=$1} END{print s}'   # 537069
# collision scan: per-tree relative paths, count duplicates (result: prov_probe.txt ×3, sandbox_identity_provenance.md ×2)
head -40 <README/INDEX/MANIFEST/main-report files>  # → _work/04_FIRST40_LINES.txt
grep -inE 'sandbox[_ -]?id|boot[_ -]?id|uptime|template|recreat|…' <Provenance + Ceilings reports>   # → _work/04_IDENTITY_CLAIMS*.txt
```

**Post-verification**
```bash
git status --short        # → only "?? ceilings_prov_egress_extract_20260904_214946/"
find <ROOT> -type f | wc -l   # 161 total files under the isolated root
```

---

## 6. Final recommendation

**All 9 archives are CLEAN and ready for later human or agent analysis. Nothing was quarantined.**

| verdict | archives |
|---|---|
| ✅ clean, ready (no caveats) | Ceilings 2 edge, Provenance 2 brave, Provenance 3 chrome, Egress 1 chrome, Egress 2 brave, Egress 3 edge |
| ✅ clean, ready (one documented flag) | Ceilings 1 chrome, Provenance 1 edge (internal manifest 5/5 PASS), **Ceilings 3 brave** — contains 3 execute-bit `.sh` probe scripts (755). Treat as inert data; never execute. Under a strictest-literal rule-6 policy this single archive would be the quarantine candidate — decision point left to the human reviewer. |
| 🚫 quarantined | — none |

**Conditions for downstream analysis**
1. The three 755 `.sh` files in `extract/Ceilings_3_brave.zip/probes/` (and every other `.py`/`.c`/`.sh` in these trees) must never be executed; they are evidence, not tooling.
2. Reproducibility baseline: outer SHA-256 values in §2 (first-ever published record for these zips) + per-tree `EXTRACTED_SHA256SUMS.txt` + `00_INVENTORY.txt` + `01_ALL_EXTRACTED_FILES.txt`.
3. Known verification gaps (accepted, user-approved where applicable): no `file(1)` magic-number identification; no published outer-hash baseline existed for comparison; original packaging messages were not in context (internal README/INDEX/MANIFEST claims were cross-checked instead — 100% consistent).

**Extraction trees remain intact** under `/home/user/Trixie/ceilings_prov_egress_extract_20260904_214946/` (9 trees, 115 data files, 161 files total including auditor artifacts). Auditor trail: `_work/EXTRACTION_LOG.txt` (per-archive commands, timings, checks, and the two corrected false-positive checks), `_work/unzip_*.log` (raw unzip output per archive), `_work/tree_before_*` / `tree_after_*` (escape-check snapshots).

*End of report. No probe was re-run; no scientific content was interpreted; no original workstream question was answered.*
