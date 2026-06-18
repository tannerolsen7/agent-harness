# Problem: updating a specific record in a line-oriented structured text file from POSIX sh

**Problem class:** Multi-step in-place record update — you need to locate a record by a secondary field (not the first line of the record), then update the record's header line, safely and without aborting on failure.

## When this bites you

You have a structured markdown file where each record spans multiple lines:

```
- [ ] Alpha task
  Slug: alpha-task
  Notes: ...
```

A script needs to find the record for `alpha-task` and flip `- [ ]` to `- [~]`. The wrinkle: the field you can search by (`Slug: alpha-task`) is not the line you need to edit (the `- [ ]` header above it). You also need to handle slugs from user input, where any character could be a regex metacharacter.

## Root cause (three separate problems)

**1. Slug interpolation into grep.**
A slug like `feat.name` or `task[1]` contains regex metacharacters. Dropping it directly into `grep "Slug: $SLUG"` makes grep treat `.` as "any character" and `[` as the start of a character class, matching wrong lines silently.

**2. The field you can find is not the line you need to edit.**
The slug line appears after the header line in the file. You cannot `sed "s/- \[ \]/- [~]/" ...` on the slug line — you need the header line above it. Working forward from the top of the file, you have no way to know how far away the slug line is. Walking backward is the only clean path.

**3. POSIX sh has no arrays or process-substitution tricks.**
`readarray`, `mapfile`, and `while read` over a process substitution with a counter are bash-isms. In POSIX sh, the portable tool that can walk a file with a line counter and look backward is `awk`.

## The fix

From `scripts/worktree-add.sh`:

```sh
# Step 1: Escape metacharacters so the slug is treated as a literal string.
TASK_SLUG_ESCAPED=$(printf '%s' "$TASK_SLUG" | sed 's/[.[\*^$]/\\&/g')

# Step 2: Get the line NUMBER of the slug line (not its content).
TASK_SLUG_LINE=$(grep -n "^  Slug: ${TASK_SLUG_ESCAPED}$" "$REPO_ROOT/TASKS.md" \
  | head -1 | cut -d: -f1) || true

if [ -n "$TASK_SLUG_LINE" ]; then
  # Step 3: Walk backward with awk to find the nearest preceding header line.
  TASK_HEADER_LINE=$(awk -v lim="$TASK_SLUG_LINE" \
    'NR <= lim && /^- \[ \]/ { last=NR } END { print last+0 }' "$REPO_ROOT/TASKS.md")

  if [ "${TASK_HEADER_LINE:-0}" -gt 0 ] 2>/dev/null; then
    # Step 4: Atomic write — edit into a temp file, then replace.
    TASK_TMP="$(mktemp)"
    trap 'rm -f "$TASK_TMP"' EXIT
    if sed "${TASK_HEADER_LINE}s/^- \[ \]/- [~]/" "$REPO_ROOT/TASKS.md" > "$TASK_TMP" \
        && mv "$TASK_TMP" "$REPO_ROOT/TASKS.md"; then
      echo "script: marked '${TASK_SLUG}' in TASKS.md"
    else
      echo "script: WARNING: could not update TASKS.md for '${TASK_SLUG}'" >&2
    fi
  fi
fi
```

## The invariant — replicate this when

- You need to locate a record by a secondary field (not the record's first line).
- The search value comes from user input or external data (branch names, task slugs, anything you do not fully control).
- The script is POSIX sh (no bash arrays, no `pipefail`, no process substitution with counters).
- The write is a side-effect annotation — failure should warn but not abort the main operation.

The four-part pattern generalizes to any line-oriented record format: escape the search term, get a line number, walk backward with awk, write atomically.

## What doesn't work

**Direct slug interpolation into grep** (`grep "Slug: $SLUG"`): silently matches wrong lines when the slug contains `.`, `[`, `*`, `^`, or `$`.

**Grepping for the header line directly** (`grep -n "^- \[ \] Alpha task"`): the script only has the slug, not the human-readable task name.

**Walking forward from the header**: the number of lines between the header and the slug varies by record. There is no clean forward scan without parsing the whole file structure.

**`sed -n '/Slug: foo/,/^- /!d; /^- \[ \]/p'`**: sed range expressions select forward ranges, not backward. This would give the next header after the slug line, not the one before it.

**Editing in place with `sed -i`**: BSD sed (macOS) and GNU sed differ on whether `-i` requires an extension argument. `mktemp` + `mv` is portable and atomic on any POSIX system.

**`exit 1` on write failure**: if the main operation (e.g. creating a worktree) already completed before the annotation write, failing hard leaves a dangling side-effect with no record. Demote annotation failures to `>&2` warnings.

## Tags

posix-sh, sed, awk, grep, line-number, backward-search, structured-markdown, in-place-edit, atomic-write, mktemp, regex-escape, record-update, multi-line-record, TASKS.md, worktree-add.sh
