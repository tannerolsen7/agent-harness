#!/bin/bash
# Open a PR. Enforces that /cr (full branch review) ran before the PR is created.
# In non-interactive mode: validates .claude/.cr-ok sentinel (branch:sha).
# In interactive mode: prompts the user.
# Any additional arguments are passed through to gh pr create.
set -e

SENTINEL=".claude/.cr-ok"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
  echo "PR aborted: could not determine current branch." >&2
  exit 1
}
HEAD_SHA=$(git rev-parse HEAD 2>/dev/null) || {
  echo "PR aborted: could not read HEAD sha." >&2
  exit 1
}
EXPECTED="${CURRENT_BRANCH}:${HEAD_SHA}"

if [ -t 0 ]; then
  printf "\nHave you run /cr (full branch review)? [y/N] " > /dev/tty
  read -r confirm < /dev/tty
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "PR aborted: run /cr before opening a PR." >&2
    exit 1
  fi
else
  if [ ! -f "$SENTINEL" ]; then
    echo "PR aborted: no /cr sentinel found. Run /cr before opening a PR." >&2
    exit 1
  fi
  CONSUMED="${SENTINEL}.consumed.$$"
  trap 'rm -f "$CONSUMED"' EXIT INT TERM
  if ! mv "$SENTINEL" "$CONSUMED" 2>/dev/null; then
    echo "PR aborted: /cr sentinel was consumed by another process. Re-run /cr." >&2
    exit 1
  fi
  ACTUAL=$(cat "$CONSUMED")
  if [ -z "$ACTUAL" ] || [ "$ACTUAL" != "$EXPECTED" ]; then
    mv "$CONSUMED" "$SENTINEL" 2>/dev/null || true
    BRANCH_SAFE=$(printf '%s' "$CURRENT_BRANCH" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    ACTUAL_SAFE=$(printf '%s' "$ACTUAL" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    echo "PR aborted: /cr sentinel is stale (expected ${BRANCH_SAFE}:<sha>, got ${ACTUAL_SAFE}). Re-run /cr after your last commit." >&2
    exit 1
  fi
  rm -f "$CONSUMED"
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "PR aborted: gh CLI not found. Install with: brew install gh && gh auth login" >&2
  exit 1
fi

# Guard: branch must exist on remote before gh pr create; otherwise gh gives a cryptic error.
REMOTE=$(git config --get branch."$CURRENT_BRANCH".remote 2>/dev/null || echo "origin")
if ! git ls-remote --exit-code "$REMOTE" "$CURRENT_BRANCH" >/dev/null 2>&1; then
  echo "PR aborted: branch '$CURRENT_BRANCH' not found on remote '$REMOTE'. Push first: git push -u $REMOTE $CURRENT_BRANCH" >&2
  exit 1
fi

gh pr create "$@"
