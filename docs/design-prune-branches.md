# Design: prune-branches.sh (gc.sh gap patches)

## What this changes

`scripts/gc.sh` is renamed to `scripts/prune-branches.sh`. Three new cleanup passes are added. All callers (`session-start.sh`, `AI-WORKFLOW.md`, skill references, tests) are updated to use the new name.

The rename comes first (one commit, no behavior change), then the three passes (one commit each or together).

## Gap 1 — Orphaned worktree directories

**Problem:** `git worktree prune` removes stale git registrations but leaves the directory on disk. When a registration is lost (e.g. partial removal, filesystem-level deletion of `.git`), the directory stays indefinitely and confuses future gc runs and directory listings.

**Detection:** Use `[ -f "$dir/.git" ]`. A registered worktree has a `.git` file (not a directory — it is a plain text file containing the path to the worktree's metadata inside the main `.git/worktrees/` directory). An orphaned directory has no `.git` file. This is the PITFALLS-recommended pattern for worktree detection.

**Why not `git worktree list --porcelain | grep`?** `shell-portability-lint.sh` bans that combination, and it uses substring matching that could produce false positives.

**Where is `.claude/worktrees/`?** Derive it from `git rev-parse --show-toplevel` at runtime. This gives the correct path regardless of where the script is called from.

**Implementation:**
```sh
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WT_BASE="$ROOT/.claude/worktrees"
if [ -d "$WT_BASE" ]; then
  for dir in "$WT_BASE"/*/; do
    [ -d "$dir" ] || continue
    dir="${dir%/}"
    if [ ! -f "$dir/.git" ]; then
      rm -rf "$dir"
      echo "  removed orphaned directory: $dir"
    fi
  done
fi
```

**Safety rules:**
- Only walks directly under `.claude/worktrees/` — no recursion.
- Skips entries that are not directories.
- `rm -rf` is inside the shell script itself (not a direct agent tool call), so it is not subject to the agent block.
- If `rm -rf` fails, continue. (No `set -e` interaction because the whole command is `rm -rf ... && echo ...` — failure just skips the echo.)

## Gap 2 — Remote-only orphaned agent/workflow branches

**Problem:** The workflow system pushes branches under `agent/*` and `claude/*` name prefixes. These branches are NOT always remote-only — `worktree-create.sh:20-23` creates each subagent as a local branch. However, once the workflow completes, gc's existing GONE/NO_UPSTREAM passes remove the local branch and worktree. The remote ref remains because GitHub does not auto-delete branches that were never associated with a PR.

**Safe deletion criteria (ALL must be true):**
1. The remote branch matches `agent/*` or `claude/*` prefix.
2. No local branch with the same name exists (`git rev-parse --verify refs/heads/<name>` fails).
3. No active worktree has that branch checked out (from `git worktree list --porcelain`).
4. The remote branch tip is an ancestor of `origin/main` (`git merge-base --is-ancestor`).

If criteria 1–3 are met but 4 is not: print a warning listing the branch for human review. Do not delete.

**Why not the file-existence check from the first draft?** A file being present on `origin/main` does not mean the branch's changes landed there. The branch may have touched existing files, or main may coincidentally have a file with the same name but different content. The ancestor check is precise and verifiable.

**Implementation:**
```sh
ACTIVE_WT_BRANCHES=$(git worktree list --porcelain | awk '/^branch /{sub(/^branch refs\/heads\//, ""); print}')
for ref in $(git for-each-ref --format='%(refname:short)' 'refs/remotes/origin/agent/*' 'refs/remotes/origin/claude/*' 2>/dev/null); do
  # ref is e.g. "origin/agent/wf_abc"
  short="${ref#origin/}"   # strip leading "origin/"
  # Skip if a local branch of the same name exists
  git rev-parse --verify "refs/heads/$short" >/dev/null 2>&1 && continue
  # Skip if an active worktree has this branch checked out
  echo "$ACTIVE_WT_BRANCHES" | grep -qxF "$short" && continue
  # Only delete if the tip is an ancestor of origin/main (confirmed merged)
  TIP=$(git rev-parse "$ref" 2>/dev/null) || continue
  if git merge-base --is-ancestor "$TIP" origin/main 2>/dev/null; then
    git push origin --delete "$short" >/dev/null 2>&1 \
      && echo "  deleted remote: $short (tip is ancestor of origin/main)"
  else
    echo "  skipped remote: $short (not confirmed merged — delete manually if done: git push origin --delete $short)" >&2
  fi
done
```

**Note on `grep -qxF`:** `-x` (whole-line match) and `-F` (fixed string, not regex) make this safe for branch names with dots and brackets. This is not the banned `worktree list | grep` pattern — the list is already parsed by awk into clean branch names.

## Gap 3 — CLOSED PR branches

**Problem:** When a local branch had a PR that was CLOSED (not merged), the merge-verify loop's `$MERGED != true` path silently skips it with a generic "delete manually if sure" message. The human doesn't know whether the branch was closed intentionally or is just stale.

**Solution:** Add a `gh pr list --head "$b" --state closed` check inside the existing `$MERGED != true` path, guarded by `command -v gh`. If a CLOSED PR is found, print a targeted message:
- Branch name, PR number, PR title
- The exact `git branch -D` command
- An explicit note that this was closed (not merged)

Do not delete. The human makes the call.

**Position in the loop:** This check runs inside the existing `if [ "$MERGED" != true ]` block, replacing the generic skip message for the CLOSED-PR case. A branch that is both `[gone]` and has a CLOSED PR gets the closed-PR message (more informative), not the generic one.

**Implementation (inside the merge-verify loop):**
```sh
if [ "$MERGED" != true ]; then
  CLOSED_PR=""
  if command -v gh >/dev/null 2>&1; then
    CLOSED_PR=$(gh pr list --head "$b" --state closed --json number,title -q '.[0] | "#\(.number) \(.title)"' 2>/dev/null || true)
  fi
  if [ -n "$CLOSED_PR" ]; then
    echo "  closed PR: $b had PR $CLOSED_PR (not merged — delete manually: git branch -D $b)"
  else
    echo "  skipped: $b (remote gone but NOT merged — delete manually if sure: git branch -D $b)"
  fi
  continue
fi
```

## Rename: gc.sh → prune-branches.sh

**Why:** `gc` (garbage collection) is a git term for compacting object storage. This script does something different: it removes stale branches and worktrees. `prune-branches.sh` describes what the script actually does.

**Callers to update:**
- `.claude/hooks/session-start.sh` — the `bash "$ROOT/scripts/gc.sh"` invocation
- `.claude/AI-WORKFLOW.md` — if it references gc.sh
- `.claude/skills/feature/SKILL.md` — the "Worktree cleanup" section at the bottom
- `.claude/skills/queue/SKILL.md` — any gc.sh reference
- `tests/gc.test.sh` → rename to `tests/prune-branches.test.sh`, update the `GC=` variable
- `BACKLOG.md`, `PITFALLS.md`, `V2-TRACEABILITY.md` — update references
- `docs/RECURRING-FINDINGS.md` — if referenced

The old filename is deleted. No compatibility shim or redirect.

## What is NOT changing

- The two existing detection passes (GONE and NO_UPSTREAM) — untouched.
- The merge-verify gate logic — untouched.
- The worktree removal logic for merged branches — untouched.
- The `set -e` behavior — unchanged (new sections handle their own errors without relying on global set -e for the new loops).
