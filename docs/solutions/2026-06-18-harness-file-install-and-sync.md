# Problem: Installing a Shared Toolset into Arbitrary Repos Without Destroying Project Knowledge

**Problem class:** A managed set of files (skills, agents, scripts, hooks) needs to be installed into arbitrary target repos and kept current over time. A naive "copy everything on sync" approach overwrites files the project team has customized. A git submodule or package manager approach adds coupling and network dependencies the user didn't ask for.

## When this bites you

You have a harness — skills, agents, hook scripts, settings — that lives in one repo and should work in many. You copy it into a new project. Six months later the harness has improved. You want to pull in those improvements. You run a copy. You just clobbered the `CLAUDE.md` that the team spent weeks filling with real architecture context, the `PITFALLS.md` that records lessons from three production incidents, and the `CONTEXT.md` that describes the domain. The only recovery is git — if the team committed those files before you overwrote them.

The reverse problem also bites: you want to preserve the harness files and only update those. So you skip the copy when a file already exists. Now a user's one-line edit to a hook script blocks an upstream security fix from ever landing.

## Root cause

The naive framing — "does this file exist?" or "does this file differ from source?" — has only two states per file. Files fall into at least three behavioral categories:

1. **Harness-owned:** always replace on sync (skills, scripts, hook configs).
2. **Starter templates:** install once from a template, then become project property (CLAUDE.md, PITFALLS.md, AGENTS.md, CONTEXT.md).
3. **Project-only:** never touch (TASKS.md, memory files, feature docs).

Without recording which category each file belongs to, any sync algorithm has to guess — and it guesses wrong for at least one category.

A two-value diff check ("local matches source?") also misclassifies a real conflict. If a user edited a harness-owned file and the source changed, that is a conflict. But if the user edited it and the source did not change, that is a user-only customization and overwriting it is wrong. You cannot tell the difference without a third data point: what the file looked like at install time.

## The fix

### Three-category classification with a per-file policy in the manifest

Install records every file in `.claude/.harness-manifest.json` with a `policy` field — either `"copy"` (harness-owned, always updated) or `"create-once"` (installed once, then project-owned). Category-3 files (project-only) never appear in the manifest. Sync ignores anything not in the manifest.

The manifest also records the `sha256` of each file at install or last-sync time. This is the anchor value for three-way comparison.

Manifest format (`.claude/.harness-manifest.json`):
```json
{
  "schema": 1,
  "source": "<local path to harness>",
  "sha": "<git sha of harness at install time, or 'local'>",
  "installed_at": "...",
  "synced_at": "...",
  "files": {
    "relative/path/from/repo/root": {
      "sha": "<sha256 of file at install/last-sync>",
      "policy": "copy | create-once"
    }
  }
}
```

See `scripts/install.sh` lines 61–78 (how entries are built) and lines 122–143 (manifest write).

### Three-way sha comparison for drift detection

For `"copy"` files, sync (`scripts/sync-harness.sh` lines 104–127) computes three values:

- `local_sha` — sha256 of the file on disk right now
- `old_sha` — sha256 stored in the manifest (what was there at last install or sync)
- `upstream_sha` — sha256 of the same file in the harness source

Decision table:

| `local == old_sha` | `local == upstream_sha` | `old_sha == upstream_sha` | Action |
|-|-|-|-|
| yes | yes | yes | up-to-date, nothing to do |
| yes | no | — | update from upstream |
| no | yes | — | user edited to match upstream already; mark up-to-date |
| no | no | yes | user-only edit; upstream unchanged; leave it alone |
| no | no | no | **CONFLICT** — exit non-zero, leave file untouched |

The fourth row is the false-positive trap: without `old_sha == upstream_sha` as a distinct case, a user edit on a file that upstream hasn't touched triggers a conflict. The fix is in `sync-harness.sh` line 119: `elif [ "$old_sha" = "$upstream_sha" ]; then` — user edited it, upstream didn't, leave it and record the local sha as current.

### Atomic manifest write (temp file + mv)

Both `install.sh` (lines 123–143) and `sync-harness.sh` (lines 139–161) write the manifest by building it into a `mktemp` file and then `mv`-ing it into place. A mid-run kill leaves the temp file orphaned and the manifest either still at its previous valid state or absent. Either way, a re-run is safe:

- If the manifest is absent (first install died mid-copy), `install.sh` reinstalls everything.
- If the manifest is present at the previous state, `sync-harness.sh` re-runs the three-way check correctly.

`sync-harness.sh` also withholds the manifest rewrite when any conflict exists (line 132: `[ -z "$conflicts" ]`). Conflicts leave the manifest at the pre-sync state so a retry after manual resolution starts from the same baseline.

### Separation of side-effect steps

`install.sh` makes no network calls and does not run `npm`. It only reads from `HARNESS_SRC` (a local path) and writes to `TARGET_DIR`. The husky/npm wiring is in `scripts/install-harness-hooks.sh`, which the user runs explicitly after inspecting it. This keeps `install.sh` safe to re-run from CI and avoids surprising network calls in environments with restricted access.

## Algorithm summary (sync-harness.sh)

```
for each entry in manifest.files:

  if policy == "create-once":
    if file missing: restore from template, record new sha
    else: skip — project owns this file
    continue

  # policy == "copy"
  if file missing: copy from upstream, record new sha; continue
  if source missing: skip with warning; continue

  local_sha    = sha256(file on disk)
  upstream_sha = sha256(file in HARNESS_SRC)

  if local == old_sha:
    if local == upstream: up-to-date
    else: update from upstream, record upstream sha
  elif local == upstream: up-to-date (user edited to match); record local sha
  elif old_sha == upstream: user-only edit; record local sha
  else: CONFLICT — add to conflict list, keep old_sha

after loop: if conflicts non-empty, exit non-zero
```

## When to reuse this pattern

Use this pattern when:
- A set of files is managed by one repo and consumed by many.
- Some of those files are starter templates that become project-owned after first install.
- You need a safe update path that doesn't require a human to diff every file by hand.
- You want CI to catch merge conflicts between harness updates and local edits.

The pattern works for any file-based toolset: scaffolding generators, shared CI configs, linter rulesets that projects might tune, documentation templates.

## When not to use this pattern

- When the "harness" is a library with a semver contract. Use a package manager instead — it handles versioning, dependency trees, and changelogs in ways a file manifest doesn't.
- When files are binary or generated. Sha comparison on generated files produces spurious conflicts every build.
- When the number of consuming repos is small enough that git submodules or a monorepo are practical. The manifest adds operational overhead (the manifest must stay in sync; consumers must run sync-harness.sh manually).
- When you need automatic updates. This pattern requires a human to run `sync-harness.sh`. Automated updates that overwrite local edits without a conflict check are unsafe.

## Files

- `scripts/install.sh` — first install; writes manifest last (atomic); lines 51–59 show the file classification, lines 66–110 show copy and create-once logic, lines 122–143 show atomic manifest write
- `scripts/sync-harness.sh` — update loop; three-way sha comparison at lines 104–127; false-positive guard at line 119; conflict holdback at line 132; atomic manifest write at lines 139–161
- `docs/features/one-command-install.md` — design contract; drift detection algorithm section describes the decision table in plain English
- `docs/TESTING.md` — "Install system" section; confirmed behaviors for all conflict, skip, and re-create cases

## Tags

file-sync, manifest, three-way-diff, drift-detection, sha256, create-once, idempotent, atomic-write, conflict-detection, toolset-distribution
