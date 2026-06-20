## Feature skill — worktree setup

The `/feature` skill must instruct agents to create a dedicated git worktree before
starting any implementation work, so that feature branches are never worked on in the
main worktree.

### Confirmed behaviors

- **`/feature` instructs agents to create a worktree before starting implementation:**
  The skill includes "Step 0.5 — Create a dedicated worktree" immediately after the
  size-estimate step and before the `## Tiny` tier. The step calls
  `scripts/worktree-add.sh .claude/worktrees/<slug> feat/<slug>` explicitly, so all
  paths through the pipeline (Tiny, Small, Medium, Large) hit the worktree setup step.

- **`worktree-add.sh` appears in setup, not only in cleanup:**
  The skill's `## Worktree cleanup (after merge)` section already referenced worktrees,
  but only for post-merge cleanup. Step 0.5 adds a pre-implementation reference so the
  setup instruction is unconditional — not dependent on "if this feature ran in a
  dedicated worktree."
