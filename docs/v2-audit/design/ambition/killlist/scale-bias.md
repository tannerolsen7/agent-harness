# Kill-List Attack: Scale-Bias

**Charge:** Catalog every world-class idea the conservative V2 synthesis dismissed because of
"solo / small-team / our-economics-differ" scale reasoning, and re-judge each under the new charter:
**scale = a world-class engineer running parallel agent fleets across 5+ repos, with autonomy first-class,
cloud `/schedule` proven, and `disable-model-invocation:true` making side-effect skills safe.**

**Method.** Grep across the 37 re-mines (`design/ambition/remine/<slug>.md`) and the 37 pass3 files
(`passes/<slug>/pass3-apply.md`) for scale-dismissal phrases (`solo`, `our scale`, `our economics`,
`single-project`, `single-vendor`, `premature`, `doesn't transfer`, `doesn't apply`, `at our scale`,
`scale-amortized`, `scale-bound`, `team of one`, `overkill for`, `don't need`). Each row cites the
ground-truth pass3 quote (the dismissal) and the re-mine row that already corrected it where one exists;
where the re-mine had not yet been forced to confront the dismissal, the corrected verdict is supplied here.

**Verdict legend:**
- **OVERTURNED** — the cut rested on scale-bias the charter retires; the idea is now in-scope-now (or a NEW first-class candidate).
- **PROMOTED** — kept but throttled in size/priority by scale framing; charter raises it to a first-class pillar.
- **UPHELD (honest bad-fit)** — cut survives the charter because the failure mode is about irreversibility / threshold / install-state, NOT about being solo. Kept here for completeness so the attack is not credulous.

---

## The catalogue

| # | Source (re-mine + pass3) | Idea dismissed | Scale-reasoning quoted (the dismissal) | Corrected verdict under fleet-scale charter |
|---|---|---|---|---|
| 1 | `bug-to-pr-automation` (pass3 §c-3, §d) | **Autonomous bug→reviewed-PR trigger front-door** (label / Slack-Linear summon / CI self-heal) | "Buyer's-guide framing assumes a substrate we don't have… *our economics (solo + parallel-agent batches) are different and it never models them*"; YES to research only "*if V2 decides to build a trigger front-door*… minimum viable trigger surface for a **solo/duo repo**." | **OVERTURNED — headline deliverable.** Re-mine: "ELEVATE — maximally. In-scope-now and the headline deliverable… The reasoning that suppressed it was pure solo-conservatism." Cloud `/schedule` exists (durability MOOT); `disable-model-invocation` open-PR skill is the safe actuator. The front door is *exactly* what lets one engineer dispatch fleets across 5+ repos without being the per-repo dispatcher. |
| 2 | `12-factor-agents` (pass3 line 40) | **F11 "trigger from anywhere" (webhook/cron entry points)** | "Tractable only after the global-install gap is closed; research here should be *deferred* until V2 has a shared installable harness… **Premature now.**" | **OVERTURNED — the headline reversal.** Re-mine: "ELEVATE — this is the headline reversal." The deferral's premise (downstream of install-gap + machine-asleep) is MOOT: cloud `/schedule` already exists as a cron surface and the install gap is now an active plugin+marketplace workstream. From "premature, defer until 3 installs exist" to "the primary autonomy front door, built now." |
| 3 | `stripe-minions-kaliski` (pass3 §85–93) | **Low-friction multi-surface trigger (Slack-emoji / activation-energy lens)** | "Activation-energy / low-friction trigger **inverts at solo scale — a gap to *resist*, not build**… with one human review gate, driving activation toward a Slack-emoji trigger increases queue pressure on the exact bottleneck we can't scale… The harness is a **single-project, single-human** artifact." | **OVERTURNED.** Re-mine: "the pass3 dismissal is the textbook instance of the 'doesn't apply to solo' scale-bias… Under that scale the Slack/automated-system trigger" is the only ergonomic way to dispatch dozens of concurrent sessions. The "one reviewer is the bottleneck" premise is the very thing the fleet dissolves (see #14 auto-approve). |
| 4 | `ramp-inspect-agent` (pass3 §27, §38, §43) | **Multi-interface summon / AFK trigger ("computer-use yourself" → real-interface)** | Treated multi-interface accessibility as an "org-adoption nicety"; "computer-use-yourself (**anti-applicable pre-MVP**)"; "session velocity (page self-deferred, **no solo infra layer**)." | **OVERTURNED.** Re-mine: "ELEVATE — this is exactly the deferral the new charter reverses… The old 'solo dev doesn't need it' dismissal fails twice." Ramp's 30% organic-adoption number came *without mandate* because the summon was cheap from anywhere — the cleanest world-class evidence the front door pays off. |
| 5 | `code-review-latentspace` (pass3 §c) | **Deterministic risk-based auto-approval (Ona L4) — take most PRs out of the human path** | The whole pass assumed the human as mandatory final gate; the auto-approve mechanism "was left on the floor as mere commentary." Solo framing: ration the human's time ("5 PRs <400 lines in a 2h window"). | **OVERTURNED — pick up first.** Re-mine: "ELEVATE (toward NEW)… the human-review-capacity model is *the* bottleneck the whole vision is trying to dissolve… capping output to '5 PRs a human can read' is precisely the conservative solo-dev framing the new charter retires." Independent (non-vendor) 74% lead-time proof. Deterministic → safe under `disable-model-invocation`. |
| 6 | `coderabbit` (pass3 §26, §33) | **Slack review-ops agent (stale-PR nudges, weekly ship briefs, incident triage)** | Filed under "review routing → **does NOT transfer (solo dev routes to Tanner anyway)**"; "Solo-scale verdicts are unearned… at solo scale the tool competes for the *same* attention it claims to save." | **OVERTURNED — NEW candidate.** Re-mine: "Under the fleet charter that dismissal fails: a fleet across 5+ repos *needs* stale-PR nudges and ship briefs surfaced to Slack precisely because no human is watching 5 repos' PR queues." |
| 7 | `coderabbit` (pass3 §26) | **GitHub-as-canonical review verdict (vs. gitignored local `.cr-ok` sentinel)** | "No cross-repo / multi-project review reality… the harness has never been installed anywhere but event-vendor"; cross-repo reasoning "doesn't transfer yet." | **OVERTURNED.** Re-mine: "ELEVATE — the single most important move on the page… an autonomous agent summoned from Slack/cloud *cannot read a gitignored local sentinel*. The review verdict MUST be reconstructable from GitHub." Bridge from "solo laptop reviewer" to "fleet-grade gate." |
| 8 | `basis-canon-not-canon` (pass3 §112, §129) | **Self-improving context loop — scheduled scanner → auto-PR-opening repair worker** | "Keep maintenance *detection* automated; keep *repair* human-gated"; "importing Basis's 'daily workers auto-implement scanner findings' would be **actively dangerous here**… not something to import wholesale **at solo scale**." | **OVERTURNED — flagship autonomy loop.** Re-mine: "ELEVATE. The 'solo scale' reasoning is exactly the suppressed SCALE BIAS: fleets across 5+ repos rot *faster*, not slower… 'repair is dangerous' was written under the OLD charter where the machine slept." The worker opens a *PR* gated by `/cr` + human merge; only honest residual = scope it away from guard files. |
| 9 | `basis-monorepo-deep` (pass3 §56–57, §96, §112) | **Daily-scanner / daily-worker context-maintenance tier** | "The *daily-worker* tier is **scale-amortized and not yet justified for a single-project harness**"; "Amortization masquerading as principle… the daily-scanner/daily-worker economy"; "**premature** per the build-what's-needed-now rule." | **OVERTURNED, hard.** Re-mine: "ELEVATE, hard. This is the single most suppressed move in the file… 'scale-amortized / not justified for a single-project solo harness' — struck." Cloud `/schedule` is *exactly* the daily-scanner shape; "the conservative synthesis literally could not have built this when it ran; now it can." |
| 10 | `anthropic-contains-claude` (pass3 §7, §52, §94–98) | **Egress / operation-enforcement plane (deny-by-default unattended profile, per-task manifest)** | "Localized the **real solo threat** to fetched external content…"; the enforcement plane was framed as "a single optional hook to maybe add, not a first-class pillar." | **PROMOTED — first-class pillar.** Re-mine: "ELEVATE. The single most important move in the entire corpus for autonomy… the conservative bias is the scale dismissal: at solo-interactive scale a human watches each tool call." Cloud `/schedule` with connector creds = "a model holding credentials with nobody watching egress." Pillar, not patch — bigger by an order of magnitude. |
| 11 | `claude-dev-containers` (pass3 §18–19) | **OS-layer egress firewall (two-tier: allowlist artifact + bash-guard + container firewall)** | "The container, the volumes, the DinD analysis, and the firewall-in-a-container are all correctly **rejected** against the map"; verdict rested on "the threat model has not materialized in the 4-task and early 10-task batch runs." | **OVERTURNED — precondition for autonomy.** Re-mine: "ELEVATE. The 'reject the container firewall' reasoning was pure solo-scale bias: at fleet scale the firewall is the difference between 'one repo compromised' and 'all five.'" "Hasn't materialized" is the wrong test for a *safety* constraint (§9 Golden Rule satisfied). |
| 12 | `claude-dev-containers` (pass3 §34) | **Per-agent process/network isolation (cross-agent credential-read prevention)** | "§F kill-list flagged the 'dev-container/VM/microVM/gVisor sandbox stack' as **wrong threat model at solo scale**… 'Today's blocker is task dependency management and throughput, not blast radius.'" | **OVERTURNED (principle) / UPHELD (local-DinD vehicle).** Re-mine: "ELEVATE the *principle*… The §F rejection ('wrong threat model at solo scale') is struck verbatim." At 23 agents + parallel `/queue` + scheduled routines, "one agent reads all the others' secrets" is real lateral movement. Realize via cloud sandbox + managed-settings floor, not hand-rolled local DinD. |
| 13 | `claude-dev-containers` (pass3 §27) | **Managed-settings (model-unreachable deterministic floor) — agent can't edit its own deny rules** | Treated "agent-editable policy" as low-probability ("in principle") because "no agent had yet edited its own deny rules in the small batch runs." | **OVERTURNED — in-scope-now.** Re-mine: "ELEVATE… Under first-class autonomy that probability is no longer hypothetical — it is the *defining* attack on a self-improving loop (an agent that can edit its own constraints is an agent with no constraints)." For the cloud tier the file is baked into the image — uncertainty disappears. |
| 14 | `shopify-ai-first` (pass3 §88, §100–103) | **Review-throughput as a named pillar / handoff artifact / review-queue depth signal** | "For a **solo operator this is naming, not mechanism**"; "Demo velocity… resists gaming *because there is an audience*. **Solo, there is no audience**… a solo 'demo velocity' metric prevents no failure mode. Reject as instrumentation." | **OVERTURNED — and the §9 objection flips.** Re-mine: "ELEVATE… the purest instance of the scale bias the new charter retires. At fleet scale the failure mode is concrete: *N agents generate PRs faster than one human can review*… That passes the §9 golden rule." Every autonomy feature scored on review-throughput effect. |
| 15 | `shopify-ai-first` (pass3 §30) | **AI-traffic gateway/proxy (cost telemetry, model-swap, experimentation visibility)** | "Tool-agnostic stance ≈ the proxy's transferable nugget… **No proxy to build**"; cost-control + experimentation-visibility are "**scale-bound / rhetorical** for a solo team." | **PROMOTED (partial).** Re-mine: "that analysis assumed a solo dev." At fleet scale, per-repo/per-agent cost telemetry and an organic-traction signal across 5+ repos are real fleet-ops needs (a `>$250/day` curiosity alert is meaningful when N agents run unattended). Model-swap nugget already survives; the telemetry half un-suppresses. |
| 16 | `agent-sandboxing-10co` (pass3 §137) | **Egress allowlist for unattended local runs** | "The article itself rates the **solo-dev mechanism 'maintenance difficult**,'… the threat is second-order to the credential gap." Pass2 ranked Tier-1; pass3 demoted on solo-economics. | **OVERTURNED.** Re-mine: "ELEVATE. The clearest case of the SCALE BIAS… (1) 'maintenance difficult for a solo dev' — struck (fleets make a one-time allowlist *more* valuable, amortized across every repo via the plugin/marketplace); (2) cloud `/schedule` already has restricted network — the gap is the **local** `/queue` path." |
| 17 | `vercel-agentic-infra` (re-mine §39) | **Skill-provenance trust governance (pinned + reviewed-on-update floating upstream skills)** | Conservative read scoped the threat at *solo interactive* scale → "one-pass lookup if greenlit." (Pass2: "wrong threat model at solo scale.") | **PROMOTED — first-class control.** Re-mine: "ELEVATE… a floating, unreviewed upstream skill that steers judgment is now a supply-chain vector into *every repo the fleet touches, executing autonomously*… from 'one-pass lookup' to a **first-class trust-governance control** on the distribution boundary." |
| 18 | `harness-engineering-survey` (re-mine §27) | **Sensor ledger + threshold alerts (quality dashboard feeding the ratchet)** | "Eval framework = heavy" — the "scaled-to-solo bias." | **OVERTURNED.** Re-mine: "ELEVATE. Sensors are *the* prerequisite for autonomy… At fleet scale the human cannot eyeball quality on every run; sensors are the only way drift becomes visible before it ships. A self-improving loop with no sensors is a thermostat with no thermometer." |
| 19 | `ashby` (pass3 §67) | **Retrieval substrate over harness history (index PITFALLS + solutions + post-mortems + git log)** | "REJECTED-as-over-engineering… The article's Pass 3 correctly flags this as **over-engineering at solo scale**… we shouldn't *build* the SQLite DB at solo scale." | **PROMOTED (right-sized, not rejected).** Re-mine reframes to "*not* a SQLite mirror of hundreds of engineers' PRs; it is index PITFALLS.md + docs/solutions + post-mortems + git history into something an agent retrieves at triage time." At fleet scale a retrieval layer over accumulated cross-repo history is real leverage — the *capability* survives even though the *Ashby-sized DB* does not. |
| 20 | `every-compound-lfg` (re-mine §27, §70) | **`/lfg` orchestrator + brainstorm/plan seam + seven-failure-mode guard battery** | The synthesis "lost this entirely by deferring the loop it lives inside" — treated `/lfg` as "a direction we already aim at" and generated zero build move. | **OVERTURNED — NEW; build first.** Re-mine: "NEW… the cheapest insurance against the most expensive autonomous failure (a confidently-wrong plan executed overnight)." We have every *cell* (`/dev`, `/feature`, `/cr`, `/compound`) but no committed command closing them into a deterministic sequence ending in an opened PR. |
| 21 | `osmani-agent-skills` (pass3 §12, §150–153) | **Cross-harness skill router / portability (Cursor / Gemini / Copilot)** | "The router rejection **assumes permanent single-project Claude-Code scope** — V2's stated goal contradicts it." Verdict "sound *for today's shape*." | **PROMOTED (scope-dependent, not settled).** Pass3 itself flags the dismissal as scope-dependent. Once the harness ships as a plugin across 5+ repos, cross-harness portability "becomes live." Mark not-settled rather than rejected. |
| 22 | `ai-automation-ecosystem` (re-mine §19) | **Per-skill upstream-dependency disposition policy (which skills travel / vendor-freeze / track upstream)** | Disposition "throttled in *size*" — treated as "a one-line gap" for "a single-project artifact where the coupling only bites once." | **PROMOTED — first-class V2 item.** Re-mine: "ELEVATE… roughly 5–10x bigger… at fleet scale across 5+ repos, an un-priced upstream dependency drifts every repo independently." A policy doc + a per-skill disposition column in the skill registry. |
| 23 | `ai-pilling-team-of-one` (re-mine §5; pass3 §78) | **Cultural + Operational org-readiness pillars (discarded; only Technical kept)** | "Discard the Cultural and Operational pillars as **large-org change management you don't need yet**." Pass3: "'Team of one' = 'one human' is the **wrong unit**." | **PARTIALLY OVERTURNED.** Pass3 already catches that "team of one" mis-frames the unit — the harness *orchestrates an agent fleet*, so the "Operational readiness" pillar (process/guardrails for many concurrent actors) is live, not org-change-management. Cultural pillar genuinely thins at solo; Operational pillar un-suppresses. |
| 24 | `37signals-dhh` (pass3 §77) | **CLI-first for recurring admin ops** | "Prices CLIs at zero **for a solo dev**… ignores that a CLI is a second tested/versioned/documented interface… our 'third occurrence' rule cuts against reflexive CLI-building." | **UPHELD (honest bad-fit, scale-independent).** The cut survives: the cost (a second tested interface) is real at any scale and the "third occurrence" rule is a threshold argument, not a solo argument. Flagged here only to keep the attack honest. |

---

## Honest residuals (cuts the charter does NOT overturn)

The attack would be credulous if it elevated everything. These cuts are about **irreversibility,
threshold, or install-state — not scale-skepticism** — and they hold at fleet scale:

- **Ramp browser-driving-for-mutations** (`ramp-inspect-agent` re-mine §20): UPHELD-CUT. Failure mode is
  irreversibility (a browser-driving agent fat-fingering a stateful mutation), which collides with the
  PocketOS destructive-op rules and would be a bad fit at fleet scale *too*. The *screenshot guardrail*
  half is ELEVATED; only the mutation-driving mechanism is cut.
- **Collapse 23 agents → 1** (`ramp-inspect-agent` re-mine §41): UPHELD-CUT. "23 ≪ hundreds, so the
  maintenance-tax that justified Ramp's consolidation does not exist for us." Threshold argument, holds
  at any scale. (The §9 model-capacity re-audit it implies *is* elevated.)
- **Unified custom MCP server** (`basis-monorepo-deep` re-mine §43): UPHELD-CUT. Cloud `/schedule` runs
  with restricted network and no local MCP servers — a self-hosted unified server is unreachable from the
  autonomy substrate. The *capability* (one debugging trajectory across issues+logs+DB) is satisfiable via
  claude.ai connectors, so wire, don't build.
- **Standalone "paying-stranger" validation channel** (`recursive-self-improvement` re-mine §39):
  UPHELD-CUT. There is genuinely no paying stranger yet (single vendor) — an empty channel reports green
  because nothing flows. The *adversarial golden-set seeding* requirement is elevated instead.
- **CI-latency optimization** (`notion-spec-driven` re-mine §31): UPHELD-CUT, justified by *install-state*
  not scale — "there is no fleet whose throughput CI currently caps." Sharpened flip trigger: in-scope the
  moment `/queue` regularly runs ≥3 parallel worktrees blocking the same pipeline.
- **Feature-area-scoped AGENTS.md** (`harness-io` pass3 §21): UPHELD with reason — splitting buys
  unverified discovery-locality at the cost of more files to keep non-stale, against our worst problem
  (staleness/duplication, canon §4). Threshold/maintenance argument, not pure scale-bias.
- **CLI-first reflex** (#24 above).

---

## TOP 5 ideas the scale-bias most wrongly suppressed (ranked by world-class value)

1. **The autonomous bug→reviewed-PR trigger front door** (#1/#2/#3/#4 — `bug-to-pr-automation`,
   `12-factor-agents`, `stripe-minions-kaliski`, `ramp-inspect-agent`). This is the north star itself.
   It was deferred under *four separate* scale dismissals ("premature," "inverts at solo scale," "solo
   dev doesn't need a Slack summon," "our economics differ") — every one resting on the now-MOOT
   machine-asleep premise. Cloud `/schedule` exists; `disable-model-invocation` makes the open-PR
   actuator safe. This is the literal difference between "we think about autonomy" and "we have it,"
   and it is the only thing that lets one engineer run fleets across 5+ repos without being the
   per-repo dispatcher.

2. **The egress / operation-enforcement plane + OS-layer firewall** (#10/#11/#16 —
   `anthropic-contains-claude`, `claude-dev-containers`, `agent-sandboxing-10co`). The deterministic
   control that still protects you *after* a prompt injection has compromised the agent's judgment.
   Dismissed as "solo threat is theoretical / hasn't materialized in 4-task runs" — but cloud
   `/schedule` with connector creds is precisely "a model holding credentials with nobody watching
   egress," and at fleet scale the firewall is the difference between "one repo compromised" and "all
   five." It is a *precondition for switching autonomy on at all*, not follow-on hardening — and the
   §9 Golden Rule (nameable failure mode = not overhead) is satisfied.

3. **The self-improving context-maintenance loop (scheduled scanner → auto-PR repair worker)** (#8/#9/#18
   — `basis-canon-not-canon`, `basis-monorepo-deep`, `harness-engineering-survey`). The single most
   suppressed move in its file, cut on "scale-amortized / not justified for a single-project harness"
   and "actively dangerous at solo scale." Both premises are dead: fleets across 5+ repos rot *faster*,
   and the repair worker opens a `/cr`-gated, human-merged PR — the same trust boundary every other
   agent change passes. Paired with the sensor ledger (#18), this is the self-improving loop the charter
   names as a first-class pillar, buildable *now* on the scheduler that already exists.

4. **Deterministic risk-based auto-approval (Ona L4) + review-throughput as a named pillar** (#5/#14 —
   `code-review-latentspace`, `shopify-ai-first`). The conservative synthesis kept the human as the
   mandatory final gate on *every* source and then rationed the human's time ("5 PRs in a 2h window") —
   the exact solo-dev bottleneck framing the charter exists to dissolve. Deterministic classification
   (paths + diff-size + test-delta + scope) auto-approves LOW, routes MEDIUM to `/cr`, forces human
   sign-off on HIGH. It is safe under `disable-model-invocation` (no model judgment in the merge
   decision), backed by an *independent* 74% lead-time number, and it is the load-bearing mechanism
   without which the human is the throughput ceiling no amount of parallel agents can lift.

5. **The `/lfg` orchestrator + brainstorm/plan seam + seven-failure-mode guard battery** (#20 —
   `every-compound-lfg`). The synthesis lost this *entirely* by deferring the loop it lives inside,
   generating zero build move for a source that is the existence proof a small team ran the loop in
   production and published its exact seven failure modes. We already own every cell (`/dev`,
   `/feature`, `/cr`, `/compound`, UNATTENDED mode) but have no committed command closing them into a
   deterministic sequence ending in an opened PR — the gap between thinking about autonomy and having
   it, shipped with its failure modes wired in as deterministic guards from day one.
