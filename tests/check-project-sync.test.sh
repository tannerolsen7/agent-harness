#!/usr/bin/env bash
# Tests for hooks/check-project-sync.sh
#
# Six cases:
#   1. No harness manifest → silent (nothing printed, exit 0)
#   2. Dry-run reports one "updated:" line → one notice line, exit 0
#   3. Dry-run reports three "updated:" lines → still one notice line, exit 0
#   4. Dry-run reports a "CONFLICT:" line → one conflict notice line, exit 0
#   5. Dry-run reports only "up-to-date:" lines → silent, exit 0
#   6. Dry-run exits non-zero → silent, exit 0
#
# Each test creates a fake $CLAUDE_PLUGIN_ROOT with a stub sync script that
# produces controlled output, and a fake $CLAUDE_PROJECT_DIR with or without
# a harness manifest.
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE 2>/dev/null || true

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/hooks/check-project-sync.sh"

[ -f "$SCRIPT" ] || { echo "check-project-sync.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Build a fake plugin root with a stub sync script.
# $1 = output to print, $2 = exit code (default 0)
make_plugin_root() {
  local output="$1" exit_code="${2:-0}"
  local plugin_root="$TMP/plugin-root"
  rm -rf "$plugin_root"
  mkdir -p "$plugin_root/scripts"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" %s\nexit %s\n' \
    "$(printf '%s' "$output" | sed "s/'/'\"'\"'/g; s/^/'/; s/$/'/")" \
    "$exit_code" > "$plugin_root/scripts/sync-harness.sh"
  chmod +x "$plugin_root/scripts/sync-harness.sh"
  printf '%s\n' "$plugin_root"
}

# Build a fake project dir with an optional manifest.
# $1 = "yes" to create manifest, anything else to skip
make_project_dir() {
  local with_manifest="${1:-no}"
  local project_dir="$TMP/project-$$-$RANDOM"
  mkdir -p "$project_dir/.claude"
  if [ "$with_manifest" = "yes" ]; then
    printf '{"schema":1,"source":"/fake","sha":"abc123","files":{}}\n' \
      > "$project_dir/.claude/.harness-manifest.json"
  fi
  printf '%s\n' "$project_dir"
}

run_check() {
  local plugin_root="$1" project_dir="$2"
  CLAUDE_PLUGIN_ROOT="$plugin_root" CLAUDE_PROJECT_DIR="$project_dir" bash "$SCRIPT" 2>&1
}

# ── Test 1: no manifest → silent ──────────────────────────────────────────────

PLUGIN1=$(make_plugin_root "up-to-date: somefile")
PROJ1=$(make_project_dir no)

OUT1=$(run_check "$PLUGIN1" "$PROJ1")
EXIT1=$?

[ "$EXIT1" = "0" ] && ok || no "test 1: expected exit 0, got $EXIT1"
[ -z "$OUT1" ]     && ok || no "test 1: expected no output, got: $OUT1"

# ── Test 2: one "updated:" line → one notice ──────────────────────────────────

PLUGIN2=$(make_plugin_root "  updated: some/file.sh")
PROJ2=$(make_project_dir yes)

OUT2=$(run_check "$PLUGIN2" "$PROJ2")
EXIT2=$?

[ "$EXIT2" = "0" ] && ok || no "test 2: expected exit 0, got $EXIT2"
[ "$OUT2" = "[harness] project files are out of date — run /sync to apply updates" ] \
  && ok || no "test 2: unexpected output: $OUT2"

# ── Test 3: three "updated:" lines → still one notice ─────────────────────────

PLUGIN3=$(make_plugin_root "  updated: a
  updated: b
  updated: c")
PROJ3=$(make_project_dir yes)

OUT3=$(run_check "$PLUGIN3" "$PROJ3")
EXIT3=$?
LINE_COUNT3=$(printf '%s\n' "$OUT3" | grep -c . || true)

[ "$EXIT3" = "0" ] && ok || no "test 3: expected exit 0, got $EXIT3"
[ "$LINE_COUNT3" = "1" ] && ok || no "test 3: expected 1 output line, got $LINE_COUNT3: $OUT3"

# ── Test 4: "CONFLICT:" line → one conflict notice ────────────────────────────

PLUGIN4=$(make_plugin_root "  CONFLICT: some/file.sh — local edits + upstream change; resolve manually and re-run")
PROJ4=$(make_project_dir yes)

OUT4=$(run_check "$PLUGIN4" "$PROJ4")
EXIT4=$?

[ "$EXIT4" = "0" ] && ok || no "test 4: expected exit 0, got $EXIT4"
[ "$OUT4" = "[harness] sync conflict detected — run /sync and resolve manually" ] \
  && ok || no "test 4: unexpected output: $OUT4"

# ── Test 5: only "up-to-date:" lines → silent ─────────────────────────────────

PLUGIN5=$(make_plugin_root "  up-to-date: a
  up-to-date: b")
PROJ5=$(make_project_dir yes)

OUT5=$(run_check "$PLUGIN5" "$PROJ5")
EXIT5=$?

[ "$EXIT5" = "0" ] && ok || no "test 5: expected exit 0, got $EXIT5"
[ -z "$OUT5" ]     && ok || no "test 5: expected no output, got: $OUT5"

# ── Test 6: sync exits non-zero → silent ──────────────────────────────────────

PLUGIN6=$(make_plugin_root "  CONFLICT: some/file.sh" 1)
PROJ6=$(make_project_dir yes)

OUT6=$(run_check "$PLUGIN6" "$PROJ6")
EXIT6=$?

[ "$EXIT6" = "0" ] && ok || no "test 6: expected exit 0, got $EXIT6"

# ── Summary ───────────────────────────────────────────────────────────────────

echo "check-project-sync: $pass passed, $fail failed"
[ "$fail" = "0" ]
