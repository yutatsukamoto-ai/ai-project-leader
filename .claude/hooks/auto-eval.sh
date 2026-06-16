#!/usr/bin/env bash
# auto-eval.sh - タスク完了後の機械eval
set -uo pipefail

# タイムアウト設定（TaskCompletedは5秒）
TIMEOUT=5
LOG_FILE="/tmp/claude-hooks-eval.log"

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
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="${LOG_FILE:-/tmp/claude-hooks-eval.log}"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# TaskCompletedはmatcherが無いので、30_Flow配下の変更有無を自前で判定する。
if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  FLOW_CHANGES=$(git -C "$PROJECT_DIR" status --porcelain -- 30_Flow 2>/dev/null || true)
  [[ -n "$FLOW_CHANGES" ]] || { echo '{}'; exit 0; }
else
  echo '{}'
  exit 0
fi

RESULT=$(bash "$PROJECT_DIR/_tools/eval.sh" 2>&1)
EXIT_CODE=$?
{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') eval after TaskCompleted ==="
  printf '%s\n' "$RESULT"
  echo
} >> "$LOG_FILE"

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "eval.sh FAIL: see $LOG_FILE for details"
else
  echo '{}'
fi
HOOK_MAIN

# タイムアウトの場合でもexit 0で終了
exit 0
