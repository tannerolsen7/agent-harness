# Git Discipline

*Universal patterns — adapt to your project.*

Git is the safety net the whole system rests on — every "it's revertable" claim in the settings-and-permissions layer assumes git state is clean and known. When git state is *unknown* — wrong branch, tangled sessions, stale relative to main — the net has a hole in it. This page closes that hole.

> **Why this page exists.** The system had branch protection, CI, and destructive-op hooks before this page. What it lacked was *agent-side git discipline*: a way for an agent to know and report where it is, a way to stop two sessions colliding on one branch, a defined procedure for staying current with main, and a recovery runbook for when things tangle anyway. Prevention hooks live in the settings-and-permissions layer. This page is the workflow and the recovery doctrine.

The four failure modes this page addresses, each named so the system can target it:

- **Disorientation** — the agent doesn't reliably know its branch, worktree, or sync state, so it acts on a stale assumption. Fixed by the Git Status Preamble.
- **Collision** — two sessions write to the same branch, discovered only at merge time when the commits must be split apart. Fixed by the one-session-per-branch invariant and the branch registry.
- **Drift** — a feature branch falls behind `main` and the gap is found at merge, producing "passed on the branch, breaks on main." Fixed by the sync checkpoints and the pre-push staleness gate.
- **Tangle** — sessions commingle, or a commit lands on `main`, or HEAD detaches. Fixed by the Recovery Runbook.

---

## The Git Status Preamble

The agent must emit a git status block **before any git-touching action** (`git checkout`, `git add`, `git commit`, `git rebase`, `git merge`, `git push`, worktree operations) and **once at session start**. It is part of the agent's response — not a terminal status line. A terminal status line serves the human watching a terminal; the preamble serves anyone reading the transcript, including on mobile, and the next agent inheriting a handoff.

**Format:**

```
git: <branch> · worktree: <worktree-name or "primary checkout">
sync: <up to date with origin/main | N behind | N ahead | N behind N ahead>
state: <clean | N staged, N modified, N untracked>
last: <short-sha> "<commit subject>"
```

**Worked example — healthy:**

```
git: feat/list-filters · worktree: list-filters
sync: up to date with origin/main
state: clean
last: a1b2c3d "test(list): filter by category"
```

**Worked example — needs attention (⚠ signals):**

```
git: feat/export-renderer · worktree: export-renderer
sync: ⚠ 4 behind origin/main — rebase before push
state: 2 staged, 1 modified
last: b2c3d4e "feat(export): add PDF export"
```

**Worked example — critical (🛑 signals):**

```
git: main · worktree: primary checkout
sync: ⚠ ON MAIN — feature work must be on a branch
state: 3 modified
last: c3d4e5f "fix: patch list query"
```

**⚠ warning triggers — emit before any action when any of these are true:**

- On `main` or `master`
- Behind `origin/main` by any commits
- Detached HEAD state
- Branch differs from the branch-registry registration for this session

**On a ⚠:** stop the planned action, surface the warning, wait for human go-ahead or follow the Recovery Runbook step that resolves it. Never silently continue through a warning.

---

## One-session-per-branch invariant

The branch collision problem — two sessions writing to the same branch, discovered only when commits must be split at merge — is a registration problem. No git mechanism prevents it. The branch registry closes it.

**The invariant:** one active session per branch at a time. A session claims a branch when it starts work. No other session commits to that branch until the claim is released. *(This harness: the one-session-per-branch rule and the full worktree lifecycle are documented in `.claude/AI-WORKFLOW.md`.)*

**The registry:** a gitignored JSON file (e.g. `.claude/active-branches.json`) — never committed.

```json
{
  "feat/list-filters": {
    "worktree": "list-filters",
    "session_id": "session-abc123",
    "claimed_at": "2026-05-21T14:32:00Z"
  },
  "feat/export-renderer": {
    "worktree": "export-renderer",
    "session_id": "session-def456",
    "claimed_at": "2026-05-21T15:10:00Z"
  }
}
```

**Lifecycle:**

| Step | When | Action |
| --- | --- | --- |
| Claim | `git checkout -b feat/<slug>` | Write entry to registry |
| Verify | Before every `git add` / `git commit` | Check registry: this session owns this branch |
| Release | After merge + worktree removal | Delete entry from registry |
| Stale check | Session start, `claimed_at` > 24h with no recent commit | Flag to human; do not auto-release |

**Claim check (before `git checkout -b`):**

```bash
BRANCH="feat/my-slug"
REGISTRY=".claude/active-branches.json"

if [ -f "$REGISTRY" ]; then
  OWNER=$(jq -r --arg b "$BRANCH" '.[$b].session_id // empty' "$REGISTRY")
  if [ -n "$OWNER" ] && [ "$OWNER" != "$MY_SESSION_ID" ]; then
    echo "⛔ Branch $BRANCH is claimed by session $OWNER"
    echo "Options:"
    echo "  A) Open that session's worktree and continue there"
    echo "  B) Pick a different slug for this task"
    exit 2
  fi
fi
```

**Commit guard hook — `branch-registry-guard.sh`:**

```bash
#!/bin/bash
# PreToolUse: Bash
# Blocks git add/commit when registry shows another session owns this branch.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '^git (add|commit)'; then
  exit 0
fi

REGISTRY=".claude/active-branches.json"
[ ! -f "$REGISTRY" ] && exit 0

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
MY_SESSION="${CLAUDE_SESSION_ID:-unknown}"
OWNER=$(jq -r --arg b "$BRANCH" '.[$b].session_id // empty' "$REGISTRY" 2>/dev/null)

if [ -n "$OWNER" ] && [ "$OWNER" != "$MY_SESSION" ]; then
  echo "⛔ Branch collision: $BRANCH is registered to session $OWNER" >&2
  echo "This session ($MY_SESSION) may not commit to it." >&2
  echo "STOP AND SURFACE: write a BLOCKING question to questions.md." >&2
  exit 2
fi

exit 0
```

Wire this in your settings file alongside the existing scope-enforcement PreToolUse entry. Add the registry file to `.gitignore`.

---

## Sync discipline — staying current with main

A branch that drifts behind `main` produces "passed on branch, breaks on main" at merge. Three checkpoints address this: branch creation, pre-review, and pre-push.

### Checkpoint 1 — Branch creation

Always branch from a fresh `origin/main`. The feature-loop line `git checkout -b feat/<slug>` expands to:

```bash
git fetch origin
git checkout origin/main -b feat/<slug>
```

The branch starts current. Drift cannot accumulate before the first commit.

### Checkpoint 2 — Pre-review

Before running the full pre-merge review (`/cr`), check sync state and rebase if behind:

```bash
git fetch origin
BEHIND=$(git rev-list --count HEAD..origin/main)
if [ "$BEHIND" -gt 0 ]; then
  echo "Branch is $BEHIND commits behind origin/main — rebasing before review"
  git rebase origin/main
fi
```

If the rebase produces conflicts: stop, surface the conflict list to the human, do not run the review until resolved. The review reviews the post-rebase state — never a stale branch.

### Checkpoint 3 — Pre-push auto-rebase gate

If the branch is behind `origin/main` at push time, auto-rebase — but only when safe.

**Safe conditions for auto-rebase (all must be true):**

- Not on `main` or `master`
- Not in detached HEAD
- Branch is registered to this session in the branch registry

**On successful auto-rebase:** re-emit the preamble with updated sync state, then continue to push.

**On conflict during auto-rebase:** run `git rebase --abort` (branch left exactly as before), block the push, surface the conflict.

**On unsafe conditions:** block without rebasing, surface which condition failed.

Add to the pre-push hook before the existing sentinel checks:

```bash
# Sync gate — auto-rebase if behind origin/main and provably safe
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ] && [ "$BRANCH" != "HEAD" ]; then
  git fetch origin --quiet 2>/dev/null
  BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)

  if [ "$BEHIND" -gt 0 ]; then
    echo "Branch is $BEHIND commits behind origin/main — auto-rebasing..."
    if git rebase origin/main --quiet; then
      LAST=$(git log -1 --format="%h \"%s\"" 2>/dev/null)
      echo ""
      echo "git: $BRANCH · sync: up to date with origin/main (rebased)"
      echo "last: $LAST"
      echo ""
    else
      git rebase --abort
      echo "" >&2
      echo "⛔ Auto-rebase failed — conflicts detected. Push blocked." >&2
      echo "Resolve conflicts manually, then re-push." >&2
      echo "git: $BRANCH · sync: ⚠ conflict with origin/main" >&2
      exit 1
    fi
  fi
fi
```

### Rebase-vs-merge policy

| Scenario | Use | Why |
| --- | --- | --- |
| Staying current with `main` — un-pushed, single-session branch | `git rebase origin/main` | Linear history; safe when history is private |
| Staying current with `main` — pushed branch another session has touched | `git merge origin/main` | Rebase rewrites shared history — never do this |
| Integrating the finished branch into `main` | PR merge via your host | Preserves branch context; the PR is the record |
| Applying one specific commit to another branch | `git cherry-pick <sha>` | Surgical; used in the Recovery Runbook |

**Hard rule:** never `git rebase` a branch that has been pushed and that another session or person may have pulled. If in doubt, `git merge`. The auto-rebase gate only fires on branches registered to the current session — the safe case.

---

## Recovery Runbook

Named procedures for the four tangle scenarios. The agent follows these exactly — does not improvise, does not extend scope, does not merge or push until the procedure is complete and the preamble shows clean. Each procedure ends by re-emitting the Git Status Preamble; a clean preamble is the exit condition.

### RR-1 — Committed to `main` by mistake

**Symptom:** preamble shows `git: main`; commits present that belong to a feature.

```bash
# 1. Identify the commits to rescue
git log --oneline origin/main..HEAD

# 2. Create a rescue branch at current HEAD
git checkout -b feat/<correct-slug>

# 3. Reset local main to match origin/main
git checkout main
git reset --hard origin/main

# 4. Verify commits are on the rescue branch
git checkout feat/<correct-slug>
git log --oneline origin/main..HEAD

# 5. Register rescue branch in the branch registry
# 6. Emit preamble — continue from feat/<correct-slug>
```

Do not push `main` after the reset. The reset is local only; `origin/main` is unchanged.

### RR-2 — Two sessions wrote to the same branch (split by cherry-pick)

**Symptom:** `git log` shows commits from two distinct pieces of work that should be on separate branches.

**Confirm with human before Step 5** — interactive rebase rewrites history and requires explicit same-turn approval.

```bash
# 1. Map the commits — identify Task A vs Task B
git log --oneline origin/main..HEAD

# 2. Create Task B's branch from origin/main
git checkout -b feat/<task-b-slug> origin/main

# 3. Cherry-pick Task B's commits
git cherry-pick <sha-b1> <sha-b2> ...

# 4. Return to the original branch (Task A)
git checkout <original-branch>

# 5. CONFIRM WITH HUMAN — interactive rebase to drop Task B's commits
git rebase -i origin/main
# Mark Task B's commits as 'drop' in the editor

# 6. Verify each branch contains only its own commits
git log --oneline origin/main..feat/<task-a-slug>
git log --oneline origin/main..feat/<task-b-slug>

# 7. Register both branches in the branch registry
# 8. Emit preamble for each — proceed independently
```

### RR-3 — Detached HEAD

**Symptom:** preamble shows `git: HEAD detached at <sha>` instead of a branch name.

```bash
# 1. Check if there are commits to save
git log --oneline -5

# 2a. No commits to save — return to correct branch
git checkout feat/<correct-slug>

# 2b. Commits were made while detached — rescue them first
git checkout -b rescue/<short-sha>
git checkout feat/<correct-slug>
git cherry-pick <rescue-sha1> <rescue-sha2> ...
git branch -d rescue/<short-sha>

# 3. If commits were lost (left detached HEAD without saving)
git reflog
# Find: HEAD@{N}: commit: <message> — note the SHA
git checkout -b rescue/<sha>
# Then follow 2b

# 4. Emit preamble — verify branch name is correct
```

### RR-4 — Branch behind main with conflicts (auto-rebase failed)

**Symptom:** pre-push hook ran `git rebase --abort`; preamble shows `⚠ conflict with origin/main`.

```bash
# 1. Understand the conflict before rebasing
git fetch origin
git log --oneline HEAD..origin/main   # commits in main not in branch
git diff HEAD...origin/main           # divergent content

# 2. Rebase and resolve one commit at a time
git rebase origin/main
# On each conflict:
git status
# Edit conflicting files, then:
git add <resolved-file>
git rebase --continue

# 3. If rebase becomes unmanageable — abort and merge
git rebase --abort
git merge origin/main   # always safe; produces a merge commit

# 4. Run tests before pushing
<your test command>

# 5. Emit preamble — verify sync shows up to date
```

Abort and use merge instead when: more than 3 conflict rounds; conflict involves a schema migration; any conflicting file is outside the task's allowed-files. Surface to human before switching strategies.

---

## Parallel worktree merge-time integration

The workflow-skills layer states: "merge worktrees only after both are green." This section defines the deliberate integration procedure. *(This harness: the worktree create/work/PR/merge/cleanup lifecycle and the `.claude/worktrees/<slug>` convention are documented in `.claude/AI-WORKFLOW.md`.)*

**The key insight:** worktree isolation doesn't remove conflicts — it moves them to merge time, where they surface as visible git conflicts instead of silent runtime overwrites. That is the right tradeoff. But "merge time" must have a procedure, or conflicts are handled ad-hoc under time pressure.

**Integration order:** merge in dependency order — the slice whose output feeds another goes first. If slices are truly independent (no shared state, no common files), go simplest first so the complex slice resolves conflicts against a clean post-merge baseline.

```bash
# 1. Fetch and sync main before starting integration
git fetch origin
git checkout main && git pull origin main

# 2. Integrate slice A (most foundational first)
git checkout feat/<slice-a>
git rebase origin/main        # bring current
<your test command>           # must be green
# Open PR for slice A, merge via your host

# 3. Integrate slice B against post-merge main
git fetch origin
git checkout feat/<slice-b>
git rebase origin/main        # now includes slice A — conflicts surface here
<your test command>           # resolve any conflicts before proceeding
# Open PR for slice B, merge

# 4. If conflict resolution changes behavior, re-run the feature review on the affected slice

# 5. Remove all worktrees after their branches are merged
git worktree remove .claude/worktrees/<slice-a>
git worktree remove .claude/worktrees/<slice-b>
git branch -d feat/<slice-a> feat/<slice-b>
# Delete registry entries from the branch registry
```

| Rationalization | Rebuttal |
| --- | --- |
| "Both slices are green independently — combined is fine" | Independent green does not mean combined green. Integration surfaces interactions. Run tests after each rebase, in order. |
| "I'll resolve conflicts quickly and skip the review re-run" | Conflict resolution is a code change. If it touches behavior, it needs review. Skip only if purely mechanical (import reorder, comment merge). |
| "Worktrees are still there but branches are merged — I'll clean up later" | Stale worktrees are invisible drift. Clean up immediately after merge; the registry entry is your signal that a worktree exists. |

---

## What to add to your session-start process doc

Add this block to the session-start section of your process doc (e.g. CLAUDE.md) in every project:

```markdown
## Git discipline

At session start and before any git-touching action, emit the Git Status Preamble:

  git: <branch> · worktree: <worktree-name or "primary checkout">
  sync: <up to date with origin/main | N behind | N ahead>
  state: <clean | N staged, N modified, N untracked>
  last: <short-sha> "<commit subject>"

Stop and surface (⚠) if on main, behind origin/main, detached HEAD,
or branch differs from the branch-registry registration for this session.

Before git checkout -b: check the branch registry — do not claim a
branch registered to another session.

Before git rebase on a pushed branch or git push --force-with-lease:
confirm with human. History rewrites are never automatic.

Run git branch --show-current before every git add / git commit.
If on main: stop.
```

---

## File checklist — what to create per project

| File | Action | Notes |
| --- | --- | --- |
| Branch registry (e.g. `.claude/active-branches.json`) | Create with `{}` | Add to `.gitignore` immediately |
| `branch-registry-guard.sh` hook | Copy from above | `chmod +x` |
| Pre-push hook | Add sync gate block | Before existing sentinel checks |
| Session-start process doc (e.g. CLAUDE.md) | Add git discipline block | Session-start section |
| `.gitignore` | Add the branch-registry line | Prevent accidental commit |

See the settings-and-permissions layer for the settings-file wiring. Wire `branch-registry-guard` alongside the existing scope-enforcement PreToolUse entry.
