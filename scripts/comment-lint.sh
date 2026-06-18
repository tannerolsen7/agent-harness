#!/usr/bin/env bash
# Block WHAT comments — comments that restate what the code already says through
# its names and structure. Only WHY comments are allowed: ones that explain a
# non-obvious decision, a workaround, or a subtle constraint that the code itself
# cannot express.
#
# A WHAT comment describes the mechanic ("loop through files", "check if user exists").
# A WHY comment explains the reason ("workaround for bash 3.2 on macOS",
# "git returns true for empty branches — see PR #50").
#
# Usage:
#   bash scripts/comment-lint.sh [files...]      # lint specific files
#   bash scripts/comment-lint.sh                 # lint all .sh and .js/.ts files
#
# Exits non-zero when any WHAT comment is found; exits 0 when clean.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# ---------------------------------------------------------------------------
# Patterns that flag WHAT comments.
#
# A WHAT comment opens with an action verb describing what the next line of
# code does. The pattern matches common forms: "# Verb the Noun", "# Verb Noun",
# "# Check if ...", "# Return ...", etc.
#
# We use two passes:
#   Pass 1 (grep -Ei): match lines whose comment body starts with a WHAT verb.
#   Pass 2 (grep -Eiv): drop lines that also contain WHY words — words that
#     shift the meaning from "what" to "why" (workaround, because, note, see, etc.).
#
# grep -E is POSIX and works on both GNU (Linux/CI) and BSD (macOS) grep.
# ---------------------------------------------------------------------------

# Action verbs that describe what code does (not why).
WHAT_VERBS="loop|iterate|walk|traverse|check|verify|validate|confirm|ensure|set|assign|update|increment|decrement|clear|reset|add|append|push|pop|insert|remove|delete|call|invoke|run|execute|start|stop|open|close|read|write|load|save|fetch|get|return|send|emit|print|log|display|show|hide|create|build|make|initialize|init|parse|format|sort|filter|map|reduce|count|calculate|compute|find|search|define|declare|import|export|process|handle"

# WHY words — their presence anywhere on the line means the comment explains
# a reason, not a mechanic, even if it starts with an action verb.
# Common purpose connectors ("to preserve X", "to allow Y", "to maintain Z")
# are included so comments that start with a verb but explain the goal pass through.
WHY_WORDS="workaround|because|since|reason|note|see |avoid|prevent|preserve|maintain|allow|enable|guard|warn|todo|fixme|hack|bug|issue|pr #|github|https|http|so that|in order|otherwise|instead|fallback|fall.back|bypass|due to|explain|based on|refer|per |follow|context|safety|important|critical|force|need|must|should|only if|unless|v[0-9]|3\.2|macos|linux|darwin|ci |posix|bsd|gnu"

find_what_comments() {
  local file="$1"
  local ext="${file##*.}"
  local comment_prefix

  case "$ext" in
    sh|bash) comment_prefix="#" ;;
    js|ts|jsx|tsx) comment_prefix="//" ;;
    *) return 0 ;;
  esac

  # Match: line starts with optional whitespace, then the comment marker,
  # then optional whitespace, then one of the WHAT verbs, then a space
  # (so "loop" matches "loop through" but not "loopback").
  grep -En "^[[:space:]]*${comment_prefix}[[:space:]]*(${WHAT_VERBS})[[:space:]]" "$file" 2>/dev/null \
    | grep -Eiv "${WHY_WORDS}" \
    || true
}

# ---------------------------------------------------------------------------
# Determine which files to check.
# ---------------------------------------------------------------------------
if [ $# -gt 0 ]; then
  files="$*"
else
  files=""
  while IFS= read -r f; do
    files="$files $f"
  done < <(find . -type f \( -name '*.sh' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \) \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    -not -path '*/worktrees/*' \
    -not -path '*/.husky/_/*' \
    2>/dev/null | sort)
fi

# ---------------------------------------------------------------------------
# Lint each file.
# ---------------------------------------------------------------------------
fail=0
count=0

for f in $files; do
  [ -f "$f" ] || continue
  ext="${f##*.}"
  case "$ext" in sh|bash|js|ts|jsx|tsx) ;; *) continue ;; esac

  count=$((count + 1))
  hits=$(find_what_comments "$f")
  if [ -n "$hits" ]; then
    echo "comment-lint: WHAT comments found in $f:" >&2
    printf '%s\n' "$hits" | while IFS= read -r line; do
      echo "  $line" >&2
    done
    fail=1
  fi
done

if [ "$fail" = 0 ]; then
  echo "comment-lint: OK ($count files checked — no WHAT comments found)"
fi
exit "$fail"
