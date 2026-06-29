# fix-plugin-manifest

## Confirmed behaviors

### B1 — plugin.json passes Claude Code schema validation

`plugin.json` lists agents as an array of individual `.md` file paths and skills as a
`commands` array of `SKILL.md` file paths. Both fields pass the schema validator that
Claude Code runs at install time (no "Invalid input" errors).

**Acceptance:** `bash tests/plugin-manifests.test.sh` exits 0. The test confirms:
- `.agents` is a JSON array with at least one entry
- `.commands` is a JSON array with at least one entry
- `.skills` is absent (field was renamed to `commands`)
