# F6 — the un-forgeable finish line (the CI verdict gate)

**What it is (plain):** when a PR is opened, a separate computer you control — not the robot's
laptop — re-runs the checks (lint + tests) on the *exact* code in the PR, and the merge button is
blocked unless they pass. The robot's "I reviewed it" is an *opinion*; this re-run is a *fact* it
can't fake. That's what lets you stop reading every line.

**Why the local pre-push hook isn't enough:** it runs on the robot's own machine, so it's
forgeable — the agent can skip it (`git push --no-verify`), the husky shim can silently go missing
in a worktree, or the agent can write the `.cr-ok` sentinel directly. The server-side re-run is the
one guarantee that can't be bypassed. (This is the "simple half" of F6; the independent review
established that the sentinel-tied-to-SHA "fancy half" wasn't buildable and isn't needed while a
human merges everything — revisit only if auto-merge ships.)

## Host-agnostic by construction

The harness is project-agnostic, so F6 works the same on GitHub and GitLab. Both CI configs call
the **same** script — `scripts/ci-verify.sh` — so the check is byte-identical across hosts. Add a
step there (e.g. a typecheck, or later the bug-catch gate) and every host stays in sync.

| | GitHub | GitLab |
|---|---|---|
| CI config | `.github/workflows/ci.yml` | `.gitlab-ci.yml` |
| Runs | `npm ci` → `bash scripts/ci-verify.sh` | *same* |
| Term for a PR | Pull Request | Merge Request |
| **Make it block the merge** (human step) | Settings → Branches → protect `main` → "Require status checks" → select `verify` | Settings → Merge requests → "Pipelines must succeed" |

A project drops in the one config for its host and flips the one toggle. Both files ship; neither
assumes a host.

## The gate is two parts

1. **The check runs** (automatic, in the repo) — the CI config + `ci-verify.sh`. Built here.
2. **The merge blocks on red** (one-time human step) — branch protection (GitHub) / "Pipelines must
   succeed" (GitLab). A human owns the merge boundary, so a human turns this on.

Until step 2 is set, CI runs and reports but does not *block* — it's advisory. With it set, red CI
makes the merge button unavailable.

## Honest limit

The CI config lives in the repo, so the agent could edit it to weaken the check (e.g. make the test
step always pass). Two things contain that: a change to `ci-verify.sh` or the CI config **shows in
the PR diff**, which the human reviews before merging; and for stronger protection you can restrict
who may edit CI files (GitHub: CODEOWNERS on `.github/`; GitLab: protected paths / approval rules).
The gate defends against a forgetful or buggy agent, not a malicious human with merge rights.
