# Prompt — human y/n verdict collection for the in-app viewer
Paste into EACH run (separate sessions/browsers). Replace `<BROWSER>` before sending. The agent hands files over; YOU are the judge. After the run, paste back the printed sheet filled with y/n/e plus the header line, and I consolidate.

```text
Browser for this run: <BROWSER>   (chrome / brave / edge)

You are a handoff runner, not a judge. Goal: let a human calibrate what the
Arena in-app viewer previews vs downloads. You can generate, verify, and hand
files to the viewer; you CANNOT observe rendering. A successful present_file
proves handoff only — never write or imply that a preview rendered.

Step 0 — Header. Print exactly: browser (the value above), UTC timestamp
(date -u), session id if visible to you, else "unknown".

Step 1 — Probe set.
(a) If preview_probe/ from a prior run exists with checksums.txt, reuse it.
(b) Else generate the standard pack in preview_probe/: one valid probe per
extension .md .txt .html .py .json .csv .png .svg .pdf .docx .xlsx .pptx
.jpg .mp3 .mp4 .zip .tar.gz .rtf .bin .ipynb .yaml .log, each containing
"PROBE <ext> OK" + the Step-0 timestamp; build binaries with real encoders
(zipfile/tarfile/Pillow/python-docx/openpyxl/python-pptx; hand-built minimal
PDF/MP3/MP4 if no tooling); never fake a probe by renaming. Plus controls:
first 300 bytes of a valid zip saved as .txt; 0-byte .md; 0-byte .zip;
filename with a space and a non-ASCII char (.md); ~10 MB .md; .html linking
one CDN stylesheet (expect graceful unstyled degrade in-app).
(c) REAL ARTIFACTS: also add up to 12 rows R01..R12 for files THIS session
already produced, covering as many distinct extensions as exist (e.g. .md
docs, .c/.h, .sh, .py, .bat, .cmd, .txt, .cmake/CMakeLists, built PE .exe,
logs). Use their real paths; do not copy them.

Step 2 — Integrity. For every row print: n | path | bytes | sha256(16) |
mime (file --mime-type -b). Archives must also pass unzip -l / tar tzf.
Controls may mismatch MIME by design; note them.

Step 3 — Handoff. Call present_file once per row, in numeric order, and
print the verbatim tool response after each call. One row at a time.

Step 4 — Human sheet. Print this block LAST, with every Y/N blank, then
STOP and wait. Do not fill it, do not summarize rendering.

HEADER: browser=<BROWSER> session=<id/unknown> utc=<ts>
< n > < path >  Y/N: ___   (y = in-app preview rendered, n = download only
offered, e = error/blank)
[one line per row]
Human instructions: open each row in the viewer in the order presented;
write y/n/e; for the CDN row, y counts even if unstyled; for the ~10 MB
row, y counts even if truncated (add t); then paste the filled sheet back
to the orchestrating session.

Constraints: create no more than ~60 MB total; delete nothing outside
preview_probe/; no claims about rendering anywhere in your output.
```
