#!/usr/bin/env bash
# Routing-assertion gate — MERGE-TIME half (R4-D32 #3). Host-agnostic, project-agnostic.
#
# If a change touches DB-safety-relevant paths/content (declared per-project in
# .claude/routing.json), it must have gone through the project's DB-safety skill — evidenced
# by a CI-VISIBLE commit trailer ("<requiredTrailer>: <skill>") on the branch. Gitignored
# sentinels like .cr-ok are invisible to CI (see docs/ci-gate.md), so the marker is a commit
# trailer, which lives in the history CI can read. The run-time twin (a PreToolUse hook —
# docs/routing-gate.md) is the stronger half that stops the damage live; this is the
# merge-time backstop + the mis-route signal.
#
# Inert when .claude/routing.json is absent (project has no DB / opted out).
# No jq dependency — config is read with node (always present in an npm repo).
# Test-only overrides: ROUTING_CONFIG, ROUTING_BASE, ROUTING_CHANGED, ROUTING_DIFF, ROUTING_TRAILERS.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CFG="${ROUTING_CONFIG:-$ROOT/.claude/routing.json}"

[ -f "$CFG" ] || { echo "check-routing: no routing config ($CFG) — routing-assertion inert (project opted out)."; exit 0; }
command -v node >/dev/null 2>&1 || { echo "check-routing: node required to read $CFG — BLOCKING (fail-closed)." >&2; exit 2; }

read_arr() { node -e "const c=require(process.argv[1]);(c[process.argv[2]]||[]).forEach(x=>console.log(x))" "$CFG" "$1"; }
TRAILER=$(node -e "const c=require(process.argv[1]);process.stdout.write(String(c.requiredTrailer||'DB-Safety'))" "$CFG")

if [ -n "${ROUTING_CHANGED+x}" ] && [ -n "${ROUTING_DIFF+x}" ] && [ -n "${ROUTING_TRAILERS+x}" ]; then
  changed="$ROUTING_CHANGED"; diffbody="$ROUTING_DIFF"; trailers="$ROUTING_TRAILERS"
else
  BASE="${ROUTING_BASE:-origin/main}"
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || BASE=main
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || { echo "check-routing: base ref not found ($BASE) — skipping (nothing to diff against)."; exit 0; }
  changed=$(git diff --name-only "$BASE"...HEAD)
  diffbody=$(git diff "$BASE"...HEAD)
  trailers=$(git log "$BASE"..HEAD --format='%B')
fi

hit=""
while IFS= read -r pat; do
  [ -z "$pat" ] && continue
  printf '%s\n' "$changed" | grep -qE "$pat" && { hit="path:$pat"; break; }
done < <(read_arr highRiskPathPatterns)

if [ -z "$hit" ]; then
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    printf '%s\n' "$diffbody" | grep -qiE "$pat" && { hit="content:$pat"; break; }
  done < <(read_arr highRiskContentPatterns)
fi

if [ -z "$hit" ]; then
  echo "check-routing: no high-risk changes — OK."
  exit 0
fi

if printf '%s\n' "$trailers" | grep -qE "^[[:space:]]*${TRAILER}:[[:space:]]*[^[:space:]]"; then
  echo "check-routing: high-risk change ($hit) — '${TRAILER}:' trailer present. OK."
  exit 0
fi

{
  echo "check-routing: BLOCKED — high-risk change ($hit) with no '${TRAILER}:' commit trailer."
  echo "  A change touching DB-safety-relevant paths/content must go through the project's DB-safety skill."
  echo "  After it reviews the change, add a trailer to a commit on this branch:  ${TRAILER}: <skill>"
  echo "  Mis-route signal: sentinel-expected-by-diff-content missing ($hit)."
} >&2
exit 1
