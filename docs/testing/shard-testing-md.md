## TESTING.md sharding (`scripts/assemble-testing.sh`)

Splits `docs/TESTING.md` into per-feature shard files under `docs/testing/<slug>.md`.
`assemble-testing.sh` rebuilds `docs/TESTING.md` from all shards in alphabetical
order. A pre-commit hook keeps the assembled file in sync automatically whenever
shards are staged.

### Confirmed behaviors

- **Assembly produces canonical file from shards:** Given one or more
  `docs/testing/*.md` files exist, when `scripts/assemble-testing.sh` runs, it
  writes `docs/TESTING.md` with a generated-file header at the top, followed by
  each shard's content in alphabetical filename order, with `---` dividers
  separating each shard.

- **Assembly is idempotent:** Running `scripts/assemble-testing.sh` a second time
  without changing any shard files produces a `docs/TESTING.md` that is byte-for-byte
  identical to the one produced by the first run. No timestamp or random value is
  injected.

- **Slug strips `feat/` prefix only:** Given a branch name starting with `feat/`,
  the slug is derived by removing that prefix before applying the remaining
  transformations. A branch named `fix/auth-bug` retains `fix-` in the slug because
  only the `feat/` prefix is stripped — no other prefix is removed.

- **Slug lowercases, replaces non-word characters, collapses hyphens, and trims
  edges:** After prefix stripping, the slug is lowercased, all slashes and
  non-word characters are replaced with hyphens, consecutive hyphens are collapsed
  to one, and leading and trailing hyphens are removed. For example,
  `feat/auth/login-v2` produces `auth-login-v2` and `fix/auth-bug` produces
  `fix-auth-bug`.

- **Pre-commit hook regenerates assembled file when shards are staged:** Given one
  or more `docs/testing/*.md` files are staged for commit, when the pre-commit hook
  runs, it executes `bash scripts/assemble-testing.sh` and stages `docs/TESTING.md`
  automatically. The commit completes without any manual step from the developer.
