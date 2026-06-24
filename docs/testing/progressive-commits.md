## Spec commit before `/tdd` in the /feature pipeline

After the spec writer produces `docs/testing/<slug>.md`, a git commit captures
that file before `/tdd` starts. This prevents the spec from being lost if the
session crashes or context compacts between the spec step and the implementation
step. The commit runs in the Tiny, Small, and Medium /feature pipelines.

### Confirmed behaviors

- **Spec file present: commit runs with the correct message:** Given
  `docs/testing/<slug>.md` exists after the spec writer step, when the
  spec-commit step runs, it stages and commits that file with the message
  `docs(testing): behaviors for <slug>` where `<slug>` is the value returned by
  `bash scripts/derive-slug.sh`.

- **Spec file missing: pipeline stops with an error:** Given
  `docs/testing/<slug>.md` does not exist when the spec-commit step runs (for
  example, because the spec writer failed silently), the pipeline exits with an
  error and does not proceed to `/tdd`.

- **Spec commit runs in Tiny, Small, and Medium pipelines:** The spec-commit
  step is present in all three /feature pipeline variants (Tiny, Small,
  Medium). It is not limited to one size.

## Simplify commit in the /feature Small and Medium pipelines

After `/simplify` runs in the Small or Medium /feature pipeline, a git commit
captures all modified tracked files before `/cr` starts. This prevents
simplify-only changes from being lost if `/cr` crashes mid-run.

### Confirmed behaviors

- **Changes present after `/simplify`: commit runs with the correct message:**
  Given `/simplify` produces at least one modified tracked file, when the
  simplify-commit step runs, it executes `git add -u` and commits with the
  message `style(<slug>): simplify` where `<slug>` is the value returned by
  `bash scripts/derive-slug.sh`.

- **No changes after `/simplify`: step prints a notice and continues:** Given
  `/simplify` produces no changes to tracked files, when the simplify-commit
  step runs, it prints "nothing to commit — skipping" and proceeds to `/cr`
  without creating a commit. The pipeline does not stop.

- **`git add -u` is used, not a targeted file list:** The simplify-commit step
  stages all modified tracked files with `git add -u`. This means earlier
  uncommitted changes (such as CONTEXT.md edits from the grill step) are
  bundled into the same commit. That bundling is acceptable.

- **Simplify commit runs in Small and Medium pipelines only:** The
  simplify-commit step is present in the Small and Medium /feature pipelines.
  It does not run in the Tiny pipeline.

## CR-findings commit inside the `/cr` skill

After `/cr` completes Step 5 (triage and applying any fix-now changes), a git
commit captures those changes before the `.cr-ok` sentinel is written in
Step 7. This ensures cr-driven fixes are recorded before the sentinel signals
that review is complete.

### Confirmed behaviors

- **Changes present after Step 5: commit runs with the correct message:** Given
  `/cr` Step 5 produces at least one modified file, when the cr-findings-commit
  step runs, it stages and commits those changes with the message
  `fix(<slug>): apply cr findings` where `<slug>` is the value returned by
  `bash scripts/derive-slug.sh`.

- **No changes after Step 5: step skips silently:** Given `/cr` Step 5
  produces no file changes (for example, all findings were deferred or there
  were no findings), the cr-findings-commit step skips without printing
  anything. The pipeline continues to Step 6 and Step 7 normally.

- **CR-findings commit happens inside `/cr`, before the sentinel:** The commit
  runs before `/cr` writes `.claude/.cr-ok` in Step 7. By the time `/cr`
  returns control to `/feature`, the commit is already done and the sentinel is
  already written.

- **The existing final commit in /feature Small and Medium is not removed:**
  The final "Commit" step in the /feature Small and Medium pipelines remains as
  a safety-net fallback. It captures any stray uncommitted artifacts (such as
  docs or grill output) not already covered by the earlier intermediate commits.

## Spec commit in `@task-runner` after `@spec-writer`

After `@task-runner` Step 2 (`@spec-writer`) returns and writes
`docs/testing/<slug>.md`, a git commit captures the spec file before Step 3
(implement) begins. This matches the same protection provided in the /feature
pipeline.

### Confirmed behaviors

- **Spec file present: commit runs with the same message format as /feature:**
  Given `docs/testing/<slug>.md` exists after Step 2 returns, the spec-commit
  step stages and commits that file with the message
  `docs(testing): behaviors for <slug>` where `<slug>` is the value returned by
  `bash scripts/derive-slug.sh`.

- **Pre-commit gate still runs before the spec commit:** The mandatory
  pre-commit gate — which checks `.claude/questions.md` for BLOCKING entries —
  runs before this commit, just as it does before every commit in `@task-runner`.
  A BLOCKING question stops the commit.

- **@implementer per-slice commits are unchanged:** `@implementer` already
  commits after each implementation slice during the `/tdd` step. The
  task-runner spec commit does not change or replace that behavior.

- **@implementer must-fix commits in the fix loop are unchanged:** `@implementer`
  already commits must-fix items in the `@task-runner` fix loop. The
  task-runner spec commit does not change or replace that behavior.
