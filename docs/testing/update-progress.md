## Progress auto-updater (`scripts/update-progress.sh`)

The script updates the mechanical fields in `harness-progress.html` —
the date, PR count, and progress bar — and writes a visible "last
auto-updated" line so you can tell at a glance that it ran and what changed.

### Confirmed behaviors

- **Last-updated line shows time and what changed:** Given `harness-progress.html`
  has an `auto-update-status` element, when `update-progress.sh` runs, it replaces
  that element's text with "Last auto-updated: [date] at [time] · [old]→[new] PRs"
  when the PR count changed, or "Last auto-updated: [date] at [time] · [N] PRs (no change)"
  when the count was already current.
