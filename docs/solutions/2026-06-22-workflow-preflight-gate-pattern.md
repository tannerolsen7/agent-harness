# Preflight gates in workflow scripts

**Problem:** A workflow script needs to validate inputs before spawning any agents or creating any
worktrees, but the script cannot `require()` or `import` helpers from other files, and has no
Node.js `fs` access. Validation logic must run at the top of the script, and its tests need to
exercise the logic without being able to load the script directly.

**Solution pattern:** Write the gate as a pure-JS function at the top of the workflow script, before
any `phase()` or `agent()` call. Keep the function's logic self-contained (no side effects, no
imports). Test it in two layers:

1. **Behavioral tests** via `node -e` with an inline copy of the function. These test the function's
   logic in isolation. The inline copy is the acknowledged tradeoff — workflow scripts can't be
   required, so the copy is the only way to run isolated behavioral tests. The test file comment
   must say this explicitly: "any change to the function in the source must be mirrored here."

2. **Static-analysis tests** via `grep` against the actual source file. These don't test behavior —
   they verify that the function exists in the source, that key strings are present, and that the
   function appears before critical downstream calls (like `computeStacks`). They catch drift between
   the inline copy and the source only at a coarse level (string presence, not logic parity).

**File-existence checks** (when the gate needs to verify a file path exists) must go through an
`agent()` call because workflow scripts have no direct filesystem access. Use structured bash output
(`test -f "$path" && echo "OK: $slug" || echo "MISSING: $slug: $path"`) so the result is easy to
parse. Guard against both null and empty-string returns:

```js
if (!check || !check.trim()) {
  throw new Error('gate: file-existence check produced no output. Aborting.')
}
const missing = check.split('\n').filter(l => l.trimStart().startsWith('MISSING:'))
```

**Run order:** slug validation (safety) → design gate (content) → `computeStacks()` (work). This
guarantees no worktree is ever created from invalid input.

**References:** `.claude/workflows/queue-execute.js` (slug validation + design gate), `tests/queue-design-gate.test.sh`
