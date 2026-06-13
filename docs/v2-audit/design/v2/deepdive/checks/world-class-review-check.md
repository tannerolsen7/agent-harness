# Adversarial Check — `world-class-review.md`

> Checker stance: doer ≠ checker. A different agent wrote the target; my job is to attack it, not validate it.
> I read the target in full, then read every source it cites: `VISION.md` (both halves), `roster.md`, and all
> six re-mines (`coderabbit.md`, `code-review-latentspace.md`, `ramp-inspect-agent.md`,
> `when-is-llm-call-worth-it.md`, `engineering-rigour-small-team.md`, `augment-code.md`). Findings are tiered.
> Verdict at the bottom.

---

## Charge-by-charge verdict (the five questions I was asked)

**(1) Does it USE the review research, or stay generic?** — USES it, deeply and accurately. Every load-bearing
number traces to a specific source line, and the numbers are *correctly attributed* (which is the harder test —
a generic doc gets the number right but the mechanism wrong). Spot-checks I ran against the sources:

- "1.7x more review comments per line" → `coderabbit.md:5`. ✓
- "43%→91% merge-readiness" → `code-review-latentspace.md:5,23`. ✓ — and critically the target says (line 42,
  316) the number is **from the loop, not a single pass.** The source agrees (`:23`: "it is the *iterative
  loop*… which the conservative read dropped"). Most summaries get this wrong; this one is precise.
- "800-line ceiling, treat as tunable" → `code-review-latentspace.md:12`. ✓ (exact phrasing carried.)
- "74% Ona lead-time, independent (non-vendor)" → `code-review-latentspace.md:27,62`. ✓
- "87–100% over 8 weeks from context accumulation, not model upgrades" → `code-review-latentspace.md:5,35`. ✓
- "~30% of merged PRs, no usage mandate" → `ramp-inspect-agent.md:9`. ✓
- "24 of 25 credential exfiltration" → VISION F2 / `augment-code.md` (Anthropic red-team). ✓

This is not a generic "review is good" essay. It is anchored to the corpus at finding-level granularity.

**(2) Is the "humans catch bugs" half concrete?** — Mostly YES, and concrete where it counts. §2.3 (scannable PR
template), §2.5 (blast-radius surfacing), and §2.6 (the 5-item human checklist) are specific and behavioral, not
hand-wavy. The "<15-min review" claim is the one soft spot (see SHOULD-FIX-1). The human checklist items are each
tied to a *category machine layers structurally under-catch* (odd-smelling code, real-world behavior, intent,
tenant leaks, taste) — that is the right framing, and the tenant-trap item (§2.6.4) correctly cites the
real C8 mechanism (RLS isolation invisible to the DOM).

**(3) Is the keystone HONEST?** — YES. This is the doc's strongest section (§2.2 + Layer 12 + the §2.8 close).
It says explicitly and repeatedly that F6 makes only the **SHA-match + deterministic checks** un-forgeable, and
that the 9-pass + 4-lens judgment is **coverage-bounded trust-but-verify** measured by C4 recall, *not* the merge
gate. It refuses the over-claim "the model agreed with itself is un-shippable" — in three separate places
(§2.2, Layer 12, the closing caveat). This matches VISION headline-delta #3 verbatim. No over-claim found.

**(4) Is the GAP list real?** — YES, all 8 gaps trace to a real, citable mechanism in the corpus that the V2
*design* under-built or left as a thread. I verified each against its cited source (details in MUST/SHOULD
sections). Two of the eight are slightly mis-framed as "new" when VISION already names them as clauses (see
SHOULD-FIX-2) — but the underlying gap is real in each case.

**(5) Any rebuilt-rejected-pattern?** — NO. The most dangerous candidate — the "no shared context" reviewer —
is an UPHELD-CUT in VISION (`VISION.md:753`). The target does **not** rebuild it; §1.1 explicitly names it as
the thing "the Gemini experiment got wrong" and adopts the *kept* form (isolated solution context + full project
canon). Clean. I checked the other UPHELD-CUTs too (auto-merge on confidence score, collapse-23-agents,
`learned-patterns.md` file) — none are resurrected.

---

## MUST-FIX

*(None at the SOUND-blocking level. The doc is substantively correct and honest. The items below are the closest
to must-fix; I rank the strongest one here because it is a factual mismatch with the cited source, even though
it does not change the conclusion.)*

**MF-1 — The §1.6 "test-count-never-decreases" framing slightly mis-states what the source actually gates on,
and risks shipping a weaker gate than the research prescribes.**
The target (§1.6, "Test-count-never-decreases floor") leads with *counting tests before/after and blocking if
the count drops on a sensitive path*, then adds the `bugfix-test-guard` as a sharpening. But the source
(`engineering-rigour-small-team.md:14`) does NOT prescribe a count-comparison; it prescribes a **red-before /
green-after reproducing test for any `fix`-scoped commit** — a categorically stronger and different check. A
test *count* can stay flat while the fix ships with a test that never exercised the bug (the exact failure
`/tdd`'s no-transcription rule exists to prevent — `roster.md:60`). The count-floor is real (it's one of the
REJECT triggers, §1.3 trigger 4) but it is the *weaker* of the two; presenting it first as "the" floor inverts
the source's emphasis. **Fix:** lead with the `bugfix-test-guard` (red-before/green-after for `fix` commits) as
the primary gate; demote the count-floor to the secondary deterministic check it is. This is a must-fix because
the final author could otherwise build only the count-comparison and believe they implemented the research.

---

## SHOULD-FIX

**SF-1 — "<15-min review" / "well under 15 minutes" is asserted as a research-backed throughput claim, but no
source in the corpus states a 15-minute number.**
§2.3 says the structured PR "a human can scan in well under 15 minutes" and the section header promises "reviews
in under 15 minutes." The *mechanism* (machine PR summary + evidence bundle → review intent over proof) is
sourced to `ramp-inspect-agent.md`, but the **15-minute figure is the target's own invention**, not Ramp's.
The closest real number in the corpus is Microsoft's **400/800-line review-effectiveness cliff**
(`code-review-latentspace.md:5`) — which the target never uses, and which is the *actual* quantified
review-throughput finding available. **Fix:** either drop the "15 minutes" to an unquantified "scan quickly,"
or replace it with the 400/800-line cliff (the real, citable throughput datum). As written it reads like a
sourced number but is not one.

**SF-2 — Two GAP items are framed as "the vision does NOT design X" when VISION in fact already carries X as a
clause — the gap is real but the framing overstates the omission.**
- GAP #2 (abstention/fallback contract): the target says "the current design has F7's retry ceiling but no
  uniform pass-result contract." But `when-is-llm-call-worth-it.md:31` (Move 4) is the source, and the gap is
  genuinely *that the uniform contract isn't wired* — fair. However VISION F7 *does* name "REJECT/NEEDS-HUMAN
  terminal state" which partially overlaps. The distinction (terminal-state ≠ per-pass abstention field) is
  correct but the target should say "F7 covers the loop ceiling but not the per-pass abstention field" more
  precisely, since a reader could think VISION ignored it entirely.
- GAP #5 (Doctrine layer): real and well-sourced (`engineering-rigour-small-team.md:26–31`). But the target
  doesn't note that VISION's session-start ritual machinery (`last_run > 7 days`) is the *existing hook* this
  would extend — it even says "surfaced at session start like the ritual check already is," which is correct,
  so this one is fine; flagging only for symmetry.
**Fix:** in GAP #2, add one clause acknowledging F7's terminal state so the "no contract" claim is precise.

**SF-3 — The "humans catch bugs" half claims the human does a "60-second manual smoke" on a preview deploy
(§2.6.2), but the doc never resolves the tension with its own §2.7 "auto-approve ≠ auto-merge" flow where LOW-risk
PRs reach main with NO human in the path at all.**
If LOW auto-approves into the F6 floor and the floor merges (§2.7), then the human checklist of §2.6 — including
the 60-second smoke and the tenant-trap check — *never runs* on LOW PRs. The doc implies the human checklist is
"the last line" (§2.6 intro: "the human is the last line") but §2.7 explicitly removes the human from LOW. These
are both true under the design (the human reviews MEDIUM+; LOW rides the deterministic floor) — but the doc never
states that the §2.6 checklist applies to **MEDIUM+ only**, leaving an apparent contradiction. **Fix:** add one
sentence scoping §2.6 to the PRs that reach a human (MEDIUM/HIGH), and note that LOW's safety rests entirely on
the deterministic floor + C4 recall, which is *why* C4 must clear a floor before LOW-auto goes live (the doc
says this in §2.7 but doesn't connect it back to "and therefore the human checklist doesn't protect LOW").

**SF-4 — GAP #6 (property-based testing) is correctly flagged as *pending/fork-gated*, but the body text §2 and
the Layered Defense stack never mention money-math invariants at all — so a reader who skips the GAP list would
not know money math has no review oracle in the current stack.**
C11 (PBT on money math) is the human-authored oracle "the loop cannot weaken" and money math on a $30k-client
tool is named (correctly) as the most expensive place for a silently-weakened test. Yet the 12-layer defense
stack (the doc's centerpiece) has no layer for it. That's defensible (it's fork-gated on `fast-check`) but the
omission should be *visible in the stack*, not only in the gap appendix. **Fix:** add a one-line note to the
Layered Defense section that money-math invariant-checking is a *pending* layer (C11/Fork F6), so the stack
doesn't read as complete when a known-expensive surface has no oracle.

---

## CONSIDER

**C-1 — The doc asserts the four lenses are "blind on purpose" and cites the isolation invariant, but never
surfaces the cost tension the roster flags.** `roster.md:160,165` notes the 4 lenses run ×4 in parallel and
questions whether the leaf lenses should stay on the cheaper model vs "the reviewer doing fewer on a stronger
model." The target presents the 4-lens fan-out as unambiguously good; a fuller treatment would note the
cost/independence trade the roster itself raises. Minor — the doc is about *mechanism*, not cost-tuning.

**C-2 — §1.7 (cost-ordered gates) gives the 0.9³ = 73% compounding math, which is correct, but the doc's own
"do NOT cut review passes" scope-limit slightly undercuts the section's own logic without resolving it.** The
source (`when-is-llm-call-worth-it.md:27`) is explicit that the resolution is *deterministic gates between
passes recover the reliability without cutting passes* — the target says this, but the reader is left to infer
why 9 probabilistic passes don't simply decay to a low number. One added sentence ("the deterministic
checkpoint between passes resets the chain to 1.0 at each gate, so the 0.9ⁿ decay only applies *within* a
segment, not across the whole pipeline") would close the logical gap. The current text is correct but slightly
under-explains its own escape hatch.

**C-3 — The doc could state the one place it is weakest more loudly: the entire "trust-but-verify" half (layers
5–7) rests on C4 calibration *existing and clearing a floor*, and C4 is tagged P1 / not-yet-built.** The doc is
honest that calibration is the meta-layer (Layer 8, §1.4) — but a sharp reader notices that until C4 ships, the
judgment half has an *unmeasured* miss-rate, which means in the interim the only real wall is the deterministic
floor + the human. The doc implies this but never says "until C4 ships, layers 5–7 are trust-*without*-verify."
That is the most honest possible framing and the doc stops one step short of it. Worth adding to the §2.8 close.

**C-4 — GAP #8 (calibrate `/cr-security` + each lens, not just `/cr` overall) is real and well-sourced**
(`when-is-llm-call-worth-it.md:10` — "Same pattern for `/cr-security` (golden vulnerable diffs) and the 4
adversarial lenses"; and the roster's `/cr-calibrate` already says "per pass/lens" at `roster.md:79,364`). So
the gap is *partially* addressed in the roster's calibration design already. The target's framing — "the
golden-set design currently centers on `/cr`; make sure `/cr-security` gets its own corpus" — is fair, but it
slightly under-credits that VISION C4 already emits per-pass/per-lens recall. **Consider** softening to "ensure
the `/cr-security` golden corpus is *built*, not just the per-lens recall *emitted*."

---

## What I tried to break and could not

- **The keystone honesty.** I attacked §2.2 looking for an over-claim. It holds — the un-forgeable/trust-but-
  verify split is stated three times and matches VISION delta #3 word-for-word. No daylight.
- **The rejected-pattern check.** I specifically hunted for a resurrection of "no shared context reviewer,"
  auto-merge-on-confidence, and the collapse-23-agents reflex. None are present; §1.1 actively rejects the
  first, §2.7 actively rejects the second.
- **The numbers.** Every quantified claim I checked traced to a source line with correct attribution. I found
  zero fabricated statistics. (The only un-sourced *number* is the 15-minute claim — SF-1 — which is a target
  invention, not a misattribution.)
- **The lens contracts.** I verified all four differentiating fields (LIKELIHOOD/BLAST-RADIUS/golden-exemplar/
  stay-in-lane/isolation-invariant) against `roster.md:160–165`. All accurate, including the "silent wrong
  value shown to user" rubric entry the doc quotes.
- **The corrections.** All three user corrections are applied throughout: Slack/Linear as first-class triggers
  (§2.1, the boxed correction), git-host-agnostic language ("your git host," "PR/MR," "CI pipeline," "protected
  branch" — consistent), and "built-in continuation loop" not a new `/goal` skill. **One residual:** see SF/CONSIDER
  note below.

**Residual on the corrections (CONSIDER-level):** The target's masthead (line 5) says it uses "Claude Code's
built-in continuation loop" — correct per the user's correction. But the *sources and VISION* still call this
`/goal` (a new skill), and the target inherits "iterate-until-clean loop" language that maps to VISION's L2
`/goal`. The target handles this correctly at the masthead but doesn't flag that the underlying VISION/roster
still design a `/goal` skill — so a downstream author wiring this up could re-introduce the rejected
"build a new `/goal`" framing. Worth a single explicit note: "where VISION says `/goal`, read 'the built-in
continuation loop'." Not a flaw in *this* doc, but a seam it could close for the next author.

---

## VERDICT: **SOUND-WITH-CORRECTIONS**

The doc genuinely uses the review research at finding-level granularity, keeps the keystone honest without
over-claiming, builds a concrete (not hand-wavy) human-catch half, lists real and citable gaps, and resurrects
no rejected pattern. It is the strongest kind of synthesis: precise about its numbers and explicit about the
boundary between what is un-forgeable and what is measured-trust.

The corrections are all SHOULD-FIX or below — none invalidate the structure:
- **MF-1** is the one factual mismatch worth fixing before the final author builds from it (the bugfix-test
  guard is red-before/green-after, not a count comparison — get the emphasis right or a weaker gate ships).
- **SF-1** (the un-sourced 15-minute number) and **SF-3** (the §2.6-vs-§2.7 human-path contradiction) are the
  two that a careful reader would catch and that slightly dent the doc's otherwise-high rigor.
- The rest are polish that make an already-honest doc tighter.

Recommend: apply MF-1, SF-1, SF-3 before this becomes source prose; SF-2/SF-4 and the CONSIDER items are
author's-discretion improvements.
