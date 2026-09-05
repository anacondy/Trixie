# Trixie

Forensic archive of Code Arena / E2B sandbox characterizations (environment, ceilings, provenance, egress, code-arena).

Working branch for this reorg: `arena/01a070c2-trixie`. Raw zips, characterization markdown, and prompt files are never overwritten. Outer SHA-256 values are recorded in `forensic/reports/summary/00_ROOT_INVENTORY.txt`.

## Account mapping

Browser token in the filename is the stable discriminator (sandbox/template IDs are shared or per-session — see `forensic/reports/summary/ID_COMPARISON_ROUND2.md`).

| Account | Browser |
|---|---|
| `account_a` | chrome |
| `account_b` | edge |
| `account_c` | brave |

## Layout

```
zips/
  environment/                 # reserved for Agent 1-9 (currently still zips/Agent *.zip)
  provenance/account_{a,b,c}/
  ceilings/account_{a,b,c}/
  egress/account_{a,b,c}/
  code_arena/account_{a,b,c}/
  benchmarks/account_{a,b,c}/  # empty
  persistence/account_{a,b,c}/ # empty
characterizations/             # round-1 *.md remain at this root; category subdirs reserved
  environment/ provenance/ ceilings/ egress/ code_arena/ benchmarks/ persistence/
prompts/
  round1/ forensic/ round2/    # reserved; existing prompts remain at prompts/ root
forensic/
  reports/
    round1_environment/        # reserved (legacy files still in forensic_reports/)
    round2_ceilings_provenance_egress/
    round2_code_arena/
    summary/
  evidence/
    environment/               # reserved; round-1 trees still at forensic/evidence/Agent *
    provenance/account_{a,b,c}/
    ceilings/account_{a,b,c}/
    egress/account_{a,b,c}/
    code_arena/account_{a,b,c}/  # empty (characterization zips not unpacked)
    benchmarks/ persistence/     # empty
```

Temporary `*_extract_YYYYMMDD_HHMMSS/` trees are left on disk for human review and are gitignored via `*extract*/` (already-tracked older extract trees stay in git).

## Verification status

Light checks only: outer SHA-256 vs burst-0 inventory, `unzip -l`, `unzip -t`, zipfile metadata (traversal / absolute path / symlink / nested zip > 10 MB / uncompressed > 50 MB). **No payload execution.**

| Family | Placement | Evidence copy | Light verify | Outer hashes |
|---|---|---|---|---|
| Ceilings 1/2/3 | `zips/ceilings/account_{a,b,c}/` | `forensic/evidence/ceilings/…` | **PASS** (burst 8) | match inventory |
| Egress 1/2/3 | `zips/egress/account_{a,c,b}/` | `forensic/evidence/egress/…` | **PASS** (burst 9) | match inventory |
| Provenance 1/2/3 | `zips/provenance/account_{b,c,a}/` | `forensic/evidence/provenance/…` | **PASS** (burst 9) | match inventory |
| code-arena 1/2/3 | `zips/code_arena/account_{b,c,a}/` | not unpacked (app skeletons) | **PASS** (burst 10) | match inventory |
| Agent 1–9 environment | `zips/Agent *.zip` | `forensic/evidence/Agent *` (round 1) | prior PR #2 | match inventory |
| benchmarks / persistence | skeleton only | skeleton only | n/a | n/a |

Quarantine: **none**.

Reports: `forensic/reports/round2_ceilings_provenance_egress/`, `forensic/reports/round2_code_arena/`, `forensic/reports/summary/`.

## Safety

Do not execute `.sh`, `.py`, `.c`, or binaries found inside zips or extract trees. Treat every zip as untrusted until outer hash + structure checks pass. Do not follow symlinks out of the repository.
