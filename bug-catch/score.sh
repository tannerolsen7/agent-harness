#!/usr/bin/env bash
# Score a bug-catch run: read a results TSV ("<case-id>\t caught|missed" per line) and print
# the catch rate plus the 95% Wilson score lower bound. Gate on the LOWER BOUND, not the rate —
# a small real drop hides in luck on a small set (R4-D32 #1).
#
# With --traps, ALSO print the classifier-guard breakdown: the under-call rate over the
# "looks-trivial-but-isn't" cases (frontmatter `trap: true`). Under-tiering one of those is the
# failure that skips the safety battery — bias the classifier to over-tier when unsure (R4-D32 #5,
# docs/risk-classifier.md). The trap subset is read from the sibling cases/ dir, so --traps needs
# the repo layout; without --traps the behavior and output are unchanged.
#
# Usage: bash bug-catch/score.sh [--traps] <results.tsv>     (or pipe the TSV on stdin)
set -euo pipefail

TRAPS=0
if [ "${1:-}" = "--traps" ]; then TRAPS=1; shift; fi

SRC="${1:-/dev/stdin}"
[ "$SRC" = "/dev/stdin" ] || [ -f "$SRC" ] || { echo "score: results file not found: $SRC" >&2; exit 1; }

# Wilson scorer over a 2-col TSV. $1 = id-set file ("" = all ids; restrict to the set otherwise),
# $2 = tsv file. Default (overall) output is byte-identical to the original single-awk version.
score_block() {
  awk -F'\t' -v setfile="$1" '
    BEGIN {
      use_set = (setfile != "")
      if (use_set) { while ((getline line < setfile) > 0) { gsub(/[ \t\r]/, "", line); if (line != "") want[line] = 1 } }
    }
    {
      id = $1; v = $2; gsub(/[ \t\r]/, "", id); gsub(/[ \t\r]/, "", v)
      if (use_set && !(id in want)) next
      if (v == "caught") { n++; k++ }
      else if (v == "missed") { n++ }
      else if ($0 ~ /[^ \t\r]/ && !use_set) { bad++ }
    }
    END {
      if (n == 0) {
        if (use_set) { print "classifier-guard: no trap cases in this run" > "/dev/stderr"; exit 0 }
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
        printf "\n— classifier-guard / trap subset (looks trivial but is not) —\n"
        printf "trap cases:   %d\n", n
        printf "under-calls:  %d  (missed -> under-tiered -> safety battery skipped)\n", n - k
        printf "trap recall:  %.1f%%\n", p*100
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
cleanup() { [ "${#TMPFILES[@]}" -gt 0 ] && rm -f "${TMPFILES[@]}"; }
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
  # Print the case id iff its frontmatter has `trap: true`.
  awk '
    /^---$/ { d++; next }
    d == 1 && /^id:/   { id = $2; gsub(/"/, "", id) }
    d == 1 && /^trap:/ { tr = $2 }
    d == 2 { if (tr == "true" && id != "") print id; exit }
  ' "$f"
done > "$IDS"
score_block "$IDS" "$BUF"
