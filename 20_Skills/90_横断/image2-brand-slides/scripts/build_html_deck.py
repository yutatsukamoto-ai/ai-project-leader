#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import json
import shutil
from pathlib import Path


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def load_titles(path: Path | None) -> dict[str, str]:
    if path is None:
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    titles: dict[str, str] = {}
    for item in data:
        file_name = str(item.get("file", "")).strip()
        title = str(item.get("title", "")).strip()
        if file_name and title:
            titles[Path(file_name).name] = title
    return titles


def discover_slides(slides_dir: Path, titles: dict[str, str]) -> list[dict[str, str]]:
    files = sorted(
        p for p in slides_dir.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS
    )
    slides: list[dict[str, str]] = []
    for p in files:
        fallback = p.stem.replace("-", " ").replace("_", " ").strip()
        slides.append({
            "source": str(p),
            "name": p.name,
            "title": titles.get(p.name, fallback),
        })
    return slides


def copy_slides(slides: list[dict[str, str]], output_dir: Path) -> list[dict[str, str]]:
    slides_out = output_dir / "slides"
    slides_out.mkdir(parents=True, exist_ok=True)
    copied: list[dict[str, str]] = []
    for slide in slides:
        src = Path(slide["source"])
        dst = slides_out / slide["name"]
        if src.resolve() != dst.resolve():
            shutil.copy2(src, dst)
        copied.append({
            "file": f"slides/{dst.name}",
            "title": slide["title"],
        })
    return copied


def write_manifest(path: Path, title: str, slides: list[dict[str, str]]) -> None:
    data = {
        "title": title,
        "format": "image-html-deck",
        "slide_count": len(slides),
        "slides": slides,
    }
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def render_html(title: str, slides: list[dict[str, str]]) -> str:
    safe_title = html.escape(title)
    first_slide = slides[0]
    first_file = html.escape(first_slide["file"], quote=True)
    first_title = html.escape(first_slide["title"], quote=True)
    slides_json = json.dumps(slides, ensure_ascii=False)
    return f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{safe_title}</title>
  <style>
    :root {{
      color-scheme: light dark;
      --bg: #111214;
      --panel: rgba(17, 18, 20, 0.82);
      --text: #f7f7f5;
      --muted: #b8bbb8;
      --accent: #d6e4ff;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      min-height: 100vh;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Noto Sans JP", sans-serif;
      overflow: hidden;
    }}
    main {{
      width: 100vw;
      height: 100vh;
      display: grid;
      place-items: center;
      padding: 44px 56px;
    }}
    .stage {{
      width: min(100%, calc(100vh * 16 / 9 - 96px));
      aspect-ratio: 16 / 9;
      position: relative;
      background: #fff;
      box-shadow: 0 24px 80px rgba(0, 0, 0, 0.42);
    }}
    .stage img {{
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
      background: #fff;
    }}
    .nav {{
      position: fixed;
      inset: auto 0 0 0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 14px 18px;
      background: linear-gradient(to top, var(--panel), transparent);
      pointer-events: none;
    }}
    .nav button, .thumb-toggle {{
      pointer-events: auto;
      border: 1px solid rgba(255, 255, 255, 0.2);
      background: rgba(255, 255, 255, 0.08);
      color: var(--text);
      min-width: 44px;
      height: 36px;
      padding: 0 12px;
      border-radius: 6px;
      font: inherit;
      cursor: pointer;
    }}
    .meta {{
      min-width: 180px;
      text-align: center;
      color: var(--muted);
      font-size: 13px;
      letter-spacing: 0;
    }}
    .thumbs {{
      position: fixed;
      top: 0;
      right: 0;
      width: min(320px, 88vw);
      height: 100vh;
      overflow: auto;
      padding: 16px;
      background: var(--panel);
      transform: translateX(100%);
      transition: transform 180ms ease;
    }}
    .thumbs.open {{ transform: translateX(0); }}
    .thumb {{
      width: 100%;
      margin: 0 0 12px;
      border: 1px solid rgba(255, 255, 255, 0.16);
      background: rgba(255, 255, 255, 0.06);
      color: var(--text);
      border-radius: 6px;
      padding: 8px;
      text-align: left;
      cursor: pointer;
    }}
    .thumb.active {{ outline: 2px solid var(--accent); }}
    .thumb img {{
      width: 100%;
      aspect-ratio: 16 / 9;
      object-fit: cover;
      display: block;
      background: #fff;
      border-radius: 3px;
      margin-bottom: 6px;
    }}
    .thumb span {{
      display: block;
      color: var(--muted);
      font-size: 12px;
      line-height: 1.4;
    }}
    .print-root {{ display: none; }}
    @media (max-width: 720px) {{
      main {{ padding: 26px 12px 70px; }}
      .stage {{ width: 100%; }}
      .meta {{ min-width: 120px; }}
    }}
    @media print {{
      @page {{ size: 16in 9in; margin: 0; }}
      body {{ background: #fff; overflow: visible; }}
      main, .stage {{ display: block; width: 100vw; height: 100vh; padding: 0; box-shadow: none; }}
      main {{ display: none; }}
      .nav, .thumbs {{ display: none !important; }}
      .print-root {{ display: block; }}
      .print-slide {{ page-break-after: always; width: 100vw; height: 100vh; }}
      .print-slide img {{ width: 100%; height: 100%; object-fit: contain; display: block; }}
    }}
  </style>
</head>
<body>
  <main>
    <div class="stage"><img id="slide" src="{first_file}" alt="{first_title}"></div>
  </main>
  <div class="nav">
    <button id="prev" type="button" aria-label="Previous slide">Prev</button>
    <div class="meta"><span id="counter"></span></div>
    <button id="next" type="button" aria-label="Next slide">Next</button>
    <button class="thumb-toggle" id="toggle" type="button" aria-label="Toggle thumbnails">List</button>
  </div>
  <aside class="thumbs" id="thumbs" aria-label="Slide list"></aside>
  <script>
    const slides = {slides_json};
    let index = 0;
    const img = document.getElementById('slide');
    const counter = document.getElementById('counter');
    const thumbs = document.getElementById('thumbs');

    function clamp(n) {{
      return Math.max(0, Math.min(slides.length - 1, n));
    }}

    function show(n) {{
      index = clamp(n);
      const slide = slides[index];
      img.src = slide.file;
      img.alt = slide.title || `Slide ${{index + 1}}`;
      counter.textContent = `${{index + 1}} / ${{slides.length}}`;
      [...thumbs.querySelectorAll('.thumb')].forEach((el, i) => {{
        el.classList.toggle('active', i === index);
      }});
    }}

    function buildThumbs() {{
      thumbs.innerHTML = '';
      slides.forEach((slide, i) => {{
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'thumb';
        const thumbImg = document.createElement('img');
        thumbImg.src = slide.file;
        thumbImg.alt = '';
        const label = document.createElement('span');
        label.textContent = `${{i + 1}}. ${{slide.title || ''}}`;
        button.appendChild(thumbImg);
        button.appendChild(label);
        button.addEventListener('click', () => {{ show(i); thumbs.classList.remove('open'); }});
        thumbs.appendChild(button);
      }});
    }}

    document.getElementById('prev').addEventListener('click', () => show(index - 1));
    document.getElementById('next').addEventListener('click', () => show(index + 1));
    document.getElementById('toggle').addEventListener('click', () => thumbs.classList.toggle('open'));
    document.addEventListener('keydown', (event) => {{
      if (event.key === 'ArrowLeft') show(index - 1);
      if (event.key === 'ArrowRight' || event.key === ' ') show(index + 1);
      if (event.key === 'Home') show(0);
      if (event.key === 'End') show(slides.length - 1);
      if (event.key === 'Escape') thumbs.classList.remove('open');
    }});
    document.querySelector('.stage').addEventListener('click', () => show(index + 1));
    buildThumbs();
    show(0);
  </script>
  <div class="print-root">
    {"".join(f'<section class="print-slide"><img src="{html.escape(slide["file"])}" alt="{html.escape(slide["title"])}"></section>' for slide in slides)}
  </div>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build a static HTML slide deck from one-image-per-slide files."
    )
    parser.add_argument("--slides-dir", required=True, help="Directory containing final slide images.")
    parser.add_argument("--output-dir", required=True, help="Directory for index.html, manifest.json, and slides/.")
    parser.add_argument("--title", default="Image2 Slide Deck", help="Deck title for HTML metadata.")
    parser.add_argument("--titles", help="Optional titles.json with {file,title} entries.")
    args = parser.parse_args()

    slides_dir = Path(args.slides_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    if not slides_dir.is_dir():
        raise SystemExit(f"slides-dir is not a directory: {slides_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    titles = load_titles(Path(args.titles).expanduser().resolve() if args.titles else None)
    discovered = discover_slides(slides_dir, titles)
    if not discovered:
        raise SystemExit(f"no slide images found in: {slides_dir}")

    slides = copy_slides(discovered, output_dir)
    write_manifest(output_dir / "manifest.json", args.title, slides)
    (output_dir / "index.html").write_text(render_html(args.title, slides), encoding="utf-8")
    print(f"built HTML deck: {output_dir / 'index.html'}")
    print(f"slides: {len(slides)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
