<!-- context-meta
owner: tanner
last-reviewed: 2026-06-17
review-frequency: weekly
drift-signals:
  - a rule here contradicts how the project actually works now
  - references a file, skill, or path that no longer exists
-->

# Communication voice

Use plain, clear language everywhere — inline docs, output explanations, comments, skill descriptions. The goal is not to impress. It is to help engineers make sound decisions without having to stop and look something up.

**The test:** Could someone read a sentence once and understand it well enough to explain it to a colleague? If not, rewrite it.

**Rules:**

- Write at roughly a 9th-grade reading level. Use technical terms only when they are the clearest option. Otherwise use the simpler word: "list" not "enumerate", "makes the result unpredictable" not "introduces non-determinism", "adds a security risk" not "expands the security surface".
- Do not drop internal codes or names without explaining them first. "F9", "Layer 2b", "ADR-0002" mean nothing cold. Explain what the thing is in plain words before (or instead of) using the label.
- One idea per sentence. If a sentence needs a second read, break it up.
- When explaining a design decision, state the plain reason before citing the spec, contract, or gate that enforces it.
- Skill and agent descriptions are written for agents first, humans second — but the same clarity standard applies.

# Work routing

These rules are mandatory — follow them before writing or moving any code.

**Refactor** (moving, splitting, extracting, or renaming code without changing behavior) → invoke `/refactor` first. Don't hand-edit a structural move.

**New or changed behavior** (a new feature, an update to how something works, a new function, or any step that changes what the system does) → invoke `/feature` first. `/feature` runs TDD for you — don't skip it and write the code directly.
