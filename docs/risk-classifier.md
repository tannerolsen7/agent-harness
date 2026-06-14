# Risk classifier (blast-radius tiering) — spec + guard

**Status: SPEC, not yet implemented.** The deterministic tiering script does not exist as code yet
(it is the Phase-1 "SCALE-TO-TASK via the existing blast-radius classifier" item, R4-D20 / R4-D32 #2).
This file is the contract the build inherits — most importantly the **over-classify-when-unsure rule
(R4-D32 #5)** and the **bug-catch trap subset** that measures it. Read it before building the classifier.

## What it is

A deterministic, non-model decision rule (a hook/script, safe under `disable-model-invocation`) that maps
a diff to a tier and selects the per-task **battery** (which review agents fire). Minimal review is the
DEFAULT; machinery is added only when the diff's risk earns it (R4-D32 #2).

| Tier | Diff looks like | Battery |
|---|---|---|
| **LOW** | docs / copy / one pure function — small, in-scope, no blast-radius paths, positive test delta, CI green, `/cr` clean (all at once) | 1 Haiku pass (the generalized `/cr` Step-0 docs path) |
| **MEDIUM** | ordinary feature/bugfix code | combined analytical pass + 4 lenses (+ ux/perf only if a screen is touched) |
| **HIGH** | auth / RLS / payments / public (unauthenticated) / schema | full battery incl. `/cr-security` red-team + mandatory human sign-off |

Signals it reads (deterministic, path/diff-derived — never a model judgment in the merge decision):
paths touched (auth, middleware, RLS/policies, schema/migrations, payments, public routes, `next.config.*`),
diff size, test delta, in-scope-ness.

## The guard (R4-D32 #5) — bias toward over-classifying

The classifier gates **all downstream safety**: under-classify a HIGH change as LOW and the whole safety
battery is skipped on the one diff that needed it most. The failure is asymmetric:

- **Under-call** (HIGH rated LOW) → a real hole ships unreviewed. **Catastrophic.**
- **Over-call** (LOW rated HIGH) → a few extra checks run. **Merely wasteful.**

So the rule is a **hard requirement**, not a preference:

> **When any HIGH signal is present or the tier is uncertain, classify UP.** A change that *touches* an
> auth / RLS / payments / public-route / schema path is HIGH even if the diff is one line and reads as
> trivial. Ambiguity resolves toward the higher tier, never the lower.

Because the rule is deterministic and path-based, "uncertain" mostly means "a blast-radius path is touched
but the change looks harmless" — exactly the **looks-trivial-but-isn't** case. Those are the trap cases below.

## How it is measured — the trap subset of the bug-catch test

The under-call rate is measured, not asserted. The [bug-catch test](../bug-catch/README.md) carries a
subset of **trap cases** (`trap: true` in the case frontmatter): minimal, innocuous-looking diffs whose
correct tier is HIGH (a one-line RLS opening, a removed auth guard, a widened public-route matcher, a
client-supplied price, a dropped NOT NULL). A trap **missed** = the reviewer/classifier under-tiered it.

```
bash bug-catch/score.sh --traps results/<run>.tsv
```

prints the trap-subset breakdown: `trap cases`, `under-calls` (= misses), `trap recall`, and the 95% Wilson
lower bound — **the classifier-guard gate**. Bias the classifier up until the trap-recall lower bound stays
high; every escaped under-call becomes a new trap case (auto-grow, same pipeline as the rest of the set).

## Build checklist (when this becomes code)

- [ ] Emit LOW/MEDIUM/HIGH from paths + diff size + test delta + scope (deterministic; no model call in the gate).
- [ ] Encode the over-classify rule: any HIGH-path touch or ambiguity → HIGH.
- [ ] Run the bug-catch trap subset against it; gate on the trap-recall lower bound (`score.sh --traps`).
- [ ] Wire the tier to the battery (LOW→1 pass, MEDIUM→analytical+lenses, HIGH→full + `/cr-security` + human sign-off).
- [ ] Reuse this one classifier everywhere it is needed — do not invent a second (R4-D32 #2 / LOOP-7 / A6).
