#!/usr/bin/env bash
# Token linter — checks UI files for hardcoded colors/spacing and absolute design bans.
#
# What this does:
#   1. Checks that docs/design/DESIGN.md exists (the project's design token file).
#      If it does not exist, the linter exits 0 — projects without a design system are not blocked.
#   2. Scans every UI-related file in the diff (or the whole repo when run manually)
#      for hardcoded hex colors (#rrggbb / #rgb), raw rgb/rgba/hsl calls, and
#      pixel values that look like spacing (4px multiples that should be tokens).
#      Token usage is detected by the presence of var(-- in the same line — not by checking
#      against the specific token names in DESIGN.md.
#   3. Checks for six absolute design bans that are never OK regardless of tokens:
#      gradient text, glassmorphism, side-stripe borders, hero-metric template,
#      identical-card grids, eyebrow-on-every-section.
#
# Modes:
#   token-lint.sh            — scan all UI files in the repo
#   token-lint.sh --diff     — scan only files changed vs. origin/main (used in CI)
#   token-lint.sh <file>...  — scan specific files
#
# Exit codes: 0 = clean, 1 = violations found, 2 = config/setup error
#
# UI file extensions covered: .css .scss .less .html .jsx .tsx .vue .svelte .styled.ts .styled.js
#
# Adding a new ban: add a check_ban_* function below and call it from check_bans().
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DESIGN="$ROOT/docs/design/DESIGN.md"

# ── Colour output (suppressed when not a tty) ──────────────────────────────
RED=""
YELLOW=""
RESET=""
if [ -t 1 ]; then
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  RESET='\033[0m'
fi

fail=0
warn_count=0
error_count=0

emit_error() { printf '%b[TOKEN-LINT ERROR]%b %s\n' "$RED" "$RESET" "$1" >&2; error_count=$((error_count + 1)); fail=1; }
emit_warn()  { printf '%b[TOKEN-LINT WARN]%b  %s\n' "$YELLOW" "$RESET" "$1" >&2; warn_count=$((warn_count + 1)); }

# ── Require the design file ────────────────────────────────────────────────
if [ ! -f "$DESIGN" ]; then
  echo "token-lint: docs/design/DESIGN.md not found." >&2
  echo "  Run @design-synthesizer (or /design) to create the project's design token file." >&2
  echo "  Token linting is skipped until the file exists." >&2
  exit 0
fi

# DESIGN.md existence is the gate — the linter's checks use var(-- structural detection,
# not the specific token names in DESIGN.md. The file's presence signals that the project
# has adopted a design system and token enforcement is active.

# ── Collect files to scan ─────────────────────────────────────────────────
# Scans UI component files — CSS, SCSS, JSX, TSX, Vue, Svelte, HTML templates.
# HTML files are only included when they live in component-style directories
# (src/, app/, pages/, components/, templates/), not top-level tracking/report files.
# Excluded dirs: docs/, node_modules/, .claude/worktrees/, tests/, __tests__/.

collect_files() {
  # Accepts a list of paths (newline-separated) and filters to UI component files.
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$ROOT/$f" ] || [ -f "$f" ] || continue
    # Exclude non-component directories.
    case "$f" in
      docs/*|node_modules/*|.claude/worktrees/*|tests/*|__tests__/*) continue ;;
    esac
    case "$f" in
      # CSS/SCSS/Less are always UI files regardless of directory.
      *.css|*.scss|*.less) printf '%s\n' "$f" ;;
      # Component files — always UI.
      *.jsx|*.tsx|*.vue|*.svelte) printf '%s\n' "$f" ;;
      # Styled-components / css-in-js.
      *.styled.ts|*.styled.js) printf '%s\n' "$f" ;;
      # HTML — only when inside a component-style directory, not top-level reports.
      *.html)
        case "$f" in
          src/*|app/*|pages/*|components/*|templates/*) printf '%s\n' "$f" ;;
        esac
        ;;
    esac
  done
}

if [ "$#" -gt 0 ] && [ "$1" = "--diff" ]; then
  # CI mode: only changed files vs. origin/main
  BASE="${ROUTING_BASE:-}"
  [ -z "$BASE" ] && [ -n "${GITHUB_BASE_REF:-}" ] && BASE="origin/$GITHUB_BASE_REF"
  [ -z "$BASE" ] && BASE="origin/main"
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || BASE="main"
  git rev-parse --verify "$BASE" >/dev/null 2>&1 || {
    echo "token-lint: could not resolve base ref '$BASE'. Scanning all UI files instead." >&2
    BASE=""
  }
  if [ -n "$BASE" ]; then
    files=$(git diff --name-only "$BASE"...HEAD 2>/dev/null | collect_files)
  else
    files=$(git ls-files | collect_files)
  fi
elif [ "$#" -gt 0 ] && [ "$1" != "--diff" ]; then
  # Explicit file list
  files=$(printf '%s\n' "$@" | collect_files)
else
  # Full repo scan (default)
  files=$(git ls-files 2>/dev/null | collect_files)
fi

if [ -z "$files" ]; then
  echo "token-lint: no UI files to scan."
  exit 0
fi

file_count=0
# ── Per-file checks ────────────────────────────────────────────────────────
check_file() {
  local f="$1"
  local abs_f
  if [ -f "$ROOT/$f" ]; then abs_f="$ROOT/$f"; else abs_f="$f"; fi
  [ -f "$abs_f" ] || return 0

  local lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    loc="$f:$lineno"

    # Skip comment lines (CSS //, /*, # in SCSS/Sass, HTML <!-- comments)
    stripped="${line#"${line%%[! ]*}"}"  # ltrim
    case "$stripped" in
      "//"|"//"*) continue ;;  # JS/CSS single-line comment
      "/*"*) continue ;;        # CSS block comment opener
      "<!--"*) continue ;;      # HTML comment
      "#"*) continue ;;         # SCSS/shell comment (won't appear in JSX/TSX)
      "*"*) continue ;;         # Inside a block comment
    esac

    # 1. Hardcoded hex color: #rgb or #rrggbb (not #anchor in URLs)
    # Allow: inside a comment, inside a string that is a CSS var name, or a known token.
    # Heuristic: flag any 3 or 6 hex-digit token preceded by # that is NOT in a var() call.
    case "$line" in
      *'#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*)
        # 6-digit hex. Allow only inside CSS custom property references or comments.
        # Crude but effective: if the line contains a #RRGGBB not preceded by var(-- it's bare.
        check="${line}"
        # Strip var(--color-*: #...) style declarations (those are token definitions in DESIGN.md-style tables, not usage)
        check="${check//var(--[a-zA-Z0-9_-]*/}"
        case "$check" in
          *'#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*)
            emit_error "$loc: hardcoded 6-digit hex color. Use a design token (e.g. var(--color-primary))." ;;
        esac
        ;;
    esac
    case "$line" in
      *'#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][!0-9a-fA-F]*)
        # 3-digit hex only (exclude 6-digit already caught above and longer sequences like #abc123)
        # This catches #abc, #fff, #000 style values
        check="${line}"
        check="${check//var(--[a-zA-Z0-9_-]*/}"
        case "$check" in
          *'#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][!0-9a-fA-F]*)
            emit_error "$loc: hardcoded 3-digit hex color. Use a design token (e.g. var(--color-border))." ;;
        esac
        ;;
    esac

    # 2. Raw rgb() / rgba() / hsl() / hsla() color functions
    case "$line" in
      *'rgb('*|*'rgba('*|*'hsl('*|*'hsla('*)
        emit_error "$loc: raw color function (rgb/rgba/hsl/hsla). Use a design token instead." ;;
    esac

    # 3. Hardcoded pixel spacing values that should come from the spacing scale.
    # Flag px values that are NOT multiples of 4 (never valid in a 4px-base system),
    # OR that are used as padding/margin/gap/inset outside a var() reference.
    # We check the presence of CSS properties with raw px values.
    case "$line" in
      *'padding:'*'px'*|*'margin:'*'px'*|*'gap:'*'px'*|*'inset:'*'px'*)
        # Allow if it contains var(-- (already using tokens) or the value is 0
        case "$line" in
          *'var(--'*) ;;  # already tokenized
          *'padding: 0'*|*'padding:0'*|*'margin: 0'*|*'margin:0'*) ;;  # zero is always fine
          *)
            emit_warn "$loc: raw px value in padding/margin/gap. Prefer var(--space-N) tokens." ;;
        esac
        ;;
    esac

  done < "$abs_f"
}

# ── Absolute ban checks (run on full file content, not line-by-line) ───────
check_bans() {
  local f="$1"
  local abs_f
  if [ -f "$ROOT/$f" ]; then abs_f="$ROOT/$f"; else abs_f="$f"; fi
  [ -f "$abs_f" ] || return 0
  local content
  content=$(cat "$abs_f")

  # Ban 1: Gradient text (background-clip: text pattern)
  # This creates text that shows a gradient — a flashy effect banned by the design system.
  # Two separate case statements because *'background-clip: text'* matches the webkit
  # variant too (pattern overlap), which triggers a shellcheck false-positive warning.
  _gradient_ban=0
  case "$content" in *'background-clip: text'*|*'background-clip:text'*) _gradient_ban=1 ;; esac
  case "$content" in *'-webkit-background-clip: text'*|*'-webkit-background-clip:text'*) _gradient_ban=1 ;; esac
  if [ "$_gradient_ban" -eq 1 ]; then
    emit_error "$f: BAN — gradient text (background-clip: text) is not allowed in this design system."
  fi

  # Ban 2: Glassmorphism — backdrop-filter: blur used as the primary card/panel style.
  # One legitimate use (e.g. a tooltip or floating panel) may be acceptable, but this
  # catches the pattern being applied as a default surface treatment.
  case "$content" in
    *'backdrop-filter'*'blur'*)
      emit_error "$f: BAN — glassmorphism (backdrop-filter: blur) is not allowed as a surface style." ;;
  esac

  # Ban 3: Side-stripe border as the sole visual differentiator.
  # border-left with 3px+ solid is the decorative stripe pattern — banned.
  # 1px solid is a functional divider (allowed). 2px solid gets a warning.
  #
  # NOTE: These checks run independently rather than as a single case statement.
  # A single case exits on the first match, so a file with both "1px solid" (allowed)
  # and "4px solid" (banned) would only match the 1px arm and silently miss the ban.
  # Separate checks ensure every thickness is evaluated regardless of what else is in the file.
  case "$content" in
    *'border-left:'*'px solid'*)
      # Banned (3px+): flag unless the only border-left thickness present is 1px or 2px.
      # Strip all 1px occurrences, then strip all 2px occurrences; if anything remains, it's 3px+.
      _bl_check="${content}"
      _bl_check="${_bl_check//border-left: 1px solid/}"
      _bl_check="${_bl_check//border-left:1px solid/}"
      _bl_check="${_bl_check//border-left: 2px solid/}"
      _bl_check="${_bl_check//border-left:2px solid/}"
      case "$_bl_check" in
        *'border-left:'*'px solid'*)
          emit_error "$f: BAN — side-stripe border (border-left: 3px+ solid) used as a visual accent is not allowed." ;;
      esac
      # Warning (2px): present only when no banned thickness was found.
      # This runs after the error check so 2px-only files still get the advisory.
      case "$content" in
        *'border-left: 2px solid'*|*'border-left:2px solid'*)
          case "$_bl_check" in
            *'border-left:'*'px solid'*) ;;  # already flagged as error — skip warning
            *)
              emit_warn "$f: REVIEW — side-stripe border (border-left: 2px+) — ensure this is not used as the sole visual differentiator (ban applies at 3px+)." ;;
          esac ;;
      esac
      ;;
  esac

  # Ban 4: Hero-metric template — giant centered number + small label as a primary content block.
  # Catch the pattern: a very large font-size (>= 48px or text-display class) adjacent to a
  # small label, both centered, used as a section pattern. We look for the CSS signals.
  case "$content" in
    *'hero-metric'*|*'hero_metric'*|*'HeroMetric'*)
      emit_error "$f: BAN — hero-metric template component/class name found. Giant number + label pattern is not allowed as a primary content pattern." ;;
  esac
  # Also catch the structural CSS pattern: font-size >= 48px + text-align center near each other
  case "$content" in
    *'font-size: 4'*'text-align: center'*|*'font-size: 5'*'text-align: center'*|\
    *'font-size: 6'*'text-align: center'*|*'font-size: 7'*'text-align: center'*|\
    *'font-size: 8'*'text-align: center'*|*'font-size: 9'*'text-align: center'*)
      emit_warn "$f: REVIEW — very large centered text may be a hero-metric pattern (banned). Verify this is a one-off heading, not a repeating metric template." ;;
  esac

  # Ban 5: Identical card grids — three or more cards with identical structure and no differentiation.
  # We catch component/class naming patterns that indicate a grid of identical cards.
  case "$content" in
    *'card-grid'*|*'CardGrid'*|*'card_grid'*)
      emit_warn "$f: REVIEW — card-grid pattern found. Verify the cards have content differentiation (identical card grids are banned)." ;;
  esac
  # Catch repeated identical JSX card components (3+ of the same component in a row)
  # This is a heuristic — human review still applies
  case "$content" in
    *'<Card '*'<Card '*'<Card '*)
      emit_warn "$f: REVIEW — three or more identical <Card> components in sequence. Ensure content differentiation (identical card grids are banned)." ;;
  esac

  # Ban 6: Eyebrow labels on every section — text-transform: uppercase small label above every heading.
  # We catch repeated eyebrow/overline/kicker class usage, or multiple uppercase-label patterns.
  case "$content" in
    *'eyebrow'*|*'overline'*|*'kicker'*|*'section-label'*|*'sectionLabel'*)
      # Only warn — one eyebrow is fine; many is the banned pattern. Human review applies.
      emit_warn "$f: REVIEW — eyebrow/overline label class found. Verify this pattern is not used on every section (banned). One or two eyebrows per page is acceptable." ;;
  esac
}

# ── Run all checks ─────────────────────────────────────────────────────────
while IFS= read -r f; do
  [ -z "$f" ] && continue
  file_count=$((file_count + 1))
  check_file "$f"
  check_bans "$f"
done <<EOF
$files
EOF

# ── Summary ────────────────────────────────────────────────────────────────
if [ "$fail" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
  echo "token-lint: OK ($file_count UI file(s) scanned, 0 violations)."
elif [ "$fail" -eq 0 ] && [ "$warn_count" -gt 0 ]; then
  echo "token-lint: WARNINGS ($file_count file(s) | 0 errors | $warn_count warning(s) — review before merging)." >&2
else
  echo "token-lint: FAILED ($file_count file(s) | $error_count error(s) | $warn_count warning(s))." >&2
  echo "  Errors must be fixed before merging. See findings above." >&2
fi

exit "$fail"
