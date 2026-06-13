# Phase 4 + 5 — Reconciliation (doer≠checker resolved)

Both artifacts: **SOUND-WITH-CORRECTIONS, NO blockers, no architectural rework.** Each checker attacked the
central load-bearing claim and it survived — Phase 4's plugin-settings constraint survived *strengthened*
against a real installed plugin; Phase 5's measurement design is the strongest in the set (concrete,
never-self-certify, R-5-closed, phantom-clean). Corrections below are the authoritative position; Phases 6
+ assembly build on these.

## Phase 4 — distribution (corrections, all factual/precision)
- **C1.** `skills-lock.json` at repo root is **751 B**, not 6.7 KB (the 6.7 KB file is the *global*
  `~/.agents/.skill-lock.json` — different file, conflated). The substantive argument stands (real,
  git-tracked, SHA-256, tracks the 2 supabase upstream skills, is the manifest precedent that corrects the
  map's stale "phantom" claim); only the size citation is wrong.
- **C2 [strengthens §1].** Restate the plugin-settings mechanism empirically: the live installed
  `vercel 0.43.0` plugin's settings.json is **27 bytes** (`{"enabledPlugins":{}}`) — carries NEITHER
  `agent` nor `subagentStatusLine`, ships NO permissions block, wires hooks via top-level `hooks/hooks.json`
  + `${CLAUDE_PLUGIN_ROOT}`, registers agents/commands via `plugin.json`. The conclusion (a plugin cannot
  carry permissions → the seam is forced) is correct and was *under*-stated.
- **C3.** `recyclops/logistics-service` has **no `.claude` dir at all** (not "empty" as the map §8 says) —
  more greenfield than stated. Re-verify-absence rule: trust disk.
- **C4.** (a) `additionalDirectories` is not a top-level `settings.json` key (disk top-level keys:
  env/autoMode/permissions/hooks) — drop/relocate the claim. (b) **The decision package MUST sum the WHOLE
  V2 budget-(2)**, not report distribution's +4–5 as the total — see cross-phase note below.

## Phase 5 — compounding loop (corrections, one required)
- **A [REQUIRED].** The "budget (1) = ZERO" claim is false as written: a new model-invocable `/cr-eval`
  skill adds one `description` line to the always-loaded skill index. **Fix: add
  `disable-model-invocation: true` to `/cr-eval` frontmatter** (capability-confirmed: removes it from
  context — it is ritual/CI/explicit-invoke only, never model-auto-routed). With it, budget-(1)=0 holds;
  without it, report +1. The doc violated its *own* two-budget discipline — a useful confirmation the lens
  is right.
- **B.** The golden-case emission (§3.6 ONE-writer) rides `/cr` Step 3b, which is **model-executed skill
  prose, not a deterministic hook** — so it inherits the "the model must actually do it" reliability
  ceiling; the human-confirm gate (never-self-certify) is the backstop. State it; don't imply determinism.
- **C.** Disambiguate "automated writer": `/cr` Step 3b is *skill-driven (model-executed)* automated; the
  §1 Stop-hook is a genuine *out-of-band deterministic* writer. Two senses sit adjacent. (Propagate to
  memory-model §S3 wording.)
- **D [non-blocking, surface it].** The load-bearing open risk stays surfaced in the decision package: can
  a Stop hook *see the turn's corrected-mistake signal*? Gated on a one-session empirical check; degrade
  path (`/cr` 3b + manual append) named. This is RECONCILIATION-phase3 D2.

## Cross-phase budget summation (the number the decision package must state)
**Total V2 budget-(2) delta ≈ +16 to +20 out-of-band files/mechanisms** = Phase 3 (~+9–11: bash guard,
session-end hook, drift detector, migration-lint, repo-structure, gen-rules, dependency-cruiser config+dep,
~5–6 rule shards, 2 CI jobs) + Phase 4 (+4–5: plugin.json, marketplace.json, hooks.json, harness-manifest,
VERSION/CHANGELOG) + Phase 5 (+3 now: golden-set corpus, scorer, `/cr-eval` skill; +1 later: CI lane).
**Against:** budget (1) — agent-context/advisory prose — **falls sharply** (memory.md deleted, PITFALLS
monolith → path-scoped shards, ~64 rules out of prose, copies-per-fact 3→1, per-`/cr` PITFALLS token cost
~172 KB → a fraction); knowledge-file count ≈ flat-to-slightly-down. **This is the honest whole-V2 ledger:
total tracked files up modestly, every addition §9-justified and out-of-band; the thing that hurt V1 (the
forgeable advisory-prose budget the agent reads) falls hard.** Per the two-budget rule (RECONCILIATION-
phase3 §A), that is the win — but it must be stated as two numbers, never one.

## Status
Phases 4–5 reconciled. Vehicle = two-vehicle split (plugin + thin template), recommend revising the canon's
locked single-vehicle decision (defended). Compounding loop = wire the Phase-3 write-back/read-path + build
the minimal `/cr` recall harness now (it is the precondition for the MOVE-4 Opus-4.8 re-audit and for
bounding the `.cr-ok`→CI trust claim). Open decisions accumulate toward the brief (Phase-4 §7 + Phase-5 §7
+ phase-3 §F + MASTER-FINDINGS §H) — Phase 6 deduplicates them to the real ~4–8.
