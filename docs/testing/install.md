## Install system (`scripts/install.sh`, `scripts/sync-harness.sh`, `scripts/install-harness-hooks.sh`)

`install.sh` copies harness files into a target git repo and writes a manifest. `sync-harness.sh`
reads the manifest and updates harness-owned ("copy") files while leaving project-owned
("create-once") files alone. `install-harness-hooks.sh` wires husky into the target's package.json.

### Confirmed behaviors

- **Install creates files and manifest:** Given a valid git repo as the target, `install.sh` copies
  category-1 files, creates category-2 files from templates, and writes `.claude/.harness-manifest.json`.
  Exits 0.

- **Non-git target is rejected:** Given a directory that is not a git repository, `install.sh` exits
  non-zero with a clear message asking the user to run `git init` first.

- **Re-run preserves create-once files:** Given `install.sh` has already run and `CLAUDE.md` exists
  in the target, running `install.sh` again does not overwrite `CLAUDE.md` — it reports "skipped (exists)".

- **Sync updates a copy file:** Given a copy file in the target that matches the manifest sha (unmodified),
  and the same file has changed in the harness source, `sync-harness.sh` overwrites the target file
  and exits 0.

- **Sync skips a create-once file:** Given `CLAUDE.md` exists in the target (unmodified or edited),
  and the template in the harness source has changed, `sync-harness.sh` does not overwrite `CLAUDE.md`.

- **Sync exits non-zero on conflict:** Given a copy file that the user edited locally AND has also
  changed in the harness source (three-way divergence: local != manifest sha != upstream), `sync-harness.sh`
  exits non-zero and prints the file path. The local file is left untouched.

- **Sync leaves a user-only edit alone:** Given a copy file that the user edited but the harness
  source has not changed (local != manifest sha, but manifest sha == upstream sha), `sync-harness.sh`
  exits 0 and does not overwrite the file.

- **Sync re-creates a deleted copy file:** Given a copy file that was deleted from the target,
  `sync-harness.sh` re-creates it from the harness source.

- **Sync re-creates a deleted create-once file:** Given a create-once file (e.g. `CLAUDE.md`) that
  was deleted from the target, `sync-harness.sh` re-creates it from the template.

- **Missing manifest blocks sync:** Given no `.claude/.harness-manifest.json` in the target,
  `sync-harness.sh` exits non-zero with a message telling the user to run `install.sh` first.

- **Hook paths in settings.json exist in the harness tree:** Every hook script path referenced
  in `.claude/settings.json` via `$CLAUDE_PROJECT_DIR/...` exists as a real file.

- **settings.json has no autoMode.environment block:** `autoMode.environment` has been removed;
  project-specific context belongs in `CLAUDE.md`, not in `settings.json`.

- **install-harness-hooks creates package.json when none exists:** Given a target with no
  `package.json`, running `install-harness-hooks.sh` creates one with `prepare` and `test` scripts.

- **install-harness-hooks protects an existing prepare script:** Given a `package.json` that
  already has a `prepare` script, `install-harness-hooks.sh` exits non-zero and prints the
  manual steps rather than overwriting the existing prepare.
