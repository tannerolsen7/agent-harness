# Problem: Workflow `isolation: 'worktree'` Commits to `agent/*` Branches, Not Your `feat/*` Branches

**Problem class:** A queue workflow pre-creates named `feat/*` worktrees in a Setup phase, then runs agents with `isolation: 'worktree'`. The work lands on `agent/wf_<run-id>-<seq>` branches. The Push phase finds the `feat/*` branches empty and cannot open PRs.

## When this bites you

You run a queue workflow. Setup creates five worktrees, one per task. Execute runs the agents. Each agent's result says "Branch: `agent/wf_1ec1ed57-863-7`" — not `feat/perf-budget`. Push tries to push `feat/perf-budget`, finds it at the same commit as main, and `gh pr create` fails: no diff, no PR.

Two of five tasks ship correctly. Three don't. The difference: the agents that produced `feat/*` branches ran without `isolation: 'worktree'`; the ones that produced `agent/*` branches ran with it.

## Root cause

`isolation: 'worktree'` is designed to give each agent a clean, conflict-free sandbox when multiple agents might write the same files concurrently. It always creates a *new* branch named `agent/<run-id>-<seq>` and a fresh worktree on that branch. It does not check out an existing branch. The branch name you pass in the agent prompt is just text in the prompt — git never sees it.

## The fix — pick one

**Option 1 — Drop `isolation: 'worktree'` when agents work in separate directories.**

Pre-created worktrees already provide isolation when each task writes to its own path. Pass the worktree path in the prompt so the agent knows where to work:

```js
await agent(
  'Work in .claude/worktrees/' + slug + ' on branch feat/' + slug + '. ...',
  { label: 'run:' + slug }   // no isolation: 'worktree'
)
```

The agent commits to the branch that worktree is checked out on (`feat/<slug>`). No `agent/*` branch is created.

**Option 2 — Accept `agent/*` branch names and push those.**

If you need isolation (agents share a directory or could step on each other's files), let the workflow own branch naming. In the Push phase, read the actual branch from the agent's return value instead of from your pre-created names:

```js
// result.result contains "Branch: `agent/wf_...-7`\nCommit: ..."
const branch = result.result.match(/Branch:\s*`([^`]+)`/)?.[1]
if (branch) await agent('Push ' + branch + ' and open a PR...', { label: 'push:' + slug })
```

Push `branch`, not your pre-planned `feat/<slug>`.

## What doesn't work

**Passing the branch name in the agent prompt:** The agent reads your prompt and may *say* it worked on `feat/perf-budget`, but git commits land on whatever branch the isolation worktree created. The return value will name `agent/wf_*` as the branch.

**Setting up worktrees in Setup and using `isolation: 'worktree'` in Execute:** The setup worktrees go unused. The isolation worktrees are created separately, on separate branches, and cleaned up (or left as stale worktrees) after the agent finishes.

## Recovery when it's already happened

The work is committed — just on a different branch. Find it:

```bash
git log --oneline agent/wf_1ec1ed57-863-7 | head -5
```

Then either:
1. Push and PR directly from the `agent/*` branch (fastest)
2. Cherry-pick onto the `feat/*` branch if the pre-existing PR matters

## Tags

workflow, isolation, worktree, agent-branch-naming, queue, pipeline
