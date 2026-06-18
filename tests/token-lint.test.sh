#!/usr/bin/env bash
# Tests for scripts/token-lint.sh — UI token linter and absolute-ban checker.
#
# Three test paths:
#   1. Token detection: hardcoded hex/rgb exits non-zero; token-only file exits zero.
#   2. Absolute bans: gradient-text, glassmorphism, side-stripe border, hero-metric,
#      identical-card-grid, and eyebrow-on-every-section each exit non-zero.
#   3. Missing DESIGN.md: script exits 0 with a clear skip message (non-blocking).
#
# GIT_DIR guard: unset inherited git state so temp-repo tests don't touch the real repo.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LINT="$ROOT/scripts/token-lint.sh"
DESIGN="$ROOT/docs/design/DESIGN.md"

[ -f "$LINT" ] || { echo "token-lint.test: $LINT not found"; exit 1; }

pass=0; fail=0
ok()     { pass=$((pass+1)); }
no()     { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }
hasout() { printf '%s' "$1" | grep -qi "$2" && pass=$((pass+1)) || { printf '  MISS (%s): output missing %q\n' "$3" "$2"; fail=$((fail+1)); }; }

# ── Helpers ───────────────────────────────────────────────────────────────────

# Write a temp CSS file with the given content; return its path.
tmpfile() {
  local f
  f=$(mktemp /tmp/token-lint-test-XXXX.css)
  printf '%s\n' "$1" > "$f"
  echo "$f"
}

# Run the linter against specific files (bypasses git-file discovery).
run_lint() {
  bash "$LINT" "$@" 2>&1
}

# ── Guard: DESIGN.md must exist for the non-skip tests ───────────────────────
if [ ! -f "$DESIGN" ]; then
  echo "token-lint.test: docs/design/DESIGN.md not found — token checks will all be skipped."
  echo "token-lint.test: SKIP (create docs/design/DESIGN.md to activate enforcement)"
  exit 0
fi

# ── Path 1: token detection ───────────────────────────────────────────────────

echo "── token-only file: exits 0 ──"
F=$(tmpfile ".button { color: var(--color-primary); padding: var(--space-4); }")
rc=$(bash "$LINT" "$F" >/dev/null 2>&1; echo $?)
[ "$rc" -eq 0 ] && ok || no "token-only CSS should exit 0 (got $rc)"
rm -f "$F"

echo "── hardcoded 6-digit hex: exits non-zero ──"
F=$(tmpfile ".button { color: #336699; }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "6-digit hex should exit non-zero"
hasout "$out" "hardcoded" "names the violation type" "6-digit hex"
rm -f "$F"

echo "── hardcoded 3-digit hex: exits non-zero ──"
F=$(tmpfile ".button { color: #369; }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "3-digit hex should exit non-zero"
hasout "$out" "hardcoded" "names the violation type" "3-digit hex"
rm -f "$F"

echo "── raw rgb() call: exits non-zero ──"
F=$(tmpfile ".button { color: rgb(51, 102, 153); }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "raw rgb() should exit non-zero"
hasout "$out" "rgb" "mentions rgb in output" "rgb()"
rm -f "$F"

echo "── raw rgba() call: exits non-zero ──"
F=$(tmpfile ".button { background: rgba(0, 0, 0, 0.5); }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "raw rgba() should exit non-zero"
rm -f "$F"

echo "── raw hsl() call: exits non-zero ──"
F=$(tmpfile ".button { color: hsl(210, 50%, 40%); }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "raw hsl() should exit non-zero"
rm -f "$F"

echo "── var(--color) reference allowed: exits 0 ──"
F=$(tmpfile ".button { color: var(--color-primary); background: var(--color-surface); }")
rc=$(bash "$LINT" "$F" >/dev/null 2>&1; echo $?)
[ "$rc" -eq 0 ] && ok || no "var(--color-*) usage should exit 0 (got $rc)"
rm -f "$F"

# ── Path 2: absolute bans ─────────────────────────────────────────────────────

echo "── ban: gradient text (background-clip: text): exits non-zero ──"
F=$(tmpfile ".title { background: linear-gradient(red, blue); background-clip: text; -webkit-background-clip: text; color: transparent; }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "gradient-text ban should exit non-zero"
hasout "$out" "gradient" "mentions gradient" "gradient-text ban"
rm -f "$F"

echo "── ban: glassmorphism (backdrop-filter: blur): exits non-zero ──"
F=$(tmpfile ".card { backdrop-filter: blur(10px); background: rgba(255,255,255,0.1); }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "glassmorphism ban should exit non-zero"
hasout "$out" "glassmorphism" "mentions glassmorphism" "glassmorphism ban"
rm -f "$F"

echo "── ban: side-stripe border 4px solid: exits non-zero ──"
F=$(tmpfile ".card { border-left: 4px solid var(--color-primary); }")
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "side-stripe ban (4px) should exit non-zero"
hasout "$out" "side-stripe" "mentions side-stripe" "side-stripe ban"
rm -f "$F"

echo "── ban: 1px border-left (divider, not stripe): exits 0 ──"
F=$(tmpfile ".nav { border-left: 1px solid var(--color-border); }")
rc=$(bash "$LINT" "$F" >/dev/null 2>&1; echo $?)
[ "$rc" -eq 0 ] && ok || no "1px border-left (divider) should exit 0 (got $rc)"
rm -f "$F"

echo "── ban: hero-metric class name: exits non-zero ──"
F=$(tmpfile '<div class="hero-metric"><span class="value">42</span><span class="label">Users</span></div>')
F2=$(mktemp /tmp/token-lint-test-XXXX.jsx)
cp "$F" "$F2"; rm -f "$F"; F="$F2"
out=$(run_lint "$F"); rc=$?
[ "$rc" -ne 0 ] && ok || no "hero-metric class ban should exit non-zero"
hasout "$out" "hero-metric" "mentions hero-metric" "hero-metric ban"
rm -f "$F"

echo "── ban: identical card grid class: warns (exits 0) ──"
F=$(tmpfile '<div class="card-grid"><div class="card">A</div><div class="card">B</div></div>')
F2=$(mktemp /tmp/token-lint-test-XXXX.jsx)
cp "$F" "$F2"; rm -f "$F"; F="$F2"
out=$(run_lint "$F"); rc=$?
# card-grid emits a warning (not an error), so exit code is still 0
[ "$rc" -eq 0 ] && ok || no "card-grid warning should still exit 0 (got $rc)"
hasout "$out" "card-grid" "mentions card-grid" "card-grid warning"
rm -f "$F"

echo "── ban: eyebrow label class: warns (exits 0) ──"
F=$(mktemp /tmp/token-lint-test-XXXX.jsx)
printf '<section><p class="eyebrow">Featured</p><h2>Heading</h2></section>\n' > "$F"
out=$(run_lint "$F"); rc=$?
[ "$rc" -eq 0 ] && ok || no "eyebrow warning should still exit 0 (got $rc)"
hasout "$out" "eyebrow" "mentions eyebrow" "eyebrow warning"
rm -f "$F"

# ── Path 3: missing DESIGN.md ─────────────────────────────────────────────────

echo "── missing DESIGN.md: exits 0 with skip message ──"
# Run the linter from a temp git repo that has no docs/design/DESIGN.md.
TMPDIR_TEST=$(mktemp -d)
git -C "$TMPDIR_TEST" init -q
# Create a dummy UI file inside the temp repo so the linter has something to find.
mkdir -p "$TMPDIR_TEST/src"
printf '.button { color: #ff0000; }\n' > "$TMPDIR_TEST/src/button.css"
git -C "$TMPDIR_TEST" add src/button.css >/dev/null
git -C "$TMPDIR_TEST" config user.email "test@test.com" >/dev/null
git -C "$TMPDIR_TEST" config user.name "Test" >/dev/null
git -C "$TMPDIR_TEST" commit -qm "test" >/dev/null
# Run the linter from the temp repo dir so git rev-parse finds the right root.
out=$(cd "$TMPDIR_TEST" && bash "$LINT" "src/button.css" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok || no "missing DESIGN.md should exit 0 (non-blocking), got $rc"
hasout "$out" "DESIGN.md" "mentions DESIGN.md" "missing-DESIGN.md message"
hasout "$out" "design-synthesizer\|/design" "mentions the fix command" "missing-DESIGN.md fix hint"
rm -rf "$TMPDIR_TEST"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "token-lint: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
