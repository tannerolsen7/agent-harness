# docs/design/

This directory holds the project's design system.

## Files

| File | What it is |
|---|---|
| `DESIGN.md` | The single source of truth for the design system. Every agent that writes UI code reads this file first. |
| `sources/<slug>.md` | Raw source files that were fed into the design synthesizer. One file per source design system. Kept for reference — `DESIGN.md` is the output, not these. |

## How DESIGN.md is created

The `design-synthesizer` agent builds `DESIGN.md`. You give it one or more source design systems — local files or a short description like "something like Linear". It always produces exactly one output.

- **One source:** The agent normalizes it (adds any missing sections) and writes it directly. No questions.
- **Multiple sources:** The agent compares the sources across 12 design axes (font, spacing, color strategy, etc.), finds conflicts, and asks you one question per conflict — all in a single message. After you answer, it synthesizes a single coherent file.

## Required sections

Every `DESIGN.md` must have these 6 sections, in this order:

1. **Colors** — named color tokens with hex values and a neutral scale.
2. **Typography** — font families, type scale levels, and usage rules.
3. **Spacing** — base unit, named scale steps, section gaps, component padding.
4. **Components** — key UI patterns with full specs for each state.
5. **Shapes & elevation** — border radius scale and shadow levels.
6. **Philosophy & constraints** — hard rules, absolute bans, and the system's register (Brand vs Product).
7. **Agent Prompt Guide** — a compressed reference agents paste before writing any UI code. Always last.

## Validation

Run this to check that `DESIGN.md` has all 6 required sections:

```sh
cd <repo-root> && bash scripts/design-system-validate.sh docs/design/DESIGN.md
```

This script exits non-zero and names any missing section. It is called automatically by `token-lint` as a pre-flight check.
