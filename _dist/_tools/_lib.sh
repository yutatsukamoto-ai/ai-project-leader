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

# 配布除外・履歴除外にすべきファイルがGit追跡下に残っていないかを検査する。
# .gitignoreは新規追加を止めるだけなので、既に追跡済みの実データ/著作物/生成物はここで検出する。
check_forbidden_tracked_paths() {
  local root="$1" problems=0 f
  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ℹ️  Git管理外のためスキップ"
    return 0
  fi

  local denied_dirs=(
    "30_Flow/YYYY-MM-DD/実案件_サンプル社"
    "30_Flow/YYYY-MM-DD/Skillテスト_サンプル"
    "_backups"
  )

  for dir in "${denied_dirs[@]}"; do
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      echo "❌ 追跡禁止パスがGit管理下: $f"
      problems=$((problems+1))
    done < <(git -C "$root" -c core.quotePath=false ls-files -- "$dir")
  done

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      "10_参考資料/PMBOK第8版_40プロセス一覧.md"|"10_参考資料/PMBOK第8版_6原則一覧.md") ;;
      *) echo "❌ 著作物側の追跡疑い: $f"; problems=$((problems+1)) ;;
    esac
  done < <(git -C "$root" -c core.quotePath=false ls-files -- "10_参考資料")

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    echo "❌ 再生成可能な.skillがGit管理下: $f"
    problems=$((problems+1))
  done < <(git -C "$root" -c core.quotePath=false ls-files -- "*.skill")

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    echo "❌ バックアップ/一時ファイルがGit管理下: $f"
    problems=$((problems+1))
  done < <(git -C "$root" -c core.quotePath=false ls-files -- "*.bak" ".DS_Store" ".DS_Store?")

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
check_distribution_todos() {
  local root="$1" hits
  hits="$(grep -RIn --include='*.md' '配布TODO' "$root/20_Skills" 2>/dev/null || true)"
  if [[ -z "$hits" ]]; then
    echo "✅ 配布TODOなし"
    return 0
  fi
  echo "$hits" | sed "s#$root/##" | sed 's/^/⚠️  /'
  echo "--- distribution TODO: $(printf '%s\n' "$hits" | grep -c .)件 ---"
  return 1
}
