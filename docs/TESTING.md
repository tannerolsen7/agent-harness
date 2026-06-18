# TESTING — confirmed behaviors

Confirmed behaviors for the harness's own tooling. Each entry is a behavior a test
checks, not an invented requirement. Per-project work adds its own entries.

---

## Progress auto-updater (`scripts/update-progress.sh`)

The script updates the mechanical fields in `harness-progress.html` —
the date, PR count, and progress bar — and writes a visible "last
auto-updated" line so you can tell at a glance that it ran and what changed.

### Confirmed behaviors

- **Last-updated line shows time and what changed:** Given `harness-progress.html`
  has an `auto-update-status` element, when `update-progress.sh` runs, it replaces
  that element's text with "Last auto-updated: [date] at [time] · [old]→[new] PRs"
  when the PR count changed, or "Last auto-updated: [date] at [time] · [N] PRs (no change)"
  when the count was already current.

---

## Context slicer (`scripts/slice-context.sh`)

The slicer turns a source file into a compact outline: the lines that declare
functions, classes, types, and exports, plus the structural headers that tell an
agent where each declaration sits. It drops function bodies and other detail the
agent does not need to understand what a file offers. The task-runner uses it when
it assembles REFERENCES context for a specialist, so a specialist gets the
signatures relevant to its task instead of the full file.

### Confirmed behaviors

- **Signature extraction (the gated path):** Given a file path argument, the
  slicer prints declaration lines and drops body lines. For a JavaScript or
  TypeScript file it keeps lines that declare a `function`, an arrow-function
  `const` assigned a `=>`, a `class`, an `interface`, a `type`, or an `export`,
  and it drops the statements inside a function body.
- **Output is smaller than input:** For any file with at least one multi-line
  function body, the sliced output has fewer lines than the original file.
- **Header anchoring:** Markdown heading lines (`#`, `##`, …) and shell/Python
  comment-style section banners are kept, so the agent can see where in the file
  each kept line lives.
- **Missing file fails loud:** Given a path that does not exist, the slicer prints
  an error to stderr and exits non-zero. It never prints a partial or empty slice
  as if it were a real result.
- **No path given fails loud:** With no file-path argument the slicer prints a
  usage message to stderr and exits non-zero.
- **Unknown file type falls back safely:** For a file type the slicer has no rules
  for, it prints the whole file rather than silently dropping content. A safe
  fallback never hides code from the agent.
