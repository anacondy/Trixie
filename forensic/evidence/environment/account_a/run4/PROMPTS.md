# Prompts — verbatim record

Scope of this file: the user prompts that produced everything in this archive, and an explicit
statement of which ones I hold **verbatim** versus **reconstructed**. I have not silently
paraphrased a prompt and labelled it verbatim; the distinction is marked per entry.

Precision note: the requester's messages arrived as HTML-escaped text (`&amp;` for `&`). Prompts
reproduced below are de-escaped, which is the only normalization applied. Quotation-mark
characters and wording are otherwise unchanged for entries marked VERBATIM.

---

## Prompt 1 — the original task  ·  STATUS: reconstructed (condensed), not verbatim

The conversation history available to me for this turn was compacted into a session summary, so
the exact wording of the first message is not recoverable from my context. What follows is the
task specification as recorded in that summary — faithful in content, not in phrasing.

> Setting up a long-running research + data pipeline (mixed CPU work, network I/O, package
> installs, file processing) and need serious environment characterization before committing real
> code or data. Required checks:
>
> 1. **Runtime & isolation** — exact OS/kernel/arch/libc; containerization/VM/sandbox signals
>    (cgroup, `/.dockerenv`, mount info, process tree, capabilities, seccomp); user/uid/gid/sudo/
>    root; resource limits (ulimit, cgroup memory/cpu, pids).
> 2. **Tooling** — availability and versions of python3, pip, node, npm, git, curl, wget, ffmpeg,
>    docker, make, gcc/clang, jq, etc.; which package managers work and can actually install;
>    whether pure-python packages, system packages, and compilation work.
> 3. **Filesystem & persistence** — cwd/home/`/tmp` behaviour, free disk and inodes, read-only
>    mounts/protected paths, write+read+delete tests in several locations, whether files survive
>    across sessions.
> 4. **Network characterization** — real measurements, not "can I connect": DNS resolution speed;
>    latency and rough throughput to at minimum google.com/8.8.8.8, github.com, pypi.org,
>    huggingface.co, plus a large multi-MB download; timeouts/blocks/captive portals/asymmetric
>    performance; restricted outbound ports or protocols.
> 5. **Performance micro-benchmarks**, short but accurately timed — pure-Python CPU
>    `sum(range(10**7))` plus a heavier loop or numpy; disk sequential write+read of a 50–100 MB
>    file; a small pip install time; anything anomalously fast or slow.
> 6. **Other** — memory-pressure behaviour, background/long-running tasks, anything that hangs or
>    is surprisingly restricted, sandbox-related environment variables or injected config.
>
> Deliverable: a clean Markdown file named like `environment_characterization.md`, with an
> executive summary (2–4 sentences), sections matching the categories, tables for tool
> availability+versions and network latency/throughput and benchmark timings, and raw notes/outputs
> in a collapsible or clearly marked appendix, plus clear statements of what is fast, what is slow,
> and what the hard limitations are. Prefer real measured data over guesses; precise numbers with
> units and measurement method.

Standing constraints from the same message, as recorded:

- Treat this as serious environment characterization work; be systematic; keep notes as you go.
- Run real measurements, not connectivity assertions ("not just 'can I connect'").
- Benchmark tests must be short but timed accurately.
- Do not commit any real code or data — characterization only.
- Produce the final Markdown report only after finishing all checks.

---

## Prompt 2 — the auditability follow-on  ·  STATUS: reconstructed (condensed), not verbatim

Also inside the compacted region, so wording is not recoverable; the requirements are recorded as:

> The evidence must be independently auditable.
>
> - **Publish the raw `.txt` outputs, not just the reports** — verbatim transcripts with no LLM
>   summarisation layer are the primary evidence; produce them if they don't already exist.
> - **Ship the probe script** so a third party runs *my* script and diffs the output.
> - **Verification manifest per run:** timestamp, sandbox ID, template ID, SHA-256 of raw files.

The first premise-check performed against this prompt (recorded because it decided the work): the
filenames `01_runtime.txt` and `09_net_matrix.txt` were grepped for in the report and appeared
**nowhere**, and the ten `.txt` files that did exist were narrow single-command `tee` fragments —
confirming that full per-section transcripts genuinely did not yet exist and had to be produced.

---

## Prompt 3 — this archive  ·  STATUS: verbatim

> now zip all of these files ? & save the zip as Agent 4 chrome.zip , with all the files u have
> created , explaining, what the zip has, & what every file does, & when it was created , exact time
> & date & in sequence, which file was created when & also with the exact prompts i gave u , each
> time, & any imp metadata, that can be helpful

Requirements derived from it, each of which is satisfied by a specific artifact in this archive:

| Requested | Where it is answered |
|---|---|
| zip everything | `Agent 4 chrome.zip` itself (built by `envcheck/make_bundle_zip.py`) |
| name it `Agent 4 chrome.zip` | filename preserved exactly, spaces included |
| explain what the zip has | `README_START_HERE.md` §"What this archive contains" |
| what every file does | `README_START_HERE.md` §"File-by-file" (one row per file, generated from the actual file list) |
| when it was created, exact time & date | `TIMELINE.csv` + the timeline table: birth time to 6 decimal places, UTC and IST |
| in sequence, which file was created when | `TIMELINE.csv` sorted ascending by creation instant; the archive's zip entry order is that same sequence |
| exact prompts given, each time | this file, with verbatim-vs-reconstructed marked per entry |
| any important metadata | `README_START_HERE.md` §"Metadata" and `ZIP_METADATA.json` |

---

## Honest limits of this record

1. **Prompts 1 and 2 are reconstructions.** If you need their exact wording, it is in your chat
   history, not in this sandbox — there is no conversation log on disk here (checked:
   `/home/user`, `/tmp` contain no transcript/history file; only `envcheck/` and the report).
2. **Filesystem creation times are "instant of materialization in this sandbox instance."** Files
   authored in earlier turns were restored from a workspace snapshot at
   `2026-09-04 13:44:24.468 UTC`, so their recorded birth time is that restore, not the moment I
   typed them. Anything created *during this turn* (13:47 onward) has a true, nanosecond birth
   time. `README_START_HERE.md` marks which is which per file.
3. **The guest clock is not monotonic here.** It steps forward when the microVM resumes between
   tool calls, so cross-checking a file's mtime against a timestamp printed in another call can be
   misleading. Provenance in this bundle therefore relies on the `run_id` header embedded in each
   transcript, and on `MANIFEST.txt`.
