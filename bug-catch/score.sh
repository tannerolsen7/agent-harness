#!/usr/bin/env bash
# Score a bug-catch run: read a results TSV ("<case-id>\t caught|missed" per line) and print
# the catch rate plus the 95% Wilson score lower bound. Gate on the LOWER BOUND, not the rate —
# a small real drop hides in luck on a small set (R4-D32 #1).
#
# With --traps, ALSO print the classifier-guard breakdown: the under-call rate over the
# "looks-trivial-but-isn't" cases (frontmatter `trap: true`). A trap missed is the kind of
# HIGH-risk diff the classifier must not under-tier — bias the classifier to over-tier when unsure
# (R4-D32 #5, docs/risk-classifier.md). NOTE: until the classifier exists and is wired to this, a
# "missed" trap measures the *reviewer* failing to catch it — a proxy for the classifier's
# under-call, not the classifier itself. The trap subset is read from the sibling cases/ dir, so
# --traps needs the repo layout. Without --traps the behavior and output are unchanged.
#
# Usage: bash bug-catch/score.sh [--traps] <results.tsv>     (or pipe the TSV on stdin)
# Exit:  0 ok · 1 results file missing · 2 no caught/missed verdicts · 3 --traps but no trap
#        cases were in the run (the guard would have measured nothing — fail loud, not green).
set -euo pipefail

# Parse args: --traps may appear in ANY position (a flag the caller forgets to put first must not
# silently no-op into a green overall score). The first non-flag arg is the results file.
TRAPS=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --traps) TRAPS=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
SRC="${ARGS[0]:-/dev/stdin}"
[ "$SRC" = "/dev/stdin" ] || [ -f "$SRC" ] || { echo "score: results file not found: $SRC" >&2; exit 1; }

# Wilson scorer over a 2-col TSV. $1 = id-set file ("" = all ids; restrict to the set otherwise),
# $2 = tsv file, $3 = trap corpus size (only used for the trap subset's "n of M" coverage line).
# Default (overall) output is byte-identical to the original single-awk version.
score_block() {
  awk -F'\t' -v setfile="$1" -v traptotal="${3:-0}" '
    BEGIN {
      use_set = (setfile != "")
      if (use_set) { while ((getline line < setfile) > 0) { gsub(/[ \t\r"]/, "", line); if (line != "") want[line] = 1 } }
    }
    {
      id = $1; v = $2; gsub(/[ \t\r"]/, "", id); gsub(/[ \t\r]/, "", v)
      if (use_set && !(id in want)) next
      if (v == "caught") { n++; k++ }
      else if (v == "missed") { n++ }
      else if ($0 ~ /[^ \t\r]/ && !use_set) { bad++ }
    }
    END {
      if (n == 0) {
        if (use_set) {
          # --traps asked for the guard but the run contained no trap cases: it measured nothing.
          # That must not read as a pass — print loud (stdout) and exit non-zero.
          print "classifier-guard: NO trap cases in this run — the guard measured nothing (run the trap cases)."
          exit 3
        }
        print "score: no caught/missed verdicts found" > "/dev/stderr"; exit 2
      }
      if (bad > 0) printf "score: %d line(s) were not caught|missed — ignored\n", bad > "/dev/stderr"
      p = k / n
      z = 1.96; z2 = z*z
      denom  = 1 + z2/n
      center = p + z2/(2*n)
      margin = z * sqrt( (p*(1-p))/n + z2/(4*n*n) )
      lower  = (center - margin) / denom
      if (lower < 0) lower = 0
      if (use_set) {
        printf "\n— classifier-guard / trap subset (looks-trivial-but-isn'"'"'t) —\n"
        printf "trap cases:   %d  (of %d in corpus)\n", n, traptotal
        if (n < traptotal) printf "  WARN: %d trap case(s) absent from this run — guard coverage is PARTIAL\n", traptotal - n
        printf "under-calls:  %d  (missed trap = a HIGH-risk diff the classifier must not under-tier)\n", n - k
        printf "trap recall:  %.1f%%  (reviewer-catch proxy until the classifier is wired in)\n", p*100
        printf "lower bound:  %.1f%%  (95%% Wilson — the classifier-guard gate)\n", lower*100
      } else {
        printf "cases:        %d\n", n
        printf "caught:       %d\n", k
        printf "recall:       %.1f%%\n", p*100
        printf "lower bound:  %.1f%%  (95%% Wilson — gate on this)\n", lower*100
      }
    }
  ' "$2"
}

if [ "$TRAPS" -eq 0 ]; then
  score_block "" "$SRC"
  exit
fi

# --traps: buffer the input (may be stdin) so we can scan it twice, then add the trap subset.
declare -a TMPFILES=()
cleanup() { [ "${#TMPFILES[@]}" -gt 0 ] && rm -f "${TMPFILES[@]}"; return 0; }
trap cleanup EXIT

BUF=$(mktemp); TMPFILES+=("$BUF")
cat -- "$SRC" > "$BUF"
score_block "" "$BUF"

SDIR=$(cd -- "$(dirname -- "$0")" && pwd)
CASES="$SDIR/cases"
if [ ! -d "$CASES" ]; then
  echo "classifier-guard: cases/ dir not found next to score.sh — skipping trap breakdown" >&2
  exit
fi

IDS=$(mktemp); TMPFILES+=("$IDS")
for f in "$CASES"/*.md; do
  [ -f "$f" ] || continue
  # Print the case id iff its frontmatter has `trap: true`. Emit on the CLOSING `---` (d==2 fence),
  # not the line after it, so a frontmatter-only case (no body) is still counted. Values are
  # normalized (strip quotes/space, lowercase trap) so `trap:true` / `trap: "True"` still match.
  awk '
    /^---[ \t]*$/ {
      d++
      if (d == 2) { if (tr == "true" && id != "") print id; exit }
      next
    }
    d == 1 && /^[ \t]*id:/   { v = $0; sub(/^[ \t]*id:[ \t]*/, "", v);   gsub(/[ \t\r"]/, "", v); id = v }
    d == 1 && /^[ \t]*trap:/ { v = $0; sub(/^[ \t]*trap:[ \t]*/, "", v); gsub(/[ \t\r"]/, "", v); tr = tolower(v) }
  ' "$f"
done > "$IDS"
TRAPTOTAL=$(grep -c . "$IDS" || true)
score_block "$IDS" "$BUF" "$TRAPTOTAL"
