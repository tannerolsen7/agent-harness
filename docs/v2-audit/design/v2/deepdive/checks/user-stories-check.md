# Adversarial Check — `user-stories.md`

> **Role:** doer≠checker. A different agent wrote `user-stories.md`; this is an attack on it, not a co-sign.
> **Method:** every claim in the doc was checked against three things — (1) the design spine
> (`../../../ambition/VISION.md`), (2) the on-disk reality of the skills/agents the stories invoke
> (`.claude/skills/**`, `.claude/agents/**`), and (3) the capability facts the design is bound by
> (`../../../capability-facts.md`). Findings are tiered MUST-FIX / SHOULD-FIX / CONSIDER, then a verdict.
> The charge has five questions; each finding names which it answers.

---

## TL;DR verdict

**SOUND-WITH-CORRECTIONS.**

The doc is genuinely strong on the things the charge worried most about. It is **not GitHub-only** — it explicitly
opens with "three ways in, on equal footing" and routes Slack/Linear as first-class doors with a *safety* (not
*precedence*) difference (Q2 ✅). It does **not** invent a `/goal` skill — it uses "the built-in continuation loop"
and even includes a glossary entry correcting older drafts (Q5-adjacent ✅). The feature flow **does** put a written,
human-approved spec before code, and that gate matches the real `/feature` skill on disk (Q5 ✅ for Medium+). The
"what these flows teach us" section surfaces **real, load-bearing gaps** (the missing front-door classifier, the
undecided paging surface, the rebase-invalidates-sentinel problem) rather than restating the design (Q3 ✅).

But three things must be fixed before this is trustworthy as substance for a plain-English deliverable:

1. **A fabricated capability.** The doc says `@investigator` stops on "**payments/money math**." It does not — the
   real agent has no money/payment STOP condition (MUST-FIX-1). This is exactly the "assumes a capability we do not
   have" failure the charge asked me to hunt (Q4).
2. **The spec-first gate has a hole the doc half-hides.** Story B routes bug fixes to `/feature (Tiny)`, and the
   real `/feature` skill writes a spec file *only for Medium+* — Tiny and Small skip it entirely. So "world-class,
   not code-first" is true for the example chosen (a Medium feature) but **not** for the most common path (a small
   fix). The doc's own G2 gestures at this but undersells how big the hole is (MUST-FIX-2, Q5).
3. **A trust-laundering risk in how the stories lean on the unbuilt classifier.** Stories A and B narrate the
   "front-door classifier" as if it is a working part ("the classifier reads the request and decides"), and only in
   G1 admit it does not exist as a built artifact. A reader who skims the stories will believe the routing is solved
   (MUST-FIX-3, Q1/Q4).

Everything else is SHOULD-FIX or CONSIDER. The bones are right; the corrections are about honesty at the hard steps.

---

## MUST-FIX

### MF-1 — `@investigator` does NOT stop on "payments/money math." The doc invents a capability. (Q4, Q1)

**The claim.** Story B.2, the "EARLY-SURFACE PATH": *"If the root cause touches **auth, RLS (...), a database
migration, payments/money math**, or the bug is ambiguous — it STOPS AND SURFACES to the operator."* The appendix
table repeats it: *"Early-surface on auth/RLS/migration/billing."*

**The ground truth.** The real agent (`.claude/agents/investigator.md:67-77`) has exactly 7 STOP-AND-SURFACE
conditions. They are:
1. Cannot reproduce after two attempts
2. Root cause ambiguous between two locations
3. Root cause touches **auth, RLS, or data access boundary**
4. Root cause requires a **schema migration**
5. Symptom appears outside initial search scope
6. **A NEVER rule in CLAUDE.md** would be violated by the likely fix
7. The bug appears **systemic** (multiple root causes feeding one symptom)

**Payments / money math / billing is not in that list.** The doc's "7 BLOCKING STOP conditions" *count* is correct
(there are 7), but it then *describes the wrong 7* — it swaps the real conditions #5/#6/#7 (out-of-scope, NEVER-rule,
systemic) for a fabricated "payments/money math," and the appendix hardens the fabrication into "billing." This is
the precise failure the charge named: **a step that assumes a capability we do not have.**

**Why it matters (not pedantry).** Money math is the single most $30k-client-dangerous surface in the product
(Monica's whole reason for "world-class"). A plain-English deliverable that tells the reader "the investigator stops
before touching money" is selling a safety property that *is not wired*. Worse, it's plausible enough that nobody
re-checks it. Money math is only protected *late* — at `/cr` REJECT time via F7's "auth/schema/payment change with
zero/negative test delta" trigger (`VISION.md:306-307`) and at C11's property-based-testing gate — not *early* at
the investigator. The doc conflates an early-surface guarantee with a late REJECT trigger.

**Fix.** Either (a) correct the description to the *real* 7 conditions and state money-math protection lives later
(F7 REJECT + C11 PBT), OR (b) if "investigator should stop on money math" is a desired *new* design item, name it as
a GAP/new-design-item ("add a money-math STOP condition to `@investigator`"), do not narrate it as existing.
**Recommended:** do both — correct the prose AND log the gap, because adding a money-math early-tripwire is a
genuinely good idea that G4 already half-argues for.

---

### MF-2 — Spec-first has a hole the doc under-discloses: Tiny/Small fixes skip the spec entirely. (Q5)

**The claim.** Story A's headline: *"a feature does NOT start with code... a clear written spec that a human
approves before any code is written."* This is presented as *the* discipline that makes output world-class.

**The ground truth — and where it breaks.** The real `/feature` skill (`.claude/skills/feature/SKILL.md:51-54`,
`:105`, `:128`) writes a `docs/specs/<slug>.md` with `human-approved: false` **only for Medium (6–15 behaviors) and
Large (16+)**. The **Tiny (1 behavior)** and **Small (2–5)** paths have *no spec file step at all* — Tiny is just
`Confirm → TESTING.md → /tdd → /simplify → /cr`. The doc's Story A picks a *Medium* example (line-item comments), so
it reads as airtight. But:

- **Story B explicitly routes bug fixes to `/feature (Tiny)`** (B.3: *"the filled TASK-TEMPLATE goes to `/feature`
  (Tiny)"*). Tiny has **no spec gate.** So the most common autonomous path — a bug becomes a small fix — *is*
  code-first by the real skill's own table. The "world-class spec-first" headline does not hold for it.
- The doc's own **G2** says spec-first "has no deterministic gate... a bug-to-PR trigger could plausibly route a
  feature-shaped request straight to coding and skip the spec." That's the right gap — but it frames it as a
  *trigger-routing* risk ("a feature-shaped request gets miscategorized"). The deeper, simpler truth is that **even
  when correctly categorized, Tiny/Small features have no spec by design.** G2 undersells this: it's not just "the
  trigger might misroute," it's "two of the four size classes never write a spec."

**Why it matters.** This is the crux of the charge's Q5 ("does the feature flow actually ensure a SPEC exists before
code, or skip to coding?"). The honest answer is: **for Medium+, yes; for Tiny/Small, no.** A deliverable that
claims spec-first universally will be wrong the first time a reader watches a small fix ship.

**Fix.** State the size-class truth plainly: spec-first is a Medium+ guarantee. Then make a *design decision* visible
— is that acceptable (a 1-behavior fix arguably doesn't need a spec doc, the failing test IS the spec), or should
Small at least get a lightweight spec? The TASK-TEMPLATE contract (inputs/outputs/must-not/done) that B.2 produces
*is* a spec-shaped artifact for the Tiny path — the doc could lean on that and say "the spec for a Tiny fix is the
failing test + the TASK-TEMPLATE, not a `docs/specs/` file." That's defensible and honest. What's not OK is implying
every path writes an approved `docs/specs/<feature>.md`.

---

### MF-3 — The stories narrate the front-door classifier as a working part; it exists nowhere. (Q1, Q4)

**The claim.** Story A.1: *"The front-door classifier reads the request and decides the downstream path."* Story
B.1: *"The classifier routes..."* Story C.1: *"The front-door classifier sees incident-class and routes..."* These
read as descriptions of an existing mechanism.

**The ground truth.** There is **no classifier skill or agent on disk** (verified: nothing in `.claude/skills/` or
`.claude/agents/` matching class/triage/router/front-door). The *only* place a "front-door classifier" is described
as a built thing is this user-stories doc. The github-usage design (`../../github-usage.md:166-185`) shows the
trigger trifecta as a routing *table* and a GitHub Action skeleton, but the thing that reads **free text** and emits
{feature, incident, behavior-change, needs-human} is not specified there either — it's a box labeled "classifier →".

**The doc's own G1 admits this** ("the actual classifier... is described only as a step, never as a built artifact
with inputs, a decision table, and a confidence threshold"). So the doc is *internally* honest — but the **stories
themselves** spend three flows treating the classifier as load-bearing and working, and the correction is buried 400
lines later in the gaps section. A reader building a mental model from Stories A–C will believe routing is solved.

**Why it matters.** This is a trust-laundering shape: narrate capability up front, disclose absence at the end. For a
*teaching* deliverable the order matters — the reader internalizes the first telling. And the classifier is on the
**critical path for Slack/Linear being genuinely first-class** (the doc says so itself in G1): a label is a
controlled token that needs no classifier, but free text *requires* one. So "Slack/Linear are first-class" is
*aspirational until the classifier is built* — a caveat the stories don't carry.

**Fix.** When the stories first invoke the classifier, mark it inline as not-yet-built ("the front-door classifier —
a design addition, see G1 — would read..."). Cheap, one clause per story, and it stops the deliverable from
overselling routing. The gap analysis in G1 is excellent; just forward-reference it at the point of use.

---

## SHOULD-FIX

### SF-1 — The `/cr` → `/cr-security` auto-route is called "a deterministic glob, no model judgment." That router isn't on disk. (Q4)

Story B.4: *"the cr-security path classifier (a deterministic glob, no model judgment) auto-routes it to
`/cr-security`."* On disk, `/cr-security` exists and its *description* lists the trigger surfaces (auth, RLS, public
endpoints, server actions — `.claude/skills/cr-security/SKILL.md:3-19`), and CLAUDE.md has the human-facing rule
"if any commit touched auth, middleware, or RLS: run `/cr-security`." But there is **no deterministic glob router**
that mechanically fires `/cr → /cr-security` without model judgment. Today it's a *convention* (the human or the
agent decides to run it), not a wired path-glob hook. The doc states an enforcement mechanism that is actually
advisory. **Fix:** either soften to "should route" / "a path-glob router *would* make this deterministic (design
addition)," or flag building the glob router as a small new design item. (This is the same class of error as MF-3 —
narrating a deterministic gate that is currently a convention.)

### SF-2 — Story G's stop-paths are strong, but two of them assume floor pieces that are GATED, not built — and the doc doesn't carry the gate. (Q4)

Story G lists F1/F2/F4/F7/F8/F9 as live stop mechanisms. Per VISION, **F1, F2, F7, F9 are P0-floor (built first)**,
but **F8 (fleet circuit breaker) is "P0 before running fleets at volume"** and **F3/F4 are GATED on Fork F4**
(`VISION.md:110-114`, `:340-342`). Story G presents them as a uniform menu of guards that all fire. The narration is
fine for *what the design intends*, but a teaching deliverable should not imply the circuit breaker and
egress/migration guards are day-0 — they're explicitly sequenced later or fork-gated. **Fix:** add a one-line "built
when" note per stop mechanism (most are P0; F8 is pre-fleet-volume; F3/F4 ride Fork F4). The doc does this well for
LOOP-7 ("GATED, observe-only") and for the dep-update stub ("NEW build, not carry-forward") — apply the same honesty
to the floor pieces in Story G.

### SF-3 — G5 correctly flags the force-continue probe, but five stories silently assume it passes — and the fallback changes their shape. (Q4, Q5)

G5 is one of the best gaps: it names that the built-in continuation loop rests on an *unverified* capability (does a
Stop hook's `decision:block` force-continue, or only error? — `capability-facts.md:13-16` marks it "verify
empirically"). Good. But the *stories themselves* (C, E, F, the auto-approve path, and arguably A's long runs) narrate
uninterrupted long runs as if continuation is solved. The doc says "five of these eight stories silently assume the
probe passes" — which is honest — but then **leaves those five stories written as if it passed.** If the probe fails,
the fallback is "external re-invocation via the L1 front door / cloud `/schedule`," which means the long-run stories
become *re-summon* loops, not *in-process continue* loops — a materially different sequence of events. **Fix:** in the
continuation-dependent stories (at least C and F), add the conditional: "if the Phase-0 probe fails, this becomes a
re-summoned loop, not an in-process one." Otherwise the deliverable teaches a flow that may not be how it actually
runs. (This is a Q5 issue too: "done" for a long run depends on continuation semantics that aren't verified.)

### SF-4 — The early-surface discipline (the charge's "human-decision early-surface") is real for `/debug` but the doc over-claims its reach. (Q1)

Story B's early-surface path is the doc's strongest "human decision surfaced early" moment, and it maps to real
on-disk STOP conditions (modulo MF-1's fabricated money-math). **But** the doc's own G4 correctly notes this
tripwire exists *only* in `@investigator` (the bug flow), not uniformly across the feature/refactor/dep-bump flows —
there, risky decisions surface *later*, as `/cr` `needs-design-decision` findings at review time. That's an honest
gap. The SHOULD-FIX is that the *appendix table* and Story A don't carry this asymmetry: Story A's "HUMAN POINT #3"
(stop on open decision / new package) is **advisory** (the doc itself says "they're advisory until a human drives, so
under full autonomy this leans on the bounded-loop REJECT path"), whereas Story B's early-surface is a *hard agent
STOP condition*. A reader will think both are equally strong. **Fix:** distinguish "hard STOP condition baked into
the agent" (B's investigator) from "advisory stop rule that degrades to F7 REJECT under autonomy" (A's HUMAN POINT
#3). The charge specifically asks whether the early-surface step is concrete or hand-wavy "at the hard steps" — for
the feature flow, it is softer than the doc implies.

### SF-5 — "F5 is the only difference" between label and free-text doors is asserted but not shown. (Q1, Q2)

The doc repeatedly says the *only* difference between a git-host label and a Slack/Linear message is that free text
"passes through one extra safety gate (F5, the injection/trifecta gate) before routing" (A.0, B.0). That's the right
*shape* and matches VISION (`:109-110`, label-trigger doesn't need F5). But it's stated as a finished fact, when in
reality: (a) F5 is P0 *only for the free-text path* and the free-text doors "wait for F5 + F3" before they ship
(`github-usage.md:171-178`) — meaning at first ship, **Slack/Linear are not actually live yet** (label ships first).
So "three ways in, on equal footing" is the *design intent*, but the *ship order* is label-first, Slack/Linear-later.
The doc acknowledges this once ("the only difference the design makes is a safety one") but doesn't carry the
**sequencing** consequence: on day 1, only one of the three doors is open. **Fix:** add "first-class in design;
label ships first, Slack/Linear follow once F5+F3 land" so the deliverable doesn't imply all three doors work on
launch day. (This is consistent with the user's correction #1 — Slack/Linear *must be first-class* — but first-class
in capability ≠ shipped-simultaneously, and the doc should be honest about the gap.)

---

## CONSIDER

### C-1 — Story E (dep bump) leans on a NEW build but narrates it smoothly. (Q4)
The doc correctly flags that `dep-update` was "an empty stub (cut); this is a NEW build." Good honesty. But the rest
of Story E reads as a working flow. Consider a one-line "none of this exists yet" banner so the teaching reader
doesn't mistake it for current behavior. Minor — the disclosure is present, just easy to miss.

### C-2 — The 6 evidence checks / 8-type classification are slightly mis-cited. (Q4)
The doc says `/incident` "runs 6 evidence checks" and "assigns an 8-type classification." On disk the incident skill
has **6 evidence checks** (Check 1–6, with Check 6 = PITFALLS.md — confirmed) but the classification table I sampled
shows the routing types without a clean "8" count visible in the head. The "8-type" number traces to the roster
(`roster.md:47,158`), which is a design doc, not the skill. Low-stakes, but for a teaching deliverable that prides
itself on concrete numbers, verify the "8" against the actual `/incident` classification table before printing it as
fact. (The security-isolation short-circuit IS real and correctly described — `incident/SKILL.md:76`,
`:161` "immediately as security regardless of other evidence.")

### C-3 — Story H (`/explain`) claim "appended to every autonomous PR" is aspirational. (Q3)
H.3 says the teaching brief is "optionally... appended to every autonomous PR." There's no wiring for this today
(`/explain` is a standalone skill). It's flagged "optionally," so it's not dishonest, but it reads like a near-term
feature. Consider marking it a design addition. Trivial.

### C-4 — G8/G9/G10 are excellent and should be promoted, not buried. (Q3)
The charge asks whether "what these flows teach us" surfaces REAL gaps. G3 (paging-surface-into-the-void), G8
(rebase invalidates the F6 sentinel SHA → forces a `/cr` re-run, which no flow accounts for), G9 (no dedup against
in-flight findings → fleet re-opens the same PR nightly), and G10 (human-merge is the *remaining* bottleneck, not
lifted until LOOP-7) are **genuine, non-obvious, design-advancing findings** — exactly what the section is for. This
is the doc's strongest section and answers Q3 affirmatively. The only "consider" is that G8's insight (any rebase
kills the verdict) is arguably a **MUST-FIX-severity design hole** in F6 itself, not just a story gap — it deserves
to be escalated into the floor design, not left as a story-level observation. Worth surfacing to the VISION/F6 owner.

---

## Scorecard against the five charge questions

| # | Charge question | Verdict |
|---|---|---|
| Q1 | Each flow concrete & complete at the hard steps (spec-confirmation, early-surface, failure points)? | **Mostly.** Spec-confirmation is concrete for Medium+ but has the Tiny/Small hole (MF-2). Early-surface is concrete for `/debug` (with a fabricated money-math line, MF-1) but softer-than-claimed for the feature flow (SF-4). Failure points ("Where X can fail") are genuinely concrete and a strength. |
| Q2 | Routes from Slack/Linear first-class, not GitHub-only? | **Yes — done well.** "Three ways in, on equal footing"; git-host-agnostic vocabulary throughout; the only door-difference is the F5 safety gate. Caveat: first-class in *design* ≠ shipped-simultaneously (SF-5); the unbuilt classifier is the real blocker (MF-3). |
| Q3 | "What these flows teach us" surfaces REAL gaps, not restated design? | **Yes — the doc's strongest section.** G1 (classifier), G3 (paging void), G5 (force-continue probe), G8 (rebase kills sentinel), G9 (no dedup), G10 (merge is the remaining ceiling) are real and advance the design. G8 may deserve MUST-FIX escalation into F6 (C-4). |
| Q4 | Any step assuming a capability we don't have (per capability-facts)? | **Yes — three.** MF-1 (investigator money-math STOP — fabricated). MF-3 + SF-1 (front-door classifier and cr-security glob-router narrated as built; neither exists). SF-3 (continuation force-continue assumed, marked "verify empirically" in capability-facts). |
| Q5 | Does the feature flow ensure a SPEC exists before code? | **For Medium+, yes — and it matches the real skill. For Tiny/Small, no** (MF-2). The headline "world-class, not code-first" over-generalizes a Medium+ guarantee. Honest fix: spec-first is a size-gated guarantee; the Tiny path's "spec" is the failing test + TASK-TEMPLATE. |

---

## Verdict: **SOUND-WITH-CORRECTIONS**

The doc gets the three things the user's corrections demanded *right*: Slack/Linear first-class (not GitHub-only),
git-host-agnostic language, and the built-in continuation loop (no reinvented `/goal`). Its failure-mode and gaps
sections are concrete and genuinely advance the design — this is not a doc that restates the pillars. It earns
"SOUND" on structure and intent.

It drops to "WITH-CORRECTIONS" on three honesty failures at the hard steps: one fabricated capability (investigator
money-math, MF-1), one over-generalized guarantee (spec-first is Medium+-only, MF-2), and one trust-laundering
pattern (narrating the unbuilt classifier as working, then disclosing 400 lines later, MF-3). All three are exactly
the "what did we under-build / over-claim" surface the user explicitly asked us to expose. Fix those three, carry the
SF caveats (especially the label-ships-first sequencing and the force-continue conditional), and this is sound
substance for the deliverable.
