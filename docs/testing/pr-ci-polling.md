## CI polling after PR creation (`scripts/pr.sh`)

After `gh pr create` succeeds, `pr.sh` fetches the new PR's URL and then polls
GitHub's status-check API in a loop until all checks finish, time out, or one
fails. This gives the caller immediate feedback on CI rather than requiring a
separate `gh pr checks --watch` step.

### Confirmed behaviors — normal poll flow

- **Poll starts after a successful `gh pr create`:** When the `gh pr create`
  command exits 0, `pr.sh` calls `gh pr view --json url -q .url` to get the PR
  URL, then enters a polling loop that calls `gh pr view --json
  statusCheckRollup` on each iteration.

- **Loop continues while checks are pending or running:** While at least one
  check in `statusCheckRollup` has a pending or in-progress state, the loop
  repeats. The script does not exit during this period.

- **Exits 0 when all checks pass:** When every check in `statusCheckRollup`
  reaches a SUCCESS state, the script exits 0.

- **Exits 1 when any check fails:** When at least one check in
  `statusCheckRollup` reaches a FAILURE or ERROR state, the script exits 1.

### Confirmed behaviors — timeout path

- **Timeout is controlled by `CI_POLL_TIMEOUT`:** The env var `CI_POLL_TIMEOUT`
  sets the maximum number of seconds to wait. When the variable is not set, the
  default is 600 seconds.

- **Elapsed time is tracked with the bash `SECONDS` builtin:** The polling loop
  compares `$SECONDS` against the timeout threshold. There is no dependency on
  the external `timeout` command.

- **Timeout exits 0 with a warning:** When the elapsed time reaches
  `CI_POLL_TIMEOUT` before the checks finish, `pr.sh` prints a one-line warning
  to stderr and exits 0. A timeout is not treated as a CI failure.

### Confirmed behaviors — skip paths

- **`CI_POLL_SKIP=1` skips polling:** When `CI_POLL_SKIP` is set to any
  non-empty value, `pr.sh` skips CI polling entirely and exits 0 immediately
  after a successful PR creation. No `gh pr view` calls are made.

- **`PR_DRY_RUN=1` path is unchanged:** When `PR_DRY_RUN` is set, `pr.sh`
  prints the resolved `gh pr create` command and exits 0 without making any
  network calls — the same behavior as before this change. CI polling is never
  reached.

- **GitLab forge skips polling with a warning:** When `FORGE=gitlab`, `pr.sh`
  skips CI polling after a successful MR creation and prints a one-line warning
  to stderr explaining that GitLab polling is not supported. The script still
  exits 0.

### Confirmed behaviors — sentinel interaction

- **A CI poll failure does not restore the `.cr-ok` sentinel:** The sentinel
  restore trap is cleared before CI polling begins (the PR was created
  successfully). If CI polling exits 1, the sentinel stays consumed. There is
  no rollback of the PR creation.
