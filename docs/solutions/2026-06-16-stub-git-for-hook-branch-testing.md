# Problem: Testing Branch-Dependent Git Hooks Without Real Branch State

**Problem class:** A PreToolUse hook calls `git rev-parse --abbrev-ref HEAD` internally to read the current branch, but the test suite runs inside the real repo — so the branch under test is always whatever branch the test runner is on, making branch-conditional behavior untestable without actually checking out branches.

## When this bites you

You want to verify that `block-dangerous-git.sh` blocks `git commit` on `main` and allows it on `feat/x`. But your CI runs on `feat/main-branch-guard`. Every test that pipes a commit command through the hook will hit the real `git rev-parse` call and get back the CI branch, not the branch you're trying to simulate. You can't force the hook into the "you are on main" code path without either checking out `main` (which modifies repo state and is unsafe in CI) or patching the hook source (which defeats the point of testing the shipped artifact).

The same applies to `git push origin` (bare push): the hook resolves the current branch to decide whether to block. The test cannot control what that resolution returns without controlling what `git` returns.

## Root cause

The hook binary is tested by piping JSON into it as a subprocess. The subprocess inherits `PATH` from the test runner, which means it also inherits the real `git`. The hook calls `git rev-parse --abbrev-ref HEAD` to determine the current branch — and that call goes to the real repo, returning the real branch. The test has no seam to inject a different branch without modifying either the hook or the repo.

## The fix

Create a minimal stub `git` binary in a temp directory, prepend that directory to `PATH` when invoking the hook, and let the stub answer only the one call the hook actually makes.

`make_stub()` in `tests/main-branch-guard.test.sh`:

```bash
make_stub() {
  local dir="$1" branch="$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\n[ "$1" = "rev-parse" ] && [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ] && { echo "%s"; exit 0; }\necho "stub: unsupported git call: $*" >&2; exit 1\n' \
    "$branch" > "$dir/git"
  chmod +x "$dir/git"
}

STUB_MAIN=$(mktemp -d);    make_stub "$STUB_MAIN"   "main"
STUB_FEAT=$(mktemp -d);    make_stub "$STUB_FEAT"   "feat/my-feature"
trap 'rm -rf "$STUB_MAIN" "$STUB_FEAT"' EXIT
```

Invocation in `run()`:

```bash
printf '%s' "$json" | PATH="$stub:$PATH" bash "$HOOK" >/dev/null 2>&1; rc=$?
```

The stub intercepts `git rev-parse --abbrev-ref HEAD`, returns the controlled branch name, and exits 1 noisily for any other git call — so an unanticipated call is immediately visible in test stderr rather than silently succeeding or corrupting state.

Tests that do not need branch simulation pass no stub, so `$stub` is empty and `PATH` is unmodified — existing protections (explicit refspec push, force push) continue to use the real git.

## How to know it's working

Run the test directly:

```
bash tests/main-branch-guard.test.sh
```

A passing run prints `main-branch-guard: N passed, 0 failed`. If the stub is wired incorrectly (wrong argument matching), the hook's `git rev-parse` call will hit the real git and the branch-conditional cases will fail or pass for the wrong reason — the stub's `exit 1` fallback will also print `stub: unsupported git call: ...` to stderr, which surfaces the mismatch.

## The regression gate

File: `tests/main-branch-guard.test.sh`

What it checks:
- `git commit` on `main`/`master`/`develop` → exit 2 (BLOCK)
- `git commit` on `feat/*` → exit 0 (ALLOW)
- `git push` (no args) on protected branch → BLOCK
- `git push origin` (remote-only) on protected branch → BLOCK
- `git push origin HEAD` on protected branch → BLOCK (HEAD resolved via stub)
- `git push origin feat/x` → ALLOW (explicit safe refspec, no stub needed)
- Force-push variants and explicit-refspec push to main → still BLOCK (unchanged protections)

Four stubs are created at test startup: `main`, `master`, `develop`, `feat/my-feature`. Each is a temp dir that survives only the test run; `trap ... EXIT` cleans them up.

## The invariant (replicate this when adding branch-dependent hook logic)

Any hook code path that calls `git rev-parse --abbrev-ref HEAD` to make a block/allow decision must be tested via a stub, not via real repo state. The pattern is always:

1. `make_stub <tmpdir> <branch-name>` — creates a `git` binary that answers only `rev-parse --abbrev-ref HEAD`
2. `PATH="<tmpdir>:$PATH" bash "$HOOK"` — prepend the stub dir, not replace PATH
3. `trap 'rm -rf ...' EXIT` — always clean up

Never test branch-conditional behavior by checking out the branch in CI. Never write the hook to accept a branch override via env var (that changes the shipped artifact). The stub technique tests the real hook code through the real PATH override, which is the actual mechanism the OS uses.

## What doesn't work

**Reading `GIT_DIR` from the environment:** If the test inherits `GIT_DIR` from an outer `git` process (e.g., running inside a git hook or certain CI wrappers), `git rev-parse` may operate on the wrong repo or fail entirely. The stub sidesteps this: it never calls real git, so `GIT_DIR` is irrelevant. See `reference-git-hook-env-pollutes-tests.md` for the broader GIT_DIR contamination problem.

**Patching the hook to accept a `BRANCH_OVERRIDE` env var:** Makes the test exercise a code path that doesn't exist in production. The hook that runs in Claude Code is not the hook you tested.

**Checking out `main` in the test setup:** Mutates the repo. Breaks under concurrent test runs. Leaves the repo on a different branch if the test crashes mid-run.

**Using `--abbrev-ref HEAD` against a bare or freshly-init'd temp repo:** The call returns `HEAD` (detached) rather than a branch name, so you cannot use a temp repo as a branch simulator.

---

# Problem: Push Guard Refspec Bypass Taxonomy

**Problem class:** A git push guard that only inspects explicit refspec arguments silently allows pushes that git resolves implicitly — covering only named refs while leaving bare pushes and `HEAD` unguarded.

## When this bites you

You add `git push origin main` to the block list and it works. Then you notice `git push origin` (no refspec) and `git push origin HEAD` while on `main` both pass through. The guard looks complete because it handles the "obvious" attack vector but misses the two forms that git resolves at runtime.

## Root cause

Git has three push forms that all push to the same destination when on `main`:

| Command | Refspec present? | How destination is chosen |
|---|---|---|
| `git push origin main` | Yes (explicit) | The literal string `main` is matched against the block list |
| `git push origin HEAD` | Yes (symbolic) | `HEAD` is a symbolic ref, not in the block list; resolves at git runtime |
| `git push origin` | No | Git infers current branch from tracking config; no refspec to inspect |
| `git push` | No | Same — remote also inferred |

The original guard only looped over arguments to `norm_ref()`. `norm_ref()` strips quote chars, takes the `:dst` half of a `src:dst` refspec, and strips `refs/heads/`. It never resolves `HEAD` to an actual branch name, so `norm_ref("HEAD")` returns `"HEAD"`, which is not in `main|master|develop`. And for bare pushes, there are zero non-flag args that contain a colon, so the loop body never matches anything.

## The fix

Two additions to the `push)` case in `.claude/hooks/block-dangerous-git.sh`:

**1. Resolve HEAD after `norm_ref()`:**

```sh
_ref=$(norm_ref "$a")
[ "$_ref" = "HEAD" ] && _ref=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
case "$_ref" in main|master|develop) block "..." ;; esac
```

**2. Detect bare pushes using non-flag arg count and colon presence:**

```sh
_non_flag=0; _has_colon=0
for a in "$@"; do
  case "$a" in -*) continue ;; esac
  _non_flag=$((_non_flag+1))
  # ... norm_ref + HEAD resolution ...
  case "$a" in *:*) _has_colon=1 ;; esac
done
if [ "$_has_colon" -eq 0 ] && [ "$_non_flag" -le 1 ]; then
  _cur=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  case "$_cur" in main|master|develop) block "..." ;; esac
fi
```

The bare-push heuristic: if no non-flag argument contains a colon AND there is at most one non-flag argument (the optional remote name), git is inferring the push destination from the current branch. Block if that branch is protected.

## How to know it's working

```
bash tests/main-branch-guard.test.sh
```

Specifically, these cases exercise the two new paths:
- `git push origin HEAD` on main → BLOCK (HEAD resolution path)
- `git push origin` on main → BLOCK (bare-push path, one non-flag arg)
- `git push` on main → BLOCK (bare-push path, zero non-flag args)

## The regression gate

`tests/main-branch-guard.test.sh`, section `── bare push guard ──` and `── existing protections unchanged ──`. The existing-protections section verifies that `git push origin main` (the original explicit-refspec block) is still caught — preventing a regression where fixing the new gaps breaks the old check.

## The invariant (replicate this when extending push guards)

Every new push form must be classified against three axes before deciding how to check it:

1. **Explicit named ref** (`push origin main`) — caught by `norm_ref()` loop
2. **Symbolic ref** (`push origin HEAD`, `push origin @{upstream}`) — must resolve via `git rev-parse` after `norm_ref()` returns the symbol
3. **No refspec** (`push origin`, `push`) — must check current branch via `git rev-parse --abbrev-ref HEAD` as a fallback when `_non_flag <= 1` and `_has_colon == 0`

If you add a new protection (e.g., block push to `release/*`), make sure it is tested against all three forms, not just the explicit one.

## What doesn't work

**Checking `norm_ref("HEAD") in protected_list`:** `norm_ref` does not resolve symbolic refs. It does string manipulation only (strip quotes, take `:dst`, strip `refs/heads/`). HEAD is not in the protected list and will never be matched this way.

**Counting args to detect bare pushes:** `git push -u origin` has two non-flag args after stripping `-u` — but `_non_flag` counts non-flag args, so `-u` is excluded and `origin` is the only non-flag arg (`_non_flag == 1`). The heuristic correctly catches this. But `git push origin HEAD` has two non-flag args (`origin` and `HEAD`) — so the bare-push fallback does NOT fire for this case; it is instead caught by the HEAD-resolution path in the loop. The two paths are complementary, not redundant.

## Tags

git-hooks, push-guard, refspec, HEAD-resolution, bare-push, branch-protection, PreToolUse, stub-testing
