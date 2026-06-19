# Claude Code版 実装仕様書

作成: 2026-06-17
目的: Cowork版で蓄積した設計をClaude Code版に移植する。本書をClaude Codeに渡して「これを順にやって」と言える粒度で書く。
前提ドキュメント: `00_プロジェクト管理/Claude_Code版を作るときの覚書_モデル堅牢性.md`（設計意図の正典）

> **最初にやること**: 本書の設定キー・API名は2026-06-17時点の公式ドキュメントに基づく。着手時に `https://docs.anthropic.com/en/docs/claude-code/hooks` と `https://code.claude.com/docs/en/sub-agents` で裏取りし、変わっていたら本書を更新してから実装に入ること。

---

## 0. 全体像（8件・依存順）

```
Phase 0（基盤構築）✅ 完了 2026-06-17
  ├─ CLAUDE.md 作成
  ├─ .claude/settings.json 最小構成作成
  ├─ .claude/agents/llm-judge.md 最小版作成（WI-03で差し替え）
  ├─ build.sh --sync-cc 実装（.claude/skills/ 同期）
  ├─ package-dist.sh --target claude-code 実装
  ├─ _dist/ Git追跡解除 + .gitignore追加
  ├─ .claude/skills/ を .gitignore追加（生成物扱い）
  ├─ build.sh --verify にCC skills ドリフト検査追加
  └─ test-dist-cc.sh スモークテスト追加

Phase 1（急所1＝承認ゲート）✅ 実装・テスト済 2026-06-19
  └─ WI-01: 停止ポイントのHooks構造強制

Phase 2（急所2＋基盤防御＝PostToolUseまとめ実装）✅ 実装・テスト済 2026-06-19
  ├─ WI-04: build/verify/syncのHook化
  └─ WI-02: eval.shのHook自動実行
  ※ WI-04→WI-02の順で settings.json に配列登録（build→evalの実行順を守る）

Phase 3（質の自動判定）✅ 実装済 2026-06-19（eval-judge subagent定義）
  └─ WI-03: LLM-judgeのsubagent自動化

Phase 4（自動回復＋移植の仕上げ）✅ 実装済 2026-06-19
  ├─ WI-05: 一段落チェックポイントのHook化（Stop prompt hook）
  ├─ WI-06: サブエージェント正式定義（4本: eval-judge/researcher/integrity-checker/status-aggregator）
  └─ WI-07: モデル使い分けの設定表現（eval-judge=opus, 他=sonnet）

Phase 5（実地テスト）
  └─ WI-08: Hooks基盤CC実環境検証                ✅ 検証完了 2026-06-19

  ※ Phase 1-5 全完了。次はW-02（監視push化）着手判断。
```

Phase 1→2→3は依存順。Phase 4は3と並行可。Phase 5はWI-01〜07完了後に手動実施。

### Phase変更の理由（2026-06-17追記）
- **WI-02とWI-04を同一Phaseにまとめた**: 両方が `PostToolUse` + `Write|Edit` マッチャーを使い、settings.jsonの配列で `build→eval` の順序を守る必要がある。別Phaseだとsettings.jsonの並べ替え手戻りが発生するため。
- **Phase 0を追加**: Codexで基盤構築済み。WI実装の前提が整っている。

---

## WI-01: 停止ポイントのHooks構造強制

### Why
最大の見落としリスク（急所1）。不可逆・高stakesの承認ゲート（✋✋）がCoworkでは指示だけで構造強制でない。弱い/別モデルは承認ゲートを飛ばしうる。

### What
不可逆ゲート3箇所を、承認マーカーが無ければ次フェーズの成果物書き込みをブロックするHookにする。

対象ゲート（まずこの3つだけ。全停止の鍵化は後）:

| ゲート | 承認マーカーの条件 | ブロック対象 |
|---|---|---|
| 前段0-4承認 | `30_Flow/{案件}/00_前段/計画提案書*.md` 内に `## 承認記録` セクションが存在 | `30_Flow/{案件}/10_立ち上げ/` 以降へのWrite/Edit |
| 計画承認 | `30_Flow/{案件}/20_計画/統合計画書*.md` 内に `## 承認記録` が存在 | `30_Flow/{案件}/30_実行/` 以降へのWrite/Edit |
| 終結docx確定 | `30_Flow/{案件}/50_終結/終結報告書*.md` 内に `## 提出版確定` が存在 | 終結報告書のdocx生成（Bash内のpython-docx呼び出し） |

### How（実装指示）

**Hook種別**: `PreToolUse`（Write/Editを捕まえてdeny）
**設定ファイル**: `.claude/settings.json`（プロジェクトにcommit）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/gate-check.sh"
          }
        ]
      }
    ]
  }
}
```

**`.claude/hooks/gate-check.sh` の仕様**:

入力: stdin から JSON（`tool_name`, `tool_input` 含む）。`tool_input.file_path` で書き込み先パスを取得。
処理:
1. 書き込み先が `30_Flow/{案件}/10_立ち上げ/` 以降のパスか判定。該当しなければallow。
2. 該当する場合、対応する承認マーカーファイルを探索。
3. マーカーファイル内に `## 承認記録` セクション（前段/計画）or `## 提出版確定`（終結）が在るか grep。
4. 在ればallow、無ければdeny。

出力: JSON。

```bash
#!/usr/bin/env bash
# gate-check.sh — 承認ゲートのHooks構造強制
set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Write/Edit以外は素通し
[[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]] || { echo '{}'; exit 0; }
[[ -n "$FILE_PATH" ]] || { echo '{}'; exit 0; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR}"
FLOW_DIR="$PROJECT_DIR/30_Flow"

# 30_Flow配下でなければ関係なし
[[ "$FILE_PATH" == "$FLOW_DIR"/* ]] || { echo '{}'; exit 0; }

# パスから案件名とフェーズを抽出
REL="${FILE_PATH#$FLOW_DIR/}"
CASE_NAME="${REL%%/*}"
PHASE_PATH="${REL#*/}"

# フェーズ判定
allow_json='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
deny_json_tpl='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"REASON"}}'

check_marker() {
  local marker_dir="$1" pattern="$2" section="$3"
  local found=0
  for f in "$FLOW_DIR/$CASE_NAME/$marker_dir"/$pattern; do
    [[ -f "$f" ]] || continue
    grep -q "^## $section" "$f" && { found=1; break; }
  done
  echo $found
}

# 10_立ち上げ以降 → 前段0-4承認が必要
if [[ "$PHASE_PATH" == 10_立ち上げ/* || "$PHASE_PATH" == 20_計画/* || "$PHASE_PATH" == 30_実行/* || "$PHASE_PATH" == 40_監視/* || "$PHASE_PATH" == 50_終結/* ]]; then
  if [[ $(check_marker "00_前段" "計画提案書*.md" "承認記録") -eq 0 ]]; then
    echo "${deny_json_tpl/REASON/前段0-4の承認記録がありません。計画提案書に「## 承認記録」を追記してから進めてください。}"
    exit 0
  fi
fi

# 20_計画以降（実行・監視・終結）→ 計画承認が必要
if [[ "$PHASE_PATH" == 30_実行/* || "$PHASE_PATH" == 40_監視/* || "$PHASE_PATH" == 50_終結/* ]]; then
  if [[ $(check_marker "20_計画" "統合計画書*.md" "承認記録") -eq 0 ]]; then
    echo "${deny_json_tpl/REASON/計画の承認記録がありません。統合計画書に「## 承認記録」を追記してから進めてください。}"
    exit 0
  fi
fi

# 終結docx確定チェック（Bashでdocx生成を叩く場合はWI-01の範囲外＝後続で追加）

echo "$allow_json"
```

### 受け入れ条件
- [ ] 承認記録なしで `30_Flow/テスト案件/10_立ち上げ/` にWrite → deny されること
- [ ] 承認記録ありで同じ操作 → allow されること
- [ ] `30_Flow` 外のファイル → 影響なし
- [ ] `20_Skills/` 等の開発ファイル → 影響なし

---

## WI-02: eval.shのHook自動実行

### Why
急所2。機械eval（型チェック）を手動忘れで空振りさせないために、成果物書き込み後に自動で回す。

### What
`30_Flow/` 配下への成果物書き込み完了後に `_tools/eval.sh` を自動実行し、FAILなら警告を返す。

### How

**Hook種別**: `PostToolUse`（Write/Edit完了後）
**設定ファイル**: `.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/auto-eval.sh"
          }
        ]
      }
    ]
  }
}
```

**`.claude/hooks/auto-eval.sh` の仕様**:

1. stdin から JSON を読み、`tool_input.file_path` を取得。
2. `30_Flow/` 配下の `.md` ファイルでなければ何もせず終了（開発中のSkill編集等に反応しない）。
3. パスからSkill名を推定し `bash _tools/eval.sh <skill>` を実行。
4. exit code が 0 以外なら `decision: "block"` + 理由を返す（Claudeに「evalがFAILしている」と伝える）。
5. exit 0 なら空JSONを返す。

```bash
#!/usr/bin/env bash
set -uo pipefail
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // .tool_input.command // empty')

# 30_Flow配下のmd以外はスキップ
[[ "$FILE_PATH" == *30_Flow/*.md ]] || { echo '{}'; exit 0; }

# eval実行（全件＝軽い。特定Skillに絞りたければここで抽出）
RESULT=$(bash "${CLAUDE_PROJECT_DIR}/_tools/eval.sh" 2>&1) || true
EXIT_CODE=${PIPESTATUS[0]:-$?}

if [[ $EXIT_CODE -ne 0 ]]; then
  # FAILを通知（blockではなく警告として返す＝作業は止めないが気づかせる）
  ESCAPED=$(echo "$RESULT" | tail -5 | jq -Rs .)
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"message\":\"⚠️ eval.sh FAIL: ${ESCAPED}\"}}"
else
  echo '{}'
fi
```

> **設計判断**: PostToolUseの `decision: "block"` にすると成果物の書き込み自体は済んでいるので巻き戻しはできない。ここではblockではなくメッセージで警告し、Claudeに修正を促す形にする。本当に止めたい場合はPreToolUse側でevalを先に回す設計に変更可。

### 受け入れ条件
- [ ] `30_Flow/` 配下にmdを書き込むとeval.shが自動で走ること
- [ ] eval FAIL時にClaudeがFAILメッセージを受け取ること
- [ ] `20_Skills/` への書き込みでは発火しないこと

---

## WI-03: LLM-judgeのsubagent自動化

### Why
急所2の質の網。機械eval（型）が緑でも中身が浅い/誤りの出力は通る。LLM-judgeを人手でなくsubagentで自動実行する。

### What
`_tools/eval-judge.sh --prompt <skill> <case>` が生成するプロンプトを、専用subagentに渡して判定→結果を `_tools/eval/judge-results/result_*.md` に書き出す。

### How

**`.claude/agents/eval-judge.md`**:

```yaml
---
name: eval-judge
description: 成果物の品質を合格チェックリストに照らして判定するLLM-judge。eval-judge.shが生成したプロンプトを受け取り、pass/failを返す。
tools: Read, Write, Bash
maxTurns: 15
model: opus
effort: high
---

あなたはプロジェクトマネジメント成果物の品質監査者です。
渡されたjudgeプロンプトの指示に従い、各チェック項目を pass / fail / n/a で判定し、一文の根拠を付けてください。
判定は「型（節が在るか）」ではなく「中身の質・判断の妥当性」を見ます。
結果は指定されたファイルパスに書き出してください。
```

**実行フロー（呼び出し側のSkillまたはスクリプトから）**:

```
1. bash _tools/eval-judge.sh --prompt <skill> <case> > /tmp/judge-prompt.txt
2. Agent(eval-judge) に渡す:
   「以下のjudgeプロンプトで判定し、結果を _tools/eval/judge-results/result_{skill}_{case}.md に書き出せ」
   + /tmp/judge-prompt.txt の中身
3. 結果ファイルを読み、総合判定がfailなら警告
```

**一括実行コマンド（手動 or CI）**:

```bash
# 全ゴールデンをsubagentで判定（Claude Code CLIから）
for row in $(tail -n +2 _tools/eval/goldens.tsv); do
  skill=$(echo "$row" | cut -f1)
  kase=$(echo "$row" | cut -f2)
  claude --agent eval-judge \
    "$(bash _tools/eval-judge.sh --prompt "$skill" "$kase")" \
    --max-turns 15
done
```

> **注意**: 上記CLIの `--agent` フラグの正確な記法は着手時に確認。`claude agent eval-judge` の形式かもしれない。

### 受け入れ条件
- [ ] subagentが判定結果を `judge-results/result_*.md` に書き出すこと
- [ ] 判定者モデルが実行モデルより強い or 同等であること（覚書§5）
- [ ] 1ゴールデンあたり15ターン以内で完了すること

---

## WI-04: build/verify/syncのHook化

### Why
基盤防御。手動の `build.sh --verify` / `--sync` の実行忘れを構造で潰す。

### What

| トリガー | 実行内容 |
|---|---|
| 正典ファイル（`sync-manifest.tsv` に載っているソース）の編集後 | `build.sh --sync`（コピー反映＋再パッケージ＋verify） |
| `20_Skills/` 配下のSKILL.md編集後 | `build.sh <そのSkillディレクトリ>`（再パッケージ＋verify） |
| Git commit前（可能なら） | `build.sh --verify`（非破壊の健全性点検） |

### How

**PostToolUse Hook（正典/Skill編集）**:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/auto-build.sh"
          }
        ]
      }
    ]
  }
}
```

**`.claude/hooks/auto-build.sh`**:

```bash
#!/usr/bin/env bash
set -uo pipefail
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')
[[ -n "$FILE_PATH" ]] || { echo '{}'; exit 0; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR}"

# 正典ファイルが編集された → sync
if grep -qF "${FILE_PATH#$PROJECT_DIR/}" "$PROJECT_DIR/_tools/sync-manifest.tsv" 2>/dev/null; then
  bash "$PROJECT_DIR/_tools/build.sh" --sync 2>&1 | tail -3
  echo '{}'
  exit 0
fi

# SKILL.md が編集された → そのSkillを再ビルド
if [[ "$FILE_PATH" == */SKILL.md ]]; then
  SKILL_DIR="$(dirname "$FILE_PATH")"
  bash "$PROJECT_DIR/_tools/build.sh" "$SKILL_DIR" 2>&1 | tail -3
  echo '{}'
  exit 0
fi

echo '{}'
```

> **注意**: WI-02のauto-eval.shとWI-04のauto-build.shは同じPostToolUseに掛かる。`.claude/settings.json` では同一matcherに複数hookを配列で並べられる。実行順=配列順。build → eval の順にする。WI-04とWI-02はPhase 2でまとめて実装し、settings.jsonへの登録順を `[auto-build, auto-eval]` にすること。

### 受け入れ条件
- [ ] 正典ファイルを編集 → sync が自動で走ること
- [ ] SKILL.mdを編集 → そのSkillが再パッケージされること
- [ ] verify FAIL時にメッセージが出ること

---

## WI-05: 一段落チェックポイントのHook化

### Why
節目で宿題棚卸し＋衛生チェック＋次の一手を自動発火。Coworkではメモリーの"オーラ"で効かせていたものを、CC版でHookに格上げして真の自動発火にする。

### What
フェーズ移行（成果物の完成 → 次フェーズの着手）を検知し、チェックポイント・ルーチンをprompt hookで自動注入する。

### How

**Hook種別**: `Stop`（Claudeのターン終了時）
**hook type**: `prompt`（LLMに追加指示を注入）

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "直前の作業を振り返ってください。以下の条件のいずれかに該当する場合は、チェックポイント・ルーチンを実行してください：(1)フェーズ移行を伴う成果物が完成した (2)不可逆な分岐に到達した (3)成果物やタスクのまとまりが片付いた。該当しない場合は何もせず続行。\n\nルーチン（該当時のみ）：\n1. 何が片付いたかを一行で確認\n2. 宿題を正典（00_プロジェクト管理/）から拾い直して一覧化\n3. この一段落だからやるべき衛生作業を点検（入口文書の鮮度チェック・SSOT整合・バックアップ）\n4. 次の一手を理由つきで推奨（判断はユーザー）\n5. 必要なら入口の地図を更新＋git commitを提案"
          }
        ]
      }
    ]
  }
}
```

> **設計判断**: Stopイベント＋prompt hookにすることで、毎ターン終了時にLLMが「該当するか」を自己判定する。形骸化を防ぐために「該当しない場合は何もせず続行」を明記。該当判定の精度が低い場合はmatcherの `if` フィールドでbashスクリプトによるファイル変更検知を追加する。
>
> **Codex実装時の注意**: 該当判定の精度は未知数。まず入れてみて、実運用（WI-08）で形骸化したら調整する前提。

### 受け入れ条件
- [ ] フェーズ完了を伴う作業後にチェックポイントが自動発火すること
- [ ] 単純なファイル編集では発火しないこと（形骸化しない）
- [ ] ルーチンの5ステップが実行されること

---

## WI-06: サブエージェント正式定義

### Why
Coworkでは不可能だった制約（maxTurns/ツール制限/自動委譲）をCC版で解消する。

### What
以下のサブエージェントを `.claude/agents/` に定義する。

| 名前 | 役割 | tools | maxTurns | model | 優先度 |
|---|---|---|---|---|---|
| eval-judge | 成果物のLLM品質判定 | Read, Write, Bash | 15 | opus | Tier1（WI-03で作成済） |
| researcher | 並列Web検索＋ファイル書き出し | Read, Write, Bash, WebSearch | 30 | sonnet | Tier1 |
| integrity-checker | 成果物間の整合性検証 | Read, Grep, Glob | 20 | sonnet | Tier3 |
| status-aggregator | 状況報告用の複数ソース並列読み取り | Read, Grep, Glob, Write | 25 | sonnet | Tier2 |

### How

> **Codex実装時の注意**: 各エージェント定義は `40_Stock/横断ガイドライン/サブエージェント設計基準.md` の6原則+3アンチパターンと整合していること。実装前にこのガイドラインを読み、違反がないか確認すること。

各エージェントを `.claude/agents/{name}.md` として作成。例（researcher）:

```yaml
---
name: researcher
description: Web検索と情報収集の専門エージェント。検索軸ごとに並列調査し、結果をファイルに書き出して要約のみ返す。research-memoのサブエージェントとして使う。
tools: Read, Write, Bash, WebSearch
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
```

### 受け入れ条件
- [ ] 各エージェントが `.claude/agents/` に存在すること
- [ ] maxTurnsを超えた場合に自動停止すること
- [ ] toolsで指定した以外のツールが使えないこと

---

## WI-07: モデル使い分けの設定表現

### Why
覚書§5の運用ルール（作る系=強モデル/回す系=寛容）を設定で固定し、人間の記憶依存を無くす。

### What
サブエージェントのfrontmatterでmodelを指定。メインのClaude Codeセッションのモデルは手動選択だが、CLAUDE.mdにルールを明記する。

### How

1. 各 `.claude/agents/*.md` のfrontmatterに `model:` を設定（WI-06で実施済）。
2. `CLAUDE.md` に以下を追記:

```markdown
## モデル使い分けルール

- 作る系（新Skill伴走・references起草・テーラリング設計・計画提案書の設計意図）: 強モデル（opus）必須
- 回す系（既存Skillで成果物生成・定型巻き上げ）: 別モデル可（sonnet以上）
- モデルを交代したら: 着手前に `bash _tools/eval.sh` 全件 + 主要Skillの judge を流す
```

### 受け入れ条件
- [ ] CLAUDE.mdにルールが明記されていること
- [ ] サブエージェントのmodelが役割に応じて設定されていること

---

## WI-08: M-08 ポータビリティ確定

### Why
Cowork→CC移植で壊れる箇所を洗い出し、移植漏れを防ぐ。

### What
WI-01〜07の実装後に、以下を実地確認する。

### チェック項目（2026-06-19実環境検証結果）

| 確認事項 | 想定 | 実地で確認 |
|---|---|---|
| Skill本体（SKILL.md + references/）のパス | `20_Skills/` → `.claude/skills/` に `build.sh --sync-cc` でコピー | ✅ build.sh --verify で37/37件同期確認 |
| descriptionトリガー（Subagent） | 4本がCC版に認識されるはず | ✅ test-hooks.shで4本存在確認。`.claude/agents/`への配置で認識 |
| 停止ポイント（✋）gate-check.sh動作 | WI-01のHooksで構造強制に格上げ済 | ✅ 実動作確認: 承認記録なし→deny・あり→allow |
| eval.sh / build.sh のパス解決 | bashスクリプトなのでそのまま動くはず | ✅ CLAUDE_PROJECT_DIR経由でeval.log/build.log生成確認 |
| .skill形式（zipパッケージ） | CC版はskillsディレクトリ直置き | ✅ `.claude/skills/`直置き方式で37件動作確認 |
| project-context.md の読み込み | Skill内で明示参照しているので動くはず | 🟡 未確認（フル実案件実走は3案件目スコープ）|
| chain-trace.json の書き込み | bashスクリプトなのでそのまま | 🟡 未確認（フル実案件実走は3案件目スコープ）|

**残リスク**: hook実行環境（locale差異）でpost-build verify()のwbs-builder偽陽性が発生するケースあり（手動実行では再現せず）。

### How（実施済）
WI-01〜07の動作をClaude Code実セッションで直接検証。gate-check.sh deny/allow・auto-eval.sh PostToolUse発火・auto-build.sh SKILL.md編集トリガーを実動作で確認。

### 受け入れ条件
- ✅ CC実環境でgate-check.shのdeny/allowを確認済み
- ✅ auto-eval.shのPostToolUse発火・ログ確認済み
- ✅ auto-build.shのSKILL.md編集トリガー・ログ確認済み
- ✅ サブエージェント4本認識確認済み
- 🟡 テスト案件での前段chain→計画フル実走（3案件目実証で検証予定）

---

## 実装時の共通ルール

### ファイル配置

```
.claude/
├── settings.json          ← Hooks設定（WI-01〜05）
├── hooks/
│   ├── gate-check.sh      ← WI-01: 承認ゲート
│   ├── auto-eval.sh       ← WI-02: eval自動実行
│   └── auto-build.sh      ← WI-04: build自動実行
├── agents/
│   ├── eval-judge.md       ← WI-03/06: LLM-judge
│   ├── researcher.md       ← WI-06: 並列検索
│   ├── integrity-checker.md← WI-06: 整合性検証
│   └── status-aggregator.md← WI-06: 状況報告集約
└── skills/                 ← build.sh --sync-cc で同期
    ├── anken-rikai-summary/
    ├── kadai-kasetsu-sheet/
    └── ...
```

### 設計原則（守ること）
1. **1Skill=1成果物** は変えない。
2. **共通ひな形・eval・references分離** の4点は触らない（メモリー `architecture-do-not-simplify`）。
3. **可逆性軸**: 可逆な一手は踏み込む、不可逆は必ず止める。
4. **段階的構築**: 一度に完璧を目指さず、Phase 1から順に動くものを作って確認。

### テスト方法
各WIの受け入れ条件をそのままテストケースとして使う。WI-01〜04はhookの発火テストなので、テスト用の `30_Flow/テスト案件/` を用意して確認する。

---

## 着手の手順

### 前提（着手前に必ず実施）
0. Hooks公式ドキュメント（下記参照先）で裏取り。本書のJSON構造が現行APIと合っているか検証。変わっていたら本書を更新してから実装に入る。

### Phase 0 ✅ 完了
- `.claude/` ディレクトリ、settings.json、llm-judge.md（最小版）、skills同期、配布分離、Git整理

### Phase 1 → Codexに投げてOK
1. WI-01: gate-check.sh を実装 → `.claude/hooks/` に配置 → settings.json の PreToolUse に登録 → テスト

### Phase 2 → Codexに投げてOK（WI-04とWI-02をまとめて実装）
2. WI-04: auto-build.sh を実装 → `.claude/hooks/` に配置
3. WI-02: auto-eval.sh を実装 → `.claude/hooks/` に配置
4. settings.json の PostToolUse に `[auto-build, auto-eval]` の順で登録 → テスト

### Phase 3 → Codexに投げてOK
5. WI-03: eval-judge.md を既存ファイルから差し替え → 1ゴールデンで試行

### Phase 4 → Codexに投げてOK（WI-05/06は注意付き）
6. WI-05: Stopのprompt hookを settings.jsonに追加 → テスト案件で確認（形骸化したら後で調整）
7. WI-06: 残りのagentを作成（サブエージェント設計基準.mdとの整合を確認してから）
8. WI-07: CLAUDE.mdにモデルルールを追記

### Phase 5 → 手動（Codexに出さない）
9. WI-08: Claude Codeでテスト案件を一通り流して確認
10. 全受け入れ条件の通過を確認 → 完了

---

## 参照先一覧

| ドキュメント | 場所 | 用途 |
|---|---|---|
| 覚書（設計意図の正典） | `00_プロジェクト管理/Claude_Code版を作るときの覚書_モデル堅牢性.md` | Whyの根拠 |
| サブエージェント設計基準 | `40_Stock/横断ガイドライン/サブエージェント設計基準.md` | 6原則+3アンチパターン |
| 合格チェックリスト | `_tools/eval/合格チェックリスト.md` | LLM-judgeの判定基準 |
| judgeプロンプト | `_tools/eval/judge-prompt.md` | judge の指示文テンプレート |
| goldens.tsv | `_tools/eval/goldens.tsv` | 回帰evalのゴールデン一覧 |
| sync-manifest.tsv | `_tools/sync-manifest.tsv` | 正典→コピーの対応表 |
| Hooks公式ドキュメント | https://docs.anthropic.com/en/docs/claude-code/hooks | API仕様の裏取り |
| Subagent公式ドキュメント | https://code.claude.com/docs/en/sub-agents | API仕様の裏取り |
