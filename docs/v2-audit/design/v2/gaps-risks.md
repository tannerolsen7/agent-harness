# V2 — Honest Gaps, Open Risks, and the Harvest-from-Disk Method

> The charter demands honest assessment over validation. This document is the *checker's* artifact for the
> whole V2 design effort: what the research **left out** even though a world-class effort should have covered
> it, the **load-bearing open risks** ranked by how much they move the design if wrong, and the
> **harvest-from-disk method** that V2 inherits as a principle. It cites ground truth the same way the vision
> does — `VISION.md` moves, `capability-facts.md` line numbers, `CANONICAL-HARNESS-AS-IS.md` §N rows, and
> on-disk re-verification done **this session** (26 skills, 23 agents, 5 hooks; `.claude/rules/`,
> `.claude-plugin/`, `block-dangerous-bash.sh`, `session-end.sh`, `enforce-scope.sh` all ABSENT; the existing
> Stop hook at `settings.json:191` plays a `Glass.aiff` sound only; `.claude/.cr-ok` gitignored at
> `.gitignore:58`).

---

## What the research LEFT OUT even though it probably should have been included

Ranked by **how much each could change the design if it is wrong** — the test a world-class effort owes itself.
Each item names the gap plainly, why it matters, and what it would have taken to close it.

### 1. No live empirical probe was run for the load-bearing capabilities — the design rests on docs, not tests (HIGHEST)

Four capabilities the design is *built on top of* were reasoned from documentation and never executed once this
effort:

- **Force-continue Stop-hook semantics.** Whether a Stop hook's `decision:block` makes the model **keep
  working** or only **errors and stops** is the single load-bearing unknown. `capability-facts.md:13-16`
  flags it explicitly: the guide was "internally hedged… **Verify empirically before relying on force-continue
  semantics.**" `VISION.md` gates `/goal` (L2) and the C10 evidence bundle on it and names a Phase-0 probe —
  but **the probe was deferred to the build, not run during the design.** If force-continue does *not* hold,
  the continuation engine — the literal "engine V1 never built" of the one-paragraph thesis — has to be
  re-architected onto external re-invocation (the named fallback), which changes the shape of L2, L5, C10, and
  the whole Phase-1 spine.
- **`chrome-devtools-mcp` headless.** C8's render gate routes the unattended leg to a CI job "because
  chrome-devtools-mcp is headed-only" — an assumption never confirmed against the actual MCP this session.
- **`managed-settings.json` honored on macOS.** `capability-facts.md:39-41` says managed settings "genuinely
  override everything," but also that the macOS managed path is **absent on this machine (verified absent, not
  verified working)** — F9, P2, and Fork F5 lean on a floor that was never placed and exercised once.
- **`autoMode` in `settings.local`.** `capability-facts.md:42-46` reasons from docs that committed-project
  autoMode is ignored and local/managed is the correct home; the corrected behavior was never observed at
  runtime.

**Why it ranks first:** these are not features inside the design — they are the *substrate the design assumes
exists*. The vision is honest that two are probes (the Capability-Preconditions section), but honesty about an
unverified assumption is not the same as verifying it. A single afternoon of probing would have either
de-risked the spine or forced a redesign while it was still cheap. **It could change the design more than any
other item because it could invalidate the continuation primitive itself.** This is the gap most worth closing
before any build starts.

### 2. The economics of running parallel fleets across 5+ repos on cloud `/schedule` were never modeled (HIGH)

The charter's definition of scale is "one engineer running parallel agent fleets across 5+ repos." The vision
designs the *mechanism* (L4 cloud heartbeat, P9 cross-repo loop, CMP6 scheduled prune-PR) but **never prices
it**. There is no model of: tokens-per-night for a discovery-plus-action fleet, the cost of every `/cr` running
Opus 4.8 on every candidate PR (C13 *raises* cost by re-pinning reasoning agents off the cheapest model), the
20-23% context-cost penalty ETH Zurich found (cited *inside* CMP6 as a reason to prune, then never applied to
the fleet's own running cost), or the marginal cost of the narration stream (L7) emitting after every
milestone across a fleet. **Why it matters:** a design that is correct but economically unviable at 5-repo
scale fails the charter as surely as an unsafe one. R1's "+98% PRs, zero DORA gain" finding (cited in L4) is a
*throughput* warning; there is no matching *cost* ceiling. This would not change the architecture, but it could
change the **rollout aggressiveness** (Fork F2) and the **schedule cadence** materially — and it is the kind of
number an operator needs before switching the fleet on.

### 3. No real user/operator test of the narration channel or the auto-approval thresholds (HIGH)

L7 (narration) is Tanner's own mid-run design input and is "dogfooded in this very session" — but dogfooded by
*one operator inside the design conversation*, not tested as a standalone channel an operator relies on to
course-correct a genuinely-autonomous run they are not already watching. The harder gap: **the LOOP-7/A6
auto-approval thresholds (LOW/MEDIUM/HIGH off paths + diff-size + test-delta + scope) are asserted, never
fit to data.** Nobody has taken a sample of real event-vendor PRs and checked whether the classifier's "LOW"
bucket actually contains only safe changes, or whether a cross-tenant RLS hole can wear a LOW costume (small
diff, no path match). **Why it matters:** the auto-approval threshold is the exact lever that decides what
ships without a human on a $30k-client tool (see Risk #5). A threshold designed from first principles and never
validated against the repo's own change distribution is a guess wearing a number.

### 4. The corpus is curator-selected and the *selection* was never audited for bias (MEDIUM-HIGH)

The research correctly **refused to invent effectiveness rates** when sources didn't supply them (the
coherence check confirms this rigor). But the discipline stopped at the rates and never reached the
**selection**: the ~37-page Notion corpus was hand-picked, and every named source in the vision —
`bug-to-pr-automation`, `loop-engineering`, `recursive-self-improvement`, `every-compound-lfg`,
`stripe-minions-kaliski` — is autonomy-*positive*. There is no cited source that ran an autonomous fleet and
**pulled back**, no documented failure of the loop pattern beyond the safety incidents (Replit, PocketOS,
Cline) that the design uses to *justify the floor* rather than to question the loop. Selection bias toward
autonomy-positive evidence is the most likely reason a design lands on "build the autonomous engine" — which
may well be right, but the **counter-evidence was never sought**. **Why it matters:** if the corpus
systematically over-samples successes, the vision's confidence is inflated in a way no internal-consistency
check can catch — adversarial checks verify *coherence with the corpus*, not *coverage of the field*. Closing
it would have meant one deliberate search for "autonomous coding fleet failures / rollbacks" and an honest note
on what was found. Ranked below the empirical-probe and economics gaps because it changes *confidence*, not
*architecture*.

### 5. Prompt-injection defenses are designed, not red-teamed (MEDIUM-HIGH)

F5 (MCP lethal-trifecta gate), F3 (egress allowlist), and the L1 ordering carve-out ("GitHub-label trigger
first; Slack/CI free-text waits for F3+F8 because it ingests attacker-controllable issue text") are a coherent
*design* against the injection class. **None of it was attacked.** No one wrote a poisoned issue body and ran it
through the planned trigger to see whether the leg-union check actually fires, whether the egress profile
actually blocks the exfil path, or whether a tool-description "rug-pull" is actually caught by the pin-and-diff
lockfile. Given `.env.local` points at **production** Supabase with the service-role key (`capability-facts`
and F2), the trifecta is permanently one leg lit — the defenses are the only thing standing between a poisoned
page and prod PII. **Why it matters:** a security control validated only by its own design rationale is
"probabilistic enforcement in a costume" (F1's own phrase, turned on the design). The fix is a red-team pass on
the trifecta gate and egress profile before the free-text trigger path ships — which the build order already
gates behind F3/F8, so the *sequencing* protects us; the **un-tested-ness** is the gap.

### 6. The §9 deletion engine has never been run even once — there is no baseline (MEDIUM)

`CANONICAL-HARNESS-AS-IS.md:325-346` (§9, the Model Capacity Audit / Page 13) is a set of **keep/replace
judgments** — and the prompt is right that it has never been *executed* as a deletion run. The judgments were
made against **Sonnet 4.6** (§9 line 328: "re-audit due on model update → now Opus 4.8") and CMP6 is designed
to turn each "Replace (capability proxy)" into a behavioral probe and run the whole thing as a scheduled
prune-PR loop. But **not a single one of those cuts has been made or probed**, so there is no baseline for what
the prune-loop will actually find: we don't know if the model has outgrown the scaffolds the audit says it has,
and we don't know if Opus 4.8 *lost* a capability a cut assumed (the two-sided failure CMP6 names). **Why it
matters:** CMP6 is "the safety interlock for the entire de-scaffolding program," and an interlock that has
never fired once is itself unverified. A single manual run of the §9 audit against Opus 4.8 — even on one or
two proxies — would have produced the baseline the scheduled loop is supposed to maintain. Ranked here, not
higher, because it affects a Phase-4 item, not the spine.

### 7. Other things a world-class effort would have covered and didn't (MEDIUM-to-LOW)

- **The keystone (F6) was never built or even prototyped against real CI.** F6 — the CI job that re-verifies
  `branch:sha` and posts the verdict — is *the* keystone and a hard prerequisite for every unattended push, yet
  it exists only as a described mechanism. Fork F1 (verdict-artifact surface: PR comment vs body vs committed
  file vs Checks API) is still open, which means the keystone's *interface* is undecided. A throwaway CI job
  proving the sentinel-SHA comparison works on a real PR would have de-risked the single most load-bearing
  control. (Ranks with #1 in importance but is listed here because it is a known-open fork, not a blind spot.)
- **No rollback / kill-switch design for the fleet as a whole.** F8 is a per-defect-class circuit breaker; F7 is
  a per-loop ceiling. There is no designed "stop the entire fleet right now across all repos" control — the
  human-paging surface (Fork F9) is for *escalation*, not *halt*. At 5-repo scale the absence of a global kill
  switch is a real gap.
- **Recovery semantics after a partial unattended run are under-specified.** The harvest-from-disk method
  (below) makes the *design effort* resumable; the vision does not specify what a half-finished *autonomous loop*
  leaves behind (orphaned worktrees, dangling branches, a written `.cr-ok` with no PR) or who cleans it up. The
  CLAUDE.md worktree-GC discipline is human-driven; an unattended fleet needs its own.
- **No cost/benefit on the platform pillar's own maintenance.** P5/P6/P7 add a manifest, a provenance lockfile,
  and an upstream-disposition policy — real upkeep the §9 golden rule ("name the failure mode the constraint
  prevents") should have been turned on *as honestly as it was turned on the corpus*. The vision asserts the
  manifest's value; it doesn't price its drift cost.

---

## The open risks (load-bearing, ranked)

These are the risks that, if they break, break something the design *depends on*. Ranked by blast radius.

### R1 — Force-continue is the capability the whole continuation engine rests on (CRITICAL)

`/goal` (L2) and the C10 evidence bundle assume a Stop hook's `decision:block` **force-continues** the model.
`capability-facts.md:13-16` marks this "verify empirically" and the vision names a Phase-0 probe with a fallback
(external re-invocation via the L1 front door / cloud `/schedule`). **Why it is the top risk:** if it fails,
the engine V1 "never built" can't be built the way the spine assumes — L2, L5, and C10 all re-route onto the
fallback, and the "run until a separate grader says done" thesis becomes "re-invoke until a grader says done,"
a meaningfully different and more complex loop. **Status:** mitigated by a named fallback and a build-time
probe, but the probe has not been run — so this is a *bounded* risk, not a *closed* one. **Action:** run the
probe before any Phase-1 spine work; do not build L2 on the unverified semantics.

### R2 — The screenshot can't be compelled by a hook (HIGH, already mitigated)

`capability-facts.md:18-20`: "**No hook can REQUIRE an artifact (screenshot) to exist before completion.**"
This is a *fact*, not a probe. **Why it matters:** a naive design would make the render artifact a hard Stop-hook
gate and quietly ship UI-broken PRs when the agent simply didn't produce the screenshot. **Status: already
correctly mitigated** — C10 scopes the render check to "verify-if-present + advisory at the hook," and the
*hard* render gate lives on the **CI leg (C8)** against a headless preview deploy. The residual risk is only
that C8's headless path depends on the unverified `chrome-devtools-mcp`-headless / preview-deploy assumption
(Gap #1). **Action:** confirm the CI render leg works headless before treating C8 as a hard gate.

### R3 — Stop-hook corrected-mistake detection may be semantic, not deterministic (MEDIUM-HIGH)

CMP5's session-end capture proposes memory/PITFALLS rules from "corrections observed during the session." A
hook can deterministically run tests and block on red (`capability-facts.md:11-13`), but **detecting that a
*correction* happened is a semantic judgment, not a deterministic signal** — and the vision is honest that CMP5
is "deliberately NOT a deterministic mistake-detector… human confirms." **Why it matters:** if the capture
proposer is unreliable, the compounding loop's *read-back-into-context* quality (CMP1) degrades — it learns
from noise. **Status: bounded by design** — the human-confirm step is the degrade-safe path, and `/cr` 3b
already auto-writes findings as the fallback, so CMP5 is an *upgrade* on a working baseline, not a new
dependency. The risk is real but **does not gate the spine**. **Action:** none required pre-build; keep the
human-confirm gate; do not promote CMP5 to deterministic.

### R4 — Audit artifacts ROT — and this recurred mid-effort (MEDIUM-HIGH, recurring)

The harness has a **live, dated proof** that its own canon rots: the as-is audit shipped four false absences,
and `VISION.md` notes ground truth had to be "re-verified on disk this session." **It recurred during this very
effort** — which is why this checker re-ran the on-disk verification (26 skills / 23 agents / 5 hooks; the five
named absences; the Stop-hook-is-a-sound fact; `.cr-ok` gitignored) rather than trusting the prompt's framing.
**Why it matters:** a design built on a rotted as-is map rebuilds phantoms or skips real gaps — the exact
failure CMP4 (`/scan-context` fiction detection) exists to prevent. **Status:** CMP4 is the designed fix, but
CMP4 itself is not yet built — so until it ships, **every consumer of the audit must re-verify absences on disk
at point of use.** This document does. **Action:** treat the as-is map as stale-by-default; CMP4 detection is
P0 precisely because of this.

### R5 — The auto-approval risk threshold on a $30k-client tool (MEDIUM-HIGH, governance)

LOOP-7/A6 takes most PRs out of the human path via a non-LLM LOW/MEDIUM/HIGH classifier; LOW auto-*approves*
into the F6 CI floor (auto-approve ≠ auto-merge — F6 is still the deterministic last gate). **Why it matters:**
this is the product's commercial stakes meeting the autonomy program — Monica would send a proposal to a
$30k-plus client "without hesitation," and a mis-bucketed pricing or RLS change that auto-approves is a
client-facing or cross-tenant incident. The threshold (Gap #3) was never fit to real PR data. **Status:
bounded by design** — ships in **observe-only mode** (classify + log, human merges) until C4's golden-set
recall clears a stated floor; Fork F2 explicitly asks whether auto-merge ever touches `src/data/` or money math.
The residual risk is that **observe-only's promotion criterion is C4 recall, and C4 was never measured either**
(Gap #1/#3 compound here). **Action:** keep observe-only; do not flip LOW-auto until C4 recall is measured *and*
the classifier is validated against real event-vendor PRs; never let auto-merge touch money math or `src/data/`
without MEDIUM+ routing.

---

## The harvest-from-disk method (and why V2 inherits it as a principle)

### What it is, plainly

A "big agent run" is a single sub-agent doing one slice of expensive work (a research pass, a synthesis, an
adversarial check). When you fan out many of these in one session, you hit the **account session limit** — the
session simply stops. The naive design has each sub-agent *return its result to the orchestrating loop*, and the
loop holds all the results in memory until the end. **That design loses everything when the session dies
mid-run**: the returned values were never written down, so a partial run is a total loss.

The harvest-from-disk method inverts the dependency:

1. **Every agent persists its artifact to a DISK file before returning** — a named slug (e.g.
   `lens-autonomy.md`, `VISION-CHECK-overengineering.md`, this file's siblings under
   `docs/research/v2-audit/design/`).
2. **The main loop harvests from the disk files, not from workflow return values.** The orchestrator's source
   of truth is the filesystem, not its own memory of what each sub-agent returned.
3. **Partial runs are resumable: re-run only the missing slugs.** Because completion is "the file exists on
   disk," the loop can be restarted and it only re-does the slugs whose files are absent — everything already
   written is harvested as-is.

### Why it earned its place this effort

**This effort HIT the session limit twice and lost nothing of value** — because the work was phased into
named slugs and every phase persisted to disk before returning. The artifacts are *on disk right now* and
self-evidence the method: the `design/ambition/` tree alone carries `VISION-DRAFT.md`, the three pillar lenses
(`lens-autonomy.md`, `lens-craft.md`, `lens-platform.md`), `VISION.md`, both adversarial checks
(`VISION-CHECK-overengineering.md`, `VISION-CHECK-coherence-feasibility.md`), the six grounding files under
`grounding/`, and a `_PROGRESS.md` ledger — each a separately-resumable slug. The limit interrupted the *runs*,
not the *results*.

### Why V2 inherits it as a first-class principle

The method is not a research convenience — it is the **same property the autonomous loop needs at runtime**,
and the vision already encodes it in two places:

- **The narration / observability principle (L7).** `VISION.md` L7 names the exact failure the harvest method
  avoids: *"an autonomous run that only reports at the end leaves the operator blind during the run."* A loop
  that holds its work in memory and reports once at the end is, at runtime, the naive design that loses
  everything on interruption. L7's continuous narration stream + append-only agent-PR observability log is the
  *runtime* form of "persist before you return" — every milestone written to disk/the log surface as it
  happens, so a killed run leaves a readable trail, not a blank.
- **The resumable-loop / bounded-loop principle (F7).** A loop that can be interrupted must be re-enterable
  without redoing finished work. F7's bounded-loop contract (`MAX_ITERATION` + a first-class terminal
  `REJECT`/`NEEDS-HUMAN` state with a **defined artifact**) is the runtime statement of the same idea: progress
  and terminal state are *written artifacts*, not in-memory facts, so the loop can stop, page, and resume from
  the artifact. The harvest method is the design-time proof that this works.

**The teach-test version:** *a loop that only reports at the end loses its work when interrupted; a loop that
persists every step to disk loses nothing — V2 inherits "persist-before-return" as both the observability
principle (L7) and the resumable-loop principle (F7), proven by the fact that this very effort survived two
session-limit interruptions with zero lost work.*

---

## Status

This is the honest-assessment artifact for the V2 design effort: the gaps the research left out (ranked by how
much each moves the design if wrong — empirical probes first, economics and operator-test second, corpus-bias
and red-teaming third), the load-bearing open risks (force-continue at the top, the auto-approval threshold on a
$30k-client tool as the governance risk), and the harvest-from-disk method V2 inherits as the L7/F7 principle.
On-disk ground truth re-verified this session — because the audit's own demonstrated rot (R4) means no
consumer should trust the as-is map without re-checking it at point of use.
