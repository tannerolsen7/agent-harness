#!/usr/bin/env bash
# Test matrix for block-credential-read.sh (the credential firewall, CRITICAL-1).
# block = exit 2, allow = exit 0. Also asserts fail-closed when jq is absent.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.claude/hooks/block-credential-read.sh"
BASH_BIN=$(command -v bash)
command -v jq >/dev/null 2>&1 || { echo "test: jq required"; exit 1; }
[ -f "$HOOK" ] || { echo "test: $HOOK not found"; exit 1; }

pass=0; fail=0
run() {
  local expect="$1" cmd="$2" json rc
  json=$(jq -nc --arg c "$cmd" '{tool_input:{command:$c}}')
  printf '%s' "$json" | "$BASH_BIN" "$HOOK" >/dev/null 2>&1; rc=$?
  if [ "$expect" = block ]; then
    [ "$rc" -eq 2 ] && pass=$((pass+1)) || { echo "  MISS (want BLOCK, got $rc): $cmd"; fail=$((fail+1)); }
  else
    [ "$rc" -eq 0 ] && pass=$((pass+1)) || { echo "  MISS (want ALLOW, got $rc): $cmd"; fail=$((fail+1)); }
  fi
}

echo "── must BLOCK (reading/exfiltrating credentials) ──"
run block 'cat .env.local'
run block 'cat .env'
run block 'cat .env.production'
run block 'grep SUPABASE .env.local'
run block 'head -5 .env'
run block 'tail -n 20 config/.env'
run block 'cp .env /tmp/exfil'
run block 'cp .env.local ~/Desktop/x'
run block 'source .env'
run block '. ./.env'
run block 'base64 .env.local'
run block 'xxd id_rsa'
run block 'cat ~/.aws/credentials'
run block 'cat service-account.json'
run block 'cat my-key.json'
run block 'cat secrets.yaml'
run block 'cat app.pem'
run block 'tar czf out.tgz .env'
run block 'awk "{print}" .env'
run block 'sed -n 1p .env.local'
run block 'cat .npmrc'
run block 'cat foo < .env'

echo "── must ALLOW (safe reads) ──"
run allow 'cat .env.example'
run allow 'cat .env.sample'
run allow 'cat .env.template'
run allow 'cat README.md'
run allow 'cat package.json'
run allow 'grep foo src/app.ts'
run allow 'cp a.txt b.txt'
run allow 'cat src/env.ts'
run allow 'head -5 docs/TESTING.md'
run allow 'node -r dotenv/config index.js'
run allow 'ls -la'
run allow 'cat .gitignore'

echo "── fail-closed (jq absent → BLOCK) ──"
MASK=$(mktemp -d); for b in cat tr; do p=$(command -v "$b"); [ -n "$p" ] && ln -sf "$p" "$MASK/$b"; done
json=$(jq -nc '{tool_input:{command:"cat .env"}}')
printf '%s' "$json" | PATH="$MASK" "$BASH_BIN" "$HOOK" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && { pass=$((pass+1)); echo "  ok: blocks when jq absent"; } || { echo "  MISS: want BLOCK with jq absent, got $rc"; fail=$((fail+1)); }
rm -rf "$MASK"

echo ""
echo "block-credential-read: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
