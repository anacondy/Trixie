# Probe G — GitHub-connect egress two-curl re-probe

**Date:** 2026-09-08
**Question it settles:** the Debloat GitHub-connect session (during its open PR) reported `curl 000` — no direct egress — while `git push` to github.com worked. Plain Agent Mode sessions (Trixie work, this workspace) have full egress. Is direct egress blocked in *connected* sessions, or was the 000 one-session variance?

## Routing decision: FRESH connected session (primary cell)

1. The anomaly cell is "connected session **during an open PR**". The old Debloat session is now **post-merge**; as the user noted, several capabilities the agent had before the merge may be gone after it (install-token scope / grants can change at merge). A curl result from that session therefore cannot adjudicate the during-PR observation — it would conflate "connect egress policy" with "post-merge token state".
2. Protocol spirit (round-2 routing table, line 360): characterization comparisons run **fresh** (A, C, D, F → fresh). Probe G is a C-family egress characterization ⇒ fresh.
3. The plain-side control is **already captured** (below), so exactly one new session is needed.

## Control side — DONE (plain, non-connected Agent Mode session)

`forensic/evidence/egress_probe/plain_control_run1.txt`, 2026-09-08T10:23:33Z, host e2b.local:

```
--- cmd1 ---
http=200 time=0.084391s
exit=0
--- cmd2 ---
http=200 time=0.039872s
exit=0
```

## Paste block — open a FRESH Agent Mode session with GitHub connect enabled (connect to anacondy/Debloat or any repo you own), then paste verbatim:

----
Run exactly these two commands and print the complete verbatim output of each, including the exit line. Do nothing else. Do not create, modify or delete any file.

curl -sS -m 20 -o /dev/null -w 'http=%{http_code} time=%{time_total}s\n' https://example.com; echo "exit=$?"

curl -sS -m 20 -o /dev/null -w 'http=%{http_code} time=%{time_total}s\n' https://api.github.com; echo "exit=$?"

Then print: PROBE_G_DONE
----

Paste the session's output back; I will bank it as `forensic/evidence/egress_probe/connect_fresh_run1.txt` and adjudicate against the control.

## Optional third cell — FOLLOW-UP in the OLD merged-PR Debloat session

Same two curls, labelled `connected-post-merge`. This directly tests the user's hypothesis that the agent lost abilities after the merge. Interpret separately from the primary comparison.

## Interpretation matrix

| fresh-connected result | plain control (done: pass) | Conclusion |
|---|---|---|
| fail (http=000 / exit 7 or 28) | pass | connected sessions restrict direct egress; anomaly generalizes; git worked because GitHub traffic goes through the platform's connector, not sandbox egress |
| pass | pass | the original 000 was transient/session-specific variance (env quirk of that one session) |
| fail | fail | sandbox-wide egress outage at probe time — re-run the control before concluding anything |

Cross-reads with the third cell: fail-fresh + fail-post-merge ⇒ stable connect restriction; fail-fresh + pass-post-merge ⇒ egress policy changed with merge/token state; pass-fresh + fail-post-merge ⇒ post-merge capability loss (user's hypothesis confirmed for egress).
