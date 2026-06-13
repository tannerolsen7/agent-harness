# Pass 2 — Penetrate: "Agentic Platform Engineering"

Building on pass1: this pass does not restate the article. It reads *underneath* the pass-1 points to
surface the load-bearing thesis, the assumptions the author never defends, the internal tensions, and the
net-new analytical claims that pass 3 will apply to our harness.

---

## A. The real thesis is narrower than the title — and it's a borrowed one

Building on **pass1 §1–§2**: the title says "Agentic Platform Engineering," but the article's actual load-
bearing claim (pass1 §1, "model selection is last") is **Stripe's** claim, not Fernandez's. The article is
two documents fused: (a) a *reported* summary of Minions (pass1 §4), and (b) a *proposed* personal three-
repo layout (pass1 §3). The persuasive force comes almost entirely from (a) — the 1,300-PRs/week number —
while the prescription is entirely (b). **Net-new observation:** the article smuggles the credibility of an
industrial system (Minions, built by a payments company with a pre-existing devbox fleet) onto a solo-dev
file-organization scheme (symlinked markdown repos) that shares *none* of Minions' actually load-bearing
properties (isolation, blueprints, Toolshed, retry caps). The thesis that survives scrutiny is the modest
one — **"agent config is infrastructure, version it and scope it"** — not the grand one.

## B. The hidden thesis: *scoping is the whole game, sharing is secondary*

Building on **pass1 §4.3 (curated context) and §5 (token efficiency)**: the article presents three-repo
*separation* as the headline, but every concrete efficiency claim is actually about **scoping** —
directory-scoped layers, file-pattern rules, home-scoped meta-skills, "global rules used very judiciously."
**Net-new:** separation (three repos) and scoping (load only what's local) are *orthogonal*. You can scope
within a single repo; you can have three repos with no scoping. The article conflates them because in
*Fernandez's* implementation they happen to coincide. The transferable insight is **scoping**; the three-
repo split is one packaging of it, not the source of the benefit. This matters because our harness could
capture ~all the token/clarity value of "curated context" without adopting the repo split at all.

## C. Assumption the author never defends #1: symlinks are a virtue

Building on **pass1 §3.2 (symlinks not copies) and §6 (DR)**: "edit a layer, live everywhere instantly" is
sold as pure upside. The unexamined cost: **symlinks couple every consumer to a single mutable source with
no version pinning.** A change to `global.md` silently alters every project's agent behavior with no review
gate, no per-project lock, no rollback. This directly contradicts the DR promise (pass1 §6): "everything in
git" implies *versioned* recovery, but a symlink resolves to *whatever HEAD is now*, not the SHA a project
was validated against. **Net-new tension:** the article wants both live-propagation (symlinks) and
reproducibility (git DR), and these fight. Copies-with-a-lockfile (the thing it dismisses) is what actually
delivers reproducible DR. Our own canon already saw this — it prescribes "vendor as committed copies, not
symlinks" in one place and "install globally" in another (ground-truth §7.8); the article lands on the
*weaker* side of a debate our own canon hasn't resolved.

## D. Assumption never defended #2: "their infra was already excellent" is the actual product

Building on **pass1 §2 ("agents just plugged in")**: this is presented as a reassuring aside; it is in fact
the **entire precondition** and it quietly invalidates the article's "config-first, model-last" ordering.
Stripe's agents work because of devboxes + selective CI + autofix + a 500-tool curated MCP — i.e., *years
of platform investment that has nothing to do with markdown layering.* **Net-new:** the article's own
evidence refutes its own emphasis. The three-repo `agent-library` is the *cheapest, least load-bearing*
part of what made Minions work. If you copy the markdown architecture and skip the isolation + selective-CI
+ retry-cap + toolshed, you have copied the packaging and left the engine. The honest reading: **the article
documents a brain-layer pattern, then borrows evidence from a system whose success came from its body.**

## E. The "hard limit on retries" is the most under-sold idea in the piece

Building on **pass1 §4.4 (max 2 CI retries, diminishing returns)**: the article spends one bullet on this
and pages on repo layout, but this is the only item that encodes a *non-obvious empirical claim about LLM
behavior* — that retry value decays, so a deterministic stop beats an open loop. **Net-new:** this is a
*control-theory* point, not a file-organization point. It generalizes far past CI: it argues every agentic
loop in a harness (review auto-fix, debug, self-correction) needs a hard iteration cap with a defined
human-handoff state, because the failure mode is not "agent gives up too early" but "agent burns budget
converging on nothing." This is the single most portable, model-independent idea in the article and the
author barely notices he wrote it.

## F. The blueprint idea contradicts the "skills are never auto-loaded" rule

Building on **pass1 §3.1 (skills explicit, never auto-loaded) vs §4.2 (blueprints: some nodes deterministic,
some agentic)**: blueprints are an *orchestration* layer that *automatically* sequences deterministic and
agentic steps — i.e., the system decides when to run a procedure, the human does not invoke `/skill:x`.
**Net-new contradiction:** the `agent-library` philosophy ("nothing auto-loads, everything is explicit,
human stays in control of invocation") and the Minions philosophy ("blueprints automate the sequence, only
critical steps are pinned") are *opposite stances on agency*. The article never reconciles them because they
come from its two unmerged halves (§A). For a harness designer this is the crux decision the article dodges:
**is the orchestration explicit-invoke (library) or pinned-blueprint (Minions)?** They imply different
enforcement architectures.

## G. What the author takes for granted: that markdown *is* the intelligence

Building on **pass1 §3.1 (layers/skills/rules) and §5**: the entire `agent-library` treats agent capability
as a function of *which markdown is in context*. **Net-new challenge:** this is precisely the assumption our
own ground-truth map flags as the thing to re-audit on a model upgrade — the canon's **Model Capacity Audit
(ground-truth §9)** distinguishes *reasoning discipline (keep)* from *capability proxies (remove)* and warns
that scaffolding the current model no longer needs is overhead. The article is written entirely in the
"more curated markdown = more capable agent" frame and never asks whether a stronger model needs *less*
layering, not better-organized layering. Its token-efficiency argument (load less) is the right *instinct*
for the wrong *reason*: it optimizes cost, not the deeper question of which scaffolds a capable model has
outgrown.

## H. The page's own gap analysis is graded on a generous curve

Building on **pass1 §7 (the page's claims)**: the page rates us "Better" on skills, human-in-loop, and spec-
first, and "Equal" on memory/CI/AFK. **Net-new skepticism:** "Better" here means "more elaborate," which the
Model Capacity Audit (ground-truth §9) treats as a *liability signal*, not a win. The page also asserts
"worktrees per task — we do this" as if it answers Gap 2; pass 3 must check whether worktree isolation is
the *same kind* of isolation as a devbox (it is not — same filesystem, same credentials unless a firewall
exists). And the page is a **frozen snapshot explicitly disclaimed for implementation decisions** (pass1
header) — its gap list is a starting hypothesis, not a finding. Pass 3 treats every "Equal/Better/Gap" cell
as a claim requiring a ground-truth citation.

---

## Net distilled theses carried into pass 3

1. The portable core is **scoping**, not the three-repo split (§B).
2. **Symlink-live vs. versioned-copy** is an unresolved tension the article gets wrong for DR (§C).
3. The article's success evidence is **infra, not markdown** — copying the brain without the body is the
   trap (§D).
4. **Hard retry caps with defined handoff** is the most valuable, most under-developed, most model-
   independent idea (§E).
5. **Explicit-invoke vs. pinned-blueprint orchestration** is the unmade decision (§F).
6. "More elaborate" ≠ "better"; measure scaffolds against **Model Capacity Audit** keep/remove (§G–§H).
