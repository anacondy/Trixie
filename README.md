# Trixie

Forensic archive of Code Arena / E2B sandbox characterizations.

Working branch: `arena/01a070c2-trixie`. Raw zips, original characterisation markdown, and original prompt files are never overwritten. Outer SHA-256 values: `forensic/reports/summary/00_ROOT_INVENTORY.txt`. Per-zip index: `forensic/reports/summary/INDEX_ALL.tsv`.

## Account mapping

Browser string in filenames is ground truth; `account_*` labels are aliases. Full table: `ACCOUNTS.md`.

| account | browser | acctN | env run numbers |
|---|---|---|---|
| account_a | chrome | 1 | 1, 4, 5 |
| account_b | brave | 2 | 2, 3, 6 |
| account_c | edge | 3 | 7, 8, 9 |

## Two-axis taxonomy

**Generation × category.** Environment spans two generations.

| | environment | provenance | ceilings | egress | code_arena | benchmarks | persistence |
|---|---|---|---|---|---|---|---|
| **original** | `characterizations/environment/*.md` | — | — | — | — | — | — |
| **followup** | Agent zips + `forensic/evidence/environment/` + `forensic/reports/round1_environment/` | — | — | — | — | — | — |
| **new_sessions** | — | zips + evidence | zips + evidence | zips + evidence | zips + evidence | empty | empty |

## Layout

```
zips/
  environment/account_{a,b,c}/     # Agent 1-9 (followup)
  provenance/account_{a,b,c}/
  ceilings/account_{a,b,c}/
  egress/account_{a,b,c}/
  code_arena/account_{a,b,c}/
  benchmarks/account_{a,b,c}/      # empty
  persistence/account_{a,b,c}/     # empty
characterizations/
  environment/                     # original *.md
  provenance/ ceilings/ egress/ code_arena/ benchmarks/ persistence/   # empty
prompts/
  round1/                          # ORIGINALwork / Verification / Zipping
  forensic/                        # FORENSIC_UNPACK_PROMPT.md
  round2/                          # placeholder README
  round3/                          # placeholder README
forensic/
  reports/
    round1_environment/            # followup unpack reports
    round2_ceilings_provenance_egress/
    round2_code_arena/
    summary/                       # inventory, INDEX_ALL.tsv, ID comparison
  evidence/
    environment/account_{a,b,c}/runN/
    provenance/ ceilings/ egress/ code_arena/account_{a,b,c}/
    benchmarks/ persistence/       # empty
```

Temporary `*_extract_*` trees are left on disk for human review (`*extract*/` in `.gitignore`). Already-tracked older extract trees remain in git.

## Verification status

Light checks: outer SHA-256, `unzip -l`, `unzip -t`, zipfile metadata. **No payload execution.**

| Family | Placement | Evidence | Light verify | Outer hashes |
|---|---|---|---|---|
| Environment Agent 1–9 | `zips/environment/account_{a,b,c}/` | `forensic/evidence/environment/…/runN` | PR #2 + burst 13 re-hash | match inventory |
| Ceilings 1/2/3 | `zips/ceilings/…` | copied | **PASS** (burst 8) | match |
| Egress 1/2/3 | `zips/egress/…` | copied | **PASS** (burst 9) | match |
| Provenance 1/2/3 | `zips/provenance/…` | copied | **PASS** (burst 9) | match |
| code_arena 1/2/3 | `zips/code_arena/…` | extracted + scrubbed | **PASS** (burst 10/15) | match |
| benchmarks / persistence | skeleton | skeleton | n/a | n/a |

Quarantine: **none**. code_arena `drizzle.config.json` DATABASE_URL redacted to `[REDACTED – scheme+host only]`.

## Safety

Do not execute `.sh`, `.py`, `.c`, or binaries found inside zips or extract trees.
