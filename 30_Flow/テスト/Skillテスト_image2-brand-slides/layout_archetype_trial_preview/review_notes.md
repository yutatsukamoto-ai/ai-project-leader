# review_notes

## 目的

`image2-brand-slides` の新標準で追加した `slide_role` / `layout_archetype` / `emphasis_pattern` が、色やモチーフだけでなくレイアウト差分を作れるかを確認するための試作。

## 注意

- この5枚は、Image2本番生成ではなく、標準デザイン思想と構図差分を見比べるためのローカル描画プレビュー。
- 完成品質の提出物ではなく、次のImage2生成プロンプトを改善するための検証素材。

## 試した構図

| slide | title | slide_role | layout_archetype | emphasis_pattern |
|---:|---|---|---|---|
| 1 | AIプロジェクト推進の型 | title | editorial_statement | statement |
| 2 | 失敗しやすい進め方 | problem | before_after | contrast |
| 3 | 進め方は5つの工程に分ける | process | process_flow | sequence |
| 4 | 判断材料を先に揃える | evidence | evidence_board | proof |
| 5 | 最後に残すもの | summary | summary_rows | decision_axis |

## 確認結果

- 5枚すべて 1920x1080 の16:9。
- HTMLデッキを生成済み。
- Quick Lookで先頭表示サムネイルを生成済み。
- Skillビルドと回帰evalは通過。

## 次に見るべき点

- 「この程度の構図差分で十分か」
- もっと攻めた方向性候補を `visual_direction_board.md` に増やすべきか
- 本番Image2生成では、各プロンプトに `layout_archetype` と `emphasis_pattern` を明示し、同型反復を避ける
