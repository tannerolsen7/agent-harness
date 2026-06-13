# Cluster D — Enforcement, Settings, Global Config, Git Discipline (CANON inventory)

Fact-only inventory of what the canonical "AI-Native Engineering System" (Notion) DECLARES about the
harness enforcement layer, settings.json model, global config, and git discipline. No recommendations,
no design. Every claim is tagged `[CANON-DECLARES]` and cited to a source page. "No claim without a citation."

**Sources fetched (with last-edited timestamps in the fetch):**

| Page | Notion ID | Fetched-as-of |
|------|-----------|---------------|
| 08 · Settings & Permissions | `358e2971cd6281a1a3a5d5487bd3fddf` | 2026-06-04 |
| 09 · Global Config | `358e2971cd62810a8b8fd934e1484466` | 2026-05-18 |
| 14 · Git Discipline | `367e2971cd62815fa056cda8f4238aee` | 2026-05-21 |
| Setup Prompts | `359e2971cd6281dd9f21d1af5e4d0b30` | 2026-05-21 |
| Templates (index) | `359e2971cd62819e9142c30b99fecb6c` | 2026-06-09 |
| Template: settings.json | `359e2971cd62811b8bece1616014c277` | 2026-06-04 |
| Template: block-dangerous-git.sh | `375e2971cd62815495eefdabba967f70` | 2026-06-04 |
| Template: block-npm-install.sh | `375e2971cd6281e6...e18fb2db7f08eb0c2e` | 2026-06-04 |
| Template: block-dangerous-bash.sh | `375e2971cd62817fa704d3b84a7e3480` | 2026-06-04 |
| Template: .husky/pre-push | `364e2971cd62812a9191e4ff14e36693` | 2026-06-04 |
| Template: .githooks/pre-commit | `364e2971cd6281b99218e156f8653543` | 2026-05-18 |
| Template: .husky/post-checkout | `36ee2971cd6281bbaabecb132da91e8e` | 2026-05-28 |
| Template: Global config (`~/.claude/CLAUDE.md`) | `359e2971cd6281c3904bc5604a7b33c9` | 2026-05-18 |

---

## 1. Every HOOK the canon defines

The canon declares hooks across two surfaces: **Claude Code hooks** (wired in `settings.json` under `hooks.<Event>`)
and **git hooks** (`.husky/*`, `.githooks/*`, tracked via `core.hooksPath`). The exact script names are taken from
the canonical `settings.json` template and the individual template pages.

### 1a. Claude Code hooks (settings.json `hooks` key)

| Hook (canon script name) | Event | What it does | STRUCTURAL / observational |
|--------------------------|-------|--------------|----------------------------|
| `.claude/hooks/session-start.sh` | `SessionStart` | Wired in the settings.json template under `SessionStart`. Canon does not give the script body; note says "Remove the SessionStart hook if you don't have a `session-start.sh` yet." | Not specified (no body given) |
| `.claude/hooks/block-dangerous-git.sh` | `PreToolUse` (matcher `Bash`) | Blocks destructive/irreversible git ops: `git push` (to protected branch), force pushes (incl. `+refspec`), `git reset --hard`, `git rebase`, `git clean`, `git branch -D`, `git stash clear`, `worktree remove` outside `../worktree-*`. Exit 2 = block, exit 0 = allow. Parses command SEGMENTS, strips env assignments / wrapper words / git global options (`-C`/`-c`). Fails OPEN (exit 0) with stderr warning if `jq` missing. | **STRUCTURAL (blocks, exit 2)** [CANON-DECLARES] |
| `.claude/hooks/block-npm-install.sh` | `PreToolUse` (matcher `Bash`) | Blocks `npm install`/`npm add` of a **package** (incl. flag-first `npm i -D x`, global-first `npm -g install x`, `npm --prefix p install x`). Allows `npm ci`, bare `npm install`, flag-only installs. Enforces "ask before adding a dependency." Exit 2 = block. Fails OPEN if `jq` missing. | **STRUCTURAL (blocks, exit 2)** [CANON-DECLARES] |
| `.claude/hooks/block-dangerous-bash.sh` | `PreToolUse` (matcher `Bash`) | "Safety floor" — third Bash guard. Blocks deploys (`serverless`/`sls`/`npm run deploy`), recursive `rm` / `find … -delete`, and any command that WRITES to the agent's boundary (`.claude/settings*`, `.claude/hooks*`, `.git/`, `.husky/`). Reads of those paths pass; unmatched commands pass. Exit 2 = block. Fails OPEN if `jq` missing. | **STRUCTURAL (blocks, exit 2)** [CANON-DECLARES] |
| Stop sound hook (inline command, no script file) | `Stop` | Plays a sound when any session finishes: `afplay /System/Library/Sounds/Glass.aiff` else `printf '\a'`. "Critical when running parallel sessions." | Observational (notification only) [CANON-DECLARES] |
| `.claude/hooks/session-end.sh` | `Stop` (second Stop hook, paired with sound) | Proposes `memory.md` candidates after sessions that produced file changes. Two gates: (1) skip if no git changes + no commits in 8h; (2) 30-min cooldown lockfile. Calls `claude --print` to review the session and output CANDIDATES ONLY. "The hook proposes — you decide." Nothing written automatically. | Observational (proposes; never writes; never blocks) [CANON-DECLARES] |
| `.claude/hooks/enforce-scope.sh` | `PreToolUse` (matcher `Bash`) | Scope enforcement hook: hard-blocks any `git add`/`git commit` that stages a file not in the `## ALLOWED FILES` list of `.claude/TASK-TEMPLATE.md`. Compares `git diff --cached --name-only` against the list; any unlisted staged file → exit 2 with a blocking message offering Path A (discovered necessity → questions.md) / Path B (opportunistic → backlog + unstage). If no `## ALLOWED FILES` section: exits 0 and logs a warning ("scope enforcement disabled"). Does NOT intercept reads, grep, tsc, tests, or writes to `.claude/` files. | **STRUCTURAL (blocks `git add`/`commit`, exit 2)** [CANON-DECLARES] |
| `.claude/hooks/branch-registry-guard.sh` | `PreToolUse` (matcher `Bash`) | (Defined on 14 · Git Discipline.) Blocks `git add`/`git commit` when `.claude/active-branches.json` shows another session owns the current branch (`$CLAUDE_SESSION_ID` mismatch). Exit 2 with "STOP AND SURFACE: write a BLOCKING question to questions.md." "Wire alongside the existing `enforce-scope.sh` PreToolUse entry." | **STRUCTURAL (blocks `git add`/`commit`, exit 2)** [CANON-DECLARES] |
| `.claude/hooks/enforce-pnpm.sh` | `PreToolUse` (matcher `Bash`) | Example/illustrative hook ("use pnpm instead of npm") shown on 08 to demonstrate the deterministic-hook pattern. Exit 2 if command starts with `npm `. Presented as an example, not part of the canonical settings.json template. | **STRUCTURAL (blocks, exit 2)** — example only [CANON-DECLARES] |

> Note: the canonical `settings.json` template (page `359e2971...c277`) wires **exactly three** PreToolUse(Bash)
> hooks — `block-dangerous-git.sh`, `block-npm-install.sh`, `block-dangerous-bash.sh` — plus one `SessionStart`
> (`session-start.sh`) and one `Stop` (the sound). `enforce-scope.sh`, `branch-registry-guard.sh`, the
> `session-end.sh` memory hook, and `enforce-pnpm.sh` are described in prose on pages 08 and 14 but are NOT in the
> canonical settings.json template's `hooks` block. [CANON-DECLARES]

### 1b. Git hooks (`.husky/*`, `.githooks/*`)

| Hook (canon path) | Trigger | What it does | STRUCTURAL / observational |
|-------------------|---------|--------------|----------------------------|
| `.githooks/pre-commit` | git pre-commit | Runs `npx tsc --noEmit` + `npx vitest run` before every commit. Skips if `node_modules` missing. Vitest exit code 2 (no test files) treated as pass. **Main-branch protection:** on `main`/`master` with no TTY (`[ ! -t 0 ]`) → hard-block (exit 1, "agents must use a feature branch, not main"); human on main → warn + exit 0 (checks skipped). Tracked via `core.hooksPath .githooks`. | **STRUCTURAL (blocks commit, exit 1/nonzero)** [CANON-DECLARES] |
| `.husky/pre-push` | git pre-push | The review gate. Reads push refs from stdin; all-deletions push → exit 0. Three hard preconditions: `.env.local` must exist; branch's PR must not already be merged (`gh pr list --head <branch> --state merged`); branch must not be detached `HEAD`. Then TTY-branches on `[ -t 0 ]`: **interactive (human)** → prompts "Have you run /cr for this feature? [y/N]", abort on N; **non-interactive (agent)** → validates `.claude/.cr-ok` == `branch:sha` against current HEAD (missing/empty/stale → exit 1). Does NOT consume `.cr-ok`. After gates pass: `npm run test && npm run build` — blocks if either fails. | **STRUCTURAL (blocks push, exit 1)** [CANON-DECLARES] |
| `.husky/post-checkout` | git post-checkout | Auto-installs `node_modules` in fresh worktrees: runs `npm install` only when prev-HEAD (`$1`) is all-zeros (new worktree via `git worktree add`) AND `node_modules/` missing. | Observational (convenience; never blocks) [CANON-DECLARES] |

### 1c. Sync gate (added INTO `.husky/pre-push` by 14 · Git Discipline)

| Mechanism | Trigger | What it does | STRUCTURAL / observational |
|-----------|---------|--------------|----------------------------|
| Pre-push auto-rebase sync gate | git pre-push (block added "before the existing sentinel checks") | If branch is behind `origin/main` at push time AND safe (not `main`/`master`/`HEAD`, registered to this session), `git fetch` + `git rebase origin/main --quiet`. Success → re-emit preamble, continue. Conflict → `git rebase --abort` + exit 1 ("Auto-rebase failed — Push blocked"). | **STRUCTURAL (blocks push on conflict, exit 1)** [CANON-DECLARES] |

> **Discrepancy in canon itself:** 14 · Git Discipline says to add the sync-gate block to `.husky/pre-push`
> *before the existing sentinel checks*, but the canonical `.husky/pre-push` **template** (page `364e2971...36693`)
> does NOT include this sync-gate block. The two canonical pages describe different pre-push scripts. [CANON-DECLARES]

---

## 2. The declared settings.json model

Source: Template `settings.json` (`359e2971cd62811b8bece1616014c277`) + prose on 08. [CANON-DECLARES]

### 2a. Top-level shape
The canonical `settings.json` has four top-level keys: `permissions`, `env`, `hooks`, (and `statusLine` is set in
the **global** `~/.claude/settings.json`, not the project file). "This file must be valid JSON. No comments allowed."
— Claude Code silently fails to load the file if it contains `//` or `/* */` comments.

### 2b. `permissions.deny` (canonical template)
```
Edit(/.claude/hooks/**)
Write(/.claude/hooks/**)
Edit(/.claude/settings.json)
Write(/.claude/settings.json)
Edit(/.claude/settings.local.json)
Write(/.claude/settings.local.json)
Bash(rm -rf*)
```
Declared purpose: "locks the agent out of editing its own guardrails" so it "can't quietly weaken its own
enforcement." `deny` takes precedence over `allow`. [CANON-DECLARES]

**Path-anchoring rule (critical, stated twice):** "Permission path patterns are PROJECT-RELATIVE, not absolute."
A single leading `/` (e.g. `Edit(/.claude/hooks/**)`) anchors to the **project root**. `//path` is
filesystem-absolute; `~/path` is home. An absolute machine path like `Edit(/Users/me/repo/.claude/hooks/**)` is
"silently treated as project-relative, resolves to a nonexistent nested path, matches nothing, and the rule does
NOTHING — no error." After adding a deny, "verify it fires by attempting the denied edit once." [CANON-DECLARES]

### 2c. `permissions.allow` (canonical template)
```
Bash(git diff*) · Bash(git log*) · Bash(git status*)
Bash(git stash list*) · Bash(git stash show*) · Bash(git stash push*)
Bash(git stash pop*) · Bash(git stash apply*) · Bash(git stash drop*)
Bash(git branch*) · Bash(git show*) · Bash(git worktree list*)
Bash(git checkout -b *) · Bash(git worktree add *)
Bash(git add *) · Bash(git commit *) · Bash(git pull *)
Bash(npm run *) · Bash(npx tsc *) · Bash(npx vitest *) · Bash(npx wait-on *)
Read(//home/<user>/dev/**)
```
Note `Read` uses `//home/...` (double leading slash = genuinely absolute). The allowlist is "organized by category
(git introspection, git write, tooling, read access)" but JSON comments are stripped. [CANON-DECLARES]

### 2d. `permissions.additionalDirectories` (canonical template)
```
/tmp
```
08 prose elsewhere says: "Use parent directories in `additionalDirectories`, not specific worktree paths. When you
create a new worktree, it's automatically covered" and gives the example `["/home/<user>/dev", "/home/<user>/.claude"]`.
The actual template ships only `["/tmp"]`. [CANON-DECLARES]

### 2e. Baseline allowlist for overnight / AFK queue runs (08, separate from the template)
08 declares an extra allow set for overnight/AFK queue runs so sub-agents in worktrees don't stall on prompts:
`Bash(find *)`, `Bash(grep *)`, `Bash(ls *)`, `Bash(wc *)`, `Bash(command -v *)`, `Bash(git rev-parse *)`,
`Bash(git -C /path/to/repo/.claude/worktrees/* *)` (worktree glob — "never hardcode a specific agent ID"),
plus `Edit(/path/to/repo/**)` and `Write(/path/to/repo/**)`. Explicitly NOT pre-approved: `git push`, `git reset`,
`git clean`, `git rebase`, external API mutations, `rm`. [CANON-DECLARES]

### 2f. `env` block (canonical template)
```
CLAUDE_CODE_DISABLE_1M_CONTEXT = "1"      → don't load 1M-token context by default (cost)
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "80"    → auto-compact at 80% full
```
[CANON-DECLARES]

### 2g. `hooks` block (canonical template) — see §1a. SessionStart→session-start.sh; PreToolUse(Bash)→
block-dangerous-git.sh, block-npm-install.sh, block-dangerous-bash.sh; Stop→sound. All hook commands use
`$CLAUDE_PROJECT_DIR/.claude/hooks/...`. [CANON-DECLARES]

### 2h. The `.cr-ok` sentinel / gating mechanism
[CANON-DECLARES] The sentinel chain is the canon's one structural review gate:
- **Written** by `/cr` Step 7 after a clean full-branch review with no unresolved MUST-FIX items. Encodes `branch:sha`.
- **Validated** by `.husky/pre-push` on every agent push (NOT consumed there).
- **Validated AND consumed** by `scripts/pr.sh` — "the sole consumer" — exactly once, atomically, at PR creation.
- Any commit after `/cr` invalidates the sentinel (sha mismatch) → re-run `/cr`.
- `.claude/.cr-ok` (and `.claude/.cr-ok.consumed.*`) MUST be gitignored — "a local signal file … must never be committed."
- Historical: pre-v0.85 used a dual-sentinel system (`.cr-feature-ok` + `.cr-ok`); v0.85 retired `/cr-feature` and
  folded it into `/cr`; v0.95 "cleaned up the `scripts/pr.sh` template gap." [CANON-DECLARES]

### 2i. `permissions.defaultMode` and permission-mode reference
08 declares six permission modes (Claude Code 2026): `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`,
`bypassPermissions` — cycle with Shift+Tab. Set default in settings.json: `"permissions": { "defaultMode": "acceptEdits" }`.
Stage-3 recommended mode is `acceptEdits` + `block-dangerous-git.sh`. [CANON-DECLARES]

### 2j. autoMode concept (present)
[CANON-DECLARES] "Auto mode (research preview, March 2026)" replaces per-action confirmation prompts with a dedicated
**Sonnet 4.6 classifier** that evaluates every tool call before it runs.
- **Classifier BLOCKS:** mass file deletion, sensitive data exfiltration, force pushes to main, production deploys,
  downloading+executing arbitrary code (`curl | bash`), modifying shared infrastructure.
- **Classifier ALLOWS:** local file ops in working dir, declared dependency installs, read-only HTTP, pushing to the
  branch Claude created.
- "Meaningfully safer than `--dangerously-skip-permissions` because the classifier is active even when you aren't."
- Requires Team/Enterprise/API plan + Sonnet 4.6 or Opus 4.6. Enable: `claude --enable-auto-mode --permission-mode auto`.
- **Auto-mode interaction with allowlist:** entering auto mode DROPS any allow rule granting blanket shell access
  (`Bash(*)`), wildcarded interpreters (`Bash(python*)`), and package-manager run commands; narrow rules
  (`Bash(npm test)`) carry over; dropped rules restored on leaving auto mode. "Do not remove the
  [block-dangerous-git.sh] hook when enabling auto mode; they serve different threat models." [CANON-DECLARES]

### 2k. `.claudeignore` / `.agentignore`
[CANON-DECLARES] Canon declares a repo-root ignore file to keep credentials invisible to the agent. Claude Code
reads `.claudeignore`; other tools may use `.agentignore`. Canonical contents:
```
.env · .env.local · .env.development · .env.production · .env*.local
.env.development.local · .env.test.local · .env.production.local
*.pem · *.key · service-account.json
```
"Non-negotiable if the repo has Supabase keys, API tokens, or service accounts." Before enabling
`--dangerously-skip-permissions`: "verify credentials are in `.claudeignore`." [CANON-DECLARES]

---

## 3. STRUCTURAL (deterministically blocks) vs ADVISORY — and the three-layer model

### 3a. Does the canon have a named "three-layer enforcement model"?
**No single page names a numbered "three-layer enforcement model" as such.** The closest canon constructs:

1. **Hooks-vs-CLAUDE.md dichotomy (08, "Deterministic hooks vs CLAUDE.md instructions").** [CANON-DECLARES]
   Reproduced: "Putting behavioral rules in CLAUDE.md has two problems. First, it wastes instruction budget…
   Second, it's probabilistic, not deterministic. Adding 'don't use git push' to CLAUDE.md reduces the chance of
   an unwanted push. It doesn't prevent it. PreToolUse hooks are deterministic. If the hook exits with code 2, the
   action is blocked… The wrong command becomes impossible to run, not just unlikely." Source cited: aihero.dev
   (Pocock). The page gives a routing table (Rule type → Hook vs CLAUDE.md):
   - Hook (deterministic): use pnpm instead of npm; don't run git push; block specific commands entirely.
   - CLAUDE.md (requires judgment): architecture decisions; layer boundary rules; safe-change files.

2. **The "safety net" stack (08, "The philosophy").** [CANON-DECLARES] Reproduced verbatim:
   "The safety net is not the permission prompt — it's git (everything is revertable), tests (catches mistakes),
   and the review pipeline (catches what tests don't)." This is the canon's three-part safety model (git / tests /
   review pipeline), but it is framed as a *safety net*, not an *enforcement* model.

3. **Auto-mode + hook additivity (08).** [CANON-DECLARES] "The hook and the classifier are additive — deterministic
   blocks for git destructive ops, classifier coverage for everything else." Two threat models, both retained.

4. **08 opening doctrine (LangChain "Anatomy of an Agent Harness").** [CANON-DECLARES] "why hooks are deterministic
   (enforcement the model can't override)" — the canon's explicit thesis that hooks are the layer the model
   *cannot* override, contrasted with CLAUDE.md/skills/memory which are model-honored.

### 3b. What the canon explicitly declares STRUCTURAL (deterministic, exit-2/exit-1 blocks)
[CANON-DECLARES]
- `block-dangerous-git.sh` (PreToolUse exit 2) — destructive git ops.
- `block-npm-install.sh` (PreToolUse exit 2) — dependency adds.
- `block-dangerous-bash.sh` (PreToolUse exit 2) — deploys, recursive deletes, boundary writes.
- `enforce-scope.sh` (PreToolUse exit 2) — out-of-scope `git add`/`commit`.
- `branch-registry-guard.sh` (PreToolUse exit 2) — cross-session branch collision.
- `.githooks/pre-commit` (exit 1) — tsc/vitest gate + main-branch block for agents.
- `.husky/pre-push` (exit 1) — `.cr-ok` sentinel / human prompt + test/build gate + merged-PR / detached-HEAD / `.env.local` preconditions.
- pre-push sync gate (exit 1 on conflict) — auto-rebase staleness gate.
- `.cr-ok` sentinel chain — gates PR creation via `scripts/pr.sh`.
- `permissions.deny` block — locks hook/settings files (deterministic, deny > allow).
- Auto-mode classifier — blocks the named destructive classes (Stage 4; probabilistic-but-active).
- Repo platform: branch protection (require PR, require CI status check, require up-to-date branch, no bypass) +
  CI pipeline — "protect the branch for everyone … including anyone who runs `git push --no-verify`." [CANON-DECLARES]

### 3c. What the canon explicitly declares ADVISORY (model must honor; not deterministic)
[CANON-DECLARES]
- All of `CLAUDE.md` behavioral rules ("probabilistic, not deterministic").
- `SOUL.md` (engineering values) and global `~/.claude/CLAUDE.md` (behavior prefs) — "both travel to every session"
  but are model-honored prose.
- The Git Status Preamble (14) — "part of the agent's response," emitted by the model, not enforced by a hook.
- The 60% context rule / `/handoff` discipline — "the agent monitors its own context usage" — advisory.
- MCP quarantine + allowlist rules — placed in `AGENTS.md`, model-honored prose.
- `session-end.sh` memory proposals — "the hook proposes — you decide"; never writes, never blocks.
- The one-session-per-branch invariant is enforced by `branch-registry-guard.sh` (structural) BUT the registry
  itself (`active-branches.json`) and the claim/release lifecycle depend on the agent writing entries — advisory
  bookkeeping behind a structural guard. [CANON-DECLARES]

---

## 4. Page 09 · Global Config — what the canon says belongs in `~/.claude`

Source: 09 · Global Config + Template "Global config" (`~/.claude/CLAUDE.md`). [CANON-DECLARES]

### 4a. What the global config file IS
- Claude Code global config location: **`~/.claude/CLAUDE.md`** — "loaded at session start across all projects."
  (08 also references this under "Global personal config (cross-tool)".) [CANON-DECLARES]
- The statusline is also global: `~/.claude/statusline.sh` wired in **`~/.claude/settings.json`** under `statusLine`
  (`{"statusLine": {"type":"command","command":"bash ~/.claude/statusline.sh"}}`). The context-percentage
  `ccstatusline` variant is wired the same way in `~/.claude/settings.json`. [CANON-DECLARES]

### 4b. SOUL.md vs global CLAUDE.md (the split)
[CANON-DECLARES] Quoted: "SOUL.md (`.claude/SOUL.md` in each project repo) carries engineering values — what the
agent stands for, what it never compromises on. Global CLAUDE.md carries personal behavior preferences — how direct
to be, when to push back, verification habits, scope discipline. Both travel to every session. SOUL.md answers
'what does this agent value?'; global CLAUDE.md answers 'how does this agent work with me?'"
Note: SOUL.md lives **per-project** (`.claude/SOUL.md`), NOT in `~/.claude`. [CANON-DECLARES]

### 4c. Global config vs repo-level split table (09)
[CANON-DECLARES] Global config holds: how direct to be · when to push back · how to handle mistakes · teaching
preferences · verification expectations · scope discipline. Repo-level (CLAUDE.md) holds: coding conventions ·
NEVER rules · architecture rules · pipeline workflow · commit format · safe-change rules.

### 4d. The three non-negotiables for any global config (09)
[CANON-DECLARES] Regardless of personal style, every global config should contain:
1. Hold scope — name new paths as out-of-scope rather than absorbing them.
2. When something can be verified by running code, run it.
3. Prefer the boring, obvious solution. Cleverness is a liability.

### 4e. The canonical global `~/.claude/CLAUDE.md` template content
[CANON-DECLARES] The template (page `359e2971...33c9`) ships these sections:
- **How I work** — be direct / accuracy over comfort; double-check assumptions; hold scope ("Activity is not
  compounding progress"); stop spinning on unknowns; ask one clarifying question; execute decisions / don't
  re-litigate; keep diffs scoped (no drive-by reformats); investigate root cause on failure; prefer boring solution;
  research options rather than naming what can't be done.
- **Before committing AI-generated code** — the 3-question supervision checkpoint (what does this do & why / where
  could it fail / what would you change).
- **On mistakes** — own it, no excessive apology; note what failed and why; flag patterns for `memory.md`.
- **On verification** — run code / read docs to verify; "Don't report done without verifying"; investigate before retrying.
- **Teaching** — brief 💡 explanations of non-obvious concepts; don't over-teach.
- **Guides** — read repo-level CLAUDE.md + AGENTS.md first; "this file only governs behavior."

### 4f. Other canon-declared global-config constructs (09)
[CANON-DECLARES]
- **Two-bucket memory model (Yan):** Project docs = facts (CONTEXT.md/AGENTS.md/docs, in repos); Global config =
  preferences (workflows/taste/behavior, in home dir). "The former provides context; the latter provides configuration."
- **Lazy-loaded guides:** when global config gets long, break into named guides loaded on demand (e.g.
  `[path]/guides/writing.md`, `dashboards.md`) — referenced by name, not inlined, to preserve context budget.
- **Cross-project INDEX.md (optional):** a global index at the tool's config location for resources spanning repos
  (design references, infrastructure dashboards), with per-project INDEX.md for repo-specific resources.

> **What the canon does NOT declare for `~/.claude`:** the canon does NOT place global *agents*, global *skills*, or
> a global *settings.json permissions/hooks* block in `~/.claude` beyond `statusLine`. Global `~/.claude` per canon =
> `CLAUDE.md` (behavior prefs) + `settings.json` (statusLine only, + the documented `env`/permission examples) +
> `statusline.sh` + optional guides/ + optional cross-project INDEX.md. Agents, skills, hooks, and the
> permissions/deny/allow model are all declared at the **project** (`.claude/`) level. [CANON-DECLARES]

---

## 5. Page 14 · Git Discipline — the mechanisms

Source: 14 · Git Discipline (`367e2971cd62815fa056cda8f4238aee`). [CANON-DECLARES]

### 5a. Page framing — four failure modes it targets
[CANON-DECLARES] "Prevention hooks live in 08. This page is the workflow and the recovery doctrine."
- **Disorientation** — agent doesn't know branch/worktree/sync → fixed by the Git Status Preamble.
- **Collision** — two sessions on one branch → fixed by one-session-per-branch + the registry.
- **Drift** — branch falls behind main → fixed by sync checkpoints + pre-push staleness gate.
- **Tangle** — sessions commingle / commit on main / detached HEAD → fixed by the Recovery Runbook.

### 5b. The Git Status Preamble (mechanism)
[CANON-DECLARES] The agent MUST emit a git status block **before any git-touching action** (`git checkout`, `add`,
`commit`, `rebase`, `merge`, `push`, worktree ops) and **once at session start**. "It is part of the agent's
response — not a terminal status line." Distinguished explicitly from the 08 statusline (08 serves the human watching
a terminal; the preamble serves anyone reading the transcript / the next agent inheriting a handoff).

Format:
```
git: <branch> · worktree: <worktree-name or "primary checkout">
sync: <up to date with origin/main | N behind | N ahead | N behind N ahead>
state: <clean | N staged, N modified, N untracked>
last: <short-sha> "<commit subject>"
```
**⚠ warning triggers — emit before any action when any are true:** on `main`/`master`; behind `origin/main` by any
commits; detached HEAD; branch differs from `.claude/active-branches.json` registration for this session. **On a ⚠:**
stop the planned action, surface the warning, wait for human go-ahead or follow the Recovery Runbook. "Never silently
continue through a warning." (Note: the preamble is **model-emitted / advisory** — there is no hook that enforces its
emission; the structural backstop is `branch-registry-guard.sh` for the registration-mismatch case.) [CANON-DECLARES]

### 5c. One-session-per-branch invariant + branch registry
[CANON-DECLARES]
- **Invariant:** one active session per branch at a time. "No git mechanism prevents it. The branch registry closes it."
- **Registry file:** `.claude/active-branches.json` — **gitignored, never committed.** Maps branch → `{worktree,
  session_id, claimed_at}`.
- **Lifecycle:** Claim (on `git checkout -b feat/<slug>` → write entry) · Verify (before every `git add`/`commit` →
  check this session owns the branch) · Release (after merge + worktree removal → delete entry) · Stale check
  (session start, `claimed_at` > 24h with no recent commit → flag to human, **do not auto-release**).
- **Claim check** (before `git checkout -b`): bash snippet reading the registry with `jq`, exits 2 if the branch is
  claimed by another `session_id` (offers: open that session's worktree, or pick a different slug).
- **Commit guard hook:** `.claude/hooks/branch-registry-guard.sh` (PreToolUse Bash) — see §1a. Uses
  `${CLAUDE_SESSION_ID:-unknown}`. Wire alongside `enforce-scope.sh`; add `active-branches.json` to `.gitignore`.

### 5d. Sync discipline — three checkpoints
[CANON-DECLARES]
- **Checkpoint 1 — branch creation:** always branch from fresh `origin/main`. `git checkout -b feat/<slug>` expands to
  `git fetch origin` + `git checkout origin/main -b feat/<slug>`. "Drift cannot accumulate before the first commit."
- **Checkpoint 2 — pre-`/cr`:** before `/cr`, `git fetch origin`; if `git rev-list --count HEAD..origin/main` > 0 →
  `git rebase origin/main`. Conflicts → stop, surface, do not run `/cr` until resolved. "`/cr` reviews the post-rebase
  state — never a stale branch."
- **Checkpoint 3 — pre-push auto-rebase gate:** the `.husky/pre-push` sync block (see §1c). Safe conditions (all
  required): not `main`/`master`, not detached HEAD, branch registered to this session. Success → re-emit preamble +
  continue; conflict → `git rebase --abort` + block; unsafe → block without rebasing, surface which condition failed.

### 5e. Rebase-vs-merge policy (table)
[CANON-DECLARES]
- Staying current — un-pushed single-session branch → `git rebase origin/main` (linear history; safe when private).
- Staying current — pushed branch another session touched → `git merge origin/main` ("Rebase rewrites shared history — never do this").
- Integrating finished branch into main → PR merge via GitHub/GitLab.
- Applying one commit to another branch → `git cherry-pick <sha>`.
- **Hard rule:** "never `git rebase` a branch that has been pushed and that another session or person may have pulled.
  If in doubt, `git merge`." The auto-rebase gate only fires on branches registered to the current session — the safe case.

### 5f. Recovery Runbook (four named procedures)
[CANON-DECLARES] "The agent follows these exactly — does not improvise, does not extend scope, does not merge or push
until the procedure is complete and the preamble shows clean. Each procedure ends by re-emitting the Git Status
Preamble; a clean preamble is the exit condition."
- **RR-1 — Committed to `main` by mistake:** identify commits (`git log origin/main..HEAD`) → `git checkout -b
  feat/<slug>` (rescue) → `git checkout main` + `git reset --hard origin/main` → verify on rescue branch → register →
  emit preamble. "Do not push `main` after the reset. The reset is local only."
- **RR-2 — Two sessions wrote to one branch (split by cherry-pick):** map commits → create Task B branch from
  `origin/main` → cherry-pick Task B commits → return to Task A branch → **CONFIRM WITH HUMAN before** `git rebase -i
  origin/main` to drop Task B commits ("interactive rebase rewrites history and requires explicit same-turn approval")
  → verify each branch → register both → emit preamble.
- **RR-3 — Detached HEAD:** check for commits → if none, `git checkout feat/<slug>`; if commits made while detached,
  `git checkout -b rescue/<sha>` then cherry-pick onto the correct branch; if commits lost, `git reflog` to find the
  SHA → rescue → emit preamble.
- **RR-4 — Branch behind main with conflicts (auto-rebase failed):** understand conflict (`git log HEAD..origin/main`,
  `git diff HEAD...origin/main`) → rebase + resolve one commit at a time → if unmanageable, `git rebase --abort` +
  `git merge origin/main` ("always safe; produces a merge commit") → run tests → emit preamble. **Abort-and-merge
  when:** > 3 conflict rounds; conflict involves a schema migration; any conflicting file is outside the task's
  `allowed-files`. Surface to human before switching strategies.

### 5g. Parallel worktree merge-time integration
[CANON-DECLARES] "merge worktrees only after both are green." Integrate in dependency order (foundational/feeding
slice first; if truly independent, simplest first). Procedure: sync main → integrate slice A (rebase onto origin/main,
test green, PR + merge) → integrate slice B against post-merge main (rebase — "conflicts surface here" — test green,
PR + merge) → if conflict resolution changes behavior, re-run `/cr-feature` on the affected slice → remove all
worktrees + `git branch -d` + delete registry entries after merge. Includes a rationalization-rebuttal table
("Independent green does not mean combined green"; conflict resolution that touches behavior needs review; "Stale
worktrees are invisible drift").

### 5h. What 14 says to add to CLAUDE.md (session-start block) and the per-project file checklist
[CANON-DECLARES] 14 prescribes a `## Git discipline` block for `CLAUDE.md` session-start (emit preamble, stop-and-
surface ⚠ rules, registry claim check, confirm-before-history-rewrite, "Run `git branch --show-current` before every
`git add`/`commit`. If on main: stop."). Per-project file checklist: create `.claude/active-branches.json` = `{}`
(gitignore it); copy `.claude/hooks/branch-registry-guard.sh` (`chmod +x`); add sync gate to `.husky/pre-push`; add
git-discipline block to `CLAUDE.md`; add `active-branches.json` line to `.gitignore`.

---

## 6. Setup Prompts — the three prompts

Source: Setup Prompts (`359e2971cd6281dd9f21d1af5e4d0b30`). [CANON-DECLARES]
"Three prompts to run when setting up a new project. Run them in order." Work with any AI coding tool; substitute
`.claude/` for the tool's config dir.

| Prompt | Name | What it does |
|--------|------|--------------|
| **Prompt 1** | Project context intake | Run first in a fresh session at repo root. **Step 0:** confirm branch (`git branch --show-current`) — if on `main`/`master`, stop and tell the human to create a feature branch ("Context summaries reflect branch state at session start and may not match the actual current branch — always verify directly"). Reads template files, then interviews the human **one question at a time** (12 numbered questions: what is this / what it replaces / tech stack + which AI tool / hard rules / domain failure modes / data flow / routes + auth / external repos / tools+integrations / open decisions / out of scope / safe-change files). Shows a plan, gets approval, then writes project-specific files (CLAUDE.md, AGENTS.md, CONTEXT.md skeleton, PITFALLS.md empty, agent-contract.md, INDEX.md, AI-WORKFLOW.md, cr/cr-security SKILL.md domain passes) — each shown before writing. Lists "do not write" copy-paste-ready files. For settings/permissions: "tell me the correct paths to use and I will edit it manually." |
| **Prompt 2** | Existing codebase review | Run on an existing project to audit the AI-coding setup and identify gaps. Reads every existing setup file + the tool config dir + skills dir. Evaluates each file (has all template sections / empty-that-should-be-populated / contradictions / specific-enough). Runs the **one-shot readiness checklist** (5 items: Boundaries clear · Patterns generalized · Context sufficient · Skills exist · Tech debt not in the way). Produces a report (One-shot readiness: N/5 · Files reviewed · Files missing · Priority fixes · Questions). "Do not write or modify any files yet." |
| **Prompt 3** | Post-write validation | Run after Prompt 1 to verify internal consistency. Reads all setup files; checks 8 issue classes: contradictions · missing cross-references · stack consistency (same names for same concepts) · skills completeness (feature skill invokes existing skills; review skill references PITFALLS/AGENTS/CONTEXT) · pipeline tier consistency (CLAUDE.md table matches skill files) · NEVER-list coverage · agent-contract STOP AND SURFACE references real files · tool-config paths match repo name + worktree naming. Produces a validation report (Contradictions / Missing cross-refs / Inconsistencies / Recommended fixes / Ready to use). "Do not fix anything yet." |

**When-to-run table (canon):** new project → Prompt 1; existing project audit → Prompt 2; after Prompt 1 → Prompt 3;
after a major refactor/stack change → Prompt 2 then 3; "something feels inconsistent" → Prompt 3 alone. [CANON-DECLARES]

**Setup Prompts caveat (enforcement-relevant):** Prompt 1 says to fetch and enumerate the Templates index
(`359e2971cd62819e9142c30b99fecb6c`) as "the authoritative checklist" because "the lists below are not exhaustive —
new templates are added with each version." [CANON-DECLARES]

---

## 7. Version markers / contradictions / draft notes

[CANON-DECLARES]
- **v0.85** — `/cr-feature` retired and folded into `/cr`; the standalone `.cr-feature-ok` sentinel retired, leaving the
  single `.cr-ok` sentinel. (08, .husky/pre-push template, Templates index.)
- **v0.95** — "cleaned up the `scripts/pr.sh` template gap." (.husky/pre-push template, Historical note.)
- **v0.19** — "Ten committed specialist agent templates" build-order note. (Templates index.)
- **Research-preview markers:** Auto mode = "research preview, March 2026"; Anthropic **Dreaming** = "research preview
  as of May 2026" (08 notes Dreaming is the official version of the session-end memory hook pattern and to evaluate
  replacing the hook with it when GA). (08.)
- **`CLAUDE_PROJECT_DIR` contradiction:** the `.husky/pre-push` design note says "`CLAUDE_PROJECT_DIR` is not used — it
  is not guaranteed to be set by Anthropic," yet the **settings.json template** wires all hook commands as
  `$CLAUDE_PROJECT_DIR/.claude/hooks/...` AND the `session-end.sh` script uses `PROJ="${CLAUDE_PROJECT_DIR:-.}"`. So
  the canon both disavows and relies on `CLAUDE_PROJECT_DIR`. [CANON-DECLARES]
- **Pre-push sync-gate contradiction:** 14 · Git Discipline instructs adding the auto-rebase sync gate to
  `.husky/pre-push` "before the existing sentinel checks," but the canonical `.husky/pre-push` template does not
  contain that block — the two canon pages describe divergent pre-push scripts. [CANON-DECLARES]
- **additionalDirectories contradiction:** 08 prose recommends parent dirs `["/home/<user>/dev", "/home/<user>/.claude"]`;
  the shipped settings.json template has only `["/tmp"]`. [CANON-DECLARES]
- **TTY-detection convention (resolved in canon):** both `.husky/pre-push` and `.githooks/pre-commit` templates
  explicitly use `[ -t 0 ]` (stdin-is-a-terminal) and explicitly reject `[ -c /dev/tty ]` / `[ ! -c /dev/tty ]` as
  "tests file existence and is unreliable." But 08's inline pre-commit example STILL uses the rejected
  `[ ! -c /dev/tty ]` form — the 08 prose example is stale relative to the template. [CANON-DECLARES]
- **`/cr-feature` ghost references:** the `.husky/pre-push` "Historical note" and the worktree-integration section of
  14 still reference `/cr-feature` (retired v0.85) — 14 says "re-run `/cr-feature` on the affected slice." Stale
  relative to the v0.85 retirement. [CANON-DECLARES]
- **Templates index duplication:** `agents/task-runner.md` is listed twice and `agents/reviewer.md` appears as both a
  v0.19 entry and a later page link — index has duplicate/superseded entries. [CANON-DECLARES]

---

## Notable

**A. Where the canon's own declared enforcement is itself only ADVISORY (markdown the model must honor, no deterministic backstop):**
- The **Git Status Preamble** (14) is the centerpiece of git discipline but is **model-emitted prose** — no hook
  enforces that the agent emits it or that it stops on a ⚠. The only structural backstop is `branch-registry-guard.sh`
  (registration-mismatch case) and the pre-commit main-branch block. Disorientation prevention is otherwise advisory.
- The **one-session-per-branch lifecycle** (Claim/Verify/Release/Stale-check) is advisory bookkeeping the agent must
  perform by hand; only the *commit-time collision* is structurally caught by `branch-registry-guard.sh`. Claim,
  release, and stale-flagging have no hook.
- **Sync Checkpoints 1 & 2** (branch-from-fresh-main; pre-`/cr` rebase) are advisory model steps; only Checkpoint 3
  (pre-push) is structural — and that structural block is missing from the shipped pre-push template (§7).
- The **60% context rule / proactive `/handoff`** (08) is declared "not optional behavior" but is entirely
  model-self-monitored; the only mechanical aid is the ambient statusline + `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80`.
- The **MCP quarantine + allowlist** rules (08) are markdown placed in `AGENTS.md` — model-honored, no enforcement.
- The **discipline checkpoint** (3 questions before committing AI code) in both global config and 08 is a model-honored
  prompt, not a gate.
- `session-end.sh` is structurally wired but explicitly **proposes only / never writes / never blocks** — observational.
- The canon's "three-layer" framing is itself only the *safety net* triad (git / tests / review pipeline) and the
  hook-vs-CLAUDE.md dichotomy — it never names a numbered enforcement-layer model; the structural floor is just the
  PreToolUse Bash guards + the two git hooks + the `.cr-ok` sentinel + `permissions.deny`. This matches the disk
  finding that enforcement is "overwhelmingly advisory."

**B. Where the canon names hooks/scripts that DIFFER from disk names:**

Disk inventory given: hooks `block-dangerous-git.sh`, `block-npm-install.sh`, `permission-logger.sh`,
`session-start.sh`, `worktree-create.sh`; husky `pre-commit`/`pre-push`/`post-checkout`; scripts `pr.sh`,
`worktree-add.sh`, `gc.sh`, `gen-local-env.sh`, `test-local.sh`, `seed.ts`.

| Canon names | Disk has | Match status |
|-------------|----------|--------------|
| `block-dangerous-git.sh` | `block-dangerous-git.sh` | ✅ same name |
| `block-npm-install.sh` | `block-npm-install.sh` | ✅ same name |
| `block-dangerous-bash.sh` (3rd PreToolUse guard, in settings.json template) | — (not in disk list) | ⚠ canon-only: canon's 3rd structural Bash guard appears absent on disk |
| `session-start.sh` (SessionStart hook) | `session-start.sh` | ✅ same name (canon gives no body) |
| `session-end.sh` (Stop memory hook) | — | ⚠ canon-only: disk has no session-end.sh in the given list |
| `enforce-scope.sh` (PreToolUse scope guard) | — | ⚠ canon-only (prose, not in settings.json template either) |
| `branch-registry-guard.sh` (PreToolUse collision guard) | — | ⚠ canon-only (14 · Git Discipline) |
| `enforce-pnpm.sh` (example) | — | example only; not expected on disk |
| `.husky/pre-commit` | `.husky pre-commit` | ✅ name matches — but canon's CANONICAL pre-commit is `.githooks/pre-commit` via `core.hooksPath .githooks`, NOT husky. ⚠ location divergence: canon pre-commit = `.githooks/`, disk pre-commit = `.husky/` |
| `.husky/pre-push` | `.husky pre-push` | ✅ same |
| `.husky/post-checkout` | `.husky post-checkout` | ✅ same |
| `scripts/pr.sh` | `scripts/pr.sh` | ✅ same |
| (canon: worktrees created via `git worktree add` / `claude --worktree`; no named `worktree-create.sh` script) | `worktree-create.sh` | ⚠ disk-only: disk has `worktree-create.sh`; the project CLAUDE.md references `scripts/worktree-add.sh` (also disk-only, not in canon templates) |
| — | `permission-logger.sh` | ⚠ disk-only: no `permission-logger.sh` anywhere in canon (no logging hook declared) |
| — | `scripts/worktree-add.sh`, `scripts/gc.sh`, `scripts/gen-local-env.sh`, `scripts/test-local.sh`, `scripts/seed.ts` | ⚠ disk-only: none of these appear as canon template pages (canon's only script template is `scripts/pr.sh`) |

**Net:** the canon declares **three** PreToolUse Bash guards in its settings.json template (`block-dangerous-git.sh`,
`block-npm-install.sh`, `block-dangerous-bash.sh`); disk has only the first two named, plus a `permission-logger.sh`
the canon never mentions. The canon's structural pre-commit lives at `.githooks/pre-commit` (core.hooksPath); disk's
lives at `.husky/pre-commit`. The canon's `session-end.sh`, `enforce-scope.sh`, and `branch-registry-guard.sh`
structural hooks have no disk counterpart in the provided list; the disk's `worktree-create.sh` /
`worktree-add.sh` / `gc.sh` / `gen-local-env.sh` / `test-local.sh` / `seed.ts` have no canon template counterpart.
