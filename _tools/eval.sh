#!/usr/bin/env bash
# 回帰eval の機械チェック層（M-04）。ゴールデン案件の出力が「型として崩れていないか」を点検する。
# 値の厳密一致はしない（LLM出力なので無理）。代わりに各ゴールデンに「ファイルが在るか」＋「節の核トークンが全て在るか」を見る。
# 目視層（状態は言葉/数字ぼかさない/下流と矛盾しない 等）は eval-judge.sh でプロンプト生成→判定結果保存→--checkで確認する。
#   bash _tools/eval.sh            … 全ゴールデンを点検（0=全PASS）
#   bash _tools/eval.sh <skill>    … その skill のゴールデンだけ点検
# いつ流すか: Skill改訂時／モデル交代時／配布前。build.sh --verify（構造健全性・ドリフト）とは別の層。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MANIFEST="$ROOT/_tools/eval/goldens.tsv"
FILTER="${1:-}"

[[ -f "$MANIFEST" ]] || { echo "ERROR: goldens.tsv が無い: $MANIFEST" >&2; exit 2; }

total=0; pass=0; fail=0
echo "=== 回帰eval（ゴールデン点検）==="
while IFS=$'\t' read -r skill kase path tokens; do
  # コメント・空行を飛ばす
  [[ -z "${skill// }" || "${skill:0:1}" == "#" ]] && continue
  [[ -n "$FILTER" && "$skill" != "$FILTER" ]] && continue
  total=$((total+1))
  local_problems=""
  f="$ROOT/$path"
  if [[ ! -f "$f" ]]; then
    echo "❌ $skill / $kase : ファイルが無い → $path"
    fail=$((fail+1)); continue
  fi
  # 必須トークン（||区切り）が全て本文に在るか。
  # file:<root相対パス> は軽量smoke用の存在確認として扱う。
  missing=""
  IFS='|' read -ra toks <<< "${tokens//||/|}"
  for t in "${toks[@]}"; do
    [[ -z "${t// }" ]] && continue
    if [[ "$t" == file:* ]]; then
      required_path="${t#file:}"
      [[ -e "$ROOT/$required_path" ]] || missing+="「$t」 "
    else
      grep -qF -- "$t" "$f" || missing+="「$t」 "
    fi
  done
  if [[ -n "$missing" ]]; then
    echo "❌ $skill / $kase : 核トークン欠落 → $missing"
    fail=$((fail+1))
  else
    echo "✅ $skill / $kase"
    pass=$((pass+1))
  fi
done < "$MANIFEST"

echo "--------------------------------"
echo "ゴールデン ${total}件: PASS ${pass} / FAIL ${fail}"
if [[ $fail -eq 0 ]]; then
  echo "✅ eval: 回帰なし（型は維持されている）"
  echo "※ 目視層: bash _tools/eval-judge.sh <skill> でプロンプト生成 → 判定後に --check <skill>"
  exit 0
else
  echo "⚠️  eval: ${fail}件のゴールデンで型が崩れている（上記）"
  exit 1
fi
