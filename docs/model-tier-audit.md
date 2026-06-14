# Model-tier audit — this harness's agents (role → tier)

**Last audited:** 2026-06-13, against the current lineup: **Opus 4.8** (`claude-opus-4-8`, top),
**Sonnet 4.6** (`claude-sonnet-4-6`, workhorse), **Haiku 4.5** (`claude-haiku-4-5-20251001`, fast/cheap).
**Fable 5** (`claude-fable-5`) exists but is unassigned here — no role-fit capability profile yet
(see "Open"). This is the repo-specific application of the universal framework in
[`engineering-system/13 · Model Capacity Audit`](engineering-system/13-model-capacity-audit.md);
re-run it whenever the model lineup changes (R4-D32#4 — the `model-review` ritual).

> **Guard-file note:** agent `model:` fields live in `.claude/agents/**`, which the agent cannot edit
> (OS-locked). This doc is the recommendation; the **Change list** at the bottom is copy-paste-ready
> for a human to apply.

---

## The tier principle — match model to *role stakes × judgment depth*, not to seniority

| Tier | Use when the role is… | The cost of under-powering it |
|---|---|---|
| **Haiku** | mechanical / transcription — transform X into Y with little open judgment | misses nuance, but the task has little nuance to miss |
| **Sonnet** | a capable specialist — implement, explore, research, most review; the default workhorse | rarely the bottleneck; this is where most agents belong |
| **Opus** | orchestration (holding many threads + a protocol) **or** highest-stakes adversarial judgment where a *miss is the expensive outcome* | a missed subtle bug / security hole, or a dropped thread in a multi-agent pipeline |

Two anti-patterns this guards against (both from the C13 canon):
- **Over-powering by default** — putting everything on the top tier "to be safe" burns budget where Sonnet
  is already sufficient. Spend Opus where reasoning *depth changes the outcome*, not everywhere.
- **Under-powering the consequential** — running the review-orchestrator or the security gate on a mid
  tier to save cost, when those are exactly the roles whose misses are the costliest.

---

## Per-agent audit (23 agents)

Current: **21 `sonnet`, 2 `opus`, 0 `haiku`.** Recommended changes are **bold**.

### Orchestrators — Opus (hold a pipeline + a protocol)
| Agent | Now | Rec | Why |
|---|---|---|---|
| `task-runner` | opus | **opus** (keep) | Runs the whole per-task specialist pipeline + the questions.md blocking protocol. |
| `spike-orchestrator` | opus | **opus** (keep) | Sequences the full spike pipeline; coordinates many sub-agents. |

### The review verdict — Opus (a miss here ships a defect)
| Agent | Now | Rec | Why |
|---|---|---|---|
| `reviewer` | sonnet | **opus ↑** | The review *orchestrator*: spawns the 4 lenses and **consolidates** them into the tiered verdict. Its synthesis gates the whole `/cr` outcome — the one place where a stronger model most directly changes whether a real finding survives. |
| `security-reviewer` | sonnet | **opus ↑** | Highest-stakes review: every finding is MUST-FIX and a false *negative* (missed auth/credential hole) is the costliest miss in the system. |

### Adversarial finders — Sonnet now, Opus *if* bug-catch shows a gap
| Agent | Now | Rec | Why |
|---|---|---|---|
| `lens-abuse`, `lens-assumption`, `lens-cascade`, `lens-composition` | sonnet | **sonnet** (keep; revisit) | They run **in parallel, per finding** (4× fan-out), so cost scales fast. Sonnet is the right default; promote to Opus only if the bug-catch catch-rate shows the lenses are the recall bottleneck (tie this to the Phase-1 bug-catch baseline, not a guess). |
| `spike-adversarial-verifier` | sonnet | **sonnet** (keep; revisit) | Adversarial, but one-shot and bounded; same "promote only on evidence" stance. |

### Specialists / implementers / researchers — Sonnet (the workhorse band)
| Agent | Now | Rec | Why |
|---|---|---|---|
| `implementer` | sonnet | **sonnet** (keep) | Red-green TDD on one slice; Sonnet codes this well. |
| `explorer` | sonnet | **sonnet** (keep) | Codebase search + light synthesis. (Pure-retrieval sweeps could trial Haiku — measure recall first.) |
| `spec-writer` | sonnet | **sonnet** (keep) | Judgment about which behaviors are *confirmed* vs invented. |
| `investigator` | sonnet | **sonnet** (keep) | Hypothesis-driven debugging; promote case-by-case for a genuinely hard bug, not by default. |
| `refactor-extractor` | sonnet | **sonnet** (keep) | "Move symbols, no logic change" is semi-mechanical, but the git + verify discipline wants Sonnet's reliability. |
| `incident-responder` | sonnet | **sonnet** (keep) | Structured evidence-gathering; high-stakes but bounded and checklist-driven. |
| `hotfix-guard` | sonnet | **sonnet** (keep) | Scope-guards a hotfix; judgment, bounded. |
| `solution-evaluator` | sonnet | **sonnet** (keep) | Build-vs-buy research + synthesis. |
| `ux-reviewer` | sonnet | **sonnet** (keep) | UX friction judgment. |
| `spike-researcher` | sonnet | **sonnet** (keep) | Web research + cited summary. |
| `spike-synthesis` | sonnet | **sonnet** (keep) | Writes the dossier from research passes. |
| `spike-slice` | sonnet | **sonnet** (keep) | Writes one TDD test to confirm/kill the recommendation. |
| `spike-user-verifier` | sonnet | **sonnet** (keep) | End-user stakes assessment; bounded. |

### Mechanical / transcription — Haiku
| Agent | Now | Rec | Why |
|---|---|---|---|
| `doc-updater` | sonnet | **haiku ↓** | Transcribes a diff + the compound answers into a doc *draft* for human review. Low open judgment, structured output, runs after every task — the clearest Haiku candidate (fast + cheap where it's mostly transformation). If draft quality drops, revert to Sonnet. |

---

## Net change: 3 edits (1 down, 2 up), 0 churn elsewhere

- `reviewer`: sonnet → **opus** (review verdict)
- `security-reviewer`: sonnet → **opus** (highest stakes)
- `doc-updater`: sonnet → **haiku** (mechanical)
- Everything else: unchanged. The 4 lenses + `spike-adversarial-verifier` are **flagged for re-audit
  against the bug-catch baseline**, not changed now.

Rationale for the shape: spend the top tier on the two roles whose *misses are most expensive* (the
review synthesis and the security gate), recover budget on the one clearly-mechanical role
(doc-updater), and leave the workhorse band alone. This is a reallocation, not an across-the-board bump.

---

## Change list (human-applies — guard files)

Each agent file's frontmatter has a `model:` line. Apply:

```bash
# from the repo root
sed -i '' 's/^model: sonnet$/model: opus/'  .claude/agents/reviewer.md
sed -i '' 's/^model: sonnet$/model: opus/'  .claude/agents/security-reviewer.md
sed -i '' 's/^model: sonnet$/model: haiku/' .claude/agents/doc-updater.md
```
(GNU `sed`: drop the `''` after `-i`.) Verify: `grep -m1 '^model:' .claude/agents/{reviewer,security-reviewer,doc-updater}.md`.

---

## Re-audit ritual (on every model-lineup change)

When the provider ships a new top model or retires one (R4-D32#4 / the `model-review` ritual):
1. Update the "Last audited" line + the lineup at the top of this doc (with the date).
2. For each tier, ask the C13 question: *is this constraint/assignment a response to a model limitation
   that no longer exists?* A new, more capable top model may let an Opus role drop to Sonnet, or a
   Sonnet role absorb work that needed Opus before.
3. Re-confirm the dated capability claims in the C13 canon against the model you are actually running.
4. Feed any bug-catch catch-rate movement into the "adversarial finders" row (promote/keep on evidence).

---

## Open

- **Fable 5 (`claude-fable-5`)** is in the lineup but unassigned — no role-fit profile yet. When its
  capability/cost envelope is known, slot it into the tier table (it may fit the workhorse or
  fast-mechanical band). Don't assign roles to it on speculation.
- The lens promotion question is **gated on the Phase-1 bug-catch baseline** — resolve it there, not here.
