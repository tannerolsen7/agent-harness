#!/usr/bin/env bash
# Reads .claude/activity/*.jsonl and writes harness-activity.html.
# Skips malformed lines — one bad line must not break the report.
# Run from any directory; uses git to find the repo root.
set -euo pipefail

# Clear inherited git env so hooks don't point git at the wrong object store.
unset GIT_DIR GIT_WORK_TREE

REPO_ROOT="$(git rev-parse --show-toplevel)"
ACTIVITY_DIR="$REPO_ROOT/.claude/activity"
HTML="$REPO_ROOT/harness-activity.html"

DATE=$(date +"%B %-d, %Y")
TIME=$(date +"%-I:%M %p")

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Collect valid records from every JSONL file. Skip empty lines and lines that
# fail JSON parsing — one bad line must not abort the whole report.
if [ -d "$ACTIVITY_DIR" ]; then
  for f in "$ACTIVITY_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if printf '%s' "$line" | jq -e 'type == "object"' >/dev/null 2>&1; then
        printf '%s\n' "$line"
      else
        printf 'activity-report: skipping bad line in %s\n' "$f" >&2
      fi
    done < "$f"
  done
fi > "$TMP"

# One jq pass: sort newest-first, compute summary stats, render table rows.
JQ_OUT=$(jq -s '
  sort_by(.ts // "") | reverse |
  . as $recs |
  {
    total: ($recs | length),
    avg_dur: (
      [$recs[] | select(.duration_s != null and (.duration_s | type) == "number") | .duration_s] |
      if length > 0 then (add / length | floor | tostring) + "s" else "—" end
    ),
    top_skills: (
      [$recs[] | .skills // [] | .[]] |
      group_by(.) | map({k: .[0], n: length}) | sort_by(-.n) | .[0:3] | map(.k) |
      if length > 0 then join(", ") else "—" end
    ),
    rows: (
      if ($recs | length) == 0 then
        "<tr><td colspan=\"6\" class=\"empty\">No sessions recorded yet</td></tr>"
      else
        ($recs | map(
          "<tr>" +
          "<td>" + (.ts // "—") + "</td>" +
          "<td class=\"branch\">" + (.branch // "—") + "</td>" +
          "<td><code>" + ((.sha // "???????") | .[0:7]) + "</code></td>" +
          "<td>" + (.model // "—") + "</td>" +
          "<td>" + ((.skills // []) | join(", ") | if . == "" then "—" else . end) + "</td>" +
          "<td class=\"dur\">" + (if .duration_s == null then "—" else (.duration_s | tostring) + "s" end) + "</td>" +
          "</tr>"
        ) | join("\n      "))
      end
    )
  }
' "$TMP")

TOTAL=$(printf '%s' "$JQ_OUT" | jq -r '.total')
AVG_DUR=$(printf '%s' "$JQ_OUT" | jq -r '.avg_dur')
TOP_SKILLS=$(printf '%s' "$JQ_OUT" | jq -r '.top_skills')
ROWS=$(printf '%s' "$JQ_OUT" | jq -r '.rows')

STATUS="Last updated: ${DATE} at ${TIME} · ${TOTAL} session(s) recorded"

cat > "$HTML" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Agent Harness — AI Activity</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f5f5f5;
      color: #1a1a1a;
      padding: 40px 20px 80px;
    }

    .page { max-width: 900px; margin: 0 auto; }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 28px;
    }
    .page-header h1 { font-size: 26px; font-weight: 700; letter-spacing: -0.4px; }
    .page-header .subtitle { font-size: 14px; color: #666; margin-top: 4px; }
    .page-header .date { font-size: 14px; color: #888; white-space: nowrap; padding-top: 4px; }

    .summary-bar {
      background: #fff;
      border: 1px solid #e5e5e5;
      border-radius: 10px;
      padding: 18px 24px;
      display: flex;
      gap: 36px;
      margin-bottom: 28px;
      flex-wrap: wrap;
    }
    .stat { display: flex; flex-direction: column; gap: 2px; }
    .stat-label { font-size: 11px; font-weight: 700; letter-spacing: 0.07em; text-transform: uppercase; color: #999; }
    .stat-value { font-size: 20px; font-weight: 700; color: #1a1a1a; }

    .auto-update-status {
      font-size: 11px; color: #aaa; font-style: italic; margin-bottom: 20px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      background: #fff;
      border: 1px solid #e5e5e5;
      border-radius: 10px;
      overflow: hidden;
      font-size: 13.5px;
    }
    thead th {
      text-align: left;
      padding: 10px 14px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.07em;
      text-transform: uppercase;
      color: #999;
      border-bottom: 1px solid #e5e5e5;
      background: #fafafa;
    }
    tbody tr { border-top: 1px solid #f0f0f0; }
    tbody tr:first-child { border-top: none; }
    tbody tr:hover { background: #fafafa; }
    tbody td { padding: 10px 14px; vertical-align: top; }
    td.branch { font-size: 12px; color: #555; word-break: break-all; max-width: 180px; }
    td.dur { text-align: right; color: #555; }
    code { font-family: "SF Mono", "Fira Code", monospace; font-size: 12px; color: #6d28d9; }
    td.empty { text-align: center; color: #aaa; padding: 24px; }
  </style>
</head>
<body>
<div class="page">

  <div class="page-header">
    <div>
      <h1>AI Activity</h1>
      <div class="subtitle">One record per top-level session stop, newest first</div>
    </div>
    <div class="date">${DATE}</div>
  </div>

  <div class="summary-bar">
    <div class="stat">
      <div class="stat-label">Total sessions</div>
      <div class="stat-value">${TOTAL}</div>
    </div>
    <div class="stat">
      <div class="stat-label">Top skills</div>
      <div class="stat-value" style="font-size:15px;padding-top:4px">${TOP_SKILLS}</div>
    </div>
    <div class="stat">
      <div class="stat-label">Avg duration</div>
      <div class="stat-value">${AVG_DUR}</div>
    </div>
  </div>

  <div class="auto-update-status">${STATUS}</div>

  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Branch</th>
        <th>SHA</th>
        <th>Model</th>
        <th>Skills</th>
        <th style="text-align:right">Duration</th>
      </tr>
    </thead>
    <tbody>
      ${ROWS}
    </tbody>
  </table>

</div>
</body>
</html>
HTMLEOF

echo "harness-activity.html updated: ${TOTAL} session(s), avg ${AVG_DUR}, top skills: ${TOP_SKILLS}"
