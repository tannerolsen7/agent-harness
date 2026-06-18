#!/usr/bin/env bash
# Tests for the AI activity dashboard.
#
# Three cases:
#   1. session-stop.sh writes a valid JSONL record for a top-level session stop
#   2. session-stop.sh writes nothing when agent_type is set (subagent stop)
#   3. activity-report.sh skips a bad JSONL line and still renders valid records
#
# Tests 1 and 2 call .claude/hooks/session-stop.sh directly with crafted stdin.
# They require the session-stop.sh extension (the "activity record writer" block)
# to be applied. Run after applying the hook diff.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STOP_HOOK="$ROOT/.claude/hooks/session-stop.sh"
REPORT="$ROOT/scripts/activity-report.sh"

[ -f "$STOP_HOOK" ] || { echo "activity.test: $STOP_HOOK not found"; exit 1; }
[ -x "$REPORT"    ] || { echo "activity.test: $REPORT not found or not executable"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

CLEAR_GIT="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE"

# Helper: init a bare-minimum git repo in $1 with one commit and .claude/activity/.
setup_repo() {
  local dir="$1"
  (
    cd "$dir"
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m "init"
    git branch -M main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
    mkdir -p .claude/activity
  ) >/dev/null 2>&1
}

# ── Test 1: top-level stop writes a valid JSONL record ──────────────────────

TMP1=$(mktemp -d)
trap 'rm -rf "$TMP1"' EXIT
setup_repo "$TMP1"

SESSION1="act-test-top-001"
START_TS=$(($(date +%s) - 90))

printf '%s claude-sonnet-4-6\n' "$START_TS" > "/tmp/claude-activity-${SESSION1}"

HASH1=$(echo "$TMP1" | md5 | cut -c1-8)
LOGFILE1="/tmp/claude-perm-log-${HASH1}.jsonl"
printf '{"ts":1000,"tool":"Skill","key":"skill","val":"design"}\n' > "$LOGFILE1"
printf '{"ts":1001,"tool":"Skill","key":"skill","val":"cr"}\n' >> "$LOGFILE1"
printf '{"ts":1002,"tool":"Skill","key":"skill","val":"design"}\n' >> "$LOGFILE1"

INPUT1="{\"session_id\":\"${SESSION1}\"}"
(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '%s' "$INPUT1" | CLAUDE_PROJECT_DIR="$TMP1" bash "$STOP_HOOK" >/dev/null 2>&1
)
EXIT1=$?

if [ "$EXIT1" = "0" ]; then ok; else no "session-stop.sh exited $EXIT1 for top-level stop (expected 0)"; fi

RECORD1="$TMP1/.claude/activity/main.jsonl"

if [ -f "$RECORD1" ]; then
  ok
else
  no "JSONL file not created at .claude/activity/main.jsonl"
fi

if [ -f "$RECORD1" ] && jq -e '.model == "claude-sonnet-4-6"' "$RECORD1" >/dev/null 2>&1; then
  ok
else
  no "record.model is not claude-sonnet-4-6"
fi

if [ -f "$RECORD1" ] && jq -e '([.skills[]] | sort) == ["cr","design"]' "$RECORD1" >/dev/null 2>&1; then
  ok
else
  no "skills not deduplicated to [\"cr\",\"design\"]"
fi

if [ -f "$RECORD1" ] && jq -e '.duration_s > 0' "$RECORD1" >/dev/null 2>&1; then
  ok
else
  no "duration_s should be a positive integer (got null or 0)"
fi

# ── Test 2: subagent stop (agent_type set) writes no record ─────────────────

TMP2=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2"' EXIT
setup_repo "$TMP2"

SESSION2="act-test-sub-002"
printf '%s claude-sonnet-4-6\n' "$(($(date +%s) - 30))" > "/tmp/claude-activity-${SESSION2}"

INPUT2="{\"session_id\":\"${SESSION2}\",\"agent_type\":\"designer\"}"
(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '%s' "$INPUT2" | CLAUDE_PROJECT_DIR="$TMP2" bash "$STOP_HOOK" >/dev/null 2>&1
)

JSONL_COUNT=$(find "$TMP2/.claude/activity" -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')
if [ "$JSONL_COUNT" = "0" ]; then
  ok
else
  no "subagent stop (agent_type=designer) wrote a JSONL file — it must write nothing"
fi

# ── Test 3: bad JSONL line is skipped; valid lines still render ─────────────

TMP3=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2" "$TMP3"' EXIT
(
  cd "$TMP3"
  git init -q
  git config user.email t@example.com
  git config user.name tester
  git commit -q --allow-empty --no-verify -m "init"
) >/dev/null 2>&1
mkdir -p "$TMP3/.claude/activity"

cat > "$TMP3/.claude/activity/main.jsonl" << 'JSONLEOF'
{"ts":"2026-06-01T10:00:00Z","branch":"main","sha":"aaabbb1234567","model":"claude-sonnet-4-6","skills":["cr"],"duration_s":60}
NOT VALID JSON {{{ garbage
{"ts":"2026-06-02T10:00:00Z","branch":"main","sha":"cccfff7654321","model":"claude-opus-4-8","skills":[],"duration_s":null}
JSONLEOF

REPORT_EXIT=0
(
  unset $CLEAR_GIT 2>/dev/null || true
  cd "$TMP3" && bash "$REPORT" 2>/dev/null
) || REPORT_EXIT=$?

if [ "$REPORT_EXIT" = "0" ]; then
  ok
else
  no "activity-report.sh exited $REPORT_EXIT with a bad JSONL line (expected 0)"
fi

if grep -q "aaabbb1" "$TMP3/harness-activity.html" 2>/dev/null; then
  ok
else
  no "first valid record (sha aaabbb1) not found in harness-activity.html"
fi

if grep -q "cccfff7" "$TMP3/harness-activity.html" 2>/dev/null; then
  ok
else
  no "second valid record (sha cccfff7) not found in harness-activity.html"
fi

[ "$fail" = "0" ] && echo "activity: OK ($pass passed)"
exit "$fail"
