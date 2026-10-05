# MPX cross-check prompts (2026-09-24)

**Adjudication: use the FOLLOW-UP first, in the same MPX session.** Rationale: the missing values (template ID, sandbox/boot IDs, cgroup limits, CPU topology) are static per sandbox lineage and are NOT altered by the session's earlier apt/build activity, so a follow-up ties the identity probes to the exact sandbox that produced the evidence. Use the FRESH variant only if (a) the MPX session is dead/reset, or (b) you additionally want a clean pristine-instance datapoint from the same surface for surface-vs-surface comparison. Either way, one paste, one reply.

---

## VARIANT A — FOLLOW-UP (paste into the existing MPX session)

```
Platform identity cross-check. Run ONLY the commands below, in order, and print their raw output as ONE verbatim fenced block, no interpretation, no truncation except where a cap is stated. Do not install anything, do not create or modify any file, do not start another burst.

1. cat /.e2b 2>/dev/null || echo NO_.e2b_FILE
2. env | grep -E 'E2B|TEMPLATE|SANDBOX|BUILD_ID' || echo NO_MATCHES
3. uname -a
4. grep -E 'MemTotal|MemAvailable' /proc/meminfo
5. cat /proc/sys/kernel/random/boot_id
6. nproc; echo ---; cat /sys/fs/cgroup/cpu.max 2>/dev/null; cat /sys/fs/cgroup/memory.max 2>/dev/null; cat /sys/fs/cgroup/user/cpu.max 2>/dev/null; cat /sys/fs/cgroup/user/memory.max 2>/dev/null; echo ---; cat /sys/fs/cgroup/cpuset.cpus.effective 2>/dev/null; cat /sys/fs/cgroup/user/cpuset.cpus.effective 2>/dev/null
7. grep -m2 'model name' /proc/cpuinfo; taskset -c 2 true 2>&1 && echo TASKSET2_OK || echo TASKSET2_EINVAL
8. ls /dev/dri 2>/dev/null || echo NO_DRI; command -v lspci ffmpeg valgrind || echo NONE_OF_LSPCI_FFMPEG_VALGRIND
9. grep -E 'libsdl2|libavformat|cmake|ninja' /var/log/apt/history.log 2>/dev/null | head -20 || echo NO_APT_LOG_MATCH
10. sha256sum /home/user/docs/BashTracker.md /home/user/build-native/mpx
11. date --iso-8601=ns

STOP after the block.
```

What each line decides: 1-2 template/sandbox/build IDs (ties this session to our class-T template nlhz8vlwyupq845jsdg9 or not); 3-4 kernel/MemTotal lock re-check; 5 boot_id — equality with `2bb79165-136a-4b63-829d-17027b0a8e40` = same snapshot image still restoring across surfaces+dates; 6-7 cgroup/CPU topology lock (memory.max 1947172864, cpuset 0-1, taskset EINVAL); 8 headless lock + ffmpeg-CLI question; 9 template-shipped vs apt-installed origin of the SDL/FFmpeg stack; 10 ties the printout to the exact ledger/binary we hold; 11 freshness.

---

## VARIANT B — FRESH (new session on the same surface; only if A is impossible or you also want pristine comparison)

```
Print the sandbox identity, verbatim, one fenced block, no interpretation, no other commands, install nothing, create nothing:
cat /.e2b 2>/dev/null || echo NO_.e2b_FILE
env | grep -E 'E2B|TEMPLATE|SANDBOX|BUILD_ID' || echo NO_MATCHES
uname -a
grep -E 'MemTotal|MemAvailable' /proc/meminfo
cat /proc/sys/kernel/random/boot_id
nproc; cat /sys/fs/cgroup/memory.max 2>/dev/null; cat /sys/fs/cgroup/user/memory.max 2>/dev/null; cat /sys/fs/cgroup/user/cpuset.cpus.effective 2>/dev/null
grep -m2 'model name' /proc/cpuinfo
date --iso-8601=ns
STOP.
```

Paste each reply back here; I consolidate against the class-T lock table and the MPX extraction (mpx_session_sandbox_findings.md).
