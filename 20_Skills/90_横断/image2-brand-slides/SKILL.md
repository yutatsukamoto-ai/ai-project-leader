---
name: image2-brand-slides
description: |
  Codex版の主スライド生成Skill。ロゴ、Style Markdown、公式サイト、既存資料、または雰囲気指定を資料テーマへ翻訳したデザインシステムを作り、Image2で1スライド1画像を生成し、PNG群をHTMLデッキにまとめる。
  「スライドを作って」「プレゼン資料を作って」「この原稿をスライド化して」「ロゴ起点で資料を作って」「Image2でスライドを作って」「ブランドに合うスライド画像を作って」「HTMLでスライドをまとめて」と頼まれたら、Codexでは原則このSkillを主入口にする。
  既存 slide-craft は編集可能PPTXや既存PPTXレビューが主目的のときだけ補助として使う。
---

# Image2 Brand Slides

## 目的

Codex版でのスライド作成は、編集可能なPPTXを最初からコードで組むことではなく、**ブランドアンカーからデザインシステムを作り、Image2で1スライド1画像として高品質なスライドを生成する**ことを主軸にする。

基本思想:

- ロゴやStyle Markdownなどのブランドアンカーを、模倣対象ではなく資料テーマへ翻訳する起点にする
- 会社ブランドそのものより、資料の目的・読者・意思決定テーマに合う世界観を主役にする
- 原稿品質と意味設計を先に確認し、曖昧な主張や根拠不足のまま見た目作りへ進まない
- 長文を勝手に要約せず、全情報を `deck_structure.md` に割り振る
- 各ページで何を言い切るかを決め、意味から論理構造とレイアウトを選ぶ
- 1スライド1メッセージ、1画像1スライドで生成する
- 最終PNGを `slides/` に集約し、`index.html` でスライドデッキとして表示する
- 最初の3〜5枚で必ず止め、方向性確認を取る
- 通常スライドの小タイトル・下線・ロゴだけを後処理で揃える
- 本文エリアの誤字や崩れはコード補正せず、該当スライドを再生成する

HTMLデッキを主成果物にする。PPTXは主成果物ではない。必要な場合だけ、最終PNGを貼り付ける器として作る。

---

## 参照ファイル

| ファイル | いつ読むか |
|---|---|
| `references/brand-anchor-guide.md` | ロゴなし、公式サイト、Style Markdown、既存資料、雰囲気指定からブランドルールを作るとき |
| `references/message-design-gate.md` | 原稿品質、各ページの主張、根拠、意味からレイアウトを決めるとき |
| `references/design-system-rubric.md` | `design_system.md` の必須項目と品質を確認するとき |
| `references/layout-archetype-guide.md` | スライド別の役割、構図、強調方法を決めるとき |
| `references/headline-emphasis-guide.md` | 見出し、ページカテゴリ、強調サイズを決めるとき |
| `references/consulting-logic-pattern-guide.md` | DX/AIコンサル資料の論理構造を決めるとき |
| `references/color-hierarchy-guide.md` | 主色の濃淡、アクセント、非強調色で情報階層を決めるとき |
| `references/reference-material-roles.md` | 参照資料から何を取り入れ、何を模倣しないかを決めるとき |
| `references/prompt-contract.md` | スライド別Image2プロンプトを作るとき |
| `scripts/fix_title_logo.py` | 生成後に通常スライドのタイトル・下線・ロゴを揃えるとき |
| `scripts/build_html_deck.py` | 最終PNGをHTMLスライドデッキにまとめるとき |

このSkillは `10_参考資料/` の記事・PDF・画像を実行時参照しない。配布可能な運用ルールだけをこのSkill内に持つ。

---

## 入力

必須:

- スライドにしたい原稿、構成案、議事録、メモ、またはMarkdown

ブランドアンカーはいずれか:

1. ロゴ画像
2. Style Markdown / 社内デザインルール
3. 公式サイトURL
4. 既存資料/PDF/スクリーンショット
5. ユーザー指定の雰囲気・業種・用途
6. 壁打ちによる暫定ブランド指定

何もない場合は、次の3問だけ確認して暫定ブランドルールを作る。

1. 誰に見せる資料か
2. どんな印象にしたいか
3. 避けたい印象は何か

---

## 出力フォルダ

案件内で使う場合:

```text
{案件ルート}/outputs/image2-brand-slides/{デッキ名}/
├── input_manifest.md
├── message_design.md
├── deck_structure.md
├── design_system.md
├── visual_direction_board.md  # 任意。方向性比較が必要な場合のみ
├── prompts/
│   ├── 01-title.md
│   ├── 02-normal.md
│   └── ...
├── image2-original/
│   ├── 01-title.png
│   ├── 02-normal.png
│   └── ...
├── image2-fixed/
│   ├── 01-title.png
│   ├── 02-normal.png
│   └── ...
├── titles.json
├── review_notes.md
└── export/
    ├── html/
    │   ├── index.html
    │   ├── manifest.json
    │   └── slides/
    │       ├── 01-title.png
    │       ├── 02-normal.png
    │       └── ...
    └── {デッキ名}.pptx  # 任意。必要な場合のみ
```

案件外のテストでは `30_Flow/テスト/Skillテスト_image2-brand-slides/` を使う。

正典成果物にする場合は、HTMLデッキ、画像群、PPTXをフェーズフォルダへ移す前にユーザー確認を取る。

---

## Core Rules

- Codexでスライド生成を頼まれた場合、原則このSkillを主入口にする。
- `slide-craft` へ自動フォールバックしない。Image2が使えない場合は止めて報告する。
- APIキー、環境変数、独自APIスクリプト、CLIフォールバックを勝手に使わない。
- 既存テンプレート、過去出力、無関係な作業フォルダを勝手に参照しない。
- Image2生成は、現在のCodexセッションで利用可能な組み込み画像生成機能を使う。
- 1画像に複数スライドを入れない。コンタクトシートを作らない。
- ブランドアンカーをそのまま模倣しない。公式サイト風、ロゴ主役、スクリーンショット主役に寄せず、資料テーマへ翻訳する。
- 各スライドで `slide_role`、`layout_archetype`、`emphasis_pattern` を決め、同じ構図の量産を避ける。
- 各スライドで `reader_question`、`page_claim`、`evidence`、`evidence_status` を決め、意味の弱いまま生成しない。
- 事実、入力上の前提、推測、欠落情報を分ける。入力にない数字、効果、固有情報を捏造しない。
- 意味設計が不足している場合は、デザイン検証などの仮試作を除き、生成前に確認する。
- 同じ `layout_archetype` を3枚以上連続で使わない。
- 最終成果物は `index.html` と `slides/*.png` を標準にする。
- 目次/本日の流れスライドは自動で強制しない。読者、資料目的、枚数、発表用途から必要と判断した場合だけ入れる。
- 表示タイトルに `01`、`1.`、`第1章` などの連番を入れない。
- ページ番号を表示しない。
- 通常スライドが2枚以上ある場合は `image2-fixed/` を作る。
- `image2-original/` を上書きせず、補正後は `image2-fixed/` に出す。
- 最終閲覧用の正本は `export/html/index.html` と `export/html/slides/` に置く。
- `export/html/slides/` には最終PNGだけを入れる。通常スライドは `image2-fixed/` から、表紙など補正不要のスライドは最終採用元からコピーする。
- HTMLは相対パスだけで動く静的ファイルにする。外部CDN、外部フォント、外部JSに依存しない。
- ロゴなしの場合、ロゴを捏造しない。
- 本文エリアをSVG、HTML、Python、Mermaid、pptxgenjsで描き直さない。
- 本文エリアの誤字・崩れは、該当スライドの再生成で直す。

---

## Workflow

### Step 1: 入力整理

原稿を読み、以下を抽出する。

- デッキタイトル
- 想定読者
- 資料目的
- 主要メッセージ
- セクション候補
- 表、チェックリスト、注意書き、手順、引用、補足

不足が大きい場合は、スライド生成へ進まず追加確認する。

### Step 2: `message_design.md` 作成

`references/message-design-gate.md` を読み、見た目を作る前に原稿品質と意味設計を確認する。

必須項目:

- 資料目的
- 想定読者
- 読後にしてほしい判断・行動
- content_mode（production / design_trial）
- 入力原稿の成立度
- 各スライド候補の `reader_question`
- 各スライド候補の `page_claim`
- 各スライド候補の `evidence`
- 各スライド候補の `evidence_status`（fact / provided_assumption / inferred / missing）
- 各スライド候補の `missing_detail`
- 各スライド候補の `layout_reason`
- 確認が必要な点
- 生成へ進む判断（proceed / proceed_as_draft / stop_for_clarification）

原則:

- 原稿だけで内容が成立するかを見る
- 各ページで何を言い切るかを先に決める
- 主張と根拠を対応させる
- 数字、期限、金額、件数、固有名詞は入力にあるものだけを使う
- 入力にない内容を補う場合は `inferred` として扱い、事実のように書かない
- 根拠が弱い場合は、断定を避けるか、ユーザー確認に回す
- ユーザーが「デザイン検証」「仮題材で試作」と明示した場合は `content_mode: design_trial` / `proceed_as_draft` として進め、仮置きであることを `review_notes.md` に残す
- 本番資料や客先提出に近い資料では `content_mode: production` とし、根拠不足の主張を断定しない

`stop_for_clarification` の場合は、Image2生成へ進まず、確認が必要な点だけを短く提示して止める。

### Step 3: ブランドアンカー確認

`references/brand-anchor-guide.md` を読み、入力種別ごとに `input_manifest.md` を作る。

`input_manifest.md` に残すもの:

- 入力種別（ロゴ / Style Markdown / 公式サイト / 既存資料 / 雰囲気指定 / 壁打ち）
- 参照URLまたはファイル名
- 取得日・確認日
- 抽出した色（可能ならHEX）
- 抽出したトーン・雰囲気
- 推測と事実の切り分け
- 参照しなかったもの（既存テンプレート、過去出力など）

公式サイトを使う場合は、ユーザーから明示されたURLを優先する。勝手に古い企業情報を推測しない。

### Step 4: `deck_structure.md` 作成

`message_design.md` を前提に、全体構成を作る。

必須項目:

- デッキ目的
- 想定読者
- 全スライド一覧
- 目次/本日の流れスライドの要否と理由
- 各スライドの表示タイトル
- 各スライドの1メッセージ
- 各スライドの `navigation_title`
- 各スライドの `message_headline`
- 各スライドの `supporting_message`
- 各スライドの `reader_question`
- 各スライドの `page_claim`
- 各スライドの `evidence`
- 各スライドの `evidence_status`
- 各スライドの `missing_detail`
- 各スライドの `layout_reason`
- 各スライドの `visual_focus`
- 各スライドの `emphasis_reason`
- 各スライドの `logic_pattern`
- 各スライドの `logic_purpose`
- 各スライドの `primary_read`
- 各スライドの `structure_notes`
- 各スライドの `color_role`
- 各スライドの `slide_role`
- 各スライドの `layout_archetype`
- 各スライドの `emphasis_pattern`
- 各スライドに割り当てた元情報
- ソースカバレッジマップ
- 初回プレビュー対象
- 後続スライドへ延期した情報の明示

原則:

- 入力にある重要情報を勝手に落とさない
- 情報が多い場合は要約で消さず、スライドを分ける
- 1スライド1メッセージ
- 長文では `deck_structure.md` を構成マップとして扱い、見出し、表、チェックリスト、注意書きがどのスライドに割り当たったかを記録する
- 目次/本日の流れスライドは、読者が流れを必要とする場合だけ入れる。短い提案、比較、単発ショットでは2枚目を課題・結論・判断材料にしてよい
- `page_claim` が曖昧なページは、見た目でごまかさず構成を見直す
- `evidence_status` が `missing` の主張は、断定スライドにしない
- `message_headline` は `page_claim` を読者向けに短く言い換える
- 固定ヘッダーの表示タイトルは、ページのカテゴリが分かる短い `navigation_title` にする
- 本文の大見出しは、ページの結論や判断を示す `message_headline` にする
- 表示タイトルにはページ番号や連番を入れない
- 項目数、章番号、補助ラベルを巨大化しない。大きくする場合は `emphasis_reason` に理由を残す
- 3枚以上連続で同じ `layout_archetype` にしない
- 3カラムカード、2x3グリッド、下部メッセージ帯を無意識に標準化しない
- 課題整理、比較、工程、計画、判断基準のページでは、抽象的な雰囲気図ではなく論理構造を持たせる
- `logic_pattern` と `layout_archetype` は `layout_reason` に基づいて選ぶ
- 色数を増やして差分を作らない。主色の濃淡、非強調グレー、少量のアクセントで読み順を作る

### Step 5: `design_system.md` 作成

`references/design-system-rubric.md`、`references/color-hierarchy-guide.md`、`references/reference-material-roles.md` を読み、ブランドアンカーと参照資料を資料テーマへ翻訳した、再利用可能なデザインシステムを作る。

必須項目:

- 目的
- ブランド原則
- ロゴ使用ルール、またはロゴなしルール
- 色の役割
- 色の階層: base_background / main_dark / main_mid / main_light / accent_color / neutral
- タイポグラフィ
- 余白・配置
- 情報設計
- レイアウト戦略
- 表・チャート方針
- 画像・アイコン・図版方針
- 避ける表現

デフォルトは、参照資料を役割分担して使う `reference-informed consulting proposal style` にする。外資系コンサル系資料からは形とロジック、Retty型資料からは色階層とパーツ設計を抽象化して使う。真っ白ではない背景、資料テーマから翻訳した主色、主色の濃淡、非強調グレー、少量アクセントで階層を作る。深緑/セージは八束電工のようにテーマへ合う場合の候補であり、固定デフォルトではない。ロゴや公式サイト素材は主役にせず、資料テーマに合わせて翻訳する。

ただし、ユーザーが明示的に別の方向性（例: 強いブランド再現、写真中心、営業色の強いビジュアル、ダッシュボード風）を求めた場合は、ユーザー指示を優先し、その理由を `design_system.md` に残す。

### Step 6: レイアウト戦略の確認

`references/layout-archetype-guide.md`、`references/headline-emphasis-guide.md`、`references/consulting-logic-pattern-guide.md`、`references/color-hierarchy-guide.md`、`references/reference-material-roles.md` を読み、スライド別に `slide_role`、`layout_archetype`、`emphasis_pattern`、見出し、強調対象、論理構造、色の役割を確定する。

目的:

- 色やモチーフだけでなく、構図と強調方法に差分を作る
- AIが平均的なカードUI、3カラム、2x3グリッドに逃げるのを防ぐ
- 資料タイプ（提案、研修、報告、構想、検証）に合う見せ方へ翻訳する
- 見出しを文章要約ではなく、ページのカテゴリと主張に分ける
- 大きく見せる要素に理由を持たせる
- 静かな見た目と、コンサル資料としての論理骨格を分けて設計する
- 課題/解決策、比較、プロセス、計画、判断表などは `logic_pattern` で指定する
- 主色、主色の薄い面、非強調グレー、アクセントをどの情報に割り当てるかを `color_role` で指定する
- 参照資料の色やテンプレートをコピーせず、形/ロジック/色階層/パーツを分解して取り入れる

`deck_structure.md` の各スライド行に以下を持たせる。

```text
navigation_title:
message_headline:
supporting_message:
reader_question:
page_claim:
evidence:
evidence_status:
missing_detail:
layout_reason:
visual_focus:
emphasis_reason:
logic_pattern:
logic_purpose:
primary_read:
structure_notes:
color_role:
slide_role:
layout_archetype:
emphasis_pattern:
```

ユーザーがデザイン差分を確認したい場合、または初回の方向性がまだ曖昧な場合は、`visual_direction_board.md` を作ってよい。

方向性ボードは `message_design.md` の後に作る。内容の事実性や主張の正しさを検証するものではなく、意味設計済みのページをどう見せるかの候補比較に限る。

`visual_direction_board.md` に残すもの:

- 3〜6個の方向性候補
- 各候補の `layout_archetype`
- 各候補の強調方法
- 向いている資料タイプ
- 避けるべき既視感
- 採用/不採用理由

方向性ボードは完成物ではない。細かい本文の正確性より、全体トーン、余白、構図、強調方法の見比べに使う。

### Step 7: `prompts/` 作成

`references/prompt-contract.md` を読み、1スライドにつき1プロンプトを作る。

`message_design.md`、`deck_structure.md`、`design_system.md` を分けて扱う。

- `message_design.md`: 誰に、何を、どの根拠で言い切るか
- `deck_structure.md`: 何を、どの順番で、どのスライドに載せるか
- `design_system.md`: どのトーン、余白、配色、文字階層で見せるか
- `layout_archetype`: どの構図で見せるか
- `emphasis_pattern`: 何で印象を作るか
- `navigation_title`: 固定ヘッダーに置く短いカテゴリ
- `message_headline`: 本文エリアの大見出し。ページの結論や判断
- `reader_question` / `page_claim` / `evidence_status`: 読者の問い、ページ主張、根拠の状態
- `visual_focus` / `emphasis_reason`: 何を大きく見せるか、なぜ大きくするか
- `logic_pattern`: コンサル資料としての論理骨格。例: logic_tree、issue_emphasis_tree、proposal_logic_tree、issue_solution_tree、decision_table、process_swimlane、flow_type
- `color_role`: 主色の濃淡、非強調グレー、アクセントを何に使うか

各プロンプトには、対象スライドの `slide_role`、`layout_archetype`、`emphasis_pattern`、`navigation_title`、`message_headline`、`reader_question`、`page_claim`、`evidence_status`、`visual_focus`、`emphasis_reason`、`logic_pattern`、`logic_purpose`、`primary_read`、`structure_notes`、`color_role` を明記する。同じ構図の使い回しを避けたい場合は、前後スライドと違う構図にする制約も入れる。

### Step 8: 初回プレビュー生成

フルデッキでも、最初に生成するのは3〜5枚まで。

初回プレビュー対象:

- 1枚目: 表紙
- 2枚目以降: `message_design.md` と `deck_structure.md` で重要度が高い主要スライド
- 目次/本日の流れが必要な資料では、初回プレビューに含める

組み込み画像生成機能を、1スライドにつき1回呼ぶ。

生成後の保存ルール:

- Image2が返した画像は、まず `image2-original/` に安定ファイル名で保存する。
- ファイル名は `01-title.png`, `02-normal.png` のように2桁連番にする。
- 生成ツールが別の保存先を返す場合は、元ファイルを残したままコピーする。
- 画像をローカル保存できない場合は、作業を止めて保存不能を報告する。
- 保存できないまま `image2-fixed/`、HTML化、PPTX化へ進まない。

ここで停止し、ユーザー確認を取る。

確認観点:

- ブランド感は合っているか
- 文字の読みやすさは許容できるか
- 情報量は多すぎないか
- 画像生成の方向性は続行可能か
- 修正したいトーンはあるか

承認されたら、`input_manifest.md` または `deck_structure.md` に `## プレビュー承認記録` を追記する。

記録する項目:

- 承認日
- 承認者（ユーザー本人でよい）
- 承認対象（何枚目までのプレビューか）
- 修正条件（あれば）
- 残りスライド生成へ進んでよいか

この承認記録がない場合、残りスライド生成へ進まない。

### Step 9: 残りスライド生成

初回プレビュー承認後に残りを生成する。

サブエージェントが使える場合は、安定した `deck_structure.md` / `design_system.md` / `prompts/` を渡して並列生成する。

並列生成の境界:

- 1サブエージェントあたり1〜6枚程度
- 各サブエージェントは構成やデザインシステムを変更しない
- 生成物の命名、ヘッダー補正、最終検査はメイン側で行う

失敗時の戻し方:

- スタイルがズレたスライドだけ再生成する
- `deck_structure.md` と `design_system.md` は固定し、再生成時に勝手に変更しない
- 再生成では同じプロンプトをベースに、ズレた制約だけを強める
- 並列生成でばらつきが大きい場合は、残りを小さいバッチに分け直す
- 旧版は `image2-original/_rejected/` などに退避するか、ファイル名に `_v2` を付けて履歴を残す

### Step 10: ヘッダー補正

通常スライドが2枚以上ある場合は、`image2-fixed/` を作る。

`titles.json` は配列で作る。

```json
[
  {"file": "02-normal.png", "title": "プロジェクト概要"},
  {"file": "03-normal.png", "title": "解決したい課題"}
]
```

ページ番号は入れない。

ロゴあり:

```bash
python3 scripts/fix_title_logo.py \
  --input-dir <image2-original> \
  --output-dir <image2-fixed> \
  --logo <logo-path> \
  --titles <titles-json>
```

ロゴなし:

```bash
python3 scripts/fix_title_logo.py \
  --input-dir <image2-original> \
  --output-dir <image2-fixed> \
  --titles <titles-json> \
  --title-only
```

補正対象:

- 通常スライドの小タイトル
- 小タイトル下の短い下線
- ロゴがある場合は小ロゴ

補正してはいけないもの:

- 本文エリア
- 図表
- 本文テキスト
- ページ番号

### Step 11: HTMLデッキ生成

最終PNGを静的HTMLデッキへまとめる。これを標準の最終成果物にする。

採用するPNG:

- 通常スライドが2枚以上ある場合: 通常スライドは `image2-fixed/` から使う。
- 表紙など補正対象外のスライド: 最終採用した `image2-original/` または補正済みコピーから使う。
- ロゴなしでタイトルのみ補正した場合: タイトル補正済みのフォルダを使う。

HTML化の前に、閲覧用の最終PNGだけを1つのフォルダへ集約する。フォルダ名は原則 `final-slides/` または `export/html/slides/` とし、古い版や却下版を混ぜない。

標準コマンド:

```bash
python3 scripts/build_html_deck.py \
  --slides-dir <folder-with-final-slide-pngs> \
  --output-dir <deck-folder>/export/html \
  --title "<デッキ名>" \
  --titles <titles-json>
```

生成物:

- `export/html/index.html`: ブラウザで開くスライドデッキ
- `export/html/manifest.json`: スライド順・タイトル・形式の管理
- `export/html/slides/*.png`: HTMLが参照する最終PNG

HTMLデッキ要件:

- 相対パスだけで動く
- 外部CDN、外部フォント、外部JSに依存しない
- 16:9表示を維持する
- 左右キー、クリック、サムネイル一覧で移動できる
- ブラウザ印刷/PDF化に最低限耐える印刷CSSを持つ
- スライド本文をHTMLで再構成しない。HTMLは最終PNGを表示する器に徹する

### Step 12: 検査

各最終PNGを原寸で確認する。

最低限の検査:

- 各スライドが別ファイルか
- `message_design.md` が存在するか
- `export/html/index.html` が存在するか
- `export/html/slides/` に最終PNGだけが入っているか
- `manifest.json` の順序と画像ファイル名が合っているか
- HTMLをブラウザで開いたとき、最初のスライドが表示されるか
- 左右キーまたはクリックで移動できるか
- 目次/本日の流れが必要な資料でだけ入っているか。不要な資料で固定挿入されていないか
- ページ番号が表示されていないか
- タイトルに連番が混ざっていないか
- 通常スライドのタイトル/ロゴ位置が揃っているか
- ロゴなしモードでロゴを捏造していないか
- `message_design.md` に資料目的、想定読者、読後にしてほしい判断があるか
- `message_design.md` に `content_mode` があり、production / design_trial の扱いが分かるか
- `message_design.md` に各スライドの `reader_question` / `page_claim` / `evidence` / `evidence_status` / `layout_reason` があるか
- `evidence_status` が `missing` の主張を、事実や実績として断定していないか
- 入力情報が構成上どこかに割り当てられているか
- `deck_structure.md` に `slide_role` / `layout_archetype` / `emphasis_pattern` があるか
- `deck_structure.md` に `reader_question` / `page_claim` / `evidence_status` / `layout_reason` があるか
- `deck_structure.md` に `navigation_title` / `message_headline` / `supporting_message` / `visual_focus` / `emphasis_reason` があるか
- `deck_structure.md` に `logic_pattern` / `logic_purpose` / `primary_read` / `structure_notes` があるか
- `deck_structure.md` に `color_role` があり、何を主色、薄色、非強調色、アクセントにするか説明されているか
- 固定ヘッダーがページカテゴリを伝えているか
- 本文の大見出しがページの結論、判断、変化、課題、条件を伝えているか
- 課題整理、比較、工程、計画、判断条件のページが、論理構造ではなく雰囲気図だけになっていないか
- 項目数、章番号、補助ラベルが不自然に巨大化していないか
- 同じ `layout_archetype` が3枚以上連続していないか
- 3カラムカード、2x3グリッド、下部メッセージ帯が無意識に反復されていないか
- 多色化せず、主色の濃淡と非強調グレーで階層が作られているか
- アクセント色が推奨、注意、結論、差分以外に広がっていないか
- 各スライドの構図が、スライドの役割と合っているか
- 意味のない大きな円、泡、背景図形、チャート風の飾りがないか
- すべての図形、線、矢印、アイコンに意味があり、孤立した装飾になっていないか
- 接続線や矢印が本文、見出し、カード枠を横切っていないか
- アイコン/丸印と横のテキストが同じ視覚中心線に揃っているか
- 中央図形の下に置く矢印、ラベル、補助図形が親図形の中心と揃っているか
- 見出しブロックと補足文の左端/中央軸が意図どおり揃っているか
- 図形、線、チャート、アイコンが本文やラベルと重なっていないか
- 文字が読めるか
- 画像生成特有の誤字がないか
- デザインが過度に装飾的になっていないか

本文エリアに誤字・文字崩れ・意味崩れがある場合:

- ヘッダー補正スクリプトで直さない
- 該当スライドを再生成する
- 誤字が繰り返される場合は、本文量を減らす、表現を短くする、または分割する
- 人間が読めない文字が残る場合、そのスライドは未完成として報告する

### Step 13: 任意のPPTX化

PPTX化は主成果物ではない。必要な場合だけ、最終PNGを16:9の各スライドへ全面配置する。

初期判断:

- 画像貼り付けPPTXのみ対応する
- PPTX内の本文・図表を編集可能にすることはしない
- `pptxgenjs` が使える環境ならNodeで生成する
- `pptxgenjs` が未導入の場合は、依存追加の承認を取るか、PPTX化を未実施としてPNG群だけ渡す
- PPTX生成に失敗しても、HTMLデッキとPNG群が完成していれば標準成果物としては完了扱いにできる

将来拡張:

- ユーザーが「編集可能なPPTX」を明示的に求める場合のみ、`deck_structure.md`、`design_system.md`、承認済みPNGを参考に、別工程で編集可能PPTXへ再構成する
- この場合もImage2成果物をそのまま上書きせず、別成果物として扱う
- 画像生成で確認したデザイン方向を、PPTX側で完全再現できるとは限らないことを事前に説明する

### Step 14: 人間レビューと微調整

最終成果物を渡す前に、人間レビュー前提の確認レシートを出す。

確認項目:

- 伝えたいメッセージとズレていないか
- 社内/顧客向け資料として違和感がないか
- 表現が過度にカジュアル、装飾的、広告的になっていないか
- 読み手にとって修正したい点が特定しやすいか
- 再生成が必要なスライド番号が明確か

レビュー結果は、必要に応じて `review_notes.md` に残す。

---

## 既存Skillとの住み分け

`slide-craft` を使う条件:

- 編集可能なPPTXが必須
- Image2/画像生成が使えず、ユーザーが代替生成を承認した
- 既存PPTXのレビューやコード修正が主目的
- ユーザーが明示的に `slide-craft` を指定した

Image2が使えない場合は自動で `slide-craft` にフォールバックしない。まず止めて、以下を報告する。

- 画像生成ツールが使えない理由
- PNG生成なしで進める場合の品質差
- `slide-craft` / PPTXコード生成へ切り替えるかどうかの確認

---

## 品質チェック

必要に応じて `slide-quality-check` を使う。ただし現時点では、画像スライド固有の検査はこのSkillのStep 11を優先する。

将来的に `slide-quality-check` へ以下を追加する候補:

- 1画像1スライドか
- ページ番号がないか
- ロゴなしでロゴを捏造していないか
- `image2-fixed/` があるか
- 本文エリアをコード補正していないか
- 画像生成文字の誤字・崩れが残っていないか
