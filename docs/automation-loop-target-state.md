# World-class unattended loop — target state

> **What this is.** The finish line for a world-class unattended automation loop: assign a Linear issue → the harness builds it, tested and reviewed → a PR you merge. Use it as a scorecard — measure an actual wiring (per repo) against it and the gaps are the backlog.

> **The shape.** Unattended up to the merge, never past it. The agent does the work; the human does the merge.

## Non-negotiables

- The agent builds unattended; **a human always merges** — enforced structurally (the bot *cannot* merge), not by prompt.
- **Quality is the point, not speed.** Every change is clean, simple, reliable, with impeccable UX. Three surfaces held to the same bar: the code itself, the dev + agent experience, and the end-user experience.
- **You never lose comprehension** — at any moment you can see what the agent did and why, from the issue.
- **Nothing fails silently.** Every end-state is visible.
- **The tracker is the single source of truth** for state.

## 1. Intake / front door

- [ ] Work starts by assigning a tracker issue to the agent — no manual session needed.
- [ ] The trigger is a signed, validated, replay-protected webhook → routine, with a scheduled backstop that re-scans for assigned issues so dropped events still get picked up.
- [ ] The backstop's fire budget cannot be silently burned by a malformed or ungated issue.
- [ ] The routine and its triggers are the documented source of truth (a repo artifact), not only web-UI state no one can inspect.

## 2. Triage / routing (quality)

- [ ] The issue is routed by **type**: a bug → `/debug` (root cause → failing test → fix), a feature → `/feature`, a chore → its path. **A bug is never built like a feature.**
- [ ] MEDIUM+ work without a design gets a design step, or a clear "needs design" bounce — never a silent death inside the workflow.
- [ ] Scope/size is detected and the right pipeline tier runs.

## 3. Claim / state machine

- [ ] On start: Todo → In Progress, safe enough that two runs can't both claim the same issue.
- [ ] Dedup: an issue that already has an open PR, or is already In Progress, is skipped.
- [ ] On block/fail: released back to Todo so the claim doesn't wedge.
- [ ] On PR open: → In Review, set by the loop, not left to chance.
- [ ] On merge: → Done **automatically** — the PR always carries a guaranteed `Closes <ISSUE>` link, however the PR was opened.

## 4. Build (quality + testing)

- [ ] Runs the full quality pipeline: design gate → TDD → review (adversarial `/cr` + lenses) → security / UX review as scoped → simplify.
- [ ] **World-class testing:** tests written first; property-based / fuzz tests for logic-heavy code; mutation-checked so vacuous tests are caught.
- [ ] **CI re-runs the tests as the un-forgeable gate** — the agent's own "I verified it" is never what gates a merge.
- [ ] Isolated worktree per task; the *committed* tree is verified (nothing on-disk-but-uncommitted slips through).

## 5. The agent talks back (comprehension)

- [ ] On claim: posts its plan / approach as a comment on the issue.
- [ ] During the run: logs key decisions and assumptions (a decision log) and surfaces any blocking question.
- [ ] On finish: posts the **PR link + the preview-deploy link + a plain-language "what changed and why"** summary, on the issue — so you understand the change without digging through the diff.

## 6. Human Q&A loop (unblock without babysitting)

- [ ] When blocked, the agent asks a specific question on the issue and stops.
- [ ] You answer in a comment; the backstop / routine reads the answer and **resumes** — no manual re-kick.
- [ ] Hard caps on retries and stuck runs prevent infinite loops or budget burn.

## 7. Review + merge (you always merge)

- [ ] The PR opens with full context (spec, decisions, preview link) rendered for a teachable review.
- [ ] Branch protection physically prevents the bot from merging; required reviews and required status checks are enforced.
- [ ] You get **one clear notification** with the PR + preview + summary — enough to decide whether to deep-review.
- [ ] **No auto-merge, ever.** Approval is your merge.

## 8. Notification / control panel

- [ ] **Every** end-state notifies — PR-ready, blocked-question, and hard-fail alike. Never silent.
- [ ] Failure alerts are actionable: what failed, which issue, the next step.
- [ ] Slack (or equivalent) is a reliable pager at the right noise level; the forge (GitHub) is where you act. No Slack approval theater unless the merge flow stops being enough.

## 9. Deploy / preview

- [ ] Every PR gets an automatic preview deploy.
- [ ] The preview URL is posted **where you'll see it** (the issue + the notification), not buried on the PR checks.
- [ ] (Later, optional) runtime errors on the preview surface back as issues — the bug-to-issue loop.

## 10. Compounding (two-way)

- [ ] Lessons learned in a run (a new pitfall, pattern, or fix) are captured and **proposed back to the harness** as a PR you merge.
- [ ] Harness improvements propagate **out** to every repo automatically, without halting anyone's in-progress work.
- [ ] The loop's own metrics — revert rate, time-to-PR, catch-rate, silent-failure count — are tracked, so the *loop* improves over time, not just the code it produces.

## Never

- Auto-merge anything.
- Let anything fail silently.
- Build a bug like a feature.
- Trust the agent's self-report as the gate.
- Add Slack approval buttons while merging on the forge is already enough.
- Block teammates' work when the harness updates.
