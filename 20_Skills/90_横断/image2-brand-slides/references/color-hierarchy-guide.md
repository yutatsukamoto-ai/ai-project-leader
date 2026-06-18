# Color Hierarchy Guide

多色でそれっぽく整えるのではなく、少ない色数と濃淡で情報の重要度を伝えるためのガイド。

---

## 基本思想

色は「ブランドらしさ」だけでなく、読み順と判断軸を作るために使う。

```text
base_background: 真っ白ではない生成り、アイボリー、薄く色づいた白
main_color: 資料テーマを代表する1色
main_dark: 見出し、重要線、主要アイコン、結論
main_mid: 図解の主部品、強調枠、選択中の項目
main_light: 背景面、薄いセル、補助ブロック
accent_color: 1色だけ。推奨、注意、結論、差分に限定
neutral: 本文、罫線、非強調データ、過去値、比較対象
```

Rettyのような資料から抽象化すると、近い白背景に対して、主色を「濃い見出し・強い棒・薄い塗り」に分解し、比較対象はグレーへ退かせる。色数を増やすのではなく、主色の強弱で階層を作る。オレンジそのものを固定で使うのではなく、この階層設計を案件ごとの主色へ翻訳する。

---

## 推奨比率

- `base_background`: 60〜75%
- `neutral`: 15〜25%
- `main_color` 系: 8〜15%
- `accent_color`: 1〜5%

アクセントは主色では表しきれない「推奨」「注意」「決定」「差分」だけに使う。アクセントが複数箇所に広がると、どこを読むべきか分からなくなる。

---

## テーマ別の翻訳例

主色は資料テーマとブランドアンカーから選ぶ。深緑やオレンジは候補であり、固定デフォルトではない。

八束電工 / 施工計画書レビューAIのような静かな提案資料:

```text
base_background: #F8F6EF / #FBFAF5
main_dark: #0E4334 / #174D3A
main_mid: muted sage green
main_light: #DDE6DB / #E8EFE7
accent_color: #B88416 / #C6921E
neutral: charcoal text, warm gray lines
```

オレンジ系の事業資料:

```text
base_background: near-white / warm white
main_dark: strong orange for current, recommended, key title marks
main_mid: orange bars, selected states, active labels
main_light: pale orange cells and callout backgrounds
accent_color: use only if orange cannot represent warning or contrast
neutral: gray for past, baseline, non-selected options
```

---

## OK / NG

OK:

- 比較表で、推奨案だけを `main_mid`、その他を `neutral` にする
- 棒グラフで、当期や重要値だけを `main_dark`、過去値を `neutral` にする
- 課題ツリーで、問題箇所だけを `main_light` の面と `main_dark` の線で強調する
- 下部メッセージのキーワードだけを `accent_color` にする

NG:

- 要素ごとに別々の色を割り当てる
- 3色以上を同じ強さで使う
- 明るいブランドカラーを全面に敷く
- アクセント色を全スライドで多用する
- 真っ白背景をデフォルトにする
- 意味のない円、泡、線、チャート風装飾に色を使う

---

## deck_structure / prompt で指定すること

各スライドに `color_role` を持たせる。

```text
color_role:
  base_background:
  main_dark:
  main_mid:
  main_light:
  accent_color:
  neutral:
  highlight_rule:
```

`highlight_rule` には、「何を主色で強調し、何をグレーへ退かせ、アクセントをどこだけに使うか」を短く書く。
