# docs/specs/ — per-feature behavioral contracts

A spec answers the question code and context docs don't: **what is this feature
supposed to do, and how do we know it still does it?** One file per feature,
created from `docs/templates/spec.md`, kept current for the life of the feature.

The file has two halves:

- **Top half (requirements)** — Outcome, User journey, Edge cases, Out of scope.
  Written in business terms before any design or code. A non-engineer can write
  it, and a non-engineer can verify the shipped feature against it.
- **Bottom half (contract)** — Behavior, Implementation pointers, Verification.
  Filled in during the build. This is what a cold-start agent — one with zero
  memory of the original build — reads before touching the feature, so the
  fifth modification six months later doesn't silently break behavior nobody
  re-stated.

## Lifecycle

| `status` | Meaning | Who moves it |
|---|---|---|
| `draft` | Top half written, not yet approved | Author (human or agent) |
| `building` | Human set `human-approved: true`; build in progress | `/feature`, after approval |
| `complete` | Shipped; bottom half current; Verification passing | Set at spec close-out, same PR |

`/cr` Pass 7 flags any spec for a shipped feature whose `status` is not
`complete` — a spec left behind is doc drift.

## Rules

1. **Spec before code.** `/feature` creates or updates the spec before design
   starts (Small and above). No approved spec, no build.
2. **Cold-start rule.** Modifying a feature that has a spec? Read the spec
   first. If the change alters behavior, update the Behavior list *before*
   changing the code — the spec's git history is the changelog of intent.
3. **Verification is executable.** Every Verification item is a command with an
   expected result. Prose ("check it works") fails review. `/cr` runs the
   Verification section and updates `last-verified` on pass.
4. **No self-certification.** The spec gets an independent adversarial pass
   (`/grill-with-docs` at Small, `@design-griller` at Medium+) — the agent that
   wrote the spec never solely approves it. Spec-first has no built-in
   adversary unless we add one.
5. **A human approves the top half.** `human-approved: true` is set only by a
   human, after reading Outcome and User journey. This is the factory's
   requirements gate: a non-engineer directs the work without writing task
   contracts.

## How this relates to the other doc classes

- `docs/testing/<slug>.md` — confirmed *test* behaviors for TDD slices. The
  spec's Behavior list is the source those entries trace back to.
- `docs/adr/` — cross-feature *decisions*. A spec is one feature's contract.
- `TASKS.md` / issues — *work orders*. A spec outlives the work order.
