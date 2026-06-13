#!/usr/bin/env bash
# Smoke test: the core harness machinery is present and executable. This fails loud
# in a fresh worktree or after an accidental deletion — the gates are the safety net,
# so their absence must not be silent.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

fail=0
note() { echo "  MISSING: $1" >&2; fail=1; }

# Executable hooks (the deterministic floor).
for h in block-dangerous-bash block-credential-read block-egress block-dangerous-git block-npm-install worktree-create permission-logger session-start; do
  [ -x ".claude/hooks/$h.sh" ] || note ".claude/hooks/$h.sh (executable)"
done

# Executable scripts.
for s in worktree-add assert-husky-shim pr detect-forge check-routing gc test-local lint run-tests ci-verify; do
  [ -x "scripts/$s.sh" ] || note "scripts/$s.sh (executable)"
done

# The full universal skill roster (Step 0 migration). grill-with-docs is the vendored
# Matt Pocock skill; the rest are the harness's universal core.
for sk in queue cr cr-security feature tdd refactor debug compound grill-with-docs \
          incident hotfix post-mortem migrate behavior-change perf spike \
          prioritize-tasks review-strategy setup-strategy design evaluate-solution; do
  [ -f ".claude/skills/$sk/SKILL.md" ] || note ".claude/skills/$sk/SKILL.md"
done

# Phase 1: the governance & canon pass must remain in /cr.
grep -q 'Governance & Canon' .claude/skills/cr/SKILL.md || note "/cr governance & canon pass"

# The full agent roster (all 23 — Step 0 migration). reviewer + the 4 isolated lenses
# are load-bearing for /cr; the rest cover incident/security/refactor/eval/docs/ux/spike.
for a in reviewer lens-assumption lens-composition lens-cascade lens-abuse \
         task-runner implementer spec-writer explorer investigator hotfix-guard \
         incident-responder security-reviewer refactor-extractor solution-evaluator \
         doc-updater ux-reviewer \
         spike-orchestrator spike-researcher spike-slice spike-synthesis \
         spike-adversarial-verifier spike-user-verifier; do
  [ -f ".claude/agents/$a.md" ] || note ".claude/agents/$a.md"
done

# The agent contract the orchestrator + task-runner depend on.
[ -f ".claude/agent-contract.md" ] || note ".claude/agent-contract.md"

# Husky pre-push gate wiring (the un-forgeable-gate precursor).
[ -f ".husky/pre-push" ] || note ".husky/pre-push"

# No project-specific stack terms must leak back into the portable core.
if grep -rilE 'supabase|event-vendor|moodboard' .claude/skills .claude/agents .claude/hooks scripts 2>/dev/null | grep -q .; then
  echo "  LEAK: project-specific term found in portable core (run the grep to locate)" >&2
  fail=1
fi

[ "$fail" = 0 ] && echo "harness-smoke: OK"
exit "$fail"
