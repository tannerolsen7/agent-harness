# One-Command Install

## What & Why

Engineers waste hours copying harness files by hand whenever they start a new project. There is no
standard way to bring in the skills, agents, hooks, and scripts that make the harness work. This
feature gives any repo a single command that installs the full harness as an add-on, and a
follow-up script that keeps it current without clobbering project-specific customizations —
including accumulated knowledge in `PITFALLS.md`, `docs/solutions/`, and memory files.

Without this, every new project requires a manual copy-paste session that is error-prone, produces
stale installs, and has no update path.

## Context

The harness lives in this repo. On first install, it places three categories of files in the
target repo.

**Category 1 — always update on sync** (harness owns these forever):
- `.claude/skills/` — all skill markdown files
- `.claude/agents/` — all agent definitions
- `.claude/hooks/` — all pre-tool and session hook scripts
- `.claude/settings.json` — harness permissions, hook wiring, deny lists (no env block; see below)
- `.claude/AI-WORKFLOW.md`, `.claude/agent-contract.md`, `.claude/SOUL.md` — harness docs
- `scripts/` — all shell scripts
- `docs/engineering-system/` — harness guidance docs
- `docs/security/` — security policy templates
- `.husky/pre-commit`, `.husky/pre-push`, `.husky/post-checkout` — git hooks

**Category 2 — create-once** (harness installs from a template; sync never touches them again):
- `CLAUDE.md` — from `docs/templates/CLAUDE.md`
- `PITFALLS.md` — from `docs/templates/PITFALLS.md`
- `AGENTS.md` — from `docs/templates/AGENTS.md`
- `CONTEXT.md` — from `docs/templates/CONTEXT.md`

These start as harness-provided starters and immediately become project knowledge. Project teams
fill them with real content over time — pitfalls discovered, architecture decisions, domain context.
A sync must never erase that work.

**Category 3 — never installed** (sync ignores these entirely; they are project-owned from day one):
- `TASKS.md`, `BACKLOG.md` — project work tracking
- `.claude/settings.local.json` — per-project environment block and custom permissions
- `docs/features/`, `docs/design/`, `docs/solutions/` — project-produced artifacts
- `.claude/memory/` — auto-memory notes accumulated during work
- `docs/TESTING.md` — project behavior specs

The `scripts/install-locks.sh` script shows the existing one-time install pattern for the
OS-level managed settings. `install.sh` follows the same philosophy: transparent, idempotent, and
never takes an action the user has not seen.

## Done Looks Like

- Running the one-command installs all category-1 and category-2 files into a target repo with no
  manual steps
- Running it a second time is safe — it reports what is up to date and does nothing else
- Category-2 files (CLAUDE.md etc.) are created if missing, skipped silently if they already exist
- `scripts/sync-harness.sh` updates category-1 files from a newer harness source; category-2 files
  are skipped even if they were never edited; category-3 files are ignored entirely
- Sync exits non-zero when any conflict is found (local edits + upstream change in a category-1
  file); every conflict prints the file path so the user knows what to resolve
- A deleted category-1 file is re-created on sync
- Project-specific settings survive in `.claude/settings.local.json` — never in the manifest,
  never touched by sync
- `tests/install.test.sh` passes: verifies install creates manifest, category-2 files are skipped
  on re-run, sync detects drift in a category-1 file while leaving a category-2 file untouched,
  sync exits non-zero on conflict, and deleted category-1 files are re-created
- The test suite asserts that every hook path referenced in `settings.json` appears in the
  manifest's file list

## Interface Contract

**The one command**

```bash
git clone <harness-url> /tmp/agent-harness && bash /tmp/agent-harness/scripts/install.sh
```

The install script reads from a local path (`HARNESS_SRC`). The user clones the harness repo
separately — no network calls happen inside install.sh. When the harness is published publicly,
the URL in this command is the only thing that changes.

**install.sh**

Inputs:
- `TARGET_DIR` (positional arg, default `.`) — path to the repo to install into; must be a git
  repo root; exits non-zero with a clear message if it is not
- `HARNESS_SRC` (env var, default: directory containing install.sh) — lets tests point at a local
  source without cloning

Outputs:
- Category-1 files written to `TARGET_DIR` (always)
- Category-2 files written to `TARGET_DIR` only if they do not already exist
- `.claude/.harness-manifest.json` written last (written last so a partial run leaves no manifest;
  a re-run sees no manifest and reinstalls everything safely)
- `settings.local.json` created from `docs/templates/settings.local.json` if it does not exist
  (this file is not in the manifest; it belongs to the project permanently)
- Exit 0 with a per-file summary: `installed`, `skipped (up to date)`, or `skipped (exists)`
- Exit non-zero if `TARGET_DIR` is not a git repo
- Prints a post-install block at the end:
  ```
  Next steps:
    1. bash scripts/install-harness-hooks.sh   # wire git hooks (reads package.json; runs npm install)
    2. bash scripts/install-locks.sh           # optional: place OS-level safety locks (requires sudo)
    3. Open Claude Code and run /init          # fill in project settings and create starter docs
  ```

**scripts/install-harness-hooks.sh**

A separate script for the husky / git hooks wiring step. install.sh does not run it because it
has side effects (network call via `npm install`; modifies `package.json`).

Behavior:
- If `TARGET_DIR/package.json` does not exist: creates a minimal one with `prepare` and `test`
  scripts for husky and the harness test runner
- If `package.json` exists and has no `prepare` or `test` entry: adds them
- If `package.json` exists and already has a `prepare` script: prints the exact lines to add
  manually and exits with a non-zero code and a clear message (never overwrites a pre-existing
  `prepare` script)
- Runs `npm install` to wire husky
- Verifies `.husky/pre-commit` is executable after wiring

**sync-harness.sh**

Inputs:
- `TARGET_DIR` (positional arg, default `.`) — must contain `.claude/.harness-manifest.json`;
  exits non-zero with a plain message if manifest is missing
- `HARNESS_SRC` (env var) — same override as install.sh
- `--dry-run` flag — prints what would change without writing anything

Outputs:
- Updated category-1 files in `TARGET_DIR`
- Updated `.claude/.harness-manifest.json`
- Per-file status line: `updated`, `up-to-date`, `re-created (was deleted)`, `skipped (create-once)`,
  or `CONFLICT: <path> — local edits + upstream change; resolve manually and re-run`
- Exit non-zero if any conflicts are found (so CI fails and forces a human to resolve them)

**Manifest format — `.claude/.harness-manifest.json`**

```json
{
  "schema": 1,
  "source": "<path or URL of harness source>",
  "sha": "<git sha of harness at install time, or 'local' if source is a dirty working tree>",
  "installed_at": "<ISO-8601 date>",
  "synced_at": "<ISO-8601 date, updated on each sync>",
  "files": {
    "<relative path from repo root>": {
      "sha": "<sha256 hex of file contents at install/last-sync time>",
      "policy": "copy | create-once"
    }
  }
}
```

`"policy": "copy"` — category-1 files; updated on sync when local matches manifest sha.
`"policy": "create-once"` — category-2 files; created on install if missing; sync skips them
always, even if the upstream template has changed. The `sha` field records what was installed
for audit purposes but is not used by drift detection.

The `policy` field exists in schema 1 so later policies (e.g. a merge strategy for
`package.json`) do not require migrating every installed repo.

**Drift detection algorithm (sync-harness.sh)**

For each entry in `manifest.files`:

```
if entry.policy == "create-once":
    if file does not exist on disk: create from HARNESS_SRC template, print "re-created (was deleted)"
    else: print "skipped (create-once)" and move on — it is project-owned now
    continue

# policy == "copy" from here
if file does not exist on disk:
    copy from HARNESS_SRC, update entry.sha, print "re-created (was deleted)"
    continue

local_sha  = sha256(file on disk)
upstream_sha = sha256(HARNESS_SRC / file)

if local_sha == entry.sha:        # file is unmodified since last install/sync
    if local_sha == upstream_sha: print "up-to-date" and skip
    else: copy from HARNESS_SRC, update entry.sha, print "updated"
elif local_sha == upstream_sha:   # user edited it but it already matches upstream
    update entry.sha, print "up-to-date"
else:                             # user edited it AND upstream changed — true conflict
    print "CONFLICT: <path>", add to conflict list
# after all files: if conflict list is non-empty, exit non-zero
```

**settings.json split — how project config survives updates**

The current harness `settings.json` mixes harness config (permissions, hook wiring, deny lists)
with a per-repo environment block (`autoMode.environment`) that every project must fill in. These
must be separated before install can work correctly.

The design:
- `settings.json` ships with only harness-owned content. The `autoMode.environment` placeholder
  block is removed from it. This file is category-1 (always updated by sync).
- `.claude/settings.local.json` carries the per-repo environment block and any project-specific
  permission additions. Claude Code merges `settings.local.json` on top of `settings.json` at
  startup. This file is category-3 (install creates it once from a template; sync never touches it).
- `settings.local.json` is committed to the target repo so the whole team shares the same
  AI environment context. Secrets are never in this file — they belong in `.env`.

Required fields in `settings.local.json` (filled in by `/init`):
- `project_name` — name of the project
- `tech_stack` — languages and frameworks (e.g. "TypeScript, Next.js, PostgreSQL")
- `package_manager` — npm / yarn / pnpm / bun
- `source_control_host` — GitHub / GitLab / Bitbucket
- `deployment_target` — Vercel / AWS / self-hosted / etc.

**Hook path consistency check**

The hook entries in `settings.json` reference exact paths inside `scripts/` and `.claude/hooks/`.
A test in `tests/install.test.sh` asserts that every hook path referenced in `settings.json`
appears as a `"policy": "copy"` entry in the manifest file list. This catches any future edit that
adds a hook reference to `settings.json` without adding the target to the install set.

**The `/init` skill**

After install.sh places the files, the user runs Claude Code and invokes `/init`. This skill:
- Checks whether `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `PITFALLS.md` exist and are filled in;
  copies templates from `docs/templates/` for any that are missing
- Walks the user through filling in the five required fields in `settings.local.json`
- Asks the user one optional question: "Is there anything else about your project the AI should
  know?" and writes the answer as a free-form note in `settings.local.json`
- Does not re-run install.sh; assumes install.sh has already run
- Reports what it created vs. what it skipped (already existed)

Constraints:
- install.sh must be a plain bash script with no dependencies beyond `git`, `sha256sum` (or
  `shasum -a 256` on macOS), and `cp`
- install.sh must be idempotent — safe to run twice on the same target
- install.sh writes the manifest last; a partial run leaves no manifest and a re-run is safe
- sync-harness.sh must never delete files that are not in its own manifest
- No file outside `TARGET_DIR` is modified by install.sh or sync-harness.sh
- install.sh makes no network calls; HARNESS_SRC is always a local path
- install-harness-hooks.sh runs `npm install` (network) but is a separate script the user
  explicitly runs after inspecting it

State:
- The only persistent state is `.claude/.harness-manifest.json`; no other state files are introduced

## Decisions Made

All six open questions from the initial design are resolved:

1. **Distribution** — harness is not yet public. The one command uses `git clone <private-url>`.
   When it goes public, only the URL in the README changes. No script changes needed.

2. **One-command form** — `git clone <url> /tmp/agent-harness && bash /tmp/agent-harness/scripts/install.sh`.
   Transparent: the user can read the script before running it.

3. **Sync conflict exit code** — non-zero. Conflicts fail CI and require human resolution.

4. **settings.local.json in git** — committed. It holds team configuration (stack, org, topology),
   not secrets. Committing it means every developer and every CI run gets identical AI behavior.

5. **Husky wiring** — separate `scripts/install-harness-hooks.sh`. install.sh prints the command
   to run but does not run it. The user inspects the script and runs it themselves.

6. **Template scope** — templates ship in `docs/templates/`. The `/init` skill copies them and
   fills in the five required environment block fields interactively.

## Out of Scope

- Fetching the harness from the network inside install.sh. The user clones separately.
- Automatic scheduled updates. A human runs sync-harness.sh when ready.
- Uninstall. No removal script in this task.
- Windows support. POSIX sh only. WSL is fine.
- Multi-harness installs (one target pulling from two harness sources).
- Notifying users when a `"create-once"` template has been updated upstream. They can compare
  manually against `docs/templates/` at any time.

## Relevant Files

- [scripts/install-locks.sh](../../scripts/install-locks.sh) — existing one-time install pattern; install.sh follows the same shape
- [.claude/settings.json](../../.claude/settings.json) — the file that must be split before install works; env block moves to settings.local.json
- [scripts/run-tests.sh](../../scripts/run-tests.sh) — must be wired into target's package.json by install-harness-hooks.sh
- [docs/engineering-system/04-context-docs.md](../engineering-system/04-context-docs.md) — describes CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md; governs what the templates must contain
- [README.md](../../README.md) — current file list of what belongs in the harness; governs which files go in the manifest
