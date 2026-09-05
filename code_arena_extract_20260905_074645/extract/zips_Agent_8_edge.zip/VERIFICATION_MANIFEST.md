# Verification manifest — environment probe

This is the **run record**. Raw transcripts (no LLM rewrite) live in `probe_raw/`. The script that produced them is `probe_environment.sh`. A third party should run that script and `diff -u` against `probe_raw/*.txt` (expect drift in timestamps, sandbox ID, and micro-benchmarks).

## Run identity

| Field | Value |
|--------|--------|
| UTC end | **2026-09-04T14:14:32Z** (manifest append 2026-09-04T14:14:38Z) |
| Hostname | `e2b.local` |
| `E2B_SANDBOX` | `true` |
| `E2B_SANDBOX_ID` | `iitws4rrop6j50j2hed7r` |
| `E2B_TEMPLATE_ID` | `nlhz8vlwyupq845jsdg9` |
| uname | `Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux` |

**Note:** An earlier ad-hoc characterization in this conversation used sandbox ID `i87c7gwotry240rbx1u77` (same template). Sandbox IDs are per-boot; **template ID is the image**.

## How to reproduce

```bash
bash probe_environment.sh /tmp/probe_raw_rerun
diff -u probe_raw/01_runtime.txt /tmp/probe_raw_rerun/01_runtime.txt
sha256sum -c <<'EOF'
# paste hashes below after stripping filenames from this table
EOF
```

Compare `00_MANIFEST.txt` fields `E2B_TEMPLATE_ID` and `uname`. Do **not** expect `E2B_SANDBOX_ID`, UTC stamps, or bench timings to match bit-for-bit.

## SHA-256 of artifacts (this run)

Algorithm: `sha256sum` / Python `hashlib.sha256` over full file bytes.

| File | Bytes | SHA-256 |
|------|------:|---------|
| `probe_environment.sh` | 13694 | `fcae745dd2c5a4cc917a8821c84e113b5fb47c51684db40c522190452a411524` |
| `probe_raw/01_runtime.txt` | 1556 | `c67bedc54027bd3de98ba6e6ba98b1affbf904d9880d29f165623bf93aa5bcbe` |
| `probe_raw/02_isolation.txt` | 11077 | `619007347f739a67df5c232304a6565d2de9254aecd9accd27ab0e90c4725d57` |
| `probe_raw/03_identity_limits.txt` | 1966 | `3340438a387010dc8e43d1adc24870b1316052a628126914fa5f2fb5ac57b5e1` |
| `probe_raw/04_cpu_mem.txt` | 7646 | `ec65970e9d1ef86ab330ff02d5f821cc9b32eb54c0957d2eabf72f901dee58b9` |
| `probe_raw/05_tools.txt` | 3996 | `ac2113b634630a34925d0affdeaf347e69488806eafe1bd6b9992660b6fe2e99` |
| `probe_raw/06_python_pkgs.txt` | 615 | `cea46f569a230c9624cc4dfb1411a3af9a86359fa694dc1e6f49c62fb540610e` |
| `probe_raw/07_filesystem.txt` | 1637 | `d057abdad2dac4e4c4a4ac37a01c270aace7dbd6f2c25f984c2afe077c8310cb` |
| `probe_raw/08_env.txt` | 343 | `05a1a56ebd18a4248bc99e263e4e1b49ccaaa4384506ce43229d8fb1809845f6` |
| `probe_raw/09_net_matrix.txt` | 3501 | `5a341a34bdd2605030c65ab90b61d40bc3620dcbc4176febff3efe3b11a313b7` |
| `probe_raw/10_benches.txt` | 480 | `045c00cec88409cb69e44a73e5099565b991c0db73753e9a42a6a20be1fe4d9b` |
| `probe_raw/11_pip_sample.txt` | 260 | `14fc7d1a4ad1b880623c000ef281acdb3d746979d796905ba3d6dd4228161f8f` |
| `environment_characterization.md` (narrative report; **not** raw) | — | `a6ba79f091a4047ac09bcb833994367423af0cbe54d287f3fbd6397c16d9cd04` |

`probe_raw/00_MANIFEST.txt` is the machine-readable copy of the same hashes (plus later append of script SHA). Its own hash changes if you edit it; treat the table above as the frozen transcript hashes.

## File map

| Transcript | Contents |
|------------|----------|
| `01_runtime.txt` | uname, os-release, libc, virt |
| `02_isolation.txt` | dockerenv, cgroup, mounts, caps, seccomp, ps |
| `03_identity_limits.txt` | id, sudo, ulimit |
| `04_cpu_mem.txt` | lscpu, meminfo, uptime |
| `05_tools.txt` | command -v + --version matrix |
| `06_python_pkgs.txt` | importlib versions |
| `07_filesystem.txt` | df, write tests |
| `08_env.txt` | env \| sort |
| `09_net_matrix.txt` | DNS, curl timings, TCP samples, download, ports |
| `10_benches.txt` | CPU / disk / gcc |
| `11_pip_sample.txt` | timed pip install |

Narrative summary remains in `environment_characterization.md`. **Primary evidence is the `.txt` files.**
