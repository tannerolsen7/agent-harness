#!/usr/bin/env bash
# Plugin-level SessionStart hook: check if per-project harness files are behind the plugin.
# Runs a dry-run sync and prints one line when updates or conflicts are pending.
# Always exits 0 — never blocks session startup.
set -euo pipefail

[ -n "${CLAUDE_PROJECT_DIR:-}" ] || exit 0
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0

MANIFEST="${CLAUDE_PROJECT_DIR:-}/.claude/.harness-manifest.json"
[ -f "$MANIFEST" ] || exit 0

output=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-harness.sh" --dry-run "${CLAUDE_PROJECT_DIR}" 2>&1) || true

case "$output" in
  *'updated:'*) echo "[harness] project files are out of date — run /sync to apply updates" ;;
  *'CONFLICT'*) echo "[harness] sync conflict detected — run /sync and resolve manually" ;;
  *'re-created'*) echo "[harness] harness files are missing — run /sync to restore them" ;;
esac

exit 0
