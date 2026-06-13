# Adversarial Check — `gaps-risks.md`

> Doer≠checker. A different agent wrote `../gaps-risks.md`; this is the attack pass, not a validation.
> Charge: honesty + completeness — is each gap real or self-serving hedging; what did it MISS; are risks
> ranked by true blast-radius; is the harvest method accurately described; does it over-claim. Every finding
> below was re-checked against disk this session (not inherited from the prompt or the artifact's framing).

**Re-verified on disk before attacking (so this check isn't itself a phantom):** 26 skills, 23 agents, 5 hook
files (`block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`, `session-start.sh`,
`worktree-create.sh`); `.claude/rules/`, `.claude-plugin/`, `block-dangerous-bash.sh`, `session-end.sh`,
`enforce-scope.sh` ABSENT; Stop hook at `settings.json:191` plays `Glass.aiff` only; `.cr-ok` at `.gitignore:58`;
all eight named sibling artifacts + six grounding files present; `capability-facts.md:13-16/18-20/39-46` and
`CANONICAL §9` (lines 325–346) read as cited. **The artifact's factual substrate is sound** — its citations
are real and accurate. The attack therefore lands on *completeness*, *framing*, and *two citation slips*, not
on fabrication.

---

## VERDICT: SOUND-WITH-CORRECTIONS

The artifact is the most honest of the v2 tree's documents and its gaps are overwhelmingly **real, not
self-serving**. It correctly refuses to claim verification it didn't do, ranks force-continue at the top (the
genuinely load-bearing unknown), and the harvest-method description is accurate and self-evidencing. It is
**not UNSOUND** — nothing in it is fabricated or backwards. But it falls short of "the harshest reader owes
itself" on three counts that a world-class gaps-doc would have covered: it (1) **adopts a checker-voice
"verified this session" frame it cannot honor** while simultaneously scolding the vision for exactly that
move; (2) **never reconciles gaps across its own sibling design artifacts** despite claiming to be "the
checker's artifact for the *whole* V2 design effort"; and (3) **misses several structural gaps** a complete
effort would have named (file-budget accounting honesty, the `/init` materializer's own injection surface, the
absence of any cost ceiling on the compounding loop's *own* nightly runs, and the doer≠checker independence of
the design effort itself). Fix the MUST-FIX items and it is SOUND.

---

## MUST-FIX

### MF-1 — Checker-voice over-claim: it scolds the vision for the exact frame it adopts itself

The header (lines 3, 8) declares this "the *checker's* artifact" citing "on-disk re-verification done **this
session**," and the closing (lines 184, 269–270) says "this checker re-ran the on-disk verification" and
"on-disk ground truth re-verified this session." **But this file lives in the `design/v2/` tree as a sibling
of `file-tree.md`, `github-usage.md`, `memory-model.md` — it is a design-effort artifact, and the same
"re-verified on disk this session" boilerplate appears verbatim in all three siblings** (confirmed: file-tree.md
and github-usage.md carry the identical claim). So either every v2 artifact re-ran the verification (possible,
but then it isn't *this checker's* distinguishing act), or the phrase is house boilerplate the document inherited
and dressed up as its own forensic work.

This matters because **Gap #1's entire thesis is "honesty about an unverified assumption is not the same as
verifying it" (line 44)** — and the document then turns around and asserts "this checker re-ran the verification"
as a credential. A gaps-doc that polices the vision's epistemic honesty cannot itself blur reasoned-from-boilerplate
with verified-this-session. **Fix:** state plainly what *this* document re-checked vs. inherited, or drop the
"this checker re-ran" framing and own that it is a design artifact reasoning over the same ground truth — not an
independent verification pass. (The irony is load-bearing: the one document whose job is honest assessment is the
one that should never reach for unearned forensic authority.)

### MF-2 — It never reconciles gaps across its own sibling design artifacts (incompleteness against its own scope)

The artifact claims to be "the checker's artifact for the **whole V2 design effort**" (line 3). But it cites
**only `VISION.md`** as the design surface and never references `file-tree.md`, `github-usage.md`, or
`memory-model.md` — its three peers in the same directory (confirmed: zero matches for those slugs in
gaps-risks.md). A gaps-doc scoped to "the whole effort" that examines one of four design artifacts has audited
a quarter of its stated surface.

This is not pedantic — **`file-tree.md` surfaces a live, named gap the gaps-doc omits**: its budget table
opens with "the honest accounting — forced by `RECONCILIATION §A`, where **two of three Phase-3 artifacts
drifted into a file INCREASE while reporting a favorable proxy**." That is a documented case of a V2 design
artifact mis-reporting its own metric — precisely the "over-claim" class this gaps-doc exists to catch — and it
is nowhere in the gaps list. **Fix:** either narrow the scope claim to "gaps in the VISION," or add a pass over
the sibling artifacts and fold in at least the budget-proxy-drift gap.

### MF-3 — The design effort's OWN doer≠checker independence is never questioned

The charter mandates doer≠checker, and Gap #4 correctly attacks the *corpus's* selection bias. But the artifact
never turns that lens on **the design effort itself**: VISION.md states it was "authored by the main loop … +
both adversarial checks folded in" — i.e., the same orchestrating loop wrote the draft, ran the checks, and
folded them back. The adversarial checks (`VISION-CHECK-*`) were spawned by the same effort that produced the
thing they checked. Gap #4 names "adversarial checks verify *coherence with the corpus*, not *coverage of the
field*" (line 87) — a sharp point — but stops one step short of the structurally identical problem one level up:
**the checks verify coherence-with-the-draft, and were authored inside the same loop as the draft.** A
world-class gaps-doc covering "the whole design effort" owes a line on whether the effort's own internal checks
were independent enough to catch a shared blind spot, or whether (like the corpus) they over-sample agreement.
**Fix:** add this as an explicit gap — the design effort's verification was loop-internal, not adversarially
external, and that is the same selection-bias risk Gap #4 raises about the corpus.

---

## SHOULD-FIX

### SF-1 — Two citation slips (one off-by-one, one inherited-and-unowned)

- **Gap #6 (line 112)** cites "§9 line 328" for "re-audit due on model update → now Opus 4.8." Line **328**
  reads "Canon's own keep/replace judgments (made against **Sonnet 4.6**;"; the "re-audit due on model update
  → now Opus 4.8" text is on line **329**. Off-by-one. Minor, but a document that polices citation rigor must
  hit its own line numbers.
- **Gap #5 (line 99)** leans on ".env.local points at production Supabase with the service-role key" and
  attributes it to "`capability-facts` and F2." The substantive claim is **true** (corroborated by CLAUDE.md +
  auto-memory). But the artifact inherits F5's "settings line 14 (`.env.local` → prod)" provenance from the
  vision, and `settings.json:14` is in fact **blank** on disk this session. The artifact doesn't cite line 14
  directly, so this is the vision's slip not the gaps-doc's — but a checker re-verifying "at point of use"
  (its own stated discipline, line 188) should have caught that the inherited line-number is stale and flagged
  it rather than passed it through.

### SF-2 — Several "gaps" are deferred-build items dressed as research omissions (partial self-serving framing)

Gaps #1 (probes), #5 (red-team), #6 (§9 baseline), and the #7 sub-bullets (F6-against-real-CI, kill-switch,
recovery semantics) are real — but they are not things the *research* "left out"; they are things the *build*
hasn't done yet, which at the design stage is partly expected. The artifact mostly handles this honestly (it
says "deferred to the build" for the probe), but the **framing device — "What the research LEFT OUT even though
a world-class effort should have covered it" — over-charges several items.** A probe that the vision *explicitly
names as a Phase-0 gate with a fallback* is not "left out"; it is *scheduled*. The honest version distinguishes
**(a) genuine blind spots the effort never saw** (corpus-bias #4, the cost model #2, the operator-test #3 — these
are real omissions) from **(b) known-open items the vision already flagged and sequenced** (#1, #6, the F6/kill-
switch/recovery bullets — these are deferred, not missed). Conflating them inflates the gap count and lets a
sequenced-decision wear an omission costume. **Fix:** split the section into "genuine omissions" vs. "named-but-
unexecuted," so the reader can tell a blind spot from a backlog item.

### SF-3 — Risk ranking is defensible but R2–R5 are under-differentiated by blast radius

R1 (force-continue) is correctly CRITICAL and correctly first. But **R2 through R5 are all tagged some flavor
of "HIGH / MEDIUM-HIGH"** with the differentiation buried in prose, and the ranking conflates two different axes:
*blast radius if it breaks* vs. *how mitigated it already is*. R2 (screenshot-not-compellable) is tagged "HIGH,
already mitigated" — but a fully-mitigated risk does not belong above an unmitigated one in a blast-radius
ranking; it belongs in a "residual" tier. R5 (auto-approval on a $30k tool) has arguably the **highest
real-world blast radius** of the non-R1 risks (cross-tenant PII / client-facing pricing error shipping
unattended) yet sits last. The artifact's own Gap #3 calls the auto-approval threshold "the exact lever that
decides what ships without a human on a $30k-client tool" — that argues R5 should rank second, not fifth.
**Fix:** separate the ranking axis (blast radius) from the mitigation status (open vs. bounded vs. residual),
and re-order so R5 sits where its stakes put it.

---

## CONSIDER

### C-1 — Missed: the `/init` materializer and P2 template are themselves an injection/supply-chain surface

Gap #5 red-teams the trifecta gate, F3 egress, and the L1 free-text path — good. But it misses that **P2's
`/init` materializer writes `permissions`/`settings.local.json`/`managed-settings.json` content from a committed
canonical template** into every new repo. A poisoned or drifted template is a one-shot way to ship a weakened
permission baseline into the entire fleet — a higher-leverage injection target than any single poisoned issue,
because it lands *below* the model on every repo at once. A world-class red-team gap would name the distribution
template as its own attack surface, not only the runtime triggers.

### C-2 — Missed: no cost ceiling on the COMPOUNDING loop's own nightly runs (Gap #2 stops at the fleet)

Gap #2 prices the *action* fleet (bug→PR across 5 repos) but never prices the **compounding engine's own
recurring cost**: CMP4 (`/scan-context`), CMP6 (the §9 probe suite on every model bump), P9 (cross-repo context
loop), CMP3 (the scheduled metrics report) all run on `/schedule` *in addition to* the action fleet. The ETH
20–23% context-cost penalty the artifact cites (line 56) applies to these maintenance loops too. A complete cost
gap covers the *overhead* loops, not just the value-producing ones — the harness can be economically viable on
output and still bleed on self-maintenance.

### C-3 — Missed: the harvest-from-disk method's own failure mode is never named

The harvest-method section (the artifact's strongest, most self-evidencing part) describes the mechanism
accurately and the L7/F7 inheritance is a genuine insight. But per the §9 golden rule the artifact itself
invokes ("name the failure mode the constraint prevents"), **the method's own failure mode is unstated:**
disk-persistence makes a partial run *resumable* but not *correct* — a slug can be written to disk in a
half-complete or wrong state, and "the file exists" is the completion signal, so the resumable loop will
**harvest a bad artifact as done** and never re-run it. The method trades total-loss-on-interruption for
silent-acceptance-of-a-corrupt-slug. A world-class write-up of a method it's promoting to a *first-class V2
principle* (L7/F7) would name that the existence-check is not a quality-check — otherwise the resumability
property quietly launders incomplete work as finished.

### C-4 — The "global kill switch absent" gap (#7) is correct and arguably under-ranked

Verified: VISION.md has no global halt-all control (F8 is per-defect-class, F7 is per-loop, Fork F9 is paging
not halt). The artifact names this correctly but buries it in the #7 catch-all "MEDIUM-to-LOW" bullets. At the
charter's stated scale (5+ repos, fleets running laptop-closed), **"no way to stop the entire fleet right now"
is plausibly a higher-severity gap than the §9 baseline (#6) or the platform-maintenance cost (#7 last bullet).**
Consider promoting it to a named risk (R6) rather than a sub-bullet.

---

## What the artifact got RIGHT (so the verdict isn't read as dismissive)

- **Every factual citation checks out on disk** — the 5 absences, the Stop-hook-sound fact, `.cr-ok` line,
  the capability-facts line ranges, the §9 reproduction, the ETH and dogfood citations. This is rare and worth
  saying: the artifact did not fabricate a single ground-truth claim I could find.
- **Force-continue ranked first is correct.** It is the genuinely load-bearing unknown; the vision gates the
  spine on it; the ranking is honest.
- **The harvest-method → L7/F7 mapping is a real insight**, not a stretch — the "persist-before-return"
  property genuinely is the runtime form of the observability and resumable-loop principles, and the
  "survived two session-limit interruptions" self-evidence is accurate (the named slugs are all on disk).
- **Gap #4 (corpus selection bias) is the sharpest finding** — "adversarial checks verify coherence with the
  corpus, not coverage of the field" is exactly the kind of structural blind spot a coherence check cannot
  catch, and naming it is the document earning its honest-assessment charter.
- It correctly **does not over-claim that any probe was run** — Gap #1, R1, and R2 are scrupulous about
  "reasoned, not tested."

---

## Bottom line

SOUND-WITH-CORRECTIONS. The substrate is honest and accurate; the gaps are real. It loses "SOUND" on three
completeness/framing failures a harshest-reader pass must flag: the checker-voice over-claim it elsewhere
condemns (MF-1), the un-audited three-quarters of its own design surface (MF-2), and the un-questioned
independence of the design effort's own checks (MF-3). Resolve those and the SHOULD-FIX citation/ranking items,
and this becomes the strongest document in the v2 tree.
