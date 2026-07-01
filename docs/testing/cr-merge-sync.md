## Diagnose open PRs that conflict with main (`scripts/sync-open-prs.sh`, `.gitattributes`)

`sync-open-prs.sh` runs at session start to check open PRs GitHub marks
`CONFLICTING`. It used to call `gh pr update-branch --rebase`, which runs
server-side on GitHub and can't run this repo's local merge drivers — so it failed
on conflicts a local `git merge origin/main` would resolve automatically.

An earlier version of this script also self-issued a scoped `.claude/.cr-ok`
sentinel and pushed automatically whenever it could prove the merge only touched
files with a registered `.gitattributes` merge strategy. An adversarial review
found that unsafe even scoped: a self-issued sentinel is indistinguishable from a
real `/cr` review to `.husky/pre-push`, and the proof itself could be read from the
merged (attacker-influenced) working tree instead of a trusted source. The script
now only diagnoses — it never pushes and never issues a sentinel.

### Confirmed behaviors

- **`.gitattributes` covers all hot generated/tracking files:** `harness-activity.html`
  has `merge=ours` (regenerated fresh every session — branch versions are always
  stale) and `BACKLOG.md` has `merge=union` (append-only — keep both sides'
  entries). Matches the existing `harness-progress.html merge=ours` and
  `PITFALLS.md merge=union` entries.

- **A conflicting PR that merges clean locally is reported resolvable, never
  pushed:** for an open, non-draft, same-repo PR targeting the default branch with
  `mergeable: CONFLICTING`, the script creates a scratch worktree, merges
  `origin/<base>` there, and — if the merge succeeds and every file it had to
  decide between is covered by a registered merge strategy — prints `resolvable
  #<n> (<head>) — not a real conflict, push it yourself: <exact commands>`. It
  never pushes on its own.

- **A PR with a genuine content conflict is reported, not force-resolved:** if the
  local merge leaves conflict markers, the script aborts the merge and prints
  `failed #<n> (<head>) — real conflict, resolve manually: ...` with the exact
  fetch/checkout/merge commands to run by hand. No partial state is left behind.

- **A merge that succeeds cleanly but touches an uncovered file is still flagged:**
  a plain `git merge` can succeed with no conflict markers even when both sides
  changed the same file (e.g. different lines) — that alone doesn't mean the
  content is safe. If any file both sides changed lacks a registered
  `.gitattributes` merge strategy, the script prints `failed #<n> (<head>) — merge
  touched files outside the registered merge strategies, needs a real /cr pass`,
  even though `git merge` itself reported no conflict.

- **Merge-strategy coverage is checked against the trusted (base) side's
  `.gitattributes`, never the merged tree:** `scripts/check-merge-driver-coverage.sh`
  reads attributes via `git check-attr --source=<base-ref>`. A PR branch that adds
  its own `.gitattributes` entry (e.g. granting itself `merge=union` on a file it
  edited) does not gain coverage from that — only entries already present on the
  base side count.

- **Only a known, explicit set of merge strategies counts as covered:** `union`,
  `ours`, and `tasks-higher-state`. For `ours` and `tasks-higher-state`, the script
  also confirms the driver is actually registered in `.git/config`
  (`merge.<name>.driver`) before trusting it — an attribute naming an unregistered
  driver is treated as uncovered, not as a free pass.

- **Cross-repository (fork) PRs are never touched:** the PR loop reads
  `isCrossRepository` from `gh pr list` and skips any PR where it's true, before
  the merge/coverage logic ever runs — untrusted fork content and its
  `.gitattributes` are never merged in, even just to diagnose.

- **A branch checked out in another live worktree is skipped, not touched:** if
  `git worktree list` shows the PR's branch already checked out elsewhere, the
  script prints `skipped #<n> (<head>) — checked out in another worktree, check it
  yourself` and moves on without creating a scratch worktree for it.

- **The scratch worktree is always removed and never creates a local branch:** the
  scratch checkout is detached (`git worktree add --detach`), so it can never reset
  or clobber an existing local branch of the same name. Whether the diagnosis for a
  given PR succeeds, fails on a real conflict, or fails to create the worktree, the
  scratch worktree is removed before the script moves to the next PR.

- **Non-conflicting, draft, and stacked-base PRs are untouched (unchanged from
  before):** PRs with `mergeable != CONFLICTING`, `isDraft: true`, or a
  `baseRefName` other than the default branch are never passed to the diagnose
  step.

- **The script still always exits 0:** a mix of resolvable, skipped, and failed PRs
  in one run never produces a non-zero exit — this runs from the session-start
  hook and must never block it.
