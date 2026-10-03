# Passport Run — agent handoff (2026-10-02)

## Latest destination enjoyment expansion

All six approved ideas are implemented. `DestinationTheme` maps all 282 destinations to palettes, path families and named keepsakes. Tiles have ice/sand/lantern/jungle/ocean/space/magic/lava/stone surfaces and edge ornaments; atmosphere adds snow, dust, petals, fireflies, magic glints and embers. Japan/East Asian scenes have decorative lantern posts. `TileGrid.position_for()` adds gentle curves or elevation; bridges have wooden support/rail details attached to tiles so collapse removes them. The same positions drive touch rays and character landings. Legacy challenges keep classic flat positions. The follow camera centers the upcoming row and gives Hard lanes additional room. These are visual changes, not new obstacle rules or ranked score bonuses.

Music now uses coherent 64-beat melodic phrases, chord changes, bass, pad, arpeggios and rhythmic layers. One bounded synthesis thread prepares tracks without blocking gameplay; rapid changes discard stale results and prepare only the latest requested destination. The thread is joined on exit. The outgoing/current players crossfade for 1.2 seconds, freeze with pause and both follow live volume/mute. Only two playing streams are retained; the old one is released after fading. Audio remains original synthesized instrumental music; listening/device audio QA is pending.

Souvenirs derive from earned discoveries and need no duplicate save field. See MY PASSPORT → MY SOUVENIRS for searchable illustrated keepsakes, and the current passport page for its souvenir name. Some illustrations are shared motif families. `PlayerProfile.daily_missions` atomically persists the current UTC day's distinct cleared destinations, first-try clear and finished short adventure. DAILY TRAVEL MISSIONS on the main menu displays three stars and the Daily Explorer reward. They can all be earned on a free short adventure. Actual country awards advance progress; retries and duplicate clears do not inflate it. No mission points enter ranked replay or purchase entitlements.

Traveler idle glance/breathing, worried motion and a static exclamation at >65% tile pressure, plus different celebration movements, respect pause and Reduced Motion. Render captures are `artifacts/destination-*.png`, `fun-souvenirs*.png` and `fun-daily-missions*.png`.

The complete regression run passed eleven Godot suites plus three Python tests. Final focused checks cover music crossfades, saved daily missions, rendered 390×844/320×568 collection screens, and Hard previews/touch rays/landings/follow-camera visibility. Real local backend integration passed 19 checks. Latest development-signed build is `/private/tmp/passport-native-enrichment/PassportRun.xcodeproj`; no hosted deployment or live-purchase claim. Installation on the paired iPhone was attempted: CoreDevice error 10003 says the device is locked, preventing developer-disk mounting (12040). Physical installation/launch, FPS, thermal behavior and human acceptance remain pending.

Destination music continuation: `GameAudio.play_destination()` selects an original synthesized looping composition per destination. Region/theme selects scales, lead harmonics, bass/pad and percussion; destination seed determines notes and key. Infinite uses `INFINITE`, independent of geography. Called at path setup; same-destination retries do not restart playback. Only the current stream is retained. Headless and rendered Mac `tests/test_music.gd` passed (catalog coverage, distinct FR/IT PCM, theme selection, mute, loop and playback pause); existing polish suite passed 208 checks. Added music check to `tools/check.sh`. No new recordings, dependencies or copyrighted scores; listening balance and physical-device audio acceptance remain pending. Native build above predates this music change.

Latest continuation: finite-path completion now moves the traveler onto `TestEnvironment.finish_position`, centered on the solid finish platform, before celebration and passport stamping. The existing completion hop is reused, preserving completion timing/scoring and pause behavior. Reduced Motion moves without a vertical arc. Nine Godot suites and three Python tests passed; rendered animation/timer checks passed 53 assertions and real local backend integration passed 19. Native export and signed build passed at `/private/tmp/passport-native-finish/PassportRun.xcodeproj`. Captures `artifacts/27-passport-pocket.png` and `28-passport-stamped.png` show the finish landing. Physical-device acceptance remains pending.

Read `spec.md`, this file, [build status](docs/build-status.md), and [iPhone validation](docs/iphone-validation.md). The user authorized continued implementation: **“dont stop and finish as much as you can do without needing me.”** Continue feasible local work; do not reimpose the original M0–M2 boundary. Do not publish or claim production/device validation without evidence.

## Current state

Godot 4.5.2 standard/GDScript portrait game, 250 free countries and territories, a separately purchased 24-destination Special Expeditions route (16 landmarks plus eight fantasy worlds), and an independently purchased eight-destination Cinema Worlds route. Total passport coverage: 282 destinations. Ranked Daily retains its immutable 197-country catalog. Compatibility renderer. World Tour, Infinite, offline Daily, Kids, tutorial, immutable difficulty presets, durable local passport/history/records, accessibility/audio preferences, validated PR1 challenge codes, and original temporary procedural 3D art/audio work. The latest graphics pass follows the references with perspective stone paths, detailed illustrated scenery and backpacker artwork; see [visual asset notes](docs/visual-assets.md). It is a hybrid scene rather than a fully rigged 3D art pipeline. The user explicitly approved broad country expansion on 2026-10-02, overriding the old five-country gate.

This continuation added illustrated pauseable/skippable travel, Kids robot/facts/stickers, a collection badge, illustrated PNG cards, safe-area scrolling/focus fixes, session/run-aware local reporting, and a real **local Convex** competition service with Godot integration. Facts have primary sources in [country-facts.md](docs/country-facts.md).

Online play is explicitly optional: `network/backend_url` defaults empty, so offline modes work independently. When configured, Online Daily/Infinite/Rankings use authenticated anonymous sessions, server manifests, exact replay reconstruction, atomic personal bests and separated boards. Passport discovery merges cannot award ranked points. There is no hosted deployment, account recovery, bot prevention, ad provider, configured App Store purchase products, public challenge URL, native share sheet or remote analytics. Kids remains local and exposes no sharing actions.

## Graphics continuation

The reference-driven graphics pass replaces the overhead camera and primitive destination set with perspective preview/follow views, five generated matte paintings, a detailed transparent backpacker sprite, textured rounded shared tile meshes, illustrated main-menu key art and an openly licensed display font. Kids retains a rounded procedural robot. All generated assets are in `assets/`; prompts, provenance and remaining animation limits are documented in `docs/visual-assets.md`. Physical-device profiling is still required.

## Native build

Godot and matching iOS templates are installed. Xcode detects a paired iPhone15,2. Existing Apple development certificate OU confirmed Team ID `BA24C6W48D`; development bundle `com.serhansari.passportrun` is configured. No private credentials are committed. Mobile ETC2 import and iOS 15 minimum are configured for the installed Xcode. See the native evidence document for export/build/device status; device presence alone is not acceptance.

## Backend and checks

Read [backend/README.md](backend/README.md). Local server uses ports 3210/3211, `.env.local` and `.convex/` are ignored. Never print private keys, tokens or local admin config. Local anonymous initialization avoids a hosted project. Hosted auth needs separate validation; local JWT adaptation is guarded to loopback and never accepts caller-created claims.

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh
cd backend
npm run check
npm test
node tools/smoke.mjs
```

With local backend running, execute `tests/test_online.gd` from Godot (see backend README). Six offline suites, 3 report tests, 144 backend tests, real HTTP smoke and 16 Godot online checks passed. The graphics pass adds seven scene checks and bounded animation-state waits for rendered QA. Portrait rendered checks passed at 375×667/390×844 and dialogs down to 320×568. Test profiles and development scores are isolated from ordinary game saves.

## Resume priorities

1. Complete actual iPhone install/launch and human checks: notch/home indicator, taps, Hard readability, focus/lock/resume, sound/mute/haptics, sustained frame times, memory and thermal behavior. Do not infer 60 FPS from desktop tests.
2. Human-test the expanded travel and passport loop on a physical phone. Infinite reveals successive sections; retries retain paths. Active-run restoration after process death is not implemented (conditional in spec).
3. Provision and validate hosted Convex only with an authorized target. Preserve v1 generator/balance and challenge compatibility. Complete account linking/recovery, abuse controls and retention policy before public rankings. Ranked replay ceiling is 4,096 choices; longer play remains local. Menu-aborted runs are not ranked.
4. Native sharing and hosted challenge links need real platform code. Ads and purchases need actual provider/store setup and verified callbacks/transactions; do not create fake rewards or premium flags.
5. Remote analytics needs consent/age handling and real users. The 500-event single-device report cannot establish population D1 retention, conversion or revenue.

## Main code locations

- `scripts/game/game.gd`: orchestration, lifecycle, online setup/submission, travel, camera/input.
- `scripts/core/`: deterministic generator/routes/session, validated profile/challenges, backend client, bounded replay recorder and local telemetry.
- `scripts/ui/`: menu/HUD, shared safe margins, travel artwork/transition and share card.
- `backend/convex/`: schema/auth/live-session authorization, immutable competition math, run verification, rankings and passport sync.
- `backend/tests/fixtures/v1.json`: generated by `tests/export_contract.gd`; cross-language contract evidence.
- `tests/`, `tools/`: isolated gameplay/contract/UI checks and local reporting.
- `export_presets.cfg`: iPhone-only ARM64 development Xcode project; docs/tests/backend/artifacts excluded.

Preserve unrelated work, make scoped local commits, and do not push/deploy/publish unless authorized. Read Convex skill before changing backend code; use current primary documentation when needed (Context7 is preferred when available).

## Latest user follow-up: animations and 10-second choices

The user explicitly requested thinking, jumping, falling, celebration and taking a passport from the pocket to stamp the completed country. These use a generated 16-pose atlas plus a pauseable country-specific passport animation. Kids uses procedural gestures and a book prop. Completion is awarded once after the sequence; ending during celebration preserves the earned completion and cancels visual callbacks.

New runs use balance v2: each playable row gets 10 seconds, reset after successful landing. Preview/jumping/pause/travel/completion freeze the clock. Timeout triggers a fall while preserving the earned score. Old PR1 codes without a balance field and old balance-v1 ranked retries remain untimed; generator-v1 paths and preset values remain unchanged. New challenge codes include the balance version, and server boards separate it.

The server checks bounded supplied decision times and their consistency with recorded elapsed time. The active client clock is not independently attested; existing bot/modified-client limitations remain. The local Convex service was restarted against its existing persisted database and the widened schema pushed successfully. No hosted project was created.

Animation/timer suite: 36 checks passed headlessly and rendered; backend: 151 tests and typecheck passed; real Godot/backend integration: 19 checks including waiting a real 10 seconds and submitting a timeout. The paired phone remained locked when installation was attempted; native build success is not device acceptance.

Rendered motion demo: `artifacts/character-motion.mp4` (390×844), with stills `24-thinking.png` through `28-passport-stamped.png`. Capture source: `tools/capture_motion.gd`. Latest signed native build: `/private/tmp/passport-native-animated/PassportRun.xcodeproj`.

## World destination expansion — 2026-10-02

197 destinations are bundled in `resources/geography/destinations.json`; Godot and Convex consume the same snapshot. Dubai is under UAE (`AE`). Every requested country is covered. The graph now uses filtered reciprocal land borders; islands and exhausted neighbors use flights. Country picker and passport are searchable; sticker view renders earned discoveries only. Long buttons clip to avoid forcing the entire menu wider than a phone, and shared cards summarize lengthy routes.

Catalog v2 is distinct from generator v1 and balance v2. New Daily routes cover all 197 destinations; full hard route is 3,940 events, within the existing 4,096-event ceiling. Old ranked runs missing catalogVersion retain the five-country graph, original board keys and retry manifests. Daily records have an index including optional catalogVersion to permit old and new challenges on the same date. PR1 challenge routes remain self-contained and old codes continue to decode.

Five original country paintings remain. `assets/world-backdrops.png` is a 16-cell regional scenery atlas used consistently by gameplay, passport animation, travel and stickers; this is shared regional art, not 192 unique new paintings. Provenance and exact prompt are in `docs/visual-assets.md`. Dataset license and source hash are bundled alongside the catalog and credited in the country picker. See `docs/destinations.md` for full coverage and import instructions.

Expanded catalog verification: seven offline suites passed (7,795 checks plus 3 Python checks), backend typecheck plus 154 tests passed, HTTP smoke passed and real Godot/backend integration passed 19 checks. Rendered sixteen new scenery variants plus Dubai search/passport/sticker; captures are in `artifacts/`, generated by `tools/capture_destinations.gd`. Latest signed native project: `/private/tmp/passport-native-world/PassportRun.xcodeproj`; packaged JSON, license/source and every backdrop were loaded in native-pack QA. No hosted deploy or physical-device acceptance.

## Paid destination continuation

250 free countries and territories, a separately purchased 24-destination Special Expeditions route (16 landmarks plus eight fantasy worlds), and an independently purchased eight-destination Cinema Worlds route. Total passport coverage: 282 destinations. Ranked Daily retains its immutable 197-country catalog. Native StoreKit 2 adapter and pinned Godot 4.5.2 iOS plugin are included. Ownership comes from Apple-verified current entitlements and is never loaded from passport/profile flags. Restore, cancellation, pending approval and refunds are handled. Tests simulate native StoreKit only in excluded test files; no live purchase is claimed. Follow [purchase setup](docs/purchases.md) for the two non-consumable products. Art remains illustrated scenery over interactive 3D tiles.

Validation for this continuation: 10,427 Godot checks (eight suites), three Python tests, 155 backend tests plus typecheck, real local HTTP smoke, 19 Godot/backend integration checks, rendered 2,630 destination/payment checks, signed native build and exported-pack inspection. Latest native project is `/private/tmp/passport-native-cinema`. Purchase products remain unconfigured.

## Latest continuation: three-second preview, Infinite scenery, map and passport

All new games use balance v3 with a three-second preview, including Kids/tutorial. `GameCatalog.difficulty(key, balance_version)` retains original resource presets for legacy v1/v2 codes and ranked manifests; do not alter v1 fixtures. Current boards separate b3. Ten seconds per decision row remains unchanged. Infinite no longer returns a country ID, and uses `assets/infinite-backdrop.png` through `TestEnvironment`, including after segment changes.

Main menu WORLD MAP draws Natural Earth country outlines and 250 snapshot coordinates; only cleared real destinations are pinned. MY PASSPORT draws an illustrated/stamped bound visa page per saved discovery, with previous/next and search. Empty search resets the full collection. See `docs/world-map.md` for geography provenance and `docs/visual-assets.md` for the exact Infinite image-generation prompt. Native project is `/private/tmp/passport-native-map`. Physical-device/payment acceptance is still pending.

Final checks: eight Godot suites passed (10,448 checks for this run) plus three Python tests; rendered mode checks passed at 480×900 and 390×844; backend typecheck/156 tests, real local HTTP smoke and 19 Godot/backend checks passed. Native export/build and new resource-pack inspection passed. Relevant screenshots: `artifacts/15-passport-390x844.png`, `34-world-map-390x844.png`, `18-infinite-390x844.png`.

## Enjoyment pass — 2026-10-02

Main menu SHORT ADVENTURES offers European Escape (FR→IT→ES), Asian Adventure (JP→TH→ID), and American Discovery (US→MX→CA). Three clears end each route and award a durable adventure badge. Mode `trip` uses the existing JourneySession fixed-route lifecycle, celebration, stamps, retry and local challenge sharing. Retries preserve the seed and route. Daily/Infinite scoring and generator/balance versions are unchanged.

Correct jumps build a cosmetic streak: rising landing notes, gold text and a small character bounce every third jump. First-try country clears receive a badge and celebration particles; a failed country remains marked across retries. Failures briefly reveal the missed safe tile and show jumps to the next stamp. Existing retry remains immediate.

WorldAtmosphere draws lightweight cloud/bird/water glints, bubbles underwater and space streaks in cosmic locations behind the 3D path. Motion freezes during pause/menu and is disabled by Reduced Motion. Collection Goals derives earned Sunset/Jade/Ocean passport covers from the corresponding three discoveries. Selection and validated badges are saved atomically in PlayerProfile; locked covers cannot be selected in the UI or restored from an unearned saved selection. Badges/covers are local cosmetics, not App Store entitlements or ranked points. The world map adds per-region completed/total counts and completion markers.

Nine Godot suites (10,545 checks for this run) plus three Python tests passed. The new 95-check gameplay suite also passed rendered at 390×844 after separating headless/render test saves. Real Godot/backend integration passed 19 checks. Native signed build and exported-pack inspection passed at `/private/tmp/passport-native-fun`. Screenshots are `artifacts/fun-*.png`. Human enjoyment/retention and physical-device performance remain unverified. No backend code changed in this pass.

## Progressive cracks and row timeout — 2026-10-02

`PathTile.set_pressure()` grows thin jagged surface fissures without replacing the landed/preview state. Game updates only the occupied stone from the decision timer, resets the new stone after landing, and freezes during non-play phases/pause. The starting platform is now a PathTile-backed wide slab, so initial timeout visibly collapses it too. `fall()` collects every tile in the occupied row for a timeout and animates them together; wrong selections retain single-tile falls. Reduced Motion keeps pressure feedback and hides the collapsed surface without spatial drop/shake. Legacy untimed runs have no pressure growth. The change is visual; balance version and replay scoring remain unchanged.

Relevant captures: `artifacts/cracking-start.png`, `cracking-stone.png`, `26-falling.png`. Latest native project is `/private/tmp/passport-native-cracks`; physical-device acceptance remains pending.

This pass: nine-suite regression and three Python tests passed, rendered animation checks passed, real Godot/backend integration passed 19 checks, and native export/signed build passed. Final extra checks cover crack freeze, legacy untimed pressure and Reduced Motion row removal. No backend code changed.

## Adventure, collection and friend expansion — 2026-10-02

Implemented the approved continuation: separate Adventure Play with Norwegian ice drift, Brazilian/Greek moving bridges, Moon low gravity and underwater buoyancy; Special pack ownership still gates paid adventures. Standard and competitive mechanics stay versioned. Moving tiles freeze during jumps and pause, and the decision clock still resets after landing.

MY TRAVEL ROOM displays up to six selected earned souvenirs; WARDROBE equips earned outfit tints, hats and backpack colors, with a live character preview. Both persist locally and reject unearned selections on reload. These are cosmetic variations of the existing character artwork.

Challenge sharing now copies a self-contained `passport-run://challenge/…` installed-app link containing the same path and up to 512 successful-step timings. Imported local friend ghosts report progress and appear only on already visited safe stones, never revealing future lanes. Longer recordings explicitly end at the cap; ghosts are not verified ranked opponents. iPhone exports register the scheme and include a native receiver that opens challenge review. Public hosted/universal links and a native share sheet remain pending.

Adventure and paid destinations have skippable, pauseable cinematic artwork arrivals before memorization, with Reduced Motion support. Physical-device testing is intentionally deferred to the user; no device acceptance or live purchase is claimed. Latest signed project: `/private/tmp/passport-native-travel-expansion/PassportRun.xcodeproj`. Regenerate with `python3 tools/export_iphone.py /private/tmp/passport-native-travel-expansion`, then build/run through Xcode. See [native link notes](ios/native/README.md).

Rendered feature checks passed (37); screenshots are `artifacts/expansion-*.png`. Signed generic-iPhone build passed. All 12 Godot regression suites and four Python checks passed; the real local Godot/backend integration passed 19 checks. Exported native resource-pack loading passed.
