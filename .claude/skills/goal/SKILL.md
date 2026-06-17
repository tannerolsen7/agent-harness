---
name: goal
description: |
  One adaptive front door for stating a goal. Sizes the work, then routes to the
  right existing skill — never implements. Use when the user states an outcome
  without a chosen path: "I want to X", "we need X", "can you make X happen",
  "here's the goal", "get this done", or invokes /goal. Routes a single confirmed
  near-trivial behavior to /tdd, and anything needing discovery, planning, or
  multi-step work to /feature. Do not use when the path is already chosen — go
  straight to that skill.
---

# /goal — One front door. Size first. Route second. Never implement.

A goal is an outcome, not a plan. The user knows what they want to be true; they
do not yet know how big the work is or which skill owns it. That sizing-and-routing
decision is this skill's only job.

`/goal` routes. It does not implement, and it does not duplicate what `/feature`
or `/tdd` already do. Its output is a size judgment, a named target skill, and the
hand-off. The target skill does the work.

## Routing targets

| Target | When it owns the goal | What it requires going in |
|---|---|---|
| **/tdd** | A single, already-confirmed behavior — one test, one commit, no discovery left | The behavior is in `docs/TESTING.md` → confirmed behaviors (or the user states it precisely enough to record there first). One behavior, not several. |
| **/feature** | Everything else — anything needing discovery, planning, design, decomposition, or more than one behavior | Nothing pre-confirmed; `/feature` Step 0 sizes it (Tiny / Small / Medium / Large) and runs the sized pipeline. |

These are the only two targets. `/goal` never invents a third route and never
fixes anything itself.

## The routing rule

Apply the first rule that matches, top to bottom:

1. **More than one behavior, or any open question about what/how/whether** → `/feature`.
   Discovery, design, decomposition, multiple slices, "I'm not sure if…", "should we…"
   — all of these are `/feature`'s job, regardless of how small each piece feels.
2. **Exactly one behavior, already confirmed, nothing left to decide** → `/tdd`.
   "Confirmed" means it is in `docs/TESTING.md` → confirmed behaviors, or the user
   states it precisely enough that the next step is to record it there and write the
   test — no grilling, no design, no plan required.
3. **Exactly one behavior but NOT yet confirmed** → `/feature` (it will land as Tiny).
   A lone behavior that still needs the user to confirm expected output, or that
   touches an unread part of the system, is a Tiny `/feature` — not a direct `/tdd`.
   `/feature`'s Tiny tier exists precisely to confirm → record in TESTING.md → call
   `/tdd` with a contract. Skipping to `/tdd` here would skip the confirmation step
   `/tdd` itself demands.

This mirrors how the system already routes: `/debug` hands a *known* single-behavior
fix to "`/feature` (Tiny)", not straight to `/tdd`. `/goal` follows the same boundary.

## At the boundary — the tie-breaker

When a goal looks like it could be either, **route to `/feature`.** `/feature`'s
Step 0 sizing is the authoritative sizer; its Tiny tier is cheap (confirm →
TESTING.md → `/tdd` → `/simplify` → `/cr`) and it will itself drop down to `/tdd`
for the single slice. The only goals that go *directly* to `/tdd` are the ones that
clear all three of these:

- **One** behavior — not two dressed up as one.
- **Confirmed** — expected behavior is settled and recorded (or trivially recordable)
  in `docs/TESTING.md`, not something the user still needs to decide.
- **No discovery** — the interface and the affected files are already known; nothing
  needs to be read, grilled, or designed first.

Miss any one of the three and the goal is a `/feature` (Tiny at smallest). When in
doubt, `/feature` — over-routing to `/feature` costs a few minutes of sizing;
under-routing to `/tdd` skips the confirmation and discovery the work actually needed.

## What this is not

- **Not an implementer** — `/goal` writes no code and no tests. It hands off.
- **Not a second sizer** — `/feature` Step 0 owns the Tiny/Small/Medium/Large call.
  `/goal` only decides *which skill* sizes and runs the work; it does not pre-assign
  a tier.
- **Not a re-implementation** — it never duplicates `/feature`'s discovery/plan steps
  or `/tdd`'s red-green loop. It points at them.
- **Not for an already-chosen path** — if the user already named the route ("run
  /tdd on this", "use /feature"), or another skill has already classified the work
  (`/incident`, `/debug`), go straight there. `/goal` is for a bare goal with no
  path yet chosen.

## Anti-rationalization

| Rationalization | Rebuttal |
|---|---|
| "This is one tiny behavior, send it straight to /tdd" | Only if it is already confirmed in TESTING.md with no discovery left. If the user still has to confirm what "correct" means, it is a /feature (Tiny) — that is the tier that confirms then calls /tdd. |
| "It's basically two small behaviors, /tdd can do both" | /tdd is one behavior = one test = one commit, by rule. Two behaviors is /feature, which decomposes them. |
| "I can see the design, I'll just route to /tdd and skip /feature" | Seeing the design is not the same as it being confirmed and recorded. If discovery or design happened in your head, it still needs to happen on the record. /feature. |
| "Routing to /feature for something this small is overkill" | /feature's Tiny tier is five minutes and ends in /tdd anyway. Over-routing costs minutes; under-routing skips confirmation and review. |
| "The goal is clear enough, I'll just start building" | /goal's whole job is to not start building. State the size, name the target, hand off. |

## The hand-off

1. **Restate the goal** in one sentence as an outcome ("X is true / X happens"),
   so the target skill inherits a clean problem statement.
2. **Apply the routing rule** above and name the target — `/tdd` or `/feature`.
3. **State why** in one line: which rule matched (one confirmed behavior → /tdd;
   more than one behavior / unconfirmed / discovery needed → /feature).
4. **Invoke the target skill.** Do not do its work yourself. `/feature` runs its
   own Step 0 sizing and full pipeline; `/tdd` confirms the behavior is in
   `docs/TESTING.md` and runs its red-green loop.

## Final report format

```
## /goal routed
Goal: <one-sentence outcome>
Behaviors: <one | more than one>
Confirmed: <yes — in docs/TESTING.md | no>
Discovery needed: <yes | no>
Routed to: </tdd | /feature>
Why: <which routing rule matched>
```

## Done criteria

- Goal restated as a single-sentence outcome
- Routing rule applied; target is exactly one of `/tdd` or `/feature`
- Direct-to-`/tdd` only when all three hold: one behavior, confirmed, no discovery
- Target skill invoked — `/goal` wrote no code and ran no pipeline of its own
- Final report delivered
