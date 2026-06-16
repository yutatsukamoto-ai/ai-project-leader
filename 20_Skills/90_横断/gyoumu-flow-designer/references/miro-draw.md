# Miro描画リファレンス

描画層がMiroの場合に参照する知識。
座標テーブル＋接続計画（Step 2の出力）を、Miro REST API v2のcurlコマンドに変換する。

ノードタイプ・配色・サイズの定義は `設計方法論.md §4` が正典。本ファイルはMiro固有の実装方法のみ記載する。

---

## §1 前提条件

環境変数 `MIRO_TOKEN` と `MIRO_BOARD_ID` が必要。

### 環境変数の確認（描画前に必ず実行）

```bash
echo "MIRO_TOKEN: ${MIRO_TOKEN:0:10}..."
echo "MIRO_BOARD_ID: ${MIRO_BOARD_ID}"

RESULT=$(curl -s -H "Authorization: Bearer ${MIRO_TOKEN}" \
  "https://api.miro.com/v2/boards/${MIRO_BOARD_ID}")
echo "$RESULT" | jq -r '.name // .message // "エラー: レスポンスなし"'
```

APIテストが成功するまで描画に進まない。

### ボードクリア

既存アイテムをクリアする場合（ユーザー確認後）:

```bash
while true; do
  ITEMS=$(curl -s -H "Authorization: Bearer ${MIRO_TOKEN}" \
    "https://api.miro.com/v2/boards/${MIRO_BOARD_ID}/items?limit=50")
  COUNT=$(echo "$ITEMS" | jq '.data | length')
  if [ "$COUNT" = "0" ] || [ "$COUNT" = "null" ]; then
    echo "ボードクリア完了"
    break
  fi
  echo "$ITEMS" | jq -r '.data[].id' | while read ID; do
    curl -s -X DELETE "https://api.miro.com/v2/boards/${MIRO_BOARD_ID}/items/${ID}" \
      -H "Authorization: Bearer ${MIRO_TOKEN}"
  done
done
```

---

## §2 座標系

Miroは**中央原点**。position の x, y は要素の中心座標。
FigJamとの最大の違いはこの点。FigJamの左上座標と同じ値を使うとずれる。

Y座標レイアウトとノード間隔の計算式は設計方法論.md §4 / figma-draw.md §2 と同じ値を使う（座標系の違いはAPIが吸収する）。

### 座標の連動ルール（QA修正時に必読）

1. **派生座標はベタ書き禁止** — コネクタの始点・終点、スイムレーン幅、見出し位置など、ノード座標から計算できる値はリテラルで書かず、ノードの変数から計算する。ノードを動かしたとき連動漏れが起きる。
2. **ノード移動後は衝突チェック** — QA修正でノードの位置を変えたら、隣接ノード・ラベル・コネクタと重ならないか確認してから再描画する。

---

## §3 API基本形

```bash
curl -s -X POST "https://api.miro.com/v2/boards/${MIRO_BOARD_ID}/[endpoint]" \
  -H "Authorization: Bearer ${MIRO_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[JSONボディ]'
```

レスポンスから `id` を取得してコネクタ作成に使う:

```bash
NODE_ID=$(curl -s -X POST ... | jq -r '.id')
```

---

## §4 実行順序（鉄則）

```
1. スイムレーン作成（/frames）   ← 最初＝最背面
2. 見出し・タイムラインヘッダー（/texts）
3. タイムライン補助線（/shapes）
4. ノード作成（/shapes）         ← IDを保存
5. コネクタ作成（/connectors）   ← 全ノードのIDが揃ってから
```

---

## §5 スイムレーン（/frames）

Miroではスイムレーンを **Frame** で実装する。

```json
{
  "data": { "title": "[アクター名]", "format": "custom", "type": "freeform" },
  "position": { "x": [中央X], "y": [レーンY] },
  "geometry": { "width": [計算した幅], "height": 250 },
  "style": { "fillColor": "#FFFFFF" }
}
```

幅 = 最右ノードX - 最左ノードX + 500。

---

## §6 見出し・タイムライン

### 見出し（/texts）

タイムラインあり時:
```json
{
  "data": { "content": "<strong>[業務名]</strong><br>[サイクル]" },
  "position": { "x": [中央X], "y": -240 },
  "geometry": { "width": 700 },
  "style": { "fontSize": "48", "textAlign": "center" }
}
```

タイムラインなし時: `"y": -80`, `"fontSize": "24"`, `"width": 400`。

### タイムラインヘッダー（/texts）

```json
{
  "data": { "content": "<strong>[タイミング]</strong>" },
  "position": { "x": [該当タスクX], "y": -60 },
  "geometry": { "width": 180 },
  "style": { "fontSize": "18", "textAlign": "center", "color": "#2C3E50" }
}
```

タイムラインヘッダーは「その時点までに完了すべきタスク」の右側（後）に配置する。

### タイムライン補助線（/shapes）

API制約: `width >= 8px`, `borderWidth >= 1.0`。

```json
{
  "data": { "shape": "rectangle" },
  "position": { "x": [ヘッダーX], "y": [中央Y] },
  "geometry": { "width": 8, "height": [高さ] },
  "style": { "fillColor": "#E8E8E8", "borderWidth": "1.0", "borderColor": "#E8E8E8" }
}
```

高さ = レーン数 × 270 - 20。中央Y = 100 + (高さ / 2) - 125。

---

## §7 Miroノード形状マッピング

設計方法論.md §4のノードタイプをMiro APIの形状にマッピングする。

| ノードタイプ | Miro shape | 特記 |
|---|---|---|
| 開始 | `circle` | — |
| 終了 | `circle` | — |
| タスク | `rectangle` | — |
| 判断 | `rhombus` | ★ `diamond` ではなく `rhombus` |
| システム/ツール | `round_rectangle` | borderWidth=1.0 |
| データソース | `round_rectangle` | borderWidth=1.0 |
| ドキュメント | `round_rectangle` | borderWidth=1.0 |
| 差戻し | `rectangle` | — |

### ノード作成例（/shapes）

**タスクノード**:
```json
{
  "data": { "shape": "rectangle", "content": "<p>[タスク名]</p>" },
  "position": { "x": [X], "y": [Y] },
  "geometry": { "width": 140, "height": 70 },
  "style": {
    "fillColor": "#FFFFFF", "borderColor": "#000000", "borderWidth": "2.0",
    "textAlign": "center", "textAlignVertical": "middle"
  }
}
```

**判断ノード**:
```json
{
  "data": { "shape": "rhombus", "content": "<p>[判断内容]?</p>" },
  "position": { "x": [X], "y": [Y] },
  "geometry": { "width": 100, "height": 100 },
  "style": {
    "fillColor": "#FEF9E7", "borderColor": "#F39C12", "borderWidth": "2.0",
    "textAlign": "center", "textAlignVertical": "middle"
  }
}
```

**開始ノード**: shape=`circle`, 60×60, fill=`#D5F5E3`, border=`#27AE60`。
**終了ノード**: shape=`circle`, 60×60, fill=`#D5D8DC`, border=`#7F8C8D`。
**差戻しノード**: shape=`rectangle`, 120×60, fill=`#FADBD8`, border=`#E74C3C`。
**システム**: shape=`round_rectangle`, 120×40, fill=`#EBF5FB`, border=`#3498DB`, borderWidth=`1.0`。
**データソース**: shape=`round_rectangle`, 120×40, fill=`#F5EEF8`, border=`#9B59B6`, borderWidth=`1.0`。
**ドキュメント**: shape=`round_rectangle`, 120×40, fill=`#E8F8F5`, border=`#1ABC9C`, borderWidth=`1.0`。

システム/データソース/ドキュメントはタスクノードの下（Y+60）に配置する。

---

## §8 コネクタ（/connectors）

### 基本形

全コネクタに `endStrokeCap: "stealth"` を指定（矢印表示）。

```json
{
  "startItem": { "id": "[開始ノードID]", "snapTo": "right" },
  "endItem": { "id": "[終了ノードID]", "snapTo": "left" },
  "style": { "strokeColor": "#000000", "strokeWidth": "2.0", "endStrokeCap": "stealth" },
  "shape": "elbowed"
}
```

### snapTo値

`top`, `bottom`, `left`, `right`（小文字）。FigJamのmagnetは大文字だが、Miroは小文字。

### 接続パターン早見表

判断ノード: 入力=`left`、Yes出力=`bottom`、No出力=`right`。
タスクノード: 入力=`left`、出力=`right`、レーン跨ぎ入力=`top`、レーン跨ぎ出力=`bottom`、ループ戻り先=`bottom` or `top`。
差戻しノード: 入力=`left`、ループ出力=`top`。
開始: 出力=`right`。終了: 入力=`left`。

### コネクタ種別

| 種別 | strokeColor | strokeStyle | ラベル |
|---|---|---|---|
| 通常 | `#000000` | — | — |
| Yes分岐 | `#27AE60` | — | `captions: [{"content":"Yes"}]` |
| No分岐 | `#E74C3C` | — | `captions: [{"content":"No"}]` |
| ループ（差戻し） | `#E74C3C` | `"strokeStyle": "dashed"` | — |

### 接続点の重複禁止（必須）

同じノードの同じsnapToに複数のコネクタを接続しない。描画前に接続計画を立てること。

---

## §9 シェル変数の注意（必須）

**異なるBash呼び出し間でシェル変数は引き継がれない。**

```bash
# ❌ 悪い例
# 1回目のBash呼び出し
START_ID=$(curl -s ... | jq -r '.id')
# 2回目のBash呼び出し — START_IDは空

# ✅ 良い例: 同一Bash内で完結
START_ID=$(curl -s ... | jq -r '.id')
TASK1_ID=$(curl -s ... | jq -r '.id')
curl ... "startItem":{"id":"${START_ID}"},"endItem":{"id":"${TASK1_ID}"} ...

# ✅ 良い例: レスポンスのIDをハードコードで使用
curl ... "startItem":{"id":"3458764655498618816"} ...
```

ノード作成とコネクタ作成は**同一のBash呼び出し内**で行うか、ノードIDをハードコードで使用する。

---

## §10 スイムレーンパターン集

業務フローでよく使われるパターン。入力分析（Step 1）の結果をどの構造にマッピングするかの参考。

### パターン1: シンプル承認フロー（2レーン）

申請→承認の基本。申請者レーンと承認者レーンの2段。

```
申請者:  [開始]→[申請作成]→[提出]
                                ↓
承認者:           [確認]→{承認?}→Yes→[処理]→[終了]
                           └No→[却下]
```

### パターン2: 多段階承認フロー（3レーン）

担当→一次承認→最終承認。差戻しループあり。

### パターン3: 並行処理フロー（3レーン）

複数部署が同時に作業し合流する。フォーク/ジョイン構造。

### パターン4: 問い合わせ対応フロー（4レーン）

顧客→コールセンター→技術サポート→開発チーム。種別判断で振り分け。

### パターン5: 経費精算フロー（3レーン + ループ）

申請→承認→精算。差戻しループが申請者レーンに戻る典型パターン。

---

## §11 トラブルシュート

### 401 Unauthorized

トークンが無効。https://miro.com/app/settings/user-profile/apps でトークンを再取得。

### 404 Not Found

ボードIDが不正。MiroボードURLから `https://miro.com/app/board/[ここがボードID]/` で確認。

### 403 Forbidden

トークンのスコープに `boards:write` が含まれているか確認。

### シェイプ最小サイズエラー

`width >= 8px`, `borderWidth >= 1.0` が必須。補助線を幅2pxで作成するとエラーになる。

### コネクタ作成エラー（IDが空）

シェル変数が別のBash呼び出しで消えている。§9の対処法に従う。

### 判断ノードの形状エラー

`diamond` ではなく `rhombus` を使用する。
