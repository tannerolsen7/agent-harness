#!/usr/bin/env bash
# Tests for the design gate in queue-execute.js and the SKILL.md documentation update.
# queue-execute.js is a workflow script (no require/import), so behavioral tests run the
# validation function inline via node -e. Static analysis tests grep source files.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
QE="$ROOT/.claude/workflows/queue-execute.js"
SKILL="$ROOT/.claude/skills/queue/SKILL.md"

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

# Inline copy of the pure-JS validation function from queue-execute.js.
# WARNING: these behavioral tests exercise this copy, not the live function in queue-execute.js.
# Any change to validateDesignGate or GATED_SIZES in queue-execute.js must be mirrored here.
# The static-analysis tests below are the only automated guard against drift.
read -r -d '' VALIDATE_FN << 'JSEOF' || true
const GATED_SIZES = new Set(['LARGE', 'FEATURE', 'MEDIUM'])
function validateDesignGate(taskList) {
  const gated = taskList.filter(t => GATED_SIZES.has((t.size || '').trim().toUpperCase()))
  const noDesign = gated.filter(t => !t.design || !t.design.trim())
  if (noDesign.length > 0) {
    throw new Error('GATE_ERROR: ' + noDesign.map(t => t.slug).join(', '))
  }
  return gated
}
JSEOF

run_validate() {
  node -e "$VALIDATE_FN
try {
  const result = validateDesignGate($1)
  console.log('OK:' + result.length)
} catch(e) {
  console.log('THREW:' + e.message)
}" 2>&1
}

echo "── LARGE task missing design field → throws, names the slug ──"
out=$(run_validate '[{"slug":"my-task","size":"LARGE"}]')
echo "$out" | grep -q 'THREW' && pass=$((pass+1)) || { echo "  MISS: LARGE without design should throw"; fail=$((fail+1)); }
echo "$out" | grep -q 'my-task' && pass=$((pass+1)) || { echo "  MISS: error should name slug 'my-task'"; fail=$((fail+1)); }

echo "── MEDIUM task missing design field → throws, names the slug ──"
out=$(run_validate '[{"slug":"med-task","size":"MEDIUM"}]')
echo "$out" | grep -q 'THREW' && pass=$((pass+1)) || { echo "  MISS: MEDIUM without design should throw"; fail=$((fail+1)); }
echo "$out" | grep -q 'med-task' && pass=$((pass+1)) || { echo "  MISS: error should name slug 'med-task'"; fail=$((fail+1)); }

echo "── FEATURE task missing design field → throws, names the slug ──"
out=$(run_validate '[{"slug":"feat-task","size":"FEATURE"}]')
echo "$out" | grep -q 'THREW' && pass=$((pass+1)) || { echo "  MISS: FEATURE without design should throw"; fail=$((fail+1)); }
echo "$out" | grep -q 'feat-task' && pass=$((pass+1)) || { echo "  MISS: error should name slug 'feat-task'"; fail=$((fail+1)); }

echo "── LARGE task with design field → passes, included in gated list ──"
out=$(run_validate '[{"slug":"big","size":"LARGE","design":"docs/features/big.md"}]')
echo "$out" | grep -q 'OK:1' && pass=$((pass+1)) || { echo "  MISS: LARGE with design should return gated list of 1"; fail=$((fail+1)); }

echo "── SMALL task with no design field → passes through ──"
out=$(run_validate '[{"slug":"small","size":"SMALL"}]')
echo "$out" | grep -q 'OK:0' && pass=$((pass+1)) || { echo "  MISS: SMALL should pass through (not in gated list)"; fail=$((fail+1)); }

echo "── unspecified size → passes through ──"
out=$(run_validate '[{"slug":"no-type"}]')
echo "$out" | grep -q 'OK:0' && pass=$((pass+1)) || { echo "  MISS: no-size task should pass through"; fail=$((fail+1)); }

echo "── whitespace-only size → treated as unrecognized, passes through ──"
out=$(run_validate '[{"slug":"ws-size","size":"   "}]')
echo "$out" | grep -q 'OK:0' && pass=$((pass+1)) || { echo "  MISS: whitespace-only size should pass through"; fail=$((fail+1)); }

echo "── empty-string design after trim → treated as missing, rejected ──"
out=$(run_validate '[{"slug":"empty-design","size":"LARGE","design":"  "}]')
echo "$out" | grep -q 'THREW' && pass=$((pass+1)) || { echo "  MISS: whitespace-only design should be rejected"; fail=$((fail+1)); }

echo "── multiple failing tasks → single throw listing all slugs ──"
out=$(run_validate '[{"slug":"a","size":"LARGE"},{"slug":"b","size":"MEDIUM"}]')
echo "$out" | grep -q 'THREW' && pass=$((pass+1)) || { echo "  MISS: multiple failing tasks should throw"; fail=$((fail+1)); }
echo "$out" | grep -q 'a' && pass=$((pass+1)) || { echo "  MISS: error should mention slug 'a'"; fail=$((fail+1)); }
echo "$out" | grep -q 'b' && pass=$((pass+1)) || { echo "  MISS: error should mention slug 'b'"; fail=$((fail+1)); }

echo "── source: GATED_SIZES defined before computeStacks ──"
gated_line=$(grep -n 'GATED_SIZES' "$QE" 2>/dev/null | head -1 | cut -d: -f1)
stacks_line=$(grep -n 'computeStacks' "$QE" 2>/dev/null | grep -v 'function computeStacks' | head -1 | cut -d: -f1)
if [ -n "$gated_line" ] && [ -n "$stacks_line" ] && [ "$gated_line" -lt "$stacks_line" ]; then
  pass=$((pass+1))
else
  echo "  MISS: GATED_SIZES must be defined before computeStacks() call (gated=$gated_line stacks=$stacks_line)"
  fail=$((fail+1))
fi

echo "── source: MEDIUM in GATED_SIZES in queue-execute.js ──"
grep -q 'MEDIUM' "$QE" 2>/dev/null && pass=$((pass+1)) || { echo "  MISS: MEDIUM missing from queue-execute.js"; fail=$((fail+1)); }

echo "── source: fail-closed null check on agent return ──"
grep -q '!check' "$QE" 2>/dev/null && pass=$((pass+1)) || { echo "  MISS: no fail-closed null check in queue-execute.js"; fail=$((fail+1)); }

echo "── source: file-existence uses structured bash output (test -f) ──"
grep -q 'test -f' "$QE" 2>/dev/null && pass=$((pass+1)) || { echo "  MISS: file-existence check should use 'test -f' in queue-execute.js"; fail=$((fail+1)); }

echo "── SKILL.md: Step 2 names MEDIUM as a gated size ──"
# Step 2 section must mention MEDIUM near the design gate description
if awk '/## Step 2/,/## Step 3/' "$SKILL" 2>/dev/null | grep -q 'MEDIUM'; then
  pass=$((pass+1))
else
  echo "  MISS: SKILL.md Step 2 does not mention MEDIUM in the design gate"
  fail=$((fail+1))
fi

echo "── SKILL.md: Step 3 task object includes size and design fields ──"
if awk '/## Step 3/,/## Step 4|^---/' "$SKILL" 2>/dev/null | grep -q '"size"' && \
   awk '/## Step 3/,/## Step 4|^---/' "$SKILL" 2>/dev/null | grep -q '"design"'; then
  pass=$((pass+1))
else
  echo "  MISS: SKILL.md Step 3 missing \"size\" or \"design\" field in the task object"
  fail=$((fail+1))
fi

echo ""
echo "queue-design-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
