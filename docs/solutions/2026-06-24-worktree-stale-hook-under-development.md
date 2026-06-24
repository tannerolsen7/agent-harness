# Problem: A test in a worktree loads a stale hook file and misses uncommitted changes

**Problem class:** File isolation mismatch — editing a hook file in the main working tree does not update the checked-out copy in a linked worktree, so a test that resolves the hook path from the worktree root runs against an older version of the file.

## When this bites you

You are developing a new behavior for a hook file (for example, `.claude/hooks/block-dangerous-git.sh`). You edit the file in your main checkout — but have not committed the change yet. A feature branch lives in a linked worktree created from the main branch before your edit. You run the tests from inside that worktree. The test sets `HOOK="$ROOT/.claude/hooks/block-dangerous-git.sh"` where `ROOT` is the worktree root.

The worktree has its own copy of the hook from when the branch was created. Your edit is invisible to it. Tests that should now pass with the new behavior fail instead (or, worse, the old behavior passes tests you thought you fixed).

In the concrete case that triggered this: adding a "allow delete on merged branches" path to `block-dangerous-git.sh`. The test for the new "allow" cases ran against the old hook, which blocked all `-D` calls unconditionally. The "allow" test cases got exit 2 (blocked) instead of 0 (allowed) and failed — for the wrong reason.

## Root cause

When `scripts/worktree-add.sh` creates a worktree, git checks out the branch at that point in history. The worktree gets its own copy of every tracked file at that revision. Edits made to files in the main working tree after the worktree was created are not visible in the worktree — unless they are committed and the worktree's branch is updated.

This is expected git behavior. The surprise is that a test file resolving `HOOK` from `$ROOT` (the worktree root) will always find the worktree's copy, not the main checkout's copy. The two copies diverge the moment you edit the file in the main tree without committing.

## The fix

At the top of the test file, detect whether we are running inside a worktree. If we are, resolve the main repo root from the worktree's `.git` file and point `HOOK` there instead.

In `tests/allow-merged-branch-delete.test.sh`, lines 9–14:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
HOOK="$ROOT/.claude/hooks/block-dangerous-git.sh"
if [ -f "$ROOT/.git" ]; then
  _gitdir=$(sed 's/gitdir: //' "$ROOT/.git")
  _main="${_gitdir%/.git/worktrees/*}"
  [ -f "$_main/.claude/hooks/block-dangerous-git.sh" ] && HOOK="$_main/.claude/hooks/block-dangerous-git.sh"
fi
```

How this works:

- In a linked worktree, `.git` is a file containing a line like `gitdir: /path/to/repo/.git/worktrees/<name>`. Stripping that suffix gives the main repo root.
- The `[ -f "$ROOT/.git" ]` test is the worktree detection. In a normal checkout, `.git` is a directory, so the branch is never taken and `HOOK` stays at the local (now-committed) path.
- The final `[ -f ... ] &&` guard keeps the original path if the main repo doesn't have the file yet (for example, on a brand-new hook being introduced on this branch).

Once the branch is merged and the hook is committed, running the test in a normal checkout resolves the local copy as usual. The worktree-detection code is present but inert.

## How to know it's working

Run the test suite from inside the worktree while the hook file has uncommitted changes in the main tree:

```bash
cd /path/to/repo/.claude/worktrees/<task-slug> && bash tests/allow-merged-branch-delete.test.sh
```

The "allow on merged" cases should exit 0. Before the fix, they exited 2 (blocked by the old hook).

After merge, run from the main checkout:

```bash
cd /path/to/repo && bash tests/allow-merged-branch-delete.test.sh
```

The same cases should still exit 0, now loading the committed file directly.

## The regression gate

`tests/allow-merged-branch-delete.test.sh` — specifically the cases that exercise the "allow delete when branch is already merged" path. If those cases fail with exit 2 instead of 0, the worktree detection broke or the wrong file is being loaded.

## The invariant (replicate this when...)

Any test file that resolves a hook or script path from `$ROOT` (the git toplevel) and is intended to run during development from inside a worktree should include the worktree-detection block above. Apply it when:

- The hook or script under test is likely to be edited before it is committed (that is, during active development on the branch).
- The test lives in the same repo and is run from a linked worktree.
- The alternative — always committing the hook before running the test — would break the red-green-refactor cycle or slow iteration down.

## What doesn't work

**Committing the hook before each test run:** This works but forces you to make speculative commits just to run a test. It also makes the test history noisy and means you cannot verify behavior against a half-finished change.

**Copying the hook to the worktree manually:** Error-prone. You would have to remember to re-copy after every edit. Easy to forget and get a false pass.

**Running tests from the main working tree instead of the worktree:** This breaks the isolation the worktree provides and can cause the tests to pick up uncommitted changes to other files you are not testing.

**Checking `GIT_DIR` instead of `ROOT/.git`:** `GIT_DIR` may or may not be set depending on how the test is invoked. The `.git` file test works regardless of environment variables.

## Tags

git-worktree, hook-testing, stale-file, worktree-detection, .git-file, uncommitted-changes, test-isolation, block-dangerous-git, development-workflow
