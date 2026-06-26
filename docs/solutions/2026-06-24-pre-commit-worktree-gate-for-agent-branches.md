# Problem: Agents Bypass the Worktree Requirement by Committing in the Main Worktree

**Problem class:** The pre-push hook requires that agent pushes come from a dedicated worktree (`.git` is a file, not a directory). But the check runs too late — an agent can make edits in the main worktree, create a branch there, commit to it, and clear `/cr` before push ever runs. The worktree requirement is never actually enforced.

## When this bites you

An agent is working on a documentation change. It edits a file directly in the main worktree while on `main`. Then it invokes `/cr`, which creates a branch (`docs/cr-auto-merge-sync`) from the uncommitted changes and commits them on that new branch — still inside the main worktree, not inside a dedicated worktree.

The `/cr` skill finishes and writes `.cr-ok`. When `scripts/worktree-add.sh` runs later to create the proper worktree for the branch, it fails with an error like:

```
fatal: '<branch>' is already checked out at '<main-worktree-path>'
```

The branch is stuck. It cannot be added to a new worktree because the main worktree already has it checked out. The agent committed on the wrong branch, in the wrong location, and the gate that was supposed to prevent this never fired.

The pre-push hook does check for worktree validity — but only at push time. By then there are already commits on the wrong branch, in the wrong worktree.

## Root cause

The worktree guard lives only in `.husky/pre-push`. It checks whether `.git` is a file (dedicated worktree) or a directory (main worktree). That check is correct, but it fires after the work is already done:

1. Agent edits files in main worktree.
2. Agent creates branch and commits.
3. Agent runs `/cr`, sentinel is written.
4. Pre-push runs → sees `.git` is a directory → blocks.

By step 4, there are already commits on the branch from the wrong location. The user must now manually clean up the branch history or delete and recreate the worktree.

The fix is to move the check earlier — to pre-commit — so the very first commit on a feature branch from the main worktree is blocked.

## The fix

Add a worktree check to `.husky/pre-commit`. The check runs only for agent processes (no TTY) committing on a feature branch from the main worktree (`.git` is a directory):

```sh
COMMIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
case "$COMMIT_BRANCH" in
  main|master|HEAD|"") ;;
  *)
    if [ -d .git ] && ! { exec 3</dev/tty; } 2>/dev/null; then
      exec 3<&- 2>/dev/null || true
      _SLUG=$(printf '%s' "$COMMIT_BRANCH" | sed 's|.*/||')
      printf "commit blocked: '%s' must be committed from a dedicated worktree.\n" "$COMMIT_BRANCH" >&2
      printf "  Create one: bash scripts/worktree-add.sh .claude/worktrees/%s %s\n" "$_SLUG" "$COMMIT_BRANCH" >&2
      exit 1
    fi
    exec 3<&- 2>/dev/null || true
    ;;
esac
```

Place this block in `.husky/pre-commit` before the lint checks, so it fires first and gives a clear, actionable message before anything else runs.

Three conditions must all be true to block:

| Condition | What it checks |
|---|---|
| Branch name not in `main|master|HEAD|""` | Only feature branches need worktrees. Committing to main in the main worktree is normal. |
| `.git` is a directory (`[ -d .git ]`) | Dedicated worktrees have a `.git` file, not a directory. A directory means this is the main worktree. |
| No TTY (`! { exec 3</dev/tty; }`) | Agents have no terminal. Humans do. This makes the block agent-only. |

If any condition is false, the check passes silently. Human commits in the main worktree on any branch are unaffected.

## Why TTY detection is the right discriminator

Agents run as non-interactive subprocesses — they have no controlling terminal. Humans run in a terminal — they do. The `/dev/tty` probe is the standard POSIX way to test for an interactive session without relying on environment variables, which can be set or unset in both directions.

An agent trying `exec 3</dev/tty` gets a "no such device" error (exit non-zero). A human gets a valid file descriptor (exit zero). The `!` in the condition inverts this: block when the test fails (agent), pass when it succeeds (human).

This is the same discriminator used in other hooks in this codebase (see `.husky/pre-push` non-interactive path).

## Why pre-commit, not just pre-push

Pre-push catches the violation only after commits have accumulated. By then:

- The branch is checked out in the wrong worktree.
- `worktree-add.sh` cannot create a proper worktree for it.
- The user must either manually rebase onto a clean worktree or delete and recreate the branch.

Pre-commit catches the violation at the first commit. The error message includes the exact command to create the right worktree:

```
commit blocked: 'docs/cr-auto-merge-sync' must be committed from a dedicated worktree.
  Create one: bash scripts/worktree-add.sh .claude/worktrees/cr-auto-merge-sync docs/cr-auto-merge-sync
```

The agent (or human) can run that command, switch to the new worktree, and commit there. No cleanup required.

## The general pattern for agent-only enforcement

Any gate that currently lives only in pre-push should be evaluated for a pre-commit mirror when commits from the wrong setup are themselves the problem (not just the push).

Ask: at what point does the violation actually happen? If the answer is "at the first commit," enforce it at pre-commit. If the answer is "at push time," pre-push is sufficient.

The TTY + `.git` directory test is the right discriminator whenever the rule is "agents must do X, humans are exempt."

## What doesn't work

**Pre-push only:** The worktree is already the wrong one when the hook fires. Cleanup is required.

**Checking the `CLAUDE` environment variable:** Some harness scripts set `CLAUDE=1` for agent processes, but this variable can be set by accident in human shells, and it is not guaranteed across all agent invocations. TTY detection is more reliable because it tests the actual process context, not a variable value.

**Blocking all commits to feature branches from the main worktree:** Without the TTY check, this would block humans too. A developer starting work on a feature before running `worktree-add.sh` would get an unhelpful error. The TTY check limits the block to automated agents.

## Tags

git, pre-commit, pre-push, worktree, agent, TTY detection, enforcement, hook, defense-in-depth, gate-placement, non-interactive
