# Problem: Porting a Doc Fix From a Downstream Copy Back Into the Canonical Source

**Problem class:** A project that consumes shared files from a source-of-truth repo (via a sync
script, a template, a plugin) sometimes fixes one of those files locally before the fix ever lands
upstream. Porting that fix back into the canonical repo looks like a simple copy or `git apply`,
but the canonical copy may have quietly diverged in the meantime — through its own independent
fix, or through unrelated development on the same file. Blindly applying the downstream diff can
silently discard the canonical repo's own changes, or corrupt a file whose content assumptions no
longer hold.

## When this bites you

`agent-harness` is the canonical repo for a set of Claude Code skills (`.claude/skills/**/SKILL.md`).
`event-vendor` is a downstream project that installed those skills via this repo's sync tooling.
Two separate PRs landed in `event-vendor` before the same fixes existed here:

- PR #200 fixed jargon in `design/SKILL.md`'s sign-off flow (three specific spots).
- PR #203 (a much larger sweep) added a "Presenting decisions to the human" standard to 22 skill
  files project-wide.

Porting #200 first (this session, first task) surfaced that `agent-harness`'s copy of
`design/SKILL.md` didn't have PR #200's fix yet — expected, since `event-vendor` got it first. But
while porting, a docs-review pass caught two real bugs *in the ported text itself* (a wrong
cross-reference, "Steps 3 and 5" instead of "Steps 3 and 4," and a confirmation-ordering
contradiction) that also existed in the *merged, upstream* PR #200. Those got fixed here, in the
canonical copy — meaning `agent-harness`'s `design/SKILL.md` was now *ahead* of `event-vendor`'s on
this one point, despite being behind on everything else PR #200 added.

Porting #203 next (same session) confirmed the general case: running `git apply --check` for each
of the 22 changed files against `agent-harness`'s current skill files found 17 files applied
cleanly, but 2 did not — `design/SKILL.md` (because of the fix above) and `queue/SKILL.md` (because
`agent-harness`'s `/queue` reads tasks straight from `TASKS.md`, while `event-vendor`'s had already
been adapted to query Linear via `list_issues` — a real content fork, not just a one-line fix). `dev`
and `notion-sync` didn't exist in `agent-harness` at all — they're skills `event-vendor` built for
itself and never contributed upstream.

## Root cause

Two repos that started from the same file will diverge the moment either one changes it — from a
local bugfix, from unrelated ongoing work, or from a skill that only makes sense in one project. A
diff generated against one repo's history encodes an assumption about what the "before" state looked
like. When you copy that diff to a different repo, you're implicitly asserting the assumption still
holds. It usually does — most files in a shared skill set don't change often — but assuming it
holds for *all* files without checking means:

- A file the canonical repo already fixed independently gets silently reverted to the older,
  buggy text (this would have happened here for `design/SKILL.md` if the port had been a blind
  copy-paste instead of a patch).
- A file that diverged into different *content*, not just a different fix, gets corrupted by a
  patch whose context lines don't match anything real in the target (this is what `queue/SKILL.md`
  would have looked like — the patch's context is Linear-flavored wording that never existed in
  `agent-harness`'s version).

## The fix

Never port a multi-file diff from a downstream copy by "apply it and see." Instead:

1. Split the source diff into one patch per file (`awk '/^diff --git/{n++} {print > sprintf("filepatch-%02d.diff", n)}' full.diff` — macOS `csplit` doesn't support `-z`, so `awk` is the portable option here).
2. For each file, run `git apply --check <patch>` against the target repo, from the target repo's
   root. This partitions the file list into two sets without touching anything:
   - **Clean** — context matches exactly, safe to `git apply` verbatim.
   - **Conflict** — context doesn't match, meaning the target has diverged since the diff's
     baseline.
3. Apply every clean patch directly (`git apply <patch>` — cheap and mechanical for the majority
   case; here that was 17 of 19 applicable files).
4. For each conflicting file, don't force the patch (`git apply --reject` still leaves partial,
   half-applied state that has to be reasoned about hunk-by-hunk). Instead: read what changed
   conceptually in the source diff (the *shape* of the fix — e.g. "add this standard's section,
   then add an 'invite to ask' sentence at each named decision point"), read the target file's
   actual current content at the same conceptual location, and hand-write the equivalent edit
   using the target's own wording, terminology, and step numbers. For `design/SKILL.md`, that
   meant keeping the harness's own "Steps 3 and 4" correction instead of reverting to the source's
   "Steps 3 and 5." For `queue/SKILL.md`, that meant translating "which issues to run" /
   `list_issues` language into "which tasks to run" / `TASKS.md`-native language, while still
   landing the same standard (full context, plain words, invite to ask) at the same decision
   points (Step 1's batch ask, Step 4's results report).
5. Files named in the source diff that don't exist in the target at all (`dev/SKILL.md`,
   `notion-sync/SKILL.md` here) are not divergence — they're scope that never applied to begin
   with. Skip them; don't manufacture a version of a skill the target project never asked for.

## Why this is the correct default

- **`git apply --check` is free and non-destructive.** It costs one command per file and never
  writes anything, so there's no reason to skip straight to a manual diff-read for files that turn
  out to apply cleanly.
- **A silent revert is worse than a loud failure.** If the port had been done by eyeballing the
  source PR's description and hand-copying "the same change" into each file, `design/SKILL.md`'s
  independent fix would have been overwritten with no error and no diff to review — it would have
  looked like a successful, complete port. `git apply`'s context check turns that into a visible
  conflict instead, which is the whole reason to prefer patch-based porting over prose-guided
  reproduction when the source is available as a diff.
- **Conflicts are a signal to read, not a blocker to force past.** `git apply --reject` or manually
  resolving `<<<<<<<` markers treats the conflict as a merge to win; the actual right move is
  almost always "re-derive the same *intent* against what's really here," which for a doc change
  means re-reading the target file's real content, not fighting the patch tool into accepting a
  hunk that doesn't belong.

## What doesn't work

**Copying the change file-by-file by re-reading the source PR's description and reproducing "the
same edit" from memory:**
- No mechanical signal when the target has already diverged — the fix looks complete because you
  did make *a* similar-looking edit; you just can't tell if it silently clobbered something the
  target repo already had right.

**`git apply` (no `--check`, no per-file split) against the whole multi-file diff at once:**
- One conflicting hunk in one file aborts or partially applies the entire patch depending on flags
  used, and diagnosing which of 22 files was the problem is slower than just checking each file
  first.

**Forcing conflicting hunks through with `git apply --reject` and manually resolving `.rej` files:**
- Works, but treats the source diff's context lines as ground truth to reconcile against, when the
  target file's actual current content is ground truth. For `queue/SKILL.md`, the source diff's
  context (Linear-flavored Step 1 wording) never existed in the target file at all — there was
  nothing to "reconcile," only a fresh edit to write using the target's real content as the base.

## Tags

skill-sync, upstream-port, git-apply-check, doc-drift, multi-repo-divergence, downstream-fix,
patch-reconciliation, cherry-pick-alternative, design-skill, queue-skill
