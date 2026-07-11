# docs/specs/ — per-feature behavioral contracts

A spec answers the question code and context docs don't: **what is this feature
supposed to do, and how do we know it still does it?** One file per feature,
created from `docs/templates/spec.md`, kept current for the life of the feature.

**Files are named for the feature, not the branch.** A feature outlives every
branch that touches it. Before creating a new spec, search this directory for
an existing spec that covers the feature (check `feature:` frontmatter and
Implementation pointers against the files you're changing) — update that spec
instead of creating a sibling. A second spec for the same feature is a bug.

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
| `building` | Approved and mid-change | `/feature` sets it when the human approves; a later task that changes a `complete` feature's behavior also flips it back to `building` |
| `complete` | Shipped; bottom half current; Verification passing | Set at spec close-out, in the same PR, before `/cr` |

The whole `building` window lives inside one branch: approval flips it on,
close-out flips it to `complete`, and `/cr` runs after close-out. `/cr` Pass 7
flags any spec on a shipped feature left short of `complete` — a spec left
behind is doc drift.

## Rules

1. **Spec before code.** `/feature` creates or updates the spec before design
   starts (Small and above). No approved spec, no build.
2. **Cold-start rule — every tier, including Tiny.** Modifying a feature that
   has a spec? Read the spec first. If the change alters behavior, update the
   Behavior list *before* changing the code — the spec's git history is the
   changelog of intent. A one-behavior Tiny fix to a specced feature still
   updates the spec.
3. **Verification is executable and safe to run.** Every Verification item is
   a command with an expected result. Prose ("check it works") fails review.
   Commands run headlessly from the repo root, never write outside the
   worktree, never call the network, never read credentials — reviewers read
   each command before running it, and the harness's bash locks (dangerous-bash
   block, egress allowlist, credential firewall) apply to them like any other
   agent command. Steps that need a running app go on `manual:` lines, which
   `/cr` routes to the manual test checklist. `/cr` runs the executable items
   and updates `last-verified` on pass.
4. **No self-certification.** The spec gets an independent adversarial pass
   (`/grill-with-docs` at Small, `@design-griller` at Medium+) — the agent that
   wrote the spec never solely approves it. Spec-first has no built-in
   adversary unless we add one.
5. **A human approves the top half.** `human-approved: true` is set only by a
   human, after reading Outcome and User journey. This is the factory's
   requirements gate: a non-engineer directs the work without writing task
   contracts. Honest limit: today this is process, not a lock — no hook
   verifies who set the field (unlike `.design-confirmed`, which has a guarded
   sentinel). Making it mechanically enforceable is future guard work, and
   guard files are human-edit-only.

## Known gap

The `/queue` → `@task-runner` fleet path does not create, approve, or verify
specs yet — it uses `@spec-writer` (testing shards) and `@reviewer`, not `/cr`,
so nothing on that path runs a spec's Verification section. Agent definitions
under `.claude/agents/` are human-edit-only, so wiring it needs a human commit.
Until then, specs are only created and verified on the `/feature` + `/cr` path.

## How this relates to the other doc classes

- `docs/testing/<slug>.md` — confirmed *test* behaviors for TDD slices. The
  spec's Behavior list is the source those entries trace back to.
- `docs/adr/` — cross-feature *decisions*. A spec is one feature's contract.
- `TASKS.md` / issues — *work orders*. A spec outlives the work order.
