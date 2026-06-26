# Problem: Auto-Rebase Breaks Automated Tool Workflows

**Problem class:** An automated tool (skill, hook, or agent) needs to sync a feature branch with the base branch before operating on it. Using rebase to do this forces a history rewrite, may leave the repo in a broken mid-rebase state if conflicts arise, and conflicts with existing project guidance that recommends merge as the safe fallback.

## When this bites you

You have a feature branch that has fallen behind `main`. An automated tool — say, the `/cr` review skill — detects the divergence and decides to sync before proceeding. It runs `git rebase origin/main` automatically. Two things can go wrong:

1. The rebase succeeds but rewrites history. If the branch was already pushed, the next push must use `--force`. Automated tools generally cannot do this safely — force-pushing destroys remote history without warning.

2. The rebase hits a conflict and stops mid-way. The repo is now in a `REBASE_HEAD` state. The tool exits, the user is left with a half-applied rebase, and recovery requires manual `git rebase --abort` before anything else can run.

Both scenarios break the automated workflow and leave the developer to clean up a mess the tool created.

## Root cause

Rebase rewrites commit SHAs. That is its purpose in interactive developer workflows — it produces clean linear history. But in automated tools, SHA rewriting has no safe landing zone:

- If the branch is untracked: the rewrite is harmless but also pointless — merge would have been simpler.
- If the branch is already pushed: the rewrite orphans the remote branch. The only recovery is `--force-push`, which automated tools should never run without explicit human instruction.
- If the rebase conflicts: git stops and waits for human input. An automated tool cannot provide that input.

PITFALLS.md (line 328) covers this explicitly: "Never auto-rebase inside a pre-push hook. Block-and-instruct instead." The reasoning applies equally to any automated tool, not just hooks.

## The fix

Use `git merge origin/$BASE` instead of rebase. On success, the tool continues. On conflict, it runs `git merge --abort` and surfaces the conflicts to the user.

The pre-flight step in `.claude/skills/cr/SKILL.md` implements this pattern:

```bash
BASE=$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}')
[ -z "$BASE" ] || [ "$BASE" = "(unknown)" ] && BASE="main"
git fetch origin "$BASE" --quiet 2>/dev/null || true

if ! git merge "origin/$BASE" --quiet 2>/dev/null; then
  git merge --abort 2>/dev/null || true
  echo "BLOCKED: branch has conflicts with origin/$BASE — resolve them, then re-run."
  exit 1
fi
# merge succeeded (or branch was already up to date) — proceed
```

If `git merge` exits non-zero, conflicts remain. `git merge --abort` resets the working tree to its pre-merge state — no lingering state, no half-applied changes. The user sees a clear message and only needs to run `git merge origin/$BASE` themselves, resolve the conflicts, and re-run the tool.

If `git merge` exits zero, either the branch was already up to date or git resolved all changes automatically. Either way the tool can proceed. The merge creates one new merge commit, but that commit does not rewrite any existing history.

## Why merge over rebase in automated tools

- **No history rewrite.** Merge adds one commit. It does not change the SHA of any existing commit. A branch that was already pushed can be pushed again with a normal `git push` — no `--force` needed.
- **Clean failure mode.** A conflicting merge exits non-zero and leaves the index dirty. `git merge --abort` fully undoes it. There is no mid-operation recovery state for the user to untangle.
- **Project guidance already endorses it.** PITFALLS.md line 266 explicitly lists `git merge origin/main` as the correct fix when rebase fails. Using merge here is consistent with the project's established preference.
- **The downstream gates don't care.** The `.husky/pre-push` hook and `scripts/pr.sh` check for the `.cr-ok` sentinel. Neither inspects whether the sync was done via rebase or merge. A merge commit satisfies all of them.

## What doesn't work

**Auto-rebase (`git rebase origin/$BASE`):**
- Rewrites history. Force-push required if branch is already remote. Automated tools must not force-push.
- Mid-conflict state (`REBASE_HEAD`) cannot be resolved without human input. The tool is stuck.

**Hard block — tell the user to sync manually, then re-run:**
- Correct for interactive developer workflows. Correct for hooks that cannot safely mutate the working tree. But for a review skill running in a worktree that is about to do a lot of work, refusing to sync at all means the user must run two commands to accomplish what one should do.
- Use block-and-instruct when the tool cannot safely recover from a bad sync. Use auto-merge when a clean rollback (`--abort`) is available.

**Running the review without syncing:**
- Reviewing a branch that is behind the base produces findings that may be invalidated by the commits it has not yet seen. The review is technically correct but practically stale.

## Tags

git, rebase, merge, sync, auto-merge, pre-flight, automated-tool, skill, hook, force-push, conflict-recovery, PITFALLS
