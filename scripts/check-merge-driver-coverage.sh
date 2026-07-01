#!/bin/bash
# scripts/check-merge-driver-coverage.sh — is a merge between two refs fully covered by
# registered .gitattributes merge strategies?
#
# Usage: check-merge-driver-coverage.sh <merge-base> <ref-untrusted> <ref-trusted>
#
# <ref-trusted> MUST be the base/main side of the merge, never the other branch. Coverage is
# resolved against <ref-trusted>'s OWN .gitattributes (via `git check-attr --source`), not the
# merged working tree. Reading the merged tree would let <ref-untrusted> grant itself coverage
# by adding its own `.gitattributes` entry in the same change — this script exists specifically
# to rule that out, so the trust direction is not optional.
#
# Only files BOTH refs changed since <merge-base> went through an actual merge decision — files
# only one side touched keep that side's already-reviewed content unchanged. A merge is "fully
# covered" when every such file has one of a known, explicit set of merge strategies (`union`,
# `ours`, `tasks-higher-state`) — not just "anything git check-attr reports" — and, for any
# strategy other than the driver-free `union`, that the driver is actually registered in
# .git/config. An attribute naming an unregistered custom driver did not necessarily get the
# resolution it claims; treating it as covered anyway would be trusting an assumption this
# script can't verify.
#
# Exit 0: fully covered. Exit 1: not covered — prints the reason to stderr.
# Must run inside a worktree that can resolve all three revisions (e.g. after fetching both
# refs), and .git/config must already have any custom drivers registered
# (scripts/register-merge-drivers.sh does this at `npm install` time).
set -u

MERGE_BASE="${1:?usage: check-merge-driver-coverage.sh <merge-base> <ref-untrusted> <ref-trusted>}"
REF_UNTRUSTED="${2:?usage: check-merge-driver-coverage.sh <merge-base> <ref-untrusted> <ref-trusted>}"
REF_TRUSTED="${3:?usage: check-merge-driver-coverage.sh <merge-base> <ref-untrusted> <ref-trusted>}"

CHANGED_UNTRUSTED=$(git diff --name-only "$MERGE_BASE" "$REF_UNTRUSTED" 2>/dev/null | sort -u)
CHANGED_TRUSTED=$(git diff --name-only "$MERGE_BASE" "$REF_TRUSTED" 2>/dev/null | sort -u)

# Files both sides changed — the only ones a merge decision actually had to make.
BOTH_CHANGED=$(comm -12 <(printf '%s\n' "$CHANGED_UNTRUSTED") <(printf '%s\n' "$CHANGED_TRUSTED"))

[ -z "$BOTH_CHANGED" ] && exit 0

ATTRS=$(printf '%s\n' "$BOTH_CHANGED" | git check-attr --source="$REF_TRUSTED" --stdin merge)

UNCOVERED=false
while IFS= read -r line; do
  [ -z "$line" ] && continue
  strategy="${line##*: merge: }"
  case "$strategy" in
    union)
      ;; # built into core git — no driver registration to verify
    ours|tasks-higher-state)
      if [ -z "$(git config --get "merge.${strategy}.driver" 2>/dev/null)" ]; then
        printf '%s (driver "%s" not registered in .git/config)\n' "${line%%: merge: *}" "$strategy" >&2
        UNCOVERED=true
      fi
      ;;
    *)
      printf '%s (no recognized merge strategy: "%s")\n' "${line%%: merge: *}" "$strategy" >&2
      UNCOVERED=true
      ;;
  esac
done <<ATTRS_EOF
$ATTRS
ATTRS_EOF

[ "$UNCOVERED" = true ] && exit 1

exit 0
