## Keep open PRs synced with main (`scripts/sync-open-prs.sh`, `.gitattributes`)

`sync-open-prs.sh` runs at session start to re-sync open PRs GitHub marks
`CONFLICTING`. It used to call `gh pr update-branch --rebase`, which runs
server-side on GitHub and can't run this repo's local merge drivers — so it failed
on conflicts a local `git merge origin/main` would resolve automatically.

### Confirmed behaviors

- **`.gitattributes` covers all hot generated/tracking files:** `harness-activity.html`
  has `merge=ours` (regenerated fresh every session — branch versions are always
  stale) and `BACKLOG.md` has `merge=union` (append-only — keep both sides'
  entries). Matches the existing `harness-progress.html merge=ours` and
  `PITFALLS.md merge=union` entries.

- **A conflicting PR that merges clean locally is synced and pushed:** for an open,
  non-draft PR targeting the default branch with `mergeable: CONFLICTING`, the
  script creates a scratch worktree, merges `origin/<base>` there, and — if the
  merge succeeds — pushes the result and prints `synced #<n> (<head>)`.

- **A PR with a genuine content conflict is reported, not force-resolved:** if the
  local merge leaves conflict markers, the script aborts the merge and prints
  `failed #<n> (<head>) — real conflict, resolve manually: ...` with the exact
  fetch/checkout/merge commands to run by hand. No partial state is left behind.

- **A branch checked out in another live worktree is skipped, not touched:** if
  `git worktree list` shows the PR's branch already checked out elsewhere, the
  script prints `skipped #<n> (<head>) — checked out in another worktree, sync it
  yourself` and moves on without creating a scratch worktree for it.

- **The scratch worktree is always removed:** whether the sync for a given PR
  succeeds, fails on a real conflict, or fails to push, the scratch worktree used
  for that PR is removed before the script moves to the next PR.

- **A successful local merge that fails to push is reported distinctly:** if
  `git merge` succeeds but `git push` fails, the script prints `failed #<n>
  (<head>) — merge ok locally but push failed, sync it yourself` — different
  wording from a real conflict, since the recovery is different (nothing to
  resolve, just re-push).

- **The push carries a scoped, self-issued `.cr-ok` sentinel:** before pushing, the
  script diffs the merge commit against `origin/<base>` and confirms every changed
  path has a `.gitattributes` merge= entry. Only then does it write `.claude/.cr-ok`
  for `<head>:<merge-sha>` in the scratch worktree so `.husky/pre-push`'s sentinel
  check passes. If any changed path lacks a merge= entry, the script does NOT
  write a sentinel — the push is skipped and the PR is reported as needing manual
  `/cr`, even if the merge itself was clean.

- **Non-conflicting, draft, and stacked-base PRs are untouched (unchanged from
  before):** PRs with `mergeable != CONFLICTING`, `isDraft: true`, or a
  `baseRefName` other than the default branch are never passed to the sync step.

- **The script still always exits 0:** a mix of synced, skipped, and failed PRs in
  one run never produces a non-zero exit — this runs from the session-start hook
  and must never block it.
