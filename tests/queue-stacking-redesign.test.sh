#!/usr/bin/env bash
# Tests for validateStacksOn in queue-execute.js.
# validateStacksOn takes a task list and the groups already computed by
# computeStacks, so tests call computeStacks first to get those groups.
# queue-execute.js cannot be imported directly (top-level return, harness globals),
# so this test extracts parseFiles, computeStacks, and validateStacksOn from the
# source using awk and runs them as an ES module via node --input-type=module.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

SRC=".claude/workflows/queue-execute.js"
SKILL=".claude/skills/queue/SKILL.md"
[ -f "$SRC" ] || { echo "  MISSING: $SRC" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mod="$work/validate.mjs"

# Extract parseFiles, computeStacks, and validateStacksOn from the source.
# awk prints each top-level function from its opening line through its closing
# brace at column 0.
awk '
  /^function parseFiles/      { infn=1 }
  /^function computeStacks/   { infn=1 }
  /^function validateStacksOn/ { infn=1 }
  infn { print }
  infn && /^}/ { infn=0; print "" }
' "$SRC" > "$mod.body"

for fn in parseFiles computeStacks validateStacksOn; do
  if ! grep -q "function $fn" "$mod.body"; then
    echo "  FAIL: could not extract $fn from $SRC" >&2
    exit 1
  fi
done

{ cat "$mod.body"; echo; echo "export { parseFiles, computeStacks, validateStacksOn }"; } > "$mod"

fail=0
check() {
  local desc="$1" expect_throw="$2" snippet="$3"
  local out
  out=$(node --input-type=module -e "
    import { parseFiles, computeStacks, validateStacksOn } from '$mod'
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

# Helper to build groups from a task list, same as the workflow does.
SETUP='
function groups(tasks) {
  const { stacks, independent } = computeStacks(tasks)
  return { stacks, independent }
}
'

echo "── no stacksOn fields → passes ──"
check "no stacksOn fields" 0 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/shared.ts' },
  { slug: 'b', filesAffected: 'src/shared.ts' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" >/dev/null

echo "── empty-string stacksOn → treated as absent, passes ──"
check "empty stacksOn" 0 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/x.ts', stacksOn: '' },
  { slug: 'b', filesAffected: 'src/y.ts' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" >/dev/null

echo "── stacksOn with unknown slug → throws, names bad slug ──"
out=$(check "unknown slug" 1 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/shared.ts' },
  { slug: 'b', filesAffected: 'src/shared.ts', stacksOn: 'task-x' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" 2>&1) || true
case "$out" in
  *task-x*) : ;;
  *) echo "  FAIL: error should name the unknown slug 'task-x'; got: $out" >&2; fail=1 ;;
esac

echo "── stacksOn self-reference → throws ──"
check "self-reference" 1 "
$SETUP
const tasks = [{ slug: 'a', filesAffected: 'src/x.ts', stacksOn: 'a' }]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" >/dev/null

echo "── stacksOn cross-group (no shared file) → throws with filesAffected guidance ──"
out=$(check "cross-group" 1 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/a.ts' },
  { slug: 'b', filesAffected: 'src/b.ts', stacksOn: 'a' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" 2>&1) || true
case "$out" in
  *filesAffected*) : ;;
  *) echo "  FAIL: error should mention filesAffected workaround; got: $out" >&2; fail=1 ;;
esac

echo "── stacksOn cycle (A→B, B→A) → throws, names the cycle ──"
out=$(check "two-node cycle" 1 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/shared.ts', stacksOn: 'b' },
  { slug: 'b', filesAffected: 'src/shared.ts', stacksOn: 'a' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" 2>&1) || true
case "$out" in
  *cycle*) : ;;
  *) echo "  FAIL: error should mention cycle; got: $out" >&2; fail=1 ;;
esac

echo "── multiple errors → single throw listing all ──"
out=$(node --input-type=module -e "
  import { computeStacks, validateStacksOn } from '$mod'
  const tasks = [
    { slug: 'a', filesAffected: 'src/a.ts', stacksOn: 'missing-1' },
    { slug: 'b', filesAffected: 'src/b.ts', stacksOn: 'missing-2' }
  ]
  const { stacks, independent } = computeStacks(tasks)
  try { validateStacksOn(tasks, stacks, independent); console.log('NOTHROW') }
  catch (e) { console.log(e.message) }
" 2>&1) || true
case "$out" in
  *missing-1*) : ;;
  *) echo "  FAIL: error should mention first bad slug; got: $out" >&2; fail=1 ;;
esac
case "$out" in
  *missing-2*) : ;;
  *) echo "  FAIL: error should mention second bad slug; got: $out" >&2; fail=1 ;;
esac

echo "── valid stacksOn in same group → passes ──"
check "valid stacksOn same group" 0 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/shared.ts' },
  { slug: 'b', filesAffected: 'src/shared.ts', stacksOn: 'a' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" >/dev/null

echo "── whitespace-only stacksOn → treated as absent, passes ──"
check "whitespace stacksOn" 0 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/x.ts', stacksOn: '  ' },
  { slug: 'b', filesAffected: 'src/y.ts' }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" >/dev/null

echo "── non-string stacksOn → throws with clear type error ──"
out=$(check "non-string stacksOn" 1 "
$SETUP
const tasks = [
  { slug: 'a', filesAffected: 'src/x.ts' },
  { slug: 'b', filesAffected: 'src/y.ts', stacksOn: 5 }
]
const { stacks, independent } = groups(tasks)
validateStacksOn(tasks, stacks, independent)
" 2>&1) || true
case "$out" in
  *number*|*string*) : ;;
  *) echo "  FAIL: error should describe type mismatch; got: $out" >&2; fail=1 ;;
esac

echo "── source: validateStacksOn defined before computeStacks call ──"
validate_line=$(grep -n 'function validateStacksOn' "$SRC" 2>/dev/null | head -1 | cut -d: -f1)
stacks_call_line=$(grep -n 'computeStacks(tasks)' "$SRC" 2>/dev/null | head -1 | cut -d: -f1)
if [ -n "$validate_line" ] && [ -n "$stacks_call_line" ] && [ "$validate_line" -lt "$stacks_call_line" ]; then
  : # pass
else
  echo "  FAIL: validateStacksOn must be defined before computeStacks(tasks) call (validate=$validate_line stacks_call=$stacks_call_line)" >&2
  fail=1
fi

echo "── source: validateStacksOn called before phase('Setup') ──"
validate_call_line=$(grep -n 'validateStacksOn(tasks' "$SRC" 2>/dev/null | head -1 | cut -d: -f1)
setup_line=$(grep -n "phase('Setup')" "$SRC" 2>/dev/null | head -1 | cut -d: -f1)
if [ -n "$validate_call_line" ] && [ -n "$setup_line" ] && [ "$validate_call_line" -lt "$setup_line" ]; then
  : # pass
else
  echo "  FAIL: validateStacksOn must be called before phase('Setup') (call=$validate_call_line setup=$setup_line)" >&2
  fail=1
fi

echo "── source: buildPrevSlugMap removed ──"
if grep -q 'buildPrevSlugMap' "$SRC" 2>/dev/null; then
  echo "  FAIL: buildPrevSlugMap still present in $SRC — it should be removed" >&2
  fail=1
fi

echo "── source: baseRef comes from task.stacksOn, not group position ──"
if grep -q 'group\[i - 1\]' "$SRC" 2>/dev/null; then
  echo "  FAIL: group[i-1] still used for baseRef in $SRC — replace with task.stacksOn" >&2
  fail=1
fi

echo "── source: baseRef uses trim normalization at use site ──"
if grep -q '(task\.stacksOn || .*)\.trim() || null' "$SRC" 2>/dev/null; then
  : # pass
else
  echo "  FAIL: baseRef in Execute phase must use (task.stacksOn || '').trim() || null to normalize whitespace" >&2
  fail=1
fi

echo "── SKILL.md: Step 1 mentions stacksOn as opt-in ──"
if awk '/## Step 1/,/## Step 2/' "$SKILL" 2>/dev/null | grep -q 'stacksOn'; then
  : # pass
else
  echo "  FAIL: SKILL.md Step 1 does not mention stacksOn" >&2
  fail=1
fi

echo "── SKILL.md: Step 1 mentions filesAffected workaround ──"
if awk '/## Step 1/,/## Step 2/' "$SKILL" 2>/dev/null | grep -q 'filesAffected'; then
  : # pass
else
  echo "  FAIL: SKILL.md Step 1 does not explain the filesAffected workaround" >&2
  fail=1
fi

echo "── SKILL.md: Step 3 JSON example includes stacksOn field ──"
if awk '/## Step 3/,/## Step 4|^---/' "$SKILL" 2>/dev/null | grep -q '"stacksOn"'; then
  : # pass
else
  echo "  FAIL: SKILL.md Step 3 JSON example missing stacksOn field" >&2
  fail=1
fi

echo ""
echo "queue-stacking-redesign: $(($(grep -c 'echo "──' "$0") - fail)) passed, $fail failed"
[ "$fail" -eq 0 ]
