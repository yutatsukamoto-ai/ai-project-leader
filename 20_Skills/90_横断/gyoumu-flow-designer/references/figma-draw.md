# FigJam描画リファレンス

描画層がFigJamの場合に参照する知識。
座標テーブル＋接続計画（Step 2の出力）を、Figma MCP経由のPlugin APIコマンドに変換する。

ノードタイプ・配色・サイズの定義は `設計方法論.md §4` が正典。本ファイルはFigJam固有の実装方法のみ記載する。

---

## §1 前提条件

- Figma MCPサーバーが接続済み（`mcp__figma-remote__*` が利用可能）
- 主要ツール: `whoami`（認証確認）、`create_new_file`（新規作成）、`use_figma`（Plugin APIコード実行）、`get_screenshot`（スクリーンショット）
- セットアップ: `claude mcp add --transport http figma https://mcp.figma.com/mcp`

### 描画先の決定

| パターン | 手順 |
|---|---|
| 新規作成 | `whoami` で planKey取得 → `create_new_file({ fileName, planKey, editorType: "figjam" })` → file_key取得 |
| 既存ファイル | URLから fileKey 抽出（`https://www.figma.com/board/{fileKey}/...`）。既存ノードを残すか消すかをユーザーに確認 |

---

## §2 座標系と基本ルール

### 座標系

FigJamは**左上原点**。全要素のx, yは左上角の座標。

### Y座標レイアウト

```
Y=-240: 見出し（タイムラインあり時）/ Y=-80（タイムラインなし時）
Y=-60:  タイムラインヘッダー（ある場合のみ）
Y=100:  レーン1
Y=370:  レーン2（+270px間隔）
Y=640:  レーン3
Y=910:  レーン4
Y=1180: レーン5
```

レーン高さ = 250px、レーン間隔 = 270px（250+20pxの隙間）。

### ノード間隔の計算

ノード間の空白を50〜60px確保する。

```
次ノードX = 前ノードX + 前ノード幅/2 + 余白(60px) + 次ノード幅/2
```

| 遷移パターン | 推奨中心間距離 |
|---|---|
| タスク(140) → タスク(140) | 200px |
| タスク(140) → 判断(100) | 180px |
| 判断(100) → タスク(140) | 180px |
| 判断(100) → 差戻し(120) | 250px |
| 開始/終了(60) → タスク(140) | 160px |

### スイムレーン幅の計算

```
幅 = 最右ノードX - 最左ノードX + 500
```

+500pxの余白は必須。不足するとノードがはみ出す。

### 複数業務フローの配置

```
業務N の見出しY = 業務N-1 の最終レーンY + 125 + 200
業務N のレーン1 Y = 見出しY + 340
```

---

## §3 スイムレーン実装

**FigJamのSectionは使わない**（内部オブジェクトを「含む」動作をし、タイムライン補助線が背面に隠れるため）。

長方形（Rectangle）+ テキストラベル（Text）で表現する。

| 要素 | 実装 |
|---|---|
| 背景 | `figma.createRectangle()` — 奇数レーン `#F5F5F5` / 偶数レーン `#FAFAFA`、枠線 `#CCCCCC` |
| ラベル | `figma.createText()` — レーン左上、fontSize 18、Bold、色 `#555555` |

**描画順序が重要**: スイムレーン背景を最初に作成すると最背面になり、上にノードを置いても隠れない。

---

## §4 見出し・タイムライン

### 見出し

| 条件 | Y | fontSize |
|---|---|---|
| タイムラインヘッダーあり | -240 | 48 |
| タイムラインヘッダーなし | -80 | 24 |

テキスト: `[業務名] / [サイクル]`、Bold、中央配置。

### タイムライン補助線

縦の薄い長方形で表現する。

```
幅 = 8px
色 = #E8E8E8
高さ = レーン数 × 270 - 20
```

ヘッダーテキスト: Y=-60、fontSize 18、Bold。

---

## §5 FigJamノード形状マッピング

設計方法論.md §4のノードタイプをFigJam Plugin APIの形状にマッピングする。

| ノードタイプ | FigJam shapeType | 特記 |
|---|---|---|
| 開始 | `ELLIPSE` | square=true で正円にする |
| 終了 | `ELLIPSE` | 同上 |
| タスク | `SQUARE` | — |
| 判断 | `DIAMOND` | 幅はテキスト推定値×1.6以上 |
| システム/ツール | `ROUNDED_RECTANGLE` | strokeWeight=1 |
| データソース | `ROUNDED_RECTANGLE` | strokeWeight=1 |
| ドキュメント | `ROUNDED_RECTANGLE` | strokeWeight=1 |
| 差戻し | `SQUARE` | — |

### システム/ドキュメントの配置

タスクノードの下（Y+60）に配置する。複数ある場合はX方向にずらす。

```
タスク: x=300, y=100, width=140
  └─ システムA: x=240, y=160（左寄せ）
  └─ ドキュメントB: x=360, y=160（右寄せ）
```

---

## §6 コネクタ実装

### 作成方法

`figma.createConnector()` を使用。ノードの `ref` 辞書からIDを引いて接続する。

```javascript
const c = figma.createConnector();
c.connectorStart = { endpointNodeId: nodeA.id, magnet: 'RIGHT' };
c.connectorEnd   = { endpointNodeId: nodeB.id, magnet: 'LEFT' };
c.connectorLineType = 'ELBOWED';
```

### マグネット文字列

FigJamのmagnet: `LEFT`, `RIGHT`, `TOP`, `BOTTOM`（大文字）。

### 接続パターン早見表

**判断ノード**:

| 接続種別 | magnet |
|---|---|
| 入力 | `LEFT` |
| Yes出力 | `BOTTOM` |
| No出力 | `RIGHT` |

**タスクノード**:

| 接続種別 | magnet |
|---|---|
| 入力 | `LEFT` |
| 出力 | `RIGHT` |
| レーン跨ぎ入力 | `TOP` |
| レーン跨ぎ出力 | `BOTTOM` |
| ループ戻り先 | `BOTTOM` or `TOP`（`LEFT`が使用中の場合） |

**差戻しノード**: 入力=`LEFT`、ループ出力=`TOP`。
**開始**: 出力=`RIGHT`。**終了**: 入力=`LEFT`。

### 接続点の重複禁止（必須）

同じノードの同じmagnetに複数のコネクタを接続しない。
3方向以上の分岐では4接続点を全て使い切る場合があり、事前の接続計画が必須。

### 接続点割り当ての優先順位

1. 入力: 前のノードの方向から（上→TOP、左→LEFT）
2. 同レーン右方向への出力: RIGHT
3. 下レーンへの出力: BOTTOM
4. 上レーンへの出力: TOP（入力で使用中ならLEFT）
5. 左方向への出力: LEFT

### コネクタラベルのフォント設定（必須）

ラベル代入前に `connector.text.fontName` を**明示的に設定**する。省略するとフォント読み込みエラーになる。

```javascript
c.text.fontName = { family: 'Inter', style: 'Medium' };
c.text.characters = 'Yes';
```

### 破線コネクタ（ループ）

```javascript
c.dashPattern = [6, 4];
```

---

## §7 差戻し・ループ構造の配置ルール

1. **差戻しノードは判断ノードと同じY座標**に配置する
2. **X方向に+250px以上**離す
3. 差戻しノードは必ず**同じスイムレーン内**に収める
4. ループコネクタは差戻しのTOPから戻り先のBOTTOMへ（破線、色 `#E74C3C`）

```
[判断?] X=500 ──No→ [修正] X=750（同じY）
   │                    │
   Yes                   └─破線→ 戻り先のBOTTOM
   ↓
```

---

## §8 テキスト幅推定

FigJamの `createShapeWithText()` はwidthが固定で、テキストが長いと省略される。動的にwidthを決定する。

```javascript
const estimateWidth = (text, fontSize = 14, padding = 28) => {
  let units = 0;
  for (const ch of text) units += /[\x20-\x7E]/.test(ch) ? 0.55 : 1.05;
  return Math.ceil(units * fontSize + padding);
};
```

日本語1文字 = 1.05em、半角 = 0.55em。DIAMONDは斜辺で削られるため、推定値×1.6にする。

---

## §9 描画コードテンプレート

通常は**1回の `use_figma` 呼び出し**で完結させる。50000文字制限があるが、概算で150ノード+150コネクタまで収まる。

### 実行順序（鉄則）

```
A プレリュード（フォント読み込み・ヘルパー定義）
→ B スイムレーン（最初に作る＝最背面）
→ C 見出し＋タイムライン
→ D ノード（ref辞書に登録）
→ E コネクタ（refが揃ってから接続）
```

### テンプレートコード

```javascript
// ===== A. プレリュード =====
// 既存ノードをクリアする場合のみ:
// for (const n of figma.currentPage.children) n.remove();

await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });

const hex = (h) => ({
  r: parseInt(h.slice(1,3),16)/255,
  g: parseInt(h.slice(3,5),16)/255,
  b: parseInt(h.slice(5,7),16)/255
});
const solid = (h) => [{ type: 'SOLID', color: hex(h) }];

const estimateWidth = (text, fontSize = 14, padding = 28) => {
  let units = 0;
  for (const ch of text) units += /[\x20-\x7E]/.test(ch) ? 0.55 : 1.05;
  return Math.ceil(units * fontSize + padding);
};

const refs = {};

const mkShape = (shapeType, text, x, y, opts = {}) => {
  const {
    minWidth = 140, height = 70, fill = '#FFFFFF', stroke = '#000000',
    fontSize = 14, ref, square = false
  } = opts;
  const needed = estimateWidth(text, fontSize);
  let width = Math.max(minWidth, needed);
  let h = height;
  if (shapeType === 'DIAMOND') {
    width = Math.max(minWidth, Math.ceil(needed * 1.6));
    h = Math.max(height, Math.ceil(needed * 1.0));
  }
  if (square) { width = Math.max(width, h); h = width; }
  const s = figma.createShapeWithText();
  s.shapeType = shapeType;
  s.x = x; s.y = y; s.resize(width, h);
  s.text.fontName = { family: 'Inter', style: 'Medium' };
  s.text.fontSize = fontSize;
  s.text.characters = text;
  s.fills = solid(fill);
  s.strokes = solid(stroke);
  s.strokeWeight = 2;
  if (ref) refs[ref] = s;
  return s;
};

const mkText = (text, x, y, opts = {}) => {
  const { fontSize = 14, bold = false, color = '#2C3E50' } = opts;
  const t = figma.createText();
  t.fontName = { family: 'Inter', style: bold ? 'Bold' : 'Medium' };
  t.x = x; t.y = y; t.fontSize = fontSize;
  t.characters = text;
  t.fills = solid(color);
  return t;
};

const mkRect = (x, y, w, h, fill, stroke = fill, sw = 1) => {
  const r = figma.createRectangle();
  r.x = x; r.y = y; r.resize(w, h);
  r.fills = solid(fill);
  r.strokes = solid(stroke);
  r.strokeWeight = sw;
  return r;
};

const mkConn = (startKey, magA, endKey, magB, opts = {}) => {
  const {
    color = '#000000', weight = 2, dashed = false, label = '',
    lineType = 'ELBOWED'
  } = opts;
  const a = refs[startKey], b = refs[endKey];
  if (!a || !b) throw new Error(`ref not found: ${startKey} or ${endKey}`);
  const c = figma.createConnector();
  c.connectorStart = { endpointNodeId: a.id, magnet: magA };
  c.connectorEnd   = { endpointNodeId: b.id, magnet: magB };
  c.connectorLineType = lineType;
  c.strokes = solid(color);
  c.strokeWeight = weight;
  if (dashed) c.dashPattern = [6, 4];
  if (label) {
    c.text.fontName = { family: 'Inter', style: 'Medium' };
    c.text.characters = label;
  }
  return c;
};

// ===== B. スイムレーン =====
// mkRect(左端X, レーンY, 幅, 250, 背景色, '#CCCCCC', 1);
// mkText('アクター名', 左端X+10, レーンY+5, { fontSize: 18, bold: true, color: '#555555' });

// ===== C. 見出し＋タイムライン =====
// mkText('[業務名] / [サイクル]', 中央X, -240, { fontSize: 48, bold: true });
// mkRect(タイムラインX, 100, 8, ガイド高さ, '#E8E8E8', '#E8E8E8');
// mkText('タイミング', タイムラインX-50, -60, { fontSize: 18, bold: true });

// ===== D. ノード =====
// mkShape('ELLIPSE', '開始', x, y, { minWidth:60, height:60, fill:'#D5F5E3', stroke:'#27AE60', square:true, ref:'start' });
// mkShape('SQUARE', 'タスク名', x, y, { ref:'t_name' });
// mkShape('DIAMOND', '判断名?', x, y, { minWidth:120, height:120, fill:'#FEF9E7', stroke:'#F39C12', ref:'dec_name' });

// ===== E. コネクタ =====
// mkConn('start', 'RIGHT', 't_name', 'LEFT');
// mkConn('dec_name', 'BOTTOM', 't_next', 'LEFT', { color:'#27AE60', label:'Yes' });
// mkConn('dec_name', 'RIGHT', 'reject_name', 'LEFT', { color:'#E74C3C', label:'No' });
// mkConn('reject_name', 'TOP', 't_name', 'BOTTOM', { color:'#E74C3C', dashed:true });

return { nodes: figma.currentPage.children.length, ok: true };
```

---

## §10 大規模時の分割実行（150ノード超）

50000文字制限を超える場合、コールを分割する。

**1コール目**: ノードまで作成し、ref→nodeId辞書を保存。

```javascript
const map = {};
for (const [k, v] of Object.entries(refs)) map[k] = v.id;
figma.root.setSharedPluginData('gflow', 'refs', JSON.stringify(map));
return { saved: Object.keys(map).length };
```

**2コール目以降**: 辞書を読み出してコネクタ作成。

```javascript
const map = JSON.parse(figma.root.getSharedPluginData('gflow', 'refs'));
const getNode = async (key) => await figma.getNodeByIdAsync(map[key]);

// コネクタ作成
const a = await getNode('t_input');
const b = await getNode('dec_diff');
const c = figma.createConnector();
c.connectorStart = { endpointNodeId: a.id, magnet: 'RIGHT' };
c.connectorEnd   = { endpointNodeId: b.id, magnet: 'LEFT' };
// ...
```

---

## §11 検証（Step 4）

```
mcp__figma-remote__get_screenshot({ fileKey: "...", nodeId: "0:1" })
```

チェック観点:
- スイムレーンからノードがはみ出していないか
- ノード同士が重なっていないか
- コネクタが適切なノードに接続されているか
- テキストが切れていないか
- タイムライン補助線とノードの位置関係が正しいか

問題があれば修正コードを `use_figma` で再投入（追加 or 該当ノードのみ削除して再作成）。

---

## §12 トラブルシュート

### Figma MCPツールが見つからない

`claude mcp add --transport http figma https://mcp.figma.com/mcp` を実行し、Claude Codeを再起動。

### 認証切れ

OAuthトークン期限切れ。MCPサーバーを `mcp remove` → `mcp add` で再接続。

### コネクタのフォント読み込みエラー

`The font " " could not be loaded` — ラベル代入前に `c.text.fontName = { family: 'Inter', style: 'Medium' }` を明示設定してから `characters` に代入する。

### テキストが省略される

`estimateWidth` 関数でwidthを動的に決定する。DIAMONDは×1.6。

### Sectionのz-order問題

FigJam Sectionは内部オブジェクトを「含む」動作をする。スイムレーンにはSectionを使わず、Rectangle+Textで表現する。

### 座標系の違い（Miroとの比較）

FigJamは全要素が左上基点。Miroのフレームは中央基点。Miro版の座標をそのまま使うとずれる。

### use_figma の50000文字制限

§10の分割実行手順に従う。

### 月間コール制限（Starterプラン）

月6回の制限あり。Professional以上にアップグレードするか翌月まで待つ。
