#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
PASS=0
FAIL=0

echo "=== Hook スクリプト テスト ==="

run_check() {
  local label="$1"
  shift
  if "$@"; then
    echo "✅ $label"
    PASS=$((PASS+1))
  else
    echo "❌ $label"
    FAIL=$((FAIL+1))
  fi
}

# gate-check.sh: ブロックされるべきケース（承認記録なし）
echo "--- gate-check.sh: deny ケース ---"
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/10_立ち上げ/test.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
if echo "$RESULT" | grep -q "deny"; then
  echo "✅ deny 正常"
  PASS=$((PASS+1))
else
  echo "❌ deny されなかった: $RESULT"
  FAIL=$((FAIL+1))
fi

# gate-check.sh: 許可されるべきケース（30_Flow外）
echo "--- gate-check.sh: allow ケース ---"
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/20_Skills/test/SKILL.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
if echo "$RESULT" | grep -q "deny"; then
  echo "❌ 不正なdeny: $RESULT"
  FAIL=$((FAIL+1))
else
  echo "✅ allow 正常"
  PASS=$((PASS+1))
fi

# 実行権限チェック
echo "--- 実行権限チェック ---"
for f in "$HOOKS_DIR"/*.sh; do
  if [[ -x "$f" ]]; then
    echo "✅ $(basename "$f") +x"
    PASS=$((PASS+1))
  else
    echo "❌ $(basename "$f") 実行権限なし"
    FAIL=$((FAIL+1))
  fi
done

# 終了コードチェック（全スクリプトがexit 0で終わるか）
echo "--- exit 0 チェック ---"
for f in "$HOOKS_DIR"/*.sh; do
  if echo '{}' | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$f" >/dev/null 2>&1; then
    echo "✅ $(basename "$f") exit 0"
    PASS=$((PASS+1))
  else
    echo "❌ $(basename "$f") exit ≠ 0"
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
[[ $FAIL -eq 0 ]]
