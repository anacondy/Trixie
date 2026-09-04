#!/usr/bin/env bash
# diff_run.sh — compare two probe runs, ignoring values that legitimately vary.
#
#   ./diff_run.sh DIR_A DIR_B          # A = published baseline, B = your run
#
# Compares the normalized transcripts (timings/sizes/tokens masked) so a genuine
# environment difference shows up, while noise does not. Exit 0 = identical
# normalized transcripts.
set -u
A="${1:?usage: diff_run.sh <baseline_rawdir> <your_rawdir>}"; B="${2:?usage: diff_run.sh <baseline_rawdir> <your_rawdir>}"
[ -d "$A" ] || { echo "no such dir: $A"; exit 2; }
[ -d "$B" ] || { echo "no such dir: $B"; exit 2; }

echo "=== diff_run.sh  $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "  baseline: $A"
echo "  yours:    $B"
echo

# 1) presence check
miss=0
for f in $(cd "$A" && ls *.txt 2>/dev/null | sort); do
  if [ ! -f "$B/$f" ]; then echo "  MISSING IN YOURS : $f"; miss=$((miss+1)); fi
done
for f in $(cd "$B" && ls *.txt 2>/dev/null | sort); do
  if [ ! -f "$A/$f" ]; then echo "  EXTRA IN YOURS   : $f"; fi
done
[ "$miss" = 0 ] && echo "  all expected transcripts present"
echo

# 2) verbatim hash comparison (expected to differ)
echo "--- verbatim sha256 (expected to DIFFER: contains live timings) ---"
if [ -f "$A/MANIFEST.txt" ] && [ -f "$B/MANIFEST.txt" ]; then
  d=$(diff <(grep -E '^  [0-9a-z]+\.txt' "$A/MANIFEST.txt" | awk '{print $1}' | sort) \
           <(grep -E '^  [0-9a-z]+\.txt' "$B/MANIFEST.txt" | awk '{print $1}' | sort) | head -20)
  [ -z "$d" ] && echo "  same file set" || printf '%s\n' "$d"
fi
echo

# 3) normalized comparison = the real test.
#    ALWAYS re-normalize both sides with the current normalize.py: stale .norm files left
#    over from a run made by an older normalizer would produce phantom differences.
echo "--- normalized transcripts (this is the meaningful diff) ---"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/a" "$WORK/b"
same=0; diffn=0; difflist=""
for f in $(cd "$A" && ls *.txt 2>/dev/null | sort); do
  case "$f" in MANIFEST.txt|SHA256SUMS*.txt|manifest.json) continue;; esac   # hashes always differ
  [ -f "$B/$f" ] || continue
  # a normalizer crash must NOT masquerade as "files match": check exit status and size
  ea=$(mktemp); eb=$(mktemp)
  python3 "$HERE/normalize.py" --stdout "$A/$f" > "$WORK/a/$f" 2>"$ea"
  ra=$?
  python3 "$HERE/normalize.py" --stdout "$B/$f" > "$WORK/b/$f" 2>"$eb"
  rb=$?
  if [ "$ra" != 0 ] || [ "$rb" != 0 ]; then
    echo "  ERROR: normalize.py failed on $f (exit $ra/$B) - not comparing, result would be meaningless:"
    sed -e 's/^/      /' "$ea" "$eb" | tail -4
    echo "=== verdict ==="; echo "  TOOL ERROR - fix normalize.py before trusting any comparison."; exit 3
  fi
  if [ ! -s "$WORK/a/$f" ] && [ -s "$A/$f" ]; then
    echo "  ERROR: normalize.py produced empty output for non-empty $f - refusing to score it as a match"; exit 3
  fi
  rm -f "$ea" "$eb"
  if cmp -s "$WORK/a/$f" "$WORK/b/$f"; then same=$((same+1)); else
    diffn=$((diffn+1)); difflist="$difflist $f"
  fi
done
echo "  identical after normalization : $same"
echo "  differ                        : $diffn$difflist"
echo "  (manifest/SHA256SUMS excluded by design - hashes cannot match across runs)"
if [ -n "$difflist" ]; then
  echo
  echo "--- per-file normalized diff (up to 40 lines each) ---"
  for f in $difflist; do
    n=$(diff "$WORK/a/$f" "$WORK/b/$f" | grep -Ec '^[-<>]')
    echo "### $f  ($n differing lines)"
    diff "$WORK/a/$f" "$WORK/b/$f" | grep -E '^[-<>]' | head -40
    echo
  done
fi
echo "=== verdict ==="
[ "$diffn" = 0 ] && [ "$miss" = 0 ] && { echo "  MATCH: your environment is structurally identical to the published baseline."; exit 0; } || { echo "  DIFFERENCES FOUND in $diffn transcript(s), $miss missing file(s) - inspect the diff above."; exit 1; }
