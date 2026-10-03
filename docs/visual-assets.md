# Reference graphics pass — 2026-10-02

Compared `image1.png` and `image2.png` with actual game screenshots. The reference's defining elements are a close perspective stone path over water, rich destination scenery, a detailed backpacker, warm cinematic lighting, rounded tile edges and bold playful type.

The playable scene now uses perspective: the complete path fits during memorization, then the camera moves closer for tapping. Gameplay geometry, collision, deterministic paths, tile state indicators and scores are unchanged. Rounded stone meshes are shared by size, with one small shared stone texture. Destination backgrounds are illustrative composites, not geographically literal maps.

## Assets and provenance

Generated with the built-in image-generation tool, copied into the repository and inspected:

- `assets/backdrops/FR.png`, `TR.png`, `JP.png`, `EG.png`, `US.png`: destination matte paintings.
- `assets/menu-key-art.png`: main-menu travel illustration.
- `assets/backpacker.png`: original transparent character artwork; `assets/backpacker-poses.png`: the 16-pose animation atlas used in play.

This is a hybrid presentation: static illustrated destination backdrops and a camera-facing backpacker sprite over actual interactive 3D tiles. The backpacker now uses 16 thinking, jump, fall, celebration, pocket, open-passport and stamping poses, with movement and pose timing driven by actual game state. It is still a sprite atlas rather than a fully rigged 3D character. Kids retains its procedural explorer robot. Full skeletal character animation, dynamic environment parallax and physical-device performance remain future visual work. Do not describe this as exact reference parity or a finished art pipeline.

`assets/fonts/LilitaOne-Regular.ttf` is the openly licensed Lilita One display face, sourced from the Google Fonts repository. Its license is included as `assets/fonts/OFL.txt`. Body text uses Godot's default font. Image art was generated for this project; the supplied references were inspected for visual direction, not copied into runtime screens.

## Final prompt set

Backdrop prompt: “Full-bleed portrait 2:3 matte painting for a premium charming 3D mobile travel adventure. Rich detailed architecture, dimensional soft light, atmospheric depth, believable textured materials and painterly finish. Camera slightly above water looking into distant city, horizon 30% from top. Center 45% and lower half open blue/turquoise water with reflections; landmarks, buildings and trees in upper half and side edges. No path, stepping stones, platforms, characters, interface, words or watermark.”

Destination variants: Paris/Seine and Eiffel Tower at warm sunset; Istanbul/Bosphorus, domed mosque and minarets in Mediterranean daylight; Japanese riverside village, vermilion pagoda, blossoms and distant Fuji at pink sunrise; Egyptian Nile, pyramids, palms and sandstone ruins at golden hour; New York harbor, Statue of Liberty and Manhattan in bright daylight. These are stylized country compositions.

Menu prompt: “Wide 3:2 travel adventure key art, no text or UI. Charming backpacker from behind, brown tousled hair, cream shirt, navy shorts, boots and detailed brown backpack, standing on a stone overlook. Curved world of lush islands with Eiffel Tower, Statue of Liberty, pyramids, pagoda and Istanbul domes, cyan sky, clouds, polished animated-film aesthetic.”

Backpacker prompt: “Transparent full-body rear-view game sprite. Charming young traveler, tousled brown hair, cream short-sleeve shirt, navy knee-length shorts, white socks, brown boots and detailed canvas backpack with padded straps, leather flap, buckles and pouch. Premium polished animated-feature rendering, soft light, slightly elevated camera, natural standing pose, clear silhouette; no floor, landscape, UI, words or watermark.”

## Verification

Offline suites check complete preview framing at every difficulty, real touch dispatch, jump/fall/retry lifecycle, mobile dialog scrolling, contrast settings and resource inclusion. Rendered tests use bounded state waits and resume if desktop automation steals focus; explicit pause tests still verify that the preview clock freezes. See build status for current evidence. Native packaging must include all seven image assets and the font; do not ship source references or test screenshots.

Godot canvas layering was checked against the [Godot 4.5 Environment documentation](https://docs.godotengine.org/en/4.5/classes/class_environment.html#class-environment-property-background-canvas-max-layer); Context7 was unavailable in this session.

## Character animation follow-up

The built-in image-generation tool produced a strict 4×4 transparent atlas using the original backpacker as its reference. Prompt: preserve the same character/costume and consistent scale; row one relaxed/thinking/chin/head-scratch/hands-on-hips, row two crouch/airborne/descent/landing, row three victory/pocket/open-passport/stamp, row four startled/flailing/falling/tumbling; full-body poses, no labels, no grid, no background. Each pose occupies one equal cell.

Country completion now plays victory, pocket and open-passport gestures, then an enlarged actual-country passport stamp. The sequence pauses/resumes, respects reduced motion and cancels on departure without duplicate awards. The capture tool `tools/capture_motion.gd` saves a desktop animation demo; this is visual evidence, not mobile frame-time profiling.
# Expanded world scenery — 2026-10-02

Saved asset: `assets/world-backdrops.png` and its import settings. Generated with the built-in imagegen tool; final output is 1024×1536, a 4×4 atlas of 256×384 paintings. No image-editing scripts were used. The five original country paintings remain. `GameCatalog.backdrop` selects a regional atlas cell for other destinations and shares it between gameplay, travel, stickers and the passport animation. These are stylized regional scenes; countries sharing a cell do not have distinct landmark art yet. Preview screenshots are `artifacts/destination-*.png`.

Final prompt:

Use case: stylized-concept. Asset type: production mobile travel-game background atlas. Create ONE precisely aligned 4-column by 4-row atlas, 2048 x 3072 pixels overall. Every cell is a complete portrait 512x768 matte painting, no borders or gutters, no labels, no text. Consistent sophisticated colorful hand-painted 3D storybook adventure style, detailed textured stone and architecture, soft sunlight, atmospheric perspective. Each cell has landmarks in upper half and a calm open expanse of water or mist in lower half for separately rendered gameplay tiles, no characters, no tiles, no UI. Exactly row-major cells: 1 Bavarian castle alpine forest (Germany/central Europe), 2 Rome colosseum Mediterranean coast (Italy/southern Europe), 3 colorful onion-domed Russian architecture (Russia/eastern Europe), 4 winding Great Wall and misty green mountains (China/east Asia); 5 Dubai futuristic needle skyline desert waterfront (UAE), 6 Sydney Opera House harbor (Australia), 7 Norwegian fjord mountains colorful timber houses (Nordic), 8 lush Brazilian rainforest coastal city Sugarloaf mountain (Brazil); 9 Greek white blue-domed island village Aegean sea (Greece), 10 Spanish warm terracotta plaza Moorish palace garden (Spain/Portugal), 11 Central Asian steppe snow mountains yurts (Mongolia/Kazakhstan), 12 ornate Thai temple tropical palms and turquoise river (Thailand/southeast Asia); 13 African savanna acacia and distant rocky peaks (Kenya/Africa), 14 Andes mountains terraced hillside colorful village (Bolivia/Andean South America), 15 Mexican colorful colonial town stone stepped pyramid tropical landscape (Mexico/Central America), 16 Caribbean turquoise bay palms brightly painted fishing village (Jamaica/islands). No random layout changes. Rich polished game art, coherent perspective, distinctly different cells.

## Expanded landmark, fantasy and cinema scenes

Eight new four-scene atlases provide individual backgrounds for all 32 paid locations. Polar territories share the aurora scene. Asset paths, exact prompts and built-in image-generation provenance are recorded in [destination art prompts](destination-art-prompts.md). Rendered 390×844 screenshots cover every new scene in `artifacts/special-*.png` and `artifacts/cinema-*.png`. Ownership in these captures uses the excluded test simulation, not a live purchase.
# Infinite scenery — 2026-10-02

`assets/infinite-backdrop.png` was generated with the built-in image-generation tool and inspected in the rendered game. Infinite uses this dedicated dreamscape in every section, with no country/city label or destination scenery. The path generator and bounded tile window remain unchanged.

Exact prompt: Original production background for an Infinite Memory mobile game, portrait 2:3, rich polished painterly 3D adventure aesthetic matching a detailed backpacker game. An endless dreamlike turquoise mist ocean, soft luminous abstract floating rock arches at far side edges, subtle glowing particles, layered lavender and teal clouds disappearing into an infinite horizon. Upper third airy atmospheric sky; center and lower half calm open turquoise water and mist for separately overlaid stepping-stone gameplay. NO city, NO buildings, NO world map, NO flags, NO country landmarks, NO planet, NO characters, NO stepping stones, NO UI, NO text. Detailed textured surfaces at side edges, warm gentle golden rim light, beautiful depth, readable calm composition.

## Unique destination artwork — 2026-10-03

The user requires a unique image for every destination. Afghanistan had incorrectly inherited a Thai-temple regional scene; it now has its own Hindu Kush-inspired valley painting at `assets/backdrops/AF.png`. All other shared free-country scenery is replaced: 244 distinct paintings across 16 atlases plus six dedicated country PNGs. With the existing 32 paid scenes, every one of the 282 destinations resolves to a different image. Infinite retains its separate dreamscape.

`GameCatalog.backdrop()` prioritizes dedicated PNGs, then the stable ID-to-atlas/cell mapping in `resources/geography/artwork.json`, then existing paid artwork. Every gameplay/passport/sticker/travel surface already uses this lookup. Atlases load on demand. Country data, routes, catalog and balance versions are unchanged. Generated images are stylized country-inspired compositions; they are not exact landmark photographs. Full prompts and built-in imagegen provenance are recorded in `docs/unique-artwork-prompts.md`.

`tests/test_unique_artwork.gd` checks all 282 resolved images, region bounds, uniqueness and the Afghanistan correction; added to `tools/check.sh`. Rendered 390×844 checks capture AF, TH, IN, PK, IR, MY, GL, AQ and passport in `artifacts/unique-*.png`. Physical-device acceptance remains deferred to the user.

## Arcade animation sheet

Saved runtime asset: `assets/arcade-poses.png`. Generated using the built-in image generation tool with `assets/backpacker-poses.png` as the character reference. Transparent 4 by 4 walking, throwing, blaster and falling poses; runtime mirrors walking for left movement. Exact prompt:

Use case: stylized-concept. Create ONE transparent 4-column by 4-row sprite sheet for the referenced backpacker character. Supporting reference: assets/backpacker-poses.png defines character identity only. Preserve cream shirt, blue shorts, brown boots and leather backpack, short brown hair, polished storybook 3D art. True transparent background, no brown backdrop, no text or gridlines. EXACT 16 equal aligned cells, full body centered and feet at same baseline except falling frames. Back/three-quarter camera consistent. Row1: four sequential walking RIGHT poses alternating strides and arm swings (mirror in runtime for LEFT). Row2: four sequential upward-arrow THROWING poses: windup, arm lifted, upward release, recovery; a small handheld toy harpoon launcher, no projectile outside the cell. Row3: four aiming/firing a compact toy blaster UPWARD poses: aim, recoil, firing, recovery. Row4: four non-graphic hit/fall/death poses: startled, stumble, falling sideways, lying sideways. Each character fits strictly within its own cell with generous transparent margins. No extra characters or decoration.
