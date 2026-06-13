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

echo "ci-verify: OK"
