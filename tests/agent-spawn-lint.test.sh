#!/usr/bin/env bash
# Tests agent spawn lint in .husky/pre-commit.
# Any staged .md file under .claude/agents/ that lists Task in tools
# must also have permissionMode: default or auto (and vice versa).
# An agent with Task but no permissionMode fails to spawn; one with
# permissionMode but no Task can never spawn at all.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "agent-spawn-lint.test: $HOOK not found"; exit 1; }

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

# Write an agent definition and return the path.
write_agent() {
  local dir="$1" name="$2" tools="$3" perm="$4"
  local path="$dir/.claude/agents/$name.md"
  {
    printf -- '---\nname: %s\n' "$name"
    [ -n "$tools" ] && printf 'tools: %s\n' "$tools"
    [ -n "$perm"  ] && printf 'permissionMode: %s\n' "$perm"
    printf -- '---\nAgent body.\n'
  } > "$path"
  printf '%s' "$path"
}

run_hook() {
  bash "$HOOK" >/dev/null 2>&1
  echo $?
}

echo "── Task without permissionMode is blocked ──"
D=$(mk)
write_agent "$D" "bad-agent" "Task,Read" "" >/dev/null
rc=$(cd "$D" && git add .claude/agents/bad-agent.md && run_hook)
ok "$rc" 1 "Task without permissionMode blocked"
rm -rf "$D"

echo "── permissionMode without Task is blocked ──"
D=$(mk)
write_agent "$D" "bad-agent" "Read,Write" "default" >/dev/null
rc=$(cd "$D" && git add .claude/agents/bad-agent.md && run_hook)
ok "$rc" 1 "permissionMode without Task blocked"
rm -rf "$D"

echo "── Task + permissionMode: default passes ──"
D=$(mk)
write_agent "$D" "good-agent" "Task,Read" "default" >/dev/null
err=$(cd "$D" && git add .claude/agents/good-agent.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissionMode\|Task\|spawn"; then
  fail=$((fail+1))
  echo "  MISS (Task+default passes): got spawn error: $err"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── Task + permissionMode: auto passes ──"
D=$(mk)
write_agent "$D" "good-agent" "Task,Read" "auto" >/dev/null
err=$(cd "$D" && git add .claude/agents/good-agent.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissionMode\|Task\|spawn"; then
  fail=$((fail+1))
  echo "  MISS (Task+auto passes): got spawn error: $err"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── neither Task nor permissionMode passes (non-spawning agent) ──"
D=$(mk)
write_agent "$D" "reader-agent" "Read,Write" "" >/dev/null
err=$(cd "$D" && git add .claude/agents/reader-agent.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissionMode\|Task\|spawn"; then
  fail=$((fail+1))
  echo "  MISS (neither passes): got spawn error: $err"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── .md files outside .claude/agents/ are not checked ──"
D=$(mk)
# An agent-like file in the wrong location should not trigger the check
printf -- '---\ntools: Task\n---\nbody\n' > "$D/some-doc.md"
err=$(cd "$D" && git add some-doc.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissionMode\|Task\|spawn"; then
  fail=$((fail+1))
  echo "  MISS (.md outside agents/): spawn lint fired on wrong path"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── error message names both fields and explains what breaks ──"
D=$(mk)
write_agent "$D" "bad-agent" "Task,Read" "" >/dev/null
err=$(cd "$D" && git add .claude/agents/bad-agent.md && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "Task" && \
   printf '%s' "$err" | grep -q "permissionMode"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (error mentions both fields): stderr='$err'"
fi
rm -rf "$D"

echo ""
echo "agent-spawn-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
