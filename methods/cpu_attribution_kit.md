# CPU Attribution Kit v2 — cross-platform (Windows PowerShell ⇄ Linux bash) (2026-09-24)

Question under test: is the high local CPU during Agent Mode sessions (a) ordinary client rendering of a heavy transcript (expected, benign), or (b) hidden client-side compute in arena.ai's JS? Server-side model/sandbox work is invisible locally except while tokens stream, so the two are separable. v1 was Windows-only (2026-09-15); v2 gives every command a Linux twin so the evidence is cross-platform (user migrated client OS Windows 11 → Arch/KDE/Wayland on 2026-09-24; browsers now Brave+Chrome+Firefox).

## Method — six states, one harness, correlation markers (OS-independent)

Run EITHER sampler continuously and switch the browser through these states, ~2–3 min each, noting state-change times (or use the co-op prompt's MARK lines):

- S0 baseline: browser open, NO arena tab.
- S1 arena transcript loaded, agent IDLE (no spinner, no stream).
- S2 agent STREAMING a long reply.
- S3 server-busy / NO stream: agent inside a long tool call (`sleep 90`) — spinner, no new content.
- S4 network CUT (DevTools → Offline) with the transcript open, agent idle.
- S5 static control: a LOCAL .html file of comparable size (2–4 MB plain text) in the same browser, idle.
- S6 arena tab MINIMIZED/hidden vs visible, agent idle.

Both samplers emit the SAME schema: `utc,chrome_cpu,brave_cpu,edge_cpu,firefox_cpu,net_rx_bytes_per_s` — CPU = % of one core averaged over all cores (a 1-core-pinned loop reads 100/nproc, e.g. ~50 on a 2-core host; verified in-sandbox 2026-09-24). Rows from both OSes are directly comparable.

## Interpretation matrix (OS-independent)

| Observation | Conclusion |
|---|---|
| S1 ≈ S0 (idle tab ~0% CPU) | no hidden idle compute; load is update-driven |
| S1 >> S0 sustained with static DOM and ~0 bytes received | **hidden client compute — hypothesis (b) proven** |
| S2 high but S1/S3 low | cost = streaming/rendering new DOM (benign, expected) |
| S3 high | UI polls/animates during tool calls (mild client cost, still benign) |
| S4 high | client work independent of server data (suspicious) |
| S5 ≈ S2-size DOM but << arena CPU | arena JS does extra work beyond DOM size (investigate) |
| S6 hidden drops to ~0 | rendering/animation-driven (rAF throttled when hidden) |
| S6 hidden stays high | background JS/worker compute (suspicious) |

Direct worker check (no harness needed, identical on both OSes): DevTools → Performance → record 10 s during S1. Sustained JS on Worker threads (or Main) while nothing changes on screen = client compute. Chromium Shift+Esc per-tab task manager works on Windows AND Linux; Firefox uses about:processes (memory) + the Profiler for CPU.

## Command equivalence table

| Purpose | Windows (PowerShell / GUI) | Linux (bash / GUI, Arch-KDE) |
|---|---|---|
| Continuous sampler | `cpu_sample.ps1` | `cpu_sample.sh` (this workspace; tested) |
| System CPU/RAM overview | Task Manager | `htop` (if installed; NOT in the Arena template sandbox) else `top -b -n1` / `free -h` |
| Per-browser RAM spot | `(Get-Process -Name chrome \| Measure-Object WorkingSet64 -Sum).Sum/1MB` | VmRSS one-liner below |
| Per-browser CPU spot (lifetime avg only) | `Get-Process -Name chrome \| Measure-Object CPU -Sum` | `ps -C chrome -o %cpu,rss --no-headers` (avg-since-start; use sampler for instantaneous) |
| Net RX B/s spot | `Get-NetAdapterStatistics` | `ip -s link` or the sampler's /proc/net/dev delta |
| Per-tab CPU | Shift+Esc | Shift+Esc (Chromium); Firefox about:processes/Profiler |
| Offline / worker checks | DevTools | identical (browser-side) |
| Read the CSV | Excel import | `column -s, -t cpu_sample.csv` (NOT in minimal sandbox → portable fallback `awk -F, -v OFS="\t" '$1=$1' cpu_sample.csv`, tested) |

Linux per-browser RAM one-liner (MB, working set):
```bash
for b in chrome brave firefox; do s=0; for p in /proc/[0-9]*; do [ "$(cat $p/comm 2>/dev/null)" = "$b" ] && { r=$(awk '/^VmRSS/{print $2}' $p/status 2>/dev/null); s=$((s+${r:-0})); }; done; echo "$b $((s/1024)) MB"; done
```

## Windows sampler (cpu_sample.ps1, v2 — firefox column added)

```powershell
$csv = "cpu_sample.csv"; "utc,chrome_cpu,brave_cpu,edge_cpu,firefox_cpu,net_rx_bytes_per_s" | Out-File $csv
$prev = @{}; $prevNet = (Get-NetAdapterStatistics | Measure-Object ReceivedBytes -Sum).Sum; $prevT = Get-Date
while ($true) {
  Start-Sleep -Seconds 2
  $now = Get-Date; $dt = ($now - $prevT).TotalSeconds; $prevT = $now
  $line = @((Get-Date -AsUTC).ToString("yyyy-MM-ddTHH:mm:ssZ"))
  foreach ($n in "chrome","brave","msedge","firefox") {
    $cs = (Get-Process -Name $n -ErrorAction SilentlyContinue | Measure-Object CPU -Sum).Sum
    $d = if ($prev[$n]) { [math]::Round((($cs - $prev[$n]) / $dt) * 100 / [Environment]::ProcessorCount,1) } else { 0 }
    $prev[$n] = $cs; $line += "$d"
  }
  $net = (Get-NetAdapterStatistics | Measure-Object ReceivedBytes -Sum).Sum
  $line += [math]::Round(($net - $prevNet) / $dt,0); $prevNet = $net
  ($line -join ",") | Out-File $csv -Append
}
```

## Linux sampler (cpu_sample.sh, v2 — tested 2026-09-24; save +x, run `./cpu_sample.sh [out.csv] [interval]`)

```bash
#!/usr/bin/env bash
set -u
CSV=${1:-cpu_sample.csv}; INTERVAL=${2:-2}
NPROC=$(nproc); CLK=$(getconf CLK_TCK)
echo "utc,chrome_cpu,brave_cpu,edge_cpu,firefox_cpu,net_rx_bytes_per_s" > "$CSV"
ticks() { # $1 = exact comm name -> sum(utime+stime) ticks over matching PIDs
  local t=0 f line comm rest
  for f in /proc/[0-9]*/stat; do
    [ -r "$f" ] || continue
    IFS= read -r line < "$f" 2>/dev/null || continue
    comm=${line#*(}; comm=${comm%)*}
    [ "$comm" = "$1" ] || continue
    rest=${line##*) }
    set -- $rest
    t=$(( t + ${12:-0} + ${13:-0} ))
  done
  echo "$t"
}
rxbytes() { awk -F: 'NR>2 { if ($1 !~ /^ *lo$/) { split($2, a, " "); rx += a[1] } } END { printf "%.0f", rx+0 }' /proc/net/dev; }
declare -A PREV
PREVNET=$(rxbytes); PREVT=$(date +%s.%N)
while true; do
  sleep "$INTERVAL"
  NOWT=$(date +%s.%N); DT=$(awk -v a="$NOWT" -v b="$PREVT" 'BEGIN{printf "%.3f", a-b}')
  LINE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  for b in chrome brave msedge firefox; do
    T=$(ticks "$b")
    if [ -n "${PREV[$b]:-}" ]; then
      D=$(awk -v t="$T" -v p="${PREV[$b]}" -v dt="$DT" -v n="$NPROC" -v c="$CLK" 'BEGIN{ d=((t-p)/c)/dt*100/n; printf "%.1f", (d<0?0:d) }')
    else D="0.0"; fi
    PREV[$b]=$T; LINE="$LINE,$D"
  done
  N=$(rxbytes); ND=$(awk -v n="$N" -v p="$PREVNET" -v dt="$DT" 'BEGIN{ printf "%.0f", (n-p)/dt }'); PREVNET=$N
  echo "$LINE,$ND" >> "$CSV"
  PREVT=$NOWT
done
```
Parser verified: utime/stime = /proc stat fields 14/15 (offsets 12/13 after the comm strip), cross-checked against raw stat; calibration loop pinned to one core read 49.9–50.3 on nproc=2.

## Co-op prompt (paste into the Arena session; gives clean S1/S2/S3 windows; OS-independent)

```text
Cooperation protocol for a local CPU-attribution experiment on my machine.
Print a UTC timestamp line before and after EACH step, exactly in order:
1. MARK IDLE-START → then sleep 60 (one Bash call) → MARK IDLE-END
2. MARK STREAM-START → then stream ~1500 words of repetitive filler text → MARK STREAM-END
3. MARK TOOL-START → then sleep 90 (one Bash call, no output while running) → MARK TOOL-END
4. MARK DONE
No other tools, no file writes, keep the transcript small. Do not comment between marks.
```

Report back the CSV + state log (from either OS) and I adjudicate (a) vs (b). Prior Windows datapoints (idle 11% total; activity 45%) used the 3-browser v1 schema — comparable modulo the added firefox column.

## Tested matrix (2026-09-24)

| Command | Arena template sandbox (Debian trixie) | User's Arch/KDE (from screenshots) |
|---|---|---|
| `nproc`, `getconf CLK_TCK` | OK (2 / 100) | OK (4 / 100) |
| `top -b -n1`, `free -h` | OK (procps-ng 4.0.4) | OK (procps-ng 4.x, same syntax) |
| `htop` | **MISSING** (minimal image) | OK (user ran it) |
| `ps -C <b> -o %cpu,rss --no-headers` | OK, rc=1 on no match (expected) | OK |
| `ip -s link` | OK (iproute2) | OK |
| `column -s, -t` | **MISSING** → awk fallback tested OK | OK (util-linux) |
| awk (sampler) | mawk 1.3.4 — sampler verified | gawk — same POSIX constructs |
| bash (assoc arrays, /proc parsing) | 5.2 — sampler verified | 5.2 |
| `cpu_sample.ps1` | parse-clean under real pwsh 7.4.6 (ERRORS=0; parser args tokens-then-errors); runtime needs Windows (`Get-NetAdapterStatistics` is Windows-only) | legacy Windows twin; never runtime-executed — Windows datapoints came from Task Manager shots |
| `date +%s.%N` / UTC form | OK (coreutils) | OK |
| Shift+Esc / about:processes / DevTools | browser-side, identical | browser-side, identical |

Version-mismatch verdict: no breaking drift between Debian-trixie and Arch for anything the kit uses; the only absences are optional packages (htop, column), both covered by tested fallbacks. PowerShell twin not testable in this Linux sandbox — unchanged from v1, which ran on the user's former Windows 11 box.
