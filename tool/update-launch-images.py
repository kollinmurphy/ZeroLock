#!/usr/bin/env python3
"""
Overwrite every image in a directory with a PNG that:
  • has the exact same pixel dimensions as the original, and
  • is rendered from a given SVG, scaled to fit (with --scale), and
  • is filled with a constant background color.

By default we *overwrite the original file path* with PNG data (even if the
extension was .jpg, etc.). Pass --rename-to-png to rename each file to .png.

Requirements:
  pip install pillow cairosvg

Examples:
  python make_pngs_from_svg.py ./images --svg logo.svg --bg "#111827"
  python make_pngs_from_svg.py ./images --svg art.svg --bg white --recursive --rename-to-png --scale 0.5
"""

import argparse
import io
import os
import sys
from pathlib import Path

from PIL import Image
import cairosvg

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}


def is_image_file(p: Path) -> bool:
    return p.is_file() and p.suffix.lower() in IMAGE_EXTS


def parse_args():
    ap = argparse.ArgumentParser(description="Overwrite images with PNGs rendered from an SVG at the same dimensions.")
    ap.add_argument("directory", type=Path, help="Directory containing images to overwrite.")
    ap.add_argument("--svg", required=True, type=Path, help="Path to the source SVG to render.")
    ap.add_argument("--bg", default="#ffffff", help="Background color (e.g., '#RRGGBB' or 'white').")
    ap.add_argument("--recursive", action="store_true", help="Recurse into subdirectories.")
    ap.add_argument("--rename-to-png", action="store_true",
                    help="Rename outputs to .png (recommended). Without this, files are overwritten in place with PNG content.")
    ap.add_argument("--scale", type=float, default=1.0,
                    help="Scale factor for SVG relative to the image dimensions (e.g., 0.5 for half-size, 2.0 for double).")
    return ap.parse_args()


def render_svg_to_png_bytes(svg_path: Path, width: int, height: int) -> bytes:
    """
    Render the SVG to a transparent PNG with the given output size.
    CairoSVG respects the SVG's preserveAspectRatio (default 'xMidYMid meet'),
    which gives us a 'contain' fit with transparent letterboxing.
    """
    return cairosvg.svg2png(
        url=str(svg_path),
        output_width=width,
        output_height=height,
        background_color="transparent",
        unsafe=True,
    )


def process_image(path: Path, svg_path: Path, bg_color: str, rename_to_png: bool, scale: float):
    try:
        original_size_bytes = path.stat().st_size
        with Image.open(path) as im:
            im.load()
            width, height = im.size

        # Apply scaling to SVG render size
        render_width = max(1, int(width * scale))
        render_height = max(1, int(height * scale))

        # Render SVG at scaled size
        png_bytes = render_svg_to_png_bytes(svg_path, render_width, render_height)
        svg_png = Image.open(io.BytesIO(png_bytes)).convert("RGBA")

        # Center scaled SVG on background canvas
        bg = Image.new("RGB", (width, height), color=bg_color)
        offset_x = (width - render_width) // 2
        offset_y = (height - render_height) // 2
        bg.paste(svg_png, (offset_x, offset_y), mask=svg_png.split()[-1])

        # Save result
        if rename_to_png:
            target = path.with_suffix(".png")
            if target.exists() and target.resolve() != path.resolve():
                target = path.with_name(path.stem + "_replaced.png")
        else:
            target = path

        tmp = target.with_name(target.name + ".tmp")
        bg.save(tmp, format="PNG", optimize=True)
        os.replace(tmp, target)

        new_size_bytes = target.stat().st_size
        print(f"[OK] {path} -> {target.name} ({width}x{height}) scale={scale}  orig={original_size_bytes}B -> {new_size_bytes}B")
    except Exception as e:
        print(f"[ERR] {path}: {e}", file=sys.stderr)


def main():
    args = parse_args()

    if not args.directory.exists() or not args.directory.is_dir():
        print(f"Directory not found: {args.directory}", file=sys.stderr)
        sys.exit(1)
    if not args.svg.exists():
        print(f"SVG not found: {args.svg}", file=sys.stderr)
        sys.exit(1)

    if args.recursive:
        paths = (p for p in args.directory.rglob("*") if is_image_file(p))
    else:
        paths = (p for p in args.directory.iterdir() if is_image_file(p))

    count = 0
    for p in paths:
        process_image(p, args.svg, args.bg, args.rename_to_png, args.scale)
        count += 1

    if count == 0:
        print("No images found to process.")


if __name__ == "__main__":
    main()
