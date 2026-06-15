# Problem: Orchestrator Agent Silent Spawn Collapse

**Problem class:** An agent whose body instructs it to spawn sub-agents produces output even when it physically cannot spawn — it collapses all "parallel" work into one context, silently defeating isolation.

## When this bites you

You see output from your multi-agent pipeline. The reviewer or orchestrator returns a consolidated report. It looks like four lenses ran. Nothing errors.

What actually happened: the agent ran all four analyses in one context, cross-contaminating findings. The lens isolation that your design required — "no shared context between lenses" — never occurred. You get one agent's opinion dressed up as four independent ones.

The deceptive part: there is no error. No warning. No truncated output. The fallback behavior (running everything in one pass) produces structurally correct output. The defect is invisible unless you know to check the frontmatter of every orchestrator agent file.

## Root cause

Two independent blockers, both present in `reviewer.md` at the time of the fix:

**Blocker 1 — Missing `Task` in tools:** The `Task` tool is what grants an agent the capability to spawn sub-agents. Without it, the agent has no spawn mechanism. When the body says "Spawn @lens-assumption in parallel," the runtime has no tool to execute that instruction. Claude falls back to handling the work inline.

**Blocker 2 — `permissionMode: plan`:** This mode makes an agent read-only. It blocks all actions including spawning. Even if `Task` were present in `tools:`, `permissionMode: plan` would prevent it from being invoked. Both fields must be correct independently.

`task-runner.md` had Blocker 1 only: it was missing `Task` from its `tools:` list despite body instructions to `Invoke @explorer`, `Invoke @spec-writer`, etc.

## The fix

Two fields in the agent frontmatter must both be set correctly for any orchestrator agent:

```yaml
tools: Task,Read,...   # Task must appear; other tools as needed
permissionMode: default  # or auto — never plan for an orchestrator
```

Working reference: `.claude/agents/spike-orchestrator.md` had `tools: Task,Read,Write,Bash` and `permissionMode: default` before this fix landed.

The two agents that needed correction:

`.claude/agents/reviewer.md`:
- `tools: Read,Glob` → `tools: Task,Read,Glob`
- `permissionMode: plan` → `permissionMode: default`

`.claude/agents/task-runner.md`:
- `tools: Read,Edit,Bash,Glob,Grep` → `tools: Task,Read,Edit,Bash,Glob,Grep`
- `permissionMode: auto` was already correct; no change needed

## How to know it's working

After fixing the frontmatter, spawned agents will show up as distinct agent tool calls in the conversation trace — each lens appears as a separate invocation with its own context, not as inline reasoning blocks. You can verify by watching the tool use: a correctly wired `@reviewer` produces four `Task` tool calls in a single message before consolidating.

If you still see one monolithic analysis block with no agent invocations in the trace, the wiring is still broken.

## The regression gate

File: `tests/agent-spawn-tools.test.sh`

What it checks (bidirectional):
- Forward: if a `.claude/agents/*.md` body contains a line starting with `Spawn[s] ` or `Invoke @<name>`, then `Task` must appear in its `tools:` frontmatter field. Failure message: `"FAIL: $name spawns sub-agents but tools='...' (missing Task)"`
- Reverse: if `Task` appears in `tools:`, then the body must contain a detected spawn instruction. Failure message: `"FAIL: $name declares Task but no spawn instruction detected"` — catches agents that declare `Task` unnecessarily, which would signal a new spawn idiom slipping past the heuristic.

How to read a failure: the test prints the failing agent name, the current `tools=` value, and the fix instruction. A forward failure means an orchestrator lost its spawn capability. A reverse failure means a new spawn pattern was added without updating the heuristic.

Detection heuristic limitations: the regex anchors to line-start (`^[[:space:]]*`). Passive mentions like "Spawned by @reviewer" (describes callers, not spawn instructions) do not match. If a new spawn idiom is introduced that doesn't start with `Spawn` or `Invoke @`, the heuristic must be updated.

## The invariant (replicate this when adding new orchestrators)

Any `.claude/agents/*.md` file whose body instructs it to spawn or sequence other agents must declare `Task` in its `tools:` frontmatter AND set `permissionMode` to `default` or `auto` — never `plan`. These are two independent conditions; satisfying only one still breaks spawning. If you are unsure whether an agent orchestrates others, grep its body for lines starting with `Spawn` or `Invoke @` — if any match, both fields apply.

## What doesn't work

**Adding `Task` to tools while keeping `permissionMode: plan`:** This was the state `reviewer.md` would have been in if only one field had been fixed. The `Task` tool exists in the grant list but `plan` mode prevents all action invocations. Still broken, still silent.

**Relying on the description field or memory to catch this:** The description for `reviewer.md` said "Spawns four specialist lens agents in parallel" the entire time the defect was present. The description is prose, not enforcement. Only the frontmatter fields control runtime behavior.

**Inferring correctness from output quality:** A single-context collapse produces plausible-looking output. There is no output quality signal that distinguishes "four lenses ran in isolation" from "one context ran four analyses." The only reliable check is the frontmatter.

## Tags

agent-system, spawn, task-tool, permissionMode, orchestrator, regression-gate
