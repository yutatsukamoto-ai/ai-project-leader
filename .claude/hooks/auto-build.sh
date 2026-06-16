#!/usr/bin/env bash
# auto-build.sh - 正典/Skill編集後の同期・再ビルド
set -uo pipefail

# タイムアウト設定（PostToolUseは5秒）
TIMEOUT=5
LOG_FILE="/tmp/claude-hooks-build.log"

# stdinからJSON入力を読み込む（読み込み失敗時は終了）
HOOK_INPUT=$(cat) || exit 0

# 外部コマンドの存在確認
if ! command -v jq &> /dev/null; then
  # jqが利用できない場合はスキップ（意図しないブロックを防ぐ）
  exit 0
fi

run_with_timeout() {
  if command -v timeout &> /dev/null; then
    timeout "$TIMEOUT" bash -s
  elif command -v gtimeout &> /dev/null; then
    gtimeout "$TIMEOUT" bash -s
  else
    bash -s
  fi
}

# メイン処理（タイムアウト付き）
HOOK_INPUT="$HOOK_INPUT" LOG_FILE="$LOG_FILE" run_with_timeout <<'HOOK_MAIN'
set -uo pipefail
INPUT="${HOOK_INPUT:-}"
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="${LOG_FILE:-/tmp/claude-hooks-build.log}"

[[ -n "$FILE_PATH" ]] || { echo '{}'; exit 0; }
[[ "$FILE_PATH" == "$PROJECT_DIR"/* ]] || { echo '{}'; exit 0; }

REL="${FILE_PATH#$PROJECT_DIR/}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log_result() {
  local label="$1" result="$2"
  {
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') $label ==="
    printf '%s\n' "$result"
    echo
  } >> "$LOG_FILE"
}

# 正典ファイルが編集された → sync
if awk -F '\t' 'NF >= 2 && $1 !~ /^#/ && $1 != "" {print $1}' "$PROJECT_DIR/_tools/sync-manifest.tsv" | grep -qxF "$REL"; then
  RESULT=$(bash "$PROJECT_DIR/_tools/build.sh" --sync 2>&1)
  EXIT_CODE=$?
  log_result "build --sync after $REL" "$RESULT"
  if [[ $EXIT_CODE -ne 0 ]]; then
    echo "build --sync FAIL: see $LOG_FILE for details"
  else
    echo '{}'
  fi
  exit 0
fi

# 20_Skills配下のSKILL.mdが編集された → そのSkillを再ビルド
if [[ "$REL" == 20_Skills/*/SKILL.md ]]; then
  SKILL_DIR="$(dirname "$FILE_PATH")"
  RESULT=$(bash "$PROJECT_DIR/_tools/build.sh" "$SKILL_DIR" 2>&1)
  EXIT_CODE=$?
  log_result "build skill ${SKILL_DIR#$PROJECT_DIR/}" "$RESULT"
  if [[ $EXIT_CODE -ne 0 ]]; then
    echo "build skill FAIL: see $LOG_FILE for details"
  else
    echo '{}'
  fi
  exit 0
fi

echo '{}'
HOOK_MAIN

# タイムアウトの場合でもexit 0で終了
exit 0
