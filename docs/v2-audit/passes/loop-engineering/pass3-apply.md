# Pass 3 — Apply: the article against OUR harness (ground-truth map)

Building on pass2: pass 2 distilled the article's defensible core to a two-part rule — **(A) temporal
gaps are invisible to static audits** (pass2 §2.3, §2.6.A) and **(B) split autonomy at the discover/act
seam** (pass2 §2.2, §2.6.B) — and flagged five contradictions (pass2 §2.7 C1–C5) the proposed
`triage-inbox.md` node inherits. This pass tests both the rule and the node against
`CANONICAL-HARNESS-AS-IS.md`. Every gap below cites a map section or a confirmed on-disk absence; no gap
without a citation.

I also ground-truthed the article's load-bearing empirical claim directly on disk (pass2 §2.4 said it
*must* be adjudicated, not accepted). Findings inline below.

---

## (a) What we ALREADY do

Carrying pass2 §2.1 (a loop = harness + one cron-driven discovery step), the map confirms we have the
**entire harness floor** the article concedes is not the differentiator:

- **Sub-agent orchestration** — the map shows **23 agents** including all 4 review lenses, 6 spike
  agents, task-runner/orchestrator [map §3d]. Per pass1 Claim 3 this is "just a harness capability," and
  the map confirms we have it in depth. We are not missing orchestration.
- **Worktrees** — `worktree-create.sh` + `worktree-add.sh` + prod-key firewall, a genuine disk *advance*
  over canon [map §3e, §6]. Another harness piece the article says doesn't make a loop.
- **Skills / connectors** — ~26 project skills + Notion MCP plugin [map §1, §3b]. Same.
- **External memory (the spine, pass1 Claim 4)** — we are *strong* here: a **six-store** memory layer
  (`memory.md`, `RECURRING-FINDINGS.md` [confirmed on disk at `docs/RECURRING-FINDINGS.md`], `PITFALLS.md`,
  `docs/solutions/`, `docs/adr/`, plus the auto-memory `MEMORY.md` + 51 siblings) [map §4]. The article's
  "memory on disk, not in context" requirement is *over*-satisfied. Our gap is not memory existence; it's
  the duplication/lifecycle problem the map already owns [map §4].
- **The discover/act seam already biases to human-gated action** — `/change`, `/queue`, `/compound`
  curation are human-initiated [the article's own Claim 5, corroborated]. So the article's prescription
  (pass2 §2.6.B: gate action) is *already our posture*; we would only be adding the discovery half.
- **A ritual layer exists** — `.claude/rituals.md` is real (confirmed on disk): five rituals
  (`improve-codebase-architecture` weekly, `scan-context` weekly, `model-review` on-release,
  `prioritize-tasks` weekly, `stale-branch-audit` 14d), each with `last_run` + `frequency`, surfaced by
  the CLAUDE.md session-start instruction.

**So:** per the article's own reduction, we have five of the six pieces. The one piece — the heartbeat
— is the open question for (b).

---

## (b) REAL gaps it exposes (each cited)

**Gap 1 — No scheduler. The heartbeat is genuinely absent, and it is the article's bullseye.**
*Confirmed on disk:* there is **no cron, no scheduled-tasks config, no `/loop` or `/goal` wiring** in
`.claude/settings.json` or anywhere in `.claude/` (grep returned nothing but worktree `node_modules`
noise). The ritual layer (`.claude/rituals.md`) is triggered **only at session start**, by a CLAUDE.md
line that asks the *model* to check `last_run` against `frequency` — i.e., it fires only when a human
starts a session and only if the model remembers to look. This is exactly pass1 Claim 6 / pass2 §2.4:
**a "weekly ritual" with no enforcing scheduler.** This maps to the map's enforcement gap: the canon's
own `session-end.sh` memory-capture hook is **absent on disk** [map §3e, §5], and more broadly the map's
verdict is "**the system is overwhelmingly advisory** — neither [canon nor disk] has a deterministic
backstop" [map §3e *Net enforcement picture*]. The article sharpens that verdict with a *temporal* edge
the map states statically: our rituals don't just lack a hook, they lack a **clock**. This is a real,
citable gap.

**Gap 2 — `permission-logger.sh` produces output nothing consumes (the article's "permission aggregation"
ritual is real and orphaned).** *Confirmed on disk:* the hook writes one JSON line per tool call to
`/tmp/claude-perm-log-${HASH}.jsonl`. Nothing reads or aggregates it; it is a disk-only observational hook
the canon doesn't even declare [map §3e, §6]. The article's claim that "permission-logger aggregation" is
a scheduled ritual with no scheduler is **true for the aggregation step** — though note (pass2 §2.4
demanded adjudication) the *logging* runs on every tool call; only the *aggregation* is missing. So the
precise gap is: a per-event log that no scheduled job ever rolls up. Citable via [map §6 `permission-logger.sh`].

**Gap 3 — The triage-inbox input artifacts don't exist; `review-log.md` and `triage-inbox.md` are
phantoms.** *Confirmed on disk:* both are **absent in the real project** (present only inside worktrees /
node_modules). The map independently lists `review-log.md` and `triage-inbox.md` among **phantom refs —
"referenced on disk, never built on disk or in canon"** [map §6 *Phantom refs*]. This validates pass2 §2.7
C5: the article's proposed node grep-reads `review-log.md` and the `/p/[token]` runtime-error table, both
of which it admits are conditional ("once built"). So the gap the article exposes is **upstream of the
loop**: we cannot feed a triage inbox from artifacts that don't exist. Any Node-17 proposal is really
"build the inputs, *then* the heartbeat."

**Gap 4 — Morning review is not a wired ritual, so even a half-loop has no closing consumer.** The
article quotes our own plan: the morning review is *"not a named calendar ritual"* (Node 5.2). The map
corroborates the broader pattern — read-time is specified for only ~5 of ~14 knowledge files [map §4
*admitted ambiguities*]. Per pass2 §2.5.2 (C2), a `triage-inbox.md` consumed by an unscheduled human
habit is a half-open loop. Real gap, cited to [map §4].

**Net of (b):** the single real, defensible gap the article uniquely exposes is **Gap 1 — the absence of
a scheduler/heartbeat** — and it is correctly framed as a *temporal* gap the static map could not surface
on its own (pass2 §2.3). Gaps 2–4 are real but are pre-existing map facts (§6 phantoms, §4 ambiguities)
that the article re-bundles around the heartbeat theme rather than newly discovering.

---

## (c) Weaknesses in the article's OWN reasoning

Carrying pass2 §2.7 forward and testing each against the map:

1. **The cure inherits the disease (pass2 §2.5.1 / C1).** The article indicts "no scheduler named" and
   prescribes "a single scheduled job," asserting "the scheduling capability exists in this environment"
   — but *names no scheduler*. On disk there is none (Gap 1). The map's enforcement section is blunt: the
   system is "overwhelmingly advisory" [map §3e]. A proposal that doesn't name a concrete, always-on
   trigger (cron on an always-on host? a CI schedule? `CronCreate`?) reproduces the exact orphaned-ritual
   pattern it condemns. **This is the article's most serious self-undermining flaw** and Phase 3/4 must
   close it before the node is buildable.

2. **It over-credits "discovery" as the scarce resource (pass2 §2.2 / C3).** The article wants both
   "discovery is the gap" and (via R1) "review is the bottleneck," and never reconciles them. Our map
   actually leans toward *review/curation* being the loaded path: the §4 memory model already suffers
   **triple-duplication** that `/compound` must manually adjudicate [map §4]. A discovery loop that floods
   a triage inbox adds to exactly that curation load. The article treats discovery output as free; it
   isn't.

3. **It re-bundles known phantoms as a discovery (Gap 3).** `review-log.md`, `triage-inbox.md`, the
   `/p/[token]` table are all already catalogued as phantoms/conditional in [map §6]. The article presents
   feeding from them as a near-term step ("once built"), under-stating that the node is really several
   build steps. The map is more honest about their non-existence than the article is.

4. **"Five orphaned rituals" is *mostly* accurate but imprecisely scoped (pass2 §2.4).** Ground-truthing:
   the rituals that *do* exist (`.claude/rituals.md`) are a **different five** (architecture, scan-context,
   model-review, prioritize-tasks, stale-branch) than the article's five (check-resolvable, mutation
   testing, doc-drift, permission aggregation, 3+-recurrence). Several of the article's five are
   **plan/canon items not yet on disk** (`check-resolvable`/Node 2.1, mutation testing/Node 6.3). So the
   article's *category* (scheduled ritual without scheduler) is correct and confirmed, but its *specific
   list* mixes built-but-unscheduled rituals with not-yet-built nodes. The valid, disk-true version of its
   claim is: **the rituals we have built have no scheduler, and several it names aren't built at all.**

5. **Pillar 1 framing is borrowed, not load-bearing for us yet.** The article leans on "Pillar 1: a
   control with no enforcing hook is a hope." That doctrine lives in our research/canon layer, not as an
   enforced disk mechanism — consistent with the map's "overwhelmingly advisory" finding [map §3e]. The
   article uses our aspiration as if it were our enforcement. The point still lands (advisory ≠ enforced),
   but it's rhetorical leverage, not evidence.

---

## (d) Does it warrant fresh external research?

**Largely no — synthesize, don't re-research.** Per pass2 §2.6, the article's transferable core is a
*rule*, not an architecture, and we can act on it from what we already have:

- The **heartbeat gap (Gap 1)** is now a confirmed disk fact; we don't need external research to know we
  lack a scheduler. What's needed is an **internal design decision**, not a literature search: pick the
  scheduling substrate. The deferred-tool surface in *this very environment* lists `CronCreate` /
  `CronList` and a `schedule`/`loop` skill — so the capability the article merely *asserted* exists is
  in fact present here. That's an internal verification (a 1-line spike: does `CronCreate` persist on a
  solo dev's machine state?), not research.
- The **R1 evidence (pass1 Claim 9)** is already ingested in our own backlog (the article cites *our*
  Svpino R1). Re-researching autonomy ROI would duplicate work we've done. The map's posture — action
  human-gated, blast-radius caps — already encodes the R1 lesson.
- The **discover/act split (pass2 §2.6.B)** is a synthesis call, not an open question.

**One narrow exception worth a bounded check, not a research project:** the *durability* assumption
(pass2 §2.5.1) — whether a scheduler in this environment fires when the dev's machine is asleep/closed,
or whether it needs an always-on host (CI schedule, hosted runner). This is the difference between a real
heartbeat and a second orphaned ritual. It's a **15-minute capability spike** (`CronCreate` + observe),
not external research.

**Recommendation for the build plan:** promote pass2 §2.6.A (temporal-gap rule) into the audit doctrine —
*the CANONICAL map must add a "fires how / on what clock?" column to every ritual/hook row*, because pass2
§2.3 showed a file-inventory audit structurally cannot catch a missing heartbeat. That single doctrine
change is the article's highest-value contribution to V2, above the `triage-inbox.md` node itself (which
is a sound but input-blocked instantiation: Gap 3). The node maps to the map's candidate-build register
as a §5-style "build it" item, but **gated behind**: (i) naming a durable scheduler [closes C1], (ii)
building `review-log.md` / the `/p/[token]` table [closes Gap 3], (iii) wiring the morning-review consumer
[closes Gap 4]. Until those, it would be a fourth orphaned ritual.
