#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFont


BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "final-slides"
ORIG = BASE / "image2-original"
W, H = 1920, 1080

BG = "#F7F4EC"
SURFACE = "#FEFCF7"
PRIMARY = "#243B53"
SECONDARY = "#496A72"
SUPPORT = "#DFE8E6"
LINE = "#D4CBBF"
ACCENT = "#B15D3A"
TEXT = "#252B2E"
MUTED = "#70736F"


def find_font(weight: str) -> str:
    fonts = list(Path("/System/Library/Fonts").glob(f"*角*{weight}.ttc"))
    if fonts:
        return str(fonts[0])
    return "/System/Library/Fonts/Supplemental/AppleGothic.ttf"


FONT_R = find_font("W3")
FONT_B = find_font("W6")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_B if bold else FONT_R, size=size)


def text_size(d: ImageDraw.ImageDraw, text: str, size: int, bold: bool = False) -> tuple[int, int]:
    box = d.textbbox((0, 0), text, font=font(size, bold))
    return box[2] - box[0], box[3] - box[1]


def ml(d: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int, fill: str, bold: bool = False, spacing: int = 12) -> None:
    d.multiline_text(xy, text, font=font(size, bold), fill=fill, spacing=spacing)


def base() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, H), fill=BG)
    d.line((120, 76, 1800, 76), fill=LINE, width=2)
    return img, d


def header(d: ImageDraw.ImageDraw, title: str, mark: str = "AI Project Pattern") -> None:
    d.text((120, 110), title, font=font(29), fill=PRIMARY)
    d.line((120, 164, 232, 164), fill=ACCENT, width=3)
    w, _ = text_size(d, mark, 22)
    d.text((1800 - w, 110), mark, font=font(22), fill=MUTED)


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    ORIG.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path)
    shutil.copy2(path, ORIG / name)


def icon_circle(d: ImageDraw.ImageDraw, cx: int, cy: int, label: str) -> None:
    d.ellipse((cx - 72, cy - 72, cx + 72, cy + 72), fill=SUPPORT, outline=LINE, width=2)
    tw, _ = text_size(d, label, 26, True)
    d.text((cx - tw // 2, cy - 18), label, font=font(26, True), fill=PRIMARY)


def title_slide() -> Image.Image:
    img, d = base()
    header(d, "Pattern Preview", "No-logo Trial")
    ml(d, (120, 245), "AIプロジェクト\n推進の型", 92, PRIMARY, True, 18)
    d.text((120, 530), "曖昧な期待を、判断可能な計画へ変える", font=font(38), fill=TEXT)
    d.line((120, 610, 820, 610), fill=LINE, width=2)
    ml(d, (120, 660), "AI導入はツール選定ではなく、\n曖昧な期待を判断可能な計画へ変える仕事である。", 30, SECONDARY, spacing=10)
    # Abstract route diagram
    pts = [(1190, 340), (1330, 470), (1510, 410), (1630, 585), (1450, 700)]
    for a, b in zip(pts, pts[1:]):
        d.line((*a, *b), fill=SECONDARY, width=3)
    for i, (x, y) in enumerate(pts, 1):
        d.ellipse((x - 34, y - 34, x + 34, y + 34), fill=SURFACE, outline=ACCENT if i == 1 else PRIMARY, width=3)
        d.text((x - 9, y - 17), str(i), font=font(24, True), fill=ACCENT if i == 1 else PRIMARY)
    d.rectangle((120, 878, 1800, 976), outline=LINE, width=2)
    d.text((162, 914), "MESSAGE", font=font(18, True), fill=ACCENT)
    d.text((310, 902), "型を持つことで、PoCの前に判断材料を揃えられる。", font=font(30), fill=PRIMARY)
    return img


def before_after_slide() -> Image.Image:
    img, d = base()
    header(d, "PoC開始前の課題")
    ml(d, (120, 230), "判断基準を\n後回しにしない。", 66, PRIMARY, True, 16)
    d.text((120, 400), "いきなりPoCへ進むと、成果物と判断基準が後追いになる。", font=font(28), fill=MUTED)
    left = (150, 470, 820, 835)
    right = (1100, 470, 1770, 835)
    d.rectangle(left, fill=SURFACE, outline=LINE, width=2)
    d.rectangle(right, fill=SURFACE, outline=SECONDARY, width=3)
    d.text((190, 510), "BEFORE", font=font(20, True), fill=ACCENT)
    d.text((1140, 510), "AFTER", font=font(20, True), fill=SECONDARY)
    d.text((190, 560), "いきなりPoC", font=font(40, True), fill=PRIMARY)
    d.text((1140, 560), "型から始める", font=font(40, True), fill=PRIMARY)
    for i, txt in enumerate(["ツール選定が先行", "成功条件が曖昧", "判断ログが残らない"]):
        y = 645 + i * 58
        d.ellipse((190, y + 8, 204, y + 22), fill=ACCENT)
        d.text((230, y), txt, font=font(25), fill=TEXT)
    for i, txt in enumerate(["案件理解を揃える", "成功条件を先に置く", "検証後に再利用できる"]):
        y = 645 + i * 58
        d.ellipse((1140, y + 8, 1154, y + 22), fill=SECONDARY)
        d.text((1180, y), txt, font=font(25), fill=TEXT)
    d.line((895, 648, 1025, 648), fill=ACCENT, width=5)
    d.polygon([(1025, 648), (990, 628), (990, 668)], fill=ACCENT)
    d.text((910, 700), "判断可能に", font=font(24, True), fill=ACCENT)
    return img


def process_slide() -> Image.Image:
    img, d = base()
    header(d, "推進プロセス")
    ml(d, (120, 230), "工程を分けるほど、\n戻る場所が明確になる。", 58, PRIMARY, True, 14)
    d.text((120, 390), "案件理解、課題仮説、計画、実行、監視を分けて手戻りを減らす。", font=font(27), fill=MUTED)
    steps = [
        ("案件理解", 300, 530),
        ("課題仮説", 570, 650),
        ("計画", 870, 555),
        ("実行", 1165, 675),
        ("監視", 1490, 560),
    ]
    for (label, x, y), nxt in zip(steps, steps[1:] + [None]):
        icon_circle(d, x, y, label)
        if nxt:
            nx, ny = nxt[1], nxt[2]
            d.line((x + 78, y, nx - 78, ny), fill=LINE, width=4)
            d.ellipse((nx - 88, ny - 10, nx - 68, ny + 10), fill=ACCENT)
    d.text((245, 830), "分けるほど、戻る場所が明確になる。", font=font(30), fill=SECONDARY)
    d.line((245, 876, 1260, 876), fill=LINE, width=2)
    return img


def evidence_slide() -> Image.Image:
    img, d = base()
    header(d, "成功条件")
    ml(d, (120, 230), "PoC前に\n判断基準を固定する。", 62, PRIMARY, True, 14)
    d.line((170, 570, 650, 570), fill=LINE, width=2)
    ml(d, (170, 620), "先に揃えるほど、\n検証後の議論が短くなる。", 29, SECONDARY, spacing=10)
    d.text((170, 760), "項目数ではなく、何を判断するかを主役にする。", font=font(23), fill=MUTED)
    rows = [("成功条件", "何ができたらGoか"), ("レビュー観点", "何を見ればよいか"), ("リスク", "どこで止めるか"), ("判断ログ", "なぜそう決めたか")]
    for i, (head, body) in enumerate(rows):
        y = 480 + i * 105
        d.rounded_rectangle((950, y, 1720, y + 72), radius=0, fill=SURFACE, outline=LINE, width=2)
        d.text((990, y + 19), head, font=font(28, True), fill=PRIMARY)
        d.text((1230, y + 22), body, font=font(24), fill=TEXT)
    d.text((170, 856), "評価のぶれを減らす", font=font(24), fill=SECONDARY)
    return img


def summary_slide() -> Image.Image:
    img, d = base()
    header(d, "再利用資産")
    ml(d, (120, 230), "成果物だけでなく、\n判断ログを残す。", 58, PRIMARY, True, 14)
    d.text((120, 390), "次案件で再利用できる型を残すことで、立ち上がりを軽くする。", font=font(27), fill=MUTED)
    rows = [("成果物", "提出・共有できる形にする"), ("判断ログ", "なぜ決めたかを残す"), ("再利用できる型", "次案件の入口を軽くする"), ("次の改善点", "Skillと運用へ戻す")]
    for i, (head, body) in enumerate(rows):
        y = 450 + i * 108
        d.line((150, y, 1150, y), fill=LINE, width=2)
        d.ellipse((170, y + 30, 218, y + 78), fill=SUPPORT, outline=SECONDARY, width=2)
        d.text((250, y + 32), head, font=font(31, True), fill=PRIMARY)
        d.text((525, y + 37), body, font=font(25), fill=TEXT)
    d.line((1320, 450, 1320, 860), fill=ACCENT, width=4)
    d.text((1380, 470), "残す", font=font(44, True), fill=ACCENT)
    ml(d, (1380, 548), "案件ごとの成果を\n次の型に戻す", 29, PRIMARY, spacing=10)
    d.text((1380, 730), "提出物", font=font(24), fill=MUTED)
    d.line((1480, 746, 1630, 746), fill=LINE, width=2)
    d.text((1650, 730), "再現性", font=font(24, True), fill=SECONDARY)
    return img


def main() -> None:
    save(title_slide(), "01-title.png")
    save(before_after_slide(), "02-normal.png")
    save(process_slide(), "03-normal.png")
    save(evidence_slide(), "04-normal.png")
    save(summary_slide(), "05-normal.png")


if __name__ == "__main__":
    main()
