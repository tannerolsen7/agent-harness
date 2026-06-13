# Vendored skills — provenance (P5 / R4-D17)

Third-party skills are **vendored and pinned to a reviewed SHA** so the harness is
self-contained (no reliance on a global install) and the supply chain is auditable.
Before bumping any vendored skill, re-fetch at the new SHA and human-review the diff.

## Source: `github.com/mattpocock/skills` (MIT)

- **Pinned SHA:** `694fa30311e02c2639942308513555e61ee84a6f`
- **License:** MIT — retained as `VENDOR-LICENSE-mattpocock`
- **Vendored skills** (copied from the repo at that SHA, dereferenced):
  - `to-issues` (engineering/) — borrowed dep used by `/feature`
  - `prototype`, `zoom-out`, `triage`, `to-prd` (engineering/), `write-a-skill` (productivity/) — adopted (R4-D17)
- **`grill-with-docs`** was the first vendored Matt Pocock skill (brought in the bootstrap).

## Not vendored
- **`simplify`** — a Claude Code **built-in** (absent from mattpocock/skills and the global
  install); `/feature` resolves it via the built-in, so no file is vendored.
