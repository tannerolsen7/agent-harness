#!/usr/bin/env bash
# pr.sh is host-agnostic: forge detection from the remote URL, and the normalized
# --title/--body interface maps to each CLI's flags (gh pr create --body /
# glab mr create --description). Uses PR_DRY_RUN so nothing is created and no network is hit.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DETECT="$ROOT/scripts/detect-forge.sh"
PR="$ROOT/scripts/pr.sh"
[ -f "$DETECT" ] || { echo "test: $DETECT not found"; exit 1; }
[ -f "$PR" ] || { echo "test: $PR not found"; exit 1; }

pass=0; fail=0
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else echo "  MISS ($1): got '$2', want '$3'"; fail=$((fail+1)); fi; }
has() { if printf '%s' "$2" | grep -qF -- "$3"; then pass=$((pass+1)); else echo "  MISS ($1): '$3' not in '$2'"; fail=$((fail+1)); fi; }
hasnt() { if printf '%s' "$2" | grep -qF -- "$3"; then echo "  MISS ($1): '$3' unexpectedly in '$2'"; fail=$((fail+1)); else pass=$((pass+1)); fi; }

echo "── forge detection ──"
eq "https github"  "$(sh "$DETECT" 'https://github.com/o/r.git')" github
eq "ssh github"    "$(sh "$DETECT" 'git@github.com:o/r.git')"     github
eq "https gitlab"  "$(sh "$DETECT" 'https://gitlab.com/o/r.git')" gitlab
eq "ssh gitlab"    "$(sh "$DETECT" 'git@gitlab.com:o/r.git')"     gitlab
eq "self-hosted"   "$(sh "$DETECT" 'https://git.acme.com/o/r.git')" unknown

echo "── arg mapping (dry-run) ──"
gh_out=$(PR_DRY_RUN=1 PR_FORGE=github bash "$PR" --title T --body B)
has "github sub"   "$gh_out" "gh pr create"
has "github title" "$gh_out" "--title T"
has "github body"  "$gh_out" "--body B"

gl_out=$(PR_DRY_RUN=1 PR_FORGE=gitlab bash "$PR" --title T --body B)
has "gitlab sub"    "$gl_out" "glab mr create"
has "gitlab title"  "$gl_out" "--title T"
has "gitlab desc"   "$gl_out" "--description B"
hasnt "gitlab no --body" "$gl_out" "--body"

echo "── pass-through of extra args ──"
draft=$(PR_DRY_RUN=1 PR_FORGE=github bash "$PR" --title T --body B --draft)
has "passthrough --draft" "$draft" "--draft"

echo "── sentinel preserved when a precondition fails (no consume-before-validate) ──"
# Regression: pr.sh must validate its preconditions (CLI present, branch on remote) BEFORE it
# consumes the .cr-ok sentinel. A precondition abort must leave the sentinel intact so the user
# can fix the cause and retry without re-running /cr. Hermetic: a throwaway repo with a LOCAL bare
# remote and a branch that was never pushed → the remote-branch precondition fails (or, if gh is
# absent, the CLI precondition does). The sentinel is VALID (matches branch:sha), so the old
# consume-first code would have deleted it before the precondition check ran. Offline — no GitHub.
TMP=$(mktemp -d)
(
  cd "$TMP" || exit 1
  git init -q
  git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m init
  git checkout -q -b testbranch
  git init -q --bare origin.git
  git remote add origin "$TMP/origin.git"   # local bare remote — testbranch never pushed
  mkdir -p .claude
  printf 'testbranch:%s' "$(git rev-parse HEAD)" > .claude/.cr-ok   # VALID sentinel
) >/dev/null 2>&1
( cd "$TMP" && PR_FORGE=github bash "$PR" --title T --body B </dev/null >/dev/null 2>&1 ); sentinel_rc=$?
if [ "$sentinel_rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS (precond abort): pr.sh exited 0, expected non-zero"; fail=$((fail+1)); fi
if [ -f "$TMP/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS (regression): .cr-ok was consumed on a precondition abort"; fail=$((fail+1)); fi
rm -rf "$TMP"

echo "── create success consumes the sentinel; create failure restores it (stub CLI) ──"
# The trap is the heart of the reorder: a successful create permanently consumes the sentinel; a
# FAILED create must restore it so the PR stays retryable. Stub `gh` on PATH so no network/auth is
# needed and we control the create's exit code. Branch is pushed to a LOCAL bare remote so the
# remote-branch precondition passes and we actually reach the create step.
TRAP_TMP=$(mktemp -d); STUB_BIN="$TRAP_TMP/bin"; mkdir -p "$STUB_BIN"
setup_pushed_repo() {  # $1 = repo dir; init, push feat/x to a local bare remote, write a VALID sentinel
  (
    cd "$1" || exit 1
    git init -q; git config user.email t@example.com; git config user.name tester
    git commit -q --allow-empty --no-verify -m init
    git checkout -q -b feat/x
    git init -q --bare "$1/origin.git"; git remote add origin "$1/origin.git"
    git push -q origin feat/x   # branch on the remote → precondition passes, we reach create
    mkdir -p .claude
    printf 'feat/x:%s' "$(git rev-parse HEAD)" > .claude/.cr-ok
  ) >/dev/null 2>&1
}
# gh exits 0 — sentinel should be permanently consumed
ROK="$TRAP_TMP/ok"; mkdir -p "$ROK"; setup_pushed_repo "$ROK"
printf '#!/bin/sh\nexit 0\n' > "$STUB_BIN/gh"; chmod +x "$STUB_BIN/gh"
( cd "$ROK" && PATH="$STUB_BIN:$PATH" PR_FORGE=github bash "$PR" --title T --body B </dev/null >/dev/null 2>&1 )
if [ ! -f "$ROK/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel not consumed on create success"; fail=$((fail+1)); fi
# gh exits 7 — sentinel should be restored so the user can retry
RFAIL="$TRAP_TMP/fail"; mkdir -p "$RFAIL"; setup_pushed_repo "$RFAIL"
printf '#!/bin/sh\nexit 7\n' > "$STUB_BIN/gh"; chmod +x "$STUB_BIN/gh"
( cd "$RFAIL" && PATH="$STUB_BIN:$PATH" PR_FORGE=github bash "$PR" --title T --body B </dev/null >/dev/null 2>&1 )
if [ -f "$RFAIL/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS: sentinel not restored on create failure (not retryable)"; fail=$((fail+1)); fi
rm -rf "$TRAP_TMP"

echo "── clean branch passes conflict check ──"
# A branch with no conflicting changes must NOT be rejected by the conflict check, even when
# the base branch has advanced. Without this test, a bug that blocks all branches (e.g. grep -c
# always returning non-zero) would go undetected — the other tests skip the check entirely because
# they use bare remotes where origin/<base> doesn't exist.
CLEAN_TMP=$(mktemp -d); CLEAN_BIN="$CLEAN_TMP/bin"; mkdir -p "$CLEAN_BIN"
printf '#!/bin/sh\nexit 0\n' > "$CLEAN_BIN/gh"; chmod +x "$CLEAN_BIN/gh"
CLEAN_REPO="$CLEAN_TMP/repo"; mkdir -p "$CLEAN_REPO"
(
  cd "$CLEAN_REPO" || exit 1
  git init -q; git config user.email t@example.com; git config user.name tester
  printf 'base content\n' > base.txt; git add base.txt
  git commit -q --no-verify -m "init"
  _BASE=$(git rev-parse --abbrev-ref HEAD)
  git init -q --bare "$CLEAN_TMP/origin.git"; git remote add origin "$CLEAN_TMP/origin.git"
  git push -q origin "$_BASE"
  git checkout -q -b feat/clean
  printf 'feature only\n' > feature.txt; git add feature.txt
  git commit -q --no-verify -m "add feature file"
  git push -q origin feat/clean
  git checkout -q "$_BASE"
  printf 'base only\n' > other.txt; git add other.txt
  git commit -q --no-verify -m "advance base"
  git push -q origin "$_BASE"
  git checkout -q feat/clean
  mkdir -p .claude
  printf 'feat/clean:%s' "$(git rev-parse HEAD)" > .claude/.cr-ok
) >/dev/null 2>&1
( cd "$CLEAN_REPO" && PATH="$CLEAN_BIN:$PATH" PR_FORGE=github bash "$PR" --title T --body B </dev/null >/dev/null 2>&1 ); clean_rc=$?
if [ "$clean_rc" -eq 0 ]; then pass=$((pass+1)); else echo "  MISS (clean pass): pr.sh rejected a clean (non-conflicting) branch"; fail=$((fail+1)); fi
rm -rf "$CLEAN_TMP"

echo "── merge conflict aborts before sentinel consumption ──"
# A branch whose shared file diverged from origin/main (same line changed differently) must be
# rejected BEFORE the sentinel is consumed, so the user can rebase and retry without re-running /cr.
CONFLICT_TMP=$(mktemp -d); CONFLICT_BIN="$CONFLICT_TMP/bin"; mkdir -p "$CONFLICT_BIN"
printf '#!/bin/sh\nexit 0\n' > "$CONFLICT_BIN/gh"; chmod +x "$CONFLICT_BIN/gh"
CONFLICT_REPO="$CONFLICT_TMP/repo"; mkdir -p "$CONFLICT_REPO"
(
  cd "$CONFLICT_REPO" || exit 1
  git init -q; git config user.email t@example.com; git config user.name tester
  printf 'shared line\n' > shared.txt; git add shared.txt
  git commit -q --no-verify -m "init"
  _BASE=$(git rev-parse --abbrev-ref HEAD)   # capture actual default (main or master)
  git init -q --bare "$CONFLICT_TMP/origin.git"; git remote add origin "$CONFLICT_TMP/origin.git"
  git push -q origin "$_BASE"
  git checkout -q -b feat/conflict
  printf 'our change\n' > shared.txt; git add shared.txt
  git commit -q --no-verify -m "our change"
  git push -q origin feat/conflict
  git checkout -q "$_BASE"
  printf 'their change\n' > shared.txt; git add shared.txt
  git commit -q --no-verify -m "conflicting change on base"
  git push -q origin "$_BASE"
  git checkout -q feat/conflict
  mkdir -p .claude
  printf 'feat/conflict:%s' "$(git rev-parse HEAD)" > .claude/.cr-ok
) >/dev/null 2>&1
( cd "$CONFLICT_REPO" && PATH="$CONFLICT_BIN:$PATH" PR_FORGE=github bash "$PR" --title T --body B </dev/null >/dev/null 2>&1 ); conflict_rc=$?
if [ "$conflict_rc" -ne 0 ]; then pass=$((pass+1)); else echo "  MISS (conflict abort): pr.sh exited 0, expected non-zero on conflicting branch"; fail=$((fail+1)); fi
if [ -f "$CONFLICT_REPO/.claude/.cr-ok" ]; then pass=$((pass+1)); else echo "  MISS (conflict sentinel): .cr-ok was consumed before conflict check aborted"; fail=$((fail+1)); fi
rm -rf "$CONFLICT_TMP"

echo ""
echo "pr-host-agnostic: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
