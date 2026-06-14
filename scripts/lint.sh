#!/usr/bin/env bash
# Lint the harness's own shell. Zero-dependency: a `bash -n` syntax check on every
# shell file, plus shellcheck (error severity only) when it is installed. This is
# the harness's pre-commit gate — the harness is mostly shell + markdown, so the
# scripts ARE the code.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

files=""
# Lint OUR shell only. Exclude: transient worktrees under .claude/worktrees/ (each carries its own
# copy of everything + husky's generated _/husky.sh, which has no shebang → SC2148), any node_modules,
# and husky's internal _/ shim dir. Without this, running from the repo root descends into a leftover
# worktree and lints husky-generated files we don't own (broke the pre-commit gate; CI has no worktrees
# but the exclusion keeps local + CI identical).
while IFS= read -r f; do files="$files $f"; done < <(find .claude scripts -type f -name '*.sh' \
  -not -path '*/worktrees/*' -not -path '*/node_modules/*' -not -path '*/.husky/_/*' 2>/dev/null)
for h in .husky/pre-commit .husky/pre-push .husky/post-checkout; do
  [ -f "$h" ] && files="$files $h"
done

fail=0
count=0
for f in $files; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  if ! bash -n "$f"; then
    echo "lint: syntax error in $f" >&2
    fail=1
  fi
done

if command -v shellcheck >/dev/null 2>&1; then
  for f in $files; do
    [ -f "$f" ] || continue
    if ! shellcheck -S error "$f"; then
      echo "lint: shellcheck error in $f" >&2
      fail=1
    fi
  done
else
  echo "lint: shellcheck not installed — ran 'bash -n' only (install shellcheck for deeper checks)."
fi

[ "$fail" = 0 ] && echo "lint: OK ($count shell files checked)"
exit "$fail"
