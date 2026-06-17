#!/usr/bin/env bash
# scan-context.sh reads context-meta blocks from governed files and reports which are
# overdue for review (weekly > 7 days, monthly > 30 days since last-reviewed; on-merge is
# not time-checked) and which governed files are missing a block. Read-only. Hermetic:
# fixture files in throwaway dirs, with --today pinned so the result never drifts with the clock.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SC="$ROOT/scripts/scan-context.sh"
[ -x "$SC" ] || { echo "test: $SC not found or not executable"; exit 1; }

TODAY=2026-06-17
pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

# write a governed file carrying a context-meta block
mkmeta() { # <path> <last-reviewed> <frequency>
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<EOF
<!-- context-meta
owner: tester
last-reviewed: $2
review-frequency: $3
drift-signals:
  - example signal
-->

# heading
body
EOF
}
# write a governed file with NO context-meta block
mkplain() { mkdir -p "$(dirname "$1")"; printf '# heading\nbody\n' > "$1"; }

run() { ( cd "$1" && bash "$SC" --root "$1" --today "$TODAY" ); }   # echoes report; returns exit code

# --- A: weekly file 47 days old → OVERDUE, exit 1 ---
A=$(mktemp -d); mkmeta "$A/CLAUDE.md" 2026-05-01 weekly
outA=$(run "$A"); rcA=$?
chk "$([ "$rcA" -eq 1 ] && echo 0 || echo 1)" "A: overdue weekly file → exit 1 (got $rcA)"
printf '%s' "$outA" | grep -qiE 'overdue.*CLAUDE\.md|CLAUDE\.md.*overdue'; chk $? "A: report names CLAUDE.md as OVERDUE"

# --- B: weekly file 2 days old → fresh, exit 0 ---
B=$(mktemp -d); mkmeta "$B/CLAUDE.md" 2026-06-15 weekly
run "$B" >/dev/null 2>&1; chk $? "B: fresh weekly file → exit 0"

# --- C: a REQUIRED-core file (PITFALLS.md) with no block → MISSING, exit 1 ---
C=$(mktemp -d); mkplain "$C/PITFALLS.md"
outC=$(run "$C"); rcC=$?
chk "$([ "$rcC" -eq 1 ] && echo 0 || echo 1)" "C: missing-block required-core file → exit 1 (got $rcC)"
printf '%s' "$outC" | grep -qiE 'missing.*PITFALLS\.md|PITFALLS\.md.*missing'; chk $? "C: report names PITFALLS.md as MISSING"

# --- D: on-merge file, very old → NOT time-flagged, exit 0 ---
D=$(mktemp -d); mkmeta "$D/PITFALLS.md" 2024-01-01 on-merge
run "$D" >/dev/null 2>&1; chk $? "D: stale on-merge file is not time-flagged → exit 0"

# --- E: monthly file 38 days old → OVERDUE (>30), exit 1 ---
E=$(mktemp -d); mkmeta "$E/skills/bar/SKILL.md" 2026-05-10 monthly
run "$E" >/dev/null 2>&1; chk "$([ $? -eq 1 ] && echo 0 || echo 1)" "E: 38-day monthly file → exit 1 (overdue)"

# --- F: a mix all within limits → exit 0 ---
F=$(mktemp -d)
mkmeta "$F/CLAUDE.md" 2026-06-15 weekly        # 2d
mkmeta "$F/PITFALLS.md" 2024-01-01 on-merge     # not time-checked
mkmeta "$F/skills/baz/SKILL.md" 2026-06-07 monthly  # 10d
run "$F" >/dev/null 2>&1; chk $? "F: all-fresh mix → exit 0"

# --- G: a skill with NO block is opt-in, not required → not flagged, exit 0 ---
G=$(mktemp -d); mkplain "$G/skills/qux/SKILL.md"
run "$G" >/dev/null 2>&1; chk $? "G: skill without a block is opt-in → exit 0 (not MISSING)"

rm -rf "$A" "$B" "$C" "$D" "$E" "$F" "$G"
echo ""
echo "scan-context: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
