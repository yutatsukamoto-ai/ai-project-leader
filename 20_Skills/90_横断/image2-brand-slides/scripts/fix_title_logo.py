#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def font(size: int) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default(size=size)


def load_logo(path: Path) -> Image.Image:
    logo = Image.open(path).convert("RGBA")
    bbox = logo.getbbox()
    return logo.crop(bbox) if bbox else logo


def paste_logo(base: Image.Image, logo: Image.Image, x: int, y: int, width: int) -> None:
    ratio = width / logo.width
    resized = logo.resize((width, int(logo.height * ratio)), Image.Resampling.LANCZOS)
    base.alpha_composite(resized, (x, y))


def cover(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str) -> None:
    draw.rectangle(box, fill=fill)


def fix_slide(
    src: Path,
    out: Path,
    logo: Image.Image | None,
    title: str,
    bg: str,
    title_color: str,
    accent: str,
    title_left: float,
    title_top: float,
    logo_right: float,
    logo_top: float,
    logo_width: float,
    header_band: float,
) -> None:
    img = Image.open(src).convert("RGBA")
    draw = ImageDraw.Draw(img)
    w, h = img.size

    title_x = int(w * title_left)
    title_y = int(h * title_top)
    logo_w = int(w * logo_width)
    logo_x = int(w * (1 - logo_right)) - logo_w
    logo_y = int(h * logo_top)

    if header_band > 0:
        cover(draw, (0, 0, w, int(h * header_band)), bg)
    else:
        cover(draw, (0, 0, title_x + int(w * 0.38), title_y + int(h * 0.08)), bg)
        if logo is not None:
            cover(draw, (logo_x - int(w * 0.03), 0, w, logo_y + int(logo_w * 0.34)), bg)

    title_font = font(max(18, int(h * 0.03)))
    draw.text((title_x, title_y), title, font=title_font, fill=title_color)
    y_line = title_y + int(h * 0.047)
    draw.line((title_x, y_line, title_x + int(w * 0.04), y_line), fill=accent, width=max(2, int(h * 0.003)))

    if logo is not None:
        paste_logo(img, logo, logo_x, logo_y, logo_w)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(out, "PNG")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fix only normal-slide title, underline, and optional logo placement after Image2 generation."
    )
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--titles", required=True, type=Path, help="JSON array with file and title fields.")
    parser.add_argument("--logo", type=Path)
    parser.add_argument("--title-only", action="store_true", help="No-logo mode. Redraw title and underline only.")
    parser.add_argument("--bg", default="#FBFAFD")
    parser.add_argument("--title-color", default="#17131F")
    parser.add_argument("--accent", default="#482888")
    parser.add_argument("--title-left", default=0.052, type=float)
    parser.add_argument("--title-top", default=0.052, type=float)
    parser.add_argument("--logo-right", default=0.052, type=float)
    parser.add_argument("--logo-top", default=0.048, type=float)
    parser.add_argument("--logo-width", default=0.13, type=float)
    parser.add_argument(
        "--header-band",
        default=0.0,
        type=float,
        help="Cover this top fraction before redrawing header. Use only for header artifacts.",
    )
    args = parser.parse_args()

    if args.title_only and args.logo:
        raise SystemExit("--title-only cannot be used with --logo")
    if not args.title_only and not args.logo:
        raise SystemExit("Provide --logo, or use --title-only for no-logo mode")

    logo = None if args.title_only else load_logo(args.logo)
    title_specs = json.loads(args.titles.read_text(encoding="utf-8"))

    args.output_dir.mkdir(parents=True, exist_ok=True)
    spec_files = {spec["file"] for spec in title_specs}

    for src in args.input_dir.glob("*.png"):
        if src.name not in spec_files:
            shutil.copy2(src, args.output_dir / src.name)

    for spec in title_specs:
        file_name = spec["file"]
        if "page" in spec:
            raise SystemExit("titles.json must not include page values")
        fix_slide(
            args.input_dir / file_name,
            args.output_dir / file_name,
            logo,
            spec["title"],
            args.bg,
            args.title_color,
            args.accent,
            args.title_left,
            args.title_top,
            args.logo_right,
            args.logo_top,
            args.logo_width,
            args.header_band,
        )


if __name__ == "__main__":
    main()
