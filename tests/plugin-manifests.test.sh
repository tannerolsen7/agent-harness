#!/usr/bin/env bash
# Tests for .claude-plugin/plugin.json and .claude-plugin/marketplace.json
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE 2>/dev/null || true

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"
MARKET_JSON="$ROOT/.claude-plugin/marketplace.json"

command -v jq >/dev/null 2>&1 || { echo "plugin-manifests.test: jq is required"; exit 1; }

pass=0; fail=0
ok()  { pass=$((pass+1)); }
no()  { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

# ── plugin.json ───────────────────────────────────────────────────────────────

[ -f "$PLUGIN_JSON" ] && ok || { no "plugin.json not found"; echo "plugin-manifests: $pass passed, $fail failed"; exit 1; }

jq -e . "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json is not valid JSON"
jq -e '.name' "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json missing .name"
jq -e '.description' "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json missing .description"
jq -e '.version' "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json missing .version"
jq -e '.author.name' "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json missing .author.name"
jq -e '.license' "$PLUGIN_JSON" >/dev/null 2>&1 && ok || no "plugin.json missing .license"
jq -e '.agents | (type == "array" and length > 0)' "$PLUGIN_JSON" >/dev/null 2>&1 \
  && ok || no "plugin.json .agents must be a non-empty array of file paths"
jq -e '.commands | (type == "array" and length > 0)' "$PLUGIN_JSON" >/dev/null 2>&1 \
  && ok || no "plugin.json .commands must be a non-empty array of file paths"
jq -e '.skills == null' "$PLUGIN_JSON" >/dev/null 2>&1 \
  && ok || no "plugin.json must not have .skills (field was renamed to .commands)"

# ── marketplace.json ──────────────────────────────────────────────────────────

[ -f "$MARKET_JSON" ] && ok || { no "marketplace.json not found"; echo "plugin-manifests: $pass passed, $fail failed"; exit 1; }

jq -e . "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json is not valid JSON"
jq -e '."$schema"' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json missing .\$schema"
jq -e '.name' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json missing .name"
jq -e '.owner.name' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json missing .owner.name"
jq -e '.autoUpdate == true' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json .autoUpdate must be true"
jq -e '.plugins | length > 0' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json .plugins must be non-empty"
jq -e '.plugins[0].name' "$MARKET_JSON" >/dev/null 2>&1 && ok || no "marketplace.json plugins[0] missing .name"
jq -e '.plugins[0].source.source == "github"' "$MARKET_JSON" >/dev/null 2>&1 \
  && ok || no "marketplace.json plugins[0].source.source must be \"github\""
jq -e '.plugins[0].source.repo == "tannerolsen7/agent-harness"' "$MARKET_JSON" >/dev/null 2>&1 \
  && ok || no "marketplace.json plugins[0].source.repo must be \"tannerolsen7/agent-harness\""

echo "plugin-manifests: $pass passed, $fail failed"
[ "$fail" = "0" ]
