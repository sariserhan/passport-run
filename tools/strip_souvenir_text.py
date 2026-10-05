#!/usr/bin/env python3
"""Remove captions the image model drew ABOVE a souvenir (e.g. the country name).

The object is the largest opaque connected shape; any separate shape lying entirely
above it is treated as stray text and erased. The object is then re-centered at ~80%
of a 512x512 transparent canvas, matching tools/slice_souvenir_batch.py.
Usage: tools/strip_souvenir_text.py [--dry-run] [ID ...]   (default: every souvenir)
Needs Pillow, numpy and scipy.
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

DIR = Path(__file__).resolve().parents[1] / "assets/realistic/souvenirs"
SIZE, FILL = 512, 0.8

def clean(path: Path, dry: bool) -> bool:
    image = Image.open(path).convert("RGBA")
    pixels = np.array(image)
    alpha = pixels[:, :, 3]
    labels, count = ndimage.label(alpha > 8)
    if count < 2: return False
    sizes = ndimage.sum(np.ones_like(alpha), labels, range(1, count + 1))
    main = int(np.argmax(sizes)) + 1
    main_top = np.where(labels == main)[0].min()
    removed = False
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        if index != main and box[0].stop <= main_top: # entirely above the object
            pixels[labels == index, 3] = 0
            removed = True
    if not removed or dry: return removed
    ys, xs = np.where(pixels[:, :, 3] > 8)
    crop = Image.fromarray(pixels).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    scale = SIZE * FILL / max(crop.size)
    crop = crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(crop, ((SIZE - crop.width) // 2, (SIZE - crop.height) // 2), crop)
    canvas.save(path)
    return True

if __name__ == "__main__":
    dry = "--dry-run" in sys.argv
    ids = [a for a in sys.argv[1:] if not a.startswith("--")]
    paths = [DIR / f"{i}.png" for i in ids] if ids else sorted(DIR.glob("*.png"))
    changed = [p.stem for p in paths if clean(p, dry)]
    print(("would clean " if dry else "cleaned ") + str(len(changed)) + ": " + " ".join(changed))
