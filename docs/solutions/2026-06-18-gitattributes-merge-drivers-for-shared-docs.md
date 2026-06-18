# Pattern: .gitattributes + per-file merge drivers for shared doc files

**Problem class:** Recurring merge conflicts on shared files that many feature branches
touch concurrently — each branch adds content or updates a field, and the default 3-way
merge produces conflict markers that block every PR.

## When this bites you

A project has a handful of shared doc files — spec lists, finding logs, dashboards —
that every feature branch touches. Each branch adds entries or bumps counters. The
default merge produces conflicts on these files every time, and resolving them manually
is always the same mechanical operation: keep both sides, or pick the higher value.

The pain compounds in a multi-worktree workflow where a dozen branches are open at once:
every PR merge triggers another conflict, and they are never semantically interesting.

## The fix: `.gitattributes` declares a strategy per file

Git reads `.gitattributes` and applies the named merge strategy when it detects a
conflict on a file matching that pattern. No command-line flags needed; the strategy
is part of the repo.

### Three built-in strategies, one custom driver

**`merge=union`** — keeps all distinct lines from all sides. Safe for append-only doc
files (each branch adds a new section). Two branches each adding a new `##` heading at
EOF: both headings survive, no markers.

```
docs/TESTING.md           merge=union
docs/RECURRING-FINDINGS.md merge=union
```

**`merge=ours` (per-file driver)** — always keeps the CURRENT (main) branch version and
discards the OTHER (feature) version. Requires one local config entry:
`git config merge.ours.driver "true"`. Used for auto-regenerated files (dashboards,
progress pages) where the branch's version is always stale.

```
harness-progress.html     merge=ours
```

**Custom driver** — a shell script that receives `%O` (ancestor), `%A` (current/output),
`%B` (other) as temp file paths. The script resolves what it can and exits 0 (clean) or 1
(unresolved, markers left in `%A`). Custom drivers enable domain-specific logic like
"pick the higher task state on a status-field conflict."

```
TASKS.md                  merge=tasks-higher-state
```

### Registration is required for non-union strategies

`merge=union` is a git built-in. `merge=ours` and any custom driver must be registered
in `.git/config` — which is NOT committed. Wire the registration into `npm prepare` so
it runs on every `npm install`:

```sh
# scripts/register-merge-drivers.sh
git config merge.ours.driver "true"
git config merge.tasks-higher-state.name "TASKS.md higher-state-wins driver"
git config merge.tasks-higher-state.driver "sh scripts/tasks-merge-driver.sh %O %A %B"
```

```json
"prepare": "husky && bash scripts/register-merge-drivers.sh"
```

A fresh clone that runs `npm install` gets the hooks AND the merge driver registration.
Without this step, a fresh clone silently produces conflict markers instead of
auto-resolving — the `.gitattributes` file is present but the config it depends on is not.

## Writing a custom merge driver

The driver receives three positional args: `$1=%O` (ancestor), `$2=%A` (output),
`$3=%B` (other). Git reads `%A` after the driver exits to get the merged result.

**Algorithm pattern:**
1. Try `git merge-file "$CURRENT" "$ANCESTOR" "$OTHER"` first. If it exits 0 (clean
   3-way merge), done — the file is already resolved.
2. If non-zero (conflicts remain), process the conflict markers. For each conflict block,
   apply domain logic. Leave unresolvable conflicts as markers and set `bad=1`.
3. `exit $bad` — 0 = clean, 1 = unresolved markers remain.

**Guard the temp file:**
```sh
TMP=$(mktemp) || exit 1
trap 'rm -f "$TMP"' EXIT
awk '...' "$CURRENT" > "$TMP"
AWK_EXIT=$?
if [ "$AWK_EXIT" -le 1 ]; then
  mv "$TMP" "$CURRENT"
fi
exit $AWK_EXIT
```

Only replace `$CURRENT` when awk completed with an expected exit code (0 or 1). Any
other code (e.g. 127 = awk missing) leaves `$CURRENT` untouched; the trap cleans up
the temp file.

**Anchor field reads:** In awk, use `substr(s, 3, 3)` to read the task bracket at a
fixed position, not `index(s, "[x]")` which matches the substring anywhere in the line
(a task description like `- [ ] Support [x] syntax` would be misranked).

## Testing the driver

Each test creates a real temp git repo via `git init`, copies `.gitattributes` and
registers the drivers in the temp repo's config, makes three commits (base + two
conflicting branches), runs `git merge`, and checks the result. The subshells use
`>/dev/null 2>&1` to suppress merge noise; write `printf -- '- [x] ...'` (note the
`--`) to prevent bash's printf builtin from treating the leading `-` in the format
string as an option flag.

Cover all these cases:
- Higher-state wins: `[x]` beats `[~]`, `[~]` beats `[ ]`, `[x]` beats `[ ]`
- Unresolvable conflict exits non-zero and leaves markers (e.g. two branches changed
  both the status field AND a prose Notes field — status gets resolved, notes leaves markers)

## What doesn't work

**`merge=union` on files with mutable counters** — when two branches each increment the
same `**Occurrences:**` field, union keeps both lines. The file is not broken, but it
now has two conflicting count lines. This is acceptable as a lower-bound approximation;
it is NOT acceptable if the field drives automated logic.

**Relying on the comment to register drivers** — a comment in `.gitattributes` saying
"run `git config ...` after cloning" is always missed. Wire it into `npm prepare`.

## Where this applies in the codebase

- `.gitattributes` — five file rules: TESTING.md (union), RECURRING-FINDINGS.md (union),
  patterns-registry.md (union), harness-progress.html (ours), TASKS.md (custom tasks-higher-state driver)
- `scripts/tasks-merge-driver.sh` — the custom driver for TASKS.md
- `scripts/register-merge-drivers.sh` — wired into npm prepare
- `tests/gitattributes-merge-drivers.test.sh` — 27-case regression suite

## Tags

gitattributes, merge driver, union, ours, conflict prevention, shared docs, multi-worktree,
TASKS.md, task state, append-only, per-file strategy, npm prepare, fresh-clone setup
