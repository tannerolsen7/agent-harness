#!/usr/bin/env bash
# Checks staged .claude/skills/*/SKILL.md files for frontmatter problems that
# would silently break skill routing or discovery.
# Usage: bash scripts/skill-frontmatter-lint.sh <file1.md> [file2.md ...]
# Exit 0 = no violations. Exit 1 = violations found, details on stderr.
# Only single-line `name: value` / `description: value` frontmatter fields are
# supported. Multi-line YAML block scalars (`description: |` / `description: >`)
# are not parsed and will read as an empty value.
set -euo pipefail

# Strips one matching pair of leading/trailing quotes (" or ') from a value,
# so `name: "foo-bar"` and `name: foo-bar` are treated the same. Only matches
# when both ends actually have the same quote char, so a lone quote character
# is left alone.
strip_quotes() {
  local v=$1
  case "$v" in
    \"*\") v=${v#\"}; v=${v%\"} ;;
    \'*\') v=${v#\'}; v=${v%\'} ;;
  esac
  printf '%s' "$v"
}

found=0

for f in "$@"; do
  if [ ! -e "$f" ]; then
    continue
  fi
  if [ ! -f "$f" ]; then
    printf "%s: not a regular file\n" "$f" >&2
    found=1
    continue
  fi

  # Frontmatter is a --- delimited block at the very top of the file.
  # tr strips a trailing \r so CRLF-saved files aren't misread as missing it.
  if [ "$(head -1 "$f" | tr -d '\r')" != "---" ]; then
    printf "%s: no frontmatter block\n" "$f" >&2
    found=1
    continue
  fi

  # sub(/\r$/,"") normalizes CRLF line endings before any pattern match below.
  # The `|| { ... }` guard matters because this runs under set -e: without it,
  # a rare awk failure (e.g. a permissions race) would abort the whole script
  # mid-loop, silently skipping every file after the one that failed.
  frontmatter=$(awk '{sub(/\r$/,"")} /^---$/{c++; next} c==1{print} c>=2{exit}' "$f") || {
    printf "%s: could not read frontmatter (awk failed)\n" "$f" >&2
    found=1
    continue
  }
  # head -1 takes the first match if a field is duplicated — malformed YAML,
  # but not worth a dedicated check for a hand-authored SKILL.md file.
  name_val=$(printf '%s\n' "$frontmatter" | grep -E '^name:' | sed -E 's/^name:[[:space:]]*//' | head -1) || true
  desc_val=$(printf '%s\n' "$frontmatter" | grep -E '^description:' | sed -E 's/^description:[[:space:]]*//' | head -1) || true
  name_val=$(strip_quotes "$name_val")
  desc_val=$(strip_quotes "$desc_val")

  if ! printf '%s\n' "$frontmatter" | grep -qE '^name:'; then
    printf "%s: missing name: field\n" "$f" >&2
    found=1
  elif [ -z "$name_val" ]; then
    printf "%s: name: field is empty\n" "$f" >&2
    found=1
  fi

  if ! printf '%s\n' "$frontmatter" | grep -qE '^description:'; then
    printf "%s: missing description: field\n" "$f" >&2
    found=1
  elif [ -z "$desc_val" ]; then
    printf "%s: description: field is empty\n" "$f" >&2
    found=1
  fi

  # A bare filename with no parent directory (dirname returns ".") means the
  # caller didn't pass a path we can compare against — skip rather than
  # report a misleading "does not match directory '.'" false positive.
  dir_name=$(basename "$(dirname "$f")")
  if [ "$dir_name" != "." ] && [ -n "$name_val" ] && [ "$name_val" != "$dir_name" ]; then
    printf "%s: name '%s' does not match directory '%s'\n" "$f" "$name_val" "$dir_name" >&2
    found=1
  fi

  if [ -n "$desc_val" ]; then
    desc_len=${#desc_val}
    # 1024 matches the skill description length limit documented in
    # .claude/skills/write-a-skill/SKILL.md's Description Requirements.
    if [ "$desc_len" -gt 1024 ]; then
      printf "%s: description exceeds 1024 chars (%d)\n" "$f" "$desc_len" >&2
      found=1
    fi
    case "$desc_val" in
      *"Use when"*) ;;
      *)
        printf "%s: description is missing the 'Use when' trigger phrase\n" "$f" >&2
        found=1
        ;;
    esac
  fi
done

exit $found
