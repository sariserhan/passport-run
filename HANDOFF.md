# Passport Run — current agent handoff (2026-10-03)

Read this section first. It supersedes conflicting status claims in the historical notes below, especially claims about sharing, retries, lives, and unfinished feature batches.

## Current state and request

The latest user request is to document completed work and remaining work for another agent. All approved travel feature batches and the latest country-retry/branding request have been implemented and committed locally. The working tree was clean at `c50de1a` before this handoff update. No push, production deployment, or installation of the latest full game on the physical iPhone was performed.

The most recent gameplay report was: complete Denmark, enter Germany, fail, then incorrectly restart Denmark. This is fixed: casual travel retries stay in Germany until it is passed, and Continue resumes the first uncleared country.

## Completed work

| Commit | Delivered |
| --- | --- |
| `330f2d3` | World Champion celebration with journey and souvenirs; reactive bird/robot/dragon buddies; souvenir set room rewards; daily journal; room and album picture exports. |
| `fe6d37e` | Buddy personalities, regional trophies, rare keepsakes, archived daily postcards, journey replay, and native iOS picture sharing. |
| `cdc7685` | The approved 7 + 12 activity batch, listed below. |
| `0c08959` | The next 15 journey/workshop features, listed below. |
| `c50de1a` | Preserve the active country after casual failure; resume saved World/Kids progress; app icons, macOS icon, and matching splash artwork/configuration. |

The 19 activity features are arrival scenery/music/buddy reactions, interactive souvenirs, buddy quests/accessories, room interactions, editable scrapbook, weekly expeditions, small-phone polish, photo mode, personalized passport, bronze/silver/gold destination mastery, capital treasure hunts, weekly bingo, departure lounge, travel timeline, separate room spaces, weather/time choices, optional capital learning stickers, celebration choices, and discovery checklist. Entry points are **More adventures & creative tools** and **Departure lounge**. See [travel activities](docs/travel-activities.md).

The next 15 features are city stops, branching trips, landmark stages, transport journeys, secret viewpoints, rotating seasonal themes, NPC requests, crafting, six room presets, interactive globe, journey recaps/GIF movies, local multiplayer/profile slots, friendly route challenge codes, accessibility controls, and portable passport backup/restore. Entry point: **New journeys & workshop**. See [new journeys](docs/new-journeys.md).

## Latest retry fix: behavior and code

- `scripts/game/game.gd`: casual offline World, Kids, Special, Cinema, Trip, Adventure, and Expedition failures reload the active country without calling `session.begin()`. Preserve the route position, completed countries, banked tiles, completed stops, and ordinary retry path seed. Truncate failed-country timing samples while keeping completed-country timings.
- Daily, Infinite, Challenge, and online retries retain their full scored-run restart behavior. Do not apply casual checkpoints to these modes.
- `JourneySession.resume_world()` resumes World/Kids after the already earned country prefix. It does not fabricate banked score or current-session completions. A fully completed tour can replay from home.
- `route_start_index` and `challenge_seed()` preserve the actual resumed route and its seed in shared challenge codes.
- World/Kids menu buttons display Continue where applicable; World identifies the next stop. Failure text names the country being continued.
- The real local save was inspected read-only: home Denmark (`DK`), discoveries `AF`, `US`, `DK`; Germany was uncleared. No player save was edited.
- Regression coverage: `tests/test_country_retry.gd` includes Denmark → Germany, repeated failures, score/reward preservation, saved resume, mode boundaries, and resumed challenge seeds. Preview: `artifacts/germany-retry.png`.

## Branding delivered

Generated matching passport/globe/stepping-tile artwork is packaged in `assets/branding/`:

- `app-icon.png`: opaque 1024-square app icon; all 16 required iOS icon variants are configured.
- `PassportRun.icns` and its iconset: macOS icon.
- `splash-screen.png`: 887 × 1774 portrait splash; iOS storyboard uses aspect fit on a navy background.
- `project.godot` configures the desktop icon and boot splash; `export_presets.cfg` configures iOS icons and launch imagery.
- `tools/build_brand_assets.gd` packages image sizes; [branding documentation](docs/branding.md) records prompts, provenance, and rebuild steps.

The native export was checked for opaque correctly sized icons, matching splash pixels, and resolved storyboard settings. The latest full unsigned iPhone Debug build succeeded:

- Project: `/private/tmp/passport-native-branding/PassportRun.xcodeproj`
- Product: `/private/tmp/passport-native-branding/build/Build/Products/Debug-iphoneos/PassportRun.app`
- Logs: `/tmp/passport-brand-export.log`, `/tmp/passport-brand-native-build.log`

This is build evidence, not physical-device installation or acceptance. Temporary build paths may disappear.

## Verification completed

- Full `tools/check.sh` passed after the main retry/resume change and updated Kids fixtures.
- After the final challenge-seed/timing changes, focused checks passed: Core **1143**, Modes **388**, Country Retry **59**, all zero failures. The full suite was not rerun after those final small changes.
- Country Retry rendered checks passed **56** before those final additions; Germany retry screenshot was captured.
- Travel Extras: **95 headless / 96 rendered** checks; screens reviewed at 375 × 667 and 390 × 844, including larger text. GIF output was decoded as multiple frames.
- The earlier activity batch passed **42 headless / 45 rendered** checks and the full suite.
- Native sharing was tested using isolated apps: picture presentation and synthetic cancellation on the physical iPhone 14 Pro; picture, JSON backup, and GIF presentation/cancellation in the simulator. These tests do not prove recipient delivery or full Godot gameplay on the phone.
- `python3 tests/test_iphone_export.py` passed. The native bridge/export patches remain covered.
- The stale project desktop process was restarted with the latest game; `/tmp/passport-run-current.log` had no reported errors. Do not stop a running user game merely for documentation work.

Relevant artifacts: `artifacts/batch-*.png`, `artifacts/extras-*.png`, `artifacts/extras-journey-movie.gif`, and `artifacts/germany-retry.png`.

## Phone fixes after first device install (2026-10-03)

- `TouchScroll` (`scripts/ui/touch_scroll.gd`) replaces every menu/dialog ScrollContainer: Godot does not forward touch drags past STOP buttons, so phone swipes starting on a button never scrolled.
- Landscape Balloon Tour: single-row header, arrows/FIRE in side gutters (co-op: one gutter per player), arena uses the full height. Landscape main menu hides the key art.
- Globe handled touch and emulated mouse events, rotating twice per swipe on phones; it now handles mouse only.
- `PerfLog` writes `profile.json.perf.csv` (FPS, worst frame, memory, scene) every 5 s. Pull it with `xcrun devicectl device copy from --device <id> --domain-type appDataContainer --domain-identifier com.serhansari.passportrun --source Documents/profile.json.perf.csv --destination perf.csv`.
- TestFlight not attempted: needs the App Store Connect issuer ID for key `5QYF99NV59`, an app record for `com.serhansari.passportrun`, and the two purchase products. Hosted Convex not attempted: needs an authorized deployment target.

## Release prep and device tooling (2026-10-03, later)

- Soak test: `tools/device_soak.sh <device> [minutes]` copies `autoplay.json` to the phone; `Autoplay` plays World Tour and Balloon Tour on an isolated save while `PerfLog` records. On the first device tries the app stopped producing frames once it left the foreground. A clean soak needs the phone unlocked with the game on screen.
- `project.godot` enables file logging, so device errors land in `Documents/logs/godot.log`. One harmless engine startup error ("Mouse is not supported") appears on iOS.
- 138 opaque photo textures import as lossy WebP 0.8: the data pack went from 198 MB to 44 MB, and a release IPA is 78 MB. Alpha sprite sheets stay lossless.
- Backdrop cache fix: drawers hold their texture, because the 8-entry cache could free an on-screen card's image (white card).
- `tools/capture_screens.gd` sweeps 62 screens at three phone sizes; `tools/capture_store.gd` makes 6.9-inch App Store screenshots; `docs/app-store-listing.md` has the listing text.
- `tools/release_iphone.sh` builds a distribution-signed App Store IPA locally, and uploads to TestFlight once `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_PATH` are set. Still needed: the issuer ID, the App Store Connect app record, the purchase products, and support/privacy URLs.

## Ads, App Store Connect and TestFlight (2026-10-04)

- Ads: vendored Poing AdMob plugin v5.1.0 (`addons/admob`, iOS "ads" lib only). `AdService` shows a forced interstitial on every 4th failure (memory results screen and arcade GAME OVER), never in Kids Mode or the tutorial, and never mid-run. Requests are non-personalized with no ATT prompt; Google UMP consent runs first. Plugin calls live in `admob_bridge.gd`, loaded only on iOS, because the plugin's desktop mocks leak at exit. `tools/export_iphone.py` runs the plugin's SPM pbxproj patch, which headless export skips. **Still uses Google's test App ID and unit**: set `admob/general/ios/app_id` and `passport_run/ads/interstitial_ios` once the AdMob account exists.
- Remove Ads: `com.serhansari.passportrun.remove_ads` ($4.99), in Settings behind ParentGate.
- App Store Connect app `6819080280` (bundle ID renamed "Passport Run"). Done through the API: subtitle, privacy URL, description, keywords, promo text, support and marketing URLs, copyright, categories (Games: Puzzle and Family), five 6.9-inch screenshots, and four non-consumable IAPs with localization, availability and review screenshots (only Remove Ads is priced). Blocked by permission checks, so left for the user: age-rating questionnaire (Advertising = Yes), app price (Free) and availability, IAP prices for the three packs, App Privacy label, content-rights declaration, review contact details.
- TestFlight: builds 202610042039 (0.1.0) and 202610042109 (1.0, ads) uploaded with key `B64B7LA698` and issuer `98986775-96ac-42d1-bf30-abc0f3ba7135` via `tools/release_iphone.sh`.
- Overflow fixes: OptionButtons no longer widen to their longest item, which made the travel room 497 units wide on a 480-unit portrait screen. Captures must use the 480-unit logical base.

## What remains

1. **Done (install/launch only):** full `tools/check.sh` passed with zero failures at `4bd13f0`. That build was exported, development-signed and installed on the iPhone 14 Pro (`00008120-001E28663CE3C01E`) at `/private/tmp/passport-native-device`. It launched and kept running; it wrote the GLES3 shader cache to `Documents`. The app was not previously installed, so no save was overwritten. This is not gameplay acceptance; items 2–5 still need a person holding the phone.
2. **Device acceptance:** Denmark → Germany failure/retry and menu resume; touch controls across difficulties; portrait/landscape and safe areas; larger text; background/lock/resume; performance, heat, audio/mute/haptics; save persistence and backup recovery.
3. **Real sharing acceptance:** use the full game to share room/album pictures, GIF movies, and passport backups; verify actual recipient delivery or Photos saving. Prior synthetic cancellation callbacks are not this evidence.
4. **Branding acceptance:** check the home-screen icon and cold-launch splash on the phone, including possible cached old assets.
5. **Human visual acceptance:** obtain confirmation of explorer orientation toward the actual path and the latest art/audio presentation. A rendered still or passing test does not establish this.

There is no known unfinished implementation from the approved feature batches. Online hosting, public challenge-link hosting, live events, online leaderboards, production entitlements, and deployment are separate work; do not describe local features as those services. Existing backend integration was not revalidated or deployed during these batches. The default empty backend URL keeps the game offline.

## Important limits and invariants

- Multiplayer offers four local profile slots; passports/rooms persist, but the match board is session-only. Friendly codes and scores are local/offline.
- Seasonal themes rotate by UTC month locally; weekly activities use Monday UTC.
- In-game recaps retain the full recorded route. GIF exports are 240 × 450 and sample at most 12 frames, including first/last.
- Backup restore affects the current player slot, preserves device identity/store entitlements, and keeps a `.before-restore` recovery save. Reload with `save_current=false` to avoid overwriting the restored file with stale memory.
- Keep country access/paid gates on every route. Short scenic routes use easy mastery rather than awarding higher tiers for shortened paths.
- Keep the transport deck below the tile slab so preview markers remain visible.
- Balloon collision remains fatal on the first hit. Preserve manual arcade movement, separate practice scoring/progression, and permanent starting-country choice.
- Never modify the user's save to manufacture test evidence.

## Where to continue

Core state: `scripts/core/player_profile.gd`, `journey_session.gd`, `travel_activities.gd`, `travel_extras.gd`, `passport_backup.gd`.

Game and scenery: `scripts/game/game.gd`, `travel_stage.gd`, `tile_grid.gd`, `traveler.gd`, `balloon_arcade.gd`.

UI: `scripts/ui/menu_ui.gd`, `travel_activity_ui.gd`, `travel_extras_ui.gd`, `travel_globe.gd`, `travel_movie.gd`. Native export/sharing tooling lives under `tools/`; consult the current feature docs before older build-status notes.

Godot executable: `/Applications/Godot.app/Contents/MacOS/Godot`.

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bash tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_country_retry.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/test_travel_extras.gd
python3 tests/test_iphone_export.py
python3 tools/export_iphone.py /private/tmp/passport-native-branding
```

Do not run tests that share save fixtures concurrently. Inspect assertion totals and `ERROR`/`SCRIPT ERROR`; an engine exit code alone is insufficient. A stale Godot instance can retain imported assets: inspect its working directory/start time and restart only the relevant project process when necessary.

Commit only owned changes. No push or deployment is implied. Documentation-only handoff updates do not require rerunning gameplay tests.

---

# Historical handoff notes

The notes below preserve earlier context. Their status statements are superseded by the current handoff above; do not treat older pending lists as the current backlog.

# Passport Run — agent handoff (2026-10-03)

## Latest correction: jumping characters face toward the path

The jumping/memory game uses rear-view human and Kids robot sheets: backs toward the camera, faces toward the path. This supersedes the earlier incorrect camera-facing interpretation. Balloon Arcade keeps its separate side-facing explorer. `Traveler.align_portrait()` uses refreshed measured full-pose bounds from `resources/jumping-explorer.json` to avoid clipping generated frames and align boots. Existing pose indices and jump/scoring rules remain. The bounds JSON is included in iPhone export. Built-in edit prompts are in `docs/jumping-character-prompts.json`; preview is `artifacts/realistic-memory-path-jump.png`. `tools/capture_realistic.gd` now captures a real safe-tile jump as well as standing, Kids and Infinite. Previous native Xcode builds predate this correction. Verification passed 53 animation/timer checks both headlessly and rendered, 208 polish checks, standing/mid-jump/Kids/Infinite captures, and 582 standalone artwork/startup checks of `/private/tmp/passport-path-facing.pck`.

## Current continuation: mastery and photorealistic graphics

This section supersedes older illustrated-art descriptions below. The user approved all six proposed features plus a strong realistic graphics pass. `ArcadeProgress` defines three medal tiers, three UTC daily goals and the 22-entry mystery journal. `PlayerProfile` atomically saves validated medals per destination/difficulty/solo-co-op, bounded goal counts, revealed drop keys and touch preferences. Practice does not award any of these. Old checkpoints are compatible: missing country time is -1, so legacy destinations cannot retroactively earn Silver/Gold.

`BalloonArcade` accumulates destination play time across rounds and retries, retry count, best combo, pops and starting-score baseline. Clear panels show destination results and a photographic medal. Boss patterns alternate charge/bounce/summoner, warn for 0.85 seconds, freeze with pause/countdown/freeze, persist through recovery, and cancel with boss death. Summoner minions have distinct spawn markers. FIRE can swap sides and touch targets expand to 88 pixels via Pause or Settings; both persist. One contact still kills, including frozen balloons. The free starting country stays permanently locked, route order stays stable, future destination art stays hidden, and practice stays separate.

`RealisticArt` caches atlas regions and cropped material textures. All 282 destination backdrops, arcade explorer/objects, memory explorer, menu/Infinite backgrounds, medals and path materials use generated photorealistic artwork. Arcade gait/idle/turn geometry keeps feet on the floor and the head at a constant height; rendering regression checks inspect real frames. `GameCatalog` bounds backdrop/atlas caches to 8/4 entries. `resources/realistic-explorer.json` is explicitly included in iPhone export: it is essential for frame alignment. Original illustrated files stay in source history but are excluded from export. Prompt provenance and current validation are in [realistic graphics](docs/realistic-graphics.md).

Validation passed all 25 Godot suites plus four Python tests, 99 rendered mastery/graphics checks, 110 rendered turn checks, 581 exported-pack checks and unsigned Xcode compilation. Latest native project is `/private/tmp/passport-native-realistic/PassportRun.xcodeproj`. New coverage: `tests/test_arcade_mastery.gd`, updated unique-artwork and rendered turn suites. Run `tools/check.sh` for the complete offline checks. Current screenshots are `artifacts/realistic-*.png`; older screenshots below predate this pass. Physical-device FPS, thermal behavior and human visual acceptance are still deferred. No backend, purchase products or hosted deployment changed.


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

## Soundtrack clarity pass — 2026-10-02

Replaced random scale walks and unrelated backing chords with four composed answering phrases, rests, diatonic chord progressions and phrase dynamics. Slower 16-bar arrangements distinguish plucked strings, bell tones, warm sustained leads, waltz accompaniment and percussion. Short reflections soften timbres; music gain increased 3 dB while retaining mute, pause, bounded background synthesis and crossfades. These remain original synthesized music, not recorded country songs or film scores.

Music lifecycle checks passed, including minimum phrase duration, audible unclipped PCM, deterministic destination differences and rapid changes; 1,189 destination-polish checks passed. Listen to `artifacts/music-france.wav`, `music-japan.wav`, and `music-desert.wav`. Musical taste and device listening remain user acceptance; objective tests do not prove perceived quality.

Updated signed iPhone build passed at `/private/tmp/passport-native-travel-expansion`; no device installation performed.

## Unique destination artwork — 2026-10-03

The user requires a unique image for every destination. Afghanistan had incorrectly inherited a Thai-temple regional scene; it now has its own Hindu Kush-inspired valley painting at `assets/backdrops/AF.png`. All other shared free-country scenery is replaced: 244 distinct paintings across 16 atlases plus six dedicated country PNGs. With the existing 32 paid scenes, every one of the 282 destinations resolves to a different image. Infinite retains its separate dreamscape.

`GameCatalog.backdrop()` prioritizes dedicated PNGs, then the stable ID-to-atlas/cell mapping in `resources/geography/artwork.json`, then existing paid artwork. Every gameplay/passport/sticker/travel surface already uses this lookup. Atlases load on demand. Country data, routes, catalog and balance versions are unchanged. Generated images are stylized country-inspired compositions; they are not exact landmark photographs. Full prompts and built-in imagegen provenance are recorded in `docs/unique-artwork-prompts.md`.

`tests/test_unique_artwork.gd` checks all 282 resolved images, region bounds, uniqueness and the Afghanistan correction; added to `tools/check.sh`. Rendered 390×844 checks capture AF, TH, IN, PK, IR, MY, GL, AQ and passport in `artifacts/unique-*.png`. Physical-device acceptance remains deferred to the user.

Unique-art validation: all 282 destination images are distinct in both desktop and exported native-pack checks. Eight country/polar scenes and passport rendered successfully. Updated development-signed generic-iPhone build passed at `/private/tmp/passport-native-travel-expansion`; no physical-device installation or performance acceptance is claimed.

Destination progression regression passed: 5,676 checks, zero failures.

## Balloon Tour arcade and connected map — 2026-10-03

Added **BALLOON TOUR · ARCADE** to the main menu, inspired by [Pang's balloon-splitting world tour and connected map](https://gamingpicks.wordpress.com/2014/05/31/classic-games-pang-arcade-1989/). The reference article, gameplay image and `pana_map.png` were inspected. No reference screenshots, music or original sprites were copied into the game.

This separate single-player mode uses left/right movement and upward harpoons. Large balloons split into two medium ones; medium into two small ones; small balloons pop. Three rounds per destination introduce additional balloons and a blocking platform. Lives, hit grace, a 90-second round timer, shield/freeze/double-wire pickups, pause, retry and local scores are implemented. Retry rolls back failed-round points. Keyboard arrows/A/D and Space work; independent touch indices support holding movement and FIRE together. Responsive geometry keeps balloons circular in portrait and landscape.

World route uses the existing border/flight planner and includes all 250 free countries/territories, beginning at the chosen home. Special (24) and Cinema (8) routes keep their independent verified-entitlement gates, including ownership revocation during arcade play. Every round uses `GameCatalog.backdrop` and existing destination music. Three successful rounds earn the shared passport stamp, souvenir/cosmetic progress and daily destination mission; a damaged/timed-out country cannot receive the flawless mission. Arcade records use `balloon:<difficulty>` and are local, separate from verified memory scores. Active arcade runs do not resume after app termination.

The passport map connects recent saved completion history. Arcade arrival/results show a connected upcoming itinerary with the current destination highlighted. Routes wrap at the date line instead of drawing across the map. Fantasy/paid locations without geographic pins remain in the passport rather than receiving invented map coordinates. Other gameplay retains its memory rules.

This is a playable original adaptation with three pickup types, not a complete reproduction of Pang's weapons, animals or two-player mode. Those extra mechanics and multiplayer are outside this first arcade implementation. User physical-device testing remains pending.

Balloon Tour validation: all 14 Godot regression suites and four Python checks passed. The arcade/route-map suite passed 46 checks headlessly, rendered at 390×844 and against the exported native pack. Existing real local Godot/backend integration passed 19 checks. Updated development-signed generic-iPhone build passed at `/private/tmp/passport-native-travel-expansion`; no device installation performed. Screenshots: `artifacts/balloon-*.png`.

## Expanded mystery arcade — 2026-10-03

Balloon Tour now has walking, upward throwing, blaster recoil and hit/falling/death poses. Death plays before retry; pause freezes it. Eight weapons include the basic wire, double/triple arrows, ceiling-sticking harpoon, rapid blaster, spread shot, piercing laser and splash rocket. Special weapons last 18 seconds. All 22 drop outcomes share the same question-mark appearance until collected. Helpful drops include shield, freeze, slow balloons, quick boots, heart, time, coins, bomb and magnet; hazards include faster/multiplied balloons, heavy boots, reversed controls, a short weapon jam and lost time. Multiplication caps its immediate wave at 40 balloons; splitting descendants can increase that count. Rounds use 85/80/75 seconds by difficulty, with speed and balloon count increasing along the tour. Combo points and burst particles provide feedback. Existing destination artwork, music, passport stamps and paid-route gates remain integrated. Screenshots: `artifacts/arcade-rich-*.png`. Physical-device testing remains pending.

Expanded arcade validation: all 15 Godot suites and four Python checks passed. New mechanics passed 45 checks headlessly, rendered and against the exported native pack; existing arcade passed 46 checks headlessly and rendered. Development-signed generic-iPhone build succeeded at `/private/tmp/passport-native-travel-expansion`. No physical-device installation performed.

## Portrait and landscape play — 2026-10-03

Enabled sensor rotation for iPhone portrait and both landscape directions. The square minimum canvas retains the portrait layout and keeps landscape touch targets usable. Memory-game instructions and preview camera fit the wide screen; arcade buttons, arena and header respect mobile safe areas. Rotation preserves the current arcade round and equipped weapon. Godot sensor setting verified against https://docs.godotengine.org/en/4.5/classes/class_displayserver.html . Scene (348), mobile UI (20), rich arcade (45) and landscape checks passed; portrait and landscape scenes rendered at 844x390, 667x375 and 390x844. Updated development-signed generic-iPhone build succeeded and its plist includes portrait plus both landscape orientations. Physical-device rotation testing remains pending. Screenshots: `artifacts/landscape-*.png`.

## Balloon Tour adventures and local co-op — 2026-10-03

All six approved additions are implemented in the existing arcade. Round one is balloon clearing, round two rotates through 25-second swarm survival, no-fire dodging and rising-water clearing challenges, and round three is an armored boss. Bosses take 5/7/9 hits by difficulty, shed armor, reverse/increase movement and spawn faster waves below half health. A passport stamp requires finishing all three rounds, including remaining boss minions.

DestinationTheme drives sandy gusts, icy movement inertia, underwater gravity/bubbles and space/Moon low gravity, with themed floors and the existing unique destination artwork/music. Repeated weapons upgrade to level three and fire faster. Different weapons inherit a modifier from the preceding weapon: extra volley, ceiling attachment, piercing, blast or rapid fire. Examples include ceiling-sticking blasters and explosive double arrows; upgrades expire with the weapon. All drops retain the same question mark. Pause exposes collect/avoid; Q toggles it on desktop. Three consecutive beneficial mystery collections award 500 points; a curse breaks that chain.

Select LOCAL CO-OP on the arcade's arrival screen, then START. P1 uses arrows/A/D + Space; P2 uses J/L + K, or each player's dedicated touch row. Players move independently and share the weapon arsenal/pickup effects. A fallen player can be revived by a teammate staying within 70 logical units for two seconds, within a 15-second deadline. Both falling ends the round. Hearts revive a fallen teammate or grant a shield to a healthy team. Co-op records use `balloon-coop:<difficulty>`, including menu exits. This is local shared-screen co-op; online networking and second-device pairing were not added. Screenshots: `artifacts/arcade-adventure-*.png`.

Adventure validation: all 17 Godot regression suites and four Python checks passed. The new adventure suite passed 58 checks headlessly, rendered in portrait/landscape and against the exported iPhone pack. Existing arcade (46), rich weapons (45), rotation and passport progression checks remain passing. Updated development-signed generic-iPhone build succeeded at `/private/tmp/passport-native-travel-expansion`; no physical-device installation or online co-op claim.

## Arcade return loop — 2026-10-03

Added stronger bursts, weapon-specific synthesized cues, armor flashes and Reduced Motion-aware arena shake; run-scoped tour coins, between-destination heart/shield/weapon purchases, safe-route shield versus armored fast detour/double pop coins; deterministic UTC daily solo destination/weapon/modifier with fixed Moderate rules and date-specific local scores; zigzag, armored, timer-splitting and arrow-dodging balloons; independent co-op shot cooldowns, automatic four-pair synchronized team attack and rewarded proximity rescues. Retry rolls back attempt coins. Purchased supplies apply each round; co-op extra hearts prevent knockdowns. No hosted daily board, online co-op or active-run save was added. See README for costs and controls. New regression suite: tests/test_arcade_return.gd.

Return-loop validation: full tools/check.sh passed (18 Godot suites and four Python checks). New arcade return suite passed 31 checks headlessly and rendered; captures artifacts/arcade-daily.png, arcade-supplies.png and arcade-team.png cover portrait daily/shop and landscape co-op. No native export, deployment or physical-device check performed in this continuation.

## Progressive balloon difficulty — 2026-10-03

Tour pressure smoothly grows as country_index / (country_index + 25), increasing base horizontal speed by up to 150 and reducing normal round time by up to 20 seconds. Opening waves add one balloon every four destinations, capped at five extra; spawns distribute within the arena. Bosses gain one hit every three destinations, capped at twelve extra, and wave intervals shorten by up to half. Each round retains its speed increase; retries preserve tuning and Daily Arcade excludes tour pressure. New test_arcade_difficulty.gd covers stages through destination 250, spawn bounds, time/health bounds, wave cadence, retries and daily isolation. All six focused arcade/rotation suites passed; difficulty suite passed 75 checks headlessly.

Rendered difficulty suite also passed 75 checks; artifacts/arcade-difficulty.png shows a six-balloon late-tour wave at 390×844. Physical-device tuning remains pending.

## Arcade leg animation correction — 2026-10-03

New transparent side-profile walk atlas assets/arcade-walk-v2.png shows bent knees and changing foot positions. Gait follows actual distance traveled, scales with boots/heavy boots, continues on ice, stops at walls and freezes during pause. Shared draw_explorer renders independent torso recoil/leg locomotion while firing and mirrors both players; stationary shots/hit/death retain original poses. Reduced Motion suppresses torso bob. Seven focused arcade/rotation suites passed; new walk suite passed ten checks rendered, with a two-second right/left movement and firing clip artifacts/arcade-walking-v2.mp4. Built-in image-generation provenance and prompt in docs/visual-assets.md. Physical-device acceptance remains pending.

## Smooth arcade turns — 2026-10-03

assets/arcade-turn.png adds five planted-foot right/profile-to-front-to-left/profile poses from built-in image generation. Both players interpolate orientation over 0.25 seconds, blend neighboring poses, and use matching side-profile idle poses rather than instantly mirror-flipping. Direction changes brake at 1,800 logical units/s² before ordinary 4,000 acceleration; ice retains its 260 acceleration. Rapid reversals retarget the ongoing turn, pause freezes it, and Reduced Motion skips supplementary rotation. Walking/firing/hit/death remain integrated. Eight focused arcade/rotation suites passed, including eight new turn checks rendered. Preview artifacts/arcade-turning.mp4, still arcade-turning.png. No physical-device check or native export in this continuation.

## Side-profile pivot refinement — 2026-10-03

Preserves the later side-only/anchored sprite changes and one-hit rules. Turns now use a 100 ms progression with a brief planted stance at the midpoint and a subtle sinusoidal body lean, rendered as a single solid sprite; no opacity blending or duplicate silhouettes. Walking keeps distance-based phase. Both players use the transition, rapid reversals retarget it, pause freezes it, and Reduced Motion skips it. Existing anchor/sole alignment remains, with rotation about the head center. Seven arcade/rotation regression suites passed, and test_arcade_turn.gd passed 108 rendered checks covering every gait at completed and intermediate turns. Updated preview: artifacts/arcade-turning-smooth.mp4 and still arcade-turning-smooth.png. No device validation in this continuation.
