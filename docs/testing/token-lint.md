## Token linter (`scripts/token-lint.sh`)

Enforces design-system token usage in UI files. Catches hardcoded colors and
spacing, and flags six absolute design bans that are never acceptable regardless
of token use. Activated the moment `docs/design/DESIGN.md` exists in the repo.

### Confirmed behaviors

- **Token-only file passes:** A CSS file that uses only `var(--...)` references
  for colors and spacing exits 0 with no violations.
- **Hardcoded 6-digit hex exits non-zero:** A file containing a bare `#RRGGBB`
  value (not inside a `var()` call) causes the linter to exit 1 and name the
  violation in the output.
- **Hardcoded 3-digit hex exits non-zero:** A file containing a bare `#RGB` value
  (not inside a `var()` call) causes the linter to exit 1 and name the violation.
- **Raw color function exits non-zero:** A file using `rgb()`, `rgba()`, or
  `hsl()` directly causes the linter to exit 1 and mention the function name.
- **Ban — gradient text:** A file with `background-clip: text` (the CSS gradient-text
  pattern) causes the linter to exit 1 and mention "gradient" in the output.
- **Ban — glassmorphism:** A file with `backdrop-filter: blur` causes the linter
  to exit 1 and mention "glassmorphism" in the output.
- **Ban — side-stripe border (3px+):** A file with `border-left: 4px solid` causes
  the linter to exit 1 and mention "side-stripe" in the output.
- **Side-stripe 1px (divider) is allowed:** A file with `border-left: 1px solid`
  exits 0 — 1px is a functional divider, not a decorative stripe.
- **Ban — hero-metric template:** A file containing the class name `hero-metric`
  causes the linter to exit 1 and mention "hero-metric" in the output.
- **Warning — identical card grid:** A file containing the class name `card-grid`
  emits a warning and exits 0 (warning, not a hard error — human review required).
- **Warning — eyebrow label:** A file containing an `eyebrow` class emits a warning
  and exits 0 (one eyebrow per page may be acceptable; human review required).
- **Missing DESIGN.md skips without blocking:** When `docs/design/DESIGN.md` does
  not exist, the linter exits 0 and prints a message naming the missing file and
  telling the user to run `@design-synthesizer` to create it.
