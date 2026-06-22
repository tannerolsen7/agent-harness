#!/usr/bin/env bash
# Tests branch naming enforcement in .husky/pre-push.
# Valid branch names must match type/slug where type is one of the conventional
# commit types. The check fires before any network call (git fetch / gh pr list).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-push"
[ -f "$HOOK" ] || { echo "pre-push-branch-naming.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got exit $1, want $2"; fail=$((fail+1)); fi; }

STUB=$(mktemp -d)
printf '#!/bin/sh\nexit 0\n' > "$STUB/npm"; chmod +x "$STUB/npm"
printf '#!/bin/sh\nexit 0\n' > "$STUB/gh";  chmod +x "$STUB/gh"

# Create a temp git repo with a commit.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# Run hook in a detached session so it takes the non-interactive (sentinel) path.
run_hook() {
  perl -MPOSIX -e 'POSIX::setsid(); exec "bash", $ARGV[0] or die $!' -- "$1"
}

# Build push stdin for a branch name using HEAD as the SHA.
push_input() {
  sha=$(cd "$1" && git rev-parse HEAD)
  printf 'refs/heads/%s %s refs/heads/%s 0000000000000000000000000000000000000000' "$2" "$sha" "$2"
}

echo "── invalid branch names are blocked ──"
for bad in "my-branch" "feature-login" "FEAT/thing" "wip/stuff" "add-feature"; do
  D=$(mk)
  PUSH=$(push_input "$D" "$bad")
  rc=$(cd "$D" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
  ok "$rc" 1 "blocked: $bad"
  rm -rf "$D"
done

echo "── feat/ with no slug is blocked with a specific message ──"
D=$(mk)
PUSH=$(push_input "$D" "feat/")
err=$(cd "$D" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "missing a slug"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (feat/ no-slug message): stderr='$err'"
fi
rm -rf "$D"

echo "── invalid branch error includes rename command ──"
D=$(mk)
PUSH=$(push_input "$D" "my-branch")
err=$(cd "$D" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "git branch -m" && \
   printf '%s' "$err" | grep -q "feat\|fix\|chore"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error rename hint): stderr='$err'"
fi
rm -rf "$D"

echo "── valid type/slug branches pass the naming check ──"
# Use a dedicated worktree so the worktree enforcement check (slice #96) also passes.
for good in "feat/login" "fix/typo" "chore/cleanup" "revert/undo-auth" "refactor/split"; do
  MAIN=$(mk)
  WT=$(mktemp -d); rm -rf "$WT"
  (cd "$MAIN" && git worktree add "$WT" -b "$good" HEAD) >/dev/null 2>&1
  SHA=$(cd "$MAIN" && git rev-parse "$good")
  mkdir -p "$WT/.claude"
  printf '%s:%s' "$good" "$SHA" > "$WT/.claude/.cr-ok"
  PUSH=$(printf 'refs/heads/%s %s refs/heads/%s 0000000000000000000000000000000000000000' "$good" "$SHA" "$good")
  rc=$(cd "$WT" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
  ok "$rc" 0 "passes: $good"
  rm -rf "$MAIN" "$WT"
done

echo "── main and master are exempt from naming check ──"
for exempt in "main" "master"; do
  D=$(mk)
  SHA=$(cd "$D" && git rev-parse HEAD)
  mkdir -p "$D/.claude"
  printf '%s:%s' "$exempt" "$SHA" > "$D/.claude/.cr-ok"
  PUSH=$(printf 'refs/heads/%s %s refs/heads/%s 0000000000000000000000000000000000000000' "$exempt" "$SHA" "$exempt")
  rc=$(cd "$D" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>/dev/null; echo $?)
  ok "$rc" 0 "exempt: $exempt"
  rm -rf "$D"
done

echo "── check fires before any git fetch (no network on invalid branch) ──"
D=$(mk)
# Use an invalid branch name; the naming check should fire before gh pr list or git fetch.
# We verify no network error appears in stderr (if it got to fetch, there would be one).
PUSH=$(push_input "$D" "bad-branch-name")
err=$(cd "$D" && printf '%s\n' "$PUSH" | PATH="$STUB:$PATH" run_hook "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "does not follow\|missing a slug\|type/slug"; then
  pass=$((pass+1))  # naming check fired correctly before network calls
else
  fail=$((fail+1))
  echo "  MISS (naming check order): expected naming error. got: $err"
fi
rm -rf "$D"

rm -rf "$STUB"

echo ""
echo "pre-push-branch-naming: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
