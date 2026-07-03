<!-- context-meta
owner: tanner
last-reviewed: 2026-07-02
review-frequency: monthly
drift-signals:
  - a shared skill hardcodes a backend/domain assumption instead of naming an adapter here
  - an adapter convention listed here no longer matches what any skill actually checks for
-->

# Harness extension points

How a repo using this harness adds project-specific behavior to a shared (harness-owned)
skill, without forking that skill. This is a documentation-only convention — no new tooling,
no new skill. It names a pattern that already exists in this codebase (`cr-security`'s
Pass 3) and gives future skill authors and downstream projects a clear recipe to follow.

## Two different problems this harness already solves differently

**"I need to add something new"** — a project-specific script, skill, or doc that the
harness doesn't ship. This already works with zero ceremony: `scripts/sync-harness.sh` only
touches files listed in `.claude/.harness-manifest.json` (the harness-owned "copy" files and
the project-owned "create-once" files). Anything a project adds outside that manifest is
invisible to sync — it can never be overwritten by an upstream update, and it never needs a
fork. If what you need is a wholly new file, just add it. Nothing below applies to you.

**"A shared skill needs to call into logic that's different per project"** — this is the
real gap. A harness-owned skill sometimes has a step that is correct in shape (there should
be a check here) but wrong to hardcode (which backend, which auth model, which deploy
target). That step is an **extension point**: the shared skill defers to a project-provided
adapter, checked by a naming convention, instead of assuming one specific answer.

## The convention

An extension point is a skill that:

1. Lives at `.claude/skills/<extension-point-name>/SKILL.md` in the *consuming* project (not
   in the harness repo — the harness never ships the adapter itself, since the whole point is
   that it's project-specific).
2. Is invoked by name from a harness-owned skill, which checks whether the file exists before
   calling into it.
3. Has a **documented, explicit fallback** when the adapter is absent. Never silently skip the
   step — either state the gap out loud (so the human sees it as a real absence, not a pass)
   or fall back to a generic, backend-agnostic version of the check.

### The existing example: `cr-security` Pass 3

`.claude/skills/cr-security/SKILL.md` Pass 3 ("Backend Security Checklist") does not hardcode
a database or backend. It invokes `.claude/skills/database-safety-adapter/SKILL.md` in the
consuming project — a skill that project writes once, encoding its own backend's specific
security checklist (row-level policies, privileged functions, storage access rules — whatever
applies to *that* project's actual data store). If the project hasn't written one and the diff
touches the database, Pass 3 says so as a MUST FIX routing gap — it does not quietly pass.

This is the only extension point in the harness today. It predates this doc; this doc exists
so the next one doesn't have to be reverse-engineered from `cr-security`'s prose.

## Adding a new extension point to a harness-owned skill

1. Name it: `<domain>-adapter` (e.g. `database-safety-adapter`, `deploy-target-adapter`).
   Keep it a noun phrase describing what the adapter is responsible for, not what skill calls
   it — the same adapter might eventually be called from more than one place.
2. In the harness skill, check for `.claude/skills/<name>/SKILL.md` before the step that
   needs it. Document in the harness skill's own text: what the adapter is expected to
   receive, what it's expected to return or assert, and what happens if it's absent.
3. Do not write a starter/example adapter file into the harness repo's own `install.sh`
   templates — the harness has no opinion on what a project's backend or deploy target is,
   and a shipped-but-empty stub invites cargo-culting a shape that doesn't fit. The absent-case
   fallback (state the gap, or fall back to generic checks) is what a project sees until it
   writes its own.
4. Record the new extension point in this file, following the `cr-security` entry's format
   above.

## When NOT to use this pattern

If a project just needs to add a script, skill, or doc the harness doesn't ship — that's the
first case above, not an extension point. Extension points exist only for the narrower case
where a *harness-owned* skill needs project-specific logic injected into one of its own steps.
Most "I need to add what my repo needs" requests are the simple case and need nothing from
this doc at all.
