# Pass 3 — Apply to OUR harness vs. the ground-truth map

Building on pass2: I apply pass2's transplantable-kernel-vs-non-transplantable-shell split (pass2
§H), the canon-is-a-liability-until-verified reframe (pass2 §G), the push-vs-pull context distinction
(pass2 §D), and the exogenous-model confound (pass2 §E) against `CANONICAL-HARNESS-AS-IS.md`. Every
gap below cites a ground-truth row or a confirmed absence. The Full-Analysis curator's gap table is
treated as claims; several collapse on contact with ground truth.

---

## (a) What we ALREADY do (cite ground-truth rows)

- **Skills as on-demand procedures.** Ground-truth §3b lists ~26 disk skills (`cr`, `feature`,
  `tdd`, `compound`, `migrate`, `queue`, `refactor`, …). Basis's layer 3 (pass1 §5.3) is the same
  construct; we are arguably ahead on workflow-opinionation. The curator's "Better" rating here
  survives.
- **Verification + tests as enforcement floor.** Ground-truth §3e (hooks) + §3f (CI: `ci.yml`,
  `integration.yml`) cover Basis's layer 6 (pass1 §5.6). `block-dangerous-git.sh` /
  `block-npm-install.sh` + pre-commit (tsc/lint/vitest) are our deterministic backstop.
- **Scope enforcement, per-task.** Ground-truth §5 lists `enforce-scope.sh` as **canon-declared**
  (TASK-TEMPLATE ALLOWED FILES) — but note this is a *canon* row, **not confirmed on disk** (it is in
  the "declared, NOT on disk" registry). So the curator's "Equal — we enforce scope per task" rating
  is **half-true at best**: the mechanism is documented, not verified present. (See gaps.)
- **A real memory layer.** Ground-truth §4 documents five canon stores + a sixth auto-memory store
  (`MEMORY.md` + 51 siblings). Basis's "memory/compound" equivalence (curator "Equal") holds
  conceptually; we materially exceed Basis on *manual* memory richness.
- **Interoperability at the format layer.** Ground-truth §3a shows we run `CLAUDE.md` **and**
  `AGENTS.md` at repo root. Basis's principle 4 (pass1 §3.4) — `AGENTS.md` + symlink — is something we
  partially mirror. Per pass2 §F this is format-level interop only, which is exactly where we also
  sit.
- **Sub-agent roles exist.** Ground-truth §3d: **23 disk agents** incl. 4 review lenses,
  hotfix-guard, solution-evaluator, the 6 spike agents. Basis's layer 4 (pass1 §5.4) "more than half
  a dozen roles" is a construct we already exceed in count.

## (b) REAL gaps it exposes — each cited

1. **No canon/not-canon authority taxonomy — and our memory model is the exact corpus that needs
   it.** Cite ground-truth §4: it explicitly names the **triple-duplication the canon both sanctions
   and forbids** (same fact in `memory.md` + `PITFALLS.md` + auto-memory `feedback_*`), with
   `/compound` flagging entries as "already covered by PITFALLS (redundant)," and states the Phase-3
   target is "ONE coherent model … every store one writer/one reader/one freshness rule." Basis's
   canon/not-canon cut (pass1 §4) + self-consistency-as-invariant (pass2 §B) is *precisely* the
   missing ontology that would let a checker collapse that duplication. This is a real gap, citation:
   **§4 (the Phase-3 crux)**.

2. **Declared-canon-vs-verified-canon is unmodeled, and ground-truth proves the rot is real.** Per
   pass2 §G, "canon" needs a third state (declared-but-failing). Cite the ground-truth **Correction
   log** (lines 19–28): the project audit artifact *itself rotted* — `HARNESS-AS-IS.md` carried four
   stale absence-claims (`CONTEXT.md`, `ARCHITECTURE.md` ground-truthed to exist). That is exactly
   Basis's staleness/contradiction failure mode occurring *inside our own canon*, with no scanner to
   catch it. Real gap; citation: **§0 Correction log + §3a** ("Present (audit had it stale-absent)").

3. **No automated context-maintenance loop (scanner/owners/CI-frontmatter).** Cite ground-truth §5
   (canon-only registry) and §3e: we have **no `session-end.sh`** memory hook (memory is "fully
   manual"), no daily scanner, no owner-frontmatter CI check anywhere in §3a–§3f. Basis's Automatic
   Context (pass1 §8) is absent. BUT per pass2 §C1 the *daily-worker* tier is scale-amortized and not
   yet justified for a single-project harness — so the real, sized gap is the **lightweight tier**: a
   manual/periodic consistency check + owner/last-verified frontmatter, not the full daily-agent
   automation. Citation: **§5** ("`session-end.sh` … disk memory is fully manual") and **§4(d)**.

4. **No diff-scoped `verifier` that closes inside the task.** Cite ground-truth §3c/§3e: `/cr` runs
   **at feature end** (9 passes + adversarial), and CI never verifies `.cr-ok` (the "Node 8.5(c)
   gap," §3f). There is no in-loop, pre-human, diff-scoped test/hook runner. Basis's `verifier`
   (pass1 §5.4) is the missing construct. Note the curator's framing cites `/cr-feature` — **retired
   v0.85** per ground-truth §3b — so the gap must be re-grounded to today's `/cr` + `/tdd`, which it
   survives. Real gap; citation: **§3c, §3f (the `.cr-ok`/CI hole)**.

5. **No unified external-context MCP for in-task debugging.** Cite ground-truth §2/§1: global MCP is
   **`notion` only**; project layer adds Supabase tooling but there is no single server exposing
   GitHub issues + Supabase logs + analytics for an agent mid-debug. Basis's layer 5 (pass1 §5.5) is
   absent. Severity is lower for us (single project, no Linear/Slack/PostHog stack) — frame as
   targeted, not wholesale. Citation: **§2 global inventory** (mcpServers = notion only).

6. **No root-file token-budget discipline (default-no audit).** Cite ground-truth §3a: `CLAUDE.md`
   exists and is "Aligned in purpose," but nothing in the map asserts a default-no / instruction-not-
   description audit has ever run against it; `CONTEXT.md` (15 KB) and a long `CLAUDE.md` are both
   auto-context. Per pass2 §D the real action is separating **push-context** (audit hard for
   default-no) from **pull-context** (must be correct, need not be small). This is a confirmed
   *absence of a discipline*, not a missing file. Citation: **§3a** (governance docs; no audit row).

## (c) Weaknesses in the article's OWN reasoning

- **No control for model improvement (pass2 §E).** The 5x/2.5x is uncontrolled; three months of
  context work overlaps three months of model gains. The article claims architecture as cause with
  no counterfactual. Our v2 should *not* adopt a Basis mechanism on the strength of these numbers
  alone.
- **Interoperability claimed but only format-deep (pass2 §F).** Layers 4–5 (roles + MCP) are
  current-harness-shaped; "symlink `AGENTS.md`" decouples vocabulary, not architecture. Don't inherit
  the principle as "achieved."
- **The canon/not-canon binary is under-specified (pass2 §G).** It has no slot for declared-canon-
  that-has-rotted — which is the very thing the scanner exists to catch, so the taxonomy alone is
  insufficient and the article presents it as if it were sufficient.
- **default-no vs. every-file-is-context is an unreconciled tension (pass2 §D).** The article uses
  one word "context" for two loading mechanisms; copied naively it produces either a bloated root or
  a starved tree.
- **Amortization masquerading as principle (pass2 §C1).** The daily-scanner/daily-worker economy is
  justified by "thousands of onboardings/month." A reader at lower volume who adopts it inherits pure
  overhead. The article never states the break-even.

## (d) Does it warrant fresh external research?

**Mostly no — synthesize.** The transplantable kernel (canon/not-canon, push-vs-pull, self-
consistency-as-invariant, instruction-not-description) is fully captured here and maps cleanly to
ground-truth §4/§5/§3a; no further reading is needed to act. Two narrow exceptions, both scoped:

1. **Owner/last-verified frontmatter + a CI consistency check** — before building, do a *bounded*
   check of how the existing global Matt-Pocock skills (ground-truth §1 "CONTEXT.md coupling")
   already expect frontmatter, so we extend their convention rather than invent a parallel one.
   Internal inspection, not external research.
2. **Unified-MCP scope** — defer until a second project exists (ground-truth §8: harness has "never
   been installed anywhere but event-vendor"). No external research warranted now; it would be
   premature per the build-what's-needed-now rule.

Everything else is a synthesis-and-build decision against the map, not a re-research task. The
Full-Analysis page's own "must not be used to make implementation decisions / use the delta page"
warning reinforces this: re-grounding against our current map (done above) supersedes re-reading the
snapshot.
