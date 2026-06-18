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

These start as harness-provided starters and become project knowledge. The team fills them with
real content over time — pitfalls discovered, architecture decisions, domain context. A sync must
never erase that work.

**Category 3 — never installed** (sync ignores these entirely; project-owned from day one):
- `TASKS.md`, `BACKLOG.md` — project work tracking
- `.claude/settings.local.json` — project-specific permission customizations
- `docs/features/`, `docs/design/`, `docs/solutions/` — project-produced artifacts
- `.claude/memory/` — auto-memory notes accumulated during work
- `docs/TESTING.md` — project behavior specs

The `scripts/install-locks.sh` script shows the existing one-time install pattern for the
OS-level managed settings. `install.sh` follows the same philosophy: transparent, idempotent, and
never takes an action the user has not seen.

## Done Looks Like

- Running the one command installs all category-1 and category-2 files with no manual steps
- Running it a second time is safe — it reports what is up to date and does nothing else
- Category-2 files are created if missing, skipped silently if they already exist
- `scripts/sync-harness.sh` updates category-1 files from a newer harness source; category-2
  files are skipped even if never edited; category-3 files are ignored entirely
- Sync exits non-zero when any conflict is found (local edits + upstream change in a category-1
  file); every conflict prints the file path
- A deleted category-1 file is re-created on sync; a deleted category-2 file is also re-created
  (from the template — it was deleted, so the template is the best restore)
- `tests/install.test.sh` passes: verifies install creates manifest, category-2 files skip on
  re-run, sync detects drift in a category-1 file while leaving a category-2 file untouched,
  sync exits non-zero on conflict, deleted category-1 files are re-created
- The test suite asserts that every hook path referenced in `settings.json` appears in the
  manifest's file list

## Interface Contract

**The one command**

```bash
git clone <harness-url> /tmp/agent-harness && bash /tmp/agent-harness/scripts/install.sh
```

The install script reads from a local path (`HARNESS_SRC`). The user clones the harness repo
separately — no network calls happen inside install.sh. When the harness goes public, the URL
in this command is the only thing that changes.

**install.sh**

Inputs:
- `TARGET_DIR` (positional arg, default `.`) — path to the repo to install into; must be a git
  repo root; exits non-zero with a clear message if it is not
- `HARNESS_SRC` (env var, default: directory containing install.sh) — lets tests point at a local
  source without cloning

Outputs:
- Category-1 files written to `TARGET_DIR` (always)
- Category-2 files written to `TARGET_DIR` only if they do not already exist
- `.claude/.harness-manifest.json` written last (if install.sh dies mid-run, no manifest exists
  and a re-run reinstalls everything safely — idempotent by design)
- Exit 0 with a per-file summary: `installed`, `skipped (up to date)`, or `skipped (exists)`
- Exit non-zero if `TARGET_DIR` is not a git repo
- Prints a post-install block at the end:
  ```
  Done. Next steps:
    1. bash scripts/install-harness-hooks.sh   # wire git hooks (inspectable; runs npm install)
    2. bash scripts/install-locks.sh           # optional OS-level locks (requires sudo)
    3. Open Claude Code in this directory and run /init
  ```

**scripts/install-harness-hooks.sh**

A separate script for the husky / npm wiring step. install.sh does not run it because it has
side effects (network call via `npm install`; modifies `package.json`).

Behavior:
- If `package.json` does not exist in `TARGET_DIR`: creates a minimal one with `prepare` and
  `test` scripts for husky and the harness test runner
- If `package.json` exists with no `prepare` or `test` entries: adds them
- If `package.json` exists and already has a `prepare` script: prints the exact lines to add
  manually and exits non-zero (never overwrites a pre-existing `prepare` script)
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
- Exit non-zero if any conflicts are found (CI fails and forces human resolution)

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
always. The `sha` field records what was installed for audit purposes but drift detection ignores
it for create-once entries.

The `policy` field exists in schema 1 so adding a merge strategy later does not require migrating
every installed repo.

**Drift detection algorithm (sync-harness.sh)**

```
for each entry in manifest.files:

  if entry.policy == "create-once":
    if file does not exist on disk:
      copy from HARNESS_SRC template, print "re-created (was deleted)"
    else:
      print "skipped (create-once)"   # it is project-owned; do not touch
    continue

  # policy == "copy" from here
  if file does not exist on disk:
    copy from HARNESS_SRC, update entry.sha, print "re-created (was deleted)"
    continue

  local_sha    = sha256(file on disk)
  upstream_sha = sha256(file in HARNESS_SRC)

  if local_sha == entry.sha:          # unmodified since last install/sync
    if local_sha == upstream_sha:
      print "up-to-date"              # nothing to do
    else:
      copy from HARNESS_SRC, update entry.sha, print "updated"
  elif local_sha == upstream_sha:     # user edited it but it already matches upstream
    update entry.sha, print "up-to-date"
  else:                               # user edited it AND upstream changed — conflict
    print "CONFLICT: <path>", add to conflict_list

after all files: if conflict_list is non-empty, exit non-zero
```

**settings.json split — how project config survives updates**

The current harness `settings.json` contains a per-repo environment block (`autoMode.environment`)
mixed in with harness-owned config. These must be separated.

The design:
- `settings.json` ships with only harness-owned content (permissions, hook wiring, deny lists).
  The `autoMode.environment` placeholder block is removed. Category-1: always updated by sync.
- `.claude/settings.local.json` is for project-specific **permission customizations only** (e.g.
  allowing specific bash commands). Not required on day one. If a project needs it, install.sh
  creates a minimal template. Category-3: sync never touches it.

**Where project description lives**

Project context — name, tech stack, architecture overview, process rules — belongs in **`CLAUDE.md`**,
not in `settings.json` or `settings.local.json`. CLAUDE.md is where Claude has always expected to
find "describe your project" content. It is visible, readable, and editable as plain text.

The harness template (`docs/templates/CLAUDE.md`) ships a fill-in skeleton. The `/init` skill
walks the user through filling it in interactively.

The `autoMode.environment` block is removed from the harness entirely. Project context goes in
CLAUDE.md. Permission customizations go in `settings.local.json` only if needed.

**Hook path consistency check**

The hook entries in `settings.json` reference exact paths inside `scripts/` and `.claude/hooks/`.
A test in `tests/install.test.sh` asserts that every hook path referenced in `settings.json`
appears as a `"policy": "copy"` entry in the manifest. This catches any edit that adds a hook
reference to `settings.json` without adding the target to the install set.

**The `/init` skill**

After install.sh places the files, the user opens Claude Code and runs `/init`. This skill:
- Copies `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `PITFALLS.md` from `docs/templates/` for any
  that are missing
- Walks the user through filling in the `CLAUDE.md` fill-in sections interactively: project name,
  tech stack, package manager, source control host, deployment target, and anything else Claude
  should know
- Reports what it created vs. what it skipped (already existed)
- Does not re-run install.sh; assumes install.sh has already run

**The setup checklist in the CLAUDE.md template**

`docs/templates/CLAUDE.md` ships with a `## Setup checklist` section at the very top. It is the
first thing a newly-installed user sees when they open CLAUDE.md:

```markdown
## Setup checklist (remove this section when done)
- [ ] `bash scripts/install-harness-hooks.sh`  — wire git hooks and npm
- [ ] `bash scripts/install-locks.sh`          — optional OS-level locks (requires sudo)
- [ ] Open Claude Code and run `/init`         — fill in this file and create starter docs
```

The checklist lives in CLAUDE.md — not only in terminal output from install.sh — because that is
where the user will be when they need it. Once the three steps are done, they delete this section.

Constraints:
- install.sh must be a plain bash script with no dependencies beyond `git`, `sha256sum` (or
  `shasum -a 256` on macOS), and `cp`
- install.sh must be idempotent — safe to run twice on the same target
- install.sh writes the manifest last; a partial run leaves no manifest and a re-run is safe
- sync-harness.sh must never delete files that are not in its own manifest
- No file outside `TARGET_DIR` is modified by install.sh or sync-harness.sh
- install.sh makes no network calls; HARNESS_SRC is always a local path
- install-harness-hooks.sh runs `npm install` but is a separate script the user explicitly runs

State:
- The only persistent state is `.claude/.harness-manifest.json`

## Decisions Made

All six open questions from the initial design are resolved:

1. **Distribution** — not yet public. One command uses `git clone <private-url>`. When it goes
   public, only the URL changes; no script changes needed.

2. **One-command form** — `git clone <url> /tmp/agent-harness && bash /tmp/agent-harness/scripts/install.sh`.
   Transparent: the user reads the script before running it.

3. **Sync conflict exit code** — non-zero. Conflicts fail CI and require human resolution.

4. **settings.local.json** — for permission customizations only, not project description. Most
   projects will not need it on day one. Project context lives in CLAUDE.md.

5. **Husky wiring** — separate `scripts/install-harness-hooks.sh`. install.sh prints the command;
   the user inspects and runs it themselves.

6. **Template scope** — templates ship in `docs/templates/`. `/init` copies them and walks the
   user through filling in CLAUDE.md interactively. A setup checklist at the top of the CLAUDE.md
   template tells new users exactly what to do next.

## Out of Scope

- Fetching the harness from the network inside install.sh. The user clones separately.
- Automatic scheduled updates. A human runs sync-harness.sh when ready.
- Uninstall. No removal script in this task.
- Windows support. POSIX sh only. WSL is fine.
- Multi-harness installs (one target pulling from two harness sources).
- Notifying users when a create-once template has been updated upstream. They can compare
  manually against `docs/templates/` at any time.

## Relevant Files

- [scripts/install-locks.sh](../../scripts/install-locks.sh) — existing install pattern; install.sh follows the same shape
- [.claude/settings.json](../../.claude/settings.json) — must be split: env block removed, project context moves to CLAUDE.md
- [scripts/run-tests.sh](../../scripts/run-tests.sh) — wired into target's package.json by install-harness-hooks.sh
- [docs/engineering-system/04-context-docs.md](../engineering-system/04-context-docs.md) — describes what CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md must contain; governs the templates
- [README.md](../../README.md) — current file list; governs which files go in the manifest
