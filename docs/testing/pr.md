## PR opener (`scripts/pr.sh`) — merge conflict check

`pr.sh` verifies the branch merges cleanly into the remote base branch before
consuming the `/cr` sentinel. This is a safety net: `/cr` runs the same check
as its first step, and `pr.sh` re-runs it as a last guard in case the branch
received a commit after `/cr` ran.

### Confirmed behaviors

- **Conflict detection aborts before sentinel consumption:** Given a branch
  where the same file has conflicting changes in HEAD versus `origin/<base>`,
  when `pr.sh` runs non-interactively with a valid `.cr-ok` sentinel, it exits
  non-zero and leaves the sentinel intact — the sentinel is still there once
  the conflicts are resolved and the user retries.

- **Clean branch passes conflict check:** Given a branch where both HEAD and
  the base branch have advanced independently with no overlapping file changes,
  when `pr.sh` runs non-interactively with a valid `.cr-ok` sentinel, it exits
  zero and the PR proceeds normally.

- **Base branch detected dynamically:** The merge check reads the base branch
  from `git remote show origin`, falling back to `main` if the remote HEAD
  cannot be determined (including when the remote reports `(unknown)`).
