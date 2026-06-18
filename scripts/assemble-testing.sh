#!/usr/bin/env bash
# Assembles docs/TESTING.md from all shard files in docs/testing/*.md.
# Run this after adding or editing a shard to refresh the canonical file.
# Set TESTING_ROOT to override the repo root (useful in tests).
set -e

ROOT=${TESTING_ROOT:-$(git rev-parse --show-toplevel)}
OUTPUT="$ROOT/docs/TESTING.md"
SHARDS_DIR="$ROOT/docs/testing"

{
  printf '<!-- generated — do not edit directly. Run scripts/assemble-testing.sh to regenerate. -->\n\n'
  printf '# TESTING — confirmed behaviors\n\n'
  printf 'Confirmed behaviors for the harness'"'"'s own tooling. Each entry is a behavior a test\n'
  printf 'checks, not an invented requirement. Per-project work adds its own entries.\n'

  for f in "$SHARDS_DIR"/*.md; do
    [ -e "$f" ] || continue
    printf '\n---\n\n'
    cat "$f"
  done
} > "$OUTPUT"
