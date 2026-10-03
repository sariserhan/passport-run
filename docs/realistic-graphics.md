# Photorealistic graphics — 2026-10-03

The user requested realistic graphics throughout the game. This pass replaces the earlier illustrated destination and character assets with generated photographic-style imagery. The game still combines 2D sprites/backdrops with interactive 3D memory-path geometry; it is not a fully rigged 3D character pipeline.

## Selected runtime assets

| Asset | Purpose |
| --- | --- |
| `assets/realistic/details/scenery-00.png` through `scenery-68.png` | 69 four-cell atlases: 276 distinct destination scenes, approximately 512×768 per scene |
| `assets/realistic/backdrops/{FR,TR,US,JP,EG,AF}.png` | Six dedicated full-resolution portrait scenes |
| `assets/realistic/explorer.png` | Adult arcade explorer, planted side-profile idle/walk/shoot/death poses |
| `assets/realistic/memory-explorer.png` | Adult memory-game thinking, jump, celebration, passport and fall poses |
| `assets/realistic/robot-explorer.png` | Kids explorer with physically textured metal, rubber, canvas and matching memory poses |
| `assets/realistic/objects.png` | Three latex balloon colors, brass boss, anonymous sealed capsule and three weapon/projectile sprites |
| `assets/realistic/materials.png` | Limestone, sandstone, frosted ice and oak surfaces |
| `assets/realistic/medals.png` | Bronze, silver and gold compass medallions |
| `assets/realistic/menu.png`, `infinite.png` | Photographic travel cover and physically plausible fantasy Infinite vista |

The built-in `image_gen.imagegen` tool generated these assets. This is synthetic photographic-style artwork, not documentary photography. Geographic/fantasy prompts identify each location; visual geographic accuracy has not received a complete human audit. The atlas layout is mapped in `resources/geography/realistic-artwork.json`. The lower-detail 16-cell drafts are discarded rather than shipped. [The asset manifest](realistic-asset-manifest.json) records dimensions and SHA256 hashes for all 83 selected PNGs.

Exact submitted prompts: [destination atlases](realistic-scenery-prompts.json), [objects/materials/menu/Infinite/memory explorer](realistic-object-prompts.json), [dedicated scenery, arcade explorer and pose corrections](realistic-hero-prompts.json). Generated outputs were copied unchanged. No Python image editing was used. Alpha analysis produced `resources/realistic-explorer.json`, which records sprite crop/head/sole anchors without modifying the PNG. It is explicitly included in native export.

## Runtime behavior

Arcade walkers use one right-facing profile, mirrored for left motion, with a short planted turn. Gait frames align the feet and crown without idle bobbing or jumping in place. Contact shadows, natural exposure, muted brass/slate controls and textured platform edges tie the objects to their surroundings. Scenery cover-crops preserve aspect ratio rather than stretching. Character portraits in travel and memory play use the same realistic style.

Memory path stones use photographic albedo and restrained procedural normal detail on the existing 3D mesh. Clear/preview states retain their colors and visual rules. Four extracted material textures with mipmaps are reused. Backdrops and sprites retain lossless imports to preserve fine photographic detail. Destination caches retain at most eight backdrop entries and four atlas entries; active UI nodes may hold additional references while visible. Mystery drops share the same sealed exterior until collected. Locked destination scenery is never requested by the discovery UI.

## Gameplay additions

Three bosses use distinct, saved attack patterns with warnings. Destination results track total active play time including failed attempts, retries, best combo, pops and destination points. Mastery medals never downgrade and separate difficulty and solo/co-op. Gold: ≤150 seconds, zero retries, combo ≥5. Silver: ≤210 seconds, ≤2 retries, combo ≥3. Other clears: Bronze. Legacy saves without a complete timing history receive Bronze.

Balloon daily goals reset at UTC midnight. The journal reveals only collected effects. Touch preferences swap the fire side and enlarge targets to 88 pixels. Practice preserves the main journey, medals, goals and journal. One-touch death and permanent first-country choice remain unchanged.

## Validation

Rendered mastery/graphics checks passed 99 checks, including old saves, malformed profile data, permanent journal discovery, goal boundaries, all boss patterns, practice isolation and large/swapped controls at 320×568, 390×844, 844×390 and 667×375. Dedicated captures verify memory play, the Kids explorer, Infinite and varied destination scenery. The complete offline check passed all 25 Godot suites and four Python tests with no script errors. The rendered turn suite passed 110 checks, including measured head/feet alignment. The final iPhone resource pack passed 581 standalone artwork/startup checks from outside the source project, and the exported Xcode project compiled successfully with signing disabled. Physical iPhone installation, frame rate, heat, battery use and human visual acceptance remain pending. Desktop rendering does not establish physical-device acceptance.

Reproduce desktop captures:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tools/capture_realistic.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/test_arcade_mastery.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/test_arcade_turn.gd
```

The selected source images remain lossless. Material mipmap generation follows [Godot's Image API](https://docs.godotengine.org/en/4.5/classes/class_image.html#class-image-method-generate-mipmaps); [Godot's import documentation](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_images.html) explains the quality/memory tradeoffs. No physical-device performance claim follows from this choice.

Latest local native project: `/private/tmp/passport-native-realistic/PassportRun.xcodeproj`. Current build is unsigned. The packaged game is `PassportRun.pck`; `tools/verify_exported_art.gd` verifies all 282 backdrops, the eight shared realistic assets, four textured 3D surfaces, alignment data and actual menu startup. It also checks that the superseded illustrated cover is absent. Physical-device acceptance remains pending.

Selected previews: [arcade play](../artifacts/realistic-gameplay.png), [bounce boss](../artifacts/realistic-bounce-boss.png), [destination result](../artifacts/realistic-destination-results.png), [memory path](../artifacts/realistic-memory-france.png), [Kids explorer](../artifacts/realistic-kids-explorer.png), [landscape controls](../artifacts/realistic-large-landscape-controls.png).
