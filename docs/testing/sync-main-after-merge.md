# sync-main-after-merge

## Confirmed behaviors

### 1. Print a pull reminder when local main is behind origin/main after worktree cleanup

After `cleanup-worktree.sh` successfully removes a merged worktree, it checks
whether local `main` is behind `origin/main`. If it is, the script prints a
message showing how many commits main is behind and the exact `git pull` command
to run. If local main is already up to date, nothing is printed.
