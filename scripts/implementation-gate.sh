#!/usr/bin/env bash
# The /feature implementation gate (R4-D4): coding may not start unless the
# design was confirmed through the real gate. This logic used to be inline bash
# in .claude/skills/feature/SKILL.md that agents copy-pasted each run — a
# transcription slip there would fail open silently, so the gate now lives here
# where lint and tests cover it.
#
# The sentinel (.claude/.design-confirmed, written only by scripts/design-confirm.sh)
# records "branch:sha" at design confirmation. The gate passes when the current
# branch matches and the sentinel sha is an ancestor of HEAD — tolerating
# pre-coding commits (spec, plan, grill docs) without demanding re-confirmation.
#
# Exit 0: gate passed, coding may start. Non-zero: stop, surface the remediation,
# and never write the sentinel by hand to get past this — a design not confirmed
# through the gate is unconfirmed.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "implementation-gate: not in a git repo." >&2; exit 1; }
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "HEAD" ]; then
  echo "implementation-gate: detached HEAD — check out a branch before coding." >&2
  exit 1
fi
ACTUAL=$(cat "$ROOT/.claude/.design-confirmed" 2>/dev/null || true)
if [ -z "$ACTUAL" ]; then
  echo "implementation-gate: no design-confirmed sentinel found. Coding refuses to start." >&2
  echo "         Run /design contract's before-coding gate and get human sign-off first," >&2
  echo "         then: bash scripts/design-confirm.sh" >&2
  exit 1
fi
case "$ACTUAL" in
  *:*) ;;
  *)
    echo "implementation-gate: sentinel is malformed (expected branch:sha, got '${ACTUAL}')." >&2
    echo "         Re-run: bash scripts/design-confirm.sh (after human sign-off)." >&2
    exit 1
    ;;
esac
SENTINEL_BRANCH="${ACTUAL%%:*}"
SENTINEL_SHA="${ACTUAL##*:}"
# The sha field must be a full hex commit id. A ref name here (e.g. a branch)
# would resolve to whatever that ref points at NOW — a moving target that is
# always an ancestor of itself, so a malformed sentinel would pass forever.
if ! printf '%s\n' "$SENTINEL_SHA" | grep -qE '^[0-9a-f]{40}$'; then
  echo "implementation-gate: sentinel sha field ('${SENTINEL_SHA}') is not a full commit sha." >&2
  echo "         Re-run: bash scripts/design-confirm.sh (after human sign-off)." >&2
  exit 1
fi
if [ "$SENTINEL_BRANCH" != "$BRANCH" ]; then
  echo "implementation-gate: sentinel is for branch '${SENTINEL_BRANCH}', currently on '${BRANCH}'." >&2
  echo "         Re-confirm the design on this branch: bash scripts/design-confirm.sh" >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$SENTINEL_SHA" HEAD 2>/dev/null; then
  echo "implementation-gate: sentinel sha (${SENTINEL_SHA}) is not an ancestor of HEAD." >&2
  echo "         Design was confirmed before current branch history — re-run: bash scripts/design-confirm.sh" >&2
  exit 1
fi
echo "implementation-gate: passed for ${BRANCH} (design confirmed at ${SENTINEL_SHA})."
