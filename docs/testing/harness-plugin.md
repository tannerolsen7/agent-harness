## Plugin manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`)

A new `.claude-plugin/` directory at the repo root holds two JSON files that let
Claude Code discover and install the harness as a plugin. Neither file has any
runtime behavior — they are read by Claude Code's plugin system at install time.

### Confirmed behaviors — `plugin.json`

- **`plugin.json` declares non-default skills location:** `plugin.json` includes
  `"skills": ".claude/skills"`. This tells Claude Code where to find skills
  because the harness stores them at a non-default path.

- **`plugin.json` declares non-default agents location:** `plugin.json` includes
  `"agents": ".claude/agents"`. This tells Claude Code where to find agent
  definitions because the harness stores them at a non-default path.

- **`plugin.json` includes all required top-level fields:** The file contains
  `name`, `description`, `version`, `author.name`, `license`, `skills`, and
  `agents`. None of these fields is absent.

### Confirmed behaviors — `marketplace.json`

- **`marketplace.json` sets `autoUpdate: true`:** The file includes
  `"autoUpdate": true` so Claude Code applies harness updates automatically at
  session start without manual intervention.

- **`marketplace.json` includes a `$schema` field:** A `$schema` key is present
  to help editors validate the file.

- **`marketplace.json` includes an `owner` field:** The file names the plugin
  owner so the marketplace can attribute the plugin correctly.

- **`marketplace.json` `plugins[]` entry points to `tanner/agent-harness`:** The
  array contains exactly one entry with a GitHub source reference to
  `tanner/agent-harness`.

### Confirmed behaviors — install commands

- **`/plugin marketplace add tanner/agent-harness` installs the plugin:** Given
  a user runs this command, Claude Code reads `marketplace.json` and registers
  the harness as a plugin. No manual file copying is required.

- **`/plugin install agent-harness@agent-harness` installs the plugin directly:**
  Given a user runs this command, Claude Code installs the plugin from the
  registry entry. Both commands result in the same installed state.

## Updated `/init` skill (`.claude/skills/init/SKILL.md`)

Step 0 changes from checking `.claude/.harness-manifest.json` to checking the
`$CLAUDE_PLUGIN_ROOT` environment variable. All remaining steps stay the same
except the setup checklist, which no longer tells users to run `install.sh` by
hand.

### Confirmed behaviors — Step 0: plugin root check

- **`$CLAUDE_PLUGIN_ROOT` not set causes `/init` to stop:** Given
  `$CLAUDE_PLUGIN_ROOT` is not set in the environment, Step 0 prints:
  `The agent-harness plugin is not installed. Run /plugin install agent-harness@agent-harness first.`
  and the skill stops without running any further steps.

- **`$CLAUDE_PLUGIN_ROOT` set to a non-existent directory causes `/init` to
  stop:** Given `$CLAUDE_PLUGIN_ROOT` is set but the directory it names does not
  exist on disk, Step 0 prints the same message as above and the skill stops.

- **`$CLAUDE_PLUGIN_ROOT` set to a valid directory lets `/init` continue:**
  Given `$CLAUDE_PLUGIN_ROOT` is set and the directory exists, Step 0 passes and
  the skill proceeds to Step 1.

- **Step 0 no longer checks for `.claude/.harness-manifest.json`:** Given
  `.claude/.harness-manifest.json` does not exist but `$CLAUDE_PLUGIN_ROOT` is
  valid, Step 0 does not stop. The manifest check has been removed from this
  step.

### Confirmed behaviors — Step 1: run install.sh via plugin root

- **Step 1 runs `bash "$CLAUDE_PLUGIN_ROOT/scripts/install.sh" "$(pwd)"`:**
  Given `$CLAUDE_PLUGIN_ROOT` is valid, Step 1 executes that command in the
  current project directory. This copies harness-owned files into the project
  and writes `.claude/.harness-manifest.json`.

- **Step 1 is idempotent:** Given `install.sh` has already run and
  harness-owned files exist, running `/init` again does not overwrite
  create-once files (such as `CLAUDE.md`). The script reports them as
  "skipped (exists)".

### Confirmed behaviors — setup checklist (Step 3)

- **Setup checklist lists only `bash scripts/install-harness-hooks.sh`:**
  The checklist shown in Step 3 no longer includes `bash scripts/install.sh`.
  Users no longer run `install.sh` manually — `/init` runs it for them via
  `$CLAUDE_PLUGIN_ROOT`.

## Session-start sync check (`hooks/check-project-sync.sh`, `hooks/hooks.json`)

Two new files at the plugin root (not inside `.claude/hooks/`) run a dry-run
sync check every time a Claude Code session starts. The hook tells the user when
project files are out of date or have a conflict, but never applies changes
automatically.

### Confirmed behaviors — `hooks/hooks.json`

- **`hooks.json` registers a `SessionStart` hook:** The file declares a
  `SessionStart` event that runs `check-project-sync.sh`. This causes Claude
  Code to execute the script at the beginning of every session where the plugin
  is active.

### Confirmed behaviors — `check-project-sync.sh`: project not initialized

- **Script exits 0 silently when no manifest exists:** Given
  `$CLAUDE_PROJECT_DIR/.claude/.harness-manifest.json` does not exist, the
  script exits 0 immediately without printing anything. The project has not been
  initialized, so there is nothing to sync-check.

### Confirmed behaviors — `check-project-sync.sh`: files out of date

- **Script prints one line when sync output contains `updated:`:** Given
  `sync-harness.sh --dry-run` produces at least one output line containing the
  word `updated:`, the script prints exactly:
  `[harness] project files are out of date — run /sync to apply updates`
  and exits 0.

- **Script prints exactly one line regardless of how many files are out of
  date:** Given three files are reported as `updated:` by the dry-run, the
  script still prints only one summary line, not one line per file.

### Confirmed behaviors — `check-project-sync.sh`: conflict detected

- **Script prints one line when sync output contains `CONFLICT`:** Given
  `sync-harness.sh --dry-run` produces at least one output line containing the
  word `CONFLICT`, the script prints exactly:
  `[harness] sync conflict detected — run /sync and resolve manually`
  and exits 0.

### Confirmed behaviors — `check-project-sync.sh`: clean state

- **Script exits 0 silently when sync output has neither `updated:` nor
  `CONFLICT`:** Given `sync-harness.sh --dry-run` exits 0 and no output line
  contains `updated:` or `CONFLICT`, the script exits 0 and prints nothing.

### Confirmed behaviors — `check-project-sync.sh`: error safety

- **Script never exits non-zero:** Regardless of what `sync-harness.sh` returns
  or what the dry-run output contains, the script always exits 0. A sync error
  does not block the session from starting.

- **Script never prints "checking..." or any progress output:** The script is
  silent unless it has a result to report (`updated:` or `CONFLICT` was found).
  No progress or status lines appear during the check.

## New `/sync` skill (`.claude/skills/sync/SKILL.md`)

A new skill that runs `sync-harness.sh` in the current project directory and
reports what changed or what conflicts need manual resolution.

### Confirmed behaviors — Step 0: plugin root check

- **`$CLAUDE_PLUGIN_ROOT` not set causes `/sync` to stop:** Given
  `$CLAUDE_PLUGIN_ROOT` is not set, Step 0 prints an error telling the user to
  install the plugin and stops. No sync attempt is made.

- **`$CLAUDE_PLUGIN_ROOT` set to a non-existent directory causes `/sync` to
  stop:** Given `$CLAUDE_PLUGIN_ROOT` is set but the directory does not exist,
  Step 0 prints the same install-instructions error and stops.

- **`$CLAUDE_PLUGIN_ROOT` set to a valid directory lets `/sync` continue:**
  Given `$CLAUDE_PLUGIN_ROOT` is valid, Step 0 passes and the skill proceeds to
  Step 1.

### Confirmed behaviors — Step 1: run sync-harness.sh

- **Step 1 runs `bash "$CLAUDE_PLUGIN_ROOT/scripts/sync-harness.sh" "$(pwd)"`:**
  Given `$CLAUDE_PLUGIN_ROOT` is valid, Step 1 executes that exact command. The
  current working directory is passed as the target.

- **sync-harness.sh output is passed through unchanged:** Step 1 surfaces the
  script's output directly without filtering or summarizing it. The user sees
  the same lines the script produces.

### Confirmed behaviors — Step 2: success summary

- **Step 2 runs only when the script exits 0:** Given `sync-harness.sh` exits 0
  (no conflicts), Step 2 prints a single line summarizing what changed. The
  summary is derived from the script's output.

- **Step 2 does not run when the script exits non-zero:** Given
  `sync-harness.sh` exits non-zero (conflicts found), the skill skips Step 2
  and proceeds to Step 3 instead.

### Confirmed behaviors — Step 3: conflict handling

- **Step 3 runs only when the script exits non-zero:** Given `sync-harness.sh`
  exits non-zero, Step 3 surfaces the list of conflicting files from the
  script's output and tells the user to resolve them manually before running
  `/sync` again.

- **Step 3 does not run when the script exits 0:** Given `sync-harness.sh`
  exits 0, the skill shows the Step 2 summary and skips Step 3.
