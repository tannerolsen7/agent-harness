# Keep open PRs synced with main so /cr's clean-merge check stays true

## What & Why

`/cr` checks that a branch merges cleanly into main before it lets you push — but
that check only holds at the moment `/cr` runs. Once a PR is open, main keeps moving
(other PRs land, and this repo's dashboard files — `TASKS.md`, `harness-progress.html`,
`harness-activity.html`, `PITFALLS.md`, `BACKLOG.md`, `docs/RECURRING-FINDINGS.md` — get
touched by nearly every branch). By the time a human goes to merge, the PR can show
`CONFLICTING` on GitHub even though it passed `/cr` cleanly.

Right now two real PRs (#128, #129) are stuck in exactly this state. Tanner has to
notice this, then manually fetch, merge, resolve, and push each one — the thing
`sync-open-prs.sh` (run every session start) is supposed to do automatically, but
doesn't, because of the two problems below. If this doesn't get fixed, every session
keeps producing new stuck PRs and the manual cleanup never stops.

## Context

- `scripts/sync-open-prs.sh` — runs at session start. For every open PR GitHub marks
  `CONFLICTING`, it currently calls `gh pr update-branch --rebase`. That call runs
  **server-side on GitHub** — it cannot see or run this repo's local `.git/config`
  merge drivers (registered by `scripts/register-merge-drivers.sh` from
  `.gitattributes`). So it fails on conflicts that a local `git merge origin/main`
  would resolve automatically.
- `.gitattributes` already declares merge strategies for some hot files:
  `harness-progress.html merge=ours`, `PITFALLS.md merge=union`,
  `docs/RECURRING-FINDINGS.md merge=union`, `docs/patterns-registry.md merge=union`,
  `TASKS.md merge=tasks-higher-state` (custom driver in
  `scripts/tasks-merge-driver.sh`). Two other files hit by nearly every branch —
  `harness-activity.html` and `BACKLOG.md` — were never added.
- `.claude/skills/cr/SKILL.md` (Pre-flight — Merge readiness, lines ~28–79) already
  implements the correct pattern for this exact problem: detect the base branch,
  fetch it, and if the branch doesn't merge cleanly, run `git merge "origin/$BASE"`;
  on success continue, on failure `git merge --abort` and tell the human to resolve
  manually. This design reuses that pattern instead of inventing a new one.
- `docs/solutions/2026-06-24-auto-merge-as-sync-strategy-for-automated-tools.md` is
  this repo's own written policy: automated tools must use `git merge` + abort-on-
  conflict, never `git rebase`, because rebase either needs a force-push (which
  automated tools must not do) or leaves a `REBASE_HEAD` half-state a script can't
  recover from on its own.
- Confirmed by hand on this repo: `git merge-tree origin/main
  origin/feat/hooks-security-batch-a` (PR #128) exits 0 with no conflict markers —
  it merges clean locally because the registered drivers resolve
  `harness-progress.html`. GitHub still reports this PR as `CONFLICTING`, because it
  can't run those drivers. That gap is the bug this design closes.

## Done Looks Like

- `.gitattributes` has `harness-activity.html merge=ours` and
  `BACKLOG.md merge=union`.
- `sync-open-prs.sh` no longer calls `gh pr update-branch --rebase`. For each open,
  non-draft, default-base PR GitHub marks `CONFLICTING`, it merges `origin/<base>`
  locally in a throwaway worktree and pushes the result on success.
- A PR whose branch is checked out in a live worktree elsewhere is skipped with a
  clear "sync it yourself" message — the script never touches a branch someone else
  has checked out.
- A PR with a genuine content conflict (not a generated-file collision) aborts
  cleanly and prints the exact manual recovery command, same wording style as
  `/cr`'s pre-flight block message.
- The scratch worktree used for the merge is always removed, even when the merge or
  push fails.
- The script's existing contract is preserved: always exits 0 (this runs from the
  session-start hook and from `/queue`'s merge-batch trigger — it must never block
  either).
- `tests/sync-open-prs.test.sh` covers the new mechanism with a real local bare repo
  (same pattern as `tests/pre-push-sync-gate.test.sh`), not a stubbed `gh
  update-branch` call — because the whole point is that real git merge behavior
  (including driver resolution) is what's under test now.
- Running the updated script against this repo's two real stuck PRs, #128 (the
  false-conflict one) syncs and pushes cleanly; #129 (the genuine
  `.claude/skills/harness-setup/SKILL.md` conflict) is reported for manual
  resolution, unchanged.

## Interface Contract

### `.gitattributes` (modified)

Add two lines, same format as the existing entries:
```
harness-activity.html merge=ours
BACKLOG.md             merge=union
```
No driver registration changes needed — `merge.ours.driver` is already registered
globally in `.git/config` by `scripts/register-merge-drivers.sh`, and `merge=union`
needs no driver at all (it's a built-in git merge strategy).

### `scripts/sync-open-prs.sh` (modified)

Inputs: unchanged — `gh pr list --json number,headRefName,baseRefName,mergeable,isDraft`.
The existing filters (`is_draft`, `base != $DEFAULT_BRANCH`, `mergeable !=
CONFLICTING`) are unchanged; they already decide which PRs reach the sync step.

For each PR that reaches the sync step, replace the `gh pr update-branch --rebase`
call with:

1. **Skip if the branch is checked out elsewhere.** Check
   `git worktree list --porcelain` for `branch refs/heads/<head>`. If found, print
   `skipped #<n> (<head>) — checked out in another worktree, sync it yourself` and
   move to the next PR. This is the one case where touching the branch would step on
   someone's in-progress work.
2. **Create a scratch worktree.** `git worktree add --quiet <tmpdir> <head>` into a
   `mktemp -d` directory. If this fails (e.g., branch doesn't exist locally yet —
   first run may need a `git fetch origin <head>:<head>` first), report failure for
   that PR and continue.
3. **Merge and push inside the scratch worktree**, mirroring `/cr`'s pre-flight
   exactly:
   ```bash
   git fetch origin "$base" --quiet
   if git merge "origin/$base" --quiet -m "chore(sync): merge origin/$base into $head"; then
     git push origin "HEAD:$head" --quiet && echo "synced #$n ($head)" \
       || echo "failed #$n ($head) — merge ok locally but push failed, sync it yourself"
   else
     git merge --abort
     echo "failed #$n ($head) — real conflict, resolve manually: git fetch origin && git checkout $head && git merge origin/$base"
   fi
   ```
4. **Always remove the scratch worktree** after the attempt (`git worktree remove
   --force <tmpdir>`), success or failure — use a trap so a mid-step error can't
   leave it behind.

Outputs: same shape as today — one status line per PR to stdout, script always
exits 0. Line wording changes from "updated #N" / "failed #N ... rebase manually" to
"synced #N" / "failed #N ... " + a specific reason (checked out elsewhere, scratch
worktree couldn't be created, real conflict, or push failed after a clean merge).

Constraints:
- Never force-push. The merge commit is a normal, forward-only commit; a plain
  `git push` always suffices.
- Never touch a branch checked out in another live worktree — that worktree may be
  mid-edit in another session.
- Never leave a scratch worktree registered after the script exits, on any exit
  path.
- Preserve the script's "always exit 0" contract — a sync failure for one PR is
  reported, never fatal to the run.
- GitLab path is unaffected — it already exits early with "not yet supported."

State: none owned. Every run re-derives the PR list from `gh pr list` and re-does
the sync from scratch; nothing persists between runs.

## Out of Scope

- Fixing PR #129's real conflict in `.claude/skills/harness-setup/SKILL.md` — that's
  overlapping hand-written content, not a generated-file collision. Handled
  separately, by hand.
- Auto-merging PRs. This only keeps branches in sync with main; a human (or a
  separate tool) still decides when to actually merge.
- GitLab support for this sync path — already stubbed as unsupported; not extended
  here.
- Changing `/cr`'s own pre-flight step — it already does the right thing today.
- Adding merge strategies for any file besides `harness-activity.html` and
  `BACKLOG.md` — no other hot file showed up unmanaged in the audit.

## Relevant Files

- `scripts/sync-open-prs.sh` — the script being changed
- `.gitattributes` — two new lines
- `.claude/skills/cr/SKILL.md` (lines ~28–79) — the merge/abort pattern this reuses
- `docs/solutions/2026-06-24-auto-merge-as-sync-strategy-for-automated-tools.md` —
  the policy this brings `sync-open-prs.sh` into line with
- `tests/sync-open-prs.test.sh` — existing tests to rewrite for the new mechanism
- `tests/pre-push-sync-gate.test.sh` — reference pattern for driving real git
  behavior against a local bare-repo remote in a test

---

## Design Questions Sheet

### 1. Data shape

No database, no schema, no Zod boundary — this is a shell script operating on git
state and one JSON payload from `gh pr list` (shape unchanged from today).

**Inputs:**
- PR JSON: `{number, headRefName, baseRefName, mergeable, isDraft}` — unchanged.
- Git state: local worktree list, `origin/<base>` after fetch.

**Outputs:**
- stdout status lines (human-readable, not machine-parsed anywhere today — grepped
  only by tests).
- Git side effects: a new merge commit pushed to the PR's remote branch, on success.
- Process exit code: always 0.

### 2. Edge cases

- **Branch checked out in another worktree** (e.g., an active `/feature` session on
  that exact branch): skip, don't touch it, tell the human to sync manually.
- **Branch doesn't exist locally yet** (first time this script runs after the PR was
  opened from a fresh clone): `git worktree add <tmpdir> <head>` fails because there's
  no local branch ref. Fetch it first (`git fetch origin <head>:<head>`) before the
  worktree add, or worktree add with `-b` from `origin/<head>` — needs the actual
  implementation to pick one and note it; either is fine since both leave the local
  ref where `git worktree add` expects it. (Left as an implementation detail — not a
  product decision.)
- **Merge succeeds locally but push fails** (e.g., someone pushed to the same branch
  in between fetch and push, or a permissions issue): report distinctly from a merge
  conflict so the human knows the branch already has the right content locally, just
  not published — different recovery than "resolve a conflict."
- **Real content conflict** (like #129): abort, report, move on. Never leave the
  scratch worktree mid-conflict.
- **Two sessions run this script at the same time** on the same PR: the second
  `git worktree add` for the same branch fails (git refuses to check out a branch
  twice). That's the existing "checked out elsewhere" skip path — no special
  handling needed beyond what's already in the design.
- **`origin` push requires auth the script doesn't have** (rare, e.g. a stale token):
  falls into the "push failed" case above — reported, not fatal to the run.

### 3. Open questions the robot must NOT answer

None. This is an internal tooling fix with no product, UX, or business trade-off —
every decision above is mechanical (which git plumbing call does the job) rather
than a judgment call about what the system should do for a user. If the grill pass
finds one hiding in here, it gets added below before this goes to Tanner for
sign-off.
