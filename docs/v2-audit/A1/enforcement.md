# A1 — Enforcement Layer Inventory (Hooks + Permission Settings)

FACT-ONLY ground-truth record. No evaluation. Every claim cites `file:line`.
Slice: `.claude/hooks/*`, `.claude/settings.json`, `.claude/settings.local.json`, `.husky/*`.

Files read in full:
- `/Users/tanner/Dev/event-vendor/.claude/hooks/block-dangerous-git.sh`
- `/Users/tanner/Dev/event-vendor/.claude/hooks/block-npm-install.sh`
- `/Users/tanner/Dev/event-vendor/.claude/hooks/permission-logger.sh`
- `/Users/tanner/Dev/event-vendor/.claude/hooks/session-start.sh`
- `/Users/tanner/Dev/event-vendor/.claude/hooks/worktree-create.sh`
- `/Users/tanner/Dev/event-vendor/.claude/settings.json`
- `/Users/tanner/Dev/event-vendor/.claude/settings.local.json`
- `/Users/tanner/Dev/event-vendor/.husky/pre-commit`
- `/Users/tanner/Dev/event-vendor/.husky/pre-push`
- `/Users/tanner/Dev/event-vendor/.husky/post-checkout`

---

## `.claude/hooks/block-dangerous-git.sh`

**What it is / guards.** A `PreToolUse(Bash)` hook (header line 2) that parses a Bash command and blocks destructive/irreversible git operations. Exit 2 = block, exit 0 = allow (line 7).

**Trigger.** Registered under `settings.json` `PreToolUse` with `matcher: "Bash"` (`settings.json:158-165`). Fires on every Bash tool call.

**Logic / exact conditions:**
- Reads stdin JSON, extracts `.tool_input.command` via `jq` (line 15). If empty → exit 0 (line 16).
- **jq missing → fails OPEN** (exit 0) with a stderr warning that the guard is DISABLED (line 13). This is an intentional, documented fail-open.
- Splits `$CMD` on shell separators `;|&()\`` and newlines via `tr` (line 99), iterating each segment.
- Per segment: strips leading whitespace (line 34), peels leading `NAME=VALUE` env assignments using regex `ENVRE` (lines 31, 38-41), then strips wrapper words `sudo|env|command|time|nice|nohup|xargs|\` (lines 45-49).
- Requires `$1 = git` or skips the segment (line 50).
- Strips git global options `-C`/`-c` (consume 2 tokens), `--git-dir=`/`--work-tree=`/`--namespace=`/`-p`/`--no-pager`/`--paginate`/`--bare`, and any other `-*` (lines 52-59).
- Subcommand dispatch (lines 61-97):
  - `reset` → blocks only if an arg `--hard` is present (line 62).
  - `clean` → always blocks (line 63).
  - `rebase` → always blocks (line 64).
  - `stash` → blocks only if first arg is `clear` (line 65).
  - `branch` → blocks on any arg matching `-*D*` (force-delete), skips `--*` long opts (lines 66-72).
  - `push` → blocks `--force`, `--force-with-lease`, `--force-with-lease=*`, `--force=*`, and short `-*f*` (lines 74-80); then for non-flag args, normalizes the refspec dst via `norm_ref()` (strips quotes, takes `${r##*:}`, strips `refs/heads/`, lines 22-27) and blocks pushes whose dst is `main|master|develop` (lines 81-84).
  - `worktree remove` → allows only paths matching `.claude/worktrees/*` (and blocks those containing `..` traversal); blocks removal of any other path (lines 85-96).

**Verifiable gaps (facts):**
- **Fail-open on missing jq** (line 13): on any host without `jq`, the entire git guard is inert and the agent is told so on stderr only.
- **Protected-branch list is literal** `main|master|develop` (line 83). A push to any other default/protected branch name is not caught.
- `push` protected-branch check reads the **refspec dst**, not the currently checked-out branch. A bare `git push` with no refspec (relying on `push.default`) yields no non-flag arg, so `norm_ref` never runs → a bare `git push` while on `main` is **not blocked** by the protected-branch arm (only force variants would be). (Derived from lines 81-84: the loop only inspects explicit refspec args.)
- `git worktree add` is not restricted by this hook; only `worktree remove` path is gated (lines 85-96).
- Other destructive git verbs not covered: `update-ref -d`, `reflog expire`, `gc --prune`, `filter-branch`, `branch -M` (rename/force-create), `checkout -- .` / `restore` (working-tree discard), `tag -d`, `push --delete`, `push --mirror`. None appear in the dispatch (lines 61-97). (Fact: absent from the case list.)
- `--force-if-includes` and `--force-with-lease`-without-`=` are caught (line 76); but `push` deletion via `:branch` refspec to a protected branch: `norm_ref ":main"` → `${r##*:}` = `main` → **would block** (covered).

**Cross-references:** Comment at lines 86-87 references `AI-WORKFLOW.md` for the `.claude/worktrees/<slug>` convention. **`AI-WORKFLOW.md` does not exist** in the repo root (verified: `ls AI-WORKFLOW.md` → No such file). The dangling doc reference is informational only; logic does not read the file.

---

## `.claude/hooks/block-npm-install.sh`

**What it is / guards.** A `PreToolUse(Bash)` hook (header line 2) blocking npm commands that ADD a dependency. Allows `npm ci`, bare `npm install` (no package arg), and flag-only installs (line 3).

**Trigger.** Registered under `PreToolUse` `matcher: "Bash"` as the second hook in the array (`settings.json:166-169`). Fires on every Bash call alongside the git guard.

**Logic / exact conditions:**
- **jq missing → fails OPEN** (exit 0), warns guard DISABLED (line 6). Same fail-open as the git hook.
- Splits `$CMD` on `;|&()\`` + newlines (line 41), iterating segments.
- Per segment strips env assignments `[A-Za-z_]*=*` and wrappers `sudo|env|command|time|nice|nohup|\` (lines 14-20). (Note: wrapper list omits `xargs`, which the git hook includes.)
- Requires `$1 = npm` or skips (line 21).
- Scans args for an install/add token; tokens recognized: `install i in ins inst insta instal isntall isnt add link ln update up upgrade` (line 37) — includes common typos (`isntall`, `isnt`).
- Once the install token is found (`found=1`), the **next non-flag token** is treated as a package being added → block exit 2 (lines 27-34). Flags after the token are skipped (`-*) continue`).

**Verifiable gaps (facts):**
- **No `--ignore-scripts` handling.** The hook does not inspect or require `--ignore-scripts`; it blocks based solely on presence of a package-name positional. A blocked install is blocked regardless; an allowed bare `npm install` runs lifecycle scripts with no `--ignore-scripts` enforcement. (Fact: string `ignore-scripts` absent from file.)
- **Fail-open on missing jq** (line 6).
- Wrapper-word list (line 17) lacks `xargs` and `nohup`-chaining parity considerations present in the git hook; `time`/`nice` are present.
- `npm exec` / `npx <pkg>` (which can fetch+run arbitrary packages) is **not** matched — only literal `npm` with an install-family subcommand (line 21, 37). `npx` is not `npm`.
- `npm install <pkg>` is blocked, but the **allowlist in `settings.json:65` is `Bash(npm install*)`** which permits `npm install <pkg>` at the permission layer — the block hook is the only thing stopping it. If the hook fails open (no jq), `npm install <pkg>` is allowed end-to-end.
- Token matcher is exact-word per arg (line 36-38 `case` on whole token), so `install` embedded in a longer token won't false-positive; flag values consumed generically.

**Cross-references:** Enforces the CLAUDE.md rule "ask before installing any npm package" (referenced in block message, line 31).

---

## `.claude/hooks/permission-logger.sh`

**What it is / does.** Logs every tool call to a per-project JSONL file for session-end analysis to surface safe patterns not yet allowlisted (lines 2-3).

**Trigger.** Registered under `PreToolUse` with **NO matcher** (`settings.json:172-179`) → fires on **every tool call of every type**, not just Bash.

**Logic:**
- Reads stdin, extracts `.tool_name` (line 5), the first key of `.tool_input` (line 6), and that key's value truncated to 300 chars (line 7).
- Computes an 8-char `md5` hash of `CLAUDE_PROJECT_DIR` (line 8). Writes to `/tmp/claude-perm-log-${HASH}.jsonl` (lines 9-10).
- Always exit 0 (line 11) — never blocks.

**Verifiable gaps (facts):**
- Uses `md5` (line 8), a macOS/BSD binary. Verified present at `/sbin/md5`; `md5sum` (Linux) also present. On a Linux host without `md5`, the `HASH` computation would error and the line could mis-write; the script has no `command -v jq` guard, so if `jq` is missing this hook errors per call (unlike the two blocking hooks which guard jq). (Fact: no jq guard in this file.)
- Writes to `/tmp` only; `/tmp` is in `additionalDirectories` (`settings.json:143`).
- Purely observational — no enforcement.

**Cross-references:** Companion to `session-start.sh`, which truncates the same log path (the two share the `md5`-of-`CLAUDE_PROJECT_DIR` hashing, `session-start.sh:5` vs `permission-logger.sh:8`).

---

## `.claude/hooks/session-start.sh`

**What it is / does.** A `SessionStart` hook (registered `settings.json:148-157`). Two actions: (1) truncate the permission log so each session starts clean; (2) on remote sessions only, `npm install`.

**Logic:**
- `set -euo pipefail` (line 2).
- Computes the same `md5` HASH of `CLAUDE_PROJECT_DIR` (line 5) and truncates `/tmp/claude-perm-log-${HASH}.jsonl` via `> file` (line 6), errors suppressed (`|| true`).
- If `CLAUDE_CODE_REMOTE != "true"` → exit 0 (lines 8-10). So local sessions stop here.
- Otherwise `cd "$CLAUDE_PROJECT_DIR"` (line 12) and run `npm install` (line 14).

**Verifiable gaps (facts):**
- `npm install` at line 14 runs **without `--ignore-scripts`** in remote sessions (lifecycle scripts execute).
- Under `set -e` (line 2), if `npm install` fails on a remote session start, the hook exits non-zero. (Fact from `set -e` + final command.)
- No jq dependency here.

**Cross-references:** Shares log-path scheme with `permission-logger.sh`. `npm install` overlaps with `.husky/post-checkout` (which also conditionally runs `npm install` in fresh worktrees) and with the `Bash(npm install*)` allow entry.

---

## `.claude/hooks/worktree-create.sh`

**What it is / does.** A `WorktreeCreate` hook (registered `settings.json:181-189`). Creates/decorates an isolated git worktree for a subagent and provisions env files. Reads JSON on stdin with `name`; outputs the worktree path on stdout (lines 2-4).

**Logic:**
- `set -e` (line 4).
- Requires `jq` (line 7, **hard exit 1** if missing — fail-CLOSED, unlike the two Bash guards) and `CLAUDE_PROJECT_DIR` (line 8, exit 1 if unset).
- Extracts `.name` (line 11) and `.worktreePath`/`.worktree_path` (line 13).
- If a preset path is given, use it (back-compat, lines 12, 15-16); else build `WORKTREE=$CLAUDE_PROJECT_DIR/.claude/worktrees/$NAME`, `BRANCH=agent/$NAME` (lines 18-20) and `git worktree add -b "$BRANCH" "$WORKTREE" HEAD` if the dir doesn't exist (lines 21-24).
- **UNATTENDED branch** (lines 27-32): if `UNATTENDED=1`, run `scripts/gen-local-env.sh "$WORKTREE"`. On failure, print "local stack unavailable", `git worktree remove "$WORKTREE"`, exit 1. (This is the Tier-0 credential isolation path: no prod env symlinked in unattended mode.)
- **Attended branch** (lines 33-40): symlink each of `.env.local .env.test .env` from project root into the worktree if the source exists and dest doesn't (`ln -sf`, lines 34-39).
- Echo `$WORKTREE` to stdout (line 42).

**Verifiable gaps / facts:**
- `BRANCH=agent/$NAME` (line 19) — branch names are `agent/<name>`, distinct from the `.claude/worktrees/<slug>` path convention the git hook references.
- In attended mode (lines 34-39) it **symlinks `.env.local`**, which per repo memory/CLAUDE.md points at **production** Supabase. UNATTENDED=1 is the only mode that avoids prod credentials (lines 27-32). The default (env unset) is attended → prod env symlinked.
- `scripts/gen-local-env.sh` is referenced at line 28 and **exists** (verified `ls` → present, executable).
- Fail-closed on missing jq (line 7) — opposite posture from `block-dangerous-git.sh`/`block-npm-install.sh`.

**Cross-references:** Invokes `scripts/gen-local-env.sh` (line 28). Branch/path scheme is consumed by `block-dangerous-git.sh` worktree-remove gate (`.claude/worktrees/*`, that hook lines 92-93) and by `scripts/worktree-add.sh`/`scripts/gc.sh` (both exist).

---

## `.claude/settings.json`

**`env` (lines 2-5):** `CLAUDE_CODE_DISABLE_1M_CONTEXT=1`, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80`.

**`autoMode` (lines 6-32)** — natural-language policy lists, each prefixed `$defaults` (inherits built-in defaults):
- `environment` (7-15): org/context statements; notably line 14 states there is no staging/prod separation — treat all Supabase mutations as production.
- `allow` (16-20): git worktree add/remove; `supabase db reset` against localhost/127.0.0.1.
- `soft_deny` (21-26): no direct SQL migrations outside the Supabase CLI workflow; no Supabase row mutations outside `src/data/`; no use of `.env.local`/`.env` credentials for out-of-scope calls.
- `hard_deny` (27-31): no `DROP TABLE`/`DROP DATABASE`/`TRUNCATE`/`DELETE` without WHERE against prod; never force-push to main/master.
- **Fact:** `autoMode` lists are natural-language directives consumed by the autonomous-mode classifier, **not** deterministic regex gates. Their enforcement strength depends on the model honoring them; they are not shell-level blocks. The deterministic backstops for the same concerns live in the Bash hooks and `.husky/pre-push` (force-push) — `autoMode.hard_deny` force-push overlaps with `block-dangerous-git.sh` push arm.

**`permissions.deny` (lines 34-47):** all entries use a **leading slash** path:
- `Edit/Write(/.claude/hooks/**)`, `Edit/Write(/.claude/settings.json)`, `Edit/Write(/.claude/settings.local.json)`, `Edit/Write(/.claude/agents/**)`, `Edit/Write(/.env*)`, `Edit/Write(/supabase/config.toml)`.
- **Fact to verify (path form):** these are written as `/.claude/...` (leading slash = filesystem-root-anchored absolute form, not project-relative). Whether the harness interprets `/.claude/**` as repo-relative or as literal absolute `/​.claude` determines if these denies bite. The companion `allow` entries mix forms: some are absolute real paths (`/Users/tanner/Dev/event-vendor/**`, line 139-140) and some use the same leading-slash style (`Edit(/.claude/skills/cr/**)`, line 138). If `/.claude/**` resolves literally against filesystem root, the deny would not match files under `/Users/tanner/Dev/event-vendor/.claude/**` and would be **inert**. This is a structural ambiguity I can identify from the path strings but cannot resolve by reading alone — recorded as a factual inconsistency in path anchoring between deny (leading-slash) and the absolute allow entries (full `/Users/...` paths).

**`permissions.allow` (lines 48-141):** broad Bash allowlist including `Bash(git *)` (line 49), `Bash(gh pr/issue/label/api *)`, `Bash(scripts/*.sh*)`, `Bash(npm install*)` (line 65), `Bash(npm ci*)`, `Bash(npm run *)`, `Bash(npx tsc/vitest/wait-on *)`, `Bash(supabase *)`/`npx supabase *`, a docker family (lines 73-80), and a large read-only coreutils set (find/ls/grep/cat/wc/echo/date/jq/awk/sed/sort/uniq/head/tail/tr/cut/which/type/command -v/printf/mkdir, lines 81-100). Plus `MCP(chrome/*)`, ten `mcp__claude_ai_Supabase__*` entries (103-113), four `mcp__claude_ai_Notion__*` (114-117), `WebFetch(*)` (118), `Read(/Users/tanner/Dev/**)` and `Read(/Users/tanner/.claude/skills/**)` (119-120), seven `Skill(...)` pairs (124-137), and `Edit/Write(/Users/tanner/Dev/event-vendor/**)` (139-140), plus `Edit(/.claude/skills/cr/**)` (138).
- **Fact:** `Bash(git *)` (line 49) broadly allows git at the permission layer; the deterministic narrowing for dangerous git lives only in `block-dangerous-git.sh`. Same for `Bash(npm install*)` (line 65) narrowed only by `block-npm-install.sh`.
- **Fact (overlap):** `Bash(scripts/pr.sh*)` (54), `Bash(scripts/worktree-add.sh*)` (55), `Bash(scripts/gc.sh*)` (56) are individually listed AND covered by the broader `Bash(bash scripts/*.sh*)` (57).

**`permissions.additionalDirectories` (142-145):** `/tmp` and `/Users/tanner/Dev/event-vendor/.claude/worktrees`.

**`hooks` (147-201):** registrations:
- `SessionStart` → `session-start.sh` (148-157).
- `PreToolUse` matcher `Bash` → `block-dangerous-git.sh` then `block-npm-install.sh` (158-171).
- `PreToolUse` **no matcher** → `permission-logger.sh` (172-179) — fires on all tools.
- `WorktreeCreate` → `worktree-create.sh` (181-189).
- `Stop` → inline command playing a sound (`afplay` Glass.aiff, else BEL) (191-200).
- **Fact:** all hook commands use `$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh`. All five referenced scripts exist and are executable (verified `ls -la`).

---

## `.claude/settings.local.json`

**What it is.** A local (gitignored-by-convention, user-specific) permission overlay. Contains only `permissions.allow` (lines 3-50) and `permissions.additionalDirectories` (51-54). **No deny, no hooks, no autoMode.**

**Contents (facts):**
- `allow` is an accreted list of **highly specific, single-use** Bash invocations — exact `git -C /Users/tanner/Dev/event-vendor ...` commands (diffs, shows, status, log, rev-parse), several pointing at worktree paths (`/.claude/worktrees/agent-*`, lines 35-41), and prior-branch-specific shows (`feat/agent-guardrails:.husky/pre-push`, line 8). These are session-captured allowlist grants.
- Notable broad grants here: `Bash(git checkout *)` (line 23) and `Bash(xxd)` (18). `git checkout *` allows working-tree-discarding checkouts that `block-dangerous-git.sh` does **not** gate (the git hook has no `checkout` case).
- Edit grants for skill dirs: `Edit(/.claude/skills/cr-security/**)` (17), `Edit(/.claude/skills/notion-sync/**)` (22), `Edit(/.claude/skills/cr/**)` (34), `Edit(/.claude/skills/dev/**)` (47), `Edit(/.claude/skills/queue/**)` (48) — same leading-slash form as settings.json deny entries.
- `additionalDirectories` (51-54): the tool-results dir and `/Users/tanner/Dev/event-vendor/.claude/skills/cr`.
- **Fact:** this file grants only; it cannot tighten the project settings (no deny block present). Local allow entries are additive to `settings.json` allow.

---

## `.husky/pre-commit`

**What it is.** Git pre-commit hook (`.husky/pre-commit`).

**Logic (lines 1-6):** `set -e`, then `npm run lint`, `npx tsc --noEmit`, `npm run test:unit`. Any non-zero aborts the commit.

**Verifiable gaps / facts:**
- `npm run test:unit` = `vitest run --exclude 'src/data/**'` (verified from package.json). **Integration tests under `src/data/` are NOT run at commit time** — only at pre-push (`npm run test` = full `vitest run`). Fact.
- No `next build` at commit time (build runs at pre-push).
- Does not source `.husky/_/husky.sh` (unlike post-checkout) — it's a plain bash script with `set -e`.

---

## `.husky/pre-push`

**What it is.** Git pre-push hook enforcing the `/cr` gate and full test+build.

**Logic:**
- `set -e` (line 2). Reads all push refs from stdin (lines 7-15). If **all refs are deletions** (local-sha all-zeros) → exit 0 (lines 16-18). So branch deletions bypass the gate.
- `BRANCH = git rev-parse --abbrev-ref HEAD` (line 20).
- **`.env.local` required** (lines 22-25): if absent → block (integration tests need creds). Fact: this forces prod (or symlinked) creds present to push.
- **Merged-PR guard** (lines 28-35): if `gh` present and not detached HEAD, query `gh pr list --head $BRANCH --state merged`; if a merged PR exists → block (new commits need a new branch).
- **Interactive (TTY) path** (lines 37-46): prompts "Have you run /cr?"; non-`y`/`Y` aborts. Comment (line 45) notes `.cr-ok` is validated/consumed by `scripts/pr.sh`, not here.
- **Non-interactive (agent) path** (lines 47-72):
  - Detached HEAD → block (50-53).
  - `SHA = git rev-parse HEAD`; `EXPECTED = ${BRANCH}:${SHA}` (55-57).
  - `.claude/.cr-ok` must exist (59-62), be non-empty (63-67), and equal `EXPECTED` exactly (68-71); else block as missing/empty/stale.
  - Comment (line 72): sentinel validated but NOT consumed here (`scripts/pr.sh` is sole consumer).
- Then `npm run test` (full suite, line 75) and `npm run build` (line 76).

**Verifiable gaps / facts:**
- The sentinel `.claude/.cr-ok` **exists** (verified) and is **gitignored** (`.gitignore:58`). So it is a local, untracked file; a worktree without it must regenerate via `/cr`.
- Agent-path gate is a **string-equality sentinel** (`branch:sha`, line 57/68). Any process that writes the correct `branch:sha` string to `.claude/.cr-ok` satisfies it — the hook does not verify `/cr` actually ran (it trusts the sentinel content). Memory entry `feedback_sentinel_bypass` corroborates this is policy-enforced, not hook-enforced.
- Interactive path does **not** check the sentinel at all (lines 37-46) — relies on a typed `y` and on `scripts/pr.sh` later.
- `set -e` + `gh pr list` failure is mitigated by `|| true` (line 29).

---

## `.husky/post-checkout`

**What it is.** Git post-checkout hook.

**Logic (lines 1-9):** sources `.husky/_/husky.sh` (line 2, verified exists). If `$1` (previous HEAD) is all-zeros AND `node_modules` absent → echo + `npm install` (lines 6-8). All-zeros previous-HEAD is the signal of a freshly-created `git worktree add`.

**Verifiable gaps / facts:**
- `npm install` (line 8) runs **without `--ignore-scripts`** in fresh worktrees.
- Overlaps with `session-start.sh` (remote `npm install`) and `worktree-create.sh` provisioning — three independent code paths can run `npm install` for a new worktree depending on how it was created (git CLI vs harness WorktreeCreate vs remote session start).

---

## Cross-Reference / Overlap Map (facts)

- **jq fail-posture is inconsistent across hooks:** `block-dangerous-git.sh:13` and `block-npm-install.sh:6` fail **OPEN** (guard disabled) on missing jq; `worktree-create.sh:7` fails **CLOSED** (exit 1); `permission-logger.sh` and `session-start.sh` have **no jq guard** at all.
- **`--ignore-scripts` appears nowhere** in any of the five hooks. Three distinct `npm install` call sites (`session-start.sh:14`, `post-checkout:8`, plus the allowed `Bash(npm install*)`) run lifecycle scripts.
- **Permission-log hashing** is shared identically between `permission-logger.sh:8` and `session-start.sh:5` (`md5`-of-`CLAUDE_PROJECT_DIR`, first 8 chars).
- **Force-push to main is guarded twice:** `autoMode.hard_deny` (settings.json:30, advisory) and `block-dangerous-git.sh` push arm (deterministic, lines 74-84).
- **`git checkout`** is broadly allowed (`settings.local.json:23`) and has **no** dangerous-git hook case → working-tree-discarding checkouts are ungated.
- **`AI-WORKFLOW.md`** referenced in `block-dangerous-git.sh:86-87` does not exist (verified).
- **Sentinel `.cr-ok`** is the single deterministic gate tying pre-push (agent path) to the `/cr` workflow; `scripts/pr.sh` is the documented consumer (pre-push lines 45, 72). `.cr-feature-ok` is referenced in `settings.local.json` allow entries (27, 37) but **does not exist** on disk (verified).
- **Redundant allow entries:** `scripts/pr.sh*`, `scripts/worktree-add.sh*`, `scripts/gc.sh*` (settings.json 54-56) are subsumed by `Bash(bash scripts/*.sh*)` (57).
