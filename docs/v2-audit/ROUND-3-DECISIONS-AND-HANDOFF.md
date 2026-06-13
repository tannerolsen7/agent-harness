# V2 Harness — Round 3 Decisions & Next-Session Handoff (READ THIS FIRST)

> Tanner reviewed `V2-DECISIONS.html` (the deck) and gave decisions + corrections + new requests, then said
> "save your work and start a new conversation." This is the clean resume point. The deck has NOT yet been
> refreshed with these answers — that's a next-session task (item 5 below).

## Deliverables (current)
- **`V2-DECISIONS.html`** — the short, decidable deck (the primary artifact). *Needs refresh per below.*
- **`V2-HARNESS-REVIEW.html`** — the full plain-English write-up (reference).
- **Design:** `design/ambition/VISION.md` (43 moves, 5 pillars), `design/v2/{roster,file-tree,memory-model,
  github-usage,gaps-risks,simplification-pass,git-commit-pr-structure}.md`, `design/v2/deepdive/*`,
  `design/v2/CORRECTIONS-LEDGER.md`, `design/v2/ROUND-2-FEEDBACK-AND-CORRECTIONS.md`.
- **Memories:** `project_harness_multi_repo_reality` (5 repos, not 1; isolation conditional),
  `feedback_locks_always_on` (new this round), `feedback_teachable_explanations` (jargon — reinforced).

## DECISIONS TANNER LOCKED THIS ROUND
- **Auto-approval: NO — "not allowed yet."** Watch-only; a human merges everything. (Revisit far later.)
- **Commit/PR habit (small commits → one small PR, ~200-line target/~400 cap, stacked PRs for dependency
  chains): YES.** (Card 4 — "Good".)
- **"Break-the-code" (mutation) testing: YES — but GENERALIZE.** "Not all repos deal with pricing." → apply it
  to each repo's critical calculation / pure logic *where it exists*; skip repos with none. Don't hardcode "money
  math." (Card 5.)
- **Honest review gate (server re-runs the tests = un-fakeable; the AI's review opinion = measured-trust, not the
  merge gate): YES.** (Card 7 — "Good".)
- **Git host: BOTH GitHub and GitLab.** (Card 8.)
- **Human paging surface: SLACK.** (Card 9.)

## CORRECTIONS / NEW DIRECTION (fold into the design + the deck)
1. **Safety LOCKS ARE ALWAYS ON — not conditional, not a "later."** The practice/dev database is **NOT** a
   build-now default ("not realistic for every new repo"). Reframe: *always* have the locks; have the **harness
   detect and RECOMMEND a dev database where it would help, and explain HOW to set one up.** So: locks = universal
   default; practice-copy = a recommendation the harness surfaces, never an assumed per-repo default. (Update
   VISION F0/F2/F3/F5 and the deck accordingly.)
2. **NEVER gate behavior on attended vs. unattended.** "Unattended should not be a consideration. The agent will
   never know this." Strike every "if running unattended/locally…" condition in the design — the agent can't know,
   so the locks apply universally, period. (This kills the "heavy guards only when local-unattended" framing.)
3. **Block-dangerous-commands must be VERY thorough.** Make F1 exhaustive and high-priority (deploys, destructive
   SQL, prod writes, writes to .git/.husky/.claude, rm -rf, force-push, etc.). "Need to be very thorough in this."

## NEW BUILD ITEMS TANNER REQUESTED
4. **A harness METRICS DASHBOARD.** "I want a dashboard that shows key metrics and helps me understand how and
   where this is actually helping, if at all." → elevate the metrics ledger (CMP3) into a real dashboard a human
   reads: is the harness helping? where? Design what metrics (first-pass-approval, review cycles, bugs caught vs.
   escaped, time-to-PR, per-repo) and how to surface them.
5. **"Answer the data-shape & design questions BEFORE coding."** On Flow 1 (new feature), Tanner asked: *"How do
   we make sure the data shape or other feature questions are properly answered before coding?"* → design an
   explicit mechanism: the spec step must force the hard design questions (schema / data shape, edge cases, open
   decisions) to be raised and **human-confirmed** before any code. Ties to the spec layer (C6) + STOP-AND-SURFACE
   + the open-decisions discipline. This is a real gap to close.

## NEXT-SESSION AGENDA (in order)
1. **Explain the three "front doors" in plain words.** Tanner: "I don't know what you mean by these" (the issue
   label / the Slack-or-Linear summon / auto-react-to-a-failed-test). Explain each simply, THEN he picks which
   ships first (Card 6 / D6 is still OPEN — do not assume).
2. **REVIEW THE DEFERRED ~35 ITEMS.** Tanner: "What are the other 35? We should review them because this already
   found holes." Present the backlog reviewably (deck-style: what it is, why deferred, the trigger), so he can
   vet / pull-forward each. The list = `VISION.md`'s 43 moves minus the build-now set; cross-ref
   `design/v2/simplification-pass.md`. **Treat the "defer" verdicts as suspect — deferring already hid the
   5-repos and practice-copy holes.**
3. **Design item 5** (data-shape/design-questions-before-coding mechanism).
4. **Design item 4** (the metrics dashboard).
5. **Refresh `V2-DECISIONS.html`** to reflect: the 6 locked decisions; locks-always-on + dev-DB-as-recommendation;
   strike "unattended" framing; generalize mutation testing; add the dashboard; add the before-coding-questions
   mechanism; mark D6 as needs-explanation.
6. **Still open:** D6 (front door first, after explanation); which of the 5 repos can have a dev DB.

## Build-now set (as of this round, pre-refresh — will grow per the corrections)
The practice copy is NO LONGER a build-now default (it's a recommendation). The locks (block-dangerous-commands
[thorough], block-real-keys, basic internet-limit, retry-ceiling + ask-a-human, side-effect locks + outbox) are
the always-on floor. Plus: the un-fakeable review gate, the 4-angle reviewer + measured catch-rate, the learning
loop (read-back), the front door + narration, get-the-5-repos-in-sync, and the metrics dashboard (new).
