# AI Workflow Guide

How to work with AI coding agents under this harness. Project-agnostic: it holds only
universal patterns — each project supplies its own stack, conventions, and adapters.

---

## Prerequisites

Before using scripts that automate push and PR creation:

- **`gh` CLI** — install with `brew install gh && gh auth login`. Required for `scripts/pr.sh`.
- **`npm install`** — run once so the husky git hooks (the pre-commit / pre-push gates) are installed.
- **Project env/credentials** — if this project's tests need env files (e.g. `.env.local`), they must
  exist at the repo root. Each worktree symlinks them in (see below). Projects that need none skip this.

---

## Parallel branch work with git worktrees

When working on multiple features simultaneously, use git worktrees — not multiple checkouts of the
same directory. Each agent window needs its own worktree to avoid branch conflicts. A worktree is a
second working directory pointing at a different branch; the `.git` repo is shared.

### Worktree convention (standardized)

All worktrees live under **`.claude/worktrees/<slug>`** (nested, inside the repo). This single
convention is what the machinery enforces:

- `scripts/worktree-add.sh` and the `WorktreeCreate` hook create worktrees here.
- `block-dangerous-git.sh` only permits `git worktree remove` of a `.claude/worktrees/*` path.
- `.claude/worktrees/` is gitignored (transient).

Do **not** use sibling paths like `../<repo>_<slug>` — the guards won't cover them and you get
un-removable orphans.

### Lifecycle

| Step | Command | When |
|---|---|---|
| 1. Create | `scripts/worktree-add.sh .claude/worktrees/<slug> <branch>` | Starting parallel work — use the script, not bare `git worktree add` |
| 2. Work | (use the new directory normally) | Throughout the feature |
| 3. Open PR | `scripts/pr.sh --title "..." --body "..."` | After /cr passes |
| 4. Merge | (a human merges the PR) | Feature complete |
| 5. Clean up | `git worktree remove .claude/worktrees/<slug>` | After merge — required |
| 6. Delete branch | `git branch -d <branch>` | After merge — confirm merged first: `gh pr view <n> --json state` |
| 7. Prune tracking ref | `git remote prune origin` | After deletion — or the stale `origin/<branch>` ref lingers |

`delete_branch_on_merge=true` removes only the **remote** ref. The **local** branch and the
**remote-tracking** ref persist on disk until explicitly removed — steps 6–7 are not optional.
`scripts/gc.sh` does steps 5–7 in bulk for every `[gone]` branch.

`scripts/worktree-add.sh` symlinks any root env files into the new worktree so integration tests
have their credentials. Bare `git worktree add` skips this — tests that need env will fail.

There is no auto-delete. Worktree directories persist until explicitly removed (`git worktree list`).

### Rules

- One agent window per worktree directory (one session, one branch, one worktree).
- Never run `git checkout` in a shared directory — use worktrees instead.
- Remove the worktree immediately after merging.
- If a new session starts in the repo root and the branch has uncommitted work from a prior session,
  create a worktree before writing any code. Two sessions must never share a branch.

---

## Choosing the right work state

Identify the work state before invoking any skill. When it's not explicit in the user's message,
name it and confirm before proceeding. When it's obvious, proceed directly.

| Signal | Work state | Entry point |
|---|---|---|
| Live breakage, data loss, security event, unexpected behavior | Incident | `/incident` (classify first) |
| Bug confirmed in our code, contained blast radius | Hotfix | `/hotfix` |
| New capability, greenfield feature, UI work | Feature | `/feature` (→ `/design` first if scoped) |
| Multiple independent backlog tasks in parallel | Parallel execution | `/queue` |
| Schema change, data backfill, DB restructure | Migration | `/migrate` |
| Changing existing behavior intentionally | Behavior change | `/behavior-change` |
| Correct code that is too slow | Performance | `/perf` |
| Ambiguous between two states | Ambiguous | Name both, ask one question to decide |
| Session resumed mid-task | Resumption | Check `git branch --show-current` and TASKS.md first, then confirm |
| Exploratory ("what should we do") | Exploratory | 2–3 sentences with a recommendation + main tradeoff. No skill invoked. |

> Some of these skills are vendored in this harness today; others (`/incident`, `/migrate`,
> `/perf`, `/behavior-change`, `/design`, `/hotfix`) arrive in later build phases. A reference to a
> not-yet-present skill should be skipped with a one-line note, not block the work.

Work state can shift during a session (e.g. `/incident` → `/hotfix` after triage). Re-classify at
each transition.

---

## Skills brought by the bootstrap

| Skill | When |
|---|---|
| `/queue` | Run multiple independent backlog tasks in parallel worktrees |
| `/feature` | Starting any feature — sized automatically |
| `/tdd` | Implementing a confirmed behavior (red-green-refactor) |
| `/refactor` | Restructuring without changing behavior |
| `/debug` | Diagnosing a failing test or bug |
| `/grill-with-docs` | Stress-test a plan against the project's domain language + decisions |
| `/compound` | After a feature that introduced a non-obvious pattern |
| `/cr` | Before pushing — the single pre-merge review gate |

`/to-issues` and `/simplify` (Matt Pocock's repo) are referenced by `/feature` but are not yet
vendored — install them globally (`npx skills@latest add mattpocock/skills`) until a later phase
vendors them.

---

## Agent context files (conventions, created per project)

| File | What it covers |
|---|---|
| `CLAUDE.md` | Process rules, coding discipline, NEVER list (judgment-only) |
| `AGENTS.md` | Architecture, open decisions, golden exemplars |
| `CONTEXT.md` | Domain model, business rules, the why |
| `.claude/memory.md` | Corrected mistakes — read every session |
| `PITFALLS.md` | Codebase-specific traps — read before writing in any affected area |
| `docs/TESTING.md` | Confirmed behaviors, test infrastructure |
| `docs/RECURRING-FINDINGS.md` | Review findings tracked toward enforcement (the learning ratchet) |

The harness does not require these to exist; skills create or read them as the project grows.

---

## Commit discipline

The unit of work is one behavior, not one feature.

- One behavior = one spec = one commit.
- Test and implementation go in the same commit.
- Conventional commits: `type(scope): short description`. Body explains *why*, not *what*.
- If a task spans multiple commits, each must leave tests green.

A commit that can't be reviewed in under a minute is too large.
