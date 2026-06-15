#!/usr/bin/env bash
# Tests for scripts/classify-risk.sh — deterministic blast-radius classifier.
#
# Verifies: HIGH path patterns, HIGH content patterns, MEDIUM (default),
# LOW (docs-only), empty diff, and the over-classify rule.
# Also validates the run-classifier.sh pipeline against the real trap corpus.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CLASSIFY="$ROOT/scripts/classify-risk.sh"
RUN_CLASSIFIER="$ROOT/bug-catch/run-classifier.sh"
SCORE="$ROOT/bug-catch/score.sh"

[ -f "$CLASSIFY" ]        || { echo "classify-risk.test: $CLASSIFY not found"; exit 1; }
[ -f "$RUN_CLASSIFIER" ]  || { echo "classify-risk.test: $RUN_CLASSIFIER not found"; exit 1; }
[ -f "$SCORE" ]           || { echo "classify-risk.test: $SCORE not found"; exit 1; }

pass=0; fail=0
ok() { pass=$((pass+1)); }
no() { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

# Build a minimal synthetic diff for a single file path + one added line.
mkdiff() {
  local p="$1" body="${2:-+placeholder line}"
  printf 'diff --git a/%s b/%s\n--- a/%s\n+++ b/%s\n@@ -1 +1 @@\n%s\n' \
    "$p" "$p" "$p" "$p" "$body"
}

classify() { printf '%s\n' "$1" | bash "$CLASSIFY" 2>/dev/null; }

# ── HIGH: path-based signals ──────────────────────────────────────────────────

# Auth / session / identity
for p in \
  middleware.ts \
  src/middleware.ts \
  src/auth/handler.ts \
  src/authentication/provider.ts \
  src/authorization/policy.ts \
  pages/api/login.ts \
  pages/api/logout.ts \
  lib/session/store.ts \
  lib/token/verify.ts \
  lib/credential/check.ts \
  lib/oauth/callback.ts \
  lib/jwt/sign.ts; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "auth path '$p' → $r (want HIGH)"
done

# Admin routes
for p in src/app/api/admin/users/route.ts src/pages/admin/dashboard.tsx; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "admin path '$p' → $r (want HIGH)"
done

# RLS / policies
for p in supabase/policies/projects.sql db/rls/users.sql; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "rls path '$p' → $r (want HIGH)"
done

# Payments
for p in \
  src/app/api/checkout/route.ts \
  lib/stripe/webhook.ts \
  lib/billing/invoice.ts \
  src/payments/processor.ts \
  lib/pricing/tiers.ts; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "payments path '$p' → $r (want HIGH)"
done

# Schema / migrations
for p in \
  supabase/migrations/20240101_add_rls.sql \
  db/migrations/0042_drop_column.sql \
  prisma/schema.prisma \
  db/schema.sql \
  db/database/schema.ts; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "schema path '$p' → $r (want HIGH)"
done

# Framework config
for p in next.config.ts next.config.js src/next.config.mjs vercel.json; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "HIGH" ] && ok || no "config path '$p' → $r (want HIGH)"
done

# ── HIGH: content-based signals ───────────────────────────────────────────────

# RLS using (true) — the canonical trap (case 009)
r=$(classify "$(mkdiff "safe.sql" "+alter policy \"x\" on t using (true);")")
[ "$r" = "HIGH" ] && ok || no "content: using (true) → $r (want HIGH)"

# RLS policy DDL
for sql in \
  "+alter policy test on t using (true);" \
  "+create policy test on t as permissive for all to anon using (true);" \
  "+drop policy test on t;" \
  "+alter table t enable row level security;"; do
  r=$(classify "$(mkdiff "safe.sql" "$sql")")
  [ "$r" = "HIGH" ] && ok || no "content: RLS '$sql' → $r (want HIGH)"
done

# Schema DDL — includes the drop not null trap (case 013)
for sql in \
  "+alter table orders alter column user_id drop not null;" \
  "+alter table users add column is_admin boolean;" \
  "+drop table sessions;" \
  "+create table api_keys (id uuid primary key);" \
  "+drop column user_id;" \
  "+drop constraint orders_user_id_fkey;" \
  "+drop index idx_users_email;"; do
  r=$(classify "$(mkdiff "safe.sql" "$sql")")
  [ "$r" = "HIGH" ] && ok || no "content: schema DDL '$sql' → $r (want HIGH)"
done

# SQL GRANT / REVOKE
r=$(classify "$(mkdiff "safe.sql" "+grant select on projects to anon;")")
[ "$r" = "HIGH" ] && ok || no "content: grant → $r (want HIGH)"
r=$(classify "$(mkdiff "safe.sql" "+revoke all on projects from authenticated;")")
[ "$r" = "HIGH" ] && ok || no "content: revoke → $r (want HIGH)"

# ── Over-classify rule: mixed diff with one HIGH path → still HIGH ────────────

mixed_diff="$(mkdiff "src/utils/format.ts")
$(mkdiff "middleware.ts")"
r=$(printf '%s\n' "$mixed_diff" | bash "$CLASSIFY" 2>/dev/null)
[ "$r" = "HIGH" ] && ok || no "over-classify: mixed (format.ts + middleware.ts) → $r (want HIGH)"

# ── MEDIUM: regular code files (no HIGH signals) ──────────────────────────────

for p in \
  src/utils/format.ts \
  src/components/Button.tsx \
  lib/helpers/date.ts \
  src/app/page.tsx; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "MEDIUM" ] && ok || no "medium path '$p' → $r (want MEDIUM)"
done

# ── LOW: docs-only changes ────────────────────────────────────────────────────

for p in \
  README.md \
  docs/getting-started.md \
  CHANGELOG.md \
  docs/api/overview.mdx \
  .github/CONTRIBUTING.md; do
  r=$(classify "$(mkdiff "$p")")
  [ "$r" = "LOW" ] && ok || no "low (docs) '$p' → $r (want LOW)"
done

# ── LOW: empty diff ───────────────────────────────────────────────────────────

r=$(printf '' | bash "$CLASSIFY" 2>/dev/null)
[ "$r" = "LOW" ] && ok || no "empty diff → $r (want LOW)"

# ── Integration: run-classifier.sh + score.sh --traps ────────────────────────
# All 5 trap cases (path: HIGH, tier: HIGH) must be caught by the classifier.

tsv=$(bash "$RUN_CLASSIFIER" 2>/dev/null)
trap_count=$(printf '%s\n' "$tsv" | grep -c '	caught' || true)
miss_count=$(printf '%s\n' "$tsv" | grep -c '	missed' || true)

[ "$trap_count" -eq 5 ] && ok || no "run-classifier: caught=$trap_count (want 5)"
[ "$miss_count" -eq 0 ] && ok || no "run-classifier: missed=$miss_count (want 0)"

# Pipe through score.sh --traps; lower bound must be above 0 (gate present)
score_out=$(printf '%s\n' "$tsv" | bash "$SCORE" --traps /dev/stdin 2>/dev/null)
lb=$(printf '%s\n' "$score_out" | awk '/lower bound:.*classifier/{gsub(/%.*/, ""); for(i=1;i<=NF;i++) if($i+0>0) {print $i+0; exit}}')
[ "${lb:-0}" != "0" ] && ok || no "score --traps: lower bound is 0 or missing (got '$lb')"

# Exit code from score --traps must be 0 (all traps in run)
printf '%s\n' "$tsv" | bash "$SCORE" --traps /dev/stdin >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok || no "score --traps exit code: $rc (want 0)"

echo ""
echo "classify-risk: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
