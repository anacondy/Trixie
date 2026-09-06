# Changelog

Reorg of the Trixie forensic archive on branch `arena/01a070c2-trixie`. One line per burst.

- **Burst 0** (`7f20f44`) — Inventory of every zip (size + SHA-256) and scalable directory skeleton.
- **Burst 1** (`1e90c32`) — `git mv` Ceilings 1/2/3 into `zips/ceilings/` (temporary account labels).
- **Burst 2** (`2a6884f`) — `git mv` Egress 1/2/3 into `zips/egress/`.
- **Burst 3** (`b37f1f7`) — `git mv` Provenance 1/2/3 into `zips/provenance/`.
- **Burst 4** (`ca03f0a`) — `git mv` code-arena 1/2/3 into `zips/code_arena/`.
- **Burst 5** (`873ef8f`) — Copy verified ceilings extract into `forensic/evidence/ceilings/`.
- **Burst 6** (`9f2d05f` / `9e17695` / `4471c58`) — Copy verified egress extract (split 6/6b/6c to stay under the insertion cap).
- **Burst 7** (`1564f5d`) — Copy verified provenance extract into `forensic/evidence/provenance/`.
- **Burst 8** (`07a738f`) — Light-verify Ceilings zips (`unzip -l`/`-t`, hashes; no execution). All PASS.
- **Burst 9** (`cc4e7ac`) — Light-verify Egress and Provenance zips. All PASS.
- **Burst 10** (`7fed0a3`) — Light-verify code_arena characterization zips. All PASS.
- **Burst 11** (`792e5df`) — README, first ID comparison, gitignore `*extract*/` (labels later corrected).
- **Burst 12** (`6d9325b`) — Correct mapping to chrome=`account_a` / brave=`account_b` / edge=`account_c`; add `ACCOUNTS.md`. Outer SHA-256 deltas: 0.
- **Burst 13** (`32f9f3b`) — Place environment generation: characterizations = original; Agent zips + `forensic/evidence/environment/` + `forensic/reports/round1_environment/` = followup.
- **Burst 14** (`b6defc6`) — Split prompts into `round1/` and `forensic/`; add round2/round3 placeholders.
- **Burst 15** (`67ff35c`) — Extract code_arena evidence with credential scrub (DATABASE_URL redacted in all three accounts).
- **Burst 16** — INDEX_ALL.tsv, regenerated inventory + ID comparison (final mapping), README, this changelog.
- **Burst 17** (`f2a634c`) — Fill `vm_class` in INDEX_ALL.tsv from existing env-lock evidence only (environment mostly T, provenance mixed, egress NEW, ceilings blank, code_arena left blank pending snapshots).
- **Burst 18** (`9f00ba6`) — code_arena `vm_class=C` from the five committed `/api/env` snapshots.
- **Housekeeping** — organised user-added round2/round3 prompts into `prompts/round2/` and `prompts/round3/`; confirmed no stray `api_env_snapshot*` files on this branch root (canonical copies remain under `forensic/evidence/code_arena/{chrome,brave,edge}/`).
- **Burst 19** — Place & unpack round-3 probe archives into `zips/round3/` and `forensic/evidence/round3/`; outer SHA-256 + per-manifest file hashes + hash-of-hashes all PASS (`forensic/reports/round3/UNPACK_REPORT.md`).

