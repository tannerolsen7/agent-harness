#!/usr/bin/env bash
# After a sub-agent creates a stacked worktree, the queue-execute workflow checks
# git ancestry itself because the agent's report is not trustworthy. An agent
# could paraphrase or garble the worktree-add.sh command and create the worktree
# on the wrong base, silently breaking the stack's ancestry.
#
# The decision is a pure function verifyAncestry(worktreePath, prevSlug,
# isAncestorFn). isAncestorFn(worktreePath, ref) returns whether `ref` is an
# ancestor of the worktree's HEAD; the real call shells out to
# `git -C <path> merge-base --is-ancestor feat/<prevSlug> HEAD`, but the pure
# function takes it as an argument so it can be tested without a real repo.
#
# queue-execute.js cannot be imported on its own — it has a top-level `return`
# and depends on harness-injected globals. So this test extracts just the
# verifyAncestry function from the source, writes it to a temp ES module, and
# exercises the real code.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

SRC=".claude/workflows/queue-execute.js"
[ -f "$SRC" ] || { echo "  MISSING: $SRC" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mod="$work/verify.mjs"

# Pull the verifyAncestry function out of the source: from its opening
# `function verifyAncestry` line through its matching closing brace at column 0.
awk '
  /^function verifyAncestry/ { infn=1 }
  infn { print }
  infn && /^}/ { infn=0 }
' "$SRC" > "$mod.body"

if ! grep -q 'function verifyAncestry' "$mod.body"; then
  echo "  FAIL: could not extract verifyAncestry from $SRC" >&2
  exit 1
fi

{ cat "$mod.body"; echo; echo "export { verifyAncestry }"; } > "$mod"

fail=0
expect() { # description, node-snippet-returning-JSON, expected-substring
  local desc="$1" snippet="$2" want="$3"
  local out
  out=$(node --input-type=module -e "
    import { verifyAncestry } from '$mod'
    console.log(JSON.stringify($snippet))
  " 2>&1) || { echo "  FAIL: $desc — node errored: $out" >&2; fail=1; return; }
  case "$out" in
    *"$want"*) : ;;
    *) echo "  FAIL: $desc — wanted substring '$want', got: $out" >&2; fail=1 ;;
  esac
}

# Ancestry holds: isAncestorFn returns true -> ok.
expect "ancestry ok when base is an ancestor" \
  "verifyAncestry('.claude/worktrees/task-b', 'task-a', () => true)" \
  '"ok":true'

# Ancestry broken: isAncestorFn returns false -> not ok, with an error.
expect "ancestry fails when base is not an ancestor" \
  "verifyAncestry('.claude/worktrees/task-b', 'task-a', () => false)" \
  '"ok":false'

# The failure message names the expected base branch so a human can see what
# was supposed to be the ancestor.
expect "failure message names feat/<prevSlug>" \
  "verifyAncestry('.claude/worktrees/task-b', 'task-a', () => false)" \
  'feat/task-a'

# The failure message names the worktree path that was checked.
expect "failure message names the worktree path" \
  "verifyAncestry('.claude/worktrees/task-b', 'task-a', () => false)" \
  '.claude/worktrees/task-b'

# The check calls isAncestorFn with the worktree path and the feat/<prevSlug>
# ref — confirming the workflow checks the right branch in the right worktree.
expect "isAncestorFn is called with worktree path and feat/<prevSlug>" \
  "(() => { let seen=''; verifyAncestry('.claude/worktrees/task-b', 'task-a', (p, r) => { seen = p + '|' + r; return true }); return seen })()" \
  '.claude/worktrees/task-b|feat/task-a'

[ "$fail" = 0 ] && echo "queue-ancestry-verify: OK"
exit "$fail"
