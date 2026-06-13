# Pass 3 — Apply: Basis vs our harness, against the ground-truth map

Building on pass2: I apply pass-2's sharpened theses to our actual harness, using
`CANONICAL-HARNESS-AS-IS.md` as the only admissible evidence. Rule: no gap survives without a citation to
a ground-truth section (`[map §X]`) or a confirmed absence. The article's own "Application to This System"
section is treated as **claims to test**, not findings to inherit — and pass 2 already showed why (its
"Verified" ledger over-states secondhand provenance).

## (a) What we ALREADY do

- **Canon vs not-canon, partially — and in the exact direction Basis prescribes.** Pass2's "canonicality
  is a truth-claim that decays, kept honest by a maintenance loop" maps onto a structure our map already
  records: our memory model has *lifecycle stages* baked in — `memory.md` (session corrections),
  `RECURRING-FINDINGS.md` (pipeline-only, never read by implementers), `PITFALLS.md` (promoted canonical
  traps), plus `docs/solutions/` and `docs/adr/` (locked decisions) [map §4]. ADRs *are* our canon-with-
  authority; `docs/specs/` *is* our not-canon intent layer. So the conceptual distinction Basis "unlocks"
  is not absent here — it is **implemented as separate stores rather than as a declared per-artifact
  label**.
- **Default-no / curation already operates as a hard rule, not a vibe.** Basis's default-no maps onto our
  standing CLAUDE.md disciplines "Build what's needed now," "do not extract a shared abstraction until the
  third occurrence," "write the minimum code that satisfies the requirement" — and the canon's own
  **Page 13 Model Capacity Audit**, whose golden rule is *"if you can't name a failure mode the constraint
  prevents, the constraint is overhead"* [map §9]. That is default-no applied to *rules themselves*, which
  is stronger than Basis's default-no applied to *context lines*.
- **Localization / scoped instructions — we do the skill-scoping half.** Basis Layer 3 (on-demand skills
  for cross-folder knowledge) maps onto our ~26 project skills loaded on trigger, and trigger-gated CLAUDE.md
  rules ("if the task touches Supabase, invoke `/supabase`") [map §3b]. Cross-cutting knowledge already
  lives in on-demand skills, exactly the article's authoring-rule-#3 resolution.
- **Verifier (diff-scoped, pre-PR) — substantially built, and broader than Basis's.** Basis's verifier =
  diff-scoped tests + pre-commit hooks before PR. We have the pre-commit hook chain (ESLint, `tsc
  --noEmit`, unit tests) [map §3e pre-commit], a pre-push gate (tests + `next build`) [map §3e pre-push],
  and `/cr` — a 9-pass + adversarial review over the **branch diff** [map §3c]. Our `/cr` is diff-scoped by
  construction and goes well past Basis's "run scoped tests."
- **Standards-enforcer — we have its strongest form.** Pass2 separated "behavioral verifier" from
  "canon-conformance enforcer" and noted the enforcer is the agent-native one. Our `/cr` already does
  canon-conformance: its passes include "layer violations, doc drift, architectural inconsistency"
  (skill registry) and our CLAUDE.md mandates doc updates in the same commit. That **is** the
  standards-enforcer the article's Application section proposes adding to `/cr-feature`.
- **Owner/freshness on stores — partially.** Basis's `owner` + `last-verified`: our `memory.md` already
  has a **90-day `last_seen` freshness rule** and a quarterly `/compound` Step 7 stale-review;
  `RECURRING-FINDINGS` has a cap-at-5; `PITFALLS` is changelog-driven [map §4]. Freshness exists for 3
  stores already.

## (b) REAL gaps it exposes — each cited

1. **No declared canon/not-canon *label* — only implicit-by-store separation, and the stores leak.**
   The map's headline finding is **bidirectional drift** and the canon being **internally inconsistent**
   (two feature loops, two reviewer names, Pages 12↔13 contradictions) [map §0, §7]. Pass2's point lands
   exactly here: our problem is not "load less," it is *agents cannot tell which of two contradicting
   artifacts is the current truth-claim*. We have no `authority-map` and no per-artifact `canonical:`
   field; the only thing distinguishing canon from intent is which folder it sits in — and §7 proves the
   folders disagree with each other. This is a real gap: **the canon contradicts itself with no label
   saying which side wins** except an undocumented "later-dated page wins" convention [map §7]. Citation:
   `[map §7]`, `[map §0]`.

2. **No automated context-maintenance loop at all — the scanner/worker category is a confirmed absence.**
   Pass1's daily scanner (staleness, contradictions, duplicated instructions, broken refs) has **no disk
   equivalent**. The map shows `/scan-context` is **documented in canon but ABSENT on disk**
   [map §5: "`/scan-context` … no disk dir"], and the only maintenance ritual is manual `/compound`. The
   drift the map documents (`HARNESS-AS-IS.md` itself rotted — inherited four stale absence-claims that
   ground-truthed false [map §0 correction log]) is *precisely* the failure a scanner catches. We have a
   live, dated proof that our context artifacts rot undetected. Citation: `[map §5]`, `[map §0 correction
   log]`.

3. **The triple-duplication is the contradiction-detection gap Basis's scanner exists to close.**
   Pass2: a maintenance loop's job is catching internally-inconsistent canon. The map documents the same
   corrected-mistake facts living in `memory.md` + `PITFALLS.md` + auto-memory `feedback_*` files
   simultaneously, with `/compound` itself flagging entries as "already covered by PITFALLS (redundant)"
   [map §4]. Basis's "duplicated instructions" scanner check is the named mechanism we lack. Citation:
   `[map §4]`.

4. **The auto-memory store has no owner, no freshness rule, and no place in any model — the `owner`-field
   gap, concretely.** Basis requires every canonical artifact to carry an `owner`. The map records a
   **sixth store** — auto-memory `MEMORY.md` + 51 siblings — that is "**not in the canon at all**,"
   written by the Claude Code subsystem, with no writer/reader/freshness assignment [map §4, §6]. Pass2's
   "the owner is the out-of-loop verifier that stops the loop eating its tail" makes this sharp: our
   largest-by-count knowledge store has *no* out-of-loop anchor. Citation: `[map §4]`, `[map §6]`.

5. **`/scan-context` (and the canon/not-canon classification it would need) is a canon-declared,
   disk-absent build candidate — so the article's #1 sequencing advice targets a real hole.** The
   article says: classify canon/not-canon first, *then* run `/scan-context`. The map confirms both halves
   are absent on disk: `/scan-context` is canon-only [map §5], and there is no authority map anywhere in
   §3a's governance-doc inventory (no `authority-map.md` row exists). Citation: `[map §5]`, `[map §3a]`
   (absence — no such row).

6. **Enforcement is overwhelmingly advisory — Basis's "Layer 6 tests as backstop" exposes our missing
   deterministic floor for *context* rules.** The map's net enforcement finding: "**Both agree the system
   is overwhelmingly advisory** — neither has a deterministic backstop for the bulk of skill bodies,
   CLAUDE.md rules, or the autoMode lists" [map §3e]. Basis's CI-validates-frontmatter check is a
   deterministic backstop for *context integrity* specifically; we have CI for code (`ci.yml`: tsc/lint/
   vitest [map §3f]) but **no CI check that validates any knowledge artifact** — no frontmatter check, no
   contradiction check, nothing that would have caught the §7 canon contradictions. Citation: `[map §3e]`,
   `[map §3f]`.

## (c) Weaknesses in the article's OWN reasoning (carry into any adoption)

- **Secondhand provenance dressed as "Verified"** (pass2 contradiction #1). The map's whole governing rule
  is "no proposal survives without a citation" [map preamble]; the Basis page would *fail its own bar* —
  its load-bearing blog claims cite intermediary snapshots, not the primary. Adopt the *ideas*, never cite
  the *numbers* (5x/2.5x/20–30%) as evidence in a V2 proposal — they are uncontrolled and un-refetched
  (pass2 contradictions #1, #2).
- **Two-bucket canon/not-canon is too crude for our actual failure** (pass2: canonicality decays). Our §7
  contradictions are *canon-vs-canon* (two skills pages disagree), not canon-vs-spec. A binary label
  wouldn't resolve them; we need a *precedence rule* (the "later-dated wins" convention [map §7]) made
  explicit and machine-checkable. The article offers no precedence mechanism — it assumes canon is
  self-consistent, which §7 proves ours is not.
- **The closed agent-fixes-agent loop has no external anchor** (pass2). Importing Basis's "daily workers
  auto-implement scanner findings" would be actively dangerous here: our map already shows agents must not
  edit guard files / settings without human handoff (memory: "No agent edits to guard files"), and the
  destructive-op floor [CLAUDE.md] forbids unattended mutation. The article's own Application section
  hedges this correctly ("get the compound agent stable first") — so even the article doesn't fully trust
  its own loop at solo scale. Keep maintenance *detection* automated; keep *repair* human-gated.
- **The localization premise breaks on cross-cutting safety rules** (pass2). Default-no + push-rules-down
  would, applied naively, move our omnipresent destructive-operation floor and Tier-0 credential rules into
  on-demand skills — exactly the rules that must load *always* because they're never task-relevant until
  they save you. Page 13 already protects these as "keep verbatim — safety, never remove" [map §9]; Basis's
  default-no must be **subordinated** to that, not allowed to override it.

## (d) Does it warrant fresh external research? — No. Synthesize.

Disciplined answer: **no new external research.** Reasons:
- The article's transferable core (canon/not-canon labeling, default-no authoring gate, context-as-
  maintained-artifact, owner/freshness frontmatter) maps cleanly onto **already-cited rows** [map §4, §5,
  §6, §7, §3e] — it sharpens framing, it doesn't introduce an unknown we must go learn.
- It corroborates, rather than contradicts, the map's existing direction (the map *already* names "one
  coherent memory model: one writer/one reader/one freshness rule, collapse triple-duplication" [map §4
  Phase-3 target] — Basis is independent confirmation of that exact target, not a new requirement).
- The one genuinely novel mechanism (automated daily scanner) is, per pass2 + (c), **deliberately not**
  something to import wholesale at solo scale; the build-vs-reject decision is a §5 candidate call, not a
  research question.
- The only true unknowns the article raises ("Clueso," Basis's stale-vs-wrong scanner classification,
  pre-systematization baseline) are *about Basis*, not about our harness — answering them changes nothing
  in our build plan.

**Exception worth one narrow check (not full research):** whether `vitest` supports diff-scoped test
selection by changed-path — a 10-minute tooling verification, not a research pass — *if* a future slice
decides to add a diff-scoped pre-PR test gate beyond the existing pre-commit chain [map §3e]. Prefer
synthesize over re-research everywhere else.
