# Round 2 — Tanner's feedback on V2-HARNESS-REVIEW.html + corrections (SAVE-ALL-WORK anchor)

> Resume anchor for the second pass. The deliverable HTML needs a REWRITE (plain 6th-grade English, no jargon,
> teachable deeply) + folding 9 notes. Background work is persisting to disk. Where this disagrees with earlier
> docs, this wins (later-doc convention).

## Tanner's 9 notes (verbatim intent)
1. **Kick off via Slack or Linear** — make these FIRST-CLASS entry points (not "after the GitHub label").
2. **Not so GitHub-focused** — some projects use GitLab. Be git-host-agnostic.
3. **/goal is already built into Claude — don't build a new one.** (CONFIRMED — see facts below.)
4. **User stories** — how does someone submit a feature? how is it confirmed SPEC'd so code is world-class? how
   does a bug get submitted/kicked off → reviewed at PR time (or earlier if human decisions needed)? other use
   cases + flows? what does that teach us?
5. **World-class review** — we have lots of review research and the page barely touched it. How are we making
   review world-class? How are agents safe to run up to a PR AND humans best able to catch bugs?
6. **Test verification** — easy to write green tests even with /tdd. How are the tests VERIFIED?
7. **3-pass the Ranger article** (https://outpost.ranger.net/post/why-youre-overthinking-background-agents/) +
   Notion write-up.
8. **REWRITE in 6th-grade English, remove ALL jargon, teachable deeply.** (The dominant directive over everything.)
9. **How do individual repos' agents get better AND the global harness? Show the process.**

## /goal + Claude Code primitive FACTS (from claude-code-guide, official docs) — fold these
- **`/goal <condition>` is NATIVE** (v2.1.139+, June 2025). English condition; a fast model (Haiku) checks it each
  turn; agent auto-continues until met. Headless: `claude -p "/goal ..."`. Clear with `/goal clear`. Docs:
  code.claude.com/docs/en/goal.md. → **REMOVE the "new /goal skill" from the roster. USE the built-in.** (This was
  a phantom — exactly the anti-phantom failure the effort should catch.)
- Native loop/schedule: **`/loop [interval] [prompt]`** (session-scoped repeat); **`/schedule <desc>`** = cloud
  ROUTINES (run on Anthropic infra; triggers = schedule / **generic webhook API (HTTP POST + bearer token)** /
  **GitHub event** / issue-label-via-GitHub; survives sleep); **`/background`** (detach session, 7-day resume).
- **Plugins/marketplaces are GIT-HOST-AGNOSTIC**: `claude plugin marketplace add <git-url>` takes any git host;
  private marketplaces self-host on GitLab/Gitea/any. Only Anthropic's PUBLIC curated marketplaces are GitHub-pinned.
  → GitLab is fully supported for our plugin + canon-in-repo.
- **Trigger front-door (host-agnostic):** Slack/Linear/any external event → (MCP connector OR a webhook) →
  a `/schedule` routine's **generic webhook/API trigger** → the agent in a worktree. GitHub events have a native
  trigger; **GitLab CI / generic CI has NO native Claude action** → use the **generic webhook→routine** or the
  **Agent SDK** for a custom runner. (Honest gap to state: the bug→PR runner on non-GitHub hosts is webhook→routine
  or SDK, not a native action.)

## Corrections to fold into the design + the rewrite
- DROP the new `/goal` skill; L2 = "use the built-in `/goal` continuation loop." (Frees the spine of a phantom.)
- Trigger front-door = `/schedule` routines (native webhook/API + GitHub-event); Slack/Linear via connector/webhook;
  ALL host-agnostic. Replace "GitHub Action" framing with "a routine triggered by a webhook from your tracker/chat."
- Replace GitHub-specific words everywhere: "your git host", "pull/merge request (PR/MR)", "CI pipeline",
  "protected branch", "issue/ticket". GitHub AND GitLab. Plugin + canon-in-repo + CI gate all generalize.
- Slack/Linear are first-class kickoff doors, equal to a repo label.

## Background work running (persists to disk — harvest from disk)
- **WF deep-dives** (run wf_95cf2888-d76): 4 doers + 4 checkers → `design/v2/deepdive/{user-stories, world-class-review,
  test-verification, dual-learning-loop}.md` + `design/v2/deepdive/checks/*.md`. Folds the corrections.
- **Ranger 3-pass** (agent ab2071a7…): → `passes/ranger-background-agents/pass1|2|3.md`. Then I write the Notion
  page from MAIN context (WAF blocks sub-agent Notion writes on security terms — feedback_notion_write_waf_block).
- **/goal verify** (agent a21487…): DONE → facts captured above.

## STATUS (session limit hit 3rd time — resets 7:50pm Denver)
- **HTML REWRITE: ✅ DONE** (`V2-HARNESS-REVIEW.html`, 360 lines, offline). Folds ALL 9 notes: plain 6th-grade
  English + word-list; 6 user stories (feature w/ spec-first gate, bug w/ early-stop, incident, refactor, deps,
  discovery) + "what they teach"; world-class review section (independent reviewer, 4 lenses, REJECT, governance
  lens, calibration, the layered-defense ordered list, the <15-min scannable PR + human checklist) + honest
  keystone; test-verification section (no-transcription, red-before-green, MUTATION TESTING [new], property tests,
  test-quality review lens, "how we know a test is real" checklist); the two learning loops (local example
  tenant-scope mistake→impossible; global push-up→/plugin update) shown as process; Slack/Linear first-class;
  GitHub-OR-GitLab throughout; /goal = built-in (phantom removed); honest gaps + risks; harvest method + its own
  trap; decisions (7 consolidated, plain). The HTML is the assembled position.
- **deep-dives (wf_95cf2888): FAILED on limit, nothing persisted.** BUT their substance was authored directly
  into the HTML by the main loop — the user's content ask is delivered. (Optional: re-run after reset for the
  standalone proof-of-process artifacts.)
- **Ranger 3-pass (#7): ✅ DONE.** WebFetch works from MAIN loop even under the agent session limit. pass1 was
  saved by the dying agent (harvest-from-disk worked); pass2+pass3 authored by main loop. Files:
  `passes/ranger-background-agents/pass1|2|3.md`. **Notion write-up created (main context — no WAF block):**
  https://app.notion.com/p/37de2971cd6281da9bdae3f81496e313 (under "Research Intake — Agent Harness").
  **KEY FINDING (a real new design lever):** *isolation-by-construction.* Ranger runs PROD background agents on
  ~100 lines of safety because the agent has NO prod blast radius (disposable DB branch + no external IP + a
  SANDBOX_ENV outbox that captures side-effects). Our floor is heavy mostly because our `.env.local` points at
  PROD. → **NEW fork: "isolation-first floor"** — give the agent a disposable Supabase DB branch + no prod keys,
  then DEMOTE parts of F2/F3/F5 (remove the danger instead of guarding it). + **ADOPT the SANDBOX_ENV outbox**
  (capture every side-effect in unattended mode; complements disable-model-invocation). Keep our review/test depth
  (the article is silent on trust-the-output, which our charter centers on). Bounded check: is Supabase branching
  fast enough for a per-job DB? NOT yet folded into the HTML — surfaced to Tanner as a finding.

## ALL 9 NOTES ADDRESSED ✅ (HTML rewritten; Ranger researched+Notion'd; corrections folded)
1 Slack/Linear first-class ✅ · 2 git-host-agnostic (GitHub OR GitLab) ✅ · 3 /goal=built-in ✅ · 4 user stories ✅ ·
5 world-class review (deep) ✅ · 6 test verification + mutation testing ✅ · 7 Ranger 3-pass + Notion ✅ ·
8 6th-grade rewrite ✅ · 9 dual learning loop ✅.

## ROUND 2 — FINAL STATE (all done)
- **Deep-dive standalone artifacts RE-RUN ✅** (run wf_f56a930d) → `design/v2/deepdive/{user-stories, world-class-
  review, test-verification, dual-learning-loop}.md` + `/checks/*.md` (~26k words, doer≠checker). The checkers
  caught 6 real OVER-CLAIMS that were also in the HTML (I'd authored it from the same understanding) — all folded:
  (1) spec-first is SIZE-GATED (Medium+ only; tiny = the failing test is the spec); (2) the early human-stop is real
  for auth + DB-shape but NOT money-math (money-math caught LATE at review; early stop = a gap to add); (3) the
  front-door router that routes Slack/Linear/issue → the right path is NOT built — it's a NEW piece (the real
  blocker for "Slack/Linear first-class"); (4) lead with the bugfix-test-guard (a fix needs a test that fails-then-
  passes), test-count-never-decreases is the weaker version; (5) "<15 min review" was INVENTED — removed; real
  finding = reviews degrade past ~a few hundred lines, so keep PRs small; (6) mutation testing only covers PURE
  functions (math), NOT DB-touching code (verified differently vs a practice DB) — coverage stated honestly.
- **ISOLATION-FIRST ("practice copy") folded into V2** ✅ — HTML §7 (plain English, no jargon) + VISION.md F0 move.
- **Jargon swept: 0** instances of isolation-first/blast-radius/egress/deterministic/sandbox in the HTML.
- Memory `feedback_teachable_explanations` reinforced (jargon corrected twice in one session).
- World-class-review + test-verification deep-dives graded GENUINELY good by their checkers (real research use,
  honest keystone, mutation tool is real/maintained) — only readiness over-claims, all folded.

## ROUND-2 ORIGINAL NEXT (now done)

## NEXT (after reset if needed)
1. Notion write-up of the Ranger 3-pass (from main context; place under the Research corpus; tell Tanner the URL).
2. **REWRITE `V2-HARNESS-REVIEW.html`** in plain 6th-grade English, no jargon, teachable — folding all 9 notes:
   the corrections (1/2/3), the user stories (4), world-class review (5), test verification (6 — likely ADDS
   mutation testing + a test-quality review lens), the dual learning loop (9), and what Ranger (7) teaches about
   whether we're over-engineering. Lead with concrete stories + analogies; define every term inline; short sentences.
3. Keep the honest keystone (deterministic un-forgeable; judgment trust-but-verify measured) and the honest gaps.
