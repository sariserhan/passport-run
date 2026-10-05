#!/usr/bin/env python3
"""Labeled review sheets of the souvenir pictures (id, souvenir name, destination).

Writes artifacts/souvenirs-review-N.png, 48 items per sheet, for owner approval.
Usage: tools/souvenir_contact_sheet.py [ID ...]   (default: every existing picture)
Needs Pillow.
"""
import csv, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 15)
CELL, COLUMNS, PER_SHEET = 200, 8, 48

rows = [r for r in csv.DictReader(open(ROOT / "docs/souvenir-list.csv"))
        if (ROOT / f"assets/realistic/souvenirs/{r['id']}.png").exists() and (len(sys.argv) < 2 or r["id"] in sys.argv[1:])]
for page in range(0, len(rows), PER_SHEET):
    chunk = rows[page:page + PER_SHEET]
    sheet = Image.new("RGB", (COLUMNS * CELL, ((len(chunk) + COLUMNS - 1) // COLUMNS) * (CELL + 40)), "#1b2a3a")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(chunk):
        x, y = (index % COLUMNS) * CELL, (index // COLUMNS) * (CELL + 40)
        picture = Image.open(ROOT / f"assets/realistic/souvenirs/{row['id']}.png").convert("RGBA").resize((CELL - 10, CELL - 10))
        sheet.paste(picture, (x + 5, y + 5), picture)
        draw.text((x + 5, y + CELL - 2), f"{row['id']}: {row['souvenir']}"[:26], fill="#f1f5f9", font=FONT)
        draw.text((x + 5, y + CELL + 16), row["destination"][:26], fill="#94a3b8", font=FONT)
    out = ROOT / f"artifacts/souvenirs-review-{page // PER_SHEET + 1}.png"
    sheet.save(out)
    print(out.relative_to(ROOT))
