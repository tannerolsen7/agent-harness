---
name: feature
description: |
  Guides the user through a complete feature development workflow,
  orchestrating discovery, planning, implementation, and review steps sized to
  feature complexity. Use when starting a new feature, building something new,
  or when the user says "new feature", "build X", "implement X", "plan a feature",
  or invokes /feature.
---

# Feature Pipeline

> **Upstream skills:** `/grill-with-docs` and `/tdd` are vendored in this harness
> (`.claude/skills/`). `/to-issues` and `/simplify` are from Matt Pocock's skills repo
> and are still external — install globally until they are vendored (a later harness phase):
> `npx skills@latest add mattpocock/skills`. A step that calls a not-yet-installed skill
> should be skipped with a one-line note rather than blocking the pipeline.

## Tracer bullets (read before proceeding)

When building features, build a tiny, end-to-end slice of the feature first,
seek feedback, then expand out from there.

Tracer bullets come from The Pragmatic Programmer. When building systems, you
want to write code that gets you feedback as quickly as possible. Tracer bullets
are small slices of functionality that go through all layers of the system,
allowing you to test and validate your approach early. This helps identify
potential issues and ensures the overall architecture is sound before investing
significant time in development.

This is why /tdd enforces vertical slices and this skill enforces sizing.
AI's natural inclination is to build horizontal layers in isolation. You are
here to enforce the opposite.

## Anti-rationalization (read before proceeding)

| Rationalization | Rebuttal |
|---|---|
| "This is too small to need /grill-with-docs" | Tiny features still have hidden assumptions. /grill-with-docs takes 5 minutes. A wrong assumption takes hours to fix. Run it. |
| "The task is clear, Phase 0 isn't needed" | Phase 0 exists because tasks are never as clear as they appear. Confirming takes 2 minutes. |
| "I'll write the TESTING.md entry after" | There is no after. Spec before test. Test before code. This is the order. |
| "The plan is obvious, I don't need approval" | The plan phase exists because what seems obvious may be wrong in ways not yet considered. Get approval. |
| "We're already mid-implementation, /to-issues would interrupt the flow" | The human asking "did you use /to-issues?" is the interrupt. Stop. Run /to-issues. A process question from the human is not rhetorical — it is a direct instruction. Momentum is not a reason to skip a step; it is how steps get skipped. (observed in practice) |

---

## Step 0 — Size the feature first

Estimate scope before doing anything else:

| Size | Behaviors | Pipeline |
|---|---|---|
| Tiny | 1 | Confirm → TESTING.md → /tdd → /simplify → /cr |
| Small | 2–5 | /design contract → /grill-with-docs → TESTING.md → plan → /tdd → /simplify → /cr |
| Medium | 6–15 | /design [explore →] contract → /grill-with-docs → TESTING.md → /to-issues → decompose → /tdd → /simplify → /cr |
| Large | 16+ | /design [explore →] contract → /grill-with-docs → TESTING.md → /to-issues → decompose → /feature on each issue |

Before proceeding to any size tier, fill a contract for each sub-agent
this feature will spawn. Use .claude/agent-contract.md as the template.
A contract must exist before a sub-agent is invoked — never spawn without one.

Tell the user your estimate and ask if the size is wrong before proceeding.

---

## Tiny (1 behavior)

1. Confirm the expected behavior with the user
2. Record it in `docs/TESTING.md` under confirmed behaviors before writing any code
3. Invoke `/tdd` for the single slice (contract required)
4. Invoke `/simplify` on the changed code
5. Invoke `/cr`. If the change touched auth/permissions/data boundary,
   also invoke `/cr-security`.
6. Run `npx tsc --noEmit` — must exit zero
7. Commit with conventional commit format
8. Report

---

## Small (2–5 behaviors)

1. **Orient** — read .claude/memory.md, skim docs/solutions/README.md, check AGENTS.md open decisions. Report: any open decisions touching this task? Any relevant solutions already documented?
2. **Research check** — search `docs/research/` for files relevant to this feature's external dependencies. If a relevant file exists, read it before the design contract. If a gap exists and the feature touches an external API or new framework pattern, create a research file in `docs/research/[topic].md` before proceeding.
3. **Design contract** — invoke `/design contract`. If uncertain about the design, run `/design explore` first. Contract output goes into TASK-TEMPLATE.md before proceeding.
4. **Grill** — invoke `/grill-with-docs` (contract required). Confirm scope, surface hidden assumptions, challenge design against `CONTEXT.md`. Doc updates get written here.
5. **Solutions check** — search `docs/solutions/` for relevant patterns before designing the interface.
6. **Spec** — write all confirmed expected behaviors to `docs/TESTING.md` before touching code.
7. **Plan** — read relevant source files and existing tests. Design the public interface. Get user approval before writing code.
8. **Implement** — invoke `/tdd` (contract required). Tracer bullet slice first.
9. **Simplify** — invoke `/simplify` on all changed files.
10. **Review** — invoke `/cr`. If touched auth/permissions/data boundary, also invoke `/cr-security`.
11. **Type check** — `npx tsc --noEmit` must exit zero
12. **Commit** — conventional commit format
13. **Compound questions** — ask the agent:
    - What was the hardest decision you made here?
    - What alternatives did you reject, and why?
    - What are you least confident about?
14. **Compound** — if non-obvious pattern introduced, invoke `/compound`
15. **Report**

---

## Medium (6–15 behaviors)

1. **Orient** — read .claude/memory.md, skim docs/solutions/README.md, check AGENTS.md open decisions
2. **Research check** — search `docs/research/` for files relevant to external dependencies. Create a research file if a gap exists before designing anything.
3. **Spec** — create `docs/specs/[task-slug].md` from the Medium+ spec template. Fill the user goal, user journey, edge cases, and DMMT audit section. Set `human-approved: false`. Surface to the human for review and approval before proceeding. Do not proceed to /design until `human-approved: true`.
4. **Design** — invoke `/design explore` (if uncertain about the approach), then `/design contract`. Contract output goes into TASK-TEMPLATE.md.
5. **Grill** — invoke `/grill-with-docs` (contract required)
6. **Solutions check** — search `docs/solutions/` before designing anything
7. **Spec** — write all confirmed behaviors to `docs/TESTING.md`
8. **Decompose** — invoke `/to-issues`. Apply decomposition checklist: tracer bullet first, label parallel vs. sequential, verify each slice independently shippable.
   **STOP. Do not proceed to Step 9 until the user has confirmed the issue list.** This is a hard gate. Implementation does not begin until /to-issues has run and the output is approved. If the user asks "did you use /to-issues?" mid-implementation, that question is the instruction — stop, run /to-issues, get confirmation, then resume.
   After confirmation: identify which issues are independent. Spawn sub-agents for independent issues simultaneously — do not work sequentially through the list if issues have no shared dependency. State the parallel groupings explicitly before spawning.
9. **Plan** — read CONTEXT.md, AGENTS.md, existing tests. Design interface. Get user approval.
10. **Implement** — invoke `/tdd` for each issue in order. Tracer bullet slice first. (contract required)
11. **Simplify** — invoke `/simplify` on all changed files
12. **Review** — `/cr`, `/cr-security` if triggered
13. **Type check** — `npx tsc --noEmit` must exit zero
14. **Commit**
15. **Compound questions**
16. **Compound** — invoke `/compound` if non-obvious pattern introduced
17. **Report**

---

## Large (16+ behaviors)

1. **Research check** — search `docs/research/` for relevant external dependencies. Create research files for any gaps before proceeding.
2. **Spec** — create `docs/specs/[task-slug].md`. Must be human-approved before decomposition begins.
3. **Grill** — invoke `/grill-with-docs`
4. **Spec** — write all confirmed behaviors to `docs/TESTING.md`
5. **Decompose** — invoke `/to-issues`. Each issue maps to Small or Medium. The spec.md user journey is the reference for tracing issues back to user intent.
6. **Execute** — run `/feature` on each issue in dependency order

---

## Final report format

```
## /feature complete
Built: <one sentence>
Size: <Tiny | Small | Medium | Large>
Behaviors: <N confirmed behaviors added to docs/TESTING.md>
Tests: <N tests written, what they cover>
Review: <cr: N must-fix auto-fixed>
Commit: <hash and short message>
Security tier: <ran | not required>
Needs human: <list or "None">
```

---

## Done criteria

- All confirmed behaviors in `docs/TESTING.md`
- All slices committed (test + implementation in same commit)
- All /to-issues issues closed — via `closes #N` in commit body (auto-closed on merge) or manually if the issue was partially addressed
- `/simplify` has run
- `/cr` clean (and `/cr-security` if security-sensitive code touched)
- `npx tsc --noEmit` exits zero
- Final report delivered
- If non-obvious pattern introduced: `/compound` has run
- If feature changed a documented pattern: affected solution doc updated
- PITFALLS.md checked: if feature revealed new footgun, entry proposed
- Spec sync: if any spec assumption changed during build, TESTING.md and CONTEXT.md updated to reflect what was actually learned

---

## Worktree cleanup (after merge)

If this feature ran in a dedicated worktree (`.claude/worktrees/<slug>`), leave it in place while the
PR is open — review fixes may need it. After the PR **merges**, `scripts/gc.sh` removes the worktree
and deletes the branch (it removes the worktree before the branch, since git won't delete a branch
that is still checked out). Run `gc.sh` after merging, or let the weekly `stale-branch-audit` ritual
do it. Never remove the worktree before the PR merges.
