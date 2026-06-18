#!/usr/bin/env bash
# perf-budget.sh — compare Core Web Vitals measurements against per-project targets.
#
# What this does:
#   1. Reads budget targets for a named project from config/perf-budget.json
#      (falls back to the "default" entry when no project-specific entry exists).
#   2. Accepts measured values as CLI flags or from a JSON data file written by a
#      Lighthouse or web-vitals CI step.
#   3. Compares each supplied metric to its target and prints PASS / WARN / SKIP.
#   4. Writes a log entry to logs/perf-budget/ on every run.
#   5. Always exits 0. A breach is never silently ignored — WARN lines are always
#      printed and logged — but this is a warning-only gate, not a build stopper.
#      See docs/perf-budget.md to learn how to make a breach block CI.
#
# Usage:
#   bash scripts/perf-budget.sh [--project NAME] [--data FILE | metric flags]
#   bash scripts/perf-budget.sh --dry-run [--project NAME]
#
# Metric flags (all optional; unset metrics are skipped):
#   --lcp  MS    Largest Contentful Paint in milliseconds
#   --inp  MS    Interaction to Next Paint in milliseconds
#   --cls  N     Cumulative Layout Shift (decimal, e.g. 0.05)
#   --fcp  MS    First Contentful Paint in milliseconds
#   --ttfb MS    Time to First Byte in milliseconds
#
# Data file format (JSON, for --data):
#   { "LCP_ms": 1800, "INP_ms": 95, "CLS": 0.04, "FCP_ms": 900, "TTFB_ms": 210 }
#
# Exit codes:
#   0 — always (warning-only gate)
#   1 — bad arguments or missing config/data file (configuration error, not a breach)
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# ── defaults ────────────────────────────────────────────────────────────────
PROJECT="default"
DATA_FILE=""
DRY_RUN=0
VAL_LCP="" VAL_INP="" VAL_CLS="" VAL_FCP="" VAL_TTFB=""

# ── parse args ───────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --project)  PROJECT="$2"; shift 2 ;;
    --data)     DATA_FILE="$2"; shift 2 ;;
    --lcp)      VAL_LCP="$2";  shift 2 ;;
    --inp)      VAL_INP="$2";  shift 2 ;;
    --cls)      VAL_CLS="$2";  shift 2 ;;
    --fcp)      VAL_FCP="$2";  shift 2 ;;
    --ttfb)     VAL_TTFB="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    *) echo "perf-budget: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── validate config ──────────────────────────────────────────────────────────
CONFIG="$ROOT/config/perf-budget.json"
if [ ! -f "$CONFIG" ]; then
  echo "perf-budget: config not found: $CONFIG" >&2
  exit 1
fi

# json_field KEY JSON_TEXT
# Extract a bare number or simple value for KEY from a flat JSON object fragment.
# Works with BSD awk and POSIX awk — no gawk extensions required.
# The JSON is one flat object; we split on commas/braces, then look for the key.
json_field() {
  local key="$1"
  local text="$2"
  printf '%s' "$text" | awk -v key="\"$key\"" '
    BEGIN { RS=","; FS=":" }
    {
      # Trim whitespace from field 1 (the key candidate)
      k = $1
      gsub(/^[[:space:]\n{}"]+|[[:space:]\n"]+$/, "", k)
      kq = "\"" k "\""
      if (kq == key || k == key) {
        v = $2
        gsub(/^[[:space:]\n"]+|[[:space:]\n}"]+$/, "", v)
        print v
        exit
      }
    }
  '
}

# json_get KEY PROJECT_NAME
# Look up KEY in the per-project block; fall back to "default" if not found.
# Strategy: extract the project's object text between its opening { and the
# matching }, then call json_field on that text.
json_get() {
  local key="$1"
  local proj="$2"

  # Pull the text of the project block. We use awk to find the line with the
  # project key, then collect lines until the closing brace of that block.
  project_block() {
    local pname="$1"
    awk -v pname="\"$pname\"" '
      BEGIN { found=0; depth=0; buf="" }
      !found && $0 ~ pname { found=1; next }
      found && /{/ { depth++ }
      found && /}/ {
        if (depth == 0) { print buf; exit }
        depth--
      }
      found { buf = buf $0 "\n" }
    ' "$CONFIG"
  }

  local block
  block=$(project_block "$proj")
  local val
  val=$(json_field "$key" "$block")

  if [ -z "$val" ] && [ "$proj" != "default" ]; then
    block=$(project_block "default")
    val=$(json_field "$key" "$block")
  fi
  printf '%s' "$val"
}

T_LCP=$(json_get "LCP_ms"  "$PROJECT")
T_INP=$(json_get "INP_ms"  "$PROJECT")
T_CLS=$(json_get "CLS"     "$PROJECT")
T_FCP=$(json_get "FCP_ms"  "$PROJECT")
T_TTFB=$(json_get "TTFB_ms" "$PROJECT")

# ── dry-run: just show targets ───────────────────────────────────────────────
if [ "$DRY_RUN" = 1 ]; then
  echo "perf-budget: targets for project '$PROJECT'"
  echo "  LCP  ≤ ${T_LCP}ms"
  echo "  INP  ≤ ${T_INP}ms"
  echo "  CLS  ≤ ${T_CLS}"
  echo "  FCP  ≤ ${T_FCP}ms"
  echo "  TTFB ≤ ${T_TTFB}ms"
  exit 0
fi

# ── load measured values from --data file ────────────────────────────────────
# CLI flags take precedence over the data file.
if [ -n "$DATA_FILE" ]; then
  if [ ! -f "$DATA_FILE" ]; then
    echo "perf-budget: data file not found: $DATA_FILE" >&2
    exit 1
  fi
  data_text=$(cat "$DATA_FILE")
  read_metric() { json_field "$1" "$data_text"; }
  [ -z "$VAL_LCP"  ] && VAL_LCP=$(read_metric "LCP_ms")
  [ -z "$VAL_INP"  ] && VAL_INP=$(read_metric "INP_ms")
  [ -z "$VAL_CLS"  ] && VAL_CLS=$(read_metric "CLS")
  [ -z "$VAL_FCP"  ] && VAL_FCP=$(read_metric "FCP_ms")
  [ -z "$VAL_TTFB" ] && VAL_TTFB=$(read_metric "TTFB_ms")
fi

# ── set up logging ───────────────────────────────────────────────────────────
LOG_DIR="$ROOT/logs/perf-budget"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date -u '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/${TIMESTAMP}_${PROJECT}.log"
LATEST_LINK="$LOG_DIR/latest_${PROJECT}.log"

BREACHED=0
CHECKED=0

# Write log header
{
  echo "perf-budget run"
  echo "project:   $PROJECT"
  echo "timestamp: $TIMESTAMP"
  echo "targets:   LCP=${T_LCP}ms INP=${T_INP}ms CLS=${T_CLS} FCP=${T_FCP}ms TTFB=${T_TTFB}ms"
  echo "---"
} > "$LOG_FILE"

# ── check one metric ─────────────────────────────────────────────────────────
# check_metric LABEL VALUE TARGET
# Prints one result line; appends to LOG_FILE; updates BREACHED and CHECKED.
check_metric() {
  local label="$1"
  local val="$2"
  local target="$3"

  if [ -z "$val" ] || [ -z "$target" ]; then
    printf '  %-6s  SKIP   (no measurement provided)\n' "$label"
    printf '%s  %-6s  SKIP\n' "$TIMESTAMP" "$label" >> "$LOG_FILE"
    return
  fi

  CHECKED=$((CHECKED + 1))

  # awk handles integer and float comparison portably (BSD + GNU awk both work)
  local result
  result=$(awk -v val="$val" -v tgt="$target" 'BEGIN {
    print (val+0 <= tgt+0) ? "PASS" : "WARN"
  }')

  if [ "$result" = "PASS" ]; then
    printf '  %-6s  PASS   %s ≤ %s\n' "$label" "$val" "$target"
    printf '%s  %-6s  PASS  val=%s target=%s\n' "$TIMESTAMP" "$label" "$val" "$target" >> "$LOG_FILE"
  else
    printf '  %-6s  WARN   %s > %s (budget breached)\n' "$label" "$val" "$target"
    printf '%s  %-6s  WARN  val=%s target=%s\n' "$TIMESTAMP" "$label" "$val" "$target" >> "$LOG_FILE"
    BREACHED=$((BREACHED + 1))
  fi
}

# ── run checks ───────────────────────────────────────────────────────────────
echo "perf-budget: project='$PROJECT'  $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "perf-budget: targets  LCP≤${T_LCP}ms  INP≤${T_INP}ms  CLS≤${T_CLS}  FCP≤${T_FCP}ms  TTFB≤${T_TTFB}ms"
echo ""

check_metric "LCP"  "$VAL_LCP"  "$T_LCP"
check_metric "INP"  "$VAL_INP"  "$T_INP"
check_metric "CLS"  "$VAL_CLS"  "$T_CLS"
check_metric "FCP"  "$VAL_FCP"  "$T_FCP"
check_metric "TTFB" "$VAL_TTFB" "$T_TTFB"

echo ""

# Append summary to log
{
  echo "---"
  echo "checked:  $CHECKED"
  echo "breached: $BREACHED"
} >> "$LOG_FILE"

# Update the "latest" symlink so callers can find the most recent run quickly.
ln -sf "$LOG_FILE" "$LATEST_LINK"

# ── summary ──────────────────────────────────────────────────────────────────
if [ "$CHECKED" -eq 0 ]; then
  echo "perf-budget: no metrics supplied — nothing to check."
  echo "perf-budget: Pass --lcp / --inp / --cls / --fcp / --ttfb or --data FILE."
  echo "perf-budget: log: $LOG_FILE"
  exit 0
fi

if [ "$BREACHED" -gt 0 ]; then
  echo "perf-budget: WARN — $BREACHED of $CHECKED metric(s) exceeded budget for project '$PROJECT'."
  echo "perf-budget: Review targets in config/perf-budget.json or investigate the measured values."
  echo "perf-budget: log: $LOG_FILE"
  # Exit 0 intentionally — warning-only gate. See docs/perf-budget.md for how to
  # escalate a breach to a build failure once the measurement pipeline is stable.
  exit 0
fi

echo "perf-budget: OK — $CHECKED metric(s) within budget for project '$PROJECT'."
echo "perf-budget: log: $LOG_FILE"
exit 0
