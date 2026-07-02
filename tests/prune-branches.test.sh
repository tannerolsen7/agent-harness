#!/usr/bin/env bash
# prune-branches.sh removes merged worktrees/branches, flags closed-PR branches,
# deletes orphaned worktree directories, and removes merged remote agent branches.
# Hermetic + offline: uses a throwaway repo with a local bare remote.
# (run-tests.sh clears inherited git env so the temp-repo ops stay isolated.)
set -u
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPT="$ROOT/scripts/prune-branches.sh"
[ -x "$SCRIPT" ] || { echo "test: $SCRIPT not found or not executable"; exit 1; }

pass=0; fail=0
chk() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }

TMP=$(mktemp -d)
(
  cd "$TMP" || exit 1
  git init -q; git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m m0
  git init -q --bare "$TMP/remote.git"; git remote add origin "$TMP/remote.git"
  git push -q -u origin HEAD:refs/heads/main >/dev/null 2>&1 || git push -q -u origin master >/dev/null 2>&1

  # MERGED branch: feat/done — simulates the post-PR-merge state (branch deleted on remote).
  # push+track the feature branch, merge it, then remove the remote so [gone] fires.
  DEF=$(git rev-parse --abbrev-ref HEAD)
  git worktree add -q .claude/worktrees/done -b feat/done >/dev/null 2>&1
  ( cd .claude/worktrees/done && git commit -q --allow-empty --no-verify -m work )
  git push -q -u origin feat/done >/dev/null 2>&1
  git merge -q --no-ff feat/done -m merge >/dev/null 2>&1   # feat/done now an ancestor → branch -d works
  git push -q origin --delete feat/done >/dev/null 2>&1     # remote gone → [gone] after prune

  # ACTIVE branch: feat/wip — worktree + live remote (must SURVIVE).
  git worktree add -q .claude/worktrees/wip -b feat/wip >/dev/null 2>&1
  ( cd .claude/worktrees/wip && git commit -q --allow-empty --no-verify -m wip )
  git push -q -u origin feat/wip >/dev/null 2>&1

  # UNMERGED branch: feat/orphan — remote deleted WITHOUT merging.
  # The worktree, branch, and untracked WIP must all SURVIVE.
  git worktree add -q .claude/worktrees/orphan -b feat/orphan >/dev/null 2>&1
  ( cd .claude/worktrees/orphan && git commit -q --allow-empty --no-verify -m orphan && echo wip > WIP.txt )
  git push -q -u origin feat/orphan >/dev/null 2>&1
  git push -q origin --delete feat/orphan >/dev/null 2>&1   # remote gone, never merged into main

  # NO-UPSTREAM merged branch: feat/local — merged into main locally, never pushed.
  git checkout -q "$DEF"
  git checkout -q -b feat/local
  git commit -q --allow-empty --no-verify -m "local work"
  git checkout -q "$DEF"
  git merge -q --no-ff feat/local -m "merge feat/local" >/dev/null 2>&1

  # PROTECTED-NAME no-upstream branch: "develop" — must NOT be deleted.
  git checkout -q -b develop
  git commit -q --allow-empty --no-verify -m "develop work"
  git checkout -q "$DEF"
  git merge -q --no-ff develop -m "merge develop" >/dev/null 2>&1

  # FRESH WORKTREE branch: feat/queue-task — no commits yet (just provisioned).
  # Looks "merged" to an ancestor check — must SURVIVE.
  git worktree add -q .claude/worktrees/queue-task -b feat/queue-task >/dev/null 2>&1

  # Pass A — ORPHANED DIRECTORY: a directory under .claude/worktrees/ with no .git file.
  # Simulates a worktree whose git registration was already removed (via git worktree prune)
  # but the directory was not cleaned up.
  mkdir -p .claude/worktrees/orphaned-dir
  echo "some leftover file" > .claude/worktrees/orphaned-dir/leftover.txt
  # No .git file — this directory looks orphaned to Pass A.

  # Pass A — LIVE WORKTREE DIRECTORY: should NOT be removed.
  # .claude/worktrees/wip has a .git file from git worktree add above — it must survive.

  # Pass B — MERGED REMOTE AGENT BRANCH: origin/agent/done-task.
  # Simulate a workflow branch whose local branch is gone and tip is in main.
  git checkout -q -b agent/done-task
  git commit -q --allow-empty --no-verify -m "agent work"
  git push -q origin agent/done-task >/dev/null 2>&1
  git checkout -q "$DEF"
  git merge -q --no-ff agent/done-task -m "merge agent/done-task" >/dev/null 2>&1
  git push -q origin HEAD:refs/heads/main >/dev/null 2>&1   # update origin/main with the merge
  git branch -D agent/done-task >/dev/null 2>&1   # local branch gone (simulates post-gc state)

  # Pass B — ACTIVE LOCAL AGENT BRANCH: origin/agent/live-task.
  # Remote exists and a local branch also exists — must NOT be deleted from remote.
  git checkout -q -b agent/live-task
  git commit -q --allow-empty --no-verify -m "live agent work"
  git push -q origin agent/live-task >/dev/null 2>&1
  git checkout -q "$DEF"
  # Do NOT merge or delete local — local branch is still present

  # Pass B — UNMERGED REMOTE AGENT BRANCH: origin/agent/unmerged-task.
  # Local branch is gone but tip is NOT in main — should be warned, not deleted.
  git checkout -q -b agent/unmerged-task
  git commit -q --allow-empty --no-verify -m "unmerged agent work"
  git push -q origin agent/unmerged-task >/dev/null 2>&1
  git checkout -q "$DEF"
  git branch -D agent/unmerged-task >/dev/null 2>&1   # local gone but NOT merged

  # Pass B — ACTIVE WORKTREE AGENT BRANCH: origin/agent/wt-task.
  # The branch is checked out in a worktree (the way worktree-create.sh provisions tasks).
  # The local branch exists inside the worktree, so both the local-branch check and the
  # active-worktree check protect it. Remote must NOT be deleted.
  git worktree add -q .claude/worktrees/wt-agent -b agent/wt-task >/dev/null 2>&1
  ( cd .claude/worktrees/wt-agent && git commit -q --allow-empty --no-verify -m "worktree work" )
  git push -q origin agent/wt-task >/dev/null 2>&1

  # TOCTOU RACE — 0-trigger: an ordinary unmerged branch (remote gone, real commit, not an
  # ancestor of main), named to sort before "feat/late-dirty" in CANDIDATES so its gh call is
  # the deterministic point the fake `gh` below fires its side effect from.
  git checkout -q -b 0-trigger
  git commit -q --allow-empty --no-verify -m "0-trigger unmerged work"
  git push -q -u origin 0-trigger >/dev/null 2>&1
  git checkout -q "$DEF"
  git push -q origin --delete 0-trigger >/dev/null 2>&1

  # TOCTOU RACE — feat/late-dirty: a genuinely, fully merged branch (real commit, --no-ff
  # merge, remote gone) whose worktree is still registered when prune-branches.sh starts.
  # The fake `gh` below writes an untracked file into this worktree the moment 0-trigger's
  # merge-verify gh call fires — simulating a concurrent session adding real work to the
  # worktree during the multi-candidate gh-call window between prune-branches.sh's startup
  # snapshot and the moment this branch's turn in the delete loop arrives. Branch, worktree,
  # and the simulated concurrent work must all SURVIVE — a dirty worktree must never be
  # force-removed just because its branch is confirmed merged.
  git worktree add -q .claude/worktrees/late-dirty -b feat/late-dirty >/dev/null 2>&1
  ( cd .claude/worktrees/late-dirty && git commit -q --allow-empty --no-verify -m "late-dirty work" )
  git push -q -u origin feat/late-dirty >/dev/null 2>&1
  git merge -q --no-ff feat/late-dirty -m "merge feat/late-dirty" >/dev/null 2>&1
  git push -q origin --delete feat/late-dirty >/dev/null 2>&1
) >/dev/null 2>&1

# Fake `gh`: makes the TOCTOU race above deterministic and keeps the whole test offline (no
# real network calls to a real `gh`, unlike before). Every `pr list` call returns "nothing
# found" — matching what the real gh would say for these fixture-only branch names anyway —
# except the first call for "0-trigger", which also drops a file into feat/late-dirty's
# worktree as its side effect.
FAKEBIN=$(mktemp -d)
FAKE_GH_MARKER="$FAKEBIN/.fired"
cat > "$FAKEBIN/gh" <<EOF
#!/usr/bin/env bash
if printf '%s\n' "\$*" | grep -q -- '--head 0-trigger' && [ ! -f "$FAKE_GH_MARKER" ]; then
  touch "$FAKE_GH_MARKER"
  echo "concurrent work" > "$TMP/.claude/worktrees/late-dirty/concurrent-work.txt"
fi
exit 0
EOF
chmod +x "$FAKEBIN/gh"

# Run prune-branches.sh in the temp repo (single run; captures all side effects and output).
OUT=$(cd "$TMP" && PATH="$FAKEBIN:$PATH" bash "$SCRIPT" 2>&1)
rm -rf "$FAKEBIN"

# -- Existing behaviors (regression guard) --

# Merged branch's worktree + branch are gone.
! [ -d "$TMP/.claude/worktrees/done" ]; chk "$?" "merged worktree .claude/worktrees/done should be removed"
! ( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/done >/dev/null 2>&1 ); chk "$?" "merged branch feat/done should be deleted"

# Active branch's worktree + branch survive (live remote → never touched).
[ -d "$TMP/.claude/worktrees/wip" ]; chk "$?" "active worktree .claude/worktrees/wip must survive"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/wip >/dev/null 2>&1 ); chk "$?" "active branch feat/wip must survive"

# Unmerged-but-remote-gone branch + worktree + untracked WIP all survive (data-loss guard).
[ -d "$TMP/.claude/worktrees/orphan" ]; chk "$?" "unmerged worktree must survive (remote gone != merged)"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/orphan >/dev/null 2>&1 ); chk "$?" "unmerged branch must survive"
[ -f "$TMP/.claude/worktrees/orphan/WIP.txt" ]; chk "$?" "untracked WIP in the unmerged worktree must survive"

# No-upstream merged branch is deleted (Pass 2 blind-spot coverage).
! ( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/local >/dev/null 2>&1 ); chk "$?" "merged no-upstream branch feat/local should be deleted"

# Protected-name branch must survive even with no upstream and an ancestor position.
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/develop >/dev/null 2>&1 ); chk "$?" "develop (no upstream, merged) must survive — protected name exclusion"

# Fresh worktree branch (no commits, no upstream) must survive.
[ -d "$TMP/.claude/worktrees/queue-task" ]; chk "$?" "fresh worktree .claude/worktrees/queue-task must survive (no commits yet)"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/queue-task >/dev/null 2>&1 ); chk "$?" "fresh branch feat/queue-task must survive (no commits, active worktree)"

# -- Pass A: orphaned worktree directory behaviors --

# Orphaned directory (no .git file) is removed.
! [ -d "$TMP/.claude/worktrees/orphaned-dir" ]; chk "$?" "Pass A: orphaned directory (no .git file) should be removed"

# Live worktree directory (has .git file) survives.
[ -d "$TMP/.claude/worktrees/wip" ]; chk "$?" "Pass A: live worktree directory (.git file present) must survive"

# -- Pass B: remote agent/workflow branch behaviors --

# Merged agent branch (local gone, tip in main) is deleted from remote.
! ( cd "$TMP" && git ls-remote --heads origin 'refs/heads/agent/done-task' | grep -q 'agent/done-task' ); chk "$?" "Pass B: merged remote agent branch should be deleted from origin"

# Active local agent branch is NOT deleted from remote.
( cd "$TMP" && git ls-remote --heads origin 'refs/heads/agent/live-task' | grep -q 'agent/live-task' ); chk "$?" "Pass B: agent branch with live local branch must survive on remote"

# Unmerged remote agent branch is NOT deleted — warning is printed.
( cd "$TMP" && git ls-remote --heads origin 'refs/heads/agent/unmerged-task' | grep -q 'agent/unmerged-task' ); chk "$?" "Pass B: unmerged remote agent branch must survive on remote (warn only)"

# Active worktree agent branch is NOT deleted from remote.
( cd "$TMP" && git ls-remote --heads origin 'refs/heads/agent/wt-task' | grep -q 'agent/wt-task' ); chk "$?" "Pass B: active-worktree agent branch must survive on remote"

# -- TOCTOU race: a worktree that goes dirty between the startup snapshot and the delete
# loop's turn must not be force-removed, even though its branch is confirmed merged --

[ -d "$TMP/.claude/worktrees/late-dirty" ]; chk "$?" "TOCTOU: feat/late-dirty worktree must survive (went dirty mid-run)"
( cd "$TMP" && git rev-parse --verify --quiet refs/heads/feat/late-dirty >/dev/null 2>&1 ); chk "$?" "TOCTOU: feat/late-dirty branch must survive (worktree removal correctly refused)"
[ -f "$TMP/.claude/worktrees/late-dirty/concurrent-work.txt" ]; chk "$?" "TOCTOU: simulated concurrent work in feat/late-dirty must survive — not silently destroyed"

rm -rf "$TMP"

# -- Pass A: .claude/worktrees/ absent is safe --
# Script must exit 0 and not error when the directory doesn't exist at all.
TMP2=$(mktemp -d)
(
  cd "$TMP2" || exit 1
  git init -q; git config user.email t@example.com; git config user.name tester
  git commit -q --allow-empty --no-verify -m m0
  git init -q --bare "$TMP2/remote.git"; git remote add origin "$TMP2/remote.git"
  git push -q -u origin HEAD:refs/heads/main >/dev/null 2>&1
  # No .claude/worktrees/ directory — Pass A must skip silently
) >/dev/null 2>&1
( cd "$TMP2" && bash "$SCRIPT" ) >/dev/null 2>&1; chk "$?" "Pass A: script exits 0 when .claude/worktrees/ is absent"
rm -rf "$TMP2"

echo ""
echo "prune-branches: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
