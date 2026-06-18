# Image2 Prompt Contract

1スライド1画像を生成するためのプロンプト契約。

---

## 全スライド共通

各プロンプトに含める。

- Create a single 16:9 slide image.
- Do not create a contact sheet.
- Do not include multiple slides in one image.
- The slide body/content must be Image2-generated.
- Do not use SVG, code-rendered layout, wireframe, programmatic vector graphics, HTML canvas, Mermaid, or screenshots for the body content.
- Use the provided brand system faithfully.
- Make Japanese text as accurate and readable as possible.
- Do not imitate unrelated templates.
- Use a simple consulting-style design unless another style was explicitly requested.
- Use Noto Sans JP style: thin, clean Japanese sans-serif typography; Regular for headings, Light for body text, Medium only for emphasis.
- Do not show page numbers anywhere on the slide.
- Do not include sequence numbers in visible slide titles.

---

## デフォルトデザイン

ユーザーが別の方向性を明示しない限り、以下を指定する。

- Simple consulting-style presentation design.
- Generous whitespace and wide margins.
- One clear key message.
- Two or three content groups at most.
- Thin gray rules, clean grids, and structured logic blocks.
- Conclusion-first headline placement.
- Minimal icons.
- Restrained brand-derived colors.
- No busy mockup scene.
- No dense dashboard unless the content truly requires metric blocks.
- No decorative blobs, heavy gradients, or ornamental backgrounds.

---

## 通常スライドのヘッダー

通常スライドでは指定する。

```text
Normal-slide navigation:
- Small slide title at the exact same top-left position across normal slides.
- Short thin underline below the title.
- Small logo at the exact same top-right position across normal slides, if a logo is provided.
- In no-logo mode, do not create or invent a logo. Leave the top-right area empty unless the user provided a short deck mark.
- The title and logo should be quiet navigation elements, not the main content.
- Do not show page numbers.
- Do not prefix the title with numbers such as "1.", "01", or "第1章".
```

Image2の出力は揺れる前提で、最終的に `scripts/fix_title_logo.py` で補正する。

---

## 表紙プロンプト

表紙では指定する。

```text
Title slide:
- Output only this one title slide as a standalone image.
- The entire title slide, including content area, typography, background, and logo placement, must be Image2-generated.
- If a logo is provided, include it as a small, subtle brand mark with generous whitespace.
- In no-logo mode, do not create or invent a logo.
- Do not show page numbers.
```

---

## 通常スライドプロンプト

通常スライドでは指定する。

```text
Normal slide:
- Output only this one normal slide as a standalone image.
- The content area, typography, background, and visual accents must be Image2-generated.
- Keep the normal-slide title and logo small and consistent with the deck system.
- Use a simple, airy, consulting-style, low-decoration layout unless another style was explicitly requested.
- Do not show page numbers.
```

---

## 推奨プロンプト構造

1. 生成指示
2. ブランドシステム要約
3. タイポグラフィとロゴ/ロゴなし方針
4. 固定ヘッダー規則
5. スライドタイトル
6. キーメッセージ
7. スライド内容
8. Negative constraints

---

## Negative Constraints

必要なものだけ使う。

- No contact sheet.
- No multiple slides in one image.
- No old template copy.
- No rigid spreadsheet look unless the content truly requires a table.
- No decorative meaningless blobs.
- No busy mockup scene unless explicitly requested.
- No heavy gradients or ornamental backgrounds.
- No heavy bold typography unless explicitly requested.
- No logo-dominant title slide unless explicitly requested.
- No code-rendered body content.
- No visible page numbers.
- No numbered slide titles.
- No invented logo in no-logo mode.

