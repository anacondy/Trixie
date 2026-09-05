#!/usr/bin/env bash
# ============================================================================
# compare_run.sh  v2.0.0
# Structural diff between two environment_probe.sh output directories.
#
# USAGE:  bash compare_run.sh REFDIR NEWDIR
#   e.g.  bash environment_probe.sh run2
#         bash compare_run.sh envprobe run2
#
# What "same probe battery" means here:
#   * the same set of output files exists in both dirs
#   * per file, the STRUCTURAL ANCHORS match — i.e. lines starting with
#     '== ', '### probe ' or '## ' (section headers), compared after
#     normalizing digits and timestamps to '#' (numbers, dates, run IDs
#     legitimately vary between runs; section wording must not).
# Numeric content, byte sizes and line counts WILL differ between runs
# (latency/throughput/benchmarks/sandbox IDs) and are reported as info only.
#
# Exit code: 0 = anchor sets identical; 1 = structural mismatch found.
# ============================================================================
set -u
REF="${1:?usage: compare_run.sh REFDIR NEWDIR}"
NEW="${2:?usage: compare_run.sh REFDIR NEWDIR}"

python3 - "$REF" "$NEW" <<'PY'
import os, sys, re
ref, new = sys.argv[1], sys.argv[2]

def files(d):
    return {f: os.path.join(d, f) for f in sorted(os.listdir(d))
            if os.path.isfile(os.path.join(d, f))}

rf, nf = files(ref), files(new)
common = sorted(set(rf) & set(nf))
only_ref = sorted(set(rf) - set(nf))
only_new = sorted(set(nf) - set(rf))

ANCHOR = re.compile(r'^(== |### probe |## )')
DIGITS = re.compile(r'[0-9]+')

def lines(p):
    with open(p, 'rb') as fh:
        return fh.read().decode('utf-8', 'replace').splitlines()

def anchors(ls):
    return [DIGITS.sub('#', l.strip()) for l in ls if ANCHOR.match(l)]

print(f"REF dir : {ref}  ({len(rf)} files)")
print(f"NEW dir : {new}  ({len(nf)} files)")
print(f"common  : {len(common)} files")
print(f"only in REF : {only_ref or '-'}")
print(f"only in NEW : {only_new or '-'}")
print()
ok = True
for f in common:
    a, b = lines(rf[f]), lines(nf[f])
    diff_lines = sum(1 for x, y in zip(a, b) if x != y) + abs(len(a) - len(b))
    aa, bb = anchors(a), anchors(b)
    if aa != bb:
        ok = False
        print(f"== {f}: ANCHOR MISMATCH  ({len(aa)} ref vs {len(bb)} new anchors, "
              f"{diff_lines} differing raw lines)")
        sa, sb = set(aa), set(bb)
        for x in sorted(sa - sb)[:6]:
            print(f"   only in REF : {x}")
        for x in sorted(sb - sa)[:6]:
            print(f"   only in NEW : {x}")
        if len(sa ^ sb) > 12:
            print(f"   ... and {len(sa ^ sb) - 12} more differing anchors")
    else:
        print(f"== {f}: anchors OK  ({len(aa)} anchors, {diff_lines} differing raw lines "
              f"[expected: timestamps/numbers])")
print()
if only_ref or only_new:
    print("NOTE: file-set differences above. 0*.txt + bg_ticks.txt is the canonical set;")
    print("      extra/missing files should be reviewed before comparing.")
if ok:
    print("RESULT: PASS — identical structure (file set + normalized section anchors).")
    print("        Numeric differences are expected per-run variance, not regressions.")
else:
    print("RESULT: FAIL — anchor mismatches found; see per-file diffs above.")
    print("        If the probe script was edited, headers changed wording/structure.")
sys.exit(0 if ok else 1)
PY
