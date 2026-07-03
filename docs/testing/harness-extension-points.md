## Harness extension points convention (`docs/harness-extension-points.md`)

Documents the existing but previously-unnamed pattern where a harness-owned
skill defers a project-specific step to a project-provided adapter skill,
found at a conventional path, instead of hardcoding an assumption (backend,
deploy target, etc.). No new tooling — a naming convention plus a worked
example already live in the codebase (`cr-security` Pass 3).

### Confirmed behaviors

- **`docs/harness-extension-points.md` distinguishes two cases:** adding a
  wholly new project-specific file (already safe today — anything outside
  `.claude/.harness-manifest.json` is invisible to `sync-harness.sh`) versus
  a harness-owned skill needing project-specific logic injected into one of
  its own steps (the actual extension-point pattern this doc names).

- **The convention is a path, not a config file:** an extension point lives
  at `.claude/skills/<extension-point-name>/SKILL.md` in the consuming
  project. A harness-owned skill checks for that path's existence before
  calling into it, and has a documented, explicit fallback when it's absent
  — it never silently skips the step.

- **`cr-security` Pass 3 now names its adapter's concrete path:**
  `.claude/skills/cr-security/SKILL.md` Pass 3 references
  `.claude/skills/database-safety-adapter/SKILL.md` by name and links to
  `docs/harness-extension-points.md`, replacing the previous vague "named
  in the project's config" phrasing. The existing MUST FIX routing-gap
  behavior when the adapter is absent is unchanged.

- **`/compound` gains a step to flag upstream candidates:** Step 6b
  (`.claude/skills/compound/SKILL.md`) asks, for any project built on this
  harness (not the harness source repo itself), whether the just-completed
  fix touched a harness-owned file or solved a problem general enough to
  belong in the harness. If yes, it's noted as a flag for a human to
  manually port upstream — this step does not open a PR itself.
