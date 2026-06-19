#!/usr/bin/env bash
# package-dist.sh --target claude-code のスモークテスト。
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

check_file "$DIST/.claude/settings.json"
check_file "$DIST/.claude/agents/eval-judge.md"

skill_count=0
if [[ -d "$DIST/.claude/skills" ]]; then
  skill_count="$(find "$DIST/.claude/skills" -type f -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
fi
if [[ "$skill_count" -gt 0 ]]; then
  echo "✅ Claude Code skills: $skill_count"
else
  echo "❌ Claude Code skills: 0"
  fail=1
fi

check_file "$DIST/CLAUDE.md"
check_absent "$DIST/AGENTS.md"
check_absent "$DIST/CODEX.md"
check_absent "$DIST/.claude/settings.local.json"

ds_store_count="$(find "$DIST" -name .DS_Store -type f 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$ds_store_count" -eq 0 ]]; then
  echo "✅ no .DS_Store"
else
  echo "❌ .DS_Store found: $ds_store_count"
  fail=1
fi

exit "$fail"
