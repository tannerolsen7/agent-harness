#!/usr/bin/env bash
# Update the mechanical parts of harness-progress.html:
#   - Today's date (top-right header)
#   - PR count (merged PRs from git log on main)
#   - Progress bar width (linear scale toward TOTAL PRs; clamps at 99%)
#
# Run this after any PR merges, or wire it to SessionStart in settings.json.
# Content cards (Done / Steps to finish) still need a human or Claude to
# any new-work entries here need a human or Claude to maintain.

set -euo pipefail

# Clear inherited git env so hooks don't point git at the wrong object store.
# See: reference-git-hook-env-pollutes-tests (project memory / run-tests.sh).
unset GIT_DIR GIT_WORK_TREE

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Write the HTML into whatever worktree is checked out on main, not necessarily
# the repo root. The main worktree is often on a feature branch; writing there
# would create an uncommitted change on that branch.
HTML=""
_wt=""
while IFS= read -r _line; do
  case "$_line" in
    "worktree "*) _wt="${_line#worktree }" ;;
    "branch refs/heads/main") HTML="$_wt/harness-progress.html" ;;
  esac
done < <(git -C "$REPO_ROOT" worktree list --porcelain)
unset _wt _line

if [ -z "$HTML" ]; then
  # No worktree is on main — fall back to repo root.
  HTML="$REPO_ROOT/harness-progress.html"
fi

if [ ! -f "$HTML" ]; then
  echo "error: harness-progress.html not found at $HTML" >&2
  exit 1
fi

# Read old PR count before updating so the status line can show what changed.
OLD_PR=$(grep -oE '[0-9]+ PRs merged' "$HTML" | head -1 | grep -oE '^[0-9]+' || echo "?")

# Count merged PRs from main. Uses GitHub's "Merge pull request" merge-commit
# only "Merge pull request" commits count — squash and rebase merges are excluded. grep -c exits 1
# when count is zero; handle that separately from a git failure so a broken
# repo surfaces an error instead of silently resetting the bar to 0%.
if ! GIT_LOG=$(git log main --oneline 2>&1); then
  echo "error: git log main failed: $GIT_LOG" >&2
  exit 1
fi
PR_COUNT=$(echo "$GIT_LOG" | grep -c "Merge pull request" || true)

# Linear scale toward TOTAL. Update TOTAL when the V2 roadmap changes.
# Basis: Step 0 + Phases 0–4 estimated at ~76 PRs total (audit June 2026).
# Clamp at 99%: reaching 100% requires a human to declare the project done.
TOTAL=76
PCT=$(( PR_COUNT * 100 / TOTAL ))
[ "$PCT" -gt 99 ] && PCT=99

DATE=$(date +"%B %-d, %Y")
TIME=$(date +"%-I:%M %p")

# Build what-changed summary for the status line.
if [ "$OLD_PR" = "$PR_COUNT" ]; then
  PR_CHANGE="${PR_COUNT} PRs (no change)"
elif [ "$OLD_PR" = "?" ]; then
  PR_CHANGE="${PR_COUNT} PRs (first run)"
else
  PR_CHANGE="${OLD_PR}→${PR_COUNT} PRs"
fi
STATUS="Last auto-updated: ${DATE} at ${TIME} · ${PR_CHANGE}"

# Write all substitutions in one pass, atomically: sed into a temp file,
# then mv. This prevents a partial update if the process dies mid-way.
# Single sed with multiple -e expressions is portable (BSD + GNU).
# The auto-update-status substitution is a no-op when the element is absent,
# so old HTML files without the element are safely skipped.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

sed \
  -e "s|<div class=\"date\">[^<]*</div>|<div class=\"date\">${DATE}</div>|" \
  -e "s|<div class=\"progress-label\">[0-9]* PRs merged</div>|<div class=\"progress-label\">${PR_COUNT} PRs merged</div>|" \
  -e "s|style=\"width:[0-9]*%\"|style=\"width:${PCT}%\"|" \
  -e "s|<div class=\"auto-update-status\">[^<]*</div>|<div class=\"auto-update-status\">${STATUS}</div>|" \
  "$HTML" > "$TMP"
mv "$TMP" "$HTML"

echo "harness-progress.html updated: ${PR_COUNT} PRs merged, ${PCT}% progress, date: ${DATE}"

# Refresh the activity dashboard alongside the progress dashboard.
bash "$(git rev-parse --show-toplevel)/scripts/activity-report.sh" || true
