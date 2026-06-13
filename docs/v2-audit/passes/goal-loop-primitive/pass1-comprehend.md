# Pass 1 — Comprehend: what the article SAYS

Source: Notion "Research · /goal — The Loop Primitive vs. the Harness Pipeline (2026)"
(id 37be2971cd62811b8a59f0002cad4e75). Faithful restatement; claims tagged (fact)/(opinion).
"(fact)" = the article presents it as a verifiable mechanic, citing docs. "(opinion)" =
the article's judgment, framing, or recommendation. Where the article itself flags a claim
as unconfirmed, that is noted — those are CLAIMS to verify, not facts inherited.

---

## Core thesis (the article's own framing)

- `/goal` is "the productized version of the loop you would otherwise hand-build." (opinion)
- The real question is not whether `/goal` is useful, but whether it adds anything to a harness
  that already has `/queue` → `/cr` → `/compound` with fresh-context reviewers, a MUST-FIX=0
  stopping rule, and PR-as-gate. (opinion / framing)
- Central claim: **`/goal` controls *continuation* (should there be another turn?); the pipeline
  controls *structure and verification* (was it done right, may it ship?). Different layers.** (opinion)
- `/goal` "does not replace a single one of your locked gates," and treating its built-in grader
  as a substitute for the CI sentinel "reintroduces exactly the advisory-not-structural failure
  Pillar 1 exists to prevent." (opinion — the load-bearing warning)
- Self-described as "deliberately not cheerleading"; concedes `/goal` is "a genuine convenience and
  a real maker-vs-checker advance over naive looping," but also "the single easiest place to quietly
  let a transcript-only model decide that work is 'done.'" (opinion)

## What /goal is

- A session-scoped slash command (Claude Code AND Codex) that converts a turn-at-a-time session into
  a self-continuing loop driven by a **user-authored stopping condition**. (fact)
- Instead of stopping after each turn for a "continue," the agent keeps starting new turns until a
  *verifiable* end-state becomes true — example: `all tests in test/auth pass and lint is clean`. (fact)
- Defining mechanic in Claude Code: **a separate, fresh small model evaluates "are we done?" after
  every turn** — the working agent is not the grader. (fact)
- The article frames this as "Node 12 adversarial-independence applied to the stop condition itself —
  but in a much weaker form." (opinion)

## Verified mechanics (Claude Code) — article presents these as fact, citing docs

- After each turn, a small fast model (defaults to **Haiku**) checks the condition; if false, Claude
  starts another turn instead of returning control. Goal clears automatically when the condition is met.
  Cited to code.claude.com/docs/en/goal. (fact)
- **The grader is transcript-bound: the evaluator does NOT call tools.** It judges only what Claude has
  surfaced into the conversation. Claude runs `npm test`, result lands in transcript, evaluator reads it.
  Condition can be up to 4,000 characters. (fact)
- Architecture: `/goal` is a wrapper around a session-scoped, prompt-based **Stop hook**. Evaluator
  returns yes/no + a short reason; a "no" feeds the reason back as guidance for the next turn. (fact)
- Controls: `/goal <condition>` sets (starts a turn immediately); bare `/goal` shows status (condition,
  elapsed time, turns evaluated, token spend, latest reason); `/goal clear` stops. One goal per session.
  Requires a trusted workspace; unavailable if `disableAllHooks` is set. (fact)
- Introduced Claude Code v2.1.139 (~May 12, 2026). Article flags exact date as "secondary." (fact, date hedged)

- **Load-bearing caveat** (the article's key mechanical point): because the grader only reads the
  transcript and runs no tools, a loosely-written condition can be satisfied by Claude *claiming* success
  in prose. "The feature is implemented and working" is transcript-checkable and worthless;
  "`npm test` exited 0 and the output shows 0 failures" is real. "The grader is a fresh model, but it is
  not an independent verifier of ground truth — it is a reader of one agent's homework." (opinion, grounded in the fact above)

## /goal vs /loop (two primitives, "routinely confused")

- **`/loop`** re-runs a prompt **on a time interval**; next turn starts when a clock elapses; stops when
  you stop it. For *polling* ("check deployment every 10 minutes"). Cites Cherny running
  `/loop 5m /babysit`, `/loop 30m /slack-feedback`. (fact)
- **`/goal`** starts the next turn **when the previous finishes**; stops when a model confirms the
  condition. For work with a *definable finish line*. (fact)
- Two failure modes: `/loop` on finish-line work re-runs blindly on the clock; `/goal` pointed at
  something external ("until the deploy is green") spins forever because the condition never becomes true
  through Claude's own effort. (opinion)

## Codex /goal — "the one real mechanical difference"

- Codex shipped `/goal` first (CLI 0.128.0, 2026-04-30); fuller control surface: `/goal pause`,
  `/goal resume`, `/goal clear`, plus a budget/quota stop. (fact)
- Sharpest difference is the verification model: Codex's docs say it stops when "fairly confident" it
  reached the condition and describe **no independent per-turn evaluator**. Claude Code externalizes
  "are we done?" to a separate grader; Codex (as documented) leans on the working agent's own confidence. (fact, as documented)
- For a harness built on Pillar 3 ("verify the system, not the model"), Claude Code's design is the
  better-aligned of the two — but neither grader substitutes for a CI required-check. (opinion)
- Codex experimental→GA status as of mid-2026 is "unconfirmed; treat as experimental." (article-flagged unconfirmed)

## /goal vs the /queue + /cr pipeline (the comparison "that matters")

Article's table, restated. Left = `/goal`; right = the pipeline:

- **What it controls:** continuation (another turn?) vs structure of work + ship-permission. (opinion)
- **Verification:** one transcript-only model checks one end-state per turn vs four fresh-context lens
  agents + orchestrator + adversarial pass (Node 12), CI required-check, ProofShot. (fact about pipeline / opinion on contrast)
- **Maker ≠ checker:** yes but only at coarse "done?" level vs at every phase, fresh context, spec
  withheld from reviewers. (opinion)
- **Blast-radius control:** none vs 400-line cap, 5-PR overnight cap, REJECT on out-of-spec/auth/schema
  (Node 3, 12). (fact about pipeline)
- **Stopping rule:** whatever string you wrote vs MUST FIX = 0 (not a score); CI green; PR merged =
  first-pass. (fact about pipeline)
- **Unforgeable gate:** No — grader reads the transcript vs Yes — CI required-check is the only truly
  unforgeable gate (Node 8.5c). (opinion / fact)
- **Setup cost:** one line vs "the harness you already built." (opinion)

- What `/goal` ADDS: replaces the manual "run the next task" loop and the need to hand-write a Stop hook
  for simple completion checks. "It is a one-line Ralph Loop." (opinion)
- What `/goal` does NOT do: no concept of blast-radius caps, REJECT routing, UNATTENDED=1 signal, or CI
  sentinel. Left to its grader it will "happily end a loop on a transcript that *says* the tests pass."
  "Strictly weaker than `/cr` at verification and has no structural enforcement at all." (opinion)

## Risks (mapped to the system's pillars)

- **Runaway token cost (headline risk, already flagged):** open-ended goals consume wildly variable
  tokens; documented mitigation is a turn/time clause IN the condition ("…or stop after 20 turns").
  Note: the grader itself is cheap (Haiku); the blow-up is the MAIN model taking many extra turns. Same
  economics as 5-PR / 400-line caps — bound the loop before walking away. (fact + opinion)
- **Verification is still on you (Pillar 3):** fresh grader judges only the transcript, runs no tools;
  this is why CI required-check exists as the unforgeable gate. `/goal`'s grader is "a convenience, not
  a certifier." Do not let it earn the trust only `.cr-ok` bound to CI has earned. (opinion)
- **Comprehension / intent debt (Pillar 5):** a hands-off `/goal` run maximizes unwatched code. Cites the
  system's own "Svpino R1 finding": overnight autonomy gave **+98% PRs, +154% PR size, +9% bug density,
  and zero DORA improvement** — "it relocated the review bottleneck, it did not remove it." `/goal` is a
  bottleneck-relocator unless the stop condition bottoms out on structural gates. (cited finding, article flags quiz figures as secondary/unconfirmed)
- **Reversibility (Pillar 2):** `/goal` has no notion of irreversible classes; autonomy is only safe
  where blast radius is bounded, which `/goal` does not bound on its own. (opinion)

## Application to this system (the article's prescriptions)

- `/goal` fits the harness "in exactly one role": the **continuation driver for a single, well-specified,
  reversible `/queue` task** — the Stage 3→4 "one-shot routine for well-specified work" already named in
  Node 13.3. Not a new gate, not a replacement for any locked decision. (opinion, cites Node 13.3)

The correct way to use it (4 prescriptions):
1. **Make the stopping condition bottom out on structural gates, never the transcript.** Not "the feature
   works" but `/cr returns MUST FIX = 0 AND CI is green AND the diff is under 400 lines`. This turns the
   weak transcript grader into a thin wrapper around real verifiers — the grader's job becomes "has
   /cr+CI reported success," which IS transcript-visible because the pipeline writes it there. (opinion)
2. **Always include a turn/time clause:** "…or stop after N turns and surface as NEEDS HUMAN." The 5-PR
   cap philosophy at session level. (opinion)
3. **Gate on reversibility (Pillar 2):** only allow autonomous `/goal` on direct-`/queue` classes
   (single-file changes, utility updates, test additions, doc updates). Spec-gated set — auth, schema
   migrations, RLS, payment logic, new UI surfaces — keeps a human in the loop regardless. `/goal` does
   not know the difference; you encode it in *which tasks you point it at*. (opinion)
4. **Respect UNATTENDED=1 routing:** `/goal` does not implement REJECT. A `/goal` run that can't reach its
   condition must fall back to existing routing: UNATTENDED=1 → re-queue to `/change`; interactive →
   NEEDS HUMAN. The goal loop ends; the harness takes over. (opinion)

Where it explicitly does NOT belong:
- Does not replace `/cr` (maker≠checker every phase, fresh context, spec-withholding vs grader once,
  transcript-only). Using its grader as verification-of-record = Pillar 1 violation. (opinion)
- Does not replace `/queue`'s blast-radius caps or ProofShot artifact (pipeline stages; `/goal` should
  *contain* the pipeline, not stand in for it). (opinion)
- Is NOT the mechanism for overnight multi-task autonomy — that is `/queue` + `pr-queue.md` + `/compound`.
  `/goal` is single-objective, single-session. (opinion)
- Net: adopt as a thin continuation wrapper for one reversible task at a time, stop condition pinned to
  MUST-FIX=0 + CI-green + turn cap; treat grader as a convenience reading real gates' output, never a gate.
  Do NOT add it to `/queue` or `/cr` as a structural element. (opinion)

## The Standing Rule (article's proposed repo rule)

- A `/goal` stopping condition in this repo must be machine-verifiable through the pipeline (MUST FIX = 0,
  CI green, diff under cap) and must carry a turn or time bound. If the only honest condition you can write
  is "make it better," the task is underspecified — route to `/change` for a spec, not `/goal` for a loop.
  "`/goal` continues work; it never certifies it." (opinion — the proposed standing rule)

## Sources & self-flagged verification gaps (these are CLAIMS, not inherited fact)

- Sources cited: Claude Code `/goal` docs, Claude Code What's New, OpenAI Codex follow-goals + CLI
  slash-commands docs, Anthropic harness-design-for-long-running-apps, Addy Osmani ("Agent Harness
  Engineering" / "Loop Engineering" / "Comprehension Debt"), Simon Willison Codex 0.128.0 note,
  "KnightLi /goal-vs-/goal comparison."
- Article's OWN verification flags (treat as unverified): exact Claude Code release date; Codex
  experimental→GA status; comprehension-quiz / Svpino R1 figures (+98/+154/+9/zero) are "secondary/
  unconfirmed and hedged in-text."
- NOTE for later passes: this page embeds no separate curator "passes." Its pillar/Node references
  (Pillar 1/2/3/5, Node 3/8.5c/12/13.3) are CLAIMS about our system to verify against the ground-truth
  map, not facts to inherit.
