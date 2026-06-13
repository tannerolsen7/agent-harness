# Deep Dive — Test Verification: "How do we know the tests are real?"

> **The plain-English question we are answering (from Tanner):** "It is easy to write green
> tests even using `/tdd`. How are the tests *verified*?"
>
> **Source substance for the main author.** Written in simple language, kept rigorous. Cites the
> design (VISION.md moves) and the re-mines. Flags clearly what is ALREADY in the design vs. what
> is a NEW addition this deep dive is proposing.

---

## 0. Start with the honest admission

Tanner is right, and the worry is not paranoia — it is a known, named failure mode. A test that
**passes (turns green)** can be completely worthless. Here are the three ways a green test lies, in
plain words:

1. **It tests nothing.** The test runs the code but never *asserts* anything — no "the answer should
   be X." It exercises the function, sees no crash, and reports green. It would stay green even if
   the function returned garbage.

2. **It tests a tautology.** The test asserts something that is true by definition and could never
   fail. The classic shape is `expect(x).toBe(x)`, or asserting a constant equals the same constant.
   Green forever, proves nothing.

3. **It tests what the code *happens to do*, not what the code *should do* (the transcription
   trap).** Someone (a human or, far more likely now, an agent) read the implementation, saw it
   returns `42`, and wrote `expect(result).toBe(42)`. If `42` is the *wrong* answer — the
   implementation has a bug — the test happily confirms the bug. The test is a *mirror* of the
   code, not an independent *oracle* of correct behavior. (An "oracle" is just the thing that knows
   the right answer. A good test gets the right answer from an external source; a bad test copies it
   off the code it is supposed to be checking.)

`/tdd` already fights #3 hard (see §2 below) — but `/tdd` is a skill the model **chooses** to
invoke and **chooses** to follow honestly. It is *advisory*. Nothing today *forces* the test to be
real, *proves* it would catch a bug, or *measures* whether our review actually catches a vacuous
test. The whole point of the V2 charter is: **the moment a human is no longer watching every run, an
advisory rule is a suggestion, and the only real control is something the model cannot skip or
fake.** Test quality is exactly such a place.

So this deep dive answers: **what is the layered defense that makes "green" actually mean
"correct," and which layers are already designed vs. new?** There are seven layers. Four exist in
the design. Two are NEW (mutation testing + a test-quality review lens). One is a strengthening of
something already present (red-before-green made un-skippable).

A one-line map before the detail:

| # | Layer | Catches which lie | Status |
|---|---|---|---|
| 1 | No-transcription rule | #3 (mirror of code) | **In design** (C12) |
| 2 | Spec-as-oracle (executable Verification) | #3 (wrong expected value) | **In design** (C6) |
| 3 | Red-before-green proof | #1 (no assertion) and reproduction | **In design (C12) — STRENGTHEN to un-skippable** |
| 4 | Mutation testing | #1 and #2 (test that can't fail) | **NEW addition** |
| 5 | Property-based testing | #1/#3 on money math invariants | **In design** (C11) |
| 6 | Test-quality review lens | all three, by reading the test | **NEW addition** |
| 7 | Calibration with vacuous-test diffs | proves layer 6 actually works | **In design (C4) — EXTEND the golden set** |

---

## 1. Why "/tdd writes green tests" is not enough — the precise gap

`/tdd` (the on-disk skill, `.claude/skills/tdd/SKILL.md`) is genuinely good discipline. Its loop is
**Specify → Encode → Fulfill**, one behavior = one test = one commit, and it carries the strongest
single anti-cheat rule we have (the no-transcription rule, §2). But notice exactly what `/tdd`
guarantees and what it does not:

- **It guarantees:** a test exists, it was written before the code, and the skill *tells* the agent
  to draw the expected value from the spec, not the code.
- **It does NOT guarantee:** that the agent actually obeyed. An agent under pressure to "make it
  green" can quietly peek at the implementation, write the matching expected value, and produce a
  perfectly green, perfectly worthless test — while the transcript reads like it followed the loop.
  Nothing downstream re-checks this.

This is the same disease the re-mine `recursive-self-improvement.md` calls **authority laundering**:
*every quality gate in an automated loop degenerates into a measure of the model's self-agreement
unless its terminal authority is anchored to something the model cannot redefine.* When the model
writes the code AND the test AND grades both, "green" just means "the model agreed with itself." The
re-mine's sharpest line (paraphrased): *"when the loop writes both the implementation and its
example tests, the human-specified invariant is the only check the loop cannot quietly weaken."*

So verification of tests is not one trick. It is a stack of independent checks, each closing a
different hole, arranged so that **no single layer is the only thing standing between a vacuous test
and main.**

---

## 2. Layer 1 — The no-transcription rule (already in design: C12)

**What it is, in one sentence:** the expected value in a test must come from the **spec or the
user**, *never* from reading the implementation.

This is the single most load-bearing rule against lie #3 and it already exists, verbatim, on disk.
From `tdd/SKILL.md` Step 0:

> **No transcription tests.** Expected behavior comes from `docs/TESTING.md` or from the user — never
> from reading the implementation. Reading the code to derive expected values produces tests that
> pass even when behavior is wrong.

And its anti-rationalization row nails the failure: *"A test written after implementation is a
transcription, not a spec."* C12 in VISION.md carries this forward as **P0 do-not-drop**, wired to
`docs/TESTING.md` as the behavior ledger: the behavior is read from TESTING.md in Step 1 *before*
any test, and written back in Step 6.

**Concrete example of the rule biting.** Suppose the pricing function should add a 10% service fee
but the implementation forgot it and returns the bare subtotal of `$1000`.
- *Transcription test (banned):* dev reads the code, sees `1000`, writes `expect(total).toBe(1000)`.
  Green. Bug shipped.
- *Spec-derived test (required):* `docs/TESTING.md` says "total = subtotal + 10% service fee," so
  the test asserts `expect(total).toBe(1100)`. **Red.** Bug caught before any code is trusted.

**The honest gap: can a hook or lens *detect* transcription?** This is the hard part Tanner is
really pointing at — the rule is currently **advisory**. A deterministic hook *cannot* read an
agent's mind to know whether it peeked at the implementation. But we are not helpless; there are
three partial detectors, in increasing strength:

1. **Ordering evidence (deterministic, weak-but-real).** A test is far more trustworthy when the
   commit history proves the *test file was committed in a state that fails against the absent/old
   implementation* before the implementation commit. This is Layer 3 (red-before-green) and it is
   the strongest *deterministic* proxy we have for "this was not transcribed." A test that first
   appears in the *same* commit as the code it tests is the highest-risk shape — it could have been
   written by reading that very code.

2. **Spec traceability (deterministic-ish).** Every behavioral assertion should trace to a line in
   `docs/TESTING.md` or a feature spec's Verification section (Layer 2). If a test asserts a value
   that appears *nowhere* in the spec, that is a detectable smell: where did that number come from,
   if not the code? A lens (Layer 6) can flag "assertion value has no spec source."

3. **Mutation testing (deterministic, strong — the new weapon).** This is the real answer to "prove
   it isn't a transcription that only mirrors the code." If you deliberately break the code and the
   test *still passes*, the test was provably not anchored to correct behavior — it was anchored to
   *whatever the code does*. See Layer 4. Mutation testing is the closest thing to an
   automatic transcription-detector we can actually build.

**Substance to carry:** keep C12 verbatim, and state plainly that the no-transcription rule is
*reinforced from three sides* (red-before-green ordering, spec traceability, mutation testing) rather
than trusted as honor-system prose. That reinforcement is the answer to "how is it enforced?"

---

## 3. Layer 2 — The spec is the oracle (already in design: C6)

**What it is:** a per-feature spec, `docs/specs/<feature>.md`, with three sections — **Behavior**
(what it does), **Implementation pointers** (where it lives), and an **executable Verification
section** (runnable steps that prove it still works). The spec — not the code — is the source of
truth the test must match. This is C6, elevated by the re-mine `notion-spec-driven.md`.

**Why this is the core of test verification, not a side feature.** A test is only as good as the
oracle it checks against. If the oracle is "what the code does," every test is a transcription by
construction. C6 gives the test an oracle that is *independent of the implementation and written by a
human (or reviewed by an independent agent)*. The re-mine's governing law: *"an agent's autonomy is
bounded by the quality of the verification surface you can hand it — and that surface must be a built
artifact, not a written intention."* A prose "Verification: it should work correctly" closes no loop;
a runnable assertion does.

**The Notion (Afterburner team) model this comes from, in plain words:** they hand a coding agent a
permanent, version-controlled spec whose last section is *runnable* — a list of CLI invocations /
scripted checks the agent executes to certify its own work *with no human in the loop*. The failure
they designed against is exactly ours: *"an autonomy gate that certifies process ran ('review
happened') rather than that the feature behaves as specified."*

**How a test "traces to a spec line."** This is the concrete mechanism the main author should
describe:
- Each behavior in the spec's Verification section gets a stable id (e.g. `VER-3`: "rejection notes
  capped at 2,000 chars → `notes_too_long`"). Our `docs/TESTING.md` already reads like this — e.g.
  *"Rejection notes are capped at 2,000 characters after trimming. Longer input raises
  `notes_too_long`."* That sentence IS the oracle; the test asserts exactly it.
- The test references the id (a comment `// VER-3` or a `describe('VER-3 ...')`).
- A lens / CI check can then ask two cheap questions: **(a)** does every Verification line have at
  least one test referencing it? (coverage of the spec) and **(b)** does every behavioral assertion
  trace to a Verification line? (no orphan assertions invented from the code).

**Status nuance (important, from VISION C7 / F6):** the spec's Verification section *passing* is what
the autonomy gate should check — **not** the `.cr-ok` process token. VISION demotes C7 to "a
configuration of F6 + C6": the unforgeable gate (F6) re-runs the deterministic checks on the shipped
SHA, and for a feature with a spec it *also* requires the spec's Verification to pass. The
`.cr-ok` sentinel survives only as a *readiness signal*, never as proof of correctness. (See the
F6 deep dive; here the point is: **the spec, executed, is the oracle the test answers to, and CI —
not the model — is what confirms the oracle passed.**)

**One design caveat carried from the re-mine:** spec-first has *no built-in adversary* — if the same
agent writes the spec, the test, and the code, you are back to self-agreement. So C6 must ship with
**an independent review pass on the spec itself** (a fresh agent, or the human, checks that the
Verification section describes *correct* behavior). Do NOT copy Notion's implementer-self-verifies
shortcut.

---

## 4. Layer 3 — Red-before-green proof (in design: C12 — STRENGTHEN to un-skippable)

**What it is:** the test MUST be shown to fail (red) *before* the code that makes it pass exists.
This is the single cheapest, strongest proof that a test can actually fail — which is the minimum bar
for "this test could catch a bug." A test never observed failing is a test that might be incapable of
failing (lie #1: no real assertion).

**Already in the loop:** `tdd/SKILL.md` Step 4 is explicit — *"Write the test for this ONE slice (it
should fail — red); Run `npx vitest run <test-file>` — confirm it fails **for the right reason**."*
That last phrase matters: red because the assertion is unmet (correct), not red because of a typo or
a missing import (a false red that proves nothing). For a bug fix, red-before-green doubles as the
*reproduction proof*: the failing test reproduces the bug, so green proves the fix. The re-mine
`engineering-rigour-small-team.md` makes this its #1 move: *"failing-test-first ... forces the agent
to fix the right problem."*

**The gap Tanner is pointing at: today this is honor-system.** The implementer *says* it ran red,
but nothing records or enforces it. An agent can write test + code together, run once (green), and
truthfully report "tests pass" while never having seen red. So the STRENGTHENING this deep dive
proposes (and which `engineering-rigour-small-team.md` elevates to a deterministic gate):

**Make red-before-green un-skippable and recorded.** Two concrete, git-host-agnostic mechanisms:

1. **A recorded red transcript per slice.** When a fix/feature is scoped, require that the loop
   capture and attach evidence that the new/changed test ran **red** against the pre-fix code, then
   **green** after. The shared Stop/PostToolUse hook surface (HOOK-1 in VISION) is the natural home:
   it already runs `npm run test` at task completion; extend its payload to record, per new test, a
   red-then-green observation. Honest limit from `capability-facts.md`: a hook can *run tests and
   block on red*, but it *cannot compel an artifact to exist* — so the red-transcript is
   **verify-if-present at the hook, hard at CI** (same pattern as C10/C8). The CI leg is what makes
   it real.

2. **A `bugfix-test-guard` (deterministic, from `engineering-rigour-small-team.md`).** When the
   commit/branch type is `fix`, a pre-push / CI check **refuses the sentinel unless the diff contains
   a new or modified test file.** Plain reasoning: a bug fix with zero test delta either didn't
   reproduce the bug or didn't lock the fix — both are regressions waiting to happen. The re-mine's
   exact framing: *"a gate keyed off the diff is the difference between 'rigour' and 'a comment the
   agent didn't read.'"* This is currently *advisory prose* in CLAUDE.md (TDD mandatory only for pure
   functions); the world-class form is a **gate in the floor** covering the expensive surfaces too
   (server actions, the `/p/[token]` renderer, `src/data/` RLS-adjacent edits).

> **NEW design item flagged:** the **recorded red-before-green evidence** (a red-then-green
> observation captured by HOOK-1, hard-verified at CI) and the **`bugfix-test-guard`** are not yet
> first-class moves in the floor. `engineering-rigour-small-team.md` proposes the guard;
> `capability-facts.md` constrains where it can live. The main author should call these out as the
> mechanism that turns red-before-green from honor-system into enforced.

**Honesty about the limit:** red-before-green proves a test *can* fail and *did* fail for the right
reason at one moment. It does NOT prove the test still meaningfully constrains the code after
refactors, or that it covers the *right* behavior. That is why Layers 4–6 exist.

---

## 5. Layer 4 — Mutation testing (NEW addition — the real candidate)

This is the layer that most directly answers "how do you *verify the test verifies*?" — and it is
**not yet in the design** (the ROUND-2 corrections ledger explicitly lists "MUTATION TESTING [new]"
for this deep dive). Treat it as a genuine new proposal, assessed honestly below.

### 5.1 What mutation testing is, in plain words

You deliberately **break the code** in a tiny, mechanical way — flip a `>` to `>=`, change `+` to
`-`, replace a constant `10` with `0`, delete a line, negate a boolean. Each broken version is a
**"mutant."** Then you run the test suite against the mutant.

- If a test **goes red**, the mutant is **"killed"** — good, your tests noticed the bug you injected.
- If every test **stays green**, the mutant **"survives"** — and that is a *proof* that your tests
  would not catch that real bug. **A surviving mutant is a worthless test, demonstrated, not
  guessed.**

Your **mutation score** = killed mutants / total mutants. It is the first metric we have that
measures *the quality of the tests themselves*, not the quantity of them or the coverage of lines.

**Why this is exactly Tanner's question answered.** Line coverage says "this line ran during a
test." It says nothing about whether a test would *notice if that line were wrong*. A vacuous test
(no assertion) gets 100% line coverage and a near-0% mutation score — it runs every line and kills no
mutants. Mutation testing is the only automated technique that distinguishes "ran the code" from
"would catch a bug in the code." It is, effectively, the **automatic transcription-and-tautology
detector** the no-transcription rule needed.

**Worked example.** Pricing: `total = subtotal + serviceFee`. Mutant: change `+` to `-`. If your
test only checks `expect(total).toBeGreaterThan(0)`, the mutant (`subtotal - serviceFee`, still
positive) **survives** — proving that assertion is too weak. If your test checks the exact
`expect(total).toBe(1100)`, the mutant produces `900` and the test **kills** it. Mutation testing
turns "is my assertion strong enough?" from a judgment call into a measured fact.

### 5.2 Which tool, and the cost (honest)

- **Tool:** **StrykerJS** (`@stryker-mutator/core`) is the standard, actively maintained mutation
  testing framework for the JS/TS ecosystem and has a **Vitest runner**
  (`@stryker-mutator/vitest-runner`) — which matters because our suite is Vitest 4. It ships its own
  types. (Per the ask-before-installing rule, the main author should surface name / purpose /
  weekly-downloads / last-publish / ships-types to Tanner before any install — same gate as
  `fast-check` for C11, see Fork F6.)
- **The real cost — be honest about it.** Mutation testing is **slow and expensive**. It re-runs the
  test suite once *per mutant*, and a module can generate hundreds of mutants. For our suite, where
  integration tests **hit a real Supabase instance** (we never mock the DB — CLAUDE.md), running
  mutants against integration tests would be brutally slow and would hammer the database. This is the
  decisive constraint and it dictates *where* mutation testing can live.

### 5.3 Where it runs (the proportionate answer)

The honest, proportionate design — **do not** run mutation testing on the whole suite or in the
fast pre-commit/pre-push path:

- **Scope it to pure functions, money math first.** Mutation testing shines on *deterministic pure
  functions* with no DB — exactly `src/utils/` pricing/total logic and `src/schemas/`. These run in
  milliseconds, so hundreds of mutants are cheap. This is also where a silent bug is most expensive
  (a wrong `$30k` total). Start with the **pricing module only**, the same module C11 targets.
- **Run it in CI on a schedule, not on every push.** A nightly / cloud-`/schedule` job (VISION L4
  substrate) runs Stryker against the pricing + schema modules and reports the mutation score. A
  **score floor** (e.g. fail/open-an-issue if pricing mutation score drops below a stated threshold)
  becomes a standing quality gate. This mirrors C4's calibration cadence ("a CI concern, not a
  one-time act") and the eval-in-CI doctrine from `when-is-llm-call-worth-it.md`: *"a probabilistic
  system degrades silently ... build the evals before the features."*
- **Pair it with C11 (PBT) and C4 (calibration), not in place of them.** PBT supplies strong
  invariants; mutation testing *proves those invariants are actually being checked by the tests*. A
  property test that is mis-wired and never really exercises the invariant will show up as surviving
  mutants. They are complementary: PBT widens the inputs; mutation testing widens the *injected
  bugs*.

### 5.4 Honest verdict on adoption

**Adopt it — narrowly.** It is the single most direct mechanical answer to "are these tests real?"
and the cost is fully controllable by scoping it to pure money-math/schema modules and running it on
a schedule. **Do not** make it a blocking pre-push gate (too slow) and **do not** run it against
integration/DB tests (too slow + hits prod-shaped data). Gate the dependency install behind the
same ask-first fork as `fast-check`. Sequence it in **Phase 4** alongside C11 (money-math PBT) — it
is the verification *of* the PBT layer.

> **NEW design item flagged:** mutation testing (StrykerJS + Vitest runner) on the pricing/schema
> pure-function modules, run as a scheduled CI job with a mutation-score floor. Not in VISION's move
> roster today; belongs next to C11 in Phase 4, gated on a dependency-approval fork.

---

## 6. Layer 5 — Property-based testing for invariants (already in design: C11)

**What it is:** instead of checking a handful of examples a developer/agent happened to think of, you
assert an **invariant** — a rule that must hold for *all* inputs — and the framework generates
hundreds of adversarial inputs trying to break it. C11 in VISION, elevated by
`recursive-self-improvement.md`, targets money math with `fast-check` (gated on Fork F6).

**Why it belongs in the test-verification stack specifically.** A property is, in the re-mine's
words, *"something the model can't argue with ... a human-authored, model-immutable specification of
correctness."* That is the precise antidote to the self-agreement problem: when the loop writes both
the pricing code and its example tests, the human-authored invariant is *the only check the loop
cannot quietly weaken.* It is also a defense against lie #3 at scale — the agent cannot transcribe
its way around `total = sum(line items) for ALL inputs`, because it does not get to pick the inputs.

**The concrete invariant set for our product (from C11):**
- `total = sum(line items)`
- tax is never applied to service fees
- no negative line totals; discounts never produce negative subtotals
- integer-cents round-tripping is exact

**Enforcement:** a PITFALLS rule + a coverage-style blocker — *any change to pricing/total logic
requires a property test* — on the pricing module. (This is the same "expensive surface gets a real
gate" pattern as the bugfix-test-guard.)

**The interlock the main author should state plainly:** Layers 4 and 5 are a pair. PBT writes the
human-immutable invariant; mutation testing *proves the test for that invariant can actually fail*.
Neither alone is sufficient — a beautifully-stated property that is wired up wrong (so it never
really asserts) will pass forever, and *only* mutation testing catches that.

---

## 7. Layer 6 — A test-quality review lens (NEW addition)

**What it is:** a first-class `/cr` review lens whose entire job is to read the *tests in the diff*
and ask the questions a tired human stops asking: **"Would this test catch a real bug? Does it
assert on behavior, or does it just run the code? Are there assertions at all? Does the expected
value trace to a spec line, or did it come from the implementation?"** Test-quality becomes a review
dimension on equal footing with security or correctness.

**Why this is new and why it is needed.** VISION's review stack (C2 adversarial independence, C5
governance lens, C4 calibration) is deep — but **none of the existing lenses owns "is this test
real?"** as their stay-in-lane charge. The lenses attack correctness, RLS/tenant rules, locked-ADR
violations, etc. A diff can pass all of them while shipping a vacuous test, because no lens is
*pointed at the test file as the thing under suspicion.* The ROUND-2 corrections ledger explicitly
lists "a test-quality review lens" as a new item for this deep dive.

**What the lens checks (concrete battery):**
1. **Assertion presence.** Flag any test body with no assertion, or whose only assertion is
   "did not throw." (catches lie #1)
2. **Tautology smell.** Flag `expect(x).toBe(x)`, asserting a value against itself, or asserting a
   constant against the same literal. (catches lie #2)
3. **Spec traceability.** Every behavioral assertion should reference / match a `docs/TESTING.md` or
   spec Verification line. An assertion value that appears nowhere in the spec is a transcription
   suspect — *where did this number come from if not the code?* (catches lie #3)
4. **Behavior vs. implementation coupling.** Flag tests that assert on internal/private details
   (call counts on internal helpers, exact intermediate values) rather than observable behavior —
   these are brittle *and* often transcription artifacts.
5. **Red-before-green evidence.** For changed behavior, was there a recorded red? (ties to Layer 3)
6. **Bug-fix test delta.** For a `fix`, is there a new/changed test at all? (ties to the
   bugfix-test-guard, Layer 3)

**How it stays trustworthy (reuses existing design):** it runs under C2's adversarial-independence
contract — a *fresh* sub-agent with **isolated solution context** (it never saw the coding session's
rationalizations) but **full project canon** (CLAUDE.md, PITFALLS, `docs/TESTING.md`, the spec). Its
framing is inverted: *"find the test that would not catch a bug."* And — critically — it must run on
**Opus 4.8, not the cheapest model** (VISION C13: the catch-the-error agents are exactly the ones
that should not run on the weakest model).

**Honest limit:** a review lens is a *probabilistic* check — it can miss. That is precisely why it
must be **calibrated** (Layer 7) and why it sits *above* the deterministic Layers 3–5, not instead of
them. The lens is the broad net; mutation testing is the hard proof on the money-critical core.

> **NEW design item flagged:** a dedicated **test-quality lens** in `/cr` (assertion-presence,
> tautology, spec-traceability, behavior-coupling, red-evidence, bugfix-delta), running under C2
> isolation on Opus 4.8. Not in VISION's lens roster today; should be added as a peer to C2/C5 and
> seeded into C4's calibration.

---

## 8. Layer 7 — Tie it to calibration (in design: C4 — EXTEND the golden set)

A review lens that is never measured is just a hope. C4 in VISION already builds the machinery:
a `golden-set/` corpus of labeled diffs + a `/cr-calibrate` CI job that measures **recall** (what
fraction of seeded defects `/cr` catches) and **false-positive rate**, re-run on every change to the
passes / the merge rule / the model.

**The EXTENSION this deep dive asks for:** seed the golden set with diffs whose **tests are
vacuous** — not just diffs with code bugs. Concretely, add labeled examples of:
- a test with no assertion (just runs the function),
- a tautology test (`expect(x).toBe(x)`),
- a transcription test (expected value lifted from a buggy implementation, so green confirms a bug),
- a bug fix with **no** test delta,
- a strong-looking property test that is mis-wired so it never actually exercises the invariant.

Then **measure whether the test-quality lens (Layer 6) catches them.** This is the only way to know
the lens works rather than merely exists. The re-mine `recursive-self-improvement.md` makes
adversarial seeding a *hard construction rule*, not a nice-to-have: *"a friendly-only corpus produces
a recall number that is optimistic by construction and therefore a calibration that is itself
authority-laundered."* In plain words: if your golden set only contains *real* bugs and never
*fake-test* tricks, you will never find out your reviewer is blind to fake tests.

This closes the loop end to end: **the lens checks the tests; calibration checks the lens; and the
golden set deliberately includes the exact vacuous-test shapes Tanner is worried about, so we have a
*number* for "how often do we catch a worthless test."**

> **EXTENSION flagged:** C4's golden set must include a **vacuous-test sub-corpus** (no-assertion,
> tautology, transcription, missing-bugfix-test, mis-wired-property), and `/cr-calibrate` must report
> the test-quality lens's recall against it. This is an addition to C4's seeding spec, not a new
> move.

---

## 9. How the layers compose (the defense in depth, in one picture)

Read top to bottom as a single diff travels from "agent wrote a test" to "merged":

1. **No-transcription rule (C12)** — at write time, expected value must come from the spec, not the
   code. *Advisory, but reinforced by 2, 3, 4.*
2. **Spec-as-oracle (C6)** — the test must match a runnable Verification line in
   `docs/specs/<feature>.md`; the spec passes in CI, not by model claim. *Gives the test an
   independent oracle.*
3. **Red-before-green (C12, strengthened)** — the test is proven to fail before the code exists;
   recorded by HOOK-1, hard-verified at CI; `bugfix-test-guard` refuses a fix with no test delta.
   *Proves the test can fail.*
4. **Test-quality lens (NEW)** — a fresh-context adversarial pass reads the test and flags
   no-assertion / tautology / transcription / brittle-coupling. *Broad probabilistic net for "would
   this catch a bug?"*
5. **Mutation testing (NEW)** — on the pricing/schema pure modules, deliberately break the code and
   confirm a test goes red; a surviving mutant is a *proof* of a worthless test; scheduled CI with a
   score floor. *Hard mechanical proof on the money-critical core.*
6. **Property-based testing (C11)** — human-authored invariants the loop cannot weaken, generating
   hundreds of adversarial inputs on money math. *Model-immutable correctness anchor.*
7. **Calibration (C4, extended)** — the golden set includes vacuous-test diffs; `/cr-calibrate`
   measures whether Layer 4 actually catches them, re-run on every model/pass change. *Proves the
   net works.*
8. **Unforgeable gate (F6, the keystone — its own deep dive)** — none of the above ships on the
   model's say-so; CI re-runs the deterministic checks on the exact shipped SHA, and the verdict is
   posted to the PR/MR. *The model never grades its own homework.*

The teachable cut for the main author: **C12/C6 give the test an honest oracle; red-before-green +
mutation testing prove the test can actually fail; the lens + calibration measure whether we catch
the fakes; PBT pins the money math the model can't weaken; and F6 makes sure none of it is the
model's self-report.** No single layer is trusted alone — that is the whole design.

---

## 10. Git-host-agnostic / trigger-agnostic notes (per the corrections)

So the main author keeps these neutral:

- Everything CI-resident here — the mutation-testing job, `/cr-calibrate`, the spec-Verification
  check, the red-evidence and `bugfix-test-guard` checks — is a **CI pipeline** job on a **protected
  branch**, expressed generically. It works the same on a GitHub Action or a GitLab CI pipeline; say
  "your git host" and "CI pipeline," not "GitHub Actions."
- The verdict surface (F6) is "posted to the PR/MR" — pull request *or* merge request.
- A bug or feature can be **kicked off from Slack or Linear** (first-class, equal to a repo label) —
  and the *test-verification stack runs identically* regardless of how the work was summoned, because
  it lives in CI on the shipped SHA, downstream of the trigger. The trigger chooses *who starts the
  work*; the test-verification layers decide *whether the work is allowed to merge*. They are
  independent by design.
- The continuation loop that drives a fix to a reviewed PR/MR is the **built-in continuation loop**
  (run-until-a-stopping-condition), whose stopping condition bottoms out on these deterministic
  verifiers (mutation-score floor met, CI green on SHA, spec Verification passing) — not on a prose
  "looks done." We use the built-in primitive; we do not invent a new skill for it.

---

## 11. The simple checklist — "How we know a test is real"

A test earns trust only if it can answer **yes** to these. The first three are the floor every test
must clear; 4–7 are the deeper proofs that scale with how expensive a bug would be.

1. **Does it assert something?** Not just "runs without crashing." There is at least one real
   expectation about behavior. *(catches: tests-nothing)*
2. **Could it ever fail?** It is not a tautology (`x === x`, constant vs. same constant). *(catches:
   tautology)*
3. **Did the expected value come from the spec or the user — not from reading the code?** It traces
   to a `docs/TESTING.md` / spec Verification line, not to whatever the implementation returns.
   *(catches: transcription)*
4. **Was it seen failing before the code existed?** Red-before-green, recorded — and for a bug fix,
   the red test *reproduced the bug*. A fix with no test delta fails this. *(proves: it can fail)*
5. **If we deliberately break the code, does this test go red?** (mutation testing — required on the
   pricing/schema core; a surviving mutant means the test is worthless, proven). *(proves: it catches
   real bugs)*
6. **For money/total/invariant logic: is there a property the model cannot weaken?** A human-authored
   invariant checked across hundreds of generated inputs. *(proves: the critical math is pinned)*
7. **Did an independent reviewer (test-quality lens) and our calibration confirm we'd catch a fake
   one?** The lens read the test from isolated context; the golden set includes vacuous-test diffs;
   `/cr-calibrate` reports we catch them. *(proves: our net itself works)*

If a test cannot answer 1–4, it is not a real test. If money math cannot answer 5–6, it is not
trusted. If we cannot answer 7, we do not actually know how good our review is — we are guessing,
which is the exact state Tanner's question exists to end.

---

## Appendix — Status ledger (already-in-design vs. NEW)

| Layer / item | VISION move | Status | Note |
|---|---|---|---|
| No-transcription rule | C12 | **In design — keep verbatim** | Advisory; reinforced by red-before-green + spec-trace + mutation |
| `docs/TESTING.md` behavior ledger | C12 | **In design** | Read in Step 1, written Step 6 |
| Per-feature spec + executable Verification (the oracle) | C6 | **In design** | Spec passes in CI; ships with independent spec review |
| Spec-Verification gate (not `.cr-ok`) | C7 → config of F6+C6 | **In design** | `.cr-ok` is readiness only |
| Red-before-green proof | C12 | **In design — STRENGTHEN** | Make recorded + CI-hard; **NEW:** red-evidence payload on HOOK-1 |
| `bugfix-test-guard` (fix → must have test delta) | from `engineering-rigour-small-team.md` | **NEW (not in roster)** | Deterministic floor gate on expensive surfaces |
| Mutation testing (StrykerJS + Vitest runner) | — | **NEW** | Pricing/schema pure modules, scheduled CI, score floor; pairs with C11; dep gated like F6 |
| Property-based testing (money math) | C11 | **In design** | `fast-check`, Fork F6; invariant set defined |
| Test-quality review lens | — | **NEW** | Peer to C2/C5; runs under C2 isolation, Opus 4.8; seeded into C4 |
| Reviewer calibration (golden set, recall) | C4 | **In design — EXTEND** | Add vacuous-test sub-corpus; measure lens recall |
| Unforgeable CI verdict on shipped SHA | F6 | **In design (keystone)** | The model never grades its own homework (own deep dive) |
