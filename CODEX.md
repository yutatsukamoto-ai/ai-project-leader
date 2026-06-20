# CODEX.md — Codex 作業ルール

このファイルは Codex（OpenAI）でこのリポジトリを編集するときの制約集。
リポジトリの構造・用語・運用ルールは `AGENTS.md` → `README.md` の順に読むこと。

---

## 0. Codex版の現在地

Codex版は、まず **リポジトリ編集・検証・配布生成・スライド生成補助** を安全に進めるための入口として扱う。
案件チェーン本番運用の主戦場は引き続き Claude Cowork。Codexで案件成果物を作る場合も、停止ポイントと承認ゲートはCowork版と同じ扱いにする。

Codexで今できること:

- Skill本文・references・横断ガイドラインの編集
- スライド新規作成は原則 `image2-brand-slides` の手順で進める
- `slide-craft` は編集可能PPTXが明示的に必要な場合、既存PPTXレビュー、またはユーザー承認済みの切替時だけ使う
- `build.sh --verify` / `--check` / `eval.sh` による検証
- `package-dist.sh --target codex` によるCodex配布フォルダ生成
- GitHub反映前の差分確認、危険物混入確認、コミット・push

Codexでまだ本格運用しないこと:

- 承認なしのフェーズ移行
- 実案件データを含む成果物の配布物化
- Claude Code側のHooks/CI/LLM-judge自動化を前提にした無人運用
- `.codex/` 専用設定の追加（必要になった時点で設計する）

Codex配布版を作るとき:

```bash
bash _tools/package-dist.sh --target codex
bash _tools/test-dist-codex.sh
```

配布版には `AGENTS.md` と `CODEX.md` を含める。`CLAUDE.md` と `.claude/` はClaude Code専用なので含めない。

### Codexでスライドを作るとき

ユーザーから特に指定がない限り、Codexでの新規スライド作成は必ず `image2-brand-slides` の流れで進める。

標準手順:

1. `message_design.md` で意味設計を固める
2. `deck_structure.md` で全スライドの主張・根拠・構図を固定する
3. `design_system.md` でブランド/トーンを決める
4. `prompts/` を1枚ずつ作る
5. Image2で1スライド1画像を生成する
6. 最初の3〜5枚で止めて確認を取る
7. 承認後に残りを生成し、最終PNGを `export/html/index.html` にまとめる

やらないこと:

- 明示指定なしに `slide-craft` / 編集可能PPTX生成へ切り替えない
- PPTXレンダー画像をHTML版の正本として流用しない
- DOM/HTML/CSSでスライド本文を手組みして代替しない
- 画像生成前の構成確認を飛ばさない

例外:

- ユーザーが「編集可能なPPTX」「PowerPointで編集できる形」と明示した場合
- 既存PPTXのレビュー・修正が主目的の場合
- Image2が使えず、ユーザーが代替手段への切替を明示承認した場合

---

## 1. 正典の優先順位

矛盾が見つかったら上位を信じる。下位を勝手に正にしない。

1. `00_プロジェクト管理/接続規約_前段→本体_v0.2.md`（フォルダ構造・引き継ぎ規約）
2. `40_Stock/横断ガイドライン/` 配下の各規約（出力フォーマット・文体・図・表）
3. `20_Skills/成果物Skill共通ひな形.md`（Skill実行の共通手順）
4. 各 `SKILL.md`（個別の成果物ルール）
5. `README.md` / `AGENTS.md`（概要・ナビゲーション）

迷ったら変更せずコメントで残して聞く。

## 2. 触るなリスト

以下は変更禁止。読み取り参照のみ可。

- `00_プロジェクト管理/履歴/` — 時点記録。内容が古くても正しい
- `_backups/` — スナップショット
- `10_参考資料/` — 書籍PDF・外部資料（著作物）
- `_tools/eval/goldens.tsv` — 追加はOK、既存行の編集・削除は禁止
- `30_Flow/` 配下の完了済み案件フォルダ — 実行ログとして凍結
- 実案件データ（社名・金額等）を含むファイルの配布物・Stock側へのコピー

## 3. パスの書き方

- Skill や成果物テンプレでは**フルパスを書かない**。`{案件ルート}/00_前段/...` のように相対プレースホルダを使う
- フルパスの命名規約（`30_Flow/{カテゴリ}/{案件種別}_案件名/`）は接続規約だけが持つ。他のファイルに複製しない
- `outputs/` は中間生成物の一時置き場。正典成果物のパスに使わない
- 実案件を名前だけで呼ばれたら、`30_Flow/実案件/案件インデックス.md` → 該当案件の `project-context.md` → `00_案件ステータス.md` の順に読む。実案件フォルダはgitignore配下なので、実名・進捗はそこに閉じ込める。読み取りだけなら `30_Flow/現在の作業セッション.md` のアクティブ案件は変更しない
- 案件成果物の作成・更新、または `project-context.md` への書き戻し前には、`30_Flow/現在の作業セッション.md` を読む。保存先がアクティブ案件ルート配下でない場合は、書き込まずユーザーへ確認する
- 案件を切り替えるときは、旧案件の停止位置を `30_Flow/現在の作業セッション.md` に残し、「現在: {旧案件名}/{旧フェーズ} → 次: {新案件名}/{新フェーズ}、以後の書き込み先: {新案件ルート}」を宣言してから作業する

## 4. 設計変更の停止ルール

以下に該当する変更は、**スペック案を1ファイルにまとめて止める**。各Skillへの反映はレビュー後。

- 冒頭メタのフィールド追加・削除・名称変更
- 承認ゲート（`✋✋`）の条件変更
- chain間の入出力インターフェース変更
- フォルダ構造・命名規約の変更
- 共通ひな形の手順追加・削除
- 新しい横断ガイドラインの新設

「機械的な編集」（typo修正、既存ルールの各ファイルへの反映、テスト追加）は止めなくてよい。

## 5. diff出力の義務

作業完了時に必ず以下を出す：

- 変更ファイル一覧（パスのみ）
- 各ファイルの変更前後（diff形式またはbefore/after抜粋）
- 「設計判断を含む変更」と「機械的な変更」の分類

## 6. 検証

変更後は以下を実行し、結果を報告する：

```bash
bash _tools/build.sh --verify   # 構造健全性
bash _tools/build.sh --check    # 共通項ドリフト
```

Skill内容を変えた場合は該当範囲の eval も流す：

```bash
bash _tools/eval.sh
```

配布まわりを変えた場合は対象ターゲットのスモークテストも流す：

```bash
bash _tools/package-dist.sh --target codex
bash _tools/test-dist-codex.sh
```

Claude Code配布に影響する変更なら、既存ターゲットも壊していないか確認する：

```bash
bash _tools/test-hooks.sh
bash _tools/build.sh --sync-cc
bash _tools/package-dist.sh --target claude-code
bash _tools/test-dist-cc.sh
```

GitHubへ反映する前は、少なくとも次を確認する：

```bash
rg -n '^_dist/$|^_backups/$' .gitignore
git ls-files _dist _backups
git status --short --branch
```

## 7. やりがちなミスの予防

- **参照元を読まずに書く** → 変更対象のファイルと、それを参照している側の両方を読んでから修正する
- **1箇所だけ直す** → 正典を直したら `build.sh --check` でコピー側のドリフトを確認する
- **README.md と AGENTS.md の片方だけ直す** → 両方に同じ情報がある項目（やらないこと、起動文）は両方更新する
- **Codex版とClaude Code版を混ぜる** → Codex配布は `AGENTS.md` / `CODEX.md`、Claude Code配布は `CLAUDE.md` / `.claude/` と分ける
- **構造変更時に波及先を忘れる** → Skill改名・追加・横断GL新設などの前に `00_プロジェクト管理/構造レビュー/規約・枠を新設するときの心得.md` の波及チェックリストを確認する
