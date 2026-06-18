#!/usr/bin/env bash
# Tests for scripts/perf-budget.sh — Core Web Vitals budget check.
#
# Covers:
#   pass path  — all metrics under budget: exits 0, prints "pass" lines, no "WARN"
#   warn path  — one metric over budget: exits 1 (non-zero), prints "WARN" for that metric
#   config     — a project config file overrides the defaults
#   fallback   — curl fallback (no lighthouse) exits 0 and prints results
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/perf-budget.sh"

[ -x "$SCRIPT" ] || { echo "perf-budget.test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── Helper: run the script with a fake lighthouse or fake curl ────────────────

# Writes a fake "lighthouse" binary that emits a minimal JSON report with the
# supplied metric values, then runs perf-budget.sh.
#
# Usage: run_with_lighthouse <lcp_ms> <cls> <fid_ms>
run_with_lighthouse() {
  local lcp="$1" cls="$2" fid="$3"
  local fake_bin="$TMP/fake-bin-$$"
  mkdir -p "$fake_bin"

  # Write a shell script that outputs just enough JSON for perf-budget.sh's grep.
  cat >"$fake_bin/lighthouse" <<EOFLH
#!/usr/bin/env sh
printf '{"largest-contentful-paint":{"numericValue":%s},"cumulative-layout-shift":{"numericValue":%s},"experimental_interaction-to-next-paint":{"numericValue":%s}}' \
  "$lcp" "$cls" "$fid"
EOFLH
  chmod +x "$fake_bin/lighthouse"

  PATH="$fake_bin:$PATH" bash "$SCRIPT" --url "http://fake.test" 2>&1
}

# Writes a fake "curl" binary that returns a fixed time_total, removes lighthouse
# from PATH so the script uses the curl fallback, and runs perf-budget.sh.
#
# Usage: run_with_curl <time_total_seconds>
run_with_curl() {
  local time_sec="$1"
  local fake_bin="$TMP/fake-curl-$$"
  mkdir -p "$fake_bin"

  cat >"$fake_bin/curl" <<EOFCURL
#!/usr/bin/env sh
# Print the time_total value in the format curl uses with -w "%{time_total}".
printf '%s' "$time_sec"
EOFCURL
  chmod +x "$fake_bin/curl"

  # Put fake-bin first; exclude any real lighthouse so the fallback path fires.
  PATH="$fake_bin:/usr/bin:/bin" bash "$SCRIPT" --url "http://fake.test" 2>&1
}

# ── pass path: all metrics within budget ─────────────────────────────────────

out=$(run_with_lighthouse 1800 0.05 60)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "pass path: exit code $rc (want 0)"

printf '%s\n' "$out" | grep -q "pass LCP" \
  && ok \
  || no "pass path: expected 'pass LCP' in output"

printf '%s\n' "$out" | grep -q "pass CLS" \
  && ok \
  || no "pass path: expected 'pass CLS' in output"

printf '%s\n' "$out" | grep -q "pass INP" \
  && ok \
  || no "pass path: expected 'pass INP' in output"

printf '%s\n' "$out" | grep -q "OK" \
  && ok \
  || no "pass path: expected 'OK' summary line in output"

! printf '%s\n' "$out" | grep -q "WARN" \
  && ok \
  || no "pass path: unexpected 'WARN' in output when all metrics are within budget"

# ── warn path: LCP over budget ────────────────────────────────────────────────
# A breach exits 1; ci-verify.sh uses || to make it non-blocking in CI.

out=$(run_with_lighthouse 3500 0.05 60)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "warn path: exit code $rc (want 1 on breach)"

printf '%s\n' "$out" | grep -q "WARN LCP" \
  && ok \
  || no "warn path: expected 'WARN LCP' when LCP=3500ms > budget 2500ms"

printf '%s\n' "$out" | grep -q "pass CLS" \
  && ok \
  || no "warn path: CLS should still pass when only LCP is over budget"

printf '%s\n' "$out" | grep -q "pass INP" \
  && ok \
  || no "warn path: FID should still pass when only LCP is over budget"

printf '%s\n' "$out" | grep -q "WARNING" \
  && ok \
  || no "warn path: expected 'WARNING' summary line when a metric is breached"

# ── config override: custom LCP budget ───────────────────────────────────────
# A project config tightens the LCP budget to 1000 ms.
# Measurement returns 1200 ms, which is under the default 2500 but over the custom 1000.

CONFIG="$TMP/custom.config.sh"
printf 'LCP_BUDGET_MS=1000\n' > "$CONFIG"

out=$(PATH="$TMP/fake-bin-$$:$PATH" \
  run_with_lighthouse 1200 0.05 60)
# Re-run with config to test override.
local_fake="$TMP/fake-lh-cfg"
mkdir -p "$local_fake"
cat >"$local_fake/lighthouse" <<EOFLHCFG
#!/usr/bin/env sh
printf '{"largest-contentful-paint":{"numericValue":1200},"cumulative-layout-shift":{"numericValue":0.05},"experimental_interaction-to-next-paint":{"numericValue":60}}'
EOFLHCFG
chmod +x "$local_fake/lighthouse"

out=$(PATH="$local_fake:$PATH" bash "$SCRIPT" --url "http://fake.test" --config "$CONFIG" 2>&1)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "config: exit code $rc (want 1 — LCP breaches the 1000ms custom budget)"

printf '%s\n' "$out" | grep -q "WARN LCP" \
  && ok \
  || no "config: expected 'WARN LCP' — 1200ms should exceed the 1000ms custom budget"

# ── curl fallback: no lighthouse available ────────────────────────────────────

out=$(run_with_curl 1.5)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "curl fallback: exit code $rc (want 0)"

# CLS and INP are 0 in curl mode — they pass automatically.
printf '%s\n' "$out" | grep -q "pass CLS" \
  && ok \
  || no "curl fallback: expected 'pass CLS: 0' (not measurable, defaults to 0)"

printf '%s\n' "$out" | grep -q "pass INP" \
  && ok \
  || no "curl fallback: expected 'pass INP: 0' (not measurable, defaults to 0)"

# LCP in curl mode = 1500ms (1.5 s * 1000), within the 2500ms default budget.
printf '%s\n' "$out" | grep -q "pass LCP" \
  && ok \
  || no "curl fallback: expected 'pass LCP' for 1500ms vs 2500ms budget"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "perf-budget: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
