# Lens: Honesty & Proportionality — Adversarial Review of the Integrated V2 Design

> **Lens charge.** World-class-disciplined, or kitchen-sink? (1) Is the 5-move minimal-floor discipline held
> (not a 32-move "everything is P0")? (2) Is every move §9-justified by a concrete failure mode NOT merely
> circular within the autonomy program? (3) Are the honest cuts genuinely cut? (4) Is `gaps-risks.md` honestly
> self-critical or self-serving — name a gap it MISSES. (5) Is the two-budget framing honest (budget-1 down,
> budget-2 up — not a store-count win masquerading as a file-count win)?
>
> **Posture:** doer≠checker, default-to-skepticism. Ground truth re-verified on disk this session
> (2026-06-11): 26 skill dirs (`dep-update` = empty stub, no `SKILL.md`; `evaluate-solution` PRESENT, 8.9 KB),
> 23 agents, 5 hooks; `proxy.ts` lives at **repo root** (not `src/proxy.ts`); `.cr-ok` gitignored
> (`.gitignore:58`); `pr.sh` consumes + `rm`s the sentinel locally before the PR opens. Every finding below
> cites the artifact line and the disk/check fact it stands on.

---

## VERDICT: SOUND-WITH-CORRECTIONS — but with ONE proportionality-honesty breach the integration must not ship without

The integrated design is, on the whole, **disciplined, not kitchen-sink**. The 5-move floor is held as a real
P0 set with the rest sequenced (point 1 PASSES); the honest cuts are genuinely cut and the §F rejections are
upheld dead, not reflexively elevated (point 3 PASSES); the two-budget framing is conceptually honest and the
file-tree itself refuses to chase a flat `find | wc -l` (point 5 PASSES *in the framing*, FAILS *in the
summary arithmetic*). `gaps-risks.md` is the most honest document in the tree (point 4: largely PASSES, with
named misses).

But the integration earns SOUND-**WITH-CORRECTIONS**, not SOUND, on a breach that sits exactly in this lens's
crosshairs: **the per-artifact checks (WF4) found real MUST-FIX items, and at least 6 of them across 4 of 5
checks were never folded back into the artifacts.** The most consequential is the keystone over-claim: F6 is
named "the unforgeable + visible verdict gate," and VISION's own headline-delta #3 says "done" requires
"MUST-FIX=0 … where the loop cannot forge it" — but the `github-usage-check` proves (traced to `pr.sh` +
`.gitignore` on disk) that the gate as actually specified checks **SHA-match + deterministic tsc/eslint/test
green only**, and **does not check MUST-FIX=0 at all**. The keystone is named after a property it does not
deliver, and the check that caught it was not folded. That is the precise failure this lens exists to catch:
a headline claim outrunning the mechanism, surviving an adversarial check, and shipping anyway.

The charge's framing — "the per-artifact checks already run; their MUST-FIX must be folded, verify they are
real" — is therefore **falsified on the ground**: they are real, and they are largely *not* folded.

---

## MUST-FIX

### MF-1 — The keystone (F6) is named "UNFORGEABLE" but the gate it specifies does not forge-proof the judgment half; the over-claim survives into VISION's headline deltas and was caught-but-not-folded

This is the single most important honesty finding in the design, because F6 is *the keystone* — "a hard
prerequisite for any unattended push" (`VISION.md:282`) — and the entire autonomy program rides on it.

**The claim.** VISION names F6 "**The unforgeable + visible verdict gate (THE KEYSTONE)**" (line 269) and
asserts in headline-delta #3 (line 659): *"'done' requires MUST-FIX=0 AND CI-green-on-SHA enforced in branch
protection **where the loop cannot forge it**."* The roster's Hooks table (`roster.md:131`) repeats it: "the
unforgeable last gate."

**The mechanism, traced to disk by the doer≠checker pass** (`github-usage-check.md:39-74`, re-verified this
session): `pr.sh` builds `EXPECTED="${branch}:${sha}"`, then **moves the sentinel to `.cr-ok.consumed.$$` and
`rm`s it** before the PR opens; `.cr-ok` is gitignored. So **at CI time the sentinel does not exist in the
repo** — not stale, absent. The only thing CI can re-run un-forgeably is what `ci.yml` already does
(`tsc`/`eslint`/`test` on the head SHA). The gate `github-usage.md` §4b actually specifies "FAILS unless
`sentinel_sha == head_sha` AND all required checks are green" — which **does not check MUST-FIX=0**. The
MUST-FIX verdict is relegated to the "surface face" (queryable, explicitly *not* the enforcement gate).

**Why this is a proportionality-honesty breach, not a wording nit.** The whole moral case for F6 (VISION
¶thesis lines 23-24; delta #3) is that it ends "the model agreed with itself" shipping to main. But a loop
whose 9+4 lenses share the generator's blind spot **still passes this gate** as long as tsc/eslint/tests are
green — *exactly the failure F6 claims to prevent* (`github-usage-check.md:68-70`). The judgment half is
**coverage-bounded trust-but-verify** (bounded by C4 recall), not "unforgeable." Calling it "unforgeable"
launders a trust gate as a proof gate at the one seam where the human was removed.

**And it was caught and not folded.** `github-usage-check.md` MF-1 is the check the prompt singled out
("resolve the CI-re-runs-subset vs trust-but-verify precision"). Verified this session: **the resolution
sentence is NOT in `github-usage.md` §4b** (grep for "coverage-bounded trust" / "computes the result itself"
returns nothing), and VISION delta #3 (line 659) **still** reads "where the loop cannot forge it." The
adversarial pass did its job; the integration did not consume it.

**Required fix.** (a) Rename the doctrine honestly — "F6: the un-forgeable *deterministic* gate + the
*coverage-bounded* judgment surface" — and state in one sentence that the enforceable half is SHA-match +
CI-recomputed determinism (un-forgeable; the model writes no record CI re-reads) while the 9+4 judgment passes
are trust-but-verify bounded by C4 recall and are surfaced, not gated. (b) Strike "where the loop cannot forge
it" from VISION delta #3, or scope it to the deterministic checks. (c) Fold the `github-usage-check` MF-1/MF-2
into `github-usage.md`. **Until F6's name matches its mechanism, the keystone over-claims and every downstream
"safe on the minimal floor" claim inherits the inflation** (`github-usage-check.md:168-172`, C-4).

### MF-2 — At least 6 real MUST-FIX items from the WF4 checks are unfolded; the charge's premise ("their MUST-FIX must be folded") is false on disk

This lens was told the per-artifact checks were "already run … their MUST-FIX must be folded, verify they are
real." They are real (the checks re-verified disk, and I re-verified them again). **They are largely not
folded.** Confirmed this session, per check:

| Check | MUST-FIX | Real? | Folded? | Evidence (this session) |
|---|---|---|---|---|
| `roster-check` MF-1 | `evaluate-solution` skill dropped from Table A; "22 KEEP" is actually 21 | **YES** | **NO** | Disk has 26 skill dirs incl. `evaluate-solution` (8.9 KB); Table A enumerates 25 rows (incl. the empty `dep-update`), **omits `evaluate-solution`** entirely. `roster.md:66` still asserts "22 KEEP." |
| `file-tree-check` MF-1 | "+5–6 rule shards" misfiled into Budget (2), flattering Budget (1) | **YES** | **NO** | `file-tree.md:232` still lists "+5–6 rule shards" under **Budget (2) — deterministic enforcement**, while the Budget (1) bullet (226-228) lists deletions only. The exact "store-count win masquerading as a file-count win" this lens polices. |
| `file-tree-check` MF-2 | Only 1 of 3 memory-traps routed; memory.md deletion BLOCKER gates on all 3 | **YES** | **NO** | Grep finds only `enforcement-boundary-layering` (line 81); `check-branch-before-commit` and `claude-md-referenced-scripts-must-exist` appear **nowhere** in `file-tree.md`. Two safety-adjacent traps can be silently lost at deletion. |
| `file-tree-check` SF-3 | Dead glob `src/proxy.ts` — shard won't auto-load | **YES** | **NO** | `file-tree.md:79` still globs `app/**,src/proxy.ts,middleware*`; disk: `proxy.ts` is at **repo root** (confirmed `ls`), `src/proxy.ts` absent. CLAUDE.md itself says "Pages listed in `proxy.ts PUBLIC_PATHS`" (root). A self-no-op'ing shard — the exact "fake shard" the tree warns against (line 46). |
| `github-usage-check` MF-1 | F6 over-claim (see MF-1 above) | **YES** | **NO** | Resolution sentence absent from §4b. |
| `github-usage-check` MF-2 | Two mis-pointed §3a cross-refs | **YES** | **NO** | `github-usage.md:59,98` still cite §3a (= "The trigger trifecta") for a settings-placement claim that lives in §2. A broken-cross-ref in the doc that designs cross-ref integrity. |

The honest accounting: **5 checks ran, 4 returned a SOUND-WITH-CORRECTIONS verdict requiring MUST-FIX folds,
and the folds did not happen.** A design effort that mandates doer≠checker and runs the checks but does not
*consume* them has done the expensive half (the attack) and skipped the cheap half (the fold) — which converts
an adversarial pass into theater. This is itself a proportionality failure: the rigor was paid for and not
banked. **Required fix:** fold every WF4 MUST-FIX (and the SF-3 dead glob, which silently disables a
load-bearing mechanism) into its artifact before the design is treated as integrated; or, if a fold is
rejected, record the rejection with a reason in each artifact. Do not leave a found-and-named MUST-FIX
floating in a sibling `checks/` file as if proximity equals resolution.

### MF-3 — The §9 failure-mode justification is concrete for the FLOOR but partly circular for the SPINE — and the design's own honest-gaps doc admits the evidence that would break the circularity was never sought

Charge point 2 asks whether every move is §9-justified by a *concrete failure mode, NOT merely circular within
the autonomy program.* The answer splits cleanly and the design does not flag the split:

- **The FLOOR (F1, F2, F5, F9) is concretely justified.** F1 cites Replit-July-2025 + PocketOS-2026 (real,
  external, dated incidents); F2 cites the Anthropic red-team 24/25 credential-exfil class + the on-disk fact
  that `.env.local` → prod Supabase with the service-role key; F5 cites the lethal-trifecta with leg-1
  permanently lit. These failure modes are real **whether or not** you buy the autonomy thesis. PASS.

- **The SPINE (L1, L2, L4, L5, L7) is justified by failure modes that are only failures IF autonomy is already
  the goal.** L1's failure mode is "the engineer stays the per-repo dispatcher" (`VISION.md:130`); L2's is
  "babysitting a session" (line 146); L5's is "the AFK-is-a-someday-feature trap" (line 173). Each is a real
  cost *conditional on having decided that unattended, self-triggering operation is the objective.* Strip the
  autonomy premise and none of these is a "failure" — they are descriptions of a human-driven pipeline, which
  is what V1 deliberately is. That is **circular within the autonomy program**: the move is justified by a gap
  that only exists because the program posits it.

This would be fine — the charter mandates autonomy-first, so the spine inherits that premise legitimately —
**except that the design's own honest-gaps doc concedes the premise was never adversarially tested.**
`gaps-risks.md` Gap #4 (lines 75-90): the corpus is curator-selected and *every* named source is
autonomy-**positive**; "there is no cited source that ran an autonomous fleet and **pulled back**"; "the
counter-evidence was never sought." So the spine's §9 justifications bottom out on a premise whose
supporting evidence is admittedly one-sided. **The circularity is real and the loop that would close it was
skipped.** Required fix: state plainly in VISION that the floor's failure modes are externally-grounded while
the spine's are program-internal (true and defensible under the charter), and elevate Gap #4's "one deliberate
search for autonomous-fleet rollbacks" from a noted gap to a **pre-Phase-1 action** — because the entire spine
rests on the unexamined side of it. Do not present spine moves with the same "concrete failure mode" confidence
as floor moves; the epistemic status differs.

---

## SHOULD-FIX

### SF-1 — The two-budget framing is honest at the header and DISHONEST at the summary — and that is the exact pattern it was built to police

Charge point 5 is whether budget-1-down / budget-2-up is honest or a store-count win wearing a file-count
costume. The framing earns real credit: `file-tree.md:18-40` explicitly splits the two budgets, books
`.claude/rules/` shards into Budget (1) ("exactly as forgeable as the prose they were split from," line 27),
and forbids chasing `find | wc -l` (lines 38-40). That is the honest move.

**But the Honest Budget Summary undoes it** (`file-tree-check.md` MF-1, re-confirmed this session): line 232
files "+5–6 rule shards" under **Budget (2) — deterministic enforcement**, while the Budget (1) bullet
(226-228) lists *only deletions*. Net effect: Budget (1) reads as a pure "large win" while its own +4-to-+6
file additions are parked in the budget the charter says is allowed to grow. The honest Budget (1) **file**
ledger is `−2 monoliths + ~6 shards = +4 files`; what actually falls is **per-task load** (1–2 shards on-path
vs 558 PITFALLS lines always) and **copies-per-fact (3→1)**. Those two wins are real and correctly stated —
but by misfiling the shards the summary hides the +4 file delta and invites the reader to infer a file-count
win that isn't there. **This is the precise "store-count win masquerading as a file-count win" the charge names
— and `RECONCILIATION §A` flags it as the very red-flag that `forced` the two-budget reframe** (`file-tree.md:21`).
The framing learned the lesson; the summary forgot it one screen later. **Fix per the check:** move "+5–6 rule
shards" into Budget (1) and restate the honest ledger (files +4, per-task load and duplication down sharply).
Until then the design contains a live instance of the dishonesty it was reorganized to prevent.

### SF-2 — "33 moves" / "44 moves" — the spine mis-states its own scope, in opposite directions across artifacts

`file-tree.md:4` describes VISION as "(5 pillars, **33 moves**, the 5-move minimal floor)." `file-tree-check.md:7`
counts "**44 VISION move IDs**" and reconciles every one to a landing row. Disk grep this session confirms **44
distinct move IDs** (L/F/C/CMP/P/HOOK-1/LOOP-7, excluding the C1/C3/C7/L3 demoted-to-clause IDs and the `P0`
false-positive from "P0-floor"). So the authoritative spine carries 44 moves, the file-tree says 33, and the
check says 44. A 33→44 drift (one-third undercount) in the headline scope number of a design whose entire
discipline-claim is "we tiered honestly" is a small but real honesty crack: **the proportionality story is "a
tiny floor, then a sequenced program," and the program is a third larger than the number used to sell its
restraint.** Reconcile to one number (44, or 40 if the four demoted clauses are excluded by policy) and use it
consistently. A reader cannot audit "is this kitchen-sink?" against a move count that is itself wrong.

### SF-3 — `gaps-risks.md` misses four structural gaps a complete honest-assessment owed itself (point 4)

`gaps-risks.md` is genuinely self-critical — it ranks force-continue first (the real load-bearing unknown),
refuses to claim probes it didn't run, and Gap #4 (corpus selection bias) is the sharpest finding in the tree.
It is **not** self-serving on its named gaps. But the charge demands I name a gap it MISSES, and the
`gaps-risks-check` already named several; re-verified this session, the most load-bearing misses are:

1. **It never reconciles gaps across its OWN sibling artifacts** despite claiming to cover "the **whole** V2
   design effort" (`gaps-risks.md:3`). It cites only `VISION.md` and never `file-tree.md`/`github-usage.md`/
   `memory-model.md` (grep: zero references). It thereby misses the *live, documented* budget-proxy-drift gap
   sitting in `file-tree.md:21` — a V2 artifact mis-reporting its own metric, exactly the over-claim class this
   doc exists to catch. A gaps-doc scoped to "the whole effort" that audits one of four artifacts has covered a
   quarter of its surface (`gaps-risks-check.md` MF-2).
2. **It never turns the doer≠checker lens on the design effort itself.** Gap #4 attacks the *corpus's*
   one-sidedness but stops one level short: VISION was "authored by the main loop … + both adversarial checks
   folded in" — i.e., the checks were spawned by the same loop that wrote the draft, so they verify
   *coherence-with-the-draft*, not independence. The structurally identical selection-bias risk one level up is
   unnamed (`gaps-risks-check.md` MF-3). This lens is itself evidence: I am finding *unfolded* MUST-FIX items
   the internal checks correctly raised — which means the internal pipeline's "fold the checks" step is the
   weak seam, exactly the independence gap Gap #4-one-level-up would have flagged.
3. **No cost ceiling on the COMPOUNDING loop's own nightly runs.** Gap #2 prices the action fleet but not
   CMP4/CMP6/P9/CMP3 — the maintenance loops that run on `/schedule` *in addition*. The ETH 20-23% context
   penalty the doc cites (line 56) applies to its own overhead loops; a harness can be viable on output and
   still bleed on self-maintenance (`gaps-risks-check.md` C-2).
4. **The harvest-from-disk method's own failure mode is unnamed** — by the doc's own §9 golden rule. Disk
   persistence makes a partial run *resumable* but not *correct*: "the file exists" is the completion signal, so
   a half-written or wrong slug is **harvested as done and never re-run** (`gaps-risks-check.md` C-3). The
   method this very effort is promoting to a first-class V2 principle (L7/F7) trades total-loss-on-interruption
   for silent-acceptance-of-a-corrupt-slug — *and this review found exactly that*: the WF4 checks ran, their
   slugs exist on disk, and the existence of `checks/*-check.md` was treated as resolution while their MUST-FIX
   items sit unfolded. The harvest method's failure mode is not hypothetical; it is operating right now in this
   tree.

**Fix:** either narrow the scope claim to "gaps in the VISION," or add a pass over the three sibling artifacts
and fold in at least the budget-proxy-drift gap, the design-effort-independence gap, the compounding-loop cost
gap, and the harvest-method failure-mode.

### SF-4 — The risk ranking conflates blast-radius with mitigation-status, burying the highest-stakes governance risk last

`gaps-risks.md` ranks R1 (force-continue, CRITICAL) correctly first. But R2-R5 are all some flavor of
"HIGH/MEDIUM-HIGH" with two different axes blurred: *blast radius if it breaks* vs *how mitigated it already
is*. R2 (screenshot-not-compellable) is tagged "HIGH, already mitigated" — a fully-mitigated risk does not
belong above an unmitigated one in a blast-radius ranking. R5 (auto-approval on a $30k-client tool —
cross-tenant PII / client-facing pricing error shipping unattended) has arguably the **highest real-world
blast radius** of the non-R1 risks yet sits **last**; the doc's own Gap #3 calls the auto-approval threshold
"the exact lever that decides what ships without a human on a $30k-client tool." **Fix:** separate the axes
(blast-radius vs open/bounded/residual) and re-order so R5 sits where its stakes put it (second). Also promote
"no global fleet kill-switch" from a #7 sub-bullet to a named risk — at 5+-repo laptop-closed scale, "no way to
stop the entire fleet right now" plausibly outranks the §9 baseline gap it currently sits below
(`gaps-risks-check.md` C-4, SF-3).

---

## CONSIDER

### C-1 — The honest cuts ARE genuinely cut (point 3 PASSES) — record this, because it is the design's strongest discipline

Re-verified against `killlist/F-rejected.md` and VISION's Honest Cuts (lines 718-741): the three fully-upheld
§F rejections are dead in VISION, not reflexively elevated. "Collapse 23 agents → 1" is explicitly "dead"
(VISION line 734; `roster.md:145`); "no shared context for the reviewer" stays dead and the *correct*
shared-canon/isolated-solution form is the kept one (C2); "front-load trigger-words / 200-line diet" stays an
UPHELD-CUT (tier by trigger-existence). The STILL-GATED list (line 726) holds four items behind named
flip-triggers rather than smuggling them in as P1. The UPHELD-CUT list (line 731) names a failure mode per cut
(browser-driving-for-mutations = irreversibility; auto-merge-on-confidence-score = authority-laundering;
`learned-patterns.md`-the-file = §6 phantom). **This is the part of the design where proportionality discipline
is genuinely world-class** — cuts are cut, the kept slice of each is named, and the failure mode is stated. The
one wrinkle: the cuts being *demoted-to-clause* (L3→L2, C1→F6, C3→F7, C7→F6+C6) are honest about losing
standalone-move status but, in the case of C1→F6, the merge is *where the MF-1 over-claim hides* — folding
C1 into F6 is correct, but it let "unforgeable" attach to the merged whole without re-checking that the merged
whole earns it. Cut-by-merge is fine; cut-by-merge that inherits an over-claim is the seam to watch.

### C-2 — The minimal-floor discipline (point 1) is held — but "minimal" is doing real work and should be stress-tested against F7

The 5-move floor (F1/F2/F6/F7/F9) is a genuine restraint: it is named as "the only true P0-floor set"
(VISION line 685), F5 is correctly scoped to the Slack/CI path only, F3/F4 are GATED on Fork F4, F8 is "before
fleet volume not before the first trigger." This is the opposite of "everything is P0" — PASS. One pressure
point: **F7 (bounded-loop + REJECT) is in the floor, but F7's own value depends on F6's verdict being
trustworthy** — F7 escalates "diff solves a different problem than the spec" to a human, but the spec-conformance
judgment is a *model* judgment (the same coverage-bounded trust as MF-1). So the floor's "bounded" guarantee is
deterministic for the *retry-ceiling number* but trust-bounded for the *REJECT triggers that require judgment*.
This does not break the floor (the retry ceiling alone is a real deterministic guard), but the floor's safety
claim should distinguish its deterministic spine (ceiling, SHA-match, credential-block, side-effect-lockout)
from its judgment-dependent leaves (REJECT-on-wrong-problem) — same honesty correction as MF-1, applied to F7.

### C-3 — Dogfood the P9 reference-integrity check on `design/v2/**` as the first test case — it would have caught three of this review's findings

`github-usage-check.md` C-3 makes the point and this review proves it: the SF-3 dead glob (`src/proxy.ts`), the
MF-2 mis-pointed §3a cross-refs, and the unfolded-MUST-FIX class are all exactly what P9's "no broken
cross-refs / every named artifact exists on disk" leg (`VISION.md:618`) is built to detect. If P9's detection
half (the CI check) were run on the v2 design tree itself, it would flag the dead proxy glob and the cross-ref
drift mechanically. The design indicts context-rot and then ships a tree with context-rot in it; the cheapest
proof that P9 is worth building is to run its detector on these very files.

---

## What the design gets RIGHT (so the verdict is not read as a teardown)

- **Point 1 (minimal-floor discipline): HELD.** 5-move floor, the rest sequenced with named gates; F5/F3/F4/F8
  each correctly scoped out of the first-trigger floor. Not "everything is P0."
- **Point 3 (honest cuts genuinely cut): HELD.** §F rejections dead in VISION; UPHELD-CUT list names a failure
  mode per cut; STILL-GATED items held behind flip-triggers, not smuggled to P1. The strongest discipline in
  the design.
- **Point 5 (two-budget framing): HONEST AT THE FRAMING.** The header split, the "shards are budget-1"
  correction, and the explicit "do not chase `find | wc -l`" are the right moves — the failure is the summary
  arithmetic (SF-1), not the concept.
- **`gaps-risks.md` is the most honest doc in the tree** — force-continue ranked first, no probe over-claimed,
  Gap #4 (corpus selection bias) is a genuinely sharp structural finding. Its misses (SF-3) are completeness
  gaps, not dishonesty.
- **The WF4 checks themselves are excellent** — each re-verified disk before attacking, each lands real
  MUST-FIX items, none is a rubber-stamp (all five returned SOUND-WITH-CORRECTIONS with concrete fixes). The
  failure is downstream: the integration did not *consume* them (MF-2).

---

## Bottom line

**SOUND-WITH-CORRECTIONS.** This is a disciplined, world-class-aimed design, not a kitchen sink — the floor is
minimal, the cuts are cut, the two-budget concept is honest, and the gaps-doc is genuinely self-critical. It
loses "SOUND" on proportionality-honesty for one structural reason that the lens exists to catch: **the
expensive adversarial checks were run and their MUST-FIX items were not folded** (MF-2), and the most important
unfolded item is the keystone's own over-claim — **F6 is named "unforgeable" but forge-proofs only the
deterministic half, and VISION's headline still claims the judgment is un-forgeable** (MF-1). Secondary: the
spine's §9 justifications are program-internal-circular in a way the floor's are not, resting on an
admittedly-untested autonomy premise (MF-3); the budget summary commits the exact store-count-as-file-count
slip the framing was built to prevent (SF-1); and the move-count is mis-stated by a third (SF-2). Fold the six
WF4 MUST-FIX items, rename F6 to match its mechanism, strike "where the loop cannot forge it" from delta #3,
fix the budget summary, and this design's honesty matches its considerable rigor.
