# Problem: Running Tests from Inside a Worktree Corrupts the Real Repo

**Problem class:** Test helpers that `git init` temp directories operate on the real repo instead of their temp repos when invoked from inside a git worktree — because git's autodiscovery walks up the directory tree past the worktree's `.git` file before it reaches the temp dir's `.git`. The result is silent repo corruption: spurious commits and a branch switch on the worktree, with no error.

## When this bites you

You are inside a worktree directory (`.claude/worktrees/before-coding-gate`). You run `bash scripts/run-tests.sh` or `npm test` directly. The tests complete and report success.

Then you notice:

- The worktree's branch has switched from `feat/before-coding-gate` to `feat/x`
- `git log` shows spurious `"init"` commits that do not belong to this feature
- `git push` is now blocked by the push guard hook because the branch changed

The corruption is silent — no test failure, no warning, no stderr. The test suite exits 0. The damage is only visible when you inspect the repo afterward.

## Root cause

The test helpers use a pattern like:

```bash
mk() {
  local d; d=$(mktemp -d)
  (cd "$d" && git init -b feat/x >/dev/null 2>&1 && git commit --allow-empty -m "init" >/dev/null 2>&1)
  echo "$d"
}
```

The subshell does `cd "$d"` and `git init`. That creates `.git` inside `$d`. So far, safe. The problem is `git commit` resolves the repo by walking up the directory tree from `$d` — and if `GIT_DIR` is set (or resolvable via autodiscovery), git uses it instead of `$d/.git`.

`run-tests.sh` does `unset GIT_DIR ...` at the top. That clears the exported env vars. But when invoked from inside `.claude/worktrees/before-coding-gate/`, the subshell has no inherited `GIT_DIR` — yet git's **filesystem autodiscovery** still fires. Git walks upward from `$d`, and unless `$d` is on a different filesystem mount point, it will eventually find the `.git` file at the worktree root before it settles on `$d/.git`. Specifically: in macOS `/var/folders/...` (where `mktemp -d` lands), git autodiscovery can still traverse into the real repo if the worktree path bleeds into the working directory context of the subprocess.

More precisely: a git worktree has its `.git` as a *file* (not a directory) that points into `.git/worktrees/<name>/`. When `git commit` runs in the temp dir subshell, if git resolves the repo via the worktree's `.git` file rather than the temp dir's `.git` directory, it commits to the real repo's worktree — switching the branch name to `feat/x` (from the `git init -b feat/x` call) and adding the `"init"` commit as if it were a real commit.

The `unset` in `run-tests.sh` fixes the hook-invocation case (where `GIT_DIR` is *exported* by git when calling a hook). It does not fix the worktree case, where no env var is exported — the poison is filesystem-level autodiscovery, not an inherited variable.

## The fix

Never invoke `run-tests.sh` (or `npm test`) directly from inside a worktree directory. Always explicitly clear the full set of git context variables before running, even when none appear to be set:

```bash
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE \
  && bash scripts/run-tests.sh
```

Or, equivalently, invoke it from a directory that is not inside any git worktree:

```bash
cd /tmp && bash /path/to/project/scripts/run-tests.sh
```

The safest permanent fix is to make the test helpers write their temp repos to a path that is guaranteed to be outside the project tree — use `TMPDIR` explicitly:

```bash
mk() {
  local d; d=$(mktemp -d -t harness-test-XXXXXX)  # lands in /private/var/folders or /tmp
  ( cd "$d" && GIT_DIR="$d/.git" git init -b feat/x >/dev/null 2>&1 \
    && GIT_DIR="$d/.git" GIT_WORK_TREE="$d" git commit --allow-empty -m "init" >/dev/null 2>&1 )
  echo "$d"
}
```

Pinning `GIT_DIR` and `GIT_WORK_TREE` explicitly in each subshell prevents autodiscovery entirely — the subshell's git calls use the temp dir's `.git` regardless of what the parent process's working directory was.

## Recovery

If the worktree branch was switched by a corrupted test run:

```bash
# Check what happened
git log --oneline -5
git status

# Soft-reset to the remote branch tip (preserves all local changes, just resets the branch pointer)
git reset --soft origin/feat/before-coding-gate

# Verify
git log --oneline -3
git status
```

Do not use `git reset --hard` — that discards uncommitted work. Do not try to `git rebase` — the push guard hook blocks a rebase onto a wrong-branch HEAD and you would need to unblock it first.

If the push guard fires because the current branch no longer matches what the sentinel says, reset first, then retry.

## The invariant (replicate this when adding test helpers that spin up temp repos)

Any test that calls `git init` inside a subshell must either:

1. Explicitly set `GIT_DIR` and `GIT_WORK_TREE` in the subshell to point at the temp dir, **or**
2. Be invoked from a process where the full git env is cleared (`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE`) AND the CWD at invocation time is not inside a git worktree.

The `run-tests.sh` `unset` block protects against the hook-invocation contamination case. It does not protect against worktree-filesystem-autodiscovery contamination. Both cases can corrupt the real repo silently. The only reliable protection is pinning git env vars in the subshell itself.

## What doesn't work

**Relying on `run-tests.sh`'s existing `unset` to protect you:** The unset clears inherited env vars. It does not prevent git's filesystem autodiscovery from finding the worktree's `.git` file when the process is running from inside the worktree directory. The unset was written for the push-hook invocation case (documented in `reference-git-hook-env-pollutes-tests.md`), not the worktree invocation case.

**Using `cd` to the repo root before running tests:** The repo root is still inside the git tree. Git autodiscovery resolves from the temp dir upward — the temp dir is what matters, not the CWD of the test runner. Moving to the root of the real repo does not change where git finds `.git` when operating inside a temp subshell.

**Checking `git branch --show-current` before and after:** By the time you notice the branch changed, the commits are already in the repo. This is a detection approach, not a prevention approach. The corrupting commits must be cleaned up with `git reset --soft`.

## Tags

git-worktree, GIT_DIR, test-isolation, repo-corruption, autodiscovery, subshell, run-tests, mktemp
