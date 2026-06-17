#!/usr/bin/env bash
# F6 host-agnostic CI gate: both CI configs must exist and invoke the SAME shared check
# (scripts/ci-verify.sh), so the verdict is identical across GitHub and GitLab. Structural —
# it can't run the real cloud CI, but it guarantees the two configs can't silently diverge.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

pass=0; fail=0
need() { if [ -f "$1" ]; then pass=$((pass+1)); else echo "  MISSING: $1"; fail=$((fail+1)); fi; }
calls() { if grep -q 'ci-verify.sh' "$1"; then pass=$((pass+1)); else echo "  $1 does not invoke scripts/ci-verify.sh"; fail=$((fail+1)); fi; }

need scripts/ci-verify.sh
[ -x scripts/ci-verify.sh ] && pass=$((pass+1)) || { echo "  scripts/ci-verify.sh not executable"; fail=$((fail+1)); }
need .github/workflows/ci.yml
need .gitlab-ci.yml

calls .github/workflows/ci.yml
calls .gitlab-ci.yml

# The shared check must actually run the deterministic floor (lint + tests).
grep -q 'npm run lint' scripts/ci-verify.sh && pass=$((pass+1)) || { echo "  ci-verify.sh does not run lint"; fail=$((fail+1)); }
grep -q 'npm test'     scripts/ci-verify.sh && pass=$((pass+1)) || { echo "  ci-verify.sh does not run tests"; fail=$((fail+1)); }
# Reference-integrity (CMP4) must run in the shared check, or context-doc rot ships unblocked.
grep -q 'check-integrity.sh' scripts/ci-verify.sh && pass=$((pass+1)) || { echo "  ci-verify.sh does not run check-integrity"; fail=$((fail+1)); }

echo ""
echo "ci-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
