# Handoff: realistic souvenir art and adult-proportion traveler

Two art tasks for an agent with image-generation access. Both are blocked only
on image generation: the code, data and tests around them are ready. Read the
top of `HANDOFF.md` first for project-wide rules (commit only owned changes,
never edit the player's save, run `tools/check.sh`).

Requested by the owner on 2026-10-05. Gemini (`mcp__gemini__*`) was the planned
tool; its API project had no prepaid credit at handoff time (HTTP 402
"prepayment credits are depleted"). A Gemini app subscription does not fund
the API; the AI Studio project behind the key needs credit.

---

## Task 1: a realistic picture for every souvenir

### Why

Every completed destination awards a named souvenir
(`DestinationTheme.souvenir(id)`, `scripts/core/destination_theme.gd`). All
282 destinations now have their own, unique name (enforced in
`tests/test_unique_artwork.gd`). The pictures are still flat tan line-icon
badges drawn in code over a crop of the destination photo. The owner wants
each item to look like a real object: Russia gets a real-looking matryoshka,
and so on.

### Input

`docs/souvenir-list.csv`: 282 rows, generated from the game's data:

```
id,destination,souvenir,region,theme,route
"RU","Russia","Painted nesting doll","Eastern Europe","stone","free"
```

- `souvenir` is the in-game name. Expand it into a concrete physical
  description for the prompt (material, colors, typical form), staying
  culturally accurate. For example, "Painted nesting doll" becomes "Russian
  matryoshka, glossy painted wood, red headscarf, floral apron".
- `route = cinema` rows (Hobbit Village, Wizard Castle, ...) are original
  places *inspired by* films. Their souvenirs must be original designs: no
  logos, no film-specific props or likenesses.
- If you regenerate the CSV after changing names, use the snippet in
  "Regenerating the CSV" below.

### Output

- One file per destination: `assets/realistic/souvenirs/<ID>.png`, where `<ID>`
  is the CSV `id` (e.g. `RU.png`, `HOBBIT_VILLAGE.png`).
- 512 × 512 PNG, RGBA, transparent background, object centered, about 80% of
  the frame on its longest side, with a few pixels of soft, natural edge (no
  magenta fringe).
- Consistent look across all 282: realistic studio product photo, soft even
  light from the top left, slight three-quarter front view, true-to-life
  materials. No hands, people, text, labels, price tags, ground or cast shadow.
- Write the exact prompts and the tool and model used to
  `docs/souvenir-art-prompts.md` (same provenance practice as
  `docs/unique-artwork-prompts.md`).

### Suggested pipeline

1. **Batches of 16:** generate a 4×4 grid per image at 2K resolution (about 18
   images in total), each object in its own equal cell, with the **entire
   background flat pure magenta `#FF00FF`** for keying. A tested prompt
   skeleton is at the end of this document.
2. **Slice and key:** cut each grid into cells, remove magenta (chroma key
   with a soft edge, then despill magenta from the edges), trim to the
   object's alpha bounds, pad to square, and resize to 512. Pillow and numpy
   are enough; ffmpeg is installed.
3. **Review every item at 100%:** check it's the right object, correct cultural
   details, no text or garbage, no magenta edges, and not cropped. Regenerate
   failures individually (one object per image, same style text).
4. **Contact sheet:** make a sheet of all 282 for the owner to approve
   **before** integrating.

### Integrating

All souvenir surfaces draw through `SouvenirCard` (`scripts/ui/souvenir_card.gd`):
the souvenir list, travel album, travel room (`SouvenirRoom`), journey replay
and the gift reveal (`SouvenirParcel`). The badge is drawn in `_draw()` from
about line 52: a circle at `center` (radius 39), then a per-destination motif.

- If `assets/realistic/souvenirs/<ID>.png` exists, draw that texture inside the
  badge area, slightly larger than the circle (it's a cut-out object, not a
  disc), and skip the vector motif. Keep the existing motif code as the
  fallback for any missing file.
- **Hold a reference to the loaded texture on the card** (like
  `drawn_backdrop`). A texture loaded only inside `_draw()` can be freed
  before the frame renders, which shows as a white rectangle. This is a known
  bug class in this project; see the note in `souvenir_card.gd`.
- Load on demand with `ResourceLoader.exists` / `load`. Do not preload all 282.
- **Import settings:** these PNGs have alpha. Lossy WebP (`compress/mode=1`,
  `lossy_quality=0.8`) keeps alpha and keeps the download small (282 lossless
  512² images would add about 70 MB). Check edges after import.
- **Export:** `export_presets.cfg` uses `all_resources` with an
  `exclude_filter`. Confirm `assets/realistic/souvenirs/*` is not excluded,
  then check that an exported pack contains them (`tools/verify_exported_art.gd`
  shows the pattern).
- Kids Mode uses the same souvenirs; nothing special is needed.

### Tests to add

- In `tests/test_unique_artwork.gd`: every `DestinationTheme.SOUVENIRS` id has
  `res://assets/realistic/souvenirs/<ID>.png`, it loads, is 512×512, and has
  transparent corners.
- Run `tools/capture_screens.gd` rendered (not headless) and look at
  `artifacts/screens/*-souvenirs.png`, `*-room.png` and `*-album.png` at
  375×667, 390×844 and 844×390.

---

## Task 2: adult-proportion memory-game traveler

### Why

On the phone the memory-game backpacker looks short and bulky. Measured: the
rendering is not distorted. Both the 3D billboard and the arcade world scale
are uniform. The **artwork itself** is about 3.5 heads tall with broad
shoulders and short legs (frame 0 aspect h/w = 2.30). The owner chose
**realistic adult proportions, about 7 heads tall**, same person and outfit.
The arcade's side-view explorer (`assets/realistic/explorer.png`) already looks
right and is a good reference for build and proportions.

### Asset

- `assets/realistic/memory-explorer.png`: 1254 × 1254 RGBA, a 4×4 grid of about
  313 px cells, **rear view in every pose** (back to the camera, walking up
  the path). Keep this exact layout, pose order and orientation.
- Pose order (row-major): 0 standing, 1 hand near chin, 2 hand near forehead,
  3 worried; 4 crouch, 5 rising jump, 6 midair arms wide, 7 landing crouch;
  8 raised-fist celebration, 9 taking the passport from a pocket, 10 holding
  the open passport, 11 stamping it; 12 losing balance, 13 stumbling, 14
  falling forward away from the camera, 15 prone face-down.
- The previous full prompt is in `docs/jumping-character-prompts.json`. Reuse
  its constraints and change only the body: smaller head relative to the
  body, longer legs and torso, slimmer and narrower shoulders, natural adult
  anatomy. Same curly brown hair, white T-shirt, navy cargo shorts, brown
  hiking boots, tan canvas backpack.
- Do **not** change the Kids Mode robot (`robot-explorer.png`).

### After generating

1. Make the background transparent (magenta key as in Task 1). Every figure
   must stay fully inside its cell with at least 12 px of margin.
2. **Re-measure the pose bounds.** `resources/jumping-explorer.json` holds
   `{"human": [[left, top, right, bottom] x 16], "robot": [...]}`: the alpha
   bounding box of each cell in sheet pixels. `Traveler.align_portrait()`
   (`scripts/game/traveler.gd`) uses it to size the sprite and put the boots
   on the stone. Recompute only `human` (alpha > a small threshold, per cell).
   `tools/measure_traveler_motion.gd` shows the same idea for other sheets.
3. The sprite height is normalized from pose 0
   (`pixel_size = 2.65 / (idle_height - 4)`), so the taller figure keeps the
   same in-world height and simply looks slimmer. Confirm the boots still
   land on the stone in every pose.
4. Update `docs/jumping-character-prompts.json` with the new prompt and tool.

### Checks

- `tests/test_animations.gd` (rendered and headless) and the full `tools/check.sh`.
- `tools/capture_realistic.gd` captures standing, mid-jump, Kids and Infinite.
  Compare them against the old `artifacts/realistic-memory-path-jump.png`.
- Show the owner a before/after crop at phone size before committing.

---

## Done means

- 282 souvenir PNGs approved by the owner from the contact sheet, integrated
  with the fallback kept, and the new tests passing.
- The new traveler sheet approved, bounds re-measured, and animation tests and
  `tools/check.sh` passing.
- Prompts and provenance recorded in docs. Scoped commits, pushed to `main`
  (the owner has authorized pushing in this project).
- Optionally upload a new TestFlight build: `tools/release_iphone.sh` with the
  `ASC_*` variables described in `HANDOFF.md`, then attach it to version 1.0.

## Prompt skeleton (Task 1)

```
A 4x4 grid of sixteen separate travel souvenir objects, each one photographed as a
realistic studio product photo: soft even lighting, slight three-quarter front view,
natural materials and textures, true-to-life colors, no hands, no people, no text,
no labels, no price tags. Each object is centered in its own equal square cell, fully
visible with generous empty margin, all objects a similar size within their cells.
The ENTIRE background of the whole image, behind and between every object, is flat
solid pure magenta (#FF00FF) with no gradients, no shadows on the background, no
reflections, no floor, no grid lines. Order, left to right, top to bottom:
1 <description>; 2 <description>; ... 16 <description>.
```

## Regenerating the CSV

Run headless with `--script` from the project root after any souvenir rename:

```gdscript
extends SceneTree
func _initialize() -> void:
	var file := FileAccess.open("res://docs/souvenir-list.csv", FileAccess.WRITE)
	file.store_line("id,destination,souvenir,region,theme,route")
	var ids := GameCatalog.DESTINATIONS.keys()
	ids.sort()
	for id in ids:
		var route := "special" if id in GameCatalog.PREMIUM_DESTINATIONS else "cinema" if id in GameCatalog.CINEMA_DESTINATIONS else "free"
		var row := [id, GameCatalog.country_name(id), DestinationTheme.souvenir(id), str(GameCatalog.DESTINATIONS[id].get("region", "")), DestinationTheme.style(id), route]
		file.store_line(",".join(row.map(func(v): return "\"" + str(v).replace("\"", "'") + "\"")))
	quit()
```
