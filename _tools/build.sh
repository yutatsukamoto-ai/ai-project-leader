#!/usr/bin/env bash
# Skillパッケージ化＋共通項同期の唯一の入口。手作業zipを禁じ、壊れビルド（0バイト・ルート不正・ゴミ残り）を構造的に防ぐ。
#   bash _tools/build.sh <skillディレクトリ>  … そのSkillを正しく再パッケージ＋検証＋全体verify
#   bash _tools/build.sh --all                … SKILL.mdを持つ全Skillをビルド＋検証
#   bash _tools/build.sh --verify             … 非破壊：全 .skill の健全性＋ゴミ＋ドリフトを点検（毎日の自動チェック用）
#   bash _tools/build.sh --sync               … 正典→コピーを反映し、影響する .skill を再パッケージ＋verify
#   bash _tools/build.sh --sync-cc            … 20_Skills/配下のSkill本体を .claude/skills/ へ同期
#   bash _tools/build.sh --check              … 正典↔コピーのズレだけ検査（非破壊。verify の一部）
#   bash _tools/build.sh --release-check      … 配布前ゲート：verify＋追跡禁止パス＋配布TODOを点検
#   bash _tools/build.sh --trace <案件フォルダ> … chain-trace.jsonを整形表示
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

  echo "=== 共通項のmanifest管理漏れ ==="
  check_manifest_coverage "$ROOT" "$MANIFEST" || problems=$((problems+1))

  echo "=== 成果物マップ↔実構成 ==="
  check_map_consistency "$ROOT" "$ROOT/20_Skills/成果物マップ.md" || problems=$((problems+1))

  echo "=== Claude Code Skill同期 ==="
  if [[ "${CI:-}" == "true" ]]; then
    echo "ℹ️  CI環境のためスキップ"
  else
    check_claude_code_skill_sync || problems=$((problems+1))
  fi

  echo "=== Git追跡禁止パス ==="
  check_forbidden_tracked_paths "$ROOT" || problems=$((problems+1))

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
  # list_skill_dirsベース: 既存.skillだけでなく未ビルドのSkillも拾う
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    repackage_skill "$d" && echo "built → ${d#$ROOT/}.skill"
  done < <(list_skill_dirs "$ROOT" | sort -u)
}

# 正典→コピーを反映し、影響する .skill を再パッケージ（旧 sync.sh sync）
do_sync() {
  [[ -f "$MANIFEST" ]] || { echo "ERROR: マニフェストが無い: $MANIFEST" >&2; exit 2; }
  local skilldirs_tmp
  skilldirs_tmp="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; exit 2; }
  local master copy
  while IFS=$'\t' read -r master copy _; do
    [[ -z "${master// }" || "${master:0:1}" == "#" ]] && continue
    local m="$ROOT/$master" c="$ROOT/$copy"
    [[ -f "$m" ]] || { echo "SKIP 正典なし: $master" >&2; continue; }
    mkdir -p "$(dirname "$c")"; cp "$m" "$c"; echo "copied → $copy"
    [[ "$copy" == 20_Skills/*/references/* ]] && echo "${copy%%/references/*}" >> "$skilldirs_tmp"
  done < "$MANIFEST"
  while IFS= read -r sd; do
    [[ -z "$sd" ]] && continue
    if [[ -f "$ROOT/$sd.skill" ]]; then
      repackage_skill "$ROOT/$sd" && echo "repackaged → $sd.skill"
    fi
  done < <(sort -u "$skilldirs_tmp")
  rm -f "$skilldirs_tmp"
  echo "--- sync 完了 ---"
}

sync_claude_code_skills() {
  local cc_skills="$ROOT/.claude/skills"
  rm -rf "$cc_skills"
  mkdir -p "$cc_skills"

  local count=0 name
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    name="$(basename "$d")"
    rsync -a --exclude='.DS_Store' "$d/" "$cc_skills/$name/"
    count=$((count+1))
  done < <(list_skill_dirs "$ROOT" | sort -u)

  echo "copied Claude Code skills: $count"
}

check_claude_code_skill_sync() {
  local cc_skills="$ROOT/.claude/skills"
  if [[ ! -d "$cc_skills" ]]; then
    echo "ℹ️  未同期（--sync-cc 未実行）"
    return 0
  fi

  local source_count cc_count
  source_count="$(list_skill_dirs "$ROOT" | wc -l | tr -d ' ')"
  cc_count="$(find "$cc_skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"

  if [[ "$source_count" == "$cc_count" ]]; then
    echo "✅ .claude/skills: ${cc_count}/${source_count} 件同期済み"
    return 0
  fi

  echo "❌ .claude/skills: ${cc_count}/${source_count} 件で不一致"
  echo "   bash _tools/build.sh --sync-cc を実行してください"
  return 1
}

release_check() {
  local problems=0
  verify || problems=$((problems+1))

  echo
  echo "=== 配布TODO ==="
  check_distribution_todos "$ROOT" || problems=$((problems+1))

  echo "================================"
  if [[ $problems -eq 0 ]]; then echo "✅ release-check: 配布前ゲートOK"; return 0
  else echo "⚠️  release-check: ${problems}種類の問題あり（上記）"; return 1; fi
}

cmd="${1:-}"
case "$cmd" in
  --verify) verify ;;
  --check)  [[ -f "$MANIFEST" ]] || { echo "ERROR: マニフェストが無い" >&2; exit 2; }
            check_drift "$ROOT" "$MANIFEST" && echo "✅ 全コピーが正典と一致" ;;
  --release-check) release_check ;;
  --sync)   do_sync; echo; verify ;;
  --sync-cc) sync_claude_code_skills ;;
  --all)    build_all; echo; verify ;;
  --trace)
    trace_arg="${2:-}"
    [[ -n "$trace_arg" ]] || { echo "usage: bash _tools/build.sh --trace <案件フォルダパス>" >&2; exit 2; }
    trace_dir="${trace_arg%/}"; [[ "$trace_dir" = /* ]] || trace_dir="$ROOT/$trace_dir"
    show_trace "$trace_dir"
    ;;
  ""|-h|--help)
    echo "usage: bash _tools/build.sh <skillディレクトリ> | --all | --verify | --sync | --sync-cc | --check | --release-check | --trace <案件フォルダ>" >&2
    exit 2 ;;
  *)        build_one "$cmd"; echo; verify ;;
esac
