# Headline And Emphasis Guide

`deck_structure.md` と `prompts/` で、見出しの役割と強調サイズを決めるためのガイド。

目的は、見た目の大きさや雰囲気ではなく、読み手が「このページは何を伝えるページか」を先に理解できる状態を作ること。

---

## 基本思想

スライドには、役割の違う3つの言葉を持たせる。

```text
navigation_title:
message_headline:
supporting_message:
```

- `navigation_title`: ページのカテゴリ。短い名詞句で、どの話題かを示す。
- `message_headline`: そのページで読み手に持ち帰ってほしい結論、判断、変化。
- `supporting_message`: なぜそう言えるか、何を見るべきかを補足する1文。

通常スライドの固定ヘッダーに置くのは `navigation_title`。  
本文エリアで大きく扱うのは `message_headline`。  
図表や本文の前後に置く短い補足が `supporting_message`。

---

## navigation_title

ページの棚札。読者が一瞬で「これは何のページか」を把握するために使う。

良い例:

- 導入背景
- 現状課題
- レビュー負荷の構造
- PoC範囲
- 成功条件
- 判断材料
- 実績推移
- 投資の内訳
- 業務フロー
- 次アクション

避ける例:

- 長い文章
- 結論を全部入れたタイトル
- 「なぜ今か」だけの抽象タイトル
- 「重要なポイント」など中身が分からないタイトル
- ページ番号や章番号を含むタイトル

---

## message_headline

ページの主張。本文を読まなくても、何を言いたいページかが分かるようにする。

型:

- `変化`: 何が増えた/減った/戻った/停滞したか
- `判断`: 何を決めるべきか
- `課題`: 何が詰まりや負荷を生んでいるか
- `原因`: なぜそうなっているか
- `方針`: 何を優先するか
- `範囲`: 何をやり、何をやらないか
- `条件`: 何が満たされたら次へ進むか

良い例:

- レビュー待ちが差し戻し負荷を増やしている
- PoC前に判断基準を固定する
- AIの役割は承認ではなく観点の先出しに絞る
- 成功条件を先に置くほど評価のぶれを減らせる
- 初回PoCは安全計画と仮設計画に絞る

避ける例:

- 施工計画書レビューAIについて
- いきなりPoCへ進むと、成果物と判断基準が後追いになる
- 3つの判断材料
- 重要なこと
- 今後について

---

## supporting_message

`message_headline` を支える短い説明。詳細本文ではなく、図表の読み方を案内する。

良い例:

- 判断基準が後追いになると、検証後の評価がぶれる。
- 承認判断は人が行い、AIは抜け漏れ候補を先に出す。
- まず対象文書を絞り、レビュー観点の再現性を確認する。

避ける例:

- 長い本文をそのまま置く
- 見出しと同じことを繰り返す
- 図表と関係しない一般論

---

## 強調サイズのルール

大きくするものには理由が必要。

大きくしてよいもの:

- 成果を左右する数値
- 期限、金額、割合、件数
- 読者が判断するキーワード
- Before/After の差分
- そのページの結論語

大きくしすぎないもの:

- 項目数
- 章番号
- 補助ラベル
- ただの分類名
- 装飾目的の数字

`3つの判断材料` のような項目数は、本文理解を助ける程度に扱う。KPIのように巨大化しない。

---

## deck_structure.md に残す項目

各スライドに以下を持たせる。

```text
navigation_title:
message_headline:
supporting_message:
visual_focus:
emphasis_reason:
```

- `visual_focus`: 何を視覚的な中心にするか。例: 1つのKPI、比較表、工程線、関係図。
- `emphasis_reason`: なぜそれを大きくするか。理由が言えない場合は大きくしない。

---

## プロンプトへ渡す短文例

```text
Navigation title: 導入背景.
Message headline: レビュー待ちが差し戻し負荷を増やしている.
Supporting message: 繁忙期ほど確認待ちが増え、レビュー観点の抜け漏れも起きやすい.
Visual focus: a simple bottleneck diagram, not a large decorative number.
Emphasis reason: emphasize the bottleneck because it explains why AI support is needed now.
```

```text
Navigation title: 成功条件.
Message headline: PoC前に判断基準を固定する.
Supporting message: 検証後に基準を決めると、成果評価が主観に寄りやすい.
Visual focus: three labeled criteria rows.
Emphasis reason: criteria labels are important, but the number of criteria is not the main metric.
```
