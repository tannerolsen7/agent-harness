# Adversarial check — Phase 5 compounding-loop (`compounding-loop.md`)

**Role:** adversarial checker (doer≠checker). I did not write the artifact. Every load-bearing claim
below was ground-truthed on disk this session (Bash/Grep/Read) — the audit rots, so nothing is taken on
faith from the doc's own re-verification block.

**Verdict: SOUND-WITH-CORRECTIONS.** The three-leg structure (write-back / read-path / measurement) is
correct; the keystone framing (measurement is the genuinely-new leg, the wiring is inherited) is the right
call; the anti-phantom discipline on `@benchmark-runner` holds; the golden-set-as-CI-fixture (not a 4th
memory store) is the correct fit to the Phase-3 model; the never-self-certify design is honored; the
two-budget accounting is *mostly* honest. I tried hard to kill a load-bearing claim and **one survived with
a required correction** (the budget-(1)=ZERO claim is false as stated, but rescuable with a one-token
frontmatter fix). Two further corrections sharpen citations. No blocker forces architectural rework.

---

## What I ground-truthed (disk, this session)

| Doc claim | Disk result | Verdict |
|---|---|---|
| `cr/SKILL.md` = 273 lines; Step 3b at line 174; sentinel write ~240-256; Step 8 evaluate /compound | 273 lines ✅; Step 3b header at **174** ✅; sentinel "Step 7" at **236-258** ✅; "Step 8 — Evaluate /compound" present ✅ | ACCURATE |
| `ci.yml` = 4 steps (tsc, eslint, test:unit), no eval lane | `npm ci` → `npx tsc --noEmit` → `npx eslint .` → `npm run test:unit`; triggers `pull_request`+`push`; no eval lane ✅ | ACCURATE |
| `integration.yml` = `workflow_dispatch`-only, secret-gated | `on: workflow_dispatch` only; gated on 3 Supabase secrets ✅ — the "expensive, not-every-PR" pattern the doc models the eval lane on is real | ACCURATE |
| `.cr-ok` + `.cr-feature-ok` gitignored (never reaches CI) | `.gitignore:57-58` literal entries ✅ | ACCURATE |
| `@benchmark-runner` / golden-set / eval store / scorer ABSENT | `find .claude docs -type d` for eval/golden/benchmark → nothing outside v2-audit ✅; `.claude/skills/cr-eval`, `scripts/score-cr-eval.sh`, `.github/workflows/cr-eval.yml` all absent ✅ | ACCURATE — anti-phantom holds |
| `.claude/rules/` ABSENT (S1 target) | `ls .claude/rules` → no such directory ✅ | ACCURATE |
| `dependency-cruiser` not a dep (L2 §4 wiring gated on it) | not in package.json; no config file ✅ | ACCURATE — the §4 L2-append is correctly gated "build when L2 lands" |
| `.claude/rituals.md` exists with `last_run`/`frequency`; lists `scan-context` weekly | exists; both fields present; lists `scan-context` weekly ✅ | ACCURATE |
| `/compound` reads `.claude/memory.md` only at line 143; no `feedback_*`/`project_*` corpus walk | line 143 `Read .claude/memory.md`; zero corpus refs ✅ — confirms RECONCILIATION §B.1 "NET-NEW step" relabel the doc inherits | ACCURATE |
| RECURRING-FINDINGS read "only by the pipeline" | main-repo readers (excl. worktrees) = `cr/SKILL.md`, `PITFALLS.md`, the file itself ✅ — `PITFALLS.md` reference is the *promotion target* mention, not an implementer read-path | ACCURATE (the half-open-read claim stands) |
| canon-locked §B: "L2 arch-test failure-rate over time = compounding metric → bridge between enforcement and compounding loop" | verbatim at canon-locked lines 63-65 ✅ | ACCURATE — §4 item 2's citation is exact |
| `_EMERGING` R-1..R-5 (self-certify, unmeasured recall, friendly audience, adversarial seed, calibration freshness) | all five present at the cited lines ✅ | ACCURATE |
| Runtime tools `CronCreate`/`loop`/`schedule` (brief's phantom-watch) NOT re-proposed | doc never proposes building them; they are platform/runtime tools (present in my deferred-tool list, absent as `.claude/skills/`) and the doc designs a *ritual + workflow_dispatch* cadence instead, not a new scheduler ✅ | NO PHANTOM |

---

## Axis-by-axis adjudication

### 1. PHANTOM — PASS (clean)
The doc's central anti-phantom move is correct and verified: `@benchmark-runner` is referenced only in
research docs and is never built (disk-confirmed). The doc explicitly refuses to re-propose it (§3.1, §3.5,
§5) and makes the *corpus* — not a runner agent — the load-bearing artifact. It does not re-propose
`CronCreate`/`loop`/`schedule` (those are runtime tools, and it correctly designs cadence via the existing
`rituals.md` heartbeat + a `workflow_dispatch` lane modeled on the existing `integration.yml`). It does not
re-propose `.claude/rules/` (cites it as the Phase-3 NEW S1 target, not as existing). No phantom.

### 2. CITATION-INVALID — PASS (with one sharpened nuance, below)
Every change carries a citation: write-back/read-path → memory-model §6/§9/§2 (verified those sections
exist); the L2 bridge → canon-locked §B (verbatim-verified); the never-self-certify → `_EMERGING` R-1 +
RECONCILIATION §C.5 (verified). The build-list items each carry a §9 failure mode (§6 table). No
uncited change found. **Nuance** (does not invalidate): see Correction C below — "Step 3b is the one real
automated writer on disk" is faithfully *inherited* from memory-model §S3 (line 178: "one real automated
writer"), so the citation is valid, but the word "automated" is imprecise against disk and should carry a
one-clause qualifier.

### 3. TWO-BUDGET VIOLATION — **FAIL on budget (1); this is the required correction.**
This is the load-bearing claim I attacked hardest, and it broke.

**The doc claims (§6, line 371; repeated §0 diagram framing and the §6 closing): "Budget (1) — agent-context
/ advisory prose: ZERO change."** The stated reason: "the agent never reads `.claude/eval/cr-golden/` during
normal work." That reason is *correct for the corpus, scorer, CI lane, and ritual line* — those four are
genuinely budget-(2)-only and never enter agent context. The accounting on those is honest.

**But the build list also includes a NEW `/cr-eval` SKILL.md (§3.5, §5, §6 table).** A model-invocable
skill's `description` frontmatter is loaded into the always-present skill index every session (that is the
mechanism by which the model knows the skill exists to invoke it — confirmed: `cr/SKILL.md:3` carries a
`description:` line; disk shows 26 skill dirs each contributing one). So a *new model-invocable skill is not
budget-(1)-zero* — it adds one description line to the forgeable, always-loaded skill manifest. The doc's
"ZERO change" claim is **false as written**, and it is exactly the favorable-framing failure the two-budget
rule exists to catch: presenting a near-zero as an absolute zero by silently excluding the one item that
leaks.

**This is rescuable and the fix is cheap and capability-confirmed.** `/cr-eval` is a CI/ritual-run skill —
it has no reason to be auto-invoked by the model mid-task. `capability-facts.md` (lines 31-33) confirms
`disable-model-invocation: true` ⇒ "user-only, **removed from context**." Mark `/cr-eval` with
`disable-model-invocation: true` (it is invoked by the ritual/CI lane / explicitly by Tanner, never
model-auto-routed). With that frontmatter, the skill body is not in context AND its description is removed
from the always-loaded index → the budget-(1)=ZERO claim becomes **true**. Without it, the honest delta is
**budget (1): +1 description line**, which is trivial but must not be reported as zero.

**Required correction (3a):** add `disable-model-invocation: true` to the `/cr-eval` skill frontmatter, and
state in §6 that the budget-(1)=ZERO claim *depends on* that frontmatter — otherwise report +1 line. This
is the one place the doc's own discipline (never present a favorable proxy as a total win) bites the doc.

Budget (2) accounting is otherwise honest and matches my count: corpus tree (1), `score-cr-eval.sh` (1),
`/cr-eval` skill (1) = **+3 now**, +1 ritual *line* in an existing file, +1 CI lane *later*. Each names a §9
failure mode in the §6 table. No budget-(2) item is smuggled as a budget-(1) win beyond the skill-description
leak above.

### 4. §9-OVERHEAD — PASS
Every added mechanism names a failure mode it prevents (§6 table): no corpus → no recall number → the
load-bearing `/cr` gate self-certifies forever; no deterministic scorer → LLM-as-judge authority laundering;
no `/cr-eval` → measurement is a never-repeated one-off → the stale gate R-5 warns of; no scheduled lane →
the number rots un-rerun; no ritual line → "run when you remember" = never. None is a §9 ghost. The doc also
correctly *defers* the lane/auto-feeder/freshness-CI behind a hypothesis (§5), which is the §9-disciplined
"don't build the cage before the car" move. PASS.

### 5. REQUIREMENT-MISS — PASS (every artifact requirement met)
- **write-back + read-path CITED from Phase-3, not re-designed:** ✅ §1 cites memory-model §6/§3/§(ii) and
  explicitly says "I cite and wire it; I do not re-design it"; §2 cites §9/§2/§7. Verified those sections
  exist on disk. The doc does NOT re-derive them. Honors the "two legs already designed" instruction.
- **measurement designed concretely:** ✅ golden-set construction (3 prioritized sources, §3.2), storage
  (`.claude/eval/cr-golden/` tree fit to memory model, §3.2), adversarial seed (R-4, source 3 + the
  mandatory clean controls §3.3), metric (recall/precision/calibration table §3.3), run cadence (monthly +
  model-swap + on-demand, §3.5). Concrete, not hand-wavy.
- **never-self-certify honored:** ✅ §3.4 — triage against an external human-confirmed frozen label;
  deterministic *scorer* (string/tag match, not LLM-as-judge); explicitly ties to `.cr-ok`→CI via
  RECONCILIATION §C.5 (a) re-run deterministic subset + (b) coverage-bounded trust-but-verify, with the
  recall number *supplying* the coverage bound in (b). The honest ceiling ("the eval does not make the gate
  unforgeable — it makes the trust claim quantified and falsifiable") is stated, not hidden. This is the
  strongest section.
- **golden set has its own writer/reader/freshness (R-5):** ✅ §3.6 — ONE writer (`/cr` 3b promotion emits
  candidates, human-confirmed), ONE reader (`/cr-eval`), TWO freshness clocks (coverage decay + distribution
  decay) with the adversarial cases decay-exempt, owner = ritual + README + drift-detector extension. Closes
  the recursion. Honors R-5 precisely.
- **@benchmark-runner treated as phantom, not reused:** ✅ §3.1, §3.5 — names it a phantom, refuses to
  re-propose, builds the real minimal thing.
- **L2-failure-rate compounding metric wired:** ✅ §4 item 2 — cites canon-locked §B verbatim-accurately,
  appends the rate to the same `results/` time-series, and correctly notes the same number feeds MOVE 4's
  deletion engine (flat-zero = §9 ghost candidate). Correctly gated "build when L2 lands."
- **build-now vs design-later split explicit:** ✅ §5 — five build-now items, four design-later items, each
  with a reason; the hypothesis to falsify is stated.
- **no disowned ROI rates imported:** ✅ §4 opening explicitly refuses the corpus's 80%/16.6%/91% rates
  (MASTER-FINDINGS §F) and uses only locally-measured slopes. Honored.
- **two-budget delta reported:** ✅ reported in §6 — but see Axis 3: budget (1) is mis-stated as ZERO.

### 6. CAPABILITY-VIOLATION — PASS (with one nuance that strengthens, not breaks, the design)
- The eval is a **deterministic scorer script**, not a self-certifying eval — capability-correct (a script
  doing tag-match is not an LLM-as-judge). ✅
- The CI lane is `workflow_dispatch` + scheduled, modeled on the verified `integration.yml` pattern —
  capability-correct (the established "expensive, not-every-PR" lane exists on disk). ✅
- The doc does **not** claim the eval makes `.cr-ok` unforgeable — it explicitly states the ceiling (§3.4:
  "the eval does not make the gate unforgeable"). This is the honest reading of capability-facts: a plugin/
  hook/CI mechanism *cannot* make a model-written certificate unforgeable; it can only bound its trust
  claim. The doc gets this exactly right. ✅
- **Nuance (Correction C):** the doc's framing of `/cr` Step 3b as "the one real automated writer on disk"
  and "already auto" (lines 70, 90) is *capability-imprecise*. Disk shows Step 3b is **model-executed skill
  prose** (`cr/SKILL.md:176` "After producing the tiered report, **read** `docs/RECURRING-FINDINGS.md` …
  append/increment"), NOT a deterministic hook or script — there is no hook/script writing RECURRING-FINDINGS
  (grep over `.claude/hooks scripts` = empty). "Automated" here means "the skill instructs the model to do it
  every run without being asked," not "a deterministic out-of-band writer." This nuance matters because the
  Stop-hook emitter (§1) IS proposed as a genuine out-of-band hook — so the doc has *two different senses of
  "automated"* sitting next to each other, and a reader could conflate the model-prose writer with the
  deterministic hook. It does not break soundness (the doc never claims the *scorer* depends on Step 3b being
  deterministic — the scorer is independently deterministic), but it should be disambiguated.

---

## The kill attempt — did a load-bearing claim die?

**Target:** "Budget (1) — agent-context / advisory prose: ZERO change" (§6) — the doc's single cleanest,
most-emphasized property ("this is the leg's cleanest property: it strengthens the loop without taxing the
thing budget (1) protects").

**Result: the claim DIED as written and SURVIVED only with a required frontmatter fix.** A new
model-invocable `/cr-eval` skill adds one `description` line to the always-loaded skill manifest, so
budget (1) is +1, not 0 — unless `disable-model-invocation: true` is set (capability-confirmed to remove the
skill from context). The doc's own two-budget discipline ("never present a favorable proxy as a total win")
is the rule it violates here, by rounding +1 to 0. The fix is one token of frontmatter and the claim is
restored — so the design is not architecturally wrong, but the *reported delta is wrong* until corrected.
This is a real catch, not a cosmetic one: the entire phase's credibility rests on honest budget reporting,
and this is the one line that isn't.

---

## Corrections (apply before this feeds the decision package)

- **[REQUIRED — A] Budget-(1) claim is false as written.** Add `disable-model-invocation: true` to the
  `/cr-eval` skill frontmatter (it is ritual/CI/explicit-invoke only, never model-auto-routed), and rewrite
  §6's "Budget (1): ZERO change" to: "Budget (1): ZERO **iff `/cr-eval` carries `disable-model-invocation:
  true`** (removes its description from the always-loaded skill index); otherwise +1 description line." Do
  not report 0 without the frontmatter. (Capability source: `capability-facts.md:31-33`.)

- **[REQUIRED — B] §3.4 / §3.6 ONE-writer wiring assumes Step 3b can emit a golden-case candidate
  automatically — but Step 3b is model-prose, not a hook.** This is fine, but state it: the golden-case
  emission rides the same *model-executed* skill step (not a deterministic writer), so it inherits the same
  "model must actually do it" reliability ceiling as the RECURRING-FINDINGS append itself — and the
  human-confirm gate (never-self-certify) is what backstops it. The doc already has the human-confirm gate;
  it just shouldn't imply determinism the writer doesn't have.

- **[CLARITY — C] Disambiguate "automated writer."** Qualify lines 70/90: `/cr` Step 3b is "the one real
  *skill-driven (model-executed)* automated writer on disk" — to distinguish it from the §1 Stop-hook, which
  is a genuine *out-of-band deterministic* writer. Two senses of "automated" currently sit adjacent without
  the distinction drawn. (Inherited from memory-model §S3 wording, so fix it there too if propagating.)

- **[NON-BLOCKING — D] The §1 load-bearing risk (can a Stop hook see the corrected-mistake signal?) is
  correctly carried as RECONCILIATION D2 and correctly gated on a one-session empirical check.** No
  correction — flagging that the entire write-back leg's automation still hangs on this unverified
  capability, and the degrade path (`/cr` 3b + manual append) is correctly named. Keep it surfaced in the
  decision package as the load-bearing open risk, not buried.

---

## Two-budget delta of THIS check (the checker's own accounting)

This is a research artifact, not a harness change. Budget (1): **0** (nothing the agent reads at task-time).
Budget (2): **0** (no hook/CI/script/manifest added). It only *corrects* the proposed budget (1) of the doc
under review: the doc's claimed budget (1) of **0** is corrected to **+1 description line** unless the
`disable-model-invocation` fix is applied, in which case **0** stands. Budget (2) of the proposal (+3 now,
+1 later, +1 ritual line) is confirmed accurate.

---

## Status

**SOUND-WITH-CORRECTIONS.** No UNSOUND finding; no architectural rework. The measurement design is the
strongest artifact in the phase set — concrete, never-self-certifying, R-5-closed, phantom-clean, and honest
about its own ceiling. The one real defect is a mis-reported budget-(1) zero that the doc's own discipline
should have caught; it is corrected by one frontmatter token. Apply corrections A/B/C; carry D as the
surfaced load-bearing risk. Cleared to feed the decision package after A is applied.
