# TESTING — confirmed behaviors

Confirmed behaviors for the harness's own tooling. Each entry is a behavior a test
checks, not an invented requirement. Per-project work adds its own entries.

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

---

## Performance budget (`scripts/perf-budget.sh`)

The budget checker reads Core Web Vitals targets from `config/perf-budget.json`
and compares supplied metric values against those targets. It always exits 0 —
breaches produce WARN output and are logged, but they never fail the build.
This keeps the check safe to add to CI before the measurement pipeline is proven
stable.

### Confirmed behaviors

- **Dry-run shows targets:** Given `--dry-run`, the script prints the targets for
  the named project and exits 0 without writing a log.
- **All metrics pass:** When every supplied metric is within its target, the script
  prints PASS for each metric and reports OK. Exit code is 0.
- **Breach is warned, not failed:** When a metric exceeds its target, the script
  prints WARN for that metric and a summary message. Exit code is still 0.
- **CLS float comparison works:** CLS is a decimal score (e.g. 0.05). The script
  compares it correctly against the decimal target.
- **Metrics not supplied are skipped:** Any metric omitted from the CLI or data
  file is printed as SKIP, not WARN. The check only fires on metrics with data.
- **Data file is read correctly:** Given `--data FILE`, the script reads metric
  values from a JSON file and compares them against the targets.
- **Missing data file fails loud:** If `--data FILE` is given but the file does
  not exist, the script prints an error and exits non-zero.
- **Missing config fails loud:** If `config/perf-budget.json` is absent, the
  script prints an error and exits non-zero.
- **Log is written on every run:** Each run writes a timestamped log file to
  `logs/perf-budget/` and updates a `latest_PROJECT.log` symlink.
- **Unknown argument fails loud:** An unrecognized flag causes an error message
  and a non-zero exit.
