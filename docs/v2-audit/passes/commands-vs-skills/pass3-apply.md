# Pass 3 — Apply: Commands-vs-Skills vs OUR harness (ground-truth map)

Building on pass2: I apply pass2's **two-decision activation/load grid** (§2.8 — activation-control by
reversibility-of-false-trigger; load-tier by trigger-existence-not-length), pass2's distinction
between a **trigger-gate and a kill-gate** (§2.4), and pass2's demand that the article's premises
about us be **adversarially verified** (§2.9) — before any of its recommendations are inherited. Every
gap cites a ground-truth row or a confirmed absence. Disk facts below were directly verified this
session (line counts, frontmatter inventory, skill list); I cite those as `[verified]`.

---

## (a) What we ALREADY do — and where the article is right about us

- **Unified skills machinery; no legacy `.claude/commands/`.** `[verified]` no `.claude/commands/`
  dir exists; all 26 skill dirs use `SKILL.md`. Ground-truth §3b ("26 project skill dirs"). The
  article's "commands merged into skills" is not a migration we face — **we are already entirely on
  the skill form.** This is a genuine non-gap: the article's framing question ("command or skill?")
  is moot for us.
- **AGENTS.md as single root + skills-based harness.** Ground-truth §3a (AGENTS.md "Aligned"),
  §1 (runtime skill list). The article's "your harness is already skills-based with AGENTS.md as the
  single root — the research validates rather than changes it" is **correct.**
- **Skills already carry `name`+`description` frontmatter.** `[verified]` 25/26 skills have `name:` +
  `description:` (one is the empty `dep-update` stub, ground-truth §3b/§6). So tier-3 progressive
  disclosure's *prerequisite* (a description to match on) already exists — we are not at zero.
- **Side-effectful skills are explicit-by-convention today.** `/cr`, `/queue`, `/feature` are
  human-typed in practice (ground-truth §3c/§1). The article's recommendation #2 partly describes
  existing behavior — but see gap (b)(2): convention ≠ the `disable-model-invocation` flag.
- **Git-canonical commit discipline.** CLAUDE.md mandates committing settings/skills before agents
  run (memory: "settings.json must be committed before AFW runs"). The article's "Routines only see
  committed project-level skills… aligned with your Git-canonical model" is **correct and already
  enforced** — a non-gap.

**Corrections to the article about us (per pass2 §2.9 adversarial check):**
- **`/change` does not exist.** `[verified]` only `behavior-change` exists; no `/change`. The
  article's recommendation #2 names "`/change` gates migrations" — that is a **phantom skill**
  (the real migration skill is `/migrate`, ground-truth §3b). The recommendation still applies to
  `/migrate`/`/queue`, but the article cited a skill that isn't there.
- **"799 lines" is exactly right.** `[verified]` CLAUDE.md 325 + AGENTS.md 474 = **799**. The
  article's one hard number about us checks out — unusual for a claim-about-us, worth noting.
- **The Pillars/Nodes/open-thread #4/"KILLED-list"/"Phase 1 spawning rule" it cites are
  planning-layer, not on the ground-truth map.** The map (§ headline) treats canon as a drifted
  design target, not fact. Recommendations anchored only to those (notably #1's "Phase 1 spawning
  rule") rest on decisions the map does not ratify — treat as *proposed*, not *locked*.

## (b) REAL gaps it exposes — each citing ground-truth or a confirmed absence

1. **Spawn/activation conditions are NOT in the descriptions where the model reads them — and our
   live descriptions are phrase-keyed, the §9 anti-pattern.** `[verified]` the `/cr` description reads
   *"Use… when the user says '/cr', 'run a code review', 'review this branch'…"* — literally
   trigger-words, not a situation. Ground-truth **§9 (Model Capacity Audit)** flags
   **"phrase-keyed skill descriptions → trigger should be the situation, not the words"** as a
   capability proxy to **replace**. So the article's mechanic (description IS the trigger) exposes a
   real gap, but pass2 §2.3 sharpens it: the fix is **not** the article's "front-load trigger words"
   — that *is* the anti-pattern — it is to **rewrite descriptions as situations**. Confirmed-absence
   anchor: no skill encodes a sub-agent-spawn *situation* in its description `[verified: only name +
   description present, descriptions are phrase-keyed]`. Two-part gap (pass2 §2.8 grid-A): (i) move
   activation conditions into descriptions, (ii) as *situations*, satisfying §9.

2. **Zero structural invocation-control frontmatter — but the right tier for irreversible actions is
   a hook, not the flag (pass2 §2.4).** `[verified]` 0/26 skills use `disable-model-invocation`,
   `user-invocable`, `paths`, or `context: fork`; frontmatter is `name`+`description` only. The
   article's recommendation #2 (add `disable-model-invocation: true` to side-effectful skills) targets
   a real absence. **But pass2 §2.4 bounds it:** the flag is a *trigger-gate* (governs who starts the
   skill), not a *kill-gate* (governs whether the dangerous syscall can run). For **reversible** side
   effects (`/queue` opening a PR) the flag is the correct tier and a cheap, real win. For
   **irreversible** ones (force-push, migration apply) the structural backstop belongs in a
   PreToolUse guard — and ground-truth **§3e/§5 record `block-dangerous-bash.sh` as canon's 3rd
   structural guard, ABSENT on disk** ("Disk has no safety-floor bash guard"). So this article
   *reinforces* the already-identified `block-dangerous-bash.sh` gap from the trigger side: the flag
   handles activation, the missing bash guard handles execution. Citing §5 (absent guard) + `[verified]`
   (no invocation-control frontmatter).

3. **No load-tiering of always-loaded knowledge — but the audit test is trigger-existence, not
   line-count (pass2 §2.5).** The 799-line root `[verified]` is real. Ground-truth §4 records
   PITFALLS.md / RECURRING-FINDINGS.md / memory.md as a **triple-duplicated** knowledge layer the
   canon "both sanctions and forbids," and the article's recommendation #3 (fold them into on-demand
   references) maps onto that §4 duplication-collapse target. **But pass2 §2.5 corrects the article's
   own framing:** the gap is not "799 lines is too long," it's "content that *has a natural trigger*
   is paying tier-1 cost." PITFALLS ("read before writing code in an affected area") *has* a trigger →
   tier-2/3 candidate. The destructive-operation rules (CLAUDE.md, ground-truth §9 "keep verbatim")
   have **no trigger** (they guard unprompted commands) → must stay tier-1 regardless of length. So
   the real, citable gap is narrower than "shrink the root": **§4's duplicated, triggerable stores
   (PITFALLS/RECURRING-FINDINGS) are mis-tiered into always-loaded**, while the un-triggerable safety
   floor correctly stays. Anchor: §4 (the duplication) + §9 (keep-verbatim safety content that must
   *not* move).

4. **No installable/distribution unit — plugin answers a real, mapped gap, but converge-first.**
   Ground-truth **§8** is unambiguous: "the harness has **never been installed anywhere but
   event-vendor**… 'Multi-project' is a goal, not a state," and §2 records other repos carry **no
   harness**. The article's recommendation #4 (plugin-as-package) names the correct unit for the §8
   gap. **But pass2 §2.7 adds the precondition the article omits:** a plugin is a *versioned release*,
   and ground-truth's central fact is **bidirectional canon↔disk drift** (§ headline, §3–§7). You
   cannot version-distribute a harness whose canon and disk disagree on hooks, pass counts, skill
   rosters, and memory model. So the citable gap is real (§8: no shared unit) but the article's
   sequencing is wrong: **converge canon↔disk (Phases 3–4) before packaging.** Plugin is the §8
   endpoint, not a near-term build.

## (c) Weaknesses in the article's OWN reasoning (carried from pass2)

- **Recommends the exact anti-pattern our canon flags.** "Trigger-word-front-loaded `description`"
  (Standing Rule) = §9's "phrase-keyed descriptions" capability proxy. Following it literally
  hard-codes the thing the Model Capacity Audit says to remove (pass2 §2.3). Fatal if inherited
  verbatim; salvageable if read as "situational description."
- **Overstates the flag as "structural enforcement."** `disable-model-invocation` is a trigger-gate,
  not a kill-gate (pass2 §2.4); it does not make an irreversible action safe — it only changes who
  starts it. Calling it "the structural enforcement Pillar 1 demands" conflates two tiers.
- **Treats line-count as the audit metric.** The ~200-line target is a number, not a principle; the
  principle is trigger-existence (pass2 §2.5). Blindly shrinking the root risks demoting
  no-trigger safety content (§9 keep-verbatim) into a tier that only loads on match — i.e., never
  loading when it's actually needed.
- **Cites a phantom skill (`/change`) and borrows confidence from the planning layer** (pass2 §2.9;
  `[verified]` no `/change`). "You already decided / this is aligned" is asserted against canon
  vocabulary, not disk — and the ground-truth map exists to distrust exactly that.
- **Prices the plugin endpoint at zero** (pass2 §2.7): silent on manifest/namespace/version
  discipline and on the converge-first precondition (§8 + drift). Right destination, missing the cost
  and the order.
- **Cross-tool adoption + Routines dates are self-flagged secondary/hedged** (pass1) — fine as
  context, not load-bearing for any build decision.

## (d) Does it warrant fresh external research? — Mostly no; one bounded check.

Synthesize, don't re-research:
- The article's load-bearing mechanics (frontmatter fields, three-tier loading, progressive
  disclosure) are **self-flagged primary-sourced** and are the **published Anthropic Agent Skills /
  agentskills.io open standard** — already the convention the Zapier pass also relied on. No new web
  pass adds confidence; we need *design decisions*, not more evidence.
- Every actionable item maps to an existing ground-truth row already framed by our map: §9
  (situational triggers), §5 (`block-dangerous-bash.sh`), §4 (knowledge duplication / tiering), §8
  (distribution). That is precisely the "synthesize over re-research" condition.
- **One bounded exception, only if we proceed to add invocation-control frontmatter:** confirm the
  *current, exact* frontmatter schema before writing it — specifically whether the canonical keys are
  `disable-model-invocation` / `user-invocable` / `allowed-tools` (article spelling) vs the published
  schema's actual field names, and whether Routines honor them. A ~10-minute schema check against the
  live Agent Skills spec, **not** a research project. Flag, don't launch. (This is the same bounded
  check the Zapier pass3 already flagged — do it once, for both.)

**Net for V2:** the durable yield is pass2 §2.8's **two-decision grid** (activation-control by
false-trigger reversibility; load-tier by trigger-existence) as the lens for the Phase-1 file/skill
audit. Concrete, ground-truth-anchored candidates: (1) rewrite skill descriptions as **situations**,
not phrase-keys (§9); (2) add `disable-model-invocation` to **reversible** side-effect skills while
routing **irreversible** ones to the absent `block-dangerous-bash.sh` (§5); (3) demote the
**triggerable** duplicated stores PITFALLS/RECURRING-FINDINGS toward tier-2/3 while **keeping**
no-trigger safety content in tier-1 (§4 + §9); (4) plugin-as-package as the **§8 endpoint**, gated on
canon↔disk convergence. The article's own "front-load trigger words" and "shrink to 200 lines" must
be **rejected as literal instructions** and replaced by the situational / trigger-existence forms.
