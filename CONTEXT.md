# Agent Harness

A project-agnostic harness of skills, sub-agents, hooks, and lint gates that install into any repo
and gate code from write to merge.

## Language

**deploy-targets manifest**:
A YAML file (`deploy-targets.yml`) that lists every deploy step a project requires beyond code — migrations, secrets, feature-flag flips, infra applies. The harness reads this file to verify each step is gated.
_Avoid_: deploy config, deploy list, targets file

**drift_check**:
A shell command declared in a manifest entry that exits non-zero when the step has pending changes that have not been applied to the target environment. It proves a step was applied; it does not apply it.
_Avoid_: check command, verification command, gate command

**deploy-drift gate**:
The CI check that reads the deploy-targets manifest and fails when any required entry is missing a drift_check. Runs as a step in `scripts/ci-verify.sh`. Deterministic and credential-free — it checks the manifest, not the live target.
_Avoid_: drift check, deploy gate, manifest check

**required** (manifest entry field):
A per-entry flag (`required: true/false`, default `true`) that controls whether a missing drift_check blocks CI (`true`) or only prints a warning (`false`). Teams opt into advisory behavior by setting `required: false`.
_Avoid_: blocking, severity, enforce

## Relationships

- A **deploy-targets manifest** contains one or more entries, each with a **drift_check**
- The **deploy-drift gate** reads the **deploy-targets manifest** and checks for missing **drift_check** values
- An entry with `required: true` and no **drift_check** causes the **deploy-drift gate** to block CI
- An entry with `required: false` and no **drift_check** causes the **deploy-drift gate** to warn only

## Example dialogue

> **Dev:** "Do I need a drift_check for every entry in the manifest?"
> **Domain expert:** "Yes — unless you set `required: false` on that entry. With `required: false`, a missing drift_check prints a warning but CI still passes. Without it, CI blocks."

> **Dev:** "What if I don't have a deploy-targets manifest at all?"
> **Domain expert:** "CI passes silently. The manifest is opt-in — you only get the gate once you declare deploy targets."
