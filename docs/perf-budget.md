# Performance budget — Core Web Vitals

This document explains how the harness tracks Core Web Vitals (CWV) across projects, what the targets mean, and how to wire up real measurements.

## What Core Web Vitals are

Google defines three CWV metrics that measure whether a web page feels fast to real users:

| Metric | What it measures | "Good" threshold |
|--------|-----------------|-----------------|
| **LCP** (Largest Contentful Paint) | How long until the main image or text block is visible | ≤ 2500ms |
| **INP** (Interaction to Next Paint) | How long the page takes to respond to a click, tap, or keypress | ≤ 200ms |
| **CLS** (Cumulative Layout Shift) | How much visible content jumps around unexpectedly during load | ≤ 0.1 (unitless score) |

The harness also tracks two supporting metrics:

| Metric | What it measures | "Good" threshold |
|--------|-----------------|-----------------|
| **FCP** (First Contentful Paint) | How long until the first text or image appears | ≤ 1800ms |
| **TTFB** (Time to First Byte) | How long until the browser receives the first byte of the page | ≤ 800ms |

## Where targets live

All targets are in `config/perf-budget.json`. Each project gets its own entry under `"projects"`. If no entry exists for a project, the `"default"` entry applies.

```json
{
  "projects": {
    "default": {
      "LCP_ms":  2500,
      "INP_ms":  200,
      "CLS":     0.1,
      "FCP_ms":  1800,
      "TTFB_ms": 800
    },
    "my-project": {
      "LCP_ms":  1500,
      "INP_ms":  150,
      "CLS":     0.05,
      "FCP_ms":  1000,
      "TTFB_ms": 500
    }
  }
}
```

To add a project: copy the `"default"` block, rename the key to your project name, and adjust the thresholds to match your SLO or user expectations. Document why the numbers differ from the defaults — the config is the record.

## How the check runs

`scripts/perf-budget.sh` does the comparison. It reads the targets from `config/perf-budget.json`, takes measured values as inputs, and prints a per-metric PASS/WARN/SKIP result.

Check your current targets without measuring anything:

```bash
cd <repo-root> && bash scripts/perf-budget.sh --dry-run
cd <repo-root> && bash scripts/perf-budget.sh --project my-project --dry-run
```

Run with explicit values:

```bash
cd <repo-root> && bash scripts/perf-budget.sh \
  --project my-project \
  --lcp 1800 --inp 95 --cls 0.04 --fcp 900 --ttfb 210
```

Run with a data file (see format below):

```bash
cd <repo-root> && bash scripts/perf-budget.sh --project my-project --data perf-data.json
```

### Data file format

```json
{
  "LCP_ms":  1800,
  "INP_ms":  95,
  "CLS":     0.04,
  "FCP_ms":  900,
  "TTFB_ms": 210
}
```

You only need to include the metrics you have data for. Any metric not present is skipped (SKIP), not failed.

## Logs

Every run writes a log to `logs/perf-budget/`. The log name includes the timestamp and project name. A `latest_PROJECT.log` symlink always points to the most recent run.

```
logs/perf-budget/2026-06-17_10-30-00_default.log
logs/perf-budget/latest_default.log  → (symlink)
```

A log entry looks like:

```
perf-budget run
project:   default
timestamp: 2026-06-17_10-30-00
targets:   LCP=2500ms INP=200ms CLS=0.1 FCP=1800ms TTFB=800ms
---
2026-06-17_10-30-00  LCP   PASS  val=1800 target=2500
2026-06-17_10-30-00  INP   WARN  val=250 target=200
2026-06-17_10-30-00  CLS   PASS  val=0.04 target=0.1
---
checked:  3
breached: 1
```

The `logs/` directory should be in `.gitignore` for projects that run many builds. For audit purposes, you can commit log snapshots by hand.

## CI integration

`scripts/ci-verify.sh` calls `perf-budget.sh` as a non-blocking advisory step. A breach prints WARN lines in CI output but does not fail the build. This is intentional: budgets are a signal, not a hard gate, until the team has confidence in the measurement pipeline.

To enable the CI step, set `PERF_DATA_FILE` in your CI environment to the path of a file containing measured vitals in the format above. If `PERF_DATA_FILE` is unset, the step prints a reminder and moves on.

### GitHub Actions example

```yaml
- name: Run Lighthouse CI
  run: lhci collect

- name: Export vitals for perf-budget
  run: |
    node scripts/export-lhci-vitals.js > perf-data.json
  # This script reads the Lighthouse JSON output and writes a perf-budget data file.

- name: CI verify (includes perf budget)
  run: bash scripts/ci-verify.sh
  env:
    PERF_DATA_FILE: perf-data.json
    PERF_PROJECT: my-project
```

### GitLab CI example

```yaml
verify:
  script:
    - lhci collect
    - node scripts/export-lhci-vitals.js > perf-data.json
    - PERF_DATA_FILE=perf-data.json PERF_PROJECT=my-project bash scripts/ci-verify.sh
```

## Collecting real measurements

The script does not collect measurements itself — it only compares values you supply. Real CWV data comes from tools like:

- **[Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)** — runs Lighthouse in CI and produces JSON with all five metrics.
- **[web-vitals](https://github.com/GoogleChrome/web-vitals)** — a JavaScript library that reports real-user CWV from the browser. Export the results to your analytics platform and pull the P75 values into a data file.
- **Chrome DevTools / PageSpeed Insights** — manual runs; paste the values into the data file by hand for one-off checks.

Until a measurement pipeline is wired up, run the script in `--dry-run` mode to verify targets are configured, and supply values manually when you do a Lighthouse audit.

## Making a breach block CI

Today the check is non-blocking. To make it block:

1. Confirm the measurement pipeline is reliable (stable values across runs, not flaky from network variance).
2. Change the `|| true` guard in `scripts/ci-verify.sh` so a non-zero exit from `perf-budget.sh` propagates.
3. Update `perf-budget.sh` to exit non-zero when `BREACHED > 0`.
4. Protect the branch so CI must be green before merging (GitHub: branch protection → required status checks; GitLab: "Pipelines must succeed").

Do not make the breach block before step 1 is done. A flaky measurement that randomly fails CI is worse than a non-blocking warning.

## Relationship to the /perf skill

The `/perf` skill is for optimizing a known, measured bottleneck in your code. The perf budget is for tracking whether the overall page experience stays within agreed targets across all builds.

Use the perf budget to detect regressions early. Use `/perf` to fix a specific bottleneck once detected.
