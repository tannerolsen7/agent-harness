#!/usr/bin/env bash
# Routing-assertion (merge-time) — scripts/check-routing.sh. Uses the test-only overrides
# (ROUTING_CONFIG/CHANGED/DIFF/TRAILERS) so it's pure: no temp git repo, no network.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CHECK="$ROOT/scripts/check-routing.sh"
[ -f "$CHECK" ] || { echo "check-routing.test: $CHECK not found"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "check-routing.test: node required"; exit 1; }

pass=0; fail=0
TMP=$(mktemp -d)
CFG="$TMP/routing.json"
cat > "$CFG" <<'JSON'
{
  "highRiskPathPatterns": ["(^|/)migrations?/"],
  "highRiskContentPatterns": ["create policy", "\\bRLS\\b", "stripe"],
  "requiredTrailer": "DB-Safety"
}
JSON

run() { # run <expect 0|1|2> <changed> <diff> <trailers> [config]
  local expect="$1" rc
  ROUTING_CONFIG="${5:-$CFG}" ROUTING_CHANGED="$2" ROUTING_DIFF="$3" ROUTING_TRAILERS="$4" \
    bash "$CHECK" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$expect" ]; then pass=$((pass+1)); else echo "  MISS: want exit $expect, got $rc (changed='$2')"; fail=$((fail+1)); fi
}

# 1. high-risk PATH, no trailer → BLOCK (1)
run 1 "src/db/migrations/001_init.sql" "" ""
# 2. high-risk path WITH trailer → OK (0)
run 0 "src/db/migrations/001_init.sql" "" "feat: add table

DB-Safety: supabase"
# 3. high-risk CONTENT (create policy), no trailer → BLOCK
run 1 "src/app.ts" "+create policy tenant_isolation on orders" ""
# 4. high-risk content WITH trailer → OK
run 0 "src/app.ts" "+CREATE POLICY tenant_isolation ON orders" "fix

DB-Safety: supabase"
# 5. content match is case-insensitive (STRIPE) + no trailer → BLOCK
run 1 "src/pay.ts" "+const s = new STRIPE(key)" ""
# 6. no high-risk match → OK regardless of trailer
run 0 "src/ui/button.tsx" "+export const Button = () => null" ""
# 7. no config → inert (0)
run 0 "src/db/migrations/001.sql" "" "" "/nonexistent/routing.json"

rm -rf "$TMP"
echo ""
echo "check-routing: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
