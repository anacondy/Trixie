# Agent 9 edge — read this first

## What this ZIP contains

This is the comprehensive evidence package requested in user prompt 3. It contains:

- The final characterization report.
- All retained initial raw notes, TSV/JSON results, and ad-hoc probe scripts under `payload/home/user/envchar_work/`.
- The canonical rerunnable probe and its full run under `payload/home/user/environment_evidence/`.
- All 14 numbered, direct stdout/stderr `.txt` transcripts (`01_runtime.txt` through `14_persistence.txt`).
- Per-run manifests containing UTC timestamps, sandbox ID, template ID, raw-file SHA-256 hashes, and the frozen script hash.
- The earlier compact evidence ZIP and its checksum.
- Relevant persistent side effects: npm cache/log files, sudo-success marker, and persistence sentinel.
- The exact three user prompts as received by the assistant.
- A per-file catalog, creation timeline, important machine/provenance metadata, deleted-artifact disclosure, and archive-wide checksums.
- The exact Python builder used to assemble this archive.

## Important identity

- Requested filename: `Agent 9 edge.zip`
- Packaging began (UTC): `2026-09-04T14:31:48.936310Z`
- Packaging began (IST): `2026-09-04T20:01:48.936310+05:30`
- Sandbox ID: `ixwcucmrk55t9qy240sxo`
- Template ID: `wvhxjiyesoij1nccqrqk`
- Canonical evidence run: `20260904T142002Z-2576`
- Canonical probe SHA-256: `870774e553380dd881964cfb09cc74871349e8b3b3ac2d00a53214022568046b`

## Directory layout

```text
Agent 9 edge/
├── 00_READ_ME_FIRST.md
├── documentation/
│   ├── 01_USER_PROMPTS_EXACT.txt
│   ├── 02_IMPORTANT_METADATA.json
│   ├── 03_DELETED_OR_EPHEMERAL_ARTIFACTS.md
│   ├── 04_CONVERSATION_AND_ARTIFACT_SEQUENCE.md
│   ├── 05_FILE_CATALOG.csv
│   ├── 06_CREATION_TIMELINE.csv
│   ├── 07_ARCHIVE_FILE_LIST.txt
│   └── SHA256SUMS.txt
└── payload/home/user/
    ├── environment_characterization.md
    ├── envchar_work/
    ├── environment_evidence/
    ├── .npm/
    ├── .environment_characterization_persistence_probe
    ├── .sudo_as_admin_successful
    ├── build_agent9_archive.py
    └── earlier compact evidence ZIP + sidecar
```

## What every file does

`documentation/05_FILE_CATALOG.csv` has one row for every copied payload file and every non-self-referential documentation file. Each row supplies source/archive path, purpose, size, SHA-256, current inode birth/mtime/ctime, logical evidence time, and timestamp-fidelity notes. `documentation/06_CREATION_TIMELINE.csv` presents the same records in recoverable chronological order.

Archive-control files are necessarily handled separately to avoid recursive self-description:

| File | Purpose |
|---|---|
| `05_FILE_CATALOG.csv` | Per-file purpose, path, size, hash, exact current filesystem times, best logical origin time, and timestamp-fidelity caveat. |
| `06_CREATION_TIMELINE.csv` | Catalog records reordered into the best recoverable creation sequence. |
| `07_ARCHIVE_FILE_LIST.txt` | Pre-pack member path, byte size, and SHA-256 listing. |
| `08_ARCHIVE_BUILD_LOG.txt` | Builder start time, source/catalog counts, staging/output paths, and pack method. |
| `SHA256SUMS.txt` | GNU-compatible checksum index for every other archive member; it cannot hash itself. |

These control files are all listed in the ZIP central directory with their stored modification times. Every control file except `SHA256SUMS.txt` is itself covered by `SHA256SUMS.txt`.

## Timestamp caveat

For files from the first characterization, workspace snapshot restoration reset current inode birth times to around 14:15 UTC. It is impossible to recover an exact original inode birth time after that reset. This archive does not fabricate one: it records the exact current inode times and separately records embedded command timestamps / known phase order, with an explicit fidelity field. Files from the canonical full run have exact run-manifest and current inode timing.

The API did not expose exact user-message receipt timestamps. Prompt order and text are exact; prompt times are explicitly marked unavailable.

## Verification

From the extracted `Agent 9 edge/` directory:

```bash
sha256sum -c documentation/SHA256SUMS.txt
```

`SHA256SUMS.txt` intentionally cannot hash itself. The outer ZIP's SHA-256 is written beside the archive as `Agent 9 edge.zip.sha256` after packaging.

## Self-inclusion limitation

A ZIP cannot contain its final own bytes or final own checksum without recursion. Therefore `Agent 9 edge.zip` and its external checksum sidecar are not members of themselves. The earlier compact evidence ZIP is included because it existed before this archive was assembled.
