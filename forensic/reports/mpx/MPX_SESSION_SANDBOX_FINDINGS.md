# MPX session — sandbox-relevant extraction (received 2026-09-24)

Provenance: separate agent session (user-stated: lmarena surface, Brave) that built the MPX media player over 5+ bursts on 2026-09-24. 13 files uploaded; 3 screenshots. **Authenticity: all six hashes printed in the reports/index match the uploaded bytes exactly** (KDE_DESKTOP_RAW af002f7b…, startup_raw e564052f…, sync_raw d87a2a4b…, KDE_DESKTOP_TEST 8cb4fb31…, STARTUP_FORENSICS d244dce3…, EVIDENCE_INDEX 5f28b45f…; line counts 45/16/1171/254/254/86 match; screenshots show the same shas printed in-session). Ledger discipline genuine (append-only BashTracker 1435 lines, MEASURED/INFERRED/NOT MEASURED taxonomy, immutability policy); limitations honestly declared.

## Sandbox fingerprint (Burst 1 baseline + Burst 5 env line)
- `Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64` — **same kernel stamp as our class-T lock**, 20 days after our Sep-4 round-1.
- Debian 13.6 trixie; `MemTotal: 2032608 kB` — **identical to class-T**; `E2B_SANDBOX=true`, hostname e2b.local.
- Headless: `XDG_SESSION_TYPE/DISPLAY/WAYLAND_DISPLAY/XDG_RUNTIME_DIR/DESKTOP_SESSION` all empty; no plasmashell/kwin; no `/dev/dri`; no `lspci`; no pactl/wpctl/aplay; ALSA no card → SDL offscreen fallback. **Consistent with class-T headlessness; adds /dev/dri+lspci+ALSA-absent as cheap future probe items.**
- No git repo in workspace (`git` EXIT 128) — matches our sandbox default.
- Toolchain present at 14:00Z: gcc 14.2.0-19, cmake 3.31.6, ninja 1.12.1, libavformat 61.7.103 (FFmpeg 7.1.5), SDL2 2.32.4, SDL2_ttf 2.24.0. **Origin UNDECIDED**: BashTracker starts at Burst 1; dev-phase installs (Burst 0) untracked; no apt lines in tracker. Our class-T sessions only ever showed ffmpeg *CLI* absent, never probed pkg-config dev libs — so this does NOT prove a different template.
- **MISSING platform identity**: no `/.e2b`, no `E2B_TEMPLATE_ID`, no sandbox_id, no boot_id, no cgroup memory.max/cpu.max, no nproc/cpuset anywhere in the 13 files. ⇒ cross-check required before claiming same-template.

## Why it matters if identity matches
Same kernel stamp + MemTotal + e2b.local on 2026-09-24 on a different surface ⇒ the class-T base image is still provisioning 20 days on. A follow-up boot_id equal to `2bb79165-136a-4b63-829d-17027b0a8e40` would extend the snapshot-lineage finding across surfaces AND dates; a different boot_id = newer snapshot of same base (also informative).

## Viewer behaviour cross-confirmed on another session/surface (screenshots)
- CSV rendered as a styled TABLE (KDE_DESKTOP_RAW) — matches our csv→TABLE finding.
- Viewer = single-file panel with dropdown FOLDER tree (build-native/, docs/) — exactly the corrected-F2 navigation model; nested files selectable.
- Markdown renders with embedded image (README astronaut PNG) — md+embedded-image P.
- Agent batches tool calls ("Ran commands 6") — batching present there too.
- Not platform evidence but provenance: the burst prompts reuse our ledger discipline (numbered deliverables, NOT MEASURED convention, no ratings, STOP).

## Project-scoped data (NOT platform evidence; recorded only)
Startup mean 7.08 ms (15 runs); steady-state VmRSS ~50.2 MiB CV 0.19%; sync CV 0.38 jitter 0 drops; binary da83dcd9…/BuildID 66217ff…; audio FAIL (no device) — all headless-dummy only, reports say so themselves.

## Open items → mpx_crosscheck_prompt.md
Follow-up in the SAME session first (prints /.e2b, E2B_*, boot_id, cgroup, nproc, apt history, ledger sha tie-in). Fresh lmarena session only if MPX session is dead/reset or for a clean surface-comparison datapoint.

## Variant A results (run in same MPX session, 2026-09-24T15:03:23Z) — CONSOLIDATED
- ENV_ID=TEMPLATE_ID=**nlhz8vlwyupq845jsdg9** ; BUILD_ID=**f34a5416-ef30-4cb7-8e18-0fdecd6eb529** ⇒ same product template AND same Agent-Mode build as our arena.ai sessions, on the lmarena surface. Cross-surface template equivalence CONFIRMED.
- E2B_TEMPLATE_ID=**gt0vxc01lr4s6t6w21ot** — runtime E2B template differs from product ID; third distinct runtime ID observed (after nlhz itself and transient wk9vh0w7zre9vbcia51p) ⇒ runtime E2B template IDs vary per boot while product TEMPLATE_ID/BUILD_ID stay constant. Consistent with snapshot-restore model.
- E2B_SANDBOX_ID=ifp6k9fntmb3pqkjxiqtp (new instance, as expected).
- boot_id=**2bb79165-136a-4b63-829d-17027b0a8e40** — IDENTICAL to all our round-2/3 accounts (Sep 4/6), now on another surface and 20 days later ⇒ snapshot-lineage finding EXTENDED across surfaces+dates. High confidence.
- cgroup cpu.max "max 100000", memory.max 1947172864, cpuset 0-1 both paths; nproc 2; Xeon @2.60GHz ×2; taskset -c 2 EINVAL; NO_DRI — every class-T lock value identical.
- apt history RESOLVES the toolchain-origin question: `apt-get install -y cmake pkg-config libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libsdl2-dev` ran in-session ⇒ template does NOT ship the SDL/FFmpeg stack; base template remains pristine class-T. /usr/bin/ffmpeg present via session installs; lspci/valgrind still absent.
- ANOMALY: `sha256sum /home/user/docs/BashTracker.md` → No such file or directory, while /home/user/build-native/mpx survives with the exact baseline hash da83dcd9…. Partial workspace loss inside the session — consistent with reset-snapshot behaviour (unsaved/late files lost, earlier artifacts kept); cause not proven (alternative: deletion/move). User holds the 1435-line copy. Optional one-liner to close: `ls -la docs/ /home/user/docs/ 2>&1`.
- Paste cosmetics: chat UI linkified filenames ([BashTracker.md](http://…)) — cosmetic only; the underlying error is real.

## Corrections (user, 2026-09-24 evening; screenshots Screenshot_20260924_2039xx..2042xx) — SUPERSEDES parts above
1. **BashTracker.md EXISTS** (visible in the viewer tree, user-stated). My "partial workspace loss" anomaly was WRONG: the sha256sum error was a link-mangling artifact — the executed command literally contained the markdown-mangled path `'/home/user/docs/[BashTracker.md](http://…)'` (visible verbatim in the session output), so the shell looked up a nonsense filename. The mpx half of the command ran fine. Reset-loss finding from the timekeeper arc stands on its own evidence; this datapoint is RETRACTED.
2. **Client migration:** user's machine (same HP 14s-dy2xxx, i3-1115G4, 8 GiB) moved from Windows 11 to **Arch Linux + KDE Plasma 6.7.5 (Wayland, kernel 7.2.6-arch2-1, Qt 6.11.2)**. ALL earlier client-side datapoints (Task Manager 83-88% RAM, per-browser CPU) are Windows-era; new Arch baseline: htop 5.53G/7.40G used, swap 368K/3.70G, uptime 2:09:19, load 1.10, with Brave+Chrome+Firefox+KDE running. The `Screenshot_…png` names are KDE Spectacle's pattern (saved to /home/simone/Pictures/Screenshots) — my "Android-style naming ⇒ maybe another device" guess was WRONG.
3. **Browsers (user ground truth + menu proof):** MPX session = **Firefox** (screenshot 204256 shows the Firefox menu: "Sign in to sync", fox avatar, Quit Ctrl+Q; URL bar arena.ai/agent/**01a0d320-64ad-7531-9ccb-82a54b800bac** ⇒ surface is arena.ai, not lmarena — user's "lmarena" statement vs URL bar; log both). This research chat = **Brave** (user-stated). My ~40% Edge guess was WRONG. The red-lion profile avatar in the Firefox MPX session = acct3 profile ⇒ avatar tracks ACCOUNT, not browser (account≠browser re-confirmed).
4. Implication: class-T lock + boot_id 2bb79165… now observed via Chrome, Brave, Edge AND Firefox clients, on Windows 11 AND Arch — client-independence of the sandbox fingerprint strengthened. cpu_attribution_kit's PowerShell sampler is Windows-only; a Linux (top/ps) variant is needed for future client-side attribution on Arch.
