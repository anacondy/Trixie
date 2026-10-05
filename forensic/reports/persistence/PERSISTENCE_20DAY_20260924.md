# Persistence Round — 20-day boundary (2026-09-24)

Strongest persistence result of the study. Round-1 original sessions (Sep 4) located via
arena.ai history search, reopened after 20 days idle, and answered a read-only check.
Both RESUMED AND RESPONDED ⇒ idle time is NOT the hard-reject trigger (01a02a28's
rejection is best explained by context size/turn count).

## Sessions — 3/3 answered
| Original browser (filename truth) | Chat session | Sep-4 sandbox id | 2026-09-24 sandbox |
|---|---|---|---|
| Brave | 01a06bd5-f0aa-7dcc-9fcc-03ab65718e14 | i0v44lh3n78xffvhm6u5u, i4i7wdij5c7gh9absvtu8, i54yseeebo34z5jxzvoju (3 turns) | ivd0qccvplpnv2fyhlwfv |
| Chrome | 01a06be4-48f4-7667-bc59-adea71991e3a | i0m9mhony51frr3osghn0 | ihmmvpabz6onhovkt9m0q |
| Edge (account_c; reopened in **Firefox** post-migration, same Arena account — user-stated) | 01a06c52-f3ee-77f7-839b-7616d291dd28 | ixwcucmrk55t9qy240sxo | i9n3se90nxu8t53uvivwh |

(Note: my prompt quoted the Brave ids with 2-3 transcription errors from the screenshot;
both agents corrected the premise from their own records — the honesty discipline held.)

## Shared observations (both)
- E2B_TEMPLATE_ID nlhz8vlwyupq845jsdg9 unchanged; boot_id 2bb79165-136a-4b63-829d-17027b0a8e40
  (8th identical observation; round-1 files prove it was already the value on Sep 4 ⇒
  image NOT refreshed during the study; Brave agent's "boot_id is new" was loose phrasing —
  it used boot_id as a boot discriminator, the exact C2 trap its own prompt forbade; its
  fresh-VM conclusion still stands on sandbox id + uptime).
- uptime 11.34 s (brave) / 12.45 s (chrome); all /home/user mtimes = Sep 24 17:22 restore
  stamp ⇒ fresh microVM materialised from the session snapshot (regime b).

## Integrity
- Brave: envchar/MANIFEST.txt sha256 35f3a3e9e1119feb7ed7c924f1d078bf9c7a256e3f2b0ecfeff9bedf7b614fcf
  matches the Sep-4 original; generated_utc 2026-09-04T13:45:05Z intact; every Sep-4
  deliverable present (environment_characterization.md, envchar/ + raw/, _envchar/,
  00_ZIP_INDEX.md, Agent 2 brave.zip). Only /home/user/__envchar absent — never existed.
- Chrome: envcheck/TIMELINE.csv re-hash = 148/148 byte-identical, 0 missing/size/hash changes;
  Agent 4 chrome.zip sha256 0f01d761ded3ddf9ec755bc7ce289029e093e172748f72a179e7054da769662b
  bit-for-bit the Sep-4 value; shipped checker: 150 entries verified, 0 mismatches, PASS.

## What did NOT survive (as predicted)
- /tmp, /dev/shm wiped; .cache/.npm/.local/.config gone — exactly the snapshot-excluded
  paths. Chrome agent's honest caveat: /usr/local pip-state indistinguishable
  (persisted vs reverted-to-image) ⇒ UNCHECKED, not a pass.

## Bonus datapoint
- Chrome ZIP_METADATA divergence resolved retroactively: packaging shell on Sep 4 saw
  template gujonb0q163l15z30yc7 while transcripts said nlhz…; today's nlhz… confirms the
  transcripts were accurate and the odd value was that turn's harness env ⇒ 5th distinct
  runtime template id in the lineage ⇒ per-turn harness variance is real.

## Verdict
Cross-boundary /home/user persistence: PASS at 20 days, hash-verified, two browsers.
Session resumability at 20 days idle: PASS ⇒ rejection model = context-size-driven.
This closes the wiki "Open" item "Persistence turns 2/3" with a stronger instrument.
