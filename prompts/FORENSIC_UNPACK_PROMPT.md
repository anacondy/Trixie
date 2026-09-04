# Forensic Unpack Task – Reproducible Prompt

This file contains the exact prompt that defines the forensic unpacking task for Agent *.zip archives in this repository. Use it to reproduce the work.

---

## Prompt (verbatim from user request)

```
You are a senior forensic systems engineer. Your only task is to safely unpack, inventory, verify, and cross-check every Agent *.zip archive in the current working directory (or the local clone of https://github.com/anacondy/Trixie).

STRICT SAFETY RULES (never violate):
1. Never execute any script, binary, or .sh/.py file found inside any zip.
2. Never run any command that installs packages, writes outside a dedicated extraction tree, or modifies system state.
3. Never follow symbolic links that point outside the extraction tree.
4. Treat every archive as potentially hostile until every hash and structure check passes.
5. Work only inside a fresh, isolated directory named `trixie_extract_YYYYMMDD_HHMMSS` (create it yourself).
6. If any zip fails integrity or contains unexpected content (executables, absolute paths, path traversal, nested zips that expand > 50 MB uncompressed, etc.), STOP, quarantine that zip, and report the failure before continuing.

PROCEDURE (execute in exact order):

PHASE 0 – Environment lock
- Record: date -u, uname -a, whoami, pwd, df -h ., free -h, id
- Confirm zip, unzip, sha256sum, find, file, python3 are available. If any is missing, abort and report.

PHASE 1 – Inventory
- List every file matching Agent*.zip (or *brave.zip *edge.zip *chrome.zip).
- For each zip compute and print:
  - Size in bytes
  - SHA-256
  - unzip -l (full listing, no extraction)
  - Number of entries, total uncompressed size, presence of directories, presence of any .sh/.py/.bin/.exe
- Write the inventory to `00_INVENTORY.txt`.

PHASE 2 – Controlled extraction
For each zip, one at a time:
  a. Create a subdirectory: `extract/<zipname_without_extension>/`
  b. Extract with: `unzip -o -d extract/<name>/ "<zip>"`  (never use -j or wildcards that can escape)
  c. Immediately run:
     - `find extract/<name> -type f -exec sha256sum {} + | sort > extract/<name>/EXTRACTED_SHA256SUMS.txt`
     - `find extract/<name> -type l -ls`  (report any symlinks)
     - `find extract/<name> -type f \( -name "*.sh" -o -name "*.py" -o -name "*.bin" -o -perm /111 \) -ls`  (flag any executable or script)
  d. Confirm no path traversal occurred (no files outside extract/<name>/).
  e. Record exact extraction wall-clock time.

PHASE 3 – Cross-check against published claims
For every zip that contains a README / INDEX / MANIFEST / SHA256SUMS / 00_*.md:
  - Locate the internal SHA256SUMS (or equivalent) and the claimed outer zip SHA-256 (if present in the conversation log or sidecar).
  - Run `sha256sum -c` on the internal sums (from inside the extracted tree).
  - Compare the outer zip SHA-256 you computed in Phase 1 against any value published in the original agent messages.
  - Flag any mismatch, missing file, extra file, or size discrepancy.
  - If a zip claims a particular sandbox ID / template ID / boot_id / creation timeline, extract those claims and list them side-by-side for later comparison.

PHASE 4 – Structural & content sanity
- Produce a unified tree: `find extract -type f | sort > 01_ALL_FILES.txt`
- Count total files, total directories, total bytes.
- Identify duplicate filenames across different Agent zips (possible collision risk).
- Extract and list the first 30 lines of every top-level README / INDEX / MANIFEST so a human can quickly see what each archive claims to contain.
- Never open or interpret binary data beyond the file command and size.

PHASE 5 – Final report
Write a single Markdown file `02_UNPACK_REPORT.md` that contains:
1. Execution environment snapshot (Phase 0)
2. Per-zip table: filename | size | outer SHA-256 | entry count | internal SHA check result | executable/script presence | extraction status
3. Any integrity failures or anomalies (highlight in bold)
4. Side-by-side comparison of claimed vs observed sandbox/template/boot IDs and creation timestamps where available
5. Exact commands that were run (so the process is reproducible)
6. Recommendation: which archives are clean and ready for further analysis, which are quarantined

Do not proceed to any analysis, summarization of the characterization reports, or execution of probes. Stop after the report is written and all extraction trees are left intact under `trixie_extract_.../`.

If any step fails a safety check, halt immediately, leave the partial tree as-is, and output only the failure reason + the inventory collected so far.

Begin now. Confirm you understand the safety rules before touching any zip.
```

---

## How to use this prompt

1. Place all `Agent*.zip` files in `/home/user/Trixie` (or current working directory).
2. Create a fresh isolated directory: `trixie_extract_$(date -u +%Y%m%d_%H%M%S)`
3. Follow phases 0-5 exactly as above.
4. Do not execute any extracted scripts.
5. Leave extraction trees intact and write final report as `02_UNPACK_REPORT.md`.

## Metadata

- Created: 2026-09-04T18:07:00Z
- Purpose: Reproduce forensic unpack safely
- Original request also included: "NO FORCE PUSH, AND NO MERGE YET, JUST COMMIT TO GITHUB & SAVE YOUR PROGRESS"
- This prompt file itself is safe to commit.

