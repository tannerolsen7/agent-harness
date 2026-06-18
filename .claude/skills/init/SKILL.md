---
name: init
description: Sets up a freshly-installed harness in a new repo — copies the starter context docs (CLAUDE.md, AGENTS.md, CONTEXT.md, PITFALLS.md) from docs/templates/ for any that are missing, then walks the user through filling in CLAUDE.md interactively. Use right after running scripts/install.sh, or when the user says "/init", "set up the harness", "fill in CLAUDE.md", "initialize this project", or "finish the install". Assumes install.sh has already placed the harness files; does not re-run it.
---

# /init — finish setting up a newly-installed harness

`scripts/install.sh` placed the harness files. This skill does the human-facing part install.sh
deliberately left for an interactive session: create any missing starter docs, then fill in
CLAUDE.md by asking the user about their project. Project context lives in CLAUDE.md — not in
settings.json — because that is where Claude already expects to find "describe your project" content.

## Step 0 — Confirm install ran

Check that `.claude/.harness-manifest.json` exists. If it does not, stop and tell the user to run
`bash scripts/install.sh` first. Do not re-run install.sh from this skill.

## Step 1 — Create missing starter docs

`scripts/install.sh` already copies these files on first install, so this step is a safety net.
It exists for the case where someone runs `/init` before `install.sh`, or where `install.sh` was
interrupted before writing a particular template file.

For each of `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `PITFALLS.md` at the repo root:

- If the file already exists: leave it untouched. Record it as "skipped (already existed)".
- If the file is missing: copy it from `docs/templates/<name>` and record it as "created".

Never overwrite an existing file. These hold project knowledge the team builds up over time.

## Step 2 — Fill in CLAUDE.md interactively

Open `CLAUDE.md`. Walk the user through the fill-in sections one topic at a time. Ask about:

- Project name and a one-paragraph overview of what it is and who it is for
- Tech stack: language, framework, and the package manager (npm / pnpm / yarn / bun)
- Source control host (GitHub or GitLab) and deployment target
- Dev / build / lint commands (the test command is already `npm test`)
- Architecture rules: where business logic lives, any layer boundaries
- Any project-specific hard rules for the NEVER list

Ask in small batches, not one giant prompt. Replace each `TODO` placeholder with the user's answer.
Leave a section as `TODO` only if the user genuinely does not know yet.

## Step 3 — Point out the setup checklist

CLAUDE.md ships with a `## Setup checklist` block at the very top. Remind the user it lists the
remaining one-time steps:

- `bash scripts/install-harness-hooks.sh` — wire git hooks and npm
- `bash scripts/install-locks.sh` — optional OS-level locks (requires sudo)

Tell them to delete that checklist section once all three steps (including this `/init` run) are done.

## Step 4 — Report

Print a short summary:

- Which docs were created vs. skipped (already existed)
- That CLAUDE.md is now filled in (or which sections still say TODO)
- The next command to run from the setup checklist

Do not commit anything. The user reviews and commits when ready.
