#!/usr/bin/env bash
# 新規案件フォルダを規約どおりに初期化する小さな補助ツール。
# usage:
#   bash _tools/init-case.sh [--type 模擬案件|実案件|Skillテスト] [--date YYYY-MM-DD] [--dry-run] <案件名>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

case_type="模擬案件"
case_date="$(date +%F)"
dry_run=0

usage() {
  sed -n '2,5p' "$0" >&2
}

die() {
  echo "ERROR: $*" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      [[ $# -ge 2 ]] || die "--type の値がありません"
      case_type="$2"
      shift 2
      ;;
    --date)
      [[ $# -ge 2 ]] || die "--date の値がありません"
      case_date="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      die "不明なオプション: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 1 ]] || { usage; exit 2; }
case_name="$*"

case "$case_type" in
  模擬案件|実案件|Skillテスト) ;;
  *) die "--type は 模擬案件 / 実案件 / Skillテスト のいずれかにしてください: $case_type" ;;
esac

[[ "$case_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "--date は YYYY-MM-DD 形式にしてください: $case_date"

# パスとして危ない文字だけを潰す。日本語・英数字・空白は残し、空白は _ に寄せる。
safe_name="${case_name// /_}"
safe_name="${safe_name//\//_}"
safe_name="${safe_name//:/_}"
safe_name="${safe_name//\\/_}"
safe_name="$(printf '%s' "$safe_name" | sed 's/[[:cntrl:]]/_/g')"
[[ -n "$safe_name" ]] || die "案件名が空です"

day_dir="$ROOT/30_Flow/$case_date"
case_dir="$day_dir/${case_type}_${safe_name}"

if [[ -e "$case_dir" ]]; then
  die "既に存在します: ${case_dir#$ROOT/}"
fi

echo "案件フォルダ: ${case_dir#$ROOT/}"
echo "種別: $case_type"
echo "案件名: $case_name"
echo "開始日: $case_date"

if [[ "$dry_run" -eq 1 ]]; then
  echo "dry-run: 作成は行いません"
  exit 0
fi

mkdir -p "$case_dir"/{00_前段,01_立ち上げ,02_計画,03_実行,04_監視コントロール,05_終結,outputs}

cat > "$case_dir/project-context.md" <<EOF
# project-context（案件共有コンテキスト）

全Skillがこのファイルを読む。前提を毎回口頭で伝え直さないための一元管理。
更新ルール: 各工程で新事実が確定したら追記する（推測は書かない。推測は各成果物の中で管理）。

## 基本情報

- 案件名: $case_name
- クライアント:（社名・業種・規模）
- 相談者:（役職・意思決定者かどうか）
- 開始日: $case_date
- 案件種別: $case_type

## 制約条件（出どころ付き）

- 期間: ／ 出どころ: ①クライアント指定 ②未定 ③自社制約
- 予算: ／ 出どころ: 同上
- その他の絶対条件:（例: セキュリティ要件）

## 関係者

- 意思決定者:
- キーパーソン:
- その他:

## テーラリング判断ログ

- YYYY-MM-DD: （省略・保留・作成判断と、その理由・逆転条件を1行ずつ）

## 決定事項ログ

- YYYY-MM-DD: （承認・差し戻し・方針決定を1行ずつ）
EOF

cat > "$case_dir/_検査ログ.md" <<EOF
# 検査ログ

検査ゲートのレシート要約を追記する。客先提出物の本体には内部用レシートを混ぜない。

EOF

echo "created: ${case_dir#$ROOT/}"
