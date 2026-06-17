# Recurring Findings

Tracks cross-PR patterns that surface in `/cr` passes. Auto-flagged at Occurrences ≥3 for promotion to PITFALLS.md.

Status key: **Active** — not yet promoted · **Promoted** — now in PITFALLS.md or a named /cr pass-prompt

## How findings flow (the ratchet)

This file is the memory of the learning loop. Findings enter and leave it on a fixed path:

- **In:** `/cr` Step 3b reads this file after every review. It gives each finding a stable
  signature, then either matches an Active entry (and bumps its count + last-seen) or appends a
  new one at Occurrences 1.
- **Out (promotion):** when a finding reaches Occurrences ≥3 — or `/cr` judges it high-impact at a
  lower count — it is promoted. The promoter writes the matching `PITFALLS.md` entry (or a named
  `/cr` pass-prompt) and moves the finding from **Active** to **Promoted** here. A trap seen three
  times stops being a per-PR note and becomes a rule the gate checks every time.
- **Read-back:** `@doc-updater` reads this file during `/compound` and proposes any pending
  promotion in its draft, so the human sees the ratchet fire at PR-review time.

Keep this file under version control — the occurrence counts ARE the ratchet's state. Reset the
file and you reset the loop's memory.

---

## Active

### missing-protected-branch-in-test
**Signature:** A regression gate for a hook that protects N branches only covers N-1 of them.
**Occurrences:** 1
**Last seen:** 2026-06-15
**Locations:** tests/main-branch-guard.test.sh (develop branch missing)
**Detail:** The hook protects `main|master|develop` but the test had no `develop` stub or cases. Dropping `develop` from the hook case pattern would ship green. Fixed by adding STUB_DEVELOP + 2 cases.

### hook-refspec-norm-ref-bypasses
**Signature:** A push refspec that resolves to a protected ref through an unrecognized form bypasses `norm_ref()`.
**Occurrences:** 1
**Last seen:** 2026-06-15
**Locations:** .claude/hooks/block-dangerous-git.sh (norm_ref doesn't resolve HEAD; explicit-arg branch check only)
**Detail:** `git push origin HEAD` on main exits 0 (allowed). `norm_ref("HEAD")` returns `"HEAD"` (not in protected list); two non-flag args means `_non_flag=2` skips the bare-push `_non_flag<=1` fallback. Guard file — NEEDS HUMAN to fix.

---

## Promoted

*(none yet)*
