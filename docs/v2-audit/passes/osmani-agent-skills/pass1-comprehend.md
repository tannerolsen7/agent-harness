# Pass 1 — Comprehend: "Addy Osmani's agent-skills — Study the Formats, Don't Install the Skills"

What the article SAYS, faithfully. Claims tagged (fact) = primary-sourced from the
repo (README, marketplace.json, SKILL.md files, orchestration-patterns.md) or
mechanically verifiable; (opinion) = the author's judgment/recommendation.

**Provenance note for later passes.** This page is NOT a neutral source. It is itself a
*curator's verdict* on an external repo, written specifically against the event-vendor harness:
it names our Pillars (1/3/4/5), our Nodes (2.1, 12, 13.1, 17), our skills (`/cr`, `/change`,
`/queue`, `/tdd`, `/cr-security`), our open research items (R1, R2, Ashby renderer, learned-patterns.md),
and explicitly says its findings come from "independent deep-understanding and adversarial-application
reviews run as separate agents." So the page is a *two-layer* object: (a) faithful facts about
addyosmani/agent-skills, and (b) the curator's own application verdicts about us. I tag the latter
as (curator-claim) — pass 2 penetrates them, pass 3 verifies them against the ground-truth map.

---

## Thesis (as stated)

addyosmani/agent-skills (MIT) is "the strongest *prose* skills library in circulation": 23 skills
across a Meta→Define→Plan→Build→Verify→Review→Ship lifecycle, three reviewer personas, an
orchestration doctrine, anti-rationalization tables and an evidence-based verification section in
every skill, installable as one Claude Code plugin and portable to Cursor/Gemini/Windsurf/Copilot.
(fact — repo structure) "It is genuinely impressive." (opinion)

The load-bearing claim: the question is **not** "is it good" but whether *installing* any of it
improves "a harness that is already **structurally** ahead of it." The stated answer from two
independent reviews: **"this repo's value to you is formats and named gaps, not skills to install."**
Importing the overlaps "would downgrade structural mechanisms back to advisory doctrine — a Pillar 1
regression you'd pay context budget for." (curator-claim — this is the whole spine of the page)

The page announces its own stance: "deliberately critical… The collection's strengths are real; so
is the reason most of it doesn't transfer." (opinion)

## The two innovations it credits as genuinely load-bearing

Most of the 23 "skills" are "**repackaged senior-engineer canon** given memorable names" — test
pyramid, Chesterton's Fence, Hyrum's Law, code-as-liability, measure-first performance, trunk-based
git, staged rollout — "all from *Software Engineering at Google*-lineage practice." The value is
"curation and forced application, not novelty; calling them '23 skills' inflates the apparent surface
area." (opinion, with a factual basis — the canon lineage is real)

Two ideas it credits as actually load-bearing:

1. **In-flight doubt (doubt-driven-development).** "The insight is *temporal*, not architectural":
   `/review` is "a verdict on a finished artifact"; doubt-driven inserts disproof "*while
   course-correction is still cheap* ('by PR time it's too late')." It is "the one idea here built
   specifically for the way *LLM* sessions fail — context accumulation silently converting
   assumptions into 'facts.'" (fact about the skill's design; opinion that it's the standout)

2. **The orchestration doctrine** (references/orchestration-patterns.md). "The user/slash-command is
   the orchestrator; personas never invoke personas; orchestration depth ≤ 1," with a real rationale
   (each hand-off summarizes → drift + ~2x tokens + lost human checkpoints) "and the integrity to
   argue *against* automating its own lifecycle. The most disciplined document in the repo." (fact
   that the doc states this; opinion that it's the best)

## The central structural critique — "it's all advisory"

The uniform flaw, and the stated reason it doesn't transfer: **"frontmatter is only `name` +
`description` on every skill"** — no `allowed-tools`, no `disable-model-invocation`, no
`context: fork`. So "every safety and independence property is *advisory text the model is trusted
to follow*, not *enforced policy*." (fact — primary-sourced from the skills' frontmatter)

Three concrete instances:

- **security-and-hardening** defines Always / Ask-first / **Never** tiers "but cannot enforce 'Never'
  — there's no tool-deny. The one skill that most needs a hard guardrail has none." (fact + opinion)
- **"Evidence-based verification is mostly self-reported"** — "the /goal transcript-grader problem in
  full." TDD's checklist says "[ ] all tests pass: `npm test`," but "nothing captures and verifies the
  runner's output; the agent checks its own box." Its own red flag — "'all tests pass' but no tests
  were actually run" — "is a tacit admission. The *form* is oracle-grounded; the *enforcement* is
  honor-system." (fact — the checklist is self-graded)
- **Anti-rationalization tables "catch only the excuses the author anticipated."** "They convert
  open-ended rationalization into a finite blocklist — progress, but an agent under pressure produces
  excuse #N+1 not on the list." The sharpest one (doubt-driven's "doubt theater" tripwire: "2+ cycles,
  substantive findings, zero actionable → you're validating, not doubting") "survives *because* it's a
  measurable behavioral signal, not a rebuttal — but even it is self-reported." (opinion, well-argued)

**On doubt-driven specifically as a "gate":** it is "the best-engineered *bias-reduction* mechanism
in any skills repo — and it is **not** a maker≠checker *gate*." "Pass ARTIFACT + CONTRACT, never the
CLAIM" gives "genuine independence of *input* (reduces confirmation bias)," but the reviewer's
*authority* is "entirely derivative: RECONCILE says outright 'the reviewer's output is data, not
verdict — you are still the orchestrator.' The checker can flag but never block; judgment never leaves
the maker." Cross-model escalation is "the strongest independence lever (architectural diversity cuts
*correlated* error) but is still model-judgment, not an oracle — and it's skipped in every
non-interactive context (CI, `/loop`), i.e. exactly when no human is present." The author "is honest
about all this; the surrounding 'adversarial review' language invites readers to over-trust it as a
gate it isn't." (fact about the skill's wiring; opinion about the over-trust risk)

## The meta-router question

Stated answer: **No, don't add one.** Addy's `using-agent-skills` router is "solid *for his
constraints*": cross-harness portability (Cursor/Gemini/Copilot lack Claude Code's native
description-based auto-triggering, "so on those tools a prose router *is* the routing mechanism") and
"23 fine-grained skills with blurry boundaries that need a disambiguator." (fact) "Neither applies to
a Claude-Code-only harness with fewer, sharper, structurally-gated skills." (curator-claim)

For "this system" a prose router would be: redundant with the native mechanical router
(`description=trigger` + three-tier loading); "an always-loaded context tax (Pillar 4 — the 799-line
problem you're shrinking)"; a drift liability ("every new skill must be added or it's a dark skill —
your Node 2.1 `check-resolvable`"); and a Pillar 1 regression (advisory routing over structural
gating). (curator-claim)

The resolution offered: **"a router *advises* order; your gates *enforce* it."** "`/queue`'s
spec-gate forces `/change`; `/cr` is a pipeline stage before a PR can open. You replaced 'the router
tells the model what order to work in' with 'the harness won't let work proceed out of order' —
strictly better." The real routing failure (skills not firing) "is fixed by sharp frontmatter
descriptions… plus actually running `check-resolvable` (Node 17), not by a router." Closing rule:
**"If you ever feel you need a router, that's a signal to consolidate skills, not to add a routing
layer."** (curator-claim + opinion)

## Application verdicts — REJECT the overlaps

"Reject the overlaps — they're Pillar 1 regressions, not free wins." Each "duplicates a stronger
structural mechanism and adds always-loaded surface (Pillar 4) + drift to scan (Node 2.1) +
maintenance against a solo budget (Pillar 5)." The verdict table (all curator-claims):

| Their skill | Verdict | Stated reason |
|---|---|---|
| code-review-and-quality | REJECT | `/cr` = four fresh-context lens agents + REJECT + adversarial pass; theirs is a single in-context checklist. "Downgrade." |
| spec-driven-development | REJECT | `/change` has a reversibility gate; theirs has none. "Two spec front doors = diverging intent stores." |
| security-and-hardening | REJECT (borrow vocab) | `/cr-security` is "F2 recall-weighted + reversibility hard-stops"; only the Always/Ask-first/Never tri-state is worth borrowing. |
| test-driven-development | REJECT (steal Prove-It) | `/tdd` has "ratchets + mutation testing"; only the Prove-It bug pattern is net-new. |
| git-workflow-and-versioning | REJECT | "Tier-0 worktree isolation is structural; theirs is a convention doc." |
| personas (code-reviewer / security-auditor) | REJECT | "In-context personas re-introduce the context contamination your fresh-context lens design (Node 12) exists to prevent." |

## Application verdicts — the THREE surgical imports

1. **The anti-rationalization table as the *format* for `learned-patterns.md`.** "Your
   Recursive-Improvement + Intent-Debt research already demanded executable constraints (excuse →
   why-wrong → MUST-FIX action) and you haven't built the shape. Restructure the Node 13.1 entry
   template to that three-column row; it makes structural inheritance machine-greppable. Lowest-cost,
   highest-leverage change here." (curator-claim)
2. **Cross-model escalation (from doubt-driven) into `/cr`'s adversarial pass.** "Your Pillar 3
   rename (cross-MODEL → cross-AUTHORITY) is a rename with no mechanism. On any MUST-FIX in an
   irreversible class (auth/schema/RLS/payments), escalate ARTIFACT+CONTRACT (never the claim) to a
   *different* model. The only import that changes the *epistemics* of review — but it complements the
   CI oracle, never replaces it." (curator-claim)
3. **code-simplification + deprecation-and-migration → Pillar 5's first *subtractive* enforcement.**
   "Every Pillar-5 tool you have prevents *adding* (net-diff floor, slop linter); nothing drives
   *removal*. Adopt code-simplification (Chesterton's Fence as the guard against blind deletion) and
   fold deprecation into `/change` for `task-type: migration`. Your own first-class pillar is carried
   as UNSOLVED." (curator-claim)

## Gaps the repo "revealed that you hadn't flagged"

- **Trust levels per context source** — "your three-tier loading manages token budget, not graded
  trust; context-engineering's trust taxonomy is a Pillar-4 concept you've under-specified." (curator-claim)
- **Feature flags entirely absent** — "yet your Ashby renderer item assumes a `feature_flag` column.
  Staged rollout (your acknowledged gap) is unbuildable without the flagging discipline." (curator-claim)
- **Deletion has no home** — "Pillar 5 enforcement is entirely additive-prevention, zero
  subtractive-action." (curator-claim)
- **"Critics never build" is a note, not a hooked rule** — the orchestration doctrine ("personas never
  invoke personas") "shows the clean way to codify it in AGENTS.md." (curator-claim)
- **Stop-the-line** — "halt forward work on a defect class until root-caused; relevant to R1 (without
  it an unattended run keeps stacking PRs on a known-broken foundation)." (curator-claim)

## The standing rule (the page's bottom line)

"Against a structural harness, an advisory skill is a downgrade, not an upgrade — so import this
collection as *formats and named gaps*, never as installs." The test for any external skill: does it
add a **structural** capability you lack (adopt), a **format** you can bind to an existing gate
(borrow), or a **prose duplicate** of something you already enforce (reject)? "Three borrows clear
that bar… The other twenty are a paragraph for AGENTS.md or a reject. Resist breadth: against an
unmeasured verifier (R2) and a solo maintenance budget, 23 new skills is 23 new things that can drift
and zero new things you can measure." (opinion — the thesis restated as a rule)

## One-line thesis

Against a structurally-gated harness, prose skills are an advisory *downgrade*: harvest
addyosmani/agent-skills for formats (the anti-rationalization table) and named gaps (subtractive
deletion, feature flags, trust-graded context, stop-the-line) — three surgical borrows — and reject
the other twenty as Pillar-1 regressions.
