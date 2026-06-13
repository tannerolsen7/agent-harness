# Pass 3 — Apply: Packmind vs. OUR harness (against CANONICAL-HARNESS-AS-IS)

Building on pass2: I carry forward pass2's five load-bearing findings — (B) drift has two opposite
directions and the article only sees one; (C) "add-on-observed-failure" is a monotonic ratchet that
re-creates bloat and needs a decay rule; (D) the process/knowledge skill binary smuggles an undefended
taxonomy; (F) the article assumes more governance is strictly better and never models the agent
maintaining its own context; (G) the real moat is context *accuracy/currency*, not volume. Each section
below cites a ground-truth row from CANONICAL-HARNESS-AS-IS.md. No gap is listed without a citation.

## (a) What we ALREADY do — the article describes our existing target

- **Engineering playbook = our split context docs.** Packmind's "playbook" (pass1 concept 1) is exactly
  our `CLAUDE.md` + `AGENTS.md` + `CONTEXT.md` + `SOUL.md` set. All four are **present on disk** —
  CLAUDE.md/AGENTS.md/SOUL.md aligned [canon §3a], CONTEXT.md built (15 KB, PR #92) [canon §3a]. The
  article's "name the collection" deciding-row resolves to something we already have and split *finer*
  than Packmind's single artifact.
- **The commodity/context framing already lives in our values layer.** Pass2(G)'s "context is the moat"
  is what `.claude/SOUL.md` (1-page values, present and aligned [canon §3a]) plus the canon's
  "10 · Principles" page exist to hold. The curator's recommendation ("worth adding to SOUL.md") is
  partly redundant — we have the home; the question is only the one sentence.
- **Skills as first-class playbook elements — built and over-built.** Disk has **26 project skill dirs**
  plus 23 agents [canon §3b, §3d]. Packmind launched skills in Jan 2026 as a *new* product feature; we
  already run a far larger skill surface than the article describes as state-of-the-art.
- **Drift detection / context audit is already a named, owned capability — in canon.** The canon
  documents `/scan-context` (full template) and `/compound` Step 7 quarterly stale-review of memory.md
  (90-day `last_seen`) [canon §4, §5]. The article's whole "add drift framing to /scan-context"
  recommendation presupposes a capability our **canon already specifies**.
- **The bootstrapping illusion is already our doctrine, with sharper teeth.** Our canon's Page 13 Model
  Capacity Audit already says "If you can't name a failure mode that the constraint prevents, the
  constraint is overhead" and pre-authorizes removing capability-proxy scaffolds [canon §9]. That is the
  bootstrapping illusion's *subtraction* half — which pass2(C) showed the article is missing. CLAUDE.md
  itself encodes "Build what's needed now / Research before guessing / do not implement future cases."
  **We are ahead of the article here, in writing.**

## (b) REAL gaps it exposes — each cites a ground-truth section or confirmed absence

1. **`/scan-context` is canon-documented but ABSENT on disk — so we have NO drift detector at all.**
   [canon §5: "`/scan-context` … Documented skills with no disk dir"; confirmed absent.] This is the
   single highest-value mapping in the article. Packmind names *why* the detector matters (drift compounds,
   invisibly); our ground-truth says the detector our canon promises **does not exist as a project skill**.
   The gap is not "frame it better" (the curator's extrapolation) — it is *the mechanism is missing*.
   Pass2(B) sharpens the build spec: whatever we build must catch **both** drift directions — doc-stale
   (code moved, doc didn't) **and** doc-fiction (doc asserts a rule the code never followed). Our map
   proves doc-fiction is our live failure class: phantom refs `learned-patterns.md`, `review-log.md`,
   `triage-inbox.md`, `skills-lock.json`, `agentic-system-enabled` are "referenced on disk, never built"
   [canon §6], and `/cr-feature` is "RETIRED v0.85 … yet still referenced in canon's own Page-11 and
   Page-14" [canon §3b]. A pure doc-vs-code scanner (the article's only model) would miss the canon's own
   stale self-references. **Build target: a drift/context-audit pass keyed to both directions** [maps to
   canon §5 build-or-reject].

2. **No session-end memory capture — our "add on observed failure" loop is fully manual, so the
   bootstrapping discipline can't actually run.** [canon §3e: `session-end.sh` (Stop → memory candidates)
   "Canon's memory-capture hook — absent; disk's memory is fully manual"; canon §5 lists it as a build item.]
   Packmind's core discipline (pass1 concept 4) is "when something fails repeatedly, add the rule that
   prevents it." Our map shows the *capture* half of that loop has no automation — every memory entry is
   hand-written. The article's principle is sound and we *endorse* it (CLAUDE.md "when a mistake is
   corrected, add a rule to memory.md"), but the enforcement hook the canon specifies is absent. Real gap:
   **the observed-failure→rule loop has no trigger.**

3. **The monotonic-ratchet / decay problem (pass2 C) is real for us and only half-solved.** Our canon has
   the *judgment* rule ("ghost rules if unobserved 90 days; collapse + quarterly audit", memory.md 90-day
   `last_seen`) [canon §9, §4] — but it is encoded **only in prose, in no tooling** [canon §4: "encoded in
   no tooling"; "freshness rules exist for only 3 stores"]. So we have the article's missing subtraction
   *principle* but, like the article, no mechanism that runs it. The article doesn't expose a new gap here;
   it *confirms* a gap our own map already flags — which strengthens the case to build the decay side of
   `/scan-context` (gap 1) rather than only the staleness side.

4. **Triple-duplication is the bloat the bootstrapping illusion predicts — and we have it.** [canon §4:
   the same corrected-mistake facts live in `.claude/memory.md` + `PITFALLS.md` + auto-memory `feedback_*`
   simultaneously; `/compound` itself flags memory entries as "already covered by PITFALLS (redundant)".]
   Pass2(G) reframed the moat as accuracy/currency, not volume; our map shows volume *without* a dedup
   mechanism. The article's bootstrapping framing gives this a name and a teachable cause, but the gap
   (one-writer/one-reader/one-freshness-rule per store) is already specified by our own §4 — the article
   adds motivation, not a new gap.

5. **No agent-maintains-its-own-context loop (pass2 F) — and our harness is explicitly heading toward
   unattended/autonomous runs.** The disk has `worktree-create.sh` + Tier-0 prod-key firewall for
   UNATTENDED mode [canon §3e, §6] and a whole autonomous-run posture, yet drift detection + memory
   capture (gaps 1–2) are absent. The article cannot help here — pass2(F) showed it has no model for the
   agent that detects drift also proposing the fix. This is a confirmed-absence gap *the article makes
   visible by omission*: our most distinctive disk advance (unattended runs) has the least context-
   maintenance support. [canon §6 disk-only registry: worktree-create/firewall built; §5: drift + memory
   hooks absent.]

## (c) Weaknesses in the article's OWN reasoning (carry from pass2)

- **Self-interested two-sided argument (pass2 A).** "Context is uniquely yours" (why it matters) and "buy,
  don't build" (buy our platform) are patched with an untested content/infrastructure split. For us this is
  near-noise: we have *already* chosen build, the bus-factor argument *self-admittedly doesn't transfer to
  solo* (pass1 transfer table), so the entire build-vs-buy section is inapplicable. Treat as marketing.
- **Drift is under-theorized — single-direction (pass2 B).** The article models only doc-stale drift and
  has no detector for doc-fiction/ghost rules — which §6's phantom-refs prove is *our* live failure mode.
  Adopting the article's frame verbatim would under-spec our detector.
- **The add-only ratchet contradiction (pass2 C).** "Add on observed failure" (cure for bloat) and the
  Design Challenge's separate subtraction audit (undo for bloat) are never reconciled; the article presents
  a growth rule with no decay rule and proposes a manual cleanup to fix the bloat its own rule creates.
- **Undefended process/knowledge skill taxonomy (pass2 D).** The recommendation to write more "knowledge"
  skills has no test for when externalizing judgment beats letting the code be the source of truth — and a
  knowledge-skill is the *most* drift-prone artifact. Adopting Application-claim 3 ("encode 2-3 pieces of
  Tanner's head-knowledge") without a "does the model already infer this?" gate would manufacture exactly
  the ghost rules our §6/§9 warn against.
- **Marketing stats (pass1).** 91%/5% is self-tagged unverified; 25% lead-time is unverified customer
  claim. The article uses them rhetorically anyway. Do not cite any of these numbers in V2.
- **Glib scale-invariance (pass2 E).** "/scan-context weekly" is asserted as the solo equivalent of an
  org's daily automated scanner without asking whether weekly is the right cadence for a single writer
  running serial sessions; our detection economics are different in kind, not just degree.

## (d) Does it warrant FRESH external research? — Disciplined answer: mostly NO.

- **No** on the core concepts. Drift, bootstrapping illusion, commodity/context, skills-as-knowledge are
  all already represented in our canon (drift→`/scan-context` + §9; bootstrapping→§9 golden rule + CLAUDE.md
  "build what's needed now"; skills→26 dirs). The article adds *vocabulary and motivation*, not mechanism.
  Synthesize, don't re-research: lift two teachable names ("context drift", "bootstrapping illusion") and
  the one-sentence commodity/context framing into SOUL.md / Page 10 — a doc edit, not a research task.
- **No** on build-vs-buy — inapplicable to a solo, build-committed harness (self-admitted in the transfer
  table).
- **Narrow YES, but as a DESIGN task not external research:** the *drift-detector design* (gap 1) deserves a
  focused internal spike because pass2(B) showed the article's single-direction model is insufficient and
  our §6 phantom-refs prove the second direction is live. That spike reads our own repo + canon, not the
  web — it is synthesis against the ground-truth map, not fresh external research.
- The **one** thing that might justify a *small* external look later is the open question the article itself
  poses (pass1 open-Q2/Q4): empirical latency from "context entry added → agent reliably follows it", and
  skill-versioning/deprecation mechanics. But that is downstream of building gaps 1–2; do not research it
  now. Prefer synthesize over re-research.
