# Problem: Passing state between Claude Code hook invocations

**Problem class:** A Claude Code `SessionStart` hook needs to share data with a later `SessionStop` hook for the same session. Hooks are separate shell processes with no shared memory — environment variables and shell state don't survive across hook invocations.

## When this bites you

You want to compute a value at session start (a timestamp, the model name, an initial state snapshot) and use it at session stop. The two hooks run in separate processes. You cannot pass the data via an environment variable, a global, or a return value. If you try to read the value again at stop time, you get the stop-time value, not the start-time value — which defeats the purpose.

## Root cause

Claude Code invokes each hook type (SessionStart, SessionStop, PreToolUse, PostToolUse) as a separate shell process. There is no persistent parent process bridging them. Each hook reads from stdin and produces output independently.

## The fix

Write a temp file at `SessionStart`, keyed on `session_id`:

```bash
# In .claude/hooks/session-start.sh
_INPUT=$(cat)   # stdin can only be consumed once — read it first
_SESSION_ID=$(printf '%s' "$_INPUT" | jq -r '.session_id // ""')
_MODEL=$(printf '%s' "$_INPUT" | jq -r '.model // "unknown"')
if [ -n "$_SESSION_ID" ]; then
  printf '%s %s\n' "$(date +%s)" "$_MODEL" \
    > "/tmp/claude-activity-${_SESSION_ID}" 2>/dev/null || true
fi
unset _INPUT _SESSION_ID _MODEL
```

Read it at `SessionStop`:

```bash
# In .claude/hooks/session-stop.sh
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""')
TMPFILE="/tmp/claude-activity-${SESSION_ID}"
if [ -f "$TMPFILE" ]; then
  START_TS=$(cut -d' ' -f1 "$TMPFILE")
  MODEL=$(cut -d' ' -f2- "$TMPFILE")
  STOP_TS=$(date +%s)
  DURATION=$((STOP_TS - START_TS))
else
  MODEL="unknown"
  DURATION="null"    # use null, not 0 — 0 would mean "zero seconds", null means "not measured"
fi
```

The session_id is stable across the entire session and is unique per session.

## Why this approach works here

- `/tmp` is on a fast local filesystem — reads and writes add no measurable latency to the hook.
- The `session_id` is provided by Claude Code in the stdin JSON for both `SessionStart` and `SessionStop`. It is guaranteed stable for the session's lifetime.
- Scoping by `session_id` is safe for concurrent sessions in the same project (multiple worktrees, parallel agents). Each session gets its own file.
- Errors writing the temp file use `2>/dev/null || true` — the session start never blocks on this.

## When NOT to use this

- Don't use this for large data. If the state you're sharing is more than a few hundred bytes, consider a project-level state file instead.
- Don't assume the temp file will be there at stop time. If the session crashed before `SessionStart` ran its hooks, or if `/tmp` was cleared, the file will be absent. Always handle the missing-file case explicitly (use `null`, not `0`, for numeric fields that cannot be computed).
- Don't share state between unrelated hooks (PreToolUse → PostToolUse for a different invocation). Use the session_id only to correlate start↔stop.

## Related patterns

**Subagent guard:** Claude Code sets `agent_type` in the stdin JSON for sub-agent sessions. Hooks that should only run for top-level sessions must check this at the top:

```bash
AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // ""')
[ -n "$AGENT_TYPE" ] && exit 0
```

Place this guard BEFORE any work the hook does — including handoff output. Sub-agents do not need the same session lifecycle treatment as top-level sessions.

**Protecting session stop from hook failures:** Any write inside a `SessionStop` hook that might fail should run in an isolated subshell with errors redirected to stderr:

```bash
(
  set -euo pipefail
  # ... any writes or side effects ...
) 2>&1 | sed 's/^/my-writer: /' >&2 || true
```

The `|| true` after the subshell ensures any failure inside is swallowed. The `sed` prefix makes error messages identifiable in the user's terminal. This pattern is "fire and forget with a labeled stderr drain."

## Files involved

- `.claude/hooks/session-start.sh` — writes the temp file
- `.claude/hooks/session-stop.sh` — reads it, writes the JSONL record
- `scripts/activity-report.sh` — reads all JSONL records, writes HTML dashboard
- `.claude/activity/.gitkeep` — anchors the activity directory in git
- `tests/activity.test.sh` — tests all three pieces end to end
