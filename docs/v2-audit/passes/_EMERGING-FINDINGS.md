# Emerging findings (running, compaction-proof)

High-value, ground-truthed insights as they surface from Phase 2 pass-3 analyses. Each is already
citation-anchored (map section or verified disk fact). This file seeds Phase 3–5; it is not the final
synthesis.

## Process note (forced adaptation, transparent)
Phase 2 full run hit the account session-limit after 71 agents / 2M tokens. **31/36 primary articles
got complete 3-pass files; 6 completing now; 35 per-article checkers + 8 derived did not run.** Decision:
rather than re-run 35 individual per-article checkers (the probe + the 3 read pass-3s show doers
self-discipline rigorously against phantom gaps — low yield), the doer≠checker gate moves to the
**aggregation level**: a separate adversarial agent challenges the *consolidated* gap list against
ground truth (also catches cross-article duplicate gaps, which per-article checkers cannot). This is a
budget-forced but defensible adaptation; flagged to Tanner.

---

## Doctrine core (from loop-engineering, recursive-self-improvement, commands-vs-skills pass-3s)

### 1. The missing primitive is a HEARTBEAT, not more harness. [loop-engineering]
- We have 5 of the 6 "loop" pieces (orchestration, worktrees, skills, 6-store memory, human-gated
  action). The one genuine absence is a **scheduler/clock**: no cron, no `/loop` wiring; `.claude/rituals.md`
  fires *only at session start, only if the model remembers to check `last_run`*. [map §3e advisory]
- **Temporal-gap doctrine (highest-value contribution):** a static file-inventory audit *structurally
  cannot* catch a missing heartbeat. → the CANONICAL map should carry a **"fires how / on what clock?"**
  column on every ritual/hook row. Connects to the "audit artifacts rot" finding — both are *time*
  failures a static snapshot misses.
- `permission-logger.sh` writes per-call JSONL that **nothing aggregates** — an orphaned ritual. [map §6]
- The capability the article merely *asserted* exists is real *here*: this environment exposes
  `CronCreate`/`CronList` + a `schedule`/`loop` skill. The heartbeat is a wiring decision, not research.

### 2. Verification is the scarce capability; our terminal stop authority is FORGEABLE. [recursive-self-improvement]
- **"Authority laundering"**: a loop passing model self-agreement through enough passes that it looks
  external. The real scarce resource is a **human-authored, model-immutable spec + a stop anchored to it.**
- **R-1 (the sharpest gap):** `.cr-ok` convergence is **model-computed, never oracle-computed** — Node
  8.5(c): CI never verifies `.cr-ok` (gitignored, never reaches CI) [map §3f]. Fix: stop authority =
  `MUST-FIX=0 AND CI-required-checks-green on the sentinel SHA`, enforced in **CI/branch-protection where
  it can't be forged**, not in the skill body. (Coverage-bounded oracle, not unforgeable — caveat noted.)
- R-2: `/cr` recall is **unmeasured**; no golden set exists anywhere (confirmed absence). Build *continuous*
  recall measurement (it calibrates a moving object: passes × merge-rule × model × diff-distribution).
- R-3: **no property-based testing**; integer-cents money-math is the textbook PBT case (confirmed absence).
- R-4: no adversarial/external-user signal — every verifier calibrated against a friendly audience (single
  vendor, Monica) [map §8]. Seed any golden set with adversarial/known-defective diffs, not friendly ones.
- R-5: no owner/freshness rule for the calibration itself → it becomes the next stale forgeable gate [map §4].

### 3. Skills: situational triggers + tier-by-trigger, not line-count. [commands-vs-skills]
- We are **fully on the skill form** (no `.claude/commands/`); the command-vs-skill question is moot.
- **Two-decision grid (durable lens for the Phase-3 audit):** (A) activation-control by *reversibility of
  a false trigger*; (B) load-tier by *trigger-existence*, NOT length.
- Gap: descriptions are **phrase-keyed** (e.g. `/cr` desc literally lists trigger words) — the §9
  anti-pattern. Fix = rewrite as **situations**, not "front-load trigger words" (the article's literal
  advice is the anti-pattern; reject it).
- Gap: **0/26 skills** use invocation-control frontmatter. Add `disable-model-invocation` to **reversible**
  side-effect skills; route **irreversible** ones to the absent `block-dangerous-bash.sh` [map §5]
  (trigger-gate ≠ kill-gate).
- Gap: 799-line root (CLAUDE 325 + AGENTS 474 [verified]). The **triggerable** duplicated stores
  (PITFALLS/RECURRING-FINDINGS) are mis-tiered into always-loaded; but **no-trigger safety content
  (destructive-op rules) must STAY tier-1** regardless of length [map §4 + §9]. Reject "shrink to 200 lines"
  as a blind metric.
- Gap: no installable/distribution unit [map §8]; plugin is the **endpoint**, but **converge canon↔disk
  FIRST** — you can't version-distribute a harness whose canon and disk disagree.

## Cross-cutting signal already visible
- **Fresh-research need is LOW.** All three pass-3s independently conclude "synthesize, don't re-research,"
  with only *bounded capability checks* left: (a) PBT tooling vetting (fast-check × Vitest 4), (b) Agent
  Skills frontmatter schema confirm, (c) scheduler durability spike (does `CronCreate` fire when the
  machine sleeps?). None is a research project. This validates the registry's "corpus is a starting point"
  but suggests the corpus + ground-truth already answer most questions.
- **Recurring theme across all three:** our failures are *temporal/authority* failures (missing clock,
  forgeable gate, stale calibration), not *missing-mechanism* failures. V2's job is wiring + convergence +
  enforcement-relocation, not more files. Strongly consistent with the "fewer mechanisms" mandate.
