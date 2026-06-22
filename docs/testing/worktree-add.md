## Worktree setup (`scripts/worktree-add.sh`)

`worktree-add.sh` creates a git worktree for a given branch. When the branch
name follows the `feat/<slug>` pattern and `TASKS.md` exists at the repo root,
the script also marks the matching task as in-progress in `TASKS.md`.

### Confirmed behaviors

- **In-progress marker written on worktree create:** Given `TASKS.md` contains
  `- [ ] Some task` followed (within the same task block) by `  Slug: <slug>`,
  when `worktree-add.sh <path> feat/<slug>` runs, `TASKS.md` is updated so the
  task header reads `- [~] Some task`. Other tasks in the file are not changed.

- **Non-feat branches leave TASKS.md unchanged:** Given a branch name that does
  not start with `feat/`, when `worktree-add.sh` runs, `TASKS.md` is not
  modified and the script exits 0.

- **Missing TASKS.md is not an error:** Given `TASKS.md` does not exist at the
  repo root, when `worktree-add.sh` runs, the script exits 0 and no TASKS.md
  update attempt is made.

- **Base-ref ancestry is verified before the script returns:** Given a base-ref
  is passed as the third argument and the new worktree is created from it, when
  `worktree-add.sh <path> feat/<child> <base-ref>` finishes creating the
  worktree, the script checks that `<base-ref>` is an ancestor of the new
  worktree's HEAD. If the new branch does not contain the base-ref's commits
  (broken ancestry), the script prints an error naming the base-ref, removes the
  just-created worktree, and exits non-zero. When `$3` is absent the check is
  skipped (no base-ref to verify). When `$3` is present and ancestry holds, the
  script exits 0 as before.
