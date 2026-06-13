# Pass 1 — Comprehend: "Agentic Platform Engineering" (Saul Fernandez / Stripe Minions)

**Source:** Saul Fernandez, *Agentic Platform Engineering*, DEV Community, March 2026
(`dev.to/sarony11/...`). Stripe context: Stripe's "Minions" blog (Feb 2026) + ByteByteGo breakdown.
**Notion page status (fact):** the Notion page is an explicitly **frozen snapshot (2026-05-21)**, marked
`canonical: false`, with a banner that its gap analysis **"must not be used to make implementation
decisions"** and a pointer to a separate "Research Delta — Current System State vs Snapshot Analyses"
page. The gap-analysis section below is the *page author's* analysis, not the article — treated here as
claims, not the article's own thesis.

This pass restates what the article and page **say**, faithfully. Tags: **(fact)** = verifiable/empirical
claim about a system or technique; **(opinion)** = the author's judgment, recommendation, or framing.

---

## 1. Central thesis

- The discipline of configuring agents properly is **"Agentic Platform Engineering."** Its core principle:
  **"Treat agent intelligence as infrastructure, not improvisation."** (opinion)
- Most engineers treat agent config as an afterthought — either ad-hoc prompting, or a single flat
  root-level `AGENTS.md`/`CLAUDE.md`. The author claims **neither scales.** (opinion)
- **Model selection is the last thing that matters; developer environment, test infrastructure, and
  feedback loops come first.** (opinion, framed as the central lesson)

## 2. The Stripe Minions data point

- Stripe **merges 1,300+ PRs/week written entirely by unattended AI agents.** (fact, as reported)
- The agents work **because Stripe's *human* engineering infrastructure (devboxes, CI/CD, test suite,
  linters) was already excellent** — agents "just plugged in." (opinion/causal claim, presented as fact)

## 3. The three-repo architecture (the article's central proposal)

Separate agent infrastructure into three single-responsibility repos: (opinion — a recommended design)

1. **`agent-library` — "the Brain" (tool-agnostic intelligence).** Single source of truth for everything
   the agent knows; no tool-specific config. Switch tools tomorrow → this repo is untouched. (opinion)
   Contains four primitives (fact — these are the article's defined terms):
   - **Layers**: markdown that becomes `AGENTS.md` for specific directories; **cumulative** — agent loads
     parent → child, each adding context.
   - **Skills**: reusable step-by-step procedures, **invoked explicitly** (`/skill:terraform-plan`),
     **never auto-loaded.**
   - **Rules**: always-on constraints.
   - **`library.yaml`**: central manifest declaring every layer/skill/rule/prompt — what it is, where it
     lives, where it deploys.
   - Worked example: `~/.agent/AGENTS.md → global.md` (identity) → `~/repos/AGENTS.md` (git conventions)
     → `work/AGENTS.md` (conservative/safety-first) → `work/terraform/` (terraform workflow).
2. **`agent-setup` — "the Bridge" (tool-specific deployment).** A `setup.sh` reads `library.yaml` and
   deploys via **symlinks, not copies** — edit a layer and it's live everywhere; only re-run setup when
   adding new files. (fact — the described mechanism)
3. **`resource-catalog` — "the Map."** Follows **Backstage catalog format**; registers every repo with
   type/owner/system/lifecycle. **A map, not an engine** — no agent logic lives here. (fact/opinion)

## 4. The Stripe Minions architecture (four layers) — reported facts

1. **Isolated environments (devboxes).** Cloud machines pre-loaded with the whole codebase/tools/services;
   spin up in **~10 seconds** via a pre-warmed pool; run in a **QA environment isolated from production
   data by default**; engineers already used them for human work, agents plugged in. (fact, as reported)
2. **Hybrid orchestration (blueprints).** Neither pure workflow (rigid) nor pure agent (unreliable);
   **blueprints** = a sequence of nodes, some deterministic code, some agentic loops. "Run linters" =
   hardcoded; "implement the feature" = agentic loop. Critical steps always happen; creative steps get
   LLM freedom. (fact, as reported)
3. **Curated context.** Global rules used **"very judiciously"** (loading everything globally wastes
   tokens); rules scoped to subdirectories and file patterns; a **"Toolshed"** centralized internal MCP
   server hosts **~500 tools**; agents get a small curated default set, engineers add more on demand. (fact)
4. **Fast feedback with hard limits.** Local linting **<5 s** via pre-computed cache; CI runs selective
   tests and autofixes known failure patterns; **max 2 rounds of CI retries, then back to a human** —
   because **LLMs show diminishing returns on retries.** (fact + opinion on the rationale)

## 5. Token efficiency as a first-class concern (opinion, with a mechanism)

- Level 1: layers are **directory-scoped** (terraform rules don't load in React).
- Level 2: each layer **only declares what's relevant at its level** (`global.md` lists 6 universal
  skills, never mentions `terraform-plan`).
- Level 3: meta-skills are **scoped to their home** (`create-skill` only inside `agent-library/`).
- Claimed result: in `work/terraform/` the agent loads exactly **6 global + 1 domain + 1 directory** skill.

## 6. Disaster recovery <5 minutes (opinion/guarantee)

If everything breaks: rebuild from scratch in **<5 min** via 3× `git clone` + `bash setup.sh`. Possible
because (a) everything is in git (no local-only config), (b) brain is separate from tool, (c)
`library.yaml` declares everything so `setup.sh` just executes it.

## 7. The page's OWN gap analysis (CLAIMS — not the article; to verify in pass 3)

The page (not Fernandez) rates "our system" against the architecture. Recorded here verbatim-in-summary as
**claims to test against the ground-truth map**, NOT inherited as fact:

- **Claimed "Better/Equal":** Layers ≈ our `.claude/` `CLAUDE/AGENTS/CONTEXT.md` (Equal, "no cumulative
  loading yet"); Skills (Better — "more opinionated, enforcement gates"); Rules ≈ `PITFALLS.md` /
  `RECURRING-FINDINGS.md` (Equal, "scoping by directory missing"); Human-in-the-loop (Better); Spec-first
  (Better — specs required for Medium+); Memory/compound (Equal — "resource-catalog inventory missing");
  CI feedback loops (Equal — "lack hard retry limit"); AFK/unattended (Equal — "no devbox equivalent").
- **Claimed GAPS:** (1) **No three-repo architecture (CRITICAL)** — single-repo `.claude/`, no cross-project
  skill sharing, no DR story, no skill versioning; fix = `ai-library` + `ai-setup` repos, projects pull via
  symlinks, Notion stays source-of-truth. (2) **No isolated execution environment (CRITICAL for AFK)** —
  agents run in the working dir with full filesystem access; near-term fix = worktrees-per-task (noted as
  "we do this"), long-term = Codespaces/Daytona. (3) **No `library.yaml` manifest / no skill registry** —
  skills in Notion + `.claude/` but no machine-readable manifest; fix = `library.yaml`/`skills-index.yaml`.
  *(Page content truncates mid-sentence inside Gap 3's fix — "The sync script (`/skill:sync…"; remainder
  not retrievable from this snapshot.)*

## 8. What the article does NOT claim (boundary notes — fact)

- It does not give cost/latency numbers for the three-repo setup, nor evidence the symlink approach scales
  past one machine.
- It offers **no security/credential-isolation design** beyond "QA environment isolated from prod data."
- The "1,300 PRs/week" and "<5 min DR" figures are **asserted, not independently sourced** in the page.
- Stripe's Minions and the author's three-repo `agent-library` design are **two different systems**; the
  article borrows Minions as motivating evidence, it does not claim Stripe uses the three-repo layout.
