# Agent-triggered worktree and branch cleanup after merge

## What & Why

When an agent finishes a task, its worktree and branch linger until the next session
start (when `prune-branches.sh` runs its global sweep). In a repo with many parallel
tasks, those leftovers add up. An agent should be able to clean up its own worktree
and branch right after the PR merges — without waiting for the next human session.

## Context

- `scripts/prune-branches.sh` — the existing global sweep. Runs at session start and
  after `/queue` merge batches. This new script is a targeted, single-worktree version.
- `scripts/worktree-add.sh` — counterpart: creates worktrees. `cleanup-worktree.sh`
  is the teardown mirror.
- `.claude/agents/task-runner.md` — the pipeline that will call this script. Its "On
  completion" section ends by returning a summary to /queue. The cleanup call goes
  last, after everything else is done.
- Absolute paths are fine for `git worktree remove` — no blocking hook exists for
  them. `prune-branches.sh` and `worktree-add.sh` both already use absolute paths.

## Done Looks Like

- `bash scripts/cleanup-worktree.sh .claude/worktrees/my-task` when branch is merged
  into main → worktree removed, branch deleted, recovery SHA printed, exit 0
- Same call when branch is NOT yet merged → prints "branch not yet merged — nothing
  done", exit 0
- Called with a path outside `.claude/worktrees/` → prints error, exits 1
- Called from inside a worktree with no argument → derives path from CWD, behaves as
  above
- Squash-merged branch (where `merge-base --is-ancestor` is false) → detected via
  `gh pr list --state merged` when `gh` is available, cleaned up; when `gh` is absent,
  treated as "not merged" (safe no-op)
- Called twice on an already-removed worktree → exits 0, no error (idempotent)
- `task-runner.md`'s "On completion" section includes a `bash scripts/cleanup-worktree.sh`
  call as the final step

## Interface Contract

### scripts/cleanup-worktree.sh (new)

Inputs:
- `WORKTREE_PATH` (optional positional arg): path to clean up. If omitted, defaults
  to `git rev-parse --show-toplevel` from CWD (works when called from inside the
  worktree). Rejected (exit 1) if the resolved absolute path does not match
  `$REPO_ROOT/.claude/worktrees/*`.

Outputs:
- stdout: one-line status per action ("removed worktree: ...", "deleted branch ...",
  "branch X not yet merged — nothing done")
- Recovery hint printed before branch deletion: "recover: git branch <name> <sha>"
- Exit 0 on success or safe no-op; exit 1 on safety block (bad path, unexpected error)

### .claude/agents/task-runner.md (modification)

"On completion" — add a step 6 after the TASKS.md `[x]` update and before the return
summary:

```
6. Run cleanup: `bash scripts/cleanup-worktree.sh` (called from inside the worktree,
   no argument). This is speculative — the PR is usually not merged yet at this point.
   If it is (e.g., auto-merge landed), the worktree and branch are cleaned up
   immediately. If not, `prune-branches.sh` at the next session start handles it.
   Exit code is always 0; never block the return summary on this step.
```

Constraints:
- Must never delete a branch without first confirming it is merged into main (ancestor
  check or `gh` confirmation). Not merged → exit 0, no-op.
- Must never touch anything outside `.claude/worktrees/`. Path outside that prefix →
  exit 1 immediately.
- Remove the worktree BEFORE deleting the branch — git refuses to delete a branch that
  is still checked out in a live worktree.
- Use `git branch -d` (soft delete). Fall back to `git branch -D` ONLY when `gh`
  confirms a squash-merge — the merge proof must precede the force delete.
- Script is POSIX sh — no bash arrays, no `$((...))` arithmetic, no `[[` tests.
- Idempotent: if the worktree or branch was already removed, exit 0 silently.

State:
- No persistent state. Removes the worktree directory, git's internal worktree
  registration, and the local branch ref.

## Out of Scope

- Cleaning up remote branches (Pass B in `prune-branches.sh` handles that)
- Deleting branches outside `.claude/worktrees/` scope
- Waiting/polling for a PR to merge — the call is speculative; the merge check is
  the gate
- Replacing `prune-branches.sh` — this is an additive complement, not a replacement

## Relevant Files

- `scripts/cleanup-worktree.sh` (NEW)
- `scripts/prune-branches.sh` — model for the merge-verify gate and worktree-remove
  pattern (lines 120–180)
- `.claude/agents/task-runner.md` — "On completion" section; add step 6
- `docs/solutions/2026-06-17-worktree-git-file-detection.md` — `.git` file check
  for detecting whether a path is a live worktree

---

## Design Questions Sheet

### 1. Data shape

No database or schema changes. No Zod boundaries. The inputs and outputs are git
operations only.

**Script inputs:**
- `WORKTREE_PATH` (string): resolved to absolute path before any check.
  Must match `$REPO_ROOT/.claude/worktrees/*` or the script exits 1.
- Branch name: derived inside the script via
  `git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD`.

**Merge-check inputs (same pattern as `prune-branches.sh`):**
- `git merge-base --is-ancestor <branch-tip> origin/main` — true for regular merges
- `gh pr list --head <branch> --state merged --json number -q '.[0].number'`
  — detects squash-merges when `gh` is available

**State changes on confirmed merge:**
1. `git worktree remove "$WORKTREE_PATH"` — removes directory + git registration
2. `git branch -d "$BRANCH"` (or `-D` after squash-merge proof) — removes local ref
3. Prints recovery SHA before deletion (same pattern as `prune-branches.sh` line 174)

No persistent state written. No other files modified.

### 2. Edge cases

- **Path outside `.claude/worktrees/`**: exit 1 before touching anything.
- **Worktree is the main repo root** (`.git` is a directory, not a file): exit 1 as
  a secondary check — the path guard should catch it first.
- **Branch not merged**: exit 0, print "branch X not yet merged — nothing done".
- **`gh` absent + squash-merge**: `merge-base --is-ancestor` returns false, `gh`
  unavailable → treated as "not merged", exit 0. `prune-branches.sh` catches it at
  the next session start when `gh` is available.
- **Worktree directory already removed, branch still exists**: skip
  `git worktree remove`, go straight to `git branch -d`. Idempotent path.
- **Branch already deleted**: `git branch -d` exits non-zero; suppress the error and
  exit 0 — both are cleaned up, which is the desired end state.
- **Called from inside the target worktree (no arg)**: `git rev-parse --show-toplevel`
  returns the worktree path. Path guard runs on the resolved absolute path.
- **Called twice**: second call finds no worktree directory, no branch; exits 0.

### 3. Open questions the robot must NOT answer

1. **No fetch before check.** Reads last-fetched remote state. Fast. Misses a
   just-merged PR until the next fetch, but `prune-branches.sh` catches it at
   session start.

2. **Cleanup runs before return summary** — step 6 of "On completion", after `.cr-ok`
   and TASKS.md `[x]` update, before handing results back to /queue.

3. **No PITFALLS entry.** `prune-branches.sh` already handles squash-merge cleanup
   at session start. The no-op is safe and documented in the script itself.
