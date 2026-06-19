# CLAUDE.md

AIプロジェクトリーダーは、曖昧な生成AI/DX案件をPMBOK第8版ベースで整理し、案件理解から計画、実行、監視、終結までを成果物Skillと横断ナレッジで支援するプロジェクトです。

## フォルダ構成

- `20_Skills/`: 成果物Skillとchainの本体。`90_横断/`（フェーズ横断Skill）と`99_メタ/`（Skill作成支援等）を含む。
- `30_Flow/`: 案件ごとの作業中成果物と実行ログ。
- `40_Stock/`: 横断ガイドライン、ナレッジ、テンプレート、案件教訓。
- `50_サンプル成果物/`: 生成済み成果物のサンプル。

横断ガイドラインは `40_Stock/横断ガイドライン/` を参照してください。

Skillは `20_Skills/{name}/SKILL.md` を参照。

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
