# AI Activity Dashboard

## What & Why

Engineers have no visibility into what Claude does per task — which model ran, which skills fired, how long a session took, or which commit it landed on. Without this, there's no way to audit AI cost, catch slow or expensive patterns, or trace exactly what happened on a given branch. This feature writes one record per session stop and shows the full history in a browsable HTML page that lives in the repo.

## Context

- `.claude/hooks/session-stop.sh` runs at every top-level session stop. It already reads branch, commit, and worktree state. We extend it to append an activity record.
- `.claude/hooks/session-start.sh` runs at SessionStart. We extend it to capture `model` from hook stdin and write a session-keyed temp file.
- `.claude/hooks/permission-logger.sh` already logs every tool call to `/tmp/claude-perm-log-{HASH}.jsonl`. Updated (Q4) to special-case Skill calls and capture the `skill` field.
- `scripts/update-progress.sh` is the pattern for how a script reads git/file state and updates HTML. The new `scripts/activity-report.sh` follows the same pattern.
- `harness-progress.html` is the existing progress dashboard. A parallel `harness-activity.html` is the new activity dashboard.

## Done Looks Like

- After a top-level session stop on a feature branch, `.claude/activity/{branch-slug}.jsonl` has a new line with ts, branch, sha, model, skills, and duration_s.
- Subagent stops write no record (checked via `agent_type` on hook stdin).
- `scripts/activity-report.sh` reads all `.claude/activity/*.jsonl` files and writes `harness-activity.html`: a summary bar and a sessions table, newest first.
- `harness-activity.html` is committed to the repo — browsable locally and via GitHub Pages if enabled.
- `scripts/update-progress.sh` calls `activity-report.sh` so the HTML refreshes at each SessionStart.
- Tests in `tests/activity.test.sh` verify: (a) a valid record is written on a simulated stop; (b) a subagent stop writes no record; (c) a bad line in a JSONL file is skipped, not fatal.
- `.claude/activity/` is tracked by git (not gitignored).

## Interface Contract

**Record schema** — JSONL, one object per line, in `.claude/activity/{branch-slug}.jsonl`:

```json
{
  "ts":         "2026-06-17T21:00:00Z",
  "branch":     "feat/design-synthesizer",
  "sha":        "1708637307276f2b156f36fa2f72615f99995cfd",
  "model":      "claude-sonnet-4-6",
  "skills":     ["design", "cr"],
  "duration_s": 142
}
```

| Field | Type | Source | Missing fallback |
|---|---|---|---|
| `ts` | ISO-8601 UTC string | `date -u +%Y-%m-%dT%H:%M:%SZ` at stop | — (always available) |
| `branch` | string | `git rev-parse --abbrev-ref HEAD` | `"unknown"` |
| `sha` | string | `git rev-parse HEAD` | `"unknown"` |
| `model` | string | read from session temp file (written at SessionStart) | `"unknown"` |
| `skills` | string array | perm log: `select(.tool=="Skill") \| .val`, deduplicated | `[]` |
| `duration_s` | integer or `null` | stop_ts − start_ts from temp file | `null` |

**Session temp file** — written at SessionStart, read at Stop:
- Path: `/tmp/claude-activity-{SESSION_ID}` where `SESSION_ID` = `session_id` from hook stdin JSON
- Content: `{start_unix_ts} {model_string}` — space-separated, single line
- Example: `1750197600 claude-sonnet-4-6`

**Branch slug rule:**
- Replace `/` with `-`
- Strip characters that are not `a-z`, `A-Z`, `0-9`, or `-`
- Example: `feat/design-synthesizer` → `feat-design-synthesizer`
- Accepted collision: two branches differing only in stripped chars map to the same file; `branch` field inside each record disambiguates.

**Subagent guard** (in session-stop.sh extension):
```bash
AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // ""')
[ -n "$AGENT_TYPE" ] && exit 0
```

**Reader — scripts/activity-report.sh:**
- Reads all `.claude/activity/*.jsonl` files
- Skips lines that fail `jq` parse — one bad line must not crash the report
- Writes `harness-activity.html`

**Dashboard — harness-activity.html:**
- Summary bar: total sessions | most-used skills (top 3) | average duration (null values excluded)
- Table columns: Date | Branch | SHA (first 7 chars) | Model | Skills | Duration

**Constraints:**
- Writer never blocks session stop — errors go to stderr, exit 0
- Reader tolerates malformed JSONL lines — skip and continue
- Shell + jq only — no Node, no Python
- Hook files in `.claude/hooks/` are human-edited (agent-write-blocked)
- Temp files keyed by `session_id` to prevent concurrent-session collision

**State:**
- `.claude/activity/` owns all records — append-only, committed to repo, never deleted by tooling
- Temp files in `/tmp/` are session-scoped and abandoned after stop (no cleanup needed)

## Out of Scope

- Token counts per task (no API instrumentation for this)
- Real-time activity streaming mid-session
- Multi-project aggregation
- Alerts or thresholds on duration or cost
- Filtering or search in the dashboard (v1 shows all records, newest first)
- Pixel-diff CI gate on the dashboard HTML

## Relevant Files

- `.claude/hooks/session-stop.sh` — extend to write the activity record
- `.claude/hooks/session-start.sh` — extend to write session temp file (start_ts + model)
- `.claude/hooks/permission-logger.sh` — already updated (Q4) to log skill names correctly
- `scripts/activity-report.sh` — new: reads JSONL files, writes harness-activity.html
- `scripts/update-progress.sh` — call activity-report.sh here so HTML stays fresh
- `harness-activity.html` — new dashboard
- `tests/activity.test.sh` — new tests
- `.claude/activity/` — new directory, committed to repo
