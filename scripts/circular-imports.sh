#!/usr/bin/env bash
# Detect circular imports in JS/TS projects using madge.
# Skips when no package.json exists (not a JS/TS project).
# Skips with a message when npx is not available.
# Exit 0: no cycles or skipped. Exit 1: cycles found.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

if [ ! -f package.json ]; then
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "circular-imports: npx not found — skipping (install Node.js to enable this check)."
  exit 0
fi

# Resolve source directory: env override, then src/ if it exists, else repo root.
SRC_DIR="${CIRCULAR_IMPORT_ROOTS:-}"
if [ -z "$SRC_DIR" ]; then
  SRC_DIR="."
  [ -d src ] && SRC_DIR="src"
fi

MADGE_ARGS="--circular"
[ -f tsconfig.json ] && MADGE_ARGS="$MADGE_ARGS --ts-config tsconfig.json"

echo "circular-imports: scanning $SRC_DIR (this may download madge on first run)..."
# shellcheck disable=SC2086
if npx --yes madge $MADGE_ARGS "$SRC_DIR"; then
  echo "circular-imports: OK (no cycles in $SRC_DIR)"
else
  echo "circular-imports: check failed — cycles or a parse error (see madge output above)." >&2
  exit 1
fi
