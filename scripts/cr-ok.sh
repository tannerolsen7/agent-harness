#!/usr/bin/env bash
# Write the /cr push sentinel, honestly. The sentinel (.claude/.cr-ok) certifies that /cr ran a
# full branch review at ONE specific committed sha. scripts/pr.sh validates + consumes it before
# opening a PR, and the pre-push hook checks it on the agent (non-interactive) path.
#
# This script does NOT run any checks. The un-forgeable gate is the server-side CI re-run (F6, see
# scripts/ci-verify.sh); the sentinel is a soft, local, one-shot certificate. cr-ok.sh only makes
# the WRITE trustworthy:
#   - self-resolves branch:sha (no args — call it after /cr's review passes)
#   - refuses a dirty tree, so the sentinel can't certify a sha that differs from what you'd push
#   - appends an audit line to .claude/.cr-ok.log (local traceability, gitignored, not a gate)
#
# Running it (not a Write-tool call) sidesteps the sub-agent path allowlist that made the old inline
# `printf > .claude/.cr-ok` brittle: the redirect happens inside this process.
set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "cr-ok: not in a git repo — sentinel not written." >&2; exit 1; }
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
  echo "cr-ok: could not resolve the current branch." >&2; exit 1; }
if [ "$BRANCH" = "HEAD" ]; then
  echo "cr-ok: detached HEAD — check out a branch before certifying /cr." >&2; exit 1
fi
SHA=$(git rev-parse HEAD 2>/dev/null) || {
  echo "cr-ok: could not resolve HEAD sha." >&2; exit 1; }

# Refuse a dirty tree: the sentinel certifies review at $SHA, so uncommitted TRACKED changes would
# make it lie (you'd push $SHA, but your reviewed/working state is something else). Untracked files
# are ignored on purpose — they aren't in HEAD, aren't pushed, and are often local artifacts.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "cr-ok: working tree has uncommitted changes — commit them first, then re-run /cr." >&2
  echo "       (A new commit changes the sha and would invalidate the sentinel anyway.)" >&2
  exit 1
fi

mkdir -p "${REPO_ROOT}/.claude"
SENTINEL="${REPO_ROOT}/.claude/.cr-ok"
printf '%s:%s' "$BRANCH" "$SHA" > "$SENTINEL"

# Append-only audit line: when, and for what branch:sha. Traceability only — never read as a gate.
printf '%s\t%s:%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$SHA" >> "${REPO_ROOT}/.claude/.cr-ok.log"

echo "cr-ok: sentinel written for ${BRANCH}:${SHA}"
