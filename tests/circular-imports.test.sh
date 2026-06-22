#!/usr/bin/env bash
# Tests scripts/circular-imports.sh — four behaviors:
# 1. Skip (exit 0, no output) when package.json is absent.
# 2. Skip (exit 0, informational message) when npx is unavailable.
# 3. Pass (exit 0) when madge finds no cycles.
# 4. Fail (exit 1) when madge finds cycles.
#
# Behaviors 3 and 4 require npx and are skipped when it is absent.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/circular-imports.sh"
[ -f "$SCRIPT" ] || { echo "circular-imports.test: $SCRIPT not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got '$1', want '$2'"
    fail=$((fail+1))
  fi
}

# ── Behavior 1: skip when package.json is absent ──
tmp=$(mktemp -d /tmp/ci-test-XXXXXX)
git -C "$tmp" init -q
rc=0; (cd "$tmp" && bash "$SCRIPT") >/dev/null 2>&1 || rc=$?
ok "$rc" "0" "skip: no package.json"
rm -rf "$tmp"

# ── Behavior 2: skip when npx is unavailable ──
# Build a PATH that includes bash and git but not npx.
BASH_DIR=$(dirname "$(command -v bash)")
GIT_BIN_DIR=$(dirname "$(command -v git)")
SAFE_PATH="$BASH_DIR:$GIT_BIN_DIR:/usr/bin:/bin"
tmp=$(mktemp -d /tmp/ci-test-XXXXXX)
git -C "$tmp" init -q
echo '{}' > "$tmp/package.json"
rc=0; msg=""
msg=$(cd "$tmp" && PATH="$SAFE_PATH" bash "$SCRIPT" 2>&1) || rc=$?
ok "$rc" "0" "skip: npx unavailable (exit)"
if printf '%s\n' "$msg" | grep -q "npx not found"; then
  pass=$((pass+1))
else
  echo "  MISS (skip: npx unavailable — message): got: $msg"
  fail=$((fail+1))
fi
rm -rf "$tmp"

# ── Behaviors 3 and 4: require npx ──
if ! command -v npx >/dev/null 2>&1; then
  echo "circular-imports.test: npx not available — skipping live madge tests (behaviors 3 and 4)."
else

  # Behavior 3: pass when no cycles exist.
  tmp=$(mktemp -d /tmp/ci-test-XXXXXX)
  git -C "$tmp" init -q
  echo '{}' > "$tmp/package.json"
  mkdir -p "$tmp/src"
  printf 'export const a = 1;\n' > "$tmp/src/a.js"
  printf 'import { a } from "./a.js";\nexport const b = a + 1;\n' > "$tmp/src/b.js"
  rc=0; out=""
  out=$(cd "$tmp" && bash "$SCRIPT" 2>&1) || rc=$?
  ok "$rc" "0" "pass: no cycles"
  [ "$rc" != "0" ] && printf '  output: %s\n' "$out"
  rm -rf "$tmp"

  # Behavior 4: fail when cycles exist.
  tmp=$(mktemp -d /tmp/ci-test-XXXXXX)
  git -C "$tmp" init -q
  echo '{}' > "$tmp/package.json"
  mkdir -p "$tmp/src"
  # a imports b, b imports a — a cycle.
  printf 'import { b } from "./b.js";\nexport const a = b;\n' > "$tmp/src/a.js"
  printf 'import { a } from "./a.js";\nexport const b = a;\n' > "$tmp/src/b.js"
  rc=0; out=""
  out=$(cd "$tmp" && bash "$SCRIPT" 2>&1) || rc=$?
  ok "$rc" "1" "fail: cycles found"
  [ "$rc" != "1" ] && printf '  output: %s\n' "$out"
  rm -rf "$tmp"

fi

echo "circular-imports.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
