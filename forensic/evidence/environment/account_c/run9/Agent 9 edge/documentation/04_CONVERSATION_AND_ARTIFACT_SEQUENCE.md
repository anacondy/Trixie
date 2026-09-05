# Conversation and artifact sequence

1. **User prompt 1** requested systematic runtime, isolation, tooling, filesystem, network, benchmark, memory, and background-process characterization plus a Markdown report. User-message receipt time was not exposed.
2. **Initial measurements** ran from `2026-09-04T12:11:04.583543938Z` through approximately `2026-09-04T12:18:25.866920674Z`. Ad-hoc scripts and direct outputs were retained in `envchar_work/`.
3. **Initial report** `environment_characterization.md` was produced after those checks. Workspace snapshot restoration later replaced the original inode birth times of older files; embedded timestamps remain the better origin evidence.
4. **User prompt 2** required raw `.txt` transcripts, a rerunnable probe, and per-run verification manifests.
5. The canonical script was developed and syntax/quick-tested. Two development runs were deleted after testing; they are disclosed in `03_DELETED_OR_EPHEMERAL_ARTIFACTS.md`.
6. **Canonical full evidence run** `20260904T142002Z-2576` ran exactly from `2026-09-04T14:20:02.722079460Z` to `2026-09-04T14:21:11.259311599Z`, producing 14 numbered raw transcripts plus script/manifests/checksums.
7. `environment_evidence/README.md` and the earlier compact evidence ZIP were created. The report was amended at `2026-09-04T14:22:21.433118737Z` to point to the raw evidence.
8. **User prompt 3** requested this comprehensive ZIP, exact prompts, per-file explanations, creation metadata, and chronology.
9. `build_agent9_archive.py` generated archive-specific documentation, copied all persistent generated files and side-effect logs, calculated per-file SHA-256 hashes, and packed `Agent 9 edge.zip`.

For exact per-file current filesystem times and the best recoverable logical origin time, use `05_FILE_CATALOG.csv` and `06_CREATION_TIMELINE.csv`.
