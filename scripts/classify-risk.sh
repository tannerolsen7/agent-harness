#!/usr/bin/env bash
# Deterministic blast-radius classifier.  Maps a git diff to LOW / MEDIUM / HIGH.
#
# Usage:
#   git diff <base>..<head>   | bash scripts/classify-risk.sh [--verbose]
#   bash scripts/classify-risk.sh [--verbose] <base>..<head>
#   bash scripts/classify-risk.sh [--verbose]   # reads diff from stdin
#
# Prints the tier (LOW, MEDIUM, or HIGH) on stdout.  Always exits 0.
#
# Over-classify rule (docs/risk-classifier.md § guard):
#   Any HIGH signal present or tier uncertain → HIGH.  Never lower.
#   A diff that touches a blast-radius path (auth/RLS/payments/schema/public)
#   is HIGH even if it is one line and looks trivial.
set -euo pipefail

VERBOSE=0
DIFFSPEC=""
for arg in "$@"; do
  case "$arg" in
    --verbose|-v) VERBOSE=1 ;;
    --) ;;
    *)  DIFFSPEC="$arg" ;;
  esac
done

# ── Acquire the diff ──────────────────────────────────────────────────────────

if [ -n "$DIFFSPEC" ]; then
  DIFF=$(git diff "$DIFFSPEC" 2>/dev/null) || { echo "classify-risk: cannot diff '$DIFFSPEC'" >&2; exit 1; }
else
  DIFF=$(cat)
fi

if [ -z "$DIFF" ]; then
  printf 'LOW\n'
  exit 0
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

verbose() { [ "$VERBOSE" -eq 1 ] && printf 'classify-risk [%s]: %s\n' "$1" "$2" >&2 || true; }

# Returns 0 (true) if the lowercase path $1 touches a HIGH blast-radius area.
# Split into separate case blocks so inline comments don't corrupt the pattern list.
is_high_path() {
  local lp
  lp=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')

  # Auth / access control / session / identity
  case "$lp" in
    *middleware* | */auth/* | */auth.* | *authentication* | *authorization* | \
    */login* | */logout* | */session* | */token* | \
    */credential* | */oauth* | */sso* | */saml* | */jwt*)
      return 0 ;;
  esac

  # Admin routes (unauthenticated access to admin = HIGH)
  case "$lp" in
    */admin/* | */admin.*)
      return 0 ;;
  esac

  # RLS / database policies
  case "$lp" in
    */policies/* | */policy/* | */rls/*)
      return 0 ;;
  esac

  # Payments / billing
  case "$lp" in
    */payment* | */billing* | */checkout* | */stripe* | \
    */charge* | */invoice* | */pricing*)
      return 0 ;;
  esac

  # Schema / migrations
  case "$lp" in
    */migration* | */migrations/* | \
    *schema.sql | *schema.prisma | \
    *.migration.* | *_migration.* | \
    */db/schema* | */database/schema* | \
    */seed.sql | */seeds/*)
      return 0 ;;
  esac

  # Framework config and infrastructure
  case "$lp" in
    next.config.* | */next.config.* | \
    vercel.json | */vercel.json | \
    .env | .env.* | */.env | */.env.* | \
    *dockerfile | */dockerfile | *docker-compose* | \
    */terraform/* | */infra/*)
      return 0 ;;
  esac

  return 1
}

# Scans added lines (+) for HIGH-tier content patterns.
# Prints a signal name on first match; prints nothing if no match.
high_content_signal() {
  printf '%s\n' "$1" | awk '
    /^\+/ && !/^\+\+\+/ {
      line = substr($0, 2)
      gsub(/^[[:space:]]+/, "", line)
      lline = tolower(line)

      if (lline ~ /alter[[:space:]]+policy/ ||
          lline ~ /create[[:space:]]+policy/ ||
          lline ~ /drop[[:space:]]+policy/ ||
          lline ~ /enable[[:space:]]+row[[:space:]]+level/ ||
          lline ~ /disable[[:space:]]+row[[:space:]]+level/ ||
          lline ~ /row[[:space:]]+level[[:space:]]+security/) {
        print "rls-policy-change"; exit
      }
      if (lline ~ /using[[:space:]]*\([[:space:]]*true[[:space:]]*\)/) {
        print "rls-using-true"; exit
      }
      if (lline ~ /^grant[[:space:]]/ || lline ~ /^revoke[[:space:]]/) {
        print "sql-privilege"; exit
      }
      if (lline ~ /alter[[:space:]]+table/ ||
          lline ~ /drop[[:space:]]+table/ ||
          lline ~ /create[[:space:]]+table/ ||
          lline ~ /drop[[:space:]]+column/ ||
          lline ~ /drop[[:space:]]+not[[:space:]]+null/ ||
          lline ~ /drop[[:space:]]+constraint/ ||
          lline ~ /alter[[:space:]]+column[[:space:]]/ ||
          lline ~ /drop[[:space:]]+index/) {
        print "schema-ddl"; exit
      }
    }
  '
}

# ── Classify ──────────────────────────────────────────────────────────────────

# Extract changed file paths from "diff --git a/<path> b/<path>" headers.
paths=$(printf '%s\n' "$DIFF" | sed -n 's|^diff --git a/.* b/||p' | sort -u)

tier="MEDIUM"

# 1. Path-level HIGH check (over-classify rule: any HIGH path → HIGH)
for p in $paths; do
  if is_high_path "$p"; then
    verbose "HIGH" "path: $p"
    tier="HIGH"
    break
  fi
done

# 2. Content-level HIGH check
if [ "$tier" != "HIGH" ]; then
  csig=$(high_content_signal "$DIFF")
  if [ -n "$csig" ]; then
    verbose "HIGH" "content: $csig"
    tier="HIGH"
  fi
elif [ "$VERBOSE" -eq 1 ]; then
  csig=$(high_content_signal "$DIFF")
  [ -n "$csig" ] && verbose "HIGH" "content (also): $csig" || true
fi

# 3. LOW check: all changed files are docs/copy — no code touched.
#    Only reached when no HIGH signal was found.
if [ "$tier" = "MEDIUM" ] && [ -n "$paths" ]; then
  all_docs=1
  for p in $paths; do
    lp=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')
    case "$lp" in
      *.md | *.mdx | *.txt | *.rst | \
      docs/* | */docs/* | \
      readme* | changelog* | license* | contributing* | \
      .github/*.md)
        ;;
      *)
        all_docs=0
        break ;;
    esac
  done
  [ "$all_docs" -eq 1 ] && tier="LOW"
fi

verbose "$tier" "final tier"
printf '%s\n' "$tier"
