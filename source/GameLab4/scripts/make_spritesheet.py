#!/usr/bin/env python3
import argparse
from pathlib import Path
from PIL import Image


def main():
    parser = argparse.ArgumentParser(
        description="Combine PNG files from a directory into a spritesheet grid."
    )
    parser.add_argument("output", help="Output PNG filename (e.g., spritesheet.png)")
    parser.add_argument("input_dir", help="Directory containing input PNG files")
    parser.add_argument("--width", type=int, default=64, help="Cell width in pixels (default: 64)")
    parser.add_argument("--height", type=int, default=64, help="Cell height in pixels (default: 64)")
    args = parser.parse_args()

    input_path = Path(args.input_dir)
    if not input_path.is_dir():
        raise ValueError(f"Input directory does not exist: {input_path}")

    png_files = sorted(input_path.glob("*.png"))
    if not png_files:
        print("No PNG files found in input directory.")
        return

    cols = 12
    rows = (len(png_files) + cols - 1) // cols

    sheet_width = cols * args.width
    sheet_height = rows * args.height
    sheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    for idx, png_file in enumerate(png_files):
        img = Image.open(png_file).convert("RGBA")
        if img.width > args.width or img.height > args.height:
            img = img.resize((args.width, args.height), Image.Resampling.LANCZOS)
        elif img.width < args.width or img.height < args.height:
            img = img.resize((args.width, args.height), Image.Resampling.LANCZOS)

        col = idx % cols
        row = idx // cols
        x = col * args.width
        y = row * args.height
        sheet.paste(img, (x, y))

    sheet.save(args.output)
    print(
        f"Saved spritesheet with {len(png_files)} images "
        f"({cols}x{rows} grid) to {args.output}"
    )


if __name__ == "__main__":
    main()
