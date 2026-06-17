#!/usr/bin/env bash
# Write the /design before-coding sentinel, honestly. The sentinel (.claude/.design-confirmed)
# certifies that the design was confirmed (Design Questions sheet → adversarial grill →
# schema/mockup approval where applicable → human sign-off) at ONE specific committed sha,
# BEFORE any feature code. /feature reads + validates it at the top of its implement step and
# refuses to start coding if it is absent or stale. Mirrors scripts/cr-ok.sh exactly — same
# branch:sha format, same dirty-tree refusal, same append-only audit log.
#
# This script does NOT run the design steps or any check. The design work (sheet, grill, schema
# and mockup approvals) is human-gated upstream; design-confirm.sh only makes the WRITE trustworthy:
#   - self-resolves branch:sha (no args — call it once the human has confirmed the design)
#   - refuses a dirty tree, so the sentinel can't certify a sha that differs from what gets coded on
#   - appends an audit line to .claude/.design-confirmed.log (local traceability, gitignored, not a gate)
#
# Running it (not a Write-tool call) sidesteps the sub-agent path allowlist that made inline
# `printf > .claude/.design-confirmed` brittle: the redirect happens inside this process.
set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "design-confirm: not in a git repo — sentinel not written." >&2; exit 1; }
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
  echo "design-confirm: could not resolve the current branch." >&2; exit 1; }
if [ "$BRANCH" = "HEAD" ]; then
  echo "design-confirm: detached HEAD — check out a branch before confirming the design." >&2; exit 1
fi
SHA=$(git rev-parse HEAD 2>/dev/null) || {
  echo "design-confirm: could not resolve HEAD sha." >&2; exit 1; }

# Refuse a dirty tree: the sentinel certifies the design confirmed at $SHA, so uncommitted TRACKED
# changes would make it lie (coding would start from $SHA, but your confirmed/working state is
# something else). Commit the design artifacts (sheet, contract, schema, mockup) first, then
# confirm. Untracked files are ignored on purpose — they aren't in HEAD and are often local scratch.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "design-confirm: working tree has uncommitted changes — commit the design artifacts first, then re-run." >&2
  echo "       (A new commit changes the sha and would invalidate the sentinel anyway.)" >&2
  exit 1
fi

mkdir -p "${REPO_ROOT}/.claude"
SENTINEL="${REPO_ROOT}/.claude/.design-confirmed"
printf '%s:%s' "$BRANCH" "$SHA" > "$SENTINEL"

# Append-only audit line: when, and for what branch:sha. Traceability only — never read as a gate,
# so a failed append must NOT fail an otherwise-good sentinel write (warn, don't abort).
if ! printf '%s\t%s:%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$SHA" >> "${REPO_ROOT}/.claude/.design-confirmed.log" 2>/dev/null; then
  echo "design-confirm: warning: could not append to the audit log (the sentinel was still written)." >&2
fi

echo "design-confirm: sentinel written for ${BRANCH}:${SHA}"
