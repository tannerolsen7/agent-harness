#!/usr/bin/env bash
# Tests for scripts/sync-open-prs.sh — auto-rebase conflicting open PRs.
# Uses stub gh binaries so no network or real GitHub token is required.
# (run-tests.sh clears inherited git env so git ops stay isolated.)
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/sync-open-prs.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

FAKE_BIN=$(mktemp -d)
trap 'rm -rf "$FAKE_BIN"' EXIT

# Run the script from the worktree root with $FAKE_BIN as the only place gh could come from.
# For the no-CLI test: PATH is minimal (no Homebrew) so real gh/glab are absent.
# For all other tests: $FAKE_BIN is prepended to the full PATH so stubs shadow real gh.
run_no_cli() {
  ( cd "$ROOT" && PATH="$FAKE_BIN:/usr/bin:/bin:/usr/sbin:/sbin" bash "$SCRIPT" ) 2>&1
}
run_with_stub() {
  ( cd "$ROOT" && PATH="$FAKE_BIN:$PATH" bash "$SCRIPT" ) 2>&1
}

# ---- Behavior 1: missing forge CLI exits 0 with skip message ----
rm -f "$FAKE_BIN/gh" "$FAKE_BIN/glab"
OUT=$(run_no_cli); EC=$?
chk "$EC" "no-CLI: exit 0"
printf '%s' "$OUT" | grep -qF "forge CLI unavailable — skipping PR sync"
chk "$?" "no-CLI: skip message printed"

# ---- Behavior 2: no open PRs exits 0 with skip message ----
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*) echo "[]" ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "no-PRs: exit 0"
printf '%s' "$OUT" | grep -qF "no open PRs to sync"
chk "$?" "no-PRs: skip message printed"

# ---- Behavior 3: conflicting PR rebased, success printed ----
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":42,"headRefName":"feat/my-feature","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false}]'
    ;;
  *"pr update-branch"*) exit 0 ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "rebase-success: exit 0"
printf '%s' "$OUT" | grep -qF "updated #42 (feat/my-feature)"
chk "$?" "rebase-success: updated line printed"

# ---- Behavior 4: rebase fails, script continues to next PR and exits 0 ----
# Two PRs: first fails rebase, second succeeds — verifies the script keeps going.
cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *"pr list"*)
    echo '[{"number":42,"headRefName":"feat/first","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false},{"number":43,"headRefName":"feat/second","baseRefName":"main","mergeable":"CONFLICTING","isDraft":false}]'
    ;;
  *"update-branch"*"42"*) exit 1 ;;
  *"update-branch"*"43"*) exit 0 ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
OUT=$(run_with_stub); EC=$?
chk "$EC" "rebase-fail: exit 0"
printf '%s' "$OUT" | grep -qF "failed #42 (feat/first)"
chk "$?" "rebase-fail: failure line printed for #42"
printf '%s' "$OUT" | grep -qF "updated #43 (feat/second)"
chk "$?" "rebase-fail: continues and updates #43"

# ---- Behavior 5: PR targeting a non-default base branch is skipped ----
rm -f "$FAKE_BIN/update-called"
cat > "$FAKE_BIN/gh" <<EOF
#!/bin/sh
case "\$*" in
  *"pr list"*)
    echo '[{"number":99,"headRefName":"feat/child","baseRefName":"feat/parent","mergeable":"CONFLICTING","isDraft":false}]'
    ;;
  *"pr update-branch"*)
    touch "$FAKE_BIN/update-called"
    exit 0
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
run_with_stub >/dev/null 2>&1; EC=$?
chk "$EC" "non-default-base: exit 0"
[ ! -f "$FAKE_BIN/update-called" ]
chk "$?" "non-default-base: update-branch NOT called for stacked PR"

# ---- Behavior 6: draft PR is skipped ----
rm -f "$FAKE_BIN/draft-update-called"
cat > "$FAKE_BIN/gh" <<EOF
#!/bin/sh
case "\$*" in
  *"pr list"*)
    echo '[{"number":77,"headRefName":"feat/draft-work","baseRefName":"main","mergeable":"CONFLICTING","isDraft":true}]'
    ;;
  *"pr update-branch"*)
    touch "$FAKE_BIN/draft-update-called"
    exit 0
    ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/gh"
run_with_stub >/dev/null 2>&1; EC=$?
chk "$EC" "draft-PR: exit 0"
[ ! -f "$FAKE_BIN/draft-update-called" ]
chk "$?" "draft-PR: update-branch NOT called for draft PR"

# ---- Behavior 7: PITFALLS.md has merge=union in .gitattributes ----
grep -qE "PITFALLS\.md[[:space:]]+merge=union" "$ROOT/.gitattributes"
chk "$?" ".gitattributes: PITFALLS.md merge=union present"

echo ""
echo "sync-open-prs: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
