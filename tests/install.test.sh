#!/usr/bin/env bash
# Tests for the one-command install + sync system. Each block sets up a throwaway git repo
# (mktemp) as the install TARGET and points HARNESS_SRC at a throwaway harness source, so no
# real files are touched. We never use the real harness tree as the source — drift tests need
# to mutate the source freely.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
INSTALL="$ROOT/scripts/install.sh"
SYNC="$ROOT/scripts/sync-harness.sh"
HOOKS="$ROOT/scripts/install-harness-hooks.sh"

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE

pass=0; fail=0
ck() { if [ "$1" = 0 ]; then pass=$((pass+1)); else echo "  MISS: $2"; fail=$((fail+1)); fi; }
cleanup() { for d in "$@"; do [ -n "$d" ] && [ -d "$d" ] && chmod -R u+w "$d" 2>/dev/null; rm -r "$d" 2>/dev/null; done; }

[ -f "$INSTALL" ] || { echo "test: $INSTALL not found"; exit 1; }
[ -f "$SYNC" ]    || { echo "test: $SYNC not found"; exit 1; }
[ -f "$HOOKS" ]   || { echo "test: $HOOKS not found"; exit 1; }

CLDIR=".claude"

make_src() {
  local src="$1"
  mkdir -p "$src/scripts" "$src/$CLDIR/skills" "$src/docs/templates" "$src/$CLDIR/hooks"
  printf 'v1 skill body\n' > "$src/$CLDIR/skills/example.md"
  printf 'CLAUDE template v1\n' > "$src/docs/templates/CLAUDE.md"
  printf 'PITFALLS template v1\n' > "$src/docs/templates/PITFALLS.md"
  printf 'AGENTS template v1\n' > "$src/docs/templates/AGENTS.md"
  printf 'CONTEXT template v1\n' > "$src/docs/templates/CONTEXT.md"
  cp "$INSTALL" "$src/scripts/install.sh"
  cp "$SYNC" "$src/scripts/sync-harness.sh"
  printf 'hook body\n' > "$src/$CLDIR/hooks/example-hook.sh"
  printf '%s\n' '{ "hooks": { "PreToolUse": [ { "hooks": [ { "type": "command", "command": "PROJDIR/CLD/hooks/example-hook.sh" } ] } ] } }' \
    | sed "s#PROJDIR#\$CLAUDE_PROJECT_DIR#; s#CLD#$CLDIR#" > "$src/$CLDIR/settings.json"
}

make_target() {
  local tgt="$1"
  mkdir -p "$tgt"
  ( cd "$tgt" && git init -q && git config user.email t@t.t && git config user.name t )
}

echo "── install: writes files + manifest ──"
SRC=$(mktemp -d); TGT=$(mktemp -d); make_src "$SRC"; make_target "$TGT"
HARNESS_SRC="$SRC" bash "$INSTALL" "$TGT" >/dev/null 2>&1; rc=$?
ck "$rc" "install exits 0 on a git repo target"
[ -f "$TGT/$CLDIR/.harness-manifest.json" ]; ck "$?" "manifest written"
[ -f "$TGT/$CLDIR/skills/example.md" ]; ck "$?" "category-1 copy file installed"
[ -f "$TGT/CLAUDE.md" ]; ck "$?" "category-2 create-once file installed from template"
if command -v jq >/dev/null 2>&1; then
  MAN="$TGT/$CLDIR/.harness-manifest.json"
  jq -e '.schema == 1' "$MAN" >/dev/null 2>&1; ck "$?" "manifest schema is 1"
  jq -e '.files["CLAUDE.md"].policy == "create-once"' "$MAN" >/dev/null 2>&1; ck "$?" "CLAUDE.md recorded as create-once"
  jq -e ".files[\"$CLDIR/skills/example.md\"].policy == \"copy\"" "$MAN" >/dev/null 2>&1; ck "$?" "skill recorded as copy"
fi

echo "── install: rejects a non-git target ──"
SRC2=$(mktemp -d); TGT2=$(mktemp -d); make_src "$SRC2"
HARNESS_SRC="$SRC2" bash "$INSTALL" "$TGT2" >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && ck 0 "install exits non-zero when target is not a git repo" \
  || { echo "  MISS: install should reject a non-git target"; fail=$((fail+1)); }

echo "── install re-run: create-once is preserved ──"
printf 'USER EDITED CLAUDE\n' > "$TGT/CLAUDE.md"
HARNESS_SRC="$SRC" bash "$INSTALL" "$TGT" >/dev/null 2>&1
[ "$(cat "$TGT/CLAUDE.md")" = "USER EDITED CLAUDE" ]; ck "$?" "re-run does not clobber an existing create-once file"

echo "── sync: missing manifest ──"
TGT3=$(mktemp -d); make_target "$TGT3"
HARNESS_SRC="$SRC" bash "$SYNC" "$TGT3" >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && ck 0 "sync exits non-zero with no manifest" \
  || { echo "  MISS: sync should require a manifest"; fail=$((fail+1)); }

echo "── sync: updates copy file, skips create-once ──"
SRC4=$(mktemp -d); TGT4=$(mktemp -d); make_src "$SRC4"; make_target "$TGT4"
HARNESS_SRC="$SRC4" bash "$INSTALL" "$TGT4" >/dev/null 2>&1
printf 'v2 skill body CHANGED\n' > "$SRC4/$CLDIR/skills/example.md"
printf 'CLAUDE template v2\n' > "$SRC4/docs/templates/CLAUDE.md"
HARNESS_SRC="$SRC4" bash "$SYNC" "$TGT4" >/dev/null 2>&1; rc=$?
ck "$rc" "sync exits 0 when there are no conflicts"
[ "$(cat "$TGT4/$CLDIR/skills/example.md")" = "v2 skill body CHANGED" ]; ck "$?" "copy file updated to upstream"
[ "$(cat "$TGT4/CLAUDE.md")" = "CLAUDE template v1" ]; ck "$?" "create-once file NOT updated even though upstream changed"

echo "── sync --dry-run ──"
SRC5=$(mktemp -d); TGT5=$(mktemp -d); make_src "$SRC5"; make_target "$TGT5"
HARNESS_SRC="$SRC5" bash "$INSTALL" "$TGT5" >/dev/null 2>&1
printf 'v2 dry\n' > "$SRC5/$CLDIR/skills/example.md"
HARNESS_SRC="$SRC5" bash "$SYNC" --dry-run "$TGT5" >/dev/null 2>&1
[ "$(cat "$TGT5/$CLDIR/skills/example.md")" = "v1 skill body" ]; ck "$?" "--dry-run leaves files unchanged"

echo "── sync: conflict ──"
SRC6=$(mktemp -d); TGT6=$(mktemp -d); make_src "$SRC6"; make_target "$TGT6"
HARNESS_SRC="$SRC6" bash "$INSTALL" "$TGT6" >/dev/null 2>&1
printf 'LOCAL EDIT\n' > "$TGT6/$CLDIR/skills/example.md"
printf 'UPSTREAM EDIT\n' > "$SRC6/$CLDIR/skills/example.md"
out=$(HARNESS_SRC="$SRC6" bash "$SYNC" "$TGT6" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ck 0 "sync exits non-zero on a conflict" \
  || { echo "  MISS: sync must fail on conflict"; fail=$((fail+1)); }
printf '%s' "$out" | grep -q "example.md" && ck 0 "conflict output names the file path" \
  || { echo "  MISS: conflict must print the file path"; fail=$((fail+1)); }
[ "$(cat "$TGT6/$CLDIR/skills/example.md")" = "LOCAL EDIT" ]; ck "$?" "conflict leaves the local file untouched"

echo "── sync: re-creates a deleted copy file ──"
SRC7=$(mktemp -d); TGT7=$(mktemp -d); make_src "$SRC7"; make_target "$TGT7"
HARNESS_SRC="$SRC7" bash "$INSTALL" "$TGT7" >/dev/null 2>&1
rm "$TGT7/$CLDIR/skills/example.md"
HARNESS_SRC="$SRC7" bash "$SYNC" "$TGT7" >/dev/null 2>&1
[ -f "$TGT7/$CLDIR/skills/example.md" ]; ck "$?" "deleted copy file re-created on sync"

echo "── sync: re-creates a deleted create-once file ──"
SRC8=$(mktemp -d); TGT8=$(mktemp -d); make_src "$SRC8"; make_target "$TGT8"
HARNESS_SRC="$SRC8" bash "$INSTALL" "$TGT8" >/dev/null 2>&1
rm "$TGT8/CLAUDE.md"
HARNESS_SRC="$SRC8" bash "$SYNC" "$TGT8" >/dev/null 2>&1
[ -f "$TGT8/CLAUDE.md" ]; ck "$?" "deleted create-once file re-created from template on sync"

echo "── hook paths in settings.json are all installed ──"
SETTINGS="$ROOT/$CLDIR/settings.json"
miss=0
while IFS= read -r hookpath; do
  [ -z "$hookpath" ] && continue
  [ -f "$ROOT/$hookpath" ] || { echo "  MISS: settings.json references $hookpath but it is not in the tree"; miss=1; }
done < <(grep -oE '\$CLAUDE_PROJECT_DIR/[^"]+\.sh' "$SETTINGS" | sed 's#\$CLAUDE_PROJECT_DIR/##' | sort -u)
[ "$miss" = 0 ] && ck 0 "every hook path in settings.json exists in the tree" \
  || { fail=$((fail+1)); }

echo "── settings.json env block removed ──"
if command -v jq >/dev/null 2>&1; then
  jq -e '.autoMode.environment == null' "$SETTINGS" >/dev/null 2>&1 && ck 0 "autoMode.environment removed from settings.json" \
    || { echo "  MISS: settings.json still has autoMode.environment — must move to CLAUDE.md"; fail=$((fail+1)); }
fi

echo "── install-harness-hooks: creates package.json ──"
TGT9=$(mktemp -d); make_target "$TGT9"
_HARNESS_SKIP_NPM=1 bash "$HOOKS" "$TGT9" >/dev/null 2>&1
[ -f "$TGT9/package.json" ]; ck "$?" "package.json created when none exists"
if command -v jq >/dev/null 2>&1 && [ -f "$TGT9/package.json" ]; then
  jq -e '.scripts.prepare and .scripts.test' "$TGT9/package.json" >/dev/null 2>&1; ck "$?" "prepare + test scripts added"
fi

echo "── install-harness-hooks: protects an existing prepare ──"
TGT10=$(mktemp -d); make_target "$TGT10"
printf '%s\n' '{ "scripts": { "prepare": "echo mine" } }' > "$TGT10/package.json"
_HARNESS_SKIP_NPM=1 bash "$HOOKS" "$TGT10" >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && ck 0 "exits non-zero rather than overwrite an existing prepare script" \
  || { echo "  MISS: must not overwrite an existing prepare script"; fail=$((fail+1)); }
grep -q "echo mine" "$TGT10/package.json"; ck "$?" "existing prepare script left intact"

echo "── sync: leaves a user-only edit alone (upstream unchanged) ──"
SRC11=$(mktemp -d); TGT11=$(mktemp -d); make_src "$SRC11"; make_target "$TGT11"
HARNESS_SRC="$SRC11" bash "$INSTALL" "$TGT11" >/dev/null 2>&1
printf 'LOCAL EDIT ONLY\n' > "$TGT11/$CLDIR/skills/example.md"
HARNESS_SRC="$SRC11" bash "$SYNC" "$TGT11" >/dev/null 2>&1; rc=$?
ck "$rc" "sync exits 0 when the user edited a copy file but upstream did not change"
[ "$(cat "$TGT11/$CLDIR/skills/example.md")" = "LOCAL EDIT ONLY" ]; ck "$?" "user-only edit is preserved, not clobbered"

cleanup "$SRC" "$TGT" "$SRC2" "$TGT2" "$TGT3" "$SRC4" "$TGT4" "$SRC5" "$TGT5" \
        "$SRC6" "$TGT6" "$SRC7" "$TGT7" "$SRC8" "$TGT8" "$TGT9" "$TGT10" \
        "$SRC11" "$TGT11"

echo ""
echo "install: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
