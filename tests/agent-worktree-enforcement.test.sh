#!/usr/bin/env bash
# Tests agent worktree enforcement in .husky/pre-push.
# Non-interactive pushes of feature branches from the main worktree (.git dir)
# are blocked. Pushing from a dedicated worktree (.git file) passes.
# Exempt branches (main, master) are not subject to this gate.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-push"
[ -f "$HOOK" ] || { echo "agent-worktree-enforcement.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got exit $1, want $2"; fail=$((fail+1)); fi; }

STUB=$(mktemp -d)
printf '#!/bin/sh\nexit 0\n' > "$STUB/npm"; chmod +x "$STUB/npm"
printf '#!/bin/sh\nexit 0\n' > "$STUB/gh";  chmod +x "$STUB/gh"

# Create a main git repo with a feature branch.
mk_main() {
  d=$(mktemp -d)
  branch="${1:-feat/work}"
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
    git checkout -q -b "$branch"
    git commit -q --allow-empty --no-verify -m "work"
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# Detach from controlling terminal so the hook takes the non-interactive path.
run_hook() {
  perl -MPOSIX -e 'POSIX::setsid(); exec "bash", $ARGV[0] or die $!' -- "$1"
}

echo "── agent push from main worktree (.git is dir) is blocked ──"
MAIN=$(mk_main "feat/work")
SHA=$(cd "$MAIN" && git rev-parse HEAD)
PUSH="refs/heads/feat/work $SHA refs/heads/feat/work 0000000000000000000000000000000000000000"
rc=$(cd "$MAIN" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
ok "$rc" 1 "main worktree (.git dir) blocks agent push on feat/work"
rm -rf "$MAIN"

echo "── error message includes worktree creation command ──"
MAIN=$(mk_main "feat/my-feature")
SHA=$(cd "$MAIN" && git rev-parse HEAD)
PUSH="refs/heads/feat/my-feature $SHA refs/heads/feat/my-feature 0000000000000000000000000000000000000000"
err=$(cd "$MAIN" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "scripts/worktree-add.sh" && \
   printf '%s' "$err" | grep -q "my-feature"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error message): expected worktree-add.sh command. got: $err"
fi
rm -rf "$MAIN"

echo "── agent push from dedicated worktree (.git is file) passes ──"
MAIN=$(mk_main "feat/work")
WT=$(mktemp -d); rm -rf "$WT"
(cd "$MAIN" && git worktree add "$WT" feat/work) >/dev/null 2>&1
SHA=$(cd "$MAIN" && git rev-parse feat/work)
mkdir -p "$WT/.claude"
printf 'feat/work:%s' "$SHA" > "$WT/.claude/.cr-ok"
PUSH="refs/heads/feat/work $SHA refs/heads/feat/work 0000000000000000000000000000000000000000"
rc=$(cd "$WT" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
ok "$rc" 0 "dedicated worktree (.git file) allows agent push"
rm -rf "$MAIN" "$WT"

echo "── exempt branch (main) skips worktree check ──"
MAIN=$(mk_main "feat/x")
# Check out (or create) main to ensure .cr-ok can be written for main:SHA
(cd "$MAIN" && git checkout -q -b main 2>/dev/null || git checkout -q main) >/dev/null 2>&1
SHA=$(cd "$MAIN" && git rev-parse HEAD)
mkdir -p "$MAIN/.claude"
printf 'main:%s' "$SHA" > "$MAIN/.claude/.cr-ok"
PUSH="refs/heads/main $SHA refs/heads/main 0000000000000000000000000000000000000000"
err=$(cd "$MAIN" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "from the main worktree\|worktree-add"; then
  fail=$((fail+1))
  echo "  MISS (main exempt): worktree check fired for main branch"
else
  pass=$((pass+1))
fi
rm -rf "$MAIN"

rm -rf "$STUB"

echo ""
echo "agent-worktree-enforcement: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
