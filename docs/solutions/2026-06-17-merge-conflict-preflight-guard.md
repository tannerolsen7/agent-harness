# Problem: Agents Declare Branches "Ready" Without Checking Merge Cleanness

**Problem class:** A review and PR workflow validates the branch in isolation — tests pass, handler parity, lint clean — but never checks whether the branch can merge cleanly into the current base. Agents declare branches ready and open PRs on branches that would immediately conflict.

## When this bites you

Three PRs are open. Each passed the full review pipeline. Each is marked "ready to merge." None will merge cleanly because the base branch moved forward after those branches were cut. No error surfaced during review. The conflict is discovered only when a human tries to merge.

The deceptive part: the branch is self-consistent. Its own tests pass. The review pipeline has nothing to complain about. The problem exists only in the relationship between the branch and the current base — a relationship the pipeline never checked.

## Root cause

The review pipeline (`/cr`) ran analytical passes against the branch diff. The PR script (`pr.sh`) checked that the `.cr-ok` sentinel existed. Neither step fetched the remote base branch or ran a merge simulation. Both assumed "branch is internally valid" implies "branch is mergeable." That assumption breaks the moment any other branch merges into the base after yours was cut.

## The fix

Two co-ordinated guards — one early in the workflow, one late.

**Guard 1 — Pre-flight in the review skill:**

Add a Pre-flight section that runs before any review pass. If it finds conflicts, it emits rebase instructions and hard-blocks — no passes run, no sentinel written.

```bash
BASE=$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}')
# git reports "(unknown)" when remote HEAD symref is unset — catch both forms
[ -z "$BASE" ] || [ "$BASE" = "(unknown)" ] && BASE="main"
git fetch origin "$BASE" --quiet 2>/dev/null || true
MERGE_BASE=$(git merge-base HEAD "origin/$BASE" 2>/dev/null || true)
if [ -n "$MERGE_BASE" ]; then
  # grep -c exits 1 on zero matches; || true prevents set -e from aborting
  CONFLICTS=$(git merge-tree "$MERGE_BASE" HEAD "origin/$BASE" 2>/dev/null \
    | grep -c '<<<<<<<' || true)
  if [ "${CONFLICTS:-0}" -gt 0 ]; then
    echo "BLOCKED: $CONFLICTS conflict region(s) — rebase before reviewing"
    exit 1
  fi
fi
```

**Guard 2 — Gate in `scripts/pr.sh`:**

The same check runs AFTER the remote-branch precondition but BEFORE the `.cr-ok` sentinel is consumed. This covers the window where a commit lands on the base after `/cr` ran but before the PR opens. If conflicts are found: exit non-zero, leave the sentinel intact so the user can rebase and retry without re-running the full review.

## Why `git merge-tree <ancestor> HEAD origin/<base>`?

This is the old three-argument form, available since git 1.9. It simulates the merge in memory and prints the result — no working tree changes, no index writes. Conflict markers (`<<<<<<<`) appear only when both sides changed the same region.

Two wrong alternatives:

- `git diff origin/<base>...HEAD` measures divergence, not conflict. Every feature branch diverges from its base — this would block everything.
- `git merge --no-commit` actually writes to the working tree and index. Using it as a pre-check dirties the branch. Off the table.

## Why detect the base branch dynamically?

`git remote show origin` (no `-n` flag) makes a live network call to the remote. This is the only reliable method on a fresh clone or when `origin/HEAD` was never set locally. The `-n` flag reads local config and returns `(unknown)` on any repo where the symbolic ref was never initialized.

Hardcoding "main" silently passes on any project using a different default branch name.

## The `(unknown)` edge case

`git remote show origin` outputs the literal string `(unknown)` when the remote HEAD symref is unset — bare repos, self-hosted servers with no default branch configured. A guard written as `[ -z "$BASE" ]` passes `(unknown)` through, causing `git fetch origin "(unknown)"` to fail silently and the check to be skipped entirely.

Correct guard: `[ -z "$BASE" ] || [ "$BASE" = "(unknown)" ] && BASE="main"`

## Why two guards, not one?

- The review-skill guard blocks early. No time wasted reviewing a branch that cannot ship.
- The `pr.sh` guard covers the gap between `/cr` running and the PR opening. If any commit lands on the base in that window, the review was clean but the branch is now conflicted.

These are defense-in-depth, not duplication. Each closes a window the other cannot see.

## What doesn't work

**Running only a local test suite before opening a PR:** Tests validate correctness. They say nothing about merge cleanness. A branch can be fully correct and completely un-mergeable simultaneously.

**Checking `git status` or `git diff` for conflicts:** These only reflect conflicts already present in the working tree. A clean working tree says nothing about what happens when the branch meets the latest base.

**Counting commits ahead of base (`git log origin/<base>..HEAD`):** Every feature branch is ahead of its base. Ahead ≠ conflicted. You need a merge simulation.

**Relying on the PR host to surface conflicts:** The host shows a conflict banner after the PR is open. By then the agent has already moved on. Catching conflicts at the host is too late for an automated workflow.

## Tags

merge-conflict, git, dry-run, merge-tree, pre-flight, defense-in-depth, pr-gate, base-branch-detection, sentinel, (unknown)-guard
