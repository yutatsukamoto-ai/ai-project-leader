#!/usr/bin/env bash
# package-dist.sh — L1配布フォルダを生成する。
#
# 使い方:
#   bash _tools/package-dist.sh              … _dist/ に配布フォルダを生成
#   bash _tools/package-dist.sh --dry-run    … 何をコピーするか表示（実行しない）
#   bash _tools/package-dist.sh --target claude-code
#   bash _tools/package-dist.sh --target codex
#
# 3層モデル準拠:
#   L1（配布）= 20_Skills + 40_Stock + 10_参考資料のPMBOK再構成 + _tools + README等
#   L2（雛形）= 骨格フォルダ + 空テンプレ
#   除外 = 30_Flow(案件データ) + 00_管理(建設ログ) + 10_参考資料の著作物 + _backups + 50_サンプル
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Coworkマウントはrm/deleteを拒否するため、/tmpで組み立ててからrsyncでコピーする。
STAGING="$(mktemp -d)"
DIST="$ROOT/_dist"
DRY=""
TARGET="cowork"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY="--dry-run"
      shift
      ;;
    --target)
      TARGET="${2:-}"
      [[ "$TARGET" == "cowork" || "$TARGET" == "claude-code" || "$TARGET" == "codex" ]] || {
        echo "ERROR: --target は cowork / claude-code / codex のいずれかを指定してください" >&2
        exit 2
      }
      shift 2
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      exit 2
      ;;
  esac
done

trap 'rm -rf "$STAGING"' EXIT

log() { echo "  $1"; }

if [[ "$DRY" == "--dry-run" ]]; then
  echo "=== package-dist: ドライラン（コピーしない）==="
  echo "target: $TARGET"
  echo ""
fi

# --- L1: Skills（.skillを除く。受け手がbuild.shで再生成する） ---
log "L1: 20_Skills/ （ソースのみ、.skill除外）"
if [[ "$DRY" != "--dry-run" ]]; then
  rsync -a --exclude='.DS_Store' --exclude='*.skill' "$ROOT/20_Skills/" "$STAGING/20_Skills/"
fi

# --- L2: 横断ガイドライン・カード・テンプレート・ナレッジ・案件教訓 ---
log "L2: 40_Stock/"
if [[ "$DRY" != "--dry-run" ]]; then
  rsync -a --exclude='.DS_Store' "$ROOT/40_Stock/" "$STAGING/40_Stock/"
fi

# --- L2: PMBOK再構成テキスト（著作物ではない） ---
log "L2: 10_参考資料/PMBOK再構成テキスト（2ファイルのみ）"
if [[ "$DRY" != "--dry-run" ]]; then
  mkdir -p "$STAGING/10_参考資料"
  cp "$ROOT/10_参考資料/PMBOK第8版_40プロセス一覧.md" "$STAGING/10_参考資料/"
  cp "$ROOT/10_参考資料/PMBOK第8版_6原則一覧.md" "$STAGING/10_参考資料/"
fi

# --- ツール ---
log "L1: _tools/ （eval結果・バックアップ除外）"
if [[ "$DRY" != "--dry-run" ]]; then
  mkdir -p "$STAGING/_tools/eval"
  cp "$ROOT/_tools/build.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/_lib.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/eval.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/eval-judge.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/eval-judge-summary.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/package-dist.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/sync.sh" "$STAGING/_tools/"
  cp "$ROOT/_tools/sync-manifest.tsv" "$STAGING/_tools/"
  cp "$ROOT/_tools/test-dist-codex.sh" "$STAGING/_tools/"
  # eval定義（ゴールデンは案件データなので除外、定義とチェックリストのみ）
  cp "$ROOT/_tools/eval/合格チェックリスト.md" "$STAGING/_tools/eval/"
  cp "$ROOT/_tools/eval/judge-prompt.md" "$STAGING/_tools/eval/"
  # goldens.tsvはパス参照が30_Flowを向いているので配布版では空テンプレにする
  cat > "$STAGING/_tools/eval/goldens.tsv" <<'TSV'
# 回帰eval ゴールデン定義（M-04）
# 1行 = <skill>	<case>	<goldenパス（ルート相対）>	<必須トークン（||区切り）>
# 自分の案件を回したら、出力ファイルのパスと核トークンを追記する。
# eval.sh がこのファイルを読んで回帰テストを実行する。
TSV
  chmod +x "$STAGING/_tools/build.sh" "$STAGING/_tools/eval.sh" "$STAGING/_tools/eval-judge.sh" "$STAGING/_tools/eval-judge-summary.sh" "$STAGING/_tools/package-dist.sh" "$STAGING/_tools/sync.sh" "$STAGING/_tools/test-dist-codex.sh"
fi

# --- 雛形フォルダ（空） ---
log "L2: 空フォルダ骨格（00_管理・30_Flow・50_サンプル）"
if [[ "$DRY" != "--dry-run" ]]; then
  mkdir -p "$STAGING/00_プロジェクト管理"
  mkdir -p "$STAGING/30_Flow"
  mkdir -p "$STAGING/50_サンプル成果物/docx"
  mkdir -p "$STAGING/50_サンプル成果物/pptx"
  mkdir -p "$STAGING/50_サンプル成果物/xlsx"
  # 各空フォルダにREADMEを置く
  cat > "$STAGING/00_プロジェクト管理/README.md" <<'EOF'
# プロジェクト管理（建設ログ）

このフォルダにはプロジェクト固有の管理メモが入る。懸念マスター・構造レビュー・棚卸し等。
EOF
  cat > "$STAGING/30_Flow/README.md" <<'EOF'
# 案件フォルダ（Flow）

案件ごとにサブフォルダを作り、フェーズ別に成果物を格納する。
例: `30_Flow/2026-XX-XX/案件名/00_前段/01_案件理解サマリー_v0.1.md`
EOF
  cat > "$STAGING/50_サンプル成果物/README.md" <<'EOF'
# サンプル成果物

Skillが生成した成果物のサンプル。docx/pptx/xlsx形式別に格納。
EOF
fi

# --- Artifacts（Cowork UI） ---
log "L1: _tools/artifacts/ （案件キックオフ・ダッシュボードテンプレ）"
if [[ "$DRY" != "--dry-run" ]]; then
  mkdir -p "$STAGING/_tools/artifacts"
  cp "$ROOT/_tools/artifacts/case-kickoff.html" "$STAGING/_tools/artifacts/"
  # ダッシュボードは案件データを含むため、空テンプレ版を配布
  cp "$ROOT/_tools/artifacts/project-dashboard-template.html" "$STAGING/_tools/artifacts/"
  cp "$ROOT/_tools/artifacts/project-dashboard-template.html" "$STAGING/_tools/artifacts/project-dashboard.html"
fi

# --- ルートファイル ---
log "ルート: README.md・.gitignore・プロジェクト骨子.md"
if [[ "$DRY" != "--dry-run" ]]; then
  cp "$ROOT/README.md" "$STAGING/"
  cp "$ROOT/.gitignore" "$STAGING/"
  cp "$ROOT/プロジェクト骨子.md" "$STAGING/プロジェクト骨子.md"
fi

if [[ "$TARGET" == "claude-code" ]]; then
  log "Claude Code: .claude/・CLAUDE.md"
  if [[ "$DRY" != "--dry-run" ]]; then
    [[ -f "$ROOT/CLAUDE.md" ]] || { echo "ERROR: CLAUDE.md がありません" >&2; exit 2; }
    [[ -d "$ROOT/.claude" ]] || { echo "ERROR: .claude/ がありません" >&2; exit 2; }
    cp "$ROOT/CLAUDE.md" "$STAGING/"
    rsync -a --exclude='.DS_Store' "$ROOT/.claude/" "$STAGING/.claude/"
  fi
fi

if [[ "$TARGET" == "codex" ]]; then
  log "Codex: AGENTS.md・CODEX.md"
  if [[ "$DRY" != "--dry-run" ]]; then
    [[ -f "$ROOT/AGENTS.md" ]] || { echo "ERROR: AGENTS.md がありません" >&2; exit 2; }
    [[ -f "$ROOT/CODEX.md" ]] || { echo "ERROR: CODEX.md がありません" >&2; exit 2; }
    cp "$ROOT/AGENTS.md" "$STAGING/"
    cp "$ROOT/CODEX.md" "$STAGING/"
  fi
fi

# --- macOSメタデータ除外 ---
log "除外: .DS_Store"
if [[ "$DRY" != "--dry-run" ]]; then
  find "$STAGING" -name '.DS_Store' -type f -delete
fi

# --- 除外確認 ---
echo ""
echo "=== 除外確認 ==="
log "✕ 00_プロジェクト管理/（建設ログ）→ 空フォルダ+READMEに置換"
log "✕ 10_参考資料/著作物（PDF・書籍スクショ等56点）"
log "✕ 10_参考資料/Coworkオンボーディング/"
log "✕ 30_Flow/（全案件データ）→ 空フォルダ+READMEに置換"
log "✕ 50_サンプル成果物/（案件固有出力）→ 空フォルダ+READMEに置換"
log "✕ _backups/"
log "✕ *.skill（build.shで再生成可）"
log "✕ _tools/eval/judge-results/（判定結果はインスタンスデータ）"
log "✕ _tools/eval/goldens.tsv（パスが案件データを参照→空テンプレに置換）"
if [[ "$TARGET" != "codex" ]]; then
  log "✕ AGENTS.md, CODEX.md（Codex用・$TARGET 配布には不要）"
fi
if [[ "$TARGET" != "claude-code" ]]; then
  log "✕ CLAUDE.md, .claude/（Claude Code用・$TARGET 配布には不要）"
fi

if [[ "$DRY" == "--dry-run" ]]; then
  echo ""
  if [[ "$TARGET" == "cowork" ]]; then
    echo "ドライラン完了。実行するには: bash _tools/package-dist.sh"
  else
    echo "ドライラン完了。実行するには: bash _tools/package-dist.sh --target $TARGET"
  fi
  exit 0
fi

# --- サニタイズ（配布用の除外ルールをプレースホルダ化）---
echo ""
echo "=== サニタイズ ==="
# _lib.sh / .gitignore: ローカル固有の日付フォルダを配布用の例に置換
sed -i '' 's|30_Flow/2026-06-12|30_Flow/YYYY-MM-DD/実案件_クライアント名|g' "$STAGING/_tools/_lib.sh" 2>/dev/null || \
sed -i 's|30_Flow/2026-06-12|30_Flow/YYYY-MM-DD/実案件_クライアント名|g' "$STAGING/_tools/_lib.sh"
sed -i '' 's|30_Flow/2026-06-12/|# 30_Flow/YYYY-MM-DD/実案件_クライアント名/ （実案件はここに追記して除外）|g' "$STAGING/.gitignore" 2>/dev/null || \
sed -i 's|30_Flow/2026-06-12/|# 30_Flow/YYYY-MM-DD/実案件_クライアント名/ （実案件はここに追記して除外）|g' "$STAGING/.gitignore"
log "サニタイズ完了（ローカル固有パス→プレースホルダ）"

# --- 危険物チェック ---
echo ""
echo "=== 危険物チェック（著作物・実データ混入防止）==="
danger=0
# 著作物（PDF/画像）
pdf_count=$(find "$STAGING" -iname "*.pdf" 2>/dev/null | wc -l | tr -d ' ')
img_count=$(find "$STAGING" \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null | wc -l | tr -d ' ')
if [[ $pdf_count -gt 0 ]]; then echo "❌ PDF $pdf_count 件混入"; danger=1; fi
if [[ $img_count -gt 0 ]]; then echo "❌ 画像 $img_count 件混入"; danger=1; fi
# ローカル実案件パスの残存チェック（テキストファイルのみ走査、バイナリスキップ）
for pattern in '30_Flow/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/実案件_' '30_Flow/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/Skillテスト_0-1_'; do
  hits=$(grep -Erl --include='*.md' --include='*.sh' --include='*.tsv' --include='*.html' --include='*.json' "$pattern" "$STAGING" 2>/dev/null || true)
  hit_count=$(echo "$hits" | grep -c . || true)
  if [[ -n "$hits" ]]; then echo "❌ ローカル実案件パスパターン「$pattern」が $hit_count ファイルに残存"; danger=1; fi
done
# .skillファイル
skill_files=$(find "$STAGING" -name "*.skill" 2>/dev/null | wc -l | tr -d ' ')
if [[ $skill_files -gt 0 ]]; then echo "⚠️  .skill $skill_files 件（build.shで再生成推奨）"; fi
# 案件データ
flow_data=$(find "$STAGING/30_Flow" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ $flow_data -gt 0 ]]; then echo "❌ 30_Flow に案件データ $flow_data 件残存"; danger=1; fi

if [[ $danger -eq 0 ]]; then
  echo "✅ 危険物なし"
else
  echo "⚠️  上記を修正してから配布してください"
  exit 1
fi

# --- ステージング→_dist/ にコピー ---
echo ""
echo "=== _dist/ に配置 ==="
mkdir -p "$DIST"
rsync -a --delete "$STAGING/" "$DIST/"

# --- 統計 ---
echo ""
echo "=== 配布フォルダ統計 ==="
echo "出力先: _dist/"
skill_count=$(find "$DIST/20_Skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
guideline_count=$(find "$DIST/40_Stock/横断ガイドライン" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
card_count=$(find "$DIST/40_Stock/カード" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
total_files=$(find "$DIST" -type f 2>/dev/null | wc -l | tr -d ' ')
total_size=$(du -sh "$DIST" 2>/dev/null | cut -f1)
echo "  Skill数: $skill_count"
echo "  横断ガイドライン: $guideline_count"
echo "  カード: $card_count"
echo "  総ファイル数: $total_files"
echo "  合計サイズ: $total_size"

echo ""
echo "✅ 配布フォルダ生成完了: _dist/"
