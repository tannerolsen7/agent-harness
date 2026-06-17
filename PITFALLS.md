# PITFALLS

Known traps in this codebase. Each entry is a real incident, not a speculation.
Check this file before any `/cr` pass. If you see a pattern here in a diff, flag it MUST FIX.

---

## Agent orchestrators — Task tool and permissionMode are both required for spawning

**Area:** Agent system (`.claude/agents/*.md` frontmatter)

**Rule:** Any orchestrator agent must have `Task` in `tools:` AND `permissionMode: default` or `auto`. Both conditions are independently required. Either missing alone breaks spawning completely.

**Why:** Without `Task`, the agent has no spawn mechanism. With `permissionMode: plan`, all action invocations including spawning are blocked regardless of what's in `tools:`. The failure is silent — the agent falls back to running all sub-agents in one context, producing structurally correct output with no error or warning. You cannot detect the collapse from the output quality alone.

**Symptoms:** Orchestrator returns a consolidated report but no distinct agent tool calls appear in the conversation trace. Findings from "parallel" lenses look like one analysis dressed as multiple. The design's isolation guarantee never occurs.

**Source:** `docs/solutions/2026-06-15-orchestrator-task-tool-spawn-wiring.md`
**Regression gate:** `tests/agent-spawn-tools.test.sh` (bidirectional: spawners must have Task; Task holders must have a spawn instruction)

---

## Writing a sentinel directly to bypass a gate

**Area:** Sentinel system (`.claude/.cr-ok`, `.claude/.design-confirmed`)

**Rule:** Never write a sentinel file directly (via Write-tool, `printf >`, or any means other than the designated script). Writing it directly produces a file that passes the gate's string comparison while certifying work that was never done.

**Why:** The sentinel is an honor-system certificate, not a cryptographic proof. Its only integrity property is that `scripts/cr-ok.sh` and `scripts/design-confirm.sh` refuse dirty trees and self-resolve `branch:sha` — bypasses strip both guarantees. A hand-written `.cr-ok` certifies a review that never ran; a hand-written `.design-confirmed` certifies a design session that never happened. Both silently propagate false assurance through every downstream gate.

**Symptoms:** Gate passes without the corresponding gate script having been invoked; audit log is absent or shows no matching entry for the branch:sha.

**When the gate fires unexpectedly:** Fix the condition (run the gate, commit the artifacts, resolve the stale sha) — do not write the sentinel to get past it.
