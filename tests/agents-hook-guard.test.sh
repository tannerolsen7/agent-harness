#!/usr/bin/env bash
# Tests that the pre-commit safety-file guard blocks commits touching .claude/agents/.
# Agent definitions control which tools an agent can use and what permissions it has.
# If an agent could commit a change to its own definition, it could escalate its own access.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "agents-hook-guard.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got exit $1, want $2"; fail=$((fail+1)); fi; }

mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
    mkdir -p .claude/agents
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

echo "── commit touching .claude/agents/ is blocked ──"
D=$(mk)
printf -- '---\nname: test-agent\ntools: Read\n---\nbody\n' > "$D/.claude/agents/test-agent.md"
rc=$(cd "$D" && git add .claude/agents/test-agent.md && bash "$HOOK" >/dev/null 2>&1; echo $?)
ok "$rc" 1 "commit to .claude/agents/ blocked"
rm -rf "$D"

echo "── block message mentions agent definitions ──"
D=$(mk)
printf -- '---\nname: test-agent\ntools: Read\n---\nbody\n' > "$D/.claude/agents/test-agent.md"
err=$(cd "$D" && git add .claude/agents/test-agent.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -qi "agent"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error mentions agents): stderr='$err'"
fi
rm -rf "$D"

echo "── modify to an existing agent definition is blocked ──"
D=$(mk)
printf -- '---\nname: test-agent\ntools: Read\n---\nbody\n' > "$D/.claude/agents/test-agent.md"
( cd "$D" && git add .claude/agents/test-agent.md && git commit -q --no-verify -m init ) >/dev/null 2>&1
printf -- '---\nname: test-agent\ntools: Read,Write\n---\nbody updated\n' > "$D/.claude/agents/test-agent.md"
rc=$(cd "$D" && git add .claude/agents/test-agent.md && bash "$HOOK" >/dev/null 2>&1; echo $?)
ok "$rc" 1 "modify to .claude/agents/ blocked"
rm -rf "$D"

echo "── delete of an agent definition is blocked ──"
D=$(mk)
printf -- '---\nname: test-agent\ntools: Read\n---\nbody\n' > "$D/.claude/agents/test-agent.md"
( cd "$D" && git add .claude/agents/test-agent.md && git commit -q --no-verify -m init ) >/dev/null 2>&1
rc=$(cd "$D" && git rm -q .claude/agents/test-agent.md && bash "$HOOK" >/dev/null 2>&1; echo $?)
ok "$rc" 1 "delete of .claude/agents/ file blocked"
rm -rf "$D"

echo "── commit NOT touching .claude/agents/ is not affected by this guard ──"
D=$(mk)
printf 'hello\n' > "$D/readme.txt"
err=$(cd "$D" && git add readme.txt && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -qi "agent definitions\|\.claude/agents"; then
  fail=$((fail+1))
  echo "  MISS (unrelated file unaffected): agent guard fired on non-agent path"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo ""
echo "agents-hook-guard: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
