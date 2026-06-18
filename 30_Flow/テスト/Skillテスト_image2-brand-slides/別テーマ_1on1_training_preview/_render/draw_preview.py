#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "final-slides"
W, H = 1920, 1080

BG = "#FAF7F0"
TEXT = "#262626"
PRIMARY = "#2F4858"
SUPPORT = "#DCE6E8"
ACCENT = "#B66A4B"
LINE = "#CFC8BA"
MUTED = "#6F6A61"
WHITE = "#FFFDF8"


def find_font(weight: str) -> str:
    fonts = list(Path("/System/Library/Fonts").glob(f"*角*{weight}.ttc"))
    if fonts:
        return str(fonts[0])
    return "/System/Library/Fonts/Supplemental/AppleGothic.ttf"


FONT_R = find_font("W3")
FONT_B = find_font("W6")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_B if bold else FONT_R, size=size)


def ml(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int, fill: str, bold: bool = False, spacing: int = 12) -> None:
    draw.multiline_text(xy, text, font=font(size, bold), fill=fill, spacing=spacing)


def size(draw: ImageDraw.ImageDraw, text: str, size_: int, bold: bool = False) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=font(size_, bold))
    return box[2] - box[0], box[3] - box[1]


def base() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=BG)
    for y in range(170, 920, 82):
        d.line((132, y, 1788, y), fill="#E8E0D2", width=1)
    d.ellipse((1430, 84, 1848, 502), fill=SUPPORT)
    d.line((132, 76, 1788, 76), fill=LINE, width=2)
    return img, d


def header(d: ImageDraw.ImageDraw, title: str, mark: str) -> None:
    d.text((132, 108), title, font=font(30), fill=PRIMARY)
    d.line((132, 162, 250, 162), fill=ACCENT, width=3)
    w, _ = size(d, mark, 22)
    d.text((1788 - w, 108), mark, font=font(22), fill=MUTED)


def bottom(d: ImageDraw.ImageDraw, label: str, text: str) -> None:
    d.line((132, 868, 1788, 868), fill=LINE, width=2)
    d.text((132, 908), label, font=font(18, True), fill=ACCENT)
    ml(d, (300, 894), text, 30, PRIMARY, spacing=8)


def people(d: ImageDraw.ImageDraw, x: int, y: int) -> None:
    d.ellipse((x, y, x + 92, y + 92), outline=PRIMARY, width=3)
    d.ellipse((x + 260, y + 20, x + 352, y + 112), outline=PRIMARY, width=3)
    d.arc((x + 92, y + 28, x + 268, y + 124), 200, 340, fill=ACCENT, width=4)
    d.arc((x + 88, y - 16, x + 270, y + 88), 20, 160, fill=PRIMARY, width=3)
    d.line((x + 178, y + 105, x + 197, y + 122), fill=ACCENT, width=4)
    d.line((x + 197, y + 122, x + 226, y + 91), fill=ACCENT, width=4)


def speech(d: ImageDraw.ImageDraw, xy: tuple[int, int], wh: tuple[int, int], text: str, accent: bool = False) -> None:
    x, y = xy
    w, h = wh
    d.rounded_rectangle((x, y, x + w, y + h), radius=38, fill=WHITE, outline=ACCENT if accent else LINE, width=2)
    d.polygon([(x + 72, y + h), (x + 112, y + h), (x + 80, y + h + 34)], fill=WHITE, outline=LINE)
    ml(d, (x + 38, y + 34), text, 28, PRIMARY if accent else TEXT, bold=accent, spacing=8)


def title_slide() -> Image.Image:
    img, d = base()
    header(d, "Workshop", "1on1 Dialogue")
    ml(d, (132, 246), "新任マネージャー\n1on1対話研修", 86, PRIMARY, True, 16)
    d.text((132, 506), "聞く・任せる・支えるための実践設計", font=font(38), fill=TEXT)
    people(d, 1268, 404)
    speech(d, (1140, 210), (430, 130), "今日は、答えを教える前に\n問いを置く練習をする。", True)
    bottom(d, "MESSAGE", "1on1は進捗確認ではなく、相手が自分で考えられる\n余白をつくる時間である。")
    return img


def question_slide() -> Image.Image:
    img, d = base()
    header(d, "本日の問い", "Question Design")
    ml(d, (132, 240), "よい1on1は、\n問いの設計で半分決まる。", 66, PRIMARY, True, 14)
    questions = [
        ("事実", "いま何が\n起きている？"),
        ("解釈", "それをどう\n受け止めた？"),
        ("選択肢", "次に何が\n選べる？"),
        ("約束", "何をいつまで\n試す？"),
    ]
    x0, y0 = 132, 512
    for i, (label, q) in enumerate(questions):
        x = x0 + i * 420
        d.ellipse((x, y0, x + 118, y0 + 118), fill=SUPPORT, outline=LINE, width=2)
        d.text((x + 38, y0 + 33), "?", font=font(52, True), fill=ACCENT)
        d.text((x, y0 + 150), label, font=font(32, True), fill=PRIMARY)
        ml(d, (x, y0 + 202), q, 29, TEXT, spacing=7)
        if i < 3:
            d.line((x + 168, y0 + 60, x + 360, y0 + 60), fill=LINE, width=2)
            d.polygon([(x + 360, y0 + 60), (x + 342, y0 + 50), (x + 342, y0 + 70)], fill=LINE)
    bottom(d, "AXIS", "進捗を聞く前に、相手が考えを進められる問いを置く。")
    return img


def cycle_slide() -> Image.Image:
    img, d = base()
    header(d, "対話の型", "Practice Loop")
    ml(d, (132, 238), "聞く、映す、任せる、振り返る。\nこの循環をつくる。", 62, PRIMARY, True, 14)
    cx, cy = 960, 590
    r = 210
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=LINE, width=3)
    points = [
        (cx, cy - r, "聞く", "評価を急がず\n事実をほどく"),
        (cx + r, cy, "映す", "言葉を返して\n認識を揃える"),
        (cx, cy + r, "任せる", "次の一歩を\n本人が選ぶ"),
        (cx - r, cy, "振り返る", "試した結果を\n学びに戻す"),
    ]
    for x, y, label, note in points:
        d.ellipse((x - 88, y - 88, x + 88, y + 88), fill=WHITE, outline=ACCENT, width=2)
        tw, _ = size(d, label, 33, True)
        d.text((x - tw // 2, y - 30), label, font=font(33, True), fill=PRIMARY)
        lines = note.split("\n")
        for j, line in enumerate(lines):
            lw, _ = size(d, line, 18)
            d.text((x - lw // 2, y + 26 + j * 27), line, font=font(18), fill=MUTED)
    d.arc((cx - r - 34, cy - r - 34, cx + r + 34, cy + r + 34), 312, 402, fill=ACCENT, width=5)
    d.polygon([(cx + 64, cy - r - 54), (cx + 32, cy - r - 70), (cx + 44, cy - r - 36)], fill=ACCENT)
    bottom(d, "PRACTICE", "型を守る目的は、会話を硬くすることではなく、\n相手が考える余白を安定してつくること。")
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, img in [
        ("01-title.png", title_slide()),
        ("02-normal.png", question_slide()),
        ("03-normal.png", cycle_slide()),
    ]:
        img.save(OUT / name)


if __name__ == "__main__":
    main()
