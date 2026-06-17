# agent-harness

A curated, self-contained, **project-agnostic** AI coding harness — skills, sub-agents, hooks, and
locks that travel across repos. You start every job; the harness finishes it safely and tastefully,
stopping only for the few things expensive to get wrong. It runs on the operator's laptop behind
**locks it can't switch off**, is **token-lean** (one capable pass wherever the model can hold the
work; separate agents only for independence / parallelism / scale), and is **self-improving**.

> **Status:** bootstrapping. The machinery below has been brought over and genericized. The
> phase-ordered build (safety floor → trust → loop → quality → fleet) runs next.
> See **[BUILD-PLAN.md](BUILD-PLAN.md)** for the plan and the non-negotiable principles, and
> `docs/v2-audit/` for the full decision record.

## What's here now (bootstrap)

```
.claude/
  skills/      queue · cr · feature · tdd · refactor · debug · compound · grill-with-docs
  agents/      reviewer · lens-{assumption,composition,cascade,abuse} · task-runner ·
               implementer · spec-writer · explorer · investigator · hotfix-guard · spike-*
  hooks/       block-dangerous-git · block-npm-install · worktree-create · permission-logger · session-start
  settings.json    permissions + autoMode + hook wiring (project-agnostic template)
  agent-contract.md
  AI-WORKFLOW.md   how to work with agents (worktrees, work states, commit discipline)
scripts/       worktree-add · pr · gc · test-local · lint · run-tests
.husky/        pre-commit (lint) · pre-push (/cr sentinel + branch guards + tests) · post-checkout
tests/         harness-smoke.test.sh
```

## The gates

The harness dogfoods its own gates. They are zero-dependency (no app stack required):

- **pre-commit** → `npm run lint`: a `bash -n` syntax check on every shell file (plus `shellcheck`
  if installed). The harness is mostly shell + markdown, so the scripts *are* the code.
- **before coding** → the `/design contract` before-coding gate: Design Questions sheet → adversarial
  grill → schema/mockup approval → human sign-off → `scripts/design-confirm.sh` writes
  `.claude/.design-confirmed` (`branch:sha`). `/feature`'s implement step refuses to start without it
  (Small+; Tiny exempt).
- **pre-push** → the `/cr` sentinel check (`.claude/.cr-ok` must match `branch:sha`), branch guards
  (no pushing a merged branch, no detached HEAD), then `npm test`.
- **`npm test`** → runs `tests/*.test.sh`. `harness-smoke.test.sh` asserts the core machinery is
  present, executable, and free of leaked project-specific terms.

## Getting started

```bash
npm install        # installs husky; wires the git hooks
npm run lint       # shell gate
npm test           # harness smoke + behavior tests
```

A human starts and merges everything — there is no auto-merge and no event/timer trigger yet (those
are deferred, by design, to post-launch). See [BUILD-PLAN.md](BUILD-PLAN.md) → Phase 5.

## Principles (honored in every task — see BUILD-PLAN.md for the full text)

1. **Project-agnostic** — universal patterns only; stack specifics live in each project's config/adapters.
2. **Locks are the sole safety net** — deterministic, fail-closed, OS-level where it matters.
3. **Deterministic > advisory** — mechanically-checkable rules are hooks/lint/CI, not prose.
4. **One capable pass** — spawn a separate agent only for independence, parallelism, or scale.
5. **Comments earned** (why, never what). 6. **Human in control.** 7. **Frictionless handoff.** 8. **Honest claims.**
