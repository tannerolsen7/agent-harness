# Pass 3 — Apply vs Ground-Truth

**Building on pass2:** Pass 2's central move was to re-weight the article away from its own "10
companies" framing to the two relevant data points (Anthropic red-team + Ramp), to name five hidden
assumptions (B1: "scoped Supabase key" is a roles-engineering project, not a checkbox; B2: the
migration task is structurally separable from prod-write; B3: PR-as-gate is mis-ranked as a
blast-radius control when it sits *downstream* of the exfiltration it's credited with stopping; B4:
config deny-listing is already past-tense on disk; B5: the 12 items are one load-bearing control plus
eleven hedges), and to re-tier the action list by *this system's* threat model. This pass maps that
analysis onto **CANONICAL-HARNESS-AS-IS.md** (the ground-truth), distinguishing what we already do,
the real gaps, the article's weaknesses, and whether fresh research is warranted.

Ground-truth citations use the map's own scheme: `[disk §Y]`, `[canon §X]`, `[absent]`, and the map's
section numbers (§3e hooks, §5 canon-only build list, §6 disk-only list, §9 model-capacity audit).

---

## (a) What we ALREADY do — and the article under-credits

1. **PR-as-gate is real and live.** The article marks it "Adopted" and the ground-truth confirms the
   mechanism: `/queue` agents write to worktrees and open PRs via `scripts/pr.sh`, which consumes the
   `.cr-ok` sentinel [ground-truth §3f lists `pr.sh` and the `.cr-ok` chain; §3e pre-push]. So the
   article's single green row is genuinely backed by disk. **But Pass 2-C2/B3 stands:** the map also
   records that the `.cr-ok` chain is *gitignored and never reaches CI* (the "Node 8.5(c) gap",
   `[disk §3f]`), so the gate is advisory at the CI layer — reinforcing that PR-as-gate is a quality
   gate, not a blast-radius control for pre-PR exfiltration.

2. **The prod-key firewall the article asks for in #1/#3/#7 is already partially built — by a better
   mechanism than the article proposes.** Ground-truth §3e lists `worktree-create.sh (WorktreeCreate)`
   as **disk-only**, explicitly "(prod-key firewall); a genuine disk advance over canon," and §6
   lists "`worktree-create.sh` + prod-key firewall (`gen-local-env.sh`, `test-local.sh`) — a genuine
   disk *advance* (Tier-0 credential isolation) canon lacks." This is exactly Pass 2-D Tier-0. The
   article's #1 ("separate Supabase key") and #7 ("read-only URL override") are aimed at a credential
   tier Supabase doesn't natively expose (Pass 2-B1); the disk instead **isolates which stack the
   worktree env can see** — the architecturally correct version of the article's instinct. The article
   is **behind disk** here.

3. **Config-file deny-listing (#5) is already doctrine.** Memory `feedback_no_agent_edits_guard_files.md`
   ("Never edit settings.json/settings.local.json/.claude/hooks/**") plus the current branch's commits
   #99/#100 ("harden guard hooks + autoMode settings + UNATTENDED worktree mode"; "Tier-0 credential
   isolation for unattended agent runs") are the recent history. Ground-truth §3e records two live bash
   guards (`block-dangerous-git.sh`, `block-npm-install.sh`). The article's #5 is real but **net-behind
   the disk's trajectory.**

4. **The worktree/parallelism model the article worries about in #4 / Open-Q #3 is a known, documented
   condition.** Memory `vitest reads .env.local which is prod` and `Local stack per worktree` already
   record that worktrees symlink `.env.local` to prod and that only one local stack runs at a time —
   the exact shared-mutable-credential-state risk the article raises. The article surfaces a real
   concern but it is **already in the project's own hazard log**, not a discovery.

## (b) REAL gaps — each cited to a ground-truth section or a confirmed absence

1. **No safety-floor bash guard against destructive SQL / deploys — the article's #12 lands on a
   confirmed absence.** Ground-truth §3e: `block-dangerous-bash.sh` is "**Canon's 3rd guard — ABSENT
   on disk. Disk has no safety-floor bash guard**" `[canon §08, absent on disk]`, and §5 lists it as a
   canon-only build item. The article's Action #12 ("no destructive SQL pre-commit hook scanning
   migrations for `DROP TABLE`/`TRUNCATE`/`DELETE`-without-`WHERE`") is a **concrete, validated
   instantiation of a gap the ground-truth already flags as a canon-mandated, disk-absent structural
   guard.** This is the article's strongest contribution: it converts an abstract "3rd guard absent"
   row into a specific failure mode (the Replit July-2025 incident) and a specific scan. **Build-worthy,
   cites `[ground-truth §3e + §5]`.** Note: the existing CLAUDE.md "destructive operations must have a
   rollback path" rule is *advisory text*, not an enforced hook — so this is a genuine gap, not a dup.

2. **Egress filtering is a confirmed absence at every layer.** Ground-truth lists no egress/network
   control in any hook (§3e), script (§3f), or canon-only item (§5) — `[absent]` across the board.
   Per Pass 2-C1/D-Tier-1, egress is the *only* control for the supply-chain attack class that
   credential topology cannot touch. The article's #9 (Privoxy/`pfctl` allowlist) maps to a clean
   absence. **Real gap; but see (c) — the article's own confidence in it is low ("maintenance
   difficult"), so this is a research-warranted gap, not a build-now gap.**

3. **No per-task wall-clock timeout / runaway control for `/queue`.** Nothing in ground-truth §3e–§3f
   describes a Stop-on-timeout mechanism; the closest declared item is canon's `session-end.sh` (Stop
   hook) which is **absent on disk** (§3e, §5) and does memory-capture, not timeout enforcement. The
   article's #8 (45-min SIGTERM-and-commit) addresses Open-Q #5's "10 silent PRs" throughput problem.
   **Real gap `[absent]`, but Pass 2-D tiers it as operational/observability, not security.**

4. **The migration credential is an unresolved architectural question the ground-truth does not
   answer.** CLAUDE.md (Testing) documents `test:local` against a local stack, and memory documents
   "local stack per worktree," but ground-truth has **no row** for how an overnight agent applies or
   verifies a migration without a prod-write credential. The article's Design Challenge + Open-Q #2
   name exactly this hole. Per Pass 2-B2 the answer is "agent verifies against local stack; human
   applies to prod" — but that policy is **not encoded anywhere in the ground-truth** (no hook blocks
   `supabase db push` from an agent worktree). **Real gap: a policy/enforcement absence `[absent]`,
   adjacent to gap (b)(1).**

## (c) The article's own weaknesses

1. **Ten companies, two relevant (Pass 2-A).** Eight of the ten solve "isolate untrusted user code on
   our platform"; only Anthropic's red-team and Ramp match this system's "trusted model, own machine,
   own repo, prompt-injection" threat model. The microVM/container schism — the most prose-heavy
   section — is the **least** applicable finding and should be discounted in V2 weighting.

2. **"Scoped Supabase key" is priced as a 2h checkbox; it is a custom-Postgres-role project
   (Pass 2-B1).** Supabase has no native tier between RLS-bound-anon and RLS-bypassing-service-role.
   The article's #1 and #7 are under-specified and under-estimated. The disk's worktree prod-key
   firewall is the correct architecture; the article never finds it because it audits the canon's
   threat language, not this repo's actual `worktree-create.sh`.

3. **PR-as-gate is over-ranked (Pass 2-B3/C2).** Billed "the single most important blast-radius
   control," it sits *downstream* of the 24/25 pre-PR exfiltration it's credited with preventing, and
   the article's own Open-Qs #2/#5 undercut it. It is a code-quality gate mislabeled as a security
   boundary.

4. **The 12-item list masquerades as defense-in-depth but is one load-bearing control plus eleven
   hedges (Pass 2-B5).** It never states the binary truth: creds-not-in-the-box defeats the dominant
   failure mode; nearly everything else is redundant-with or downstream-of that one control. A reader
   could spend 20+ hours on items 3–12 and not move the dominant-risk needle if #1 is done right.

5. **Internal egress contradiction (Pass 2-C1):** §2 says credential topology is *the* control; §5
   admits it does nothing against prompt-injection supply-chain attacks — for which egress (demoted to
   "follow-on") is the only listed defense. The ranking and the analysis disagree.

6. **Stale/unstated dependency on disk state.** The Application table marks several items "Open
   question" that the disk has already moved on (config deny-list, worktree prod-key firewall). The
   article's snapshot is ~2026-06-04; commits #99/#100 (Tier-0 isolation, autoMode/UNATTENDED) landed
   on the current branch. The article audits the *threat literature*, not the *current disk* — so it
   under-credits work already shipped.

## (d) Is fresh research warranted? (prefer synthesize)

**Mostly no — synthesize.** The article + ground-truth + memory already contain enough to act:

- **Gap (b)(1) destructive-SQL guard** — *synthesize, no research.* Ground-truth §5 already authorizes
  `block-dangerous-bash.sh` as a canon-mandated build item; the article supplies the concrete scan
  patterns and the Replit failure mode. This is a build decision, not an open question. The only
  synthesis needed is to scope it as part of the absent 3rd bash guard rather than a standalone hook
  (avoids the §6 "phantom proliferation" pattern).

- **Gap (b)(4) + Design Challenge migration credential** — *synthesize, no external research.* The
  answer is already latent in CLAUDE.md (`test:local` / local stack) + memory (`Local stack per
  worktree`) + Pass 2-B2: agent verifies migrations against a throwaway local stack; a human applies
  to prod; a guard blocks `supabase db push` from an agent worktree. This needs a **decision and an
  ADR**, not new sources. (Touches Supabase → per CLAUDE.md, invoke `/supabase` before writing the
  guard or any migration-path change.)

- **Gap (b)(2) egress filtering** — *narrow research warranted, but low priority.* The article itself
  rates the solo-dev mechanism "maintenance difficult," and the threat it addresses (supply-chain via
  prompt injection) is second-order to the credential gap. One bounded question — *does Claude Code's
  current sandbox/Seatbelt integration on macOS expose a usable egress-allowlist, making Privoxy/`pfctl`
  unnecessary?* — is worth a single targeted check before committing 3h to a proxy. This is the only
  genuinely under-determined factual question; everything else synthesizes.

- **The microVM/OrbStack axis (article #6, #11)** — *no research; reject for this system.* Pass 2-A +
  (c)(1): wrong threat model. Document the rejection (ground-truth §9's golden rule: "if you can't name
  a failure mode the constraint prevents, the constraint is overhead" — OrbStack prevents
  container-escape, which caused **none** of the documented incidents) rather than research it further.

**Net for V2:** the article yields **two build-worthy, ground-truth-cited gaps** (destructive-SQL
guard as part of the absent 3rd bash guard §3e/§5; migration-credential policy + `supabase db push`
worktree block §absent) and **one bounded research question** (Claude Code native egress allowlist on
macOS). Its credential-topology thesis is correct but **already better-answered on disk** (worktree
prod-key firewall, §6) than by its own #1/#7 prescriptions. Everything else is either already-built,
mis-ranked, or a control for a threat model this single-developer-own-repo system does not have.
