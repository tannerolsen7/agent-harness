## Performance budget (`scripts/perf-budget.sh`)

Measures Core Web Vitals (LCP, CLS, INP) against per-project targets. Exits 1 when any metric
exceeds its budget so `ci-verify.sh` can catch the breach with `||`; exits 0 when all metrics
pass. Never blocks the build — advisory only.

### Confirmed behaviors

- **Pass path:** When all three metrics are within budget, exits 0, prints a `pass` line for each metric, and prints the `OK` summary. No `WARN` lines appear in the output.
- **Warn path:** When a metric exceeds its budget, exits 1, prints a `WARN` line naming the metric and showing the measured value vs the budget, and prints the `WARNING` summary.
- **Config override:** A `perf-budget.config.sh` file at the project root overrides the default budgets. A metric that passes the default but fails the tighter config triggers a `WARN` line.
- **Curl fallback:** When `lighthouse` is not available, the script measures LCP via `curl` response time and sets CLS and INP to 0 (they cannot be measured without a browser). CLS and INP always pass in curl mode.
