# WBS Viewer の入手・配置・使い分け

WBSは2つのHTMLで見せる。役割が違う。

| | 何 | 用途 | 作り方 |
|---|---|---|---|
| **閲覧版**（`_閲覧版.html`） | データ埋め込みの単一HTML | *見せる・配る*。ダブルクリックで誰でも閲覧 | このSkillが `assets/閲覧版テンプレ.html` から毎回生成 |
| **WBS Viewer**（`wbs_viewer.html`） | 編集できる本家ツール（MIT・ぴぐお作） | *編集・実績入力・イナズマ運用* | 一度きり入手して使い回す（下記） |

## WBS Viewer 本体の入手（一度きり）

1. `https://github.com/piguo45/single-file-wbs` の **Releases** から `wbs_viewer.html` を1回だけダウンロード。
2. **置き場（推奨）**：プロジェクト共通で使い回すので、案件フォルダではなく共有の1か所に置く。社内なら `10_参考資料/WBS Viewer/wbs_viewer.html`、配布パッケージなら同梱フォルダ。
3. 使うとき：`wbs_viewer.html` をChrome/Edgeで開き、「ファイルを開く」で案件の `wbs.json` を読み込む。

## 配布時のルール（不可逆ガード）

- WBS Viewer は**外部のMIT製品**。配布物に同梱するなら、**MITライセンスと帰属（作者: ぴぐお / single-file-wbs）を明記**する（`source-attribution-distribution-rule`／3層モデル）。
- 我々が生成するのは `wbs.json`＋閲覧版HTML。ビューア本体は再配布物として帰属付きで添えるだけ（改変しない）。

## 使い分けの目安

- クライアントに**見せる/配る** → 閲覧版HTML（環境を選ばない・ダブルクリック）。
- 我々や更新係が**実績を入れて回す** → WBS Viewer＋`wbs.json`（Chrome/Edge）。作業者は触らず「更新依頼テンプレ」で報告。
