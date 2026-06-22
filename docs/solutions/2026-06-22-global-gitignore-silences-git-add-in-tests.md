# Global gitignore silently skips git add in test temp repos

**Tags:** testing, git, gitignore, hooks, false-positive

## The problem

When a test creates a temporary git repo and stages a file with `git add`, the command
can succeed silently — exit 0, no output — while the file is never actually staged.
This happens when the file path matches a pattern in `~/.config/git/ignore` (the
user's global gitignore). The hook then runs against an empty index, every guard
passes, and the test reports a false pass.

In the safety-file-guard test, `git add .claude/settings.local.json` produced exit 0
but staged nothing, because `~/.config/git/ignore` contained `**/.claude/settings.local.json`.
The test ran the pre-commit hook against an empty index. No guard fired. The test fell
through to `bash scripts/lint.sh`, which failed (the temp repo has no scripts/), and the
stderr didn't contain the expected keyword — so the test marked it as a failure. That was
lucky. If the hook had exited 0 cleanly on an empty index, the test would have reported
a false pass.

## Root cause

Git respects three levels of gitignore, including in temp repos:

1. `.gitignore` in the repo
2. `.git/info/exclude`
3. `$XDG_CONFIG_HOME/git/ignore` — defaults to `~/.config/git/ignore`, checked for
   **every** repo on the machine, no config needed

The global ignore is meant for personal editor noise (`.DS_Store`, `*.swp`). When it
contains project patterns like `**/.claude/settings.local.json`, those patterns apply
to all repos including your test temp dirs. `git add` silently honors them.

You cannot detect this from `git add`'s exit code or output. After the silent skip,
`git status` shows the file as untracked, not staged.

## The fix

Use `git add -f` (force) to bypass gitignore when staging inside test temp repos:

```bash
# Before (silently skips if file is in global gitignore):
(cd "$D" && git add .claude/settings.local.json) >/dev/null 2>&1

# After (stages even if globally ignored):
(cd "$D" && git add -f .claude/settings.local.json) >/dev/null 2>&1
```

`-f` overrides all ignore rules. Inside a test temp repo you created, this is safe —
you own the repo and the file.

## When to apply this

Use `git add -f` in any hook test that stages a file known to be in the project's
`.gitignore` or any common global ignore. Files that commonly need this in the harness:

- `.claude/settings.local.json` — in `~/.config/git/ignore` and the project `.gitignore`
- `.claude/.cr-ok`, `.claude/.design-confirmed` — gitignored sentinels; use `-f` when
  testing the sentinel direct-write guard
- Any other file listed in the project `.gitignore` that a guard needs to catch

Do NOT use `git add -f` for normal test files that are not gitignored — it works but
the `-f` is a signal that something unusual is happening and you want it visible.

## How to verify the file was actually staged

Add a debug check after `git add` when a test behaves unexpectedly:

```bash
D=$(mktemp -d)
cd "$D" && git init -q
printf 'test\n' > .claude/settings.local.json
git add -f .claude/settings.local.json
git diff --cached --name-only | grep -q settings.local.json && echo "staged" || echo "NOT staged — check gitignore"
```

## Diagnosis pattern

If a test for a guard that should fire is passing unexpectedly, check whether the staged
file was silently skipped by gitignore before debugging the regex:

```bash
# Inside the test's temp repo $D:
(cd "$D" && git diff --cached --name-only)
```

An empty result when you expected a file means `git add` silently skipped it.

## Related: self-referential hook bootstrap failure

A related trap: updating `.husky/pre-commit` (which now guards itself against staging)
requires `git commit --no-verify`. The "bootstrap trick" — stage the new version, restore
the old version to the working tree so the hook runs the old code — fails when HEAD's
version already contains the self-block. `--no-verify` is the correct and only exit.

`git checkout HEAD -- <file>` restores **both** the working tree and the index to HEAD,
unstaging any staged changes in the process. If you've staged changes and then run
`git checkout HEAD -- .husky/pre-commit`, you lose the staged changes — they're gone from
the index and the working tree. Recover from this by re-applying the changes manually.

## Source

`tests/safety-file-guard.test.sh` — the `settings.local.json` test case (Slice 2).
Discovered during `/cr` when 15 of 16 tests passed but the 16th fell through to
`scripts/lint.sh` instead of being blocked by the settings guard.
