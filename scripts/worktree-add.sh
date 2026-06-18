#!/bin/sh
# Create a git worktree, provision its env files, and assert the gate machinery is
# live (worktree G1 — fail-closed). Usage: scripts/worktree-add.sh <path> <branch>
#
# UNATTENDED=1 + a per-project local-env adapter (scripts/gen-local-env.sh):
#   write local/ephemeral backend credentials, fail-closed (no prod fallback).
#   Without the adapter there are no local creds to write — fall through to symlink.
# Default: symlink the repo-root env files into the worktree (human session).
#
# Project-agnostic: a project that needs no env files simply has none to symlink.
set -e

WORKTREE_PATH="${1:?Usage: scripts/worktree-add.sh <path> <branch>}"
BRANCH="${2:?Usage: scripts/worktree-add.sh <path> <branch>}"
REPO_ROOT=$(git rev-parse --show-toplevel)

# Reject a branch name git would read as a flag (e.g. "-f", "--detach").
case "$BRANCH" in -*) echo "worktree-add: refusing unsafe branch name '$BRANCH'" >&2; exit 1 ;; esac

# Idempotent: if the worktree directory already exists, skip creation.
# On resume, the Workflow re-enters Setup and may call this script again —
# the guard below makes re-running safe. Worktrees have a .git FILE (not
# a directory), which is the reliable way to detect a live worktree vs.
# a stale or unrelated directory.
if [ -d "$WORKTREE_PATH" ] && [ -f "$WORKTREE_PATH/.git" ]; then
  echo "Worktree already exists at $WORKTREE_PATH on branch $BRANCH — skipping creation."
  exit 0
fi

# Create the branch if it doesn't exist yet (so a NEW feat/<slug> works — this is how /queue
# starts each task), otherwise check out the existing branch into the worktree. Pin the new
# branch to an explicit commit-ish so it doesn't silently start from whatever HEAD the *calling*
# worktree happens to be on (run from the main worktree → branches off the current main HEAD).
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH"
else
  git worktree add -b "$BRANCH" "$WORKTREE_PATH" HEAD
fi

# --- TASKS.md: mark task in-progress for feat/<slug> branches ---
# Extract slug from branch name (only feat/* branches map to TASKS.md slugs).
TASK_SLUG=""
case "$BRANCH" in feat/*) TASK_SLUG="${BRANCH#feat/}" ;; esac
if [ -n "$TASK_SLUG" ] && [ -f "$REPO_ROOT/TASKS.md" ]; then
  TASK_SLUG_ESCAPED=$(printf '%s' "$TASK_SLUG" | sed 's/[.[\*^$]/\\&/g')
  TASK_SLUG_LINE=$(grep -n "^  Slug: ${TASK_SLUG_ESCAPED}$" "$REPO_ROOT/TASKS.md" | head -1 | cut -d: -f1) || true
  if [ -n "$TASK_SLUG_LINE" ]; then
    # Walk back from the slug line to find the nearest preceding unchecked task header.
    TASK_HEADER_LINE=$(awk -v lim="$TASK_SLUG_LINE" \
      'NR <= lim && /^- \[ \]/ { last=NR } END { print last+0 }' "$REPO_ROOT/TASKS.md")
    if [ "${TASK_HEADER_LINE:-0}" -gt 0 ] 2>/dev/null; then
      TASK_TMP="$(mktemp)"
      trap 'rm -f "$TASK_TMP"' EXIT
      if sed "${TASK_HEADER_LINE}s/^- \[ \]/- [~]/" "$REPO_ROOT/TASKS.md" > "$TASK_TMP" \
          && mv "$TASK_TMP" "$REPO_ROOT/TASKS.md"; then
        echo "worktree-add: marked '${TASK_SLUG}' as in-progress in TASKS.md"
      else
        echo "worktree-add: WARNING: could not update TASKS.md for '${TASK_SLUG}'" >&2
      fi
    fi
  fi
fi

# --- env provisioning (adapter) ---
if [ "${UNATTENDED:-}" = "1" ] && [ -x "$REPO_ROOT/scripts/gen-local-env.sh" ]; then
  "$REPO_ROOT/scripts/gen-local-env.sh" "$WORKTREE_PATH" || {
    echo "UNATTENDED=1: local stack unavailable — removing uncredentialed worktree. Start your project's local stack first." >&2
    git worktree remove --force "$WORKTREE_PATH"
    exit 1
  }
else
  linked=0
  for envname in .env.local .env.test .env; do
    if [ -f "$REPO_ROOT/$envname" ] && [ ! -e "$WORKTREE_PATH/$envname" ]; then
      ln -sf "$REPO_ROOT/$envname" "$WORKTREE_PATH/$envname"
      echo "Symlinked $envname into $WORKTREE_PATH"
      linked=1
    fi
  done
  [ "$linked" = 0 ] && echo "No env files at repo root to symlink (fine if this project needs none)."
fi

# --- G1: the gate machinery must be live in the new worktree, or refuse it ---
if [ -f "$WORKTREE_PATH/package.json" ] && [ -d "$WORKTREE_PATH/.husky" ]; then
  ( cd "$WORKTREE_PATH" && npm install ) || {
    echo "worktree-add: npm install failed — gates not provable; removing worktree (fail-closed)." >&2
    git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    exit 1
  }
  "$REPO_ROOT/scripts/assert-husky-shim.sh" "$WORKTREE_PATH" || {
    echo "worktree-add: gate shim missing after install; removing worktree (fail-closed)." >&2
    git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    exit 1
  }
  echo "Gates live in $WORKTREE_PATH."
fi
