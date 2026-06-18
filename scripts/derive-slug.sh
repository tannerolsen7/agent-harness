#!/usr/bin/env bash
# Derives a shard slug from a branch name.
# Usage: bash scripts/derive-slug.sh [branch-name]
# If no argument is given, uses the current branch from git.
# Output: the slug on stdout, e.g. "feat/my-feature" → "my-feature"
set -e

branch=${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")}
printf '%s' "$branch" \
  | sed 's|^feat/||; s|[^a-zA-Z0-9]|-|g; s|-\+|-|g; s|^-||; s|-$||' \
  | tr '[:upper:]' '[:lower:]'
printf '\n'
