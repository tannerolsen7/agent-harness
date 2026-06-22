#!/usr/bin/env bash
# Checks that every required deploy step in deploy-targets.yml has a drift_check
# command declared. This is the manifest-presence layer of the deploy-drift gate:
# it reads the manifest file and confirms each required entry names a drift_check
# command. It does not run any drift_check commands.
# For the full gate design, see docs/adr/0002-deploy-drift-gate.md.
#
# Exits 0 when all required entries have a drift_check, or when the manifest is
# absent (the project has not opted in). Exits 1 when any required entry is missing
# a drift_check command.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

MANIFEST="${HARNESS_DEPLOY_TARGETS:-$ROOT/deploy-targets.yml}"

# If the path exists but is not a regular file (e.g. a directory was passed),
# fail loudly instead of silently passing.
if [ -e "$MANIFEST" ] && [ ! -f "$MANIFEST" ]; then
  printf "deploy-drift: ERROR manifest path is not a regular file: %s\n" "$MANIFEST" >&2
  exit 1
fi

# No manifest means the project has not opted in. Pass silently.
[ -f "$MANIFEST" ] || exit 0

awk '
function strip_quotes(s) { gsub(/^["'"'"']|["'"'"']$/, "", s); return s }

BEGIN { name=""; has_drift_check=0; is_advisory=0; fail=0; in_entry=0 }

/^- name:/ {
  if (in_entry) check_entry()
  in_entry=1; has_drift_check=0; is_advisory=0
  name=$0
  sub(/^- name:[[:space:]]*/, "", name)
  name=strip_quotes(name)
}

/^- / && !/^- name:/ {
  if (in_entry) check_entry()
  printf "deploy-drift: WARN entry does not start with a name: field — skipped\n"
  in_entry=0; has_drift_check=0; is_advisory=0; name=""
}

/^[[:space:]]+drift_check:/ {
  drift_check_val=$0
  sub(/^[[:space:]]+drift_check:[[:space:]]*/, "", drift_check_val)
  if (strip_quotes(drift_check_val) != "") has_drift_check=1
}

/^[[:space:]]+required:[[:space:]]+false/ { is_advisory=1 }

END {
  if (in_entry) check_entry()
  exit fail
}

function check_entry() {
  if (!has_drift_check) {
    if (is_advisory) {
      printf "deploy-drift: WARN %s\n", name
    } else {
      printf "deploy-drift: MISSING drift_check for '"'"'%s'"'"'\n", name
      fail=1
    }
  } else {
    printf "deploy-drift: OK %s\n", name
  }
}
' "$MANIFEST"
