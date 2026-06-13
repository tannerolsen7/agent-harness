# Pass 2 — Penetrate

**Building on pass1:** Pass 1 separated the article's strong, sourced factual spine (§1.3 — the
Claims Ledger companies) from its opinion layer (§1.1, §1.4 synthesis, §1.5–8 the Application/Action
sections), and flagged two load-bearing claims to stress-test ("PR-as-gate already Adopted = the
single most important control"; "credential topology is the one control a solo dev can deploy") plus
the article's own self-undercut (Pass-1 §8 + Open Questions #2/#5). This pass goes underneath those
to the **deeper thesis, the hidden assumptions, and the contradictions the curator did not name.**

---

## A. The deeper thesis the article is actually arguing

Pass 1 recorded the surface thesis: *credential topology > compute isolation.* The deeper, unstated
thesis is sharper: **the 10-company survey is a misdirection layer over a one-company argument.** The
nine non-Anthropic companies all solve a *different problem* than Tanner has — they isolate **untrusted
third-party code submitted by their users** (Replit users, E2B/Modal/Vercel customers, Cursor/Copilot
end-users). Tanner runs **a trusted model on his own machine against his own repo.** The threat is not
"a malicious user submits code to my platform"; it is "a prompt injection turns *my* trusted agent
against *my* production." Only two of the ten cases — **Anthropic's red-team and Ramp** — are actually
that threat model. So the article's real evidentiary base is **two data points dressed as ten.** That
is not a flaw in the facts; it is a flaw in how Pass 1's "10 companies" framing invites you to weight
them. (Pass 3 must therefore privilege the Anthropic+Ramp rows and discount the microVM-vendor rows as
solving a problem this system does not have.)

The corollary: the microVM-vs-container schism (Pass-1 §4.1) is **the least relevant finding for this
system**, despite getting the most prose. The schism matters when you host *other people's* code. It
is nearly irrelevant when the question is "can my own agent reach my prod Supabase key" — because a
microVM with the service-role key inside it is exactly as dangerous as a bare process with the key in
its env. The article half-admits this ("a microVM with the prod key inside leaks it just as a Docker
container would") but never draws the conclusion: **for this system, the entire VM/container axis is a
distraction from the credential axis.** Compute isolation is a control for the platform builder;
credential topology is the control for the platform user. Tanner is a user.

## B. Hidden assumptions (each, if false, breaks a recommendation)

1. **Assumption: a "scoped" or "read-only" Supabase key meaningfully reduces blast radius.** The
   article's #1 action ("separate key with only schema/fixture read + migration dry-run") and #7
   ("read-only URL override") both assume Supabase exposes a credential tier between *anon* (RLS-bound,
   nearly useless for an agent that must read arbitrary fixtures) and *service-role* (full RLS bypass).
   **It largely does not.** Supabase's native tiers are anon, authenticated, and service-role; the
   "scoped read-only" key the article wants is **a custom Postgres role with explicit GRANTs and a
   bespoke PostgREST/connection path** — which this project does not have and which the article's "2h"
   estimate wildly under-prices. The article treats "create a dedicated key" as a checkbox; it is a
   schema-and-roles project. This is the single biggest gap between the article's confidence and
   reality.
2. **Assumption: the migration task is separable from prod-write.** Open Question #2 ("shadow DB")
   gently floats this, but the Design Challenge's own framing forces the issue — `supabase db push`
   **structurally requires** a credential that can DDL the target. The honest answer the article avoids:
   you do not give the overnight agent prod migration rights at all; you let it **write and locally
   verify** the migration against a throwaway local stack (`supabase start`, which this project already
   uses per CLAUDE.md's `test:local` flow), and a **human applies it to prod.** The article gestures at
   "shadow database" as if it were exotic; the project already has the primitive (local stack per
   worktree, per memory) and the article doesn't connect them.
3. **Assumption: "PR-as-gate" is a blast-radius control rather than a code-review control.** This is
   the article's most important hidden conflation. PR-as-gate bounds *what reaches main*; it does
   **nothing** about what the agent does *before* opening the PR — running `supabase db push`, reading
   and exfiltrating secrets, writing to other worktrees, `curl`-ing context to an endpoint. The damage
   the red-team measured (24/25 exfiltrations) **all happens pre-PR.** The article labels PR-as-gate
   "the single most important blast-radius control already in place," but by its own credential-topology
   thesis it is **not a blast-radius control at all for the highest-severity failure mode.** It is a
   code-quality gate that the article promotes one tier too high. Its own Open Question #5 (batch
   approval defeats it) is the *weaker* objection; the *stronger* objection is that the gate is
   downstream of the exfiltration it is credited with preventing.
4. **Assumption: deny-listing config files (#5) is a meaningful control against a prompt-injected
   agent.** Claude Code's permission deny list is enforced by the same agent runtime the injection is
   trying to subvert, and — more concretely for this project — **`.claude/settings.json` and hook files
   are already declared off-limits to agents** (memory `feedback_no_agent_edits_guard_files.md`, and
   the v0.97 hardening commits 99/100 on the current branch). The deny-list is real and worth having,
   but the article presents it as net-new when the project has already moved past "deny edits" to
   "Tier-0 credential isolation + worktree firewall." The article is **behind the disk** here (Pass 3
   confirms against ground-truth).
5. **Assumption: the failure modes are independent, so the controls compose additively.** They do not.
   The dominant failure mode (credential exfiltration) is defeated by exactly one control — creds not in
   the box — and *every other action item is downstream of, or redundant with, that one.* Seatbelt FS
   isolation (#3), the config deny-list (#5), the timeout (#8), OrbStack (#11): none of them stop
   exfiltration if the key is reachable, and all of them are unnecessary-for-that-mode if the key is
   not. The article's 12-item list reads as defense-in-depth but is really **one load-bearing control
   plus eleven hedges**, and it never says so. The honest prioritization is binary, not a 12-row table.

## C. Contradictions the curator did not name

1. **The egress argument contradicts the credential-topology thesis.** Synthesis §2 says "if creds
   aren't in the box, they can't leak — this is THE control." Synthesis §5 then says egress is
   under-controlled and that's dangerous because of "prompt-injection-driven supply-chain attacks." But
   a supply-chain attack (agent `npm install`s a malicious package, or `curl | bash`es a payload) is a
   **code-execution** compromise, not a credential leak — and credential topology does nothing against
   it. So the article's own §5 is evidence that its §2 thesis is **necessary but not sufficient**, yet
   it keeps billing credential scoping as "the one control." Egress filtering (#9, demoted to
   "follow-on") is actually the *only* listed control for the §5 attack class — it is mis-ranked.
2. **"PR-as-gate" is simultaneously "Adopted / most important" and structurally undercut by two of
   the article's own Open Questions (#2 migration runs pre-PR; #5 batch approval).** The Application
   table marks it green/Adopted; the Open Questions quietly mark it amber. The article never
   reconciles its own confidence.
3. **The microVM evidence undercuts the microVM recommendation.** Docker CVE-2025-907418 is cited to
   argue containers are weaker than VMs (→ evaluate OrbStack, #11). But the same red-team data shows the
   actual incidents needed **no escape at all** — the key was reachable. So the strongest cited
   container-escape evidence is for a failure mode that **did not cause any of the documented agent
   incidents.** The article spends its scariest fact (CVSS 9.3) on the least-relevant threat.

## D. Net-new analysis: re-ranking the article's own action list by THIS system's threat model

Synthesizing A–C: for a *trusted-model-on-own-machine* threat model, the article's "BLOCKS overnight
runs" ranking is wrong. The correct ordering, derived from the two relevant data points (Anthropic
red-team + Ramp) rather than the eight irrelevant ones:

- **Tier 0 (the only thing that stops 24/25):** prod credentials not reachable from the agent's env.
  For this project that is **not** "make a scoped key" (Assumption B1 — that's a roles project) but
  **"the agent's `.env.local` points at a local/throwaway stack, and prod keys live somewhere the
  worktree env cannot read"** — which the project's existing worktree-create prod-key firewall (commits
  99/100, memory `Tier-0 credential isolation`) was *built to do*. The article's #1 and #7 are the right
  instinct aimed at the wrong mechanism; the project already chose a better mechanism.
- **Tier 1 (stops the supply-chain class §C1 that credential topology misses):** egress allowlist (#9).
  The article demoted this to "follow-on"; the threat model promotes it.
- **Tier 2 (real but already largely done on disk):** config deny-list (#5), FS Seatbelt (#3),
  destructive-SQL scan (#12 — but see Pass 3: this is a *new* guard the disk lacks).
- **Tier 3 (operational, not security):** timeout (#8), audit log (#10) — these address the
  "10 silent PRs in the morning" problem (Open Q #5), which is a **throughput/observability** problem
  the article miscategorizes as blast radius.
- **Tier 4 (irrelevant to this threat model):** OrbStack/microVM (#11), Docker CVE check (#6) — these
  matter only if hosting untrusted third-party code, which this system never does.

The single most useful net-new framing for Pass 3: **the article's value to this system is not its
12 items but its one validated fact (24/25 exfiltration from ambient creds) and its one validated
pattern (Ramp: ephemeral-scoped-creds + PR-gate + per-session isolation). Everything else is either
already on disk, a roles-engineering project disguised as a checkbox, or a control for a threat model
this system doesn't have.**
