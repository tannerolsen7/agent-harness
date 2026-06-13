#!/usr/bin/env bash
# pr.sh is host-agnostic: forge detection from the remote URL, and the normalized
# --title/--body interface maps to each CLI's flags (gh pr create --body /
# glab mr create --description). Uses PR_DRY_RUN so nothing is created and no network is hit.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DETECT="$ROOT/scripts/detect-forge.sh"
PR="$ROOT/scripts/pr.sh"
[ -f "$DETECT" ] || { echo "test: $DETECT not found"; exit 1; }
[ -f "$PR" ] || { echo "test: $PR not found"; exit 1; }

pass=0; fail=0
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else echo "  MISS ($1): got '$2', want '$3'"; fail=$((fail+1)); fi; }
has() { if printf '%s' "$2" | grep -qF -- "$3"; then pass=$((pass+1)); else echo "  MISS ($1): '$3' not in '$2'"; fail=$((fail+1)); fi; }
hasnt() { if printf '%s' "$2" | grep -qF -- "$3"; then echo "  MISS ($1): '$3' unexpectedly in '$2'"; fail=$((fail+1)); else pass=$((pass+1)); fi; }

echo "── forge detection ──"
eq "https github"  "$(sh "$DETECT" 'https://github.com/o/r.git')" github
eq "ssh github"    "$(sh "$DETECT" 'git@github.com:o/r.git')"     github
eq "https gitlab"  "$(sh "$DETECT" 'https://gitlab.com/o/r.git')" gitlab
eq "ssh gitlab"    "$(sh "$DETECT" 'git@gitlab.com:o/r.git')"     gitlab
eq "self-hosted"   "$(sh "$DETECT" 'https://git.acme.com/o/r.git')" unknown

echo "── arg mapping (dry-run) ──"
gh_out=$(PR_DRY_RUN=1 PR_FORGE=github bash "$PR" --title T --body B)
has "github sub"   "$gh_out" "gh pr create"
has "github title" "$gh_out" "--title T"
has "github body"  "$gh_out" "--body B"

gl_out=$(PR_DRY_RUN=1 PR_FORGE=gitlab bash "$PR" --title T --body B)
has "gitlab sub"    "$gl_out" "glab mr create"
has "gitlab title"  "$gl_out" "--title T"
has "gitlab desc"   "$gl_out" "--description B"
hasnt "gitlab no --body" "$gl_out" "--body"

echo "── pass-through of extra args ──"
draft=$(PR_DRY_RUN=1 PR_FORGE=github bash "$PR" --title T --body B --draft)
has "passthrough --draft" "$draft" "--draft"

echo ""
echo "pr-host-agnostic: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
