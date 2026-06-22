## Deploy-drift gate (`scripts/deploy-drift-check.sh`, `scripts/ci-verify.sh`)

`deploy-drift-check.sh` reads `deploy-targets.yml` in the target project and
checks that every required entry has a non-empty `drift_check` command. It uses
an awk parser so it works on the `node:22` GitLab CI image without Python.
`ci-verify.sh` calls it as a CI step. The manifest file is created on first
install and never overwritten.

### Confirmed behaviors

- **absent-manifest:** Given `deploy-targets.yml` does not exist in the target
  project, `deploy-drift-check.sh` exits 0 and produces no output. CI passes.
  Projects that have not opted in by creating the manifest are never affected.

- **all-gated:** Given `deploy-targets.yml` exists and every entry has a
  non-empty `drift_check` value, `deploy-drift-check.sh` exits 0 and prints one
  confirmation line per entry in the format `deploy-drift: OK <name>`.

- **required-missing-drift-check:** Given `deploy-targets.yml` contains one or
  more entries where `required` is `true` (or `required` is omitted) and
  `drift_check` is missing or is an empty string, `deploy-drift-check.sh` exits 1
  and prints the name of each failing entry in its error output. All failing
  entries are reported before the script exits. CI blocks.

- **advisory-missing-drift-check:** Given `deploy-targets.yml` contains an entry
  where `required: false` and `drift_check` is missing or is an empty string,
  `deploy-drift-check.sh` prints a warning line in the format
  `deploy-drift: WARN <name>` and exits 0. CI passes.

- **install-creates-manifest:** Given a target project where `deploy-targets.yml`
  does not yet exist, running `scripts/install.sh` creates `deploy-targets.yml`
  from `docs/templates/deploy-targets.yml`. Re-running `install.sh` when
  `deploy-targets.yml` already exists does not overwrite the file. The file is
  recorded in `.claude/.harness-manifest.json` with `"policy": "create-once"`.

- **ci-verify-calls-deploy-drift-check:** `ci-verify.sh` includes a step that
  calls `deploy-drift-check.sh`. The step is present regardless of whether
  `deploy-targets.yml` exists in the project (the script itself handles the
  absent-manifest case with exit 0).
