# Master verdict sheet — Arena in-app viewer (2026-09-15, all three browsers filled)

Session↔browser mapping (user-corrected 2026-09-15; re-confirmed by URL bars in this batch's screenshots): **Chrome = 01a0a5e7-a61d-7b89-8dcd-b24434dcf755 · Edge = 01a0a5e7-ed7b-79a1-a97b-c4ad210d8422 · Brave = 01a0a5e7-0792-754e-9df8-afa9902a9370**.
Sources (all human-observed votes): Edge = `uploads/results_edge_2026-09-15.md`; Chrome = `uploads/preview_results Chrome.md`; Brave = `uploads/BRAVE_MASTER_FILLED (1).md`. Verdicts: **P** preview / **D** download-only / **E** error-crash. ⚠ = deviates from spec-expected. Per-run integrity lives in each session's `preview_probe/checksums.txt`. **Provenance (verified 2026-09-16 from Trixie repo commits `43998e486e` + `1333e3acb1`, downloaded raw and checked locally):** Chrome zip SHA-256 `00c21c7663f3793c1b6adfa5fcc937b77df3f04f8227218dc376747cd2b56813` (matches the occluded screenshot print; hidden bytes were `fcc937b`), internal SHA256SUMS 36/36 OK; Edge zip `67e75e2a9af2c19e274073f3b3e8e2c2b4cd1106d84f8b2fefa608c3a1e3c5d1`, MANIFEST.sha256 all OK; Brave zip `4c495dae5c27bbb0aadf377b91da308eb6afec8a4397fb77487237aadb5ae932`, MANIFEST.sha256 all OK. Chrome results md identical repo↔upload↔bundle; Edge results identical repo↔upload; Brave sandbox ID `ie5tmq8jibvyinh0363wa` (from bundle METADATA); Chrome/Edge session IDs unknown to their agents. Local copies under `trixie_preview/`.

| # | type / control | spec-expected | Edge | Chrome | Brave | cross-browser outcome |
|---|---|---|---|---|---|---|
| 1 | `.md` | P | P | P | P | unanimous; Markdown rendered |
| 2 | `.txt` | P | P | P | P | unanimous |
| 3 | `.html` | P | P | P | P | unanimous; page rendered |
| 4 | `.py` | P | P | P | P | unanimous; code view |
| 5 | `.json` | P | P | P | P | unanimous; formatted/highlighted |
| 6 | `.csv` | P | P | P | P | unanimous; Brave: real TABLE (header+2 rows) |
| 7 | `.png` | P | P | P | P | unanimous |
| 8 | `.svg` | P | P | P | P | unanimous; drawn as image, not XML |
| 9 | `.pdf` | P | P | P | P | unanimous; document rendered |
| 10 | `.docx` | P | P | P | P | unanimous |
| 11 | `.xlsx` | P | P | P | P ⚠? | all P, but Brave notes TEXT ONLY, no grid; Chrome/Edge sheets silent — see flag F1 |
| 12 | `.pptx` | P | P | P | P | unanimous; Brave: slide 2 reachable |
| 13 | `.jpg` | P | P | P | P | unanimous |
| 14 | `.mp3` | P | P | P | P | unanimous; player w/ controls |
| 15 | `.mp4` | P | P | P | P | unanimous; plays |
| 16 | `.zip` | D | D | D | D | unanimous |
| 17 | `.tar.gz` | D | D | D | D | unanimous |
| 18 | `.rtf` | D | P ⚠ | P ⚠ | P ⚠ | unanimous: previews as RAW SOURCE `{\rtf1\ansi…` — no RTF interpreter; spec expectation wrong |
| 19 | `.exe` | D | D | D | D | unanimous; Brave caveat: first present not visible to human, valid D card on re-present (see F2: navigation, not drop) |
| 20 | `.bin` | D | D | D | D | unanimous |
| 21 | `.ipynb` | D?/P? | P ⚠ | P | P ⚠ | unanimous raw JSON (cells/nbformat), no notebook renderer |
| 22 | `.yaml` | D?/P? | P | P | P | unanimous text/code |
| 23 | `.log` | D?/P? | P | P | P | unanimous text |
| 24 | zip-bytes as `.txt` | P vs D | P ⚠ | P  | P  | unanimous GARBLED TEXT ⇒ **extension routing, no content sniffing** |
| 25 | 0-byte `.md` | P?/E? | P | P | P | unanimous: opens, blank/empty view, no error |
| 26 | 0-byte `.zip` | D?/E? | D | D | D | unanimous download-only |
| 27 | unicode+space `.md` | P | P | P | P | unanimous; filename glyphs displayed correctly |
| 28 | ~10 MB `.md` | P(trunc?)/E | deferred | **E** | **E** | Chrome: opening it broke chat loading; Brave: hard crash, Trace 41aa15f4-5cfa, user skipped re-tries ("crashing again & again"); Edge retry pending ("retry 28") |
| 29 | `.html` + CDN css | P unstyled | P (DISPUTED) | P | pending | Chrome human: unstyled, "counts even if unstyled (sandboxed iframe, no network)"; Edge styled-looking screenshot remains the outlier; Brave about to present solo |

Totals — Edge: P23 D5 deferred1 · Chrome: P23 D5 E1 · Brave: P22 D5 E1 +row29 pending. Unanimous verdicts on every row that has three votes.

## Flags & open items
- **F1 (row 11 xlsx):** Brave is the only sheet recording "TEXT ONLY, no spreadsheet grid". Same human judged all three runs, so either rendering differed per browser or only the Brave pass noted it. Resolve by memory or one re-present per browser.
- **F2 (card visibility — CORRECTED 2026-09-16, supersedes my "batch drops cards" framing):** the Brave bundle's own `BRAVE_RESULTS.md` tail carries "FINDING (CORRECTED 2026-09-15): visibility was navigation, not dropped cards" — the viewer is a SINGLE-FILE panel; after a batch only the LAST presented file is shown; `artifacts/` was collapsed in the dropdown tree so nested files weren't visible until expanded. The user's own intuition ("some of them are in this artifacts folder… not visible to me at first") was right; the agent's first-pass "batch drops cards" conclusion (which I relayed last turn) was over-read from the same observations. Residual "delivery drop" is now UNPROVEN, not demonstrated. Practical rule unchanged: present one file per turn and have the human open each row explicitly from the dropdown; `present_file` success tells the agent nothing about which file the human sees.
- **F3 (row 28 crash):** 10 MB file is a SUFFICIENT trigger (Chrome+Brave both crashed on/after it) but NOT necessary (Edge crashed elsewhere with a small file open) ⇒ two overlapping failure classes: generic chat-load flakiness + 10MB-induced crash loop. User's auto-open hypothesis fits the loop ("again & again"); discriminator (open tiny file last / close viewer, then refresh) still pending. **Row 28 CLOSED by user decision 2026-09-24 — no further retries; the crash behaviour itself is the finding.**
- **F4 (row 29):** canary re-test (html embedding a table+link that water.css unmistakably styles) still proposed to settle the Edge styled-looking outlier; Brave's solo present will add the third datapoint.

Already human-observed elsewhere: `.c`/`.h` = P (timekeeper PLAIN cards).
