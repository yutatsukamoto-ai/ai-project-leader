# Excel操作性ルール（全Skill共通）

Excel成果物を「開いてすぐ使える」状態にするための正典(SSOT)。
見た目の配色は `出力フォーマット規約.md` C節、記号は `表と数値の見せ方.md` A節が担う。本ファイルは操作性（入力規則・条件付き書式・保護）だけを薄く担う。

---

## A. ドロップダウン（データ入力規則）

選択肢が決まっている列（enum列）には、必ずドロップダウンリストを設定する。

適用基準: Skillのreferencesで値が列挙されている列すべて。
例: 区分（作業課題/判断待ち/リスク対応）、優先度（高/中/低）、状態（オープン/対応中/完了）。

設定方法（openpyxl）:

```python
from openpyxl.worksheet.datavalidation import DataValidation

dv = DataValidation(
    type="list",
    formula1='"高,中,低"',   # 選択肢をカンマ区切り
    allow_blank=True,
    showDropDown=False,       # False = ドロップダウン表示（openpyxl仕様）
)
dv.error = "リストから選択してください"
dv.errorTitle = "入力エラー"
ws.add_data_validation(dv)
dv.add(f"E2:E1000")          # データ行の範囲
```

注意: `showDropDown=False` がドロップダウンを**表示する**設定（openpyxlの仕様で意味が逆）。

## B. 条件付き書式

enum列の値に応じて行や列の色を自動で変えたい場合、条件付き書式を設定する。

適用基準: 優先度・状態など、値と色のマッピングがreferencesに定義されている列。
色のマッピング自体は各Skillのreferencesが持つ（横断で固定しない）。

設定方法（openpyxl）:

```python
from openpyxl.formatting.rule import CellIsRule
from openpyxl.styles import PatternFill

# 行全体に適用する例（優先度列=E列の値で行色を変える）
from openpyxl.formatting.rule import FormulaRule

fills = {
    "高": PatternFill("solid", fgColor="FCE4E4"),
    "中": PatternFill("solid", fgColor="FFF8E1"),
    "低": PatternFill("solid", fgColor="F5F5F5"),
}
data_range = "A2:J1000"  # データ行の全列範囲

for val, fill in fills.items():
    ws.conditional_formatting.add(
        data_range,
        FormulaRule(
            formula=[f'$E2="{val}"'],   # $E = 優先度列（絶対列・相対行）
            fill=fill,
        ),
    )
```

重要: 条件付き書式を使う場合、セルに直接 `PatternFill` を塗らない（条件付き書式と競合する）。ヘッダー行だけ直接塗る。

## C. ヘッダー固定・フィルタ（既存ルールの再掲）

これらは以前から暗黙で適用していたが、明文化する。

- **ヘッダー行固定**: `ws.freeze_panes = "A2"`（常時適用）
- **オートフィルタ**: `ws.auto_filter.ref = "A1:{最終列}{最終行}"`（常時適用）
- **ヘッダー行の高さ**: 28pt以上（折り返し表示に対応）

## D. 将来予約

- **シート保護**（ヘッダー・数式セルのロック）: 必要が出た時点で追加。現時点では不要。
- **名前付き範囲**: 凡例シートの選択肢を名前付き範囲にする案。シンプルさ優先で現時点は不採用（formula1に直書き）。

---

## SSOT規約・運用

本ファイルの正典はここ（`40_Stock/横断ガイドライン/Excel操作性ルール.md`）。

- **境界**: 操作性（入力規則・条件付き書式・保護）は本ファイル。配色の大原則は `出力フォーマット規約.md`。記号は `表と数値の見せ方.md`。重複させない。
- **色マッピングの所在**: 各Skillのreferences（例: `issue-log/references/型と品質基準.md`）。横断で色を固定しない。理由: 優先度の「高」とリスクの「高」で色が同じとは限らない。
- **状態**: A〜C ＝✅確定。D＝将来予約。
