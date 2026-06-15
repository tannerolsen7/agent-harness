#!/usr/bin/env bash
# Run the deterministic risk classifier over bug-catch cases and emit a results TSV.
#
# Each case file that has both `path:` and `tier:` frontmatter fields is run through
# scripts/classify-risk.sh.  The classifier's emitted tier is compared to the expected
# tier from the frontmatter; the result is `caught` (match) or `missed` (mismatch).
#
# Output: "<case-id>\t caught|missed" per qualifying case, on stdout.
# Feed to bug-catch/score.sh --traps to measure the classifier-guard gate.
#
# Usage:
#   bash bug-catch/run-classifier.sh [--verbose] | bash bug-catch/score.sh --traps /dev/stdin
#   bash bug-catch/run-classifier.sh [--cases dir] [--classifier script] [--verbose]
set -euo pipefail

SDIR=$(cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(cd -- "$SDIR/.." && pwd)
CASES_DIR="$SDIR/cases"
CLASSIFIER="$ROOT/scripts/classify-risk.sh"
VERBOSE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose|-v)      VERBOSE=1; shift ;;
    --cases)           CASES_DIR="$2"; shift 2 ;;
    --classifier)      CLASSIFIER="$2"; shift 2 ;;
    *) echo "run-classifier: unknown arg: $1" >&2; exit 1 ;;
  esac
done

[ -d "$CASES_DIR" ]   || { echo "run-classifier: cases dir not found: $CASES_DIR" >&2; exit 1; }
[ -f "$CLASSIFIER" ]  || { echo "run-classifier: classifier not found: $CLASSIFIER" >&2; exit 1; }

vlog() { [ "$VERBOSE" -eq 1 ] && printf 'run-classifier: %s\n' "$1" >&2 || true; }

for f in "$CASES_DIR"/*.md; do
  [ -f "$f" ] || continue

  # Extract frontmatter fields: id, tier, path.
  # Only process cases that have both `path:` and `tier:` set.
  id=""
  tier_expected=""
  case_path=""
  while IFS= read -r line; do
    case "$line" in
      ---) break ;;  # second fence — end of frontmatter
    esac
    case "$line" in
      id:*)   id=$(printf '%s' "${line#id:}" | tr -d ' "') ;;
      tier:*) tier_expected=$(printf '%s' "${line#tier:}" | tr -d ' "') ;;
      path:*) case_path=$(printf '%s' "${line#path:}" | tr -d ' "') ;;
    esac
  done < <(awk '/^---/{d++;if(d==1){next};if(d==2){exit}} d==1{print}' "$f")

  if [ -z "$id" ] || [ -z "$tier_expected" ] || [ -z "$case_path" ]; then
    vlog "skip $(basename "$f"): missing id/tier/path frontmatter"
    continue
  fi

  # Extract the code block (content between the first pair of ``` fences).
  code=$(awk '
    /^```/{
      if (in_block) { exit }
      in_block = 1; next
    }
    in_block { print }
  ' "$f")

  if [ -z "$code" ]; then
    vlog "skip $id: no code block found"
    continue
  fi

  # Build a synthetic diff: treat the entire code block as a new file addition.
  synthetic_diff=$(printf 'diff --git a/%s b/%s\nindex 0000000..1111111 100644\n--- /dev/null\n+++ b/%s\n@@ -0,0 +1,%d @@\n' \
    "$case_path" "$case_path" "$case_path" "$(printf '%s\n' "$code" | wc -l | tr -d ' ')")
  while IFS= read -r codeline; do
    synthetic_diff="${synthetic_diff}
+${codeline}"
  done <<EOF
$code
EOF

  # Run the classifier on the synthetic diff.
  tier_actual=$(printf '%s\n' "$synthetic_diff" | bash "$CLASSIFIER" 2>/dev/null)

  if [ "$tier_actual" = "$tier_expected" ]; then
    verdict="caught"
  else
    verdict="missed"
  fi

  vlog "$id: expected=$tier_expected actual=$tier_actual → $verdict"
  printf '%s\t%s\n' "$id" "$verdict"
done
