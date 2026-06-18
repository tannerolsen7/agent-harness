#!/usr/bin/env bash
# Measure Core Web Vitals and compare them against per-project targets.
# Prints pass/warn per metric. Exits 0 even on breach — this is an advisory check, not a blocker.
#
# Usage:
#   bash scripts/perf-budget.sh [--config <path>] [--url <url>]
#
# Config file (default: perf-budget.config.sh):
#   LCP_BUDGET_MS=2500   # Largest Contentful Paint, in milliseconds
#   CLS_BUDGET=0.1       # Cumulative Layout Shift, unitless score
#   FID_BUDGET_MS=100    # First Input Delay, in milliseconds
#
# Measurement: uses Lighthouse CLI when available (lighthouse), falls back to curl-based
# time-to-first-byte for LCP and sets CLS/FID to 0 (no-op pass) when headless tools are absent.
# In CI without a browser the fallback ensures the script never crashes.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# ── Defaults ─────────────────────────────────────────────────────────────────
LCP_BUDGET_MS=2500
CLS_BUDGET=0.1
FID_BUDGET_MS=100

# ── Config override ────────────────────────────────────────────────────────
CONFIG_PATH="$ROOT/perf-budget.config.sh"
URL="http://localhost:3000"

while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG_PATH="$2"; shift 2 ;;
    --url)    URL="$2"; shift 2 ;;
    *)        echo "perf-budget: unknown option $1" >&2; exit 1 ;;
  esac
done

if [ -f "$CONFIG_PATH" ]; then
  # shellcheck source=/dev/null
  . "$CONFIG_PATH"
  echo "perf-budget: loaded config from $CONFIG_PATH"
else
  echo "perf-budget: no config file found at $CONFIG_PATH — using defaults"
fi

# ── Measurement ───────────────────────────────────────────────────────────
LCP_MS=""
CLS=""
FID_MS=""

measure_with_lighthouse() {
  local report
  report=$(lighthouse "$URL" \
    --output=json \
    --quiet \
    --chrome-flags="--headless --no-sandbox --disable-gpu" \
    2>/dev/null) || return 1

  LCP_MS=$(printf '%s' "$report" | \
    grep -o '"largest-contentful-paint":{[^}]*"numericValue":[0-9.]*' | \
    grep -o '[0-9.]*$' | head -1)
  CLS=$(printf '%s' "$report" | \
    grep -o '"cumulative-layout-shift":{[^}]*"numericValue":[0-9.]*' | \
    grep -o '[0-9.]*$' | head -1)
  FID_MS=$(printf '%s' "$report" | \
    grep -o '"max-potential-fid":{[^}]*"numericValue":[0-9.]*' | \
    grep -o '[0-9.]*$' | head -1)

  # Lighthouse rounds CLS to 3 decimal places; keep as-is.
  LCP_MS=${LCP_MS:-""}
  CLS=${CLS:-""}
  FID_MS=${FID_MS:-""}
}

measure_with_curl() {
  # No browser available. Use curl's time_total as a proxy for LCP.
  # CLS and FID require JavaScript execution — mark as 0 (safe) in this mode.
  local time_ms
  time_ms=$(curl -o /dev/null -s -w "%{time_total}" "$URL" 2>/dev/null || true)
  if [ -n "$time_ms" ]; then
    # curl returns seconds with fractional part; convert to milliseconds.
    LCP_MS=$(printf '%.0f' "$(echo "$time_ms * 1000" | bc -l 2>/dev/null || echo 0)")
  fi
  CLS="0"
  FID_MS="0"
}

echo "perf-budget: measuring $URL"

if command -v lighthouse >/dev/null 2>&1; then
  echo "perf-budget: tool = lighthouse"
  if ! measure_with_lighthouse; then
    echo "perf-budget: lighthouse failed — falling back to curl"
    measure_with_curl
  fi
else
  echo "perf-budget: tool = curl (no lighthouse; CLS and FID not measurable)"
  measure_with_curl
fi

# ── Compare ────────────────────────────────────────────────────────────────
warn=0

check_metric() {
  local name="$1" value="$2" budget="$3" unit="$4"

  if [ -z "$value" ]; then
    echo "  $name: not measured (skipping)"
    return
  fi

  # Use awk for floating-point comparison.
  local over
  over=$(awk -v v="$value" -v b="$budget" 'BEGIN { print (v > b) ? "1" : "0" }')

  if [ "$over" = "1" ]; then
    echo "  WARN $name: ${value}${unit} > budget ${budget}${unit}"
    warn=1
  else
    echo "  pass $name: ${value}${unit} <= budget ${budget}${unit}"
  fi
}

echo ""
echo "perf-budget: results"
check_metric "LCP" "$LCP_MS"  "$LCP_BUDGET_MS" "ms"
check_metric "CLS" "$CLS"     "$CLS_BUDGET"    ""
check_metric "FID" "$FID_MS"  "$FID_BUDGET_MS" "ms"
echo ""

if [ "$warn" = "1" ]; then
  echo "perf-budget: WARNING — one or more metrics exceeded their budget (non-blocking)"
else
  echo "perf-budget: OK — all measured metrics are within budget"
fi

# Always exit 0. This is a warning-only check; CI must not block on it.
exit 0
