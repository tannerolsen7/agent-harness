#!/bin/bash
# scripts/sync-open-prs.sh — rebase open PRs that conflict with main.
# Runs at session start and when a PR merges. Always exits 0 — must never block either trigger.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FORGE=$(sh "$ROOT/scripts/detect-forge.sh" 2>/dev/null || echo unknown)

# Pick the CLI based on forge type. For unknown forge, try gh then glab.
case "$FORGE" in
  github) CLI=gh ;;
  gitlab) CLI=glab ;;
  *)
    if command -v gh >/dev/null 2>&1; then
      CLI=gh
    elif command -v glab >/dev/null 2>&1; then
      CLI=glab
    else
      echo "forge CLI unavailable — skipping PR sync"
      exit 0
    fi
    ;;
esac

# Second check: forge is known but the CLI isn't installed (e.g. forge=github, gh missing).
if ! command -v "$CLI" >/dev/null 2>&1; then
  echo "forge CLI unavailable — skipping PR sync"
  exit 0
fi

# GitLab MR field names differ from GitHub's — the JSON mapping is not yet implemented.
if [ "$CLI" = glab ]; then
  echo "GitLab PR sync not yet supported — skipping"
  exit 0
fi

# Default branch — read from the remote HEAD symref; fall back to "main".
DEFAULT_BRANCH=$(git -C "$ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
[ -z "${DEFAULT_BRANCH:-}" ] && DEFAULT_BRANCH=main

PRS=$(gh pr list --json number,headRefName,baseRefName,mergeable,isDraft 2>/dev/null || echo "[]")

COUNT=$(printf '%s' "$PRS" | jq 'length' 2>/dev/null || echo 0)
if [ "$COUNT" -eq 0 ]; then
  echo "no open PRs to sync"
  exit 0
fi

# Write PR list to a temp file so the while loop can read it without a subshell pipe.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT INT TERM
printf '%s' "$PRS" | jq -c '.[]' > "$TMP"

while IFS= read -r pr; do
  number=$(printf '%s' "$pr" | jq -r '.number')
  head=$(printf '%s' "$pr" | jq -r '.headRefName')
  base=$(printf '%s' "$pr" | jq -r '.baseRefName')
  mergeable=$(printf '%s' "$pr" | jq -r '.mergeable')
  is_draft=$(printf '%s' "$pr" | jq -r '.isDraft')

  [ "$is_draft" = "true" ] && continue
  [ "$base" != "$DEFAULT_BRANCH" ] && continue
  [ "$mergeable" != "CONFLICTING" ] && continue

  if gh pr update-branch --rebase "$number" >/dev/null 2>&1; then
    echo "updated #${number} (${head})"
  else
    echo "failed #${number} (${head}) — rebase manually"
  fi
done < "$TMP"

exit 0
