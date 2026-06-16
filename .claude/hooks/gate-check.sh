#!/usr/bin/env bash
# gate-check.sh - 承認ゲートのHooks構造強制
set -uo pipefail

# タイムアウト設定（PreToolUseは1秒以内）
TIMEOUT=1

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
HOOK_INPUT="$HOOK_INPUT" run_with_timeout <<'HOOK_MAIN'
set -uo pipefail
INPUT="${HOOK_INPUT:-}"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FLOW_DIR="$PROJECT_DIR/30_Flow"

allow_json='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
}

case "$TOOL" in
  Write|Edit|Bash) ;;
  *) echo '{}'; exit 0 ;;
esac

find_marker() {
  local case_root="$1" marker_dir="$2" pattern="$3" section="$4"
  local f
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    grep -q "^## $section" "$f" && return 0
  done < <(find "$case_root/$marker_dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null)
  return 1
}

is_phase_dir() {
  case "$1" in
    00_前段|01_立ち上げ|02_計画|03_実行|04_監視コントロール|05_終結|\
    10_立ち上げ|20_計画|30_実行|40_監視|50_終結) return 0 ;;
    *) return 1 ;;
  esac
}

case_root_for_path() {
  local path="$1" rel first second
  [[ "$path" == "$FLOW_DIR"/* ]] || return 1
  rel="${path#$FLOW_DIR/}"
  [[ "$rel" == */* ]] || return 1
  first="${rel%%/*}"
  rel="${rel#*/}"
  second="${rel%%/*}"
  [[ -n "$first" && -n "$second" ]] || return 1
  if is_phase_dir "$second"; then
    printf '%s/%s' "$FLOW_DIR" "$first"
  else
    printf '%s/%s/%s' "$FLOW_DIR" "$first" "$second"
  fi
}

phase_path_for_path() {
  local path="$1" rel second
  rel="${path#$FLOW_DIR/}"
  rel="${rel#*/}"
  second="${rel%%/*}"
  if ! is_phase_dir "$second"; then
    rel="${rel#*/}"
  fi
  printf '%s' "$rel"
}

needs_front_approval() {
  case "$1" in
    01_立ち上げ/*|02_計画/*|03_実行/*|04_監視コントロール/*|05_終結/*|\
    10_立ち上げ/*|20_計画/*|30_実行/*|40_監視/*|50_終結/*) return 0 ;;
    *) return 1 ;;
  esac
}

needs_plan_approval() {
  case "$1" in
    03_実行/*|04_監視コントロール/*|05_終結/*|\
    30_実行/*|40_監視/*|50_終結/*) return 0 ;;
    *) return 1 ;;
  esac
}

check_write_or_edit() {
  local target="$1" case_root phase_path
  [[ -n "$target" ]] || { echo '{}'; exit 0; }
  [[ "$target" == "$FLOW_DIR"/* ]] || { echo '{}'; exit 0; }

  case_root="$(case_root_for_path "$target")" || { echo '{}'; exit 0; }
  phase_path="$(phase_path_for_path "$target")"

  if needs_front_approval "$phase_path"; then
    if ! find_marker "$case_root" "00_前段" "*計画提案書*.md" "承認記録"; then
      deny "前段0-4の承認記録がありません。計画提案書に「## 承認記録」を追記してから進めてください。"
      exit 0
    fi
  fi

  if needs_plan_approval "$phase_path"; then
    if ! find_marker "$case_root" "02_計画" "*統合計画書*.md" "承認記録" && \
       ! find_marker "$case_root" "20_計画" "*統合計画書*.md" "承認記録"; then
      deny "計画の承認記録がありません。統合計画書に「## 承認記録」を追記してから進めてください。"
      exit 0
    fi
  fi

  echo "$allow_json"
}

check_bash_docx() {
  local cmd="$1" case_root
  [[ "$cmd" == *python-docx* || "$cmd" == *docx* ]] || { echo '{}'; exit 0; }
  [[ "$cmd" == *終結報告書* ]] || { echo '{}'; exit 0; }

  while IFS= read -r case_root; do
    if find_marker "$case_root" "05_終結" "*終結報告書*.md" "提出版確定" || \
       find_marker "$case_root" "50_終結" "*終結報告書*.md" "提出版確定"; then
      echo "$allow_json"
      exit 0
    fi
  done < <(find "$FLOW_DIR" -mindepth 1 -maxdepth 2 -type d 2>/dev/null)

  deny "終結報告書の提出版確定記録がありません。終結報告書Markdownに「## 提出版確定」を追記してからdocx生成してください。"
}

if [[ "$TOOL" == "Bash" ]]; then
  check_bash_docx "$COMMAND"
else
  check_write_or_edit "$FILE_PATH"
fi
HOOK_MAIN

# タイムアウトの場合でもexit 0で終了
exit 0
