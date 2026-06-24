# Session isolation via auto-created worktree

**Feature:** Auto-create a git worktree at `SessionStart` when the session is starting from the main branch in the main repo. Clean up the worktree at `SessionStop` if no work was done.

**Goal:** Prevent one-off edits from landing directly on main when the user skips `/feature`.

---

## Confirmed behaviors

### B1 — SessionStart creates a worktree when on main in the main repo

When `session-start.sh` runs and:
- the current directory is the main repo (`.git` is a directory, not a file), AND
- the current branch is `main` or `master`

Then it creates a git worktree at `.claude/worktrees/<session-id>/` on a branch named `session/<session-id>`, writes the worktree path to `/tmp/claude-session-wt-<session-id>`, and prints a banner to stdout that includes the worktree path.

### B2 — SessionStart skips when already in a worktree

When `session-start.sh` runs and the current directory is already a worktree (`.git` is a file, not a directory), it does not create an additional worktree.

### B3 — SessionStart skips when not on main or master

When `session-start.sh` runs and the current branch is not `main` or `master` (e.g. `feat/some-feature`), it does not create a worktree. This avoids creating session branches on top of existing feature branches.

### B4 — SessionStop removes worktree and branch when no commits were added

When `session-stop.sh` runs and a session worktree exists (temp file present) and the session branch has 0 commits ahead of `main`, it removes the worktree and deletes the session branch silently. The temp file is also removed.

### B5 — SessionStop prints a summary and leaves the worktree when commits exist

When `session-stop.sh` runs and the session branch has 1 or more commits ahead of `main`, it prints a one-line message naming the branch and the commit count, then exits without removing the worktree.
