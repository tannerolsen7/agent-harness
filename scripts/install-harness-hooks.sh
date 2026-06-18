#!/usr/bin/env bash
# Wire the git hooks (husky) into a target repo. This is a SEPARATE step from install.sh because
# it has side effects install.sh deliberately avoids: it runs `npm install` (a network call) and
# edits package.json. The user inspects and runs this themselves.
#
# Behavior:
#   - No package.json: create a minimal one with "prepare" (husky) and "test" (harness runner).
#   - package.json with no prepare/test: add them.
#   - package.json that already has a "prepare" script: print the exact lines to add and exit
#     non-zero. We never overwrite a prepare script the project may depend on.
#   - Run `npm install` to wire husky, then verify .husky/pre-commit is executable.
#
# Set _HARNESS_SKIP_NPM=1 to skip the npm install + executable check (used by tests only).
#
# Usage:
#   bash scripts/install-harness-hooks.sh [TARGET_DIR]
set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR=$(cd "$TARGET_DIR" 2>/dev/null && pwd) || { echo "hooks: target dir does not exist: ${1:-.}" >&2; exit 1; }
PKG="$TARGET_DIR/package.json"

PREPARE_CMD="husky"
TEST_CMD="bash scripts/run-tests.sh"

if [ ! -f "$PKG" ]; then
  echo "No package.json — creating a minimal one with prepare + test scripts."
  cat > "$PKG" <<JSON
{
  "name": "$(basename "$TARGET_DIR")",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "prepare": "$PREPARE_CMD",
    "test": "$TEST_CMD"
  },
  "devDependencies": {
    "husky": "^9.1.7"
  }
}
JSON
  echo "  created package.json"
else
  command -v jq >/dev/null 2>&1 || { echo "hooks: jq is required to edit an existing package.json." >&2; exit 1; }
  existing_prepare=$(jq -r '.scripts.prepare // empty' "$PKG")
  if [ -n "$existing_prepare" ]; then
    echo "package.json already has a \"prepare\" script — leaving it untouched." >&2
    echo "Add these manually if they are not already wired:" >&2
    echo "  \"prepare\": \"$existing_prepare && $PREPARE_CMD\"   (chain husky onto your prepare)" >&2
    echo "  \"test\": \"$TEST_CMD\"" >&2
    echo "Then add husky to devDependencies and run: npm install" >&2
    exit 1
  fi
  echo "Adding prepare + test scripts to package.json."
  tmp=$(mktemp)
  trap 'rm -f "${tmp:-}"' EXIT   # never leak the temp package.json if the jq edit aborts
  jq --arg prep "$PREPARE_CMD" --arg test "$TEST_CMD" '
    .scripts = (.scripts // {})
    | .scripts.prepare = $prep
    | (if (.scripts.test // "") == "" then .scripts.test = $test else . end)
    | .devDependencies = (.devDependencies // {})
    | (if (.devDependencies.husky // "") == "" then .devDependencies.husky = "^9.1.7" else . end)
  ' "$PKG" > "$tmp"
  mv "$tmp" "$PKG"
  echo "  updated package.json"
fi

if [ "${_HARNESS_SKIP_NPM:-0}" = "1" ]; then
  echo "_HARNESS_SKIP_NPM=1 — skipping npm install (test/CI mode only; do not use in a real install)." >&2
  exit 0
fi

echo "Running npm install to wire husky..."
( cd "$TARGET_DIR" && npm install )

if [ -f "$TARGET_DIR/.husky/pre-commit" ] && [ -x "$TARGET_DIR/.husky/pre-commit" ]; then
  echo "Done. .husky/pre-commit is wired and executable."
else
  echo "hooks: warning — .husky/pre-commit is missing or not executable after npm install." >&2
  echo "  Check that install.sh placed the .husky/ files and that husky is in devDependencies." >&2
  exit 1
fi
