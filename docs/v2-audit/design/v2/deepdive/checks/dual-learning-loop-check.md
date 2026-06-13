# Adversarial check — `dual-learning-loop.md`

> **Checker stance.** A different agent wrote the doc; my job is to attack it, not validate it. I read the target,
> the VISION spine, and every artifact it cites (`memory-model.md`, `github-usage.md`, `phase45/compounding-loop.md`,
> `ROUND-2-FEEDBACK-AND-CORRECTIONS.md`, `CORRECTIONS-LEDGER.md`). Findings are tiered MUST-FIX / SHOULD-FIX /
> CONSIDER, then a verdict. Where I assert a citation is broken or a claim is un-grounded, I name the exact file and
> line I checked.

**Charge recap (5 questions):** (1) Are BOTH loops concrete and walkable, or is the global one hand-wavy? (2) Is
the connection between them real (per-repo lesson → universal; universal arriving → starts a per-repo clock)? (3)
Is the concrete example carried all the way (first mistake → impossible)? (4) Honest about built-now vs gated? (5)
Does it correctly avoid GitHub-only and the `/goal` rebuild?

---

## Headline

The doc is **strong on rigor and honesty** and **mostly walkable**, but it has **one real citation-integrity
failure that is self-indicting** (it cites a phantom file path six times — the exact "doc-fiction" failure class
its own §scan-context section exists to catch) and **one structural asymmetry**: Loop B's *down-leg* (a universal
rule arriving and starting a fresh per-repo clock) is **the doc's own synthesis presented as grounded design** —
the cited source describes Loop B as a one-direction pipe and never describes what a receiving repo does next. The
example carry-through, the built-vs-gated honesty, and the corrections compliance (git-host-agnostic, Slack/Linear
first-class, no `/goal` rebuild) are all **sound**.

---

## MUST-FIX

### MF-1 — Six phantom citations: `compound-loop.md` does not exist (the file is `compounding-loop.md`)
The doc's grounding header (line 34) correctly cites `design/phase45/compounding-loop.md`. But **every inline body
citation uses the wrong path** `compound-loop.md` — a file that is not on disk:

- line 102 — `compound-loop.md §3.2`
- line 122 — `compound-loop.md §1`
- line 187 — `compound-loop.md §2`
- line 249 — `compound-loop.md §4`
- line 252 — `compound-loop.md §4`
- line 523 (the built-vs-gated ledger) — `compound-loop.md §1`

`find` over `design/` returns only `phase45/compounding-loop.md` and `phase45/CHECK-compounding-loop.md`. There is
**no `compound-loop.md`**. A reader who follows any inline citation hits a dead reference. This is not pedantic:
**the doc's own §scan-context section (lines 459-462) defines "fiction" as "a doc asserts a rule the code never
followed" and brags that the audit's own canon "cites five phantom artifacts."** Shipping a teachable doc about
catching phantom references that *itself* carries six phantom references is the precise failure the deliverable
exists to indict. Fix: global-replace `compound-loop.md` → `compounding-loop.md` (6 occurrences).

### MF-2 — The `§3.2` cite is wrong even after the filename is fixed (mis-pointer to a different section)
Line 102 grounds the entire running example on `compound-loop.md §3.2: "a cross-tenant RLS hole"`. I checked
`compounding-loop.md`: **§3.2 is "The golden set — what it is, and WHERE it is stored"** (line 155), and `grep`
for "cross-tenant" / "RLS hole" across the whole file returns **zero hits**. The phrase "cross-tenant RLS hole"
does not live in `compounding-loop.md` at all. Its actual homes are the **golden-set seeding lists** in
`VISION.md:363` (C4), `roster.md:79`, `world-class-review.md:96`, and `file-tree.md:161` — where it is one of four
*adversarially-seeded labeled diffs* for reviewer calibration, **not** a worked compounding case. So the citation
is doubly wrong: wrong file *and* wrong section, and the content it claims to ground (tenant-scope as the canonical
worked compounding example) is the doc's own framing, not something §3.2 supports. Fix: re-point to the real home
of the cross-tenant example (VISION C4 / the golden-set list), or — cleaner — state plainly that tenant-scope is
*this doc's chosen* worked example, drawn from the project's actual `team_id`/`private.team_ids()` RLS design
(which is real and citable in CLAUDE.md), and stop attributing it to a §3.2 that doesn't say it.

### MF-3 — Loop B's down-leg (§C.2 "an arriving rule starts a local clock") is un-grounded synthesis sold as design
This is the answer to charge question 2's second half, and it is the doc's biggest *substantive* weakness. The
**up-leg is real and grounded**: `github-usage.md §5a` (lines 282-308) draws the promote → `scope:` field →
human-gated PR/MR → merge → `/plugin update` pipe explicitly. But §5a stops at "carries it DOWN to every installed
repo." I grepped `github-usage.md` for "receiving / starts a clock / own loop / new loop / local clock / adapt" —
**nothing describes what a receiving repo does after the rule lands.** The source treats Loop B as a one-direction
distribution pipe.

The doc's §C.2 ("Global → per-repo: an arriving rule starts a local clock," lines 423-444) asserts that the
arriving rule "**measures itself** — *did this rule actually help in this repo?*" and "**seeds** a fresh per-repo
loop," citing "Loop A step 5" and "Loop A step 7." But those are the doc's *own* Loop-A steps re-applied by
inference — there is **no source that says a plugin-delivered rule auto-enters the receiving repo's measurement
ledger or its airlock.** It is a *plausible and probably-correct* inference (a `paths:`-scoped rule shard would
indeed load and could be measured), but the doc presents it with the same citation confidence as the grounded
up-leg, and it is the load-bearing claim for the doc's headline thesis that "each loop is the other loop's input."
The figure-eight's *bottom* curve is asserted, not designed.

This is exactly the kind of gap the doc is *good* at flagging elsewhere (it flags GAP-DLL-2 and GAP-DLL-4 around
this same seam). It should flag §C.2's core mechanism the same way: **the down-clock is a design-addition, not
existing design.** Fix: either (a) demote §C.2 to an explicit GAP/design-addition ("the source describes the pull;
this doc proposes that arrival should start a local clock — new"), or (b) find/author a real grounding for
"plugin-delivered rules enter the receiving repo's CMP1/CMP3 machinery" and cite it. Right now it reads as settled
design and it is not.

---

## SHOULD-FIX

### SF-1 — "measures that it stopped recurring" after ratcheting is mildly circular (§C.1 step 1)
Line 411: Loop A "ratchets it into a CI block, **and measures that it stopped recurring**." But once a finding is
ratcheted into a deterministic block (§A.7 Rung 2), the mistake *cannot* recur by construction — so "it stopped
recurring" is guaranteed by the block, not evidence the block *caught real defects*. The honest version is the
signal the doc itself cites better in §A.8: **the L2 failure-rate-over-time** — the CI check *firing* (catching
attempts) and then firing *less* as the agent internalizes it. "It caught N real attempts before they merged" is
the argument for going universal; "it stopped recurring" after you made recurrence impossible is almost tautological.
Tighten §C.1 step 1 to lean on "the block fired on real attempts here" rather than "recurrence dropped."

### SF-2 — The two loops are claimed "the same shape at two scales" but the shapes are not actually congruent
The thesis (lines 58-64, and the §C figure-eight) repeatedly asserts the loops are "the same shape." They are not,
and the doc is better when it admits it. **Loop A is 7 steps and ends in *impossible* (a deterministic block below
the model's reach).** **Loop B is ~4 steps (tag → human PR/MR → merge → pull) and ends in *distributed* (the same
advisory-or-block rule, now everywhere).** Loop B has **no promotion threshold, no occurrence count, no airlock,
no ratchet, no measurement step** — its gate is a single human judgment on one field. Calling them "the same shape"
oversells the symmetry and papers over the fact that Loop B is much thinner (appropriately so — but the doc should
*say* it's thinner, not claim congruence). This matters because a reader taught "they're the same loop" will expect
Loop B to have the same self-correcting rigor (counting, decay, measurement) that Loop A has, and it doesn't. The
honest framing: *Loop A is a learning loop with a feedback controller; Loop B is a promotion-and-distribution
pipe gated by one human.* Same *purpose* (compounding), different *mechanism*.

### SF-3 — Loop B is genuinely thinner/more hand-wavy than Loop A on the "who reviews and how" step (charge Q1)
Direct answer to charge question 1: **the global loop IS less concrete than the per-repo loop**, and not only
because of MF-3. Loop A walks 7 named steps with a worked example at each rung (occurrences 1→2→3, the exact
`signature` string, the exact shard filename `src-data.md`, four named ratchet rungs). Loop B's review step (§B.3)
is three bullets — "a human reviews it — is this really universal? Is the block correct? Does it conflict?" — with
**no mechanism for *how* a reviewer answers those questions.** GAP-DLL-1 (no decision aid for `scope`), GAP-DLL-3
(no portability test for a traveling block), and GAP-DLL-2 (no conflict reconciliation) are all real holes the doc
*surfaces honestly at the end* — but their existence means the global loop is **not walkable end-to-end the way
Loop A is**: a person could not actually *execute* "review the universal PR/MR" from the doc, because the doc tells
them the three questions but not how to answer any of them. This is partly inherent (Loop B's gate is human
judgment, which resists mechanization) — but the doc should state up front that **Loop B's review is a human
judgment call the doc cannot fully mechanize**, rather than implying it's as crisp as Loop A. Credit where due:
the GAP section does most of this work; it just needs to be promoted from "new gaps" to "honest limits of Loop B
as drawn."

### SF-4 — Bare "PR" leaks against the doc's own PR/MR word-list (3 spots)
The doc's word-list (line 26) mandates "PR/MR." Lines 330, 387, and 526 use bare "PR" / "PR-volume." Lines 330/387
are direct quotes of VISION P8's "human-gated PR" phrasing, so they're defensible, but a teachable doc that defines
PR/MR and then writes bare PR three times undercuts its own git-host-agnostic discipline. Either quote VISION with
"[PR/MR]" or normalize. Minor, but it's the doc's *own* rule.

---

## CONSIDER

### C-1 — The session-end catch (CMP5) honesty note is excellent; mirror it for the down-clock
§A.2's "Honest note" (lines 120-124) is a model of the rigor the charge wants: it names that CMP5 rides an
*unverified* Stop-hook capability and gives the fallback. That same discipline is exactly what MF-3's down-clock
needs. The doc already knows how to do this — it just didn't apply it to §C.2.

### C-2 — "the same night, in another repo" (§narrative step 5) quietly assumes a 2nd repo exists
The bedtime narrative (lines 504-505) has "in another repo on the fleet, an agent hits a new recurring mistake …
it'll ride Loop B up." But §B.6 correctly establishes that **Loop B's automation is GATED until a 2nd repo installs
the plugin**, and the whole fleet premise is hypothetical today (one repo: event-vendor). The narrative is
explicitly aspirational ("while you sleep"), so this is arguably fine — but a sharp reader will notice the narrative
spends a fleet that §B.6 says doesn't exist yet. Consider a one-clause flag ("once a second repo exists —") to keep
the narrative from quietly contradicting the gated-status ledger two sections up.

### C-3 — GAP-DLL-2 and the conflict case slightly undercut the figure-eight's optimism
§C.2 step 3 cheerfully says a receiving repo's quirk "may itself eventually flow back up as a refinement" — but
GAP-DLL-2 says the design has **no mechanism to reconcile a universal rule colliding with a local carve-out**. So
the figure-eight's "it just keeps adapting" optimism (line 437) is in tension with the doc's own admission that
collisions are unhandled. Not wrong — the gaps are flagged — but the prose in §C.2 reads more confident than the
gap section warrants. Align the tone.

### C-4 — The example is carried well in BOTH loops, with correctly *different* endpoints (this is a strength, note it)
Charge question 3: the tenant-scope example **is** carried all the way. In Loop A it reaches the literal endpoint
"impossible to merge unscoped" through four named ratchet rungs (§A.7, lines 217-231) — fully walked. In Loop B it
reaches "every repo now has tenant-scope enforced without re-learning it through its own three-strikes loop" (line
416) — which is the *correct* endpoint for a distribution loop (Loop B's win is **reach**, not **impossibility**;
impossibility is Loop A's win). The doc gets this right and does not conflate the two endpoints. No fix; flagging so
the author doesn't "fix" a non-problem.

---

## Charge-by-charge verdict

1. **Both loops concrete/walkable?** Loop A: **yes, fully** (7 steps, worked example at each). Loop B: **partially
   — thinner and not end-to-end walkable** on the human-review step (SF-3), and its down-leg is un-grounded
   (MF-3). The global one *is* somewhat hand-wavy, as the charge suspected — though the doc honestly surfaces most
   of the holes in its GAP section.
2. **Connection real?** Up-leg (per-repo lesson → universal): **real and grounded** (`github-usage.md §5a`).
   Down-leg (universal arriving → starts a per-repo clock): **asserted, not grounded** — the doc's own synthesis
   presented as existing design (MF-3). The figure-eight's bottom curve is the weak half.
3. **Example carried to "impossible"?** **Yes** — fully in Loop A; appropriately to "distributed" (not
   "impossible") in Loop B (C-4). Strength, not a gap.
4. **Honest about built vs gated?** **Yes — genuinely strong.** The built-vs-gated ledger (lines 517-535), the
   FPA-volume-gating caveat (§A.8), the CMP5 unverified-capability note (§A.2), and the Loop-B automation hold
   (§B.6) are all honest and well-tiered. The recurrence-vs-FPA distinction in §C.1 leans on the day-0 metric, so
   it's internally consistent (SF-1 is about phrasing, not an honesty break).
5. **Avoids GitHub-only + `/goal` rebuild?** **Yes on both.** Git-host-agnostic is applied thoroughly (every
   "GitHub" is either "GitHub OR GitLab," a Gitea/self-host example, the legitimate curated-marketplace caveat, or
   the honest GAP-DLL-5 about the non-GitHub trigger leg). `/goal` is correctly the **built-in continuation loop,
   not a new skill** (lines 44, 498-499); the `v2.1.139+` version fact is grounded in `ROUND-2-FEEDBACK §22` and
   `goal-loop-primitive.md:12`. Slack/Linear are framed as first-class doors equal to a repo label (lines 39,
   490-492). Full corrections compliance.

---

## VERDICT: **SOUND-WITH-CORRECTIONS**

The architecture is right, the honesty discipline is real, the example is carried, and all three user corrections
are correctly applied. But it ships **six phantom citations to a non-existent file (MF-1)** plus a **wrong-section
mis-pointer (MF-2)** — self-indicting in a doc about catching doc-fiction — and it **presents Loop B's down-clock
as grounded design when the cited source stops at the pull (MF-3)**, making the figure-eight's central "each loop
feeds the other" thesis half-asserted. None of these is architectural; all are mechanical (fix the paths, re-point
or re-frame the example's grounding, and demote §C.2's down-clock to an explicit design-addition). Resolve the
three MUST-FIX items and the verdict moves to SOUND.
