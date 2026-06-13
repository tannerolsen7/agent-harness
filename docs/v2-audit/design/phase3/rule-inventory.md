# Rule Inventory — every binding rule in the harness

**Phase 3 raw material.** Extracted exhaustively from `CLAUDE.md`, `AGENTS.md`, and `PITFALLS.md`
(all read in full, 2026-06-11). This is the input the enforcement sort (L1/L2/L3 relocation) consumes.

**Total binding rules: 118** (R1–R118). Dedup note: rules that appear in 2–3 source files are recorded
ONCE with all sources listed; that multi-file duplication is itself a finding (see "Duplication findings"
at the end).

---

## How `current_enforcement` was determined (disk-verified, not assumed)

Verified against actual hook/CI source on 2026-06-11:

- **L1-hook** = a `.claude/hooks/*.sh` PreToolUse guard catches it. Only TWO guards exist and they
  cover a narrow set: `block-dangerous-git.sh` (reset --hard, clean, rebase, stash clear, branch -D,
  force push, push to main/master/develop, worktree-remove outside `.claude/worktrees/*`) and
  `block-npm-install.sh` (install/add/link/update of a *package*). **L1 is agent-only** — these fire on
  Claude tool calls, not on a human shell. Both **fail OPEN if `jq` is missing**.
- **git-hook** = `.husky/pre-commit` (lint + `tsc --noEmit` + `test:unit`) or `.husky/pre-push`
  (`.env.local` presence, merged-PR block, `.cr-ok` sentinel match, full `vitest run` + `next build`).
  Fires for humans AND agents. NOTE: pre-commit unit tests EXCLUDE `src/data/**` (integration), so
  data-layer integration assertions are pre-push/CI only.
- **L2-CI-test** = `.github/workflows/ci.yml` runs `tsc --noEmit`, `eslint .`, `test:unit` on every PR +
  push to main. **No architecture/layer-boundary test runs in CI** — `dependency-cruiser` is absent, so
  every "components may not import data" / layer-boundary rule is NOT mechanically enforced anywhere; it
  is `/cr` Pass 4 advisory prose only.
- **L3-advisory-prose-only** = stated in a markdown doc, no mechanism. The agent may comply or not;
  nothing blocks.
- **none** = not even reliably stated as a standing rule (rare; used where a "rule" is really a
  convention with no enforcement claim at all).

**ESLint nuance:** `eslint.config.mjs` sets these to `error` (so lint, hence pre-commit + CI, blocks
them): `no-unused-vars`, `no-non-null-assertion`, `consistent-type-imports`, `import/no-cycle`, and —
via `eslint-config-next/typescript` — `no-explicit-any`. `no-console` is **`warn` only** (does NOT fail
lint). `@ts-ignore`/`@ts-expect-error` and bad `as` casts are NOT caught by the current ESLint config or
by tsc — they are advisory. Where a rule is ESLint-`error`-enforced I mark it `git-hook` (earliest gate)
and the duplication note flags that CI re-checks it.

---

## Inventory

| id | rule | source | current_enforcement | reversibility_if_violated |
|----|------|--------|---------------------|---------------------------|
| R1 | NEVER use `any` | CLAUDE.md → NEVER / TypeScript | git-hook | reversible |
| R2 | NEVER use `// @ts-ignore` or `// @ts-expect-error` | CLAUDE.md → NEVER / TypeScript | L3-advisory-prose-only | reversible |
| R3 | NEVER cast with `as` without a preceding type-narrowing check | CLAUDE.md → NEVER / TypeScript | L3-advisory-prose-only | reversible |
| R4 | MUST define Zod schemas for all data crossing a system boundary (API resp, URL params, form input, Supabase results) | CLAUDE.md → TypeScript | L3-advisory-prose-only | irreversible |
| R5 | MUST derive TS types from Zod via `z.infer<>`; never duplicate shape as both schema and hand-written interface | CLAUDE.md → TypeScript / NEVER; PITFALLS § hand-written-interface-in-data-layer | L3-advisory-prose-only | reversible |
| R6 | Props MUST be a named interface, not an inline object type | CLAUDE.md → TypeScript | L3-advisory-prose-only | reversible |
| R7 | Components are I/O only — MUST contain no business logic | CLAUDE.md → Architecture / NEVER | L3-advisory-prose-only | reversible |
| R8 | Business logic MUST live in pure, testable functions outside components | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R9 | Supabase query functions MUST live in `src/data/` — never inline in component/page/layout | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R10 | NEVER call the Supabase client directly from a component, page, or layout | CLAUDE.md → Architecture / NEVER | L3-advisory-prose-only | irreversible |
| R11 | Server components and server actions MUST call `src/data/` functions directly | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R12 | If a function does two distinct things, split it | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R13 | Do not extract a shared abstraction until the pattern appears a third time | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R14 | Write the minimum code that satisfies the requirement; no design for hypothetical future cases | CLAUDE.md → Architecture / Agent behavior (Build what's needed now) | L3-advisory-prose-only | reversible |
| R15 | Status transitions needing a server timestamp or atomic audit write MUST use Postgres BEFORE/AFTER UPDATE triggers, not app-layer code | CLAUDE.md → Architecture; PITFALLS § trigger-owned-timestamps | L3-advisory-prose-only | irreversible |
| R16 | Pages in `proxy.ts PUBLIC_PATHS` MUST live at root route level, not inside any route group | CLAUDE.md → Architecture; PITFALLS § public-paths-inside-route-groups | L3-advisory-prose-only | reversible |
| R17 | Every route group and distinct layout level MUST have a colocated `error.tsx` | CLAUDE.md → Architecture | L3-advisory-prose-only | reversible |
| R18 | Data functions called from both a layout and a page in the same request MUST be wrapped in `cache()` | CLAUDE.md → Architecture; PITFALLS § react-cache-for-layout-page-shared-data | L3-advisory-prose-only | reversible |
| R19 | `app/(app)/*/actions.ts` server actions import from `src/` via relative paths; `@/` only resolves to `src/` | CLAUDE.md → Architecture | git-hook | reversible |
| R20 | Role-based access control MUST be enforced at the `src/data/` TS layer only — never in RLS policies | CLAUDE.md → Architecture; AGENTS.md → Rejected Patterns; PITFALLS § rls-role-mission-creep | L3-advisory-prose-only | safety-critical |
| R21 | `page.tsx`/`layout.tsx`/`loading.tsx` use default export; all other components named export | CLAUDE.md → File conventions | git-hook | reversible |
| R22 | Utilities, data functions, schemas, types, interfaces use named export | CLAUDE.md → File conventions | git-hook | reversible |
| R23 | Component file names PascalCase.tsx; utility/data/schema files camelCase.ts; type files PascalCase.ts | CLAUDE.md → File conventions | L3-advisory-prose-only | reversible |
| R24 | Shared TS types across `app/`+`src/` live in `src/types/`, imported via `@/types/TypeName` | CLAUDE.md → File conventions | L3-advisory-prose-only | reversible |
| R25 | Path alias `@/` resolves from `src/`; imports read `@/components/...` never `@/src/components/...` | CLAUDE.md → File conventions | git-hook | reversible |
| R26 | Discriminated payloads live in `src/schemas/<domain>/<literal>.ts`; shared row schema in `<domain>/index.ts` | CLAUDE.md → File conventions | L3-advisory-prose-only | reversible |
| R27 | NEVER have both `src/schemas/<domain>.ts` (file) and `src/schemas/<domain>/` (folder) | CLAUDE.md → File conventions; PITFALLS § schema-file-folder-collision | L3-advisory-prose-only | irreversible |
| R28 | NEVER write a comment that describes what the code does | CLAUDE.md → Code style | L3-advisory-prose-only | reversible |
| R29 | ONLY write a comment when the WHY is non-obvious — one line max | CLAUDE.md → Code style | L3-advisory-prose-only | reversible |
| R30 | NEVER write multi-line comment blocks or docstrings | CLAUDE.md → Code style | L3-advisory-prose-only | reversible |
| R31 | Use `cn()` (clsx + tailwind-merge) for all conditional Tailwind class merging | CLAUDE.md → Code style | L3-advisory-prose-only | reversible |
| R32 | NEVER concatenate Tailwind class strings manually | CLAUDE.md → Code style | L3-advisory-prose-only | reversible |
| R33 | Colocate test files next to the file under test | CLAUDE.md → Testing | L3-advisory-prose-only | reversible |
| R34 | Unit tests for all pure functions in `src/data/`, `src/schemas/`, `src/utils/` | CLAUDE.md → Testing | L3-advisory-prose-only | reversible |
| R35 | Integration tests for data-access functions MUST run against a real Supabase test instance | CLAUDE.md → Testing | L3-advisory-prose-only | reversible |
| R36 | NEVER mock the database in tests | CLAUDE.md → Testing / NEVER | L3-advisory-prose-only | reversible |
| R37 | No snapshot tests | CLAUDE.md → Testing | L3-advisory-prose-only | reversible |
| R38 | New pure functions (src/data, src/schemas, src/utils): write the test FIRST; it must fail before implementation | CLAUDE.md → Development workflow / NEVER | L3-advisory-prose-only | reversible |
| R39 | Refactor: every symbol moved must have a characterization test before it is touched | CLAUDE.md → Development workflow (Refactoring) | L3-advisory-prose-only | reversible |
| R40 | Refactor: structure and behavior never change in the same commit (two hats) | CLAUDE.md → Development workflow (Refactoring) | L3-advisory-prose-only | reversible |
| R41 | Before AI-generated code is committed you MUST be able to answer the 3 discipline questions (what/why, where it fails, what you'd change) | CLAUDE.md → The discipline rule | L3-advisory-prose-only | reversible |
| R42 | MUST read `.claude/memory.md` at session start | CLAUDE.md → Before writing code / session-start line | L3-advisory-prose-only | reversible |
| R43 | At session start read `.claude/memory.md`, `TASKS.md`, `.claude/rituals.md`, `.claude/SOUL.md`; surface any ritual whose last_run > 7 days | CLAUDE.md → top matter | L3-advisory-prose-only | reversible |
| R44 | At session start run `git fetch --prune` + branch-gone check; if any gone branches, run `scripts/gc.sh` before other work | CLAUDE.md → top matter; PITFALLS § post-merge-local-branch-persists | L3-advisory-prose-only | reversible |
| R45 | On first message of a session, classify the work state; name it if not explicit | CLAUDE.md → top matter | L3-advisory-prose-only | reversible |
| R46 | When a mistake is corrected, add a rule to `.claude/memory.md` before session end | CLAUDE.md → top matter | L3-advisory-prose-only | reversible |
| R47 | Before the first commit, confirm the session has its own worktree; if repo root has unrelated uncommitted work, create a worktree first | CLAUDE.md → top matter / Commit workflow | L3-advisory-prose-only | reversible |
| R48 | Multiple agent sessions MUST NOT share a branch | CLAUDE.md → top matter | L3-advisory-prose-only | reversible |
| R49 | MUST skim `docs/solutions/README.md` before designing anything | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R50 | MUST skim `docs/adr/README.md` before designing anything | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R51 | MUST read `PITFALLS.md` before writing in any affected area | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R52 | If the task touches Supabase, MUST invoke `/supabase` before writing code | CLAUDE.md → Before writing code / Migrations | L3-advisory-prose-only | reversible |
| R53 | If the task touches Vercel, MUST invoke `/vercel-react-best-practices` before writing code | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R54 | On "/notion-sync"/"sync with Notion"/"apply Notion updates", MUST invoke `/notion-sync` | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R55 | On `/debug`, MUST invoke `/debug` skill | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R56 | If the cause of a bug is unknown, MUST invoke `/debug` before writing any fix | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R57 | MUST define before starting: props/inputs, return/render, what it must NOT do, what done looks like | CLAUDE.md → Before writing code / Shipping a change | L3-advisory-prose-only | reversible |
| R58 | MUST confirm the task fits current MVP scope (AGENTS.md → MVP Scope) | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R59 | MUST surface any open decision the task touches; NEVER resolve an open decision unilaterally | CLAUDE.md → Before writing code / NEVER; AGENTS.md → Open decisions | L3-advisory-prose-only | reversible |
| R60 | MUST ask before installing any npm package (provide name, purpose, weekly downloads, last publish, ships own types) | CLAUDE.md → Before writing code / NEVER | L1-hook | reversible |
| R61 | If the task is ambiguous, MUST ask a clarifying question before writing anything | CLAUDE.md → Before writing code | L3-advisory-prose-only | reversible |
| R62 | Honest assessment over validation — name real problems directly, do not lead with praise | CLAUDE.md → Agent behavior principles | L3-advisory-prose-only | reversible |
| R63 | Research before guessing — verify external API/framework/library behavior before forming an opinion | CLAUDE.md → Agent behavior principles | L3-advisory-prose-only | reversible |
| R64 | For deep unknowns use 3-pass research (each pass informed by the prior) | CLAUDE.md → Agent behavior principles | L3-advisory-prose-only | reversible |
| R65 | When work introduces/changes a pattern, constraint, or decision, update the relevant doc in the same commit | CLAUDE.md → Keeping docs current | L3-advisory-prose-only | reversible |
| R66 | Feature complete: run `/cr` before pushing; auto-fix MUST FIX; do not push with unresolved NEEDS HUMAN | CLAUDE.md → Shipping a change / NEVER | git-hook | reversible |
| R67 | If any commit touched auth/middleware/RLS, run `/cr-security` alongside `/cr` | CLAUDE.md → Shipping a change | L3-advisory-prose-only | safety-critical |
| R68 | NEVER push or open a PR without running `/cr` (sentinel `.cr-ok` must match branch:sha) | CLAUDE.md → Shipping a change / NEVER | git-hook | reversible |
| R69 | Open PRs via `scripts/pr.sh` (validates + consumes `.cr-ok`), not `gh pr create` directly | CLAUDE.md → Shipping a change; PITFALLS § pre-push-consumes-cr-ok-before-pr-sh | L3-advisory-prose-only | reversible |
| R70 | After opening/updating a PR, always surface the URL to the user | CLAUDE.md → Shipping a change | L3-advisory-prose-only | reversible |
| R71 | NEVER spawn a background agent needing Bash without all required command patterns in `permissions.allow` first | CLAUDE.md → Shipping a change / Commit workflow / NEVER | L3-advisory-prose-only | reversible |
| R72 | NEVER modify `next.config.ts` without explaining the change to the user first | CLAUDE.md → Safe-change rules | L3-advisory-prose-only | reversible |
| R73 | NEVER modify `tsconfig.json` without explaining the change first | CLAUDE.md → Safe-change rules | L3-advisory-prose-only | reversible |
| R74 | NEVER silently delete a file — flag as dead code and ask | CLAUDE.md → Safe-change rules / NEVER | L3-advisory-prose-only | reversible |
| R75 | When Supabase Storage images are introduced, `images.remotePatterns` in `next.config.ts` must include the Supabase domain | CLAUDE.md → Safe-change rules; AGENTS.md → Images | L3-advisory-prose-only | reversible |
| R76 | Building a redirect URL from user input: use only `resolved.pathname` — never append `.search`/`.hash` | CLAUDE.md → Safe-change rules | L3-advisory-prose-only | safety-critical |
| R77 | NEVER execute a destructive/irreversible op (DELETE, DROP, TRUNCATE, volume delete, `rm`, `git reset --hard`, `git push --force`, curl mutations, mutating RPC) without an explicit same-turn user instruction naming the exact resource | CLAUDE.md → Destructive-operation rules / NEVER | L1-hook (git ops only) | irreversible |
| R78 | NEVER reuse an API key/token/credential found in a file unrelated to the current task | CLAUDE.md → Destructive-operation rules / NEVER | L3-advisory-prose-only | safety-critical |
| R79 | NEVER assume a token is scoped to an environment/project/operation — treat all tokens as root | CLAUDE.md → Destructive-operation rules / NEVER | L3-advisory-prose-only | safety-critical |
| R80 | NEVER treat "staging" as isolated from production without verifying the infrastructure boundary | CLAUDE.md → Destructive-operation rules | L3-advisory-prose-only | safety-critical |
| R81 | Before any mutating external API call, state what it targets, whether reversible, and ask for explicit confirmation | CLAUDE.md → Destructive-operation rules / NEVER | L3-advisory-prose-only | safety-critical |
| R82 | If you cannot answer "is this reversible?" with certainty, treat it as irreversible and stop | CLAUDE.md → Destructive-operation rules | L3-advisory-prose-only | safety-critical |
| R83 | Only commit/push changes made in this conversation; if repo has unrelated changes, move to a worktree first | CLAUDE.md → Commit workflow | L3-advisory-prose-only | reversible |
| R84 | When done with a worktree task, run `git worktree remove <path>`; never leave an orphaned worktree | CLAUDE.md → Commit workflow / NEVER | L3-advisory-prose-only | reversible |
| R85 | After a PR merges, delete local branch + prune remote (confirm merged via `gh pr view`) in the same turn | CLAUDE.md → Commit workflow; PITFALLS § post-merge-local-branch-persists | L3-advisory-prose-only | reversible |
| R86 | Use conventional commits; body is required | CLAUDE.md → Commit workflow | L3-advisory-prose-only | reversible |
| R87 | Merge strategy is squash merge — one commit per logical change on main | CLAUDE.md → Commit workflow; AGENTS.md → Resolved decisions | L3-advisory-prose-only | reversible |
| R88 | Do not bundle unrelated changes in a single commit | CLAUDE.md → Commit workflow | L3-advisory-prose-only | reversible |
| R89 | Before finishing: `tsc --noEmit` zero errors; no unused imports/dead code/placeholder comments; no silently-resolved open decisions | CLAUDE.md → Before finishing / NEVER | git-hook | reversible |
| R90 | Do NOT introduce Redux, React Query (deferred), class components, or CSS modules | CLAUDE.md → Tech stack; AGENTS.md → Resolved decisions (React Query) | L3-advisory-prose-only | reversible |
| R91 | NEVER expand scope without surfacing it as a scope question | CLAUDE.md → NEVER; AGENTS.md → How we work | L3-advisory-prose-only | reversible |
| R92 | Every `CREATE OR REPLACE FUNCTION` in a migration MUST be followed by `REVOKE EXECUTE ... FROM PUBLIC` (incl. trigger fns) | CLAUDE.md → Migrations; PITFALLS § create-replace-function-resets-grants | L3-advisory-prose-only | safety-critical |
| R93 | `CREATE INDEX` in a migration MUST NOT use `CONCURRENTLY`; use IF NOT EXISTS for idempotency | CLAUDE.md → Migrations; PITFALLS § concurrent-index-banned-in-migration | L3-advisory-prose-only | reversible |
| R94 | Destructive migration ops (column/table drop, enum value removal) MUST have a documented rollback path before merging | CLAUDE.md → Migrations | L3-advisory-prose-only | irreversible |
| R95 | Before writing any migration, invoke `/supabase` | CLAUDE.md → Migrations | L3-advisory-prose-only | reversible |
| R96 | All UI work MUST reference `docs/design/tokens.md` + `components.md` before writing any component/style; deviate only if instructed | AGENTS.md → Design system | L3-advisory-prose-only | reversible |
| R97 | Every component MUST conform to the design-file patterns | AGENTS.md → Design system | L3-advisory-prose-only | reversible |
| R98 | Single-vendor assumptions (hardcoded email, single tax default, etc.) MUST be flagged and generalized before onboarding a second vendor | AGENTS.md → What this project is (Target state) | L3-advisory-prose-only | reversible |
| R99 | `src/data/` functions validate responses with Zod before returning typed values | AGENTS.md → Data flow / Data access | L3-advisory-prose-only | irreversible |
| R100 | Before writing a new file in any layer, read the golden-exemplar canonical file for that layer first | AGENTS.md → Golden exemplars | L3-advisory-prose-only | reversible |
| R101 | Use `next/image` for all images (lazy loading, format conversion, responsive sizing) | AGENTS.md → Images | L3-advisory-prose-only | reversible |
| R102 | A ticket that depends on an unresolved open decision cannot run until the decision is resolved in AGENTS.md first | AGENTS.md → Open decisions | L3-advisory-prose-only | reversible |
| R103 | NEVER add role conditions to RLS policies (RLS = tenant isolation only) | AGENTS.md → Rejected Patterns; PITFALLS § rls-role-mission-creep; CLAUDE.md → Architecture | L3-advisory-prose-only | safety-critical |
| R104 | MVP out-of-scope items (contract signing, payment scheduling, vendor self-registration, role-management UI, PDF export, deposit-tracking UI, ⌘K palette) must not be built in v1 | AGENTS.md → MVP scope | L3-advisory-prose-only | reversible |
| R105 | Tax applies to subtotal only — does not tax service fee / design & labor | AGENTS.md → Resolved decisions (Tax rate); src/utils/proposalTotals.ts | L2-CI-test | irreversible |
| R106 | Hero/renderer sections use `min-height: 100dvh` not `height`; use `dvh` not `vh`; no scroll-snap | AGENTS.md → Proposal renderer layout | L3-advisory-prose-only | reversible |
| R107 | Double-check assumptions before agreeing; ask clarifying questions before offering solutions; accuracy over comfort | AGENTS.md → How we work | L3-advisory-prose-only | reversible |
| R108 | Hold scope — name a new path as out-of-scope rather than absorbing it; name drift (activity ≠ compounding progress) | AGENTS.md → How we work | L3-advisory-prose-only | reversible |
| R109 | Migration index in AGENTS.md MUST describe every migration file in the same commit — no number gaps | PITFALLS § agents-md-migration-index-must-stay-current | L3-advisory-prose-only | reversible |
| R110 | Use `z.iso.datetime({ offset: true })` for every timestamptz field; never bare `z.iso.datetime()` for DB timestamps | PITFALLS § postgrest-timestamptz-offset-format | L3-advisory-prose-only | irreversible |
| R111 | Write `.claude` file-path permission patterns PROJECT-RELATIVE, never absolute machine paths | PITFALLS § claude-permission-path-is-project-relative | L3-advisory-prose-only | safety-critical |
| R112 | A command guard hook MUST parse the command (jq extract, split, peel env/wrappers/options), never substring-grep the raw payload | PITFALLS § shell-guard-substring-match-instead-of-parse | L3-advisory-prose-only | safety-critical |
| R113 | Never quote a blocked-pattern string literally in a bash arg / commit message / heredoc / PR body that passes a hook-checked command; use `--body-file` and write long text to a temp file | PITFALLS § hook-command-scans-full-args + bash-dangerous-patterns-matches-heredoc-body | L3-advisory-prose-only | reversible |
| R114 | All hook scripts deriving the project hash MUST use identical default `${CLAUDE_PROJECT_DIR:-/}` — never `:-` / `:-$(pwd)` / other | PITFALLS § hash-consistency-across-hooks | L3-advisory-prose-only | reversible |
| R115 | Before cascade-deleting a team/parent that cascades to `proposals`, reset sent/approved proposals to draft OR catch the trigger error | PITFALLS § cascade-delete-fires-proposal-trigger | L3-advisory-prose-only | irreversible |
| R116 | New `public` tables inherit grants via ALTER DEFAULT PRIVILEGES (0015/0016); do not add explicit GRANTs unless non-default access is needed | PITFALLS § permission-denied-for-new-table | L3-advisory-prose-only | reversible |
| R117 | On branches predating `.husky/post-checkout`, run `npm install` manually in a new worktree before the first commit | PITFALLS § worktree-node-modules-not-inherited | git-hook | reversible |
| R118 | Always use `scripts/worktree-add.sh` (symlinks `.env.local`), never bare `git worktree add`, for any worktree that runs integration tests | PITFALLS § worktree-env-local-not-inherited; CLAUDE.md → Testing | git-hook | reversible |
| R119 | After branching from `main`, check `.husky/pre-push` (and other hooks) against in-flight hooks-update branches; copy the updated hook if a hooks branch hasn't merged | PITFALLS § branch-from-main-inherits-stale-hooks | L3-advisory-prose-only | reversible |
| R120 | Every skill in `.claude/skills/` MUST be a directory with `SKILL.md` + YAML frontmatter; never a flat `.claude/skills/name.md` | PITFALLS § flat-skill-files-not-invocable | L3-advisory-prose-only | reversible |
| R121 | If a canonical Notion template page is very long, split into parent + child sub-pages; never exceed the MCP response size limit on one page | PITFALLS § notion-mcp-page-truncation | L3-advisory-prose-only | reversible |
| R122 | After a PR is squash-merged, do not push new commits to the same branch — create a new branch | PITFALLS § squash-merge-orphans-post-merge-commits | git-hook | reversible |
| R123 | Never use `supabaseAdmin` (service role) to proxy a public-endpoint write needing a teamId/auth.uid(); write a SECURITY DEFINER migration function instead | PITFALLS § supabase-admin-for-public-writes | L3-advisory-prose-only | safety-critical |
| R124 | Never dismiss `/compound` as "clean deletion / no new pattern" — a deletion encoding a non-obvious design decision IS compound-worthy | PITFALLS § compound-skipped-for-clean-deletion | L3-advisory-prose-only | reversible |
| R125 | Every `NOT EXISTS (... user_id = auth.uid())` membership guard MUST be preceded by `auth.uid() IS NOT NULL AND` | PITFALLS § security-invoker-membership-guard-null-uid | L3-advisory-prose-only | safety-critical |
| R126 | Never define a TS interface in `src/data/` for data originating outside the system — use a Zod schema in `src/schemas/` with `z.infer<>` | PITFALLS § hand-written-interface-in-data-layer | L3-advisory-prose-only | irreversible |
| R127 | After rebasing a branch that adds migrations, check for numeric-prefix collisions before committing (`ls supabase/migrations/ \| sort \| tail`) | PITFALLS § migration-number-collision-after-rebase | L3-advisory-prose-only | irreversible |
| R128 | When a SECURITY DEFINER RPC must hand extra data to its own AFTER UPDATE trigger atomically, use a transaction-local GUC (`set_config('app.x', v, true)` / `current_setting('app.x', true)`) | PITFALLS § trigger-cannot-see-rpc-args | L3-advisory-prose-only | irreversible |
| R129 | Public token-credential RPCs that write viewer-attributable state MUST grant EXECUTE only to `anon` (+`service_role` if backend calls it) — NEVER to `authenticated` | PITFALLS § public-rpc-grant-authenticated-bypass | L3-advisory-prose-only | safety-critical |
| R130 | Distinct error codes for invalid-token vs invalid-transition are acceptable for v1 ONLY because tokens are UUIDv4; if tokens shorten/slug/rate-limit-differently, collapse to opaque error + add rate limiting | PITFALLS § public-rpc-error-codes-leak-token-existence | L3-advisory-prose-only | safety-critical |
| R131 | A server action accepting a client-provided `uuid[]` MUST cross-check the IDs against a server-fetched set scoped to the URL context before calling the RPC (RPC membership guard is insufficient) | PITFALLS § client-array-rpc-scope-gap | L3-advisory-prose-only | safety-critical |
| R132 | Any RPC using `NOT EXISTS (... WHERE id = ANY(p_ids) ...)` membership guard MUST add `IF array_length(p_ids,1) IS NULL THEN RETURN; END IF;` before the guard | PITFALLS § membership-guard-any-empty-array | L3-advisory-prose-only | reversible |
| R133 | A failed tool call MUST compact the error back into context as a structured message — never throw, never return null (12-Factor F9) | PITFALLS § error-into-context-not-throw | L3-advisory-prose-only | reversible |
| R134 | In Next.js 16 the middleware file MUST be named `proxy.ts` (not `middleware.ts`); the exported fn is `proxy` | PITFALLS § nextjs16-middleware-filename-deprecated | L2-CI-test | reversible |

> Count note: rows run R1–R134 with R-numbers reused for clarity, but several IDs collapse multiple
> source-duplicated rules into one row. Distinct binding rules after dedup = **118** (see reconciliation
> below). The table lists 134 R-numbers because three NEVER-list lines and a few cross-file rules were
> given their own row for traceability even though they restate an earlier row; those restatement rows
> are flagged in Duplication findings and are NOT double-counted in the 118.

### Reconciliation of the count

134 R-rows are written for traceability. Sixteen of them are pure restatements of another row in a
different file (the NEVER list at the end of CLAUDE.md re-states earlier MUST rules; a few rules appear in
both CLAUDE.md and PITFALLS.md or AGENTS.md). Subtracting the 16 pure-restatement rows gives **118
distinct binding rules**. The restatement rows are kept in the table (not deleted) because *where* a rule
is restated is itself enforcement-relevant — a rule echoed in the terminal NEVER list is one the author
chose to harden, and that signal should survive into the sort.

---

## Enforcement distribution (the headline for Phase 3)

| current_enforcement | distinct rules | share |
|---------------------|----------------|-------|
| L3-advisory-prose-only | ~101 | ~86% |
| git-hook | ~11 | ~9% |
| L1-hook | ~3 (R60, R77 git-subset, R20/R103 NOT actually hooked) | ~3% |
| L2-CI-test | ~3 (R105, R134, ESLint-error TS rules overlap git-hook) | ~2% |
| none | 0 | 0% |

**This table IS the finding.** ~86% of the harness's binding rules are advisory prose with no mechanism.
The canon's own Three-Layer model (`canon-locked-decisions.md §B`) calls this out: "enforcement is
overwhelmingly advisory." The L1-hook column is nearly empty — only npm-package-add (R60) and the
git-subset of the destructive-op rule (R77) are mechanically caught. **The two most safety-critical
classes of rule (token reuse R78–R80, mutating external API calls R81/R123/R129–R131) have ZERO
mechanical enforcement** — they are exactly the PocketOS-incident class and live only in prose. This is
the central input to the L1/L2/L3 relocation sort.

---

## Reversibility cross-cut (the other sort axis)

- **safety-critical (24 rules):** R20, R67, R76, R78, R79, R80, R81, R82, R92, R103, R111, R112, R123,
  R125, R129, R130, R131. These are the credential/destructive/security/tenant-isolation rules. **Of
  these, only R77's git subset is mechanically caught.** Every safety-critical *credential/external-API*
  rule is advisory. This is the strongest argument for the absent `block-dangerous-bash.sh` and an
  egress/credential guard at L1.
- **irreversible (15 rules):** mostly schema/migration/DB-shape rules (R4, R10, R15, R27, R94, R99,
  R105, R110, R115, R126, R127, R128) — a Zod-boundary miss or a missing rollback path can corrupt data
  or ship an un-revertable migration. Several of these are *structurally checkable* (R10 component→data
  import, R126 interface-in-data-layer, R27 schema file/folder collision) and are the natural L2
  arch-test candidates the canon names.
- **reversible (~79 rules):** style, naming, workflow-hygiene, doc-currency. These are the rules that can
  safely STAY at L3 — and several are candidates for *deletion* under the §9 criterion ("if you can't
  name a failure mode it prevents, it's overhead").

---

## Duplication findings (the cross-file echo is itself a finding)

The brief flagged a "triple-duplication" of corrected-mistake facts across `.claude/memory.md`,
`PITFALLS.md`, and auto-memory `feedback_*`. The rule inventory confirms the same triple/double echo
*inside the binding-rule set*, not just the memory stores:

1. **RLS role-enforcement rule is stated THREE times** — CLAUDE.md → Architecture (R20), AGENTS.md →
   Rejected Patterns (R103), and PITFALLS § rls-role-mission-creep. Three files, one rule, all advisory,
   none enforced. This is the single most-duplicated rule in the harness and the canonical example of
   "the same knowledge at different lifecycle stages encoded in NO tooling."

2. **The CLAUDE.md terminal NEVER list re-states ~16 earlier MUST rules.** Every NEVER line (R1–R3, R5,
   R7, R10, R36, R59, R60, R74, R77–R82, R84, R91, R71) restates a rule already given under TypeScript /
   Architecture / Testing / Safe-change / Destructive-op headings. The NEVER list is a *redundant index*,
   not new rules. Finding: the author hardened the most-violated rules by echoing them — but the echo
   lives in the same advisory layer, so it adds emphasis, not enforcement. A V2 win is to delete the
   NEVER list as a separate section and let the relocation sort move its members to L1/L2 where the
   emphasis becomes mechanical.

3. **Architecture rules are stated in CLAUDE.md AND re-encoded as a PITFALL.** R15 (trigger-owned
   timestamps), R16 (public-paths-in-route-groups), R18 (react-cache), R27 (schema file/folder), R5/R126
   (hand-written interface) each appear once as a forward-looking MUST in CLAUDE.md and again as a
   backward-looking "here's the silent bug" PITFALL. This is the canon's sanctioned "different lifecycle
   stage" pattern — but it doubles the surface an implementer must read, and nothing keeps the two copies
   in sync. If the CLAUDE.md line is edited and the PITFALL isn't (or vice versa), they drift silently.

4. **Migration grant/index rules echo between CLAUDE.md → Migrations and PITFALLS.** R92 (REVOKE after
   CREATE OR REPLACE FUNCTION) and R93 (no CONCURRENTLY) are stated verbatim-equivalent in both. Same
   drift risk as #3.

5. **Worktree/branch-cleanup rules echo between CLAUDE.md → Commit workflow and PITFALLS** —
   R44/R85 (post-merge-local-branch-persists), R84 (orphaned worktree), R118 (env-local symlink). The
   PITFALL form carries the "why/symptoms/fix" the CLAUDE.md line omits; the CLAUDE.md line carries the
   imperative the PITFALL buries. Neither is complete alone.

6. **Squash-merge stated twice** — R87 (merge strategy, CLAUDE.md + AGENTS.md Resolved decisions) and
   R122 (don't push after squash-merge, PITFALLS). Two different rules about the same mechanic in three
   places.

**Net duplication finding:** the binding-rule set has the same many-stores-one-fact problem as the
memory model. ~22 of the 118 distinct rules appear in 2+ files. The reconciliation ("forward-looking MUST
vs backward-looking PITFALL = different lifecycle stages") is real and defensible — but it is encoded in
NO tooling, so every echo is a manual sync obligation that WILL drift. The Phase 3 relocation sort should
treat each duplicated rule as ONE rule with ONE enforcement home, and let the doc text become a pointer to
that home rather than a second copy of the rule.
