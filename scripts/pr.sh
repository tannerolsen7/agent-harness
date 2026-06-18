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
# .design-confirmed is intentionally NOT checked here — the design gate fires at coding time
# (inside /feature's implement step), not at PR time. By the time a PR opens, implementation
# is done and re-gating on design would be a no-op. Enforcement is at the earliest useful point.
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

# --- live preconditions: validated BEFORE the /cr sentinel is consumed, so an abort here never
#     destroys it. The sentinel is the proof /cr ran at this sha; a missing CLI or un-pushed
#     branch must not cost you that proof — fix the cause and retry without re-running /cr.
#     (Regression: pr.sh used to consume the sentinel first, then fail the remote-branch check,
#     leaving you sentinel-less and unable to push.) ---
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

# --- merge-conflict pre-check: abort before sentinel consumption if branch conflicts with base ---
MERGE_CHECK_BASE=$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}')
[ -z "$MERGE_CHECK_BASE" ] && MERGE_CHECK_BASE="main"
git fetch origin "$MERGE_CHECK_BASE" --quiet 2>/dev/null || true
MERGE_CHECK_ANCESTOR=$(git merge-base HEAD "origin/$MERGE_CHECK_BASE" 2>/dev/null || true)
if [ -n "$MERGE_CHECK_ANCESTOR" ]; then
  MERGE_CHECK_CONFLICTS=$(git merge-tree "$MERGE_CHECK_ANCESTOR" HEAD "origin/$MERGE_CHECK_BASE" \
    2>/dev/null | grep -c '<<<<<<<' || true)
  if [ "${MERGE_CHECK_CONFLICTS:-0}" -gt 0 ]; then
    echo "PR aborted: branch '${CURRENT_BRANCH}' has merge conflicts with '${MERGE_CHECK_BASE}'." >&2
    echo "Rebase first: git fetch origin && git rebase origin/${MERGE_CHECK_BASE}" >&2
    exit 1
  fi
fi

# --- /cr enforcement: consume the sentinel LAST, only once we are about to create. Any failure
#     after this point (stale sentinel, or the create itself) restores it via the trap, so the
#     PR stays retryable without re-running /cr. ---
restore_sentinel() {
  [ -n "${CONSUMED:-}" ] && [ -f "${CONSUMED:-}" ] && mv "$CONSUMED" "$SENTINEL" 2>/dev/null || true
}
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
  trap 'restore_sentinel' EXIT INT TERM
  if ! mv "$SENTINEL" "$CONSUMED" 2>/dev/null; then
    echo "PR aborted: /cr sentinel was consumed by another process. Re-run /cr." >&2
    exit 1
  fi
  ACTUAL=$(cat "$CONSUMED")
  if [ -z "$ACTUAL" ] || [ "$ACTUAL" != "$EXPECTED" ]; then
    BRANCH_SAFE=$(printf '%s' "$CURRENT_BRANCH" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    ACTUAL_SAFE=$(printf '%s' "$ACTUAL" | tr -dc 'A-Za-z0-9/_.:-' | cut -c1-200)
    echo "PR aborted: /cr sentinel is stale (expected ${BRANCH_SAFE}:<sha>, got ${ACTUAL_SAFE}). Re-run /cr after your last commit." >&2
    exit 1  # trap restore_sentinel puts the sentinel back
  fi
fi

# --- create (run, don't exec, so a failed create restores the sentinel for retry) ---
if "${cmd[@]}"; then
  if [ -n "${CONSUMED:-}" ]; then rm -f "$CONSUMED" 2>/dev/null || true; fi  # success → consumed for good
  trap - EXIT INT TERM
  exit 0
else
  status=$?
  echo "PR aborted: '$CLI' create failed (exit $status). /cr sentinel preserved — fix the cause and retry." >&2
  exit "$status"
fi
