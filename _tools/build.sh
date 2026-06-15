#!/usr/bin/env bash
# Skillパッケージ化の唯一の入口。手作業zipを禁じ、壊れビルド（0バイト・ルート不正・ゴミ残り）を構造的に防ぐ。
#   bash _tools/build.sh <skillディレクトリ>  … そのSkillを正しく再パッケージ＋検証＋全体verify
#   bash _tools/build.sh --all                … 既存の .skill を全て作り直す＋検証
#   bash _tools/build.sh --verify             … 非破壊：全 .skill の健全性＋ゴミ＋ドリフトを点検（毎日の自動チェック用）
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
source "$HERE/_lib.sh"
MANIFEST="$ROOT/_tools/sync-manifest.tsv"

# 非破壊の全体点検。0=健全。
verify() {
  local problems=0
  echo "=== .skill 健全性 ==="
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if validate_skill_file "$f"; then echo "✅ $(basename "$f")"; else problems=$((problems+1)); fi
  done < <(find "$ROOT/20_Skills" -type f -name '*.skill' 2>/dev/null | sort)

  echo "=== 未パッケージのSkill本体（情報・骨組み等は想定内） ==="
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    [[ -f "$d.skill" ]] || echo "ℹ️  .skill未生成: ${d#$ROOT/}"
  done < <(list_skill_dirs "$ROOT" | sort -u)

  echo "=== ビルド事故ゴミ（正体不明ファイル） ==="
  local stray; stray="$(find_stray_archives "$ROOT")"
  if [[ -n "$stray" ]]; then echo "$stray" | sed "s#$ROOT/##" | sed 's/^/❌ ゴミ?: /'; problems=$((problems+1)); else echo "✅ なし"; fi

  echo "=== 共通項のドリフト ==="
  check_drift "$ROOT" "$MANIFEST" || problems=$((problems+1))

  echo "=== 成果物マップ↔実構成 ==="
  check_map_consistency "$ROOT" "$ROOT/20_Skills/成果物マップ.md" || problems=$((problems+1))

  echo "================================"
  if [[ $problems -eq 0 ]]; then echo "✅ verify: 異常なし"; return 0
  else echo "⚠️  verify: ${problems}種類の問題あり（上記）"; return 1; fi
}

build_one() {
  local arg="$1" dir
  # 相対(20_Skills/...)・絶対・末尾スラッシュを吸収
  dir="${arg%/}"; [[ "$dir" = /* ]] || dir="$ROOT/$dir"
  [[ -f "$dir/SKILL.md" ]] || { echo "ERROR: SKILL.md が無い（Skill本体ではない）: $arg" >&2; exit 2; }
  repackage_skill "$dir" && echo "built → ${dir#$ROOT/}.skill"
  validate_skill_file "$dir.skill" >/dev/null && echo "✅ 検証OK" || { echo "❌ 検証NG"; exit 1; }
}

build_all() {
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    local dir="${f%.skill}"
    [[ -f "$dir/SKILL.md" ]] && { repackage_skill "$dir" && echo "built → ${dir#$ROOT/}.skill"; }
  done < <(find "$ROOT/20_Skills" -type f -name '*.skill' 2>/dev/null | sort)
}

cmd="${1:-}"
case "$cmd" in
  --verify) verify ;;
  --all)    build_all; echo; verify ;;
  ""|-h|--help) echo "usage: bash _tools/build.sh <skillディレクトリ> | --all | --verify" >&2; exit 2 ;;
  *)        build_one "$cmd"; echo; verify ;;
esac
