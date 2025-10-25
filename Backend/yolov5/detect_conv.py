#!/usr/bin/env python3
"""
bstar_folder_convert.py
Convert all images in a folder to 3-channel b* images (for YOLOv5).

- Uses user-provided RGB->Lab (L, a, b) linear conversion.
- Output is b* replicated across 3 channels.
- Preserves filenames; writes to an output directory.

Usage:
  python bstar_folder_convert.py /path/to/input /path/to/output
  # Optional:
  python bstar_folder_convert.py /in /out --exts jpg,jpeg,png,bmp,tif,tiff --suffix _b3
"""

import argparse
import sys
from pathlib import Path
import cv2
import numpy as np

def rgb_to_lab_channels(image_bgr: np.ndarray):
    """
    Apply the provided RGB->Lab linear transform, returning L, a, b (uint8).
    image_bgr: HxWx3, BGR uint8 (as read by cv2)
    """
    # Convert BGR -> RGB and cast to float32
    img_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB).astype(np.float32)

    R = img_rgb[:, :, 0]
    G = img_rgb[:, :, 1]
    B = img_rgb[:, :, 2]

    # User-specified linear conversion
    L = 0.213 * R + 0.715 * G + 0.072 * B
    a = 0.326 * R - 0.499 * G + 0.173 * B + 128
    b = 0.122 * R + 0.379 * G - 0.500 * B + 128

    # Clip to [0,255] and cast back to uint8
    L = np.clip(L, 0, 255).astype(np.uint8)
    a = np.clip(a, 0, 255).astype(np.uint8)
    b = np.clip(b, 0, 255).astype(np.uint8)

    return L, a, b

def make_b3_from_b(b: np.ndarray) -> np.ndarray:
    """Stack b* into 3 channels to look like a normal RGB image to YOLOv5."""
    return cv2.merge([b, b, b])  # still BGR order for OpenCV writing, but all channels identical

def process_image(in_path: Path, out_path: Path) -> bool:
    """Read, convert, and write one image. Returns True on success."""
    img = cv2.imread(str(in_path), cv2.IMREAD_COLOR)
    if img is None:
        return False
    _, _, b = rgb_to_lab_channels(img)
    b3 = make_b3_from_b(b)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Use PNG if you want lossless; otherwise keep original suffix.
    ok = cv2.imwrite(str(out_path), b3)
    return bool(ok)

def main():
    p = argparse.ArgumentParser(description="Convert images to 3-channel b* for YOLOv5.")
    p.add_argument("input_dir", type=Path, help="Folder with source images")
    p.add_argument("output_dir", type=Path, help="Folder to write converted images")
    p.add_argument("--exts", default="jpg,jpeg,png,bmp,tif,tiff",
                   help="Comma-separated extensions to include (case-insensitive)")
    p.add_argument("--suffix", default="_b3",
                   help="Suffix to append before file extension (e.g., _b3)")
    p.add_argument("--keep_ext", action="store_true",
                   help="Keep the original extension (default). If not set, saves as .png")
    args = p.parse_args()

    exts = {("."+e.lower()).strip() for e in args.exts.split(",")}
    input_dir = args.input_dir
    output_dir = args.output_dir

    if not input_dir.exists() or not input_dir.is_dir():
        print(f"[!] Input directory not found: {input_dir}", file=sys.stderr)
        sys.exit(1)

    files = [p for p in input_dir.rglob("*") if p.is_file() and p.suffix.lower() in exts]
    if not files:
        print(f"[!] No images found in {input_dir} with extensions {sorted(exts)}")
        sys.exit(1)

    successes = 0
    failures = 0

    for f in files:
        rel = f.relative_to(input_dir)
        stem = rel.stem + args.suffix
        if args.keep_ext:
            out_name = stem + rel.suffix  # keep original extension
        else:
            out_name = stem + ".png"      # force PNG
        out_path = output_dir / rel.parent / out_name

        ok = process_image(f, out_path)
        if ok:
            successes += 1
        else:
            failures += 1
            print(f"[x] Failed: {f}", file=sys.stderr)

    print(f"[✓] Done. Converted: {successes}, Failed: {failures}")
    print(f"Output folder: {output_dir.resolve()}")

if __name__ == "__main__":
    main()
