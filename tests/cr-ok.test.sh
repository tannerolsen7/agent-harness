#!/usr/bin/env bash
# cr-ok.sh writes the /cr push sentinel honestly: self-resolves branch:sha, refuses a dirty
# (tracked-modified) tree, appends an audit line, and runs no checks. All hermetic + offline:
# each case runs in a throwaway git repo.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CROK="$ROOT/scripts/cr-ok.sh"
[ -x "$CROK" ] || { echo "test: $CROK not found or not executable"; exit 1; }

pass=0; fail=0
ok()  { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got '$1', want '$2'"; fail=$((fail+1)); fi; }

# Build a fresh repo on branch feat/x with a committed tracked file; print its dir.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
    git checkout -q -b feat/x
    echo hello > tracked.txt && git add tracked.txt && git commit -q --no-verify -m add
  ) >/dev/null 2>&1
  echo "$d"
}

echo "── clean tree: writes branch:sha + audit line, exit 0 ──"
D=$(mk); SHA=$(cd "$D" && git rev-parse HEAD)
rc=$(cd "$D" && bash "$CROK" >/dev/null 2>&1; echo $?)
ok "$rc" 0 "clean exit 0"
if [ -f "$D/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel not written"; fail=$((fail+1)); fi
ok "$(cat "$D/.claude/.cr-ok" 2>/dev/null)" "feat/x:$SHA" "sentinel content = branch:sha"
ok "$(wc -l < "$D/.claude/.cr-ok" | tr -d ' ')" 0 "sentinel has no trailing newline"
if grep -q "feat/x:$SHA" "$D/.claude/.cr-ok.log" 2>/dev/null; then pass=$((pass+1)); else echo "  MISS: audit log missing branch:sha"; fail=$((fail+1)); fi
rm -rf "$D"

echo "── audit log is append-only (two certifications → two lines) ──"
D=$(mk)
( cd "$D" && bash "$CROK" >/dev/null 2>&1 && bash "$CROK" >/dev/null 2>&1 )
ok "$(wc -l < "$D/.claude/.cr-ok.log" | tr -d ' ')" 2 "two audit lines after two runs"
rm -rf "$D"

echo "── dirty tree (unstaged tracked change): refuses, writes no sentinel ──"
D=$(mk)
( cd "$D" && echo changed >> tracked.txt )
out=$(cd "$D" && bash "$CROK" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: dirty tree should exit non-zero"; fail=$((fail+1)); fi
if [ ! -f "$D/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel written on dirty tree"; fail=$((fail+1)); fi
if printf '%s' "$out" | grep -qi 'uncommitted'; then pass=$((pass+1)); else echo "  MISS: no 'uncommitted' message"; fail=$((fail+1)); fi
rm -rf "$D"

echo "── staged-but-uncommitted change: also refuses ──"
D=$(mk)
( cd "$D" && echo changed >> tracked.txt && git add tracked.txt )
rc=$(cd "$D" && bash "$CROK" >/dev/null 2>&1; echo $?)
if [ "$rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS: staged change should exit non-zero"; fail=$((fail+1)); fi
if [ ! -f "$D/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel written with staged change"; fail=$((fail+1)); fi
rm -rf "$D"

echo "── untracked file does NOT count as dirty: still writes ──"
D=$(mk)
( cd "$D" && echo new > untracked.txt )
rc=$(cd "$D" && bash "$CROK" >/dev/null 2>&1; echo $?)
ok "$rc" 0 "untracked-only → exit 0"
if [ -f "$D/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel not written despite only-untracked"; fail=$((fail+1)); fi
rm -rf "$D"

echo ""
echo "cr-ok: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
