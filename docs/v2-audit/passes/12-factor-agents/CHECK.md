# Adversarial CHECK — "12-Factor Agents" 3-pass analysis

**Checker:** independent adversarial agent (doer≠checker). I did not write the passes. Goal: kill them.
**Verdict:** **sound** (one re-application worth flagging, not a defect).

---

## 1. Faked depth? NO — the three passes genuinely escalate.

- **Pass 1 (Comprehend)** records what the article *says*, tagged (fact)/(opinion), faithfully. Verified every article-attributed claim against the re-fetched source (`36ee…`): "70–80% wall," "100+ technical founders," framework list (LangChain/LangGraph/smolagents/crewAI/crewAI/griptape), "rounding error," "non-negotiable," the literal while-loop reference impl, honorable-mention F13 — all present in the source, all accurately quoted. Pass 1 also correctly notices the Notion page contains its *own* Pass 2/Pass 3 and records those as **the curator's claims, not its own analysis** — a sophisticated, honest distinction most readers would blur.
- **Pass 2 (Penetrate)** introduces analytical content that is NOT in Pass 1 and NOT in the article: the "demotion" thesis (model → `determine_next_step` call), the **circularity** critique (F12→F6 "free" only because F5 forces the precondition F12 assumed), the **single-loop blind spot** (F10/F11 break the reducer abstraction), the **depreciation collision** (context-engineering investment *depreciates* under capability gains, colliding with the map's §9), and the **F9-vs-F8 latent conflict** (retry/give-up is control flow → belongs in code, not model reasoning). Term-frequency check confirms these concepts are net-new in pass 2 (circular 0→1, depreciate 0→1, single-loop 0→2, boundary-policing 0→1, demot 0→2).
- **Pass 3 (Apply)** carries pass-2 findings forward onto specific canonical rows: the F9 gap is *re-scoped* using pass-2's F8 insight into "errors→context + deterministic circuit-breaker in a hook" (circuit-breaker appears 3× in pass 3, 0× in pass 1). Each pass is demonstrably informed by and built on the prior. This is the real 3-pass doctrine, not one read reformatted.

## 2. Unsupported claims? NONE found.

Every claim attributed to the article is in the article. Every claim attributed to the canonical map is in the map (verified by grep): `block-dangerous-git/npm-install` exit-2 guards [§3e], `.cr-ok` sentinel chain [§3e], SOUL/agent-contract/AI-WORKFLOW [§3a], the 5-store + auto-memory model [§4], 23 agents [§3d], "never installed anywhere but event-vendor" [§8], Sonnet 4.6→Opus 4.8 capacity audit [§9], no webhook/cron/Slack surface [§2/§8].

## 3. Phantom gaps (gap proposed that's already built)? NONE.

This is the #1 failure mode and the analysis explicitly *avoids* it. Section (a) credits what IS built; section (b) reserves five gaps, each tied to a **confirmed absence**:

| Pass-3 gap | Verification against map | Phantom? |
|---|---|---|
| F3 authority-within-context | §0 correction-log (audit artifact rots) + §4 admitted ambiguities (PITFALLS/memory dual-layer, read-time for ~5/14 files) confirm authority is undefined | NO — real |
| F5 state unification | §4: triple-duplication "encoded in no tooling"; auto-memory "a sixth store the canon doesn't account for" | NO — real |
| F9 errors-into-context | grep for error/circuit-breaker/retry/tool-failure in map → **zero hits**; confirmed absent | NO — real |
| F10 scope discipline | grep for "one agent/scope-limiting/job description" in map → zero; roster exists [§3d], rule doesn't | NO — real |
| F11 trigger-from-anywhere | §2/§8: only Claude Code sessions + git hooks + CI; no webhook/cron/email/Slack | NO — real |

**killedGaps: none.** I could not find a single proposed gap that the harness already covers.

## 4. Misapplication? One re-application worth flagging — but it is transparent and defensible, not a defect.

- **F5 mapped to memory-duplication, not execution-vs-business state.** The article's F5 is *execution state vs business state* (agent's view of proposal status vs the DB row). Pass 3 re-targets F5 onto the **knowledge-store triple-duplication** (memory.md + PITFALLS + auto-memory) — a different axis (knowledge stores, not execution/business). This *could* be a stretch. But pass 3 **does not hide the move**: it explicitly KILLS the page's own `updateProposal` F5 example as unverifiable (correctly — grep confirms `updateProposal` is nowhere in the map; it is a *product*-layer claim smuggled into a *harness* audit), then re-scopes F5 onto the strongest *harness*-layer analogue it can cite. That is honest re-application with a stated rationale, not a misapplication. The checker would have docked it had it asserted the `updateProposal` claim uncritically — it did the opposite.

## 5. What the analysis got RIGHT that a weaker checker would miss

- It **audited the source page's own self-application** and found it wrong (`updateProposal` not in ground truth; `canonical: false` + frozen snapshot → self-claims non-authoritative). This is the inverse of the usual failure: instead of inheriting the page's pass-3 as fact, it re-grounded every claim.
- It **sharpened** the article's raw F9 into an F8-aware, harness-specific gap ("circuit-breaker in a hook") rather than parroting "errors→context."
- Its §(d) "do we need fresh research?" answer ("mostly no — synthesize") is correct and disciplined: the map already contains the rows; the work is mapping/decision, not discovery. It resists the over-research reflex.

---

## Net

I tried to kill it on all four axes (faked depth, unsupported claims, phantom gaps, misapplication) and it held on every one. The single flaggable item (F5 → memory-duplication) is a transparent, rationalized re-application, not an error. The analysis is unusually honest — it spends as much energy attacking the source page's own pass-3 as praising it. **Sound.**
