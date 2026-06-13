# Pass 3 — Apply to OUR harness vs. the ground-truth map

Building on pass2: the framework's live surface area is two ideas, not eight (pass2 §1); the curator's
best idea — principles compose/conflict — is abandoned in its own application section (pass2 §2); the
impact "fix" is a definition where the real mechanism is a per-unit retro gate (pass2 §3); the
depth/breadth axis is actually a reusability axis (pass2 §4); the provenance is third-hand and already
cites a retired mechanism (pass2 §5); the "empirical/confirmed" labels are industry consensus, not
proof (pass2 §6); and the framework presupposes a team and enforced mechanisms it never checks for
(pass2 §7). Everything below is grounded in `CANONICAL-HARNESS-AS-IS.md` (cited as `[§N]`).

## (a) What we ALREADY do

The four "consensus/confirmed" principles (pass2 §1) are already built — citing ground-truth rows:

- **P3 raise the quality floor** — built and *deeper* than the article describes. `/cr` runs 9 passes
  + adversarial review `[§3c]`; pre-commit gates ESLint + `tsc` + tests, and the `.cr-ok` sentinel
  chain gates push `[§3e, §3f]`. The article's named floor-raiser `/cr-feature` is **retired**
  `[§3b: "/cr-feature RETIRED v0.85, folded into /cr"]` — confirming pass2 §5: the article quotes a
  dead mechanism as live evidence.
- **P6 own the output** — built as the discipline rule (the 3-question pre-commit checkpoint in
  `CLAUDE.md`) and the human-handoff posture; the pre-push hook validates the `.cr-ok` sentinel for
  agents `[§3e pre-push]`. Accountability is structural, not aspirational here.
- **P7 be trusted with data** — built and *ahead* of the article's bar. We have a Tier-0 prod-key
  firewall + worktree provisioning (`worktree-create.sh`, `gen-local-env.sh`, `test-local.sh`) that
  the canon itself lacks `[§3e worktree-create.sh; §6 disk-only registry]`, plus RLS tenant isolation
  and the PocketOS destructive-operation rules kept verbatim `[§9 "keep verbatim"]`.
- **P2 automate the repeatable** — substantially built: `pr.sh`, `gc.sh`, `worktree-add.sh`,
  `seed.ts`, two CI workflows `[§3f]`, session-start remote npm install `[§3e session-start.sh]`.
- **P8 adapt as a team (the mechanism, not the speed)** — the article names PITFALLS.md,
  RECURRING-FINDINGS.md, `/compound`. All exist `[§4 memory model: memory.md, RECURRING-FINDINGS.md,
  PITFALLS.md, docs/solutions/, docs/adr/]` — plus a 6th auto-memory store the canon doesn't even
  model `[§4, §6 "Auto-memory MEMORY.md + 51 siblings"]`. We adapt *more* than the article assumes.

Net: 5 of 8 principles are already satisfied at or above the article's level. This is consistent with
pass2 §1 — those five are consensus baseline, and a mature harness clears them by definition.

## (b) REAL gaps it exposes — each cited to a ground-truth section or confirmed absence

Discipline note (pass2 §6): industry-consensus evidence does not by itself justify a build. Only gaps
that map to a real ground-truth row survive.

1. **P1 impact is undefined AND unmeasured — and the map confirms there is no mechanism.**
   `CANONICAL-HARNESS-AS-IS.md` inventories context/governance docs `[§3a]`, the memory model `[§4]`,
   skills `[§3b]`, hooks `[§3e]`, and the Model Capacity Audit `[§9]`. **None contains any
   impact-/outcome-tracking mechanism** — no store keyed to "did this matter," no skill that scores a
   shipped unit against an outcome. This is a *confirmed absence*: the map has a row for every memory
   store `[§4]` and none is outcome-keyed. The gap is real. **But** (pass2 §3) the article's fix — a
   two-sentence definition in `TASKS.md` — is theater; the load-bearing version is a per-unit retro
   gate, which is a heavier lift the article hides inside its "design challenge." Disposition:
   genuine gap, but scope it as the retro-gate, not the sentence. Note `TASKS.md` exists on disk
   `[§0 headline: "TASKS.md" listed among built knowledge docs]`, so the cheap version is trivially
   addable; the real version is not.

2. **P8 "speed of adaptation" maps to a specific confirmed-absent hook.** The article's complaint —
   adaptation is "slow and manually triggered" — is exactly the ground-truth finding: the memory layer
   is **fully manual**. `session-end.sh` (the Stop → memory-candidate hook the canon declares) is
   **absent on disk** `[§3e session-end.sh: "Canon's memory-capture hook — absent; disk's memory is
   fully manual"; §5 canon-only registry: session-end.sh]`. The article's proposed fix (run
   `/scan-context` weekly) is weaker and itself blocked: **`/scan-context` is documented in canon but
   has no disk dir** `[§3b "Documented in canon, ABSENT on disk: /scan-context"; §5]`. So the article
   points at a real gap but proposes a mechanism we don't have. The actionable mapping is: build
   `session-end.sh` (auto-propose memory candidates) — a `[§5]` canon-only item — *not* "schedule the
   scanner weekly," which can't run.

3. **P5 build-in-the-open maps to the single biggest structural fact in the map.** The article parks
   this until "30+ days." The map is blunter: the harness has **never been installed anywhere but
   event-vendor** `[§8 "Multi-project is a goal, not a state"; §0 "the multi-project canonical harness
   is aspirational"]`, and the canon's own backlog has "GitHub Publishing — in progress; next gate: 3
   real installs" and "apply engineering system to Recyclops" both **unmet** `[§8, canon
   To-Think-About #20/#22]`. So P5 is not "parked pending maturity" — it is the central V2 driver
   already named by the map. The article *under*-rates this gap; the map *over*-rides the article's
   "wait 30 days" framing. Disposition: real, and higher-priority than the article claims.

4. **P4 (depth vs. reuse) maps to a live disk decision the map records.** Per pass2 §4 the real axis
   is reusability. The map shows our agent roster grew to **23 agents** `[§3d]` — the specialist-heavy
   direction Ramp moved *away* from. Meanwhile **no project skill travels to another project** `[§1
   "None of the project skills travel"]` and skills mix three ownership layers indistinguishably `[§1
   runtime skill list]`. The article's P4 critique is therefore directly applicable: our growth has
   been lane-depth (more specialist agents) rather than reuse (portable skills). This cites a real
   structural row `[§3d, §1, §8]`. Disposition: genuine, and it reframes V2's roster question — fewer
   specialist agents, more portable skills — which the map already gestures at.

5. **The composition gap (pass2 §2) maps to the Model Capacity Audit's governing rule.** The article's
   best idea — principles compose; an unenforced principle degrades the rest — is the same logic as
   `[§9]`'s golden rule: "if you can't name a failure mode that the constraint prevents, the constraint
   is overhead." A principle with no enforcement is overhead by that test. This is not a build gap; it
   is a *lens* that strengthens an existing canon rule. Disposition: fold into the §9 re-audit, no new
   mechanism.

## (c) Weaknesses in the article's OWN reasoning

- **Third-hand provenance, uncorrected (pass2 §5).** Analyzes the May-19 Notion mapping, not disk; the
  ground-truth check confirms it quotes the **retired** `/cr-feature` as a live floor-raiser `[§3b]`.
  Any "the system already does X" claim from this page must be re-grounded — as done in §(a) above.
- **Abandons its own best idea (pass2 §2).** Raises "principles compose/conflict," then issues three
  *independent* candidates (define-impact, park-publishing, weekly-scanner) ungated by impact. Two of
  the three target mechanisms that don't exist on disk (`session-end.sh` absent, `/scan-context`
  absent `[§3e, §3b]`), so the application section is partly un-runnable on our harness.
- **The P1 fix is a category error (pass2 §3).** A definition that is never evaluated is a mission
  statement; the real mechanism (per-unit retro scoring) is buried in optional homework.
- **"Empirical/confirmed" overclaims (pass2 §6).** The ledger's confirmations are industry consensus
  (Linear/Stripe/Zapier/Basis paraphrases), not falsifiable evidence; popularity is treated as proof.
- **Team/solo and principle-vs-mechanism blind spots (pass2 §7).** Half the framework presupposes a
  team and a public audience that don't exist for a solo dev running parallel agents; and it never asks
  whether an unenforceable principle earns its place — the exact question `[§9]` forces.

## (d) Does it warrant fresh external research?

**Mostly no — synthesize, don't re-research.** Disciplined verdict:

- **P1 / P2 / P3 / P5 / P6 / P7 / P8:** No new research. Each maps to a row already in the map
  `[§3a–§3f, §4, §5, §8, §9]`; the work is build-or-reject decisions, not learning. The impact gap
  (§b-1), the manual-memory gap (§b-2), and the multi-project gap (§b-3) are all already-known map
  rows; re-researching them would re-derive what `[§5]` and `[§8]` already state.
- **One narrow exception — P1 impact for a pre-revenue solo product.** The article's open question 3
  ("what's the right impact proxy with no DAU/revenue/retention?") is genuinely unanswered by the map
  and by the article. *If* V2 decides to build the per-unit retro gate (§b-1), a **small, bounded**
  search for outcome-proxy patterns at pre-revenue/solo scale would be justified — but only after the
  build-or-defer decision, and only if the answer isn't reachable by synthesizing what we already have.
  Default to defer: the map's §9 re-audit (Sonnet 4.6 → Opus 4.8) is the higher-leverage open thread,
  and impact-definition is a product decision for Tanner, not a research question.

## Pass-3 thesis

Against the ground-truth map, this article is a **pressure-test that confirms the map's own
priorities, not a source of new mechanisms.** It validates that 5 of 8 principles are already met at
or above its bar `[§3a–§3f, §4]`, and the three gaps it surfaces all resolve to rows the map already
holds: the impact gap is a confirmed outcome-tracking absence `[§4]` (fix = retro gate, not a
sentence); the adaptation-speed gap is the absent `session-end.sh` `[§3e, §5]` (not the un-runnable
weekly-scanner the article proposes); and build-in-the-open is the map's central multi-project gap
`[§8]`, which the article under-rates. Use it as an audit lens folded into the §9 re-audit; build
nothing solely on its authority (pass2 §6).
