#!/usr/bin/env bash
# scripts/test-local.sh — ADAPTER (per-project, project-agnostic by default).
#
# Role (defined by the harness): run the test suite against a LOCAL / ephemeral
# backend stack instead of whatever the default env points at — which, in many
# projects, is production. Running integration tests against prod is dangerous and
# usually useless for verifying a local change.
#
# Default behaviour (no local stack configured): just run the project's tests via
# `npm test`. A project with a local stack OVERRIDES this script to:
#   1. assert its local stack is running (else exit non-zero — fail closed),
#   2. export the local stack's credentials into the env the test runner reads,
#   3. assert those creds point at localhost (never prod) before running,
#   4. exec the test runner.
#
# See the harness docs for the override pattern. Keep the prod-safety assertion
# (step 3) in any override — it is the point of this script.
#
# Usage:
#   ./scripts/test-local.sh                 # all tests
#   ./scripts/test-local.sh path/to/test    # a subset (passed through to the runner)
set -euo pipefail

exec npm test -- "$@"
