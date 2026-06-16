あなたはプロジェクトマネジメント成果物の品質監査者です。
以下の成果物を、チェックリストの各項目について pass / fail / n/a で判定し、各項目に一文で根拠を付けてください。
判定は「型（節が在るか）」ではなく「中身の質・判断の妥当性」を見ます。節が在っても中身が浅い・誤っていれば fail。
最後に、成果物全体の総合判定（pass/fail）と、fail があればそれが「Skillの指示の劣化」か「仕様が正しく変わった可能性（ゴールデン更新候補）」かの見立てを1〜2文で述べてください。

# 対象Skill
wbs-builder（案件: 丸山）

# 共通チェック（全Skill）
- [ ] **状態は言葉**: 状態・達成度・優先度を、確度記号（●◐○）や採否記号（◎○△）で代用していない（言葉で書く）。
- [ ] **数字をぼかさない**: 件数・期日・金額・目標値が具体。概算は「概算」と明記しレンジで。
- [ ] **一文一改行**: 句点ごとに改行されている。だらだら続く長文パラグラフが無い。
- [ ] **ラベル型見出し**: 見出しを流し読みすると目次になる（何の話か一目で分かる）。
- [ ] **やらないこと・停止ポイントが明確**: 範囲外の明言・✋確認ポイントが落ちていない。
- [ ] **入力との整合**: 前工程の成果物・project-contextの確定事実と矛盾していない。

# Skill固有チェック
- [ ] 事実だけ（予定/実績の日付＋qty/hours）を持ち、工数・進捗・イナズマ線を数値で持っていない（自動計算に委ねている）。
- [ ] 最大3階層・ローリングウェーブ（直近段階のみ仮日付＋詳細／先はnull＋骨格）。
- [ ] ★律速（クリティカルパス）と不可逆の関所がnoteに示されている。
- [ ] 統合計画書§2と二重化でなく深掘り・接続になっている。

# 判定対象の成果物
{ "projects": [ {
  "name": "丸山製作所 受注〜出荷プロセス改善",
  "milestones": [
    { "date": "2026-08-14", "label": "①ゲート: 見える化完了", "color": "#ef4444" },
    { "date": "2026-09-11", "label": "②ゲート: 施策選定", "color": "#f97316" },
    { "date": "2027-03-12", "label": "③最終: 定着確認", "color": "#22c55e" },
    { "date": "2027-03-31", "label": "●●工業 契約更新", "color": "#dc2626" }
  ],
  "tasks": [
    { "id": "1", "name": "① 現状の見える化", "children": [
      { "id": "1.1", "name": "キックオフ＋体制確認",
        "qty": 1, "hours": 16, "assignee": "当社＋小林様",
        "plan": { "start": "2026-06-23", "end": "2026-07-04" },
        "actual": { "start": null, "end": null },
        "note": "委任範囲の合意を含む" },
      { "id": "1.2", "name": "現場ヒアリング（受注〜出荷）",
        "qty": 4, "hours": 8, "assignee": "当社→村上様・パート",
        "plan": { "start": "2026-07-07", "end": "2026-07-18" },
        "actual": { "start": null, "end": null },
        "note": "★律速。村上氏参画が全後続の前提" },
      { "id": "1.3", "name": "As-Is業務フロー作成",
        "qty": 1, "hours": 40, "assignee": "当社作成→村上様・小林様レビュー",
        "plan": { "start": "2026-07-14", "end": "2026-07-25" },
        "actual": { "start": null, "end": null },
        "note": "受入: 現場担当者が実態と認める" },
      { "id": "1.4", "name": "基幹データ分析（LT・ミス集計）",
        "qty": 1, "hours": 24, "assignee": "藤田様抽出→当社分析",
        "plan": { "start": "2026-07-21", "end": "2026-08-01" },
        "actual": { "start": null, "end": null },
        "note": "" },
      { "id": "1.5", "name": "ISO改訂スケジュール確認",
        "qty": 1, "hours": 4, "assignee": "小林様→高橋様",
        "plan": { "start": "2026-07-07", "end": "2026-07-11" },
        "actual": { "start": null, "end": null },
        "note": "" },
      { "id": "1.6", "name": "結果報告＋節目判断",
        "qty": 1, "hours": 16, "assignee": "当社→大西様・山田工場長",
        "plan": { "start": "2026-08-04", "end": "2026-08-14" },
        "actual": { "start": null, "end": null },
        "note": "ゲート: ②に進むか判断" }
    ] },
    { "id": "2", "name": "② 改善策の設計", "children": [
      { "id": "2.1", "name": "To-Be業務フロー設計",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "🟡 ①ゲート後に詳細化" },
      { "id": "2.2", "name": "施策の費用対効果比較",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "🟡" },
      { "id": "2.3", "name": "優先順位提案＋節目判断",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "ゲート: どの施策から着手するか" }
    ] },
    { "id": "3", "name": "③ クイックウィン実行", "children": [
      { "id": "3.1", "name": "最優先施策の実行",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "🟡 ②ゲート後に詳細化" },
      { "id": "3.2", "name": "効果測定（LT・ミスの前後比較）",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "🟡" },
      { "id": "3.3", "name": "段階展開＋定着確認",
        "qty": 1, "hours": null, "assignee": null,
        "plan": { "start": null, "end": null },
        "actual": { "start": null, "end": null },
        "note": "🟡 ✋✋ 旧運用廃止は不可逆。切替判断に関所" }
    ] }
  ]
} ] }
