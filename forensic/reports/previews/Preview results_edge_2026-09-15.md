# Edge run results — Arena in-app viewer probe sweep (2026-09-15)

HEADER: browser=Edge session=unknown utc=Tue Sep 15 16:32:24 UTC 2026
Verdicts below are **human-observed** (user answered P/D/E per row via interactive prompts; agent proved handoff only — every `present_file` returned `{"status":"success",...}`).
P = in-app preview rendered · D = download only · E = error/blank.

| # | type / control | spec-expected | Edge (this run) | notes |
|---|---|---|---|---|
| 1 | `.md` | P | **P** | |
| 2 | `.txt` | P | **P** | |
| 3 | `.html` | P | **P** | |
| 4 | `.py` | P | **P** | |
| 5 | `.json` | P (text/code) | **P** | |
| 6 | `.csv` | P | **P** | |
| 7 | `.png` | P | **P** | |
| 8 | `.svg` | P | **P** | spec-only type → confirmed previewable |
| 9 | `.pdf` | P | **P** | hand-built minimal PDF previews fine |
| 10 | `.docx` | P | **P** | |
| 11 | `.xlsx` | P | **P** | |
| 12 | `.pptx` | P | **P** | |
| 13 | `.jpg` | P | **P** | |
| 14 | `.mp3` | P | **P** | 2 s silence by design; player controls rendered |
| 15 | `.mp4` | P | **P** | libx264 via imageio-ffmpeg, 2 s |
| 16 | `.zip` | D | **D** | |
| 17 | `.tar.gz` | D | **D** | |
| 18 | `.rtf` | D | **P** | ⚠ FINDING: RTF previews in-app, spec expected download-only |
| 19 | `.exe` | D | **D** | hand-built PE32 (1536 B, `file`-verified; runtime untested — no Windows here) |
| 20 | `.bin` | D | **D** | |
| 21 | `.ipynb` | D?/P? | **P (as JSON/code)** | ⚠ FINDING: routes to text/code preview, no notebook renderer |
| 22 | `.yaml` | D?/P? | **P** | text routing confirmed |
| 23 | `.log` | D?/P? | **P** | text routing confirmed |
| 24 | zip-bytes as `.txt` | P vs D | **P** | ⚠ FINDING: extension-based routing, NOT content sniffing (binary gibberish previewed as text) |
| 25 | 0-byte `.md` | P?/E? | **P** | empty card rendered gracefully |
| 26 | 0-byte `.zip` | D?/E? | **D** | |
| 27 | space+non-ASCII `.md` | P | **P** | file was `control_probe ünïcødé spàce.md` (accented chars instead of `notes ✓.md`; same test) |
| 28 | ~10 MB `.md` | P(trunc?)/E | **E? — DEFERRED** | presenting it coincided with chat page failure: "We couldn't load this chat" Trace ID: 137b693d-daa8, Visit ID: 01a0a5e7-b58f-77ec-8820-34431d219455. Chat-infra error, not a clean viewer verdict; user deferred — retry pending |
| 29 | `.html` + CDN css | P unstyled | **P** | unstyled degrade (sandbox no-network) — counts as P per instructions |

## Findings summary (Edge)
1. **18/19 spec-P rows confirmed P.** Everything spec-claimed previewable rendered.
2. **`.rtf` = P** (row 18) — spec expected D. Spec column needs updating (pending Chrome/Brave agreement check).
3. **`.ipynb` = P as raw JSON/code** (row 21) — no dedicated notebook renderer.
4. **Routing is by extension, not content** (row 24) — zip bytes in a `.txt` still got a text preview.
5. **Empty-file UX graceful** (rows 25–26): empty `.md` → empty card; empty `.zip` → download only.
6. **Unicode+space filenames fine** (row 27).
7. **~10 MB row unresolved** (row 28) — chat load error on presentation; needs retry to separate viewer behavior from chat infra.

## Run provenance
- Pack: `preview_probe/` (29 probes, 9.7 MB), generated this session; binaries built with real encoders (Pillow, python-docx, openpyxl, python-pptx, libx264+libmp3lame via imageio-ffmpeg, zipfile/tarfile); PDF and PE32 hand-built minimal (structure-verified with `file`).
- Integrity: per-file bytes + sha256 in `preview_probe/checksums.txt`; `unzip -l` and `tar tzf` passed for archives.
