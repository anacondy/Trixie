# Brave run — viewer verdicts (filled live, 2026-09-15)
HEADER: browser=Brave session=ie5tmq8jibvyinh0363wa utc=Tue Sep 15 16:29:55 UTC 2026

| # | file | verdict | note |
|---|------|---------|------|
| 01 | probe.md   | P | rendered as Markdown |
| 02 | probe.txt  | P | text shown |
| 03 | probe.html | P | page rendered |
| 04 | probe.py   | P | code view shown |
| 05 | probe.json | P | rendered as formatted/syntax-highlighted code |
| 06 | probe.csv  | P | rendered as a TABLE (header + 2 rows) |
| 07 | probe.png  | P | image rendered |
| 08 | probe.svg  | P | rendered as a drawn image (not XML source) |
| 09 | probe.pdf  | P | document rendered |
| 10 | probe.docx | P | document rendered |
| 11 | probe.xlsx | P | TEXT ONLY - values readable, no spreadsheet grid (spec said P grid) |
| 12 | probe.pptx | P | slides rendered, slide 2 reachable |
| 13 | probe.jpg  | P | image rendered |
| 14 | probe.mp3  | P | audio player with controls |
| 15 | probe.mp4  | P | video player, plays |
| 16 | probe.zip  | D | download only (matches spec expectation) |
| 17 | probe.tar.gz | D | download only (matches spec) |
| 18 | probe.rtf  | P | RAW SOURCE shown ({\rtf1\ansi...} visible), not formatted - finding |
| 19 | probe.bin  | D | download only (matches spec) |
| 20 | probe.ipynb | P | RAW JSON shown, not a notebook render - routing = JSON - finding |
| 21 | probe.yaml | P | text/code shown |
| 22 | probe.log  | P | text shown |
| 24 | control_empty.md | P | opened, shows nothing (empty card, no error) |
| 23 | control_truncated_zip_as_txt.txt | P | GARBLED TEXT SHOWN - routes by EXTENSION, not content - finding |
| 25 | control_empty.zip | (skipped) | question dismissed, not answered |
| 26 | control spaced unicode.md | (skipped) | question dismissed, not answered |
| 27 | control_large_10mb.md | (skipped) | question dismissed, not answered |
| 28 | control_cdn.html | (skipped) | question dismissed, not answered |
| 27 | control_large_10mb.md | E/crash | 10,000,006 B / 93,464 lines - CRASHED THE CHAT UI REPEATEDLY per user; file NOT re-opened. Finding: ~10 MiB markdown is not survivable in-app |
| 25 | control_empty.zip | D | download only |
| 26 | control spaced unicode.md | P | content + filename both correct |
| R12 | artifacts/probe.exe | INVISIBLE | present_file returned success but NO FILE CARD APPEARED in chat - user: "i cant see this file" |
| 27b | 10MB crash detail | crash | "Something went wrong / We couldn't load this chat. Please try again. Trace ID: 41aa15f4-5cfaG / Visit ID: 01a0a5d3-565c-763e-af65-52d07f32331d / Try again / Still not working? Reset session and reload" - required browser page refresh |

## A/B test - three byte-identical PE files, different extensions
all three: 1536 B, sha256(16)=0d41ef0ae744a999, file(1)=application/vnd.microsoft.portable-executable
cmp: identical bytes, only the filename differs.

| name | present_file | card in chat | card said |
|---|---|---|---|
| artifacts/probe.exe | success | NOT SEEN (user, twice) | - |
| artifacts/probe_same_bytes.bin | success | unconfirmed | - |
| artifacts/probe_same_bytes.dat | success | YES | "1.5 KB - application/octet-stream - This file type cannot be previewed in the workspace viewer." = D |

Note: the viewer labelled .dat as application/octet-stream, while file(1) on the
same bytes says application/vnd.microsoft.portable-executable. The viewer
classifies by EXTENSION, consistent with the row-23 zip-named-.txt finding.
| R12 | artifacts/probe.exe | D | download-only card DID appear on re-present ("cannot be previewed") |
| A/B | probe_same_bytes.bin in a batch of 3 | NO CARD | dropped |
| A/B | probe_same_bytes.bin presented ALONE | CARD | appeared - "cannot be previewed in the workspace viewer" |

## FINDING (CORRECTED 2026-09-15): visibility was navigation, not dropped cards
User screenshots show the viewer is a SINGLE-FILE panel with a dropdown
workspace tree; artifacts/ was collapsed so nested files were not visible
until expanded, and after a batch only the last file is shown. So the
differences were navigation, not delivery. present_file success is real but
does not tell the agent which file the human has open.
