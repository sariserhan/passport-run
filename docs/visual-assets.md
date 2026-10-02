# Reference graphics pass — 2026-10-02

Compared `image1.png` and `image2.png` with actual game screenshots. The reference's defining elements are a close perspective stone path over water, rich destination scenery, a detailed backpacker, warm cinematic lighting, rounded tile edges and bold playful type.

The playable scene now uses perspective: the complete path fits during memorization, then the camera moves closer for tapping. Gameplay geometry, collision, deterministic paths, tile state indicators and scores are unchanged. Rounded stone meshes are shared by size, with one small shared stone texture. Destination backgrounds are illustrative composites, not geographically literal maps.

## Assets and provenance

Generated with the built-in image-generation tool, copied into the repository and inspected:

- `assets/backdrops/FR.png`, `TR.png`, `JP.png`, `EG.png`, `US.png`: destination matte paintings.
- `assets/menu-key-art.png`: main-menu travel illustration.
- `assets/backpacker.png`: transparent rear-view character artwork.

This is a hybrid presentation: static illustrated destination backdrops and a camera-facing backpacker sprite over actual interactive 3D tiles. The backpacker moves, jumps, scales and tilts; it is not a fully rigged animated 3D character. Kids retains its procedural explorer robot. Full skeletal character animation, dynamic environment parallax and physical-device performance remain future visual work. Do not describe this as exact reference parity or a finished art pipeline.

`assets/fonts/LilitaOne-Regular.ttf` is the openly licensed Lilita One display face, sourced from the Google Fonts repository. Its license is included as `assets/fonts/OFL.txt`. Body text uses Godot's default font. Image art was generated for this project; the supplied references were inspected for visual direction, not copied into runtime screens.

## Final prompt set

Backdrop prompt: “Full-bleed portrait 2:3 matte painting for a premium charming 3D mobile travel adventure. Rich detailed architecture, dimensional soft light, atmospheric depth, believable textured materials and painterly finish. Camera slightly above water looking into distant city, horizon 30% from top. Center 45% and lower half open blue/turquoise water with reflections; landmarks, buildings and trees in upper half and side edges. No path, stepping stones, platforms, characters, interface, words or watermark.”

Destination variants: Paris/Seine and Eiffel Tower at warm sunset; Istanbul/Bosphorus, domed mosque and minarets in Mediterranean daylight; Japanese riverside village, vermilion pagoda, blossoms and distant Fuji at pink sunrise; Egyptian Nile, pyramids, palms and sandstone ruins at golden hour; New York harbor, Statue of Liberty and Manhattan in bright daylight. These are stylized country compositions.

Menu prompt: “Wide 3:2 travel adventure key art, no text or UI. Charming backpacker from behind, brown tousled hair, cream shirt, navy shorts, boots and detailed brown backpack, standing on a stone overlook. Curved world of lush islands with Eiffel Tower, Statue of Liberty, pyramids, pagoda and Istanbul domes, cyan sky, clouds, polished animated-film aesthetic.”

Backpacker prompt: “Transparent full-body rear-view game sprite. Charming young traveler, tousled brown hair, cream short-sleeve shirt, navy knee-length shorts, white socks, brown boots and detailed canvas backpack with padded straps, leather flap, buckles and pouch. Premium polished animated-feature rendering, soft light, slightly elevated camera, natural standing pose, clear silhouette; no floor, landscape, UI, words or watermark.”

## Verification

Offline suites check complete preview framing at every difficulty, real touch dispatch, jump/fall/retry lifecycle, mobile dialog scrolling, contrast settings and resource inclusion. Rendered tests use bounded state waits and resume if desktop automation steals focus; explicit pause tests still verify that the preview clock freezes. See build status for current evidence. Native packaging must include all seven image assets and the font; do not ship source references or test screenshots.

Godot canvas layering was checked against the [Godot 4.5 Environment documentation](https://docs.godotengine.org/en/4.5/classes/class_environment.html#class-environment-property-background-canvas-max-layer); Context7 was unavailable in this session.
