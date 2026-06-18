# TESTING — confirmed behaviors

Confirmed behaviors for the harness's own tooling. Each entry is a behavior a test
checks, not an invented requirement. Per-project work adds its own entries.

---

## Token linter (`scripts/token-lint.sh`)

Enforces design-system token usage in UI files. Catches hardcoded colors and
spacing, and flags six absolute design bans that are never acceptable regardless
of token use. Activated the moment `docs/design/DESIGN.md` exists in the repo.

### Confirmed behaviors

- **Token-only file passes:** A CSS file that uses only `var(--...)` references
  for colors and spacing exits 0 with no violations.
- **Hardcoded 6-digit hex exits non-zero:** A file containing a bare `#RRGGBB`
  value (not inside a `var()` call) causes the linter to exit 1 and name the
  violation in the output.
- **Hardcoded 3-digit hex exits non-zero:** A file containing a bare `#RGB` value
  (not inside a `var()` call) causes the linter to exit 1 and name the violation.
- **Raw color function exits non-zero:** A file using `rgb()`, `rgba()`, or
  `hsl()` directly causes the linter to exit 1 and mention the function name.
- **Ban — gradient text:** A file with `background-clip: text` (the CSS gradient-text
  pattern) causes the linter to exit 1 and mention "gradient" in the output.
- **Ban — glassmorphism:** A file with `backdrop-filter: blur` causes the linter
  to exit 1 and mention "glassmorphism" in the output.
- **Ban — side-stripe border (3px+):** A file with `border-left: 4px solid` causes
  the linter to exit 1 and mention "side-stripe" in the output.
- **Side-stripe 1px (divider) is allowed:** A file with `border-left: 1px solid`
  exits 0 — 1px is a functional divider, not a decorative stripe.
- **Ban — hero-metric template:** A file containing the class name `hero-metric`
  causes the linter to exit 1 and mention "hero-metric" in the output.
- **Warning — identical card grid:** A file containing the class name `card-grid`
  emits a warning and exits 0 (warning, not a hard error — human review required).
- **Warning — eyebrow label:** A file containing an `eyebrow` class emits a warning
  and exits 0 (one eyebrow per page may be acceptable; human review required).
- **Missing DESIGN.md skips without blocking:** When `docs/design/DESIGN.md` does
  not exist, the linter exits 0 and prints a message naming the missing file and
  telling the user to run `@design-synthesizer` to create it.

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
