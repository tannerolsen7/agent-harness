# Problem: `git merge-base --is-ancestor` cannot distinguish an empty branch from a merged one

**Problem class:** False positive in branch-safety checks — a freshly-created branch with
no commits looks identical to a fully-merged branch when tested with ancestor-based checks.

## When this bites you

You have a cleanup script that deletes branches it considers safe to remove. The safety
check is:

```sh
if git merge-base --is-ancestor "$branch" HEAD 2>/dev/null; then
  # looks merged — delete it
  git branch -d "$branch"
fi
```

A parallel process creates new worktree branches (`git worktree add -b feat/task-1 ...`).
Each new branch has no commits; its tip is the same commit as its branch point. The cleanup
script runs, decides each new branch is "merged," and deletes all four — mid-run, before
any work was committed to them.

This is what happened in agent-harness when `/queue` provisioned four task worktrees and
`prune-branches.sh`'s NO_UPSTREAM pass ran at session start and wiped them.

## Root cause

`git merge-base --is-ancestor A B` returns true when commit A is reachable from commit B by
following parent links. When you create a new branch, its tip IS the branch point commit.
That commit IS reachable from HEAD. The check returns true — but "reachable" and "was merged"
are not the same thing.

They are only the same thing when the branch has at least one commit beyond the branch point.
If a branch has zero new commits, the check cannot distinguish it from a merged branch.

This is not a bug in git. It is a fundamental property of DAG-based history. There is no
git command that answers "was this branch ever merged?" — only "is this commit reachable
from that one?" A zero-commit branch is, by definition, reachable from wherever it was
branched.

## The fix

Collect all branches currently checked out in a worktree. Exclude them from the candidate
list before applying the safety check. An active worktree branch is in use by definition
and must never be deleted, regardless of what ancestor checks say.

**Step 1 — collect active worktree branches:**

```sh
ACTIVE_WT_BRANCHES=$(git worktree list --porcelain \
  | awk '/^branch /{sub(/^branch refs\/heads\//, ""); print}' \
  || true)
```

`git worktree list --porcelain` emits one block per worktree. The `branch` line looks like:
`branch refs/heads/feat/task-1`. The `awk` strips the `refs/heads/` prefix to leave the
bare branch name.

**Step 2 — filter them from the candidate list:**

```sh
if [ -n "$ACTIVE_WT_BRANCHES" ]; then
  NO_UPSTREAM=$(printf '%s\n' "$NO_UPSTREAM" \
    | grep -vFxf <(printf '%s\n' "$ACTIVE_WT_BRANCHES") \
    || true)
fi
```

Flag meanings:
- `-F` — treat each line as a fixed string, not a regex. Branch names can contain `.` and
  `[` which grep would otherwise treat as metacharacters.
- `-x` — require a full-line match. Without this, a branch named `main` would also exclude
  `main-old`.
- `-f` — read patterns from a file or process substitution.

**Also harden the current-branch exclusion** from `grep -v "^${CURRENT}$"` to
`grep -vFx "${CURRENT}"` for the same reason: branch names with dots or brackets would be
misread as regex patterns.

## Why only the NO_UPSTREAM pass needs this

The `prune-branches.sh` GONE pass (branches whose remote tracking ref was deleted by GitHub after merge)
does not need this exclusion. GitHub deletes the remote ref only when a PR is merged. A
freshly-created branch with no commits and no PR cannot have a deleted remote ref — it can't
appear in the GONE candidate list at all. The empty-branch problem is specific to logic that
uses local-only signals (no-upstream status, ancestor checks) without a GitHub merge event
as a prerequisite gate.

## The three-exclusion checklist for prune-branches.sh passes

Every candidate-collection pass in `scripts/prune-branches.sh` must apply all three exclusions before
the deletion loop:

| Exclusion | Pattern |
|---|---|
| Protected names | `grep -vE "^(main\|master\|develop)$"` |
| Current branch | `grep -vFx "${CURRENT}"` |
| Active worktree branches | `grep -vFxf <(printf '%s\n' "$ACTIVE_WT_BRANCHES")` |

The first two were present on the GONE pass from the start. The NO_UPSTREAM pass was added
later and got the first two but not the third. A new pass added in the future starts at zero
— copy all three, do not rely on "this class of branch wouldn't appear here" reasoning.

## The general rule (replicate this anywhere you use ancestor checks for deletion)

If your deletion logic contains `git merge-base --is-ancestor "$branch" HEAD`, add one of:

1. **Worktree check** (prune-branches.sh pattern above) — if the branch might be checked out in a
   worktree.
2. **Commit-count check** — verify the branch has at least one commit beyond its merge-base
   with main before treating it as merged: `[ "$(git rev-list --count main.."$branch")" -gt 0 ]`.
3. **Remote-event gate** — require a GitHub merge event (branch deleted on remote) before
   acting. A branch that GitHub never deleted was never merged through a PR.

Option 1 is the right choice for `prune-branches.sh` because the worktree list is always available and
is the exact thing you want to protect. Option 2 is the fallback for scripts that operate
outside the worktree context. Option 3 is what the GONE pass already uses.

## Where this applies in the codebase

- `scripts/prune-branches.sh` lines 44–62 — the NO_UPSTREAM pass collects `ACTIVE_WT_BRANCHES` and
  applies all three exclusions before the deletion loop.
- `tests/prune-branches.test.sh` — the regression test that provisions a zero-commit worktree branch
  and confirms gc does not delete it.

## Related

- `docs/solutions/2026-06-17-detection-path-exclusion-inheritance.md` — covers the
  protected-name exclusion gap (the first instance of a missing exclusion on this pass).
  This doc covers the worktree exclusion gap (the second instance).
- `docs/RECURRING-FINDINGS.md` § `new-detection-path-missing-branch-exclusions` — tracks
  both instances as a recurring class.

## Tags

git, gc, branch cleanup, merge-base, is-ancestor, empty branch, worktree, exclusion rules,
multi-pass collection, grep -vFxf, fixed-string, shell script, false positive
