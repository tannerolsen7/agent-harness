#!/usr/bin/env bash
# /cr Pass 6 must instruct reviewers to flag tests whose assertions the diff
# contradicts, not just check that new behavior has coverage. /behavior-change
# must cross-reference that check as its backstop for misrouted work. Both are
# prompt files (no executable code path), so this test asserts on file content.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CR_SKILL="$ROOT/.claude/skills/cr/SKILL.md"
BC_SKILL="$ROOT/.claude/skills/behavior-change/SKILL.md"

pass=0; fail=0
ok() {
  if [ "$1" = "0" ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi
}

[ -f "$CR_SKILL" ] || { echo "test: $CR_SKILL not found"; exit 1; }
[ -f "$BC_SKILL" ] || { echo "test: $BC_SKILL not found"; exit 1; }

echo "── Pass 6 contains the test contradiction check ──"
grep -q "Test contradiction check" "$CR_SKILL"
ok "$?" "Pass 6 missing a 'Test contradiction check' item"

echo "── contradiction check covers untouched tests in a touched file/shard ──"
grep -qi "untouched\|NOT change" "$CR_SKILL"
ok "$?" "contradiction check doesn't scope to untouched tests in the same file/shard"

CONTRADICTION_BLOCK=$(grep -B2 -A15 "Test contradiction check" "$CR_SKILL")

echo "── concrete contradictions are MUST FIX ──"
echo "$CONTRADICTION_BLOCK" | grep -q "MUST FIX"
ok "$?" "concrete contradiction disposition is not tied to MUST FIX"

echo "── uncertain contradictions are advisory, not blocking ──"
echo "$CONTRADICTION_BLOCK" | grep -qi "Something to Think About"
ok "$?" "uncertain contradiction is not routed to the non-blocking tier"

echo "── behavior-change Phase 3 cross-references the /cr Pass 6 backstop ──"
grep -A40 "Phase 3 — Test inversion analysis" "$BC_SKILL" | grep -qi "Pass 6"
ok "$?" "behavior-change Phase 3 doesn't mention /cr Pass 6 as a backstop"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
