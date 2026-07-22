# Outer-loop ownership plan

Seven tasks that close the gaps between what this harness documents and what it
enforces. The frame comes from Addy Osmani's essay "Own the Outer Loop": agents
run the inner loop (investigate, implement, test, report); the human owns the
outer loop (verify the evidence, decide ship/block, and be able to explain why).
The boundary between the two loops is **evidence** — diffs, tests, logs, and a
short "why" — and the human's merge click must be a verdict over that evidence,
not a rubber stamp.

Each task below is written so a smaller model can implement it without extra
context. Read the **Rules for every task** section first. Then do the tasks in
the order given in **Ordering**.

---

## Rules for every task

1. **Route through the harness.** Every task here changes behavior, so start it
   with the `/feature` skill (it runs TDD for you). Do not write the code
   directly.
2. **One task = one branch = one PR.** Branch name: use the `feat/<slug>` given
   in the task header. Create a dedicated worktree first:
   `bash scripts/worktree-add.sh .claude/worktrees/<slug> feat/<slug>` and do
   all work inside it. Committing a feature branch from the main worktree is
   blocked by the pre-commit hook.
3. **Conventional commits**, subject ≤ 72 chars (enforced by the commit-msg
   hook). Example: `feat(pr): add accountability contract to PR body`.
4. **Tests are shell tests** in `tests/<name>.test.sh`, run by `npm test`.
   Every new `*.test.sh` file MUST contain this exact line near the top (the
   pre-commit hook rejects the file without it):

   ```
   unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
   ```

   Copy the structure of an existing test (for example `tests/cr-ok.test.sh`
   or `tests/pre-push-branch-naming.test.sh`): they create a temp repo, install
   the hook or script under test, exercise it, and assert on exit codes and
   output.
5. **Shell code is POSIX sh** in hooks, bash in `scripts/*.sh`. Run
   `npm run lint` before committing. Comments must explain WHY, never WHAT
   (the comment-lint hook blocks WHAT-comments).
6. **Run `/cr` before pushing.** The pre-push hook requires the `.claude/.cr-ok`
   sentinel, which only `/cr` (via `scripts/cr-ok.sh`) may produce. Never write
   the sentinel yourself — that is the exact trust violation documented in
   `docs/solutions/2026-07-01-self-issued-review-sentinel-is-a-trust-boundary.md`.
7. **Protected files — the handoff protocol.** Agents cannot commit changes to
   `.husky/*`, `.claude/hooks/*`, `.claude/agents/*`, `.claude/settings*.json`,
   `package*.json`, or the gate scripts (`cr-ok.sh`, `design-confirm.sh`,
   `commit-msg-lint.sh`, `shell-portability-lint.sh`, `lint.sh`,
   `token-lint.sh`, `comment-lint.sh`, `data-state-lint.sh`,
   `circular-imports.sh`). The pre-commit safety guard blocks it. When a task
   needs one of these files changed:
   - Put ALL logic you can into a NEW script under `scripts/` (new scripts are
     not protected) so the protected-file diff is one or two lines.
   - Write the exact protected-file diff into the task's PR description under a
     heading `## Needs human commit`, as a fenced diff block, plus the exact
     command: `git apply <<'EOF' ... EOF` or a copy-pasteable `sed`/edit, then
     `git commit --no-verify -m "<message>"`.
   - State in one sentence what the diff does and why only the human can
     commit it. Never use `--no-verify` yourself.
8. **Do not weaken any gate.** If a step seems to require loosening a check,
   stop and surface the question instead of proceeding.

## Ordering

| Order | Task | Depends on | Who commits |
|-------|------|------------|-------------|
| any time | 1. Enable branch protection | — | human only (GitHub UI) |
| 1st | 2. Accountability contract in PRs | — | agent |
| 2nd | 6. Mandatory "why" floor | 2 | agent |
| 3rd | 4. Durable evidence | 2 | agent + tiny human hook diff |
| any time | 3. Sentinel check on the human push path | — | agent scripts + human hook diff |
| any time | 5. Memory-candidate stop hook | — | agent scripts + human hook diff |
| last | 7. Sanctioned remote-session lane | 1 (protection live) | human hook diff, agent tests |

Phase 2 — the self-improvement loop (from the Ambiance and Self-Harness
reviews). Do these after Tasks 1–7:

| Order | Task | Depends on | Who commits |
|-------|------|------------|-------------|
| 1st | 8. Observation layer (gate-trip log + session journal) | 4, 5 (hook diffs batch together) | agent scripts + human hook diffs |
| 2nd | 9. Weakness-mining ritual (/harness-mine) | 8 | agent |
| any time | 10. Regression gate on harness edits | 2 | agent |
| any time | 11. Model tagging on findings | — | agent |
| any time | 12. Return instrumentation (measure return, not activity) | 2 | agent |

Phase 3 — closing the remaining automation gaps. Task 13 is high priority
(do it alongside Tasks 1–2, before any fleet scaling); it also closes the
forgeable-sentinel gap (survey gap G3). Task 14 is a low-effort ritual. Task
15 is a deferred design sketch — do not build it until Tasks 1–13 have
earned the trust it depends on.

| Order | Task | Depends on | Who commits |
|-------|------|------------|-------------|
| high, with 1–2 | 13. Automate code + security review in CI | 1 (protection) | agent scripts + human secrets/config |
| any time | 14. Priors audit ritual | — | agent |
| deferred | 15. Event-driven initiation (Phase 5 sketch) | 1–13 | design only, then human-gated |

Phase 4 — the loop era. From the Loop Engineering reference
(cobusgreyling/loop-engineering). These make scheduled, self-starting loops
safe to run. Task 16 is a foundational convention adoptable now; Tasks
17–18 are Phase-5-adjacent and gated on the same earned trust as Task 15.

| Order | Task | Depends on | Who commits |
|-------|------|------------|-------------|
| foundational, any time | 16. Autonomy-level taxonomy (L1/L2/L3) | — | agent |
| with 15 | 17. Maintenance-loop catalog + collision rules | 15, 16 | agent (docs) |
| before any loop runs | 18. Per-run spend circuit breaker + cost estimate | 16 | agent |

Phase 5 — the skill ecosystem. From Addy Osmani's agent-skills library
(github.com/addyosmani/agent-skills). This harness is a peer skill library
and is at parity or ahead on most of that library's 24 skills. The value is
two structural patterns it applies uniformly that the harness applies
unevenly, plus a couple of genuinely thin skills.

| Order | Task | Depends on | Who commits |
|-------|------|------------|-------------|
| high, any time | 19. Standardize the skill contract (rationalizations + evidence), lint-enforced | — | agent script + human hook line |
| any time | 20. Fill the thin-spot skills (migration first) | 19 | agent |

---

## Task 1 — Enable branch protection so CI actually blocks merges

**Slug:** none — this is a human action plus one doc edit.

**Why:** `scripts/ci-verify.sh` re-runs lint and tests server-side via
`.github/workflows/ci.yml`. It is the only check an agent cannot fake. But per
`docs/ci-gate.md`, it only *blocks* a merge after branch protection is turned
on in GitHub settings — until then it is advisory. This is the
highest-leverage, lowest-effort item in the plan.

**Human steps (put these in front of the operator verbatim):**

1. Open `https://github.com/tannerolsen7/agent-harness/settings/branches`.
2. Add a branch protection rule (or ruleset) for `main`:
   - Require status checks to pass before merging → select the check produced
     by `.github/workflows/ci.yml` (open a recent PR's Checks tab to see its
     exact name).
   - Require branches to be up to date before merging.
   - Do NOT enable auto-merge anywhere. A human merge is the accountability
     boundary (`docs/automation-loop-target-state.md`).
3. Reply "protection enabled" so the doc edit below can land.

**Agent steps (after human confirms):**

1. Edit `docs/ci-gate.md`: find the section that says CI is advisory until
   branch protection is enabled, and add a dated status line, e.g.
   `Status: branch protection enabled on main (2026-07-__), CI is blocking.`
2. Commit as `docs(ci): record that branch protection is live`.

**Acceptance:** a PR with a deliberately failing test cannot be merged through
the GitHub UI.

---

## Task 2 — Accountability contract in every PR

**Slug:** `feat/pr-accountability-contract`

**Why:** Right now the merge click is the human verdict, but nothing puts the
evidence in front of the human at that moment: `/cr` writes its own sentinel,
the disposition report is optional reading, and the PR body carries no record
of what was checked. This task makes every PR carry an "accountability
contract": what was checked, the evidence, who owns it, and a short why. CI
then verifies the contract *exists* (presence only — judging its quality stays
human).

**Files to touch (all agent-committable):**

- `scripts/pr.sh` — where the PR body is assembled.
- `scripts/pr-contract-check.sh` — NEW: validates a PR body.
- `.github/workflows/ci.yml` — add a presence-check job.
- `tests/pr-contract.test.sh` — NEW.

**Steps:**

1. Read `scripts/pr.sh` end to end. Find where the PR body text is built.
2. Add a function that appends this block to every PR body:

   ```markdown
   ## Accountability contract
   ### Checklist run
   - [ ] lint (pre-commit)
   - [ ] tests (`npm test`)
   - [ ] /cr review passes
   <!-- check the boxes for gates that actually ran; never check a box for a gate that did not run -->
   ### Evidence
   <!-- filled by pr.sh: sentinel audit lines, /cr disposition summary path, ASSUMPTION entries -->
   ### Why
   <!-- one short paragraph: why this change exists and why this approach -->
   ### Owner
   <!-- GitHub handle of the human accountable for the merge -->
   ### Status if blocked
   <!-- "not blocked" or a one-line description of what is blocking -->
   ```

3. Have `pr.sh` pre-fill what it can mechanically:
   - Checklist: check the boxes for gates whose artifacts exist (`.claude/.cr-ok`
     matching `branch:sha` → check the /cr box). Never check a box you cannot
     verify from an artifact.
   - Evidence: copy the matching line(s) for this branch from
     `.claude/.cr-ok.log` and `.claude/.design-confirmed.log` (they are local
     audit logs; embedding them in the PR body is what makes them durable —
     see Task 4). Also copy any `ASSUMPTION` entries for this branch's slug
     from `.claude/questions.md`.
   - Owner: `git config user.name` / the repo owner as fallback.
   - Why / Status: leave the HTML-comment placeholders; the calling agent or
     human fills them (Task 6 makes "Why" mandatory).
4. Write `scripts/pr-contract-check.sh`: takes a file containing a PR body (or
   reads stdin), exits 0 only if all five headings are present AND the `### Why`
   section contains at least one non-comment, non-empty line. Print a specific
   error naming each missing piece.
5. In `.github/workflows/ci.yml`, add a job that runs only on `pull_request`
   events: it writes `${{ github.event.pull_request.body }}` to a file (use an
   environment variable, not direct interpolation into the script, to avoid
   injection) and runs `bash scripts/pr-contract-check.sh` on it.
6. Tests (`tests/pr-contract.test.sh`):
   - A body with all sections and a filled Why → exit 0.
   - Missing any heading → exit 1 and the error names the missing heading.
   - Why section containing only the HTML comment → exit 1.
   - `pr.sh` body-assembly: in a temp repo fixture, assert the generated body
     contains all five headings, and that the /cr checkbox is checked only
     when a matching sentinel exists.

**Acceptance:** every new PR body contains the contract; a PR whose body lacks
it fails the CI presence job; `npm test` passes.

**Out of scope:** judging the *content* of the Why; changing `.husky/*`.

---

## Task 3 — Validate the /cr sentinel on the human push path

**Slug:** `feat/human-push-sentinel-check`

**Why:** `.husky/pre-push` has two paths. The agent path checks the
`.claude/.cr-ok` sentinel. The human (TTY) path only asks "Have you run /cr?
[y/N]" and never looks at the sentinel — a human can type `y` with no review
ever having happened. Self-attestation is not evidence. The fix: both paths
validate the sentinel; the human keeps `git push --no-verify` as the deliberate
escape.

**Files:**

- `scripts/validate-cr-sentinel.sh` — NEW (agent-committable). All logic here.
- `.husky/pre-push` — PROTECTED. Two-line diff, human commits (Rule 7).
- `tests/validate-cr-sentinel.test.sh` — NEW.

**Steps:**

1. Read `.husky/pre-push` fully, and `scripts/cr-ok.sh` to learn the exact
   sentinel format (`branch:sha` in `.claude/.cr-ok`).
2. Write `scripts/validate-cr-sentinel.sh`:
   - Args: `<branch> <push-sha>`.
   - Exit 0 if `.claude/.cr-ok` exists and its content equals
     `<branch>:<push-sha>`.
   - Exit 1 otherwise, printing which condition failed (missing file, wrong
     branch, stale sha) and the remedy: run `/cr`, or
     `git push --no-verify` for a deliberate manual push.
   - POSIX sh, no bashisms (it is called from a husky hook).
3. Copy the existing non-interactive sentinel check in `.husky/pre-push` and
   confirm your script is equivalent — then the hook's agent path can also call
   the script, so the logic lives in one place.
4. Prepare the protected diff for `.husky/pre-push` (do NOT commit it):
   - Human path: replace the y/N-only block with a call to
     `sh scripts/validate-cr-sentinel.sh "$BRANCH" "$PUSH_SHA"`; on failure,
     abort. Keep a confirmation prompt after a *passing* check if you want,
     but the sentinel check is the gate.
   - Agent path: replace the inline sentinel comparison with the same script
     call.
   Put the diff in the PR body under `## Needs human commit` with the exact
   apply-and-commit command (Rule 7).
5. Tests: exercise `scripts/validate-cr-sentinel.sh` directly in a temp repo —
   pass case, missing sentinel, wrong branch, stale sha. (Testing the TTY path
   of the hook itself is not required; the script carries the logic.)

**Acceptance:** script tests pass; PR contains the ready-to-apply hook diff;
after the human applies it, a TTY push without a valid sentinel is blocked.

---

## Task 4 — Make the evidence durable

**Slug:** `feat/durable-evidence`

**Why:** The essay's boundary between loops is evidence, but most of this
harness's evidence evaporates: the sentinel audit logs (`.claude/.cr-ok.log`,
`.claude/.design-confirmed.log`) are gitignored and local-only, and the
permission log lives in `/tmp` and is truncated at every session start.
Evidence must travel with the PR (part done in Task 2) and survive the session.

**Files:**

- `scripts/pr.sh` — already embeds audit-log lines if Task 2 was done; verify,
  extend if the Evidence section is missing either log.
- `scripts/persist-perm-log.sh` — NEW (agent-committable).
- `.claude/hooks/session-stop.sh` — PROTECTED. One-line diff, human commits.
- `tests/persist-perm-log.test.sh` — NEW.

**Steps:**

1. Verify Task 2's Evidence section embeds the matching lines from BOTH
   `.claude/.cr-ok.log` and `.claude/.design-confirmed.log`. If not, add it.
2. Write `scripts/persist-perm-log.sh`:
   - Find the session permission log (`/tmp/claude-perm-log-*.jsonl` — read
     `.claude/hooks/session-start.sh` to confirm the exact path pattern).
   - Copy it to `.claude/activity/perm-<branch-slug>-<UTC timestamp>.jsonl`.
   - Exit 0 silently when no log exists (not every session produces one).
   - Check `.gitignore` / `.claude/activity` conventions: activity JSONL files
     are already committed there, so the copy needs no ignore changes.
3. Prepare the protected one-line diff for `.claude/hooks/session-stop.sh`:
   a call to `bash scripts/persist-perm-log.sh` near where the activity record
   is written. Deliver via the Rule 7 handoff in the PR body.
4. Tests: temp dir with a fake perm log → script copies it with the right name;
   no log → exit 0, no file created; run twice → second file, no clobber.

**Acceptance:** PR Evidence sections show both audit trails; after the human
applies the hook diff, ending a session leaves a `perm-*.jsonl` in
`.claude/activity/`.

**Out of scope:** adding a "why" field to activity logs (covered by Tasks 2/6
at the PR level).

---

## Task 5 — Build the promised memory-candidate stop hook

**Slug:** `feat/memory-candidate-hook`

**Why:** `docs/engineering-system/07-memory-system.md` promises "a Stop hook
proposes memory.md candidates at session end so you don't depend on
remembering" — and `docs/engineering-system/12-anti-rationalization.md` leans
on that promise. It was never built: `.claude/hooks/session-stop.sh` writes a
handoff and an activity record only. Session corrections currently survive only
if someone remembers to record them — the exact failure the doc warns about.

**Design constraint:** the hook PROPOSES candidates; only the human approves
additions to `.claude/memory.md`. Never write to memory.md from the hook
(`12-anti-rationalization.md` documents an incident where an agent did exactly
that).

**Files:**

- `scripts/memory-candidates.sh` — NEW (agent-committable).
- `.claude/hooks/session-stop.sh` — PROTECTED. One-line diff, human commits.
- `docs/engineering-system/07-memory-system.md` — update status once live.
- `tests/memory-candidates.test.sh` — NEW.

**Steps:**

1. Read `07-memory-system.md` for what a memory.md entry looks like, and
   `.claude/hooks/session-stop.sh` for how the handoff block is printed.
2. Write `scripts/memory-candidates.sh`. Sources to scan (all best-effort;
   missing file → skip silently):
   - `ASSUMPTION` entries in `.claude/questions.md` (each unreviewed assumption
     is a candidate constraint).
   - Entries added to `docs/RECURRING-FINDINGS.md` in the current branch's
     diff against the default branch (`git diff origin/main...HEAD -- docs/RECURRING-FINDINGS.md`,
     added lines only).
   - `.claude/corrections.jsonl` if it exists (future-proofing; document the
     format in a comment: one JSON object per line with a `text` field).
3. Output format: if any candidates found, print a block titled
   `memory.md candidates — human approval required:` with one bullet per
   candidate, each phrased as a durable constraint ("Always X" / "Never Y"),
   followed by the line `To adopt: edit .claude/memory.md yourself; agents may
   not write it.` If none found, print nothing and exit 0.
4. Prepare the protected one-line diff calling the script from
   `session-stop.sh` so its output lands inside the existing handoff block.
   Deliver via the Rule 7 handoff.
5. Update `07-memory-system.md`: change the "Stop hook proposes candidates"
   sentence from promise to fact, noting the script name.
6. Tests: fixture questions.md with two ASSUMPTION entries → both surface;
   empty sources → no output, exit 0; corrections.jsonl with one entry →
   surfaces.

**Acceptance:** script tests pass; PR carries the hook diff; docs no longer
promise an unbuilt safety net.

---

## Task 6 — A mandatory "why" floor on every change

**Slug:** `feat/mandatory-why-floor`

**Why:** Every "why"-capturing mechanism is currently opt-out: ADRs fire only
when the agent judges three conditions true, and every `/compound` sub-step
accepts "no compound-worthy findings." An agent that forms no judgment leaves
the diff as the entire record. Answerability must have a floor that cannot be
skipped: a short "why" on every PR (the contract's `### Why` section from
Task 2), and opt-outs that state a reason instead of a bare "nothing here."

**Files (all agent-committable — skills are not protected):**

- `.claude/skills/cr/SKILL.md`
- `.claude/skills/compound/SKILL.md`
- `scripts/pr-contract-check.sh` (from Task 2 — verify, don't rebuild)
- `tests/pr-contract.test.sh` (extend)

**Steps:**

1. Confirm Task 2's `pr-contract-check.sh` already fails an empty `### Why`
   section. That is the machine-checked floor. If Task 2 shipped without it,
   add it here with a test.
2. Edit `.claude/skills/cr/SKILL.md`: find the compound-evaluation step (the
   one that permits stating "No compound-worthy findings"). Change the rule:
   the opt-out must include a one-line reason (e.g. "routine lint fixes, no
   new pattern") AND that line must be copied into the PR's `### Why` or
   `### Evidence` section. A bare "no findings" is no longer a valid step
   output.
3. Edit `.claude/skills/compound/SKILL.md` with the same rule for its opt-out
   points.
4. Keep the skill wording in this repo's voice: plain language, one idea per
   sentence (see CLAUDE.md "Communication voice").
5. Extend `tests/pr-contract.test.sh` if step 1 added behavior.

**Acceptance:** no path through `/cr` or `/compound` ends with an unexplained
opt-out; a PR with an empty Why fails CI.

**Out of scope:** changing ADR's three-condition rule — ADRs stay reserved for
hard-to-reverse decisions; the PR Why is the floor beneath them.

---

## Task 7 — A sanctioned lane for remote agent sessions

**Slug:** `feat/remote-session-lane`

**Why:** Remote sessions (Claude Code on the web) work on `claude/<slug>`
branches checked out in the main worktree. Three gates make it impossible for
those sessions to commit or push legitimately: the branch-naming gate has no
`claude` type, the worktree gates block main-worktree commits/pushes of
feature branches, and that leaves `--no-verify` as the only route — which
trains agents to bypass the safety floor. The fix is a narrow, explicit lane,
not a loosening: `claude/*` branches become recognized, worktree-gate-exempt
(the remote platform controls that checkout, and the branch only exists in
remote sessions), but still subject to every other gate — naming, sync,
merged-PR block, the `/cr` sentinel, and `npm test`.

**Decision the human must confirm BEFORE implementation** (put this at the top
of the PR and ask via a blocking question): exempting `claude/*` from the
worktree gate is a deliberate gate change. Quality back-pressure is preserved
because the sentinel and tests still apply, and CI (Task 1) still blocks bad
merges — but the human must approve the tradeoff.

**Files:**

- `.husky/pre-push` — PROTECTED (naming gate + worktree gate). Human commits.
- `.husky/pre-commit` — PROTECTED (worktree gate). Human commits.
- `tests/remote-session-lane.test.sh` — NEW (agent-committable).
- `docs/ci-gate.md` or a new short `docs/remote-session-lane.md` — document the
  lane and its rationale.

**Steps:**

1. Read the naming gate and both worktree gates (`.husky/pre-push`,
   `.husky/pre-commit`) and the existing tests
   `tests/pre-push-branch-naming.test.sh` and
   `tests/agent-worktree-enforcement.test.sh` — mirror their test style.
2. Prepare the protected diffs (do not commit them):
   - Naming gate in `pre-push`: add `claude` to the allowed types regex.
   - Worktree gate in `pre-push` AND the matching gate in `pre-commit`: add a
     `claude/*` case to the exemption list (alongside `main|master|HEAD`),
     each with a WHY comment: remote platform sessions run in the main
     worktree by construction; all other gates still apply.
   - Do NOT touch the sentinel check, sync gate, or merged-PR block — the
     lane must keep them.
3. Write `tests/remote-session-lane.test.sh` against COPIES of the patched
   hooks (apply your prepared diff inside the test's temp repo — this lets the
   test land before the human applies the diff to the real hooks, and proves
   the diff does what it claims):
   - `claude/foo` passes the naming gate; `bogus/foo` still fails.
   - `claude/foo` commit from a main-worktree temp repo passes the worktree
     gate; `feat/foo` from the main worktree still fails.
   - `claude/foo` push without a valid `.cr-ok` sentinel still fails.
4. Write the short doc: what the lane is, what is exempted, what still applies,
   and that CI branch protection (Task 1) is the backstop.
5. Deliver both hook diffs via the Rule 7 handoff in the PR body.

**Acceptance:** tests prove the patched hooks admit `claude/*` while keeping
the sentinel and naming enforcement for everything else; the human has
explicitly approved and committed the hook diffs; a remote session can then
commit and push without `--no-verify`.

---

# Phase 2 — the self-improvement loop

Background for Tasks 8–11. Two sources shape them. The Self-Harness research
(Shanghai AI Lab) improves an agent harness in three stages: mine failure
traces for patterns, propose minimal harness edits, and validate each edit
with regression tests that reject anything that breaks a previously passing
case. The Ambiance architecture adds the "librarian": a standing role that
journals what the agent is good at, bad at, and what happened each day. This
harness already has the back half of that loop (adoption via /compound, the
RECURRING-FINDINGS ratchet, human-approved memory.md) and the validation
infrastructure (tests/). What it lacks is the front half: nothing durable
records failures, so mining happens by accident.

**Standing rule for all Phase 2 work:** the proposer is never the approver.
Mined proposals land as evidence-backed PRs against unprotected surfaces
(skills, docs, new scripts). Guard files stay human-only. The human merge
stays the verdict. An agent must never act on a mined proposal by editing
protected files itself.

---

## Task 8 — Observation layer: gate-trip log and session journal

**Slug:** `feat/observation-layer`

**Why:** Every pre-commit rejection, pre-push rejection, and CI failure is a
free failure trace — and today they all vanish. Activity logs record what ran
(skills, sha, duration) but never outcomes. Without durable traces there is
nothing to mine, and self-improvement depends on an agent happening to notice
a pattern.

**Files:**

- `scripts/log-gate-trip.sh` — NEW (agent-committable).
- `scripts/session-journal.sh` — NEW (agent-committable).
- `.husky/pre-commit`, `.husky/pre-push` — PROTECTED. One added line per
  rejection exit path, human commits (Rule 7).
- `.claude/hooks/session-stop.sh` — PROTECTED. One-line diff, human commits.
  Batch this diff with the ones from Tasks 4 and 5 so the human applies one
  combined hook patch, not three.
- `tests/log-gate-trip.test.sh`, `tests/session-journal.test.sh` — NEW.

**Steps:**

1. Write `scripts/log-gate-trip.sh <gate-name> <branch> <one-line-detail>`:
   appends one JSON line to `.claude/activity/gate-trips.jsonl` with fields
   `ts`, `gate`, `branch`, `detail`. Hard requirement: it must NEVER change
   the caller's behavior — always `exit 0`, swallow its own errors, create
   the directory if missing. A logging failure must not block or unblock a
   gate.
2. Write `scripts/session-journal.sh`: appends one JSON line to
   `.claude/activity/journal.jsonl` with fields `ts`, `branch`, `sha`,
   `model`, `outcome` (one of `merged`, `pr-open`, `blocked`, `abandoned`,
   `in-progress`), `gates_tripped` (count read from gate-trips.jsonl for this
   branch), `note` (free text: what went well, what failed, corrections the
   human made). Read `.claude/hooks/session-stop.sh` first to reuse how it
   already derives branch/sha/model for the activity record.
3. Prepare the protected diffs (Rule 7 handoff):
   - In each rejection exit path of `.husky/pre-commit` and `.husky/pre-push`
     (every `exit 1` after a "blocked" message), insert one line before the
     exit: `sh scripts/log-gate-trip.sh "<gate-name>" "$BRANCH" "<detail>" || true`.
     Use a short stable gate name per site (e.g. `worktree-gate`,
     `branch-naming`, `cr-sentinel`, `safety-file-guard`).
   - In `session-stop.sh`: one line calling `bash scripts/session-journal.sh`.
4. Tests: gate-trip script appends valid JSON and exits 0 even when the
   activity dir is unwritable; journal script produces one line per call with
   all fields present; malformed inputs never exit non-zero.

**Acceptance:** after the human applies the hook patch, a blocked commit
leaves a `gate-trips.jsonl` line, and every session end leaves a journal
line. `npm test` passes.

---

## Task 9 — Weakness-mining ritual: /harness-mine

**Slug:** `feat/harness-mine-skill`

**Why:** This is the front half of the Self-Harness loop, run as a periodic
ritual instead of an autonomous rewrite. It reads the observation layer and
proposes minimal harness edits — with the trace evidence attached — for the
human to accept or reject. It is the generalization of what `/post-mortem`
already does for hotfixes.

**Files (all agent-committable — skills are not protected):**

- `.claude/skills/harness-mine/SKILL.md` — NEW.
- `docs/engineering-system/07-memory-system.md` or the rituals doc — add the
  ritual to the weekly list next to `/scan-context`.
- `tests/skill-frontmatter-lint` coverage comes free from the existing lint.

**Steps:**

1. Read `.claude/skills/post-mortem/SKILL.md` and `scan-context/SKILL.md`
   for structure and voice. Read `scripts/skill-frontmatter-lint.sh` for the
   frontmatter rules a skill must satisfy.
2. Write the skill. Its procedure:
   a. Read `.claude/activity/gate-trips.jsonl`, `.claude/activity/journal.jsonl`,
      `docs/RECURRING-FINDINGS.md`, and recent CI failure summaries if
      available. Missing sources → note and continue.
   b. Group failures by pattern (same gate tripped ≥3 times, same finding
      recurring, same correction made twice).
   c. For each pattern, ask FIRST: "what context was the model missing?"
      Classify the pattern as missing-context, missing-rule, or missing-tool.
      When a context fix (a doc or skill edit that supplies what the model
      didn't know) and a new rule would both prevent the failure, prefer the
      context fix — rules accumulate as permanent tax on every future
      session; context fixes only load when relevant.
   d. For each pattern, propose the SMALLEST harness edit that would prevent
      it: a skill wording fix, a new PITFALLS.md entry, a new lint script, a
      doc correction. One proposal per pattern.
   e. Every proposal must carry: the evidence (the actual trace lines), the
      proposed diff, and the regression test that would have caught the
      original failure (see Task 10 — a proposal without a test is
      incomplete).
   f. Write proposals to `docs/harness-mine/<date>.md`. NEVER apply edits to
      protected files; proposals touching them get a "needs human" label.
   g. End by presenting the proposal list to the human for disposition
      (adopt / backlog / drop), reusing the disposition vocabulary from
      `/cr` Step 5.
3. Add the ritual to the weekly cadence documentation.

**Acceptance:** running `/harness-mine` on a repo with seeded gate-trip and
journal fixtures produces a proposals file with evidence, diff, and test per
proposal, and applies nothing by itself.

---

## Task 10 — Regression gate on harness edits

**Slug:** `feat/harness-edit-regression-gate`

**Why:** Self-Harness's discipline is what keeps rule churn safe: an edit
that fixes the target case but breaks a passing one is rejected. The
harness's own scripts are its product code, so the rule here is: a PR that
changes harness behavior must carry a test, or say why not — silently
untested harness edits are what let gates rot.

**Files:**

- `scripts/harness-regression-check.sh` — NEW (agent-committable).
- `.github/workflows/ci.yml` — extend the pull_request job from Task 2.
- `scripts/pr.sh` — add a `### No-test rationale` placeholder to the
  accountability contract (Task 2 structure).
- `tests/harness-regression-check.test.sh` — NEW.

**Steps:**

1. Write `scripts/harness-regression-check.sh <base-ref> <pr-body-file>`:
   - Compute the diff file list `git diff --name-only <base-ref>...HEAD`.
   - If any `scripts/*.sh` file is added or modified AND no `tests/*.test.sh`
     file is added or modified, then require the PR body's
     `### No-test rationale` section to contain a non-empty, non-comment
     line. Missing both → exit 1 naming the untested scripts.
   - Doc-only and skill-wording-only diffs pass without a test.
2. Wire it into the CI pull_request job next to `pr-contract-check.sh`,
   passing the PR body the same way (env var, not direct interpolation).
3. Tests: script-change-with-test passes; script-change-no-test-no-rationale
   fails and names the file; script-change-with-rationale passes; docs-only
   passes.

**Acceptance:** CI fails a PR that modifies a harness script with neither a
test nor a stated reason; `npm test` passes.

---

## Task 11 — Model tagging on findings

**Slug:** `feat/model-tagged-findings`

**Why:** The Self-Harness results show failure patterns are model-specific —
the biggest gains came from rules tailored to one model's quirks. This
harness routes work to different model tiers (see
`docs/model-tier-audit.md`), so a finding produced by a small model should
not become an unqualified rule for every model, and a small implementer
should get the pitfalls that apply to its tier prepended, not the whole
list.

**Files (all agent-committable):**

- `docs/RECURRING-FINDINGS.md` — add a `model:` field to the entry format.
- `.claude/skills/cr/SKILL.md` — the step that records findings now also
  records the model that produced the reviewed diff (from the session's
  model id; if unknown, write `unknown`).
- `PITFALLS.md` — document an optional `models:` qualifier on entries:
  absent means "applies to all"; present means "observed on these models".
- `docs/model-tier-audit.md` — one paragraph: when dispatching a task to a
  lesser model, prepend the PITFALLS entries whose `models:` matches or is
  absent.

**Steps:** make each edit above; keep existing entries valid (the new fields
are optional, never required retroactively). No scripts change, so Task 10's
gate accepts a no-test rationale of "format documentation only".

**Acceptance:** new RECURRING-FINDINGS entries carry `model:`; PITFALLS
documents the qualifier; the ratchet rule (3 occurrences → PITFALLS) is
unchanged.

---

## Task 12 — Return instrumentation: measure return, not activity

**Slug:** `feat/return-instrumentation`

**Why:** The harness dashboards (`harness-progress.html`,
`harness-activity.html`) count sessions, durations, and top skills — all
activity. Activity measures that the machine ran, not that it paid off. The
better question (from Boris Cherny's "Steps of AI Adoption"): would you have
spent engineering effort on this anyway, and what would it have cost in
manual eng-hours? Capture that answer at PR time — when the context is
fresh — and let the dashboard report eng-hours returned instead of sessions
run. This is also the step-3 discipline for token spend: "is this something
an engineer would have done?"

**Files:**

- `scripts/pr.sh` — extend the Task 2 accountability contract.
- `scripts/return-report.sh` — NEW (agent-committable).
- Whichever script renders `harness-progress.html` — READ FIRST to find it
  (start from the session-start hook and follow what it calls). If it lives
  under `.claude/hooks/`, it is PROTECTED: put all logic in
  `return-report.sh` and hand the one-line hook call to the human (Rule 7).
  If it lives in `scripts/`, edit it directly.
- `tests/return-report.test.sh` — NEW.

**Steps:**

1. Add two lines to the accountability contract's `### Why` area in `pr.sh`:

   ```markdown
   ### Return
   - Would we have built this without the agent? <!-- yes / no / eventually -->
   - Estimated manual effort: <!-- N hours a human would have spent -->
   ```

   Extend `scripts/pr-contract-check.sh` (Task 2) to require both lines to
   be filled (non-comment content after the colon/dash). Honesty rule: "no"
   is a valid and important answer — work you'd never have done manually is
   new capacity, not saved hours; never inflate the estimate to make the
   dashboard look good.
2. Write `scripts/return-report.sh`: for each merged PR it can see (use the
   merged-branch list or the activity records — read what's available
   locally; do not call the GitHub API), collect the two Return answers and
   print a summary: total estimated eng-hours returned, split by
   would-have-built-anyway vs. new-capacity work. Output plain text and a
   small HTML fragment the dashboard can include.
3. Wire the fragment into the progress dashboard (directly, or via the
   Rule 7 handoff if the renderer is a protected hook).
4. Tests: fixture PR-contract texts → correct totals; missing Return
   section → PR fails the contract check (extend `tests/pr-contract.test.sh`).

**Note on token spend:** precise token counts are not visible to shell
hooks. Do not fake them. The journal (Task 8) already records model and
duration per session; if real token metrics are wanted later, the supported
route is Claude Code's analytics/OpenTelemetry export — record that as a
BACKLOG entry, out of scope here.

**Acceptance:** every PR states whether the work would have happened anyway
and its manual-effort estimate; `return-report.sh` aggregates them; the
dashboard shows return alongside activity; `npm test` passes.

---

# Phase 3 — closing the remaining automation gaps

Background for Tasks 13–15. The prior phases assume code review happens. It
does not happen automatically. Today `/cr` is a manual skill: an agent or a
human must remember to run it, it self-writes a soft `.claude/.cr-ok`
certificate that "runs no checks," and CI re-runs only the deterministic
floor (lint, tests, routing, integrity) — never the review passes, the
adversarial lenses, or the security review. So the review that Boris
Cherny's "Steps of AI Adoption" treats as a default-on Step 2 guardrail is,
in this harness, trust-based and skippable. Task 13 fixes that. Tasks 14–15
carry over the last two ideas from the Ambiance review (audit bespoke
conventions against the model's priors; the event-driven kernel for
eventual initiation).

---

## Task 13 — Automate code and security review in CI

**Slug:** `feat/automated-review-ci`

**Why:** Manual review is the gap. An agent that forgets `/cr`, or writes
the sentinel directly, ships unreviewed code — the anti-rationalization
table already lists "I'll write `.cr-ok` directly" as a lie it has to
pre-empt, which means the gate is forgeable by construction. The harness's
own principle says the only un-fakeable gate is a server-side re-run the
agent cannot touch (`docs/ci-gate.md`). Apply that principle to review
itself: run the review in CI, on the PR's exact head commit, and report it
as a status check. This both automates review (Cherny's Step 2 guardrail)
and closes survey gap G3 (the forgeable local sentinel).

**Boundary this preserves:** automated review SURFACES findings and can
mark the check failed on a MUST-FIX; it never merges and never approves.
The human merge stays the verdict (`docs/automation-loop-target-state.md`).
Automated review is quality back-pressure, not the verdict.

**Human-owned config (call these out at the top of the PR; you cannot do
them yourself):**

1. Add an Anthropic API key (or Bedrock/Vertex credential) as a CI secret
   named `ANTHROPIC_API_KEY`. Why only the human: agents must never handle
   raw credentials (`SOUL.md` destructive-op / credential rule), and secrets
   are set in GitHub settings, not in the repo.
2. After the check is green on a test PR, add the review status check to the
   `main` branch protection rule (same place as Task 1) so a MUST-FIX
   failure blocks the merge button.

**Files:**

- `.github/workflows/review.yml` — NEW workflow (agent-committable; it is a
  new file, not a protected hook). Runs on `pull_request`.
- `scripts/ci-review.sh` — NEW (agent-committable). The host-agnostic entry
  point the workflow calls, mirroring how `ci-verify.sh` is shared.
- `scripts/review-verdict.sh` — NEW. Parses the review output into a
  pass/fail exit code (fail only on MUST-FIX / security findings).
- `tests/ci-review.test.sh`, `tests/review-verdict.test.sh` — NEW.
- `docs/ci-gate.md` — update: review now runs server-side too, not just the
  deterministic floor.

**Steps:**

1. Read `.github/workflows/ci.yml` and `scripts/ci-verify.sh` to mirror
   their host-agnostic structure (workflow installs deps, then calls one
   shared script).
2. Decide the review engine. Preferred: the official Claude Code GitHub
   Action (`anthropics/claude-code-action` or the current equivalent),
   which checks out the PR, runs a prompt against the diff, and can post
   comments. If that action is not approved for this org, the fallback is a
   plain step that installs the Claude Code CLI and runs the `/cr` skill
   headless against the diff. Record which engine was chosen and why in a
   comment at the top of `review.yml` (this is a build-vs-buy call —
   `/evaluate-solution` is the skill for it if the choice is non-obvious).
3. Write `scripts/ci-review.sh`: computes the PR diff
   (`git diff origin/$BASE...HEAD`), invokes the review engine with the
   harness's review prompt (reuse the `/cr` pass list and the
   `@security-reviewer` scope triggers so CI review and local `/cr` apply
   the same standard), and writes findings to a file in a stable format
   (JSON lines: `severity`, `file`, `line`, `summary`).
4. Write `scripts/review-verdict.sh <findings-file>`: exit 1 if any finding
   has severity `must-fix` or `security`; exit 0 otherwise (advisory
   findings surface as comments but do not block). Print a one-line summary.
5. Write `review.yml`: on `pull_request` to `main`, check out with full
   history, install deps, run `ci-review.sh`, post the findings as a PR
   review or comment, then run `review-verdict.sh` so the job's exit status
   becomes the status check. Pass the diff via files/env, never by
   interpolating PR text into a shell string (injection safety — mirror the
   Task 2 CI job).
6. Reconcile with the local sentinel: local `/cr` stays as fast pre-push
   feedback, but CI review is now the enforcement. Update `docs/ci-gate.md`
   to say the sentinel is a convenience certificate and the server-side
   review is the gate. Do NOT remove `/cr` or the sentinel — they give the
   agent a fast local signal before CI.
7. Tests: `review-verdict.sh` returns 1 on a must-fix fixture, 1 on a
   security fixture, 0 on advisory-only, 0 on empty. `ci-review.sh` diff
   assembly is testable with a fixture repo even if the engine call itself
   is stubbed (inject the engine command via an env var so the test can
   substitute a fake that emits canned findings).

**Acceptance:** opening a PR triggers a review job that posts findings and
sets a status check; a seeded MUST-FIX makes the check red; after the human
adds branch protection, that red check blocks the merge button; `npm test`
passes. Local `/cr` still works unchanged.

**Out of scope:** replacing the human merge; auto-fixing findings in CI
(surfacing is enough — fixes stay on the authoring branch under the normal
pipeline); changing `.husky/*`.

---

## Task 14 — Priors audit ritual

**Slug:** `feat/priors-audit`

**Why:** The Ambiance principle: the model's priors are the cheapest
resource you have, so a rule the model already knows (from standard idioms)
costs less to follow than a bespoke convention it must be taught every
session. This harness has invented several bespoke conventions (questions.md
entry types, work-state markers, sentinel formats, custom labels). Some are
worth their cost; some duplicate an idiom the model has strong priors on
(exit codes, conventional-commit types, standard TODO/FIXME markers, GitHub
issue labels). A periodic audit asks, per convention, "does a standard idiom
carry this rule with less instruction?" and recommends keep or replace.

**Files (all agent-committable):**

- `.claude/skills/priors-audit/SKILL.md` — NEW.
- Add to the weekly ritual list next to `/scan-context`.

**Steps:**

1. Read `scripts/skill-frontmatter-lint.sh` for the frontmatter a skill
   needs, and `.claude/skills/scan-context/SKILL.md` for structure and
   voice.
2. Write the skill. Procedure:
   a. Inventory the harness's bespoke conventions: grep the docs and skills
      for invented vocabularies (questions.md entry types, work-state
      markers like `[~]`, sentinel formats, custom status strings).
   b. For each, ask: is there a standard idiom the model already knows that
      would carry the same meaning (conventional-commit types, exit-code
      conventions, `TODO(owner):`, GitHub reserved labels, HTTP-style status
      words)? Would swapping to it reduce the instruction the harness must
      give, without losing a distinction the bespoke form needs?
   c. Output a report: each convention, keep-or-replace recommendation, and
      the one-line reason. Recommendations only — the skill applies nothing;
      real changes go through `/refactor` or `/feature` as normal PRs.
   d. Record a standing constraint the audit enforces going forward: harness
      state stays flat text (files, logs, docs) — no databases, no opaque
      binary state — because plain text is the interface the model has
      home-court advantage on.
3. Add the ritual to the weekly cadence docs.

**Acceptance:** running `/priors-audit` produces a keep-or-replace report
over the harness's bespoke conventions and changes no files by itself.

---

## Task 15 — Event-driven initiation (Phase 5 design sketch)

**Slug:** `docs/event-driven-initiation-sketch` (docs only — no
implementation in this task)

**Why:** Cherny's Step 3→4 ("let Claude kick off Claude"; monitor by
exception) and Ambiance's kernel (an event bus that wakes the model and
constructs the minimal right context; no polling) point at the same next
step: work that starts from an event, not a human typing. The harness has
deliberately deferred this (BUILD-PLAN Phase 5) and already has a target
scorecard (`docs/automation-loop-target-state.md`). This task does NOT build
it — it writes the design sketch so the eventual build has a spec, and so
nothing in Tasks 1–13 accidentally blocks it.

**Hard gate:** do not implement initiation until Tasks 1–13 are done and the
loop has earned trust. The Step 3 trap named in Cherny's table is scaling
agent count before the loop is trusted; the survey's caution is the same.
Initiation is the last capability added, and the human merge boundary
(`docs/automation-loop-target-state.md`: "unattended up to the merge, never
past it") and the money+DB-stay-human rule (`BUILD-PLAN.md`) are never
removed to get it.

**Deliverable:** a new doc `docs/design/event-driven-initiation.md` that
specifies, grounding each section in the matching row of
`docs/automation-loop-target-state.md`:

1. **The front door.** A signed, validated, replay-protected webhook (e.g.
   a tracker issue assigned to the agent) that starts a run, plus a
   scheduled backstop that re-scans for dropped events. Follow the kernel
   principle: the event carries or constructs the minimal context the run
   needs (the issue body, the relevant PITFALLS shard, the routing type) —
   not a generic "go look at the tracker" prompt. No polling as the primary
   path; the backstop is the safety net, with a fire budget that cannot be
   silently burned.
2. **The claim state machine.** Todo → In Progress → In Review → Done, with
   dedup so two runs cannot claim one issue, and release-on-fail so a stuck
   claim does not wedge.
3. **Monitor by exception.** Every end-state notifies (PR-ready, blocked,
   hard-fail); nothing fails silently. One clear notification per PR, at the
   right noise level.
4. **What stays human, always.** The merge; money and database changes; any
   destructive operation. State these as non-removable.
5. **What must not be architected away now.** List the seams Tasks 1–13
   must keep open so initiation slots in cleanly (the pipeline stays
   summonable head-lessly; state lives in the tracker; the journal from
   Task 8 already records trigger source).

This task writes only the doc. Building any part of it is future work, each
piece with its own `/feature` run and its own human-owned trust decision.

**Acceptance:** `docs/design/event-driven-initiation.md` exists, each
section cites the target-state row it implements, and the "stays human" and
"do not block" sections are explicit. No behavior changes.

---

# Phase 4 — the loop era (safe automation)

Background for Tasks 16–18. The Loop Engineering reference
(cobusgreyling/loop-engineering) catalogs the scheduled loops that prompt
agents instead of a human prompting them: "You should be designing loops
that prompt your agents." That is precisely this harness's deferred Phase 5.
Most of what the reference scores as "loop readiness" the harness already
has and enforces harder — worktree isolation, the maker/checker split
(implementer vs. reviewer/lens agents), guard-file governance, skills as
persistent context. Three things it does not have: a named autonomy ladder
per loop, a spend circuit breaker, and a catalog of which maintenance loops
to run. These tasks add those. The reference's central warning is the same
one the whole plan is built around: "Verification is still on you.
Unattended loops make unattended mistakes."

---

## Task 16 — Autonomy-level taxonomy (L1/L2/L3)

**Slug:** `feat/autonomy-levels`

**Why:** The harness has an implicit autonomy boundary (money and database
changes stay human; the human merges) but no per-task label for how much a
given automated job may do on its own. The Loop Engineering ladder is a
clean formalism worth adopting: every routine, loop, or pipeline declares
its level, and the level mechanically bounds what it may do.

- **L1 — report only.** Discovers, triages, proposes. Writes no code, opens
  no PR, changes no state. (Example: a triage scan that labels issues.)
- **L2 — assisted.** Implements within a declared scope (patch-only, or a
  path allowlist) and opens a PR; a human reviews before merge. Never
  merges.
- **L3 — unattended.** Runs the full pipeline to an open PR without a human
  in the loop, after governance gates pass. Still never merges — the human
  merge boundary is above L3, not inside it.

**Non-removable rule at every level:** money, database changes, and
destructive operations stay human regardless of level (`SOUL.md`,
`BUILD-PLAN.md`). The level caps the ceiling; it never lifts these floors.

**Files (all agent-committable):**

- `docs/engineering-system/autonomy-levels.md` — NEW: defines the three
  levels, the non-removable floor, and how a job declares its level.
- `.claude/agent-contract.md` is PROTECTED — do not edit it. Instead put the
  contract addition (every spawned job states its autonomy level in its
  summary) in the new doc and hand the one-paragraph contract edit to the
  human via the Rule 7 handoff.
- `docs/automation-loop-target-state.md` — add the level to each pipeline
  step that will eventually run unattended.

**Steps:**

1. Write the taxonomy doc: the three levels, the floor, worked examples
   mapping existing harness work to a level (e.g. `/scan-context` is L1,
   `/queue` building a task to an open PR is L3-shaped but human-started
   today).
2. Define the declaration convention: a routine/loop names its level in its
   config or front matter; a spawned agent states its level in the summary.
3. Prepare the Rule 7 handoff for the one-paragraph addition to
   `.claude/agent-contract.md` (agents declare their level).

**Acceptance:** the taxonomy doc exists with the floor stated as
non-removable and existing work mapped to levels; the contract edit is
handed to the human. No behavior changes yet — this is the vocabulary the
loop tasks below build on.

---

## Task 17 — Maintenance-loop catalog and collision rules

**Slug:** `docs/maintenance-loop-catalog` (docs only)

**Why:** Cherny's Step 3 unlock is "maintenance and cleanup that used to
wait now runs continuously in the background." The Loop Engineering
reference names seven concrete loops. Several are low-autonomy (L1) and safe
to pilot before full initiation. This task writes the menu — it builds no
loop — so Phase 5 has a ranked list instead of a blank page, and so the
collision risks are written down before two loops ever run at once.

**Deliverable:** `docs/design/maintenance-loop-catalog.md` containing:

1. **The catalog.** For each candidate loop, a row: purpose, autonomy level
   (Task 16), suggested cadence, rough token cost, and which existing
   harness skill it would drive. Start from the reference's seven and keep
   only those that fit a solo-operator harness:
   - Dependency Sweeper (L2, patch-only) — drives `/feature` Tiny on a
     pinned patch bump.
   - Post-Merge Cleanup (L1) — dead-code / stale-reference scan, proposes
     only.
   - Changelog Drafter (L1) — drafts release notes from commits.
   - Issue Triage (L1) — labels and routes incoming issues, proposes only.
   - CI Sweeper (L2) — attempts a fix on a red CI check; high token cost,
     flag it.
   - PR Babysitter (L1) — you already have this via `subscribe_pr_activity`;
     note it as built.
2. **The L1-safe pilot subset.** Mark which loops are report-only and could
   run first with the least risk. These are the ones to switch on before the
   full front door exists.
3. **Multi-loop collision rules.** Worktree isolation prevents file-level
   collisions but not semantic ones: one loop opens a PR while another's
   post-merge cleanup fires on it; two loops label the same issue; a sweeper
   re-triggers on its own commit. State the rules — one writer per resource,
   loops read each other's state before acting, a loop never acts on a
   change it authored — and cite the journal (Task 8) as the shared state
   loops check.
4. **Per loop: the gate it must pass before running unattended.** Tie each
   to its autonomy level and to the spend cap (Task 18).

Building any loop is future work; this task only writes the menu.

**Acceptance:** the catalog exists, every entry carries an autonomy level
and cadence, the L1-safe subset is marked, and the collision rules are
explicit. No behavior changes.

---

## Task 18 — Per-run spend circuit breaker and cost estimate

**Slug:** `feat/spend-circuit-breaker`

**Why:** The reference's top failure mode is token explosion: "Sub-agents
and extended runs consume tokens non-linearly." BUILD-PLAN Phase 5 already
lists a "fleet circuit breaker" as deferred. No loop should run unattended
without a hard spend cap that halts it mid-run and a way to estimate cost
before switching it on. This is the safety mechanism that gates the whole
loop era — build it before any L2/L3 loop runs.

**Files (all agent-committable):**

- `scripts/loop-budget.sh` — NEW: reads a per-run spend ledger and exits
  non-zero when spend crosses the cap (the circuit breaker).
- `scripts/loop-cost-estimate.sh` — NEW: given a pattern and cadence, prints
  a rough monthly token/run estimate.
- `docs/design/loop-safety.md` — NEW: the kill-switch protocol and how a
  loop wires the breaker in.
- `tests/loop-budget.test.sh`, `tests/loop-cost-estimate.test.sh` — NEW.

**Steps:**

1. Define the ledger format: a JSON-lines file (flat text — the harness's
   standing constraint) where each run appends `ts`, `loop`, `tokens`,
   `usd_estimate`. Reuse the `.claude/activity/` location and the journal
   conventions from Task 8.
2. Write `scripts/loop-budget.sh <ledger> <cap>`: sums spend in the current
   window, exits 1 with a clear halt message when it meets or exceeds the
   cap, exits 0 otherwise. A loop calls this between steps; a non-zero exit
   is the kill switch. It must fail closed — if the ledger is unreadable or
   the cap is unset, halt (exit 1), never run on.
3. Write `scripts/loop-cost-estimate.sh --pattern <p> --cadence <c>`: a
   simple table lookup (per-run token estimate × runs-per-month for the
   cadence) printing a monthly range. Honest and rough; label it an
   estimate. Do not fabricate precision the harness cannot measure.
4. Write `docs/design/loop-safety.md`: the kill-switch protocol (breaker
   trips → loop halts → notifies, never silently), the fail-closed rule, and
   how each catalog loop (Task 17) wires the breaker between steps.
5. Tests: breaker exits 1 at and above the cap, 0 below, 1 on unreadable
   ledger or missing cap (fail-closed); estimator returns a non-empty range
   for each known pattern and errors clearly on an unknown one.

**Acceptance:** `loop-budget.sh` halts fail-closed at the cap; the estimator
prints a labeled monthly range per pattern; `loop-safety.md` documents the
kill switch; `npm test` passes. No loop is switched on by this task — it
builds the safety floor loops require.

---

# Phase 5 — the skill ecosystem

Background for Tasks 19–20. Addy Osmani's agent-skills library ships 24
skills across the dev lifecycle (define → plan → build → verify → review →
ship). This harness covers the same ground and enforces more of it than that
library scores — TDD is a gate here, review is nine passes plus adversarial
lenses, git discipline is hook-enforced. The two things that library does
uniformly and this harness does unevenly: every one of its skills carries a
"Rationalizations" section (the excuses an agent uses to skip a step, each
with a rebuttal) and ends with an "Evidence" footer (the proof required to
call the skill done). In this harness only 12 of 31 skills have the first
and only 7 of 31 have the second. Task 19 closes that gap and makes it a
lint. Task 20 adds the few skills the harness genuinely lacks.

---

## Task 19 — Standardize the skill contract (rationalizations + evidence)

**Slug:** `feat/skill-contract-standard`

**Why:** The harness already has both ideas — a central
`docs/engineering-system/12-anti-rationalization.md` and a `verify` skill —
but applies them unevenly across its own skills. Coverage today: 12 of 31
skills carry a rationalizations section, 7 of 31 carry an evidence section.
The anti-rationalization doc's own principle is that the rebuttal must sit
at the step most likely to be skipped, inside the skill — a central doc no
one opens at the moment of temptation does not stop the shortcut. Making
both sections a required, linted part of every skill is the fix, and it
matches the harness's "mechanical enforcement" philosophy.

**Files:**

- `docs/engineering-system/skill-validation.md` — extend: define the two
  required sections and what a good one looks like (agent-committable).
- `scripts/skill-contract-lint.sh` — NEW (agent-committable). Checks a
  staged SKILL.md for both sections. Do NOT edit
  `scripts/skill-frontmatter-lint.sh` if it is wired as a gate; a new script
  avoids touching gate machinery.
- `.husky/pre-commit` — PROTECTED. One added line to call the new lint on
  staged skills. Human commits (Rule 7).
- The skills missing a section — agent-committable, backfilled in batches.
- `tests/skill-contract-lint.test.sh` — NEW.

**Steps:**

1. Define the contract in `skill-validation.md`:
   - **Rationalizations section:** at least one excuse→rebuttal pair,
     placed at (or referencing) the step most likely to be skipped. Phrase
     rebuttals as the anti-rationalization doc does — the plain reason the
     step matters, not a scolding.
   - **Evidence section:** a short, explicit list of what proves the skill
     is done (tests passing, build output, the specific artifact). "Seems
     right" is never evidence. This is the skill-level echo of the Task 2
     accountability contract.
2. Write `scripts/skill-contract-lint.sh <file...>`: for each staged
   SKILL.md, exit 1 if either section is missing, naming which. Keep it a
   simple header/keyword check (look for a `Rationalizations`/`Excuses`
   heading and an `Evidence`/`Proof to finish` heading). Exit 0 when both
   present.
3. Backfill the missing skills in small, reviewable batches (not one giant
   commit). For each, add the two sections in the skill's own voice — do not
   paste a boilerplate block; the excuse and the evidence are specific to
   what that skill does. Skills that genuinely have no skippable step still
   get a one-line evidence footer.
4. Prepare the protected one-line `.husky/pre-commit` wiring via Rule 7 so
   new skills cannot land without the contract.
5. Tests: a SKILL.md with both sections passes; missing either fails and
   names it; the backfilled skills all pass.

**Acceptance:** every `.claude/skills/*/SKILL.md` has both sections; the new
lint passes on all of them; the hook wiring is handed to the human; `npm
test` passes.

**Out of scope:** rewriting skill logic; touching the frontmatter lint or
other gate scripts.

---

## Task 20 — Fill the thin-spot skills

**Slug:** `feat/thin-spot-skills`

**Why:** Compared against the agent-skills library, the harness is at parity
or ahead on about 20 of 24 skills. A few have no harness equivalent. The
clearest is deprecation-and-migration: removing or migrating code is normal
work and also the first Phase 4 loop domain (Task 17), yet the harness has
`/refactor` (structure-preserving moves) and nothing for behavior-changing
migrations and planned removals. Add that skill first; treat the others as
optional.

**Files (all agent-committable — new skills are not protected):**

- `.claude/skills/migrate/SKILL.md` — NEW. Use `/write-a-skill` to scaffold
  it so it satisfies the skill contract from Task 19 on day one.

**Steps:**

1. Invoke `/write-a-skill` to create a `migrate` skill: plan a migration or
   deprecation as a code-as-liability exercise — inventory call sites, add
   the new path behind a flag, migrate incrementally with a test per slice,
   remove the old path last, and record the decision as an ADR
   (`docs/adr/`). It routes through `/behavior-change` or `/feature` for the
   actual edits; the skill is the migration playbook, not a new edit path.
2. Ensure it ships with the Task 19 contract sections (rationalizations:
   "I'll delete the old path now and fix callers after" → why big-bang
   removal breaks callers; evidence: all call sites migrated, old path gone,
   tests green).
3. Note for the human (do not build without a decision): the other thin
   spots are lower priority and partly project-specific — an
   `observability` skill (structured logging, RED metrics, OpenTelemetry)
   belongs to the project the harness builds, not the harness itself, and
   overlaps Tasks 8 and 12; a `source-driven` discipline (ground framework
   choices in official docs) is partly covered by `/spike` and the
   `claude-api` skill. Add these only if a real need appears.

**Acceptance:** a `migrate` skill exists, passes the Task 19 contract lint,
and routes edits through the existing behavior-change/feature paths; the
other candidates are recorded as optional, not built speculatively.

---

## Definition of done for the whole plan

1. CI blocks merges on `main` (Task 1) — verified by a deliberately red PR.
2. Every PR carries an accountability contract with a non-empty Why, checked
   in CI (Tasks 2, 6).
3. Both push paths — human and agent — validate the `/cr` sentinel (Task 3).
4. Sentinel audit lines and permission logs survive the session and travel
   with the PR (Task 4).
5. Session end proposes memory.md candidates; humans remain the only writers
   of memory.md (Task 5).
6. Remote sessions have a documented, gate-preserving lane and never need
   `--no-verify` (Task 7).
7. Gate rejections and session outcomes leave durable traces (Task 8), a
   periodic ritual mines them into evidence-backed proposals (Task 9), no
   harness script changes without a test or a stated reason (Task 10), and
   findings carry the model that produced them (Task 11).
8. Every PR answers "would we have built this anyway, and at what manual
   cost?" and the dashboard reports return, not just activity (Task 12).
9. Code and security review run automatically in CI on every PR and can
   block on a MUST-FIX, with the human merge still the verdict (Task 13).
10. A ritual audits bespoke conventions against the model's priors (Task
    14), and the event-driven initiation design is specified but not built
    until the loop has earned trust (Task 15).
11. Every automated job declares an autonomy level (L1/L2/L3) with money,
    database, and destructive changes staying human at every level (Task
    16); the maintenance loops are catalogued with collision rules and an
    L1-safe pilot subset (Task 17); and no loop runs without a fail-closed
    spend circuit breaker and a pre-run cost estimate (Task 18).
12. Every skill carries a rationalizations section and an evidence footer,
    lint-enforced (Task 19), and the clearest missing skill (migration) is
    added to the library (Task 20).
