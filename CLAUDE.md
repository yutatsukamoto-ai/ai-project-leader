# CLAUDE.md

AIプロジェクトリーダーは、曖昧な生成AI/DX案件をPMBOK第8版ベースで整理し、案件理解から計画、実行、監視、終結までを成果物Skillと横断ナレッジで支援するプロジェクトです。

## 初動ルーティング

最初から全ファイルを読まず、作業内容に応じて入口を選ぶ。

| 作業内容 | 最初に読むもの |
|---|---|
| 全体把握・決まったことの確認 | `README.md`、`00_プロジェクト管理/構造レビュー/決定の索引.md` |
| Skill構造・成果物対応を触る | `20_Skills/成果物マップ.md`、`20_Skills/横断GL対応表.md`、対象Skill、関連する横断ガイドライン |
| Skill追加・改名・横断GL新設など構造変更 | `プロジェクト骨子.md`（設計原則）、`00_プロジェクト管理/構造レビュー/規約・枠を新設するときの心得.md` |
| 案件成果物を作る・更新する | 該当案件の `project-context.md` **のみ**（現在地・次Skill・読むべきGL・文書ポインタが全て載っている）。案件特定が要る場合だけ `30_Flow/実案件/案件インデックス.md` を先に引く |
| 未決・懸念を調べる | `00_プロジェクト管理/構造レビュー/懸念マスター.md` |
| 宿題棚卸し・優先順位の確認 | `00_プロジェクト管理/宿題一覧_棚卸し報告書_2026-06-22.md`、`00_プロジェクト管理/構造レビュー/懸念マスター.md` |
| Skill改名・追加・横断GL新設の波及チェック | `00_プロジェクト管理/構造レビュー/規約・枠を新設するときの心得.md`（波及チェックリスト節）、`bash _tools/build.sh --verify` |

案件作業の注意:
- 成果物の作成・更新、または `project-context.md` への書き戻し前は `30_Flow/現在の作業セッション.md` でアクティブ案件を確認する。
- 案件を切り替えるときは「現在: {旧案件名}/{旧フェーズ} → 次: {新案件名}/{新フェーズ}、書き込み先: {新案件ルート}」を宣言してから作業する。

## フォルダ構成

- `20_Skills/`: 成果物Skillとchainの本体。`90_横断/`（フェーズ横断Skill）と`99_メタ/`（Skill作成支援等）を含む。
- `30_Flow/`: 案件ごとの作業中成果物と実行ログ。
- `40_Stock/`: 横断ガイドライン、ナレッジ、テンプレート、案件教訓。
- `50_サンプル成果物/`: 生成済み成果物のサンプル。

横断ガイドラインの正典は `40_Stock/横断ガイドライン/`。
どのSkillで読むかは `20_Skills/横断GL対応表.md` を参照してください。

Skillは `20_Skills/{name}/SKILL.md` を参照。

## スライド作成の扱い

新規スライド資料の生成は、原則Codex側の `image2-brand-slides` を主ルートにする。Claude Codeでは意味設計・構成案・既存PPTXレビュー・検証補助に留め、編集可能PPTXが明示された場合だけ `slide-craft` を補助的に使う。

## 現在の基盤状態

- Hooks/CI基盤は実装済み。gate-check / auto-build / auto-eval / Stop prompt hook を使う。
- `.claude/skills/` は生成物。Skill本体を変えたら `bash _tools/build.sh --sync-cc` で同期する。
- `.claude/settings.local.json` はローカル許可用で配布対象外。Hook発火の正典は `.claude/settings.json`。

## 検証コマンド

- 構造健全性: `bash _tools/build.sh --verify`
- 共通項ドリフト: `bash _tools/build.sh --check`
- Hook smoke: `bash _tools/test-hooks.sh`
- Claude Code配布: `bash _tools/build.sh --sync-cc` → `bash _tools/package-dist.sh --target claude-code` → `bash _tools/test-dist-cc.sh`

## モデル使い分けルール

- 作る系（新Skill伴走・references起草・テーラリング設計・計画提案書の設計意図）: 強モデル（opus）必須
- 回す系（既存Skillで成果物生成・定型巻き上げ）: 別モデル可（sonnet以上）
- モデルを交代したら: 着手前に `bash _tools/eval.sh` 全件 + 主要Skillの judge を流す
