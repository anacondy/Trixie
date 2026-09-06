# Burst 19 — Round-3 probe unpack (verification + placement only)

**When:** 2026-09-06  
**Scope:** place the three `probe3_evidence *.zip` archives, extract, recompute every manifest-listed file hash and each tree's hash-of-hashes by that manifest's own stated method.  
**Not done:** payload execution, package install, analysis of characterization content, README/INDEX updates.  
**Safety:** `unzip -t` then `unzip -n` only. No archived `.sh`/`.py`/binary was executed. Nothing installed. No path traversal, absolute paths, or symlinks in any archive.

Account mapping (browser string is ground truth): chrome = `account_a`, brave = `account_b`, edge = `account_c`.

Placement:

| Zip (name preserved) | Outer bytes | Moved to | Extracted to |
|---|---:|---|---|
| `probe3_evidence chrome.zip` | 58838 | `zips/round3/` | `forensic/evidence/round3/account_a/` |
| `probe3_evidence brave.zip` | 26059 | `zips/round3/` | `forensic/evidence/round3/account_b/` |
| `probe3_evidence edge.zip` | 35503 | `zips/round3/` | `forensic/evidence/round3/account_c/` |

Internal names preserved (`probe3/…`). Nothing renamed.

---

## Per-zip summary

| Zip | Outer SHA-256 (recomputed) | vs expected | `unzip -l` entries (files/dirs) | Manifest-listed | Per-file | HH expected | HH recomputed | HH |
|---|---|---|---|---:|---|---|---|---|
| chrome / account_a | `b5580da4f4fb8ff10c2fed1b8ad7013d0c94eca0ba4dad1d435b479a6fecab6a` | MATCH | 37 (35/2) | 26 | **26 PASS / 0 FAIL** | `8c2822c01dc1211bd14a005468500398f748c1b46642e3eb0bbac102851c5483` | `8c2822c01dc1211bd14a005468500398f748c1b46642e3eb0bbac102851c5483` | **PASS** |
| brave / account_b | `0599cf708d26185f44ca9c401375f510bbe3edf1369c7e43a4b3427078f0dd1b` | MATCH | 40 (38/2) | 32 | **32 PASS / 0 FAIL** | `822db84cd2dd93f007a8af412b6e784e18abd59c4f38d30e724d6c9e2c779cb5` | `822db84cd2dd93f007a8af412b6e784e18abd59c4f38d30e724d6c9e2c779cb5` | **PASS** |
| edge / account_c | `9c8a596de81013188310dcfbdf09b8571a7446dc78f5c74a57c93692549f10a2` | MATCH | 47 (45/2) | 38 | **38 PASS / 0 FAIL** | `e4737d2fde8c5630732becb8c601ffc1a5579707e28b70d5ca8030fa45197e47` | `e4737d2fde8c5630732becb8c601ffc1a5579707e28b70d5ca8030fa45197e47` | **PASS** |

`unzip -t`: all three **OK**. Quarantine: **none**.

---

## Manifest-format notes

Each tree ships `probe3/manifest3.txt`. Formats are **not** the same.

### chrome (`account_a`)

- Header comments (`generated_utc`, sandbox/template/boot IDs, C1 mtime warning).
- Body columns: `sha256  bytes  content_write_time_utc  path` (four fields).
- Coverage (from bundled `make_manifest.sh`, read as text, **not executed**): `ls [0-9][0-9]_*.txt d5/*.txt c1_probe.txt | sort` — 26 raw txt files. Scripts and `results3.json` are **not** listed.
- Stated HH method (footer + script): `sha256` of the newline-joined per-file digests **in listed order** (trailing newline). `n_files=26`.
- Recomputed HH matches expected.

### brave (`account_b`)

- No header comments. Body is `sha256sum` two-space lines: `hash  name`.
- 32 numbered `NN_*.txt` files, then a `---` separator and:
  `HASH-OF-HASHES (sha256 of the sorted per-file sha256 lines above):`
- Scripts under `probe3/scripts/` and `result_probe3.json` are **not** listed.
- Recomputed HH matches expected when hashing the listed `hash  name` lines **in listed order** (already filename-sorted) with a trailing newline. See variance note on the word "sorted".

### edge (`account_c`)

- Header comments: `recorded_utc`, `method: sha256sum per raw file; hash-of-hashes = sha256 of sorted '<hash>  <name>' lines`, claimed `HASH-OF-HASHES`, `files: 38`.
- Body: `sha256sum` two-space lines for 38 raw `NN_*.txt` files (including `28_d5_p1`…`p8`).
- `src/*.py` and `probe3.json` are **not** listed.
- Trailing `# SELF-SHA256(manifest3.txt): b9a55b1ea8a4202f1250daa69569150e32ab0b954420f968ea5b7d6b94df6391`.
- Recomputed HH matches expected when hashing the listed `hash  name` lines in listed (filename) order with a trailing newline. See variance note on "sorted" and on SELF-SHA256.

---

## Per-file PASS/FAIL

Hashes recomputed with SHA-256 of file bytes on disk after extract. Chrome also checks listed byte size.

### chrome / account_a — 26/26 PASS

| path | listed sha256 | result |
|---|---|---|
| 01_a0_lock.txt | `6c1b910d6b32c006f8b4ba5ed003daaa52f7011eee1c05e7a5ca03737b87f6f1` | PASS |
| 02_a_calib_memory_only.txt | `775fb484a9d48edef23717955f2c193754b6e077b796d205020e36f769a0bcf1` | PASS |
| 03_c_checklist_ack.txt | `b9454def07d3238bdee333b8291606f9b0ef3cdf2184ea8b0294f1b6cdb095f1` | PASS |
| 04_b_controls.txt | `fb6db9df3b363caff2e91e9779a8ca33448fb19737fe2ee6087df140f9a0d866` | PASS |
| 05_cgroup_limits.txt | `a7110a114b1a7414928f90d8cf75e7d2fea791acb7284e07381d81fd8c24155b` | PASS |
| 06_cpu_topology.txt | `aa7c76c353d072bd6fc706630e2de1924e43277ea40d5a499b3664daa0a8329e` | PASS |
| 07_d1_oom.txt | `1ac89b395cb48ad98b4e82a5bc778342da3f1c82c7dbbbf7ee7b1a5f6eafc42f` | PASS |
| 08_d2_disk.txt | `62a463b71b2e899048d2e069d529f855774e4be09973341d4f1aff7e82bb823e` | PASS |
| 09_d4_fd.txt | `c150c5562852d8971e6fbad8ddd1e1720c699801ce41404597db3494f635dec0` | PASS |
| 10_d6_smt.txt | `e1ae5dcff141550ba00fbca776f7915f02d71036bbe4e76cd29f43369eff3a29` | PASS |
| 11_d3_egress.txt | `4e83db58642d52666d004fd26b8695c8c2aeab9665fbc15588ed51810a8bcf01` | PASS |
| 12_d3b_egress_directip.txt | `7938b6f791dc0433cca4659ecdc599f0e1d669942e8a3a9e66b9e8ee58ed7649` | PASS |
| 13_b1_bandwidth.txt | `5436c5e48fd5263119bc45c48428470ebbb14fbbb45edaab9c3ca2b918143ab4` | PASS |
| 14_c1_mtimes.txt | `f2f4d477462a224ccfb8a1879c17a6c3a79304b0f4a0e7285913ccaa675987e3` | PASS |
| 15_analysis_derived.txt | `ba362172494509826b8a2420c7a9cea3ec2fbb6eb676f702dd842c82f9bb89b0` | PASS |
| 16_falsifications.txt | `17d1ad9f8e404ea1bd877529dc235b2bd2437ead913e7e332b12669670f82199` | PASS |
| 17_section_e_status.txt | `5ce53ff2b0d08c8ddb837c80d631d6b294489d63c590d7da015818fff33e1dbb` | PASS |
| c1_probe.txt | `44eac06b47bd661678d2f8cdab1274f44aeb92e91447800b26c9f2c6d6e89e7d` | PASS |
| d5/A.txt | `81c5985439ea89c8d5f9e45c4fe95178ff641006375613c5fe8d2b4b370be3b8` | PASS |
| d5/B.txt | `a41d38ad405f8bb993230dea054923cc02cd7b140b1b0a87af858588b7f13ff2` | PASS |
| d5/C.txt | `3669fb6b40157b3f93bd3405aea1a91c7dab7059c0465858f983e30811c2ef48` | PASS |
| d5/D.txt | `aa37c54f2c4a987a5a49649c4f0fcbda7f82c78ea267f472149f55f9f6fc2c3f` | PASS |
| d5/E.txt | `c0211fbab0dfdbe2ee2d7be650260f7f29f9142f2b6419fb554baa51696e9ef1` | PASS |
| d5/F.txt | `ce99d556a6bdb46bc1c0206baecb0c815b9b99442f4711f41336e42deab05525` | PASS |
| d5/G.txt | `2b6c3adb108bccd6c85464a39e842b776e834d7926b1e147557249332e5bb229` | PASS |
| d5/H.txt | `f9185620a4b7311a35d05bacaa53382ac577c4785dbf505825285f940b6be128` | PASS |

### brave / account_b — 32/32 PASS

| path | listed sha256 | result |
|---|---|---|
| 00_os_release.txt | `04516c518ed82e7ea5ac80db31129240ddfbadd837d41c5ae94bd7c76be36eab` | PASS |
| 01_uname_v.txt | `4956681cb680d9e375c34fe951480883adefbdd552b971bd8dba8903215a618b` | PASS |
| 02_python3_V.txt | `c4a684e859efa868ffdfb4967e90ffd847a0fc1f293e16ed50ea18af8e3b95f6` | PASS |
| 03_meminfo_MemTotal.txt | `395a6a3cd85997c6b6a478d59efffcab8332b2274d7ffbe49b604f35cdfee8aa` | PASS |
| 04_df_root.txt | `6e4c3f7d1eeee7af205de33ca3a73c0d35b9a584a6a6fbd56ca89e7ef04f84d7` | PASS |
| 05_dot_e2b.txt | `b07c03fb6cc666f9548b56110b370523706fd05b51540ae8a4ba0e12f4b6e8b9` | PASS |
| 06_env_E2B_TEMPLATE_ID.txt | `1f337c4c3a01ae9709408e006b98d620503e89b5c4975e9998632c5c8da84595` | PASS |
| 07_boot_id.txt | `5077c4552b908f8289b96564ac66f16c5a019e508b1c2682e29a632c0778d7ba` | PASS |
| 08_uname_a.txt | `972941c0374d35767e9b7bd27d4dbb3f69592adc6c9fc488d12c3bb6691d07bc` | PASS |
| 09_timestamp_utc.txt | `005ebfee5b010e53f2340ea7cd36b3397023b4e9a5a83322f1e3317b1393f829` | PASS |
| 10_classinfo_extra.txt | `de33de07c6d48aadba7b5f0efaf8562d8fa2d1df75cd398765b44627a65d9a86` | PASS |
| 11_cgroup_cpu.txt | `a7790e632f8a4e85b862a8f9f21d6e4a4a32688e65cd522d1b423875c84ff558` | PASS |
| 12_B3_rfc5737.txt | `04eacf71a34d8dfd3b63d9211cf1df29931023103d84a2b89d51f9a6b524bc5f` | PASS |
| 13_B2_control.txt | `bebe914ba22bf8564fe9b356bba8b9fbfeebded52b47fbac2542f58d7df4f25f` | PASS |
| 14_B1_cpu_download.txt | `59ed986027714088dedae65ff315bc337c6e20764bf03bb3a5cd3f4cdefc36c0` | PASS |
| 15_cgroup_limits.txt | `756126bf0658a3c0d32585dcb8ea796c51ce5a3056be38ee2a9e5cf8408c0758` | PASS |
| 16_D3_egress_probe.txt | `27f2450a26ef927911e5bf78b86692ecd01db94e2b2a48fd75d132bb311a3a02` | PASS |
| 17_disk_precheck.txt | `329ee085bd8fdef8dd6a475bc74eba69c8f9cc375ff57b7cda6608356b79aae3` | PASS |
| 18_B1_size_check.txt | `efae1a734fab7b084f4794ad30138c5e791f32f6ace4f6389066d69037557015` | PASS |
| 19_D6_smt_penalty.txt | `2d56894bbcd9d1b2f04329606969dcd9f906cca3de56d4595c8d5a1510851f61` | PASS |
| 20_D2_disk_speed.txt | `553e19e0172b8704cf38c03acf5bbb6ebc67f5852bad3f07fe0a5be12f45603a` | PASS |
| 21_D2_tmpfs_clean.txt | `4d0dd06b7d3398eaad7082d8038ea466ec8025ca101d08265758ff751e8b6397` | PASS |
| 22_D4_fd_discovery.txt | `111b2fae08423a5f19a5cb46deaee673a09f21c314bc8a778147667b0da2eef5` | PASS |
| 23_D2_unbottlenecked.txt | `046c1188a21cd03795d93c8e234c085b81ea24b72194ad58500e69664ca07545` | PASS |
| 24_D4_fd_ceiling.txt | `0cdeb1babfc9d82cbbac7f3a6bbcf17091c5a1f5a4e1733cc0adf920d7391f2b` | PASS |
| 25_D5_concurrency.txt | `c0435d9ec7f919d0d97b5052700430c1aa5a049fc3805bfdee591573a3e5e648` | PASS |
| 26_D3_phase2.txt | `c8a3ef6336c723061a674ba8971a0f6031d55a0369f77003757102328a4ea039` | PASS |
| 27_D3_ua_test.txt | `a5893042a62ab3ca16756e24684f590c28c4218c081ab60fe2408509bd42fe04` | PASS |
| 28_D1_oom_bisect.txt | `3c312917b0c857f6a50b267aade90bc28858506e6d070ea967a305fa3161910c` | PASS |
| 29_C1_liveness.txt | `2e66d361244ecaca70873b7d2b8777cae19a247da22c9b9112d780f34d95020b` | PASS |
| 30_cgroup_memproof.txt | `69017a6710daacbd4f32e93371d3ad9be66303138d14deec1ce1f54c0cbf7129` | PASS |
| 31_B1_variance.txt | `28ad3f801592b3aa0853202f3695c74a1f0d5b3625bc2ca1a30cff664aa2f442` | PASS |

### edge / account_c — 38/38 PASS

| path | listed sha256 | result |
|---|---|---|
| 01_os_release.txt | `fbbb0b33fdeaf27ecc0338ccd8474cec7f2f7ba275d5bc8b646397ea47075ebd` | PASS |
| 02_uname_v.txt | `604b1acc092d35ddbfadd31ce886b5441908d559a05b5ea6bae17e220a677081` | PASS |
| 03_python3_ver.txt | `e066222b34fcbcfc8397538c5c8aac6861b376613bc8736ca29d52f36b99ea7c` | PASS |
| 04_meminfo.txt | `13585642d8d26f6c09df8acca742780a632e5a2bf58b7ff29d6fd21736671192` | PASS |
| 05_df_root.txt | `e49fbda62c84bac5a74c8bdefe466b40ea5288609df211655d71cdbedc0b7627` | PASS |
| 06_e2b_file.txt | `e3808568867aab7c10fa455c635347758dd8cf8f82380baab840ef5c3e173ff0` | PASS |
| 07_env_e2b.txt | `2042063355b831540b95a1368a03ace78adae8058765bd3a6e2c3db3ef1875b4` | PASS |
| 08_boot_id.txt | `2332f7153e0eab64c68595feb028f8dad47d2417bfc5e9339634b5c072ec562c` | PASS |
| 09_uname_a.txt | `d0f96c0787c7a20a6ed83caae89a2c8073e8575acb9eb46a9412481d9e2154d0` | PASS |
| 10_uptime_host.txt | `cf6eea41822ee07e84b60c3251c20af52672aa996637f3ee6eba9191114d4c55` | PASS |
| 11_cgroup.txt | `9fc11d4cc9d5b556d53c0e5ce4859ac0c6eb9cceeb2d9dcd90bc9799c8540470` | PASS |
| 12_cpuinfo.txt | `9412236b3d757b152ca026adac60800042327ed3cd2e518598eebbc73160104e` | PASS |
| 13_mounts.txt | `2da93cf99ff66141f14e8262a1512a4fa8d01cdc21cfc2d30074e12181aa5ebb` | PASS |
| 14_net_cfg.txt | `dffcffee517f3ab30dd78de0faa26d4ddbe6ce328de1156d06b1d278b3bf7a85` | PASS |
| 15_ulimit.txt | `4ed1d3c0c15506d44e9698767c18cdf56cca6772513c70de509be2da946a2fd2` | PASS |
| 16_b3_testnet_connect.txt | `280215b070712ce6f4cb83d26dfaf38dc6ee8a97dd56831fff6a2fb1571b9086` | PASS |
| 17_b2_known_good.txt | `15efd3093d1a0038de3b1ded37f18b74a36f70db55b2978207288f75337c5894` | PASS |
| 18_oom_pre.txt | `ff352e9f100b8ccd634f45486d6163bdd74f852ccbe3de20192e69ea16202273` | PASS |
| 19_oom_bisect.txt | `eac5e3d257ea6242674dd00159afdf2a782d8d11a58a28d00ef4333acac2a125` | PASS |
| 20_oom_refine.txt | `7eeb200e81a64d4d51d1fa85f6840e4aa3f2031bc26ab5ef49710ef2622fe84d` | PASS |
| 21_fd_ceiling.txt | `ec66674bb653b0028696145601851cba20d5234a5d68abe78a0a28490f5b7c98` | PASS |
| 22_smt_penalty.txt | `f48594503e9d9a9f6d2c4a60842c455c4ba4f6821a6300bd3c5d9ccb9a700215` | PASS |
| 23_disk.txt | `ed639bf87f3f2a64fd3d111f5614790f644a02047e53139aecd7e6c5ad70dd6c` | PASS |
| 24_fd_retry.txt | `bcacf6759972b9c45a270dfe505f3d72f5bb409279e474b0b901d7164d279ca0` | PASS |
| 25_b1_confounder.txt | `c272c7f3d8acce012926bfaa9909dd1b348c682fbad16168de338b4c84ae6f3b` | PASS |
| 26_dns_sites.txt | `8b97362d23e3bcb29ed2967d8c84f2f90d9ac2de3ef5c91b671c8d5ae26b2467` | PASS |
| 27_egress_ladder.txt | `03d94ddfdac44e9388e438f42538768a0818878c0c5618fb6edabef04579686d` | PASS |
| 28_d5_p1.txt | `53dc4f6be2489d0d932db843e2ce1042f5b7a108f75e34889f36a89737da4ca2` | PASS |
| 28_d5_p2.txt | `7e4a38a2c107c5cf84813a8327ee667a6858c0ae69afc8389353916b0958f2ed` | PASS |
| 28_d5_p3.txt | `0af2038add3f717fa023bc48af8a29074e178f148ad24a41c6631f73efa91dec` | PASS |
| 28_d5_p4.txt | `4a0e6823b11a0edb57bf72057436b3268fdf5b886e21b0abc9d212a234e89adf` | PASS |
| 28_d5_p5.txt | `43d18c0d509584850d70baf07f4c9ffd431aff93b2e632b5b4a4349db5f0a600` | PASS |
| 28_d5_p6.txt | `cf1f1c51c8318a24d776c46d349dc408a00cb543c703b5feb9c3fbee1e5071cf` | PASS |
| 28_d5_p7.txt | `a6863467ac9bd818dd7443ce8bf530670b7f246b339217864c0f043601d81816` | PASS |
| 28_d5_p8.txt | `f026de206f661c2e8ab799e50cea89bf0293be0b4ac504af985e2dd8d95c58a3` | PASS |
| 29_ssh_retest.txt | `61ba0b352c861bfa84bbb1ea6abafa12dac38aa41ce35ecc1eac5ce1371b60bd` | PASS |
| 30_local_crypto.txt | `c59eb485559b3ed0461e8a881438a1847dbd8259580201210053ebd16e83a02b` | PASS |
| 31_final_checks.txt | `5bf72220a78e84360e285f6a510f86a4f661c67dc8b6c5f5def05af4eb7afda8` | PASS |

---

## Variance note

1. **Three incompatible manifest dialects.** Chrome is a 4-column custom format (digest, bytes, embedded write-time, path) with HH over **digests only**. Brave and edge are `sha256sum` `hash  name` lines with HH over the **full lines**. Do not mix methods across trees.

2. **Brave HH wording vs bytes that match the published digest.** The footer says `sha256 of the sorted per-file sha256 lines above`. Lexicographic sort of those `hash  name` lines (i.e. sort-by-hash) yields `b0c2e56c80ab4e625ff593347f77912807884a5647158e82f68ab1d38c6dd4b4` — **not** the published HH. Hashing the lines **as listed** (filename order, two spaces, trailing newline) yields `822db84c…779cb5`, which **does** match. The listed order is already sorted by filename, not by hash.

3. **Edge HH wording vs bytes that match the published digest.** Header says `hash-of-hashes = sha256 of sorted '<hash>  <name>' lines`. Lexicographic sort of those strings yields `3cfe188d434f9b9cb40c4fd5794e1b37eeb58b6dc74c650bfb277131357ae208` — **not** the published HH. Hashing the lines **as listed** / sorted by **name** (trailing newline) yields `e4737d2f…45197e47`, which **does** match. Same "sorted" ambiguity as brave: name order, not hash order.

4. **Edge `SELF-SHA256(manifest3.txt)` is not the hash of the file as stored.** Full-file SHA-256 is `39756c1225b6e66003afded7c2ced650d9830b213c2b894b191a0c1f3464bec9`. The claimed `b9a55b1ea8a4202f1250daa69569150e32ab0b954420f968ea5b7d6b94df6391` **does** match the file **with the SELF-SHA256 line removed** (chicken-and-egg: hash recorded, then the comment appended). Not a payload-file failure.

5. **Manifests are raw-txt only.** Extra extracted files, not in the HH set (present, names preserved, not executed):
   - chrome: `analyze.py`, `b1b_cpu_check.sh`, `b1c_burn.sh`, `build_json.py`, `d1_oom_bisect.py`, `d4_fd.py`, `make_manifest.sh`, `results3.json`
   - brave: `scripts/b1.sh`, `scripts/bench.py`, `scripts/burn.py`, `scripts/oom_probe.py`, `result_probe3.json`
   - edge: `src/fdtest.py`, `src/fdtest2.py`, `src/oombisect.py`, `src/oombisect2.py`, `src/smt.py`, `probe3.json`
   Chrome `make_manifest.sh` is the only tree that documents its own generator; brave/edge have no generator script in the archive.

6. **No other structural anomalies.** No `../`, no absolute paths, no symlinks, no nested zips. `unzip -t` clean. Outer SHA-256 unchanged by `git mv` into `zips/round3/`.

**Verdict:** all three archives verify. Ready for later analysis. Do not execute any extracted script until an explicit review burst.
