#!/usr/bin/env bash
# F6 — the un-forgeable finish line, HOST-AGNOSTIC. The single check both CI hosts run on a
# PR/MR's exact head commit: re-run the deterministic floor on a machine the agent cannot touch.
# That server-side re-run is the only un-fakeable guarantee (the local pre-push hook is on the
# agent's own machine and is bypassable).
#
# GitHub Actions (.github/workflows/ci.yml) and GitLab CI (.gitlab-ci.yml) BOTH invoke this one
# script, so the check is identical across hosts — add a step here and every host stays in sync.
# Also runnable locally:  bash scripts/ci-verify.sh
#
# Deps are installed by the CI config (npm ci, host-idiomatic caching) before this runs.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

echo "ci-verify: lint"
npm run lint

echo "ci-verify: tests"
npm test

# Note: `npm test` above runs check-routing.test.sh (the routing logic, with mocked inputs).
# This step runs check-routing.sh LIVE against the real branch diff — the actual gate. The two
# are intentionally distinct: unit-test the logic, then enforce it on this branch.
echo "ci-verify: routing-assertion"
bash "$ROOT/scripts/check-routing.sh"

# Reference-integrity: catch broken cross-links in context docs before they rot.
# Only blocks the PR when this PR changes at least one .md file. A PR that touches no
# docs cannot introduce a new broken link, so the full-repo scan runs in advisory mode
# instead — it reports any pre-existing rot but does not fail CI on unrelated work.
echo "ci-verify: reference-integrity"
if git diff --name-only origin/main...HEAD 2>/dev/null | grep -q '\.md$'; then
  bash "$ROOT/scripts/check-integrity.sh"
else
  bash "$ROOT/scripts/check-integrity.sh" || echo "ci-verify: reference-integrity advisory (no .md files changed in this PR)"
fi

# Performance budget check. Non-blocking: a breach prints WARN lines but does
# not fail CI. The check requires measured metric data — either a --data FILE
# written by a Lighthouse or web-vitals CI step, or explicit metric flags.
# Without data the step is skipped cleanly.
# To wire in real measurements: set PERF_DATA_FILE to the path your Lighthouse
# step writes, or pass --lcp / --inp / --cls / --fcp / --ttfb directly.
# Example integration in a GitHub Actions workflow:
#   - name: Lighthouse CI
#     run: lhci collect && lhci assert --no-patch
#     env:
#       LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
#   - name: Export vitals for perf-budget
#     run: |
#       # write a perf-budget data file from Lighthouse JSON output
#       node -e "
#         const r = require('.lighthouseci/lhr-*.json');
#         const lcp = r.audits['largest-contentful-paint'].numericValue;
#         // ... extract other metrics ...
#         require('fs').writeFileSync('perf-data.json', JSON.stringify({LCP_ms: Math.round(lcp)}));
#       "
#       echo "PERF_DATA_FILE=perf-data.json" >> $GITHUB_ENV
echo "ci-verify: perf-budget"
PERF_DATA_FILE="${PERF_DATA_FILE:-}"
PERF_PROJECT="${PERF_PROJECT:-default}"
if [ -n "$PERF_DATA_FILE" ] && [ -f "$PERF_DATA_FILE" ]; then
  bash "$ROOT/scripts/perf-budget.sh" --project "$PERF_PROJECT" --data "$PERF_DATA_FILE" \
    || true  # exit code is always 0, but guard against unexpected failures
else
  echo "ci-verify: perf-budget advisory — no PERF_DATA_FILE set; skipping metric check."
  echo "ci-verify: Set PERF_DATA_FILE to a JSON file with measured vitals to enable."
  echo "ci-verify: See docs/perf-budget.md for data file format and integration steps."
fi

echo "ci-verify: OK"
