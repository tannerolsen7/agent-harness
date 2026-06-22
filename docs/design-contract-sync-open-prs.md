# sync-open-prs — Design Contract

## What & Why

Open PRs go stale. A PR is opened cleanly, other work merges to main while it waits for review, and by the time the reviewer clicks Merge, GitHub shows conflicts. The current workflow checks for conflicts once, at push time. This feature adds a second sync point: a script that detects open PRs that are behind or conflicting and asks GitHub (or GitLab) to rebase them. It runs automatically when main advances and at the start of each session.

## Context

Existing infrastructure this builds on:
- `scripts/detect-forge.sh` — returns `github | gitlab | unknown` from the remote URL
- `.claude/hooks/session-start.sh` — already calls `gc.sh` gated behind `.claude/.gc-enabled`; same pattern for the new call
- `.github/workflows/ci.yml` — existing GitHub Actions job pattern to follow
- `.gitlab-ci.yml` — existing GitLab CI job pattern to follow
- `.gitattributes` — has `merge=union` on RECURRING-FINDINGS.md and patterns-registry.md; `merge=ours` on harness-progress.html; custom driver on TASKS.md
- `docs/TESTING.md` is generated (not tracked by git) — no entry needed for it

## Done Looks Like

- `scripts/sync-open-prs.sh` exists, is executable, and passes shellcheck
- Running with no open PRs exits 0 and prints "no open PRs to sync"
- Running with a conflicting PR calls `gh pr update-branch --rebase <number>` (GitHub) or `glab mr rebase <id>` (GitLab) and prints one result line per PR
- Running when the forge CLI is not installed exits 0 with a clear skip message
- `.claude/hooks/session-start.sh` calls the script when `.claude/.gc-enabled` exists
- `.github/workflows/sync-prs-on-merge.yml` triggers on `pull_request.closed` where merged=true
- `.gitlab-ci.yml` has a `sync-prs` job triggered on MR merged pipeline event
- `.gitattributes` has `PITFALLS.md merge=union`
- Tests cover: no-CLI path, no-PRs path, update-succeeds path, update-fails path

## Data Shape

No database changes.

Script reads from `gh pr list --json number,headRefName,baseRefName,mergeable,isDraft`:
```
[
  { "number": 102, "headRefName": "feat/deploy-drift-impl",
    "baseRefName": "main", "mergeable": "CONFLICTING", "isDraft": false }
]
```

Script output: exit code 0 always. One printed line per PR that was attempted:
- `updated #102 (feat/deploy-drift-impl)` — rebase succeeded
- `failed #102 (feat/deploy-drift-impl) — rebase manually` — rebase failed; human action needed

PRs that are skipped (draft, non-default base, or non-CONFLICTING) produce no output line.

## Edge Cases

- `gh`/`glab` not installed: exit 0 + "forge CLI unavailable — skipping PR sync"
- No open PRs: exit 0 + "no open PRs to sync"
- PR targets a non-main branch (stacked PR): skip — rebasing onto main would put it on the wrong base
- `gh pr update-branch --rebase` fails: log failure with manual rebase instructions, continue to next PR, exit 0
- Script called concurrently (two sessions start simultaneously): `gh pr update-branch` is idempotent — running it twice on a clean PR is safe
- GitLab `glab mr rebase` fails: same handling as gh failure

## Interface Contract

**sync-open-prs.sh**

Inputs: none (reads from forge via CLI)

Outputs:
- Exit code: always 0 (must never block session-start)
- Stdout: one line per PR

Constraints:
- Must exit 0 even when CLI unavailable or rebase fails — runs in session-start
- Must skip PRs whose baseRefName is not the repo default branch (main/master) — stacked PRs target feature branches
- Forge detection via `scripts/detect-forge.sh`; dispatches to `gh` or `glab`

**sync-prs-on-merge.yml (GitHub Actions)**

Trigger: `pull_request` event, `types: [closed]`, condition: `github.event.pull_request.merged == true`
Permissions: `pull-requests: write`, `contents: write`
Auth: default `GITHUB_TOKEN` — sufficient for `gh pr update-branch`

**GitLab CI sync-prs job**

Trigger: pipeline triggered on MR merged event
Auth: `glab mr rebase` requires a token with MR-write permissions. `CI_JOB_TOKEN` may not have this — teams need `GITLAB_TOKEN` set as a project CI variable.

**.gitattributes**

`PITFALLS.md merge=union` — append-only (new entries added at EOF). Two branches both adding entries: both survive. Two branches editing the same existing entry: both versions survive as duplicate lines (acceptable — rare and manually fixable).

## Out of Scope

- Resolving genuine text conflicts — script reports and skips; human resolves
- Periodic cron syncing (future: add via `/schedule`)
- Syncing stacked PRs (PRs targeting feature branches) — different logic needed; excluded
- Notifications for failed syncs

## Resolved Decisions

1. **`--rebase` vs merge commit**: use `gh pr update-branch --rebase` (not the default merge-commit form). Cleaner history; review dismissal is acceptable because approvals in this workflow happen immediately before merge, not long before.

2. **BEHIND vs CONFLICTING**: only sync PRs where `mergeable: "CONFLICTING"`. At 10+ PRs/day with 6–8 open at once, proactive rebasing of all BEHIND PRs would trigger ~70 rebases/day, most unnecessary. Reactive is correct at both low and high volume.

3. **GitLab CI auth**: gate the sync job on `$GITLAB_TOKEN` (`rules: - if: "$GITLAB_TOKEN"`). A missing variable silently skips rather than breaking the pipeline. Document the variable requirement in the job comment. Make enabling `GITLAB_TOKEN` part of the install flow so teams decide at setup time.

## Relevant Files

- `scripts/detect-forge.sh` — forge detection
- `.claude/hooks/session-start.sh` — session-start wiring target
- `.github/workflows/ci.yml` — GitHub Actions pattern
- `.gitlab-ci.yml` — GitLab CI pattern
- `.gitattributes` — merge=union target
- `scripts/gc.sh` — session-start gated-call pattern to follow
- `PITFALLS.md` — gets merge=union
