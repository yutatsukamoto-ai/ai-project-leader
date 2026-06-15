#!/usr/bin/env bash
# 共有関数ライブラリ。sync.sh / build.sh から source して使う。単体実行しない。
# ツール間で同じ処理を二重実装しない（食い違い＝裏側バグの種）ための集約場所。

# md5（GNU coreutils=md5sum / macOS=md5 の両対応）
portable_md5() {
  if command -v md5sum >/dev/null 2>&1; then md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then md5 -q "$1"
  else echo "NO_MD5_TOOL" >&2; return 3; fi
}

# Skillソースdir（中にSKILL.md）から隣の <name>.skill を正しく作り直す。zipルート=<name>/。
repackage_skill() {
  local dir="$1" name parent
  [[ -d "$dir" ]] || { echo "ERROR: skillディレクトリが無い: $dir" >&2; return 1; }
  name="$(basename "$dir")"; parent="$(dirname "$dir")"
  ( cd "$parent" && rm -f "$name.skill" && zip -r -q -X "$name.skill" "$name" -x '*.DS_Store' )
}

# .skillファイルの健全性。0=健全、非0=問題（理由を出力）。0バイト・壊れzip・ルート不正・SKILL.md欠落を検出。
validate_skill_file() {
  local f="$1" name
  name="$(basename "$f" .skill)"
  [[ -s "$f" ]] || { echo "❌ 0バイト: $f"; return 1; }
  unzip -t "$f" >/dev/null 2>&1 || { echo "❌ 壊れたzip: $f"; return 1; }
  if unzip -Z1 "$f" 2>/dev/null | grep -qvE "^$name/"; then
    echo "❌ zipルートが $name/ でないエントリを含む: $f"; return 1; fi
  unzip -Z1 "$f" 2>/dev/null | grep -qx "$name/SKILL.md" || { echo "❌ SKILL.md欠落: $f"; return 1; }
  return 0
}

# 20_Skills配下でSKILL.mdを持つdir（=Skill本体）を列挙
list_skill_dirs() {
  find "$1/20_Skills" -type f -name SKILL.md 2>/dev/null | while read -r f; do dirname "$f"; done
}

# 20_Skills配下の「.skillでも既知の拡張子でもない正体不明ファイル」=ビルド事故ゴミを列挙
find_stray_archives() {
  find "$1/20_Skills" -type f \
    ! -name '*.skill' ! -name '*.md' ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' \
    ! -name '*.pdf' ! -name '*.txt' ! -name '*.json' ! -name '*.html' ! -name '*.yaml' ! -name '*.yml' \
    ! -name '.DS_Store' 2>/dev/null
}

# 正典→コピーのドリフト検査。$1=ROOT $2=manifest。0=全一致。
check_drift() {
  local root="$1" manifest="$2" drift=0 missing=0 n=0 master copy
  while IFS=$'\t' read -r master copy _; do
    [[ -z "${master// }" || "${master:0:1}" == "#" ]] && continue
    n=$((n+1))
    local m="$root/$master" c="$root/$copy"
    [[ -f "$m" ]] || { echo "❌ 正典が無い: $master"; missing=$((missing+1)); continue; }
    [[ -f "$c" ]] || { echo "❌ コピーが無い: $copy"; missing=$((missing+1)); continue; }
    [[ "$(portable_md5 "$m")" == "$(portable_md5 "$c")" ]] || { echo "⚠️  ズレ: $copy ←→ $master"; drift=$((drift+1)); }
  done < "$manifest"
  echo "--- drift: ${n}件中 ズレ${drift}・欠落${missing} ---"
  [[ $drift -eq 0 && $missing -eq 0 ]]
}

# 成果物マップ↔実構成の整合。$1=ROOT $2=成果物マップ.md。0=一致。
#   A: SKILL.mdを持つ実在Skillがマップに載っているか（新Skillの記載漏れ検出）
#   B: マップに載るSkill名らしき記載が実在するか（消えた/改名Skillの残骸検出）
# 成果物マップが「実構成からの自動生成候補」だと自称している以上、実態とのズレは構造の嘘になる。ここで常設点検する。
check_map_consistency() {
  local root="$1" map="$2" miss=0 stale=0 total=0
  [[ -f "$map" ]] || { echo "❌ 成果物マップが無い: $map"; return 1; }
  local actual; actual="$(list_skill_dirs "$root" | while read -r d; do basename "$d"; done | sort -u)"
  total="$(grep -c . <<< "$actual" || true)"
  # A: 実在するのにマップ未記載
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    grep -qF -- "$name" "$map" || { echo "❌ 実在Skillがマップ未記載: $name"; miss=$((miss+1)); }
  done <<< "$actual"
  # B: マップのSkill名らしきtoken（バッククォート内・小文字英数＋ハイフン/下線・ドット/スラッシュ無し）が実在しない
  local cand; cand="$(grep -oE '`[a-z_][a-z0-9_-]*-[a-z0-9_-]+`' "$map" | tr -d '`' | sort -u || true)"
  while IFS= read -r tok; do
    [[ -z "$tok" ]] && continue
    grep -qxF -- "$tok" <<< "$actual" || { echo "⚠️  マップ記載だが実在Skillに無い: $tok"; stale=$((stale+1)); }
  done <<< "$cand"
  echo "--- map: 実在${total}件中 未記載${miss}・要確認${stale} ---"
  [[ $miss -eq 0 && $stale -eq 0 ]]
}
