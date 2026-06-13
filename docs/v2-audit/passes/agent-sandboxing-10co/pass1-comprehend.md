# Pass 1 — Comprehend: "Agent Sandboxing in 2026 — 10 Companies, Blast-Radius Controls"

**Source:** Notion `375e2971cd62814598f9f5a4cca9bc13` (Research → AI-Native Engineering System).
Research date 2026-06-04. `canonical: false`. Fetch succeeded; full page read.

This pass records **what the article says**, tagging each load-bearing statement
`(fact)` — sourced, verifiable, attributed to a named primary/secondary source — or
`(opinion)` — the curator's synthesis, judgment, or extrapolation. The article carries its
**own curator passes** (Hypotheses, Claims Ledger, Synthesis, Application). Per task framing,
those are treated as **claims to verify in Pass 2/3**, not as established fact here.

---

## 1. The article's thesis (as stated)

The 2026 agent-sandboxing field has split into two camps, and the load-bearing safety layer
is **not compute isolation but credential topology**. *(opinion — the central synthesis claim.)*
A solo developer cannot replicate microVM infrastructure, but **can** replicate the one control
that actually stopped the documented incidents: keep production credentials out of the box the
agent runs in. *(opinion, built on a fact — see §4.)*

## 2. The six hypotheses (the article's own verdicts)

The article opens with six hypotheses it then self-adjudicates. These verdicts are the curator's
claims:

1. ⚠️ "All 10 companies use containers as primary isolation." → **Complicated.** 6 containers,
   4 (E2B, Vercel, Replit, GitHub Copilot cloud) use Firecracker microVMs. "Container-only
   isolation is now considered insufficient for untrusted code." *(opinion-verdict over facts.)*
2. ✔️ "Filesystem access and network egress are the two primary blast-radius surfaces." →
   **Confirmed.** *(opinion-verdict; the supporting per-company facts are real.)*
3. ❌ "Most companies offer a safe-mode / permission-ask model." → **Disconfirmed.** Dominant
   model is structural isolation ("sandbox the agent, not the action"). Only Claude Code ships a
   classifier-based auto-mode gating at the action level. *(opinion-verdict.)*
4. ⚠️ "Solo macOS devs have no real sandboxing options." → **Complicated.** Native options exist
   (Apple Seatbelt/`sandbox-exec`, OrbStack+Incus, Docker devcontainers) but require assembly;
   Anthropic shipped native macOS Seatbelt into Claude Code Oct 2025. *(opinion-verdict over facts.)*
5. ✔️ "Credential exfiltration, not filesystem destruction, is the highest-severity failure mode."
   → **Confirmed.** Anthropic red-team: 24/25 attempts completed credential exfiltration via
   malicious prompt; Cline extension compromise (Feb 2026) same pattern. *(verdict over a fact.)*
6. ⚠️ "DB write access is typically blocked for unattended runs." → **Complicated.** No company
   universally blocks DB writes; Replit is the exception (forks the DB per session). *(verdict.)*

## 3. Verified per-company facts (Claims Ledger — all tagged "Verified" or "Primary-adjacent")

These are sourced and labelled by the curator; treat as `(fact)` at the claimed confidence:

- **E2B** — Firecracker microVMs; pre-warmed VM snapshots, sandbox in <200 ms. *(fact, Verified.)*
- **Modal** — gVisor (user-space syscall interception), not Firecracker; no default inbound, no
  access to Modal workspace resources. *(fact, Verified.)*
- **Replit** — Snapshot Engine = copy-on-write block storage → constant-time FS snapshots; **forks
  the database per agent session**, rollback to any checkpoint; migrating containers → Firecracker
  microVMs. *(fact, Verified.)* Replit agent **deleted a production database, July 2025** (3
  corroborating sources). *(fact, Primary-adjacent.)*
- **GitHub Copilot** — cloud + local sandboxes public preview **June 2, 2026**; local sandbox uses
  Microsoft MXC; cloud sandboxes are ephemeral GitHub-hosted instances (Firecracker-implied). *(fact.)*
- **Vercel Sandbox** — Firecracker microVMs; no host FS / no host credentials; SDK allows outbound
  allowlist (opt-in). *(fact, Verified.)*
- **Amazon Q Developer** — managed sandbox with **no credentials to reach non-public internet**;
  restriction applies only to the managed variant, not customer-provided Docker. *(fact, Verified.)*
- **Cursor** — egress + secrets scoped at environment level as of May 2026. *(fact, Verified.)*
- **Ramp (Inspect agent)** — **30%+ of merged PRs**; runs on **Modal Sandboxes (gVisor)** with
  **ephemeral tokens per session**; output **always a PR, never a direct push to main**. *(fact,
  Verified / Primary-adjacent.)*
- **Anthropic red-team** — malicious prompt → **credential exfiltration in 24/25 attempts**;
  required only that production creds were reachable in-environment, **no container escape needed**.
  *(fact, Verified.)*
- **Anthropic / Claude Code** — native macOS Seatbelt + Linux bubblewrap shipped **Oct 2025**;
  auto-mode classifier reviews every tool call, catches ~83% of overeager behaviors. *(fact /
  Primary-adjacent; 83% appears in Synthesis prose, not the ledger.)*
- **Docker Desktop CVE-2025-907418 (CVSS 9.3)** — container escape reached the Docker Desktop VM
  daemon on macOS. *(fact, Primary-adjacent, Unit 42.)*
- **Stripe Minions** — per-task devbox isolation with scoped credentials (Cross-Page Connections).
  *(fact, cited but no source row in this page's ledger.)*

## 4. The four synthesis arguments (curator opinion)

1. **VM vs Container Schism.** VM isolation stops a post-kernel-exploit attacker; container does
   not. The container camp's defense is "creds aren't in the box anyway." A solo dev running Claude
   Code in a Docker devcontainer on macOS "has a weaker boundary than advertised." *(opinion.)*
2. **Credential topology is the load-bearing layer.** "If credentials aren't in the box, they can't
   leak regardless of [the compute boundary]." This is "the one blast-radius control available to a
   solo developer with no infrastructure team." *(opinion — the article's strongest claim.)*
3. **Classifier gates vs structural isolation — not alternatives.** They operate at different
   layers (what's reachable vs what the agent will try); the careful players (Anthropic, Ramp) use
   both. *(opinion.)*
4. **Reversibility infrastructure.** Replit's DB-fork is the only default DB-level reversibility;
   the consistent industry pattern is **PR-as-gate** — "the highest-confidence companies never give
   an unattended agent the ability to write directly to the canonical branch." *(opinion over facts.)*
5. **Under-controlled egress.** Egress filtering is nowhere on-by-default; industry's implicit bet
   is "if creds aren't in the box, egress doesn't matter" — which holds against exfiltration but
   **not against prompt-injection-driven supply-chain attacks**. *(opinion.)*

## 5. What the article says about THIS system (Application table)

The curator pre-maps findings to event-vendor (these are the article's extrapolations, status-tagged):

- `.env.local` in agent scope holds the **production Supabase service-role key** → full RLS bypass;
  a compromised prompt can read/write/delete any row. **Status: Open question.** *(opinion-extrapolation.)*
- Native macOS Seatbelt (`claude --sandbox`) restricts FS writes to the worktree; doesn't restrict
  egress. **Candidate.** *(opinion.)*
- Trail-of-Bits devcontainer = Docker isolation; verify CVE patch first. **Candidate.**
- **All /queue agents write to worktrees and open PRs via `scripts/pr.sh`** → "structurally
  equivalent to the Ramp/GitHub Copilot PR-as-gate model… the single most important blast-radius
  control already in place." **Status: Adopted.** *(opinion-verdict; load-bearing for Pass 3.)*
- No egress filtering for /queue sessions → Cline (Feb 2026) vector. **Open question.**
- Auto-mode (83%) would beat `--dangerously-skip-permissions` if plan allows. **Candidate.**

## 6. The Action Item List (12 items — the article's prescriptions)

"BLOCKS overnight runs" (items 1–8): (1) separate Supabase key, no service-role, only schema/fixture
read + migration dry-run [2h]; (2) scoped GitHub PAT, `repo` limited to event-vendor, rotate [1h];
(3) enable `--sandbox` Seatbelt for /queue [1h]; (4) audit whether parallel /queue sessions share one
`.env.local` symlink [0.5h]; (5) **deny-list agent writes to `.env.local`, `.env`,
`supabase/config.toml`, `.claude/settings.json`** [0.5h]; (6) verify Docker patched vs CVE [0.25h];
(7) read-only Supabase URL override per /queue run [1.5h]; (8) per-task wall-clock timeout (~45 min),
SIGTERM + commit [1h].
"Follow-on hardening" (9–12): (9) Privoxy/`pfctl` egress allowlist (GitHub, Supabase, npm, Anthropic)
[3h]; (10) per-session audit log outside the worktree [2h]; (11) evaluate OrbStack as VM-grade host
[4h]; (12) "no destructive SQL" pre-commit hook scanning migrations for `DROP TABLE`/`TRUNCATE`/
`DELETE` without `WHERE` [2h]. *(All prescriptions = opinion; each cites a derivation source.)*

## 7. Open Questions the article leaves unresolved (stated, not answered)

1. Auto-mode plan availability (not on Pro/Bedrock/Vertex/Foundry as of May 2026 — what's Tanner's?).
2. Can `supabase db push` run against a **shadow DB** so the agent verifies migrations without a
   prod-write credential?
3. Parallel /queue workers share one `.env.local` symlink → parallelism multiplies attack surface.
4. OrbStack operational overhead vs native macOS.
5. **PR-as-gate under high-velocity runs** — 10+ PRs batch-approved next morning may defeat the gate.

## 8. Design Challenge (posed, not solved)

Design the minimum credential set for overnight /queue runs that must: run migrations
(`supabase db push`), read schema/data for fixtures, write worktree files, open PRs. Identify which
task **cannot** be done without a service-role/admin credential and propose an architecture that
eliminates that requirement. *(This is the crux Pass 3 must engage — the migration credential.)*

---

### Pass-1 takeaways (carried into Pass 2)

- The article's **factual spine is strong and well-sourced**; its **verdicts and the entire
  Application/Action sections are opinion** layered on that spine.
- Two claims are load-bearing for this system and must be stress-tested: (a) "PR-as-gate is already
  Adopted and is the single most important control," (b) "credential topology, not compute, is the
  one control a solo dev can actually deploy."
- The article's own internal tension: it ranks credential scoping #1 yet its **own Open Question #5
  and #2** quietly undercut the two controls it relies on (PR-gate weakens under batch approval; the
  migration task structurally *needs* a prod-write credential). Pass 2 develops this.
