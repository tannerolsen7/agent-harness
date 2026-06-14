# Backlog (interim)

> **Interim home.** *Where* backlog items should live per-project (Linear / GitHub Issues /
> TASKS.md / this file) is still being decided — see "Backlog mechanism" under *Promoted* below.
> This file is the durable interim so nothing is lost.
>
> **Anti-"build-forever" rule.** Every item carries a **severity** and a **status**. HIGH/MEDIUM
> items are NOT allowed to sit silently — they get *promoted to the active plan*, not parked. This
> list is reviewed whenever a `/cr` backlogs something. If an item can't be justified as worth
> keeping, it's dropped, not left to rot.

| Item | Severity | Status | Notes |
|---|---|---|---|
| **Branch protection on `main`** (require the `verify` check so F6 *blocks* merges) | LOW | Blocked (cost) | Requires a paid GitHub plan (~$4/user/mo); Tanner deferred the spend. F6 CI already runs + reports on every PR — this only flips it from advisory to merge-blocking. Revisit when on a paid plan, or if the repo moves to an org that has it. |
| **Custom diff-review UI** (better than GitHub's merge screens) | IDEA / explore | Backlog | **Goal:** make every PR so simple to review that the operator could *teach the change to another person* by the time it's pushed. GitHub's merge screens don't give a good enough feel for *what* changed and *why*. Build on what the harness already produces — the spec, the feature-doc hub (R4-D9), `/grill-with-docs`, and the `/cr` disposition report — rendered into one teachable view (the change + its intent + the review verdict, side by side). Distinct from F6/CI: this is about *human comprehension*, not the gate. |

## Promoted to the active plan (tracked, NOT parked here)
- ✅ **`/queue` orphaned-worktree** — RESOLVED (worktree-lifecycle branch). `/queue` Step 3 no longer
  passes `isolation: "worktree"`; the agent works in the pre-created `.claude/worktrees/<slug>` (which
  IS its isolation), so no second worktree is orphaned.
- ✅ **Worktree/branch cleanup in `/feature` + `/queue`** — RESOLVED (worktree-lifecycle branch).
  `gc.sh` now removes a merged branch's worktree before deleting the branch (also fixed the pre-existing
  `git branch -vv` "+ " worktree-prefix bug that made worktree branches un-gc'able; tested in
  `tests/gc.test.sh`). `/feature` and `/queue` both document post-merge cleanup via `gc.sh`.
- **Backlog mechanism research** — per-project target (Linear / Issues / file) + an aging/severity
  mechanism that prevents this list from building forever. Produces the durable replacement for
  this interim file.
