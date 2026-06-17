# Problem: new detection path in a safety script silently inherits no exclusions

**Problem class:** Safety exclusion drift — adding a new candidate-collection path to a
script that already has exclusion rules, without noticing the new path has none of them.

## When this bites you

You are extending a script that collects branches for a safety operation (cleanup, audit,
block-list check). The existing path has exclusion rules built up over time:

```sh
# existing path — collects branches with deleted remotes
GONE=$(git branch -vv | awk '/\[[^]]*: gone\]/ ...' | grep -v "^${CURRENT}$" || true)
```

You add a new detection path for a different class of candidate:

```sh
# new path — collects branches with no upstream at all
NO_UPSTREAM=$(git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ | \
  awk '$2 == "" { print $1 }' | grep -v "^${CURRENT}$" || true)
```

You copy the `grep -v "^${CURRENT}$"` exclusion (since that one is obvious), but miss the
`main|master|develop` exclusion that was embedded earlier in the GONE pipeline's processing
logic. The new path ships with a gap.

The gap is invisible during development: in normal repos these branches track origin/main,
so they don't appear in NO_UPSTREAM. The gap bites in a local-only repo or when gc runs
from a feature-branch worktree during overnight batch runs — the protected branch IS an
ancestor of HEAD, passes the merge-verify gate, and gets deleted.

## Root cause

Exclusion rules in a multi-pass collection script are not inherited by new passes. Each pass
starts from scratch. The CURRENT-branch exclusion is explicit and easy to notice. The
protected-name exclusion was baked into the downstream logic (e.g. "we only push protected
branches with `-u`, so they'll always be in GONE not NO_UPSTREAM") and not visible as a
signal in the new pass's code path.

## The fix

**Explicit exclusions in every pass.** Do not rely on invariants from a different pass's
assumptions:

```sh
NO_UPSTREAM=$(git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ | \
  awk '$2 == "" { print $1 }' | \
  grep -vE "^(main|master|develop)$" | grep -v "^${CURRENT}$" || true)
```

The `grep -vE "^(main|master|develop)$"` mirrors the same list already in
`block-dangerous-git.sh`. Any script that reasons about branch safety should use this
exact list — it's the project's canonical set of protected names.

## The invariant (replicate this when …)

When you add a new candidate-collection pass to any script that already has exclusion logic:

1. List every exclusion in the existing passes (not just the one you copied from).
2. Apply all of them to the new pass. Do not rely on downstream gates to compensate for
   missing exclusions — the downstream logic was written for the original pass's assumptions.
3. If the exclusions are scattered, consolidate them. The canonical protected-name list for
   this project is `main|master|develop`; use it everywhere.

**Related pattern — shared action loop:** When multiple passes feed the same operation,
combine their outputs first, then act once:

```sh
# collect
GONE=$(...)       # pass 1
NO_UPSTREAM=$(...)  # pass 2
# combine — sort -u deduplicates; one loop does the work
CANDIDATES=$(printf '%s\n%s\n' "$GONE" "$NO_UPSTREAM" | sort -u | grep -v '^$' || true)
if [ -n "$CANDIDATES" ]; then
  while IFS= read -r b; do
    # complex verify + action logic, written once
  done <<< "$CANDIDATES"
fi
```

This avoids duplicating the action loop (which in gc.sh includes a multi-step merge-verify,
worktree removal, and delete-with-recovery-hint). A duplicated loop means every future fix
must be applied in two places; a shared loop means it's written and tested once.

## What doesn't work

**Relying on the existing pass's assumptions to protect you.** "Protected branches always
have an upstream, so they'll never show up in NO_UPSTREAM" is true in most repos — but not
in local-only repos, and not after a misconfigured clone. A safety script that relies on
environmental invariants to fill its gaps is not a safety script.

**Adding the same exclusion to the downstream processing.** The verify loop already has a
merge-check gate, but `git merge-base --is-ancestor main HEAD` passes whenever gc runs from
a feature branch. The gate is for "was this merged?" not "is this protected?". A protected
branch that was merged would still pass it.

## Where this applies in the codebase

- `scripts/gc.sh` — two-pass branch cleanup (Pass 1: `[gone]` after remote delete; Pass 2:
  no-upstream after local merge). Both passes exclude `main|master|develop` and `$CURRENT`.
- `block-dangerous-git.sh` — the canonical source for the `main|master|develop` protected
  list. When this list changes, update both files.

## Tags

gc, branch cleanup, exclusion rules, multi-pass collection, protected branches, safety
script, detection path, merge-verify, main/master/develop, no-upstream, shell script
