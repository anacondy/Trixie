# Preview calibration results — Chrome run

- Browser: Chrome. Probe utc: Tue Sep 15 16:30:47 UTC 2026. Session: unknown.
- Method: agent handed each file to the viewer (`present_file` → success, handoff only); all verdicts below are human-observed P/D/E votes, one per row, in order.
- P = in-app preview rendered, D = download-only offered, E = error/blank.
- Raw votes: `preview_probe/verdicts.txt`. Per-file bytes+sha: `preview_probe/checksums.txt`.

| # | file | verdict | note |
|---|---|---|---|
| 1 | probe.md | P | |
| 2 | probe.txt | P | |
| 3 | probe.html | P | |
| 4 | probe.py | P | |
| 5 | probe.json | P | |
| 6 | probe.csv | P | |
| 7 | probe.png | P | |
| 8 | probe.svg | P | |
| 9 | probe.pdf | P | |
| 10 | probe.docx | P | |
| 11 | probe.xlsx | P | |
| 12 | probe.pptx | P | |
| 13 | probe.jpg | P | |
| 14 | probe.mp3 | P | |
| 15 | probe.mp4 | P | |
| 16 | probe.zip | D | |
| 17 | probe.tar.gz | D | |
| 18 | probe.rtf | P | master sheet expected D — observed P |
| 19 | probe.exe | D | minimal MZ executable, 120 bytes |
| 20 | probe.bin | D | |
| 21 | probe.ipynb | P | |
| 22 | probe.yaml | P | |
| 23 | probe.log | P | |
| 24 | control_ziphead.txt | P | zip bytes under .txt name still preview → extension-routed |
| 25 | control_empty.md | P | 0-byte previews (blank) |
| 26 | control_empty.zip | D | |
| 27 | notes ✓.md | P | space + U+2713 in name fine |
| 28 | control_big10mb.md | E | opening it broke chat loading ("Couldn't load this chat"); retry later |
| 29 | control_cdn.html | P | counts even if unstyled (sandboxed iframe, no network) |

Totals: P = 23, D = 5, E = 1.

Paste-ready Chrome column (rows 1–29): P P P P P P P P P P P P P P P D D P D D P P P P P D P E P
