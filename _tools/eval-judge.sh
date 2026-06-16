#!/usr/bin/env bash
# eval-judge.sh — 目視層（LLM-judge）の自動プロンプト生成＋判定結果の記録。
# 機械層（eval.sh）が「型」を見るのに対し、こちらは「中身の質」を見る。
#
# 使い方:
#   bash _tools/eval-judge.sh                   … 全ゴールデンのjudgeプロンプトを生成
#   bash _tools/eval-judge.sh <skill>           … その skill のゴールデンだけ
#   bash _tools/eval-judge.sh --prompt <skill> <case>  … 1件のプロンプトを標準出力
#
# Cowork での運用:
#   このスクリプトが生成したプロンプトをClaudeに渡してjudge判定させる。
#   結果は _tools/eval/judge-results/ に保存される。
#
# Claude Code 版への移植:
#   --prompt で生成したプロンプトを subagent に渡して自動実行する。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MANIFEST="$ROOT/_tools/eval/goldens.tsv"
CHECKLIST="$ROOT/_tools/eval/合格チェックリスト.md"
JUDGE_PROMPT="$ROOT/_tools/eval/judge-prompt.md"
RESULTS_DIR="$ROOT/_tools/eval/judge-results"
MODE="${1:-all}"

[[ -f "$MANIFEST" ]] || { echo "ERROR: goldens.tsv が無い" >&2; exit 2; }
[[ -f "$CHECKLIST" ]] || { echo "ERROR: 合格チェックリスト.md が無い" >&2; exit 2; }

# チェックリストからSkill固有項目を抽出する関数
extract_skill_checks() {
  local skill="$1"
  local in_skill=0
  local found=0
  while IFS= read -r line; do
    # Skill固有セクションの見出しを探す（各Skillの英名 or 日本語名）
    if [[ "$line" =~ ^\*\*${skill}\( || "$line" =~ ^\*\*${skill}（ ]]; then
      in_skill=1; found=1; continue
    fi
    # 次のSkillセクションに入ったら終了
    if [[ $in_skill -eq 1 && "$line" =~ ^\*\* ]]; then
      break
    fi
    if [[ $in_skill -eq 1 && -n "$line" ]]; then
      echo "$line"
    fi
  done < "$CHECKLIST"
  [[ $found -eq 1 ]] || echo "(Skill固有チェック項目なし)"
}

# 共通チェック項目を抽出する関数
extract_common_checks() {
  local in_common=0
  while IFS= read -r line; do
    if [[ "$line" == "## 共通チェック（全Skill）" ]]; then
      in_common=1; continue
    fi
    if [[ $in_common -eq 1 && "$line" =~ ^## ]]; then
      break
    fi
    if [[ $in_common -eq 1 && "$line" =~ ^-\ \[  ]]; then
      echo "$line"
    fi
  done < "$CHECKLIST"
}

# 1ゴールデンのjudgeプロンプトを生成
generate_prompt() {
  local skill="$1" kase="$2" path="$3"
  local f="$ROOT/$path"
  [[ -f "$f" ]] || { echo "ERROR: ファイルが無い: $path" >&2; return 1; }

  cat <<PROMPT_EOF
あなたはプロジェクトマネジメント成果物の品質監査者です。
以下の成果物を、チェックリストの各項目について pass / fail / n/a で判定し、各項目に一文で根拠を付けてください。
判定は「型（節が在るか）」ではなく「中身の質・判断の妥当性」を見ます。節が在っても中身が浅い・誤っていれば fail。
最後に、成果物全体の総合判定（pass/fail）と、fail があればそれが「Skillの指示の劣化」か「仕様が正しく変わった可能性（ゴールデン更新候補）」かの見立てを1〜2文で述べてください。

# 対象Skill
${skill}（案件: ${kase}）

# 共通チェック（全Skill）
$(extract_common_checks)

# Skill固有チェック
$(extract_skill_checks "$skill")

# 判定対象の成果物
$(cat "$f")
PROMPT_EOF
}

# --prompt モード: 1件のプロンプトを出力
if [[ "$MODE" == "--prompt" ]]; then
  SKILL="${2:-}"
  CASE="${3:-}"
  [[ -n "$SKILL" && -n "$CASE" ]] || { echo "Usage: eval-judge.sh --prompt <skill> <case>" >&2; exit 1; }
  while IFS=$'\t' read -r s k p t; do
    [[ -z "${s// }" || "${s:0:1}" == "#" ]] && continue
    [[ "$s" == "$SKILL" && "$k" == "$CASE" ]] || continue
    generate_prompt "$s" "$k" "$p"
    exit 0
  done < "$MANIFEST"
  echo "ERROR: ゴールデンが見つからない: $SKILL / $CASE" >&2; exit 1
fi

# 通常モード: 全件 or フィルタ。サマリを出力
FILTER=""
[[ "$MODE" != "all" ]] && FILTER="$MODE"

mkdir -p "$RESULTS_DIR"

total=0; generated=0; skipped=0
echo "=== eval-judge: LLM-judgeプロンプト生成 ==="
echo ""

while IFS=$'\t' read -r skill kase path tokens; do
  [[ -z "${skill// }" || "${skill:0:1}" == "#" ]] && continue
  [[ -n "$FILTER" && "$skill" != "$FILTER" ]] && continue
  total=$((total+1))

  f="$ROOT/$path"
  if [[ ! -f "$f" ]]; then
    echo "⚠️  $skill / $kase : ファイルなし（スキップ）"
    skipped=$((skipped+1)); continue
  fi

  # プロンプトファイルを保存
  outfile="$RESULTS_DIR/prompt_${skill}_${kase}.md"
  generate_prompt "$skill" "$kase" "$path" > "$outfile" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "📝 $skill / $kase → $(basename "$outfile")"
    generated=$((generated+1))
  else
    echo "⚠️  $skill / $kase : プロンプト生成失敗"
    skipped=$((skipped+1))
  fi
done < "$MANIFEST"

echo ""
echo "--------------------------------"
echo "ゴールデン ${total}件: プロンプト生成 ${generated} / スキップ ${skipped}"
echo "プロンプト出力先: _tools/eval/judge-results/"
echo ""
echo "【次のステップ】"
echo "  Cowork: 生成されたプロンプトを Claude に渡して判定を実行"
echo "  CC版:   subagent に --prompt <skill> <case> で渡して自動実行"
