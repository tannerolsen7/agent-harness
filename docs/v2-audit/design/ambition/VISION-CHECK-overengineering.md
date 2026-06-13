# VISION-CHECK — Adversarial check on PROPORTIONALITY & RIGOR

**Checker stance (doer≠checker):** a different agent wrote `VISION-DRAFT.md`. My job is to attack it, not
validate it. The charter retired "fewer files = red flag" and made autonomy first-class, so I am *not*
going to score the draft down merely for being large. The test is sharper: **is each P0/P1 move
world-class-justified and proportionate to what the 37 sources teach, does it pass the §9 golden rule
(name a concrete failure mode it prevents), is it a phantom (already world-class per killlist/E), or does
it rebuild a killlist/F UPHELD rejection?** Default to skepticism.

**What I verified on disk (so the attack rests on ground truth, not the draft's own claims):**
- `block-dangerous-bash.sh` — **ABSENT** (F1 targets a real gap). ✅
- `disable-model-invocation` across `.claude/skills/` — **0 files** (F9 real). ✅
- `.cr-ok` in `.github/workflows/` — **0 references** (F6/C1 real). ✅
- `data-testid` across `src/`+`app/` — **0** (C9 real). ✅
- `/goal`, `/scan-context`, `/lfg` skill dirs — **all ABSENT** (L2/CMP4/L5 real). ✅
- `session-end.sh` Stop hook — **ABSENT** (C10/CMP5 host real). ✅
- 26 skill dirs, 23 agent files on disk — matches the roster claims. ✅

So the draft does **not** invent absences. Every move I spot-checked targets a verifiable gap. The
phantom-rebuild charge (attack vector 3) therefore **largely fails** — and I say so plainly below. The
real attack surface is **proportionality and P0-inflation**, not phantoms.

---

## VERDICT: OVER-AMBITIOUS-IN-PLACES

Not kitchen-sink — the draft is disciplined where it counts: it honors every killlist/F UPHELD rejection
(I checked all nine; none are resurrected), it carries the Honest-Cuts section with named failure modes,
and its individual moves are real gaps with real citations. But it is **over-ambitious in its
sequencing**: it tags **32 of ~45 moves P0** ("ship first"), which is not a floor — it is a program. A
P0 set that large is indistinguishable from "everything is urgent," and it directly contradicts the
*more-disciplined sibling synthesis in the same audit* (`MASTER-FINDINGS.md`), which collapses ~30 gaps
onto **6 structural moves** and states the governing thesis: *"V2 should end with fewer files and more
wiring, not more features."* The ambition draft re-expands those 6 consolidations back into ~45 named
deliverables. That is the over-correction: the charter retired *minimalism as a virtue*, but it did not
retire *consolidation as a design technique* — and the draft treats the two as the same thing.

Below: the must-fixes (where rigor or proportionality genuinely breaks), the should-fixes (real but
lower-severity), and considers.

---

## MUST-FIX

### MF-1. The P0 set is inflated to the point of meaninglessness — 32 of ~45 moves are "ship first."
**Proportionality, severe.** A floor you can switch autonomy on behind should be the *smallest set of
deterministic guards that makes the loop safe*. The draft's own build order (Phase 0) lists **F1, F2,
F3, F4, F5, F6, F7, F8, F9, C1, C13/P10** as Phase-0 P0 — eleven items — and then Phase 1/1.5 adds
**L2, L3, L4, L5, CMP1, CMP2, CMP3, CMP4, C6, C7** as more P0, and Pillar 5 adds **P1, P2, P3, P4, P9**
as P0. That is ~32 P0 moves across five pillars. The §9 golden rule is a per-constraint test; there is
no equivalent discipline applied to the *priority tier itself*. Compare the disciplined sibling:
`MASTER-FINDINGS.md` §B reaches the same gaps via **6 consolidating moves** and explicitly warns the
harness is "mechanism-rich and wiring-poor… fewer files and more wiring, not more features."

The failure mode this inflation creates is concrete and charter-relevant: **a 32-item P0 floor cannot
ship before the first trigger, so either the floor is not actually the precondition the draft claims it
is, or the first trigger is months away.** Either way the headline deliverable (L1, the bug→PR front
door — the entire point of the charter) is gated behind a wall the draft itself made too tall. *Fix:*
re-tier. The true **deterministic safety floor** that L1 cannot fire without is small and nameable: **F1
(destructive block), F2 (credential pre-flight), F6 (unforgeable CI verdict), F9 (disable-model-
invocation on side-effect skills), F7 (bounded-loop/REJECT)**. F5 (trifecta gate) is P0 *only for the
Slack/Linear summon path* (Fork F3 surfaces this); the GitHub-label trigger does not add an untrusted-
content leg, so F5 is not a blocker for the first trigger. F3/F4 (egress) are explicitly Fork-F4-gated on
"is local unattended even first-class." Demote everything that is not literally between "agent finishes"
and "merges to main" out of P0.

### MF-2. F3/F4 (egress firewall + migration-credential) are tagged P0 while the draft's own Fork F4 says they may not be needed at all.
**Rigor contradiction.** F3 is tagged "P0/P1 — after one bounded check." F4 is tagged "P0 — resolve
now." But **Fork F4** (line 216) states: *"Cloud `/schedule` already runs restricted-network laptop-
closed. If cloud is the primary path, F3's local egress firewall + F2's local credential pre-flight
become secondary hardening… this single fork re-prioritizes a third of the floor."* You cannot tag a
move **P0 — resolve now** and simultaneously flag that an unanswered fork may demote it to secondary.
That is the over-ambition tell: the priority was assigned by *threat severity* (correct that the threat
is real) rather than by *whether this path is even in the first autonomy cut* (the actual sequencing
question). The killlist evidence (scale-bias #16, C-deferred #5) is unambiguous that the egress gap is
**the local `/queue` path, because cloud already has restricted network** — which means egress is P0
*only if local unattended ships first*, and that is exactly Fork F4. *Fix:* re-tag F3/F4 as **GATED on
Fork F4** (flip-trigger: local unattended `/queue` is chosen as a first-class autonomy surface). Until
that fork resolves, they are not P0.

### MF-3. C13 and CMP6 and P10 each independently re-audit `model:` fields — three moves, one job.
**Proportionality / duplication.** C13 = "Re-audit the `model:` fields of every reasoning sub-agent on
Opus 4.8" (P0). P10 = "re-audit every `model:` field on Opus 4.8 (this is C13's distribution face)" (P1).
CMP6 = "turn each §9 judgment into a behavioral probe… run on every model bump" (P1) — which *is* the
recurring engine that C13's one-time pass should fold into. The draft even self-flags the overlap
("this is C13's distribution face") but keeps three move IDs. This is precisely the consolidation the
killlist *upholds*: F-rejected #6 and scale-bias #62 both say the collapse-23-agents reflex is dead **but
the model-pin re-audit underneath it is the single thing that elevates** — i.e. it is *one* elevated
mechanism, not three. *Fix:* make C13 the one-time pass, make CMP6 the recurring probe-suite that
*subsumes* C13 on every model bump (C13 becomes "run CMP6's probe suite once, now"), and delete the
re-audit clause from P10 (P10 is a packaging move; it should *reference* C13/CMP6, not re-state the work).
Three P0/P1 line-items become one P0 + one P1.

### MF-4. The seven-failure-mode guard battery is buried inside L5 as a single clause, not costed as the ~7 deliverables it is.
**Rigor / hidden scope.** L5 ("the `/lfg` orchestrator") is tagged a single **P0** move, but its
mechanism paragraph contains: a cross-skill reference-integrity CI check, a skill-cache/restart rule,
encoding-normalization, an agent-stall watchdog, plus context-drift / non-determinism / compound-timing
checks — **seven distinct guards**, each a real build. The draft elsewhere (correctly) breaks the floor
into F1–F9; here it compresses a comparable amount of work into one move's prose. This understates the
true P0 surface (making MF-1 *worse* than the 32-count suggests) and hides sequencing risk: the
reference-integrity CI check is itself a precondition (the draft notes "we already carry phantom refs"),
so it should be visible as its own line, not a sub-clause. *Fix:* either pull the reference-integrity CI
check out as its own move (it pairs naturally with CMP4's fiction-scan and P6's manifest), or explicitly
mark L5 as "1 orchestrator + 7 guards = 8 deliverables" so the P0 budget is honest.

### MF-5. "Failure prevented" is satisfied loop-internally for several moves — the §9 test is being graded on a curve.
**Rigor.** §9's golden rule is "name a failure mode the constraint prevents." Several moves name a
failure that *only exists because another P0 move was assumed to exist* — the prevention is circular
within the autonomy program, not anchored to a ground-truth incident or a current-state defect. Examples:
- **L3 (verifier-rung taxonomy):** "failure prevented = trust-laundering — wiring a rung-2 grader and
  extending it rung-4 trust." That failure only exists once L2's grader exists. L3 is *doctrine about
  L2*, not an independent move. It is real and good, but tagging it a standalone **P0** double-counts.
- **C7 (autonomy gate verifies the spec, not `.cr-ok`):** the failure ("merging on 'review ran'") is the
  *same* failure F6 prevents, re-described at the spec layer. C7 is a *configuration of F6+C6*, not a
  third gate.
- **CMP3 (effectiveness-metrics ledger, P0):** its named failure is "you cannot run a self-improving loop
  on vibes" — but the self-improving loop is itself downstream. A metrics ledger over a pipeline that has
  not yet produced autonomous PRs is the **same shape** as the STILL-GATED "outcome tracking" the draft
  correctly defers (it even says so: "Distinct from outcome/impact tracking, STILL-GATED"). The
  distinction (curated vs live volume) is real for C4's *recall* calibration but thin for *first-pass-
  approval-rate*, which needs real PRs. CMP3 is **P0-overtagged**; first-pass-approval has no traffic to
  measure on day 0.
*Fix:* demote L3 to "doctrine attached to L2," fold C7 into "F6+C6 configuration," and re-tag CMP3 as
P1-with-a-volume-flip-trigger for the volume-dependent metrics (keep only the day-0-measurable fields,
e.g. review-cycle-count, as P0). Each is a real idea; none is an independent P0.

### MF-6. CMP4's auto-PR repair worker is tagged P0-for-detection but the draft's own Fork F7 hasn't decided how aggressive it is.
**Rigor / premature P0.** CMP4 ("/scan-context bidirectional drift") is **P0**, and P9 escalates it to "a
repair worker opening scoped fix PRs." But **Fork F7** (line 222) is explicitly open: *"does a failed
probe auto-revert the removal or only flag NEEDS-HUMAN? … This is the line between 'self-correcting' and
'self-modifying.'"* And the killlist that *authorizes* this (scale-bias #8, basis-canon-not-canon) is
careful: *"the worker opens a PR gated by `/cr` + human merge; only honest residual = scope it away from
guard files."* The **detection** half (scan for stale/fiction refs) is legitimately P0 and cheap. The
**repair-worker** half rides on an unresolved fork about autonomy aggressiveness on the harness's *own
canon*. The draft does split these (P9: "P0 for detection; P1 for repair-worker") — but CMP4 itself does
not carry that split and reads as one P0 move that "proposes its own fixes (gated)." *Fix:* make CMP4 =
detection-only-P0 explicitly, and route every "proposes/repairs" clause through P9's P1-gated worker so
the Fork-F7 dependency is visible at the move level, not just in the platform pillar.

---

## SHOULD-FIX

### SF-1. The draft re-expands MASTER-FINDINGS' "ONE Stop/PostToolUse hook surface" into 3-4 moves.
`MASTER-FINDINGS.md` MOVE 1 is explicitly "**Build the surface once; treat as many payloads, not many
features**" — `session-end.sh` hosts (a) the verification gate, (b) memory write-back, (c) retry-ceiling
counter, (d) render gate, (e) stop signal. The ambition draft spreads these across **C10** (evidence
bundle, "host: session-end.sh"), **CMP5** (session-end capture, "also the host for C10's evidence-bundle
hook — same Stop-hook surface"), and references the same hook from F7. The draft *notices* the shared
host ("same Stop-hook surface") but still presents them as separate moves with separate tags. This is not
wrong, but it loses the single most useful framing in the entire audit: one hook, many payloads. *Fix:*
add an explicit "shared Stop/PostToolUse hook surface" anchor move that C10/CMP5/F7 hang off, mirroring
MASTER-FINDINGS MOVE 1. Reduces apparent move-count and clarifies sequencing (build the hook once).

### SF-2. C3 is a near-verbatim restatement of F7 — the draft admits it but keeps both as moves.
C3 is parenthetically "(The Craft-side specification of F7's REJECT classification — same deterministic
triggers, owned jointly with the Floor.)" When a move's own header says it is the same thing as another
move "owned jointly," it should be a *cross-reference*, not a second numbered deliverable. Same critique,
lower severity, as MF-5's C7. *Fix:* fold C3 into F7 as "F7, surfaced inside `/cr`," delete the C3 ID.

### SF-3. C1 and F6 are explicitly "same plumbing, owned jointly" — two P0 IDs for one CI job.
C1 ("verdict as GitHub artifact + CI gate") and F6 ("CI re-verifies `.cr-ok` on the SHA") are described
as "the PR-facing half of F6 — same plumbing, owned jointly." This is genuinely one CI workstream
(parse sentinel, match SHA, require green, post verdict to PR). Keeping two P0 IDs inflates the count and
risks two teams/sessions building overlapping CI jobs. *Fix:* one move ("the unforgeable, visible
verdict gate") with two faces (CI-enforcement + PR-surface). The draft is 90% there; finish the merge.

### SF-4. P10's "carry-forward 23 agents + 26 skills as portable roles" needs a phantom-prune gate, or it ships drift.
P10 ships "the 23-agent roster + 26-skill set" into the plugin. But CANONICAL §6 lists **phantom refs**
(`learned-patterns.md`, `@benchmark-runner`, `/scan-context`, etc.) and the skill set includes a
**`dep-update` empty stub** (§3b: "disk is an empty stub, no SKILL.md") and **two duplicate skills**
(`supabase-postgres-best-practices`, `tdd` appear twice). Carrying the roster forward *as-is* packages
the rot. The draft's P5/P6/CMP4 do address dedup and drift, but P10 should *explicitly depend on a
phantom-prune + dedup pass completing first*, or the very first plugin publish ships an empty
`dep-update` and a duplicated `/tdd`. *Fix:* add "gated on CMP4 fiction-scan + P5 dedup" to P10.

### SF-5. C5 ("governance-corpus lens") and CMP2 ("finding→enforcement ratchet") overlap at the lens-criterion boundary.
The draft says CMP2 "composes with C5 (a generated lens criterion *is* an enforcement artifact)" and C5
"composes with CMP2." This bidirectional "composes with" between two P0 moves is a sign the boundary is
soft: is a new governance-lens criterion a C5 deliverable or a CMP2 output? Left ambiguous, both moves
will claim it. *Fix:* state the ownership crisply — C5 builds the *initial* governance lens from the
existing corpus; CMP2 is the *mechanism that adds new criteria to that lens* when a finding crosses ≥3.
One is the bootstrap, one is the ratchet.

### SF-6. "Property-based testing" (C11) installs a dependency the user must approve — correctly flagged, but tagged P1 ahead of the fork resolving.
C11 is tagged **P1** and says "ask before installing" / "the install is a fork (Fork F6)." A move whose
core mechanism (`fast-check`) is blocked on an unresolved dependency-approval fork should not carry a
firm P1 tag — it should be **GATED on Fork F6**, with a P1 *target* once approved. Minor, but it is the
same priority-vs-fork inconsistency as MF-2, lower stakes. *Fix:* re-tag "GATED (Fork F6) → P1 on
approval."

---

## CONSIDER

### C-1. The five-pillar cut is clean to teach but creates cross-pillar ownership seams that inflate the count.
The draft's own "Why these five" note lists three mechanisms that "span" pillars (the safety floor spans
autonomy+platform; the compounding engine spans craft+platform; the keystone CI gate spans
autonomy/craft/floor). Every span is resolved by "owned once in X, referenced from Y" — which is correct,
but each reference tends to materialize as its own move ID (F6↔C1, C3↔F7, C7↔F6+C6, C13↔P10↔CMP6,
C5↔CMP2). The pillar structure is pedagogically strong; consider whether a flatter "floor / loop /
everything-that-gets-better-over-time" cut would have produced fewer phantom cross-references.

### C-2. The draft never states a P0 *count budget* or a "smallest floor that lets L1 fire" set.
The single most useful addition would be one sentence: "the minimal floor L1 cannot fire without is
{F1, F2, F6, F7, F9}; everything else is sequenced after the first trigger proves the loop." That sentence
would resolve MF-1, MF-2, and MF-5 at once and convert the draft from "32 P0 moves" to "5-move floor +
a sequenced program." The build-order section gestures at this ("no trigger fires until the floor it
rides on is wired") but then lists ~11 Phase-0 P0 items, undercutting the discipline.

### C-3. Honest-Cuts section is strong; the one gap is it never cuts anything *from its own roster*.
Every UPHELD-CUT and STILL-GATED item is something *the sources proposed* (browser-mutation, microVM,
toolshed, paying-stranger, etc.). That is correct adversarial hygiene against the corpus. But a roster of
45 self-generated moves with **zero self-cuts** is itself a mild tell. The strongest version of this
document would carry a short "moves we considered for our own roster and demoted" list — e.g. "L3, C3,
C7 demoted to clauses of L2/F7/F6." If MF-3/MF-5/SF-2/SF-3 are accepted, that list writes itself.

---

## Attack-vector scorecard (the five questions I was sent to answer)

1. **Proportionate to what 37 sources teach, or inflated?** *Individually* proportionate (every move maps
   to a source + a real gap). *In aggregate* inflated at the **priority** layer: 32 P0 moves vs. the
   sibling synthesis's 6 consolidating moves. **MF-1, MF-3, MF-4, MF-5, SF-1, SF-2, SF-3.**
2. **Passes §9 golden rule (named failure mode)?** Yes for the floor moves and the keystone. **Partially
   for loop-internal moves** whose prevented failure only exists because another P0 move is assumed
   (L3, C7, CMP3). **MF-5.**
3. **Any PHANTOM (already world-class per killlist/E)?** **No** — I disk-verified the seven load-bearing
   absences (block-dangerous-bash, disable-model-invocation, .cr-ok-in-CI, data-testid, /goal,
   /scan-context, session-end.sh) and all are genuinely absent. The phantom charge **fails**. The draft
   correctly leaves the four killlist/E TRULY-WORLD-CLASS items (guard-file lockout, safety doctrine,
   §9-as-doctrine, the corrected CONTEXT.md/ARCHITECTURE.md false-absence) untouched.
4. **Any rebuild of a killlist/F UPHELD rejection?** **No.** Checked all nine F items: no-shared-context
   reviewer (C2 correctly does shared-canon/isolated-solution), collapse-23-agents (P10 explicitly keeps
   the roster, "collapse reflex is dead"), 200-line diet (P2 keeps the no-trigger safety floor in tier-1
   regardless of length), model-confidence auto-merge (LOOP-7/A6 is deterministic; confidence-score CUT),
   learned-patterns.md (CMP1 resurrects the read-path, file stays phantom). The draft is disciplined here.
5. **UPHELD-CUT wrongly elevated, or a genuine cut missing?** No UPHELD-CUT is wrongly elevated. One
   *near-miss*: CMP4/P9's repair-worker rides an unresolved aggressiveness fork (MF-6) — not a wrongly-
   elevated cut, but a P0 tag that outruns its own open decision. The genuine *missing* cut is **internal**:
   the draft cuts from the corpus but never from its own roster (C-3).

**Bottom line:** the vision is rigorous, honestly-cut against the corpus, and phantom-free. It is
**over-ambitious in priority-tiering, not in content** — it converts a 6-move consolidation into a
45-move/32-P0 program and lets threat-severity (not first-cut-membership) set priority. Fix the P0
inflation (MF-1, C-2), collapse the ~6 self-referential duplicate moves (MF-3, MF-5, SF-2, SF-3), and
gate the fork-dependent moves honestly (MF-2, MF-6, SF-6). Do that and OVER-AMBITIOUS-IN-PLACES becomes
WORLD-CLASS-AND-DISCIPLINED.
