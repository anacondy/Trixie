# Cross-Verification Kit — Vulkan-Typing-Studio status + Arena session-A rejection
Date of kit: 2026-09-13. All facts below were re-verified live on this date; repo state can change — always re-run Prompt A before acting on old numbers.

This kit integrates three independent browser-run verifications (Chrome plan, Edge report, Brave protocol, 2026-09-13) plus a fourth live re-audit (this session), keeping the strongest element of each and correcting every known defect.

---

## PROMPT A — Independent GitHub audit (paste into a FRESH Agent Mode session, unconnected or connected; read-only)

```text
You are an independent verification auditor. Treat every claim below as an
allegation, not a fact. Do not modify any repository, release, branch,
workflow, or session. Query the public GitHub REST API yourself this turn;
cite the exact endpoint and JSON field for each finding. If you cannot
verify something, say "Not publicly verifiable" — never guess.

Repository: anacondy/Vulkan-Typing-Studio   Audit date: <fill in, UTC>

Checks (report each as CONFIRMED / REFUTED / UNVERIFIABLE + one-line evidence):
1. GET /repos/anacondy/Vulkan-Typing-Studio — private, default_branch, pushed_at.
2. GET /repos/.../commits/main — full HEAD sha, committer date, message.
3. GET /repos/.../branches?per_page=100 — every branch name + tip sha.
   Note any branch containing 01a02a0c, 01a02435, 01a02a28. If a branch is
   absent, say only "not currently visible" — absence now does NOT prove
   "never pushed".
4. GET /repos/.../compare/main...arena/01a02a0c-vulkan-typing-studio and
   .../compare/main...arena/01a02435-vulkan-typing-studio — report status,
   ahead_by, behind_by, and whether merge_base sha equals the branch tip sha.
   "Fully merged" is defined as ahead_by == 0 (branch tip ancestor of main);
   it does NOT mean equal to main, and merge-base equality does not prove
   HOW the commits entered main.
5. GET /repos/.../releases/tags/v0.7.0 — draft, prerelease, published_at (UTC),
   author.login, target_commitish; FULL asset names (do not strip any
   prefix), sizes in bytes, download counts; quote the first four lines of
   the body and state whether it still contains "DRAFT — not yet published"
   / "Do not publish".
6. GET /repos/.../actions/workflows and /actions/runs?per_page=10 — every
   workflow (name, path, state), run count, latest conclusion + date +
   head_sha. State explicitly whether ANY workflow builds release archives.
7. GET /repos/.../contents/.github and /repos/.../contents/release — list
   entries; state whether .github/workflows exists and whether
   release/build-packages.sh exists.
8. GET /repos/anacondy/Teliya-mirror — record the HTTP status only; a 404
   means private OR other-owner OR missing; do not pick one without a token.

Allegations to score (from a prior agent write-up, 2026-09-13):
- main @ 6026e766e353681b338c63a12b4b08d17fab2443, pushed 2026-09-02T10:20:18Z
- exactly three branches: main, arena/01a02a0c-vulkan-typing-studio @ f8e19ec,
  arena/01a02435-vulkan-typing-studio @ af0e9ac; no branch containing 01a02a28
- both arena branches fully merged (ahead_by 0; behind_by 2 and 6 respectively)
- v0.7.0 published 2026-08-22T15:54:01Z, draft false, uploader anacondy,
  exactly five assets: SHA256SUMS.txt, Vulkan-Typing-Studio-Linux-x64.tar.gz,
  Vulkan-Typing-Studio-macOS-universal.tar.gz,
  Vulkan-Typing-Studio-Windows-x64.zip, Vulkan-Typing-Studio-Windows7-Portable.zip
- release body still contains the DRAFT / Do-not-publish warnings
- only workflow is GitHub-managed pages-build-deployment; no package-build
  workflow; release/build-packages.sh exists in-tree; assets were uploaded off-CI
- Teliya-mirror 404 unauthenticated

Output: (1) verdict table; (2) raw field dump; (3) discrepancy list vs the
allegations; (4) every endpoint used; (5) UTC timestamps of your calls.
Do not create, publish, edit, or upload anything.
```

## PROMPT B — Session-rejection experiment (YOU run this; no agent can see Arena routing)

Capture first (once, on dead session A `01a02a28-7bd1-79fc-a119-ee1ce492c8ba`):
- exact error banner text (copy, do not paraphrase);
- DevTools → Network → the stream/eval request of one send: HTTP status + response JSON if any (429 = rate limit; 413 = payload; 400/403 = policy/routing; 5xx = service);
- model picker value if visible; GitHub-connect state; idle duration.

Byte-identity rule: keep the original long prompt in a .txt; record `wc -c` and sha256sum; paste from that file, never from a rendered chat bubble (rendered `&amp;` is a display artifact unless the textarea itself holds the entity).

Matrix (one change per trial; record accept/reject + whether any tool ran):
| ID | Trial | Accept means | Reject means |
|---|---|---|---|
| T1 | A + `ping` | transient flap | trigger is session-level (not payload) |
| T2 | FRESH session, Vulkan connected, original prompt (byte-identical) | A's stored state is the trigger → abandon A | prompt is globally rejectable → prior diagnosis wrong |
| T3 | FRESH session, NO GitHub connect, same prompt | connect not involved | connect factor |
| T4 | A + switch model (if picker) + `ping` | H1 stale-route/pin | H2 transcript-level |
| T5 | A in other browser / hard refresh + `ping` | client-side | server-side |
| T6 | wait 30–60 min, A + `ping` | transient rate limit | persistent |
| T7 | fresh session: raw `&` vs literal `&amp;` vs `&amp;amp;` variants | encoding not a trigger (expected) | encoding trigger |

Decision rules: T1 reject + T2 accept → session-specific failure; stop retrying A; file support report with Eval ID = session UUID, banner text, Network capture, and the fact that B and fresh sessions accept the same bytes. T1 accept → transient; note and move on. T2 reject + T3 accept → connect involvement (would refute all four audits). All reject → account/service-level issue.

Platform anchor (verified live 2026-09-13): the EXACT error string has its own article —
https://help.arena.ai/articles/7703465955-arena-troubleshooting-the-ai-service-rejected-this-request-error-message
Documented causes: image sent to text-only model; bad/unsupported attachment; too many images; **conversation longer than the model can read at once**. Documented fix: remove attachments, switch model, or **start a new conversation / shorten the message**. Sibling articles (linked from it): session token limits 3975292349, daily usage limits 3295820808, generic "Something went wrong" 1645798556. (Brave also cited rate-limits article 8931786544 — not independently re-fetched by this kit.)
Consequence: the "long stored transcript at resume" mechanism (H2) is platform-documented, not speculation; the documented remedy is exactly "start a new conversation".

Stop rule: after T1 reject + T2 accept, A is done. One support report, then forget it.

## PROMPT C — Corrected Copilot / connected-agent prompt (Vulkan repo work)

```text
Work in anacondy/Vulkan-Typing-Studio (default main; expect HEAD
6026e766e353681b338c63a12b4b08d17fab2443 or newer — verify with
git rev-parse HEAD first).

Verify before editing (report each): gh release view v0.7.0 --json
tagName,draft,publishedAt,assets,body; ls .github/workflows (expect: absent);
test -f release/build-packages.sh (expect: present). Real asset names are
SHA256SUMS.txt, Vulkan-Typing-Studio-Windows-x64.zip,
Vulkan-Typing-Studio-Linux-x64.tar.gz,
Vulkan-Typing-Studio-macOS-universal.tar.gz,
Vulkan-Typing-Studio-Windows7-Portable.zip — use full names everywhere.

Constraints: new branch + ONE pull request only. Do not push to main, do not
create/publish/delete a release, do not upload assets, do not push tags.

Task 1 (workflow): add .github/workflows/release-packages.yml — trigger on
push tags v*; checkout tagged source; run bash release/build-packages.sh;
upload the four archives + SHA256SUMS.txt to the tag's release
(gh release upload --clobber or softprops/action-gh-release); no network
beyond GitHub; fail loudly if expected files are missing. Document tag
format, expected filenames, local reproduction, and the first-tag-run
checklist.

Task 2 (release notes): a PR CANNOT edit the already-published release body.
Instead: extract the body (gh release view v0.7.0 --json body --jq .body),
produce cleaned-release-notes.md deleting the "Status: DRAFT — not yet
published … Do not publish the release yourself" lines and the
"Publish steps (after the PR…)" section while KEEPING the asset table, hash
references, known limitations, and reproduce instructions; include the file
in the PR for my approval; only after I approve in chat may you run
gh release edit v0.7.0 --notes-file <approved> (live edit — never run it
without my explicit go-ahead).

Return: PR URL, changed files, test commands + results, workflow design
summary, risks/assumptions. Do not merge.
```

## How to run this testing (protocol)

1. Facts track: run Prompt A in one fresh session per browser (you already have the Chrome/Edge/Brave pattern); plus your own `curl` one-liners as a fourth leg. Adjudicate by 2-of-3 agreement with the live API as tie-breaker; any disagreement is a finding, not noise.
2. Causation track: run Prompt B yourself (agents cannot); it is the only track that can close the question, and article 7703465955 already makes the likely answer and the remedy explicit.
3. Work track: Prompt C goes to a connected agent or Copilot ONLY after the facts track confirms the allegations on the same day.
4. Every run must print: endpoints/commands used, UTC timestamps, CONFIRMED/REFUTED/UNVERIFIABLE per claim. Runs that narrate without showing endpoints score as UNVERIFIABLE.
5. Re-run Prompt A before any action if more than 24 h old.
