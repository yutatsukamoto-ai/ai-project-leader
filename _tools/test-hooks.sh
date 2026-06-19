#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
AGENTS_DIR="$PROJECT_DIR/.claude/agents"
PASS=0
FAIL=0
TOTAL=0

echo "=== Hook スクリプト テスト ==="
echo ""

assert() {
  local label="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL+1))
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label"
    echo "     期待: '$expected' を含む"
    echo "     実際: '$actual'"
    FAIL=$((FAIL+1))
  fi
}

assert_not() {
  local label="$1" unexpected="$2" actual="$3"
  TOTAL=$((TOTAL+1))
  if [[ "$actual" != *"$unexpected"* ]]; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label (含まれるべきでない '$unexpected' が含まれている)"
    FAIL=$((FAIL+1))
  fi
}

assert_empty() {
  local label="$1" actual="$2"
  TOTAL=$((TOTAL+1))
  if [[ -z "$actual" ]]; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label"
    echo "     期待: 空出力"
    echo "     実際: '$actual'"
    FAIL=$((FAIL+1))
  fi
}

assert_exit() {
  local label="$1" expected_code="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local actual_code=$?
  TOTAL=$((TOTAL+1))
  if [[ $actual_code -eq $expected_code ]]; then
    echo "  ✅ $label (exit $actual_code)"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label (期待: exit $expected_code, 実際: exit $actual_code)"
    FAIL=$((FAIL+1))
  fi
}

# ─── WI-01: gate-check.sh ───
echo "--- WI-01: gate-check.sh（承認ゲート） ---"

# deny: 承認記録なしで立ち上げフォルダに書き込み
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/01_立ち上げ/test.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert "deny: 承認なし→立ち上げ書き込み" "deny" "$RESULT"

# deny: 承認記録なしで計画フォルダに書き込み
RESULT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/02_計画/test.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert "deny: 承認なし→計画書き込み" "deny" "$RESULT"

# allow: 30_Flow外のファイル
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/20_Skills/test/SKILL.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert_not "allow: 20_Skills書き込み" "deny" "$RESULT"

# allow: 前段フォルダ（承認不要）
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/00_前段/memo.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert_not "allow: 00_前段書き込み（承認不要）" "deny" "$RESULT"

# allow: Write/Edit以外のツール
RESULT=$(echo '{"tool_name":"Read","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/01_立ち上げ/test.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert_not "allow: Readツール（対象外）" "deny" "$RESULT"

# deny: Bashでdocx生成（終結報告書・提出版確定なし）
RESULT=$(echo '{"tool_name":"Bash","tool_input":{"command":"python3 -c \"from docx import Document; ...\" 終結報告書"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert "deny: docx生成（提出版確定なし）" "deny" "$RESULT"

# allow: Bashで無関係のコマンド
RESULT=$(echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
assert_not "allow: Bash(ls -la)" "deny" "$RESULT"

echo ""

# ─── WI-04: auto-build.sh ───
echo "--- WI-04: auto-build.sh（自動ビルド） ---"

# 無関係なファイル → 何も出力しない（exit 0）
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/README.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/auto-build.sh" 2>/dev/null)
assert_empty "skip: 無関係ファイル → 空出力" "$RESULT"

# プロジェクト外のファイル → skip
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/unrelated.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/auto-build.sh" 2>/dev/null)
assert_empty "skip: プロジェクト外" "$RESULT"

echo ""

# ─── WI-02: auto-eval.sh ───
echo "--- WI-02: auto-eval.sh（eval自動実行） ---"

# 30_Flow外のファイル → skip
RESULT=$(echo '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/20_Skills/test/SKILL.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/auto-eval.sh" 2>/dev/null)
assert_empty "skip: PostToolUse 20_Skills" "$RESULT"

echo ""

# ─── 共通: 実行権限 ───
echo "--- 共通: 実行権限チェック ---"
for f in "$HOOKS_DIR"/*.sh; do
  TOTAL=$((TOTAL+1))
  if [[ -x "$f" ]]; then
    echo "  ✅ $(basename "$f") +x"
    PASS=$((PASS+1))
  else
    echo "  ❌ $(basename "$f") 実行権限なし"
    FAIL=$((FAIL+1))
  fi
done

echo ""

# ─── 共通: exit 0チェック ───
echo "--- 共通: exit 0 ---"
for f in "$HOOKS_DIR"/*.sh; do
  TOTAL=$((TOTAL+1))
  if echo '{}' | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$f" >/dev/null 2>&1; then
    echo "  ✅ $(basename "$f") exit 0"
    PASS=$((PASS+1))
  else
    echo "  ❌ $(basename "$f") exit ≠ 0"
    FAIL=$((FAIL+1))
  fi
done

echo ""

# ─── WI-06: サブエージェント定義 ───
echo "--- WI-06: サブエージェント定義 ---"
for agent in eval-judge researcher integrity-checker status-aggregator; do
  TOTAL=$((TOTAL+1))
  if [[ -f "$AGENTS_DIR/$agent.md" ]]; then
    echo "  ✅ $agent.md 存在"
    PASS=$((PASS+1))
  else
    echo "  ❌ $agent.md 不在"
    FAIL=$((FAIL+1))
  fi
done

echo ""

# ─── settings.json 構造チェック ───
echo "--- settings.json 構造 ---"
SETTINGS="$PROJECT_DIR/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  # PreToolUseにgate-checkが登録されている
  RESULT=$(jq -r '.hooks.PreToolUse[0].hooks[0].command // empty' "$SETTINGS" 2>/dev/null)
  assert "PreToolUse: gate-check登録" "gate-check.sh" "$RESULT"

  # PostToolUseにauto-buildとauto-evalが順番に登録されている
  BUILD_CMD=$(jq -r '.hooks.PostToolUse[0].hooks[0].command // empty' "$SETTINGS" 2>/dev/null)
  EVAL_CMD=$(jq -r '.hooks.PostToolUse[0].hooks[1].command // empty' "$SETTINGS" 2>/dev/null)
  assert "PostToolUse[0]: auto-build" "auto-build.sh" "$BUILD_CMD"
  assert "PostToolUse[1]: auto-eval" "auto-eval.sh" "$EVAL_CMD"

  # TaskCompletedにauto-eval
  TC_CMD=$(jq -r '.hooks.TaskCompleted[0].hooks[0].command // empty' "$SETTINGS" 2>/dev/null)
  assert "TaskCompleted: auto-eval" "auto-eval.sh" "$TC_CMD"

  # StopにpromptHook
  STOP_TYPE=$(jq -r '.hooks.Stop[0].hooks[0].type // empty' "$SETTINGS" 2>/dev/null)
  assert "Stop: prompt hook" "prompt" "$STOP_TYPE"
else
  TOTAL=$((TOTAL+5))
  echo "  ❌ settings.json が見つかりません"
  FAIL=$((FAIL+5))
fi

echo ""
echo "================================"
echo "結果: PASS=$PASS FAIL=$FAIL TOTAL=$TOTAL"
[[ $FAIL -eq 0 ]]
