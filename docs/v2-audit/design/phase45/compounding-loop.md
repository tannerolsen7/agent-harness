# Phase 5 — The single compounding loop (write-back + read-path + MEASUREMENT)

**What this is.** The design of MOVE 6 — close the one compounding loop, wired into MOVE 1 (the Stop-hook
emitter surface) and MOVE 3 (the unified memory model). The loop is structurally **half-open in BOTH
directions today** [C4-CT4; map §4]: no write-back from runs (`session-end.sh` ABSENT, [map §3e]) and no
read-path of findings into task-start (`RECURRING-FINDINGS.md` is "written by the pipeline, read only by the
pipeline" — grep-confirmed in the memory model that only `PITFALLS.md` + `.claude/skills/cr/SKILL.md`
reference it [map §4]).

**Two of the three legs are already designed — I cite and wire them, I do not re-derive them.** The
genuinely-new work in this phase is the THIRD leg: **measurement** — the precondition both halves need, and
the corpus's one honestly-external thread [MASTER-FINDINGS MOVE 6; _EMERGING §2 R-1..R-5].

**Re-verified on disk this session (anti-phantom, MASTER-FINDINGS §E):**
- `@benchmark-runner` / golden-set / recall harness — **ABSENT** (grep over `.claude/` + `docs/` returns
  only research docs and `node_modules`; no eval store, no fixtures, no runner). `@benchmark-runner` is a
  phantom [map §6] — I design the real thing, I do not propose it as if it exists.
- `/cr` SKILL.md = 273 lines; Step 3b (the RECURRING-FINDINGS auto-writer) at **line 174**; sentinel write
  at **240–256**; Step 8 (`/compound` evaluate) at **260–272**.
- `.github/workflows/ci.yml` = **4 steps** (`tsc --noEmit`, `eslint .`, `test:unit`) — **no eval lane**.
  `integration.yml` = `workflow_dispatch` only (manual, secret-gated).
- `.claude/.cr-ok` + `.claude/.cr-feature-ok` are **gitignored** (`.gitignore:57-58`) — confirms the
  sentinel never reaches CI (Node 8.5c; [map §3f]).
- `.claude/rituals.md` exists with `last_run`/`frequency` fields; already lists `scan-context` (weekly).
- `/compound` SKILL.md Steps 5/6/9 confirmed (Step 9 = the 90-day memory review at line 139).

---

## 0. The loop in one diagram (write-back · read-path · measurement)

```
   ┌──────────────────────────── THE SINGLE COMPOUNDING LOOP ────────────────────────────┐
   │                                                                                       │
   │   RUN                WRITE-BACK              READ-PATH               next RUN          │
   │  (a task)   ───▶   (lands in a store)  ───▶ (loads at task-start) ───▶ (avoids the    │
   │     │              [designed: MOVE 3]        [designed: MOVE 3]          repeat)       │
   │     │                                                                      ▲           │
   │     └──────────────────────────────────────────────────────────────────────┘          │
   │                                                                                       │
   │   ┌─────────────────────────── MEASUREMENT (this phase) ───────────────────────────┐ │
   │   │  Does /cr actually CATCH the defects the loop's write-back records?             │ │
   │   │  Recall on a human-confirmed defect set. Precision/FP rate. Calibration.        │ │
   │   │  Without this number you cannot tell if the loop is compounding or rotting,     │ │
   │   │  and you cannot trust the self-certified .cr-ok gate the whole loop hangs on.   │ │
   │   └─────────────────────────────────────────────────────────────────────────────────┘ │
   └───────────────────────────────────────────────────────────────────────────────────────┘
```

The first two legs are wiring of already-designed mechanisms. The third is the keystone — it is what tells
you whether the wiring works, and it is the only leg with no prior design.

---

## 1. WRITE-BACK — state the loop, cite the memory model, name the load-bearing risk

**This leg is designed in the Phase-3 memory model (`phase3/memory-model.md` §6, §3, §(ii)). I cite and
wire it; I do not re-design it.**

The write-back leg lands run-output in a store instead of discarding it (the precise #70 failure: the
emitter existed, but `claude --print` output "went nowhere" — [memory-model §6; map §3e]). The designed
mechanism:

- **Emitter (the absent automated writer):** a `Stop`/`SubagentStop` hook
  `.claude/hooks/session-end-capture.sh` that, on a run surfacing a candidate constraint (a corrected
  mistake, a recurred `/cr` MUST-FIX), **appends a row to S3 (`docs/RECURRING-FINDINGS.md`)** in the
  existing `signature`-matched schema [memory-model §6; S3 contract §2]. It writes the **airlock**, never
  S1 directly — preserving the promotion gate (the floor-of-3 reasoning; an automated writer dropping
  straight into the always-loaded set is the "un-vetted single observation ossifying" failure
  [memory-model §1, §6]).
- **The existing auto-writer:** `/cr` Step 3b is the **one real automated writer on disk** today
  [`cr/SKILL.md:174`; memory-model §2 S3]. It already appends/increments on the `signature` field. The
  Stop hook is the *second* emitter of the *same row shape* — one logical writer, two trigger points
  (review-time vs. session-end), matched on `signature` so there is no write-contention [memory-model §3].
- **Promotion S3 → S1:** `/cr` Step 3b (≥3 occurrences, surfaces candidates at `cr/SKILL.md:183-225`) +
  `/compound` Steps 5/9, **retargeted from `PITFALLS.md` to `.claude/rules/<area>.md`** [memory-model §3].
  The auto-memory → S1 graduation is a **NET-NEW `/compound` step** — not a retarget — per RECONCILIATION
  §B.1: `/compound` reads `.claude/memory.md` only (line 143, verified) and has zero references to the
  `feedback_*`/`project_*` corpus, so the corpus-walk is a small new build, counted in budget (2).

**THE LOAD-BEARING RISK (RECONCILIATION open decision D2, memory-model Open Decision 2).** Can a Stop hook
*see the turn's corrected-mistake signal*? `capability-facts.md` confirms a Stop hook **can run shell
commands and can block** but is **internally hedged on force-continue semantics**, and it is unverified
whether the hook's stdin/transcript carries enough of the turn to detect "a mistake was corrected this
turn." The emitter needs only **append-and-allow-stop** (write a row, never block — the
non-controversial capability), so it does NOT depend on the hedged force-continue path. But it DOES depend
on *seeing the signal*. Disposition, unchanged from the memory model:

> Build the Stop hook for append-and-allow-stop only. Gate full session-end auto-capture on a one-session
> empirical check (MASTER-FINDINGS §G). **If the hook cannot see the correction signal, the write-back
> leg degrades to `/cr` Step 3b (already auto) + a manual append** — still strictly better than today's
> prose-only `memory.md` write-back, just not fully automatic.

**Why measurement matters even to this leg:** the write-back's whole value is that the *next* run avoids the
repeat — and the only way to know it did is to measure whether `/cr` (the reader-side enforcer) catches the
defect class the write-back recorded. A write-back leg that lands findings in a store the reviewer can't
detect is a leg that compounds noise. Measurement (Leg 3) is what tells write-back it is working.

---

## 2. READ-PATH — cite the memory model, don't re-derive

**This leg is also designed in the Phase-3 memory model (§9, §2, §7). I cite and wire it.**

Two read-paths close the half-open loop, both in tooling [memory-model §9]:

1. **Sub-threshold findings (occurrences 1–2) — S3 task-start glob.** A Phase-0 read step in
   `/dev`, `/feature`, `/cr` globs the ledger's `signature`/`Example locations` against the files the task
   will touch and surfaces matches with their count ("you are about to edit X; a finding here recurred 4× in
   this area") **before code is written** [memory-model §2 S3 reader, §9]. The implementer sees the
   observation at the moment they are about to repeat it.
2. **Promoted findings (≥3 occurrences) — S1 native `paths:` auto-load.** Promoted findings land in
   `.claude/rules/<area>.md` and are delivered by the platform's native `paths:` glob lazy-load whenever any
   implementer touches that area [memory-model §7; capability-facts.md "`.claude/rules/` with `paths` globs
   = native path-scoped lazy-loading"]. The read-path for the promoted half is *the platform's
   path-scoping* — no custom reader.

S1 tells you the *promoted* constraints for this path; S3 tells you the *not-yet-promoted-but-recurring*
ones. Both halves are readable at the point of work [memory-model §9]. **Nothing new to design here** — the
read-path is the Phase-3 model's §9, wired into the same three task-entry skills the write-back's emitter
and `/cr` already touch.

---

## 3. MEASUREMENT — the keystone (the genuinely-new work)

### 3.1 Why measurement is the keystone, not a nice-to-have

`/cr` is the **load-bearing, least-tested** component of the entire harness. It is "more review rigor than
any tool the corpus studies" [MASTER-FINDINGS §E] — 9 passes + 4 adversarial lenses over the full branch
diff — and the **entire push gate hangs on its output** (`.cr-ok` = "MUST-FIX=0 per `/cr`"; the pre-push
hook and `scripts/pr.sh` consume it). Yet:

- **Its recall is UNMEASURED.** No golden set exists anywhere (confirmed absence, re-verified this session)
  [_EMERGING §2 R-2]. We have never measured *what fraction of real defects `/cr` actually catches.*
- **The gate it feeds is self-certified.** `.cr-ok` is **model-computed, never oracle-computed** — gitignored,
  never reaches CI [map §3f; _EMERGING §2 R-1]. The model writes the certificate that says its own review
  passed.
- **Every verifier is calibrated against a friendly audience.** Single vendor (Monica), single author
  (Tanner), no adversarial input [map §8; _EMERGING §2 R-4]. The review has never been tested against a diff
  built to *defeat* it.

Put together: **we cannot tell whether `/cr` got better or worse after a model swap** (Opus 4.8 re-audit,
MOVE 4 — the judgments were made against Sonnet 4.6 [map §9]), and **we cannot trust any self-certified
gate** because nothing external bounds its coverage claim. Measurement is the precondition for BOTH halves
of the loop: write-back needs to know the reviewer catches what it records; read-path needs to know the
constraints it loads are the ones that actually fire. **A compounding loop with no measurement is a loop you
cannot prove is compounding rather than rotting.** That is why this leg, not the wiring, is the phase's real
deliverable.

> **The phantom warning, stated plainly:** `@benchmark-runner` is referenced on disk but never built [map
> §6]. This design does NOT re-propose `@benchmark-runner`. It designs the real, minimal harness below, and
> deliberately makes the corpus (not a runner agent) the load-bearing artifact — because the corpus is what
> survives a model swap, and a "runner" is the cheap part.

### 3.2 The golden set — what it is, and WHERE it is stored (fit to the Phase-3 memory model)

A **golden set** is, in plain terms, *a fixed collection of code diffs whose defects are already known and
human-confirmed* — so that when `/cr` reviews them, you can score its output against the known answer
instead of against the model's own opinion.

**Critical seeding rule (R-4): seed with ADVERSARIAL / known-defective diffs, NOT friendly ones.** Every
verifier today is calibrated against a friendly single-vendor audience [_EMERGING §2 R-4; map §8]. A golden
set built from "diffs that happened to be clean" measures nothing — the reviewer passes them and learns
nothing about its recall. The set must be **diffs that contain a known defect the reviewer is supposed to
catch**, drawn from three sources, in priority order:
1. **Real historical MUST-FIX findings** — every defect `/cr` has *already* caught (mine
   `RECURRING-FINDINGS.md` promoted entries + git history of `/cr`-driven fixes). These are
   ground-truth-by-construction: a human (Tanner) confirmed them real. **This is the seed corpus — it costs
   near-zero to assemble and it is the one place the friendly-audience problem is already solved**, because
   each entry is a defect that was real enough to fix.
2. **Real historical NEEDS-HUMAN / escaped defects** — bugs that reached `main` and were later fixed (mine
   the `fix:` commit history + post-mortems + incidents). These are the **false-negatives the harness
   already produced** — the most valuable rows, because they measure the recall gap directly.
3. **Hand-authored adversarial diffs** — a *small handful* (start at ~6–10), each constructed to defeat one
   specific pass: a layer-boundary violation routed through an alias (P4), a destructive op disguised
   (P2/safety floor), a money-math off-by-one in integer cents (P1), an `as` cast with a *plausible-looking
   but absent* narrowing (P3), a redirect built from `resolved.search` (security). These probe whether each
   pass actually fires, not whether the reviewer agrees with itself.

**WHERE it is stored — fit it to the memory model, do NOT invent a 4th memory store.** This is a binding
constraint from the phase brief and the two-budget rule. The golden set is **not a new owned memory store.**
It is a **CI fixture corpus**, the same class of artifact as a test fixtures directory — it lives where test
inputs live, not where knowledge lives:

```
.claude/eval/cr-golden/
  README.md                      # the freshness contract (writer/reader/decay) — §3.6
  cases/
    0001-layer-boundary-alias.md      # one file per case: the diff + the known-defect manifest
    0002-money-cents-off-by-one.md
    ...
  cases.manifest.json            # machine-readable: {id, source, defect_class, expected_pass,
                                 #  severity, human_confirmed, added, last_scored}
  results/
    <model-id>-<date>.json       # scored runs, append-only (the recall time-series — §3.5, §3.6)
```

**Why this is NOT a 4th memory store** (the anti-phantom / two-budget discipline): a memory store in the
Phase-3 model holds *knowledge the agent reads to do work* (S1 constraints, S2 patterns, S3 findings). The
golden set holds *test inputs the eval harness reads to score the reviewer* — the agent never reads it
during normal work. It is budget-(2) infrastructure (a CI fixture corpus), exactly like `scripts/seed.ts`
or the integration test fixtures. It rides the same lifecycle discipline as a memory store (writer/reader/
freshness — §3.6) **without** being one. Conceptually, the golden set is the *measurement instrument for S1's
read-path*: when a promoted S1 rule has a corresponding golden case, you can prove the rule's pass still
fires. That coupling is wiring, not a merge — the golden case `cases.manifest.json` may carry a
`backs_rule:` pointer to an S1 `.claude/rules/*.md` entry (checked by the existing drift detector,
memory-model §8), but the two artifacts stay separate.

### 3.3 The metric — recall, precision, calibration (and why all three)

The harness scores three numbers per run. Each answers a distinct failure question:

| Metric | Definition (plain) | Failure it detects |
|---|---|---|
| **Recall on known defects** | of the N cases with a known defect, what fraction did `/cr` flag as MUST-FIX (or the correct tier)? | **The core number.** `/cr` silently got worse — misses defects it used to catch (e.g. after a model swap). A drop here is the headline regression. |
| **Precision / false-positive rate** | of everything `/cr` flagged MUST-FIX, what fraction were *not* real defects (scored against clean control cases mixed into the set)? | `/cr` got *noisier* — floods MUST-FIX with non-defects, which trains the human to ignore the gate (the "boy who cried wolf" path that makes the whole gate worthless even at high recall). |
| **Calibration vs self-agreement** | does `/cr`'s confidence/tier match the *human-confirmed* severity — NOT match its own re-run? | **Authority laundering** [_EMERGING §2]. A reviewer that agrees with itself across passes looks calibrated but is only self-consistent. Calibration is measured against the external label only. |

**Control cases are mandatory.** Precision is meaningless without clean diffs in the set the reviewer is
*supposed to pass*. Mix in ~20-30% known-clean cases (real merged diffs that had no post-merge fix). A
reviewer that flags everything scores 100% recall and is useless; the clean cases are what catch that.

### 3.4 NEVER SELF-CERTIFY — triage calibration against an external defect set

This is the non-negotiable design constraint [_EMERGING §2; phase brief item 3]. **The eval must be a TRIAGE
calibration against a human-confirmed defect set — NOT the model grading its own review.**

The forbidden design (authority laundering): run `/cr`, then ask a model "did `/cr` do a good job?" That
launders self-agreement through an extra pass until it looks external. It is the exact failure the corpus
names [_EMERGING §2 R-1].

The required design:
- **The label is external and human-confirmed.** Every golden case's `expected` defect is confirmed by a
  human (Tanner) at authoring time and frozen in `cases.manifest.json` (`human_confirmed: true`). The score
  is `/cr`'s output **diffed against that frozen label** — a mechanical comparison, not a judgment.
- **The scorer is deterministic, not a model.** Scoring = "did the MUST-FIX list contain a finding tagged
  with the case's `defect_class`?" — a string/tag match in a script, not an LLM-as-judge. (An LLM *may*
  assist *authoring* a case's expected manifest, but the human confirms it and it is then frozen; the
  *scoring* step is pure comparison.)
- **This is what bounds the `.cr-ok` → CI gate's coverage claim.** RECONCILIATION §C.5 resolves the
  `.cr-ok` forgeability to **(a) CI re-runs the deterministic subset of `/cr`** (tests/lint/typecheck — the
  mechanizable passes — so the model never writes the trusted record) **+ (b) the judgment passes accepted
  as coverage-bounded trust-but-verify.** Measurement is **what supplies the coverage bound in (b)**:
  recall on the golden set is the *number you put on* "how much do we trust the judgment-pass half of the
  gate." Without it, (b) is "trust us"; with it, (b) is "trust the judgment passes to the measured recall
  R, refreshed every quarter." The eval does not make the gate unforgeable — it makes the gate's trust claim
  *quantified and falsifiable*. That is the honest ceiling, and stating it is the design.

### 3.5 How it RUNS — the runner, the lane, the cadence

**Build now (minimal):** a `/cr-eval` skill + a deterministic scorer script. NOT a `@benchmark-runner`
agent (phantom; and a runner agent is the cheap, swappable part — the corpus is the asset).

- **`/cr-eval` skill** (`.claude/skills/cr-eval/SKILL.md`): for each case in `cases.manifest.json`, run the
  real `/cr` (or its judgment-pass subset) against the case diff, capture the MUST-FIX/tier output, and hand
  it to the scorer.
- **`scripts/score-cr-eval.sh`** (deterministic, no model): diff `/cr` output against the frozen manifest
  labels; emit recall / precision / calibration to `results/<model-id>-<date>.json`; print a one-line
  summary and a regression delta vs the previous run for the same model.

**The lane — NOT the default `ci.yml` PR lane.** `ci.yml` runs on every PR/push and must stay fast and
deterministic; a `/cr` re-run is slow and model-dependent (it would make every PR wait on a probabilistic
job). Instead:
- **A dedicated `workflow_dispatch` + scheduled GitHub Actions lane** (`.github/workflows/cr-eval.yml`),
  modeled on the existing `integration.yml` (which is already `workflow_dispatch`-only and secret-gated —
  the established pattern for "expensive, not-every-PR" jobs). It runs the golden set, writes a result row,
  and **fails the lane if recall drops below a committed floor** (a regression gate, not a PR gate).
- **A ritual cadence** in `.claude/rituals.md` (the heartbeat already exists, `last_run`/`frequency`,
  already lists `scan-context` weekly). Add a `cr-eval` ritual at `frequency: monthly` **and** a hard
  trigger rule: **run on every model swap** (the Opus 4.8 re-audit is the first such trigger). The ritual is
  what makes the cadence fire without waiting to be asked; the scheduled Actions lane is the unattended
  backstop.

**Cadence summary:** monthly (ritual) + on-every-model-swap (hard rule) + on-demand (`workflow_dispatch`
when a `/cr` pass prompt is edited). Recall is a **moving target** (passes × merge-rule × model ×
diff-distribution [_EMERGING §2 R-2]) → **continuous** measurement, not one-shot. A single recall number
taken once and trusted forever is itself the next stale forgeable gate.

### 3.6 R-5 — the calibration's OWN freshness owner (give the golden set a writer/reader/decay)

This is the trap the corpus names explicitly: **the golden set itself becomes the next stale forgeable gate
if it has no owner/decay/refresh rule** [_EMERGING §2 R-5; map §4]. A golden set authored once and never
refreshed measures the harness against a frozen, stale defect distribution — and quietly stops being a real
test. It must get the same writer/reader/freshness contract every Phase-3 store gets [memory-model §2 form]:

| Contract | The golden set's rule |
|---|---|
| **ONE writer** | `/cr` Step 3b is the natural feeder: when a finding promotes (≥3 occurrences, real defect), the promotion step **also emits a golden-case candidate** (the diff that triggered it + the defect class) into `.claude/eval/cr-golden/cases/`. Human confirms the label (the never-self-certify rule) before it counts. This makes the golden set *grow from the same write-back leg that feeds S1* — the loop feeds its own measurement instrument. |
| **ONE reader** | `/cr-eval` (the scorer), monthly + on model-swap. Nothing else reads it. |
| **ONE freshness rule** | Two clocks. **(a) Coverage decay:** a `defect_class` that has appeared in a *new* promoted finding but has *no* golden case is flagged by the drift detector (memory-model §8) as a coverage gap — the set is stale relative to what the harness is now catching. **(b) Distribution decay:** cases older than a horizon (e.g. 365 days) with `last_scored` against a *retired* model are flagged for re-confirmation — the diff distribution and the model have both moved. **Decay-exempt:** the hand-authored adversarial cases (§3.2 source 3) — they probe specific passes and don't go stale by age, only by the pass being removed. |
| **Owner** | The `cr-eval` ritual is the heartbeat; the README in `.claude/eval/cr-golden/` is the *named* freshness contract (writer/reader/clocks above) so the owner is documented, not implicit. **The drift detector (memory-model §8) is extended to assert golden-set freshness** — one more class of fiction/decay check, in the lane that already exists. No new owner mechanism; ride the heartbeat + the drift CI. |

This closes the recursion: the thing that measures whether the loop is compounding is *itself* inside the
loop's decay discipline. There is no un-owned gate.

---

## 4. The loop measures ITSELF improving (or not) — the outcome signal, no imported rates

Two compounding metrics tell you whether the harness is getting better over time. **Neither imports the
corpus's disowned ROI/recall rates** (MASTER-FINDINGS §F rejects importing 80%/16.6%/91%/etc. as
single-source/self-disowned — adopt *mechanisms*, never *rates*). Both are **measured locally, from this
harness's own runs**:

1. **`/cr` recall-over-time (the eval's own time-series).** `results/<model-id>-<date>.json` is an
   append-only series. The outcome signal is the *slope*: recall flat-or-rising across model swaps and pass
   edits = the reviewer is holding or improving; recall dropping = a regression to investigate (the Opus
   4.8 re-audit is the first data point, not an assumption). This is the loop measuring its *enforcement*
   leg.

2. **L2 architecture-test failure-rate-over-time (canon-locked §B draws this bridge explicitly).**
   `canon-locked-decisions.md §B`: "L2 arch-test failure-rate over time = a compounding metric ('whether
   layer discipline is holding') → feeds Skill Effectiveness Analytics. This is the bridge between
   enforcement (Phase 3) and the compounding loop (Phase 5)." Wire it: the `dependency-cruiser` L2 CI job
   (MOVE 2) emits a pass/fail per run; **append the rate to the same `results/` time-series.** A *falling*
   L2 failure rate over time is the loop's positive outcome signal on the *read-path* leg — it means the
   relocated layer-boundary constraints (now path-loaded S1 rules + L2 CI tests) are actually preventing the
   violations they encode, so implementers stop committing them. A *flat-high* rate means the constraint is
   loaded but not landing (a read-path failure), and a *flat-zero* rate after long history means the rule
   may be a §9 ghost (never fires → MOVE 4 eviction candidate). **The same number that proves the loop works
   also feeds the deletion engine** — this is the compounding loop and MOVE 4 sharing one signal.

**The honest outcome claim:** the loop improves iff (recall slope ≥ 0 across model swaps) AND (L2 failure
rate trends down as constraints accumulate). If recall drops on a model swap, MOVE 4's re-audit is
*triggered by data, not by calendar*. If L2 rate is flat-high, a read-path is broken. These are
locally-measured, falsifiable, and free of any imported rate — the only outcome signals the corpus's own
reject-list permits.

---

## 5. BUILD NOW vs DESIGN-NOW-BUILD-LATER (hypothesis-before-speculative-build)

Per the harness's own discipline [memory: hypothesis_before_speculative_build]: ship the simplest version
that produces a real recall number; only build the heavier machinery if the hypothesis ("a small adversarial
set catches `/cr` regressions") fails in practice.

**BUILD NOW (the minimal recall harness):**
1. `.claude/eval/cr-golden/` corpus seeded with **(a)** the historical promoted MUST-FIX findings (near-zero
   cost — mine `RECURRING-FINDINGS.md` + git history) + **(b)** a *handful* (~6–10) of hand-authored
   adversarial diffs, one per pass + the safety floor + a few clean controls. **Start small on purpose** —
   the hypothesis is that even a handful catches a real `/cr` regression.
2. `scripts/score-cr-eval.sh` — deterministic scorer (tag-match, no model), emits recall/precision to
   `results/`.
3. `/cr-eval` skill — runs `/cr` (judgment-pass subset) over the corpus and hands output to the scorer.
4. Run it **once now against Opus 4.8** to establish the baseline recall number (this is the MOVE-4
   re-audit's missing measurement — without it, the re-audit is opinion).
5. Add the `cr-eval` ritual (`frequency: monthly` + on-model-swap) to `.claude/rituals.md`.

**DESIGN NOW, BUILD LATER (gated on the minimal harness producing a useful number):**
- `.github/workflows/cr-eval.yml` scheduled lane + recall-floor regression gate. *Build once the baseline
  exists and you know what floor is meaningful* — a floor set before any data is an arbitrary gate.
- `/cr` Step 3b emitting golden-case candidates automatically (the §3.6 ONE-writer wiring). *Build after the
  manual corpus proves the format; auto-feeding a corpus whose format is still moving is premature.*
- Drift-detector extension for golden-set freshness (§3.6 clocks). *Build alongside the §8 drift detector,
  not before it exists.*
- The L2-failure-rate time-series append (§4 item 2). *Gated on MOVE 2's `dependency-cruiser` L2 job
  existing — design the wiring now, build when L2 lands.*

**The hypothesis to falsify:** "a handful of adversarial golden cases + historical defects is enough to
catch a meaningful `/cr` recall regression across a model swap." If the minimal harness runs against Opus
4.8 and the number is uninformative (e.g. trivially 100% because the cases are too easy, or noisy because the
set is too small), *then* invest in the larger corpus + the scheduled gate. Do not build the scheduled lane,
the auto-feeder, and the freshness CI before the handful proves it catches anything.

---

## 6. The honest two-budget delta (this phase)

Per the two-budget rule — report BOTH budgets, never present a budget-(2) item as a budget-(1) win.

**Budget (1) — agent-context / advisory prose (files the agent READS every session): ZERO change.**
The golden set, scorer, runner, and CI lane are **not read by the agent during normal work.** The agent
reads `.claude/rules/*.md` and `docs/solutions/` to do a task; it never reads `.claude/eval/cr-golden/`.
Measurement adds **nothing to the per-session token cost or the forgeable-prose surface.** This is the leg's
cleanest property: it strengthens the loop without taxing the thing budget (1) protects.

**Budget (2) — out-of-band deterministic enforcement / packaging (runs OUTSIDE the agent's context):
+3 to +4, each §9-justified.**

| Added (budget 2) | §9 failure mode it prevents | Build-now? |
|---|---|---|
| `.claude/eval/cr-golden/` corpus + manifest | The load-bearing `/cr` gate gets worse after a model swap and **nothing detects it** — the gate self-certifies forever. No corpus = no recall number = no falsifiable trust claim on `.cr-ok`. | **Now** (seeded small) |
| `scripts/score-cr-eval.sh` (deterministic scorer) | Without a *deterministic* scorer the eval becomes LLM-as-judge = authority laundering (the forbidden design, §3.4). The scorer being a script is what keeps the eval external. | **Now** |
| `/cr-eval` skill | No repeatable way to run the corpus = the measurement is a one-off someone does by hand and never repeats → recall becomes the stale gate R-5 warns of. | **Now** |
| `.github/workflows/cr-eval.yml` (scheduled lane + recall floor) | A measured recall number that nobody re-runs on cadence rots; the scheduled lane is the unattended heartbeat backstop to the ritual. | **Later** (after baseline) |
| Ritual entry `cr-eval` in `.claude/rituals.md` | Cadence with no heartbeat = "run it when you remember" = never (the exact rituals.md failure mode). | **Now** (one line in an existing file, not a new file) |

**Net budget (2): +3 files now** (`cr-golden/` tree counts as one corpus artifact, scorer, `/cr-eval`
skill) + 1 ritual *line* (no new file) + **+1 file later** (the CI lane). **Net budget (1): 0.** Every
budget-(2) addition names a §9 failure mode (a forgeable/stale gate it prevents); none is a §9 ghost. The
favorable proxy I must NOT claim: "it's just one eval corpus" is not a file-count win — it is budget-(2)
growth, justified, while budget (1) is untouched. That is the honest delta.

---

## 7. Open decisions surfaced (recommendation-first)

These are carried to the decision package. The first two are inherited (cited, not re-opened); the rest are
new to this phase.

1. **[INHERITED, RECONCILIATION D2] MOVE-1 Stop-hook capture: fully automatic vs degrade?** *Recommendation:
   build append-and-allow-stop now; gate full auto-capture on the one-session empirical check; degrade to
   `/cr` 3b + manual append if the hook can't see the correction signal.* The load-bearing risk in the whole
   write-back leg.
2. **[INHERITED, RECONCILIATION §C.5] `.cr-ok` → CI: re-run the deterministic `/cr` subset vs
   coverage-bounded trust-but-verify?** *Recommendation: (a) CI re-runs the mechanizable passes + (b) the
   judgment passes accepted as trust-but-verify with the coverage bound supplied by the golden-set recall
   number (§3.4).* Measurement is what quantifies (b).
3. **[NEW] Golden-set seeding ratio and the clean-control fraction.** *Recommendation: seed ~70% known-defect
   (historical + adversarial) / ~30% clean controls; start the adversarial set at ~6-10 hand-authored cases,
   one per pass + safety floor.* The fork: heavier adversarial investment up front (more confidence, more
   authoring cost) vs the minimal handful (test the hypothesis first). Lean minimal per
   hypothesis-before-speculative-build.
4. **[NEW] Does `/cr-eval` run the full `/cr` or only its judgment-pass subset?** *Recommendation:
   judgment-pass subset (P1-P9 + lenses) — the mechanical passes (lint/tsc/it.only) are already
   deterministic and measured by CI; recall on *those* is trivially 100% and uninformative. The recall that
   matters is on the judgment passes.* Running full `/cr` per case is slower and measures nothing new on the
   mechanical half. Fork only matters for cost.
5. **[NEW] Recall regression-floor: hard CI fail vs surface-and-annotate?** *Recommendation: surface +
   annotate for the first few cycles (no committed floor until there's enough data to know what floor is
   meaningful — §5), THEN promote to a hard fail in the scheduled lane.* A floor set before baseline data is
   an arbitrary forgeable gate — exactly the failure class this whole phase exists to prevent.
6. **[NEW] Eval investment timing (folds MASTER-FINDINGS §H item 5).** *Recommendation: build the minimal
   harness NOW (it is the precondition for trusting every other gate and for the MOVE-4 re-audit), defer the
   scheduled lane + auto-feeder + freshness CI behind the baseline producing a useful number.* The §H fork
   ("build the golden-set harness now, or defer behind installs?") resolves toward NOW for the minimal
   harness specifically — because without it the Opus 4.8 re-audit (MOVE 4) is opinion, not measurement, and
   the whole loop's self-certified gate stays unbounded.
