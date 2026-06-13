# Pass 3 — Apply: the article against OUR harness (ground-truth map)

Building on pass2: the article's most transferable contribution is the rung-taxonomy of verifiers
(pass2 §1) and its warning that `/goal` is "control-flow cosplaying as verification" (pass2 §3). Its
load-bearing assumption — that "the pipeline does the load-bearing work" (pass2 §8) — is itself a claim
to verify, because the article assumes a system that is fully BUILT, while the ground-truth map shows
much of it is advisory-only or absent. This pass tests the article's prescriptions against
`CANONICAL-HARNESS-AS-IS.md`, citing rows. No gap is asserted without a citation.

Map citation form: `[map §N]` = section of CANONICAL-HARNESS-AS-IS; `[disk §X]`/`[canon §Y]` as the map uses them.

---

## (a) What we ALREADY do — the article describes doctrine our harness already declares

1. **Fresh-context, spec-withheld review at every phase (`/cr`).** The article's "right column" — four
   fresh-context lens agents + adversarial pass — is real on disk: `[map §3d]` confirms 23 agents
   including all 4 lenses (assumption/composition/cascade/abuse); `[map §3c]` confirms `/cr` runs 9
   passes + an adversarial pass. So the article's premise that we *have* a stronger verifier than
   `/goal`'s grader is grounded. (Caveat carried to (b): the map also shows the pass-count is described
   three inconsistent ways.)

2. **`/loop` already exists and is exactly as the article describes.** The runtime skill list in this
   environment registers `loop` ("Run a prompt or slash command on a recurring interval (e.g. /loop 5m
   /foo)… poll for status"). The article's `/loop` = interval-poller characterization matches our
   installed skill 1:1. We do NOT need to build `/loop`; the article's `/loop` vs `/goal` distinction
   (pass1) is descriptive of tools we partly already have.

3. **Blast-radius caps and reversibility gating as doctrine.** The article leans on "400-line cap, 5-PR
   overnight cap, REJECT on out-of-spec/auth/schema." The map shows the *philosophy* is present —
   `/queue` exists `[map §1, §3b]`, UNATTENDED worktree mode and Tier-0 credential isolation are built
   `[map §3e worktree-create.sh; §6]` — so the article's "encode reversibility in which tasks you point
   it at" lands on an existing seam, not a vacuum.

4. **CI required-check as the intended unforgeable gate.** The map confirms CI exists (`ci.yml` +
   `integration.yml`, `[map §3f]`) and that `.cr-ok` is the pre-push sentinel `[disk workflow; map §3f]`.
   The article's "only truly unforgeable gate" maps to a real component.

## (b) REAL gaps the article exposes — each cites a map row or confirmed absence

1. **The article's `/goal` "Standing Rule" is unenforceable on our disk — there is no scope/condition
   guard to back it.** The article's safety rests on a *written* condition pinned to MUST-FIX=0 + CI +
   cap (pass1 prescription #1, Standing Rule), but pass2 §4 showed this is an advisory control about not
   trusting advisory controls. Our map confirms we cannot enforce it: `enforce-scope.sh` is **canon-
   structural but ABSENT on disk** `[map §3e; §5]`, and `block-dangerous-bash.sh` (the safety-floor bash
   guard) is likewise **ABSENT on disk** `[map §3e; §5]`. So if we adopt `/goal`, nothing on disk stops a
   transcript-only stopping string from being used — the article's rule would be one more advisory line in
   CLAUDE.md, exactly the Pillar-1 gap the map flags the whole system as having (`[map §3e] "Both agree
   the system is overwhelmingly advisory"`).

2. **`.cr-ok` → CI is NOT actually unforgeable in our build — the article's "unforgeable gate" premise is
   false on disk.** Pass2 §2/§5 argued the only real guard against false-positive completion is CI
   re-checking *outside* the loop. But the map records the **Node 8.5(c) gap: CI never verifies `.cr-ok`**
   — "`.cr-ok` chain has the same hole (gitignored, never reaches CI)" `[map §3f]`. The sentinel is
   consumed by the local pre-push hook only `[map §3f]`. So the article's load-bearing claim that CI is
   "the only truly unforgeable gate (Node 8.5c)" is, per our own map, **the citation of a known HOLE, not
   a guarantee.** A `/goal` loop whose condition reads ".cr-ok exists" is trusting a sentinel that CI
   never re-validates. This is the single most important gap the article exposes: its safety story
   depends on a gate the map says is incompletely wired.

3. **No `/goal` skill exists on disk — the article describes a tool we have NOT installed.** The runtime
   skill list registers `/loop` but no `/goal`; the map's skill inventory `[map §3b]` lists our 26 project
   skills and the canon-documented set, and `/goal` appears in neither. The article is a *pre-adoption*
   analysis of a Claude Code v2.1.139 primitive we have not yet wired. Gap = a build/reject decision, not
   a drift to reconcile. (Per the map's citation rule §"How later phases cite this map," adopting `/goal`
   would be a new disk-only item, candidate for §6.)

4. **The article assumes a `/change` REJECT path that the map does not confirm as built.** Prescription
   #4 routes failed `/goal` runs to "UNATTENDED=1 → re-queue to `/change`." The map's skill inventory
   `[map §3b]` does not list a `/change` skill among the 26 disk skills or the canon set; `/cr`'s own
   structure on disk has "**No REJECT tier, no UNATTENDED branching**" per `[map §3c, disk row]`. So the
   fallback routing the article depends on is **partially absent** — the REJECT tier the article assumes
   `/goal` can hand off to is, on disk, not present in `/cr`. Adopting the article's prescription would
   require building that path first.

5. **Our `/cr` pass-count is described three inconsistent ways — a `/goal` condition pinned to "`/cr`
   returns MUST FIX = 0" inherits that ambiguity.** `[map §3c]` documents three framings (canon 9 incl.
   adversarial; disk "9 + Pass 11, no Pass 10"; runtime "9 plus adversarial"). The article's prescription
   #1 condition string assumes a crisp, single "MUST FIX = 0" signal. The map shows the MUST-FIX surface
   itself isn't single-sourced, so a machine-readable stop condition would need a canonical `/cr` verdict
   artifact that the map does not confirm exists. (Confirmed absence: no single `/cr`-verdict file is
   listed in `[map §3f]` scripts/CI or `[map §4]` memory stores.)

## (c) Weaknesses in the article's OWN reasoning (from pass 2, now with map backing)

1. **Two framings never reconciled (pass2 §3): "different layers" vs "strictly weaker verifier."** The
   article uses the generous frame to argue adoption and the severe frame to argue distrust. The map
   sharpens which is right *for us*: because our CI does not re-verify `.cr-ok` `[map §3f, Node 8.5c]`,
   `/goal`'s grader is not "a weaker layer beneath a strong one" — in our build there is no strong
   independent backstop at merge, so the grader is closer to being the *last* check than the article
   admits. The severe frame is the correct one for our actual disk state.

2. **The article trusts "the pipeline writes success into the transcript" (pass2 §2) without noticing the
   pipeline's own write-paths are advisory.** It assumes `/cr`+CI verdicts arrive in the transcript as
   tool-surfaced ground truth. But per `[map §3e]` the enforcement is "overwhelmingly advisory" and per
   `[map §3f]` the sentinel never reaches CI — so what lands in the transcript is closer to the agent's
   narration of the gate than the gate's own output. The article's clean "weak grader → thin wrapper
   around real verifiers" conversion (pass2 §2) is weaker on our disk than on the idealized system it
   assumes.

3. **The article inherits the canon's pillar/Node numbering as if settled; the map shows that scaffolding
   is itself contested.** It cites Pillars 1/2/3/5 and Nodes 3/8.5c/12/13.3 as fixed. The map documents
   the canon is "internally inconsistent" with multiple unresolved contradictions `[map §7]` and that
   node dispositions were still being decided across sessions (memory: "Layer 5 synthesis inputs"). The
   article's confident pillar-mapping is rhetorically clean but rests on a doctrine layer the map flags
   as still in flux — a §9 model-capacity re-audit is explicitly pending. Not fatal, but the article
   over-states the fixity of its own coordinate system.

4. **No principle for `/goal` vs `/loop` selection (pass2 §6).** The article gives the example ("deploy
   is green" spins forever) but not the rule (use `/goal` only when the condition becomes true as a direct
   causal result of the agent's own in-session actions). For our harness this matters because we DO have
   `/loop` installed (runtime skill list) and `/schedule`/cloud routines — a careless operator could point
   `/goal` at a world-closed condition. The article leaves that selection rule implicit.

## (d) Does it warrant fresh external research? — disciplined answer: mostly NO

**Synthesize, do not re-research, for the doctrine.** The article's verification taxonomy (pass2 §1),
reversibility gating, and routing prescriptions are all reflections of doctrine we already hold `[map §1,
§3e, §6]` and of the pending §9 model-capacity re-audit. Re-researching maker≠checker or blast-radius
philosophy would duplicate the corpus the map already integrates (memory: "AI-Native Engineering
Research," "Agent-harness research tree"). Per the map's discipline ("no proposal survives without a
citation"), the value here is mapping, not new sources.

**Two narrow, BOUNDED verification items are warranted — and they are about OUR disk, not the world:**

1. **Verify the `/goal` mechanics the article self-flagged as unconfirmed, IF and only if we move to adopt
   it.** The article hedges the exact Claude Code release (v2.1.139 / ~May 12 2026), Codex GA status, and
   whether the grader truly runs no tools. Adoption requires confirming the current `/goal` Stop-hook
   contract against `code.claude.com/docs/en/goal` — a single doc fetch, not a research fan-out. (Trigger:
   only on a build decision.)

2. **No external research is needed to act on the biggest finding — it is an internal fix.** The decisive
   gap (b)(2)/(b)(4): `.cr-ok` never reaches CI `[map §3f, Node 8.5c]` and `/cr` has no REJECT/UNATTENDED
   branch `[map §3c]`. The article makes adopting `/goal` *contingent* on those being real; the map says
   they are holes. So before `/goal` is even a candidate, the prerequisite work is internal: wire `.cr-ok`
   verification into CI and build the REJECT path. That is an engineering task against known map rows, not
   a research question.

**Net recommendation (one line):** Treat `/goal` as a deferred, low-priority continuation wrapper whose
adoption is *blocked* until the two structural prerequisites the article unknowingly depends on (CI-
verified `.cr-ok` `[map §3f]`; `/cr` REJECT/UNATTENDED routing `[map §3c]`) are built — and even then, scope
it to direct-`/queue` reversible tasks only `[map §6 candidate]`. The article is most useful not as an
adoption case but as the thing that exposed that our "unforgeable gate" is, per our own map, not yet
unforgeable.
