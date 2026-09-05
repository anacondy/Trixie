#!/usr/bin/env bash
# probe_background.sh — second-invocation check for detached-process survival.
#
#   Run 1:  ./probe.sh raw            (writes raw/.bg_pid + raw/.bg_ticks)
#   ... wait >= 25 s, or just run other work in between ...
#   Run 2:  ./probe_background.sh raw  (checks whether those PIDs are still alive)
#
# A sandbox that reaps children when a call ends will report "REAPED".
set -u
OUTDIR="${1:-./raw}"
PIDF="$OUTDIR/.bg_pid"
TICKS="$OUTDIR/.bg_ticks"
echo "=== detached-process survival check  $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
if [ ! -f "$PIDF" ]; then echo "no $PIDF - run probe.sh first (it seeds the background loops)."; exit 2; fi
read -r PID WHEN < "$PIDF"
NOW=$(date +%s); AGE=$(( NOW - WHEN ))
echo "  previous run pid=$PID  seeded ${AGE}s ago"
alive=0
if kill -0 "$PID" 2>/dev/null; then
  alive=1
  echo "  verdict: STILL ALIVE across invocations (detached work survives)"
else
  echo "  verdict: REAPED (no such pid $PID)"
fi
if [ -f "$TICKS" ]; then
  n=$(wc -l < "$TICKS"); last=$(tail -1 "$TICKS")
  echo "  tick file: $n lines, last=$last (loop was designed for 20 ticks @1s)"
  [ "$n" -ge 20 ] && echo "  verdict: loop RAN TO COMPLETION unattended" || { [ $AGE -gt 25 ] && echo "  verdict: loop STOPPED EARLY after $n ticks ($AGE s available) -> killed with parent"; }
else
  echo "  tick file missing -> nohup output never landed"
fi
echo
echo "  setsid variant:"
if ls /tmp/probe_setsid_ticks* >/dev/null 2>&1; then wc -l /tmp/probe_setsid_ticks* | tail -1; fi
echo
echo "  current orphan scan (anything from earlier runs still burning CPU):"
ps -eo pid,etime,stat,pcpu,comm --sort=-pcpu 2>/dev/null | awk 'NR==1 || $4+0>20' | head -8
exit $([ "$alive" = 1 ] && echo 0 || echo 1)
