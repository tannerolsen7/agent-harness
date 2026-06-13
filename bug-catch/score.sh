#!/usr/bin/env bash
# Score a bug-catch run: read a results TSV ("<case-id>\t caught|missed" per line) and print
# the catch rate plus the 95% Wilson score lower bound. Gate on the LOWER BOUND, not the rate —
# a small real drop hides in luck on a small set (R4-D32 #1).
#
# Usage: bash bug-catch/score.sh <results.tsv>      (or pipe the TSV on stdin)
set -euo pipefail

SRC="${1:-/dev/stdin}"
[ "$SRC" = "/dev/stdin" ] || [ -f "$SRC" ] || { echo "score: results file not found: $SRC" >&2; exit 1; }

awk -F'\t' '
  {
    v = $2
    gsub(/[ \t\r]/, "", v)
    if (v == "caught") { n++; k++ }
    else if (v == "missed") { n++ }
    else if ($0 ~ /[^ \t\r]/) { bad++ }
  }
  END {
    if (n == 0) { print "score: no caught/missed verdicts found" > "/dev/stderr"; exit 2 }
    if (bad > 0) { printf "score: %d line(s) were not caught|missed — ignored\n", bad > "/dev/stderr" }
    p = k / n
    z = 1.96; z2 = z*z
    denom  = 1 + z2/n
    center = p + z2/(2*n)
    margin = z * sqrt( (p*(1-p))/n + z2/(4*n*n) )
    lower  = (center - margin) / denom
    if (lower < 0) lower = 0
    printf "cases:        %d\n", n
    printf "caught:       %d\n", k
    printf "recall:       %.1f%%\n", p*100
    printf "lower bound:  %.1f%%  (95%% Wilson — gate on this)\n", lower*100
  }
' "$SRC"
