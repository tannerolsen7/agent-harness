#!/bin/bash
# PreToolUse(Bash) hook. Blocks destructive/irreversible git ops.
# Parses each command SEGMENT (split on shell separators) and strips env
# assignments, wrapper words (sudo/xargs/...), and git global options
# (-C/-c/--git-dir) before reading the subcommand — so `git -C dir push`,
# `VAR=1 git push`, and newline-chained pushes are all caught, while a
# substring like grep "git push" is not.  Exit 2 = block; exit 0 = allow.

INPUT=$(cat)

# No jq → can't safely extract the command; fail OPEN but loud rather than
# brick every Bash call. CLAUDE.md still governs the agent.
command -v jq >/dev/null 2>&1 || { echo "block-dangerous-git.sh: jq missing — git guard DISABLED. Install jq." >&2; exit 0; }

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
    push)
      for a in "$@"; do
        case "$a" in
          --force|--force-with-lease|--force-with-lease=*|--force=*) block "force push (rewrites remote history)" ;;
          --*) : ;;
          -*f*) block "force push (-f)" ;;
        esac
      done
      for a in "$@"; do
        case "$a" in -*) continue ;; esac
        case "$(norm_ref "$a")" in main|master|develop) block "push to a protected branch (main/master/develop)" ;; esac
      done ;;
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
