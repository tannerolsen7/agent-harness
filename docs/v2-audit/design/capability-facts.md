# Claude Code capability facts (Phase 2b) — load-bearing design constraints

Verified via claude-code-guide (official docs) + on-disk checks, 2026-06-11. These constrain what
MOVES 1–6 can actually do. Confidence tagged; "verify empirically" where the guide was uncertain.

## Hooks — what's actually possible (MOVE 1, MOVE 2)
- **PreToolUse blocks by exit 2** (or `permissionDecision:deny`) — confirmed; this is how our existing
  `block-dangerous-git/npm` guards work. The absent `block-dangerous-bash.sh` is therefore buildable
  exactly like the existing two. ✅ high confidence.
- **Stop / SubagentStop hooks CAN run shell commands and CAN block** (exit 2 / `decision:block` /
  `continue:false`). `Stop` = main agent finishes a turn; `SubagentStop` = a subagent returns to parent.
  → A Stop/SubagentStop hook **can run the test suite / typecheck and block on red, feeding the reason
  back** — this is MOVE 1's verification-gate payload. ⚠️ The guide was *internally hedged* on whether
  "block" forces the model to keep working vs. just erroring; the Claude Code docs say `decision:block`
  returns the reason to the model and prevents stopping. **Verify empirically before relying on
  force-continue semantics.**
- **No hook can REQUIRE an artifact (screenshot) to exist before completion.** → MOVE 1's render-gate
  payload is weaker than the verification payload: a Stop hook can *check an artifact exists* only if the
  agent was already instructed to produce one; it cannot *compel* production. Scope render-gating as
  "verify-if-present + advisory," not a hard gate. ✅
- **PostToolUse** can inspect a tool result and inject feedback / `continue:false`, but cannot rewind a
  tool to retry it. → errors-into-context (restored C2-G13) fits PostToolUse; the circuit-breaker/retry-
  ceiling is a counter the hook maintains, not a tool-rewind. ✅
- **Skills can carry their OWN `hooks:` and `paths:` frontmatter** (skill-scoped hooks + glob-gated
  auto-activation). Big for MOVE 2/3: a skill can ship a scoped hook and only activate on matching paths.

## Skill frontmatter schema (exact — MOVE 2, MOVE 3)
Supported fields: `name`, `description` (+`when_to_use`, **combined cap 1,536 chars**), `argument-hint`,
`arguments`, **`disable-model-invocation`** (true ⇒ user-only, removed from context), **`user-invocable`**
(false ⇒ Claude-only), **`allowed-tools`**, **`disallowed-tools`**, `model`, `effort`, **`context: fork`**
(+`agent:`), **`hooks`**, **`paths`** (glob auto-activation), `shell`. Hyphenated, no underscores.
→ The invocation-control gap (C3-G6, 0/26 skills use these) is real and the field names are confirmed.
The fix for reversible side-effect skills = `disable-model-invocation` is a real, cheap lever. ✅

## Settings precedence (MOVE 2, MOVE 5)
Highest→lowest: **Managed** (`/Library/Application Support/ClaudeCode/managed-settings.json` on macOS;
`/etc/claude-code/managed-settings.json` Linux) > CLI args > **local** (`.claude/settings.local.json`,
gitignored) > **project** (`.claude/settings.json`) > **user** (`~/.claude/settings.json`).
- **Managed settings genuinely override everything and are agent-unreachable** → the deterministic policy
  floor BOTH canon and disk lack. On THIS machine `/etc/claude-code` / the macOS managed path is absent
  (verified) — so it's an *available but unused* lever. High-value, low-cost for the safety floor.
- **autoMode is NOT read from committed project `.claude/settings.json` by design** (docs: "Not read from
  shared project settings"). On disk the autoMode block IS in `.claude/settings.json:6-32` (added #99) —
  so it is being *ignored at runtime*; unattended runs use bare defaults. **MOVE 2 citation re-grounded:
  the gap is "autoMode in the file the classifier ignores," not "autoMode absent."** `settings.local.json`
  honors the same keys → the correct home is local (personal) or managed (enforced), never committed project.

## Context / file limits (MOVE 3)
- **CLAUDE.md target < 200 lines** (not a hard cap; longer reduces adherence). Our root is 325 (CLAUDE) +
  474 (AGENTS) = 799 → over target, but the §9/commands-vs-skills correction stands: tier by
  *trigger-existence*, not blind line-count; keep no-trigger safety content tier-1.
- **`.claude/rules/` with `paths` globs = native path-scoped lazy-loading** of rules (load only when
  working on matching file types). This is the native mechanism for MOVE 3's tiering — we don't invent it.
- MEMORY.md auto-memory: first **200 lines / 25KB** loaded at session start; beyond requires explicit read.

## Plugins & distribution (MOVE 5 — directly answers Tanner's npx/plugin note)
- **A Claude Code PLUGIN can ship: hooks (`hooks/hooks.json`), skills (`skills/`), agents (`agents/`),
  MCP servers (`.mcp.json`), LSP, background monitors, and a settings.json LIMITED to `agent` +
  `subagentStatusLine` keys** (i.e. a plugin can deliver the behavioral harness but NOT a permissions/
  full-settings block — permissions stay project/user/managed).
- **Plugin marketplace = the native distribution + UPDATE channel:** a `.claude-plugin/marketplace.json`
  descriptor hosted on a git repo; users `/plugin marketplace add <git-url>` then `/plugin install
  <name>`; supports **version pinning + release channels + `/plugin update`**. Install sources: git, npm,
  local path.
- **GitHub template repo (the canon's locked v1 choice) is NOT a plugin channel** — it's clone + manual
  copy, ships no install/update mechanism, and can't cleanly deliver hooks or pull updates.
- **Implication:** the plugin+marketplace route is the native answer to BOTH Phase-4 distribution AND the
  Phase-4/5 "pull updates down" path (which the template plan explicitly defers). It ships hooks/skills/
  agents reliably and is version-pinned/updatable. The template repo is simpler but manual and update-less.
  → This REVISES the canon's locked "template repo, no npx, no plugin" decision (dated 2026-05-18, predates
  plugin-marketplace maturity). **Becomes a decision-brief fork** (see MASTER-FINDINGS §H).

## On-disk confirmations (gate + this session)
- `block-dangerous-bash.sh`, `enforce-scope.sh`, `branch-registry-guard.sh`, `session-end.sh` — ABSENT ✅
- `dependency-cruiser` — not a dependency (MOVE 2 L2 needs it added) ✅
- `.claude/.cr-ok` is gitignored (`.gitignore:58`) — confirms it never reaches CI (Node 8.5c) ✅
- autoMode block present in `.claude/settings.json` (ignored at runtime per above) ✅
