# slide-craft 配置整理案

作成日: 2026-06-17
状態: **実行済み（2026-06-17）。**

---

## 背景

`slide-craft` だけが `90_横断/skills/slide-craft/` にあり、他の横断Skill（`grill-me` / `gyoumu-flow-designer`）は `20_Skills/90_横断/` にある。

現状でも `build.sh --verify` の対象外として壊れてはいないが、構造の一貫性と配布時の見通しを考えると、`slide-craft` も `20_Skills/90_横断/` に寄せるのが自然。

## 移動内容

| 項目 | 内容 |
|---|---|
| 移動元 | `90_横断/skills/slide-craft/` |
| 移動先 | `20_Skills/90_横断/slide-craft/` |
| `.skill` | `90_横断/skills/slide-craft.skill` から `20_Skills/90_横断/slide-craft.skill` へ再生成 |
| 成果物マップ | 横断・メタ表に `slide-craft` を追記 |
| Claude Code同期 | `bash _tools/build.sh --sync-cc` で `.claude/skills/slide-craft` を同期 |
| 旧ディレクトリ | `90_横断/skills/` と空の `90_横断/` を削除 |

## 実行手順

1. `90_横断/skills/slide-craft/` を `20_Skills/90_横断/slide-craft/` へ移動する。
2. `90_横断/skills/slide-craft.skill` は古い生成物として削除する。
3. `90_横断/skills/` と空の `90_横断/` を削除する。
4. `bash _tools/build.sh 20_Skills/90_横断/slide-craft` で再パッケージする。
5. `20_Skills/成果物マップ.md` の横断・メタ表へ `slide-craft` を追記する。
6. `bash _tools/build.sh --sync-cc` を実行する。
7. `bash _tools/build.sh --verify` と `bash _tools/eval.sh` を実行する。

## 影響

- `build.sh` の `list_skill_dirs` は `20_Skills` 配下だけを対象にしているため、移動後は `slide-craft` が通常のSkill検証・パッケージ化・Claude Code同期の対象になる。
- `slide-craft` の `SKILL.md` 内には `40_Stock/横断ガイドライン/スライド生成の原則.md` や `10_参考資料/スライド・プレゼン/...` への参照があるため、移動時に相対パスの記述を確認する必要がある。
- フォルダ構造変更を伴うため、CODEX.md §4に従い、このメモで承認を得てから実行した。

## 判断

推奨: **移動する**。

理由:
- 横断Skillの置き場が `20_Skills/90_横断/` に統一される。
- `build.sh --all` / `--verify` / `--sync-cc` の対象に入り、配布前の検査網に乗る。
- `90_横断/skills/` という例外ディレクトリを残さずに済む。

実行後の検証結果は作業完了報告に記録する。
