#!/usr/bin/env bash
# Routing-assertion gate — MERGE-TIME half (R4-D32 #3). Host-agnostic, project-agnostic.
#
# If a change touches DB-safety-relevant paths/content (declared per-project in
# .claude/routing.json), it must have gone through the project's DB-safety skill — evidenced
# by a CI-VISIBLE commit trailer ("<requiredTrailer>: <skill>") on the branch. Gitignored
# sentinels like .cr-ok are invisible to CI (docs/ci-gate.md), so the marker is a commit
# trailer, in the history CI can read. The run-time twin picture is in docs/routing-gate.md.
#
# FAIL-CLOSED on every error path (a silent skip would let an unrouted high-risk change merge):
# missing node, malformed config, invalid config pattern, or an unresolvable base ref all BLOCK.
# Inert ONLY when .claude/routing.json is absent (project has no DB / opted out).
# No jq dependency — config read via node. Structured trailers only (git interpret-trailers).
# Test-only overrides: ROUTING_CONFIG, ROUTING_BASE, ROUTING_CHANGED, ROUTING_DIFF, ROUTING_TRAILERS.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CFG="${ROUTING_CONFIG:-$ROOT/.claude/routing.json}"

[ -f "$CFG" ] || { echo "check-routing: no routing config ($CFG) — routing-assertion inert (project opted out)."; exit 0; }
command -v node >/dev/null 2>&1 || { echo "check-routing: node required to read $CFG — BLOCKING (fail-closed)." >&2; exit 2; }

# Validate config up-front, fail-closed. (An error inside the process-substitutions below would
# NOT propagate out under set -e — so a malformed config could silently pass. Catch it here.)
node -e 'try{JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))}catch(e){console.error("check-routing: invalid routing.json — "+e.message);process.exit(2)}' "$CFG" || exit 2

read_arr() { node -e "const c=require(process.argv[1]);(c[process.argv[2]]||[]).forEach(x=>console.log(x))" "$CFG" "$1"; }
TRAILER=$(node -e "const c=require(process.argv[1]);process.stdout.write(String(c.requiredTrailer||'DB-Safety'))" "$CFG")

if [ -n "${ROUTING_CHANGED+x}" ] && [ -n "${ROUTING_DIFF+x}" ] && [ -n "${ROUTING_TRAILERS+x}" ]; then
  changed="$ROUTING_CHANGED"; diffbody="$ROUTING_DIFF"; trailers_src="override"
else
  # Prefer a CI-provided base branch; fail closed if none resolves (config is present, so a
  # missing base is a CI misconfig, not an opt-out — never silently skip).
  BASE="${ROUTING_BASE:-}"
  [ -z "$BASE" ] && [ -n "${GITHUB_BASE_REF:-}" ] && BASE="origin/$GITHUB_BASE_REF"
  [ -z "$BASE" ] && [ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" ] && BASE="origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
  [ -z "$BASE" ] && BASE="origin/main"
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || BASE=main
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || {
    echo "check-routing: base ref not found ($BASE) but routing.json is present — BLOCKING (fail-closed)." >&2
    echo "  Ensure CI fetches the base branch (fetch-depth/GIT_DEPTH 0 + 'git fetch origin <base>')." >&2
    exit 2
  }
  changed=$(git diff --name-only "$BASE"...HEAD)
  diffbody=$(git diff "$BASE"...HEAD)
  trailers_src="$BASE"
fi

# Detect a high-risk change (path patterns case-sensitive, content patterns case-insensitive).
# Fail-closed on an invalid config pattern (grep exit >= 2).
HIT=""
match_any() {  # match_any <text> <config-array-key> <grep-flags>
  local text="$1" key="$2" flags="$3" pat rc
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    rc=0
    printf '%s\n' "$text" | grep -q"${flags}"E "$pat" || rc=$?
    if [ "$rc" -eq 0 ]; then HIT="$key:$pat"; return 0
    elif [ "$rc" -ge 2 ]; then
      echo "check-routing: invalid pattern in routing.json ($key: '$pat') — BLOCKING (fail-closed)." >&2
      exit 2
    fi
  done < <(read_arr "$key")
  return 1
}
match_any "$changed" highRiskPathPatterns "" || true
[ -z "$HIT" ] && { match_any "$diffbody" highRiskContentPatterns "i" || true; }

if [ -z "$HIT" ]; then
  echo "check-routing: no high-risk changes — OK."
  exit 0
fi

# High-risk: require a STRUCTURED DB-safety trailer (literal key match — no regex; structured
# trailers only via git interpret-trailers, so prose like "I did the DB-Safety: check" never counts).
has_trailer() {  # has_trailer <commit-message-text>
  printf '%s\n' "$1" | git interpret-trailers --parse 2>/dev/null | {
    while IFS= read -r line; do
      case "$line" in
        "$TRAILER":*) v="${line#*:}"; v="${v# }"; [ -n "$v" ] && exit 0 ;;
      esac
    done
    exit 1
  }
}

present=1
if [ "$trailers_src" = "override" ]; then
  if has_trailer "$ROUTING_TRAILERS"; then present=0; fi
else
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    if has_trailer "$(git show -s --format='%B' "$sha")"; then present=0; break; fi
  done < <(git rev-list "$BASE"..HEAD)
fi

if [ "$present" -eq 0 ]; then
  echo "check-routing: high-risk change ($HIT) — '${TRAILER}:' trailer present. OK."
  exit 0
fi

{
  echo "check-routing: BLOCKED — high-risk change ($HIT) with no '${TRAILER}:' commit trailer."
  echo "  A change touching DB-safety-relevant paths/content must go through the project's DB-safety skill."
  echo "  After it reviews the change, add a trailer to a commit on this branch:  ${TRAILER}: <skill>"
  echo "  Mis-route signal: sentinel-expected-by-diff-content missing ($HIT)."
} >&2
exit 1
