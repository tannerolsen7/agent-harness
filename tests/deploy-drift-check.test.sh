#!/usr/bin/env bash
# Tests for scripts/deploy-drift-check.sh — the manifest-presence layer of the deploy-drift gate.
#
# Covers:
#   absent-manifest                 — no deploy-targets.yml → exit 0, no output
#   all-gated                       — all entries have drift_check → exit 0, OK lines
#   required-missing                — required entry missing drift_check → exit 1, MISSING line
#   empty-string drift_check        — drift_check: "" → same as missing → exit 1
#   advisory-missing                — required: false entry missing drift_check → exit 0, WARN line
#   mixed                           — one required fails + one advisory → exit 1, reports both
#   harness-deploy-targets-env-var  — HARNESS_DEPLOY_TARGETS path override works
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/deploy-drift-check.sh"

[ -x "$SCRIPT" ] || { echo "deploy-drift-check.test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── absent-manifest: no file → exit 0, no output ─────────────────────────────

out=$(HARNESS_DEPLOY_TARGETS="$TMP/does-not-exist.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "absent-manifest: exit code $rc (want 0)"

[ -z "$out" ] \
  && ok \
  || no "absent-manifest: expected no output, got: $out"

# ── all-gated: every entry has drift_check → exit 0, OK lines ────────────────

cat > "$TMP/all-gated.yml" <<'YAML'
- name: prod-db
  kind: db-migrations
  drift_check: "supabase db push --dry-run"
- name: staging-flags
  kind: feature-flags
  drift_check: "flagtool diff --env staging"
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/all-gated.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "all-gated: exit code $rc (want 0)"

printf '%s\n' "$out" | grep -q "deploy-drift: OK prod-db" \
  && ok \
  || no "all-gated: expected 'deploy-drift: OK prod-db' in output"

printf '%s\n' "$out" | grep -q "deploy-drift: OK staging-flags" \
  && ok \
  || no "all-gated: expected 'deploy-drift: OK staging-flags' in output"

! printf '%s\n' "$out" | grep -q "MISSING\|WARN" \
  && ok \
  || no "all-gated: unexpected MISSING or WARN in output"

# ── required-missing: required entry has no drift_check → exit 1, MISSING ────

cat > "$TMP/required-missing.yml" <<'YAML'
- name: prod-db
  kind: db-migrations
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/required-missing.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "required-missing: exit code $rc (want 1)"

printf '%s\n' "$out" | grep -q "deploy-drift: MISSING drift_check for 'prod-db'" \
  && ok \
  || no "required-missing: expected MISSING line for 'prod-db'"

# ── required-missing: multiple entries, all reported before exit ──────────────

cat > "$TMP/multi-missing.yml" <<'YAML'
- name: prod-db
  kind: db-migrations
- name: prod-secrets
  kind: secrets
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/multi-missing.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "multi-missing: exit code $rc (want 1)"

printf '%s\n' "$out" | grep -q "MISSING.*prod-db" \
  && ok \
  || no "multi-missing: expected MISSING for prod-db"

printf '%s\n' "$out" | grep -q "MISSING.*prod-secrets" \
  && ok \
  || no "multi-missing: expected MISSING for prod-secrets"

# ── empty-string drift_check: treated as missing → exit 1 ────────────────────

cat > "$TMP/empty-dc.yml" <<'YAML'
- name: prod-db
  kind: db-migrations
  drift_check: ""
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/empty-dc.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "empty-string: exit code $rc (want 1 — empty drift_check is same as missing)"

printf '%s\n' "$out" | grep -q "MISSING.*prod-db" \
  && ok \
  || no "empty-string: expected MISSING for prod-db with empty drift_check"

# ── advisory-missing: required: false + no drift_check → exit 0, WARN ────────

cat > "$TMP/advisory.yml" <<'YAML'
- name: staging-flags
  kind: feature-flags
  required: false
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/advisory.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "advisory: exit code $rc (want 0)"

printf '%s\n' "$out" | grep -q "deploy-drift: WARN staging-flags" \
  && ok \
  || no "advisory: expected 'deploy-drift: WARN staging-flags'"

! printf '%s\n' "$out" | grep -q "MISSING" \
  && ok \
  || no "advisory: unexpected MISSING in output for required: false entry"

# ── mixed: one required fails, one advisory → exit 1, both reported ──────────

cat > "$TMP/mixed.yml" <<'YAML'
- name: prod-db
  kind: db-migrations
- name: staging-flags
  kind: feature-flags
  required: false
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/mixed.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 1 ] \
  && ok \
  || no "mixed: exit code $rc (want 1 — required entry fails)"

printf '%s\n' "$out" | grep -q "MISSING.*prod-db" \
  && ok \
  || no "mixed: expected MISSING for prod-db"

printf '%s\n' "$out" | grep -q "WARN.*staging-flags" \
  && ok \
  || no "mixed: expected WARN for staging-flags"

# ── HARNESS_DEPLOY_TARGETS env var: custom absolute path ──────────────────────

cat > "$TMP/custom.yml" <<'YAML'
- name: custom-step
  kind: infra
  drift_check: "terraform plan -detailed-exitcode"
YAML

out=$(HARNESS_DEPLOY_TARGETS="$TMP/custom.yml" bash "$SCRIPT" 2>&1)
rc=$?

[ "$rc" -eq 0 ] \
  && ok \
  || no "env-var: exit code $rc (want 0)"

printf '%s\n' "$out" | grep -q "deploy-drift: OK custom-step" \
  && ok \
  || no "env-var: expected 'deploy-drift: OK custom-step' when using HARNESS_DEPLOY_TARGETS"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "deploy-drift-check: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
