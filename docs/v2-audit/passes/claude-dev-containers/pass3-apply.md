# Pass 3 — Apply (vs ground-truth `CANONICAL-HARNESS-AS-IS.md`)

Building on pass2: pass-2 §8 concluded that the container — the article's nominal subject — is the *least* actionable thing in it, and that the three valuable findings (host-level managed-settings, the shared-prod-credential symlink, the never-tested built-in-sandbox comparison) are all container-independent. This pass maps those against the ground-truth map row-by-row, separating what we already do, what is a real gap, where the article is weak, and whether fresh research is warranted.

Citation key: `[canon §X]` / `[disk §Y]` / `[absent]` per the ground-truth's governing rule — *no proposal survives without a citation to a row in this map.*

---

## (a) What we ALREADY do (the article's "transfer" rows that are non-gaps)

The article's transfer table and synthesis describe several controls as missing or partial that the ground-truth shows are **already built** — these must NOT be cited as gaps (the Phase-2 actionability rule: an insight is actionable only if it maps to a real §3–§9 gap, not a disk mechanism that already covers it).

1. **Non-root user + bypass already works** (article transfer row: "Fully — macOS user is not root; CLI bypass flag already works"). Confirmed non-gap. The disk already runs unattended via `UNATTENDED` worktree mode [disk: recent commits `130f4a2`, `65cfb38` "Tier-0 credential isolation for unattended agent runs"]. No row to build.

2. **Auth persistence across rebuilds** (article transfer row: "Fully — no rebuild problem on host macOS"). The article itself rates this as a non-issue outside containers. Confirmed non-gap by the article's own admission. The named-volume recipe solves a problem we do not have.

3. **A Tier-0 credential firewall already exists** — the article frames credential isolation as a container benefit, but ground-truth §6 (disk-only registry) records `worktree-create.sh` + the prod-key firewall (`gen-local-env.sh`, `test-local.sh`) as "a genuine disk *advance* (Tier-0 credential isolation) canon lacks." [disk §3e: `worktree-create.sh (WorktreeCreate)` — "Disk-only (prod-key firewall); a genuine disk advance over canon"]. The article did not know this existed; its "managed policy" enthusiasm partly re-derives a control we already ship.

4. **Tool-call-time policy enforcement exists** — the article models `.claude/settings.json` as "an unprotected file an agent could edit." Ground-truth §3e shows `block-dangerous-git.sh` + deny on `/.claude/hooks/**` already run as PreToolUse guards, and the harness's standing rule "No agent edits to guard files" (memory) makes guard-file edits a hard NEEDS-HUMAN handoff. So pass-2 §4's point holds: the *practiced* enforcement is stronger than the article models. Partial-non-gap.

5. **Tests-against-production-Supabase is already the default** — the article's "accept tests run against production" is not a new concession; ground-truth Testing section: "`.env.local` points at **production** Supabase. `npm run test` … therefore hit prod by default." The article's firewall design assumes a state we already live in. Non-gap (but see (b)2 — the symlink that *causes* this is itself the gap).

---

## (b) REAL gaps — each citing a ground-truth section or confirmed absence

These survive the map. Ordered by leverage (cheapest/highest-confidence first).

1. **The absent 3rd bash guard is the container-free answer to the article's threat-model-2.** The article's most vivid fear is overnight prompt-injection → `curl`-exfil of `~/.claude` to an external URL. Ground-truth §3e + §5 record `block-dangerous-bash.sh` as **canon-specified, ABSENT on disk** — "Canon's 3rd guard — ABSENT on disk. Disk has no safety-floor bash guard." Canon's spec already covers "deploys, `rm -rf`, boundary writes" and the natural place to add curl-to-non-allowlisted-host blocking. **This is the actionable insight the article points at without naming:** a deterministic PreToolUse guard that intercepts exfil at the tool-call layer gives a large fraction of the egress firewall's blast-radius value with zero DinD, zero `NET_ADMIN`, zero container. Cite: `[canon §08 / §5 build-or-reject row: block-dangerous-bash.sh]` + `[disk §3e absent]`.

2. **The shared-production-credential symlink partially defeats the disk's own Tier-0 firewall.** Pass-2 §6. The article surfaces it (transfer row: "all worktrees share the same *production* Supabase credentials — Does not transfer"); the ground-truth confirms the mechanism and its severity independently [memory: "vitest reads .env.local which is prod," "No .env credential reuse"; §6 Tier-0 firewall is the *intended* isolation that the shared symlink undercuts]. The gap: there is no row in the map for *per-worktree credential scoping at the `.env.local` layer* — the symlink re-shares one prod credential into every worktree, so a prompt-injected agent in worktree A reads worktree B's (identical, prod) credential trivially. This is a **confirmed-absence gap** [absent: per-worktree credential isolation; the firewall isolates *local*-stack creds, not the shared prod `.env.local`]. Cheapest defensible hardening in the article and it needs no container.

3. **Host-level `managed-settings.json` — the trust-boundary inversion without the container.** Pass-2 §5. Ground-truth §3a/§5 record the *global* `~/.claude/CLAUDE.md` as "canon-mandated, absent globally," and §3e's net-enforcement note: "neither has a deterministic backstop for the bulk of skill bodies, CLAUDE.md rules, or the autoMode lists." A root-owned host `managed-settings.json` (highest settings precedence, un-writable by the non-root agent user) would give the deterministic, agent-unreachable policy floor that BOTH canon and disk lack — the article's single most valuable mechanism, extracted from the container. Cite: `[absent: deterministic agent-unreachable policy floor; §3e net-enforcement gap]`. Confidence: directional — the host-OS precedence behavior of `managed-settings.json` outside a container needs a one-line doc confirmation before building (see (d)).

4. **Egress allowlist as a documented artifact even if the firewall isn't built.** The article's Design Challenge produces real value as *documentation*: the set of domains event-vendor's agents legitimately need (Anthropic inference, Supabase cloud, GitHub API, npm registry, Vercel) is the exact allowlist that a future `block-dangerous-bash.sh` curl-guard (gap 1) or any later sandbox would enforce. Ground-truth has no such inventory [absent: documented egress allowlist]. Low-cost, feeds gaps 1 and 3. This is "build the documentation now, defer the enforcement" — consistent with the canon's "note future extensions, don't implement prematurely" discipline.

Gaps explicitly NOT claimed (failed the map): the dev container itself, the named `~/.claude` volume, `${devcontainerId}` scoping, DinD resolution — all are solutions to container-only problems we do not have (see (a)1–2, and the article's own "Candidate, not Adopted").

---

## (c) The article's own weaknesses

1. **The verdict rests on "the threat hasn't materialized" — the wrong test for a safety constraint.** Pass-2 §2. The ground-truth §9 Golden Rule is "if you can't name a failure mode the constraint prevents, it's overhead" — and the article *names* the failure mode vividly. By the canon's own rule that makes the control warranted, not overhead. The article applies a quality-constraint test ("has it bitten us?") to a safety constraint — exactly the PocketOS error the ground-truth §9 flags ("treating a safety constraint like a quality constraint is the PocketOS incident").

2. **It praises the egress firewall as #1 then concedes it can't accommodate the required test path.** Pass-2 §3. The "accept `npm run test:local` is out of scope" footnote silently amputates a required pre-push gate [ground-truth Testing: `test:local` refuses to run unless URL is `127.0.0.1:*`]. The clean firewall only exists in a world where event-vendor's local-stack coverage is dropped.

3. **The entire recommendation rests on ONE unfetched comparison.** Pass-2 §7. The built-in Bash sandbox (Anthropic's own alternative, "Next steps," not fetched) is never weighed. If it provides egress control without DinD/`NET_ADMIN`, the "adopt the container to get the firewall" frame collapses. The article concedes this as Open Question #2 but lets it neither discipline the verdict nor lower the confidence rating on the firewall recommendation.

4. **It binds `managed-settings.json` to the container without asking if the host supports it.** Pass-2 §5. The single highest-leverage unasked question — host-level managed-settings — is absent because the whole frame is container-shaped.

5. **It never connects to the disk's existing Tier-0 firewall.** Understandable (no ground-truth access), but it means the article re-derives credential isolation as a container benefit while a real one ships on disk, and misses the sharper finding (the symlink defeats it — gap (b)2).

6. **Reasoning is correct but several load-bearing claims are self-rated Directional/inferred** (DinD requirement, credential contention, the whole macOS-Docker-Desktop UID-remapping question is an *open question*, not a finding). The mechanism facts are solid (Verified); the *application-to-event-vendor* layer is mostly inference. The article is honest about this, which is to its credit, but it means little of the applied section is load-bearing enough to build from directly.

---

## (d) Is fresh research warranted? (prefer synthesize)

**Mostly synthesize. One narrow, cheap doc-check is warranted; the rest is already answerable from the map + adjacent corpus.**

- **Synthesize, do not research:** The container adoption question is settled by the article's own verdict + ground-truth (a)1–2 — "Candidate, not Adopted, follow-on hardening." No new research moves this. The three real gaps (b)1, (b)2, (b)4 are fully specified by the map (`block-dangerous-bash.sh` absent; symlink credential-sharing confirmed; egress allowlist absent) and need design/build, not research. Cross-page synthesis is already available in-corpus: the article's own Stripe Minions, Ramp/Modal, and 12-Factor connections [pass-1 §7] are the relevant neighbors; the agent-harness research tree [memory: `reference_agent_harness_research_tree`] is the home for the "build the autonomous car, not the cage" doctrine this feeds.

- **One warranted check (cheap, bounded):** gap (b)3 hinges on whether `managed-settings.json` at `/etc/claude-code/` is honored by Claude Code running **natively on host macOS** (not just inside a container), and whether a non-root macOS user is reliably blocked from writing it. The article didn't test this; the ground-truth doesn't cover it. This is a one-shot read of the Claude Code "settings precedence" / managed-settings doc — NOT a fan-out research effort. If confirmed, (b)3 becomes the single highest-value, lowest-cost item the entire dev-containers article yields. Per the `claude-api`/settings trigger discipline, this is a doc-lookup, not a memory answer.

- **Defer (out of scope, already named):** macOS Docker Desktop UID-remapping behavior (article OQ#1), `${devcontainerId}` rebuild stability (OQ#3), Supabase-local-stack-without-host-socket (OQ#4) — all only matter *if* the container is adopted, which (a)1–2 says it is not. Researching them now would be speculative per "build what's needed now."

**Net for the V2 synthesis layer:** this article contributes exactly three citable rows — (1) build the absent `block-dangerous-bash.sh` 3rd guard with curl-to-non-allowlist blocking [canon §08, disk-absent §3e]; (2) scope `.env.local` per-worktree so the shared prod credential stops defeating the Tier-0 firewall [confirmed absence, §6]; (3) pending a one-line doc check, add a host-level agent-unreachable `managed-settings.json` policy floor [§3e net-enforcement gap]. The container, the volumes, the DinD analysis, and the firewall-in-a-container are all correctly *rejected* against the map.
