# Design Questions — AI Activity Dashboard

_Post-grill revision. Three blocking findings folded in._

---

## 1. Data Shape

### Record schema (JSONL — one JSON object per line)

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

| Field | Type | Source |
|---|---|---|
| `ts` | ISO-8601 UTC string | `date -u +%Y-%m-%dT%H:%M:%SZ` at session stop |
| `branch` | string | `git rev-parse --abbrev-ref HEAD` |
| `sha` | string | `git rev-parse HEAD` (no guaranteed width — SHA-256 repos use 64 chars) |
| `model` | string | Captured at SessionStart (see Blocking Finding 1 below) |
| `skills` | string array | Filtered from perm log: `select(.tool=="Skill")` entries |
| `duration_s` | integer or `null` | Stop timestamp − start timestamp; `null` if unknown (not `0` — see Blocking Finding 2) |

### Storage location

`.claude/activity/{branch-slug}.jsonl` — one file per branch, append-only.

`branch-slug` = branch name with `/` replaced by `-`, then `[^a-zA-Z0-9-]` stripped.

Note: two branches that differ only in a stripped char (e.g. `feat/a.b` and `feat/ab`) produce the same slug. This is an accepted collision for now — see Open Question 3.

### Temp files — keyed by session ID, not project hash

The grill found that keying tmp files by project hash causes concurrent sessions on the same project to clobber each other. The correct key is the session ID from hook stdin.

**Session-start file:**
- Path: `/tmp/claude-activity-{SESSION_ID}`
- Content: one line: `{start_unix_ts} {model_string}`
- Written at: SessionStart, using `session_id` from hook stdin JSON

**Session-stop reads:**
- Reads `/tmp/claude-activity-{SESSION_ID}`, extracts start timestamp and model
- `SESSION_ID` comes from Stop hook stdin JSON field `session_id`

### Skills extraction

The existing `permission-logger.sh` logs `keys[0]` (sorted alphabetically). For Skill calls with both `skill` and `args` params, alphabetical order gives `args` first — the skill name is lost.

**Required change (human decision needed — see Open Question 5):** either extend `permission-logger.sh` to special-case Skill calls, or add a separate `activity-logger.sh` hook. The `.claude/hooks/` directory is Edit-blocked for the agent; hook changes are a human call.

### Subagent filtering (Blocking Finding 3)

The Stop hook fires for subagent stops too (every `@designer`, `@reviewer`, etc.). Subagent stops include `agent_type` on stdin. The writer must skip writing a record when `agent_type` is set — only top-level session stops should write records.

```bash
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // ""')
if [ -n "$AGENT_TYPE" ]; then
  exit 0  # subagent stop — skip
fi
```

### No database schema changes

This feature uses flat files only. No tables, no migrations.

---

## 2. Edge Cases

| Case | Handling |
|---|---|
| Branch name contains `/` or special chars | Slugify: `/` → `-`, strip `[^a-zA-Z0-9-]` |
| Two branches that differ only in stripped chars | Same slug — records go to same file. Accepted for v1. |
| Session stops before any commit | `sha` = whatever HEAD is — may be a prior commit. Correct behavior. |
| Permission log missing or empty | `skills` = `[]` |
| `model` not captured at SessionStart | `model` = `"unknown"` |
| Start-time file missing (SessionStart didn't write it) | `duration_s` = `null` |
| Activity directory doesn't exist | `mkdir -p .claude/activity/` before write |
| Write fails (disk full, perms) | Log to stderr, exit 0 — never block session stop |
| Two concurrent sessions on same project | Each has its own `session_id`-keyed tmp file — no collision |
| Subagent stops | `agent_type` set on stdin — skip writing record |
| `main` branch session | File is `.claude/activity/main.jsonl` |
| Malformed or truncated line in JSONL | Reader skips bad lines with a warning — one bad line must not break the whole report |
| Repo with no commits | `git rev-parse HEAD` fails — `sha` = `"unknown"` |

---

## 3. Open Questions — Human Must Decide

**1. Where are records stored — committed or gitignored?**

Option A (git-native): Commit `.claude/activity/` to the repo. Records travel with the codebase and are queryable from any clone with `jq`. Adds a new file to every merged PR. The audit trail is in git history.

Option B (flat-file, local-only): Gitignore `.claude/activity/`, same as `.cr-ok.log`. No repo noise. Records are only readable on the machine where work happened.

The task description says "flat-file or git-native" — which matters more?

---

**2. Dashboard placement — inline or separate?**

Option A: Inject an "AI Activity" section into the existing `harness-progress.html`, updated by `update-progress.sh`. One dashboard, one place to look.

Option B: New `harness-activity.html`. Keeps the progress dashboard focused on PR progress. Easier to browse long activity history.

---

**3. How to capture the model name?**

The grill confirmed: `$CLAUDE_MODEL` does not exist as an env var in hooks. `model` on hook stdin is only available at `SessionStart` (not Stop).

Option A: At SessionStart, read `model` from stdin JSON and write it to the session temp file. The Stop hook reads it back from the temp file.

Option B: Drop `model` from v1. The harness already shows the model in session context; it's not essential for the audit trail.

Option C: Hardcode the model as a constant in the start hook, updated manually when the project changes models. Simple but requires a manual update on model change.

---

**4. Skills extraction — which hook change?**

The current `permission-logger.sh` loses the skill name when a Skill call includes args (because `keys[0]` is alphabetically `args`, not `skill`). Two options to fix:

Option A: Edit `permission-logger.sh` to special-case `tool_name == "Skill"` and log the `skill` field explicitly.

Option B: Add a new `.claude/hooks/activity-logger.sh` PreToolUse hook that only handles Skill calls, leaving the existing permission logger unchanged.

`.claude/hooks/` changes are agent-blocked — this is a human edit.

---

**5. Branch-slug collision — acceptable?**

`feat/a.b` and `feat/ab` both slug to `feat-ab`. Records from both branches go to the same file.

Option A: Accept it — collisions are rare and the records include `branch` and `sha` to disambiguate.

Option B: Use a fuller slug — e.g. keep dots as hyphens instead of stripping them.

---

**6. `duration_s` type — `null` or `-1` for unknown?**

`null` is semantically clearest (JSON allows it). `-1` avoids nullable fields if the reader language doesn't handle null well. Both are better than `0`, which is indistinguishable from a real sub-second session.

---
