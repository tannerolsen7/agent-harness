# PITFALLS

Codebase traps — the non-obvious things that have bitten someone here. One entry per trap.
Read this before writing in any affected area. Add to it whenever a surprise costs you time.

Each entry: what looks safe, why it is not, and what to do instead.

<!-- Example shape (delete once you have real entries):

## Temp git repos inherit the parent GIT_DIR
What looks safe: `git init` in a mktemp dir inside a test.
Why it bites: if the test runs inside a git hook, GIT_DIR is exported and points at the real repo.
Do instead: `unset GIT_DIR GIT_WORK_TREE ...` at the top of the test.
-->

TODO: add your first pitfall when you find one.
