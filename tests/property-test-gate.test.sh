#!/usr/bin/env bash
# Property-test coverage gate — scripts/property-test-gate.sh.
# Most cases use the test-only overrides (PROPINV_CONFIG / PROPINV_CHANGED /
# PROPINV_TRACKED) so they're pure. The final section builds a real temp git repo to
# exercise the git-derived path (base resolution + committed-tree read) that the overrides
# bypass.

# Hermetic git env: when run inside the pre-push hook, git exports GIT_DIR etc.
# Clear them so any git discovery here uses the intended repo, not the hook's env.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE

set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
GATE="$ROOT/scripts/property-test-gate.sh"
[ -f "$GATE" ] || { echo "property-test-gate.test: $GATE not found"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "property-test-gate.test: node required"; exit 1; }

pass=0; fail=0
TMP=$(mktemp -d)
CFG="$TMP/property-invariants.json"
cat > "$CFG" <<'JSON'
{
  "invariants": [
    {
      "name": "pricing",
      "modulePattern": "(^|/)src/(utils|schemas)/.*(pric|total|tax|discount)",
      "testPattern": "(^|/)src/(utils|schemas)/.*(pric|total|tax|discount).*\\.(prop|property)\\.(test|spec)\\."
    }
  ]
}
JSON

run() { # run <expect> <changed> <tracked> [config]
  local expect="$1" rc
  PROPINV_CONFIG="${4:-$CFG}" PROPINV_CHANGED="$2" PROPINV_TRACKED="$3" \
    bash "$GATE" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$expect" ]; then pass=$((pass+1)); else echo "  MISS: want exit $expect, got $rc (changed='$2')"; fail=$((fail+1)); fi
}

# ── Core matching behavior ──────────────────────────────────────────────────
# 1. no config → inert (0)
run 0 "src/utils/pricing.ts" "" "/nonexistent/property-invariants.json"
# 2. invariant module changed, matching property test present → pass (0)
run 0 "src/utils/pricing.ts" "src/utils/pricing.ts
src/utils/pricing.property.test.ts"
# 3. invariant module changed, no matching property test → block (1)
run 1 "src/utils/pricing.ts" "src/utils/pricing.ts
src/utils/pricing.test.ts"
# 4. a plain unit test (not a property test) does not satisfy the gate → block (1)
run 1 "src/utils/tax.ts" "src/utils/tax.ts
src/utils/tax.spec.ts"
# 5. no invariant module changed → pass regardless of tests (0)
run 0 "src/ui/button.tsx" "src/ui/button.tsx"
# 6. property test exists elsewhere in tree (tracked, not in diff) → pass (0)
run 0 "src/schemas/total.ts" "src/utils/other.ts
src/schemas/total.property.spec.ts"

# ── Case-insensitive matching (H1: a lowercase pattern must catch PascalCase files) ─────────
# 15. PascalCase money file matches lowercase pattern, no property test → block (1)
run 1 "src/utils/TaxCalculator.ts" "src/utils/TaxCalculator.ts"
# 16. same, with a matching property test present → pass (0)
run 0 "src/utils/TaxCalculator.ts" "src/utils/TaxCalculator.ts
src/utils/TaxCalculator.property.test.ts"

# ── Leading-dash pattern is a regex, not a grep option (must not error as exit 2) ───────────
DASH="$TMP/dash.json"
cat > "$DASH" <<'JSON'
{ "invariants": [ { "name": "dash", "modulePattern": "-foo", "testPattern": "bar\\.property\\." } ] }
JSON
# 20. modulePattern "-foo" matches "-foo.ts"; no matching test → block (1), NOT a grep-option error (2)
run 1 "-foo.ts" "-foo.ts" "$DASH"

# ── Multiple invariants (exercises the TSV parse with >1 row) ────────────────────────────────
MULTI="$TMP/multi.json"
cat > "$MULTI" <<'JSON'
{
  "invariants": [
    { "name": "pricing", "modulePattern": "(^|/)src/pricing", "testPattern": "(^|/)src/pricing.*\\.property\\.test\\." },
    { "name": "tax",     "modulePattern": "(^|/)src/tax",     "testPattern": "(^|/)src/tax.*\\.property\\.test\\." }
  ]
}
JSON
# 17. two invariants, second one uncovered → block (1)
run 1 "src/pricing.ts
src/tax.ts" "src/pricing.ts
src/pricing.property.test.ts
src/tax.ts" "$MULTI"
# 18. two invariants, both covered → pass (0)
run 0 "src/pricing.ts
src/tax.ts" "src/pricing.ts
src/pricing.property.test.ts
src/tax.ts
src/tax.property.test.ts" "$MULTI"

# ── Fail-closed config validation (exit 2) ──────────────────────────────────
# 7. malformed JSON → 2
BAD="$TMP/bad.json"; printf '{ not json' > "$BAD"
run 2 "src/utils/pricing.ts" "" "$BAD"
# 8. invariant missing testPattern → 2
NOFIELD="$TMP/nofield.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "src/x" } ] }' > "$NOFIELD"
run 2 "src/x.ts" "src/x.ts" "$NOFIELD"
# 9. missing top-level invariants array → 2
NOARR="$TMP/noarr.json"; printf '{ "foo": 1 }' > "$NOARR"
run 2 "src/utils/pricing.ts" "" "$NOARR"
# 10. invalid regex in a pattern → 2
BADRE="$TMP/badre.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "src/x[", "testPattern": "y" } ] }' > "$BADRE"
run 2 "src/x.ts" "src/x.ts" "$BADRE"
# 11. empty testPattern (would match every file) → 2
EMPTYT="$TMP/emptyt.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "src/x", "testPattern": "" } ] }' > "$EMPTYT"
run 2 "src/x.ts" "README.md" "$EMPTYT"
# 12. empty modulePattern → 2
EMPTYM="$TMP/emptym.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "", "testPattern": "y" } ] }' > "$EMPTYM"
run 2 "src/x.ts" "src/x.ts" "$EMPTYM"
# 13. identical modulePattern and testPattern (gate theater) → 2
SAME="$TMP/same.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "src/pricing", "testPattern": "src/pricing" } ] }' > "$SAME"
run 2 "src/pricing.ts" "src/pricing.ts" "$SAME"
# 14. a literal tab inside a pattern (would corrupt the TSV) → 2
TABP="$TMP/tab.json"; printf '{ "invariants": [ { "name": "x", "modulePattern": "foo\\tbar", "testPattern": "y" } ] }' > "$TABP"
run 2 "src/x.ts" "src/x.ts" "$TABP"

# ── 0 invariants declared → inert-but-explicit (0) ──────────────────────────
EMPTYARR="$TMP/emptyarr.json"; printf '{ "invariants": [] }' > "$EMPTYARR"
# 19. empty invariants array → pass (0)
run 0 "src/utils/pricing.ts" "src/utils/pricing.ts" "$EMPTYARR"

# ── Git-path integration (real temp repo; no PROPINV_CHANGED/TRACKED overrides) ──────────────
gitpass=0
REPO="$TMP/repo"
mkdir -p "$REPO/src/utils"
(
  cd "$REPO" || exit 1
  git init -q
  git config user.email t@t.t; git config user.name t
  git checkout -q -b work
  mkdir -p .claude src/utils
  cp "$CFG" .claude/property-invariants.json
  printf 'export const total = 0\n' > src/utils/pricing.ts
  git add -A; git commit -qm base
  BASECOMMIT=$(git rev-parse HEAD)
  # Change the invariant module in a new commit, WITHOUT a committed property test.
  printf 'export const total = 1\n' > src/utils/pricing.ts
  git add -A; git commit -qm change
  # Stage a property test but DO NOT commit it — must not count as coverage.
  printf 'test\n' > src/utils/pricing.property.test.ts
  git add src/utils/pricing.property.test.ts

  rc=0; PROPINV_BASE="$BASECOMMIT" bash "$GATE" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 1 ] || { echo "  MISS(git): staged-not-committed test should block (want 1, got $rc)"; exit 2; }

  # Now commit the property test — coverage exists → pass (0).
  git commit -qm addtest
  rc=0; PROPINV_BASE="$BASECOMMIT" bash "$GATE" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || { echo "  MISS(git): committed property test should pass (want 0, got $rc)"; exit 2; }

  # Stale base that already contains HEAD → fail-closed (2).
  rc=0; PROPINV_BASE=HEAD bash "$GATE" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] || { echo "  MISS(git): base containing HEAD should fail-closed (want 2, got $rc)"; exit 2; }
)
gitpass=$?
if [ "$gitpass" -eq 0 ]; then pass=$((pass+3)); else fail=$((fail+1)); fi

rm -rf "$TMP"
echo ""
echo "property-test-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
