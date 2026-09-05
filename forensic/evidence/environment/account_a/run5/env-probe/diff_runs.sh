#!/usr/bin/env bash
# =============================================================================
# diff_runs.sh - Compare two env_probe runs
# =============================================================================
# Usage:
#   ./diff_runs.sh <run_dir_A> <run_dir_B>
#   ./diff_runs.sh                      # auto: two most recent runs
#
# Prints, per section: identical / changed (with unified diff), plus a
# manifest-level comparison of host identity fields.
# =============================================================================

BASE="${OUTDIR:-$HOME/env-probe}"

if [ $# -eq 2 ]; then
  A="$1"; B="$2"
else
  mapfile -t dirs < <(ls -dt "$BASE"/runs/*/ 2>/dev/null)
  if [ "${#dirs[@]}" -lt 2 ]; then
    echo "Need at least 2 runs in $BASE/runs/ (found ${#dirs[@]})." >&2
    exit 1
  fi
  B="${dirs[0]}"; A="${dirs[1]}"   # A = older, B = newer
fi

A="${A%/}"; B="${B%/}"
echo "=============================================================="
echo "PROBE RUN DIFF"
echo "  A (older): $(basename "$A")"
echo "  B (newer): $(basename "$B")"
echo "=============================================================="
echo

# --- integrity first -------------------------------------------------------
echo "--- INTEGRITY (SHA-256 self-check) ---"
for d in "$A" "$B"; do
  if [ -f "$d/SHA256SUMS.txt" ]; then
    bad=$( (cd "$d" && sha256sum -c SHA256SUMS.txt 2>/dev/null | grep -cv ': OK$') )
    tot=$( (cd "$d" && wc -l < SHA256SUMS.txt) )
    if [ "$bad" -eq 0 ]; then echo "  $(basename "$d"): all $tot files OK"
    else echo "  $(basename "$d"): *** $bad of $tot FAILED ***"; fi
  else
    echo "  $(basename "$d"): no SHA256SUMS.txt"
  fi
done
echo

# --- manifest identity comparison ------------------------------------------
echo "--- HOST IDENTITY (MANIFEST.json) ---"
printf '%-22s %-34s %-34s\n' FIELD A B
for k in probe_version run_utc sandbox_id template_id boot_id hostname kernel os arch nproc mem_total_kb egress_ip mode; do
  va=$(python3 -c "import json,sys;print(json.load(open('$A/MANIFEST.json')).get('$k','-'))" 2>/dev/null)
  vb=$(python3 -c "import json,sys;print(json.load(open('$B/MANIFEST.json')).get('$k','-'))" 2>/dev/null)
  if [ "$va" = "$vb" ]; then mark="  "; else mark="**"; fi
  printf '%s%-20s %-34s %-34s\n' "$mark" "$k" "${va:0:34}" "${vb:0:34}"
done
echo "  (** = differs between runs)"
echo

# --- per-section content diff ----------------------------------------------
echo "--- SECTION DIFFS ---"
changed=0; same=0
for fa in "$A"/*.txt; do
  n="$(basename "$fa")"
  [ "$n" = "SHA256SUMS.txt" ] && continue
  fb="$B/$n"
  if [ ! -f "$fb" ]; then echo "  $n: PRESENT IN A ONLY"; continue; fi
  # strip volatile header lines (timestamps, run ids) before comparing
  if diff -q <(grep -vE '^# (run_utc|generated|probe_version)' "$fa") \
             <(grep -vE '^# (run_utc|generated|probe_version)' "$fb") >/dev/null 2>&1; then
    echo "  $n: identical"
    same=$((same+1))
  else
    d=$(diff -u <(grep -vE '^# (run_utc|generated|probe_version)' "$fa") \
                <(grep -vE '^# (run_utc|generated|probe_version)' "$fb") \
        | grep -cE '^[+-][^+-]')
    echo "  $n: CHANGED ($d differing lines)"
    changed=$((changed+1))
  fi
done
for fb in "$B"/*.txt; do
  n="$(basename "$fb")"; [ -f "$A/$n" ] || echo "  $n: PRESENT IN B ONLY"
done
echo
echo "Summary: $same identical, $changed changed."
echo
echo "For a full unified diff of one section:"
echo "  diff -u $A/09_net_matrix.txt $B/09_net_matrix.txt"
