#!/bin/sh
# Register the local git merge drivers declared in .gitattributes.
# Called automatically by npm prepare (runs on npm install / npm ci).
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
git -C "$ROOT" config merge.ours.driver "true"
git -C "$ROOT" config merge.tasks-higher-state.name "TASKS.md higher-state-wins driver"
git -C "$ROOT" config merge.tasks-higher-state.driver "sh scripts/tasks-merge-driver.sh %O %A %B"
echo "register-merge-drivers: merge drivers registered in .git/config"
