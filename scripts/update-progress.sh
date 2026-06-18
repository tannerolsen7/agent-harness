#!/usr/bin/env bash
# Update the mechanical parts of harness-progress.html:
#   - Today's date (top-right header)
#   - PR count (from git log merge commits)
#   - Progress bar width (linear scale: 46 merged PRs = ~60%; total ~76 expected)
#
# Run this after any PR merges. Content cards (Done / Steps) still need a
# human or Claude to update when new work lands.

set -euo pipefail

HTML="$(cd "$(dirname "$0")/.." && pwd)/harness-progress.html"

if [ ! -f "$HTML" ]; then
  echo "error: harness-progress.html not found at $HTML" >&2
  exit 1
fi

# Count merged PRs from git log.
PR_COUNT=$(git log --oneline | grep -c "Merge pull request" || true)

# Linear scale: 0 PRs = 0%, ~76 PRs = 100%. Clamp at 99% until explicitly done.
TOTAL=76
PCT=$(( PR_COUNT * 100 / TOTAL ))
[ "$PCT" -gt 99 ] && PCT=99

# Date formatted as "June 17, 2026" (macOS-compatible).
DATE=$(date +"%B %-d, %Y")

# --- Update date ---
sed -i '' "s|<div class=\"date\">[^<]*</div>|<div class=\"date\">${DATE}</div>|" "$HTML"

# --- Update PR count label ---
sed -i '' "s|<div class=\"progress-label\">[0-9]* PRs merged</div>|<div class=\"progress-label\">${PR_COUNT} PRs merged</div>|" "$HTML"

# --- Update progress bar width ---
sed -i '' "s|style=\"width:[0-9]*%\"|style=\"width:${PCT}%\"|" "$HTML"

echo "harness-progress.html updated: ${PR_COUNT} PRs merged, ${PCT}% progress, date: ${DATE}"
