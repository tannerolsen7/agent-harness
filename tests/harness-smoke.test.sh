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
for s in worktree-add assert-husky-shim pr cr-ok design-confirm detect-forge check-routing check-integrity gc test-local lint run-tests ci-verify install-locks update-progress; do
  [ -x "scripts/$s.sh" ] || note "scripts/$s.sh (executable)"
done

# The full universal skill roster (Step 0 migration). grill-with-docs is the vendored
# Matt Pocock skill; the rest are the harness's universal core.
for sk in queue cr cr-security feature tdd refactor debug compound grill-with-docs \
          incident hotfix post-mortem migrate behavior-change perf spike handoff \
          prioritize-tasks review-strategy setup-strategy design evaluate-solution; do
  [ -f ".claude/skills/$sk/SKILL.md" ] || note ".claude/skills/$sk/SKILL.md"
done

# Phase 1: the governance & canon pass must remain in /cr.
grep -q 'Governance & Canon' .claude/skills/cr/SKILL.md || note "/cr governance & canon pass"

# Vendored / adopted skills (mattpocock@SHA — see .claude/skills/VENDORED.md). simplify is a
# Claude Code built-in (not vendored).
for sk in to-issues prototype zoom-out triage to-prd write-a-skill; do
  [ -f ".claude/skills/$sk/SKILL.md" ] || note ".claude/skills/$sk/SKILL.md (vendored)"
done

# No empty stubs: every shipped skill must have a non-empty `description:` or it can never
# auto-invoke (it would be dead routing noise — the V1 triage/diagnose failure).
for f in .claude/skills/*/SKILL.md; do
  grep -qE '^description:[[:space:]]*\S' "$f" || note "$f has no non-empty description (dead routing stub)"
done

# Frontmatter must PARSE as YAML, or Claude Code warns + the skill may not auto-invoke — and the
# non-empty check above does NOT catch this (a non-empty but malformed description still loads dead).
# A plain `description:` scalar breaks when a continuation line is unindented, or when the value
# contains ": " or " #" (YAML reads those as structure). A `description: |` / `>` block scalar is
# immune. Assert each skill AND agent description is a block scalar, or a plain value with neither
# breaker. (Skills are agent-editable; agents are guard files — both are guarded so neither side
# can silently reintroduce an unparseable frontmatter that fails Claude Code's loader.)
for f in .claude/skills/*/SKILL.md .claude/agents/*.md; do
  risky=$(awk '
    NR==1 && $0=="---"{infm=1; next}
    infm && $0=="---"{exit}
    infm && /^description:[[:space:]]*[|>]/{blk=1; next}
    infm && /^description:/{d=1; v=$0; sub(/^description:[[:space:]]*/,"",v); next}
    infm && d && /^[a-zA-Z_][a-zA-Z0-9_-]*:[[:space:]]/{d=0}
    infm && d && $0=="---"{d=0}
    infm && d { if ($0 ~ /^[^[:space:]]/) c0=1; v=v" "$0 }
    END{ if(!blk && (c0 || v ~ /: / || v ~ / #/)) print "risky" }
  ' "$f")
  [ -n "$risky" ] && note "$f: unparseable plain description (unindented continuation or ': '/' #' in the value) — use a 'description: |' block scalar"
done

# Side-effect skills (irreversible external mutations — issue creation, PRD publish, migration,
# parallel PR open) must opt out of autonomous model invocation (R4-D8 / F9). Agents must never
# invoke these unprompted; only explicit user invocation is safe.
for sk in to-issues to-prd migrate queue; do
  grep -q '^disable-model-invocation: true' ".claude/skills/$sk/SKILL.md" \
    || note ".claude/skills/$sk/SKILL.md missing disable-model-invocation: true (R4-D8 / F9)"
done

# Forbidden skills: cut from V2 and must stay out. dep-update was an empty stub; notion-sync
# is obsolete under the Notion→GitHub canon move (canon lives in the repo — no sync-to-Notion).
for forbidden in notion-sync dep-update; do
  [ -e ".claude/skills/$forbidden" ] && note "forbidden skill present (cut from V2): $forbidden"
done

# The engineering-system canon (Step 0 Notion→GitHub migration) — the universal "what to build" docs.
for c in README 02-four-layers 03-file-structure 04-context-docs 07-memory-system \
         10-principles 11-skill-ecosystems 12-anti-rationalization 13-model-capacity-audit \
         14-git-discipline templates; do
  [ -f "docs/engineering-system/$c.md" ] || note "docs/engineering-system/$c.md (canon)"
done

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

# The queue-execute Workflow script — /queue Step 3 invokes it by path; absence breaks /queue silently.
[ -f ".claude/workflows/queue-execute.js" ] || note ".claude/workflows/queue-execute.js (required by /queue Step 3)"

# Husky pre-push gate wiring (the un-forgeable-gate precursor).
[ -f ".husky/pre-push" ] || note ".husky/pre-push"

# Husky v10-safe hooks: husky runs each hook under sh and v10 dropped both the shebang and the
# auto-sourced shim line. The real hazard is a bash-only construct used AS A GATE CONDITION
# (e.g. `[[ ! -f .cr-ok ]] && exit 1`): under sh the `[[` errors, the `&&` short-circuits, the
# `exit` never fires, and the gate falls through to "allowed" — a silent no-op. Assert each hook
# carries no shebang, no stale shim-source line, and none of the bash-only constructs the gate
# logic might use: here-string (`<<<`), double-bracket (`[[`), combined redirect (`&>`, which by
# substring also covers `&>>`), or `==` inside a single-bracket test (`[ x == y ]`). Patterns are
# anchored so the hooks' own comments don't trip them. (Syntax-error bashisms — arrays, `function`,
# `<(...)` — abort loudly under sh on CI rather than no-opping, so they're not enumerated here.)
# Also require a `# shellcheck shell=sh` directive: with the shebang gone, shellcheck has no shell
# hint and errors SC2148 in CI — and lint.sh skips shellcheck when it's absent locally, so the only
# way to catch this BEFORE CI is to assert the directive here (this runs with or without shellcheck).
for h in .husky/pre-commit .husky/pre-push .husky/post-checkout; do
  [ -f "$h" ] || { note "$h"; continue; }
  head -n 1 "$h" | grep -q '^#!' && note "$h has a shebang (husky v10 hooks run under sh — drop it)"
  grep -qE '^[[:space:]]*(\.|source)[[:space:]].*husky' "$h" && note "$h sources the removed husky v10 shim"
  grep -qE '<<<|\[\[|&>|\[[^]]*==' "$h" && note "$h uses a bash-only construct (fails silently under sh)"
  grep -q '^# shellcheck shell=sh' "$h" || note "$h missing '# shellcheck shell=sh' (CI shellcheck SC2148s a shebang-less hook without it)"
done

# No project-specific stack terms must leak back into the portable core.
if grep -rilE 'supabase|event-vendor|moodboard' .claude/skills .claude/agents .claude/hooks scripts 2>/dev/null | grep -q .; then
  echo "  LEAK: project-specific term found in portable core (run the grep to locate)" >&2
  fail=1
fi

[ "$fail" = 0 ] && echo "harness-smoke: OK"
exit "$fail"
