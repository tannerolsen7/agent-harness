#!/usr/bin/env bash
# Tests for scripts/assemble-testing.sh and the slug-derivation algorithm.
#
# Three test paths:
#   1. Assembly: produces docs/TESTING.md with generated header + shards in alphabetical order
#   2. Idempotency: running the script twice produces the same output
#   3. Slug derivation: feat/ stripped, non-word chars become hyphens, lowercased
#
# GIT_DIR guard: unset inherited git state so temp-repo tests don't touch the real repo.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/assemble-testing.sh"

[ -f "$SCRIPT" ] || { echo "assemble-testing.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

DERIVE_SLUG="$ROOT/scripts/derive-slug.sh"
[ -f "$DERIVE_SLUG" ] || { echo "assemble-testing.test: $DERIVE_SLUG not found"; exit 1; }

derive_slug() { bash "$DERIVE_SLUG" "$1"; }

# ── Path 1: assembly produces canonical file ──────────────────────────────────

echo "── assembly: generated header + shards in alphabetical filename order ──"
T=$(mktemp -d /tmp/assemble-testing-XXXX)
mkdir -p "$T/docs/testing"

cat > "$T/docs/testing/alpha.md" << 'EOF'
## Alpha feature

### Confirmed behaviors

- **Alpha behavior:** An alpha behavior.
EOF

cat > "$T/docs/testing/beta.md" << 'EOF'
## Beta feature

### Confirmed behaviors

- **Beta behavior:** A beta behavior.
EOF

TESTING_ROOT="$T" bash "$SCRIPT" 2>/dev/null
OUT="$T/docs/TESTING.md"

[ -f "$OUT" ] \
  && ok || no "docs/TESTING.md should be created"

grep -q "generated" "$OUT" 2>/dev/null \
  && ok || no "output should contain a generated-file header"

grep -q "Alpha feature" "$OUT" 2>/dev/null \
  && ok || no "output should contain alpha shard content"

grep -q "Beta feature" "$OUT" 2>/dev/null \
  && ok || no "output should contain beta shard content"

alpha_line=$(grep -n "Alpha feature" "$OUT" 2>/dev/null | cut -d: -f1)
beta_line=$(grep -n "Beta feature" "$OUT" 2>/dev/null | cut -d: -f1)
[ -n "$alpha_line" ] && [ -n "$beta_line" ] && [ "$alpha_line" -lt "$beta_line" ] \
  && ok || no "alpha shard should appear before beta (alphabetical order)"

grep -q "^---$" "$OUT" 2>/dev/null \
  && ok || no "output should have a --- divider between shards"

# ── Path 2: idempotency ───────────────────────────────────────────────────────

echo "── idempotency: running the script twice produces the same file ──"
first=$(cat "$OUT")
TESTING_ROOT="$T" bash "$SCRIPT" 2>/dev/null
second=$(cat "$OUT")
[ "$first" = "$second" ] \
  && ok || no "running assemble-testing.sh twice should produce identical output"

rm -rf "$T"

# ── Path 3: slug derivation ───────────────────────────────────────────────────

echo "── slug: feat/ prefix stripped ──"
slug=$(derive_slug "feat/my-feature")
[ "$slug" = "my-feature" ] \
  && ok || no "feat/my-feature should produce my-feature (got $slug)"

echo "── slug: non-feat/ prefix kept ──"
slug=$(derive_slug "fix/auth-bug")
[ "$slug" = "fix-auth-bug" ] \
  && ok || no "fix/auth-bug should produce fix-auth-bug (got $slug)"

echo "── slug: slashes and non-word chars become hyphens, lowercased ──"
slug=$(derive_slug "feat/auth/login-v2")
[ "$slug" = "auth-login-v2" ] \
  && ok || no "feat/auth/login-v2 should produce auth-login-v2 (got $slug)"

# ── Path 4: pre-commit hook auto-stages assembled file ───────────────────────

echo "── pre-commit hook: runs assemble-testing.sh and stages docs/TESTING.md ──"
D=$(mktemp -d)
(
  cd "$D" || exit 1
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
  git init -q
  git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m init

  mkdir -p docs/testing scripts
  cp "$ROOT/scripts/assemble-testing.sh" scripts/assemble-testing.sh

  cat > docs/testing/my-feature.md << 'SHARD'
## My feature

### Confirmed behaviors

- **My behavior:** A behavior.
SHARD

  git add docs/testing/my-feature.md

  # Run just the shard-detection logic from the pre-commit hook.
  STAGED_SHARDS=$(git diff --cached --name-only --diff-filter=ACM | grep "^docs/testing/" || true)
  if [ -n "$STAGED_SHARDS" ]; then
    bash scripts/assemble-testing.sh
    git add docs/TESTING.md
  fi

  git diff --cached --name-only | grep -q "^docs/TESTING.md$" && echo "staged" || echo "not-staged"
) > "$D/result.txt" 2>/dev/null

result=$(cat "$D/result.txt" 2>/dev/null || echo "not-staged")
[ "$result" = "staged" ] \
  && ok || no "docs/TESTING.md should be auto-staged when a shard file is staged (got: $result)"
rm -rf "$D"

# Structural guard: the pre-commit hook must call assemble-testing.sh and git add docs/TESTING.md.
grep -q "assemble-testing.sh" "$ROOT/.husky/pre-commit" 2>/dev/null \
  && ok || no "pre-commit hook must call assemble-testing.sh"
grep -q "git add docs/TESTING.md" "$ROOT/.husky/pre-commit" 2>/dev/null \
  && ok || no "pre-commit hook must stage docs/TESTING.md after assembling"

echo ""
printf 'assemble-testing: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
