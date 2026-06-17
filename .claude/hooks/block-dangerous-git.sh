#!/bin/bash
# PreToolUse(Bash) hook. Blocks destructive/irreversible git ops.
# Parses each command SEGMENT (split on shell separators) and strips env
# assignments, wrapper words (sudo/xargs/...), and git global options
# (-C/-c/--git-dir) before reading the subcommand — so `git -C dir push`,
# `VAR=1 git push`, and newline-chained pushes are all caught, while a
# substring like grep "git push" is not.  Exit 2 = block; exit 0 = allow.

INPUT=$(cat)

# No jq → can't safely extract the command. FAIL CLOSED (HIGH-1): an un-inspectable
# command is treated as dangerous. The locks are the sole safety net (R4-D8).
command -v jq >/dev/null 2>&1 || { echo "block-dangerous-git.sh: jq missing — cannot inspect command, BLOCKING (fail-closed). Install jq." >&2; exit 2; }

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

block() { echo "Blocked by block-dangerous-git.sh: $1" >&2; echo "If genuinely intended, run it yourself in a terminal." >&2; exit 2; }

# dst branch of a push refspec: strip surrounding quotes, take the refspec dst,
# strip a refs/heads/ prefix.
norm_ref() {
  local r="$1"
  r="${r#\"}"; r="${r%\"}"; r="${r#\'}"; r="${r%\'}"
  r="${r##*:}"
  echo "${r#refs/heads/}"
}

# matches one leading NAME=VALUE env assignment (VALUE may be double-quoted and
# contain spaces), plus trailing whitespace and the rest of the command.
ENVRE='^[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|[^[:space:]]*)([[:space:]]+(.*))?$'

# Track the last cd target seen in the command chain. An agent that does
# `cd .claude/worktrees/slug && git commit` would otherwise be checked against
# the hook process's cwd (the main repo root, always on "main"), which blocks
# every worktree commit. Storing the cd target lets commit/push run
# `git -C <dir> rev-parse` in the correct directory instead.
_tracked_cd=""

while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  [ -z "$seg" ] && continue
  # peel leading env assignments off the raw string first, so a quoted value
  # with spaces can't break word-splitting and hide the git invocation.
  while [[ "$seg" =~ $ENVRE ]]; do
    [ -z "${BASH_REMATCH[3]}" ] && { seg=""; break; }
    seg="${BASH_REMATCH[3]}"
  done
  [ -z "$seg" ] && continue
  set -f; set -- $seg; set +f
  while [ $# -gt 0 ]; do
    case "$1" in
      sudo|env|command|time|nice|nohup|xargs|\\) shift ;;
      *) break ;;
    esac
  done
  # Track cd so subsequent git commands resolve the branch in the right dir.
  if [ "$1" = "cd" ] && [ -n "$2" ]; then _tracked_cd="$2"; continue; fi
  [ "$1" = "git" ] || continue
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c) shift 2 ;;
      --git-dir=*|--work-tree=*|--namespace=*|-p|--no-pager|--paginate|--bare) shift ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  sub="$1"; [ $# -gt 0 ] && shift
  case "$sub" in
    reset)  for a in "$@"; do [ "$a" = "--hard" ] && block "git reset --hard (destructive)"; done ;;
    clean)  block "git clean (destructive)" ;;
    rebase) block "git rebase (rewrites history)" ;;
    stash)  [ "$1" = "clear" ] && block "git stash clear (drops all stashes)" ;;
    branch)
      for a in "$@"; do
        case "$a" in
          --*) : ;;
          -*D*) block "git branch with -D flag (force-deletes a branch)" ;;
        esac
      done ;;
    commit)
      # Block committing on main/master/develop — work must start on a feature branch.
      # Use the tracked cd path (if any) so worktree commits aren't falsely blocked
      # by checking the main repo's HEAD instead of the worktree's branch.
      if [ -n "$_tracked_cd" ]; then
        _cur=$(git -C "$_tracked_cd" rev-parse --abbrev-ref HEAD 2>/dev/null)
      else
        _cur=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      fi
      case "$_cur" in main|master|develop) block "commit on protected branch '$_cur' — run: git checkout -b feat/<slug>" ;; esac ;;
    push)
      for a in "$@"; do
        case "$a" in
          --force|--force-with-lease|--force-with-lease=*|--force=*) block "force push (rewrites remote history)" ;;
          --*) : ;;
          -*f*) block "force push (-f)" ;;
        esac
      done
      _non_flag=0; _has_colon=0
      for a in "$@"; do
        case "$a" in -*) continue ;; esac
        _non_flag=$((_non_flag+1))
        _ref=$(norm_ref "$a")
        if [ "$_ref" = "HEAD" ]; then
          if [ -n "$_tracked_cd" ]; then
            _ref=$(git -C "$_tracked_cd" rev-parse --abbrev-ref HEAD 2>/dev/null)
          else
            _ref=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
          fi
        fi
        case "$_ref" in main|master|develop) block "push to a protected branch (main/master/develop)" ;; esac
        case "$a" in *:*) _has_colon=1 ;; esac
      done
      # Bare push (no refspec or remote-only): resolve current branch and block if protected.
      # Closes the "git push origin" gap — remote named but target branch inferred.
      if [ "$_has_colon" -eq 0 ] && [ "$_non_flag" -le 1 ]; then
        if [ -n "$_tracked_cd" ]; then
          _cur=$(git -C "$_tracked_cd" rev-parse --abbrev-ref HEAD 2>/dev/null)
        else
          _cur=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        fi
        case "$_cur" in main|master|develop) block "push to protected branch '$_cur' (no refspec — current branch inferred)" ;; esac
      fi ;;
    worktree)
      # This project's worktree convention is .claude/worktrees/<slug> (see AI-WORKFLOW.md),
      # not the system-default ../worktree-* — adapt the allowed path accordingly.
      [ "$1" = "remove" ] && { shift
        for a in "$@"; do
          case "$a" in -*) continue ;; esac
          case "$a" in
            .claude/worktrees/*) case "$a" in *..*) block "git worktree remove path traversal" ;; esac ;;
            *) block "git worktree remove of a path other than .claude/worktrees/*" ;;
          esac
          break
        done ; } ;;
  esac
done <<EOF
$(printf '%s' "$CMD" | tr $';|&()`' $'\n')
EOF
exit 0
