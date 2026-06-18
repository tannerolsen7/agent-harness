#!/usr/bin/env bash
# Tests for scripts/perf-budget.sh.
# Each test runs in a temporary repo so it does not pollute the real repo's logs/
# and so the config path resolves cleanly via git rev-parse --show-toplevel.
#
# GIT_DIR guard: inherited GIT_DIR from a hook or outer worktree would make git
# commands operate on the wrong repo. Clear it here.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/perf-budget.sh"
CONFIG_SRC="$ROOT/config/perf-budget.json"

[ -f "$SCRIPT" ]     || { echo "test: $SCRIPT not found"; exit 1; }
[ -f "$CONFIG_SRC" ] || { echo "test: $CONFIG_SRC not found"; exit 1; }

pass=0; fail=0
ok()     { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "  MISS ($3): got '$1', want '$2'"; fail=$((fail+1)); fi; }
nonzero(){ if [ "$1" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS ($2): expected non-zero exit"; fail=$((fail+1)); fi; }
hasout() { if printf '%s' "$1" | grep -qi "$2"; then pass=$((pass+1)); else echo "  MISS ($3): output missing '$2'"; fail=$((fail+1)); fi; }
noout()  { if ! printf '%s' "$1" | grep -qi "$2"; then pass=$((pass+1)); else echo "  MISS ($3): output should not contain '$2'"; fail=$((fail+1)); fi; }
clean()  { d="$1"; [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d" 2>/dev/null; }

# Build a throwaway git repo with the script and a copy of the config.
mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com
    git config user.name tester
    mkdir -p scripts config logs
    cp "$SCRIPT"     scripts/perf-budget.sh
    cp "$CONFIG_SRC" config/perf-budget.json
    chmod +x scripts/perf-budget.sh
    git add -A && git commit -q -m init
  ) >/dev/null 2>&1
  echo "$d"
}

# ── 1. --dry-run prints targets and exits 0 ──────────────────────────────────
echo "── dry-run: prints targets, exit 0 ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh --dry-run 2>&1); rc=$?
ok "$rc" 0 "dry-run exit 0"
hasout "$out" "LCP" "dry-run shows LCP"
hasout "$out" "INP" "dry-run shows INP"
hasout "$out" "CLS" "dry-run shows CLS"
clean "$D"

# ── 2. all metrics within budget: PASS lines, exit 0 ────────────────────────
echo "── all metrics pass: PASS lines, exit 0 ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh \
  --lcp 1000 --inp 100 --cls 0.02 --fcp 800 --ttfb 300 2>&1); rc=$?
ok "$rc" 0 "all pass exit 0"
hasout "$out" "PASS" "output contains PASS"
noout  "$out" "WARN" "output has no WARN when all pass"
clean "$D"

# ── 3. one metric breached: WARN line, still exits 0 ────────────────────────
echo "── one metric breached: WARN, exit still 0 ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh \
  --lcp 9000 --inp 100 --cls 0.02 --fcp 800 --ttfb 300 2>&1); rc=$?
ok "$rc" 0 "breach still exits 0 (non-blocking)"
hasout "$out" "WARN" "output contains WARN on breach"
hasout "$out" "LCP"  "WARN names the breached metric"
clean "$D"

# ── 4. CLS float comparison works ───────────────────────────────────────────
echo "── CLS float comparison ──"
D=$(mk)
# CLS 0.05 is within default budget of 0.1
out_pass=$(cd "$D" && bash scripts/perf-budget.sh --cls 0.05 2>&1); rc_pass=$?
ok "$rc_pass" 0 "CLS 0.05 exits 0"
hasout "$out_pass" "PASS" "CLS 0.05 is PASS"

# CLS 0.15 exceeds default budget of 0.1
out_warn=$(cd "$D" && bash scripts/perf-budget.sh --cls 0.15 2>&1); rc_warn=$?
ok "$rc_warn" 0 "CLS 0.15 still exits 0"
hasout "$out_warn" "WARN" "CLS 0.15 is WARN"
clean "$D"

# ── 5. no metrics supplied: prints advisory, exits 0 ────────────────────────
echo "── no metrics: advisory, exit 0 ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh 2>&1); rc=$?
ok "$rc" 0 "no metrics exits 0"
hasout "$out" "nothing to check" "no-metrics message present"
clean "$D"

# ── 6. --data file: reads values, compares against targets ──────────────────
echo "── --data file: reads metrics from JSON ──"
D=$(mk)
printf '{"LCP_ms":1000,"INP_ms":80,"CLS":0.03,"FCP_ms":700,"TTFB_ms":200}\n' \
  > "$D/vitals.json"
out=$(cd "$D" && bash scripts/perf-budget.sh --data vitals.json 2>&1); rc=$?
ok "$rc" 0 "--data file exit 0"
hasout "$out" "PASS" "--data file shows PASS"
noout  "$out" "WARN" "--data file with good values has no WARN"
clean "$D"

# ── 7. --data file with a breached metric ───────────────────────────────────
echo "── --data file breach: WARN ──"
D=$(mk)
printf '{"LCP_ms":9999}\n' > "$D/vitals.json"
out=$(cd "$D" && bash scripts/perf-budget.sh --data vitals.json 2>&1); rc=$?
ok "$rc" 0 "--data breach exits 0"
hasout "$out" "WARN" "--data breach shows WARN"
clean "$D"

# ── 8. --data file missing: exits non-zero with error ───────────────────────
echo "── --data missing file: error, non-zero exit ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh --data /nonexistent/path.json 2>&1); rc=$?
nonzero "$rc" "missing data file exits non-zero"
hasout "$out" "not found" "error message says not found"
clean "$D"

# ── 9. config missing: exits non-zero with error ────────────────────────────
echo "── missing config: error, non-zero exit ──"
D=$(mk)
rm "$D/config/perf-budget.json"
out=$(cd "$D" && bash scripts/perf-budget.sh --lcp 1000 2>&1); rc=$?
nonzero "$rc" "missing config exits non-zero"
hasout "$out" "config not found" "error says config not found"
clean "$D"

# ── 10. log file is written on each run ─────────────────────────────────────
echo "── log file is written after a run ──"
D=$(mk)
cd "$D" && bash scripts/perf-budget.sh --lcp 1000 >/dev/null 2>&1; rc=$?
log_count=$(find "$D/logs/perf-budget" -name '*.log' -not -name 'latest*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$log_count" -ge 1 ]; then pass=$((pass+1)); else echo "  MISS (log written): got $log_count log files, want ≥1"; fail=$((fail+1)); fi
# latest symlink exists
if [ -L "$D/logs/perf-budget/latest_default.log" ]; then pass=$((pass+1)); else echo "  MISS (latest symlink missing)"; fail=$((fail+1)); fi
clean "$D"

# ── 11. unknown argument exits non-zero ──────────────────────────────────────
echo "── unknown argument: exits non-zero ──"
D=$(mk)
out=$(cd "$D" && bash scripts/perf-budget.sh --not-a-flag 2>&1); rc=$?
nonzero "$rc" "unknown flag exits non-zero"
hasout "$out" "unknown argument" "unknown-arg error message"
clean "$D"

echo ""
echo "perf-budget: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
