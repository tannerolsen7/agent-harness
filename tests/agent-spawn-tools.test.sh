#!/usr/bin/env bash
# Spawn-wiring regression: any agent whose body instructs it to spawn or sequence
# sub-agents must declare the Task tool in its frontmatter. Prevents the class of
# defect where reviewer.md said "four agent tool calls" but tools: Read,Glob had no
# Task — the agent physically cannot spawn and silently falls back to one context.
#
# Detection heuristic (body of each agent file):
#   "Spawn[s] " at line start → orchestrator-style spawn (reviewer, spike-orchestrator)
#   "Invoke @<name>"          → pipeline-style sequencing (task-runner)
# These two patterns cover every known spawner and are hard to produce accidentally in
# a non-spawner. "Spawned by @..." (passive, non-instruction) does NOT match.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
AGENTS_DIR="$ROOT/.claude/agents"
[ -d "$AGENTS_DIR" ] || { echo "agent-spawn-tools.test: $AGENTS_DIR not found"; exit 1; }

pass=0; fail=0

for f in "$AGENTS_DIR"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)

  # Detect spawner: line-starting "Spawn[s] " or "Invoke @<name>" anywhere in file.
  # Line-start anchor prevents false positives like "Before spawning" / "Do not spawn".
  if grep -qE "^[[:space:]]*Spawn[s]? |Invoke @[a-z]" "$f" 2>/dev/null; then
    tools=$(awk '/^---/{d++;next} d==1 && /^tools:/{sub(/^tools:[[:space:]]*/,""); print; exit}' "$f")
    # Wrap in commas for exact token matching (avoids "TaskFoo" matching "Task")
    if echo ",$tools," | grep -q ',Task,'; then
      pass=$((pass+1))
    else
      fail=$((fail+1))
      echo "  FAIL: $name spawns sub-agents but tools='$tools' (missing Task)"
      echo "        .claude/agents/$name.md is a guard file — human edit required"
      echo "        Fix: add Task to tools: in the frontmatter"
    fi
  fi
done

echo ""
echo "agent-spawn-tools: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
