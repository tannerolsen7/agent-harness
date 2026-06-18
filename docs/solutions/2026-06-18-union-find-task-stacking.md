# Problem: Parallelizing Tasks That Touch Overlapping Files

**Problem class:** A batch of N tasks runs in parallel — but some tasks touch the same files,
so their branches conflict when both try to merge to main. The naive fix (serialize the whole
batch) wastes wall-clock time. The right fix (detect which subsets overlap and serialize only
those) needs a grouping algorithm that handles transitive overlap: if A overlaps B and B
overlaps C, then A, B, and C must all run in order even if A and C don't directly overlap.

## When this bites you

You run a `/queue` batch with 4 tasks. Two of them both list `scripts/pr.sh` in
`filesAffected`. The workflow runs them in parallel — each implementer writes to the same
file on separate branches. Both PRs merge cleanly from their own perspective (no conflicts
with main at that moment), but the second one to merge clobbers the first.

Or: you know task B depends on task A's output file, so you put A first in TASKS.md. But the
workflow still runs them at the same time because there's no serialization mechanism.

## Root cause

`parallel()` runs all tasks concurrently. Two tasks that write to the same file will always
race to merge, and one will win and one will need a manual rebase. Without a grouping step,
you choose between full serialization (slow, defeats the point of `/queue`) or full
parallelism (conflict-prone).

## The solution

**Step 1 — Compute connected components** from the `filesAffected` strings using union-find:

```js
function parseFiles(filesAffected) {
  const s = (filesAffected || '').trim()
  if (!s || s.toUpperCase() === 'N/A') return new Set()
  return new Set(s.split(',').map(f => f.trim()).filter(Boolean))
}

function computeStacks(taskList) {
  const parent = taskList.map((_, i) => i)
  function find(i) {
    if (parent[i] !== i) parent[i] = find(parent[i])
    return parent[i]
  }
  function union(a, b) { parent[find(a)] = find(b) }

  const fileSets = taskList.map(t => parseFiles(t.filesAffected))

  for (let i = 0; i < taskList.length; i++) {
    if (fileSets[i].size === 0) continue
    for (let j = i + 1; j < taskList.length; j++) {
      if (fileSets[j].size === 0) continue
      for (const f of fileSets[i]) {
        if (fileSets[j].has(f)) { union(i, j); break }
      }
    }
  }

  const groups = new Map()
  for (let i = 0; i < taskList.length; i++) {
    const root = find(i)
    if (!groups.has(root)) groups.set(root, [])
    groups.get(root).push(taskList[i])
  }

  const stacks = [], independent = []
  for (const group of groups.values()) {
    if (group.length >= 2) stacks.push(group)
    else independent.push(group[0])
  }
  return { stacks, independent }
}
```

Tasks with no `filesAffected` (N/A, empty) are never grouped — they run independently.
Tasks in the same connected component form a stack that runs serially. The order within each
component follows TASKS.md input order.

**Step 2 — Unified execution: treat independents as single-element groups**

This is the key simplification. Instead of two separate code paths (parallel for independents,
serial for stacks), treat every task as a group:

```js
const allGroups = [...independent.map(t => [t]), ...stacks]

const allResults = await parallel(
  allGroups.map(group => async () => {
    const results = []
    for (let i = 0; i < group.length; i++) {
      const task = group[i]
      const baseRef = i === 0 ? null : group[i - 1].slug

      await agent(createWorktreePrompt(task, baseRef), ...)
      const result = await agent(executeTaskPrompt(task), ...)

      if (!result || result.status !== 'done') {
        // abort the rest of this group
        break
      }
      results.push(result)
    }
    return results
  })
)
```

`parallel()` runs all groups at the same time. Within each group, the `for` loop serializes
tasks. A failed task breaks the loop; downstream tasks in the same group are skipped.

**Step 3 — Thread the base-ref through three layers**

For stacked tasks, each branch must be cut from the previous task's post-implementation tip:

```
computeStacks() → group[i-1].slug as baseRef
  ↓
createWorktreePrompt(task, baseRef) → appends `feat/<baseRef>` as $3 to worktree-add.sh
  ↓
scripts/worktree-add.sh <path> <branch> [base-ref] → `git worktree add -b $BRANCH $PATH $BASE_REF`
```

The idempotency guard in `worktree-add.sh` runs before `$BASE_REF` is ever used, so a resume
re-creates nothing that already exists.

**Step 4 — Stack the PRs**

Build a map from each non-first task's slug to its predecessor:

```js
function buildPrevSlugMap(stacks) {
  const map = {}
  for (const group of stacks) {
    for (let i = 1; i < group.length; i++) {
      map[group[i].slug] = group[i - 1].slug
    }
  }
  return map
}
```

In the Push phase, use it to set `--base feat/<prevSlug>` on the PR. This means:
- The PR diff shows only that task's changes (not the parent's changes too).
- GitHub will offer to retarget the PR to main after the parent merges.

## Why it works in this codebase

`worktree-add.sh`'s idempotency guard (`[ -f "$WORKTREE_PATH/.git" ]`) fires before `$3` is
used, so resume is safe: the guard exits 0 if the worktree already exists, the base-ref call
is never attempted again. This means the stacking logic never double-creates a branch.

The `parallel()` call in the Workflow engine runs all groups concurrently — so independent
tasks still run in parallel; only stacked groups are serialized. Wall-clock cost = slowest
single-item chain, not sum of all groups.

## When to reuse

Any time a batch workflow must handle N tasks where some may touch overlapping files:
- Tasks share a config file, migration, or generated file
- Tasks have an implicit ordering constraint captured as file overlap

## When NOT to reuse

- **Explicit dependencies, not file overlap**: if task B must wait for task A for logical
  reasons (not file reasons), `filesAffected` won't capture that — you need an explicit
  `dependsOn` field (which doesn't exist yet).
- **All tasks share one common file** (e.g. `package.json`): the connected-components
  algorithm will collapse the entire batch into one serial chain. Exclude extremely common
  files from `filesAffected` to prevent this.
- **Order within a stack matters but isn't guaranteed by TASKS.md order**: stack ordering
  follows input-array order. If the correct execution order differs from TASKS.md position,
  you need to sort tasks explicitly before passing them to `computeStacks()`.

## Gotchas

- Path normalization: `./src/a.ts` and `src/a.ts` are treated as different paths and won't
  trigger stacking. Normalize paths before building the Set (strip leading `./`).
- A task with `filesAffected: "N/A"` is never stacked, even if it actually touches a shared
  file. The system trusts `filesAffected` — inaccurate declarations cause missed stacks and
  merge conflicts.
- Skipped tail-of-chain tasks (when a group aborts mid-stack) currently don't appear in the
  structured summary count — only in the log message. See BACKLOG.md.

## Files

- `.claude/workflows/queue-execute.js` — `computeStacks()`, `buildPrevSlugMap()`, unified loop
- `scripts/worktree-add.sh` — `BASE_REF="${3:-HEAD}"` and guard

## Tags

union-find, connected-components, parallel-tasks, file-overlap, branch-stacking, worktree, queue-execute
