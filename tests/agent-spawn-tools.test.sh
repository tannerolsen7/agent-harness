#!/usr/bin/env bash
# Spawn-wiring regression: any agent whose body instructs it to spawn or sequence
# sub-agents must declare the Task tool in its frontmatter. Prevents the class of
# defect where reviewer.md said "four agent tool calls" but tools: Read,Glob had no
# Task — the agent physically cannot spawn and silently falls back to one context.
#
# Detection heuristic (both branches are line-start anchored):
#   "Spawn[s] " at line start → orchestrator-style spawn (reviewer, spike-orchestrator)
#   "Invoke @<name>" at line start → pipeline-style sequencing (task-runner)
# "Spawned by @..." (passive, non-instruction) does NOT match either branch.
#
# Bidirectional: also fails if an agent declares Task but has no detected spawn
# instruction — catches new idioms that slip past the heuristic before they hide.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "agent-spawn-tools.test: not in a git repo"; exit 1; }
AGENTS_DIR="$ROOT/.claude/agents"
[ -d "$AGENTS_DIR" ] || { echo "agent-spawn-tools.test: $AGENTS_DIR not found"; exit 1; }

pass=0; fail=0

for f in "$AGENTS_DIR"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)

  # Extract tools value; normalize bracket form ([Task, Read] → Task,Read) so
  # both comma-form and YAML flow-list formats are handled identically.
  tools=$(awk '/^---/{d++;next} d==1 && /^tools:/{sub(/^tools:[[:space:]]*/,""); print; exit}' "$f" \
          | tr -d '[] ')

  has_task=0
  echo ",$tools," | grep -q ',Task,' && has_task=1

  # Both alternatives anchored to line start — prevents matching passive mentions
  # like "Spawned by @reviewer" or documentation notes like "Do not Invoke @foo".
  has_spawn=0
  grep -qE "^[[:space:]]*(Spawn[s]? |Invoke @[a-z])" "$f" 2>/dev/null && has_spawn=1

  if [ "$has_spawn" -eq 1 ] && [ "$has_task" -eq 0 ]; then
    fail=$((fail+1))
    echo "  FAIL: $name spawns sub-agents but tools='$tools' (missing Task)"
    echo "        .claude/agents/$name.md is a guard file — human edit required"
    echo "        Fix: add Task to tools: in the frontmatter"
  elif [ "$has_task" -eq 1 ] && [ "$has_spawn" -eq 0 ]; then
    fail=$((fail+1))
    echo "  FAIL: $name declares Task but no spawn instruction detected"
    echo "        Either the spawn idiom is new (update heuristic) or Task is unneeded"
  elif [ "$has_spawn" -eq 1 ] && [ "$has_task" -eq 1 ]; then
    pass=$((pass+1))
  fi
done

echo ""
echo "agent-spawn-tools: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
