#!/bin/bash
# scripts/sync-open-prs.sh — sync open PRs that conflict with main.
# Runs at session start and when a PR merges. Always exits 0 — must never block either trigger.
#
# Why local merge, not `gh pr update-branch --rebase`: that call runs server-side on GitHub,
# which can't run this repo's local .git/config merge drivers (registered from .gitattributes
# by scripts/register-merge-drivers.sh). A PR that would merge clean locally (because a driver
# resolves the shared dashboard/tracking files) can still show CONFLICTING on GitHub. Rebase is
# also this project's documented anti-pattern for automated tools — see
# docs/solutions/2026-06-24-auto-merge-as-sync-strategy-for-automated-tools.md — because a
# server-side rewrite either needs a force-push or leaves a half-applied state nothing here can
# recover from. A local `git merge` + abort-on-conflict (the same pattern /cr's pre-flight uses)
# avoids both problems.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Sibling scripts are resolved relative to where THIS script lives, not $ROOT — $ROOT is the
# repo being synced (which is always this same checkout in production, but a disposable test
# fixture repo under test), while active-worktree-branches.sh and check-merge-driver-coverage.sh
# only ever exist alongside this script's own installation.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FORGE=$(sh "$ROOT/scripts/detect-forge.sh" 2>/dev/null || echo unknown)

# Pick the CLI based on forge type. For unknown forge, try gh then glab.
case "$FORGE" in
  github) CLI=gh ;;
  gitlab) CLI=glab ;;
  *)
    if command -v gh >/dev/null 2>&1; then
      CLI=gh
    elif command -v glab >/dev/null 2>&1; then
      CLI=glab
    else
      echo "forge CLI unavailable — skipping PR sync"
      exit 0
    fi
    ;;
esac

# Second check: forge is known but the CLI isn't installed (e.g. forge=github, gh missing).
if ! command -v "$CLI" >/dev/null 2>&1; then
  echo "forge CLI unavailable — skipping PR sync"
  exit 0
fi

# GitLab MR field names differ from GitHub's — the JSON mapping is not yet implemented.
if [ "$CLI" = glab ]; then
  echo "GitLab PR sync not yet supported — skipping"
  exit 0
fi

# Default branch — read from the remote HEAD symref; fall back to "main".
DEFAULT_BRANCH=$(git -C "$ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
[ -z "${DEFAULT_BRANCH:-}" ] && DEFAULT_BRANCH=main

PRS=$(gh pr list --json number,headRefName,baseRefName,mergeable,isDraft 2>/dev/null || echo "[]")

COUNT=$(printf '%s' "$PRS" | jq 'length' 2>/dev/null || echo 0)
if [ "$COUNT" -eq 0 ]; then
  echo "no open PRs to sync"
  exit 0
fi

# Cache the active worktree branch list once — reused for every PR's checked-out-elsewhere check.
ACTIVE_WT_BRANCHES=$(bash "$SCRIPT_DIR/active-worktree-branches.sh" || true)

# $base is $DEFAULT_BRANCH for every PR that reaches sync_conflicting_pr (filtered below), so
# fetch it once here instead of once per conflicting PR.
git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null || true

# Sync one CONFLICTING PR: merge origin/$3 into $2 inside a scratch worktree, and push on success.
# Mirrors .claude/skills/cr/SKILL.md's pre-flight (merge, abort-on-conflict) instead of rebasing.
sync_conflicting_pr() {
  local number="$1" head="$2" base="$3"

  if printf '%s\n' "$ACTIVE_WT_BRANCHES" | grep -qxF "$head"; then
    echo "skipped #${number} (${head}) — checked out in another worktree, sync it yourself"
    return
  fi

  git fetch origin "$head" --quiet 2>/dev/null || true
  local scratch
  scratch=$(mktemp -d)
  # -B resets/creates a local branch named $head from origin/$head — safe even if a stale local
  # branch of the same name lingers from a previous run (the active-worktree check above already
  # ruled out it being checked out anywhere).
  if ! git worktree add --quiet -B "$head" "$scratch" "origin/$head" >/dev/null 2>&1; then
    echo "failed #${number} (${head}) — could not create scratch worktree, sync it yourself"
    rm -rf "$scratch"
    return
  fi

  (
    cd "$scratch" || exit 1

    local pre_merge_head merge_base
    pre_merge_head=$(git rev-parse HEAD)
    merge_base=$(git merge-base "$pre_merge_head" "origin/$base" 2>/dev/null || true)

    if ! git merge "origin/$base" --quiet -m "chore(sync): merge origin/$base into $head" >/dev/null 2>&1; then
      git merge --abort 2>/dev/null || true
      echo "failed #${number} (${head}) — real conflict, resolve manually: git fetch origin && git checkout $head && git merge origin/$base"
      exit 0
    fi

    # Certifying this push is safe only if the merge is fully covered by registered
    # .gitattributes merge strategies — anything else means unreviewed content landed via the
    # merge, and this must go through a real /cr pass instead.
    if ! bash "$SCRIPT_DIR/check-merge-driver-coverage.sh" "$merge_base" "$pre_merge_head" "origin/$base" >/dev/null 2>&1; then
      echo "failed #${number} (${head}) — merge touched files outside the registered merge strategies, needs a real /cr pass"
      exit 0
    fi

    # Self-issue a scoped .cr-ok: safe only because the coverage check above confirms this merge
    # commit introduces no content beyond what the registered merge drivers already resolved.
    local merge_sha
    merge_sha=$(git rev-parse HEAD)
    mkdir -p .claude
    printf '%s:%s' "$head" "$merge_sha" > .claude/.cr-ok

    if git push origin "HEAD:$head" --quiet 2>/dev/null; then
      echo "synced #${number} (${head})"
    else
      echo "failed #${number} (${head}) — merge ok locally but push failed, sync it yourself"
    fi
  )

  git worktree remove --force "$scratch" >/dev/null 2>&1 || rm -rf "$scratch"
}

# Write PR list to a temp file so the while loop can read it without a subshell pipe.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT INT TERM
printf '%s' "$PRS" | jq -c '.[]' > "$TMP"

while IFS= read -r pr; do
  number=$(printf '%s' "$pr" | jq -r '.number')
  head=$(printf '%s' "$pr" | jq -r '.headRefName')
  base=$(printf '%s' "$pr" | jq -r '.baseRefName')
  mergeable=$(printf '%s' "$pr" | jq -r '.mergeable')
  is_draft=$(printf '%s' "$pr" | jq -r '.isDraft')

  [ "$is_draft" = "true" ] && continue
  [ "$base" != "$DEFAULT_BRANCH" ] && continue
  [ "$mergeable" != "CONFLICTING" ] && continue

  sync_conflicting_pr "$number" "$head" "$base"
done < "$TMP"

exit 0
