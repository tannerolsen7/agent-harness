## Circular import detection (`scripts/circular-imports.sh`)

Runs `madge --circular` against the project's JS/TS source files.
Exits 1 when any import cycle is found so the pre-commit gate can catch it.
Exits 0 when no cycles are found or when the check is skipped.

### Confirmed behaviors

- **Skip — no JS/TS project:** When `package.json` does not exist at the repo root, the script exits 0 and produces no output. The check is not relevant to non-JS/TS repos.
- **Skip — npx unavailable:** When `npx` is not in PATH, the script exits 0 and prints a one-line message: `circular-imports: npx not found — skipping (install Node.js to enable this check).`
- **Pass — no cycles:** When madge finds no circular imports, the script exits 0 and prints `circular-imports: OK (no cycles in <dir>)` where `<dir>` is the directory that was checked.
- **Fail — cycles or error:** When madge exits non-zero (cycles found, or a parse error), the script exits 1. Madge's output goes to stdout. A summary line `circular-imports: check failed — cycles or a parse error (see madge output above).` goes to stderr.
