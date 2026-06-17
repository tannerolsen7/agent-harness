# Backlog (interim)

> **Interim home.** *Where* backlog items should live per-project (Linear / GitHub Issues /
> TASKS.md / this file) is still being decided — see "Backlog mechanism" under *Promoted* below.
> This file is the durable interim so nothing is lost.
>
> **Anti-"build-forever" rule.** Every item carries a **severity** and a **status**. HIGH/MEDIUM
> items are NOT allowed to sit silently — they get *promoted to the active plan*, not parked. This
> list is reviewed whenever a `/cr` backlogs something. If an item can't be justified as worth
> keeping, it's dropped, not left to rot.

| Item | Severity | Status | Notes |
|---|---|---|---|
| **Branch protection on `main`** (require the `verify` check so F6 *blocks* merges) | LOW | Blocked (cost) | Requires a paid GitHub plan (~$4/user/mo); Tanner deferred the spend. F6 CI already runs + reports on every PR — this only flips it from advisory to merge-blocking. Revisit when on a paid plan, or if the repo moves to an org that has it. |
| **`@implementer` never-touch list for regression tests + guard files** | LOW | Backlog | Surfaced by /cr adversarial review on the spawn-wiring PR. The automated fix loop (`task-runner` → `@implementer`) can Edit `tests/agent-spawn-tools.test.sh` to force the spawn-wiring gate green, or inadvertently mutate agent guard files. Fix: add a hard rule to `.claude/agents/implementer.md` that prohibits editing `tests/` regression gate files and `.claude/agents/**`. Guard file — human edit only. |
| **Custom diff-review UI** (better than GitHub's merge screens) | IDEA / explore | Backlog | **Goal:** make every PR so simple to review that the operator could *teach the change to another person* by the time it's pushed. GitHub's merge screens don't give a good enough feel for *what* changed and *why*. Build on what the harness already produces — the spec, the feature-doc hub (R4-D9), `/grill-with-docs`, and the `/cr` disposition report — rendered into one teachable view (the change + its intent + the review verdict, side by side). Distinct from F6/CI: this is about *human comprehension*, not the gate. Sibling of **System-map / zoomable comprehension UI** below (that's *per-change*; this is *whole-system*). |
| **System-map / zoomable comprehension UI** (agent-built, Prezi-like) | IDEA / explore | Backlog | **Goal:** let a human *scan and deeply understand the whole software system of a repo* — start at the highest level (all the data flow, simply), then click in and *dive deeper and deeper*, progressive-disclosure / Prezi-style zoom. Agents build and keep the map current from the codebase itself. **Why it matters:** the operator wants to lean on agents to the fullest extent the model allows *and* understand the system deeply enough to make decisions "from a steady and strong place" — this UI is what keeps the human's comprehension ahead of the agents' output instead of behind it. Part of the **education piece**. Sibling of **Custom diff-review UI** above (that teaches a *change*; this teaches the *system*). **Needs more exploration** before any design: what "data flow at altitude" actually means for these repos (modules → contracts → call/data edges?), how the map is generated and re-generated without rotting, and what the zoom interaction is (single artifact vs. live tool). |
| **Trap-tag the pre-existing bug-catch security cases (002 IDOR / 005 SQLi / 008 webhook)** — or document why they aren't traps | LOW | Backlog | Surfaced by /cr on the classifier-guard PR. The trap subset (R4-D32 #5) only covers the new cases 009–013; existing HIGH-risk cases predate the `trap`/`tier` fields, so there are two overlapping notions of "security-critical case." The inclusion criterion is now documented (a trap is a HIGH-tier diff that *reads as trivial*). Audit 001–008 against it: 002's own note already says "looks like a trivial endpoint," so it's a plausible trap; 005/008 read as obviously dangerous, so likely not. Retro-tag the ones that fit and leave the rest, so the subset is principled rather than just "the new ones." Corpus-quality, not blocking. |
| **Side-effect skill registry** (auto-cover new skills in `disable-model-invocation` smoke check) | LOW | Backlog | The smoke test in `tests/harness-smoke.test.sh` hardcodes 4 skill names (`to-issues`, `to-prd`, `migrate`, `queue`) as the side-effect guard list. A new side-effect skill added without the flag will pass the smoke test silently. Fix options: (a) a declared `side-effect: true` frontmatter field + a glob-based smoke check that requires `disable-model-invocation: true` whenever `side-effect: true` is present; (b) invert the check — scan all skills and require the flag unless on an explicit safe-to-invoke allowlist. Either requires a side-effect skill convention the project does not yet have. Surfaced by /cr on phase0-f9-verify PR. |
| **Gate the out-of-band deploy steps** (deploy-drift gate) | IDEA / explore | Proposed (ADR-0002) | The harness gates *code* at PR→CI→merge, but deploy-time manual steps (migration push, env/secret/flag changes) live *past* that boundary — no gate sees them. Field report: a sibling project's manual Supabase migration push broke prod, ungated. Scoped in `docs/adr/0002-deploy-drift-gate.md`: a `deploy-targets` manifest + two-tier gate (**2a** deterministic "no gate declared"/orphan-migration check folded into `ci-verify.sh`, no creds; **2b** stateful live-drift check in a *separate* credentialed job — the live dry-run can't go in F6's deterministic floor) + `/migrate` reinforcement (refuse + scaffold if a target it mutates is ungated). **First slice:** 2a + the manifest schema (free, no creds, catches "not gated anywhere"). **Disposition:** explore, not fix-now (the harness owns no project's deploy yet — nothing to gate here) and not drop (real, on-mission blind spot). Sibling of **Branch protection on `main`** above (that makes the *code* gate *block*; this extends gating *past* merge). |

## Promoted to the active plan (tracked, NOT parked here)
- ✅ **`/queue` orphaned-worktree** — RESOLVED (worktree-lifecycle branch). `/queue` Step 3 no longer
  passes `isolation: "worktree"`; the agent works in the pre-created `.claude/worktrees/<slug>` (which
  IS its isolation), so no second worktree is orphaned.
- ✅ **Worktree/branch cleanup in `/feature` + `/queue`** — RESOLVED (worktree-lifecycle branch).
  `gc.sh` now removes a merged branch's worktree before deleting the branch (also fixed the pre-existing
  `git branch -vv` "+ " worktree-prefix bug that made worktree branches un-gc'able; tested in
  `tests/gc.test.sh`). `/feature` and `/queue` both document post-merge cleanup via `gc.sh`.
- **Branch-naming convention mismatch (`/queue` ↔ agent-contract ↔ task-runner)** — MEDIUM. `/queue`
  Step 5, `pr.sh`, and `gc.sh` all assume `feat/<task-slug>`, but `.claude/agent-contract.md` BRANCH
  format is `<working-branch>/<short-task-slug>`, and `/queue` Step 3 doesn't name `task-runner` as the
  `subagent_type`. Step 5's `.cr-ok` check is an EXACT `feat/<slug>:<sha>` match, so a divergent branch
  name breaks it. Reconcile the convention across the three (task-runner.md is a guard file → human
  reconciliation). Surfaced by /cr on the worktree-lifecycle PR.
- **Backlog mechanism research** — per-project target (Linear / Issues / file) + an aging/severity
  mechanism that prevents this list from building forever. Produces the durable replacement for
  this interim file.
