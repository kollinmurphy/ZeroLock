#!/usr/bin/env python3
"""
Round the corners of every image in a directory, making the corners transparent.

Requirements:
  pip install pillow

Examples:
  python round_corners.py ./images
  python round_corners.py ./images --recursive --radius-frac 0.2
  python round_corners.py ./images --radius 24 --overwrite
"""

import argparse
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageChops

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}

def is_image_file(p: Path) -> bool:
    return p.is_file() and p.suffix.lower() in IMAGE_EXTS

def parse_args():
    ap = argparse.ArgumentParser(description="Round corners and make them transparent for images in a directory.")
    ap.add_argument("directory", type=Path, help="Directory containing images.")
    ap.add_argument("--recursive", action="store_true", help="Process subfolders recursively.")
    ap.add_argument("--radius", type=int, default=None,
                    help="Corner radius in pixels. If omitted, --radius-frac is used.")
    ap.add_argument("--radius-frac", type=float, default=0.12,
                    help="Corner radius as a fraction of the shorter side (default: 0.12). Ignored if --radius is set.")
    ap.add_argument("--overwrite", action="store_true",
                    help="Overwrite the original file path with PNG data. Otherwise, write alongside as .png.")
    ap.add_argument("--suffix", default="_rounded",
                    help="Suffix for output filename when not overwriting (default: _rounded).")
    return ap.parse_args()

def rounded_mask(size, radius):
    """High-quality anti-aliased rounded-rectangle mask."""
    w, h = size
    # Draw at 4x and downsample for smooth edges
    scale = 4
    W, H, R = w * scale, h * scale, max(0, int(radius * scale))
    mask_l = Image.new("L", (W, H), 0)
    draw = ImageDraw.Draw(mask_l)
    # Pillow's rounded_rectangle handles all corners
    draw.rounded_rectangle([(0, 0), (W, H)], radius=R, fill=255)
    return mask_l.resize((w, h), Image.LANCZOS)

def compute_radius(w, h, px, frac):
    if px is not None:
        return max(0, int(px))
    return max(0, int(min(w, h) * frac))

def process_image(path: Path, radius_px: int | None, radius_frac: float, overwrite: bool, suffix: str):
    try:
        with Image.open(path) as im:
            im.load()
            w, h = im.size

            r = compute_radius(w, h, radius_px, radius_frac)
            mask = rounded_mask((w, h), r)

            # Ensure RGBA and apply mask (preserve existing alpha if present)
            rgba = im.convert("RGBA")
            existing_alpha = rgba.getchannel("A")
            combined_alpha = ImageChops.multiply(existing_alpha, mask)
            result = rgba.copy()
            result.putalpha(combined_alpha)

            if overwrite:
                target = path  # overwrite path (content becomes PNG)
                tmp = target.with_name(target.name + ".tmp")
                result.save(tmp, format="PNG", optimize=True)
                os.replace(tmp, target)
            else:
                target = path.with_name(f"{path.stem}{suffix}.png")
                tmp = target.with_name(target.name + ".tmp")
                result.save(tmp, format="PNG", optimize=True)
                os.replace(tmp, target)

            print(f"[OK] {path.name}  ->  {target.name}  ({w}x{h}, radius={r})")
    except Exception as e:
        print(f"[ERR] {path}: {e}")

def main():
    args = parse_args()
    if not args.directory.exists() or not args.directory.is_dir():
        raise SystemExit(f"Directory not found: {args.directory}")

    if args.recursive:
        files = (p for p in args.directory.rglob("*") if is_image_file(p))
    else:
        files = (p for p in args.directory.iterdir() if is_image_file(p))

    count = 0
    for p in files:
        process_image(p, args.radius, args.radius_frac, args.overwrite, args.suffix)
        count += 1

    if count == 0:
        print("No images found to process.")

if __name__ == "__main__":
    main()
