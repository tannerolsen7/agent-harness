# Pass 3 — Apply (vs. ground-truth map)

**Building on pass2:** pass-2 reframed the page from "egress controls" to a law about **trust
granularity** ("the adversary is always one level finer than the boundary you drew"), and produced
the **enforcement-plane test** — *any control must name a non-model enforcer or it is a behavioral
defense in disguise and fails the page's own 24/25 standard* (pass-2 §"Net-new synthesis" #2). It
also localized the real solo threat to **fetched external content flowing into an agent holding prod
credentials** (pass-2 #3), and named **logging as the keystone** (pass-2 #4). This pass maps those
against `CANONICAL-HARNESS-AS-IS.md` and live disk inspection. Every gap cites a ground-truth section
or a confirmed absence.

Disk facts verified live this session (cited inline as `[verified]`): `.claude/settings.json` has
**92 allow entries**; network-capable entries include `Bash(gh api *)`, `Bash(gh pr *)`,
`Bash(npm install*)`, `Bash(supabase *)`, `Bash(npx supabase *)`, `WebFetch(*)`, and
`mcp__claude_ai_Supabase__apply_migration` (a remote write). `.env.local` exists at repo root (756
bytes, agent-readable). Hooks on disk: `block-dangerous-git.sh`, `block-npm-install.sh`,
`permission-logger.sh`, `session-start.sh`, `worktree-create.sh`. Scripts include `gen-local-env.sh`,
`test-local.sh`, `worktree-add.sh`, `pr.sh`.

---

## (a) What we ALREADY do — and how far it actually gets us

| Page principle (pass-1) | Already on disk | Ground-truth cite | Honest coverage |
|---|---|---|---|
| Bound blast radius — "secrets in host keychain, prod creds separate from agent workspace" (4-layer floor, layer 4) | **Tier-0 prod-key firewall**: `worktree-create.sh` + `gen-local-env.sh` + `test-local.sh` provision a local stack and refuse to run vitest unless the URL is `127.0.0.1` | `[disk §3e worktree-create.sh]`, `[disk §6]`, `[verified]` | **Strong, and ahead of the page.** This is exactly the page's layer-4 "host keychain not .env" pattern, built before the article. It is the one place disk *exceeds* the page. |
| Log every tool call/denial (4-layer floor, layer 3) | `permission-logger.sh` (PostToolUse logger) | `[disk §3e]`, `[disk §6]`, `[verified]` | **Partial.** A logger exists — but pass-2 §4 says logging is the *keystone*; the map calls it merely "observational, canon doesn't declare it." It logs permission events, not a queryable record of every outbound call + denial for post-hoc overnight investigation. The mechanism exists; the forensic completeness does not. |
| Restrict tool scope / no terminal (4-layer floor, layer 1) | `block-dangerous-bash.sh` would be the floor — **but it is ABSENT on disk** | `[canon §5 block-dangerous-bash.sh]`, `[disk §3e: "ABSENT on disk"]` | **Mostly absent.** Disk has `block-dangerous-git.sh` + `block-npm-install.sh` only; the canon's third "safety-floor bash guard" (the one closest to the page's "no terminal / safe buttons") is not built. |
| Destructive-op confirmation (capability-not-behavior in spirit) | CLAUDE.md PocketOS rules; `block-dangerous-git.sh` | `[disk §3e]`, canon §9 "keep verbatim" | **Real but advisory + one deterministic sliver.** The git guard is a non-model enforcer (passes pass-2's test); the PocketOS prose rules do not (model-enforced). |
| Egress restriction for /queue | **None beyond the default sandbox** | `[verified: WebFetch(*), gh api *, supabase * all in allow]` | **Absent.** Covered as a gap in (b). |

**Summary of (a):** event-vendor already implements the page's *layer 4* (blast-radius / credential
isolation) better than the page describes, and has the *raw material* for layer 3 (a logger). It does
**not** implement layers 1 (full safety-floor / narrow-tool discipline) or 2 (egress validation) in
any non-model form.

---

## (b) REAL gaps — each cites a ground-truth section or confirmed absence

**Gap 1 — No egress control of any kind for /queue; the allow list is full of permitted-path
exfiltration surfaces.** The page's flagship finding (egress is "the only defense that holds") has
**zero** corresponding mechanism on disk. `[verified]` the 92-entry allow list contains
`Bash(gh api *)` (arbitrary GitHub API mutations incl. writes), `Bash(npm install*)` (arbitrary
postinstall network), `Bash(supabase *)` + `mcp__claude_ai_Supabase__apply_migration` (remote DB
writes), and `WebFetch(*)` (unrestricted outbound fetch). Per pass-2's unifying law, each is trust
granted at *destination* granularity, not *operation* granularity. The ground-truth map confirms no
egress hook and no network guard exists: the hook roster `[disk §3e]` has no egress entry, and §5/§6
list none. This is the single largest gap the article surfaces.

**Gap 2 — `WebFetch(*)` is the actual untrusted-input channel and it is wide open.** Pass-2 §3
localized the real solo threat to *fetched external content flowing into a credential-holding agent*.
`[verified]` `WebFetch(*)` is allow-listed with no domain restriction, running in the same session
that holds `apply_migration` and (via `.env.local`) the prod service-role key. The map documents no
control on fetched-content provenance anywhere. This is the precise injection→exfiltration path the
24/25 result demonstrates, present on disk, and **not** covered by the Tier-0 firewall (which guards
*test DB* selection, not *outbound* traffic or *fetched input*). Confirmed absence: no row in
`[disk §3e/§5/§6]` addresses inbound-content trust.

**Gap 3 — `.env.local` is agent-readable in the repo the agent works in.** The page's blast-radius
recommendation (pass-1 application, "verify `.env.local` is not readable during /queue") maps to a
confirmed disk fact: `[verified]` `.env.local` exists at repo root (756 bytes) and `.env.local`
"points at **production** Supabase" per CLAUDE.md. The Tier-0 firewall isolates *vitest's* target,
but does not remove the prod key from a path the agent can `Read`. Per pass-2's localized threat, one
injected WebFetch result instructing a read+POST of `.env.local` is the whole exploit. Cite:
`[disk §6 prod-key firewall]` covers test-DB isolation only; the readable-prod-key surface is a
confirmed residual absence.

**Gap 4 — No non-model enforcement plane for task scope; the only "scope" is the Bash allow list.**
The page proposes a /queue task manifest. The map confirms /queue's only scope control today is
`permissions.allow` at the Bash level — there is no per-task action scope (`/queue` appears in §3b as
a skill, with no manifest mechanism anywhere in §3e hooks or §5 canon-only registry). By pass-2's
**enforcement-plane test**, a manifest is only real if a hook/wrapper enforces it; the canon's
*nearest* structural primitive, `enforce-scope.sh` (blocks staging files outside `## ALLOWED FILES`),
is **canon-declared but ABSENT on disk** `[canon §5 enforce-scope.sh; disk §3e "absent on disk"]`.
So the *enforcer substrate* the page's manifest would need does not exist either.

**Gap 5 — The safety-floor bash guard the page implies (layer 1, "no terminal") is unbuilt.**
`block-dangerous-bash.sh` (deploys, `rm -rf`, writes to `.git`/`.husky`/`.claude`) is `[canon §5;
disk §3e: ABSENT]`. This is the deterministic, non-model layer-1 control. Its absence means the
page's "first line of containment" has no enforcement on disk.

**Gap 6 — Logging exists but is not forensic-grade, and pass-2 says it's the keystone.** `[disk §3e
permission-logger.sh]` logs permission events; there is no append-only, queryable record of *every
outbound network call + every denial* scoped to a /queue run — the exact artifact needed to answer
the page's own undetectable threat (memory poisoning, Open Q5) and to audit an overnight run after
the fact. Gap = the delta between "a permission logger exists" `[disk §6]` and "complete egress/tool
forensics," a confirmed absence.

---

## (c) The article's own weaknesses (carry forward from pass-2; do not let pass-3 launder them)

1. **Its flagship solo recommendation fails its own 24/25 test.** The model-read task manifest with
   "STOP AND SURFACE" is a *behavioral* control (pass-2 Hidden Assumption #1). Any event-vendor
   proposal derived from it must add a **non-model enforcer** (hook/wrapper), or it inherits the flaw.
2. **Threat-model mislocalization.** The page optimizes against an attacker-planted workspace file —
   the *least* applicable solo scenario — and barely mentions fetched-content injection, the *most*
   applicable (pass-2 Hidden Assumption #2). Gap-2 above corrects for this; do not adopt the page's
   actor.
3. **Self-contradiction on the Seatbelt sandbox** — "fully transfers, no action" vs. "no explicit
   egress restriction… permits any destination" (pass-2 §contradiction). The page does not know
   Claude Code's real default egress profile (its own Open Q1). Treat the sandbox as a *filesystem*
   win only; assume **zero** network containment until measured.
4. **Most of the page is non-transferable infrastructure** (gVisor, VM, MitM proxy, OTLP,
   wake-on-demand) — the page's own table admits this. The durable residue is one principle:
   *allowlist operations, not destinations; enforce off the model* (pass-2 §"transferable residue").
5. **Single-source empirics.** Every load-bearing number (93%, 84%, 24/25) is Anthropic-internal and
   externally unverifiable (pass-1 Source Reliability). The *direction* is trustworthy; the
   *magnitudes* should not be quoted as settled fact in any V2 doc.

---

## (d) Is fresh research warranted? — Prefer synthesize

**No new external research is warranted to act on this page.** The actionable content reduces to
gaps already grounded in the map + verified disk facts; the page's transferable core is one principle
we can apply immediately. Three items are *local verification*, not research, and should be done in
synthesis rather than spun out:

- **Measure, don't research, Claude Code's default /queue egress profile** (resolves the page's Open
  Q1 *for our install*): a one-session empirical check of what the sandbox actually permits
  outbound — not a literature task.
- **Confirm whether `apply_migration` / `gh api` / `WebFetch(*)` are reachable in the *unattended*
  /queue allow set specifically** (vs. interactive) — a config read against `[verified]` settings,
  not research.
- **The "operation-not-destination" principle is already fully synthesized** here and in pass-2; it
  needs a *design decision* (build an egress hook? scope the allow list? remove `WebFetch(*)` from
  unattended runs?), not more reading.

One genuinely open thread is worth a *flag, not a research spawn*: the page's Open Q4 (multi-agent
trust escalation — "for a /queue system that uses sub-agents… this is the current architecture").
event-vendor's `/cr` and `/queue` *do* fan out sub-agents whose structured output is trusted by an
orchestrator (this very task is an instance). That is a real, novel surface the map does not address
— but it is a **design question for Phase 3/4**, answerable by applying pass-2's enforcement-plane
test to sub-agent output provenance, not by external research. Synthesize, don't fan out.

---

## Net for V2 (what survives the anti-duplication gate)

Citable, non-duplicative items this page legitimately surfaces:
- **Build an egress/operation control for unattended /queue** — closes Gaps 1, 2, 4; maps to
  `[canon §5 enforce-scope.sh / block-dangerous-bash.sh]` absences and `[verified]` open allow list.
  Must have a **non-model enforcer** (pass-2 test).
- **Remove the prod-key surface from agent-readable paths during unattended runs** — Gap 3, extends
  the existing Tier-0 firewall `[disk §6]` from test-DB isolation to outbound/read isolation.
- **Promote `permission-logger.sh` to forensic-grade egress logging** — Gap 6, the keystone layer
  (pass-2 §4), building on `[disk §3e]`.
- **Drop `WebFetch(*)` (and `gh api *`, `apply_migration`) from the *unattended* allow set unless an
  enforcer validates the operation** — directly from `[verified]`, the cleanest immediate win.

Rejected as duplicate/non-transferable: VM/devcontainer adoption (the page admits it doesn't
transfer at solo scale and it duplicates the devcontainers research page already in the corpus); the
MitM token proxy (requires a VM boundary we don't have); wake-on-demand and EDR (wrong problem, per
the page's own table).
