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

# Token lint: check UI files changed in this PR for hardcoded colors, spacing,
# and absolute design bans (gradient text, glassmorphism, side-stripe borders,
# hero-metric template, identical card grids, eyebrow-on-every-section).
# Inert when docs/design/DESIGN.md does not exist — projects without a design
# system are not blocked. Active the moment DESIGN.md is committed.
echo "ci-verify: token-lint"
bash "$ROOT/scripts/token-lint.sh" --diff

# Performance budget: measure Core Web Vitals and warn on breach. Advisory only — never blocks.
# Runs after tests so a broken build doesn't waste time measuring perf.
echo "ci-verify: perf-budget"
bash "$ROOT/scripts/perf-budget.sh" || echo "ci-verify: perf-budget advisory (see output above for details)"

# TESTING.md drift check: ensure the committed assembled file matches what assemble-testing.sh
# would produce. Catches manual edits, merge corruption, and assembly script regressions.
echo "ci-verify: testing-md-drift"
bash "$ROOT/scripts/assemble-testing.sh"
git diff --exit-code docs/TESTING.md || {
  echo "ci-verify: docs/TESTING.md is out of sync with docs/testing/*.md shards."
  echo "           Run: bash scripts/assemble-testing.sh"
  exit 1
}

echo "ci-verify: OK"
