## Skill frontmatter lint (`scripts/skill-frontmatter-lint.sh`)

`skill-frontmatter-lint.sh` checks staged `.claude/skills/*/SKILL.md` files for
frontmatter problems that would silently break skill routing or discovery.
Modeled on `scripts/shell-portability-lint.sh`: takes a list of file paths as
arguments, prints file:reason on stderr for each violation, exits 1 if any
file has a violation, exits 0 if clean.

### Confirmed behaviors — frontmatter presence

- **Missing frontmatter block exits 1:** Given a `SKILL.md` file with no
  `---`-delimited frontmatter block at the top of the file, the script prints
  an error naming the file and reason ("no frontmatter block") and exits 1.

- **Missing `name:` field exits 1:** Given a frontmatter block with a
  `description:` field but no `name:` field, the script exits 1 and names the
  missing field.

- **Missing `description:` field exits 1:** Given a frontmatter block with a
  `name:` field but no `description:` field, the script exits 1 and names the
  missing field.

- **Empty `name:` value exits 1:** Given `name:` present but with no value
  (e.g. `name:` or `name: ""`), the script exits 1.

- **Empty `description:` value exits 1:** Given `description:` present but
  with no value, the script exits 1.

- **Complete frontmatter with both fields non-empty passes this check:** Given
  a frontmatter block with non-empty `name:` and `description:` fields, this
  check does not flag the file.

### Confirmed behaviors — name/directory match

- **`name:` matching the parent directory passes:** Given a file at
  `.claude/skills/foo-bar/SKILL.md` with `name: foo-bar` in frontmatter, the
  directory-match check does not flag the file.

- **`name:` not matching the parent directory exits 1:** Given a file at
  `.claude/skills/foo-bar/SKILL.md` with `name: something-else` in
  frontmatter, the script exits 1 and reports both the frontmatter name and
  the expected directory name.

### Confirmed behaviors — description length

- **Description at or under 1024 chars passes:** Given a `description:` value
  of exactly 1024 characters, the length check does not flag the file.

- **Description over 1024 chars exits 1:** Given a `description:` value over
  1024 characters, the script exits 1 and reports the actual length against
  the 1024 limit.

### Confirmed behaviors — trigger phrase

- **Description containing "Use when" passes:** Given a `description:` value
  that contains the literal substring "Use when", the trigger check does not
  flag the file.

- **Description missing "Use when" exits 1:** Given a `description:` value
  that does not contain the literal substring "Use when", the script exits 1
  and reports that the trigger phrase is missing.

### Confirmed behaviors — reporting and aggregation

- **Multiple violations in one file are all reported:** Given a single file
  that fails more than one check (e.g. missing `name:` and description over
  1024 chars), the script prints a separate line for each violation, not just
  the first one found.

- **Violations across multiple files are all reported:** Given multiple file
  arguments where more than one has a violation, the script checks every file
  and reports violations for all of them, not just the first failing file.

- **Clean run across multiple files exits 0:** Given multiple file arguments
  that all pass every check, the script exits 0 with no output.

- **Non-SKILL.md or missing files are skipped, not errors:** Given a file
  argument that does not exist on disk (e.g. a file staged for deletion), the
  script skips it without treating it as a violation or crashing.

### Confirmed behaviors — quoting, path edge cases, and line endings

- **Quoted empty values are treated as empty:** Given `name: ""` or
  `description: ""` (a quoted empty string, not just a bare colon), the script
  strips the surrounding quotes before checking emptiness and exits 1 with the
  same "field is empty" message as an unquoted empty value.

- **Quoted non-empty values are compared unquoted:** Given `name: "foo-bar"`
  in a file at `.claude/skills/foo-bar/SKILL.md`, the script strips the quotes
  before the directory-match comparison, so it does not flag the file.

- **A bare filename with no parent directory skips the directory-match
  check:** Given a file argument with no path separator (e.g. `SKILL.md`
  passed from inside the skill's own directory), the script cannot determine
  the intended skill directory and skips the name/directory comparison rather
  than reporting a misleading mismatch against `.`.

- **A path that exists but is not a regular file is a violation, not a
  silent skip:** Given a file argument that resolves to a directory (or any
  non-regular-file path) that exists on disk, the script reports "not a
  regular file" and exits 1 — distinct from a genuinely missing path, which is
  still skipped silently per the behavior above.

- **CRLF line endings are normalized:** Given a `SKILL.md` file saved with
  Windows-style CRLF line endings, the script strips the trailing `\r` from
  each line before matching the frontmatter delimiter and extracting field
  values, so a well-formed CRLF file is not misreported as missing its
  frontmatter block.

- **An `awk` failure while reading one file does not abort the run:** Given
  `awk` fails on a specific file (e.g. a permissions or I/O error), the
  script reports "could not read frontmatter (awk failed)" for that file and
  continues checking the remaining file arguments, rather than crashing the
  whole run under `set -e`.

### Known limitations (not enforced by this script)

- Only single-line `name: value` / `description: value` frontmatter is
  parsed. Multi-line YAML block scalars (`description: |` or `description:
  >`) read as an empty value and are reported as a missing/empty field.
- If a field is duplicated (e.g. two `name:` lines), only the first is read;
  the second is silently ignored.
- The description length check counts characters via the shell's locale, not
  bytes — a description with multi-byte (non-ASCII) characters may count
  differently than a byte-exact tool would.
