# PMBOK第8版 40プロセス一覧

> **★ 本プロジェクトのPMBOKプロセス語彙の正典（SSOT）★**（2026-06-13確定 / 懸念M-02対応）
> プロセス名・番号・ドメイン名は**この表を唯一の正**とする。Skill・成果物マップ・PM成果物がプロセスを参照するときは、必ず本表の**番号 #1〜40 と表記**に紐づける。
> 書籍『プロジェクトリーダーの仕事』p52-53由来の別表記（再構成版 `40_Stock/ナレッジ/PMBOK第8版_40プロセスと7領域.md`）は、本表への**対照表として降格**済み。語彙が食い違ったら常に本表が優先。
> ドメイン名の正: **資源**（×リソース）／**ファイナンス**。

【この文書について】
PMBOK® Guide 第8版（2025年11月 PMI発行）の40プロセスを、
7パフォーマンスドメイン × 5フォーカスエリアでマッピングした一覧表。
Skillチェーン設計（フェーズ×ドメインの可視化）の土台として使う。

【注意】
日本語訳は参考訳（第8版日本語版の公式訳が未確認のため）。
ITTOは第8版では「例示であり網羅ではない（illustrative, not comprehensive）」と位置づけられている。
作成日: 2026-06-12

---

## 全体構造

【グリッドの読み方】
縦軸 = 7パフォーマンスドメイン（何の仕事か / 旧・知識エリアの後継）
横軸 = 5フォーカスエリア（ライフサイクルのどこか / 旧・プロセス群の改称）

| ドメイン | 計 | 立ち上げ | 計画 | 実行 | 監視・コントロール | 終結 |
|---|---|---|---|---|---|---|
| ガバナンス | 9 | 1 | 2 | 3 | 2 | 1 |
| スコープ | 6 | - | 4 | - | 2 | - |
| スケジュール | 3 | - | 2 | - | 1 | - |
| ファイナンス | 4 | - | 3 | - | 1 | - |
| ステークホルダー | 7 | 1 | 2 | 2 | 2 | - |
| 資源 | 5 | - | 2 | 2 | 1 | - |
| リスク | 6 | - | 4 | 1 | 1 | - |
| **合計** | **40** | **2** | **19** | **8** | **10** | **1** |

---

## 1. ガバナンス（Governance）ドメイン — 9プロセス

旧・統合マネジメントの後継。品質保証・調達戦略・終結も吸収した最大ドメイン。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 1 | Initiate Project or Phase | プロジェクトまたはフェーズの立ち上げ | 立ち上げ | 旧 Develop Project Charter を改称・拡張 |
| 2 | Integrate and Align Project Plans | プロジェクト計画の統合と整合 | 計画 | 旧 Develop Project Management Plan を改称 |
| 3 | Plan Sourcing Strategy | ソーシング戦略の計画 | 計画 | 旧 Plan Procurement Management を改称・移動（調達詳細は付録X4へ） |
| 4 | Manage Project Execution | プロジェクト実行のマネジメント | 実行 | 旧 Direct and Manage Project Work を改称 |
| 5 | Manage Project Knowledge | プロジェクト知識のマネジメント | 実行 | 維持 |
| 6 | Manage Quality Assurance | 品質保証のマネジメント | 実行 | 旧 Manage Quality を改称（QC要素はスコープ側へ） |
| 7 | Monitor and Control Project Performance | プロジェクトパフォーマンスの監視・コントロール | 監視・コントロール | 旧 Monitor and Control Project Work を改称 |
| 8 | Assess and Implement Changes | 変更の評価と実装 | 監視・コントロール | 旧 Perform Integrated Change Control を改称 |
| 9 | Close Project or Phase | プロジェクトまたはフェーズの終結 | 終結 | 維持 |

## 2. スコープ（Scope）ドメイン — 6プロセス

旧・スコープマネジメントの後継。スコープレベルの品質も担う。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 10 | Plan Scope Management | スコープマネジメントの計画 | 計画 | 維持 |
| 11 | Elicit and Analyze Requirements | 要求事項の引き出しと分析 | 計画 | 旧 Collect Requirements を改称（能動的な引き出しを強調） |
| 12 | Define Scope | スコープの定義 | 計画 | 維持 |
| 13 | Develop Scope Structure | スコープ構造の作成 | 計画 | 旧 Create WBS を改称（アダプティブ対応で広義化） |
| 14 | Validate Scope | スコープの妥当性確認 | 監視・コントロール | 維持 |
| 15 | Monitor and Control Scope | スコープの監視・コントロール | 監視・コントロール | 旧 Control Scope を改称（旧 Control Quality の一部を吸収） |

## 3. スケジュール（Schedule）ドメイン — 3プロセス

旧・スケジュールマネジメントの後継。4プロセスが1つに統合され最小ドメインに。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 16 | Plan Schedule Management | スケジュールマネジメントの計画 | 計画 | 維持 |
| 17 | Develop Schedule | スケジュールの作成 | 計画 | 旧 Define Activities / Sequence Activities / Estimate Activity Durations / Develop Schedule の4つを統合 |
| 18 | Monitor and Control Schedule | スケジュールの監視・コントロール | 監視・コントロール | 旧 Control Schedule を改称 |

## 4. ファイナンス（Finance）ドメイン — 4プロセス

旧・コストマネジメントの後継。「コスト」から「財務」へ広義化。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 19 | Plan Financial Management | 財務マネジメントの計画 | 計画 | 旧 Plan Cost Management を改称・広義化 |
| 20 | Estimate Costs | コストの見積り | 計画 | 維持 |
| 21 | Develop Budget | 予算の作成 | 計画 | 旧 Determine Budget を改称 |
| 22 | Monitor and Control Finances | 財務の監視・コントロール | 監視・コントロール | 旧 Control Costs を改称（EVMはここ） |

## 5. ステークホルダー（Stakeholders）ドメイン — 7プロセス

旧・ステークホルダー＋コミュニケーションの2知識エリアを統合。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 23 | Identify Stakeholders | ステークホルダーの特定 | 立ち上げ | 維持 |
| 24 | Plan Stakeholder Engagement | ステークホルダーエンゲージメントの計画 | 計画 | 維持 |
| 25 | Plan Communications Management | コミュニケーションマネジメントの計画 | 計画 | 維持（コミュニケーション知識エリアから移動） |
| 26 | Manage Stakeholder Engagement | ステークホルダーエンゲージメントのマネジメント | 実行 | 維持 |
| 27 | Manage Communications | コミュニケーションのマネジメント | 実行 | 維持（同上の移動） |
| 28 | Monitor Stakeholder Engagement | ステークホルダーエンゲージメントの監視 | 監視・コントロール | 維持 |
| 29 | Monitor Communications | コミュニケーションの監視 | 監視・コントロール | 維持（同上の移動） |

## 6. 資源（Resources）ドメイン — 5プロセス

旧・資源マネジメントの後継。チーム2プロセスが Lead the Team に統合。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 30 | Plan Resource Management | 資源マネジメントの計画 | 計画 | 維持 |
| 31 | Estimate Resources | 資源の見積り | 計画 | 旧 Estimate Activity Resources を簡略化 |
| 32 | Acquire Resources | 資源の獲得 | 実行 | 維持 |
| 33 | Lead the Team | チームをリードする | 実行 | 旧 Develop Team ＋ Manage Team を統合 |
| 34 | Monitor and Control Resourcing | リソーシングの監視・コントロール | 監視・コントロール | 旧 Control Resources を改称 |

## 7. リスク（Risk）ドメイン — 6プロセス

旧・リスクマネジメントの後継。定性・定量分析が1つに統合。

| # | プロセス（英語） | 参考訳 | フォーカスエリア | 第6版からの変更 |
|---|---|---|---|---|
| 35 | Plan Risk Management | リスクマネジメントの計画 | 計画 | 維持 |
| 36 | Identify Risks | リスクの特定 | 計画 | 維持 |
| 37 | Perform Risk Analysis | リスク分析 | 計画 | 旧 Perform Qualitative ＋ Quantitative Risk Analysis を統合 |
| 38 | Plan Risk Responses | リスク対応の計画 | 計画 | 維持 |
| 39 | Implement Risk Responses | リスク対応策の実行 | 実行 | 維持 |
| 40 | Monitor Risks | リスクの監視 | 監視・コントロール | 維持 |

---

## 第6版（49プロセス）から消えたもの

【統合（9→4）】
スケジュール4つ → Develop Schedule
リスク分析2つ → Perform Risk Analysis
チーム2つ → Lead the Team

【削除・吸収（3つ）】
Plan Quality Management → ガバナンス（QA）とスコープに分散吸収
Conduct Procurements → 付録X4へ
Control Procurements → 付録X4へ
Control Quality → Monitor and Control Scope ほかに分散吸収

【知識エリアの行方】
コミュニケーション → ステークホルダードメインに吸収
調達 → 付録X4に降格（Plan Sourcing Strategy のみガバナンスに残存）
品質 → ガバナンス（QA）とスコープ（要求品質）に分割

---

## Skillチェーン設計での使い方

20_Skills のフェーズフォルダ（01_立ち上げ〜05_終結）= フォーカスエリア（横軸）。
各Skillがどのプロセス（縦軸=ドメイン）をカバーするかをこの表の番号（#1〜40）で紐づけると、
「フェーズ×ドメイン」のカバレッジマップが作れる。

---

## 出典

- [BrainBOK: PMBOK Guide 7th vs 8th Edition](https://www.brainbok.com/blog/pmp/pmbok-guide-7th-vs-8th-edition-what-has-changed)
- [BrainBOK: Focus Areas vs Process Groups](https://www.brainbok.com/blog/pmp/focus-areas-vs-process-groups-pmbok-8)
- [Ricardo Vargas: PMBOK 8th Edition Processes Flow](https://ricardo-vargas.com/pmbok-guide-8th-edition-processes-flow/)
