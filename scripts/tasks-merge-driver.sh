#!/bin/sh
# TASKS.md merge driver: higher-state-wins for task status fields.
#
# git passes three temp file paths as arguments:
#   $1 = %O  ancestor (common base)
#   $2 = %A  current branch (also the output — driver writes merged result here)
#   $3 = %B  other branch being merged in
#
# Exit 0 = merge is clean. Exit 1 = unresolved conflicts remain in $2.
#
# Algorithm:
#   1. Try a standard 3-way merge with git merge-file. If it succeeds cleanly, done.
#   2. If conflicts remain, process the conflict markers: for any single-line conflict
#      where both sides are a task status line (- [ ], - [~], or - [x]), replace the
#      conflict block with the higher-state line. Leave all other conflicts as markers.
#
# State rank (highest first): [x]=3  [~]=2  [ ]=1

ANCESTOR="$1"
CURRENT="$2"
OTHER="$3"

# Try standard 3-way merge first. Exit 0 = clean; non-zero = conflicts remain.
if git merge-file -L CURRENT -L ANCESTOR -L OTHER "$CURRENT" "$ANCESTOR" "$OTHER" 2>/dev/null; then
  exit 0
fi

# Conflicts remain. Process conflict markers, applying higher-state-wins for task lines.
TMP=$(mktemp) || exit 1
trap 'rm -f "$TMP"' EXIT
awk '
BEGIN { in_c=0; side=""; cbuf=""; obuf=""; bad=0 }

/^<<<<<<< / { in_c=1; side="c"; cbuf=""; obuf=""; next }

/^=======$/  { if (in_c) { side="o"; next } }

/^>>>>>>> / {
  in_c=0
  # Count lines in each side (split on newline, drop trailing empty element).
  nc = split(cbuf, ca, "\n"); if (nc > 0 && ca[nc] == "") nc--
  no = split(obuf, oa, "\n"); if (no > 0 && oa[no] == "") no--

  if (nc == 1 && no == 1 && ca[1] ~ /^- \[[ ~x]\]/ && oa[1] ~ /^- \[[ ~x]\]/) {
    # Single-line conflict between two task status lines — pick the higher state.
    print (rank(ca[1]) >= rank(oa[1])) ? ca[1] : oa[1]
  } else {
    # Cannot resolve — emit conflict markers and signal unresolved.
    print "<<<<<<< CURRENT"
    printf "%s", cbuf
    print "======="
    printf "%s", obuf
    print ">>>>>>> OTHER"
    bad = 1
  }
  cbuf = ""; obuf = ""; next
}

in_c && side == "c" { cbuf = cbuf $0 "\n"; next }
in_c && side == "o" { obuf = obuf $0 "\n"; next }

{ print }

function rank(s,    c) {
  c = substr(s, 3, 3)
  if (c == "[x]") return 3
  if (c == "[~]") return 2
  if (c == "[ ]") return 1
  return 0
}

END { if (in_c) bad=1; exit bad }
' "$CURRENT" > "$TMP"
AWK_EXIT=$?
if [ "$AWK_EXIT" -le 1 ]; then
  mv "$TMP" "$CURRENT"
fi
exit $AWK_EXIT
