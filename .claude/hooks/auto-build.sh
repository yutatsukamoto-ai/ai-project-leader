#!/usr/bin/env bash
# auto-build.sh -- 正典/Skill編集後の同期・再ビルド（PostToolUse hook）
# PostToolUseはブロック不可。失敗時だけadditionalContextでClaudeに伝える。
set -uo pipefail

LOG_FILE="/tmp/claude-hooks-build.log"

INPUT=$(cat) || exit 0
command -v jq &>/dev/null || exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

[[ -n "$FILE_PATH" ]] || exit 0
[[ "$FILE_PATH" == "$PROJECT_DIR"/* ]] || exit 0

REL="${FILE_PATH#$PROJECT_DIR/}"

log_result() {
  {
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') $1 ==="
    printf '%s\n' "$2"
    echo
  } >> "$LOG_FILE" 2>/dev/null || true
}

emit_context() {
  jq -n --arg ctx "$1" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
}

# 正典ファイルが編集された → sync
MANIFEST="$PROJECT_DIR/_tools/sync-manifest.tsv"
if [[ -f "$MANIFEST" ]] && \
   awk -F '\t' 'NF >= 2 && $1 !~ /^#/ && $1 != "" {print $1}' "$MANIFEST" 2>/dev/null | grep -qxF "$REL"; then
  RESULT=$(bash "$PROJECT_DIR/_tools/build.sh" --sync 2>&1)
  EXIT_CODE=$?
  log_result "build --sync after $REL" "$RESULT"
  if [[ $EXIT_CODE -ne 0 ]]; then
    emit_context "build --sync FAIL after $REL. $(echo "$RESULT" | tail -3)"
  fi
  exit 0
fi

# 20_Skills配下のSKILL.mdが編集された → そのSkillを再ビルド（全verifyはCIに寄せる）
if [[ "$REL" == 20_Skills/*/SKILL.md || "$REL" == 20_Skills/*/*/SKILL.md ]]; then
  SKILL_DIR="$(dirname "$FILE_PATH")"
  RESULT=$(bash "$PROJECT_DIR/_tools/build.sh" --build-only "$SKILL_DIR" 2>&1)
  EXIT_CODE=$?
  log_result "build skill ${SKILL_DIR#$PROJECT_DIR/}" "$RESULT"
  if [[ $EXIT_CODE -ne 0 ]]; then
    emit_context "build FAIL: ${SKILL_DIR#$PROJECT_DIR/}. $(echo "$RESULT" | tail -3)"
  fi
  exit 0
fi

exit 0
