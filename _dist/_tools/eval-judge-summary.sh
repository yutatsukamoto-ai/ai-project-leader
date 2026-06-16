#!/usr/bin/env bash
# eval-judge-summary.sh — judge結果ファイルを集計し、合否サマリーを出力する。
#
# 使い方:
#   bash _tools/eval-judge-summary.sh              … 全結果を集計
#   bash _tools/eval-judge-summary.sh <skill>      … そのSkillの結果だけ
#
# 結果ファイル形式:
#   _tools/eval/judge-results/result_{skill}_{case}.md
#   frontmatter に verdict: pass|fail、fail_count: N を持つ。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$HERE/eval/judge-results"
FILTER="${1:-}"

total=0; pass=0; fail=0; missing=0

echo "=== eval-judge: 品質判定サマリー ==="
echo ""

# goldens.tsv から期待されるゴールデン一覧を読み、結果があるかチェック
MANIFEST="$HERE/eval/goldens.tsv"
while IFS=$'\t' read -r skill kase path tokens; do
  [[ -z "${skill// }" || "${skill:0:1}" == "#" ]] && continue
  [[ -n "$FILTER" && "$skill" != "$FILTER" ]] && continue
  total=$((total+1))

  result_file="$RESULTS_DIR/result_${skill}_${kase}.md"
  if [[ ! -f "$result_file" ]]; then
    echo "⚠️  $skill / $kase : 結果ファイルなし"
    missing=$((missing+1))
    continue
  fi

  # frontmatter から verdict を抽出
  verdict=$(sed -n '/^---$/,/^---$/{ /^verdict:/{ s/^verdict: *//; p; q; } }' "$result_file")
  fc=$(sed -n '/^---$/,/^---$/{ /^fail_count:/{ s/^fail_count: *//; p; q; } }' "$result_file")

  case "$verdict" in
    pass)
      echo "✅ $skill / $kase (fail項目: ${fc:-0})"
      pass=$((pass+1))
      ;;
    fail)
      echo "❌ $skill / $kase (fail項目: ${fc:-?})"
      # fail の詳細行を抽出して表示
      grep -E "^- \[.+\] fail" "$result_file" | head -5 | while read -r line; do
        echo "   └─ $line"
      done
      fail=$((fail+1))
      ;;
    *)
      echo "⚠️  $skill / $kase : verdict不明 (${verdict:-空})"
      missing=$((missing+1))
      ;;
  esac
done < "$MANIFEST"

echo ""
echo "--------------------------------"
echo "対象 ${total}件: PASS ${pass} / FAIL ${fail} / 未判定 ${missing}"

if [[ $fail -gt 0 ]]; then
  echo "⚠️  FAILあり — Skill劣化 or ゴールデン更新が必要"
  exit 1
elif [[ $missing -gt 0 ]]; then
  echo "⚠️  未判定あり — eval-judgeを実行してください"
  exit 2
else
  echo "✅ 全件PASS（品質維持）"
  exit 0
fi
