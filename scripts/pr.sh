#!/bin/bash
# Open a PR (GitHub) or MR (GitLab) — HOST-AGNOSTIC. Enforces that /cr (full branch review)
# ran before it is created.
#   Non-interactive: validates + consumes the .claude/.cr-ok sentinel (branch:sha).
#   Interactive: prompts the user.
# Normalized interface: --title / --body. These map to each CLI's flags (gh: --body,
# glab: --description); any other args pass through. Forge is detected from the remote
# (override with PR_FORGE=github|gitlab). PR_DRY_RUN=1 prints the resolved command, runs nothing.
set -e

SENTINEL=".claude/.cr-ok"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
  echo "PR aborted: could not determine current branch." >&2
  exit 1
}
HEAD_SHA=$(git rev-parse HEAD 2>/dev/null) || {
  echo "PR aborted: could not read HEAD sha." >&2
  exit 1
}
EXPECTED="${CURRENT_BRANCH}:${HEAD_SHA}"

# --- parse the normalized interface (host-agnostic) ---
TITLE=""; BODY=""; REST=()
while [ $# -gt 0 ]; do
  case "$1" in
    --title)   TITLE="${2:-}"; shift 2 ;;
    --title=*) TITLE="${1#--title=}"; shift ;;
    --body)    BODY="${2:-}"; shift 2 ;;
    --body=*)  BODY="${1#--body=}"; shift ;;
    *)         REST+=("$1"); shift ;;
  esac
done

# --- detect the forge, then build the create command ---
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FORGE="${PR_FORGE:-$("$SCRIPT_DIR/detect-forge.sh")}"
if [ "$FORGE" = unknown ]; then
  if command -v gh >/dev/null 2>&1 && ! command -v glab >/dev/null 2>&1; then FORGE=github
  elif command -v glab >/dev/null 2>&1 && ! command -v gh >/dev/null 2>&1; then FORGE=gitlab
  else
    echo "PR aborted: couldn't tell GitHub from GitLab via the remote. Set PR_FORGE=github|gitlab, or install exactly one of gh/glab." >&2
    exit 1
  fi
fi

case "$FORGE" in
  github) CLI=gh;   cmd=(gh pr create);   BODYFLAG=--body ;;
  gitlab) CLI=glab; cmd=(glab mr create); BODYFLAG=--description ;;
  *) echo "PR aborted: unsupported forge '$FORGE' (use PR_FORGE=github|gitlab)." >&2; exit 1 ;;
esac
[ -n "$TITLE" ] && cmd+=(--title "$TITLE")
[ -n "$BODY" ]  && cmd+=("$BODYFLAG" "$BODY")
[ ${#REST[@]} -gt 0 ] && cmd+=("${REST[@]}")

# --- dry run: preview only, touch nothing (no sentinel, no network) ---
if [ -n "${PR_DRY_RUN:-}" ]; then
  printf '%s\n' "${cmd[*]}"
  exit 0
fi

# --- /cr enforcement (host-agnostic) ---
if [ -t 0 ]; then
  printf "\nHave you run /cr (full branch review)? [y/N] " > /dev/tty
  read -r confirm < /dev/tty
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "PR aborted: run /cr before opening a PR." >&2
    exit 1
  fi
else
  if [ ! -f "$SENTINEL" ]; then
    echo "PR aborted: no /cr sentinel found. Run /cr before opening a PR." >&2
    exit 1
  fi
  CONSUMED="${SENTINEL}.consumed.$$"
  trap 'rm -f "$CONSUMED"' EXIT INT TERM
  if ! mv "$SENTINEL" "$CONSUMED" 2>/dev/null; then
    echo "PR aborted: /cr sentinel was consumed by another process. Re-run /cr." >&2
    exit 1
  fi
  ACTUAL=$(cat "$CONSUMED")
  if [ -z "$ACTUAL" ] || [ "$ACTUAL" != "$EXPECTED" ]; then
    mv "$CONSUMED" "$SENTINEL" 2>/dev/null || true
    BRANCH_SAFE=$(printf '%s' "$CURRENT_BRANCH" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    ACTUAL_SAFE=$(printf '%s' "$ACTUAL" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    echo "PR aborted: /cr sentinel is stale (expected ${BRANCH_SAFE}:<sha>, got ${ACTUAL_SAFE}). Re-run /cr after your last commit." >&2
    exit 1
  fi
  rm -f "$CONSUMED"
fi

# --- live checks ---
if ! command -v "$CLI" >/dev/null 2>&1; then
  echo "PR aborted: $CLI not found (needed for a $FORGE remote)." >&2
  [ "$CLI" = gh ]   && echo "Install: brew install gh && gh auth login" >&2
  [ "$CLI" = glab ] && echo "Install: https://gitlab.com/gitlab-org/cli (then glab auth login)" >&2
  exit 1
fi

# Branch must exist on the remote before create; otherwise the CLI gives a cryptic error.
REMOTE=$(git config --get branch."$CURRENT_BRANCH".remote 2>/dev/null || echo "origin")
if ! git ls-remote --exit-code "$REMOTE" "$CURRENT_BRANCH" >/dev/null 2>&1; then
  echo "PR aborted: branch '$CURRENT_BRANCH' not found on remote '$REMOTE'. Push first: git push -u $REMOTE $CURRENT_BRANCH" >&2
  exit 1
fi

exec "${cmd[@]}"
