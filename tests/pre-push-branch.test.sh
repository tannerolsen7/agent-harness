#!/usr/bin/env bash
# pre-push hook uses the branch from git's stdin ref-list, not HEAD.
# Pushing feat/x from a worktree where HEAD=main must check the sentinel
# for feat/x, not for main.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-push"
[ -f "$HOOK" ] || { echo "pre-push-branch.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got '$1', want '$2'"; fail=$((fail+1)); fi; }

# Stubs: npm exits 0 (skip test suite); gh exits 0 with no output (no merged PRs).
STUB=$(mktemp -d)
printf '#!/bin/sh\nexit 0\n' > "$STUB/npm"; chmod +x "$STUB/npm"
printf '#!/bin/sh\nexit 0\n' > "$STUB/gh";  chmod +x "$STUB/gh"

# Build a temp git repo on feat/x with one commit, then check out the initial branch
# (main or master) so HEAD != feat/x. This simulates pushing from a parent worktree.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
    # Record the default branch name before moving to feat/x.
    git rev-parse --abbrev-ref HEAD > "$d/.default-branch"
    git checkout -q -b feat/x
    git commit -q --allow-empty --no-verify -m "feat/x work"
    # Return to the default branch — HEAD is now NOT feat/x.
    git checkout -q "$(cat "$d/.default-branch")"
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# Run the hook detached from the controlling terminal so it takes the sentinel
# (non-interactive) path. Without this, running the test from an interactive
# terminal lets the hook open /dev/tty and prompt the user, bypassing the sentinel.
# perl's POSIX::setsid() creates a new session with no controlling terminal,
# which makes the hook's `exec 3</dev/tty` fail and fall to the sentinel path.
run_hook() {
  perl -MPOSIX -e 'POSIX::setsid(); exec "bash", $ARGV[0] or die $!' -- "$1"
}

echo "── sentinel for feat/x passes when HEAD is on a different branch ──"
D=$(mk)
DEFAULT=$(cat "$D/.default-branch")
FEAT_SHA=$(cd "$D" && git rev-parse feat/x)
mkdir -p "$D/.claude"
printf 'feat/x:%s' "$FEAT_SHA" > "$D/.claude/.cr-ok"
# git sends: <local-ref> <local-sha> <remote-ref> <remote-sha>
PUSH_INPUT="refs/heads/feat/x $FEAT_SHA refs/heads/feat/x 0000000000000000000000000000000000000000"
rc=$(cd "$D" && printf '%s\n' "$PUSH_INPUT" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
ok "$rc" 0 "sentinel feat/x:SHA passes when HEAD=$DEFAULT"
rm -rf "$D"

echo "── sentinel for a different branch blocks when pushing feat/x ──"
D=$(mk)
DEFAULT=$(cat "$D/.default-branch")
FEAT_SHA=$(cd "$D" && git rev-parse feat/x)
DEFAULT_SHA=$(cd "$D" && git rev-parse "$DEFAULT")
mkdir -p "$D/.claude"
# Sentinel belongs to the default branch, not to feat/x — a wrong sentinel.
printf '%s:%s' "$DEFAULT" "$DEFAULT_SHA" > "$D/.claude/.cr-ok"
PUSH_INPUT="refs/heads/feat/x $FEAT_SHA refs/heads/feat/x 0000000000000000000000000000000000000000"
rc=$(cd "$D" && printf '%s\n' "$PUSH_INPUT" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
ok "$rc" 1 "wrong branch in sentinel blocks push of feat/x (HEAD=$DEFAULT)"
rm -rf "$D"

rm -rf "$STUB"

echo ""
echo "pre-push-branch: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
