# Art handoff, round 2: finish souvenirs and redo the traveler

This is a follow-up to [art-handoff-souvenirs-and-traveler.md](art-handoff-souvenirs-and-traveler.md).
That document still describes the formats, the pipeline and where things live.
This one lists exactly what is left and what went wrong in round 1, so it isn't
repeated. Written 2026-10-05, after the owner reviewed round 1.

## Where round 1 ended

Accepted and committed:

- 192 souvenir pictures in `assets/realistic/souvenirs/`.
- The `SouvenirCard` integration. After review it no longer skips the travel
  room's name and title labels, and the badge is resized for compact cards.
- An interim traveler sheet: slightly slimmer, but not the requested
  proportions (see Task 2).

Fixed after round 1, no action needed:

- 48 pictures had the destination name rendered above the object.
  `tools/strip_souvenir_text.py` removed it; Moldova was cleaned by hand.
- The pictures were imported lossless. They are now lossy WebP (q 0.8, which
  keeps transparency): 4.8 MB for 192.
- Tests: `tests/test_unique_artwork.gd` checks every existing picture
  (512×512, transparent corners, a valid destination id) and prints the
  count.

## What went wrong in round 1, and how to avoid it

1. **Destination names in prompts got drawn into the image.** Round 1 listed
   items as `"1. Lithuania: realistic Amber sun pin"`. **Never put place names
   in the prompt.** Describe only the object.
2. **Short names were used instead of physical descriptions,** which led to
   wrong objects. For example, "Mountain tower miniature" came out as a TV
   tower for Georgia. **Use the `prompt_description` column below as given.**
3. **Three items were dropped from the staged list** (Venice, Volcanic Realm,
   Wizard Village). Work from `docs/souvenir-art-todo.csv`, not from round
   1's batch notes in `docs/souvenir-art-prompts.md`.
4. **The traveler was declared "7 heads tall" without measuring;** it's about
   4.5. Use the measurable acceptance below.
5. **Nothing was committed, and the contact sheet had no labels.** Commit
   scoped work, and review with `tools/souvenir_contact_sheet.py`, which
   labels each item with its id, souvenir name and destination.

---

## Task 1: 96 souvenir pictures

`docs/souvenir-art-todo.csv` has 96 rows:

- **90 `missing`**: no picture yet. Includes Russia's matryoshka, Turkey,
  Thailand, the US, the Taj Mahal, Stonehenge and others.
- **6 `redo`**: replace the existing file:

| id | Problem in round 1 |
|---|---|
| GE | Shows a modern TV tower; should be a medieval stone defensive tower |
| MOON | Stray purple fragments floating around the rock |
| KY | Stingray has an elephant-like head |
| HT | Shows a drum can; should be flat cut-steel wall art |
| KM | Garbled label text on the vial |
| KP | Garbled text under the cup |

Each row's `prompt_description` is the object description to use. Cinema items
(`WIZARD_CASTLE`, `WIZARD_VILLAGE`, `WONDERLAND`, `VOLCANIC_REALM`) must be
original designs, not film props.

### Steps

1. **Generate** in grids of 16 using the prompt skeleton from round 1's
   document, **with only the descriptions**, numbered `1.` to `16.`. Keep a
   record of which id is in which cell.
2. **Slice** with `tools/slice_souvenir_batch.py` (round 1's script, already
   in the repo).
3. **Check for captions** with `tools/strip_souvenir_text.py --dry-run <ids>`.
   - Bermuda (BM) and Western Sahara (EH) are known false positives (the
     bottle cork and the glass rim); never run it on them.
   - Anything else it flags: look, then run it without `--dry-run`, or
     regenerate.
   - Captions touching the object aren't detected, so still look at every
     image.
4. **Review** with `tools/souvenir_contact_sheet.py <ids>` at 100%:
   - It's the right object, matching the description.
   - No text anywhere: no labels, no captions, no fake writing.
   - No magenta fringe, nothing cropped, nothing floating nearby.

   Regenerate failures one object per image.
5. **Import** each new `.png.import` as lossy WebP: `compress/mode=1`,
   `compress/lossy_quality=0.8`. Run
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit`
   so Godot imports them, then confirm a `.import` exists for every PNG.
6. **When all 282 exist**, make the test strict. In
   `tests/test_unique_artwork.gd`, assert `pictured == 282`.
7. **Get the owner's approval** of the review sheets for the new and redone
   items before committing.

---

## Task 2: traveler with real adult proportions

The interim `assets/realistic/memory-explorer.png` is still stocky: a big head,
broad build and short legs. Redo it to match the arcade explorer's build
(`assets/realistic/explorer.png`, side view: use it for proportions, not
pose).

### Measurable acceptance (pose 0, standing)

- **Height-to-width ratio** of the figure's alpha bounding box:
  **≥ 3.0**. Interim is 2.59; the original was 2.30. These are the
  `human[0]` values in `resources/jumping-explorer.json`.
- **Head height** (top of hair to chin) **≤ 1/6.5 of total figure height.**
  Measure it on pose 0, and record both numbers in
  `docs/jumping-character-prompts.json`.
- Same person and outfit, all 16 poses in the same order, rear view in every
  pose, 1254×1254 RGBA, every figure at least 12 px clear of its cell's
  edge, and no text.

### After generating

Follow round 1's Task 2 steps:

1. Key out the background.
2. Recompute `human` in `resources/jumping-explorer.json`: the alpha
   bounding box per cell.
3. Run `tests/test_animations.gd` headless and rendered, then
   `tools/capture_realistic.gd`.
4. Show the owner a phone-size before/after (interim versus new) before
   committing.

Leave the Kids Mode robot alone.

---

## Done means

- `tests/test_unique_artwork.gd` asserts **282** pictures and passes.
- The six redo items are replaced.
- Every new or replaced picture is approved on a labeled review sheet.
- The traveler meets the measured acceptance, is approved by the owner, and
  the animation tests pass.
- `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bash tools/check.sh`
  passes with no `ERROR` lines.
- Scoped commits pushed to `main`, with prompts and provenance appended to
  `docs/souvenir-art-prompts.md` and `docs/jumping-character-prompts.json`.
