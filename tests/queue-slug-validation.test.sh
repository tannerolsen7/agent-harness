#!/usr/bin/env bash
# queue-execute validates every task slug before any work starts. Slugs are
# interpolated into shell commands (e.g. "bash scripts/worktree-add.sh
# .claude/worktrees/<slug> feat/<slug>"), so a slug like "my-task --force" could
# inject extra shell arguments. The workflow must reject any slug that does not
# match /^[a-z0-9-]+$/ by throwing immediately, and the error must name the slug.
#
# queue-execute.js cannot be imported on its own — it has a top-level `return`
# and depends on harness-injected globals (args, phase, log, agent, parallel).
# So this test extracts just the SLUG_RE constant and the validateSlugs function
# from the source, writes them to a temp ES module, and exercises the real code.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

SRC=".claude/workflows/queue-execute.js"
[ -f "$SRC" ] || { echo "  MISSING: $SRC" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mod="$work/validate.mjs"

# Pull the SLUG_RE declaration and the validateSlugs function out of the source.
# awk prints the SLUG_RE line, then the validateSlugs function from its opening
# `function validateSlugs` line through its matching closing brace at column 0.
awk '
  /^const SLUG_RE = / { print; next }
  /^function validateSlugs/ { infn=1 }
  infn { print }
  infn && /^}/ { infn=0 }
' "$SRC" > "$mod.body"

if ! grep -q 'SLUG_RE' "$mod.body" || ! grep -q 'function validateSlugs' "$mod.body"; then
  echo "  FAIL: could not extract SLUG_RE / validateSlugs from $SRC" >&2
  exit 1
fi

{ cat "$mod.body"; echo; echo "export { SLUG_RE, validateSlugs }"; } > "$mod"

fail=0
check() { # description, expect-throw(0/1), node-snippet
  local desc="$1" expect_throw="$2" snippet="$3"
  local out rc
  out=$(node --input-type=module -e "
    import { validateSlugs } from '$mod'
    try { $snippet; console.log('NOTHROW') }
    catch (e) { console.log('THREW:' + e.message) }
  " 2>&1) || true
  if [ "$expect_throw" = "1" ]; then
    case "$out" in
      THREW:*) : ;;
      *) echo "  FAIL: $desc — expected throw, got: $out" >&2; fail=1 ;;
    esac
  else
    case "$out" in
      NOTHROW) : ;;
      *) echo "  FAIL: $desc — expected no throw, got: $out" >&2; fail=1 ;;
    esac
  fi
  echo "$out"
}

# Valid slugs pass.
check "valid hyphenated slug passes" 0 \
  "validateSlugs([{ slug: 'add-rate-limiter' }])" >/dev/null

check "valid digits-and-letters slug passes" 0 \
  "validateSlugs([{ slug: 'task-123', }, { slug: 'abc' }])" >/dev/null

# Invalid slugs throw.
check "slug with a space + flag throws (the injection case)" 1 \
  "validateSlugs([{ slug: 'my-task --force' }])" >/dev/null

check "slug with uppercase throws" 1 \
  "validateSlugs([{ slug: 'MyTask' }])" >/dev/null

check "slug with a slash throws" 1 \
  "validateSlugs([{ slug: 'a/b' }])" >/dev/null

check "empty slug throws" 1 \
  "validateSlugs([{ slug: '' }])" >/dev/null

check "missing slug throws" 1 \
  "validateSlugs([{ title: 'no slug here' }])" >/dev/null

# The error names the offending slug.
out=$(node --input-type=module -e "
  import { validateSlugs } from '$mod'
  try { validateSlugs([{ slug: 'good' }, { slug: 'bad slug!' }]) }
  catch (e) { console.log(e.message) }
" 2>&1) || true
case "$out" in
  *"bad slug!"*) : ;;
  *) echo "  FAIL: error message must name the offending slug; got: $out" >&2; fail=1 ;;
esac

# A valid slug alongside an invalid one must still throw (validates all, not just first).
check "one bad slug among good ones throws" 1 \
  "validateSlugs([{ slug: 'ok-one' }, { slug: 'bad space' }, { slug: 'ok-two' }])" >/dev/null

[ "$fail" = 0 ] && echo "queue-slug-validation: OK"
exit "$fail"
