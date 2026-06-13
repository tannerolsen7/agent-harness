#!/bin/sh
# Print the forge host for a git remote URL: github | gitlab | unknown.
# Keeps the harness host-agnostic — callers (e.g. pr.sh) dispatch on the result.
# Usage: scripts/detect-forge.sh [remote-url]   (defaults to origin's URL)
#
# Self-hosted hosts that don't carry "github"/"gitlab" in the URL return "unknown";
# callers should let the operator override (e.g. PR_FORGE=github|gitlab).
url="${1:-}"
[ -z "$url" ] && url=$(git remote get-url origin 2>/dev/null || true)

case "$url" in
  *github.com*|*github.*) echo github ;;
  *gitlab.com*|*gitlab.*) echo gitlab ;;
  *) echo unknown ;;
esac
