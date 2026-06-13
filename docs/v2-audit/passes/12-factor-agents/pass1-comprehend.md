# Pass 1 — Comprehend: "12-Factor Agents" (Dex Horthy / HumanLayer, 2026)

**Source:** github.com/humanlayer/12-factor-agents (~19k stars, May 2026). Notion snapshot `36ee2971cd62812a82bde6c006a71e20`, frozen 2026-05-28, `canonical: false`.

This pass records what the article SAYS, faithfully. Each major claim tagged (fact) or (opinion). "(fact)" = verifiable/definitional or a reported observation; "(opinion)" = a normative or contestable judgment. Note: the Notion page is itself a research write-up that already contains its own "Pass 2" and "Pass 3" sections — those are the *author/curator's* interpretation and self-application, and I record them here as claims the page makes, not as my own analysis.

## Framing and provenance

- The piece is framed "in the spirit of 12 Factor Apps" — engineering principles you apply *inside what you're already building*, not a framework to adopt. (opinion / framing)
- Core claim: most production agents aren't truly agentic — they're "mostly deterministic code with LLM steps at the right inflection points," and that is the pattern, not a bug. (opinion)
- Provenance offered as evidence: Horthy tried every major agent framework (LangChain, LangGraph, smolagents, crewAI, griptape) and talked to 100+ technical founders. (fact — reported experience)
- The recurring pattern claimed: frameworks get you to 70–80% quality, then you spend the rest reverse-engineering the framework to go further. (opinion, presented as observed pattern)

## The load-bearing axiom

- **Factor 12 is declared the foundation everything else derives from:** "Make your agent a stateless reducer. Given the same context window, the agent always produces the same next action." (opinion — it is an architectural stance, asserted as foundational)
- The agent loop is presented as a literal while-loop: `context=[initial_event]; while True: next_step=llm.determine_next_step(context); context.append(next_step); if done: return; result=execute_step(next_step); context.append(result)`. (fact — it is the author's reference implementation)
- Claim: every other factor is a consequence of taking F12 seriously; "test it like a function, debug it like a function." (opinion)

## The 12 (+1) factors as stated

1. **Natural Language to Tool Calls** — LLM's only job is to decide the next action, outputting structured JSON; deterministic code executes. LLM = decision, code = action. This separation is what makes agents debuggable. (fact about the design; opinion on "what makes debuggable")
2. **Own Your Prompts** — if a framework hides prompts you can't debug output quality; visibility into what the LLM sees is "non-negotiable"; framework opacity is "the root of the 70–80% wall." (opinion)
3. **Own Your Context Window** — the context window is the agent's entire working memory; what you put in, in what order, with what compression, determines output quality "more than model choice." This is *context engineering*, "the most underrated skill." Explicitly flagged by the author as the hidden key factor. (opinion — strong)
4. **Tools Are Just Structured Outputs** — tool calling is not magic, it's JSON schema; function calling / structured outputs / JSON mode are the same pattern at different strictness levels. (fact)
5. **Unify Execution State and Business State** — don't keep two state systems; agent execution state and application business state should live in one place. "Most async agent bugs live at this boundary." (opinion / claimed observation)
6. **Launch/Pause/Resume with Simple APIs** — production agents get interrupted; design for pause/resume from the start; requires serializable state, which is a consequence of F12. (opinion + fact dependency)
7. **Contact Humans with Tool Calls** — human approval isn't a special interrupt; it's just another tool the agent calls. Makes human-in-the-loop trivial to add/remove and keeps the loop uniform. (opinion — the article's favored "elegant reframe")
8. **Own Your Control Flow** — LLM decides the action; keep if/else and switch in your code. The moment a framework owns control flow, debugging becomes reverse-engineering the framework. (opinion)
9. **Compact Errors into Context Window** — a failed tool call is information, not an exception to throw; put the error back in context so the agent can reason and retry differently. Error handling is just another context event. (opinion — explicitly "a complete inversion of conventional exception-handling instincts")
10. **Small, Focused Agents** — one agent, one job; reliability degrades with scope; production agents do one thing well and hand off cleanly. "The hardest discipline to maintain" because scope creep is the path of least resistance. (opinion / claimed observation)
11. **Trigger from Anywhere** — email, Slack, webhook, cron, mobile; same agent triggerable from any surface without rewriting core logic. The trigger is just how you construct the initial context. (opinion / design goal)
12. **Make Your Agent a Stateless Reducer** — restated as the architectural principle that makes everything tractable. (opinion)
13. **(Honorable Mention) Pre-Fetch All the Context You Might Need** — fetch everything potentially relevant before the loop starts, not reactively mid-execution; reduces latency, makes behavior more predictable. (opinion)

## The page's own "Pass 2" (author/curator interpretation — recorded as claims)

- The 12 factors are not 12 independent tips but one coherent model with F12 as axiom and the rest as corollaries. (opinion)
- Stated derivations: F12→F1,F4 (reducer can only emit a structured action); F12→F6 (reducer is trivially serializable, pause/resume is "free"); F12→F5 (two state systems break the reducer invariant — unified state is a prerequisite, not a separate concern). (opinion)
- F3 is "the skill"; model choice is "almost a rounding error." (opinion — strong)
- F7 is "the most elegant reframe"; collapses an entire category of architectural special-casing. (opinion)
- F8 is "the anti-framework principle" — frameworks are "evil precisely because they own your control flow," which is why they hit 80% fast then become a ceiling. (opinion — strong, value-laden)
- F10 is "the hardest discipline" — every focused agent accretes scope without active resistance. (opinion)
- F9 is "a stance on error philosophy" — errors are just context. (opinion)

## The page's own "Pass 3" (curator self-application to "this system" — recorded as claims, NOT verified here)

The page already maps the factors onto "this system" (our harness). Recorded verbatim-in-substance so my own Pass 3 can check them:

- **Strong resonance (claimed already present):** F1/F4/F8 ↔ feature loop, skill architecture, control flow in deterministic code ("skills are the tool schema; agent decides, hook executes"); F6/F12 ↔ "AFK workflow model, human-checkpoints-complete gate"; F7 ↔ "human-checkpoints-complete gate, question batching in questions.md"; F2 ↔ "SOUL.md, skills as owned prompt templates."
- **Gaps it claims to illuminate:** F3 — the canon/not-canon distinction is "a context engineering problem" and "the most direct mapping to the existing CRITICAL gap stack"; F5 — the `updateProposal` enforcement gap in event-vendor is "exactly a F5 violation"; F9 — no error-into-context convention exists (new gap); F10 — specialist subagents exist but "one agent, one job" isn't codified (discipline gap), proposed new principle "an agent's job description should fit in one sentence"; F11 — agents only triggerable via Claude Code sessions, no webhook/email/cron/Slack path (medium-term gap, "a plumbing problem, not an architecture change").
- **New gap the page adds to "Research Delta":** "F9: No Error-into-Context Convention — OPEN (MEDIUM)."

## Key quotes (paraphrased in the source)

- Fastest path to production AI is taking small modular concepts into your existing product, not adopting a framework wholesale. (opinion)
- Most "agentic" agents are mostly deterministic code with LLM steps at inflection points. (opinion)
- Context engineering is the most underrated skill; model choice almost irrelevant by comparison. (opinion)
- The 70–80% wall isn't a model problem, it's a framework-owns-control-flow problem. (opinion)

## Relationship to prior research (as the page states it)

The page cross-links: Basis (canon/not-canon ↔ F3), Stripe Minions (F10 small agents, F7 human-as-tool), Harness/Agent-Ready Repos (F2/F8 = "agent-ready"), Ramp Inspect (F5 unified state), Linear (F11 trigger from issue events). (fact — these links are asserted by the page)

## What the article is fundamentally about (one line)

A coherent argument that production agents are deterministic programs with an LLM as a pure decision-function over an owned, engineered context window — and that everything painful about agents (debuggability, pause/resume, human-in-loop, errors, triggers) dissolves once you treat the agent as a stateless reducer and refuse to cede control flow, prompts, or context to a framework.
