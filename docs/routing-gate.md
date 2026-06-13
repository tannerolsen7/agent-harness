# Routing-assertion gate (R4-D32 #3)

**What it is (plain):** if a change touches the dangerous parts of a project — database
migrations, access policies, auth, payments — it must have gone through that project's
**database-safety skill**, not slipped in unreviewed. The gate is the deterministic backstop for
"lean on built-in routing" (R4-D31): a mis-route that skips the DB-safety skill is the worst silent
failure, because the locks treat that skill as the net (R4-D8).

**Project-agnostic:** the harness never hardcodes what counts as "dangerous" or which skill reviews
it. The project declares both in `.claude/routing.json` (copy from `.claude/routing.example.json`).
With no config, the gate is inert.

## How the merge-time check works

`scripts/check-routing.sh` (run in CI via `ci-verify.sh`):
1. Reads `.claude/routing.json` — high-risk **path** patterns + high-risk **content** patterns +
   the required commit trailer.
2. Diffs the branch against the base (`origin/main`).
3. If a changed path or an added diff line matches a high-risk pattern, it requires a
   **commit trailer** `DB-Safety: <skill>` somewhere on the branch. Missing → the check fails
   (blocks the merge) and logs the mis-route signal.

**Why a commit trailer, not a sentinel:** the F6 review proved CI can't see gitignored/consumed
sentinels like `.cr-ok` (see [ci-gate.md](ci-gate.md)). A commit trailer lives in the history CI
*can* read. It is added by the agent after the DB-safety skill reviews the change; like any
in-repo marker it's forgeable, but the change + trailer both appear in the PR diff the human
reviews, and the merge-time re-check is on the exact head commit.

## The run-time picture (HIGH-3) — already covered, mostly

HIGH-3 noted the merge-time check is "too late — damage is run-time." In this harness the run-time
*damage* vector is already gated deterministically:

- **`block-dangerous-bash.sh` already blocks the destructive DB commands at run-time** — `db push`,
  `db reset`, `migrate deploy/reset`, `DROP`/`TRUNCATE`/`DELETE`-without-`WHERE`, etc. So the agent
  cannot *apply* a dangerous DB change live, routed or not.

A dedicated run-time hook that blocked *editing* a high-risk file (vs. applying it) is **not shipped**:
editing a migration file isn't itself damaging (applying it is, and that's already blocked), and a
clean run-time signal for "the DB-safety skill is active" doesn't propagate reliably from a skill to
a PreToolUse hook. Adding a flaky marker would be over-engineering. If a real need appears (e.g.
after autonomy ships), revisit with a deliberate session-marker mechanism.

## Project setup (one-time, per project that has a database)

1. `cp .claude/routing.example.json .claude/routing.json` and fill in YOUR high-risk path/content
   patterns + the DB-safety skill name.
2. Ensure `scripts/check-routing.sh` runs in CI (it's wired into `ci-verify.sh`) and that CI checks
   out full history (`fetch-depth: 0` / `GIT_DEPTH: 0` — already in the shipped CI templates) so the
   base diff works.
3. Workflow: when a change touches the high-risk surface, run the project's DB-safety skill, then add
   a `DB-Safety: <skill>` trailer to a commit on the branch. The gate passes; the human sees both the
   change and the attestation in the PR.
