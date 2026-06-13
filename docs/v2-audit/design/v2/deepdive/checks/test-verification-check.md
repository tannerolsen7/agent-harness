# Adversarial Check — `test-verification.md`

> **Role:** doer-not-checker. A different agent wrote `test-verification.md`; this file attacks it.
> Every finding is grounded in a source I read (cited by path/line). Tiered MUST-FIX / SHOULD-FIX /
> CONSIDER + a one-word verdict at the end.
>
> **Charge (verbatim from the orchestrator):** (1) Does it actually solve "green but worthless" or
> just assert /tdd is good? (2) Is mutation testing evaluated concretely (tool/cost/where) or
> name-dropped? (3) Is the no-transcription rule given a real ENFORCEMENT mechanism or left
> advisory? (4) Does it distinguish what is already in the design from genuine NEW additions,
> honestly? (5) Any capability assumption that does not hold (e.g. a hook detecting transcription
> semantically)?

---

## What I verified (so the findings are not opinion)

- `tdd/SKILL.md` — the no-transcription quote (doc §2, lines 95-98) matches **verbatim**
  (`SKILL.md:37-39`), and the anti-rationalization row "a test written after implementation is a
  transcription, not a spec" matches `SKILL.md:28`. ✅ The doc quotes the on-disk skill honestly.
- `capability-facts.md:17-20` — "**No hook can REQUIRE an artifact (screenshot) to exist before
  completion**" and `:11-16` — Stop-hook block-on-red works but force-continue semantics are
  "**verify empirically**." The doc's honest-limit claims (Layer 3: red-evidence is "verify-if-present
  at the hook, hard at CI") are correctly grounded in this. ✅
- `engineering-rigour-small-team.md:46` — the `bugfix-test-guard` and the "a gate keyed off the diff
  is the difference between 'rigour' and 'a comment the agent didn't read'" quote match **verbatim**. ✅
- `recursive-self-improvement.md:5,39` — "authority laundering," the self-agreement thesis, and the
  hard-construction rule "a friendly-only corpus produces a recall number that is optimistic by
  construction" all match. The Layer-7 vacuous-test sub-corpus is a faithful application of Move 4. ✅
- `VISION.md` — grepped for `mutation|stryker`: **zero** roster hits (only unrelated "gh api
  mutations" / "browser-driving for mutations"). Mutation testing is genuinely **not** in the roster,
  so the "NEW addition" label is honest. ✅
- `ROUND-2-FEEDBACK-AND-CORRECTIONS.md:59,90` — the corrections ledger **does** explicitly list
  "MUTATION TESTING [new]" and "a test-quality review lens" as new items for this deep dive. The
  doc's claim it "explicitly lists" them is accurate. ✅
- `.claude/skills/cr/SKILL.md:143-147` — `/cr` Pass 11 has **four** lenses (assumption violation,
  composition failures, cascade construction, abuse cases). None owns "is this test real?" — so the
  doc's Layer-6 gap claim is accurate. ✅
- **StrykerJS Vitest runner** (WebSearch, June 2026): `@stryker-mutator/vitest-runner` is real,
  officially maintained in the Stryker monorepo since Stryker 7.0, current v9.1.1, integrates with
  the project's own Vitest install. The Layer-4 tool claim is **fact, not name-drop**. ✅
- The doc does **not** reproduce the old "build a `/goal` skill" framing (grep: no `/goal` skill
  reference); §10 correctly says "the **built-in continuation loop**." The correction is applied. ✅

So on the headline charge the doc is mostly **sound**: it does NOT merely assert "/tdd is good." It
names the exact gap (/tdd is advisory and self-graded), and stacks six other layers around it. The
findings below are where it over-claims readiness, hand-waves a mechanism, or rests on one capability
assumption that is shakier than stated.

---

## MUST-FIX

### MF-1 — The headline question is answered for ~10% of the test surface; the doc lets the reader feel it's answered for all of it.

The doc's strongest, most concrete proof against "green but worthless" is **mutation testing**
(Layer 4) — and it is, correctly and honestly, scoped to **pure functions only** (pricing/schema),
run on a schedule, never on integration tests, because "integration tests hit a real Supabase
instance" (doc §5.2, lines 282-285). That scoping is right. But it has a consequence the doc never
states plainly: **the one mechanical, deterministic "this test would catch a real bug" proof does not
cover the surfaces where a bad change is most expensive** — the `/p/[token]` renderer in front of a
$30k client, server actions, and RLS-adjacent `src/data/` edits. Those are exactly the surfaces
`engineering-rigour-small-team.md:17` names as "where a bad fix is most expensive," and they are
*integration-tested against a real DB*, so mutation testing is explicitly off the table for them.

For everything outside pure money math, the answer to "how do we know the test is real?" collapses
back to: the no-transcription rule (advisory), red-before-green (honor-system → CI-hard only if an
artifact is produced), and a **probabilistic review lens** (Layer 6, can miss). That is a real and
honest answer — but it is *materially weaker* than the mutation-testing proof, and the doc's framing
(seven layers, "defense in depth," the confident §11 checklist) lets a reader walk away believing the
hard proof covers the whole product. **Fix:** add one explicit paragraph — "On the integration-tested
surfaces (renderer, server actions, RLS-adjacent data), there is *no* mechanical kill-the-mutant
proof; trust there rests on the probabilistic lens + red-before-green + the human checklist, which is
weaker, and that is the honest state." Right now the strongest claim and the weakest coverage are not
visibly connected.

### MF-2 — Spec-traceability (the mechanism doing real work in Layers 1, 2, and 6) is presented as near-ready; on disk it does not exist and is not trivial.

Three separate layers lean on "every behavioral assertion traces to a spec line": Layer 1 detector #2
(doc lines 123-126), Layer 2's "How a test traces to a spec line" (lines 161-170), and Layer 6 check
#3 (lines 374-376). The doc presents this as lightweight — "each behavior gets a stable id (e.g.
`VER-3`)… the test references the id… a lens can then ask two cheap questions" — and claims **"Our
`docs/TESTING.md` already reads like this."**

I checked. `docs/TESTING.md` contains good prose behavior statements (e.g. line 51, *"Rejection notes
are capped at 2,000 characters after trimming. Longer input raises `notes_too_long`"* — which the doc
quotes correctly), **but it has no `VER-` ids, no stable anchors, and no test↔line linking
machinery.** The "two cheap questions" a lens asks (every Verification line has a test; every
assertion traces to a line) require an id scheme and a convention for tests to reference it — neither
exists. This is not "cheap"; it is a new convention to design, retrofit across the existing
TESTING.md corpus, and keep in sync. The doc's "already reads like this" papers over the gap between
*prose that a human can eyeball* and *machine-checkable traceability a lens/CI can enforce*. **Fix:**
demote "already reads like this" to "reads like this in prose, but has no stable ids yet — the id
scheme + test-reference convention is itself a NEW design item," and flag it as such (it is currently
flagged nowhere; it hides inside Layers 1/2/6 as if free). Without it, three of the seven layers'
transcription/coverage checks are aspirational.

---

## SHOULD-FIX

### SF-1 — Layer 6's "spec-traceability" check is a transcription-*detector* that a determined transcriber defeats; the doc oversells it as catching lie #3.

Layer 6 check #3 (lines 374-376) and Layer 1 detector #2 both say: an assertion value that "appears
nowhere in the spec" is a transcription suspect. True. But the realistic transcription failure is
*not* "agent invents `42` out of nowhere" — it is "the spec says `total = subtotal + 10% fee`, the
buggy code returns the bare subtotal `1000`, and the agent writes `expect(total).toBe(1000)`." In
that case **the asserted value DOES trace to a plausible-looking computation**, and the spec contains
all the ingredients — the transcription is *wrong-but-spec-adjacent*, not *spec-absent*. Spec-trace
catches the lazy transcriber (value from nowhere) but not the competent one (value that looks
derived). The doc's own §2 worked example (lines 104-109) is precisely this case, yet it is filed
under the rule "biting" — when in fact only **mutation testing** (which the doc admits doesn't cover
this surface unless it's pure-function pricing) or an **independent oracle that recomputes the
expected value** actually catches it. **Fix:** state that spec-traceability catches *absent-source*
transcription, not *wrong-but-derivable* transcription; the latter needs an independent recompute or
a mutant. This is the difference between the lens "flagging a smell" and "catching the bug."

### SF-2 — The "recorded red-then-green observation" (Layer 3 mechanism #1) is asserted as buildable on HOOK-1, but the doc's own capability source says the hook cannot compel the artifact, and the doc never closes the loop on *what makes the CI leg able to verify it either.*

Layer 3 (lines 210-218) proposes HOOK-1 "record, per new test, a red-then-green observation," then
honestly concedes (citing `capability-facts.md`) that "a hook… *cannot compel an artifact to
exist*," so it is "verify-if-present at the hook, hard at CI." Good honesty at the hook. **But the CI
leg is hand-waved.** How does CI verify a test ran *red against the pre-fix code*? CI sees the final
SHA, where the test is green. To prove red-before-green at CI you must either (a) re-run the new test
against the *parent* commit (requires isolating which test is new and checking out the parent —
buildable but non-trivial, and meaningless for a multi-commit feature branch where "before" is
ambiguous), or (b) trust a recorded transcript the agent attached (which is exactly the forgeable,
"verify-if-present" artifact the hook couldn't compel — moving it to CI doesn't make it
unforgeable, it just moves the unverifiable claim downstream). The doc says "the CI leg is what makes
it real" (line 218) without describing a CI mechanism that is actually un-forgeable. **Fix:** either
specify the parent-commit re-run mechanism and its limit (works for single-commit fixes; degrades on
squashed/multi-commit branches), or downgrade the claim to "red-before-green is enforceable only as
the `bugfix-test-guard` (test-delta-exists, which IS diff-checkable) — the *red observation itself*
stays advisory, even at CI." The `bugfix-test-guard` is genuinely deterministic (diff contains a test
file = checkable); the *red observation* is not, and the doc blurs the two.

### SF-3 — "Mutation score floor" is named but never given a number, an owner, or a failure action — the same advisory-prose trap the doc spends Layer 1 warning against.

Layer 4 §5.3 (lines 298-301) proposes "a **score floor** (e.g. fail/open-an-issue if pricing mutation
score drops below a stated threshold)." But it never states a threshold, never says whether a
below-floor score *blocks* anything or just *opens an issue*, and never assigns an owner. The doc
elsewhere (correctly, following `engineering-rigour-small-team.md`) hammers that "advisory prose the
agent may ignore" is the disease and "a gate keyed off the diff" is the cure. A mutation-score floor
with no number and no enforcement action is *exactly advisory prose*. Worse, mutation scores are
noisy (equivalent mutants inflate the "survived" count with false positives), so a naive floor will
flap. **Fix:** either commit to "scheduled report only, human reads it, NOT a gate" (honest, matches
the slow-and-noisy reality) — or specify a floor, a blocking-vs-reporting decision, and an equivalent-
mutant handling story. Right now it inherits the credibility of "deterministic proof" while behaving
like the advisory layer the doc disowns.

### SF-4 — Layer 6 (the test-quality lens) is the broadest claimed coverage and the *least* proven; the doc's own honesty about it is buried.

Layer 6 is the only layer the doc claims catches "all three [lies], by reading the test" (the §0
table, line 55). It is also the only **new** probabilistic check, running on Opus 4.8 under C2
isolation. The doc's one honest sentence about its weakness — "a review lens is a *probabilistic*
check — it can miss" (line 391) — is true but under-weighted relative to the breadth of what Layer 6
is asked to carry (it is the *only* "is this test real?" coverage on every non-pricing surface, per
MF-1). And its trustworthiness is entirely deferred to Layer 7 calibration — which has **never been
run** (C4 is `confirmed absence`, `recursive-self-improvement.md:21`: no recall number exists for
`/cr` at all). So the doc's broadest coverage claim rests on an un-calibrated probabilistic check
whose recall is, today, literally unknown. **Fix:** state plainly that Layer 6 is the load-bearing
check for most of the product *and* is currently un-calibrated, so its real recall is unknown until
C4's vacuous-test sub-corpus is built and run — i.e. "we don't yet know how often Layer 6 catches a
fake test" should be a headline caveat, not an inference the reader has to assemble from §6 + §8.

---

## CONSIDER

### C-1 — The "ships its own types" claim for StrykerJS should be marked verify-at-install, not asserted.

§5.2 line 277 states the Vitest runner "ships its own types." I confirmed the package is real and
maintained, but did not confirm the bundled-types claim; the doc elsewhere (correctly) routes the
install through the ask-first dependency fork. Tag the types claim as "verify at install" alongside
weekly-downloads/last-publish, rather than asserting it.

### C-2 — Minor staleness inherited from VISION C6: `docs/specs/` is no longer empty.

Layer 2 leans on C6, and VISION C6 says `docs/specs/` "does not exist on disk." On disk it now holds
`change-quote-request.md` (31KB) + `.gitkeep`. The doc doesn't restate the "doesn't exist" claim, so
this is not a defect *in the doc* — but if the main author copies C6's framing wholesale, they'll
ship a stale fact. Worth a one-line note that one spec now exists (so C6 is "barely started," not
"absent").

### C-3 — The §11 checklist's confidence outruns the body's honesty.

The closing checklist (lines 490-515) reads as a crisp, shippable gate ("If a test cannot answer 1-4,
it is not a real test"). Items 4 and 5 (recorded red-before-green; "if we break the code does it go
red") are presented as binary pass/fail, but per SF-2 (red-record not un-forgeable) and MF-1 (mutation
only on pure modules), neither is universally answerable today. The checklist is a good *aspiration*;
label it as the target state, not the current one, so it isn't quoted as if already enforced.

### C-4 — Git-host-agnostic / trigger-agnostic framing (§10) is correct and worth keeping; no defect.

§10 cleanly keeps everything CI-resident as "your git host / CI pipeline / protected branch /
PR-or-MR," puts Slack/Linear on equal footing with a repo label as first-class kickoff, and uses "the
built-in continuation loop" rather than a new `/goal` skill. This matches the corrections in
`ROUND-2-FEEDBACK-AND-CORRECTIONS.md:39-46` exactly. Flagging it as a *pass* so the main author
preserves it verbatim.

---

## Verdict

**SOUND-WITH-CORRECTIONS.**

The doc clears the bar the charge sets. (1) It does **not** just assert "/tdd is good" — it names the
precise gap (/tdd is advisory, self-graded, and re-checked by nothing) and stacks six independent
layers around it; the "green but worthless" failure is genuinely engaged, not waved at. (2) Mutation
testing is evaluated **concretely** — real tool (verified: `@stryker-mutator/vitest-runner`, Stryker
7.0+), real cost reasoning (per-mutant suite re-runs, brutal against real-DB integration tests), and
a real *where* (pure pricing/schema modules, scheduled CI). It is the doc's best section. (3) The
no-transcription rule is honestly admitted to be advisory and is reinforced from three named sides —
this is real, not hand-waved. (4) The already-in-design vs. NEW split is **honest and verifiable** —
I confirmed mutation testing and the test-quality lens are absent from VISION and explicitly
authorized as new in the corrections ledger. (5) The one capability assumption that matters — a hook
detecting transcription *semantically* — the doc **correctly refuses to make** (lines 111-114: "a
deterministic hook *cannot* read an agent's mind"); it does not claim a hook understands meaning.

What pulls it to *with-corrections* rather than fully sound: the doc lets its strongest proof
(mutation testing) borrow credibility for surfaces it explicitly cannot cover (MF-1); it presents
spec-traceability as near-ready when the id/linking machinery does not exist on disk (MF-2); and three
mechanisms (CI-verified red-record, mutation-score floor, the test-quality lens) are asserted with
more enforcement-confidence than they currently have (SF-2/3/4). None of these is a structural hole —
they are over-claims of *readiness*, the exact failure mode this whole audit exists to catch. Fix the
two MUST-FIX framing gaps and tag the three SHOULD-FIX mechanisms as "designed, not yet enforced," and
the doc is sound.
