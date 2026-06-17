#!/usr/bin/env bash
# scan-context.sh — a freshness check for "governed" context docs.
#
# A governed file carries a `context-meta` block at the top that records when it was last
# reviewed and how often it should be. This script reads those blocks and reports:
#   - OVERDUE: a weekly file older than 7 days, or a monthly file older than 30 days
#   - MISSING: a required-core file that has no context-meta block (or a broken one)
# `on-merge` files are reviewed on every pull request (by /cr), so they are NOT time-checked here.
# Read-only — it prints a report and never edits a file.
#
# Two scopes, on purpose:
#   - Freshness (OVERDUE) applies to ANY file that carries a block — so a skill opts INTO
#     governance by adding one. This keeps the maintenance surface small.
#   - MISSING applies ONLY to the required-core files below — the canonical governance docs that
#     must always carry a block. Skills are never reported MISSING (they are opt-in).
#
# Exit 0 = everything fresh. Exit 1 = at least one OVERDUE or MISSING file (so a /schedule
# routine or a person can tell action is needed). Exit 2 = a usage or date-parse error.
#
# Flags (both exist so the test can pin a fixture and a clock):
#   --root DIR          scan under DIR instead of the repo root
#   --today YYYY-MM-DD  treat this as "today" instead of the system date
set -u

WEEKLY_LIMIT=7
MONTHLY_LIMIT=30

ROOT=""
TODAY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)  ROOT="${2:-}"; shift 2 ;;
    --today) TODAY="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: scan-context.sh [--root DIR] [--today YYYY-MM-DD]"; exit 0 ;;
    *) echo "scan-context: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$ROOT" ] || ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
[ -d "$ROOT" ] || { echo "scan-context: not a directory: $ROOT" >&2; exit 2; }

# Date → epoch seconds, portable across GNU date (Linux/CI) and BSD date (macOS).
if date -d "2020-01-01" +%s >/dev/null 2>&1; then DATE_GNU=1; else DATE_GNU=0; fi
to_epoch() { # <YYYY-MM-DD>
  if [ "$DATE_GNU" = 1 ]; then date -d "$1" +%s 2>/dev/null
  else date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null; fi
}

if [ -n "$TODAY" ]; then TODAY_EPOCH=$(to_epoch "$TODAY"); else TODAY_EPOCH=$(date +%s); fi
[ -n "$TODAY_EPOCH" ] || { echo "scan-context: could not resolve today's date" >&2; exit 2; }

# Read one field's value out of a file's REAL context-meta block — the first one outside any
# ``` code fence. Fence-aware on purpose, so it reads the same block has_real_meta counts: a file
# that shows a fenced example above its real block must not be read from the example.
meta_field() { # <file> <field>
  awk -v field="$2" '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    !inblock && /<!-- context-meta/ { inblock = 1; next }
    inblock && /-->/ { exit }
    inblock {
      s = $0; sub(/^[[:space:]]+/, "", s)
      if (s ~ "^" field ":") { sub("^" field ":[[:space:]]*", "", s); sub(/[[:space:]]+$/, "", s); print s; exit }
    }' "$1"
}

# True if the file carries a REAL context-meta block — one outside any ``` code fence. This
# skips the example block in docs that document the format (e.g. 11-skill-ecosystems.md), which
# lives inside a fenced code sample and is not actual governance metadata.
has_real_meta() { # <file>
  awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    !fence && /<!-- context-meta/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

overdue=0; missing=0; ok=0
report=""

# 1) Freshness — every file that carries a REAL context-meta block (core files + any opted-in skill).
all_md=$(find "$ROOT" \
  \( -path '*/.git' -o -path '*/node_modules' -o -path '*/.claude/worktrees' \) -prune -o \
  -type f -name '*.md' -print | sort)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  has_real_meta "$f" || continue
  rel="${f#"$ROOT"/}"
  freq=$(meta_field "$f" review-frequency)
  reviewed=$(meta_field "$f" last-reviewed)
  case "$freq" in
    weekly)   limit=$WEEKLY_LIMIT ;;
    monthly)  limit=$MONTHLY_LIMIT ;;
    on-merge) report="${report}OK       on-merge  ${rel}  (checked every PR)
"; ok=$((ok+1)); continue ;;
    *) report="${report}MISSING  ?         ${rel}  (block has no/unknown review-frequency: '${freq:-empty}')
"; missing=$((missing+1)); continue ;;
  esac
  r_epoch=$(to_epoch "$reviewed")
  if [ -z "$r_epoch" ]; then
    report="${report}MISSING  ${freq}    ${rel}  (unparseable last-reviewed: '${reviewed:-empty}')
"; missing=$((missing+1)); continue
  fi
  days=$(( (TODAY_EPOCH - r_epoch) / 86400 ))
  if [ "$days" -lt 0 ]; then
    report="${report}MISSING  ${freq}    ${rel}  (last-reviewed is in the future: ${reviewed})
"; missing=$((missing+1)); continue
  fi
  if [ "$days" -gt "$limit" ]; then
    report="${report}OVERDUE  ${freq}    ${rel}  (last-reviewed ${reviewed}, ${days}d ago, limit ${limit}d)
"; overdue=$((overdue+1))
  else
    report="${report}OK       ${freq}    ${rel}  (last-reviewed ${reviewed}, ${days}d ago)
"; ok=$((ok+1))
  fi
done <<EOF
$all_md
EOF

# 2) Missing — required-core files that exist but carry no block. Skills are NOT required;
#    they opt into governance by adding a block (keeps the maintenance surface small).
required=$(find "$ROOT" \
  \( -path '*/.git' -o -path '*/node_modules' -o -path '*/.claude/worktrees' \) -prune -o \
  -type f \( -name CLAUDE.md -o -name AGENTS.md -o -name CONTEXT.md -o -name PITFALLS.md \
             -o -name SOUL.md -o -name memory.md \) -print | sort)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  has_real_meta "$f" && continue   # already counted as a carrier above
  rel="${f#"$ROOT"/}"
  report="${report}MISSING  -         ${rel}  (required file has no context-meta block)
"; missing=$((missing+1))
done <<EOF
$required
EOF

[ -n "$report" ] && printf '%s' "$report"
echo "scan-context: ${overdue} overdue, ${missing} missing, ${ok} ok"

[ "$overdue" -eq 0 ] && [ "$missing" -eq 0 ]
