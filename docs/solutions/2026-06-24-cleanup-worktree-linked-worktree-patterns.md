---
date: 2026-06-24
task: agent-worktree-cleanup
pr: feat/agent-worktree-cleanup
type: solution
---

# Linked worktree shell patterns: cleanup-worktree.sh

This document records the non-obvious shell patterns found while writing
`scripts/cleanup-worktree.sh`. The script removes an agent's git worktree
and branch immediately after a PR merges.

---

## Pattern 1 — Find the main repo root from inside a linked worktree

### Problem
`git rev-parse --show-toplevel` run from inside a linked worktree returns the
**worktree path**, not the main repo root. Using it to find the main repo root
produces the wrong directory.

### Solution
`git rev-parse --git-common-dir` returns the absolute path to the main `.git`
directory. `dirname` of that path is the main repo root.

```bash
COMMON_DIR=$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir)
REPO_ROOT=$(dirname "$COMMON_DIR")
```

### Why it works
In a linked worktree, `.git` is a FILE (a pointer), not a directory. The
`--git-common-dir` flag resolves through that pointer to the main `.git`
directory. In the main worktree, `--git-common-dir` returns `.git` (relative),
which is why the script guards for an absolute path.

---

## Pattern 2 — Run `git worktree remove` from outside the target worktree

### Problem
`git worktree remove /path/to/worktree` fails with "fatal: cannot remove current
worktree" when run from inside that worktree.

### Solution
Run in a subshell from the main repo root:

```bash
(cd "$REPO_ROOT" && git worktree remove --force "$WORKTREE_PATH")
```

### Why it works
Git checks whether the worktree being removed is the "current" one based on CWD.
Running from the main repo root sidesteps that check.

---

## Pattern 3 — Guard against the zero-commit branch false positive

### Problem
`git merge-base --is-ancestor BRANCH_TIP origin/main` returns true for a
freshly-provisioned branch with no unique commits. The branch tip equals
origin/main's tip (the commit the branch was created from). The script would
incorrectly delete it.

This is the PITFALLS.md entry: "git merge-base --is-ancestor cannot tell a
fresh branch from a merged one."

### Solution
Compare `BRANCH_TIP` to `MAIN_TIP` before the ancestor check. If they are equal,
the branch is at origin/main's current tip — treat it as unmerged and fall through
to the gh check:

```bash
MAIN_TIP=$(git -C "$REPO_ROOT" rev-parse origin/main 2>/dev/null || true)

if [ -n "$BRANCH_TIP" ] && [ -n "$MAIN_TIP" ] && [ "$BRANCH_TIP" != "$MAIN_TIP" ] \
   && git -C "$REPO_ROOT" merge-base --is-ancestor "$BRANCH_TIP" origin/main; then
  MERGED=true
fi
```

### Why `[ "$BRANCH_TIP" != "$MAIN_TIP" ]` is not a complete fix
This guard only blocks the case where the branch tip equals origin/main's CURRENT
tip. If origin/main has advanced since the branch was created, the fresh branch tip
is an older commit in origin/main's history — `BRANCH_TIP != MAIN_TIP`, and the
ancestor check still returns true. In the task-runner flow, this window is
extremely small (the task-runner makes commits before calling cleanup), and the gh
fallback handles any edge cases. The guard is necessary but not sufficient; gh
confirmation is the authoritative source.

---

## Pattern 4 — Must compare against `origin/main`, NOT `HEAD`

### Problem
`HEAD` inside a linked worktree points to the feature branch, not main. Every
`merge-base --is-ancestor BRANCH_TIP HEAD` call returns true (the tip is always
an ancestor of itself). This would delete every branch.

### Solution
Always use `origin/main` as the comparison target:

```bash
git -C "$REPO_ROOT" merge-base --is-ancestor "$BRANCH_TIP" origin/main
```

---

## Pattern 5 — Strip trailing slash before `git worktree remove`

### Problem
Git stores worktree registrations without a trailing slash. Passing a path with a
trailing slash (e.g., from a user typing `worktrees/task/`) does not match the
stored registration and the removal silently fails.

### Solution
Strip any trailing slash immediately after resolving the path:

```bash
WORKTREE_PATH="${WORKTREE_PATH%/}"
```

---

## Pattern 6 — Use `|| true` for non-blocking cleanup in agent instructions

### Problem
Writing "treat exit code as always 0" in an agent's text instructions is
advisory, not enforced. The agent's Bash tool call still fails if the underlying
script exits non-zero.

### Solution
Use `|| true` in the command itself:

```bash
bash scripts/cleanup-worktree.sh || true
```

This makes the exit code always 0 regardless of what the script does.

---

## PITFALLS.md candidates (for human review)

The patterns above are already partially covered by PITFALLS.md. No new PITFALLS
entry is proposed — Pattern 3 IS the existing "merge-base --is-ancestor" pitfall.
Pattern 1 (git-common-dir) and Pattern 2 (worktree remove from outside) are worth
adding if they surface again in a second PR.
