## Merge conflict prevention (`.gitattributes` + `scripts/tasks-merge-driver.sh`)

Four shared doc files accumulate changes from many feature branches at once.
Without help, git produces a conflict marker every time two branches touch the
same file. These behaviors describe how each file is handled so that concurrent
work auto-resolves without human intervention.

### Confirmed behaviors

- **TESTING.md auto-resolves concurrent appends:** When two feature branches
  each append a new `##` section to the end of `docs/TESTING.md` and are then
  merged, git keeps both appended sections and produces no conflict markers. The
  `.gitattributes` file assigns `merge=union` to `docs/TESTING.md`, which tells
  git to take all lines added on either side rather than picking one.

- **RECURRING-FINDINGS.md auto-resolves concurrent appends and field edits:**
  When two feature branches each append content to `docs/RECURRING-FINDINGS.md`,
  or when both branches update the same `**Occurrences:**` field, git keeps both
  versions and produces no conflict markers. If both branches edited the same
  field, the merged file contains two lines for that field — this is acceptable
  because occurrence counts are a lower bound, not an exact count. The
  `.gitattributes` file assigns `merge=union` to `docs/RECURRING-FINDINGS.md`.

- **harness-progress.html keeps the main-branch version on merge:** When a
  feature branch that auto-updated `harness-progress.html` (via the
  session-start hook) is merged into main, git discards the branch's version
  and keeps main's version. The branch's auto-updated timestamp, PR count, and
  progress bar values are all discarded. This is safe because the file is
  regenerated fresh at the next session start. The `.gitattributes` file assigns
  `merge=ours` to `harness-progress.html`.

- **TASKS.md uses a custom driver that picks the higher task state on
  conflict:** When two branches both update the same task's status field in
  `TASKS.md` and are then merged, the custom merge driver picks the higher state
  instead of producing a conflict marker. The state order from highest to lowest
  is: `[x]` (done) > `[~]` (in-progress) > `[ ]` (open). For example, if one
  branch set a task to `[~]` and the other set it to `[x]`, the merged result is
  `[x]`. The driver is implemented in `scripts/tasks-merge-driver.sh` and is
  registered in `.git/config` as a local driver named `tasks-higher-state`. The
  `.gitattributes` file assigns `merge=tasks-higher-state` to `TASKS.md`.
