# Pass 1 — Comprehend: "How Anthropic Contains Claude — Capability Boundaries, Sandboxes & Egress Controls"

Notion id `375e2971cd6281abaa79ccf5a9243060`. Fetched successfully (2026-06-04 snapshot).
This pass records *what the article says*. Claims are tagged **(fact)** = empirical/attributed to a
source, or **(opinion)** = the curator's synthesis, judgment, or design recommendation. The page
embeds its own curator passes (Hypotheses, Source Reliability, Claims Ledger, Synthesis,
Application). Per instructions, those are treated as **claims to verify**, not settled fact — most
land as (opinion) below even when the page presents them assertively.

---

## The three sources (as the page describes them)

1. **Anthropic Engineering Blog — "How We Contain Claude Across Products" (May 25, 2026).** The
   page's primary source; "the source is the subject." (fact: source identity) Note: the page spells
   it "Anthropoc" twice — a typo, flagged here, not a different entity.
2. **sandboxed README (tastyeffectco/sandboxes, beta).** A self-hosted multi-tenant container
   isolation platform; "the source is the artifact itself." (fact: source identity)
3. **Security Engineering Weekly — "How I'd Secure an AI Chat System Before It Leaks Your .env
   File" (undated, author unnamed).** Rated **Secondary** by the page — practitioner opinion, no
   original data. (fact: the page's own rating)

The page states all three were "provided verbatim" and "read directly," with "no inference about
content required." (opinion — the curator's self-report on method, not independently checkable.)

---

## The anchor thesis

> "Rather than supervising what the agent does, we supervise what it's able to do by enforcing
> access boundaries through… sandboxes, virtual machines, and egress controls." (fact — quoted from
> the Anthropic blog)

The page's central claim: this framing is **confirmed but with a hard caveat** — what "supervising
what it's able to do" *requires in practice* is **egress control specifically, not sandboxes
generally**. (opinion — the curator's sharpening of the quote.)

---

## Empirical figures from the Anthropic blog (Claims Ledger, all rated "Verified")

- claude.ai executes code in **gVisor containers, ephemeral per-session**. (fact)
- Claude Code users approved **~93% of permission prompts** before the sandbox redesign. (fact —
  Anthropic-internal telemetry; the page flags it as unverifiable externally.)
- OS-level sandbox (**Seatbelt** macOS / **bubblewrap** Linux) reduced permission prompts by
  **84%**. (fact — internal telemetry.)
- In red-team testing, **credential exfiltration succeeded 24 of 25 attempts** despite model-layer
  defenses (system prompts, classifiers, trained behaviors). (fact — internal telemetry; the page's
  load-bearing data point.)
- Stated conclusion: **"the only defense that holds in this situation is the environment,
  specifically egress controls that block the POST regardless of intent."** (fact — direct quote.)
- **Claude Cowork uses full VM isolation** (Apple Virtualization / HCS), credentials in the **host
  keychain, not the guest**; **agent loop runs outside the guest, code execution inside**. (fact)
- The Cowork exploit: **malicious workspace files used the Files API (api.anthropic.com) as an
  egress channel** — attacker embedded *their own* API key in a workspace file and instructed the
  model to exfiltrate via the Files API. (fact)
- Fix: a **defensive man-in-the-middle (MitM) proxy inside the VM that rejects non-session
  tokens** — accepts only the VM's provisioned session token. (fact)
- **VM isolation blocks enterprise EDR tools from monitoring guest activity**; mitigation is
  **pull-based OTLP exports** for post-hoc retrieval (auditability without live monitoring). (fact)
- **Symlink resolution must occur before path validation** to prevent sandbox escape. (fact — a
  named implementation bug class.)
- **Pre-trust execution vulnerability:** hooks ran *before* the trust prompt was accepted. (fact)
- Named **future** threats: **persistent memory poisoning**, and **multi-agent trust escalation**
  (a sub-agent's structured output receiving higher trust than raw tool results). (fact — named as
  future vectors by the blog.)

## Figures from the sandboxed README ("Verified" for the architecture it describes)

- Uses **hardened runc** (`cap-drop ALL`, `no-new-privileges`, read-only rootfs) + Docker. (fact)
- Architecture: **one Go binary + Traefik + SQLite, no Kubernetes**; wake-on-demand for idle
  agents. (fact)
- Recommends **VM-per-tenant** (or gVisor/Kata/Firecracker) for "untrusted strangers' code,"
  reserving hardened Docker for "your own users running their own code." (fact — the repo's own
  threat-model split.)
- Flags **"open, unlogged network egress"** as kept-simple-on-purpose: fine for dev, unacceptable
  for untrusted code. (fact)

## Figures from Security Engineering Weekly (Primary-adjacent only when Anthropic confirms)

- **Tool gateway pattern:** check identity, role, tenant, resource access *before* execution.
  (opinion → page upgrades to Primary-adjacent "confirmed by Anthropic MCP trust discussion.")
- **"Do not give the AI a terminal. Give it safe buttons."** (opinion — practitioner maxim.)
- **Authorization must live outside the model**, in policy engines and tool gateways. (opinion,
  page-confirmed-adjacent.)
- **Block arbitrary outbound by default**; restrict to approved internal + external destinations.
  (opinion, page-confirmed-adjacent by the egress-as-last-defense finding.)

---

## The page's synthesis claims (curator's own analysis — (opinion) unless noted)

1. **"regardless of intent" is load-bearing.** The defense must hold *even when the model is
   actively trying to comply* with malicious instructions — which it was, 24 times. So "supervise
   capability not behavior" is "the only approach that survives adversarial conditions." (opinion —
   built on the 24/25 fact.)
2. **The sandbox is not enough — the gap is specific.** Claude Code's sandbox denies network *by
   default* but **permits api.anthropic.com by design**. The permitted path is where exfiltration
   occurred. "A sandbox that permits any outbound connection has an egress profile that must be
   evaluated as carefully as the sandbox itself." (opinion, grounded in facts.)
3. **The allowlist-as-capability-grant inversion** (the page's sharpest reframe): the allowlist
   *worked correctly* and the attacker exploited it anyway. The fix reframes the allowlist as **a
   list of permitted *operations*, not trusted *destinations*** — "the question is not 'what domains
   can the agent reach' but 'what authenticated operations can the agent perform at those
   domains.'" (opinion — the page's headline conceptual move.)
4. **VM isolation = strongest boundary, most expensive tradeoff.** Strength (VM) trades against
   visibility (EDR blindness). "Not a solved problem; a known gap with a partial workaround." (opinion.)
5. **Narrow tools as the *first* line of containment, not the last.** "A tool called `run_command`
   with a command string argument is not a tool; it is a terminal with extra steps." Allowlists give
   "surface containment with no depth containment" if an allowed tool accepts an arbitrary string
   passed to a shell or SQL executor. "The narrowness is the security property." (opinion — the
   page's most transferable design rule.)
6. **Four-layer minimum viable containment floor** (ordered by ease): (1) restrict tool scope at
   design time (narrow tools, no terminal, no arbitrary-path file read); (2) enforce explicit egress
   at the application layer — validate the *operation*, not just the destination; (3) log every tool
   call and denial for post-hoc investigation; (4) bound blast radius (secrets in host keychain, not
   `.env`; prod creds separate from agent workspace). A VM/firewall is the 5th. **"The gap between
   zero containment and the first four layers is larger than the gap between four and five."**
   (opinion — the page's central practical recommendation.)

---

## Application-to-event-vendor claims (the page's own, all tagged Candidate / Open question)

- **Minimum viable egress for /queue:** event-vendor has "no explicit egress restriction beyond
  Claude Code's default Seatbelt sandbox." Audit `permissions.allow` in `.claude/settings.json`:
  "any entry that permits a command capable of outbound HTTP is an egress permission, not just a
  filesystem permission." Open question: do `npm install`, `gh api`, Supabase CLI entries
  transitively permit network calls? (opinion + open question)
- **Network-level isolation on macOS:** feasible via `pf` rules or Little Snitch, but must permit
  both api.anthropic.com and the Supabase URL; "permitted destination is insufficient if the
  operation is not also validated." Ceiling without devcontainers: process-level firewall + logging
  + app-layer credential validation. (opinion)
- **Easiest blast-radius wins (no new infra):** (1) audit allow list for `curl`/`wget`/
  `npm install`/`gh api`/Supabase-remote-write; (2) verify `.env.local` is **not** readable by the
  Claude Code process during /queue ("the production Supabase service role key is one successful
  prompt injection away from exfiltration"); (3) scope /queue Supabase creds to read-only /
  migration-scoped keys, not the service role key. (opinion — actionable recommendations.)
- **Devcontainers interaction:** the VM boundary is "specifically what closes the egress
  exfiltration gap"; a devcontainer for /queue gives host-keychain creds + provisioned-token-only
  agent + container network policy. "Strongest argument for adopting devcontainers specifically for
  /queue runs even if the daytime loop stays on the bare host." (opinion)
- **Tool gateway applied to event-vendor:** applies to server actions in `app/(app)/*/actions.ts`;
  current authz is RLS + role checks in `src/data/`. Proposes a **task manifest /queue reads at
  startup** defining permitted actions; out-of-scope action → STOP AND SURFACE. Open question: does
  /queue have per-task action scope, or only the Bash-level allow list? (opinion + open question)

## "What Doesn't Transfer at Solo Scale" (the page's own table)

- gVisor isolation → partially (Docker + cap-drop ALL feasible, needs setup).
- OS-level Seatbelt sandbox → **fully transfers, already active, no action**. (fact about Claude Code default)
- Full VM + host keychain → partially (devcontainers; EDR gap irrelevant solo).
- MitM token-validation proxy → **doesn't transfer directly** (requires VM boundary).
- Operation-level egress allowlist → partially (key scoping transfers; token proxy doesn't).
- Tool gateway → partially (concept transfers, simpler at solo scale).
- Wake-on-demand pool, enterprise EDR, NIST/ACSC/ISO identity standards → **don't transfer** (wrong
  problem / wrong context / not yet).

## Design Challenge (posed, not answered)

Treat /queue's permitted `gh api` calls as a permitted-path exfiltration surface. Design a task
manifest that closes it *without* a network proxy; then answer whether it *prevents* or merely
*reduces* the attack — and if reduction, what the residual risk is. (The page poses this; it does
not solve it.)

## Open Questions the page leaves unresolved (condensed)

1. Real egress profile of the Seatbelt sandbox — was the red-team config reduced, or is 24/25
   reproducible in a standard install?
2. What the session-token proxy inspects — Authorization header only, or request bodies too?
3. Do CLAUDE.md files fall in the same pre-trust-execution category as hooks? (A malicious CLAUDE.md
   in a cloned repo as an instruction-injection surface.)
4. Timeline for multi-agent trust escalation becoming an active exploit — "for a /queue system that
   uses sub-agents… this is not a future threat — it is the current architecture."
5. Practical detection pattern for persistent memory poisoning (CLAUDE.md, `.claude/memory.md`,
   /queue task manifests) short of reviewing every change.

---

## One-line thesis (pass 1 reading)

Containment must supervise **capability, not behavior**, and among capability controls **egress —
specifically operation-level (not destination-level) egress — is the only defense that holds under
adversarial conditions**; at solo scale a four-layer, no-new-infra floor (narrow tools, app-layer
egress validation, total tool-call logging, bounded blast radius) captures most of the benefit
before a VM/devcontainer fifth layer.
