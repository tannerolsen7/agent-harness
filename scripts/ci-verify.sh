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

# Reference-integrity: catch broken cross-links in context docs before they rot (CMP4).
# Runs server-side so a dead link in a knowledge doc fails the PR, not a future reader.
echo "ci-verify: reference-integrity"
bash "$ROOT/scripts/check-integrity.sh"

echo "ci-verify: OK"
