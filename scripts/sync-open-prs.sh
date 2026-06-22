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

if ! command -v "$CLI" >/dev/null 2>&1; then
  echo "forge CLI unavailable — skipping PR sync"
  exit 0
fi

# Default branch — read from the remote HEAD symref; fall back to "main".
DEFAULT_BRANCH=$(git -C "$ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
[ -z "${DEFAULT_BRANCH:-}" ] && DEFAULT_BRANCH=main

# Fetch open PRs as JSON.
if [ "$CLI" = gh ]; then
  PRS=$(gh pr list --json number,headRefName,baseRefName,mergeable,isDraft 2>/dev/null || echo "[]")
else
  PRS=$(glab mr list --output json 2>/dev/null || echo "[]")
fi

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
  isDraft=$(printf '%s' "$pr" | jq -r '.isDraft')

  [ "$isDraft" = "true" ] && continue
  [ "$base" != "$DEFAULT_BRANCH" ] && continue
  [ "$mergeable" != "CONFLICTING" ] && continue

  if [ "$CLI" = gh ]; then
    if gh pr update-branch --rebase "$number" >/dev/null 2>&1; then
      echo "updated #${number} (${head})"
    else
      echo "failed #${number} (${head}) — rebase manually"
    fi
  else
    if glab mr rebase "$number" >/dev/null 2>&1; then
      echo "updated #${number} (${head})"
    else
      echo "failed #${number} (${head}) — rebase manually"
    fi
  fi
done < "$TMP"

exit 0
