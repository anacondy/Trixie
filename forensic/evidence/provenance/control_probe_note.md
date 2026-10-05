# Control probe provenance note — the non-Arena E2B sandbox sharing `nlhz8vlwyupq845jsdg9`

**Status: PROVENANCE NOTE (researcher-recorded). NOT a raw artifact of an Arena session.**
**Recorded:** 2026-09-04, from the researcher's own E2B-backed agent sandbox — a different product on the same E2B platform, not Arena's. Verbatim reads:

```
$ cat /.e2b              # a FILE, not a directory; dated 2026-07-23 18:05:37
ENV_ID=nlhz8vlwyupq845jsdg9
TEMPLATE_ID=nlhz8vlwyupq845jsdg9        <- identical to Arena's baked template ID
BUILD_ID=f34a5416-ef30-4cb7-8e18-0fdecd6eb529
$ echo $E2B_TEMPLATE_ID
a8bgno7gunor5wbj2d1w                    <- different: injected at spawn, not baked
```

**Interpretation (as of 2026-09-08):**

1. `nlhz8vlwyupq845jsdg9` is most plausibly E2B's **shared code-interpreter base template**: E2B documents `code-interpreter-v1` as built with `cpu_count=2, memory_mb=2048`, matching the observed class-T envelope (2 vCPU, MemTotal 2 032 608 kB), and the resident service set (`envd`, `jupyter-server`, `code-interpreter.service`) is exactly that stack. Observing the ID proves "E2B code-interpreter-class microVM", **not** "this is Arena".
2. `/.e2b` (baked at image build) and `$E2B_TEMPLATE_ID` (injected at spawn) can disagree; read both.
3. The image records its own build lineage in filesystem mtimes; one layer (2026-07-13 00:00) matches the apt pin `snapshot.debian.org/archive/debian/20260713T000000Z`.

**What still points at Arena specifically** is the platform layer, not the VM: the ~128 MiB / ~10 000-file `/home/user` snapshot contract with its exact exclusion list, and the tool surface — observable only through the product UI and the agents' reports, never from inside the VM.
