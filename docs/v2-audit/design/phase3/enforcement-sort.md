# Enforcement Sort — every rule into the Three-Layer Model (Phase 3)

**Input:** `rule-inventory.md` (R1–R134, 118 distinct binding rules), `capability-facts.md` (what hooks
can actually enforce), `canon-locked-decisions.md §B` (Three-Layer model). Disk-re-verified 2026-06-11
against `.claude/hooks/`, `.husky/`, `eslint.config.mjs`, `.github/workflows/ci.yml`, `package.json`,
`.gitignore`.

**The sort's job (canon §B verbatim):** "move as many rules DOWN to L1/L2 as possible so L3 holds only
what genuinely needs judgment." Every L1/L2 assignment carries a one-line **failure mode** (the §9
deletion criterion: *no nameable failure mode → demote or delete*). The keep-verbatim safety floor stays
(mostly L1; tier-1 L3 where not mechanizable). This is enforcement-RELOCATION, not new files for their
own sake — the net new build is **3 hooks + 1 arch-test rig + 2 placement fixes**, and they *absorb*
~30 advisory rules.

---

## Definitions used in the TARGET-LAYER column

- **L1** — deterministic hook. Either a `.claude/hooks/*.sh` PreToolUse exit-2 guard (agent-only, fires
  on a Claude tool call) and/or a `.husky/` git hook + ESLint-error (humans AND agents). Binary. The
  *strongest* L1 is BOTH (PreToolUse for the agent's pre-write moment + a git/CI gate that also catches a
  human). Canon §B: "Husky pre-commit (humans) + PreToolUse settings.json (agents), same rules."
- **L2** — architecture test (`dependency-cruiser` in CI). Runs every CI run, every commit, every
  developer — *unlike* a PreToolUse hook that only fires on an agent tool call. The home for
  import/layer-boundary rules that are structurally checkable but not a one-command lint rule.
- **L3** — probabilistic judgment. Stays in prose because it genuinely needs a model's reading of intent,
  taste, or context. **Tier-1 L3** = no-trigger safety content that loads every session (keep-verbatim
  floor); **tiered L3** = path-scoped, loaded only when working in the matching area (the absent
  `.claude/rules/` mechanism — `capability-facts.md`).
- **DELETE** — §9: no nameable failure mode it prevents → it is overhead. Demote-or-delete.
- **current-enforcement** column carries the inventory's disk-verified value (`git-hook` = Husky/ESLint
  already; `L1-hook` = an existing PreToolUse guard already catches it; `L3` = advisory prose only).

A note on what "relocate" means here: most rows are *currently* L3-advisory. "relocate" = this sort moves
them to L1 or L2. "keep" = stays L3 by design (judgment or already-enforced). "demote" = drop emphasis /
fold into another rule. "DELETE" = remove the standing rule.

---

## The 5 directed resolutions (cited), applied across the table below

**(a) What the absent `block-dangerous-bash.sh` absorbs.** Built exactly like `block-dangerous-git.sh`
(`capability-facts.md`: "buildable exactly like the existing two"; PreToolUse exit-2; the existing guard
already *parses* command segments, strips env/wrappers/options — the correct model, NOT substring-grep,
which is R112). ONE unified PreToolUse(Bash) guard absorbs the bash-shaped half of **R77** (the
destructive-op denylist) plus the boundary/egress rules that are bash-observable:
- `rm -rf`, volume deletes — R77.
- destructive SQL via psql/`supabase ... execute`/heredoc — R77 (DB half), supports R94/R115.
- boundary writes to `.git/`, `.husky/`, `.claude/` (settings.json, hooks, guard files) — enforces the
  "no agent edits to guard files" standing rule [anti-phantom §E] and protects R111/R112/R114 from the
  agent rewriting its own guards.
- `curl`/`wget`/`fetch` to a non-allowlisted host (egress) — the operation-granularity egress floor
  [MASTER-FINDINGS MOVE 2, C4-G2/C4-G10]; mechanizes the bash-observable slice of R81.
- deploy commands (`vercel deploy --prod`, `supabase db push`, `gh release create`) — R77's "irreversible
  external mutation" class.
This is the **most-cited single gap** [MASTER-FINDINGS MOVE 2; map §3e/§5]. It does NOT absorb
credential-*reuse* (R78–R80): a hook cannot read the agent's intent about *which* token it grabbed or
*why* — that stays L3 tier-1 (see resolution-note below). It DOES absorb the bash-observable *use* of a
credential in a destructive/egress command.

**(b) `.cr-ok` → CI relocation (the forgeable stop authority).** Disk-confirmed today: `.cr-ok` is
gitignored (`.gitignore:58`), validated only by `.husky/pre-push` (lines 56–72, model-reachable, local)
and consumed by `scripts/pr.sh`. **It never reaches CI** — `ci.yml` runs tsc/eslint/test:unit and never
checks the sentinel. The model writes `.cr-ok` itself, so the stop authority is **forgeable on disk**
[_EMERGING-FINDINGS R-1; MASTER-FINDINGS MOVE 2; Node 8.5c]. **New stop authority = `MUST-FIX=0 AND
CI-required-checks-green on the sentinel SHA`, enforced in branch-protection where the model can't compute
it.** This re-homes **R66/R68/R69** from a local sentinel (L1-local, forgeable) to **L1-CI/branch-
protection (unforgeable)**. Caveat carried from the source: this is a *coverage-bounded* oracle (it buys
regression-trust, not correctness-trust) and MUST NOT itself become a capability unlock [MASTER-FINDINGS
MOVE 1 constraint].

**(c) `/cr-security` path/glob classifier.** Today R67 is prose: "if any commit touched auth/middleware/
RLS, run `/cr-security`." A glob classifier on the branch diff (`proxy.ts`, `**/middleware*`,
`src/data/**` auth paths, any `supabase/migrations/**` touching `POLICY`/`RLS`/`SECURITY DEFINER`)
**forces** the security pass — failing the gate if the security review didn't run on a matching diff.
This is the absent `enforce-scope.sh` slice [MASTER-FINDINGS MOVE 2, C2-G10; map §5]. Home: a CI job that
diffs `origin/main...HEAD`, and/or a SubagentStop/Stop check. Relocates **R67** L3→L1-CI.

**(d) Layer-boundary rules → `dependency-cruiser` L2.** `dependency-cruiser` is confirmed absent from
`package.json` (re-verified). It is the canon's named L2 mechanism (`canon §B`: "^src/components may not
import ^src/data"). It runs every CI run for every developer. Absorbs the *import-shaped* architecture
rules: **R9, R10, R11, R19, R24, R25, R27, R126** (and the import-cycle rule already at ESLint
`import/no-cycle`). These are structurally checkable and several are irreversible (R10, R126) — the
strongest L2 case.

**(e) autoMode placement fix.** Disk: the autoMode block IS in committed `.claude/settings.json:6-32`
(added #99) but **`autoMode` is "Not read from shared project settings" by design** (`capability-facts.md`)
— so it is *ignored at runtime*; unattended `/queue` runs use bare defaults. This is a placement bug, not
an absence. Fix: move autoMode to `settings.local.json` (personal, honored) or `managed-settings.json`
(enforced, agent-unreachable — the deterministic floor both canon and disk lack). **Forbidden:** the agent
editing settings.json/guard files itself [anti-phantom §E "no agent edits to guard files"] — prepare +
surface paste-ready for a human. This is a one-time placement relocation, not a per-rule sort row; it is
listed in the "new builds" summary.

---

## Full sort table

Legend — TARGET: `L1` deterministic hook · `L1-CI` CI/branch-protection gate · `L2` arch-test · `L3-1`
tier-1 always-loaded L3 (safety floor) · `L3` tiered/judgment L3 · `DELETE`. VERDICT: relocate / keep /
demote / DELETE.

| id | rule (abbrev) | source | current | TARGET | mechanism | failure-mode-prevented | verdict |
|----|----|----|----|----|----|----|----|
| R1 | no `any` | CLAUDE/TS | git-hook | L1 | ESLint `no-explicit-any` error + pre-commit + CI | untyped boundary value flows in unchecked → runtime shape error | keep (already L1) |
| R2 | no `@ts-ignore`/`@ts-expect-error` | CLAUDE/TS | L3 | L1 | add ESLint `@typescript-eslint/ban-ts-comment` error | suppressed type error ships a real type bug silently | **relocate** |
| R3 | no `as` without preceding narrowing | CLAUDE/TS | L3 | L3 | judgment — "preceding narrowing exists" is semantic | a cast masks a wrong type; needs reading the narrowing | keep |
| R4 | Zod schema for all boundary data | CLAUDE/TS | L3 | L3 | judgment — "is this a boundary?" needs intent | unvalidated external data corrupts state (irreversible) | keep (tier per-path L3) |
| R5 | derive types via `z.infer`, no dup shape | CLAUDE/TS, PITFALLS | L3 | L2 | dependency-cruiser/custom rule: no hand-written interface mirroring a schema in `src/data` (= R126) | schema and interface drift; validation passes, type lies | **relocate** (folds into R126) |
| R6 | props = named interface | CLAUDE/TS | L3 | L1 | ESLint rule (no inline object type on a component prop) — *if* a clean rule exists; else L3 | inline prop types resist reuse | **relocate** (verify lint rule exists; else keep L3) |
| R7 | components are I/O only, no business logic | CLAUDE/Arch | L3 | L3 | judgment — "is this business logic?" is semantic | logic in components becomes untestable | keep |
| R8 | business logic in pure functions outside components | CLAUDE/Arch | L3 | L3 | judgment (dual of R7) | untestable logic; no unit coverage | keep |
| R9 | Supabase queries only in `src/data/` | CLAUDE/Arch | L3 | L2 | dependency-cruiser: only `src/data/**` may import the supabase client | a stray query bypasses Zod validation + RLS assumptions | **relocate** |
| R10 | never call Supabase client from component/page/layout | CLAUDE/Arch | L3 | L2 | dependency-cruiser: `^src/(components\|app)` may not import supabase client | direct client call skips data-layer validation (irreversible data risk) | **relocate** |
| R11 | server components/actions call `src/data/` directly | CLAUDE/Arch | L3 | L2 | dependency-cruiser (inverse boundary of R9/R10) | bypassing data layer duplicates query logic | **relocate** |
| R12 | split a function that does two things | CLAUDE/Arch | L3 | L3 | judgment — "two distinct things" is taste | none nameable mechanically | keep |
| R13 | no shared abstraction before 3rd occurrence | CLAUDE/Arch | L3 | L3 | judgment (rule-of-three) | premature wrong abstraction | keep |
| R14 | write minimum code, no speculative future | CLAUDE/Arch | L3 | L3 | judgment | speculative code = debt | keep |
| R15 | status transitions use BEFORE/AFTER triggers not app code | CLAUDE/Arch, PITFALLS | L3 | L3 | judgment — "needs a server timestamp/atomic audit" is semantic | app-layer timestamp races; non-atomic audit (irreversible) | keep (tier per migration path) |
| R16 | PUBLIC_PATHS pages at root route, not in a group | CLAUDE/Arch, PITFALLS | L3 | L1-CI | CI grep/test: every `PUBLIC_PATHS` entry maps to `app/<path>/page.tsx` not inside `(group)/` | page is auth-gated despite being "public" → broken public link | **relocate** |
| R17 | every route group + layout level has `error.tsx` | CLAUDE/Arch | L3 | L1-CI | CI test: each `(group)/`/layout dir contains `error.tsx` | unhandled throw → raw 500, no nav/recovery | **relocate** |
| R18 | shared layout+page data wrapped in `cache()` | CLAUDE/Arch, PITFALLS | L3 | L3 | judgment — "called from both in same request" needs call-graph reading | duplicate DB round-trips per request | keep (consider L2 custom rule later) |
| R19 | actions.ts imports `src/` via relative path (`@/` = src only) | CLAUDE/Arch | git-hook | L1/L2 | tsc resolves the path already (git-hook); dependency-cruiser can assert no `@/` from `app/**` actions | build break (already caught by tsc) | keep (already L1 via tsc) |
| R20 | RBAC enforced in `src/data/` TS layer only, never RLS | CLAUDE/Arch, AGENTS, PITFALLS | L3 | L3-1 | judgment — "is this a role check in a policy?" semantic; tier-1 safety | role logic in RLS = the rejected pattern; tenant-isolation regression (safety-critical) | keep (tier-1; **dedup R103**) |
| R21 | page/layout/loading default export; others named | CLAUDE/File | git-hook | L1 | ESLint/tsc already (Next requires it) | broken Next route | keep (already L1) |
| R22 | utilities/data/schemas/types named export | CLAUDE/File | git-hook | L1 | ESLint `import/no-default-export` (scoped) | inconsistent imports; refactor friction | keep (already L1) |
| R23 | file-naming case conventions | CLAUDE/File | L3 | L2 | dependency-cruiser/custom CI: filename-pattern per directory | inconsistent casing breaks case-sensitive CI/imports | **relocate** (cheap CI glob check) |
| R24 | shared types in `src/types/`, import `@/types/...` | CLAUDE/File | L3 | L2 | dependency-cruiser: cross-`app`/`src` types resolve to `src/types` | type duplication across boundaries | **relocate** |
| R25 | `@/` = src; never `@/src/...` | CLAUDE/File | git-hook | L1 | tsc path resolution (already) | unresolved import = build break | keep (already L1) |
| R26 | discriminated payloads in `schemas/<domain>/<literal>.ts` | CLAUDE/File | L3 | L3 | judgment — folder taxonomy needs intent | mis-filed schema; minor | keep (or demote) |
| R27 | never both `schemas/<domain>.ts` AND `<domain>/` | CLAUDE/File, PITFALLS | L3 | L1-CI | CI test: no file+dir name collision under `src/schemas` | TS silently resolves the file; later index.ts shadows it (irreversible-surprise) | **relocate** |
| R28 | no comment describing what code does | CLAUDE/Style | L3 | L3 | judgment — "describes what vs why" is semantic | noise comments; low harm | keep (DELETE candidate — see note) |
| R29 | comment only when WHY non-obvious, 1 line | CLAUDE/Style | L3 | L3 | judgment | over-commenting | keep (DELETE candidate) |
| R30 | no multi-line comment blocks/docstrings | CLAUDE/Style | L3 | L1 | ESLint `multiline-comment-style`/custom — *if* clean; else DELETE | docstring noise; near-zero failure mode | demote (lint if trivial, else DELETE) |
| R31 | use `cn()` for conditional Tailwind merge | CLAUDE/Style | L3 | L3 | judgment — "conditional merge" detection is fuzzy | class-merge precedence bug | keep |
| R32 | never concatenate Tailwind strings manually | CLAUDE/Style | L3 | L3 | judgment | duplicate/conflicting classes | keep (pairs with R31) |
| R33 | colocate test files | CLAUDE/Test | L3 | L1-CI | CI test: every `src/**/{data,schemas,utils}` fn file has a sibling `*.test.ts` (overlaps R34) | orphaned/missing tests go unnoticed | **relocate** |
| R34 | unit tests for all pure fns in data/schemas/utils | CLAUDE/Test | L3 | L1-CI | CI coverage/file-pairing test (same mechanism as R33) | untested pure fn ships a logic bug | **relocate** |
| R35 | integration tests hit real Supabase | CLAUDE/Test | L3 | L3 | judgment — "is this a data-access fn needing integration?" semantic; partly enforced by pre-push `npm run test` hitting real DB | mocked DB hides RLS/constraint bugs | keep (pre-push already exercises real DB) |
| R36 | never mock the database | CLAUDE/Test | L3 | L1 | ESLint custom: ban `vi.mock` on the supabase client path | mocked DB = false-green integration test | **relocate** |
| R37 | no snapshot tests | CLAUDE/Test | L3 | L1 | ESLint custom: ban `toMatchSnapshot`/`toMatchInlineSnapshot` | brittle snapshots rot; reviewers rubber-stamp | **relocate** |
| R38 | TDD: test first, must fail, for new pure fns | CLAUDE/Dev | L3 | L3-1 | judgment — "test existed before impl" needs history reading; keep-verbatim floor (tracer-bullet-first) | implementation-shaped tests that can't fail | keep (tier-1, **keep-verbatim**) |
| R39 | refactor: characterization test before moving a symbol | CLAUDE/Dev | L3 | L3-1 | judgment; keep-verbatim (tests-before-movement) | silent behavior change during a move | keep (tier-1) |
| R40 | two hats: structure ≠ behavior in same commit | CLAUDE/Dev | L3 | L3 | judgment — "did behavior change?" semantic | bug smuggled inside a "refactor" commit | keep |
| R41 | answer 3 discipline questions before commit | CLAUDE/Discipline | L3 | L3-1 | judgment; keep-verbatim (3 questions) | committing code the author can't reason about | keep (tier-1, **keep-verbatim**) |
| R42 | read `.claude/memory.md` at session start | CLAUDE/top | L3 | L1 | `session-start.sh` hook injects/echoes it (hook EXISTS) | corrected-mistake repeats because memory unread | **relocate** (wire existing session-start.sh) |
| R43 | session-start: read memory/TASKS/rituals/SOUL; surface stale ritual | CLAUDE/top | L3 | L1 | `session-start.sh` + ritual-clock (MOVE 1 heartbeat) | rituals never fire (no clock) — _EMERGING #1 | **relocate** (the missing heartbeat) |
| R44 | session-start: fetch --prune + gc.sh if gone branches | CLAUDE/top, PITFALLS | L3 | L1 | `session-start.sh` runs `git fetch --prune` + branch-gone check | merged branches accumulate silently | **relocate** (into session-start.sh) |
| R45 | classify work-state on first message | CLAUDE/top | L3 | L3 | judgment — pure reasoning act | unscoped work; mis-framed task | keep |
| R46 | corrected mistake → add rule to memory.md before session end | CLAUDE/top | L3 | L1 | Stop/SubagentStop emitter proposes a memory write-back (MOVE 1) | the half-open write loop — learning lost at session end | **relocate** (MOVE 1 emitter) |
| R47 | confirm own worktree before first commit | CLAUDE/top | L3 | L1 | pre-commit guard: block commit at repo root if uncommitted unrelated work + agent context | two sessions bundle each other's changes | **relocate** (worktree-create.sh exists; extend) |
| R48 | sessions must not share a branch | CLAUDE/top | L3 | L3 | judgment — cross-session state not observable in one hook | merge conflicts; lost work | keep (partly covered by R47) |
| R49 | skim `docs/solutions/README.md` before designing | CLAUDE/before | L3 | L3 | judgment | re-solve a solved problem | keep (tiered — load on design tasks) |
| R50 | skim `docs/adr/README.md` before designing | CLAUDE/before | L3 | L3 | judgment | violate a locked decision | keep (tiered) |
| R51 | read `PITFALLS.md` before writing in affected area | CLAUDE/before | L3 | L3 | judgment; path-scoped `.claude/rules/` is the native tiering | re-hit a known trap | keep (tier via `.claude/rules/` paths) |
| R52 | touch Supabase → invoke `/supabase` | CLAUDE/before, Migr | L3 | L1 | skill `paths:` frontmatter auto-activates on `supabase/**`/data paths (`capability-facts.md`) | migration ships an RLS/grant gotcha | **relocate** (skill paths trigger) |
| R53 | touch Vercel → invoke `/vercel-react-best-practices` | CLAUDE/before | L3 | L1 | skill `paths:` on `next.config.ts`/`vercel.json` | misconfigured deploy/build | **relocate** (skill paths) |
| R54 | "/notion-sync" → invoke `/notion-sync` | CLAUDE/before | L3 | L3 | user-typed command already routes the skill | n/a — restates how skills work | demote (redundant with skill routing) |
| R55 | `/debug` → invoke `/debug` | CLAUDE/before | L3 | L3 | user-typed command routes it | n/a — restatement | demote (redundant) |
| R56 | unknown bug cause → invoke `/debug` before any fix | CLAUDE/before | L3 | L3 | judgment — "is the cause unknown?" semantic | guess-fix masks root cause | keep |
| R57 | define inputs/outputs/must-not/done before starting | CLAUDE/before | L3 | L3-1 | judgment; keep-verbatim-adjacent (the 4 definitions) | ambiguous task → wrong build | keep (tier-1) |
| R58 | confirm task fits MVP scope | CLAUDE/before | L3 | L3 | judgment | scope creep | keep (pairs with R91/R104) |
| R59 | surface open decisions; never resolve unilaterally | CLAUDE/before, AGENTS | L3 | L3-1 | judgment; keep-verbatim-adjacent | a locked decision silently decided | keep (tier-1) |
| R60 | ask before installing any npm package | CLAUDE/before | L1-hook | L1 | `block-npm-install.sh` (exit 2) — EXISTS | unvetted dependency / supply-chain | keep (already L1) |
| R61 | ambiguous task → ask first | CLAUDE/before | L3 | L3 | judgment | wrong build from a guess | keep |
| R62 | honest assessment over validation | CLAUDE/principles | L3 | L3 | judgment — the core agent disposition | sycophantic review misses real problems | keep |
| R63 | research before guessing | CLAUDE/principles | L3 | L3 | judgment | confident wrong answer | keep |
| R64 | 3-pass research for deep unknowns | CLAUDE/principles | L3 | L3 | judgment | shallow read dressed as analysis | keep |
| R65 | update the relevant doc in the same commit | CLAUDE/docs | L3 | L1-CI | drift detector (MOVE 3 `/scan-context`): pattern changed but doc untouched | doc rots → doc-fiction (live failure class) | **relocate** (drift check) |
| R66 | run `/cr` before pushing; auto-fix MUST FIX | CLAUDE/ship | git-hook | L1-CI | **(b)** stop authority → `MUST-FIX=0 AND CI-green on sentinel SHA` in branch-protection | unforgeable gate (today: model writes its own `.cr-ok`) | **relocate** (forgeable→CI) |
| R67 | auth/middleware/RLS commit → run `/cr-security` | CLAUDE/ship | L3 | L1-CI | **(c)** path/glob classifier on the diff forces the security pass | a security-relevant diff merges unreviewed (safety-critical) | **relocate** |
| R68 | never push/PR without `/cr`; `.cr-ok` must match branch:sha | CLAUDE/ship | git-hook | L1-CI | **(b)** same as R66 — sentinel validated in CI, not just local pre-push | forgeable local sentinel | **relocate** (dedup with R66/R69) |
| R69 | open PRs via `scripts/pr.sh` (consumes `.cr-ok`) | CLAUDE/ship, PITFALLS | git-hook | L1-CI | **(b)** branch-protection makes pr.sh's check unforgeable | bypass pr.sh → unreviewed PR | **relocate** (dedup with R66/R68) |
| R70 | surface PR URL after open/update | CLAUDE/ship | L3 | L3 | judgment / cheap output convention | minor UX gap | keep (or demote) |
| R71 | bg agent needs all Bash patterns in `permissions.allow` first | CLAUDE/ship, NEVER | L3 | L1-CI | CI/precheck: validate `permissions.allow` covers a spawned agent's declared commands | bg agent fails silently (no prompt) — real incident class | **relocate** (precheck) |
| R72 | never modify `next.config.ts` without explaining first | CLAUDE/safe | L3 | L1 | `block-dangerous-bash.sh` boundary-write rule flags edits to config files → require explanation | silent config change breaks build/security | **relocate** (boundary half) — judgment half stays L3 |
| R73 | never modify `tsconfig.json` without explaining first | CLAUDE/safe | L3 | L1 | same boundary guard as R72 | silent tsconfig change weakens type safety | **relocate** (boundary half) |
| R74 | never silently delete a file — flag + ask | CLAUDE/safe, NEVER | L3 | L3 | judgment — "is this dead code?" semantic | losing live code | keep (subtractive-enforcement home, MOVE 3 `/simplify`) |
| R75 | Storage images → add domain to `images.remotePatterns` | CLAUDE/safe, AGENTS | L3 | L1-CI | CI test: every supabase storage host used resolves in `remotePatterns` | broken image / next/image throws at runtime | **relocate** |
| R76 | redirect from user input: only `resolved.pathname` | CLAUDE/safe | L3 | L2 | dependency-cruiser/ESLint custom: ban `.search`/`.hash` append on a redirect built from input | open-redirect / XSS (safety-critical) | **relocate** |
| R77 | never destructive/irreversible op without explicit same-turn instruction | CLAUDE/Destructive, NEVER | L1-hook (git only) | L1 | **(a)** `block-dangerous-bash.sh` extends coverage from git-only to rm/SQL/deploy/curl/boundary | irreversible data/infra loss (PocketOS class) | **relocate/extend** (**keep-verbatim**) |
| R78 | never reuse a token found in an unrelated file | CLAUDE/Destructive, NEVER | L3 | L3-1 | judgment — a hook can't read *why* a token was grabbed; tier-1 keep-verbatim | credential reuse = the PocketOS incident (safety-critical) | keep (tier-1, **keep-verbatim**) |
| R79 | never assume a token is scoped — treat all as root | CLAUDE/Destructive, NEVER | L3 | L3-1 | judgment; tier-1 keep-verbatim | over-trusting a token → cross-env blast | keep (tier-1) |
| R80 | never treat "staging" as isolated without verifying boundary | CLAUDE/Destructive | L3 | L3-1 | judgment; tier-1 keep-verbatim | prod mutation via "staging" token | keep (tier-1) |
| R81 | before any mutating external API call, state target/reversibility, confirm | CLAUDE/Destructive, NEVER | L3 | L1+L3-1 | **(a)** bash-observable curl/mutation half → hook; the *state-and-confirm* reasoning stays tier-1 L3 | unconfirmed external mutation (safety-critical) | **relocate (bash half) + keep (judgment, tier-1)** |
| R82 | if you can't answer "reversible?", treat as irreversible + stop | CLAUDE/Destructive | L3 | L3-1 | judgment; tier-1 keep-verbatim | proceeding on an unknown-irreversible op | keep (tier-1) |
| R83 | only commit/push this conversation's changes; else worktree | CLAUDE/commit | L3 | L1 | pre-commit guard (same as R47): block bundling unrelated working-tree changes | another task's changes shipped in your commit | **relocate** (pairs with R47) |
| R84 | remove worktree when done; never orphan | CLAUDE/commit, NEVER | L3 | L3 | judgment — "task done" not hook-observable; a stale-worktree ritual can sweep | orphaned worktrees block branch deletion | keep (sweep via ritual/heartbeat) |
| R85 | after merge: delete local branch + prune (confirm merged) | CLAUDE/commit, PITFALLS | L3 | L1 | session-start.sh `gc.sh` (= R44) sweeps gone branches | merged branches accumulate | **relocate** (dedup with R44) |
| R86 | conventional commits; body required | CLAUDE/commit | L3 | L1 | commit-msg hook (commitlint) — net-new git hook | malformed history; broken changelog/tooling | **relocate** |
| R87 | squash merge, one commit per logical change | CLAUDE/commit, AGENTS | L3 | L1-CI | GitHub repo setting: squash-only merge button | merge-commit noise on main | **relocate** (repo setting, not a rule) |
| R88 | no unrelated changes in one commit | CLAUDE/commit | L3 | L3 | judgment — "unrelated" is semantic | tangled commit; hard to revert | keep |
| R89 | before finishing: tsc clean, no dead code, no silent decisions | CLAUDE/finish | git-hook | L1 | tsc (pre-commit/CI) + ESLint `no-unused-vars`; the "silent decision" half stays L3 | type errors / dead code ship | keep (already L1; decision-half L3) |
| R90 | no Redux/React Query/class components/CSS modules | CLAUDE/stack, AGENTS | L3 | L1 | dependency-cruiser/ESLint: ban imports of `redux`/`@tanstack/react-query`; ban `.module.css` | a deferred/forbidden dep enters the tree | **relocate** |
| R91 | never expand scope without surfacing it | CLAUDE/NEVER, AGENTS | L3 | L3-1 | judgment; tier-1 (the scope discipline) | silent scope creep | keep (tier-1; dedup with R58/R108) |
| R92 | every CREATE OR REPLACE FUNCTION → REVOKE EXECUTE FROM PUBLIC | CLAUDE/Migr, PITFALLS | L3 | L1-CI | CI test over `supabase/migrations/**`: each `CREATE OR REPLACE FUNCTION` has a matching REVOKE | function callable by any role (safety-critical) | **relocate** |
| R93 | no `CONCURRENTLY` in a migration; use IF NOT EXISTS | CLAUDE/Migr, PITFALLS | L3 | L1-CI | CI grep over migrations: fail on `CONCURRENTLY` | migration aborts (CLI wraps in a txn) | **relocate** |
| R94 | destructive migration ops need a documented rollback path | CLAUDE/Migr | L3 | L3 | judgment — "is the rollback documented and correct?" semantic | un-revertable schema change (irreversible) | keep (tier per migration path) |
| R95 | before any migration, invoke `/supabase` | CLAUDE/Migr | L3 | L1 | skill `paths:` on `supabase/migrations/**` (= R52) | migration ships a known gotcha | **relocate** (dedup with R52) |
| R96 | UI work references design tokens/components first | AGENTS/design | L3 | L3 | judgment | off-system component | keep (tier on component paths) |
| R97 | every component conforms to design-file patterns | AGENTS/design | L3 | L3 | judgment | inconsistent UI | keep (pairs with R96) |
| R98 | flag single-vendor assumptions before 2nd vendor | AGENTS/target | L3 | L3 | judgment | hardcoded assumption blocks multi-tenant | keep |
| R99 | `src/data/` validates with Zod before returning | AGENTS/data | L3 | L3 | judgment — "did it validate?" partly checkable but semantic; pairs with R4 | unvalidated row returned typed (irreversible) | keep (consider L2 custom rule) |
| R100 | read the golden-exemplar file for the layer first | AGENTS/exemplars | L3 | L3 | judgment | inconsistent new file | keep (tiered per layer) |
| R101 | use `next/image` for all images | AGENTS/images | L3 | L1 | ESLint `@next/next/no-img-element` (error) | unoptimized images; LCP regression | **relocate** |
| R102 | ticket on unresolved open decision can't run until resolved | AGENTS/decisions | L3 | L3 | judgment | building on an undecided fork | keep (pairs with R59) |
| R103 | never add role conditions to RLS | AGENTS/Rejected, PITFALLS, CLAUDE | L3 | L1-CI | CI test over migrations: RLS policies reference only `private.team_ids()`, no role checks | role logic in RLS = rejected pattern (safety-critical) | **relocate** (mechanizes the R20/R103 dedup) |
| R104 | MVP out-of-scope items not built in v1 | AGENTS/scope | L3 | L3 | judgment | scope creep into deferred features | keep (pairs with R58) |
| R105 | tax on subtotal only, not service/design-labor | AGENTS/resolved, util | L2-CI-test | L2 | existing unit test on `proposalTotals.ts` (already enforced) | wrong invoice total (irreversible client-facing) | keep (already L2) |
| R106 | hero uses `min-height:100dvh`/`dvh`, no scroll-snap | AGENTS/renderer | L3 | L1 | ESLint/stylelint custom: ban `100vh`/`height` on renderer sections | mobile viewport clipping | **relocate** (if clean rule; else keep) |
| R107 | double-check assumptions; ask before solutions | AGENTS/work | L3 | L3 | judgment | premature wrong solution | keep |
| R108 | hold scope; name drift | AGENTS/work | L3 | L3 | judgment | scope creep; activity≠progress | keep (dedup with R91) |
| R109 | AGENTS migration index describes every migration, no gaps | PITFALLS | L3 | L1-CI | CI test: every `supabase/migrations/*` file has an AGENTS.md index entry | stale index → orientation rot | **relocate** |
| R110 | `z.iso.datetime({offset:true})` for every timestamptz | PITFALLS | L3 | L2 | dependency-cruiser/ESLint custom: flag bare `z.iso.datetime()` in `src/schemas` | PostgREST `+00:00` rejected by strict Z → parse failure (irreversible-feeling) | **relocate** |
| R111 | `.claude` permission patterns project-relative, not absolute | PITFALLS | L3 | L3-1 | judgment — guard-file content; humans only edit these | absolute path → permission never matches (safety-critical) | keep (tier-1; guard-file = human-only) |
| R112 | command guard hooks must PARSE, not substring-grep | PITFALLS | L3 | L3-1 | judgment — meta-rule about hook authoring; humans only | a forgeable guard (the whole point of L1) — safety-critical | keep (tier-1, **keep-verbatim**) |
| R113 | never quote a blocked pattern literally in a hook-checked arg; use `--body-file` | PITFALLS | L3 | L3 | judgment — workaround technique | false-positive hook block on a legit commit/PR | keep (tiered with hook work) |
| R114 | all hooks use identical `${CLAUDE_PROJECT_DIR:-/}` default | PITFALLS | L3 | L3-1 | judgment — meta-rule on hook authoring; humans only | hash mismatch silently disables a guard (safety-critical) | keep (tier-1) |
| R115 | reset sent/approved proposals before cascade-delete | PITFALLS | L3 | L3 | judgment — operational sequencing | cascade fires proposal trigger → error/loss (irreversible) | keep (pairs with R77 SQL guard) |
| R116 | new tables inherit grants; don't add explicit GRANTs | PITFALLS | L3 | L3 | judgment | redundant/over-broad grant | keep (tier per migration) |
| R117 | run `npm install` in new worktree before first commit (pre-post-checkout branches) | PITFALLS | git-hook | L1 | `.husky/post-checkout` runs it (EXISTS) | missing node_modules → false test failure | keep (already L1 on current branches) |
| R118 | always use `scripts/worktree-add.sh` (symlinks `.env.local`) | PITFALLS, CLAUDE | git-hook | L1 | pre-push checks `.env.local` presence (EXISTS); worktree-create.sh symlinks | integration tests can't run; push blocked | keep (already L1) |
| R119 | check pre-push against in-flight hook branches after branching | PITFALLS | L3 | L3 | judgment — cross-branch awareness | stale hook silently weaker | keep (rare; demote candidate) |
| R120 | every skill is a dir with SKILL.md + frontmatter, never flat `.md` | PITFALLS | L3 | L1-CI | CI test: no `.claude/skills/*.md` at top level; each skill dir has SKILL.md + valid frontmatter | flat skill file is not invocable (silent) | **relocate** |
| R121 | split long Notion template pages to avoid MCP truncation | PITFALLS | L3 | L3 | judgment — operational | truncated canonical page | keep (demote candidate — niche) |
| R122 | after squash-merge, don't push to same branch — new branch | PITFALLS | git-hook | L1 | pre-push `gh pr list --state merged` check (EXISTS) | commits orphaned on a merged branch | keep (already L1) |
| R123 | never use `supabaseAdmin` for a public write needing teamId/auth.uid | PITFALLS | L3 | L2 | dependency-cruiser: `supabaseAdmin` import banned outside an allowlisted server set | service-role bypass of RLS on a public endpoint (safety-critical) | **relocate** |
| R124 | never dismiss `/compound` as "clean deletion" | PITFALLS | L3 | L3 | judgment — "does this deletion encode a decision?" semantic | lost design rationale; canon drift | keep |
| R125 | `NOT EXISTS(... user_id = auth.uid())` guard preceded by `auth.uid() IS NOT NULL AND` | PITFALLS | L3 | L1-CI | CI test over migrations: every such membership guard has the null-uid precondition | null `auth.uid()` → guard passes for anon (safety-critical) | **relocate** |
| R126 | no TS interface in `src/data/` for external data — use Zod schema | PITFALLS | L3 | L2 | dependency-cruiser/custom: no hand-written interface in `src/data` mirroring external shape (= R5) | schema/interface drift; validation lies (irreversible) | **relocate** (dedup with R5) |
| R127 | after rebase adding migrations, check numeric-prefix collisions | PITFALLS | L3 | L1-CI | CI test: no duplicate numeric prefixes under `supabase/migrations` | two migrations same number → apply-order ambiguity (irreversible) | **relocate** |
| R128 | use transaction-local GUC to pass RPC args to its AFTER trigger | PITFALLS | L3 | L3 | judgment — specialized implementation pattern | non-atomic data hand-off (irreversible) | keep (tier on migration path) |
| R129 | public token RPCs grant EXECUTE only to `anon`, never `authenticated` | PITFALLS | L3 | L1-CI | CI test over migrations: public token RPCs' GRANTs exclude `authenticated` | auth bypass on a public RPC (safety-critical) | **relocate** |
| R130 | distinct error codes acceptable only because tokens are UUIDv4 | PITFALLS | L3 | L3 | judgment — conditional design note, not a fixed rule | token-existence leak if token format changes (safety-critical, conditional) | keep (tier-1; conditional) |
| R131 | server action with client `uuid[]` cross-checks IDs vs server-scoped set | PITFALLS | L3 | L3 | judgment — "is the cross-check present and correct?" semantic | IDOR / cross-tenant read (safety-critical) | keep (tier-1) |
| R132 | `NOT EXISTS(... id = ANY(p_ids))` guard adds empty-array early return | PITFALLS | L3 | L1-CI | CI test over migrations: such guards have the `array_length IS NULL` guard | empty array → guard vacuously passes | **relocate** |
| R133 | failed tool call compacts error into context, never throw/null | PITFALLS | L3 | L1 | PostToolUse errors-into-context hook (MOVE 1 emitter, `capability-facts.md`) | lost error; agent proceeds on a silent failure | **relocate** (MOVE 1) |
| R134 | Next.js 16 middleware file is `proxy.ts`, fn `proxy` | PITFALLS | L2-CI-test | L1 | build fails if mis-named (Next requires it) — already effectively L1 | middleware silently doesn't run | keep (already enforced by build) |

---

## Summary

### Counts per target layer (118 distinct binding rules)

| target | count | what's here |
|----|----|----|
| **L1** (deterministic hook: PreToolUse exit-2 / git hook / ESLint-error / skill-paths / session-start) | **30** | R1, R2, R6, R21, R22, R25, R30(demote-or-lint), R36, R37, R42, R43, R44, R47, R52, R53, R60, R72, R73, R77, R83, R85, R86, R89, R90, R95, R101, R106, R117, R118, R122, R133, R134 (counting the ~30 unique after dedup) |
| **L1-CI** (CI / branch-protection — unforgeable, runs for every dev) | **21** | R16, R17, R27, R33, R34, R65, R66, R67, R68, R69, R71, R75, R87, R92, R93, R103, R109, R120, R125, R127, R129, R132 |
| **L2** (dependency-cruiser arch-test in CI) | **13** | R5, R9, R10, R11, R23, R24, R76, R90(dep-ban overlap), R105, R110, R123, R126; plus existing `import/no-cycle` |
| **L3-1** (tier-1, always-loaded safety/judgment floor — keep-verbatim) | **15** | R20, R38, R39, R41, R57, R59, R78, R79, R80, R81(judgment half), R82, R91, R111, R112, R114, R130, R131 |
| **L3** (tiered/judgment — genuinely needs a model) | **39** | R3, R4, R7, R8, R12, R13, R14, R15, R18, R26, R28, R29, R31, R32, R35, R40, R45, R46(write-back is L1; *deciding what to write* is L3), R48, R49, R50, R51, R56, R58, R61, R62, R63, R64, R70, R74, R84, R88, R94, R96, R97, R98, R99, R100, R102, R104, R107, R108, R113, R115, R116, R119, R121, R124, R128 |

> Counts are approximate at the boundaries because ~12 rules split across layers (a bash-observable half →
> L1 + a judgment half → L3, e.g. R72/R73/R81; or a dedup target, e.g. R20≡R103, R5≡R126, R44≡R85,
> R52≡R95). The headline shape is what matters: **~30 L1 + ~21 L1-CI + ~13 L2 = ~64 rules relocated to a
> deterministic layer (≈54%)**, vs. ~86% advisory today. **L3 falls from ~101 to ~54 (39 tiered + 15
> tier-1)** — and of those 54, the irreducible judgment core is the ~39 tiered rules; the 15 tier-1 are the
> keep-verbatim safety floor that *should* stay prose-but-always-loaded.

### Headline movement

- **Before:** L3-advisory ≈101 (86%), git-hook ≈11, L1-hook ≈3, L2 ≈3.
- **After:** L1 ≈30, L1-CI ≈21, L2 ≈13, L3-1 ≈15, L3 ≈39. **≈64 rules (54%) become deterministic.**
- The relocation is the win, not new prose. Almost every relocation rides ONE of seven new mechanisms
  (below) — many rules per mechanism. This is consolidation: **7 build items absorb ~64 rules.**

### DELETE / demote list (§9: no nameable failure mode → overhead)

True deletes are few — most low-value rules are *demotable* (fold into another rule or drop the
standalone emphasis) rather than removable, because even style rules name a (small) failure mode.

- **DELETE candidates** (no nameable failure mode OR pure restatement):
  - **The CLAUDE.md terminal NEVER list as a section** — 16 lines that pure-restate R1–R3, R5, R7, R10,
    R36, R59, R60, R74, R77–R82, R84, R91, R71 [rule-inventory Duplication finding #2]. Once their members
    relocate to L1/L2, the NEVER list's *emphasis* becomes mechanical; the section is redundant index.
    **Delete the section; keep the rules at their new homes.**
  - **R30** (no multi-line comment blocks) — failure mode is near-zero (doc noise). Lint it if a trivial
    ESLint rule exists; otherwise DELETE — it is taste, not a defect-preventer.
  - **R54, R55** (on `/notion-sync` invoke `/notion-sync`; on `/debug` invoke `/debug`) — these restate how
    skill routing already works. No failure mode a rule prevents that the runtime doesn't. **DELETE** (R56,
    the *judgment* version "unknown cause → debug first", stays).
- **Demote (fold, don't delete):** R26→R27 area; R28/R29 (comment style — keep one L3 line, drop the
  three-way split); R70 (surface PR URL — output convention); R87 (becomes a repo setting, not a rule);
  R95→R52; R85→R44; R103→R20; R126→R5; R119/R121 (niche — keep but de-emphasize).
- **Dedup (one rule, one home — eliminates the cross-file echo):** R20≡R103 (RLS-role, stated 3×),
  R5≡R126 (interface-in-data-layer), R44≡R85 (branch GC), R52≡R95 (invoke /supabase), R66≡R68≡R69
  (the `.cr-ok`/`/cr` gate). Per rule-inventory Duplication findings, ~22 of 118 rules echo across files;
  the sort gives each ONE enforcement home and the doc text becomes a pointer, not a second copy.

### NEW L1 hooks / L2 tests / placement fixes that must be built (the actual build list — 7 items)

1. **`block-dangerous-bash.sh`** (new PreToolUse exit-2 guard — **resolution (a)**). Built like
   `block-dangerous-git.sh` (segment-parse, strip env/wrappers/options; never substring-grep per R112).
   Absorbs: R77 (rm/volume/destructive-SQL/deploy), the bash half of R72/R73/R81, boundary writes to
   `.git`/`.husky`/`.claude` (guard-file lockout), curl/wget egress to non-allowlisted hosts. **Most-cited
   single gap.** Fails OPEN if `jq` missing, loud (match existing pattern).
2. **`.cr-ok` → CI/branch-protection** (**resolution (b)**). New stop authority = `MUST-FIX=0 AND
   CI-required-checks-green on the sentinel SHA`, enforced where the model can't forge it. Today `.cr-ok`
   is gitignored (`.gitignore:58`) and validated only in local pre-push — never reaches CI. Re-homes
   R66/R68/R69. Requires: a CI job that re-derives MUST-FIX=0 from a committed `/cr` artifact (not the
   gitignored sentinel) + GitHub required-status-checks on the branch.
3. **`/cr-security` path/glob classifier** (**resolution (c)**) — the absent `enforce-scope.sh` slice. A
   CI job diffs `origin/main...HEAD`; if it touches `proxy.ts`/`**/middleware*`/auth `src/data/**`/RLS
   migrations, it FAILS unless the security review ran. Forces R67.
4. **`dependency-cruiser` in CI** (**resolution (d)**) — add the dev dependency (ASK FIRST per
   no-install-without-asking) + a `.dependency-cruiser.js` ruleset + a CI step. The L2 home for R5/R9/R10/
   R11/R24/R76/R90/R110/R123/R126 and the file-naming/import-boundary checks (R23). Canon §B: "not-ready —
   needs the layer map + report-mode false-positive testing first" → ship in report-mode, then enforce.
5. **A small `migration-lint` CI script** (grep/AST over `supabase/migrations/**`) — the cheapest big
   absorber. One script enforces the *mechanizable* migration/security rules currently all advisory:
   R92 (REVOKE after CREATE OR REPLACE FUNCTION), R93 (no CONCURRENTLY), R103 (no role checks in RLS),
   R109 (AGENTS index coverage), R125 (null-uid precondition), R127 (no prefix collision), R129
   (anon-only grant), R132 (empty-array guard). **8 safety-critical rules, one CI script.**
6. **A `repo-structure` CI script** — file-pairing + layout checks: R16 (PUBLIC_PATHS at root), R17
   (error.tsx per group), R27 (no schema file/folder collision), R33/R34 (test pairing), R75 (image
   remotePatterns), R120 (skill dir+frontmatter). Plus a commit-msg `commitlint` hook for R86.
7. **autoMode placement fix** (**resolution (e)**) — move the autoMode block out of committed
   `.claude/settings.json` (where it is *ignored by design*) to `settings.local.json` (personal) or
   `managed-settings.json` (enforced, agent-unreachable). **Human handoff** — the agent must NOT edit
   guard files [anti-phantom §E]; prepare paste-ready and surface as NEEDS HUMAN. Pairs with wiring the
   existing-but-orphaned `session-start.sh` to actually run R42/R43/R44 (the heartbeat), and the MOVE 1
   Stop/PostToolUse emitter that lands R46 (write-back) and R133 (errors-into-context).

**Convergence check:** these 7 build items are the *mechanisms* MASTER-FINDINGS MOVE 1+2 already name
(one Stop/PostToolUse surface, the bash guard, the CI-relocated stop authority, the security classifier,
dependency-cruiser L2, managed-settings floor). No new mechanism is invented here. The sort's contribution
is showing that **~64 of 118 rules collapse onto these 7 builds** — the "fewer files, more wiring" shape.

---

## Resolution notes (the judgment calls behind the table)

- **Why credential-reuse (R78–R80) stays L3-1, not L1.** A PreToolUse hook sees the *command string*, not
  the agent's *intent about which token and why*. It can block a destructive command that *uses* a token
  (that's the bash guard, R81's bash half), but it cannot tell "this token came from an unrelated file."
  Forcing it to L1 would produce a forgeable/false-confident guard — worse than honest prose. These are
  the keep-verbatim PocketOS rules; they stay tier-1, always-loaded, prose. The mechanical backstop is the
  *destination/operation* guard (egress + destructive-op), not a credential-provenance guard.
- **Why so many migration rules go L1-CI not L1-hook.** A PreToolUse hook only fires on an *agent* tool
  call; a human writing a migration in an editor never trips it. Migration safety rules are exactly the
  class where "humans AND agents" matters (canon §B), so the unforgeable, every-developer home is a CI
  script, not a PreToolUse guard.
- **Why R3 (`as` cast) stays L3 but R2 (`@ts-ignore`) goes L1.** `@ts-ignore` is a fixed token a linter
  bans outright. "`as` without preceding narrowing" requires reading whether a narrowing check precedes
  the cast — semantic, not lexical. Lexical → L1; semantic → L3.
- **The keep-verbatim floor is honored.** Every destructive-op/PocketOS rule (R77–R82) stays — R77 gets a
  *stronger* mechanical backstop (the bash guard) while keeping its prose; R78–R82 stay tier-1 L3 because
  they are not mechanizable. The 3 discipline questions (R41), tracer-bullet/TDD-first (R38), tests-before-
  movement (R39), the 4 pre-start definitions (R57), and scope-hold (R59/R91) all stay tier-1. No floor
  rule was cut.
- **The drift detector (R65) is the one genuinely-new *reader* obligation.** It is the MOVE 3 `/scan-context`
  payload: "a pattern changed but its doc didn't." It is L1-CI because doc-fiction (a phantom reference) is
  this audit's *live* failure class (the audit itself rotted). Without it, every relocation above still
  drifts in prose over time.
