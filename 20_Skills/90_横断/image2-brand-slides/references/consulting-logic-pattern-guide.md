# Consulting Logic Pattern Guide

DX/AIコンサル資料で、見た目の雰囲気だけでなく論理骨格を作るためのガイド。

目的は、参照資料の見た目をコピーせず、情報の置き方をコンサル資料として成立させること。  
色や余白は資料テーマへ翻訳するが、課題整理、施策比較、プロセス設計、PoC計画では、論理構造を曖昧な図解にしない。

---

## 基本思想

デザインは3層で考える。

```text
visual_style: 生成り、テーマ由来の主色、細線、線画、静かな余白
logic_pattern: issue tree, matrix, process, swimlane, workplan, decision table
color_hierarchy: main color shades, neutral gray, small accent
```

失敗例:

- 見た目だけ静かで、何を比較・判断・実行するページか分からない
- 大きな見出しとアイコンだけで、分析や構造が薄い
- すべてをカードや抽象図にしてしまい、論点の関係が見えない
- コンサル資料なのに、ポスターやLPのような密度になる

成功例:

- 見出しでページの論点が分かる
- 図表で原因、選択肢、施策、工程、判断軸の関係が分かる
- 強調色は結論、推奨、重要経路、差分にだけ使う
- 要素は少なくても、論理の接続が見える

---

## 必ず決める項目

各スライドに以下を持たせる。

```text
logic_pattern:
logic_purpose:
primary_read:
structure_notes:
```

- `logic_pattern`: 論理構造の型。
- `logic_purpose`: 何を理解・判断させるための型か。
- `primary_read`: 読者が最初に読むべきもの。
- `structure_notes`: 列、行、矢印、階層、強調対象の設計メモ。

---

## 主要パターン

### logic_tree

論点、原因、打ち手、必要能力などを階層で分解する。  
「大きな論点を分解したい」「何が構成要素かを見せたい」ときに使う。

向いているページ:

- 論点整理
- 課題の全体像
- 必要機能/必要能力の分解
- 提案範囲の構造化

構造:

- 左または上: 親論点
- 右または下: 子論点
- 末端: 具体項目、確認観点、対応候補

注意:

- 分解軸を混ぜない。
- 末端の数を増やしすぎない。
- 強調したい枝だけを主色で示し、その他は低彩度にする。

### issue_emphasis_tree

ロジックツリーや分類表の中で、どこが問題箇所かを強調する。  
「課題の全体像は広いが、今回扱う問題は一部」と示すときに使う。

向いているページ:

- 現状課題
- 問題箇所の特定
- 対象範囲の絞り込み
- 優先論点の提示

構造:

- 全体ツリーまたは分類表
- 問題箇所だけを主色の薄面、囲み、線で強調
- 下部または右側に、なぜそこが重要かの短い読み取り

注意:

- 全項目を同じ強さで塗らない。
- 強調の理由を見出しまたは注釈で説明する。

### proposal_logic_tree

前提、制約、選択肢、推奨案を分岐で整理する。  
「なぜその提案になるのか」を、結論だけでなく判断経路として見せるときに使う。

向いているページ:

- 提案方針
- 対応方向性
- 実施範囲の決定
- 推奨案の理由説明

構造:

- 左: 前提/制約
- 中央: 判断分岐または選択肢
- 右: 推奨案/今後の対応
- 強調: 採用経路、除外理由、次アクション

注意:

- 単なる樹形図にせず、推奨に至る読み順を作る。
- 採用しない選択肢はグレーへ退かせる。

### issue_solution_tree

課題と解決策の対応を見せる。  
「課題が複数ある」「どの施策がどの課題に効くか」を整理するときに使う。

向いているページ:

- 現状課題
- 課題と解決策
- 施策候補整理
- AIが担う範囲/担わない範囲

構造:

- 左: 課題カテゴリ
- 中央: 課題詳細または原因
- 右: 解決策/対応方針
- 接続線: どの課題がどの施策に接続するか

注意:

- 接続線を飾りにしない。
- 課題と施策が1対1でない場合は、分岐や合流を明示する。

### recommendation_matrix

複数の選択肢を評価軸で比べ、推奨案を示す。

向いているページ:

- PoC対象範囲の比較
- ツール/方式/対象業務の比較
- 優先順位付け
- やる/やらないの線引き

構造:

- 行: 選択肢
- 列: 評価軸
- 右端または上部: 推奨/判断
- 強調: 推奨案、重要な差分、リスク

注意:

- 評価軸が曖昧なら使わない。
- ただの3カードにしない。比較の軸を見せる。

### process_swimlane

工程、関係者、入力、処理、アウトプットを一気通貫で見せる。

向いているページ:

- PoCの進め方
- 業務フロー
- 導入プロセス
- 役割分担
- レビュー業務の流れ

構造:

- 横: 時間/工程
- 縦: レーン（入力、作業、関係者、アウトプットなど）
- 各セル: 具体的な作業や成果物

注意:

- 装飾的な矢印列だけにしない。
- 誰が何を出し、次に何へつながるかを見せる。

### flow_type

少数ステップを、入力、プロセス、アウトプット、判断軸つきで説明する。  
「全体の進め方はシンプルだが、各工程の意味を揃えて見せたい」ときに使う。

向いているページ:

- 導入ステップ
- 検証の進め方
- 会議/ワークショップの流れ
- 初回ヒアリングから成果物までの流れ

構造:

- 横: 3〜5ステップ
- 各ステップ: 目的、入力、作業、出力のいずれかを短く記載
- 下段: 判断軸、成果物、次アクション

注意:

- 矢印だけの装飾にしない。
- 1ステップ内の文字量を増やしすぎない。
- 重要ステップだけを主色で強調し、他は薄色かグレーにする。

### workplan_roadmap

期間、タスク、成果物、判定ポイントを整理する。

向いているページ:

- PoC計画
- 実行スケジュール
- 検証ロードマップ
- 次アクション

構造:

- 横: 週/月/フェーズ
- 行: タスク、成果物、判断、会議体
- マーカー: 判定ポイント、レビュー、Go/No-Go

注意:

- 期限や判定ポイントがない場合は、単なる流れ図にしない。

### evidence_exhibit

根拠を1枚の展示物として見せる。

向いているページ:

- 実績
- 検証結果
- 調査結果
- before/after数値

構造:

- 上: 結論見出し
- 中央: グラフ/表/数値
- 右または下: 読み取りポイント

注意:

- 実データがないなら、チャート風にしない。
- 大きな数字はKPI、金額、期限、件数など意味のある数値だけ。

### decision_table

成功条件、判断基準、範囲、リスクなどを表で明確にする。

向いているページ:

- 成功条件
- AIがしないこと
- 対象範囲
- レビュー観点
- Go/No-Go条件

構造:

- 行: 判断項目
- 列: 基準、確認方法、責任者、次アクション
- 強調: 必須条件、除外条件、未決事項

注意:

- 項目数を大きく見せない。
- 何を判断する表かを見出しで明示する。

### implication_grid

論点ごとに「意味合い」と「対応」を整理する。

向いているページ:

- 今後の方向性
- 課題別対応
- リスク別打ち手
- ステークホルダー別メッセージ

構造:

- 左: 論点/課題
- 中: 意味合い
- 右: 対応/アクション

注意:

- 方向性と対応を混ぜない。
- 左から右に読める因果を作る。

---

## 選び方

| 伝えたいこと | logic_pattern |
|---|---|
| 論点や構成要素の分解 | logic_tree |
| 課題箇所の強調 | issue_emphasis_tree |
| 前提から推奨案への接続 | proposal_logic_tree |
| 課題と解決策の対応 | issue_solution_tree |
| 選択肢の比較と推奨 | recommendation_matrix |
| 業務やPoCの流れ | process_swimlane |
| 少数工程の説明 | flow_type |
| 期間と実行計画 | workplan_roadmap |
| 数値や実績の根拠 | evidence_exhibit |
| 成功条件や判断基準 | decision_table |
| 論点別の意味合いと対応 | implication_grid |

---

## Image2プロンプトでの指定例

```text
Logic pattern: issue_emphasis_tree.
Logic purpose: show which part of the current review process creates the biggest bottleneck.
Primary read: the reader should first see the whole issue tree, then the highlighted problem branch.
Structure notes: keep non-priority branches in neutral gray; use a pale main-color surface and thin main-color outline only for the priority branch.
```

```text
Logic pattern: proposal_logic_tree.
Logic purpose: explain why the recommended PoC scope follows from the constraints.
Primary read: the reader should follow the selected path from premise to recommendation.
Structure notes: left side for constraints, center for decision branches, right side for recommended action; gray out rejected paths and use accent only on the final recommendation label.
```

```text
Logic pattern: flow_type.
Logic purpose: show a short process from input to output with decision criteria.
Primary read: the reader should understand the five steps first, then the decision axis underneath.
Structure notes: use three to five horizontal steps; each step has a short input/process/output label; place a compact judgment axis in the lower row.
```

```text
Logic pattern: issue_solution_tree.
Logic purpose: show which review-work problems AI support should address.
Primary read: the reader should first see the four problem categories, then how they connect to the AI support scope.
Structure notes: left column for problem categories, center for causes/details, right column for support actions; use thin connector lines only where there is a real relationship.
```

```text
Logic pattern: decision_table.
Logic purpose: make PoC success conditions explicit before execution.
Primary read: the reader should first understand the decision criteria, not the number of criteria.
Structure notes: four horizontal rows with columns for criterion, what to check, and Go/No-Go signal. Do not use a large item-count number.
```

```text
Logic pattern: process_swimlane.
Logic purpose: show how inputs become review outputs across project phases.
Primary read: the reader should see inputs, review work, and outputs as separate lanes.
Structure notes: use three to four phases horizontally and three lanes vertically; keep icons small and labels clear.
```
