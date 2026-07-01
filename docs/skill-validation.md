# Skill Validation and Loop Classification

---

## Validating a skill: the cold session test

A skill that works in the session it was built in is not validated. When you write a skill from scratch, the conversation history carries context the skill itself does not contain. That context disappears the moment someone opens a new session. If the skill depends on it, it fails silently.

**A skill is verified when it one-shots the expected output in a fresh session with zero prior context.**

### Steps

1. **Do the task manually with the agent first.** Expect 15–20 prompts and about 2 hours. Go slow on purpose — this is where the skill gets tuned. Rushed manual passes produce skills that work once and never again.

2. **Tune until output quality is consistently right.** Run the same task a second and third time. If you have to correct the agent each time, the skill is not ready.

3. **Tell the agent to write the skill from everything you built together.** Ask it to capture every directive, constraint, and output format you discovered in the manual pass. Nothing implicit.

4. **Open a brand new Claude Code session.** No conversation history. Close the current session completely if you are unsure.

5. **Run the skill cold on the same input that took 2 hours manually.**

6. **If it one-shots the same quality output: you have a function, not a prompt.** Add it to the skills library, wrap it in a schedule, or hand it to another agent.

7. **If it does not: the skill is missing implicit context.** Go back to step 3 and make the gap explicit in the skill file.

> "Each verified skill becomes a Lego block. They accumulate.  
> You earn the ambitious loop by building verified functions first."  
> — Benji Koltai

---

## Loop type classification

Not all loops need the same oversight. Running a production code loop the same way you run a research loop is where quality debt starts.

### Research and exploration loops (lighter oversight)

These loops produce output that is either short-lived by design or mechanically verifiable against a ground truth. Human review is still valuable but not a gate.

| Type | Why it's safe to run lighter |
|------|------------------------------|
| Porting code (e.g. Zig → Rust) | Output is mechanically verifiable — tests pass or they don't |
| Performance benchmarking | Discard the artifacts; keep only the measurements |
| Security scanning | Produces findings, not lasting code |
| POC / prototype | Short shelf life is the design intent |
| Codebase analysis | Read-only; produces a report, not a change |

### Production code loops (full gate sequence required)

These loops produce output that will live in the codebase and be read by future agents and humans. Without oversight, each loop pass adds a little more complexity — a null check here, a fallback there — until the system "slowly becomes less understandable while appearing more robust." (See PITFALLS.md — defensive amplification.)

| Type | Why it needs the full gate |
|------|---------------------------|
| Writing or modifying features | Code persists; design decisions made silently are expensive to undo |
| Database migrations | Schema changes are the hardest thing to reverse |
| API contract changes | Breaking changes are invisible until something downstream fails |
| Any output that will stay in the repo | Future agents read this; quality compounds in both directions |

**Required sequence for production code loops:**

```
design contract → @design-griller → .design-confirmed → code → /cr → .cr-ok → human review
```

Skipping any step in this sequence is not a shortcut — it is deferred quality debt that the next session will pay, usually by having to reverse work.

### A simple heuristic

Ask: "If the output of this loop turns out to be wrong, how hard is it to throw away?"

- Easy to throw away → research loop, lighter oversight is fine
- Hard to throw away → production loop, run the full gate sequence
