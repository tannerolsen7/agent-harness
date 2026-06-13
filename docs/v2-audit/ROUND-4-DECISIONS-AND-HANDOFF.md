# V2 Harness — Round 4 Decisions & Handoff (LIVING — append as decisions land)

> Continues from `ROUND-3-DECISIONS-AND-HANDOFF.md`. This session is working the Round-3 next-session
> agenda in order. Decisions are recorded here as they're made so the deck refresh (agenda item 5) and the
> next session have a single source of truth. The deck (`V2-DECISIONS.html`) is NOT yet refreshed.

## BUILD PLAN — START HERE (next conversation)

Round-4 design is **COMPLETE and reviewed** (staff-engineer · AI-engineer · newcomer · security · cost/ROI ·
worktree). The harness is its **own project**, moving to its **own GitHub repo soon** — the present-state
security holes (readable prod key, missing `block-dangerous-bash.sh`, fail-open `jq` hooks, no
`managed-settings.json`) and the worktree fail-opens (G1/G2) are fixed **as part of that GitHub move** (Tanner's
call). Build there. Source of truth = the R4-D* decisions below + `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md` +
the plain-English `V2-REVIEW-PACK.html`.

**Build order (dependency-ordered; `/queue` the independent items within each phase):**
- **Phase 0 — Safety floor (first, non-negotiable):** `block-dangerous-bash` (fail-closed, full non-git scope) ·
  credential firewall (prod key NOT reachable; migrations human-applied) · `disable-model-invocation` on
  side-effect skills · fail-closed the existing `jq` hooks · `managed-settings.json` (OS-level) · basic egress
  allowlist · worktree G1 (npm-install + assert-hook, fail-closed) + G2 (standardize `.claude/worktrees/<slug>`).
- **Phase 1 — Trust:** the un-forgeable CI verdict gate (F6) · **the bug-catch test (catch-rate) seeded from REAL
  escaped defects — build FIRST; it gates the collapses** · the 4-lens reviewer + governance lens · collapse the
  9 analytical passes → 1 + free lint (gated on the bug-catch test; keep splits where recall drops) · role-based
  model tiers + event-trigger on model-id change · the routing-assertion gate (block if a DB-touch skipped the
  DB-safety skill) · bounded-loop + REJECT.
- **Phase 2 — The loop (human-started):** one adaptive build command + `/goal` · incident subsystem (carry
  forward) · narration · shared Stop-hook · **the strict before-coding gate (data shape → UX → UI mockup)** +
  the design phase (1 designer + independent grill) · the feature-doc hub + patterns/exemplars registry · the
  learning loop (read-path + finding→enforcement ratchet) + reference-integrity check.
- **Phase 3 — Quality systems:** UI (design-system bootstrap-if-missing → design-system-only + token-lint +
  `impeccable` detector + gated rendered design-review + `/compound` feedback) · UX (tiered `@ux-reviewer` + axe
  gate + feature-doc click/step targets, never fake human metrics) · perf (measured + logged + warn) · data-state
  matrix · clean-code / comments-earned · tests verified by delete-the-code + break-the-code (mutation).
- **Phase 4 — Fleet/platform (the GitHub move):** GitHub canon (P3) · pin + vendor the borrowed skills (P5) ·
  per-skill frontmatter (P6) · self-contained add-on + starter kit + `sync-harness.sh` · the deep AI-activity
  dashboard (R4-D29) · the CLAUDE.md→hooks ratchet audit (R4-D33) · adopt zoom-out / write-a-skill / prototype /
  triage / to-prd.
- **Phase 5 — Post-launch (deferred, with triggers):** the front door (L1) · the clock (L4) · auto-merge
  (LOOP-7) · the real-time access-control UI (R4-D34) · fleet circuit breaker (F8) · plugin marketplace (P1/P2).

> The cost/ROI review argued for a "lean 6" first — useful as a *priority signal* (the locks, F6, the direct
> collapses, the free UI floor, the before-coding gate, vendor-skills+sync are the highest-value core). Its
> "ship the product first" argument is STRUCK (harness ≠ product — separate projects). Build the full plan in
> phase order; lead with Phase 0 + the lean-core items.

---

## DECISIONS LOCKED THIS ROUND

### R4-D1 — Front door: PUNTED to post-launch (2026-06-12)
Tanner: *"Let's punt on the front door until after version 2 is launched."*

- **L1 (the autonomous trigger trifecta — GitHub label / Slack-Linear `/fix` summon / CI self-heal) is
  deferred to AFTER V2 launches.** It is no longer in the build-now spine.
- This was agenda item 1 (explain the 3 doors, then pick which ships first). The explanation was given;
  the answer is "none yet — punt all three."
- Consistent with the Round-3 lock *"Auto-approval: NO — not allowed yet; a human merges everything."*
  The same instinct: keep a human in the *starting* position for V2; revisit auto-start after launch.

**Ripple (what the punt changes):**
- **F3 (egress allowlist) and F5 (MCP lethal-trifecta gate) fall fully out of the build-now floor.** They
  were "P0 *only* for the Slack/CI free-text trigger path" (VISION L1, F5). With no free-text trigger in
  V2, there is no attacker-controllable text entering the agent, so their P0 justification evaporates for
  launch. (They remain deferred hardening for when the triggers ship.)
- **P4 (MCP-as-substrate — "the distribution half of L1") defers with L1.** Nothing external summons the
  harness in V2.
- **The spine becomes human-started.** `/goal` (L2), `/lfg` (L5), narration (L7), the incident subsystem
  (L6), the box (F0), the un-forgeable finish line (F6), the review spine (C2/C5/C4), and the learning
  loop (CMP1/CMP2) all still stand — they just get invoked by a human typing a command, not by an event.
  V2 = **"human starts the run, the machine finishes it safely."**

**OPEN consequence (needs Tanner's call — see R4-Q1 below):** does the **clock (L4 cloud heartbeat —
fires scheduled runs laptop-closed)** also go post-launch? It has the same "no human in the firing
position" property as the front door. Two readings: (a) punt L4 entirely → everything human-started; or
(b) keep L4 *only* for low-risk maintenance/discovery that produces a PR a human reviews (consistent with
"watch-only, human merges"), punt L4 for auto-starting feature/fix work.

### R4-D2 — The clock (L4): NO clock at all for V2 launch (2026-06-12)
Tanner chose the strictest reading: **nothing the machine does begins without a human typing a command.**

- **L4 (cloud heartbeat / scheduled self-triggering) is deferred to post-launch, entirely** — including the
  maintenance flavor (scheduled drift scans, model-capability probes).
- **Consequence:** every scheduled/cloud routine in the vision loses its timer for V2. The *logic* of those
  routines can still ship as **human-invoked commands** (you can run `/scan-context` by hand), but the
  `cloud /schedule` wrapper is post-launch. Affects: CMP4 scheduled scanner, CMP6 probe routine, P9
  cross-repo loop, L4 discovery — all become "manual command now, scheduled later."

## STRUCTURAL FINDING — the simplification pass's "deferred" list is premised on a stale 1-repo assumption
**`design/v2/simplification-pass.md` defines the ~8-build / ~35-defer split. It was written assuming the
harness lives in ONE repo (it literally says "installed exactly once (event-vendor)", line 43). Round 3
corrected that: the harness runs in ~5 repos** (memory `project_harness_multi_repo_reality`; Round-3 build-now
set includes "get-the-5-repos-in-sync"). Two of the simplification pass's biggest defer/fold calls are built
on the dead 1-repo premise:

1. **The entire PLATFORM pillar (P1/P2/P3/P5/P6/P7/P8/P10) was deferred behind a "2nd repo exists" trigger.
   That trigger has ALREADY FIRED — there are ~5.** Convergence + a single source of truth + provenance is a
   *present* problem, not a future one. → The source-of-truth + convergence half is **build-now**, not deferred.
2. **F2 (credential firewall) was folded into F0 (disposable DB), assuming F0 is universal.** Round 3
   corrected: isolation is **conditional** — not every repo has a dev DB — so **the locks are the always-on
   net** (memory `feedback_locks_always_on`). → F2 **stays a standalone always-on lock**; it does NOT
   dissolve into F0.

This is exactly the failure the Round-3 handoff warned about: *"deferring already hid the 5-repos and
practice-copy holes."* The deferred backlog below is reconciled against the corrected premises, NOT the raw
simplification pass.

### R4-D3 — Deferred-set review: 2 of 3 suspect-defers pulled forward (2026-06-12)
Reviewed the full parked set via the plain-English deck `V2-LATER-LIST.html`. Tanner's calls:

- **PULL FORWARD → build-now: "Get the 5 projects in sync."** The fleet-health slice — one shared rulebook
  (P3 source-of-truth / canon convergence), lock the 15 vendored skills to reviewed versions (P5 provenance +
  the cheap MCP pin-and-diff lockfile), per-skill frontmatter (P6), upstream-disposition policy (P7), and the
  per-repo knowledge-artifact / broken-reference CI check (P9 half — CMP4 reference-integrity). The *auto-push
  to all repos* (P8 automation) and the *plugin/marketplace packaging* (P1/P2/P10) still wait — they sit on top
  of this convergence work.
- **PULL FORWARD → build-now: "The easy accessibility win" (C9).** The `data-testid`/aria lint rule, enforced
  at commit. Helps human a11y now; pre-positions browser verification later.
- **STAYS PARKED: "Stress-test the money math" (C11).** Tanner declined — and the reasoning is sound: the
  pricing/recipe schema is flagged for redesign (`recipe-planner` blocked in TASKS.md), so the money math is
  mid-flux. **New trigger: build it when the pricing schema is finalized** (was: "approve `fast-check`").
- All other parked items confirmed SOLID with their existing triggers (see `V2-LATER-LIST.html` §"fine to wait"
  and `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md` Part C).

**Net updated build-now set** = the Part-A set in `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md`, PLUS the fleet-sync
slice (P3+P5+P6+P7+P9-half) and C9. Minus L1/L4/P4 (punted).

### R4-D4 — The "answer design questions before coding" gate: STRICT (2026-06-12)
Agenda item 5 (the data-shape-before-coding mechanism). Tanner chose the strictest of three tiers.

**The mechanism (build-now slice of C6, the spec layer):** before any feature code, the robot produces a
3-section **Design Questions sheet** — (1) data shape (tables/columns/types/relations + the Zod boundary
schema), (2) edge cases, (3) open questions the robot is FORBIDDEN to answer itself. Enforced by a hard stop:
a `design-confirmed` sentinel (same pattern as `.cr-ok`) gates the coding step — no human sign-off, coding
refuses to run.

**STRICT tier adds:** (a) a second independent agent grills the sheet adversarially (the `/grill-with-docs`
philosophy) to surface missed cases/assumptions before it reaches Tanner; (b) **whenever the feature touches
the database, the robot writes the actual proposed schema (migration + Zod) and Tanner approves that exact
data shape on its own, first** — because the schema is the least-reversible decision. Reasoning logged:
robot passes are cheap, a wrong schema is not (`feedback_estimation_harness_first`).

**UI EXTENSION — "lock the look" (Tanner: "the other challenge of a new feature is the UI work."):** the gate
locks data shape but not the look — and on a UI feature the look is the bigger guess (text is a poor way to
agree on a screen; a diff is a poor way to review one). So a parallel sub-step: **for any feature with a
screen, the robot produces a rough throwaway mockup built from the existing design system (`docs/design/`
tokens + components, NOT a new style), and Tanner approves the look BEFORE the full wired-up build** (chosen
tier: "Rough mockup first" — cheapest to iterate; escalate to Figma, which is MCP-connected, for the highest-
stakes client-facing screens). After build, a screenshot is attached to the PR for human eyeball confirmation
(the light, build-now form of C8; the full CI-resident pixel-diff + tenant-assertion render gate stays
deferred to the first *autonomous* UI run). So the gate now locks BOTH expensive-and-text-unreviewable
decisions up front: **data shape (schema approval) + look (mockup approval)**, each with a does-it-match check
after.

### R4-D5 — Simple language is the standard for ALL v2 explanations (2026-06-12)
Tanner: *"I liked the simple language and we need to build that type of language into all explanations for
version 2."* → Every human-facing v2 artifact uses the `V2-LATER-LIST.html` plain-English style: 6th-grade,
no jargon, each item gives what-it-is + why + where-it-came-from, paired with a simple way to pick. The
jargon-OK markdown records are for the next agent session only. (Captured in memory `feedback-teachable-explanations`.)

### R4-D6 — The metrics dashboard (item 4): headline = "is it getting smarter?" (2026-06-12)
A human-opened page (`npm run metrics` → local HTML; no cloud/auto-report per no-clock), **per project across
all 5.** Metrics = CMP3 elevated:
- **Day-0 (build now):** rounds-per-change (review cycles), "robot stopped itself"/REJECT count, repeat-mistake
  count, change-size trend.
- **Volume-gated (light up later):** first-pass-approval rate, escaped-post-merge-defects.
- **Headline (Tanner's pick):** the **repeat-mistake trend over time, per project** — answers "is the learning
  loop actually working / is it compounding," the riskiest claim in V2. Everything else shows below.

### R4-D7 — The infra forks (2026-06-12)
- **#3 (Fork F8) — ONE adaptive build command.** Always type the same command; it sizes the job (big → plan
  + slice; tiny → just do it) and runs the per-slice engine under the hood. Resolves /dev-vs-/feature by
  collapsing to one front door rather than killing either. *(`/feature`-style top driver, `/dev`/`/tdd` engine
  inside; no user choice of which to invoke.)*
- **#4 (Fork F1) — verdict surface = blocking check-mark + plain-English PR comment.** A required status check
  (CI re-runs tests on the head SHA) blocks merge unless green; a human-readable comment posts what was checked
  and found. (Stated as proceeding; not contested.)
- **#5 (Fork F5) — STRONGEST locks (OS-level / unreachable).** The dangerous locks live where the robot can't
  reach or disable them. Accepted cost: a one-time human paste-in per project (robot can't edit guard files —
  `feedback_no_agent_edits_guard_files`). Consistent with locks-always-on.
- **#6 (Fork F4) — LAPTOP, same as now.** Cloud NOT adopted for V2 (overrode my "both" rec). Implication: the
  laptop can reach real systems, so the always-on locks (#5) + practice-copy-where-available do the safety work
  — which is exactly why he paired this with the strongest locks. Cloud stays available post-launch with the
  clock/front door.
- **#7 (Fork F10) — share the CLEAN parts now, hold the contradictions.** Put non-contradicting rules onto the
  shared rulebook immediately so the 5 projects start converging; keep contested rules out until resolved. (A
  middle path between "perfect-first" and "share-all-with-a-tiebreaker".)

### R4-D8 — Practice DB: assume NO project has one; locks are the sole net (2026-06-12)
Tanner: *"We should treat every project as if it can't spin up a throwaway practice database."* Resolves
open-#1, and goes further than "conditional" — we don't even detect per-project; we **assume zero practice
copies** and design safety to work with none.

**Implications:**
- **The locks carry 100% of safety.** No sandbox fallback. Combined with laptop execution (R4-D7 #6, can reach
  prod) and no cloud network-restriction (cloud declined), the locks are the *entire* defense.
- **`block-dangerous-bash` (F1) + the credential firewall (F2) become load-bearing-alone and FIRST.** Must be
  exhaustive and trusted before the robot touches anything real. (Reinforces R3 correction #3 "very thorough"
  and the strongest-locks choice R4-D7 #5.)
- **F0 (the practice copy) drops from a build-now recommendation to an optional human-added bonus** for projects
  that happen to support it (event-vendor/Supabase). Never assumed, never relied on for safety.
- **Simplifies the design:** one path (locks everywhere), not two. No per-project DB-capability detection logic.
- Supersedes the "isolation-first is conditional / dev DB is a recommendation" framing with the stricter
  "assume none." (Memories `feedback_locks_always_on` + `project_harness_multi_repo_reality` updated.)

## STILL OPEN
- Nothing blocking. (All Round-3 + Round-4 decisions resolved.)

## NEXT
- Refresh the deck (agenda item 5) → a NEW plain-English `V2-DECISIONS.html` folding in R4-D1…D7 + the 2
  pull-forwards, in the `V2-LATER-LIST.html` style (the locked simple-language standard, R4-D5).

## AGENDA PROGRESS (from ROUND-3 handoff) — ALL COMPLETE
1. Explain 3 front doors → **DONE** (explained; Tanner punted all three — R4-D1; clock also punted — R4-D2).
2. Review the deferred ~35 → **DONE** (R4-D3; deck = `V2-LATER-LIST.html`, record = `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md`).
3. Design item 5 (data-shape questions before coding) → **DONE** (R4-D4 strict gate + UI "lock the look" extension).
4. Design item 4 (metrics dashboard) → **DONE** (R4-D6; headline = "is it getting smarter").
5. Refresh `V2-DECISIONS.html` → **DONE** (rewritten 2026-06-12 in the plain-language standard, folding in
   R4-D1…D7 + the 2 pull-forwards; includes an "every call you made" verification table).

## NEXT SESSION
- Confirm Tanner verified the "every call you made" table in `V2-DECISIONS.html`.
- Close STILL-OPEN #1 (practice-DB per repo) when Tanner names his 5 projects' DB setups.
- Then: turn the settled plan into the actual build order (the V2 build-now set is in
  `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md` Part A + the 2 pull-forwards).

## ARTIFACTS THIS ROUND
- **`V2-REVIEW-PACK.html` — THE single human-facing review surface** (Tanner: "the simplest and best way for
  me to review all of this"). Covers, in 6th-grade English: the big picture, every kind of job (8 flows incl. a
  dedicated security-incident flow), what ships next round + why, every parked item (un-bundled), and an "every
  call you made" verification table. **Staff-engineer reviewed before delivery** (2 passes via sub-agent): pass 1
  found 6 MUST-FIX + 5 SHOULD-FIX (overstated un-fakeable claim, undersold risk concentration, buried security
  path, self-contradicting DB flow, "governance check"/"pin" jargon, missing auto-merge verification row); all
  folded in; pass 2 confirmed all 11 resolved, no regressions, verdict "ready for the founder." Supersedes the
  other decks as the place to read everything.
- `V2-DECISIONS.html` — refreshed decision deck (still valid; the Review Pack is the fuller superset).
- `V2-LATER-LIST.html` — plain-English review of the parked set (now bundled into the Review Pack's future section).
- `V2-LAUNCH-SCOPE-AND-DEFERRED-BACKLOG.md` — the reconciled build-now set + deferred backlog (jargon-OK record).
- This file — running decisions log.

### R4-D9 — Permanent feature doc for EVERY feature; it becomes the hub (2026-06-12)
Resolves the C6 open question. Tanner: *"we should have a permanent doc for every feature… Eventually
everything should tie together. The tests and testing reports come from the feature doc, the agents can refer
to feature docs, the marketing agents can pull from there, etc."*

- **C6 (full per-feature spec doc) → BUILD-NOW**, not deferred. Every feature gets a permanent written page
  (what it does + how to verify it still works), grown out of the before-coding gate (R4-D4).
- **Bigger vision (captured in memory `project_feature_doc_as_hub`):** the feature doc is the single source of
  truth per feature that everything else references — tests + test reports derive from it, agents read it for
  context, downstream (e.g. marketing) pulls from it. This elevates C6 from "a spec doc" to the organizing
  spine. Build the doc now; the tie-ins (tests-from-doc, agent-reads-doc, marketing-pulls) are the direction to
  grow toward, not all built at once.

### R4 clarifications (2026-06-12)
- **Keystone framing corrected (Tanner: "this seems like overkill"):** F6 is NOT "run tests twice." CI already
  runs the tests on every change (standard). The only new thing is making the merge BLOCK on the server's
  result + tying the `.cr-ok` sentinel to the exact head SHA so it can't be forged. Reframed in the pack as
  "connect what already exists," not "a second round."
- **/cr audit (Tanner asked "why skip 10? why 4-pass after the agents?"):** read `.claude/skills/cr/SKILL.md`.
  Structure = **9 analytical passes in parallel** (P1 correctness, P2 domain-safety, P3 TS, P4 layers, P5
  readability, P6 tests, P7 doc-drift, P8 arch-drift, P9 devil's-advocate) **+ Pass 11 adversarial** (@reviewer
  → 4 lenses: assumption/composition/cascade/abuse) run after, before synthesis. **There is no Pass 10 — the
  number is skipped (vestigial from a removed/renumbered pass; cosmetic).** The C5 governance/rules lens being
  added could naturally fill the Pass-10 slot. The 4-lens pass runs after the 9 as the adversarial capstone
  (different in kind: 9 = check-against-checklist, 4 = break-it-from-fresh-context); no hard dependency forces
  "after" — it's a framing choice. Pack's review row corrected to show 9-checks + 4-attack-angles + the new
  rules pass (was conflating "4 angles" with the whole review).

### R4-D10 — Packaging/portability PULLED FORWARD to build-now (2026-06-12)
Tanner: make the harness self-contained and droppable into the other repos *now*. This pulls the platform
pillar substantially into build-now (revising the earlier "package later" sequencing). Concretely:
- **Self-contained, no global-skill dependencies.** Today several skills are globally installed (Matt Pocock
  pack: `/grill-with-docs`, `/simplify`, `/to-issues`, `/tdd` helpers; `/vercel-react-best-practices`). The
  add-on must bundle the skills/agents it needs so a project doesn't silently lose steps when a global pack
  isn't installed.
- **Stack-agnostic via backend ADAPTERS — stop hardcoding `/supabase`.** The gate becomes generic: *"before any
  DB change, run THIS project's database-safety skill."* Each project declares which backend skill fills the
  role (`/supabase` here, a `/firebase` one elsewhere). Same role-based pattern for any stack-specific step.
  (This is the fix for Tanner's "this is so Supabase-focused" concern.)
- **Unlocks the starter kit + the skill-reader** (P2 + the P6 manifest consumer) — they ride the add-on.
- Net: P1 (add-on/plugin), P2 (/init starter kit), P6 (manifest + reader) move from deferred → build-now.
  Auto-push-to-all-repos (P8 automation) still waits.

### R4-D11 — Security-scare response stays HUMAN-DRIVEN; improve evidence-gathering only (2026-06-12)
Do NOT build automated security response (the riskiest possible automation — a wrong move destroys evidence or
widens a breach). Keep the rule: robot isolates + logs + hands off; a human drives the response. What we DO
improve: make the isolate-and-gather step produce a thorough triage packet for the human. (Answers Tanner's
"should we build this?" — no, by design.)

### R4-D12 — Add a RED-TEAM security pass, scoped (2026-06-12)
Add a pass that actively tries to EXPLOIT a change (not just checklist-review it), as an enhancement to
`/cr-security`. **Scoped to security-sensitive diffs only** (auth/login, permissions/RLS, payments, public
endpoints) — not every PR (too slow/noisy). Justified now that the locks are the sole safety net.

### R4 corrections (2026-06-12, this round cont.)
- **`/cr` numbering fixed:** Pass 11 → Pass 10 in `cr/SKILL.md` + `docs/RECURRING-FINDINGS.md` (swept). One
  trailing ref in `.claude/agents/reviewer.md` is permission-guarded → handed to Tanner as a one-line edit.
- **Spike/outside-text correction:** `/spike` (and any web-fetch) ALREADY brings outside text into the robot, so
  the "no outside-text door yet" framing was wrong. The basic internet limit matters NOW (not post-launch); the
  full allow-list + dangerous-combination guard are more justified than stated. Human-started runs keep the risk
  lower, but it's not zero. Reflect in the pack.
- **Feature-doc generator:** the permanent feature doc (R4-D9) becomes a template-driven skill + writer agent so
  every doc is consistent + world-class — built on the existing `@spec-writer` agent + `/to-prd` skill.
- **Library-updates flow (job 7): PUNTED** — no real tool exists (empty `dep-update` stub); done by hand for now.

### R4-D13 — /evaluate-solution: KEEP (2026-06-12)
After the clearer explanation (it's wired into `/incident`'s routing for third-party/capability-gap incidents +
matches the queued "evaluate Linear" task, and deleting = net more work to avoid a broken reference), Tanner
chose to keep it.

### R4-D14 — Build a real design phase: architecture + schema + backend/API designers (2026-06-12)
All three, grounded in the project's locked patterns AND self-contained (no global-skill dependency). Each
feeds the before-coding gate. The schema designer is what the recipe-planner redesign needs.

**Critical nuance (Tanner):** *"they need to be built in a way that uses best practices for software overall
AND for that project. Not all advice is good advice when it's not applicable."* → the designers must JUDGE
applicability, not cargo-cult generic best practices. Blindly applying a generic best practice where it doesn't
fit the context is itself a failure mode. Pair general best-practice grounding with project-context discernment.
(Refines `feedback_best_practice_first` — best practice yes, but context-judged.)

### R4-OPEN — World-class UI / no-slop mechanism (2026-06-12)
Tanner deferred the UI-craft decision: *"Let's explore how others do this. There seems to be some good GitHub
skills available, too."* → researching (a) how leading AI-coding tools/teams achieve world-class UI + avoid
"AI slop", and (b) what installable skills/tools exist (shadcn skill, vercel skills, GitHub design-review
skills, Figma MCP). Two parallel research agents launched; synthesize → present options → decide. Known anchors
already on hand: real design system in `docs/design/` (tokens + components + visual templates), Figma MCP
connected, stack = Next.js 16 / React 19 / Tailwind 4, $30k client-facing. Requirement: world-class + ease of
use + **gets better every project** (a design learning loop).

### R4 — UI-quality research findings (2026-06-12)
Two web-grounded research passes on "world-class UI / no AI slop / gets better every time." Core finding:
**UI quality = constrain + audit + compound, NOT prompting** (prompting is the weakest lever; sources agree).
- **Constrain:** AI composes only from the existing component vocabulary + design tokens; forbid raw element
  styling. Expose the component library as a registry the agent reads at session start.
- **Audit (deterministic, highest ROI):** a token-violation linter in the pre-commit gate — any color/spacing/
  font outside the token set fails the commit. This is what stops quality drifting session-to-session.
- **Audit (rendered):** a screenshot/render design-review agent that LOOKS at the live page and critiques vs.
  an approved exemplar — treat as a FLAG, not a gate.
- **Compound:** fold UI into `/compound` — corrections → design rules; approved screens → few-shot exemplars.
  This is the "gets better every project" mechanism (= CMP1 pointed at UI).
- **Honest limit (measured):** AI enforces/replicates taste but can't ORIGINATE it for a high-stakes brand
  (UICrit: auto-critique 0.48 vs human 0.75; experts preferred humans 81%; ~87% of one model's auto-comments
  invalid). Human/Figma keeps: brand-taste origination + the final "$30k-worthy?" call.

**Installable, real & maintained tools (vendor+pin per R4-D10, don't rely on global install):**
- **OneRedOak `design-review` subagent** — github.com/OneRedOak/claude-code-workflows (~3.8k★). Playwright-driven
  live-page render + 7-phase critique. The standout; closes the rendered-output gap. ADOPT.
- **Vercel `web-design-guidelines` skill** — github.com/vercel-labs/agent-skills (~27.8k★, official). Static UI
  linter vs 100+ guidelines. ADOPT (cheap, matches existing vercel pack).
- **Figma Code Connect** — official; maps Figma components ↔ real React files (enforced reuse). Already have
  Figma MCP. TRY→ADOPT (durable, higher setup).
- **shadcn MCP + private registry** — publish `docs/design/` components as a registry so the agent installs
  OUR components. Conditional on shadcn base. TRY.
- **Anthropic `frontend-design` skill** — official anti-slop rules. BORROW the rules, don't let "be bold"
  override the locked brand.
- **Token-linter in CI** (Stylelint / `eslint-plugin-design-system`) — deterministic backstop. ADOPT in CI.
- Sources: Anthropic Frontend-Aesthetics Cookbook; v0 design-systems docs; hvpandya.com/llm-design-systems;
  Puck "AI slop vs constrained UI"; UICrit (arXiv 2407.08850); Cursor Design Mode.

### R4-D15 — UI quality: ADOPT existing skills + compound the feedback; don't build a custom one (2026-06-12)
Tanner: *"Let's add feedback to /compound and then the best UX and UI design skills available. I don't think we
need to build one."*

- **Buy, don't build** for the review/critique side. Adopt the best existing skills (vendored + pinned per
  R4-D10, self-contained, no global-install reliance):
  - **OneRedOak `design-review` subagent** — rendered-page critique (the standout from research).
  - **Vercel `web-design-guidelines` skill** — static UI lint vs 100+ guidelines (official).
  - **Off-the-shelf token-lint** (Stylelint / eslint-plugin-design-system) as the deterministic pre-commit
    backstop — **CONFIRMED by Tanner**: any color/spacing/font outside the design tokens FAILS the commit (no
    AI judgment; the single highest-ROI anti-drift gate). Lands in the existing pre-commit gate alongside
    lint/tsc/vitest. (Wiring the hook is a human-applied step — hooks/settings are guard files.)
  - **Figma Code Connect** available as the durable second step (he already has Figma MCP).
  - Do NOT build a bespoke design-review agent.
- **Wire UI/design feedback into `/compound`** — corrections → design rules; approved screens → few-shot
  exemplars. Reuses the existing compounding loop (CMP1/`/compound`) for "gets better every project" rather
  than a new mechanism.
- Human keeps brand-taste origination + the final "$30k-worthy?" call (the part AI provably can't originate).

### R4-D16 — UX quality: strengthen @ux-reviewer into tiered inspection; never fake human metrics (2026-06-12)
Web-grounded research. Core honesty rule: **split UX checks into agent-legitimate (inspection) vs. real-human
(empirical) — and NEVER let the agent report empirical metrics as measured.**
- **Tier 1 — agent measures (legitimate):** physical interaction cost (count clicks/steps/fields to finish a
  task), cognitive walkthrough (4 Wharton/Lewis questions per step via browser MCP), Nielsen 10-heuristic eval
  (3–5 lens passes), happy-path functional completion (report as N=1, never a success RATE), and a hard
  accessibility gate via `@axe-core/playwright` (block merge on critical WCAG violations).
- **Tier 2 — flag, never certify:** first-impression clarity, CTA-promise, predicted first-click ambiguity
  (~40% false-positive noise — triage, don't trust).
- **Tier 3 — real-user deferred (write into the doc, never claim verified):** first-click test, task-success
  RATE, SUS, SEQ — need n≥20–30 real humans. A simulated persona = a PREDICTION, not a measurement. The harness
  must never emit "92% task success" / "5-second test passed" — that's dangerous fabricated data.
- **Tie UX intent to the feature doc** via Goals-Signals-Metrics + Gherkin Given/When/Then, so "≤N clicks" and
  "primary CTA is first/most prominent" become directly runnable by the browser MCP. **Per-task click budget**
  (the global "3-click rule" is debunked — NN/g; set N per task from a KLM ideal path; agent counts, human sets
  the budget).
- **Compound** via `/compound`: accumulate realistic step budgets + recurring confusion patterns per project.
- **Adopt:** `@axe-core/playwright` (Deque, ~4.7M dl/wk) as the a11y gate; Chrome DevTools MCP for perf/CrUX
  (surface before installing — touches `.claude/mcp.md`). Lift STRUCTURE (not a dependency) from OneRedOak +
  Vercel interface guidelines. SKIP: synthetic-user / LLM-as-judge products, "Nielsen heuristic" prompt-pack
  skills (no real measurement). Human/real-user step stays for comprehension — the harness PREPARES it, never
  replaces it.
- Sources: NN/g (interaction-cost, 3-click-rule, success-rate, synthetic-users); Wharton 1994 (cognitive
  walkthrough); Card/Moran/Newell (KLM); MeasuringU/Sauro (78% benchmark, lostness); Google CHI 2010 (HEART);
  Brooke 1986 (SUS); axe-core/playwright; vercel-labs/web-interface-guidelines.

### R4-OPEN — Existing skill/agent ROSTER not yet reviewed (2026-06-12)
Tanner: *"It seems like we should be keeping skills such as /improve-codebase-architecture, but none of those
have been mentioned either."* Fair hit — the round has been ADDITIVE (new designers, UI/UX quality, security,
packaging) and never inventoried the EXISTING roster (~26 skills + ~23 agents). The self-contained add-on
(R4-D10) + P10 (roster as portable roles after prune+dedup) REQUIRE a keep/cut/bundle decision for every
existing skill/agent. Proposed next: a roster review (inventory all skills+agents → keep / cut / improve / does-
it-travel-in-the-add-on), surfaced reviewably like the deferred-items list. Pending Tanner's go + scope.

### R4-D14a — Architecture designer must cover FRONT-END architecture too, framework-adapted (2026-06-12)
Refines R4-D14. Tanner: *"front-end is as important to me [as backend]… I love Michael Thiessen's courses for
reusable/clean components… not sure how well they apply to React."* Provided a rigorous Vue architecture doc
(another project: race-tracking, Firebase/Vue/Pinia) as the depth/rigor template.

- **The architecture designer covers BOTH sides** — backend AND front-end component architecture, equal rigor.
- **Front-end architecture doc per project** at the depth of the pasted Vue doc: layers + strict one-way
  imports, architecture tests, golden exemplars, tech-debt ledger.
- **Thiessen/Vue → React transferability (my read, being research-validated):** the principles transfer ~1:1
  (testability-driven layering, pure-logic/reactive-logic/shared-state separation, humble I/O components,
  golden exemplars, arch tests). The MECHANICS adapt per framework (Vue composables→React hooks; Pinia→Context/
  light store; provide/inject→Context; PLUS React/Next's Server-vs-Client-Component boundary as an extra axis).
  event-vendor's CLAUDE.md already encodes the backbone. **Apply the principle, judge the mechanics for the
  framework** (= R4-D14's "best practice must be applicable" nuance). 
- Research thread launched: Thiessen's actual principles + their React/Next mapping + best front-end-arch to
  encode in the designer, framework-adaptable. Synthesize → present.

### R4 — Roster review IN PROGRESS (2026-06-12)
Tanner approved the full inventory. Roster on disk: **26 skills + 23 agents** (1 known-empty: `dep-update/`).
Two parallel classification passes launched (skills, agents) → reviewable keep/cut/improve/travels artifact.

### R4-D14b — Front-end architecture designer: universal skeleton + framework fill-in (2026-06-12)
Research (Thiessen Vue → React, cited). The architecture designer generates ONE fixed **universal skeleton**
and fills **framework-specific slots** — never project-specific (see `feedback_harness_is_project_agnostic`).
- **Universal skeleton (identical Vue/React/etc.):** layered one-way imports (each layer testable by mocking
  only the layer below); pure logic separated from framework glue; humble I/O components + an orchestration
  layer + a state source (Thiessen's triad); a reusability calibration ladder (don't over-abstract; rule of
  three); per-layer testability; the 3 architecture-test questions as an enforceable gate; golden exemplars per
  layer; a tech-debt/decision ledger.
- **Framework fill-in (designer judges, never copies):** reactive unit (Vue composable ↔ React hook); slots
  (Vue slots ↔ React children/named ReactNode/render-props/compound components); shared state (Pinia ↔ Context/
  light store); DI (provide-inject ↔ Context).
- **Two things that must NOT be cargo-culted (the R4-D14 nuance, concretely):** (1) Vue "thin composables" do
  NOT become "thin hooks" — React hooks re-run every render and aren't plain-testable, so pure logic goes in
  plain `.ts` files the hook merely adapts (this is what event-vendor's CLAUDE.md already does). (2) The
  **client state-management library is a per-project recorded decision, never hardcoded** — only the
  server-/URL-/local-state taxonomy is universal.
- **React/Next adds an axis Vue lacks:** Server vs Client Components (Server default, push `'use client'` to
  leaves, Server Actions for writes; server-side data layer absorbs much "store" need — converges with the
  backend `src/data/` rule).
- Sources: Thiessen (12-patterns, scaling, 6-levels, slots>props); ReactUse hooks-vs-composables; Martin Fowler
  headless-component; patterns.dev; react.dev rules; Developer Way state-2025; freeCodeCamp Next.js architecture.

### R4 — CORRECTION: harness must be PROJECT-agnostic (2026-06-12)
Tanner caught me writing "you've banned Redux + deferred React Query" into the portable harness design. That's
an event-vendor fact. **The harness encodes only universal patterns; project-specifics are read from each
project's config, never baked in.** Captured as memory `feedback_harness_is_project_agnostic`. (The FE-arch
research reached the same conclusion: state-library = per-project decision, taxonomy = universal.)

### R4 — ROSTER REVIEW RESULTS (2026-06-12)
**Skills (26): 19 KEEP · 6 IMPROVE · 1 CUT.**
- **CUT:** `dep-update` (empty folder, no SKILL.md).
- **IMPROVE (mostly executing prior decisions):** `feature` + `design` hard-require 3 global Matt-Pocock skills
  (`/grill-with-docs`, `/to-issues`, `/simplify`) → **vendor them** (executes R4-D10 self-containment; highest-
  leverage portability move). `tdd` **name collision** — a complete LOCAL skill exists AND docs list `/tdd` as a
  required global → keep the local, drop it from the global-required list. `notion-sync` + `compound` Step 8
  both write the old Notion canon → rework/retire under the Notion→GitHub move (P3). `supabase` +
  `supabase-postgres-best-practices` (symlinked Supabase-authored packs) → become the pluggable **backend
  adapter** (PROJECT-SPECIFIC, not universal core). `dev` overlaps `feature` → folds into the one-command
  driver (executes R4-D7 #3). `explain` is React-learner-specific → keep for this user, not the portable pack.
- **KEEP + UNIVERSAL core:** cr, cr-security, debug, incident, hotfix, post-mortem, migrate, behavior-change,
  perf, spike, evaluate-solution, refactor, review-strategy, setup-strategy, prioritize-tasks, queue, tdd.

**Agents (23): 21 KEEP · 2 IMPROVE · 0 CUT** (tight roster, no dead weight, every agent has a live spawn path).
- **IMPROVE:** `ux-reviewer` (strengthen per R4-D16), `doc-updater` (generalize — hardcodes this repo's doc set
  + `.claude/agentic-system-enabled` gate).
- **Model re-audit candidates (the C13 item):** 6 reasoning agents pinned `sonnet` — `reviewer`, the 4 `lens-*`,
  `spike-synthesis`, `spike-adversarial-verifier`, `security-reviewer`, `solution-evaluator`. (Only
  `spike-orchestrator` + `task-runner` are on opus, correctly.)
- **Portability snags:** 3 agents (`incident-responder`, `hotfix-guard`, `solution-evaluator`) use legacy tool
  names (`read_file,list_files,bash`); `doc-updater` is the only genuinely PROJECT-SPECIFIC agent.

### R4 — mattpocock/skills SURVEY (2026-06-12)
Repo is MIT + very actively maintained (pin to a SHA; vendor the `setup-matt-pocock-skills` glue with any
engineering skill since they need a per-repo label/CONTEXT config). Already using: grill-with-docs, simplify,
to-issues, tdd. **Adopt candidates:** `zoom-out` (ADOPT — trivial codebase-navigation aid), `write-a-skill`
(ADOPT — serves the self-contained-harness goal), `prototype` (ADOPT — best UI-exploration fit for Next/React/
Tailwind), `triage` (TRY — issue-tracker backlog grooming / `ready-for-agent` routing; DIFFERENT from `/incident`
which root-causes a live failure — `/triage` grooms the inbound backlog), `to-prd` (TRY — completes PRD→issues→
queue chain). SKIP: diagnose (overlaps /debug), grill-me (subset of grill-with-docs), caveman (conflicts with
teachable-explanations), git-guardrails/setup-pre-commit (already have stronger), and all in-progress/deprecated.
`find-skills` does NOT exist in the repo.

### R4-D17 — Adopt 4 skills from mattpocock/skills; clarify the backlog→spec→build chain (2026-06-12)
**Adopt (vendor + pin to a SHA, retain MIT LICENSE; bring `setup-matt-pocock-skills` glue for triage/to-prd):**
`zoom-out`, `write-a-skill`, `prototype`, **`triage` + `to-prd`** (Tanner: "triage and to-prd seem useful").

**Backlog → spec → build chain (Tanner asked what handles this + recalled a spec-building skill):**
- **Off the backlog / grooming:** `/prioritize-tasks` (orders TASKS.md vs strategy) → `/triage` (marks a
  ticket `ready-for-agent`).
- **Spec upstream:** `/to-prd` (conversation → PRD) → `/to-issues` (PRD → grabbable vertical slices).
- **The spec-builder Tanner recalled = `@spec-writer`** (writes confirmed testable behavior entries, today to
  `docs/TESTING.md`), plus `/design` contract mode (formalizes the design) + the **before-coding gate** (R4-D4;
  the human-confirmed spec checkpoint before any code).
- **HONEST FLAG → spec-artifact sprawl risk.** We now have 4 spec-ish artifacts: TESTING.md behavior entries,
  the permanent feature doc (R4-D9 hub), the /design contract, and the PRD. To preserve "one source of truth per
  feature" (R4-D9): **the feature doc is the SINGLE spec hub; the others are sections/inputs of it** — PRD = the
  "why", @spec-writer entries = the "testable behaviors" section, design contract = the "how it's built"
  section, the gate = the human sign-off. One doc, fed by those steps; NOT four competing docs. (Reconcile when
  building the spec layer / feature-doc generator.)

### R4-D18 — Data-states matrix (universal) + loading strategy (per-project) (2026-06-12)
- **UNIVERSAL, enforced:** every front-end change must handle the full state matrix — **no data (empty) · some
  data · lots of data (overflow) · bad data (error) · loading.** Enforced 3 ways: the design-review agent
  renders & checks each state; the before-coding mockup must show them; a checklist line in the feature doc.
  Universal constraint: **no layout/page shift.** (Also in the Vue doc Tanner pasted — a traveling principle.)
- **PER-PROJECT (Tanner applied the project-agnostic rule himself):** the *loading-state strategy* is NOT a
  harness default. The harness documents BOTH techniques + the principle; each project picks its default in its
  own architecture config:
  - *No-loading-state-first* — architect the spinner away via server-render-with-data / route-level loading /
    prefetch-on-hover (Next.js Server Components give much of this for free). Best where the stack supports it.
  - *Layout-stable skeleton* — where a loading state is unavoidable (slow client-fetched data), reserve the
    exact final space so there's zero page shift.
- **References (fit v2; reinforced existing decisions, not new scope):**
  - jjenzz "Best loading states are no loading states" (https://jjenzz.com/best-loading-states-are-no-loading-states/)
    — the no-loading-first technique; aligns with the RSC axis (R4-D14b).
  - Smashing "How to make a design system AI-ready" (2026-06) — validates R4-D15: machine-readable spec files
    the AI reads, closed token sets, audit hardcoded values + **missing states**, sync routines. The "audit for
    missing states" dovetails with the state matrix above.

### R4-D19 — Performance: proactive, measured + logged + warning (non-blocking) (2026-06-12)
- Articles are **food for thought, not gospel** (Tanner) — held as references, nothing codified as a hard rule.
- **Performance is a first-class proactive concern**, not just reactive `/perf`. Every front-end PR gets its
  speed **measured and logged**, with a **warning (red flag) if it blows budget — but NOT blocking** the merge
  (Tanner: "measured and logged, but not blocking; a warning is fine"). `/perf` stays for fixing real slowness.
- **Core Web Vitals budget per feature** in the feature doc (LCP = load, CLS = layout shift [= the no-page-shift
  rule, R4-D18], INP = interactivity). **Targets are per-project** (project-agnostic); the practice (budget →
  measure → warn → /perf) is universal. Measured via Lighthouse CI and/or Chrome DevTools MCP.
- **Feeds the dashboard (R4-D6):** "logged" perf numbers become another per-project trend the metrics dashboard
  can surface over time.

### R4 — TOKEN-EFFICIENCY + MODEL-LEVERAGE pass (requested 2026-06-12)
Tanner: *"a pass on all of this for token use and where we are not utilizing the model's capabilities… if
everything blows through tokens, there's an issue. Keep a simple and powerful harness that utilizes the model's
growing capabilities where possible."*
- **This is already a V2 pillar, not a new idea:** the vision's model-capacity prune loop (C13/CMP6/§9 — "remove
  the scaffold the model outgrew"), grounded in ETH Zurich (comprehensive/already-inferable context DEGRADES
  output ~3% AND raises cost 20-23% → bloat is a double loss). Tanner elevates it to a full pass over the Round-4
  design.
- **The honest big risk:** quality-battery FAN-OUT per task. A single feature could run 3 design specialists +
  grill + spec-writer + implementer + /cr (9 passes + 4 lenses) + design-review + ux-reviewer + red-team + perf
  + doc-updater = dozens of full-context agent loads.
- **Mitigations (mostly already in design):** (a) scale battery to task size (tiny → almost none); (b) combine
  passes a capable model can hold at once (re-audit the 9 /cr passes + the 3 design specialists — do they need
  to be separate agents on Opus 4.8?); (c) selective context, not dump-everything (CMP1 read-back + feature-doc
  hub feed RELEVANT slices); (d) re-run this audit on every model bump (the "uses the model's GROWING
  capabilities" engine). Keep where ISOLATION genuinely adds quality (4-lens argument) vs cut legacy scaffold.
- Fresh adversarial audit launched (doer≠checker — I designed it, so an independent critic hunts the bloat).
  Synthesize → present cuts/combines → decide.

### R4 — TOKEN-EFFICIENCY AUDIT RESULTS (adversarial, doer≠checker; 2026-06-12)
Core insight: **isolation buys independence (worth tokens); redundant analytical splitting + dump-everything
context buy nothing.** The design cites the ETH bloat finding then violates it (the "feature-doc everything ties
to" hub + load-all-findings read-back). The fix = run the prune the design already specifies, on the Round-4
additions, with C4 golden-set recall as the falsifiability instrument.

**The 5 highest-leverage reductions:**
1. **`/cr`: collapse the 9 analytical passes → 1 broad Opus pass + push the mechanical/lint-shaped checks (any,
   as-without-narrowing, Supabase-outside-src/data, no-DB-mock, missing cache()) to ESLint/tsc/hooks (zero model
   tokens). KEEP the 4 isolated lenses (Pass 10) untouched.** Diff was loaded ~13×/review → ~5×. Falsifiable via
   C4 recall.
2. **SCALE-TO-TASK via the existing blast-radius classifier (reuse LOOP-7/A6, don't invent a 2nd):** minimal
   battery is the DEFAULT; machinery added only when the diff's risk earns it. LOW (docs/copy/1 pure fn) → 1
   Haiku pass (generalize the existing /cr Step-0 docs path). MEDIUM → combined analytical + 4 lenses + ux/perf
   ONLY if a screen is touched. HIGH (auth/RLS/payments/public/schema) → full battery incl. red-team. **Invert
   the design: minimal is default, not the full battery.**
3. **3 design specialists → 1 coherent Opus design pass** (schema/API/front-end are interdependent collaborators,
   NOT independent checkers — splitting hurts coherence AND costs more). KEEP the independent design-grill (real
   fresh-eyes isolation). KEEP the human schema-approval gate.
4. **Dump-everything → relevant-slice-only context:** feature-doc = read the needed SECTION; recurring-findings
   read-back = load only signatures matching the touched files (CMP1's decay handles staleness, a relevance
   filter handles size); exemplars = the one golden exemplar for the layer. **Full context ONLY for the safety
   floor** (never prune safety per `feedback_locks_always_on`).
5. **Elevate the 6 reasoning agents (reviewer + 4 lenses + security-reviewer) to Opus — as ONE coordinated move
   WITH the combines**, gated/measured by C4 recall (the combines are only safe if the backstop runs on the
   capable model). This is C13 made a hard precondition.

**KEEP — genuinely earns its tokens (do NOT cut):** the 4-lens adversarial pass (fresh isolated context, C2's
43%→91%), the independent design-grill, F6 (unforgeable CI gate, near-zero token), the deterministic floor
(lint/tsc/token-linter/axe — zero model tokens; EXPAND it per #1), and C4 golden-set recall (the instrument that
makes every combine falsifiable, not faith-based — **build it FIRST**).

**Sequencing:** build C4 recall → then prune (#1-3) + elevate (#5) → measure recall before/after; keep the split
only where recall drops.

**Standing principle (bake in):** *add a separate agent/pass only when it buys independence a single context
structurally cannot — a fresh adversary, a deterministic gate, or a human checkpoint. Everything else is one
capable-model pass, proven safe by golden-set recall. Never split work the model can hold; never load context it
can already infer.* (= the operational form of the model-capacity prune loop, CMP6/§9, applied to the harness
itself; re-run on every model bump.)

### R4-D20 — Apply the token-efficiency prune, GATED ON THE CATCH-RATE (2026-06-12)
Tanner chose the falsifiable path. **Sequence: build C4 golden-set recall measurement FIRST → then do the
combines (R4 audit #1-3,5: 9 /cr passes → 1 Opus pass + lint; 3 designers → 1; selective context; reasoning
agents → Opus) → measure recall before/after → keep a split only where recall actually drops.** Nothing cut
blind. This makes C4 a hard build prerequisite and bumps it up the build order. The independence pieces (4-lens,
design-grill, gates) and the deterministic floor stay untouched. The standing principle (independence-only earns
a separate pass; everything else = one capable pass proven by recall; never load inferable context) is now a
build-time rule AND the recurring model-bump prune (CMP6/§9).

### R4-D21 — Sub-agent spawn doctrine: independence/parallelism/scale, trust + log (2026-06-12)
**The spawn rule (= the operational form of the token principle, R4-D20):** spawn a sub-agent ONLY when it buys
one of three things a single pass structurally can't — (1) **independence** (a fresh adversary/reviewer with
clean context: the 4 lenses, the design-grill, verification), (2) **parallelism** on genuinely separable work
(N independent items, no cross-dependency), or (3) **scale** (work too big to hold — want the conclusion, not
the file-dumps). **Do NOT spawn for:** judgment against material the main context already has (the bloat),
interdependent/sequential work (sub-agents can't share context → re-derivation), or small/known tasks (overhead
> work). One-liner: **independence, parallelism, or scale — or don't spawn.**
- **Two layers:** the per-task BATTERY (which agents fire) = the deterministic risk classifier (LOW/MEDIUM/HIGH,
  decided in the token audit). AD-HOC spawns (model deciding mid-task) = the doctrine above as judgment.
- **Governance (Tanner's pick): TRUST the doctrine + LOG every spawn** to the dashboard (count + which of the 3
  justifications). Leans on the model, keeps fan-out visible/tunable, no mid-task friction — "measured, not
  blind" (matches the perf call R4-D19). Tighten the rule only if the logs show over-spawning.

### R4-D22 — Design-system is a PREREQUISITE; bootstrap one if missing (2026-06-12)
Tanner: *"if the design system isn't built it will need to be."* The "build only from the design system" rule
(R4-D15) assumes one exists. event-vendor has `docs/design/` (tokens + components); another project may not.
**Step zero of the UI-quality system: detect whether a design system exists; if not, help build one first** —
establish the color/spacing/type tokens + core components + the machine-readable spec the AI reads. Until it
exists there's nothing to constrain the AI to. Bootstrapping tools: the adopted `prototype` skill + the
"AI-ready design system" approach (machine-readable spec files, closed token sets). Project-agnostic: the
harness detects + bootstraps per project; never assumes event-vendor's design system.

### R4 — design-review helper token cost (Tanner questioned 2026-06-12)
Tanner: *"what's the token cost of rendering every time to an agent? Is this worth it?"* Honest cost: a rendered
visual review = screenshots (often 3 breakpoints) + browser ≈ **5–15k tokens/run** (images are token-heavy). On
every UI change × 5 repos = significant. Its UNIQUE value is taste a checker can't see (hierarchy, spacing
rhythm, polish); the FREE deterministic checks (token-lint, a11y gate, states matrix) catch most slop at zero
tokens. → Recommendation: **gate the rendered design-review to MEANINGFUL UI changes only** (new screen, layout
change, new component), skip it for copy tweaks / logic-only / trivial; lean on the free checks otherwise; log
its cost. (Scale-to-task applied to the most expensive helper.) Pending Tanner's call.

### R4-D23 — Rendered design-review helper: gated to meaningful UI changes only (2026-06-12)
Tanner's call on the token-cost question. Run the rendered visual design-review ONLY on meaningful UI changes
(new screen, layout change, new component); skip for copy tweaks / logic-only / trivial. The FREE deterministic
checks (token-lint fail-the-commit, a11y gate, all-states rule) run on every change regardless. Log the
design-review's token cost. (Scale-to-task on the most expensive helper.)

### R4-D24 — Frictionless human handoff: every task hands over a checklist + exact commands (2026-06-12)
Tanner: every task that needs the human to act gives a **manual checklist** + the **exact terminal commands** to
keep going — `cd` to the right worktree, start the dev server, and `open` any artifact built. "Make it easy for
the user to keep going." A V2 harness feature (a "handoff block" on every human-action task; ties to L7
narration + the verify step) AND a standing rule for the agent now. Captured in memory
`feedback_frictionless_handoff`.

### R4-D25 — Patterns registry alongside golden exemplars; captured by /compound, read by agents (2026-06-12)
The architecture doc's **golden exemplars** (one canonical file per layer) get a companion **patterns registry** —
*multi-file* recipes that span several files (e.g. "how to subscribe to Firestore," "add a custom field"). 
`/compound` actively looks for + captures/updates BOTH golden-exemplar and pattern additions; agents **read the
relevant ones (sliced) when writing code** (ties to CMP1 read-back + the feature-doc hub). Project-agnostic —
each project's own patterns.

### R4-D26 — Self-documenting code; comments earned, why-only (2026-06-12)
Universal rule (already in event-vendor CLAUDE.md, made harness-wide): well-structured, well-named code does
~90% of the job; **comments are last-resort, one line max, explain the WHY when non-obvious — NEVER the WHAT.**
Agents over-comment — the readability review pass + a lint check flag it.

### R4-D27 — Test verification: a writer + a "do they catch bugs?" verifier (2026-06-12)
Tanner asked how tests are verified. Today: written by `/tdd` + `@implementer`; verified two ways — (a) the
**transcription check** (`/cr` test-quality pass: "delete the implementation — does any test fail? if not, it's
a fake test that mirrors the code"), and (b) **mutation testing** = the generalized "break-the-code" testing
(R3 Card 5: deliberately break the code, a test MUST scream; the money-math instance is parked till the pricing
schema settles). → Make this an explicit pairing: a **senior-level test-writer** + a **mutation verifier**;
the catch-rate golden-set (C4) measures the REVIEWER, mutation testing measures the TESTS.

### R4-D28 — Drop /grill-me; keep only /grill-with-docs (2026-06-12)
Confirmed (the mattpocock survey already flagged `/grill-me` as a redundant subset).

### R4 — Tight feedback loops (feedback.png, John Crickett; food for thought, 2026-06-12)
Reinforces the design: small slices · success defined before starting · run checks immediately (agent runs
them) · feed back EXACT results (error/diff/log, never "still broken") · minimal next change · commit each
stable step. **New emphasis to weave in: TIGHT loops — shrink the gap between an action and its validation**,
for the agent (in code + systems) AND the human reviewing. Strengthens the per-commit checks, the review, and
the small-commit habit.

### R4-D29 — Deep AI-activity dashboard / observability (2026-06-12)
Expand the dashboard (R4-D6) into deep visibility — *"if we're going to use agents more, we need to know
what's actually going on."* Track **per AI task**: count · WHICH task · the git commit SHA · how it was kicked
off (Linear / Slack / user / …) · which model(s) used · which skills + agents fired (+ the spawn log, R4-D21).
Surface: what's working vs. not, model usage, where more/fewer skills or agents would help. An **AI-activity
ledger** (ties L7 observability log + CMP3 metrics) feeding the dashboard. Deep visibility is the precondition
for trusting more agent use. (Ideas, not gospel — design thoroughly.)

### R4-D31 — No separate router; lean on built-in routing + per-skill model tiers (#8/#9) (2026-06-12)
- **No router layer.** Claude Code already routes by reading each skill's description and invoking the match —
  so the user can describe what they want; they don't have to memorize skill names. Make that reliable (sharp
  descriptions). A bespoke router would mostly duplicate the built-in behavior.
- **Model utilization (#8):** each skill/agent **declares its model tier** (cheap / standard / strongest; free
  linter for mechanical work), kept current by the model re-audit (C13/CMP6) — so the right model runs per task.
- **Log every routing + model choice** to the deep dashboard (R4-D29). (= "measured, not blind" for routing.)

### R4-D30 — External skill-repo review results (#5) (2026-06-12)
Answers "am I better off using theirs?" → **No — not reinventing wheels; keep the curated set.** Verdicts:
- **`pbakaus/impeccable` (38k★, Apache-2.0) — ADOPT the deterministic DETECTOR only.** `npx impeccable detect`
  = 27 zero-token / no-AI design-slop rules (purple gradients, bad easing, sub-44px touch targets, skipped
  heading levels) + a 12-rule LLM critique. Real capability gap; advances the UI-quality plan (the deterministic
  token-check expanded); the lean/zero-token approach Tanner wants. Vendor + SHA-pin the CLI, retain NOTICE, wire
  into design-review / pre-commit. **Do NOT** vendor its 23 commands (duplicate /design, /cr, UX-reviewer).
- **`leonxlnx/taste-skill` (42k★) — LEARN-FROM:** borrow the 3 "dials" (visual-variance / motion / density) into
  `/design`. Prose only; don't vendor the sub-skill sprawl.
- **`greensock/gsap-skills` — SKIP** (no GSAP in stack; revisit only if GSAP is adopted).
- **`obra/superpowers` (226k★) — SKIP as a foundation.** It has a skill for every methodology step (TDD, debug,
  brainstorm, worktrees, parallel agents, code review) and the harness already has a MORE specialized equivalent
  for each. The 226k stars = onboarding-for-the-empty-harness, not better-than-a-mature-harness; adopting it
  would regress to a generic version of what's built. Borrow at most the "hard design-gate-before-implementation"
  phrasing.

### R4-D32 — AI-engineering reliability package (from the 3-lens review, 2026-06-12)
The AI-engineer lens found the design sound but with risk concentrated in the catch-rate golden set + the
unguarded risk-classifier. Adopt (recommended — these are the "more reliable" wins):
1. **Golden set spec'd properly** (the keystone — everything trusts it): seed from REAL escaped defects (mine
   `RECURRING-FINDINGS.md` occurrence counts + post-merge fix commits), NOT model-imagined bugs (shared blind
   spots inflate recall). Size ≥~80–100; gate combines on the **lower bound of the confidence interval**, not a
   point estimate (a 5% true drop hides in small-N noise). Hold out a rotating slice never tuned against
   (anti-Goodhart). **Auto-grow from every missed bug** (anti-fragile; reuses the RECURRING-FINDINGS pipeline).
   Generate planted bugs from a different model/source than the reviewer.
2. **Deterministic floor = correctness-independence, not just token-saving.** Model-based lenses share a model
   → correlated; a model blind spot defeats all model review at once. Only the deterministic checks + the human
   are truly independent. So: keep EXPANDING the deterministic floor, and **state the limit honestly** ("fresh
   eyes" = fresh context, not independent judgment; the human-merges-everything decision is a load-bearing
   independent reviewer). (Optional, has a cost tradeoff: run one lens/red-team on a different model *lineage*
   for genuine independence — surfaced, not auto-adopted.)
3. **Routing-assertion gate (closes the silent mis-route hole).** "Lean on built-in routing" (R4-D31) has no
   measurement; a mis-route could skip the DB-safety skill (the sole net, R4-D8). Add a deterministic
   sentinel-assertion: a diff touching migrations/RLS/auth/payments must have the matching skill's sentinel, or
   the merge blocks. Log "sentinel-expected-by-diff-content missing" as the mis-route signal on the dashboard.
4. **Model tiers by ROLE, event-triggered.** Replace static per-skill tiers (R4-D31) with 3 roles (deterministic
   / generation / judgment-under-adversary); re-point 3 roles, not 49 files. Fire the model re-audit on the
   **model-id changing in config** (a deterministic laptop-local trigger — closes the drift gap the no-clock
   decision opened).
5. **Guard the risk-classifier.** It's a model judgment that gates all downstream safety (under-classify →
   skip the battery). Add planted "looks-trivial-but-isn't" cases (a 1-line RLS change) to the golden set;
   measure its under-call rate; bias it to over-classify under uncertainty.
6. **Measure retrieval recall, not just bloat.** Selective-context (R4-D20#4) optimized precision without
   measuring "did the slice contain the rule that mattered?" Match findings on touched-*subsystems* (cross-module
   invariants live one hop away), and on a repeat-mistake record "was-retrieved vs not-retrieved" (a model
   problem vs a slice problem — the dashboard headline is uninterpretable without it).
- **Highest-leverage single move:** seed+grow the golden set from real escaped defects, gate on the CI lower
  bound. It fixes the keystone, defuses eval drift, and makes 3/5/6 natural extensions of one anti-fragile loop.

**ADOPTED — all 5 (2026-06-12).** Tanner approved the full package after a plain-language re-explanation.
**TERMINOLOGY FIX (Tanner was confused, rightly):** the catch-rate "golden set" clashes with "golden
exemplars." They're different: golden EXEMPLARS = best code examples (seeded from the best); the catch-rate
tool = a **"bug-catch test"** — code changes with bugs deliberately hidden in them, to check the reviewer finds
them. **Rename it "bug-catch test" in all founder-facing material.** Plain framing of the 5: (1) test the
bug-catcher with REAL bugs (auto-grows from every miss); (2) stop if a safety step got skipped; (3) assume more
risk when unsure; (4) pick the model by kind-of-work (3 buckets: plain-check / normal / hard-thinking), not
per-skill; (5) give the robot relevant past lessons even from nearby files. Reframe note: "unusually
sophisticated" was the reviewer's praise for one smart-but-simple call, NOT a push for complexity — the goal is
simple + reliable, and all 5 keep it simple (several are simpler than before).

### R4 — 3-lens review fixes applied to the pack (2026-06-12)
- **Staff (correctness):** flow #2 fix-path corrected (no invented `/feature`-writes-the-fix; DB-shape stop only);
  internet-guard deferral corrected (BASIC internet limit is build-now — a door already reads outside text via
  `/spike`; only the full allow-list waits); flow #4 "locks things down" → "isolates + logs"; define PR/token/
  red-team. 
- **Newcomer (onboarding):** add a **"Day 1 — your first feature in 5 steps" quickstart**; **resolve the
  describe-vs-command contradiction** (you describe in plain language; the harness picks the skill; the `/names`
  are the skills running, shown so you can see what ran); clarify repo setup-vs-automatic; a "how to read this if
  you're new" note. (The pack is a decision-record AND now an onboarding doc — label the split.)

### R4-D33 — Workstream: audit CLAUDE.md line-by-line → hook/lint or judgment-only (2026-06-12)
Keep all 5 hooks (the deterministic floor); none removed. **Every CLAUDE.md rule either (a) ratchets into a
deterministic hook / lint / CI gate (if mechanically checkable) or (b) is explicitly justified as judgment-only
(needs model reasoning, can't be machine-checked).** CLAUDE.md shrinks toward judgment-only. Route by layer:
PreToolUse = unconditional ban; git hook = conditional w/ git/file state; lint = mechanical code rule; CLAUDE.md
= judgment-only. Ratchet a rule only after it's proven recurring (not preemptive — each hooked rule is
maintenance + a false-block risk). = the CMP2 finding→enforcement ratchet applied to the existing CLAUDE.md.

### R4-D34 — Save off (feature): real-time agent-access control UI (2026-06-12)
Tanner: a **control panel that lets the operator turn agent access to specific keys / databases / resources
on and off in real time.** The live operator control surface over what the agent can touch — pairs with the
credential firewall (F2), the side-effect outbox (F0), and the deep dashboard (R4-D29: *see* what's happening
AND *control* it). Likely post-core (the locks work without a UI), but a strong operator-trust feature; design
as its own pass.

### R4 — Worktree/branch coverage review (requested 2026-06-12)
Tanner: make sure all bases are covered for agents working in worktrees + branches. Known gotchas already in
memory to verify + close: `.env.local` symlink per worktree (pre-push blocks without it), sentinel absolute-path
in worktrees, `additionalDirectories` for bg sub-agents, one-local-stack-at-a-time (config.toml not committed),
settings.json committed-before-AFW, branch-check-before-commit, gone-branch gc + orphaned-worktree cleanup,
UNATTENDED worktree mode + Tier-0 env isolation. Review launched → coverage + gaps.

### R4 — SECURITY review (adversarial, 2026-06-12) — URGENT, mostly present-state
Safety architecture sound; current state dangerous (locks decided but unbuilt while prod blast radius is live).
- **CRITICAL-1:** `.env.local` is world-readable (644), prod service-role key; agent allowed to Read/cat it
  (deny-list blocks Write to `.env*`, NOT Read). FIX NOW: `chmod 600 .env.local` + add `Read` deny for `.env*`
  in settings.json + F2 must ISOLATE/scrub the key, not just "refuse to start."
- **CRITICAL-2:** `block-dangerous-bash.sh` does NOT exist — only git guarded. rm -rf / supabase db push / psql
  DROP / curl mutations unguarded. Build it, fail-closed, full non-git scope. (R4-D8 bets all safety on it.)
- **CRITICAL-3:** untrusted text already enters via `/spike` + `WebFetch(*)` + Chrome MCP — lethal trifecta is
  LIVE on human-started runs; F3/F5 deferred on a stale premise the doc itself corrected. Pull a basic egress
  allowlist + trifecta check into build-now.
- **HIGH-1:** hooks fail OPEN on missing `jq` (`exit 0`). Fix fail-closed. **HIGH-2:** no `managed-settings.json`
  (OS-level) — locks live in agent-reachable committed files (checkout-old-commit / chmod -x). **HIGH-3:**
  routing-assertion is merge-time; damage is run-time → add a PreToolUse run-time twin. **MED-1:** F2 matches the
  Supabase key shape only, blind to Vercel/gh/Stripe tokens (PocketOS = unexpected capability on an unexamined
  token) — generalize to "inventory every reachable credential, treat each as root."
- **Verdict:** NOT ready to build autonomy on until the locks are real; the current live prod key + no bash guard
  IS the Replit/PocketOS setup. Fix CRITICAL-1 first (cheap).

### R4 — COST/ROI skeptic (2026-06-12) — the plan is over-scoped
~70% of V2 is future-autonomy/team-scale machinery justified in future tense, for a SOLO operator who starts +
merges everything and hasn't shipped the product. Key cuts: the **bug-catch test is over-built — Tanner IS the
catch-rate** (reviews every PR, zero build cost); the deep dashboard is fleet-telemetry for a fleet of one
(L1 punted → "kicked off by" has one value); the portable add-on/adapters/manifest is platformization ahead of
a 2nd stack; the rendered design-review + KLM/Nielsen UX machinery + Figma + CWV budgets are redundant with the
operator's own eyes (and AI taste is 0.48 vs human 0.75). **Meta:** the product (proposal tool) isn't shipped;
recipe schema blocked; every harness hour ≠ a product hour.
- **Leanest-worth-it V2 (6):** (1) the locks F1+F2 strongest+first; (2) F6 un-forgeable finish line; (3) the
  collapses done DIRECTLY (no eval gate — you're the backstop); (4) the FREE UI floor only (token-lint +
  impeccable detect + axe); (5) before-coding gate minus the 2nd grill agent; (6) vendor the 3 borrowed skills +
  one `sync-harness.sh`. Defer the rest until product ships or autonomy is real.
- **Verdict:** over-scoped; build the lean 6 in ~a week, then go ship the product.

### R4 — WORKTREE/BRANCH coverage (2026-06-12)
- **G1 CRITICAL:** hook enforcement silently depends on `npm install` regenerating the husky shim (`.husky/_`
  is gitignored, not in a worktree checkout; only `post-checkout` installs it, conditionally). If it doesn't
  fire, ALL pre-commit/pre-push gates silently vanish (fail-open, no signal). Fix: worktree scripts run
  `npm install` + assert `.husky/_/pre-push` exists, fail-closed.
- **G2 HIGH:** three contradictory worktree-path conventions (nested `.claude/worktrees/` enforced by machinery
  vs. sibling `../event-vendor_slug` documented in AI-WORKFLOW.md vs. the git-guard only allowing nested removal)
  → following the docs makes un-editable, un-removable orphans. Fix: standardize on `.claude/worktrees/<slug>`,
  fix AI-WORKFLOW.md.
- **G3 MED:** no pre-commit branch guard (commit-to-main only caught at push). **G4 MED:** parallel-worktree
  local-stack collision undefended (shared one stack, no isolation). **G5 LOW:** sentinel-write CWD unenforced
  (use `$(git rev-parse --show-toplevel)`).
- **Verdict:** sound for the nested layout; NOT ready for heavy unattended worktree use until G1 + G2 close.

### R4 — REVIEW SYNTHESIS: through-line across all 3 lenses
The V2 *thinking* is strong but aimed above the current altitude (solo, human-in-loop, product-not-shipped),
AND there are live present-state holes (prod key readable, no bash guard, worktree fail-opens) that matter
regardless of V2 scope. Recommended path: (1) fix the urgent security + worktree holes NOW; (2) trim V2 to the
lean ~6; (3) ship the product; (4) revisit the deferred 80% when autonomy/fleet is real. PENDING Tanner's call.

### R4 — CORRECTION: the harness and the product are SEPARATE projects (2026-06-12)
Tanner: *"This harness and the product are separate projects. I just happen to be working on it in this one
right now. Once it gets moved to GitHub (soon!), that won't be a thought."* → **The cost/ROI review's
opportunity-cost / "go ship the product" argument (#6) is STRUCK** — it conflated harness work with product
work. The harness stands on its own merit. The imminent **move to its own GitHub repo** also *strengthens* the
packaging/self-contained work (R4-D10) — that's the harness becoming its own distributed thing across the 5
repos, not "platformization ahead of need." The ROI review's OTHER points (bug-catch-test over-built for solo,
deep dashboard, etc.) stand or fall on their own merit; Tanner's deliberate prior choices (R4-D6/D29 dashboard,
R4-D32 bug-catch test) stand unless he revisits a specific one.

### R4 — SECURITY TO-DO (present-state; do before heavier agent use, 2026-06-12)
- **DONE:** `chmod 600 .env.local` (was 644 → now 600). Caveat: the agent runs AS the owner, so this stops
  *other local users*, NOT the agent reading its own user's file. Partial hardening, not the fix.
- **The real fix = credential firewall (F2):** the prod service-role key must NOT be reachable in the agent's
  env at all — use a scoped/local credential; apply prod migrations by hand (F4). chmod + a settings Read-deny
  are insufficient alone (Bash `cat` bypasses the Read-tool deny; agent = owner bypasses chmod).
- **Build `block-dangerous-bash.sh`** (fail-closed, full non-git scope) — so even a read key can't run a
  destructive op. Highest-value security build. (Agent can DRAFT; human places it — guard file.)
- **Place `managed-settings.json`** (OS-level, agent-unreachable) for the truly-unbypassable floor.
- **Fail-closed the existing hooks** on missing `jq` (currently `exit 0` = allow).
- **Basic egress allowlist** (the `/spike` + WebFetch trifecta is live).
- All present-state, independent of V2 scope. Offered: draft `block-dangerous-bash.sh` next.

## REVIEW WORKFLOW PRECEDENT (Tanner asked for it this round)
Tanner requested that the review artifact "be reviewed by a staff engineer before being passed to me." Honored
via a sub-agent staff-engineer review (build draft → adversarial review → fold findings → confirmation pass →
deliver). Worth keeping as the pattern for future founder-facing v2 artifacts.
