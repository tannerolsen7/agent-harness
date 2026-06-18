<!-- context-meta
owner: tanner
last-reviewed: 2026-06-17
review-frequency: on-merge
drift-signals:
  - a metric name here no longer matches what scripts/perf-budget.sh measures
  - the default budgets here differ from the defaults in scripts/perf-budget.sh
  - a new metric was added to the script but not documented here
-->

# Performance budget

The performance budget check runs on every build. It measures three Core Web Vitals, compares them to targets, and prints a warning when a target is exceeded. It never blocks the build — a breach is always visible, never silent.

## What are Core Web Vitals?

Core Web Vitals are the three metrics Google uses to measure how fast and stable a page feels to a real user.

| Metric | Stands for | What it measures |
|---|---|---|
| **LCP** | Largest Contentful Paint | How long until the biggest visible piece of content appears. Users notice slow LCP as "the page just sat there." |
| **CLS** | Cumulative Layout Shift | How much the page jumps around while loading. A high CLS means buttons and text move after the user tries to click them. |
| **FID** | First Input Delay | How long the browser is too busy to respond to the first tap or click. A high FID makes the page feel frozen. |

These are the same metrics Lighthouse, PageSpeed Insights, and Chrome DevTools report, so targets here translate directly to those tools.

## Default targets

These are the values `scripts/perf-budget.sh` uses when no project config is present.

| Metric | Default target | Google's "good" threshold |
|---|---|---|
| LCP | 2500 ms | 2500 ms |
| CLS | 0.1 | 0.1 |
| FID | 100 ms | 100 ms |

The defaults match Google's "good" thresholds. Projects that serve users on slow connections or low-end devices should tighten these.

## How to set targets per project

Create a file called `perf-budget.config.sh` at the root of your project (next to `package.json`). Override only the metrics you want to change — unset values fall back to the defaults.

```sh
# perf-budget.config.sh
# Tighter LCP for a landing page that must feel instant.
LCP_BUDGET_MS=1500

# Looser CLS allowed for a legacy page with ads that resize.
CLS_BUDGET=0.15

# FID stays at the default 100 ms.
```

To use a config file at a non-default path:

```sh
bash scripts/perf-budget.sh --config path/to/my-config.sh
```

## How to point the check at a specific URL

By default the script hits `http://localhost:3000`. To measure a staging URL or a preview deployment:

```sh
bash scripts/perf-budget.sh --url https://preview.example.com
```

In CI, run the app in the background first, wait for it to be ready, then call `perf-budget.sh`.

## How measurement works

The script tries `lighthouse` first. If `lighthouse` is not installed, it falls back to `curl` and uses the total request time as a proxy for LCP. In the curl fallback, CLS and FID are not measurable and are set to 0 (safe — they pass automatically). The script never crashes on either path.

| Tool available | LCP | CLS | FID |
|---|---|---|---|
| `lighthouse` | full measurement | full measurement | full measurement |
| `curl` only | request time (proxy) | 0 (not measurable) | 0 (not measurable) |

To get full measurements in CI, install Lighthouse:

```sh
npm install -g lighthouse
```

## What the output looks like

When all metrics are within budget:

```
perf-budget: measuring http://localhost:3000
perf-budget: tool = lighthouse
perf-budget: results
  pass LCP: 1800ms <= budget 2500ms
  pass CLS: 0.05 <= budget 0.1
  pass FID: 60ms <= budget 100ms

perf-budget: OK — all measured metrics are within budget
```

When one metric exceeds its target:

```
perf-budget: measuring http://localhost:3000
perf-budget: tool = lighthouse
perf-budget: results
  WARN LCP: 3100ms > budget 2500ms
  pass CLS: 0.05 <= budget 0.1
  pass FID: 60ms <= budget 100ms

perf-budget: WARNING — one or more metrics exceeded their budget (non-blocking)
```

The exit code is always 0. CI prints the summary; a human decides whether to act on it.

## Where this runs in CI

`scripts/ci-verify.sh` calls `perf-budget.sh` after the test suite. The step is always advisory — CI never fails because of a budget breach. The goal is to make the numbers visible on every PR, not to block shipping.

To see the perf summary for a PR, look at the CI log for the `perf-budget` step.
