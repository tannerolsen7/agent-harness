# TESTING.md Sharding

## What & Why

When two feature branches both run `@spec-writer` at the same time, they both append to `docs/TESTING.md`. Even with `merge=union` set in `.gitattributes`, two branches adding an identically-named `##` heading will produce a duplicate section after the merge. Giving each feature its own file at `docs/testing/<slug>.md` means no two branches ever write to the same path, eliminating that class of conflict entirely.

## Context

- `docs/TESTING.md` — current monolithic file, 7 `##` sections, 199 lines. This becomes the generated output; shards are the source of truth.
- `.claude/agents/spec-writer.md` — the agent that writes behavior entries. Its instructions currently reference `docs/TESTING.md` as the write target.
- `scripts/` — where `assemble-testing.sh` will live.
- No database. No UI screen.

## Done Looks Like

- `docs/testing/` directory contains one `.md` file per existing TESTING.md section (7 files at migration time).
- `scripts/assemble-testing.sh` is executable and concatenates all `docs/testing/*.md` files in alphabetical order, with a "generated" header block at the top, to produce `docs/TESTING.md`.
- Running the script twice in a row produces the same `docs/TESTING.md` (idempotent).
- `docs/TESTING.md` has a "generated — do not edit directly" comment at the top.
- `spec-writer.md` instructions tell the agent to write to `docs/testing/<slug>.md`, deriving the slug from the current branch name.
- A pre-commit hook regenerates `docs/TESTING.md` when any `docs/testing/*.md` file is staged.
- `docs/TESTING.md` is not gitignored — it stays in the repo.

## Interface Contract

**Slug derivation (used by spec-writer and assembly script):**
- Input: branch name from `git rev-parse --abbrev-ref HEAD`
- Algorithm: strip leading `feat/` prefix if present; replace `/`, spaces, and non-word characters with `-`; collapse runs of `-` into one; lowercase; trim leading and trailing `-`s.
- Examples: `feat/my-feature` → `my-feature`, `fix/auth-bug` → `fix-auth-bug`, `main` → `main`, `feat/auth/login-v2` → `auth-login-v2`.

**Shard file format:**
- Each shard is a standard Markdown file.
- It starts with the `##` section heading that was in the monolithic file.
- It contains one or more `### Confirmed behaviors` subsections with `-` bullet entries.
- There is no special header or footer — the assembly script provides those.

**Assembly script inputs/outputs:**
- Input: all `docs/testing/*.md` files, sorted alphabetically by filename.
- Output: `docs/TESTING.md` — a generated header block followed by each shard's content, separated by `---` dividers (same style as current monolithic file).
- Exit 0 on success, non-zero on failure (e.g., unreadable shard file).

**Constraints:**
- `docs/TESTING.md` must not be gitignored — it remains in the repo.
- Agents that grep `docs/testing/*.md` or read the assembled `docs/TESTING.md` must keep working.
- The assembled file must match the current monolithic file's content (minus the generated header) after migration.
- Assembly is idempotent: re-running it on an already-assembled file produces the same output.

**State:**
- Shard files are the source of truth. `docs/TESTING.md` is derived.
- No shared state between shards. Each file is independent.
- Assembly script is stateless.

## Out of Scope

- CI enforcement that shard files and assembled file are in sync (future work).
- Updating other agent instructions beyond `spec-writer.md` (they read TESTING.md; reads still work).
- Migrating worktree copies of TESTING.md (stale copies in `.claude/worktrees/` are not updated).

## Relevant Files

- `docs/TESTING.md` — source to migrate and assembly output target.
- `.claude/agents/spec-writer.md` — write-path instruction to update.
- `scripts/` — target directory for `assemble-testing.sh`.
- `.husky/pre-commit` — hook to update for shard-change detection.

---

# Design Questions Sheet

## 1. Data shape

No database changes. The data shape is filesystem-only:

- **`docs/testing/<slug>.md`** — new file per feature slug. Format matches current TESTING.md sections: starts with `## Heading`, followed by `### Confirmed behaviors`, then `-` bullet entries. No special header.
- **`docs/TESTING.md`** — assembled output. Starts with a generated comment header, then each shard file's content separated by `---` dividers.
- **No Zod schemas** — no trust boundary crossings; this is a file-write operation, not an API.

## 2. Edge cases

- **Branch name with path separator** (`feat/auth/login-v2`): slashes become hyphens → `auth-login-v2`. File is `docs/testing/auth-login-v2.md`.
- **Non-`feat/` branch** (`fix/my-bug`, `main`, `chore/cleanup`): only `feat/` prefix is stripped; other prefixes become part of the slug → `fix-my-bug`, `main`, `chore-cleanup`.
- **Empty `docs/testing/`**: assembly emits header only, no content. Valid output.
- **Shard file already exists**: spec-writer appends to it (same behavior as appending to the monolithic file, just different path).
- **Assembly run twice**: idempotent — same output both times because shards are sorted alphabetically and no timestamps or random values are injected.
- **Pre-commit hook with no shard changes staged**: hook checks whether any `docs/testing/*.md` file is staged; if not, it skips regeneration.

## 3. Resolved decisions (from grill)

- **Pre-commit hook behavior (resolved):** The hook auto-regenerates `docs/TESTING.md` and runs `git add docs/TESTING.md` when shard files are staged. Silent auto-add chosen over fail-and-prompt because the assembled file is 100% derived — no human decision is involved in staging it.
- **Non-`feat/` prefix stripping (resolved):** Strip `feat/` only. Other prefixes (`fix/`, `chore/`, etc.) become part of the slug. The `@spec-writer` path only runs via `/feature`, which always creates `feat/` branches.
- **Shard collision (resolved):** No collision detection in the assembly script. Slug collision requires two nearly identical branch names running simultaneously — effectively impossible in practice given TASKS.md-derived slugs.
- **Phase 1 base (resolved):** Merge `feat/gitattributes-merge-drivers` into the sharding branch before migrating, so Phase 1's `## Merge conflict prevention` section is included in the 8-shard migration. No rebase of Phase 1 needed.
