# The safety floor (Phase 0 locks)

The locks are the **sole** safety net (R4-D8: assume no practice DB anywhere). They are
deterministic, fail-closed, and — where it matters — placed where the agent cannot reach
or disable them. This page is the inventory + the human-placement handoff.

## The hooks (PreToolUse(Bash), in order)

| Hook | Blocks | Test |
|------|--------|------|
| `block-dangerous-bash.sh` | rm -rf, writes into `.git`/`.husky`/`.claude`/`.env*`, destructive SQL, destructive migrations, deploys/publishes, `curl\|sh`, cloud delete, disk format, fork bomb | `tests/block-dangerous-bash.test.sh` (62) |
| `block-credential-read.sh` | reading/exfiltrating credential files (`.env*`, `*.pem/*.key`, ssh/aws creds, `.npmrc`, `*.tfvars`, `secrets.*`, …) via cat/grep/cp/source/… | `tests/block-credential-read.test.sh` (35) |
| `block-egress.sh` | external data-send (curl/wget POST/PUT/`--data`/`-F`/`-T`, `gh api` mutations) to non-localhost; allows GET + localhost | `tests/block-egress.test.sh` (24) |
| `block-dangerous-git.sh` | force-push, push to protected branches, reset --hard, rebase, clean, branch -D, worktree-remove outside `.claude/worktrees/` | (covered by `hooks-fail-closed`) |
| `block-npm-install.sh` | npm install/add of a new dependency (deps added by hand after review) | (covered by `hooks-fail-closed`) |

All five **fail closed** when `jq` is missing (`tests/hooks-fail-closed.test.sh`). Over-blocking
is the intended failure mode — a false block is cheap; an escaped destructive op is not.

## Wiring (human-applied — guard files; the agent must not edit these)

The hooks are inert until referenced in `.claude/settings.json`. The `PreToolUse` →
`"matcher": "Bash"` array should list all five:

```json
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-dangerous-git.sh" },
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-npm-install.sh" },
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-dangerous-bash.sh" },
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-credential-read.sh" },
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-egress.sh" }
```

And `permissions.deny` must include `Read(/.env*)` alongside the existing guard-file denies.

## P0-4 — managed-settings.json (OS-level, the unbypassable floor)

Project `settings.json` lives in the repo, so it can be checked out at an old commit, and its
hooks can be `chmod -x`'d. The OS-level managed settings re-assert the critical **permission
denies** — which Claude Code enforces directly (not via a repo script) — at a path the agent
cannot reach or edit. The deny on `Edit/Write(.claude/hooks/**)` means the agent also cannot
modify the hook scripts to weaken them.

**Place it (macOS, requires admin):**
```bash
sudo mkdir -p "/Library/Application Support/ClaudeCode"
sudo cp docs/security/managed-settings.template.json "/Library/Application Support/ClaudeCode/managed-settings.json"
# remove the "_comment" key in the placed copy if your version rejects unknown keys
```
(Linux: `/etc/claude-code/managed-settings.json`. Confirm the path for your install.)

**Verify:** start a new session, ask the agent to `Write` to `.claude/settings.json` — it must
be denied even though the project settings are checked out.

### Residual risk (honest)
- **checkout-old-commit:** `git checkout <old-sha>` predating the hooks removes the hook *files*
  from the working tree; the `PreToolUse` commands then point at missing scripts. The OS-level
  *denies* still hold (they don't depend on repo files), but the bash/credential/egress *content
  checks* would be absent until the working tree is restored. Full mitigation (copy the hook
  scripts to a root-owned path outside the repo and reference those from managed-settings) is a
  hardening follow-up, not build-now.
- The locks defend against the agent, not a malicious human operator with shell access.

## Operational rules (not enforceable by a file — the real fix)
- **Never put a production credential in the agent's environment.** Use a scoped/local credential.
- **Apply production migrations by hand** (F4). The hooks block destructive DB commands; the
  operator runs intended migrations themselves.
