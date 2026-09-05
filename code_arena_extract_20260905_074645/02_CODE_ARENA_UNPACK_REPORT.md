# 02 — CODE ARENA UNPACK & REDACTION REPORT
**Scope:** every `*.zip` in the working clone `anacondy/Trixie` evaluated as a candidate "Code Arena / project download"; the 10 not previously processed were unpacked, integrity-checked, and redaction-scanned.
**Isolated root:** `/home/user/Trixie/code_arena_extract_20260905_074645`
**Performed:** 2026-09-05 07:46–07:52 UTC (local date 2026-09-05, Asia/Calcutta)
**Constraints honoured:** no code executed (no npm/yarn/pnpm/drizzle, no servers, no scripts from any archive); no dependencies installed; no symlinks followed; all work confined to the isolated root; every archive treated as untrusted until outer + inner checks passed.

> **Key classification finding (read first):** **No zip in this clone is a Code Arena *project download*.** The 19 zips in the repo are (a) 9 workstream report bundles (`Ceilings/Provenance/Egress {1,2,3}`, already unpacked and verified in PR #2 under `ceilings_prov_egress_extract_20260904_214946/`) and (b) **10 sandbox environment-characterization evidence bundles** (9× `zips/Agent {1..9} <browser>.zip` + 1× nested `environment_evidence_20260904T142002Z-2576.zip`). This pass processed the 10 unprocessed bundles end-to-end (integrity + mandatory redaction audit + keep-filter). Every Code Arena high-value path listed in Phase 3 is **explicitly absent** from all 10 (see §3).

---

## 1. Environment snapshot (Phase 0)

```
$ date -u   → Sat Sep  5 07:46:35 UTC 2026
$ uname -a  → Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux
$ whoami    → user
$ id        → uid=1001(user) gid=1001(user) groups=1001(user),27(sudo),100(users)   [non-root]
$ df -h .   → /dev/root 21G total, 823M used, 20G avail (4%)
$ free -h   → 3.8Gi total, 233Mi used, 3.7Gi free, no swap
$ pwd       → /home/user  (repo root: /home/user/Trixie, branch arena/01a06e63-trixie)
```

**Tools:** `unzip` (6.00) OK · `sha256sum` OK · `find` OK · `python3` (3.11.2, stdlib) OK · **`file` MISSING** — documented approved substitute (user-approved in the prior pass of this PR): no magic-number typing; typing by zip metadata, extensions, permission bits, and content grep. Reducing inspection scope only; never widening it.

**Isolated root created:** `code_arena_extract_20260905_074645` (UTC timestamp), all work confined to it.

---

## 2. Per-archive table (Phases 1–2)

All 10 extracted one-at-a-time with `unzip -o -d "extract/<sanitised>/" "<zip>"` as non-root `uid=1001`; each followed immediately by per-file SHA-256 capture + self-verify, symlink scan, executable-bit scan, and path-escape check (all PASS, `_work/EXTRACTION_LOG.txt`).

| archive (repo path) | size (B) | outer SHA-256 | files (uncompressed B) | extraction | redaction actions | secrets found / removed |
|---|---|---|---|---|---|---|
| `zips/Agent 1 chrome.zip` | 10,863 | `52880dad6738d951ad51a255347297ea54905b282e1456f70ef97e576266dee7` | 10 (20,077) | OK, rc=0, 0.004 s | full 6-class scan; no `.env*`; nothing to remove | **none found, none removed** |
| `zips/Agent 2 brave.zip` | 78,729 | `55302d915b3c07b1f11bed29738c458ae78e349a417b9dae22281c2cd6d444fa` | 26 (253,558) | OK, rc=0, 0.007 s | ditto | **none / none** |
| `zips/Agent 3 brave.zip` | 47,044 | `066b4eb2764eea3f7543ad575a637f3c8d83e7d742ab81385d2fc17c09e8e62d` | 25 (106,674) | OK, rc=0, 0.004 s | ditto | **none / none** |
| `zips/Agent 4 chrome.zip` | 282,299 | `0f01d761ded3ddf9ec755bc7ce289029e093e172748f72a179e7054da769662b` | 151 (742,557) | OK, rc=0, 0.012 s | ditto | **none / none** |
| `zips/Agent 5 chrome.zip` | 119,842 | `cfd0179b38fe6e6edce5b56205a38a3b5d6660b6f3fa88b46e54530fda151466` | 51 (293,407) | OK, rc=0, 0.006 s | ditto | **none / none** |
| `zips/Agent 6 brave.zip` | 153,569 | `dea4ec47ac81a2e65606778aa4da6895cbce03094d2f47845d4b8fc25e7e53d0` | 90 (353,977) | OK, rc=0, 0.008 s | ditto | **none / none** |
| `zips/Agent 7 edge.zip` | 130,614 | `5c0f02b35a2f43c633a92e16fed9daa5bf77cd018bfed8fdb084734aa4eac13c` | 83 (300,759) | OK, rc=0, 0.007 s | ditto | **none / none** |
| `zips/Agent 8 edge.zip` | 30,820 | `7fe13f8118d625420a55a2ea14a66b61715acc4be9bf7249666ba2193841c898` | 16 (75,027) | OK, rc=0, 0.004 s | ditto | **none / none** |
| `zips/Agent 9 edge.zip` | 247,182 | `2007bbee89d81a92d4b3fecdf5c06c6f7ba2f53f86c599dbfc18da4c2e3e10a2` | 91 (675,295, incl. 62,153 B nested zip kept as inert file) | OK, rc=0, 0.011 s | ditto | **none / none** |
| `forensic/evidence/…/environment_evidence_20260904T142002Z-2576.zip` | 62,153 | `e8215900f3136be5bfddbd74233d9c05b48dc7bfff250802f77ffa5e53dfdb9d` | 21 (183,790) | OK, rc=0, 0.004 s | ditto | **none / none** |

**Redaction scan classes (applied to every file in every tree, twice — at 07:47:51 and final confirmation at 07:49:21 UTC):**
A. connection strings with userinfo (`scheme://user:pass@host`, 16 DB/cache/queue schemes) · B. `DATABASE_URL`/`DB_*`/`*_URL` assignments · C. known key/token formats (AWS `AKIA…`, Google `AIza…`, GitHub `ghp_/gho_/github_pat_`, Slack `xox…`, OpenAI `sk-…`, JWTs, PEM private keys) · D. generic credential assignments (`password/secret/api_key/token: value`) · E. `.env`/`.env.*`/`*.env` files · F. Bearer / basic-auth headers. Plus any-scheme userinfo URI sweep.
**Result: 0 hits in every class on both passes** (the only category-D grep hits were `PWD=`/`OLDPWD=` working-directory env lines — false positives, not credentials). No `DATABASE_URL` or connection string exists anywhere, so no scheme+host recording was required. Full logs: `_work/03_SECRET_SCAN.txt`, `_work/03b_SUPPLEMENTARY_SCAN.txt`, `_work/05_FINAL_REDACTION_CONFIRMATION.txt`.

**Other extraction checks (all 10):** no symlinks · no path traversal / absolute / backslash archive entries · no binaries by extension · no nested archives >50 MB (one nested zip at 183,790 B uncompressed — kept as inert file, not recursed) · per-tree `EXTRACTED_SHA256SUMS.txt` self-verify PASS for all 564 data files.

**⚠ Execute-bit flags (flagged, never executed):** text probe scripts with mode 755 — Agent 4 (5: `envcheck/probe.sh`, `probe_background.sh`, `diff_run.sh`, `normalize.py`, `make_manifest.py`), Agent 5 (3), Agent 6 (2), Agent 7 (1), Agent 8 (1), Agent 9 (2), nested env-evidence (2, same pair as Agent 9). Same category as PR #2's documented judgment: plain-text probe scripts inside expected probe directories with paired raw outputs; quarantining would destroy legitimate expected evidence.

---

## 3. Retained high-value paths per archive (Phase 3 — Code Arena keep-list)

| keep-list artefact | found in any of the 10? |
|---|---|
| `src/app/api/` (incl. env route) | **ABSENT — 0 files** |
| `page.tsx` / other top-level page files | **ABSENT — 0** |
| `components/` | **ABSENT — 0** |
| `lib/` | **ABSENT — 0** |
| drizzle config + schema files | **ABSENT — 0** |
| `sandbox-recon-marker.txt` | **ABSENT — 0** (nearest analog: `Agent 9 edge/payload/home/user/.environment_characterization_persistence_probe` — a persistence probe marker, not the recon marker) |
| `package.json` / lockfiles | **ABSENT — 0** |
| saved `/api/env` JSON snapshot | **ABSENT — 0** |
| rendered `SANDBOX://RECON` HTML or screenshot | **ABSENT — 0** (no `.html` files of any kind in any tree) |
| session transcript / export | **ABSENT — 0** (sole `session*` hit: `_envchar/session_marker.txt`, a persistence marker) |

**Consequence:** by the Code Arena keep-list, the retained set is **empty for all 10 archives** — everything in them is marked **non-essential to a Code Arena project subset**. The bundles' actual (non-Code-Arena) high-value content, left in place for reference: per-agent `environment_characterization.md` report (present in 8 of 10), verbatim `raw*/NN_*.txt` probe transcripts, probe scripts, and the per-run manifests/checksums listed below. If a publishable subset is still desired, it should be defined against *this* content model rather than the keep-list.

---

## 4. Quarantined archives (Phase 2/6 rule)

**None.** No archive failed integrity, contained binaries, path traversal, absolute entries, nested archives >50 MB, or any secret that could not be cleanly redacted. (The execute-bit `.sh`/`.py` flags are documented in §2 and do not trigger quarantine under the judgment recorded in PR #2's report; a stricter policy would quarantine the 6 affected archives — decision left to the reviewer.)

---

## 5. Confirmations

1. **No code was executed.** No command in any archive was run; no package/dependency was installed; no server or process from the archives was started; no npm/yarn/pnpm/drizzle invocation occurred. All "verification" was hash computation, metadata inspection, and grep (read-only).
2. **No secrets remain.** 6-class + userinfo-URI scan passes at 07:47:51 and 07:49:21 UTC: zero `DATABASE_URL`/connection strings, zero key/token formats, zero Bearer/basic auth, zero `.env*` files across all 564 data files. Nothing required redaction; the confirmation is scan-based, not assumption-based.
3. **Inner integrity:** 25 standard-format internal manifests verified — **552/552 entries OK, 0 mismatches, 0 missing** (`_work/04_ALL_MANIFESTS_VERIFIED.txt`); JSON manifest `probe_script_sha256` claim matches; the `.sha256` sidecar matches the nested zip (`e8215900…`); the nested zip embedded in Agent 9 is byte-identical to the repo's `forensic/evidence/` copy. One benign anomaly noted: the sidecar's manifest entry uses an absolute path (`/home/user/…`) — a packaging quirk, not an archive-entry traversal.
4. **Outer integrity:** `unzip -t` + CRC re-check clean on all 10; no path traversal/absolute/backslash entries in any archive entry name.

---

## 6. Exact commands used (reproducibility)

Run from `/home/user/Trixie` unless noted. `<ROOT>` = `code_arena_extract_20260905_074645`.

**Phase 0**
```bash
date -u; uname -a; whoami; pwd; df -h .; free -h; id
for t in unzip sha256sum find file python3; do command -v "$t" || echo "$t MISSING"; done
mkdir -p code_arena_extract_$(date -u +%Y%m%d_%H%M%S) && cd code_arena_extract_20260905_074645
```

**Phase 1** (per candidate zip, 10 explicit paths; read-only)
```bash
stat -c '%s' "Z"; sha256sum "Z"
unzip -l "Z"; unzip -t "Z"
python3 - "Z" <<'EOF'   # zipfile metadata: counts, uncompressed totals, unix modes,
import sys, zipfile     # .env*/node_modules/nested-zip/exec-bit/traversal detection, testzip()
... EOF
# → <ROOT>/00_INVENTORY.txt
```

**Phase 2** (sequential, one archive at a time, non-root)
```bash
mkdir -p "extract/<NAME>"
unzip -o -d "extract/<NAME>/" "/home/user/Trixie/<Z>"     # stdout → _work/unzip_<NAME>.log
find "extract/<NAME>" -type l -ls                          # symlink scan
find "extract/<NAME>" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.c" -o -name "*.bin" \
  -o -name "*.env" -o -name ".env.*" -o -perm /111 \) -ls  # script/exec/env flag
find "extract/<NAME>" -type f ! -name EXTRACTED_SHA256SUMS.txt -exec sha256sum {} + | sort \
  > "extract/<NAME>/EXTRACTED_SHA256SUMS.txt"
sha256sum -c "extract/<NAME>/EXTRACTED_SHA256SUMS.txt"     # from isolated root
# escape check: (find . -type f | sort) before/after diff, excluding extract/<NAME>/ + _work/ auditor logs
```

**Phase 2c/d — redaction scan (read-only greps, then final re-scan)**
```bash
grep -rniE '(postgres(ql)?|mysql|mariadb|mongodb(\+srv)?|redis|rediss|amqp|amqps|sqlserver|oracle|prisma|clickhouse|elastic|opensearch)(\+[^:/ ]+)?://[^/ ]*:[^@ ]*@' extract/
grep -rniE '(DATABASE_URL|DB_HOST|DB_USER|DB_PASS|DB_NAME|SQLALCHEMY_DATABASE_URI|REDIS_URL|MONGO_URI|MONGODB_URI|POSTGRES_URL|MYSQL_URL)[[:space:]]*[:=][[:space:]]*[^ ]' extract/
grep -rnE '(AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|ghp_[0-9A-Za-z]{36,}|gho_[0-9A-Za-z]{36,}|github_pat_[0-9A-Za-z_]{22,}|xox[baprs]-[0-9A-Za-z-]{10,}|sk-[A-Za-z0-9]{20,}|sk_live_[0-9A-Za-z]+|sk_test_[0-9A-Za-z]+|-----BEGIN [A-Z ]*PRIVATE KEY-----|JWT-regex)' extract/
grep -rniE '(password|passwd|pwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[^ <]{6,}' extract/   # false positives: PWD/OLDPWD only
find extract -type f \( -name '.env' -o -name '.env.*' -o -name '*.env' \)
grep -rniE '(bearer [A-Za-z0-9._-]{16,}|authorization:[[:space:]]*basic [A-Za-z0-9+/=]{12,})' extract/
grep -rnoE '[a-zA-Z][a-zA-Z0-9+.-]*://[^/ ]*@[^ ]+' extract/ | grep -vE 'file://|mailto:|SANDBOX://'
# → _work/03_SECRET_SCAN.txt, _work/03b_SUPPLEMENTARY_SCAN.txt, _work/05_FINAL_REDACTION_CONFIRMATION.txt
```

**Phase 3/4**
```bash
find extract -type f -iname '*<keep-list-pattern>*' | wc -l      # ×17 keep-list patterns → 0 (one persistence-marker false positive)
find extract -type f | sort > 01_ALL_EXTRACTED_FILES.txt         # 574 entries
# counts: 564 data files / 68 dirs / 3,005,121 data bytes
# collisions: per-tree relative paths, count >1 → 3 (all within the same env-characterization family)
( cd <manifest-dir-context> && sha256sum -c <internal manifest> )  # per manifest, correct relative context
python3 <systematic verifier over all 52 manifest/checksum files>  # → _work/04_ALL_MANIFESTS_VERIFIED.txt (25 standard, 552/552 OK)
```

---

## Disclosure & limitations

1. `file(1)` absent → user-approved substitute (as in PR #2); no magic-number typing performed.
2. No Code Arena project download exists in this clone; the keep-list is therefore empty by absence, not by selection. If the intended target zips were expected here, they were not found in the working tree (all 19 `*.zip` files are enumerated in `00_INVENTORY.txt` and classified above).
3. The nested `environment_evidence_*.zip` inside Agent 9 was **not** recursed (kept as inert file); its standalone repo copy was processed separately and is byte-identical to it.
4. Execute-bit probe scripts (12 across 6 archives) retained as inert evidence — never executed.

*End of report. No application logic analysed; no app started; nothing pushed at report-writing time.*
