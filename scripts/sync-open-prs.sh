#!/bin/bash
# scripts/sync-open-prs.sh — diagnose open PRs that conflict with main.
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
#
# Why diagnose-only, not auto-push: an earlier version of this script self-issued a scoped
# `.claude/.cr-ok` sentinel and pushed automatically when the merge was provably confined to
# .gitattributes-covered files. An adversarial review found that mechanism unsafe even scoped:
# a self-issued sentinel is indistinguishable from a real /cr review to .husky/pre-push, a fork
# PR could smuggle its own `.gitattributes` entry into the merged tree to fake coverage, and a
# bad auto-push could cascade onto the default branch via GitHub auto-merge with no audit trail.
# This script now only tells you whether a conflict is real (needs a human) or false (the local
# merge drivers already resolve it — just needs someone to run the push). It never pushes.

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

PRS=$(gh pr list --json number,headRefName,baseRefName,mergeable,isDraft,isCrossRepository 2>/dev/null || echo "[]")

COUNT=$(printf '%s' "$PRS" | jq 'length' 2>/dev/null || echo 0)
if [ "$COUNT" -eq 0 ]; then
  echo "no open PRs to sync"
  exit 0
fi

# Cache the active worktree branch list once — reused for every PR's checked-out-elsewhere check.
ACTIVE_WT_BRANCHES=$(bash "$SCRIPT_DIR/active-worktree-branches.sh" || true)

# $base is $DEFAULT_BRANCH for every PR that reaches diagnose_conflicting_pr (filtered below), so
# fetch it once here instead of once per conflicting PR.
git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null || true

# Diagnose one CONFLICTING PR: merge origin/$3 into $2 inside a scratch worktree (detached, no
# local branch created — nothing here can clobber an existing ref) to find out whether the
# conflict is real or just the generated-file problem. Never pushes; only reports.
# Mirrors .claude/skills/cr/SKILL.md's pre-flight (merge, abort-on-conflict) instead of rebasing.
diagnose_conflicting_pr() {
  local number="$1" head="$2" base="$3"

  if printf '%s\n' "$ACTIVE_WT_BRANCHES" | grep -qxF "$head"; then
    echo "skipped #${number} (${head}) — checked out in another worktree, check it yourself"
    return
  fi

  git fetch origin "$head" --quiet 2>/dev/null || true
  local scratch
  scratch=$(mktemp -d)
  # --detach: no local branch is created or reset, so this can never clobber an existing ref
  # of the same name (a real risk with `-B "$head"` — a human could have local unpushed work
  # on a same-named branch that isn't checked out anywhere).
  if ! git worktree add --quiet --detach "$scratch" "origin/$head" >/dev/null 2>&1; then
    echo "failed #${number} (${head}) — could not create scratch worktree, check it yourself"
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

    # A resolvable-looking merge is only reported as such if every file the merge actually had to
    # decide between is covered by a trusted (origin/$base) .gitattributes merge strategy — see
    # check-merge-driver-coverage.sh for why the trust source matters (a branch's own copy of
    # .gitattributes can't be used, or the branch could grant itself coverage).
    if ! bash "$SCRIPT_DIR/check-merge-driver-coverage.sh" "$merge_base" "$pre_merge_head" "origin/$base" >/dev/null 2>&1; then
      echo "failed #${number} (${head}) — merge touched files outside the registered merge strategies, needs a real /cr pass"
      exit 0
    fi

    echo "resolvable #${number} (${head}) — not a real conflict, push it yourself: git fetch origin && git checkout ${head} && git merge origin/${base} && git push origin ${head}"
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
  is_cross_repo=$(printf '%s' "$pr" | jq -r '.isCrossRepository')

  [ "$is_draft" = "true" ] && continue
  [ "$base" != "$DEFAULT_BRANCH" ] && continue
  [ "$mergeable" != "CONFLICTING" ] && continue
  # Fork PRs carry untrusted branch content and an untrusted .gitattributes — never run even the
  # diagnostic merge against them automatically.
  [ "$is_cross_repo" = "true" ] && continue

  diagnose_conflicting_pr "$number" "$head" "$base"
done < "$TMP"

exit 0
