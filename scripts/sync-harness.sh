#!/usr/bin/env bash
# Update an installed harness from a newer source, without clobbering project knowledge.
#
# Reads .claude/.harness-manifest.json and walks every recorded file:
#   - "copy" files (harness-owned): updated from source when the local copy is unmodified.
#     If the user edited a copy file AND the source also changed it, that is a CONFLICT — the
#     file is left untouched and sync exits non-zero so CI fails and a human resolves it.
#   - "create-once" files (project-owned): never updated. Re-created from the template only if
#     the user deleted them (a delete means "restore the starter is the best we can do").
#
# Exit non-zero if any conflict is found. --dry-run reports what would change, writes nothing.
#
# Usage:
#   bash scripts/sync-harness.sh [TARGET_DIR]
#   bash scripts/sync-harness.sh --dry-run [TARGET_DIR]
#   HARNESS_SRC=/path/to/harness bash scripts/sync-harness.sh /path/to/target
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HARNESS_SRC="${HARNESS_SRC:-$(cd "$SCRIPT_DIR/.." && pwd)}"

DRY_RUN=0
args=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    *) args+=("$a") ;;
  esac
done
TARGET_DIR="${args[0]:-.}"

file_sha() { sha256sum "$1" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$1" | awk '{print $1}'; }
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

TARGET_DIR=$(cd "$TARGET_DIR" 2>/dev/null && pwd) || { echo "sync: target dir does not exist: ${args[0]:-.}" >&2; exit 1; }
manifest="$TARGET_DIR/.claude/.harness-manifest.json"
[ -f "$manifest" ] || { echo "sync: no manifest at $manifest — run install.sh first." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync: jq is required to read the manifest." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 \
  || { echo "sync: sha256sum or shasum is required." >&2; exit 1; }
[ -d "$HARNESS_SRC" ] || { echo "sync: HARNESS_SRC not found: $HARNESS_SRC" >&2; exit 1; }

# Map each create-once dest back to its source template (same table install.sh uses).
template_for() {
  case "$1" in
    CLAUDE.md)   echo "docs/templates/CLAUDE.md" ;;
    PITFALLS.md) echo "docs/templates/PITFALLS.md" ;;
    AGENTS.md)   echo "docs/templates/AGENTS.md" ;;
    CONTEXT.md)  echo "docs/templates/CONTEXT.md" ;;
    *)           echo "" ;;
  esac
}

# Collect new manifest sha values here as "relpath\tsha" so we can rewrite the manifest at the end.
new_shas=""
record_sha() { new_shas="${new_shas}${1}	${2}
"; }

conflicts=""
[ "$DRY_RUN" = 1 ] && echo "sync (dry-run): nothing will be written"

# Read manifest entries as "relpath<TAB>sha<TAB>policy".
while IFS=$'\t' read -r rel old_sha policy; do
  [ -z "$rel" ] && continue
  dstf="$TARGET_DIR/$rel"

  if [ "$policy" = "create-once" ]; then
    if [ ! -f "$dstf" ]; then
      tmpl=$(template_for "$rel"); srcf="$HARNESS_SRC/$tmpl"
      if [ -n "$tmpl" ] && [ -f "$srcf" ]; then
        if [ "$DRY_RUN" = 0 ]; then mkdir -p "$(dirname "$dstf")"; cp "$srcf" "$dstf"; fi
        echo "  re-created (was deleted): $rel"
        record_sha "$rel" "$(file_sha "$srcf")"
      else
        echo "  skipped (create-once, no template): $rel"
        record_sha "$rel" "$old_sha"
      fi
    else
      echo "  skipped (create-once): $rel"
      record_sha "$rel" "$old_sha"
    fi
    continue
  fi

  # policy == "copy"
  srcf="$HARNESS_SRC/$rel"
  if [ ! -f "$dstf" ]; then
    if [ -f "$srcf" ]; then
      if [ "$DRY_RUN" = 0 ]; then mkdir -p "$(dirname "$dstf")"; cp "$srcf" "$dstf"; fi
      echo "  re-created (was deleted): $rel"
      record_sha "$rel" "$(file_sha "$srcf")"
    else
      echo "  skipped (copy, source gone): $rel"
      record_sha "$rel" "$old_sha"
    fi
    continue
  fi
  if [ ! -f "$srcf" ]; then
    echo "  skipped (copy, source gone): $rel"
    record_sha "$rel" "$old_sha"
    continue
  fi

  local_sha=$(file_sha "$dstf")
  upstream_sha=$(file_sha "$srcf")

  if [ "$local_sha" = "$old_sha" ]; then          # unmodified since last install/sync
    if [ "$local_sha" = "$upstream_sha" ]; then
      echo "  up-to-date: $rel"
      record_sha "$rel" "$local_sha"
    else
      if [ "$DRY_RUN" = 0 ]; then cp "$srcf" "$dstf"; fi
      echo "  updated: $rel"
      record_sha "$rel" "$upstream_sha"
    fi
  elif [ "$local_sha" = "$upstream_sha" ]; then    # user edited it but it already matches upstream
    echo "  up-to-date: $rel"
    record_sha "$rel" "$local_sha"
  elif [ "$old_sha" = "$upstream_sha" ]; then       # user edited it; upstream unchanged — leave it
    echo "  local-edit (upstream unchanged): $rel"
    record_sha "$rel" "$local_sha"
  else                                             # user edited it AND upstream changed — conflict
    echo "  CONFLICT: $rel — local edits + upstream change; resolve manually and re-run"
    conflicts="${conflicts}${rel}
"
    record_sha "$rel" "$old_sha"
  fi
done < <(jq -r '.files | to_entries[] | "\(.key)\t\(.value.sha)\t\(.value.policy)"' "$manifest")

# Rewrite the manifest with refreshed shas + synced_at — unless dry-run, or any conflict exists
# (a conflict means the install is in an unresolved state; do not advance the recorded shas).
if [ "$DRY_RUN" = 0 ] && [ -z "$conflicts" ]; then
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  schema=$(jq -r '.schema' "$manifest")
  source=$(jq -r '.source' "$manifest")
  sha=$(jq -r '.sha' "$manifest")
  installed_at=$(jq -r '.installed_at' "$manifest")
  [ "$source" = "null" ] && { echo "sync: manifest missing 'source' field — re-run install.sh." >&2; exit 1; }
  tmp_manifest=$(mktemp "$(dirname "$manifest")/.harness-manifest.XXXXXX")
  {
    printf '{\n'
    printf '  "schema": %s,\n' "$schema"
    printf '  "source": "%s",\n' "$(json_escape "$source")"
    printf '  "sha": "%s",\n' "$(json_escape "$sha")"
    printf '  "installed_at": "%s",\n' "$installed_at"
    printf '  "synced_at": "%s",\n' "$now"
    printf '  "files": {\n'
    first=1
    while IFS=$'\t' read -r rel newsha; do
      [ -z "$rel" ] && continue
      pol=$(jq -r --arg k "$rel" '.files[$k].policy' "$manifest")
      [ "$first" = 1 ] || printf ',\n'
      first=0
      printf '    "%s": { "sha": "%s", "policy": "%s" }' "$(json_escape "$rel")" "$(json_escape "$newsha")" "$pol"
    done <<EOF
$new_shas
EOF
    printf '\n  }\n}\n'
  } > "$tmp_manifest"
  mv "$tmp_manifest" "$manifest"
fi

if [ -n "$conflicts" ]; then
  echo ""
  echo "sync: conflicts found — resolve these and re-run:" >&2
  printf '%s' "$conflicts" | while IFS= read -r c; do [ -n "$c" ] && echo "  $c" >&2; done
  exit 1
fi

echo ""
echo "sync: complete."
