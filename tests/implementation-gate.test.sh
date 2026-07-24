#!/usr/bin/env bash
# The implementation gate used to live as copy-paste bash inside
# .claude/skills/feature/SKILL.md — every run re-typed security-relevant logic,
# and a transcription slip would fail open silently. These tests pin the
# extracted script's behavior so the gate stays trustworthy:
#   1. no sentinel                          → blocked
#   2. sentinel for a different branch      → blocked
#   3. sentinel sha not an ancestor of HEAD → blocked (real commit off a side branch)
#   4. sentinel at HEAD                     → passes
#   5. sentinel behind HEAD (ancestor)      → passes (pre-coding commits are fine)
#   6. detached HEAD                        → blocked (even when the sentinel says HEAD)
#   7. sentinel without a colon             → blocked (malformed, must fail closed)
#   8. ref name in the sha field            → blocked (a moving ref would pass forever)
set -u

# Hooks export the parent repo's git env; without clearing it, the temp repos
# below would operate on THIS repo instead of their own.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
GATE="$ROOT/scripts/implementation-gate.sh"

[ -f "$GATE" ] || { echo "implementation-gate.test: $GATE not found"; exit 1; }

pass=0; fail=0
ok() { pass=$((pass+1)); }
no() { printf '  MISS: %s\n' "$1"; fail=$((fail+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# A throwaway repo per test keeps each case independent of the others' state.
setup_repo() {
  local dir="$1"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m "init"
    git branch -M feat/demo
    mkdir -p .claude
  ) >/dev/null 2>&1
}

run_gate() { (cd "$1" && bash "$GATE") >/dev/null 2>&1; }

# ── 1. no sentinel → blocked ────────────────────────────────────────────────
R="$TMP/no-sentinel"; setup_repo "$R"
if run_gate "$R"; then no "gate must block when no sentinel exists"; else ok; fi

# ── 2. sentinel for a different branch → blocked ────────────────────────────
R="$TMP/wrong-branch"; setup_repo "$R"
SHA=$(git -C "$R" rev-parse HEAD)
printf '%s:%s' "feat/other" "$SHA" > "$R/.claude/.design-confirmed"
if run_gate "$R"; then no "gate must block when sentinel names another branch"; else ok; fi

# ── 3. sentinel sha not an ancestor of HEAD → blocked ───────────────────────
# The side-branch commit is a real, resolvable sha outside feat/demo's history,
# so this exercises the genuine not-an-ancestor path, not a git error path.
R="$TMP/not-ancestor"; setup_repo "$R"
git -C "$R" checkout -q -b side
git -C "$R" commit -q --allow-empty --no-verify -m "side commit"
SIDE_SHA=$(git -C "$R" rev-parse HEAD)
git -C "$R" checkout -q feat/demo
git -C "$R" commit -q --allow-empty --no-verify -m "diverge"
printf '%s:%s' "feat/demo" "$SIDE_SHA" > "$R/.claude/.design-confirmed"
if run_gate "$R"; then no "gate must block when sentinel sha is not an ancestor of HEAD"; else ok; fi

# ── 4. sentinel at HEAD → passes ────────────────────────────────────────────
R="$TMP/at-head"; setup_repo "$R"
SHA=$(git -C "$R" rev-parse HEAD)
printf '%s:%s' "feat/demo" "$SHA" > "$R/.claude/.design-confirmed"
if run_gate "$R"; then ok; else no "gate must pass when sentinel matches branch and HEAD"; fi

# ── 5. sentinel behind HEAD → passes (spec/plan commits land after confirm) ─
R="$TMP/behind-head"; setup_repo "$R"
SHA=$(git -C "$R" rev-parse HEAD)
printf '%s:%s' "feat/demo" "$SHA" > "$R/.claude/.design-confirmed"
git -C "$R" commit -q --allow-empty --no-verify -m "docs: spec"
if run_gate "$R"; then ok; else no "gate must tolerate pre-coding commits after the sentinel sha"; fi

# ── 6. detached HEAD → blocked ──────────────────────────────────────────────
# The sentinel deliberately says "HEAD" so the branch-mismatch check would NOT
# catch this — only the dedicated detached-HEAD check blocks it. This pins that
# check: deleting it from the script makes this case fail open.
R="$TMP/detached"; setup_repo "$R"
SHA=$(git -C "$R" rev-parse HEAD)
printf '%s:%s' "HEAD" "$SHA" > "$R/.claude/.design-confirmed"
git -C "$R" checkout -q --detach HEAD
if run_gate "$R"; then no "gate must block on detached HEAD"; else ok; fi

# ── 7. sentinel without a colon → blocked ───────────────────────────────────
R="$TMP/no-colon"; setup_repo "$R"
printf '%s' "feat/demo" > "$R/.claude/.design-confirmed"
if run_gate "$R"; then no "gate must block a sentinel with no branch:sha separator"; else ok; fi

# ── 8. ref name in the sha field → blocked ──────────────────────────────────
# "feat/demo:feat/demo" would resolve as a ref that is always an ancestor of
# itself, making a malformed sentinel valid forever if the format isn't checked.
R="$TMP/ref-in-sha"; setup_repo "$R"
printf '%s:%s' "feat/demo" "feat/demo" > "$R/.claude/.design-confirmed"
if run_gate "$R"; then no "gate must block a ref name in the sha field"; else ok; fi

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" = 0 ]
