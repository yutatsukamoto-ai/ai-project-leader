# Message Design Gate

スライドを見た目から作り始めず、先に「何を伝えるか」を固定するためのゲート。

このゲートの目的は、原稿が曖昧なままImage2へ進み、見た目は整っているが主張や根拠が弱いスライドになることを防ぐこと。

---

## 基本思想

良いスライドは、デザインの前に意味が決まっている。

- 誰に見せるか
- 読後に何を理解、判断、合意してほしいか
- 各ページで何を言い切るか
- その主張を支える事実、数字、事例、前提は何か
- 入力にない情報を勝手に補っていないか

これが弱い場合、レイアウトや配色を整えても資料は強くならない。  
意味が整っているほど、レイアウトは自然に決まる。

---

## `message_design.md` の必須項目

```text
# message_design

## 資料目的

## 想定読者

## 読後にしてほしい判断・行動

## content_mode
- production / design_trial

## 入力原稿の成立度
- 十分に書かれていること:
- 不足していること:
- 推測で補ってはいけないこと:

## スライド別メッセージ設計

### 01. <仮タイトル>
- slide_role:
- reader_question: 読者がこのページで解きたい問い
- page_claim: このページで言い切る主張
- evidence: 主張を支える事実、数字、事例、引用、原稿箇所
- evidence_status: fact / provided_assumption / inferred / missing
- missing_detail: 足りない数字、固有名詞、条件、比較対象
- layout_reason: なぜその論理構造・レイアウトが合うか
- source_notes: 元原稿のどの部分を使うか

## 確認が必要な点

## 生成へ進む判断
- proceed / proceed_as_draft / stop_for_clarification
```

---

## 原稿品質チェック

`message_design.md` 作成時に確認する。

OK:

- 原稿だけを読んで、資料の目的と読者が分かる
- 各スライド候補に、1つの主張がある
- 主張と根拠が対応している
- 数字、期限、金額、件数、固有名詞などがある場合、どのページで使うか決まっている
- 数字がない場合、数字なしでも言い切れる主張へ落としている
- 推測、仮説、例示、事実が分かれている
- 入力にない情報を盛っていない

NG:

- 「〜について」「重要なポイント」「今後について」だけで、何を言うページか分からない
- ページ主張が、原稿の要約や章タイトルに留まっている
- 根拠がないのに断定している
- 実データがないのに、数値や効果を捏造している
- 1枚に複数の判断や論点を詰め込んでいる
- デザイン差分を作るためだけに、意味のない図や構図を選んでいる

---

## production と design_trial

`content_mode` を必ず分ける。

`production`:

- 客先提出、社内意思決定、提案、報告など、内容の正確性が成果に影響する資料
- 原稿にない数字、効果、固有情報を補わない
- 根拠が弱い主張は断定しない
- 足りない情報は `確認が必要な点` に出し、必要なら止める

`design_trial`:

- デザイン方向、Image2生成品質、レイアウト差分を確認するための仮試作
- 題材や主張が仮置きであることを `review_notes.md` に残す
- 見た目が良くても、内容を本番提案の根拠として扱わない
- 本番化する前に、`production` として `message_design.md` を作り直す

---

## 止める条件

以下に該当する場合は、スライド生成へ進まず確認する。

- 資料目的、想定読者、読後の判断が不明
- 主要スライドの `page_claim` が置けない
- 根拠がないのに、成果、効果、課題の深刻度を断定する必要がある
- ユーザー確認なしに補うと、事実誤認や過大表現になりそうな数字、範囲、固有名詞がある
- 提案資料、客先提出資料、意思決定資料なのに、事実/仮説/推測の境界が曖昧

ただし、ユーザーが「デザイン検証」「仮題材で試作」と明示した場合は、`proceed_as_draft` として進めてよい。その場合は、内容が仮置きであることを `review_notes.md` に残す。

---

## 意味からレイアウトを決める

`page_claim` と `reader_question` を先に決め、その後に `logic_pattern` と `layout_archetype` を選ぶ。

| 伝えたい意味 | 向く論理構造 | 向くレイアウト |
|---|---|---|
| 課題の深刻さや詰まりを伝える | issue_emphasis_tree / evidence_exhibit | logic_exhibit / evidence_board |
| 課題と打ち手の対応を見せる | issue_solution_tree / proposal_logic_tree | logic_exhibit / before_after |
| 意思決定材料を並べる | decision_table / recommendation_matrix | logic_exhibit / evidence_board |
| 進め方や検証手順を見せる | flow_type / process_swimlane | process_flow / logic_exhibit |
| 入力、処理、出力、判断軸を固定する | flow_type | logic_exhibit / process_flow |
| 数字や実績で納得させる | evidence_exhibit / implication_grid | evidence_board / focus_metric |
| 方針や原則を印象づける | none / implication_grid | editorial_statement / summary_rows |
| 読者に考えさせる | question / decision_table | workshop_canvas / checklist_path |

---

## `deck_structure.md` への受け渡し

`deck_structure.md` では、`message_design.md` の内容を次の項目へ写す。

- `reader_question`
- `page_claim`
- `evidence`
- `evidence_status`
- `missing_detail`
- `layout_reason`

`navigation_title` はページカテゴリ、`message_headline` は `page_claim` を読者向けに短く言い換えたものにする。  
`logic_pattern` と `layout_archetype` は `layout_reason` に基づいて決める。
