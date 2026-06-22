## PR sync (`scripts/sync-open-prs.sh`)

`sync-open-prs.sh` checks all open PRs for merge conflicts and asks GitHub to
rebase them. It runs at session start and when a PR merges to main. It must
never block those triggers — it always exits 0.

### Confirmed behaviors

- **Missing forge CLI exits 0 with a skip message:** Given `gh` is not
  installed (not found on PATH), when `sync-open-prs.sh` runs, it prints
  "forge CLI unavailable — skipping PR sync" and exits 0.

- **No open PRs exits 0 with a skip message:** Given `gh` is installed and
  `gh pr list` returns an empty array, when `sync-open-prs.sh` runs, it prints
  "no open PRs to sync" and exits 0.

- **Conflicting PR is rebased and a success line is printed:** Given a PR
  whose `mergeable` field is `"CONFLICTING"`, when `sync-open-prs.sh` runs and
  `gh pr update-branch --rebase <number>` exits 0, the script prints
  `updated #<number> (<headRefName>)` and continues to the next PR.

- **Failed rebase logs the failure and continues without stopping:** Given a
  PR whose `mergeable` field is `"CONFLICTING"` and `gh pr update-branch
  --rebase <number>` exits non-zero, the script prints `failed #<number>
  (<headRefName>) — rebase manually`, moves on to the next PR, and exits 0
  after processing all PRs.

- **PRs targeting a non-default branch are skipped:** Given a PR whose
  `baseRefName` is not the repo default branch (for example, a stacked PR
  targeting a feature branch instead of `main`), when `sync-open-prs.sh` runs,
  it does not call `gh pr update-branch` for that PR and moves on to the next
  one.

- **Draft PRs are skipped:** Given a PR whose `isDraft` field is `true`, when
  `sync-open-prs.sh` runs, it does not call `gh pr update-branch` for that PR
  and moves on to the next one.

- **`PITFALLS.md` uses the union merge strategy in `.gitattributes`:** The
  `.gitattributes` file contains the line `PITFALLS.md merge=union`. When two
  branches both append new entries to `PITFALLS.md` and are merged, git keeps
  both sets of appended lines and produces no conflict markers.
