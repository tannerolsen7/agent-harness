# ADR 0002 — Deploy-drift gate (gating the out-of-band deploy step)

**Status:** Proposed (awaiting acceptance)
**Date:** 2026-06-17
**Deciders:** Tanner (human merges); drafted by the harness build agent
**Originating field report:** a sibling project broke production when a manual migration push was never gated anywhere.
**Relates to:** F6 (`scripts/ci-verify.sh`, the un-forgeable CI gate) · `/migrate` skill · `BACKLOG.md` → "Branch protection on `main`"

---

## Context

The harness gates **code** at the PR → CI → merge boundary. F6 (`scripts/ci-verify.sh`) re-runs the
deterministic floor (lint, tests, routing-assertion) server-side on the exact head commit — the only
un-fakeable guarantee, because the local pre-push hook is on a machine the agent can touch.

But the things that actually take a change *live* are not only code. **Deploy-time manual steps —
a database migration push, an env/secret change, a feature-flag flip — live *past* the PR boundary.**
No harness gate sees them. A migration file can merge cleanly, pass every gate, and then never be
applied to production (or be applied out of order), and **nothing fails**. The gate the harness is
proud of stops exactly one step short of where the failure happens.

`/migrate` is the disciplined **execution** path (classify → pre-flight → dry-run → execute → verify),
but it only fires *when invoked*. The projects most at risk are precisely the ones that bypass it
with a manual push. **A skill cannot gate a step that routes around it.** The missing piece is not
more `/migrate` — it is a *gate that fails when committed state and deployed state drift*, regardless
of how (or whether) the migration was applied.

**Field report (the motivating case):** production broke because a manual migration push was never
gated. The fix that would have caught it there: a CI check that runs the deploy's dry-run
(`supabase db push --dry-run`) and fails when there is a pending/undeployed delta. We adopt the
*shape* of that fix, generalized — not the Supabase specifics.

---

## The constraint that shapes the design

F6's contract (see the header of `scripts/ci-verify.sh`) is two words: **deterministic**, and
runnable **on a machine the agent cannot touch**. The strong form of a drift check —
"the repo says migration X exists; production has not applied it" — violates *both*:

- It is **non-deterministic**: the answer depends on live target state, not on the commit.
- It **needs production credentials** in CI, injecting a prod-cred attack surface into the PR pipeline.

Therefore the gate **must be split**. A deterministic, no-credentials tier can live inside F6's floor.
A stateful, credentialed tier **must not** — putting it there would break the determinism guarantee
that makes F6 trustworthy and would hand the PR pipeline prod credentials.

This split is the load-bearing decision of this ADR. Everything else follows from it.

---

## Decision

Adopt a **deploy-targets manifest** as the seam, a **two-tier gate**, and **reinforcement via
`/migrate`** — four layers, each at its right cadence and credential level.

| Layer | What it does | Home | Cadence | Creds |
|---|---|---|---|---|
| **1. Discovery** | Enumerate the project's release/deploy steps; emit/maintain the `deploy-targets` manifest; flag any stateful target with **no drift gate** | New light skill, or a step in `/setup-strategy` (project-level, scan-context family) | one-time + revisited | no |
| **2a. Gate — deterministic** | Repo-internal consistency: every migration file is wired into the manifest (no orphans), **and every declared stateful target *has* a `drift_check`** | a step in `scripts/ci-verify.sh` (F6) — host-agnostic, both CI hosts inherit it | every PR, server-side | **no** |
| **2b. Gate — stateful** | The real drift: run each target's `drift_check` against the live/branch target; fail on a pending delta | a **separate credentialed CI job** (deploy pipeline), *not* the F6 floor | deploy/release | yes |
| **3. Reinforcement** | `/migrate` entry gate refuses to proceed unless the target it mutates is in the manifest **and** gated; scaffolds the entry + gate if missing | `/migrate` skill | per-migration | no |

**Layer 2a is the literal encoding of the field report.** "Wasn't gated anywhere" becomes a
deterministic, zero-credential CI failure: declare a stateful deploy target with no `drift_check`
and F6 goes red. **Layer 3 closes the chicken-and-egg** — the projects most at risk are the ones not
using `/migrate`, so making the disciplined path *also install the guardrail* pulls them in over time
and keeps the manifest from rotting as new state stores appear.

### The manifest (the provider-agnostic seam)

A single declared list keeps this out of Supabase-specific territory. The harness derives placement
*mechanically* from each entry's `needs_creds` — no per-project gate code:

```yaml
# deploy-targets.yml — the harness reads this
- name: prod-db
  kind: db-migrations          # | infra | secrets | feature-flags | service
  drift_check: "supabase db push --dry-run"   # contract: exit ≠ 0 iff an undeployed delta exists
  needs_creds: true            # true → routes to Layer 2b (credentialed job); false → folded into 2a/F6
  cadence: deploy              # pr | deploy | both
```

A target with `needs_creds: false` and a deterministic check is folded into `ci-verify.sh`; otherwise
the harness generates a credentialed job for it. The manifest is the only thing a project author
writes; the harness owns the wiring.

---

## First slice (recommended build order)

**Layer 2a's "is there a gate at all?" check + the manifest schema.** It is the highest-leverage,
lowest-cost, most on-architecture piece:

- deterministic and credential-free → drops straight into the existing F6 floor;
- needs nothing from the operator (no secrets);
- already catches the field-report failure class ("not gated anywhere");
- everything else (2b, the discovery skill, the `/migrate` hook) builds on the same manifest and can
  land incrementally afterward.

Ship 2a first; treat 2b/Discovery/Reinforcement as follow-on PRs gated on real adopter need.

---

## Consequences

**Positive**
- Closes a genuine blind spot: the harness's gate currently stops one step short of where deploys
  break. 2a extends it past merge *without* weakening F6's determinism.
- Provider-agnostic by construction — the manifest is the seam; Supabase is one example value, not a
  dependency.
- Cheap to start: 2a is free (no creds, no infra) and self-contained.

**Negative / costs**
- **2b needs production (or branch) credentials in CI** and is non-deterministic by nature. It is
  human-gated by construction (the operator places the secrets) and must stay *out* of the F6 floor.
  Prefer running 2b's dry-run against a **branch/shadow** target (e.g. a Supabase branch DB via the
  MCP `create_branch` / `list_migrations`) rather than prod, to keep prod creds off the PR path.
- A new manifest is one more project-level convention to author and keep current; Layer 3 exists
  specifically to fight that rot.
- Two tiers means the "where does this check run" routing is real (small, but a moving part).

**Migration path (post-acceptance, separate PRs)**
1. Land the `deploy-targets` manifest schema + Layer 2a checks in `ci-verify.sh` (+ tests). No creds.
2. Add Discovery (the manifest-authoring skill / `/setup-strategy` step).
3. Add the `/migrate` entry-gate reinforcement (Layer 3).
4. Add Layer 2b (credentialed job) — human places secrets; prefer branch/shadow over prod.

---

## Alternatives considered

- **Bolt the live dry-run straight into `ci-verify.sh`.** Rejected — breaks F6's determinism contract
  and injects prod credentials into the PR pipeline. The 2a/2b split exists precisely to avoid this.
- **Rely on `/migrate` alone.** Rejected — a skill cannot gate a step that bypasses it, and the
  bypass case is exactly the failure mode. `/migrate` is reinforcement (Layer 3), not the gate.
- **Branch protection on `main` only** (the existing BACKLOG item). Necessary but orthogonal: that
  makes the *code* gate *block*; this ADR is about gating the deploy step that lives *past* the merge.
  They compose — this is the sibling that extends gating beyond the merge button.
- **Per-project bespoke CI for each deploy target.** Rejected — not portable across the ~5 repos.
  The manifest is the portable seam that replaces bespoke wiring.

---

## Open questions (verify at build time — do not assume)

- **Exact CLI semantics.** `supabase db push --dry-run` *prints* the diff; *failing* on a pending
  delta may require `supabase migration list` (local-vs-remote) or an output check. The manifest
  contract is "exit ≠ 0 iff drift"; Discovery must verify the chosen command actually honors it.
- **Where 2b runs** — deploy/release pipeline vs. PR-against-a-branch-DB. Branch/shadow is preferred
  to keep prod creds off the PR path.
- **Manifest location/format** — standalone `deploy-targets.yml` vs. folding into an existing project
  config the harness already reads.
- **Other out-of-band kinds beyond migrations** — secrets rotation, feature-flag flips, infra applies.
  Same manifest, different `drift_check`; confirm the contract generalizes before claiming coverage.

---

## Tracking

**Proposed.** Not added to `V2-TRACEABILITY.md` — that matrix tracks R4-locked decisions only
("how we prove V2 was built as planned, not re-planned"), and ADR-0001 set the precedent of tracking
a proposed mechanism in `BACKLOG.md` until accepted. This ADR is tracked by the BACKLOG row
"Gate the out-of-band deploy steps (deploy-drift gate)". On acceptance, promote the first slice (2a)
into the active plan.
