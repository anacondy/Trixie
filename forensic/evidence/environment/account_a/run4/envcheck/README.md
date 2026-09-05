# `envcheck/` — reproducible environment-characterization evidence bundle

Companion to `../environment_characterization.md`. The report is the summary; **this directory is the
evidence**: verbatim command transcripts with no summarization layer, produced by a script you can run
yourself and diff against mine.

```
envcheck/
├── probe.sh                <- THE PROBE. Run this to regenerate every transcript.
├── probe_background.sh     <- 2nd-invocation detached-process survival check
├── diff_run.sh             <- compares two runs, masking values that legitimately vary
├── normalize.py            <- the masking rules used by diff_run.sh + the manifest
├── make_manifest.py        <- rebuilds MANIFEST.txt / manifest.json / SHA256SUMS*.txt (idempotent)
├── session1/               <- one-off ad-hoc scripts from the interactive session (provenance)
├── run_v2/                 <- a second, independent full run kept for cross-run comparison
├── legacy_raw/             <- the earlier partial `tee` captures (superseded by raw/)
└── raw/                    <- CANONICAL OUTPUT (numbered transcripts + manifest)
    ├── 00_meta.txt            run identity: id, timestamp, template, kernel
    ├── 01_runtime.txt         OS / kernel / arch / libc / cpu / meminfo / mitigations
    ├── 02_isolation.txt       container-vs-VM evidence, cgroups, caps, seccomp, namespaces, mounts
    ├── 03_limits.txt          ulimits, rlimits, threads/pids, sysctls, swap
    ├── 04_users.txt           uid/gid/groups, sudo escalation + capability proof, sudoers
    ├── 05_tools.txt           ~110 binaries: path + `--version` line, or ABSENT
    ├── 06_pkg_and_compile.txt pip/apt/npm config, package inventory, REAL gcc C-extension build, venv
    ├── 06b_pip_freeze_sorted.txt  sorted name==version list (diff-friendly)
    ├── 07_filesystem.txt      per-path write/read/delete/exec, mount table, fs features
    │                          (fallocate, xattr, flock, mmap, O_DIRECT, inotify, epoll, io_uring)
    ├── 08_persistence.txt     persistence markers + tmpfiles sweep ages + timer schedule
    ├── 09_net_matrix.txt      TCP port matrix, ICMP, IPv6, UDP (DNS/NTP/QUIC), TLS issuer (MITM check)
    ├── 10_net_dns.txt         getaddrinfo timing, 22 hosts x N reps
    ├── 11_net_latency.txt     TCP connect + split tcp/TLS-handshake/total per host
    ├── 12_net_throughput.txt  download single+sustained+scaling, upload, HTTP/2 vs /3, curl -w lines
    ├── 13_net_egress_proof.txt  the transparent-proxy proof (reserved/unroutable IPs "connect")
    ├── 14_bench_cpu.txt       pure-python, numpy/pandas, sha256, + process vs thread scaling
    ├── 15_bench_disk.txt      ext4 vs tmpfs, buffered/fsync/cold/O_DIRECT, many-small-files
    ├── 16_bench_installs.txt  pip / apt / npm / git-clone timing, incl. npm audit hang
    ├── 17_mem_pressure.txt    cgroup memory files + (with --with-oom) the actual OOM kill
    ├── 18_background.txt      detached-process seeding + fd/pty ceilings
    ├── 19_services.txt        listeners, infra process tree, enabled units, armed timers
    ├── 20_accelerators.txt    GPU / PCI bus absence
    ├── MANIFEST.txt           <- per-run verification manifest (human readable)
    ├── manifest.json          <- same, machine readable
    ├── SHA256SUMS.txt         <- `sha256sum -c` ready, verbatim transcripts
    ├── SHA256SUMS.normalized.txt
    └── normalized/*.norm      <- masked copies whose hashes should match across runs
```

## Reproduce

```bash
./probe.sh raw                      # full run, ~4-12 min, writes raw/*.txt + manifest
./probe.sh raw --fast               # ~4 min, 1 rep / smaller payloads
./probe.sh raw --fast --with-oom    # + actually drive the cgroup to OOM (SIGKILLs a child)
```

`probe.sh` is self-contained (no dependencies beyond coreutils, `curl`, `python3`, and optionally
`sudo`/`git`/`npm`/`apt` — absent tools are recorded as `ABSENT`, never skipped silently). Safe to run
in any Linux container or VM. It writes only inside its output dir plus `$TMPDIR`, and removes its scratch
on exit.

### Two things it deliberately does NOT do by default

* **It does not OOM itself.** The memory test SIGKILLs a child, so it is behind `--with-oom`. Without the
  flag, `17_mem_pressure.txt` records the limits and says the test was skipped.
* **It does not install anything system-wide.** It only *times* an apt install of one small package
  (zstd/ripgrep) if root is available. Pass no flags if you want zero mutation — comment that line out.

## Background-process survival (needs two runs)

```bash
./probe.sh raw && sleep 25 && ./probe_background.sh raw
```

`probe_background.sh` reads `raw/.bg_pid`, checks whether the seeded `nohup` loop survived the parent
shell exiting, and counts ticks in `raw/.bg_ticks` (loop is designed for 20×1 s). Verdicts: `STILL ALIVE`
+ `RAN TO COMPLETION` ⇒ detached work survives; `REAPED` / `STOPPED EARLY` ⇒ the harness kills children
with the call. Also reports its PID so you can reap it: `kill "$(awk '{print $1}' raw/.bg_pid)"`.

## Verify my numbers

Every transcript is self-identifying (`run_id`, `sandbox`, `template`, `started`) and `raw/MANIFEST.txt`
carries SHA-256 of each file, plus a second hash of the *normalized* form:

```bash
cd raw && sha256sum -c SHA256SUMS.txt              # verbatim integrity of every transcript
cd raw && sha256sum -c SHA256SUMS.normalized.txt   # integrity of the masked copies
python3 ../make_manifest.py .                      # rebuild the manifest after copying files elsewhere
./diff_run.sh /path/to/mine/raw /path/to/yours/raw  # structure-only comparison of two runs
```

## Two published runs

| dir | run_id | wall | result |
|---|---|---|---|
| `raw/` | `20260904T142012Z-22063` | 245 s | canonical set, 22/22 hashes verified |
| `run_v2/` | `20260904T140458Z-11960` | 247 s | independent repeat, ~16 min earlier |

`./diff_run.sh run_v2 raw` → 16 of 22 transcripts identical after normalization, 6 differing, all
attributable to the outside world (anycast edge IP, DNS round-robin, cert SAN variant, benchmark
jitter, one fixed script defect). That is the calibration a third party should expect: exact-value
equality is *not* achievable between runs, structural equality is.

`MANIFEST.txt` header records `run_id`, `timestamp_utc`, `sandbox_id`, `template_id`, host/OS/kernel,
invoking user + cwd, and file/byte totals; `manifest.json` carries the same plus per-file
`sha256` / `sha256_normalized` and an explanation of what each hash means. Scratch state
(`.bg_pid`, `.bg_ticks`, `.run_id`, `.persist/`) and the manifest files themselves are deliberately
excluded, so rebuilding a manifest never changes what it attests to (verified: re-running
`make_manifest.py` twice produces a byte-identical `SHA256SUMS.txt`).

### What to expect when you diff

| Should match exactly | Will differ, and that is fine |
|---|---|
| `05_tools` (paths, versions, ABSENT set) | all timings in `10`–`12`, `14`–`16` |
| `01`, `02`, `03`, `04`, `20` structure: caps, seccomp, limits, uid, sudo verdict | `memory.current`, `cpu.stat` counters, `io.stat` byte counts |
| `09` verdict column (`CONNECTED` / `TIMEOUT` / `DENIED`) | banner bytes / error text on stalled ports |
| `13` proxy verdict (does a reserved IP connect? `yes`/`no`) | `08` run ids and marker timestamps |
| `06b_pip_freeze_sorted.txt` on the same template | `15` MB/s figures (cache state at run time) |

`diff_run.sh` masks timestamps, durations, byte sizes, bandwidth, pids, hex/long tokens, and the
self-identifying header, then compares; it exits `0` only if every normalized transcript is identical, and
prints the first 40 differing lines per file so you can see whether a difference is *your* environment.

If a normalized file differs, check it against the corresponding section of
`../environment_characterization.md` — §2–§7 each cite the exact command that produced the claim.
