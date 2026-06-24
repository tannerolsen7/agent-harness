#!/usr/bin/env bash
# Tests for session isolation — auto-created worktrees on SessionStart.
#
# Five behaviors:
#   B1. SessionStart creates a worktree when on main in the main repo
#   B2. SessionStart skips when already in a worktree (.git is a file)
#   B3. SessionStart skips when not on main or master
#   B4. SessionStop removes worktree + branch when no commits were added
#   B5. SessionStop leaves worktree and prints a summary when commits exist
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
START_HOOK="$ROOT/.claude/hooks/session-start.sh"
STOP_HOOK="$ROOT/.claude/hooks/session-stop.sh"

[ -x "$START_HOOK" ] || { echo "session-isolation.test: $START_HOOK not found or not executable"; exit 1; }
[ -x "$STOP_HOOK"  ] || { echo "session-isolation.test: $STOP_HOOK not found or not executable"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

CLEAR_GIT="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE"

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

# ── B1: SessionStart creates a worktree when on main in the main repo ─────────

SID1="si-test-b1-001"
TMP1=$(mktemp -d)
trap 'rm -rf "$TMP1"' EXIT
setup_repo "$TMP1"

OUT1=$(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '{"session_id":"%s","model":"claude-test"}' "$SID1" \
    | CLAUDE_PROJECT_DIR="$TMP1" bash "$START_HOOK" 2>/dev/null
)

WT1="$TMP1/.claude/worktrees/$SID1"
if [ -f "$WT1/.git" ]; then
  ok
else
  no "B1: worktree not created at $WT1 (expected .git file inside it)"
fi

if [ -f "/tmp/claude-session-wt-${SID1}" ]; then
  ok
else
  no "B1: temp file /tmp/claude-session-wt-$SID1 not written"
fi

if printf '%s' "$OUT1" | grep -q "Session worktree"; then
  ok
else
  no "B1: stdout did not mention 'Session worktree'"
fi

BRANCH1=$(git -C "$WT1" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$BRANCH1" = "session/$SID1" ]; then
  ok
else
  no "B1: worktree branch is '$BRANCH1', expected 'session/$SID1'"
fi

# ── B2: SessionStart skips when already in a worktree ─────────────────────────

SID2="si-test-b2-002"
TMP2=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2"' EXIT
setup_repo "$TMP2"

# Make TMP2 look like a worktree by replacing .git dir with a .git file.
mv "$TMP2/.git" "$TMP2/.git-real"
printf 'gitdir: %s/.git-real\n' "$TMP2" > "$TMP2/.git"

(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '{"session_id":"%s","model":"claude-test"}' "$SID2" \
    | CLAUDE_PROJECT_DIR="$TMP2" bash "$START_HOOK" >/dev/null 2>/dev/null || true
)

WT2="$TMP2/.claude/worktrees/$SID2"
if [ ! -d "$WT2" ] && [ ! -f "/tmp/claude-session-wt-${SID2}" ]; then
  ok
else
  no "B2: worktree or temp file was created even though .git is a file (already in worktree)"
fi

# ── B3: SessionStart skips when not on main or master ─────────────────────────

SID3="si-test-b3-003"
TMP3=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2" "$TMP3"' EXIT
setup_repo "$TMP3"
git -C "$TMP3" checkout -q -b feat/something 2>/dev/null

(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '{"session_id":"%s","model":"claude-test"}' "$SID3" \
    | CLAUDE_PROJECT_DIR="$TMP3" bash "$START_HOOK" >/dev/null 2>/dev/null || true
)

WT3="$TMP3/.claude/worktrees/$SID3"
if [ ! -d "$WT3" ] && [ ! -f "/tmp/claude-session-wt-${SID3}" ]; then
  ok
else
  no "B3: worktree or temp file was created even though branch is 'feat/something'"
fi

# ── B4: SessionStop removes worktree + branch when no commits were added ───────

SID4="si-test-b4-004"
TMP4=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2" "$TMP3" "$TMP4"' EXIT
setup_repo "$TMP4"

# Simulate what session-start would have created.
WT4="$TMP4/.claude/worktrees/$SID4"
git -C "$TMP4" worktree add -b "session/$SID4" "$WT4" HEAD >/dev/null 2>&1
printf '%s\n' "$WT4" > "/tmp/claude-session-wt-${SID4}"

# Record a start time so session-stop can compute duration.
printf '%s claude-test\n' "$(date +%s)" > "/tmp/claude-activity-${SID4}"

(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '{"session_id":"%s"}' "$SID4" \
    | CLAUDE_PROJECT_DIR="$TMP4" bash "$STOP_HOOK" >/dev/null 2>/dev/null || true
)

# Worktree dir should be gone.
if [ ! -d "$WT4" ]; then
  ok
else
  no "B4: worktree dir still exists after clean session stop — expected it to be removed"
fi

# Session branch should be gone.
if ! git -C "$TMP4" rev-parse "session/$SID4" >/dev/null 2>&1; then
  ok
else
  no "B4: branch 'session/$SID4' still exists after clean session stop"
fi

# Temp file should be cleaned up.
if [ ! -f "/tmp/claude-session-wt-${SID4}" ]; then
  ok
else
  no "B4: temp file /tmp/claude-session-wt-$SID4 still exists after clean session stop"
fi

# ── B5: SessionStop prints a summary and leaves the worktree when commits exist

SID5="si-test-b5-005"
TMP5=$(mktemp -d)
trap 'rm -rf "$TMP1" "$TMP2" "$TMP3" "$TMP4" "$TMP5"' EXIT
setup_repo "$TMP5"

WT5="$TMP5/.claude/worktrees/$SID5"
git -C "$TMP5" worktree add -b "session/$SID5" "$WT5" HEAD >/dev/null 2>&1
printf '%s\n' "$WT5" > "/tmp/claude-session-wt-${SID5}"
printf '%s claude-test\n' "$(date +%s)" > "/tmp/claude-activity-${SID5}"

# Make a commit in the session worktree.
(
  cd "$WT5"
  touch some-work.txt
  git add some-work.txt
  git commit -q --no-verify -m "feat: some work"
) >/dev/null 2>&1

OUT5=$(
  unset $CLEAR_GIT 2>/dev/null || true
  printf '{"session_id":"%s"}' "$SID5" \
    | CLAUDE_PROJECT_DIR="$TMP5" bash "$STOP_HOOK" 2>/dev/null
)

# Worktree must still be there.
if [ -d "$WT5" ]; then
  ok
else
  no "B5: worktree was removed even though the session branch has commits"
fi

# Output must mention the session branch.
if printf '%s' "$OUT5" | grep -q "session/$SID5"; then
  ok
else
  no "B5: stop output did not mention session branch 'session/$SID5'"
fi

# Cleanup temp files for B5.
rm -f "/tmp/claude-session-wt-${SID5}" || true
git -C "$TMP5" worktree remove "$WT5" --force >/dev/null 2>&1 || true
git -C "$TMP5" branch -D "session/$SID5" >/dev/null 2>&1 || true

# ── Summary ───────────────────────────────────────────────────────────────────

[ "$fail" = "0" ] && echo "session-isolation: OK ($pass passed)"
exit "$fail"
