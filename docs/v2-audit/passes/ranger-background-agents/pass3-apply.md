# Pass 3 — Apply: Ranger against OUR V2 harness (honest, including "are we over-engineering?")

Building on Pass 2. This lands the article on our V2 design. The article's whole title is an accusation —
"you're overthinking" — so this pass takes the over-engineering charge seriously and answers it honestly, rather
than defensively. Every claim cites our design (VISION move IDs / `CANONICAL-HARNESS-AS-IS.md` §N) or the article.

## (a) What it CONFIRMS we're doing right
- **Isolation-per-job.** Ranger gives each PR its own box; we give each job its own worktree + isolated env
  `[VISION F2; map §3e worktree-create.sh]`. Same instinct: never let two jobs (or a job and prod) share state.
- **Slack as a first-class front door.** Ranger's *primary* trigger is a Slack mention — exactly Tanner's note #1
  ("kick off via Slack or Linear"). This is independent confirmation that the chat-summon is the real ergonomic
  entry point, not a nice-to-have `[VISION L1]`.
- **Reuse existing infra; don't build a cluster.** Ranger explicitly skips Kubernetes, Terraform, custom queues,
  dashboards, hot pools. We already chose the *built-in* `/schedule` routines + worktrees over any custom
  orchestration `[VISION L4, P4; /goal is built-in]` — so on the *infrastructure* axis we are already aligned with
  the article, not guilty of its charge.
- **Human-visible visual review.** Ranger runs a browser feature-review and posts **screenshots to Slack so a
  non-technical PM can verify.** That is simultaneously our `/verify` render gate `[VISION C8]` AND our
  narration/observability channel `[VISION L7]` — the article is direct evidence that "show the human a picture,
  in the channel they already use" is the right shape.
- **Build-don't-buy, vendor-independent.** Ranger's "we're not locked into any agent vendor" + "the preview work
  pays double (humans get app previews too)" maps onto our plugin/Claude-Code direction and our charter.

## (b) Where the article says we're OVER-complicating — and the honest reckoning
Ranger runs *production* background agents on **~100 lines of safety** (an app-layer `SANDBOX_ENV` outbox + a
throwaway per-PR DB branch + no external IP). Our floor is heavier: an OS egress allowlist, an MCP lethal-trifecta
gate, managed-settings, a credential pre-flight, branch guards `[VISION F1–F9]`. Taken at face value, the article
says our floor is over-built. **Here is the honest reconciliation — it is real, and it is a simplification we
should adopt:**

> **The difference is the ENVIRONMENT, not the rules.** Ranger's agent has *no production blast radius* — its DB is
> a disposable branch with no real data, and there is no external IP. OUR threat model is heavier almost entirely
> because `.env.local` points at **production** Supabase `[map §3e; VISION F2/F5]`. So most of our floor is
> defending a blast radius **we chose to leave in the box.**

The sharp, transferable lesson: **the single highest-leverage safety move is isolation-by-construction — give the
agent a genuinely disposable environment (a throwaway DB branch / no prod credentials / no external IP), the way
Ranger does — and then much of our elaborate floor becomes belt-and-suspenders rather than load-bearing.** This is
a legitimate "are we over-engineering the floor?" finding to put to Tanner: if the agent literally cannot reach
prod, the egress firewall (F3), the trifecta gate (F5), and the credential pre-flight (F2) are defending against a
danger we could largely *remove* instead of *guard*.

## (c) The concrete cheap thing we should STEAL — the SANDBOX_ENV outbox
This is a beautiful ~100-line primitive we don't have, and it is a perfect fit:

- **In unattended mode, intercept every real external side-effect** (Slack post, email, deploy, external-API write,
  even a PR comment) and **write it to an outbox a human reviews**, instead of performing it. The agent *proposes*
  side-effects; a human *commits* them.
- This **complements** `disable-model-invocation` (F9): that *removes* a side-effect skill from the model's reach;
  the outbox catches anything that still tries to fire and makes it *captured, not performed.* Two layers, both
  cheap.
- The **positive version of our credential firewall.** Today F2 *refuses* a run if prod keys are present. Ranger's
  better move is to *provide a safe DB* (a disposable branch) so the run can proceed harmlessly. Supabase has
  branching too — so "give the agent a throwaway DB branch" is buildable for us, and is strictly better than
  "refuse." **New design item: a per-job disposable DB branch + a `SANDBOX_ENV` outbox for side-effects.**

## (d) Where we LEGITIMATELY go heavier — and must NOT simplify away
The article is **silent on the trust-the-output problem**, which is the half our charter exists to solve. Ranger
ends *every* run with a human reviewing a screenshot and an engineer reading the code (Pass 2). Our charter wants
to scale *past* "a human reviews every single one" — autonomy at fleet scale, eventual low-risk auto-merge, a
$30k-client product where a wrong total is a disaster. That demands exactly the depth the article punts on:

- the calibrated, independent, adversarial review with a measured catch-rate `[VISION C2/C4/C5]`;
- the un-forgeable CI gate `[VISION F6]`;
- **test verification** (mutation testing, the spec-as-oracle, "would this test catch a real bug?") `[VISION C6/C11
  + the new test-quality lens]` — because Ranger's "a PM looks at a screenshot" does not catch a green-but-vacuous
  test.

So the two works are **complementary, not contradictory.** Ranger owns "cheap, isolated runtime + chat trigger +
human-visible review"; we add "trustworthy-enough to safely *reduce* the per-PR human." A world-class harness needs
both halves.

## (e) Honest verdict + what changes
The article does **not** show our whole design is over-engineered. It makes two true points and is silent on a
third:
1. **The infrastructure should be simple** — agreed, and we already use built-in primitives, not a cluster. (No
   change; this validates our direction.)
2. **Environment isolation is the cheapest safety lever** — *a real simplification we should adopt.* **ACTION:**
   add a per-job disposable DB branch + the `SANDBOX_ENV` outbox pattern; then **re-examine whether F2/F3/F5 can be
   demoted** once the agent has no prod blast radius (a genuine new fork for Tanner — call it "isolation-first
   floor: do we remove the blast radius instead of guarding it?").
3. **It is silent on trustworthy review at scale** — the half we went deep on. **KEEP** that depth; the article is
   not evidence against it.

**Does it warrant fresh external research? Mostly no** — it is one team's build recipe, not a study; the
transferable ideas (isolation-by-construction, the outbox, the chat trigger, human-visible screenshots) are fully
extracted here. **One bounded check worth doing:** confirm Supabase branching gives a fast-enough disposable
per-job DB (Ranger uses Neon; we're on Supabase) before committing to the isolation-first simplification.

### One-line takeaway for the build plan
**Adopt isolation-by-construction (disposable DB branch + a side-effect outbox) as the cheapest safety lever — and
let it *demote* part of the floor — while keeping our review/test-verification depth, which is the half Ranger's
"a human looks at every one" model never had to solve.**
