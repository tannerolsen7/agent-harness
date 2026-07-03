# Problem: closing a TOCTOU race by re-checking once isn't the same as closing it for every destructive step

**Problem class:** A check-then-act script re-verifies its safety condition at one point
right before a destructive call, but an earlier check that also fed the decision to reach
that point is left stale — the race is narrowed, not closed.

## When this bites you

You have a cleanup script shaped like:

```sh
if <condition A is true>; then       # e.g. "branch is merged"
  <do risky thing 1>                 # e.g. remove the worktree
  <do risky thing 2>                 # e.g. delete the branch
fi
```

You find that `<risky thing 1>` can act on stale information (a worktree that picked up
real work since some earlier snapshot), so you fix that one call site: re-query the
relevant state live, right before `<risky thing 1>` runs. The fix looks complete — you
re-checked right before the destructive action.

It isn't complete. `<condition A>` was checked once, earlier, and never re-verified. If the
world changed in a way that makes `<condition A>` false by the time `<risky thing 2>` runs
— even though `<risky thing 1>`'s own live re-check passed — `<risky thing 2>` still fires
on stale grounds.

This is exactly what happened fixing `scripts/prune-branches.sh` in agent-harness (PR #132,
building on the FLO-89 incident reported by a downstream project, event-vendor). The first
version of the fix re-queried `git worktree list --porcelain` live and dropped `--force`
from `git worktree remove`, closing the case where a concurrent session left *uncommitted*
work in a worktree. Adversarial review found a second, narrower gap: a branch confirmed
merged (`git merge-base --is-ancestor "$b" HEAD`) at the *top* of its loop iteration could
gain a genuinely new **commit** before the *bottom* of that same iteration. A worktree that
only gained a commit is clean — the dirty-check fix doesn't touch it — and
`git branch --delete --force` doesn't check ancestry at all. The commit would be silently
orphaned.

## Root cause

Fixing the most visible/recently-touched check site creates a false sense of completeness.
The instinct "re-check right before the thing I'm looking at" stops at the first check you
notice is stale, not at every check whose result the destructive action depends on. In a
loop body with N destructive steps guarded by M checks computed at different points, each
step needs its OWN fresh verification of every condition it depends on — not just the one
check that happens to sit textually closest to it.

## The fix

Re-verify every condition immediately before the first destructive action that depends on
it, in the same place, back to back — don't spread "fresh enough" checks across a function
based on which one you happened to find broken first.

```sh
# Re-verify right here, before ANYTHING destructive for this candidate — not just once
# at the top of this loop iteration.
if ! git merge-base --is-ancestor "$b" HEAD 2>/dev/null; then
  echo "  WARN: $b gained new commits since it was confirmed merged — leaving it" >&2
  continue
fi
WT=$(git worktree list --porcelain 2>/dev/null | awk -v br="refs/heads/$b" \
  '/^worktree /{ p=$0; sub(/^worktree /,"",p) } $0=="branch "br { print p }')
if [ -n "$WT" ]; then
  if git worktree remove "$WT" 2>/dev/null; then
    echo "  removed worktree: $WT (branch $b, merged)"
  else
    echo "  WARN: could not remove worktree $WT — leaving it and the branch" >&2
    continue
  fi
fi
# Only now, with both checks fresh, is the branch delete itself justified.
git branch --delete --force "$b"
```

**When reviewing a check-then-act fix, ask explicitly:** "list every condition this
destructive action depends on. Is each one re-verified at the same moment, or is only the
one I already know about fresh?" A single-lens self-review tends to stop at the first
answer; this gap here was only found by two independent adversarial-review lenses running
in parallel, one of which reproduced it directly against a real git repo rather than
reasoning about it abstractly. Empirical reproduction (not just re-reading the code) is what
surfaced it — reasoning alone (a different reviewer pass, in the same review round,
concluded the gap was "already self-healing" and was wrong).

## A related judgment call from the same fix: don't port a borrowed fix's assumptions unexamined

The incident that motivated this fix was originally reported and fixed in a different
project built on this harness (event-vendor). Their fix had two parts: the live-recheck
above, and a companion exclusion — drop any branch with zero commits ahead of
`origin/main` from the candidate list before the merge-verify loop even runs.

That companion exclusion was tried here and empirically broke two existing regression
tests (`feat/done`, `feat/local` — both real, non-squash merge-commit scenarios). Root
cause: the exclusion silently assumes every merge is a squash merge, where a merged
branch's original commits are never literally absorbed into `origin/main` (squash creates a
brand-new commit). Under a REAL merge commit, a genuinely merged branch's own commits DO
become ancestors of `origin/main` — so "zero commits ahead of origin/main" stops meaning
"never touched" and starts also matching "already fully merged," and the exclusion silently
protects branches that should be cleaned up. event-vendor's own PITFALLS-equivalent
reasoning even named the assumption explicitly ("this repo squash-merges") — but a fix
copied from one repo to another does not automatically carry the copied repo's
environmental assumptions along with it if you don't check them.

**The check that would have caught this before writing any code:** does the target repo's
GitHub settings allow (or the team's practice guarantee) squash-merge only? Here,
`allow_merge_commit` and `allow_rebase_merge` were both enabled, and the test suite already
had a real merge-commit scenario as a first-class case — a five-second `gh api` check would
have flagged the mismatch before the exclusion was ever written into the script.

**When it went wrong anyway, what caught it:** the existing regression test suite, not
re-reading the reasoning. Trust the fixture-driven test failure over the imported
reasoning — the two broken tests were the actual signal that the borrowed fix didn't fit,
not a re-derivation of why it might not fit.

## Testing technique: simulating a TOCTOU race deterministically in a sequential test

Faking real concurrency in a bash test is unreliable (sleep-based races are flaky). Instead,
shim the specific command whose result needs to change mid-run, and use a marker file so the
shim only fires its side effect once — on the FIRST matching invocation — then falls through
to the real command for every other call, including the one you're actually testing.

```sh
# Fake `git`: pass everything through except one specific check, which fires a
# side effect after computing its real (pre-race) answer, then returns that answer
# unchanged — so a SECOND call with the same arguments sees the post-race state.
REAL_GIT=$(command -v git)
cat > "$FAKEBIN/git" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "merge-base" ] && [ "\$2" = "--is-ancestor" ] && [ "\$3" = "feat/late-commit" ] && [ ! -f "$MARKER" ]; then
  touch "$MARKER"
  "$REAL_GIT" "\$@"; RC=\$?
  ( cd "$WORKTREE" && "$REAL_GIT" commit -q --allow-empty -m "concurrent new commit" )
  exit \$RC
fi
exec "$REAL_GIT" "\$@"
EOF
```

This makes the race land at an exact, reproducible point in the script's execution instead
of depending on timing. See `tests/prune-branches.test.sh` (the "TOCTOU RACE" fixtures and
the fake `git`/`gh` wrappers) for the full working example, including the analogous `gh`
shim used to inject an untracked (not committed) file for the dirty-worktree variant of the
same race.

**When to use:** any check-then-act race in a script you can only exercise sequentially in a
test (no real background process). **When not to use:** if the race genuinely depends on
true parallel execution (e.g. two processes racing on a lock), a shim can't substitute for
an actual concurrency test — it only works when the "concurrent" side effect can be
deterministically pinned to a specific call in the sequential trace.

## Source

`scripts/prune-branches.sh`, PITFALLS.md ("A worktree snapshot taken at script startup goes
stale by the time the delete loop runs"), PR #132, follow-up issue #131.
