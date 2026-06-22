#!/usr/bin/env bash
# Validates a commit message first line against conventional commit format.
# Usage: bash scripts/commit-msg-lint.sh <message-file>
# Exit 0 = valid (or skipped). Exit 1 = invalid, reason written to stderr.
set -euo pipefail

MSG_FILE="${1:-}"
[ -n "$MSG_FILE" ] || { printf "commit-msg-lint: no message file given\n" >&2; exit 1; }
[ -f "$MSG_FILE" ] || { printf "commit-msg-lint: file not found: %s\n" "$MSG_FILE" >&2; exit 1; }

first=$(head -1 "$MSG_FILE")

# Skip commits git generates automatically — they don't follow conventional format.
case "$first" in
  Merge\ *|squash!\ *|fixup!\ *|Revert\ *) exit 0 ;;
esac

# Format: type(scope)?!?: description  where description starts with a lowercase letter.
# Types: feat fix chore docs refactor test perf build ci style revert
if ! printf '%s\n' "$first" | grep -qE '^(feat|fix|chore|docs|refactor|test|perf|build|ci|style|revert)(\([a-z0-9-]+\))?!?: [a-z]'; then
  printf "commit-msg: bad format: %s\n" "$first" >&2
  printf "  Expected: type(scope)?: description  (description must start with a lowercase letter)\n" >&2
  printf "  Valid types: feat fix chore docs refactor test perf build ci style revert\n" >&2
  exit 1
fi

# Hard block — reject commits whose subject exceeds 72 chars.
if [ "${#first}" -gt 72 ]; then
  printf "commit-msg: subject is %d chars (max: 72)\n" "${#first}" >&2
  exit 1
fi
