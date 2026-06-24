#!/usr/bin/env bash
# Tests the safety-file guard in .husky/pre-commit.
# The guard blocks agent commits of safety-critical files: hook scripts,
# permission settings, gate scripts, package wiring, and credential files.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOK="$ROOT/.husky/pre-commit"
[ -f "$HOOK" ] || { echo "safety-file-guard.test: $HOOK not found"; exit 1; }

pass=0; fail=0
ok() {
  if [ "$1" = "$2" ]; then
    pass=$((pass+1))
  else
    echo "  MISS ($3): got exit $1, want exit $2"
    fail=$((fail+1))
  fi
}

mk() {
  d=$(mktemp -d)
  (
    cd "$d" || exit 1
    git init -q
    git config user.email t@example.com
    git config user.name tester
    git commit -q --allow-empty --no-verify -m init
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# ── .husky/* — modifications, new files, and deletions are all blocked ──

echo "── staging a .husky/* modification is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo hook\n' > "$D/.husky/pre-commit"
(cd "$D" && git add .husky/pre-commit) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky modification): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a new .husky/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo new-hook\n' > "$D/.husky/post-merge"
(cd "$D" && git add .husky/post-merge) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky new file): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── deleting a .husky/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.husky"
printf 'echo hook\n' > "$D/.husky/some-hook"
(cd "$D" && git add .husky/some-hook && git commit -q --no-verify -m 'add hook') >/dev/null 2>&1
(cd "$D" && git rm -q .husky/some-hook) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (husky deletion): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a normal file does not trigger the hook-files guard ──"
D=$(mk)
printf 'hello\n' > "$D/normal.txt"
(cd "$D" && git add normal.txt) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  fail=$((fail+1))
  echo "  MISS (normal file): hook-files guard fired on normal staged file"
else
  pass=$((pass+1))
fi
rm -rf "$D"

# ── .claude/hooks/* — permission and egress scripts are all blocked ──

echo "── staging a new .claude/hooks/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.claude/hooks"
printf 'echo hook\n' > "$D/.claude/hooks/block-egress.sh"
(cd "$D" && git add .claude/hooks/block-egress.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (claude/hooks new): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a .claude/hooks/* modification is blocked ──"
D=$(mk)
mkdir -p "$D/.claude/hooks"
printf 'echo hook\n' > "$D/.claude/hooks/block-egress.sh"
(cd "$D" && git add .claude/hooks/block-egress.sh && git commit -q --no-verify -m 'add hook') >/dev/null 2>&1
printf 'echo modified\n' > "$D/.claude/hooks/block-egress.sh"
(cd "$D" && git add .claude/hooks/block-egress.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (claude/hooks modification): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── deleting a .claude/hooks/* file is blocked ──"
D=$(mk)
mkdir -p "$D/.claude/hooks"
printf 'echo hook\n' > "$D/.claude/hooks/block-egress.sh"
(cd "$D" && git add .claude/hooks/block-egress.sh && git commit -q --no-verify -m 'add hook') >/dev/null 2>&1
(cd "$D" && git rm -q .claude/hooks/block-egress.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "hook files"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (claude/hooks deletion): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

# ── .claude/settings*.json — permission plane ──

echo "── staging .claude/settings.json is blocked ──"
D=$(mk)
mkdir -p "$D/.claude"
printf '{"permissions":{}}\n' > "$D/.claude/settings.json"
(cd "$D" && git add .claude/settings.json) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissions"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (settings.json): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging .claude/settings.local.json is blocked ──"
D=$(mk)
mkdir -p "$D/.claude"
printf '{"permissions":{}}\n' > "$D/.claude/settings.local.json"
(cd "$D" && git add -f .claude/settings.local.json) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "permissions"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (settings.local.json): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a new .claude/agents/my-agent.md IS blocked ──"
D=$(mk)
mkdir -p "$D/.claude/agents"
printf -- '---\nname: my-agent\ntools: Read\n---\nbody\n' > "$D/.claude/agents/my-agent.md"
rc=$(cd "$D" && git add .claude/agents/my-agent.md && bash "$HOOK" >/dev/null 2>&1; echo $?)
ok "$rc" 1 ".claude/agents/*.md now protected"
rm -rf "$D"

# ── gate scripts — lint and gate enforcers ──

echo "── staging scripts/lint.sh is blocked ──"
D=$(mk)
mkdir -p "$D/scripts"
printf 'echo lint\n' > "$D/scripts/lint.sh"
(cd "$D" && git add scripts/lint.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "gate"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (scripts/lint.sh): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging scripts/cr-ok.sh is blocked ──"
D=$(mk)
mkdir -p "$D/scripts"
printf 'echo cr\n' > "$D/scripts/cr-ok.sh"
(cd "$D" && git add scripts/cr-ok.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "gate"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (scripts/cr-ok.sh): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging scripts/design-confirm.sh is blocked ──"
D=$(mk)
mkdir -p "$D/scripts"
printf 'echo confirm\n' > "$D/scripts/design-confirm.sh"
(cd "$D" && git add scripts/design-confirm.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "gate"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (scripts/design-confirm.sh): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging scripts/token-lint.sh is blocked ──"
D=$(mk)
mkdir -p "$D/scripts"
printf 'echo token\n' > "$D/scripts/token-lint.sh"
(cd "$D" && git add scripts/token-lint.sh) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "gate"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (scripts/token-lint.sh): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

# ── package.json / package-lock.json — hooks wiring ──

echo "── staging package.json is blocked ──"
D=$(mk)
printf '{"name":"test"}\n' > "$D/package.json"
(cd "$D" && git add package.json) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "package"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (package.json): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging package-lock.json is blocked ──"
D=$(mk)
printf '{"lockfileVersion":2}\n' > "$D/package-lock.json"
(cd "$D" && git add package-lock.json) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "package"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (package-lock.json): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

# ── .env files — credential files ──

echo "── staging a new .env file is blocked ──"
D=$(mk)
printf 'SECRET=abc\n' > "$D/.env"
(cd "$D" && git add .env) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "secrets"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (.env new): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging a .env modification is blocked ──"
D=$(mk)
printf 'SECRET=old\n' > "$D/.env"
(cd "$D" && git add .env && git commit -q --no-verify -m 'add env') >/dev/null 2>&1
printf 'SECRET=new\n' > "$D/.env"
(cd "$D" && git add .env) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "secrets"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (.env modification): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── deleting a .env file is NOT blocked ──"
D=$(mk)
printf 'SECRET=abc\n' > "$D/.env"
(cd "$D" && git add .env && git commit -q --no-verify -m 'add env') >/dev/null 2>&1
(cd "$D" && git rm -q .env) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "secrets"; then
  fail=$((fail+1))
  echo "  MISS (.env deletion): guard blocked a .env deletion (should be allowed)"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo "── staging a .env.local file is blocked ──"
D=$(mk)
printf 'SECRET=abc\n' > "$D/.env.local"
(cd "$D" && git add .env.local) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "secrets"; then
  pass=$((pass+1))
else
  fail=$((fail+1))
  echo "  MISS (.env.local): guard message not in stderr"
  echo "  stderr: $err"
fi
rm -rf "$D"

echo "── staging .envrc is NOT blocked ──"
D=$(mk)
printf 'export FOO=bar\n' > "$D/.envrc"
(cd "$D" && git add .envrc) >/dev/null 2>&1
err=$(cd "$D" && bash "$HOOK" 2>&1; true)
if printf '%s' "$err" | grep -q "secrets"; then
  fail=$((fail+1))
  echo "  MISS (.envrc): guard blocked .envrc (should be allowed)"
else
  pass=$((pass+1))
fi
rm -rf "$D"

echo ""
echo "safety-file-guard: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
