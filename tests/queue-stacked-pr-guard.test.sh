#!/usr/bin/env bash
# In a stacked group, task B's PR opens with --base feat/A so its diff shows only
# B's own changes. But if task A landed commits and then failed /cr, A is never
# pushed — its branch does not exist on the remote. GitHub only auto-retargets a
# stacked PR to main when the base branch MERGES, not when it is rejected or never
# pushed. So B's PR would point at a base that never lands.
#
# The fix tracks which slugs were actually pushed and decides B's PR base from
# that set. This test exercises the decision function resolvePrBase(prevSlug,
# pushedSet): an independent task gets no base override; a stacked task whose
# previous slug WAS pushed targets feat/<prevSlug>; a stacked task whose previous
# slug was NOT pushed falls back to main with a warning flag set.
#
# queue-execute.js cannot be imported on its own — it has a top-level `return`
# and depends on harness-injected globals. So this test extracts just the
# resolvePrBase function from the source, writes it to a temp ES module, and
# exercises the real code.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

SRC=".claude/workflows/queue-execute.js"
[ -f "$SRC" ] || { echo "  MISSING: $SRC" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mod="$work/resolve.mjs"

# Pull the resolvePrBase function out of the source: from its opening
# `function resolvePrBase` line through its matching closing brace at column 0.
awk '
  /^function resolvePrBase/ { infn=1 }
  infn { print }
  infn && /^}/ { infn=0 }
' "$SRC" > "$mod.body"

if ! grep -q 'function resolvePrBase' "$mod.body"; then
  echo "  FAIL: could not extract resolvePrBase from $SRC" >&2
  exit 1
fi

{ cat "$mod.body"; echo; echo "export { resolvePrBase }"; } > "$mod"

fail=0
expect() { # description, node-snippet-returning-JSON, expected-substring
  local desc="$1" snippet="$2" want="$3"
  local out
  out=$(node --input-type=module -e "
    import { resolvePrBase } from '$mod'
    console.log(JSON.stringify($snippet))
  " 2>&1) || { echo "  FAIL: $desc — node errored: $out" >&2; fail=1; return; }
  case "$out" in
    *"$want"*) : ;;
    *) echo "  FAIL: $desc — wanted substring '$want', got: $out" >&2; fail=1 ;;
  esac
}

# Independent task: no previous slug -> no base override, no warning.
expect "independent task gets no base" \
  "resolvePrBase(null, new Set())" \
  '"base":null'
expect "independent task is not flagged retargeted" \
  "resolvePrBase(null, new Set())" \
  '"retargeted":false'

# Stacked task whose previous slug WAS pushed: target feat/<prevSlug>.
expect "stacked task with pushed base targets feat/prev" \
  "resolvePrBase('task-a', new Set(['task-a']))" \
  '"base":"feat/task-a"'
expect "stacked task with pushed base is not retargeted" \
  "resolvePrBase('task-a', new Set(['task-a']))" \
  '"retargeted":false'

# Stacked task whose previous slug was NOT pushed: fall back to main, flag it.
expect "stacked task with unpushed base falls back (no feat/ base)" \
  "resolvePrBase('task-a', new Set())" \
  '"base":null'
expect "stacked task with unpushed base is flagged retargeted" \
  "resolvePrBase('task-a', new Set())" \
  '"retargeted":true'
expect "retarget warning names the missing previous branch" \
  "resolvePrBase('task-a', new Set(['other']))" \
  'task-a'

[ "$fail" = 0 ] && echo "queue-stacked-pr-guard: OK"
exit "$fail"
