#!/bin/bash
SLUG=$(bash scripts/derive-slug.sh)
if [ ! -f "docs/testing/$SLUG.md" ]; then
  echo "spec-commit: docs/testing/$SLUG.md not found — did the spec writer fail?" >&2
  exit 1
fi
git add "docs/testing/$SLUG.md"
git commit -m "docs(testing): behaviors for $SLUG"
