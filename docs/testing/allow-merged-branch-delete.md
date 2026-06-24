## git branch -D: allow when merged, block when not

The `block-dangerous-git.sh` hook intercepts `git branch -D` calls. Instead of
blocking all force-deletes, it checks whether the branch's code is already on the
default branch. If the diff is empty (covers both regular and squash merges), the
delete proceeds. If the diff is non-empty, the hook blocks and asks the user to
confirm manually.

### Confirmed behaviors

- **Force-delete of a merged branch is allowed:** When `git branch -D <branch>` is
  called and the branch has no code differences from the default branch, the hook
  exits 0 and allows the delete. This covers branches that were squash-merged
  (where `git branch -d` would refuse because the commits aren't in main's ancestry).

- **Force-delete of a branch with unmerged changes is blocked:** When
  `git branch -D <branch>` is called and the branch has code differences from the
  default branch, the hook exits 2 and prints a message naming the branch and the
  default branch so the user knows what to inspect.

- **Force-delete with no branch name is blocked unconditionally:** When
  `git branch -D` is called with no branch name argument, the hook cannot check
  merge status and exits 2.
