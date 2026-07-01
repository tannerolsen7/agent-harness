#!/bin/bash
# scripts/check-merge-driver-coverage.sh — is a merge between two refs fully covered by
# registered .gitattributes merge strategies?
#
# Usage: check-merge-driver-coverage.sh <merge-base> <ref-a> <ref-b>
#
# Only files BOTH refs changed since <merge-base> went through an actual merge decision —
# files only one side touched keep that side's already-reviewed content unchanged. A merge
# is "fully covered" when every such file has a merge= attribute in .gitattributes (checked
# via `git check-attr`, so it reflects whatever driver — union, ours, or a custom script —
# is actually registered, not just a hardcoded file list).
#
# Exit 0: fully covered — every file both sides changed has a registered merge strategy.
# Exit 1: not covered — prints the uncovered file paths to stderr, one per line.
# Must run inside a worktree that can resolve all three revisions (e.g. after fetching both
# refs), and .git/config must already have any custom drivers registered
# (scripts/register-merge-drivers.sh does this at `npm install` time).
set -u

MERGE_BASE="${1:?usage: check-merge-driver-coverage.sh <merge-base> <ref-a> <ref-b>}"
REF_A="${2:?usage: check-merge-driver-coverage.sh <merge-base> <ref-a> <ref-b>}"
REF_B="${3:?usage: check-merge-driver-coverage.sh <merge-base> <ref-a> <ref-b>}"

CHANGED_A=$(git diff --name-only "$MERGE_BASE" "$REF_A" 2>/dev/null | sort -u)
CHANGED_B=$(git diff --name-only "$MERGE_BASE" "$REF_B" 2>/dev/null | sort -u)

# Files both sides changed — the only ones a merge decision actually had to make.
BOTH_CHANGED=$(comm -12 <(printf '%s\n' "$CHANGED_A") <(printf '%s\n' "$CHANGED_B"))

[ -z "$BOTH_CHANGED" ] && exit 0

UNCOVERED=$(printf '%s\n' "$BOTH_CHANGED" | git check-attr --stdin merge | grep ': merge: unspecified$')

if [ -n "$UNCOVERED" ]; then
  printf '%s\n' "$UNCOVERED" | sed 's/: merge: unspecified$//' >&2
  exit 1
fi

exit 0
