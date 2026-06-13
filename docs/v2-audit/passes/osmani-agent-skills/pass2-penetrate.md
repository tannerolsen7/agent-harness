# Pass 2 — Penetrate

Building on pass1: the page is a *curator's verdict object*, not a neutral source — half faithful
facts about addyosmani/agent-skills, half application-claims about us tagged (curator-claim). Pass 1
established the spine ("study the formats, don't install"), the structural critique ("it's all
advisory"), the router rejection, the 6 REJECTs, the 3 borrows, and the 5 named gaps. This pass
finds the deeper thesis under those, the assumptions each rests on, the contradictions inside the
page, and what the curator takes for granted that pass 3 must verify against ground-truth.

---

## The deeper thesis: the page is performing the very test it prescribes

Pass 1 surfaced the closing "standing rule" — adopt (structural capability you lack) / borrow (a
format you can bind to a gate) / reject (prose duplicate of something you enforce). The hidden thesis
is that **this taxonomy is the actual deliverable, and addyosmani/agent-skills is just the worked
example.** The page is not really about Addy's repo; it is a *demonstration of a screening function*
for any external skills library. Pass 1's "23 new skills is 23 things that can drift and zero you can
measure" is the function's loss term: every import is scored as `structural_gain − (context_tax +
drift_surface + maintenance_cost)`, and the page asserts only 3 of 23 have a positive score. The
repo is the test fixture; the screen is the product. **This is the page's most transferable idea and
it is left implicit** — pass 3 should extract the screen as a reusable artifact, not just adjudicate
the 23 verdicts.

## The load-bearing premise the page never defends: "structural beats advisory, always"

Every REJECT in pass 1's table reduces to one move — "ours is structural, theirs is advisory,
therefore importing theirs is a *regression*." This is asserted as a near-axiom ("Pillar 1
regression"). But the page smuggles in an unexamined equivalence: **that a structural gate and an
advisory skill occupy the *same slot*, so adding one displaces the other.** That is false in general.
An advisory in-context checklist and a fresh-context lens agent are not mutually exclusive; you can
run a cheap in-line check *and* the expensive gate. The page's own framing — "adds always-loaded
surface (Pillar 4)" — is the only thing that makes them rivalrous: the cost is *context budget*, not
*correctness*. So the real claim, stripped of the Pillar-1 rhetoric, is narrower and more honest:
**"we already pay for the strong version, so the weak version is pure context tax."** That is a
*budget* argument, not a *capability* argument — and it only holds where the strong version actually
covers the same failure mode. Pass 3 must check coverage per row, because the page asserts it
categorically and the ground-truth map (§3c) shows `/cr`'s own pass structure is contested across
three sources — i.e. "ours is structurally stronger" is not as settled as the table implies.

## The sharpest move in the page: turning the critique on doubt-driven into a self-indictment

Pass 1 recorded the doubt-driven analysis as the page's best section. Penetrating it: the curator
proves that doubt-driven "can flag but never block; judgment never leaves the maker… cross-model
escalation is skipped in every non-interactive context (CI, `/loop`)." Then — without flagging the
move — the page **prescribes importing exactly that mechanism** (borrow #2: cross-model escalation
into `/cr`). The tension is real and unacknowledged: the page demonstrates that cross-model
escalation is *not a gate* (it's model-judgment, skipped when unattended), then recommends adopting
it as the headline epistemics upgrade. The reconciliation it gestures at — "complements the CI
oracle, never replaces it" — is correct but quietly concedes the import's *value is bounded by
wherever a CI oracle already exists.* So borrow #2 is weaker than it reads: it improves review
*only on classes that already have a deterministic check*, and adds nothing on the irreversible
classes (auth/RLS/payments judgment calls) where no oracle exists — which is precisely where the page
says to apply it. **This is the page's most important internal contradiction** and pass 3 must not
inherit the borrow at face value.

## What the curator takes for granted (assumptions to verify in pass 3)

1. **That "ours is structural" is true for each rejected overlap.** Taken as given: `/cr` = "four
   fresh-context lens agents + REJECT + adversarial pass"; `/change` has "a reversibility gate";
   `/cr-security` is "F2 recall-weighted + reversibility hard-stops"; `/tdd` has "ratchets + mutation
   testing"; "Tier-0 worktree isolation is structural." Pass 1 flagged these as (curator-claim). The
   ground-truth map disagrees with several on their face — there is **no `/change` skill on disk**
   (the map's skill inventory §3b lists `/cr, /feature, /tdd, /queue…` but no `/change`); `/cr` has
   **no REJECT tier** per the map (§3c: "No REJECT tier, no UNATTENDED branching"); the map calls the
   whole system "overwhelmingly advisory… neither has a deterministic backstop" (§3e). So the page's
   REJECT rationale rests on a harness that is *more built than disk actually is.* It is describing
   the **target/canon**, not the running disk.

2. **That `learned-patterns.md` and Nodes 13.1 / 2.1 / 17 / 12 exist as referents.** The page binds
   its #1 borrow to "the Node 13.1 entry template" for `learned-patterns.md`. The ground-truth map is
   explicit (§6): `learned-patterns.md` is a **phantom** — "referenced on disk, never built on disk
   *or* in canon." So the page's lowest-cost/highest-leverage borrow targets a file that does not
   exist. That doesn't kill the borrow; it relocates it from "restructure an existing template" to
   "decide whether to build the store at all, and if so, in this format." Pass 3 must demote the
   borrow's framing.

3. **That the Pillars (1/3/4/5) and R1/R2 are stable, shared vocabulary.** The page leans hard on
   "Pillar 1 regression," "Pillar 4 context tax," "Pillar 5 subtractive," "R1 unattended," "R2
   unmeasured verifier." None of these appear in the ground-truth map's vocabulary (the map organizes
   by canon/disk/global and §3–§9). They come from a *different* layer — the Layer-5 synthesis inputs
   (`project_layer5_inputs.md`, cited in the page's own sources line). So the page is written against
   the **synthesis/decision layer**, while the ground-truth map is the **as-is inventory layer.** Pass
   3's job is the join: translate the page's Pillar/Node claims into map rows, and where a Pillar claim
   has no map row, treat it as *unverified against disk.*

4. **That portability is irrelevant to us.** The router rejection turns entirely on "Claude-Code-only
   harness." This is the one assumption the ground-truth map *contradicts as a goal*: the map's
   headline (§0, §8) is that V2's whole binding principle is **global, GitHub-hosted, multi-project,
   installable** — "the harness has never been installed anywhere but event-vendor; 'multi-project' is
   a goal, not a state." If V2 succeeds, the harness travels to recyclops and beyond — and the
   cross-harness portability the page dismisses ("Cursor/Gemini/Copilot") becomes live the moment the
   harness is meant to be *shared*. The page's router rejection is sound *for a single-project
   Claude-Code harness* and silently assumes that's the permanent shape. Pass 3 should mark this as a
   scope-dependent verdict, not a settled one.

## A contradiction the page contains but doesn't notice: "format" vs "the model already knows this"

Pass 1 recorded: most skills are "repackaged senior-engineer canon given memorable names… the value
is curation and forced application, not novelty." The page treats this as a *demerit* (inflated
surface area). But its own #1 borrow — the anti-rationalization table format — is *also* repackaged
canon (a checklist), credited as "lowest-cost, highest-leverage." The discriminator the page uses
without stating it: **canon is worthless as prose the model already knows, but valuable as a
machine-greppable shape that survives in a file.** That is the actual selection criterion hiding under
"format vs install" — and it aligns precisely with this project's own memory rule
(`feedback_skill_file_design`: "skill files hinder when they prescribe what the model already knows;
earn their place only for plan-file systems, naming gates"). The page rediscovers our own doctrine
without citing it. Net-new framing for pass 3: **the borrow test isn't "format vs skill," it's "does
this shape get enforced by something other than the model's goodwill?"** The anti-rationalization
table only earns its keep if `/cr` (or a hook) actually *greps it*; as inert prose it is exactly the
advisory downgrade the page warns against. The page recommends the format without specifying the
enforcement that would make it non-advisory — a gap pass 3 must close.

## The unargued asymmetry: it audits Addy's enforcement but not ours

The page's central proof is "frontmatter is only name+description → advisory → doesn't transfer." It
holds Addy's repo to the standard "is this *enforced* or honor-system?" It never turns that same lens
on our own skills. The ground-truth map does, and the answer is uncomfortable (§3e): our system is
"overwhelmingly advisory," missing the canon's 3rd bash guard, scope guard, branch-registry guard,
and session-end memory hook; our live pre-commit is "a 67-byte husky shim" that lacks the canon's
main-branch agent block. So the page's clean dichotomy — *their advisory vs our structural* — is, on
disk, **advisory vs mostly-advisory-with-a-few-real-gates.** The page's rhetorical force depends on a
contrast that the ground-truth map weakens. Pass 3's most honest finding will be: several REJECTs are
correct *in the direction* of their reasoning but overstate how structural we actually are.

## Net-new analysis introduced this pass (not in pass 1)

- **The deliverable is the adopt/borrow/reject *screen*, not the 23 verdicts.** Extract it as a
  reusable artifact (a `/cr`-able or AGENTS.md-level rule for vetting any external skills lib).
- **"Structural beats advisory" is a budget argument disguised as a capability argument.** It only
  holds where our strong version actually covers the same failure mode — verify coverage per row.
- **Borrow #2 (cross-model escalation) is internally contradicted by the page itself** — it's
  bounded to classes that already have an oracle, and the page recommends it precisely where no oracle
  exists. Demote.
- **Borrow #1 targets a phantom (`learned-patterns.md`)** and is only non-advisory if something
  *greps* the table. The page omits the enforcement half.
- **The router rejection assumes permanent single-project Claude-Code scope** — which V2's stated goal
  contradicts. Scope-dependent, not settled.
- **The page's structural/advisory contrast over-credits our disk.** Our enforcement floor is thinner
  than the page assumes; some REJECTs lean on canon, not on what runs.

## Deeper one-line thesis

The page's real product is a *screening function* for external skill libraries — adopt/borrow/reject
scored as structural-gain minus context-tax-plus-drift — but it applies that screen against an
idealized (canon-level) picture of our own harness, so its categorical REJECTs and its two
file-bound borrows must be re-scored against what actually runs on disk before any of them ship.
