# Problem: Pre-push hook rebases on the wrong SHA and sends stale commits

**Problem class:** A `pre-push` hook that auto-rebases before a push, or reads `HEAD` instead of the push ref SHA, produces the wrong result in two distinct ways — one silently, one incorrectly.

## When this bites you

You write a sync gate in `.husky/pre-push`. It checks whether the branch is behind `origin/main` and, if so, either rebases automatically or compares the wrong commit. Two things can go wrong:

1. **Auto-rebase path:** The hook rebases, the rebase succeeds, but the push still lands the pre-rebase commits on the remote. The push appears to succeed but the new commits are not there.

2. **`HEAD` path:** You use `HEAD` in a `git rev-list` comparison. In a worktree, `HEAD` is the branch checked out in that worktree — which may not be the branch you are pushing. The comparison is against the wrong commit, and the gate gives a false pass or false fail.

Both failures are silent. Git does not tell you that the hook rebased the wrong thing, or that `HEAD` pointed somewhere unexpected.

## Root cause

### Why auto-rebase silently sends stale commits

Git resolves the push ref SHAs **before** calling the pre-push hook. The sequence is:

1. Git reads the local branch's current tip SHA. Call it `A`.
2. Git records `A` as the SHA to push. This is locked.
3. Git calls the pre-push hook, passing `A` in stdin.
4. Your hook rebases. The branch tip moves to `B`.
5. The hook exits 0.
6. Git pushes `A` — the SHA it locked in step 2 — not `B`.

The user sees a clean push. Their new commits (`B`) stay local. There is no error.

This is documented behavior, not a bug in git. It exists because git cannot know whether a hook's side effects are safe to incorporate. The push contract is: hook exit 0 = the pre-recorded refs are safe to send. Changing the refs after that point violates the contract, and git does not re-read them.

### Why `HEAD` points to the wrong commit in a worktree

Worktrees have independent `HEAD` pointers. If your main repo is checked out to `main` and you are pushing from `.claude/worktrees/feat-x` (checked out to `feat/x`), both worktrees have their own `HEAD`. But inside a pre-push hook, `HEAD` resolves to whatever the **current worktree** has checked out — which is correct when you push from the same worktree you are working in, but breaks when there is any mismatch.

More importantly: the pre-push hook already receives the exact SHA being pushed via stdin. Using `HEAD` ignores this and reads a derived value that can differ. Using the stdin SHA is always more correct.

## The fix

Parse `PUSH_SHA` from stdin at the top of the hook, before any other logic. Use `$PUSH_SHA` (not `HEAD`) everywhere you need to reference the commit being pushed.

Block-and-instruct instead of auto-rebase. Show the user the exact command to run, then exit 1.

```sh
# Read all push refs from stdin before any logic runs.
# Format per line: <local-ref> <local-sha1> <remote-ref> <remote-sha1>
PUSH_INPUT=$(cat)
BRANCH=""
PUSH_SHA=""
while IFS=' ' read -r _lref _lsha _rref _rsha; do
  [ -z "$_lsha" ] && continue
  if [ "$_lsha" != "0000000000000000000000000000000000000000" ]; then
    BRANCH=$(printf '%s' "$_lref" | sed 's|^refs/heads/||')
    PUSH_SHA="$_lsha"
    break
  fi
done <<EOF
$PUSH_INPUT
EOF

# Sync gate — uses PUSH_SHA, not HEAD.
case "$BRANCH" in
  main|master|HEAD|"") ;;
  *)
    _REF=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    _MAIN="${_REF##*/}"
    _MAIN="${_MAIN:-main}"
    if GIT_TERMINAL_PROMPT=0 timeout 15 git fetch origin "$_MAIN" --quiet 2>/dev/null; then
      _BEHIND=$(git rev-list --count "$PUSH_SHA..origin/$_MAIN" 2>/dev/null || echo 0)
      _BEHIND="${_BEHIND:-0}"
      if [ "$_BEHIND" -gt 0 ]; then
        printf "Push blocked: '%s' is %s commit(s) behind origin/%s.\n" "$BRANCH" "$_BEHIND" "$_MAIN" >&2
        printf "Sync first:   git rebase origin/%s\n" "$_MAIN" >&2
        exit 1
      fi
    fi
    ;;
esac
```

Key points:

- `PUSH_INPUT=$(cat)` consumes stdin before the `while` loop so nothing is lost.
- The `while` loop breaks on the first non-deletion ref. This captures the first branch being pushed.
- `git rev-list --count "$PUSH_SHA..origin/$_MAIN"` counts commits in `origin/main` that are not reachable from `$PUSH_SHA`. If `$PUSH_SHA` is not yet on remote, this is the number of commits the branch is behind.
- `GIT_TERMINAL_PROMPT=0` prevents git from prompting for credentials in a non-interactive context. Without it, a credential cache miss causes `git fetch` to wait forever. The gate is fail-open: if the fetch fails for any reason (no network, wrong remote, timeout), the `if` condition is false and the hook skips the gate entirely. This is intentional — network errors should not block pushes.
- The gate skips `main|master|HEAD|""` — those branches are merge targets, not feature branches, and a sync check against themselves would always pass anyway.

## Why block-and-instruct instead of auto-rebase

Auto-rebase appears to "help" but actually makes things worse. The rebase runs inside the hook, which runs after git has already locked the push SHAs. After the rebase, the local branch tip has a new SHA, but git pushes the old one. The user's new commits do not reach the remote. The push reports success.

Block-and-instruct gives the user one command to copy-paste, then lets them push again cleanly. The push happens outside the hook, so git picks up the correct SHA.

## When to reuse this pattern

Use `$PUSH_SHA` from stdin any time a pre-push hook needs to reference the commit being pushed:

- Checking whether the commit is signed
- Checking whether the commit's SHA matches a sentinel file (`.cr-ok`)
- Any `git rev-list` or `git log` comparison that is supposed to reflect what git is about to send

The sentinel check in this project's `.husky/pre-push` does exactly this:

```sh
EXPECTED="${BRANCH}:${PUSH_SHA}"
ACTUAL=$(cat "$SENTINEL_CR")
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "Push blocked: .cr-ok is stale." >&2
  exit 1
fi
```

If this used `HEAD` instead of `PUSH_SHA`, it would pass a stale `.cr-ok` check in any worktree where `HEAD` happens to match the sentinel's recorded branch name but points to a different commit.

## When NOT to use this pattern

- If you are writing a `commit-msg` or `pre-commit` hook (not `pre-push`), stdin is not populated with push refs. Those hooks use `$1` (the message file path) or operate on the index directly.
- If you only ever push from the main worktree and never use detached HEAD or named worktrees, the `HEAD` vs `PUSH_SHA` distinction doesn't affect you in practice. The stdin approach is still safer.
- The fail-open fetch behavior is appropriate for a developer sync gate. It is NOT appropriate for a security gate (e.g., signature verification). If you need a hard gate that network errors cannot bypass, check for the absence of a fetch result and exit 1 explicitly.

## Files involved

- `.husky/pre-push` — sync gate block at lines 51–68; stdin parsing at lines 10–29
- `tests/pre-push-sync-gate.test.sh` — tests covering the skip patterns, up-to-date path, blocked path, fetch-failure fail-open, and default-branch detection
