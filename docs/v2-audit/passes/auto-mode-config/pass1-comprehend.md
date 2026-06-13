# Pass 1 — Comprehend: what the article SAYS

**Article:** "Research · Claude Code Auto-Mode Configuration — Reliable Long-Running Agents (2026)"
**Notion id:** 375e2971cd628135bd0dc8ff07a07e7b · research date 2026-06-04 · `canonical: false`
**Primary source it claims:** Anthropic "Configure auto mode" official docs (fetched 2026-06-04), plus the project's own `settings.json` / `CLAUDE.md` / `AGENTS.md`.

This pass restates the article's content and tags each load-bearing statement (fact) or (opinion). "(fact)" = the article presents it as a verifiable property of the tool/doc; "(opinion)" = a judgment, recommendation, or framing the article authored. The article embeds its own Claims Ledger with confidence tags — those are treated here as **claims to verify in pass 3**, not as settled fact.

---

## 1. The core model the article asserts

- **Auto-mode is a second classifier in series, not a prompt-disabling switch.** (fact, per primary doc) It evaluates each tool call against rules + an environment description and decides allow/block without a human. The "friction removed" was the interruption loop, not the safety evaluation. (opinion — the framing)
- **The failure mode inverts under auto-mode.** Before: an unsafe op produced a prompt an unattended agent couldn't answer → stall. After: the classifier silently blocks, or — if misconfigured — silently allows. "Excessive prompts were the problem before. Silent misclassification is the risk now." (opinion — risk framing, well-reasoned)
- **Four-tier precedence:** hard_deny → soft_deny → allow → user intent. (fact, per Claims Ledger / Hypotheses)
- **The classifier is stateless per call** — no "earned trust" from prior safe calls; each tool call is judged in isolation; the environment description must therefore be complete enough to classify any single action alone. (fact, attributed to 12-Factor Agents cross-link + doc)

## 2. The two-gates claim

- **`permissions.*` and `autoMode.*` are separate, independent gates that run in sequence:** permissions first, classifier second. (fact, per Claims Ledger — though the Ledger itself marks the "two separate gates" line as *inferred* from the doc phrase "a second gate that runs after the permissions system")
- **`permissions.allow` patterns do NOT inform `autoMode.environment`.** An op that passes `permissions.allow` can still be classifier-blocked if its destination isn't in `autoMode.environment`. (fact-claim)
- **`permissions.deny` is a pre-classifier hard stop** — blocked ops never reach the classifier. (fact-claim)

## 3. Environment is prose, and is the primary lever

- **`autoMode.environment` entries are prose, not regex/tool patterns.** (fact-claim, Verified in Ledger) You describe infrastructure "as you would to a new engineer." Design intent: cheap to write, impossible to over-scope with a greedy regex. (opinion — design-intent reconstruction)
- **Default environment trusts only the working dir + configured git remotes.** (fact-claim, Verified) Correct for an interactive single-repo session; wrong for a /queue run that pushes branches, opens PRs, hits Supabase CLI, or runs npm. (opinion — applied judgment)
- **"Environment is the primary lever, not allow rules"** — most config problems trace to a missing environment entry. (opinion — the article's headline recommendation)
- **Tradeoff:** prose interpretation is not mechanically verifiable without running `claude auto-mode config` and reading the expansion. (fact-claim → motivates the Design Challenge)

## 4. The `$defaults` footgun (the article's highest-stakes claim)

- **Setting any list field (`environment`, `allow`, `soft_deny`, `hard_deny`) without `"$defaults"` in the array REPLACES the entire default list for that section.** (fact-claim, Verified in Ledger) A `hard_deny` of three entries without `"$defaults"` silently discards built-in data-exfiltration blocks; a `soft_deny` without it discards force-push + `curl|bash` protection. (fact-claim)
- **This is the highest-risk config mistake.** Every custom list field must include `"$defaults"` unless you've run `claude auto-mode defaults`, copied every built-in rule, audited them, and deliberately taken ownership. (opinion — the rule the article prescribes)

## 5. Scope hierarchy + the "where autoMode lives" claim

- **Four scopes:** user (`~/.claude/settings.json`), project-local (`.claude/settings.local.json`, gitignored), managed (org), inline (`--settings` flag / Agent SDK). (fact-claim)
- **A developer can extend org rules but not remove them** (managed precedence is downward-binding). (fact-claim)
- **THE central operational claim:** "the classifier does NOT read `autoMode` from shared `.claude/settings.json`" (the committed project file). (fact-claim, Verified in Ledger) → therefore autoMode "should NOT live" in committed `.claude/settings.json`; it must live in `~/.claude/settings.json` (user) or `.claude/settings.local.json` (gitignored). (opinion/recommendation built on the fact-claim)
- **Consequence the article flags:** auto-mode config "cannot be code-reviewed the same way CLAUDE.md changes are." (opinion — a real downside it names)
- **Per-agent override:** `--settings` / Agent SDK inline JSON lets a /queue task carry a custom autoMode block (e.g. stricter `soft_deny` for a migration task) without polluting shared config. (fact-claim + recommendation)

## 6. CLI surface the article relies on (all tagged "Verified" in its Ledger)

- `claude auto-mode defaults` — prints built-in rules as JSON. (fact-claim)
- `claude auto-mode config` — prints effective config with `$defaults` expanded. (fact-claim)
- `claude auto-mode critique` — AI feedback on custom rules (flags ambiguous/redundant/false-positive-prone entries). (fact-claim)
- Denials surface in `/permissions` → "Recently denied" tab; a `PermissionDenied` hook enables programmatic reaction. (fact-claim)

## 7. CLAUDE.md coupling

- **The classifier reads the same CLAUDE.md content Claude itself loads** — so "Never force push" in CLAUDE.md steers both. (fact-claim, Verified) The project's destructive-operation rule (PocketOS) is therefore partly enforced by the classifier's `hard_deny` defaults; omitting `"$defaults"` would silently remove a layer of the project's *own* safety model. (opinion — the synthesis the article draws)

## 8. Application to event-vendor (the article's prescriptions)

- The 2026-06-03 4-task /queue run "likely succeeded because tasks stayed within the default trusted perimeter." (opinion — speculative, flagged "likely")
- A 10+ task run will push branches, `gh pr create`, Supabase CLI, npm, multiple worktrees → default environment blocks several silently → stalls. (opinion — predicted failure)
- **Minimum required before next overnight run:** an `autoMode.environment` block in **`~/.claude/settings.json`** covering GitHub org, Supabase project URL, npm registry, plus local services; verify `$defaults` present via `claude auto-mode config`; add project-specific `soft_deny` (no DB mutation outside migrations CLI; no Supabase writes outside `src/data/`). (opinion — the recommendation)
- **Recommended sequence:** environment first (additive, low risk) → verify with `config` → soft_deny extensions (restrictive, low risk) → `critique` any custom `allow` before enabling. (opinion)
- Ships a **copy-pasteable `~/.claude/settings.json` artifact** with a full `autoMode` block (environment/allow/soft_deny/hard_deny, each led by `"$defaults"`). The artifact's `environment` includes the single-tenant constraint "the Supabase project IS production — treat all Supabase mutations as production." (the artifact)

## 9. Cross-page connections (synthesis hooks, not re-read)

- **Stripe Minions:** devbox isolation ≈ `autoMode.environment` as the trusted perimeter; configure before the run, not reactively. (opinion — analogy)
- **Ramp / Inspect Agent:** blast-radius ≈ `hard_deny` being unconditional (user intent + allow don't apply). (opinion — analogy)
- **12-Factor Agents:** stateless reducer ≈ per-call classification with no trust memory. (opinion — analogy)
- **Research Delta (self-declared):** claims it closes the Wave-1/queue-hardening gap "what settings are needed before spawning background agents?" with a concrete artifact. (opinion — self-assessment)

## 10. The Design Challenge it poses (and leaves unbuilt)

- Because environment is prose, you can't unit-test "the classifier will allow `gh pr create` on github.com/tanner-dev." Build a **pre-flight Bash script** that: (1) verifies every external destination a /queue run touches is in the effective environment; (2) catches an accidentally-omitted `"$defaults"`; (3) exits non-zero on failure; parses `claude auto-mode config` against a destination manifest. The article assigns this but does **not** write it. (the challenge — an acknowledged gap in its own deliverable)

## 11. Open questions the article itself leaves unresolved

1. Does `autoMode` in `.claude/settings.local.json` (gitignored, project-local) actually work? The doc's "doesn't read from shared `.claude/settings.json`" is ambiguous about whether that covers all project-scoped files. (self-flagged unknown — material to the recommendation)
2. What exactly does `auto-mode critique` evaluate — over-breadth of `hard_deny`? soft_deny conflicting with trusted environment? Or just style?
3. Does the classifier distinguish local Supabase (`127.0.0.1:54321`) from prod (`*.supabase.co`) for `supabase db reset`? The artifact's soft_deny assumes yes; unverified.
4. Can you see which rule fired for a given denial? Without attribution, debugging false positives is trial-and-error.
5. Ordering between the classifier's evaluation of `git push` and the pre-push `.cr-ok` hook.

**Net of pass 1:** The article is a tool-configuration study with an unusually honest epistemic frame (hypotheses-first, a Claims Ledger separating Verified from Primary-adjacent, explicit Unconfirmed items, five named open questions). Its spine is two fact-claims — (A) environment is the primary lever and (B) the `$defaults` omission silently strips safety defaults — and one operational claim — (C) the classifier ignores `autoMode` in the committed `.claude/settings.json`, so config must live user-level or in a gitignored local file. The deliverable is a copy-paste artifact placed at `~/.claude/settings.json`, plus an explicitly-unbuilt pre-flight-verification challenge.
