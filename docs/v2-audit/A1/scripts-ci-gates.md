# A1 — Scripts, CI Workflows, and Completion-Gate System (FACT-ONLY Inventory)

Pass A1 of the v2 ground-truth audit. Records what exists and what it claims to do.
No evaluation, judgment, or recommendation. Verifiable absences are recorded as facts.

Repo: `/Users/tanner/Dev/event-vendor` · Branch: `main` · Audit date: 2026-06-10

---

## Headline answers

- **(a) `.cr-ok` sentinel lifecycle:** WRITTEN by `/cr` (`.claude/skills/cr/SKILL.md` Step 7) or by the queue `task-runner` (`.claude/agents/task-runner.md` step 3). VALIDATED (not consumed) by `.husky/pre-push` non-interactive path (`.husky/pre-push:56–72`). CONSUMED (atomically `mv`'d, then `rm`'d) by `scripts/pr.sh` non-interactive path (`scripts/pr.sh:31–45`). Content is `branch:sha`. File is **gitignored** (`.gitignore:58`) so it never enters a commit, push payload, or CI checkout.
- **(b) Does CI verify the sentinel? NO.** `.github/workflows/ci.yml` and `.github/workflows/integration.yml` contain **zero** references to `.cr-ok` (`grep -c "cr-ok"` = 0 in both). CI re-runs `tsc`, `eslint`, and `npm run test:unit` independently. The sentinel is enforced only at the local git boundary by `.husky/pre-push` (validate) and `scripts/pr.sh` (consume). This is the "Node 8.5(c) gap": a push that bypasses the local hook (e.g. `--no-verify`, or merging a PR that was opened without `pr.sh`) is not caught by CI because CI never checks the sentinel.
- **(c) Does `dependabot.yml` exist? NO.** `.github/dependabot.yml` is ABSENT (`ls` confirmed). `.github/` contains only `workflows/` (ci.yml, integration.yml).

---

## Scripts

### `scripts/README.md`
1. **Purpose:** Index of the three "public" scripts (`worktree-add.sh`, `pr.sh`, `gc.sh`).
2. **Contents:** Table mapping each script to a one-line purpose (`README.md:3–7`). States `gc.sh` runs weekly, tracked in `.claude/rituals.md → stale-branch-audit` (`README.md:9`), and that GitHub auto-deletes remote branches on merge via `delete_branch_on_merge=true` so `gc.sh` mainly syncs local state (`README.md:10–11`).
3. **Enforcement:** ADVISORY (documentation only).
4. **Cross-refs:** Does NOT list `gen-local-env.sh`, `test-local.sh`, or `seed.ts` (3 of the 6 scripts are undocumented in the README).

### `scripts/gc.sh`
1. **Purpose:** Clean up stale (merged) branches and orphaned worktrees (`gc.sh:1–7`). WIP branches and active worktrees never touched.
2. **Steps:**
   - `set -e` (`:8`).
   - `git fetch --prune` — removes tracking refs for branches deleted on remote (`:15`).
   - `git worktree prune` — removes registrations for missing directories (`:19`).
   - Computes `GONE` = local branches showing `: gone]` in `git branch -vv`, excluding the current `*` branch (`:24`).
   - For each gone branch: tries `git branch -d` (`:28`); if refused (squash-merge SHA mismatch) and `gh` available, queries `gh pr list --head "$b" --state merged` (`:34`); if a merged PR is found, prints the short SHA then `git branch --delete --force` with a recovery hint (`:39–41`); else skips with a manual-delete hint (`:43`); if `gh` unavailable, skips (`:46`).
   - Comment notes assumption: branch names are not reused after squash-merge (`:33`).
3. **Enforcement:** ADVISORY / manual maintenance. Blocks nothing. Mutating (force-deletes local branches) but only after a merged-PR confirmation via `gh`.
4. **Cross-refs:** Invoked per `CLAUDE.md` session-start rule and `scripts/README.md:9` (rituals `stale-branch-audit`). Calls `git`, `gh`.
5. **Overlaps:** Branch-cleanup logic (verify merged PR before force-delete) overlaps conceptually with `.husky/pre-push:28–35` merged-PR push block, but they guard different operations (cleanup vs push).

### `scripts/gen-local-env.sh`
1. **Purpose:** Write a local-stack `.env.local` into a target worktree dir so unattended agents never receive the prod service-role key (`gen-local-env.sh:1–9`). Fail-closed: exits 1, writes nothing if local stack down.
2. **Steps:** `set -euo pipefail` (`:10`). Requires `$1` target dir, asserts it exists (`:12–15`, labeled "prod-key firewall"). Requires `supabase` on PATH (`:17`). Sources `supabase status -o env` (`:19–22`). Extracts `API_URL`, `ANON_KEY`, `SERVICE_ROLE_KEY` (`:28–30`). Asserts URL non-empty (`:32`), then case-matches URL against `http://127.0.0.1:*` and refuses to write otherwise (`:34–37`). Asserts anon + service key present (`:39–40`). Writes the three `NEXT_PUBLIC_*` / `SUPABASE_SERVICE_ROLE_KEY` lines to `$TARGET/.env.local` (`:42–43`).
3. **Enforcement:** STRUCTURAL for the prod-key firewall — refuses (exit 1) to write any `.env.local` unless the resolved URL is `127.0.0.1`. No prod fallback exists.
4. **Cross-refs:** Called only by `scripts/worktree-add.sh:16` when `UNATTENDED=1`. Calls `supabase`.
5. **Overlaps:** The `127.0.0.1` URL guard duplicates the same guard in `scripts/test-local.sh:55`.

### `scripts/pr.sh`
1. **Purpose:** Open a PR, enforcing that `/cr` ran (`pr.sh:1–5`). Non-interactive: validates `.claude/.cr-ok` (`branch:sha`); interactive: prompts user.
2. **Steps:** `set -e` (`:6`). `SENTINEL=".claude/.cr-ok"` (`:8`). Resolves `CURRENT_BRANCH` and `HEAD_SHA`, builds `EXPECTED="branch:sha"` (`:9–17`).
   - **Interactive (`[ -t 0 ]`):** prompts "Have you run /cr…"; aborts unless `y`/`Y` (`:19–25`).
   - **Non-interactive:** aborts if sentinel missing (`:27–30`); atomically `mv`s sentinel to `.consumed.$$` with an EXIT/INT/TERM cleanup trap (`:31–36`) — if `mv` fails, aborts ("consumed by another process"); reads consumed content (`:37`); if empty or `!= EXPECTED`, restores sentinel and aborts as stale (with sanitized branch/actual strings) (`:38–44`); else `rm`s the consumed file (`:45`).
   - Checks `gh` present (`:48–51`). Guards that branch exists on remote via `git ls-remote` before calling `gh` (`:54–58`).
   - `gh pr create "$@"` (`:60`) — passes through all args.
3. **Enforcement:** STRUCTURAL — blocks PR creation when sentinel missing/stale (non-interactive) or when user answers no (interactive). **Sole consumer** of `.cr-ok`. Operates only at PR-creation time, locally; it is not invoked by CI.
4. **Cross-refs:** Per `CLAUDE.md` workflow step 5 — use `scripts/pr.sh` not `gh pr create` directly. Invoked by `.claude/skills/queue/SKILL.md:104` and referenced by `.claude/skills/cr/SKILL.md:256`, `.claude/skills/notion-sync/SKILL.md:225`. Calls `git`, `gh`.
5. **Overlaps/gaps:** Sentinel SHA-match logic overlaps with `.husky/pre-push:56–72` (validate-only). Split ownership is documented in `PITFALLS.md:308–314`: pre-push validates but does NOT consume; `pr.sh` is sole consumer. **Gap:** `pr.sh` never re-runs tests/build/`/cr` content — it trusts the sentinel string only.

### `scripts/test-local.sh`
1. **Purpose:** Run vitest against the local Supabase stack instead of prod, which `.env.local` points at by default (`test-local.sh:1–19`).
2. **Steps:** `set -euo pipefail` (`:21`). Requires `supabase` on PATH (`:23–26`). Sources `supabase status -o env` (`:32–35`). `remap()` translates CLI var names to the names vitest/Next read, capturing everything after the first `=` and stripping quotes (`:40–49`). Remaps `API_URL→NEXT_PUBLIC_SUPABASE_URL`, `ANON_KEY→…ANON_KEY`, `SERVICE_ROLE_KEY→SUPABASE_SERVICE_ROLE_KEY` (`:51–53`). Aborts unless URL is `http://127.0.0.1:*` (`:55–58`). `exec npx vitest run "$@"` (`:61`).
3. **Enforcement:** STRUCTURAL safety guard — refuses to run vitest unless URL is local. Does not gate push/merge; it is a test-runner wrapper.
4. **Cross-refs:** Wired as `npm run test:local` (package.json). Documented in `CLAUDE.md` Testing section. Calls `supabase`, `npx vitest`.
5. **Overlaps:** `127.0.0.1` guard duplicates `gen-local-env.sh:34–37`. The CLI-env remap/quote-strip logic is duplicated (different implementations) between this file and `gen-local-env.sh:24–26`.

### `scripts/worktree-add.sh`
1. **Purpose:** Create a git worktree and provision Supabase creds (`worktree-add.sh:1–6`). `UNATTENDED=1` writes local-stack creds (fail-closed); default symlinks `.env.local` from repo root.
2. **Steps:** `set -e` (`:7`). Requires `$1` path + `$2` branch (`:9–10`). `REPO_ROOT=git rev-parse --show-toplevel` (`:11`). `git worktree add` (`:13`). If `UNATTENDED=1`: runs `gen-local-env.sh "$WORKTREE_PATH"`; on failure removes the uncredentialed worktree and exits 1 (`:15–20`). Else if repo-root `.env.local` exists: symlinks it into the worktree (`:21–23`). Else warns that integration tests will fail (`:24–26`).
3. **Enforcement:** STRUCTURAL only in `UNATTENDED=1` mode (removes worktree if local creds unavailable). Default mode is best-effort (warns, does not fail).
4. **Cross-refs:** Per `CLAUDE.md` worktree rule. Calls `git worktree`, `gen-local-env.sh`, `ln`.
5. **Gap:** Default (human) mode symlinks the prod-pointing repo-root `.env.local`; the prod-key firewall (`gen-local-env.sh`) only applies in `UNATTENDED=1`.

### `scripts/seed.ts` (skim — purpose only)
1. **Purpose:** Seeds a known test user (`test@gmail.com` / `Testing1234!`) and a fully populated "Talia & Bailey" demo wedding (client, event, proposal, 17 line items) so the dev UI renders (`seed.ts:1–6`). Idempotent — skips if the user already exists (`seed.ts:23–29`). Service-role only; comment says never run in prod (`seed.ts:2–3`).
2. **Form:** A `vitest` test (`test(...)`) using `supabaseAdmin` (`seed.ts:7–14`), run via `npm run seed`.
3. **Enforcement:** N/A — data-seeding utility, no gate.

---

## CI Workflows

### `.github/workflows/ci.yml`
1. **Purpose:** Type check, lint, test (`ci.yml:1, 10`).
2. **Triggers:** `pull_request` (any) and `push` to `main` (`ci.yml:3–6`).
3. **Steps (`ci.yml:12–26`):** checkout v4 → setup-node v4 (`.node-version`, npm cache) → `npm ci` → `npx tsc --noEmit` → `npx eslint .` → `npm run test:unit`.
   - `test:unit` = `vitest run --exclude 'src/data/**'` (package.json) — excludes integration (DB) tests.
4. **Enforcement:** STRUCTURAL on merge — `CLAUDE.md` step 6 states branch merges are blocked if CI fails (depends on GitHub branch-protection config, not verifiable from repo files alone).
5. **Facts:** Does NOT reference `.cr-ok` (grep count 0). Does NOT run integration/DB tests. Does NOT run `next build`. Does NOT enforce `/cr`.

### `.github/workflows/integration.yml`
1. **Purpose:** DB integration tests (`integration.yml:1, 17`).
2. **Trigger:** `workflow_dispatch` ONLY — manual (`integration.yml:12–13`). Does not run on PR or push.
3. **Steps (`integration.yml:23–33`):** checkout → setup-node → `npm ci` → `npm run test:integration`. Reads 3 repo secrets (`NEXT_PUBLIC_SUPABASE_URL`, `…ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) as env (`:19–22`); header comment says they must be added manually before first run and point to a real test instance (`:1–9`).
   - `test:integration` = `vitest run src/data/` (package.json).
4. **Enforcement:** ADVISORY — manual dispatch only; blocks no PR or merge automatically.
5. **Facts:** Does NOT reference `.cr-ok` (grep count 0). Never runs automatically.

---

## Completion-Gate / Sentinel System — Full Lifecycle

| Stage | Actor | File:line | Action |
|-------|-------|-----------|--------|
| WRITE | `/cr` skill | `.claude/skills/cr/SKILL.md:242–250` | After clean review, writes `${REPO_ROOT}/.claude/.cr-ok` = `branch:sha` (printf or Write tool fallback). |
| WRITE | queue `task-runner` | `.claude/agents/task-runner.md:119` | On completion writes `.cr-ok` = `$(branch):$(HEAD sha)`. |
| VALIDATE (no consume) | `.husky/pre-push` non-interactive | `.husky/pre-push:56–72` | Blocks push if `.cr-ok` missing / empty / `!= branch:sha`. Comment `:72`: not consumed here. |
| PROMPT (no sentinel) | `.husky/pre-push` interactive | `.husky/pre-push:37–45` | Human path: TTY prompt only; sentinel left to `pr.sh`. |
| VALIDATE | queue push step | `.claude/skills/queue/SKILL.md:105` | `cat .claude/.cr-ok` must equal `feat/<slug>:<HEAD sha>`. |
| CONSUME | `scripts/pr.sh` non-interactive | `scripts/pr.sh:31–45` | Atomic `mv` → validate `branch:sha` → `rm`. Restores on mismatch. Sole consumer. |
| CONSUME | `scripts/pr.sh` interactive | `scripts/pr.sh:19–25` | Human TTY prompt instead of file check. |
| (storage) | gitignore | `.gitignore:58` | `.claude/.cr-ok` gitignored — never committed, never in CI checkout. |

### `.cr-feature-ok` — current status (fact)
- Listed in `.gitignore:57` and referenced extensively in `docs/solutions/*` history.
- **No live (non-doc) code references it.** `grep "cr-feature-ok"` over `.husky/`, `scripts/`, `.claude/skills/`, `.claude/agents/` returns nothing.
- Per `docs/solutions/2026-05-27-collapsing-redundant-review-gate.md`, the second gate (`.cr-feature-ok` / `/cr-feature`) was removed; pre-push non-interactive now checks `.cr-ok` only. The live `.husky/pre-push` confirms this (no `.cr-feature-ok` logic present).

### Pre-push additional gates (not sentinel-related)
- `.husky/pre-push:7–18` — exits 0 for all-deletion pushes (no review needed).
- `.husky/pre-push:22–25` — blocks push if `.env.local` missing.
- `.husky/pre-push:28–35` — blocks push to a branch whose PR is already merged (via `gh pr list`).
- `.husky/pre-push:75–76` — runs `npm run test` (full suite, includes integration → hits the DB `.env.local` points at) and `npm run build` after the gate passes. STRUCTURAL.

---

## CI vs sentinel — the Node 8.5(c) gap (fact)

- The `.cr-ok` sentinel is enforced exclusively at the **local git boundary**: `.husky/pre-push` (validate) and `scripts/pr.sh` (validate + consume).
- Neither CI workflow references `.cr-ok` (grep count 0 in both `ci.yml` and `integration.yml`), and the file is gitignored, so CI could not check it even if it tried — the sentinel never reaches the CI runner.
- Consequence (factual): any path that skips the local hook/script — `git push --no-verify`, pushing from an environment without `.husky` installed, or merging a PR opened by `gh pr create` directly rather than `scripts/pr.sh` — produces no CI-level `/cr` enforcement. CI independently re-runs `tsc` + `eslint` + `test:unit` only.

## Verifiable absences (facts)

- `.github/dependabot.yml` — ABSENT.
- `ci.yml` does NOT run `next build`, integration/DB tests, or any `.cr-ok` check.
- `integration.yml` runs on `workflow_dispatch` only — never automatically on PR/push.
- `scripts/README.md` documents only 3 of 6 scripts (omits `gen-local-env.sh`, `test-local.sh`, `seed.ts`).
- `127.0.0.1` URL guard is implemented twice (`gen-local-env.sh:34–37`, `test-local.sh:55`).
- supabase-status env remap/quote-strip implemented twice with differing code (`gen-local-env.sh:24–26`, `test-local.sh:40–49`).
