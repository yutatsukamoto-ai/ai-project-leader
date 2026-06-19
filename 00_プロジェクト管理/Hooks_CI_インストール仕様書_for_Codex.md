# Hooks/CI インストール仕様書（Codex向け）

作成: 2026-06-19
目的: Cowork側で作成・テスト済みのHooks/CI基盤ファイルを `.claude/` 配下に配置し、動作確認して commit する。

状態: **完了済み**。実装コミットは `8829b7b`、CC実環境検証は `5567393`、auto-build偽陽性修正は `d4988e7`、CI配布smoke修正は `48f1abe`。本書はインストール履歴として残す。現行実装は `.claude/` と `_tools/` を正とする。

## 前提

- API仕様の裏取り済（docs.anthropic.com/en/docs/claude-code/hooks, 2026-06-19）
- hook スクリプト3本 + settings.json + サブエージェント4本 + test-hooks.sh は設計・テスト完了
- 本書の「ファイル内容」セクションをそのまま書き込めばよい

## やること（5ステップ）

1. `.claude/hooks/auto-build.sh` と `.claude/hooks/auto-eval.sh` を下記内容で**上書き**（gate-check.sh は変更なし）
2. `.claude/settings.json` を下記内容で**上書き**
3. `.claude/agents/` ディレクトリを作成し、サブエージェント4本を新規作成
4. `_tools/test-hooks.sh` は既に更新済 — `bash _tools/test-hooks.sh` を実行して全PASS確認
5. 全PASS後に git commit

## やらないこと

- gate-check.sh は変更しない（既にAPI仕様と整合済み）
- `.claude/settings.local.json` はローカル許可用で配布対象外。存在してもHook発火の正典ではないため、削除・上書きしない
- _tools/test-hooks.sh は変更済み（そのまま使う）

---

## ファイル内容

### 1. `.claude/hooks/auto-build.sh`（上書き）

```bash
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

# 20_Skills配下のSKILL.mdが編集された → そのSkillを再ビルド
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
```

権限: `chmod +x`

### 2. `.claude/hooks/auto-eval.sh`（上書き）

```bash
#!/usr/bin/env bash
# auto-eval.sh -- 成果物書き込み後のeval自動実行（PostToolUse / TaskCompleted hook）
# PostToolUse: 30_Flow配下の.md書き込み時に発火
# TaskCompleted: タスク完了時に30_Flow配下に変更があれば発火
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
      # gitに依存せず、前回eval以降の30_Flow配下Markdown更新だけを拾う
      local goldens reference
      goldens="$PROJECT_DIR/_tools/eval/goldens.tsv"
      [[ -f "$goldens" ]] || return 1
      reference="$goldens"
      [[ -f "$STAMP_FILE" ]] && reference="$STAMP_FILE"
      [[ -d "$PROJECT_DIR/30_Flow" ]] && [[ -n "$(find "$PROJECT_DIR/30_Flow" -name '*.md' -newer "$reference" -print -quit 2>/dev/null)" ]]
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
```

権限: `chmod +x`

### 3. `.claude/settings.json`（上書き）

```json
{
  "_comment": "hooks・permissions は段階的に設計。Claude Code版 Phase 1-4。",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/gate-check.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/auto-build.sh",
            "timeout": 60
          },
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/auto-eval.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/auto-eval.sh",
            "timeout": 120
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "あなたはClaude CodeのStop hook判定者です。まず除外条件を確認してください: 直前の応答がすでに「チェックポイント・ルーティン」の実行結果（宿題一覧・衛生作業点検・次の一手を含む応答）である場合は必ず {\"ok\": true} のJSONだけを返してください。除外条件に該当しない場合、以下の発火条件を確認してください。条件: (1)フェーズ移行を伴う成果物が完成した (2)不可逆な分岐に到達した (3)成果物やタスクのまとまりが片付いた。いずれにも該当しない場合は {\"ok\": true} のJSONだけを返してください。発火条件に該当する場合は {\"ok\": false, \"reason\": \"チェックポイント・ルーチンを実行してください: 1. 何が片付いたかを一行で確認 2. 宿題を正典（00_プロジェクト管理/）から拾い直して一覧化 3. この一段落だからやるべき衛生作業を点検（入口文書の鮮度チェック・SSOT整合・バックアップ） 4. 次の一手を理由つきで推奨（判断はユーザー） 5. 必要なら入口の地図を更新＋git commitを提案\"} のJSONだけを返してください。入力: $ARGUMENTS",
            "timeout": 30
          }
        ]
      }
    ]
  },
  "permissions": {
    "allowedTools": []
  }
}
```

### 4. `.claude/agents/eval-judge.md`（新規作成）

```markdown
---
name: eval-judge
description: 成果物の品質を合格チェックリストに照らして判定するLLM-judge
tools: Read, Write, Bash
maxTurns: 15
model: opus
effort: high
---

あなたはプロジェクトマネジメント成果物の品質監査者です。

## 入力
呼び出し元から渡される情報:
1. 判定対象の成果物ファイルパス
2. judgeプロンプト（`_tools/eval/judge-prompt.md` のテンプレートに基づく）

## 判定ルール
- 各チェック項目を pass / fail / n/a で判定し、一文の根拠を付ける
- 「型（節が在るか）」ではなく「中身の質・判断の妥当性」を見る
- 判定基準: `_tools/eval/合格チェックリスト.md`
- 事実と推測の区別、数字の具体性、下流成果物との矛盾を重点確認

## 出力
結果を `_tools/eval/judge-results/result_{skill}_{case}.md` に書き出す。
書式:
~~~markdown
# Judge Result: {skill} / {case}
日時: YYYY-MM-DD HH:MM
モデル: {使用モデル}

## 判定結果
| # | チェック項目 | 判定 | 根拠 |
|---|---|---|---|

## 総合判定: PASS / FAIL
{1〜2文の総評}
~~~
```

### 5. `.claude/agents/researcher.md`（新規作成）

```markdown
---
name: researcher
description: Web検索と情報収集の専門エージェント。1つの検索軸に集中し、結果をファイルに書き出して要約のみ返す
tools: Read, Write, WebSearch, WebFetch
maxTurns: 30
model: sonnet
---

あなたは情報収集の専門エージェントです。

## ルール
- 1つの検索軸に集中する（1エージェント1責務）
- 調査結果は必ずファイルに書き出す（パスは呼び出し元が指定）
- メインへの返答は要約のみ（詳細はファイルを参照と伝える）
- 事実と推測を明確に区別する
- 数字・出典・日付を必ず含める
- 検索は日本語と英語の両方で行い、カバー範囲を広げる
```

### 6. `.claude/agents/integrity-checker.md`（新規作成）

```markdown
---
name: integrity-checker
description: 成果物間の整合性を検証する。project-context・チャーター・統合計画書・課題管理表の間で矛盾がないか確認
tools: Read, Grep, Glob
maxTurns: 20
model: sonnet
---

あなたは成果物間の整合性検証の専門エージェントです。

## 検証観点
1. project-context.mdの事実と各成果物の記載が矛盾していないか
2. 上流成果物の前提が下流で変わっていないか（スコープ・予算・期間）
3. ステークホルダー名・役割が全成果物で統一されているか
4. リスクや課題のIDが成果物間で正しく参照されているか

## 出力
矛盾を発見したら、以下の形式で報告:
- 矛盾箇所（ファイルパス + 該当行の内容）
- 何と何が矛盾しているか
- 推奨される修正方向
矛盾がなければ「整合性確認OK」と報告。
```

### 7. `.claude/agents/status-aggregator.md`（新規作成）

```markdown
---
name: status-aggregator
description: 状況報告用の複数ソース並列読み取り。課題管理表・リスク登録簿・WBSから進捗データを集約する
tools: Read, Grep, Glob, Write
maxTurns: 25
model: sonnet
---

あなたは状況報告のためのデータ集約エージェントです。

## 入力
呼び出し元から案件フォルダのパスを受け取る。

## 収集対象
1. 課題管理表: 未完了課題の件数・期限超過・優先度分布
2. リスク登録簿: アクティブリスク数・新規発生・対応期限
3. WBS(wbs.json): 全体進捗率・遅延タスク・クリティカルパス上の状況
4. 変更管理表: 未承認の変更要求

## 出力
集約結果をファイルに書き出す。フォーマットは呼び出し元が指定。
数字は必ず実数で記載（「概ね」「約」は使わない）。
```

---

## 既存ファイルとの差分サマリ

### auto-build.sh（変更3点）
- 内部5秒タイムアウトと `run_with_timeout` / heredocラッパーを除去（タイムアウトは settings.json の timeout フィールドで制御）
- 出力形式を PostToolUse 正式の `additionalContext` JSON に変更（旧: 平文エラー / 空の `{}`）
- SKILL.md パスの glob に `20_Skills/*/*/SKILL.md`（サブフォルダ）を追加
- hook内の単一Skillビルドは `build.sh --build-only` を使用し、全verify由来の偽陽性を避ける

### auto-eval.sh（全面書き換え）
- `hook_event_name` フィールドで PostToolUse / TaskCompleted を判別する二刀流に
- PostToolUse: `30_Flow/**/*.md` への書き込み時に発火
- TaskCompleted: 初回は `find -newer goldens.tsv`、以後はプロジェクト別の `/tmp` スタンプで前回eval以降の更新だけ判定（旧: git status 依存 → git不要に）
- 内部タイムアウト / heredocラッパー除去
- 出力形式を `additionalContext` JSON に変更

### settings.json（変更2点）
- PostToolUse の hooks 配列に auto-eval.sh を追加（auto-build.sh の後 = build→eval の順序）
- 各 command hook に timeout を明示（PostToolUse: 60秒、TaskCompleted: 120秒）

### 新規ファイル
- `.claude/agents/` ディレクトリ + 4ファイル（eval-judge / researcher / integrity-checker / status-aggregator）

### 変更なし
- `.claude/hooks/gate-check.sh` — API仕様と整合済み、そのまま

---

## 検証手順

### Step 1: ファイル配置確認

```bash
# 実行権限の確認
ls -la .claude/hooks/*.sh
# 期待: gate-check.sh, auto-build.sh, auto-eval.sh すべて -rwxr-xr-x

# エージェント定義の確認
ls .claude/agents/
# 期待: eval-judge.md, integrity-checker.md, researcher.md, status-aggregator.md

# settings.json の構造確認
jq '.hooks | keys' .claude/settings.json
# 期待: ["PostToolUse", "PreToolUse", "Stop", "TaskCompleted"]

jq '.hooks.PostToolUse[0].hooks | length' .claude/settings.json
# 期待: 2（auto-build + auto-eval）
```

### Step 2: テスト実行

```bash
bash _tools/test-hooks.sh
```

期待結果: `結果: PASS=25 FAIL=0 TOTAL=25`（サブエージェント4本の存在確認を含む）

### Step 3: 個別動作確認（オプション）

```bash
# gate-check: deny テスト
echo '{"tool_name":"Write","tool_input":{"file_path":"'"$(pwd)"'/30_Flow/テスト/01_立ち上げ/x.md"}}' \
  | CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/gate-check.sh | jq .hookSpecificOutput.permissionDecision
# 期待: "deny"

# auto-build: 無関係ファイル → 出力なし
echo '{"tool_name":"Write","tool_input":{"file_path":"'"$(pwd)"'/README.md"}}' \
  | CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/auto-build.sh
# 期待: 出力なし、exit 0

# auto-eval: PostToolUse + 30_Flow外 → skip
echo '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"'"$(pwd)"'/20_Skills/x.md"}}' \
  | CLAUDE_PROJECT_DIR="$(pwd)" bash .claude/hooks/auto-eval.sh
# 期待: 出力なし、exit 0
```

### Step 4: git commit

```bash
cd ~/AIプロジェクトリーダー
git add -A
git commit -m "feat: Hooks/CI基盤実装（WI-01〜07）— gate-check/auto-build/auto-eval/Stop prompt hook + サブエージェント4本 + test-hooks.sh拡充"
```

---

## 設計根拠（Codex が判断に迷ったとき用）

### なぜ内部タイムアウトを除去したか
PostToolUse のデフォルトタイムアウトは600秒（公式ドキュメント）。旧スクリプトの5秒内部タイムアウトは build.sh や eval.sh が途中で打ち切られるリスクがあった。settings.json の `timeout` フィールドで60秒/120秒を明示する方が正しい。

### なぜ PostToolUse の出力に additionalContext を使うか
PostToolUse はツール実行後に発火するためブロック不可（exit code 2 は stderr を Claude に見せるだけ）。`additionalContext` で Claude にフィードバックするのが公式の推奨方式。

### なぜ auto-eval を PostToolUse と TaskCompleted の両方に掛けるか
- PostToolUse: 30_Flow への .md 書き込み直後に即座にフィードバック（粒度が細かい）
- TaskCompleted: タスク完了時の安全網（PostToolUse で漏れたケースを拾う）。ただしプロジェクト別スタンプで前回eval以降の新規変更だけを対象にし、毎回evalが走り続ける状態を避ける。

### なぜ git 依存を除去したか
旧 auto-eval.sh は `git status --porcelain -- 30_Flow` で変更検知していたが、git が未初期化の環境で動作しない。初回は `find -newer goldens.tsv`、以後は `/tmp` のプロジェクト別スタンプを基準にする方式へ変更し、git 不要かつTaskCompletedごとの過剰実行を避ける。

### サブエージェント設計基準
`40_Stock/横断ガイドライン/サブエージェント設計基準.md` の6原則に準拠:
1. 1エージェント1責務
2. コンテキスト委譲（呼び出し元が必要情報を渡す）
3. ファイル書き出し（結果はファイルに、返答は要約のみ）
4. 暴走防止（tools を必要最小限に制限）
5. 具体的 description（曖昧な「何でも屋」にしない）
6. 段階的構築（まず使ってから育てる）
