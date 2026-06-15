#!/usr/bin/env bash
# 共通項（正典→配布コピー）の同期・検査ツール（マニフェスト式）
#   bash _tools/sync.sh check  … 全コピーが正典と一致か検証（非破壊。ズレで exit 1）
#   bash _tools/sync.sh sync   … 正典→コピーを反映し、影響する .skill を再パッケージ
#   bash _tools/sync.sh        … 引数なしは check
# マニフェスト: _tools/sync-manifest.tsv（<正典>\t<コピー先>。#・空行は無視）
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
source "$HERE/_lib.sh"
MANIFEST="$ROOT/_tools/sync-manifest.tsv"
MODE="${1:-check}"
[[ -f "$MANIFEST" ]] || { echo "ERROR: マニフェストが無い: $MANIFEST" >&2; exit 2; }

do_sync() {
  local -A skilldirs=()
  local master copy
  while IFS=$'\t' read -r master copy _; do
    [[ -z "${master// }" || "${master:0:1}" == "#" ]] && continue
    local m="$ROOT/$master" c="$ROOT/$copy"
    [[ -f "$m" ]] || { echo "SKIP 正典なし: $master" >&2; continue; }
    mkdir -p "$(dirname "$c")"; cp "$m" "$c"; echo "copied → $copy"
    [[ "$copy" == 20_Skills/*/references/* ]] && skilldirs["${copy%%/references/*}"]=1
  done < "$MANIFEST"
  for sd in "${!skilldirs[@]}"; do
    if [[ -f "$ROOT/$sd.skill" ]]; then
      repackage_skill "$ROOT/$sd" && echo "repackaged → $sd.skill"
    fi
  done
  echo "--- sync 完了。整合確認: ---"
  check_drift "$ROOT" "$MANIFEST" || true
  echo "※ 再パッケージした Skill は Save skill カードから再登録してください。"
}

case "$MODE" in
  check) check_drift "$ROOT" "$MANIFEST" && echo "✅ 全コピーが正典と一致" ;;
  sync)  do_sync ;;
  *) echo "usage: bash _tools/sync.sh [check|sync]" >&2; exit 2 ;;
esac
