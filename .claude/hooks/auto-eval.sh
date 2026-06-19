#!/usr/bin/env bash
# auto-eval.sh -- 成果物書き込み後のeval自動実行（PostToolUse / TaskCompleted hook）
# PostToolUse: 30_Flow配下の.md書き込み時に発火
# TaskCompleted: タスク完了時に30_Flow配下に新しい.mdがあれば発火
set -uo pipefail

LOG_FILE="/tmp/claude-hooks-eval.log"

INPUT=$(cat) || exit 0
command -v jq &>/dev/null || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
PROJECT_KEY=$(printf '%s' "$PROJECT_DIR" | cksum | awk '{print $1}')
STAMP_FILE="/tmp/claude-hooks-eval-${PROJECT_KEY}.stamp"

should_run_eval() {
  case "$EVENT" in
    PostToolUse)
      local fp
      fp=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
      [[ -n "$fp" && "$fp" == "$PROJECT_DIR"/30_Flow/* && "$fp" == *.md ]]
      ;;
    TaskCompleted)
      local goldens reference
      goldens="$PROJECT_DIR/_tools/eval/goldens.tsv"
      [[ -f "$goldens" ]] || return 1
      reference="$goldens"
      [[ -f "$STAMP_FILE" ]] && reference="$STAMP_FILE"
      [[ -d "$PROJECT_DIR/30_Flow" ]] && \
        [[ -n "$(find "$PROJECT_DIR/30_Flow" -name '*.md' -newer "$reference" -print -quit 2>/dev/null)" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

emit_context() {
  local event_name="${EVENT:-PostToolUse}"
  jq -n --arg event "$event_name" --arg ctx "$1" \
    '{hookSpecificOutput:{hookEventName:$event,additionalContext:$ctx}}'
}

should_run_eval || exit 0

RESULT=$(bash "$PROJECT_DIR/_tools/eval.sh" 2>&1)
EXIT_CODE=$?

{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') eval after $EVENT ==="
  printf '%s\n' "$RESULT"
  echo
} >> "$LOG_FILE" 2>/dev/null || true
touch "$STAMP_FILE" 2>/dev/null || true

if [[ $EXIT_CODE -ne 0 ]]; then
  SUMMARY=$(echo "$RESULT" | tail -5)
  emit_context "eval.sh FAIL ($EVENT). $SUMMARY"
fi

exit 0
