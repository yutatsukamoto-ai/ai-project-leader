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
- Translate the brand anchor into the slide theme; do not mimic the company website, screenshots, or logo style directly unless explicitly requested.
- Use a reference-informed consulting proposal style unless another style was explicitly requested.
- Use consulting references for structure and logic, not for copying their exact blue visual template.
- Use Retty-like business deck references for color hierarchy and component language, not for copying orange by default.
- Choose a layout archetype based on the slide role; do not reuse the same layout pattern by default.
- For consulting-style AI/DX slides, choose a logic pattern such as logic tree, issue-emphasis tree, proposal logic tree, issue/solution tree, matrix, process swimlane, flow type, workplan roadmap, evidence exhibit, or decision table.
- Use a limited color hierarchy: one main color family, main-color tints, neutral gray, and one small accent color.
- Use Noto Sans JP style: thin, clean Japanese sans-serif typography; Regular for headings, Light for body text, Medium only for emphasis.
- Do not show page numbers anywhere on the slide.
- Do not include sequence numbers in visible slide titles.

---

## デフォルトデザイン

ユーザーが別の方向性を明示しない限り、以下を指定する。

- Reference-informed consulting proposal slide design.
- Warm off-white / ivory background.
- One theme-translated main color. Do not default to deep green unless the theme calls for it.
- Main-color tint areas, thin rules, small chips, highlight bars, and subtle frames.
- One small accent color only when the main color cannot express recommendation, warning, conclusion, or difference.
- Do not use pure white as the default background unless explicitly requested.
- Use main color shade hierarchy: dark for conclusions and main labels, mid for selected or active structures, light for support backgrounds.
- Use neutral gray for non-selected options, past values, comparison baselines, and low-emphasis text.
- Use the accent color only for recommendations, warnings, conclusions, or important differences.
- Generous whitespace and wide margins.
- One clear key message.
- Separate the small navigation title from the main message headline.
- The small navigation title should state the page category; the main headline should state the conclusion, decision, change, issue, condition, or scope.
- Separate the quiet visual style from the consulting logic structure.
- Two or three content groups at most.
- Thin line icons, purposeful abstract diagrams, labeled structural shapes, and structured logic blocks.
- Large conclusion-first headline placed in the upper or central area, not inside a card.
- A horizontal bottom message box or decision-axis band when useful.
- Restrained translated brand colors; darken or mute bright brand colors.
- Different slide roles should use different layout archetypes when useful: statement, split visual, before/after, process flow, evidence board, checklist, workshop canvas, or summary rows.
- Problem, proposal, process, plan, and decision slides should use explicit logic structures, not poster-like loose illustrations.
- When useful, use structures such as problem-to-detail-to-solution-to-next-action, logic tree, issue emphasis tree, proposal logic tree, flow type with input/process/output, comparison table, or decision table.
- When useful, use Retty-like component language: small section chips, pale main-color cells, highlighted bars, thin frames, gray baselines, and selective chart/table emphasis.
- No busy mockup scene.
- No dense dashboard unless the content truly requires metric blocks.
- No decorative blobs, heavy gradients, or ornamental backgrounds.
- No large unlabeled circles, bubbles, or decorative shapes without a clear semantic role.
- No generic rounded-card UI, no repeated three-column cards, no AI-looking card layout with soft shadows.
- No website imitation, no large screenshots, no logo-dominant visual system.
- No fixed deep-green deck style across unrelated topics.
- No copying Retty orange unless orange fits the brand or theme.
- No copying the external consulting reference's blue template.
- Do not reuse the same large headline + central diagram + bottom band layout on every slide.

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
- Use a quiet, airy, editorial proposal layout unless another style was explicitly requested.
- Do not show page numbers.
```

---

## 推奨プロンプト構造

1. 生成指示
2. ブランドシステム要約
3. タイポグラフィとロゴ/ロゴなし方針
4. 固定ヘッダー規則
5. Slide role
6. Layout archetype
7. Emphasis pattern
8. Navigation title
9. Message headline
10. Supporting message
11. Visual focus and emphasis reason
12. Logic pattern, purpose, primary read, and structure notes
13. Color role and highlight rule
14. スライド内容
15. Negative constraints

### Layout Instructions

各プロンプトに必要に応じて含める。

```text
Slide role: <title / agenda / problem / comparison / process / evidence / concept / proposal / summary / workshop>.
Layout archetype: <editorial_statement / split_visual / before_after / process_flow / evidence_board / logic_exhibit / checklist_path / story_strip / civic_landscape / workshop_canvas / summary_rows / focus_metric / system_map>.
Emphasis pattern: <statement / contrast / sequence / proof / question / decision_axis / checklist / scene / relationship>.
Navigation title: <short category label for the fixed header>.
Message headline: <the main takeaway, decision, change, issue, condition, or scope>.
Supporting message: <one short sentence that tells the reader how to read the slide>.
Visual focus: <what should be visually dominant>.
Emphasis reason: <why that element deserves emphasis>.
Logic pattern: <logic_tree / issue_emphasis_tree / proposal_logic_tree / issue_solution_tree / recommendation_matrix / process_swimlane / flow_type / workplan_roadmap / evidence_exhibit / decision_table / implication_grid / none>.
Logic purpose: <what the structure helps the reader understand or decide>.
Primary read: <what the reader should understand first>.
Structure notes: <rows, columns, lanes, arrows, hierarchy, and highlight rules>.
Color role: <base background, main dark, main mid, main light, accent, neutral, and highlight rule>.
Do not reuse the same layout pattern as the previous slide unless continuity is intentional.
```

---

## Negative Constraints

必要なものだけ使う。

- No contact sheet.
- No multiple slides in one image.
- No old template copy.
- No company website imitation.
- No logo-dominant title slide unless explicitly requested.
- No bright brand color flood unless explicitly requested.
- No pure white default background unless explicitly requested.
- No many-color palette.
- No assigning a different color to each element by default.
- No accent-color overuse.
- No generic rounded-card UI with soft shadows.
- No repeated three-column card layout unless the content truly requires comparison cards.
- No repeated layout archetype across the deck unless intentionally specified.
- No always-on bottom message band unless it is the chosen emphasis pattern.
- No rigid spreadsheet look unless the content truly requires a table.
- No decorative meaningless blobs.
- No unlabeled decorative circles or bubbles.
- No busy mockup scene unless explicitly requested.
- No heavy gradients or ornamental backgrounds.
- No heavy bold typography unless explicitly requested.
- No code-rendered body content.
- No visible page numbers.
- No numbered slide titles.
- No vague headline such as "about", "important points", or "future topics".
- No oversized item counts, chapter numbers, or auxiliary labels unless they are the actual key metric.
- No loose poster-like infographic when the slide needs issue analysis, option comparison, process design, workplan, or decision criteria.
- No decorative connectors; use arrows and lines only to show actual relationships.
- No invented logo in no-logo mode.
