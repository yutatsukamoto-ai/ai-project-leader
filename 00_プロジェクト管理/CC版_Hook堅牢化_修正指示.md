# CC版 Hook堅牢化 修正指示

作成: 2026-06-17
目的: テクニック集（§5.7〜5.10）のベストプラクティスを、WI-01〜05の実装済みHookスクリプトに反映する。
前提: WI-01〜07がCodexで実装済みであること。本指示はその修正・補強。

---

## 修正1: 全hookスクリプトに堅牢化パターンを適用

対象: `.claude/hooks/gate-check.sh`, `.claude/hooks/auto-eval.sh`, `.claude/hooks/auto-build.sh`

全スクリプトの冒頭を以下のパターンに統一する:

```bash
#!/usr/bin/env bash
set -uo pipefail

# タイムアウト設定（PreToolUseは1秒、PostToolUseは5秒）
TIMEOUT=__ここに秒数__

# stdinからJSON入力を読み込む（読み込み失敗時は終了）
HOOK_INPUT=$(cat) || exit 0

# 外部コマンドの存在確認
if ! command -v jq &> /dev/null; then
  # jqが利用できない場合はスキップ（意図しないブロックを防ぐ）
  exit 0
fi

# メイン処理（タイムアウト付き）
echo "$HOOK_INPUT" | timeout $TIMEOUT bash -c '
  INPUT=$(cat)
  # ... 実際の処理 ...
'

# タイムアウトの場合でもexit 0で終了
exit 0
```

各スクリプトのTIMEOUT値:

| スクリプト | TIMEOUT | 理由 |
|---|---|---|
| gate-check.sh | 1 | PreToolUseは毎ツール実行前に走る。1秒以内必須 |
| auto-build.sh | 5 | PostToolUse。build/syncは数秒かかりうる |
| auto-eval.sh | 5 | PostToolUse（またはTaskCompleted）。eval全件は重い可能性 |

### 受け入れ条件
- [ ] 全スクリプトにタイムアウトが設定されていること
- [ ] jq未インストール環境でもexit 0で安全に終了すること
- [ ] stdin読み込み失敗でもexit 0で終了すること
- [ ] タイムアウト時もexit 0で終了すること

---

## 修正2: WI-02のイベントをTaskCompletedに変更

**根拠**: テクニック集§5.7.1「フロー保証にはPostToolUseではなくTaskCompleted」+ 公式ドキュメントでTaskCompletedイベントが現行APIに存在することを確認済み。

PostToolUseだと毎回のWrite/Editでeval.shが発火し、非効率かつコンテキストを消費する。TaskCompletedはClaude Codeがタスク完了と判断したタイミングで1回だけ発火するため、品質ゲートとして適切。

**変更内容**:

`.claude/settings.json` の auto-eval.sh の登録先を変更:

変更前:
```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      { "type": "command", "command": "...auto-build.sh" },
      { "type": "command", "command": "...auto-eval.sh" }
    ]
  }
]
```

変更後:
```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      { "type": "command", "command": "...auto-build.sh" }
    ]
  }
],
"TaskCompleted": [
  {
    "hooks": [
      { "type": "command", "command": "...auto-eval.sh" }
    ]
  }
]
```

**注意**: TaskCompletedはmatcherをサポートしない（常に発火）。auto-eval.sh内で30_Flow配下のファイルが変更されたかどうかを自分で判定する必要がある。

auto-eval.sh の入力JSON形式がPostToolUseと異なる可能性があるため、TaskCompletedのinput schemaを公式ドキュメントで確認してからスクリプトを修正すること。

### 受け入れ条件
- [ ] settings.jsonでauto-eval.shがTaskCompletedに登録されていること
- [ ] PostToolUseのhooks配列からauto-eval.shが除去されていること
- [ ] タスク完了時にeval.shが自動で走ること
- [ ] 30_Flow配下に変更がないタスク完了時はスキップされること

---

## 修正3: コンテキスト消費の最小化

PostToolUseの標準出力はコンテキストに注入される。出力量を最小限にする。

対象: auto-build.sh

変更内容:
- 正常時: `{}` のみ出力（現在の `tail -3` を廃止）
- エラー時のみ: 1行のサマリー + 「詳細は /tmp/claude-hooks.log を参照」
- 詳細ログはファイルに書き出す

```bash
# 詳細ログはファイルに
LOG_FILE="/tmp/claude-hooks-build.log"
RESULT=$(bash "$PROJECT_DIR/_tools/build.sh" --sync 2>&1)
echo "$RESULT" >> "$LOG_FILE"

# Claude Codeへのフィードバックは最小限
if [[ $? -ne 0 ]]; then
  echo "build --sync FAIL: see $LOG_FILE for details"
fi
echo '{}'
```

auto-eval.sh も同様にログファイル出力に変更。

### 受け入れ条件
- [ ] 正常時のstdout出力が `{}` のみであること
- [ ] エラー時のstdout出力が1行以内であること
- [ ] 詳細ログが /tmp/claude-hooks-*.log に書き出されること

---

## 修正4: スクリプトに実行権限を付与

```bash
chmod +x .claude/hooks/gate-check.sh
chmod +x .claude/hooks/auto-eval.sh
chmod +x .claude/hooks/auto-build.sh
```

Codexが実装時にchmod +xしていない場合、フックが発火しない。

### 受け入れ条件
- [ ] 全hookスクリプトに実行権限があること（`ls -la .claude/hooks/` で確認）

---

## 修正5: 手動テストコマンドを追加

各hookスクリプトをClaude Code起動なしにテストできるコマンドを `_tools/test-hooks.sh` として作成。

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
PASS=0; FAIL=0

echo "=== Hook スクリプト テスト ==="

# gate-check.sh: ブロックされるべきケース（承認記録なし）
echo "--- gate-check.sh: deny ケース ---"
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/30_Flow/テスト案件/10_立ち上げ/test.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
if echo "$RESULT" | grep -q "deny"; then
  echo "✅ deny 正常"; PASS=$((PASS+1))
else
  echo "❌ deny されなかった: $RESULT"; FAIL=$((FAIL+1))
fi

# gate-check.sh: 許可されるべきケース（30_Flow外）
echo "--- gate-check.sh: allow ケース ---"
RESULT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PROJECT_DIR"'/20_Skills/test/SKILL.md"}}' \
  | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$HOOKS_DIR/gate-check.sh" 2>/dev/null)
if echo "$RESULT" | grep -q "deny"; then
  echo "❌ 不正なdeny: $RESULT"; FAIL=$((FAIL+1))
else
  echo "✅ allow 正常"; PASS=$((PASS+1))
fi

# 実行権限チェック
echo "--- 実行権限チェック ---"
for f in "$HOOKS_DIR"/*.sh; do
  if [[ -x "$f" ]]; then
    echo "✅ $(basename "$f") +x"; PASS=$((PASS+1))
  else
    echo "❌ $(basename "$f") 実行権限なし"; FAIL=$((FAIL+1))
  fi
done

# 終了コードチェック（全スクリプトがexit 0で終わるか）
echo "--- exit 0 チェック ---"
for f in "$HOOKS_DIR"/*.sh; do
  echo '{}' | CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$f" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "✅ $(basename "$f") exit 0"; PASS=$((PASS+1))
  else
    echo "❌ $(basename "$f") exit ≠ 0"; FAIL=$((FAIL+1))
  fi
done

echo ""
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
[[ $FAIL -eq 0 ]]
```

### 受け入れ条件
- [ ] `bash _tools/test-hooks.sh` が全PASSすること
- [ ] chmod +x _tools/test-hooks.sh が設定されていること

---

## 修正6: Hooks設計チェックリストで最終検証

全修正完了後、以下のチェックリストを通すこと（テクニック集 表5.28準拠）:

- [ ] イベント選択: 目的に合ったイベントタイプを選択しているか
- [ ] イベント選択: ブロックが必要ならPreToolUseまたはTaskCompletedを使っているか
- [ ] ブロッキング: PreToolUseのブロックはhookSpecificOutput（deny）で実装しているか
- [ ] ブロッキング: PostToolUseでブロックしようとしていないか
- [ ] 入力: stdinからJSONを読み込んでいるか（環境変数ではなくstdin）
- [ ] パフォーマンス: PreToolUseフックは1秒以内に完了するか
- [ ] パフォーマンス: PostToolUseの出力は必要最小限か
- [ ] エラー処理: 外部コマンドの存在を事前に確認しているか
- [ ] エラー処理: タイムアウト対策を実装しているか
- [ ] エラー処理: 予期しないエラー時にexit 0で安全に終了するか
- [ ] テスト: stdinにJSONをパイプした手動テストが可能か
- [ ] テスト: ブロック対象とブロック非対象の両方をテストしたか
- [ ] 運用: ログ出力戦略を定めているか

---

## 着手の手順

1. 修正4（chmod +x）→ 最も簡単で影響大
2. 修正1（堅牢化パターン）→ 全スクリプト共通
3. 修正3（コンテキスト消費最小化）→ auto-build.shの出力変更
4. 修正2（TaskCompleted移行）→ settings.json + auto-eval.sh
5. 修正5（テストスクリプト）→ 全修正のテスト
6. 修正6（チェックリスト検証）→ 最終確認
