#!/usr/bin/env bash
# package-dist.sh --target codex のスモークテスト。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/_dist"
fail=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "✅ exists: ${path#$ROOT/}"
  else
    echo "❌ missing: ${path#$ROOT/}"
    fail=1
  fi
}

check_absent() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "✅ absent: ${path#$ROOT/}"
  else
    echo "❌ should not exist: ${path#$ROOT/}"
    fail=1
  fi
}

check_file "$DIST/AGENTS.md"
check_file "$DIST/CODEX.md"
check_file "$DIST/README.md"
check_file "$DIST/20_Skills/90_横断/slide-craft/SKILL.md"

check_absent "$DIST/CLAUDE.md"
check_absent "$DIST/.claude"
check_absent "$DIST/30_Flow/2026-06-17/Skillテスト_slide-craft"

ds_store_count="$(find "$DIST" -name .DS_Store -type f 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$ds_store_count" -eq 0 ]]; then
  echo "✅ no .DS_Store"
else
  echo "❌ .DS_Store found: $ds_store_count"
  fail=1
fi

exit "$fail"
