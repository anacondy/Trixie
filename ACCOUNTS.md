# Account mapping

Browser string in filenames is ground truth; account_* labels are stable aliases used throughout the project.

| account | browser | acctN | env run numbers | note |
|---|---|---|---|---|
| account_a | chrome | 1 | runs 1, 4, 5 | chrome zips and Agent 1/4/5 |
| account_b | brave | 2 | runs 2, 3, 6 | brave zips and Agent 2/3/6 |
| account_c | edge | 3 | runs 7, 8, 9 | edge zips and Agent 7/8/9 |

Burst 12 hash check of all 12 round-2 zips after the account_b ↔ account_c directory swap: **zero SHA-256 deltas** vs `forensic/reports/summary/00_ROOT_INVENTORY.txt`.
