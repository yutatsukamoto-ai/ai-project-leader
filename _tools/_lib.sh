#!/usr/bin/env bash
# 共有関数ライブラリ。build.sh から source して使う（sync.sh は build.sh への薄いラッパー）。単体実行しない。
# ツール間で同じ処理を二重実装しない（食い違い＝裏側バグの種）ための集約場所。

# md5（GNU coreutils=md5sum / macOS=md5 の両対応）
portable_md5() {
  if command -v md5sum >/dev/null 2>&1; then md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then md5 -q "$1"
  else echo "NO_MD5_TOOL" >&2; return 3; fi
}

# Skillソースdir（中にSKILL.md）から隣の <name>.skill を正しく作り直す。zipルート=<name>/。
repackage_skill() {
  local dir="$1" name parent tmpd rc=0
  [[ -d "$dir" ]] || { echo "ERROR: skillディレクトリが無い: $dir" >&2; return 1; }
  name="$(basename "$dir")"; parent="$(dirname "$dir")"
  # マウント上では zip の原子的 rename(temp→本名) が拒否され、新規ビルドが失敗し中途半端な temp が残る。
  # そこで zip は一時領域で組み立て、cp で配置する（cp の上書きはマウント上でも通ることを実証済）。
  tmpd="$(mktemp -d)" || { echo "ERROR: 一時領域を作れない" >&2; return 1; }
  ( cd "$parent" && zip -r -q -X "$tmpd/$name.skill" "$name" -x '*.DS_Store' ) || rc=1
  [[ $rc -eq 0 ]] && { cp -f "$tmpd/$name.skill" "$parent/$name.skill" || rc=1; }
  rm -rf "$tmpd"
  return $rc
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
    ! -name '*.py' \
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

# manifest左辺にある正典ファイルと同名のreferencesコピーが、manifest右辺に登録されているか検査する。
# 0=全コピーが管理下。manifest未登録コピーは --check の対象外になるため、verifyでここを塞ぐ。
check_manifest_coverage() {
  local root="$1" manifest="$2" problems=0 checked=0
  local rhs_tmp names_tmp
  rhs_tmp="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  names_tmp="$(mktemp)" || { rm -f "$rhs_tmp"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }

  local lhs_tmp
  lhs_tmp="$(mktemp)" || { rm -f "$rhs_tmp" "$names_tmp"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  awk -F '\t' 'NF >= 2 && $1 !~ /^#/ && $1 != "" {print $2}' "$manifest" | sort -u > "$rhs_tmp"
  awk -F '\t' 'NF >= 2 && $1 !~ /^#/ && $1 != "" {print $1}' "$manifest" | sort -u > "$lhs_tmp"
  awk -F '\t' 'NF >= 2 && $1 !~ /^#/ && $1 != "" {n=$1; sub(/^.*\//, "", n); print n}' "$manifest" | sort -u > "$names_tmp"

  local name f rel
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      checked=$((checked+1))
      rel="${f#$root/}"
      # RHS（コピー先）またはLHS（正典側）に登録されていればOK
      if ! grep -qxF "$rel" "$rhs_tmp" && ! grep -qxF "$rel" "$lhs_tmp"; then
        echo "❌ manifest未登録コピー: $rel"
        problems=$((problems+1))
      fi
    done < <(find "$root/20_Skills" -path '*/references/*' -type f -name "$name" 2>/dev/null | sort)
  done < "$names_tmp"

  rm -f "$lhs_tmp"

  rm -f "$rhs_tmp" "$names_tmp"
  echo "--- manifest coverage: ${checked}件中 未登録${problems} ---"
  [[ $problems -eq 0 ]]
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

# 横断GL・テンプレート・骨子に、実在しないSkill名らしき参照が残っていないかを検査する。
# 成果物マップは未実装候補も書くため対象外。
check_skill_name_ghosts() {
  local root="$1" problems=0 checked=0
  local actual_tmp allowlist
  actual_tmp="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  allowlist="$root/_tools/skill-name-allowlist.txt"

  list_skill_dirs "$root" | while read -r d; do basename "$d"; done | sort -u > "$actual_tmp"

  local targets_tmp
  targets_tmp="$(mktemp)" || { rm -f "$actual_tmp"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  {
    find "$root/40_Stock/横断ガイドライン" -maxdepth 1 -type f -name '*.md' 2>/dev/null
    find "$root/40_Stock/テンプレート" -maxdepth 1 -type f -name '*.md' 2>/dev/null
    [[ -f "$root/プロジェクト骨子.md" ]] && echo "$root/プロジェクト骨子.md"
  } | sort -u > "$targets_tmp"

  local file token rel has_partial
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    while IFS= read -r token; do
      [[ -z "$token" ]] && continue
      checked=$((checked+1))

      # 実在Skill名そのものならOK
      if grep -qxF "$token" "$actual_tmp"; then
        continue
      fi

      # image2-brand-slides から brand-slides だけ拾う等の部分一致は誤検知として除外
      has_partial=0
      while IFS= read -r skill; do
        [[ -z "$skill" ]] && continue
        if [[ "$skill" == *"$token"* || "$token" == *"$skill"* ]]; then
          has_partial=1
          break
        fi
      done < "$actual_tmp"
      [[ $has_partial -eq 1 ]] && continue

      # project-context 等、Skill名ではない既知のハイフン語
      if [[ -f "$allowlist" ]] && grep -qxF "$token" "$allowlist"; then
        continue
      fi

      rel="${file#$root/}"
      echo "❌ 幽霊Skill名参照: $rel: $token"
      problems=$((problems+1))
    done < <(grep -Eoh '[a-z]+-[a-z-]+' "$file" 2>/dev/null | sed 's/^-*//; s/-*$//' | sort -u)
  done < "$targets_tmp"

  rm -f "$actual_tmp" "$targets_tmp"
  if [[ $problems -eq 0 ]]; then
    echo "✅ なし（候補${checked}件を確認）"
    return 0
  fi
  echo "--- ghost skill refs: ${problems}件 ---"
  return 1
}

normalize_selection_label() {
  printf '%s' "$1" \
    | sed 's/`//g; s/<[^>]*>//g; s/（[^）]*）//g; s/([^)]*)//g; s/[[:space:]　]//g; s/リソース/資源/g'
}

# 成果物マップにある成果物Skillが、成果物選定ガイドのランク表から漏れていないかを検査する。
# chainや未整備候補ではなく、成果物単位の選定ガイドとの整合だけを見る。
check_selection_guide_coverage() {
  local root="$1" problems=0
  local map="$root/20_Skills/成果物マップ.md"
  local guide="$root/40_Stock/横断ガイドライン/成果物選定ガイド.md"
  local allowlist="$root/_tools/selection-guide-allowlist.txt"
  [[ -f "$map" ]] || { echo "❌ 成果物マップが無い: $map"; return 1; }
  [[ -f "$guide" ]] || { echo "❌ 成果物選定ガイドが無い: $guide"; return 1; }

  local map_targets guide_tokens guide_labels all_map_tokens
  map_targets="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  guide_tokens="$(mktemp)" || { rm -f "$map_targets"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  guide_labels="$(mktemp)" || { rm -f "$map_targets" "$guide_tokens"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  all_map_tokens="$(mktemp)" || { rm -f "$map_targets" "$guide_tokens" "$guide_labels"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }

  grep -oE '`[a-z_][a-z0-9_-]*-[a-z0-9_-]+`|[a-z]+-[a-z-]+' "$map" \
    | tr -d '`' | sort -u > "$all_map_tokens"

  local in_scope=0 line first artifact skill norm cell
  while IFS= read -r line; do
    case "$line" in
      "## 本体"*|"## 前段"*) in_scope=1; continue ;;
      "## フェーズ×"*|"## オーケストレーター"*|"## 横断・メタ"*) in_scope=0 ;;
    esac
    [[ $in_scope -eq 1 ]] || continue
    [[ "$line" == \|* ]] || continue
    skill="$(printf '%s\n' "$line" | grep -oE '`[a-z_][a-z0-9_-]*-[a-z0-9_-]+`' | head -n 1 | tr -d '`' || true)"
    [[ -n "$skill" && "$skill" != *-chain ]] || continue
    first="$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[ \t　]+|[ \t　]+$/, "", $2); print $2}')"
    [[ "$first" =~ ^(0-[0-9]|0[1-5]|[0-5][[:space:]]) ]] || continue
    artifact="$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[ \t　]+|[ \t　]+$/, "", $3); print $3}')"
    norm="$(normalize_selection_label "$artifact")"
    printf '%s\t%s\t%s\n' "$skill" "$artifact" "$norm" >> "$map_targets"
  done < "$map"

  awk '/^## A\./ {in_a=1; next} /^## B\./ {in_a=0} in_a {print}' "$guide" \
    | grep -oE '`[a-z_][a-z0-9_-]*-[a-z0-9_-]+`|[a-z]+-[a-z-]+' \
    | tr -d '`' | sort -u > "$guide_tokens" || true

  while IFS= read -r line; do
    [[ "$line" == \|* ]] || continue
    printf '%s\n' "$line" | tr '|' '\n' | while IFS= read -r cell; do
      cell="$(printf '%s' "$cell" | sed 's/^[ \t　]*//; s/[ \t　]*$//')"
      [[ -z "$cell" || "$cell" == "---" || "$cell" == "フェーズ" || "$cell" == "成果物" || "$cell" == "ランク" || "$cell" == "根拠" || "$cell" == "Skill" || "$cell" == "着手トリガー（逆転条件）" ]] && continue
      normalize_selection_label "$cell"
      printf '\n'
    done
  done < <(awk '/^## A\./ {in_a=1; next} /^## B\./ {in_a=0} in_a {print}' "$guide") | sort -u > "$guide_labels"

  local missing=0 orphan=0 checked=0 label
  while IFS=$'\t' read -r skill artifact norm; do
    [[ -z "$skill" ]] && continue
    checked=$((checked+1))
    if grep -qxF "$skill" "$guide_tokens" || grep -qxF "$norm" "$guide_labels"; then
      continue
    fi
    if [[ -f "$allowlist" ]] && grep -qxF "$skill" "$allowlist"; then
      continue
    fi
    echo "❌ 選定ガイド未収録: $skill"
    missing=$((missing+1))
  done < "$map_targets"

  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    if grep -qxF "$skill" "$all_map_tokens"; then
      continue
    fi
    if [[ -f "$allowlist" ]] && grep -qxF "$skill" "$allowlist"; then
      continue
    fi
    echo "❌ 成果物マップに不在: $skill"
    orphan=$((orphan+1))
  done < "$guide_tokens"

  rm -f "$map_targets" "$guide_tokens" "$guide_labels" "$all_map_tokens"
  problems=$((missing+orphan))
  if [[ $problems -eq 0 ]]; then
    echo "✅ 整合（対象${checked}件）"
    return 0
  fi
  echo "--- selection guide: 未収録${missing}・孤児${orphan} ---"
  return 1
}

# 横断ガイドライン配下のMarkdownとREADME索引表の整合を検査する。
check_gl_readme_index() {
  local root="$1" problems=0
  local dir="$root/40_Stock/横断ガイドライン"
  local readme="$dir/README.md"
  [[ -d "$dir" ]] || { echo "❌ 横断GLディレクトリが無い: $dir"; return 1; }
  [[ -f "$readme" ]] || { echo "❌ 横断GL READMEが無い: $readme"; return 1; }

  local actual indexed
  actual="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  indexed="$(mktemp)" || { rm -f "$actual"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }

  find "$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -exec basename {} \; | sort -u > "$actual"
  awk '
    /^## 収録ガイドライン/ {in_section=1; next}
    in_section && /^\|/ {in_table=1; print; next}
    in_table && !/^\|/ {in_table=0; in_section=0}
  ' "$readme" \
    | grep -oE '`[^`]+\.md`' | tr -d '`' | xargs -n1 basename 2>/dev/null | sort -u > "$indexed" || true

  local f missing=0 ghost=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qxF "$f" "$indexed"; then
      echo "❌ 横断GL README索引漏れ: $f"
      missing=$((missing+1))
    fi
  done < "$actual"

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qxF "$f" "$actual"; then
      echo "❌ 横断GL 幽霊索引: $f"
      ghost=$((ghost+1))
    fi
  done < "$indexed"

  rm -f "$actual" "$indexed"
  problems=$((missing+ghost))
  if [[ $problems -eq 0 ]]; then
    echo "✅ 整合"
    return 0
  fi
  echo "--- gl readme index: 漏れ${missing}・幽霊${ghost} ---"
  return 1
}

check_golden_count_mentions() {
  local root="$1" problems=0 checked=0 count manifest file rel hit line_no text mentions num
  manifest="$root/_tools/eval/goldens.tsv"
  [[ -f "$manifest" ]] || { echo "❌ goldens.tsv が無い: $manifest"; return 1; }

  count="$(awk 'BEGIN{c=0} /^[[:space:]]*#/ || /^[[:space:]]*$/ {next} {c++} END{print c}' "$manifest")"
  for file in "$root/README.md" "$root/プロジェクト骨子.md" "$root/_tools/eval/README.md"; do
    [[ -f "$file" ]] || continue
    rel="${file#$root/}"
    while IFS= read -r hit; do
      [[ -z "$hit" ]] && continue
      line_no="${hit%%:*}"
      text="${hit#*:}"
      mentions="$(printf '%s\n' "$text" | grep -Eo '([0-9]+)件のゴールデン|ゴールデン[0-9]+件|計[0-9]+件' || true)"
      while IFS= read -r num; do
        [[ -z "$num" ]] && continue
        checked=$((checked+1))
        if [[ "$num" != "$count" ]]; then
          echo "❌ ゴールデン件数の表記ズレ: ${rel}:${line_no}: ${num}件（実数${count}件）"
          problems=$((problems+1))
        fi
      done < <(printf '%s\n' "$mentions" | grep -Eo '[0-9]+' || true)
    done < <(grep -nE '([0-9]+)件のゴールデン|ゴールデン[0-9]+件|ゴールデン.*計[0-9]+件' "$file" 2>/dev/null || true)
  done

  if [[ $problems -eq 0 ]]; then
    echo "✅ ゴールデン件数表記: ${checked}箇所が実数${count}件と一致"
    return 0
  fi
  echo "--- golden count mentions: ${problems}件 ---"
  return 1
}

check_gl_key_table_index() {
  local root="$1" problems=0
  local dir="$root/40_Stock/横断ガイドライン"
  local table="$root/20_Skills/横断GL対応表.md"
  [[ -d "$dir" ]] || { echo "❌ 横断GLディレクトリが無い: $dir"; return 1; }
  [[ -f "$table" ]] || { echo "❌ 横断GL対応表が無い: $table"; return 1; }

  local actual indexed f missing=0 ghost=0
  actual="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
  indexed="$(mktemp)" || { rm -f "$actual"; echo "ERROR: 一時ファイルを作れない" >&2; return 2; }

  find "$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -exec basename {} \; | sort -u > "$actual"
  awk '
    /^## 横断GLキー/ {in_section=1; next}
    in_section && /^---/ {exit}
    in_section {print}
  ' "$table" \
    | grep -oE '`40_Stock/横断ガイドライン/[^`]+\.md`' \
    | tr -d '`' | xargs -n1 basename 2>/dev/null | sort -u > "$indexed" || true

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qxF "$f" "$indexed"; then
      echo "❌ 横断GLキー表の索引漏れ: $f"
      missing=$((missing+1))
    fi
  done < "$actual"

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qxF "$f" "$actual"; then
      echo "❌ 横断GLキー表の幽霊索引: $f"
      ghost=$((ghost+1))
    fi
  done < "$indexed"

  rm -f "$actual" "$indexed"
  problems=$((missing+ghost))
  if [[ $problems -eq 0 ]]; then
    echo "✅ 横断GLキー表: 整合"
    return 0
  fi
  echo "--- gl key table: 漏れ${missing}・幽霊${ghost} ---"
  return 1
}

check_deprecated_project_status_refs() {
  local root="$1" hits
  hits="$(grep -RIn --include='*.md' '00_案件ステータス\.md' \
    "$root/AGENTS.md" "$root/CLAUDE.md" "$root/CODEX.md" "$root/README.md" "$root/30_Flow/README.md" 2>/dev/null || true)"
  if [[ -z "$hits" ]]; then
    echo "✅ 旧案件ステータス入口参照なし"
    return 0
  fi
  echo "$hits" | sed "s#$root/##" | sed 's/^/❌ /'
  echo "--- deprecated project status refs: $(printf '%s\n' "$hits" | grep -c .)件 ---"
  return 1
}

check_entry_doc_freshness() {
  local root="$1" problems=0
  check_golden_count_mentions "$root" || problems=$((problems+1))
  check_gl_key_table_index "$root" || problems=$((problems+1))
  check_deprecated_project_status_refs "$root" || problems=$((problems+1))
  [[ $problems -eq 0 ]]
}

# chain-trace規約が、実運用で読むchain/成果物Skillへ波及しているかを検査する。
# 横断・メタの支援Skillは案件チェーン実行ログの対象外。ただし成果物Skillの雛形は対象に含める。
check_chain_trace_propagation() {
  local root="$1" problems=0 checked=0
  local f rel
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    checked=$((checked+1))
    if grep -q 'chain-trace\.json' "$f"; then
      continue
    fi
    rel="${f#$root/}"
    echo "❌ chain-trace未反映: $rel"
    problems=$((problems+1))
  done < <(
    {
      find "$root/20_Skills/00_前段" "$root/20_Skills/01_立ち上げ" "$root/20_Skills/02_計画" "$root/20_Skills/03_実行" "$root/20_Skills/04_監視コントロール" "$root/20_Skills/05_終結" -mindepth 2 -maxdepth 2 -type f -name SKILL.md 2>/dev/null
      [[ -f "$root/20_Skills/99_メタ/_seikabutsu-template/SKILL.md" ]] && echo "$root/20_Skills/99_メタ/_seikabutsu-template/SKILL.md"
    } | sort -u
  )

  if [[ $problems -eq 0 ]]; then
    echo "✅ 反映済み（対象${checked}件）"
    return 0
  fi
  echo "--- chain-trace propagation: ${problems}件 ---"
  return 1
}

# 配布除外・履歴除外にすべきファイルがGit追跡下に残っていないかを検査する。
# .gitignoreは新規追加を止めるだけなので、既に追跡済みの実データ/著作物/生成物はここで検出する。
check_forbidden_tracked_paths() {
  local root="$1" problems=0 f
  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ℹ️  Git管理外のためスキップ"
    return 0
  fi

  report_tracked_matches() {
    local label="$1"
    shift
    local tmp count
    tmp="$(mktemp)" || { echo "ERROR: 一時ファイルを作れない" >&2; return 2; }
    git -C "$root" -c core.quotePath=false ls-files -- "$@" > "$tmp"
    count="$(grep -c . "$tmp" || true)"
    if [[ "$count" -gt 0 ]]; then
      echo "❌ ${label}: ${count}件"
      sed -n '1,20p' "$tmp" | sed 's/^/   - /'
      if [[ "$count" -gt 20 ]]; then
        echo "   ... and $((count - 20)) more"
      fi
      problems=$((problems+count))
    fi
    rm -f "$tmp"
  }

  local denied_paths=(
    "30_Flow/2026-06-12"
    "30_Flow/実案件"
    "30_Flow/現在の作業セッション.md"
    "_backups"
    "_dist"
    "tmp"
  )

  for f in "${denied_paths[@]}"; do
    report_tracked_matches "追跡禁止パスがGit管理下 ($f)" "$f"
  done

  report_tracked_matches "Flow配下の生成exportがGit管理下" ":(glob)30_Flow/**/export/**"
  report_tracked_matches "Flow配下の最終レンダー画像がGit管理下" ":(glob)30_Flow/**/final-slides/**"
  report_tracked_matches "Flow配下の_generatedがGit管理下" ":(glob)30_Flow/**/_generated/**"
  report_tracked_matches "Flow配下の_rendersがGit管理下" ":(glob)30_Flow/**/_renders/**"
  report_tracked_matches "Flow配下の一時レンダー/スクリーンショットがGit管理下" ":(glob)30_Flow/**/_render/**" ":(glob)30_Flow/**/_quicklook/**" ":(glob)30_Flow/**/screenshots/**"
  report_tracked_matches "Flow配下の生成バイナリがGit管理下" \
    ":(glob)30_Flow/**/*.docx" \
    ":(glob)30_Flow/**/*.xlsx" \
    ":(glob)30_Flow/**/*.pptx" \
    ":(glob)30_Flow/**/*.png" \
    ":(glob)30_Flow/**/*.jpg" \
    ":(glob)30_Flow/**/*.jpeg" \
    ":(glob)30_Flow/**/*.pdf" \
    ":(glob)30_Flow/**/*.html"

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      "10_参考資料/PMBOK第8版_40プロセス一覧.md"|"10_参考資料/PMBOK第8版_6原則一覧.md") ;;
      *) echo "❌ 著作物側の追跡疑い: $f"; problems=$((problems+1)) ;;
    esac
  done < <(git -C "$root" -c core.quotePath=false ls-files -- "10_参考資料")

  report_tracked_matches "再生成可能な.skillがGit管理下" "*.skill"
  report_tracked_matches "バックアップ/一時ファイルがGit管理下" "*.bak" ".DS_Store" ".DS_Store?"

  if [[ $problems -eq 0 ]]; then
    echo "✅ 追跡禁止パスなし"
    return 0
  fi
  echo "--- forbidden tracked: ${problems}件 ---"
  return 1
}

# chain-trace.jsonの整形表示。$1=案件フォルダ（絶対パス）。
show_trace() {
  local dir="$1" trace="$1/chain-trace.json"
  [[ -f "$trace" ]] || { echo "ERROR: chain-trace.json が無い: $dir" >&2; return 2; }

  # jqが無ければpython3のjsonで代替
  python3 - "$trace" <<'PYEOF'
import json, sys, re

with open(sys.argv[1], encoding='utf-8') as f:
    d = json.load(f)

name = d.get("案件", "不明")
phase = d.get("現在フェーズ", "不明")
entries = d.get("entries", [])
start = d.get("開始日", "不明")

print(f"=== チェーントレース: {name} ===")
print(f"現在フェーズ: {phase}  |  エントリ: {len(entries)}件  |  開始: {start}")
print()

# ヘッダ
print(f" {'#':<4} {'Skill':<28} {'Phase':<20} {'検査':<14} {'時間':<6} 備考")
print(f" {'---':<4} {'----------------------------':<28} {'--------------------':<20} {'--------------':<14} {'------':<6} ---")

for e in entries:
    sk = e.get("skill", "")
    if sk == "phase-transition":
        out = e.get("output", "")
        print(f" {'-':<4} [{out}]")
    else:
        seq = str(e.get("seq", ""))
        ph = e.get("phase", "")
        ins = e.get("inspection", "")
        dur = f'{e["duration_min"]}m' if e.get("duration_min") else "—"
        note = e.get("notes", "") or e.get("inspection_notes", "")
        print(f" {seq:<4} {sk:<28} {ph:<20} {ins:<14} {dur:<6} {note}")

print()
print("=== 集計 ===")

ok = warn = ng = tail = 0
tailoring_items = []
for e in entries:
    if e.get("skill") in ("phase-transition", "approval-gate"):
        continue
    ins = e.get("inspection", "")
    for m in re.finditer(r"✅(\d+)", ins):
        ok += int(m.group(1))
    for m in re.finditer(r"🟡(\d+)", ins):
        warn += int(m.group(1))
    for m in re.finditer(r"❌(\d+)", ins):
        ng += int(m.group(1))
    for t in (e.get("tailoring") or []):
        tailoring_items.append(t)
        tail += 1

print(f"検査: ✅{ok} 🟡{warn} ❌{ng}")
print(f"テーラリング判断: {tail}件")
for t in tailoring_items:
    print(f"  - {t}")
PYEOF
}

# 配布前に解消すべきTODOを一覧化する。現時点ではSkill内の配布TODOを対象にする。
# _seikabutsu-template は配布対象外のコピー元なので、意図的プレースホルダーとして除外する。
check_distribution_todos() {
  local root="$1" hits
  hits="$(grep -RIn --include='*.md' '配布TODO' "$root/20_Skills" 2>/dev/null | grep -v '/99_メタ/_seikabutsu-template/' || true)"
  if [[ -z "$hits" ]]; then
    echo "✅ 配布TODOなし"
    return 0
  fi
  echo "$hits" | sed "s#$root/##" | sed 's/^/⚠️  /'
  echo "--- distribution TODO: $(printf '%s\n' "$hits" | grep -c .)件 ---"
  return 1
}
