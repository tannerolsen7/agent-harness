## AI activity dashboard

Records one entry per top-level session stop and shows the full history in a
browsable HTML page committed to the repo.

### Confirmed behaviors

- **Session start writes temp file:** When `session-start.sh` runs and hook stdin
  JSON contains a `session_id` and `model`, it writes
  `/tmp/claude-activity-{session_id}` with a single line of the form
  `{start_unix_ts} {model}` — a Unix timestamp and the model string,
  space-separated.

- **Subagent stop writes no record:** When `session-stop.sh` runs and hook stdin
  JSON contains a non-empty `agent_type`, the hook exits without writing anything
  to `.claude/activity/`. Only top-level session stops produce records.

- **Top-level stop writes a valid JSONL record:** When `session-stop.sh` runs with
  no `agent_type` in hook stdin, it appends one valid JSON object to
  `.claude/activity/{branch-slug}.jsonl`. The object contains `ts` (ISO-8601 UTC),
  `branch`, `sha`, `model`, `skills` (array), and `duration_s` (integer or null).

- **Missing temp file yields null duration:** When the session temp file
  `/tmp/claude-activity-{session_id}` does not exist at stop time, the written
  record has `duration_s` set to `null` — not `0` and not omitted — and `model`
  set to `"unknown"`.

- **Skills are extracted and deduplicated:** The written record's `skills` array
  holds only the names of Skill calls found in the session permission log,
  deduplicated, with no duplicates. When the log is empty or absent, `skills`
  is `[]`.

- **activity-report.sh writes harness-activity.html:** Running
  `scripts/activity-report.sh` reads all `.claude/activity/*.jsonl` files and
  writes `harness-activity.html` with a summary bar (total sessions, top-3 skills,
  average duration excluding nulls) and a sessions table ordered newest-first
  (columns: Date, Branch, SHA, Model, Skills, Duration).

- **Bad JSONL line is skipped, not fatal:** A malformed line in any
  `.claude/activity/*.jsonl` file does not stop the report from completing. Valid
  records before and after the bad line still appear in the output.

- **update-progress.sh calls activity-report.sh:** Running
  `scripts/update-progress.sh` also regenerates `harness-activity.html` so the
  dashboard stays fresh at every session start.
