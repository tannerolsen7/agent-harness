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

**plugin installation**:
What happens when a user runs `/plugin install agent-harness@agent-harness`. Claude Code downloads the harness repo to a managed directory and makes the plugin's skills, agents, and hooks available in every Claude Code session. This is the Claude Code side — it does not touch any project repo.
_Avoid_: installing the harness, setting up Claude Code, running install.sh

**per-project installation**:
What `/init` does. Copies harness-owned files (scripts, husky hooks, settings) into a specific project repo and creates `.claude/.harness-manifest.json`. Done once per project. Separate from plugin installation.
_Avoid_: installing the plugin, harness setup

**plugin dir** (`$CLAUDE_PLUGIN_ROOT`):
The directory where Claude Code put the plugin when the user ran `/plugin install`. Always available as the `$CLAUDE_PLUGIN_ROOT` environment variable in any Claude Code session where the plugin is loaded. The canonical source for all harness file updates — `install.sh` and `sync-harness.sh` both read from it.
_Avoid_: harness repo, local clone, source directory

**harness manifest** (`.claude/.harness-manifest.json`):
A JSON file written into each project by `install.sh` at per-project installation time. Records the path where the harness was installed from (`source`), the git SHA of the plugin at install time (`sha`), and the sha256 fingerprint of every installed file (`files`). Used by `sync-harness.sh` for three-way comparison and by the session-start sync check.
_Avoid_: manifest, config file, harness config

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
