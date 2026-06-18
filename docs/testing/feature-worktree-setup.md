## Feature skill — worktree setup

The `/feature` skill must instruct agents to create a dedicated git worktree before
starting any implementation work, so that feature branches are never worked on in the
main worktree.

### Confirmed behaviors

- **Worktree creation step appears in preamble before implementation tiers:** The
  `/feature` skill includes a "Step 0.5 — Create a dedicated worktree" section that
  appears before the `## Tiny` heading and calls `scripts/worktree-add.sh` explicitly.
  Agents reading the skill instructions must create a worktree at
  `.claude/worktrees/<slug>` on `feat/<slug>` and do all subsequent work from there.
