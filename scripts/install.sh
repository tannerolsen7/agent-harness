#!/usr/bin/env bash
# One-command install: copy the harness into a target git repo as an add-on.
#
# What it does:
#   - Copies category-1 ("copy") files — the harness owns these forever (skills, agents, hooks,
#     scripts, settings.json, harness docs, husky hooks). Always written.
#   - Copies category-2 ("create-once") files from docs/templates/ — CLAUDE.md, PITFALLS.md,
#     AGENTS.md, CONTEXT.md. Written only if they do not already exist; never clobbered.
#   - Writes .claude/.harness-manifest.json LAST. If the script dies mid-run, no manifest exists
#     and a re-run reinstalls everything safely. The install is idempotent by design.
#
# No network calls. HARNESS_SRC is always a local path. The user clones the harness separately.
#
# Usage:
#   bash scripts/install.sh [TARGET_DIR]      # TARGET_DIR defaults to the current directory
#   HARNESS_SRC=/path/to/harness bash scripts/install.sh /path/to/target
set -euo pipefail

# HARNESS_SRC defaults to the repo root that contains this script (scripts/ -> repo root).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HARNESS_SRC="${HARNESS_SRC:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TARGET_DIR="${1:-.}"

# Portable sha256 of a file: GNU coreutils (sha256sum) first, macOS (shasum -a 256) as fallback.
file_sha() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$1" | cut -d' ' -f1; }

# JSON string escape: backslash and double-quote are the only chars our paths/shas can contain.
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

[ -d "$HARNESS_SRC" ] || { echo "install: HARNESS_SRC not found: $HARNESS_SRC" >&2; exit 1; }

# TARGET_DIR must be the root of a git repo. We resolve to an absolute path first.
TARGET_DIR=$(cd "$TARGET_DIR" 2>/dev/null && pwd) || { echo "install: target dir does not exist: ${1:-.}" >&2; exit 1; }
if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "install: $TARGET_DIR is not a git repository." >&2
  echo "  Run 'git init' there first, or pass a path to a git repo root." >&2
  exit 1
fi

# ── Category-1: directories the harness owns and always overwrites on install/sync. ──
# Each entry is a directory copied whole; every file inside gets a "copy" manifest entry.
COPY_DIRS=".claude/skills .claude/agents .claude/hooks docs/engineering-system docs/security scripts"
# Category-1 single files (not whole directories).
COPY_FILES=".claude/settings.json .claude/AI-WORKFLOW.md .claude/agent-contract.md .claude/SOUL.md .husky/pre-commit .husky/pre-push .husky/post-checkout"

# ── Category-2: create-once files installed from a template in docs/templates/. ──
# Format: "<dest path in target>:<template path in source>".
CREATE_ONCE="CLAUDE.md:docs/templates/CLAUDE.md PITFALLS.md:docs/templates/PITFALLS.md AGENTS.md:docs/templates/AGENTS.md CONTEXT.md:docs/templates/CONTEXT.md"

# Manifest entries accumulate here as "relpath\tsha\tpolicy" lines, joined into JSON at the end.
manifest_lines=""
add_manifest() { manifest_lines="${manifest_lines}${1}	${2}	${3}
"; }

copy_one() {
  # copy_one <relpath> : install a single category-1 file, record a "copy" manifest entry.
  local rel="$1" srcf="$HARNESS_SRC/$1" dstf="$TARGET_DIR/$1"
  [ -f "$srcf" ] || return 0
  mkdir -p "$(dirname "$dstf")"
  if [ -f "$dstf" ] && [ "$(file_sha "$srcf")" = "$(file_sha "$dstf")" ]; then
    echo "  skipped (up to date): $rel"
  else
    cp "$srcf" "$dstf"
    echo "  installed: $rel"
  fi
  add_manifest "$rel" "$(file_sha "$srcf")" "copy"
}

echo "Installing harness from $HARNESS_SRC into $TARGET_DIR"

# Category-1 directories: walk every file under each, install + record it.
for d in $COPY_DIRS; do
  [ -d "$HARNESS_SRC/$d" ] || continue
  while IFS= read -r f; do
    rel="${f#"$HARNESS_SRC"/}"
    copy_one "$rel"
  done < <(find "$HARNESS_SRC/$d" -type f | sort)
done

# Category-1 single files.
for rel in $COPY_FILES; do
  copy_one "$rel"
done

# Category-2 create-once files: install from template only when missing.
for pair in $CREATE_ONCE; do
  dest="${pair%%:*}"; tmpl="${pair#*:}"
  srcf="$HARNESS_SRC/$tmpl"; dstf="$TARGET_DIR/$dest"
  [ -f "$srcf" ] || { echo "  warning: template missing, cannot create $dest (no $tmpl)"; continue; }
  if [ -f "$dstf" ]; then
    echo "  skipped (exists): $dest"
  else
    mkdir -p "$(dirname "$dstf")"
    cp "$srcf" "$dstf"
    echo "  installed: $dest"
  fi
  # Record the template sha for audit. Drift detection ignores it for create-once entries.
  add_manifest "$dest" "$(file_sha "$srcf")" "create-once"
done

# ── Write the manifest LAST. Source sha = harness git sha, or "local" for a dirty/non-git source. ──
src_sha="local"
if git -C "$HARNESS_SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$HARNESS_SRC" diff --quiet 2>/dev/null && git -C "$HARNESS_SRC" diff --cached --quiet 2>/dev/null; then
    src_sha=$(git -C "$HARNESS_SRC" rev-parse HEAD 2>/dev/null || echo local)
  fi
fi
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$TARGET_DIR/.claude"
manifest="$TARGET_DIR/.claude/.harness-manifest.json"
{
  printf '{\n'
  printf '  "schema": 1,\n'
  printf '  "source": "%s",\n' "$(json_escape "$HARNESS_SRC")"
  printf '  "sha": "%s",\n' "$(json_escape "$src_sha")"
  printf '  "installed_at": "%s",\n' "$now"
  printf '  "synced_at": "%s",\n' "$now"
  printf '  "files": {\n'
  first=1
  while IFS=$'\t' read -r rel sha policy; do
    [ -z "$rel" ] && continue
    [ "$first" = 1 ] || printf ',\n'
    first=0
    printf '    "%s": { "sha": "%s", "policy": "%s" }' "$(json_escape "$rel")" "$(json_escape "$sha")" "$policy"
  done <<EOF
$manifest_lines
EOF
  printf '\n  }\n}\n'
} > "$manifest"

echo "  installed: .claude/.harness-manifest.json"
echo ""
echo "Done. Next steps:"
echo "  1. bash scripts/install-harness-hooks.sh   # wire git hooks (inspectable; runs npm install)"
echo "  2. bash scripts/install-locks.sh           # optional OS-level locks (requires sudo)"
echo "  3. Open Claude Code in this directory and run /init"
