# Pass 1 — Comprehend: "Spec-Driven Development & Agent Workflows at Notion" (Ryan Nystrom, 2026)

**Source:** *How I AI* podcast with Claire Vo, May 11, 2026. Guest: Ryan Nystrom, Engineering Manager, Notion AI ("Afterburner"). Notion research page `369e2971cd6281bd9ff4d6d0e311d016`, research-dated 2026-05-23. The page is itself a curator write-up derived from four secondary sources (ChatPRD editorial, ZenML LLMOps case study, Lenny's chapter map, Snipd quote cards) — **no verbatim transcript was obtainable** (Snipd 403, YouTube bot-gate, Lenny JS-gated).

This pass records what the page SAYS, faithfully. Tags: (fact) = verifiable/definitional or a reported observation; (opinion) = a normative or contestable judgment. The page already contains its OWN "Pass 1 / Pass 2 / Pass 3" sections — those are the *curator's* interpretation, recorded here as **claims the page makes**, not as my analysis. I separate the reported facts (Pass-1 of the page) from the curator's interpretation (Pass-2/3 of the page).

## Provenance and framing

- Nystrom manages 6–7 engineers at Notion AI and still writes code; calls the past year the most disruptive of a 20+ year career — switched IDEs/terminals/tools "more than ten times" — yet reports more joy/productivity than ever. (fact — reported experience)
- His team is described internally as "very, very AI-pilled," recruited to bring that energy to Afterburner. (fact — reported)
- **Source-reliability caveat the page itself flags:** ZenML calls the coding agent "Aider" throughout; Snipd + ChatPRD identify it as **Codex**. The page rules Codex authoritative and treats ZenML's naming as a transcript error. (fact — a confirmed contradiction in the sources, adjudicated)

## Workflow 1 — "Hot Potato" automated standup pre-read

- A custom agent runs every morning at 9 AM to eliminate standup prep. (fact — reported)
- Fans out **in parallel** across five sources: Slack project channel, GitHub (merged PRs last 24h), Notion task DB (recently closed/updated), Honeycomb (CI metrics via MCP), and yesterday's meeting transcript. (fact — reported)
- Synthesizes into a fixed-section pre-read: CI Speed / Decisions / Progress & Changes / Bugs & Feedback / Open Questions & Risks; posts a "brief, fun, sometimes quirky" Slack message with a link. (fact — reported)
- Uses Notion AI's **sub-agent** fan-out; Nystrom calls sub-agents a "sleeper feature" — expensive and finicky, under-promoted, but essential here. (fact reported + opinion on "sleeper")
- **Scoped permissions:** view-only on most DBs, edit only on the meetings DB where it writes. (fact — reported)
- **Partially self-configured:** Nystrom gave it a screenshot of a Honeycomb query UI and said "I don't know how this works, can you just update your instructions?" — the agent configured its own MCP integration from the screenshot with minor human correction. (fact — reported, notable)
- Business impact: saves ~20 min/day, protects focus, and "democratizes information" — quiet engineers' work surfaces automatically. One example: an automated summary surfaced a mock-server fix giving a 13% test improvement he'd missed, which drove an optimization discussion. (fact reported + opinion on "democratizes")

## Workflow 2 — "Boxy" / "Software Factory": Notion task → PR in ~20 min

- Engineers invoke a coding agent (**Codex**) by `@mention` in a Notion task's comments. (fact — reported)
- Trigger spins up a **VM with the full codebase, Codex, and all dev tooling**; the agent reads the task description, comments, and screenshot. (fact — reported)
- In ~20 min it comments back two links: a finished GitHub PR and a **live preview-environment URL**; the PR includes code, a description of what it did, and **screenshots showing it verified its own UI**. (fact — reported)
- Concrete timeline: task @ 10:40 → Codex PR + preview @ 10:51 → full implementation ~10 min later. (fact — reported)
- On a CI type-error failure, Nystrom replied "I don't know what is going on here. This doesn't make sense." — the agent explained its reasoning and fixed it; it also resolved a merge conflict. (fact — reported)
- Nystrom runs **Aider alongside Codex in parallel**; found some agents "lose the plot" as context fills, while Aider could "grind for hours." Runs multiple worktrees (ports 3000–3009 occupied), fires agents, attends meetings, round-robins outputs; goal is "one-shot or near-one-shot solutions that don't require him to watch." (fact reported + opinion on agent comparison)

## Workflow 3 — Spec-first development (`/agent-specs/`)

- Notion keeps an `/agent-specs/` folder in the codebase; each file is a comprehensive Markdown doc with behavioral descriptions, implementation pointers, and **critically a Verification section**. (fact — reported)
- Spec-creation loop: (1) talk through the feature into **Whisper** (raw brain dump); (2) feed transcript to Codex: "Here's our spec library. Learn the format, take my information, write a spec."; (3) a couple of revisions; (4) commit the spec to `/agent-specs/`; (5) point Codex at it and say "Build it."; (6) Codex one-shots it — for "Ask Mode," a couple of hours, several thousand lines. (fact — reported)
- **The Verification section closes the loop without a human:** Notion built a **custom CLI tool** letting agents run Notion AI from the command line — send queries, enable/disable features (e.g. Ask Mode), inspect output transcripts — to verify behavior against the spec. The agent runs its own tests using the spec's verification steps as test cases. (fact — reported, load-bearing)
- After shipping, the spec **stays as the permanent source of truth**; changes update the Markdown spec, then the agent updates code to match; the spec's git history becomes a readable changelog of intent. (fact reported + opinion on "more accessible than commits")
- Nystrom frames spec-first as **not new work but shifted emphasis**: teams always wrote design docs and held meetings; the difference is "dramatically compressed timeline — specs don't wait for review meetings and calendar availability." (opinion)

## Project Afterburner (parallel context)

- Goal: cut CI time to **a quarter** of current. (fact — reported)
- Reasoning is explicitly **agent-centric**: humans context-switch while CI runs; agents idle; a 1-hour pipeline is a "mathematical ceiling on agent throughput," a 3-minute pipeline is a multiplier. (opinion, presented as math)
- Cites **Stripe's ~1,300 agent-generated PRs/week** as impossible without fast CI. (fact — cited third-party figure)
- "DX investment that benefits humans benefits agents equally." (opinion)

## The page's OWN "Pass 2" (curator interpretation — recorded as claims)

- "**The Verification section is the whole game**" — spec-first is only AFK-capable because of it; verification capability should *precede* autonomous implementation; "if you can't define how to verify the feature, you're not ready to build it." (opinion — the page's central thesis)
- "**The spec and the task are different documents**" — task says "build X" (ephemeral, drives a session); spec says "what X IS / how it behaves / how to verify" (permanent, drives the feature's lifetime). The spec survives the task. (opinion)
- "**The spec solves behavioral drift, not just initial build**" — its value is the fifth modification six months later by an agent that didn't build it; code answers "how," CLAUDE.md answers "what the codebase is," only the spec answers "what this feature IS supposed to do and how to verify it's still doing that." (opinion)
- "**CI speed is agent throughput, not DX**" — reframes a 60-min pipeline as ~1 PR/hr/agent, a 3-min pipeline as 20x in the same wall-clock; an existential investment for agent-scale shipping. (opinion)
- "**The intern test is a quality filter on specs**" — if you can't explain the task to a human intern in plain English, the prompt will fail; plain language forces precision; spec quality is self-validating. (opinion)
- "**Emotional unbundling of code review**" — with agents Nystrom is "a little bit of a diva" ("I don't understand this. Fix it." / "Explain this like I'm 5." / "Defend your reasoning with citations."); directness that would be corrosive to a human team is just efficient with agents, so review cycles are faster/higher-fidelity. (opinion)
- "**Running AFK by default**" — the workflow is non-interactive by design; every component is "optimized for unattended operation first, interactive use second." (opinion)
- "**Sub-agents as a scaling primitive**" — parallel fan-out is a map-reduce on context gathering; expensive/finicky means it's a *production engineering* challenge, not just prompt engineering. (opinion)
- "**The spec replaces the design meeting**" — the intellectual work of design remains; the organizational coordination overhead disappears; debate happens on working code. (opinion)

## The page's own "Pass 3" (curator cross-cutting patterns — recorded as claims)

- **Infrastructure investment unlocks agent scale** — Boxy (VMs), the CLI (verification), Afterburner (CI) were all *built*, not bought; the gap between "we use Codex" and "1,300 PRs/week" is infrastructure. (opinion)
- **Spec as version-controlled behavioral contract** — specs in git are reviewed in PRs, have blame history, can be diffed and referenced by future agents; a first-class artifact, not Confluence drift. (opinion)
- **Verification before autonomy** — across all three workflows verification precedes unattended trust (scoped perms, preview URL for review, CLI-executable verification). "Autonomy is earned by verification infrastructure, not assumed." (opinion)
- **Context quality determines one-shot rate** — precise input (focused sentences + edge case + screenshot, or a full spec) → fewer correction cycles → more AFK-able output. (opinion)
- **Emotional overhead is a real engineering cost** — blunt agent correction (1 round) vs diplomatic human review (3 rounds) compounds across a team; "the social cost of human review is a hidden tax on velocity." (opinion)
- **DX = Agent DX** — every DX improvement benefits agents equally or more; reframes the ROI of DX investment. (opinion)
- **Tension flagged — pace of change as overhead** (via ZenML): 10+ tool changes/year is energizing for Nystrom but is org overhead/learning curve/breakage risk most teams won't share. Spec-first *partially* mitigates (spec is tool-agnostic, "build it" points at any agent) but Boxy/CLI are tool-coupled and need maintenance. (opinion — a self-flagged limitation)
- **Tension flagged — one-shot goal assumes strong specs**: a vague spec → a vague implementation; Whisper-to-spec works because Nystrom *already* has a complete mental model; "the process doesn't generate clarity — it requires it as input." (opinion — the page's most important self-critique)

## The load-bearing claims (what a later pass must test)

1. Spec-first is AFK-capable **only** because of an executable Verification section backed by a custom CLI. (the page's thesis)
2. The **spec ≠ the task**: permanent behavioral contract vs ephemeral session driver; the spec's durable payoff is *anti-drift* over the feature lifetime.
3. **CI speed is an agent-throughput constraint**, not DX — a multiplier on a fleet, not a comfort.
4. **One-shot rate is a function of context quality**, and the process *requires* clarity as input rather than producing it.
5. **Infrastructure (VMs, verification CLI, fast CI) is the moat**, not the choice of coding agent — which is swappable.
