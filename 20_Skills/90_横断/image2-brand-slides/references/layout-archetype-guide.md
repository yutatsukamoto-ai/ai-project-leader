# Layout Archetype Guide

`deck_structure.md` と `prompts/` の間で、各スライドの役割・構図・強調方法を決めるためのガイド。

目的は、ブランド色や余白だけを変えた同型スライドの量産を防ぎ、資料テーマごとに見せ方を翻訳すること。
ただし、構図の差分は装飾目的で作らない。ページの主張、読者の問い、根拠の見せ方から選ぶ。

---

## 使うタイミング

- `deck_structure.md` を作るとき
- `design_system.md` を作ったあと、スライド別プロンプトへ進む前
- 初回プレビューの3〜5枚で、構図の差分を意図的に見せたいとき
- ユーザーが「同じようなレイアウトばかり」を避けたいと言ったとき

---

## 必ず決める3項目

各スライドに以下を付ける。

```text
navigation_title:
message_headline:
reader_question:
page_claim:
evidence_status:
layout_reason:
visual_focus:
emphasis_reason:
logic_pattern:
slide_role:
layout_archetype:
emphasis_pattern:
```

### slide_role

スライドの仕事。

- `title`: 表紙。資料の世界観と主張を示す
- `agenda`: 流れ、章立て、今日扱うことを示す
- `problem`: 課題、違和感、なぜ今かを示す
- `comparison`: Before/After、選択肢、従来/新案を比べる
- `process`: 手順、進め方、PoCステップを示す
- `evidence`: 数値、グラフ、検証結果、根拠を示す
- `concept`: 考え方、原則、モデルを示す
- `proposal`: 提案内容、解決策、導入範囲を示す
- `summary`: まとめ、判断軸、次アクションを示す
- `workshop`: 問い、演習、記入欄、対話を促す

### layout_archetype

画面構図の型。

- `editorial_statement`: 大見出し + 余白 + 意味のある小さな抽象図。思想整理、表紙、結論提示
- `split_visual`: 左に主張、右に図版/人物/画面。サービス紹介、提案、導入説明
- `before_after`: 左右比較、中央矢印。現状/あるべき姿、従来/新案
- `process_flow`: 横/縦のステップ。手順、流れ、PoC計画
- `evidence_board`: 数値、グラフ、比較、KPI。効果検証、実績、根拠
- `logic_exhibit`: issue tree、matrix、swimlane、decision tableなどの論理骨格を主役にする。DX/AIコンサル資料の課題整理、施策比較、計画
- `checklist_path`: チェック項目 + 進行線。注意事項、品質条件、成功条件
- `story_strip`: 写真/イラスト/場面を連続で見せる。採用、会社紹介、利用シーン
- `civic_landscape`: 街並み、俯瞰図、関係者配置。公共、地域、構想、エコシステム
- `workshop_canvas`: 問い、余白、記入欄、対話の往復。研修、講義、ワークショップ
- `summary_rows`: アイコン付き横行の要約。まとめ、原則、チェックリスト
- `focus_metric`: 1つの大きな数字や指標。実績、インパクト、KPI
- `system_map`: 要素と接続関係。業務フロー、システム構成、役割分担

### emphasis_pattern

何で印象を作るか。

- `statement`: 大きな主張文
- `contrast`: 対比、差分、Before/After
- `sequence`: 順序、ステップ、時間軸
- `proof`: 数字、根拠、グラフ
- `question`: 問い、内省、議論の入口
- `decision_axis`: 判断軸、やる/やらない、範囲線引き
- `checklist`: 確認項目、条件、禁止事項
- `scene`: 利用シーン、人物、状況
- `relationship`: 関係者、つながり、役割

---

## 選び方

1. まず `slide_role` を決める。
2. `reader_question` で、読者がこのページで解きたい問いを決める。
3. `page_claim` で、そのページが言い切る主張を決める。
4. `evidence_status` で、主張の根拠が事実、入力上の前提、推測、欠落のどれかを決める。
5. `navigation_title` でページカテゴリを短く決める。
6. `message_headline` で `page_claim` を読者向けに短く言う。
7. `visual_focus` と `emphasis_reason` を決める。
8. そのスライドで読み手に起こしたい認知を決める。
9. 認知に合う `emphasis_pattern` を選ぶ。
10. 最後に `layout_archetype` を選び、`layout_reason` に理由を残す。

例:

| slide_role | 読み手に起こしたい認知 | emphasis_pattern | layout_archetype |
|---|---|---|---|
| problem | なぜ今やるべきか腹落ちする | contrast | before_after |
| process | 進め方を一目で追える | sequence | process_flow |
| evidence | 効果が数字で分かる | proof | evidence_board |
| proposal | 課題と施策の対応が分かる | relationship | logic_exhibit |
| process | 入力、作業、成果物の流れが分かる | sequence | logic_exhibit |
| workshop | 自分で考え始める | question | workshop_canvas |
| summary | 次に何を判断するか分かる | decision_axis | summary_rows |

意味から選ぶ例:

| page_claimの性質 | 避けたい選び方 | 選びたい型 |
|---|---|---|
| 課題の深刻さを示す | きれいな3カードに分けるだけ | issue_emphasis_tree / evidence_board |
| 意思決定材料を示す | 大きな数字やアイコンを飾る | decision_table / recommendation_matrix |
| PoCの進め方を示す | 抽象図形を並べる | flow_type / process_swimlane |
| 提案の妥当性を示す | 世界観イラストだけで押す | issue_solution_tree / proposal_logic_tree |

---

## 連続使用の制限

- 同じ `layout_archetype` を3枚以上連続で使わない。
- `three-column cards` は `comparison` または `summary` が主目的のときだけ使う。
- `agenda` 以外で2x3グリッドに逃げない。
- `bottom message band` を全ページ固定にしない。使う場合は判断軸や問いが必要なページに絞る。
- `logic_exhibit` のページを、単なるアイコン付きカードや大見出しだけにしない。行、列、矢印、レーン、表などで論理関係を見せる。
- 意味のない大きな円、泡、背景図形を置かない。抽象図形を使う場合は、構造、関係、順序、分類などの意味を持たせる。
- チャート風の線や棒は、実データや明確な概念図でない限り使わない。使う場合も本文やラベルと重ねない。
- 左上タイトル + 大見出し + 中央図解 + 下部帯だけを標準形として固定しない。
- カード、角丸、薄影、左アクセントバーを「整って見せるため」だけに使わない。

---

## サムネイル方向性ボード

ユーザーがデザイン差分を確認したい場合、またはテーマが曖昧な場合は、完成物の前に `visual_direction_board.md` を作ってよい。

目的:

- 細かい本文の正確性ではなく、全体トーン、余白、レイアウト、強調方法を見る。
- 3〜6案程度の方向性を並べて、どのレイアウト型を採用するか確認する。

注意:

- 方向性ボードは完成物ではない。
- 方向性ボードを作っても、最終成果物は1スライド1画像で作る。
- 方向性ボードで選んだ型を、`deck_structure.md` の `layout_archetype` に反映する。

---

## プロンプトへ渡す短文例

```text
Slide role: problem.
Layout archetype: before_after.
Emphasis pattern: contrast.
Do not use a generic three-card layout. Show the difference between current review work and AI-supported review as a clear before/after composition.
```

```text
Slide role: workshop.
Layout archetype: workshop_canvas.
Emphasis pattern: question.
Use large questions, quiet writing space, and dialogue marks. Do not reuse the previous process-flow layout.
```

```text
Slide role: evidence.
Layout archetype: evidence_board.
Emphasis pattern: proof.
Use one large metric, one small trend chart, and two supporting facts. Avoid dense dashboard styling.
```
