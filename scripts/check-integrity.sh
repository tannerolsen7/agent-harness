#!/usr/bin/env bash
# Reference-integrity check (CMP4). Scans the project's markdown docs for broken
# cross-links so context docs cannot rot silently. A link counts as broken when it
# points at a relative file path that does not exist on disk. The check runs in CI
# (scripts/ci-verify.sh) and is also runnable locally:  bash scripts/check-integrity.sh
#
# What it checks: inline markdown links of the form [text](target). It resolves each
# target against the directory of the file the link lives in (so ./x.md and ../x.md
# both work), strips any #anchor, and confirms the file exists.
#
# What it skips on purpose:
#   - external links (http://, https://, mailto:, and other scheme:// forms)
#   - pure-anchor links (#heading) — same-document jumps, no file to resolve
#   - template placeholders that contain < or > (e.g. ./registry.md#<slug>)
#   - anything inside a fenced code block (``` … ```) — those are examples, not live links
#
# Anchor targets (the #heading half) are NOT verified — only the file half. Verifying
# heading anchors needs a full markdown parse and produces false positives on generated
# or cased headings; the file-exists check is the high-value, low-false-positive part.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# Markdown files to scan. Exclude transient worktrees (each carries a full copy) and
# node_modules, mirroring scripts/lint.sh so local and CI see the same file set.
files=""
while IFS= read -r f; do files="$files
$f"; done < <(find . -type f -name '*.md' \
  -not -path '*/worktrees/*' -not -path '*/node_modules/*' 2>/dev/null | sort)

broken=0
checked=0

# awk does the per-file work: walk lines, track fenced code state, pull link targets,
# apply the skip rules, and resolve each surviving target relative to the file's dir.
# It prints one "BROKEN<TAB>source<TAB>target" line per dead link and a "CHECKED<TAB>n"
# tally line. The shell loop below turns those into the human-readable report + exit code.
run_one() {
  awk -v src="$1" '
    function dirname(p,   i) { i=length(p); while (i>0 && substr(p,i,1)!="/") i--; return (i>0)?substr(p,1,i-1):"." }
    # Resolve a possibly-relative path against base dir, collapsing . and .. segments.
    function resolve(base, rel,   parts, out, n, i, seg, full) {
      if (substr(rel,1,1)=="/") full=rel; else full=base "/" rel
      n=split(full, parts, "/")
      out[0]=""; oc=0
      for (i=1;i<=n;i++){ seg=parts[i]
        if (seg=="" || seg==".") continue
        if (seg==".."){ if (oc>0) oc--; continue }
        oc++; out[oc]=seg
      }
      res=""; for (i=1;i<=oc;i++) res=res "/" out[i]
      if (substr(full,1,1)!="/") sub(/^\//,"",res)  # keep it relative to CWD (repo root)
      return (res=="")?".":res
    }
    BEGIN{ infence=0; base=dirname(src); nchk=0 }
    {
      line=$0
      # Toggle fenced-code state on a line whose first non-space run is ``` or ~~~.
      if (line ~ /^[[:space:]]*(```|~~~)/) { infence = !infence; next }
      if (infence) next
      # Blank out inline code spans (text between paired backticks). Links shown inside
      # `…` are examples or descriptions of other files (e.g. how an external memory index
      # is formatted), not live cross-links in this repo. Strip the longest paired runs
      # first (``…``) then single (`…`) so a doubled fence does not leave a stray tick.
      gsub(/``[^`]*``/, "", line)
      gsub(/`[^`]*`/, "", line)
      # Pull every ](target) on the line. Re-scan the remainder after each match.
      rest=line
      while (match(rest, /\]\([^)]*\)/)) {
        tok=substr(rest, RSTART, RLENGTH)
        rest=substr(rest, RSTART+RLENGTH)
        # strip the leading ]( and trailing )
        tgt=substr(tok, 3, length(tok)-3)
        # An inline title — [t](path "title") — keep only the path half.
        sub(/[[:space:]].*$/, "", tgt)
        if (tgt=="") continue
        if (tgt ~ /^#/) continue                       # pure anchor
        if (tgt ~ /^[a-zA-Z][a-zA-Z0-9+.-]*:/) continue # scheme: http, https, mailto, etc.
        if (tgt ~ /[<>]/) continue                      # template placeholder
        # drop the #anchor half; verify only the file part
        sub(/#.*$/, "", tgt)
        if (tgt=="") continue
        path=resolve(base, tgt)
        nchk++
        # Defer the existence test to the shell (awk cannot stat reliably); emit candidate.
        print "CHECK\t" src "\t" tgt "\t" path
      }
    }
  ' "$1"
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || continue
  while IFS=$'\t' read -r tag src tgt path; do
    [ "$tag" = "CHECK" ] || continue
    checked=$((checked + 1))
    if [ ! -e "$path" ]; then
      echo "BROKEN: $src -> $tgt (resolved: $path) does not exist" >&2
      broken=$((broken + 1))
    fi
  done < <(run_one "$f")
done <<EOF
$files
EOF

if [ "$broken" -ne 0 ]; then
  echo "check-integrity: $broken broken cross-link(s) found across context docs." >&2
  exit 1
fi
echo "check-integrity: OK ($checked relative links resolved)."
