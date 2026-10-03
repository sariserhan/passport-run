# Build status — 2026-10-02

Latest enjoyment expansion implements destination tile palettes/effects, curves/elevation/bridge decoration, fuller original music with crossfades, earned souvenir cards, durable UTC daily missions, and character reactions/theme celebrations. All eleven Godot suites and three Python tests passed, with final focused rendered/music checks and 19 real local-backend checks. Native export/development signing passed; physical iPhone installation is blocked by the locked device. Souvenir art uses shared motif families and music remains synthesized original instrumentals.

Latest finish pass: the character reaches the solid finish platform before celebration and passport stamping. Nine Godot suites, three Python tests, 53 rendered animation/timer checks, 19 real local-backend checks and the signed iPhone build passed. Finite completion timing and scoring are unchanged.

The game with 250 free destinations and 32 separately purchased locations is a playable prototype. Online competition now works against a real local Convex instance; no hosted service or commercial release is claimed. [HANDOFF.md](../HANDOFF.md) contains continuation instructions.

| Milestone | Implemented | Remaining acceptance/work |
| --- | --- | --- |
| M0–M2 Foundation/gameplay/reveal | Portrait Godot, touch movement, jumps/falls, results/retry, timed hidden paths | Physical iPhone touch, readability, FPS and thermal testing |
| M3 Difficulty | Three immutable presets, segregated local and server boards | Human balance testing |
| M4 Infinite | Bounded tile windows, random-access generation, same-path retry, verified online submissions | Device profiling, final memory-loop validation |
| M5 Countries | 250 free destinations plus 32 paid locations, five dedicated paintings plus sixteen shared regional scenes, 3D stone paths, stamps, travel | Dynamic scenery/parallax and fully rigged character animation |
| M6 Home/route | Searchable explicit home, shared land-border geography and long-haul choices | Optional active-run persistence; source snapshot review |
| M7 World Tour | 250 non-repeating free destinations, totals, travel, full-world collection badge | Dedicated landmark scenery and curated regional rewards |
| M8 Passport | Illustrated stamped pages, completed-country map pins, durable local stamps/history, sticker album, online discovery union | Account recovery and broader sync policy |
| M9 Daily | Offline deterministic Daily plus authenticated canonical server manifests, pinned retries | Hosted deployment and device integration |
| M10 Leaderboards | Replay reconstruction, authenticated ownership, atomic personal bests, sanitized segregated boards, Godot client | Hosted validation, abuse prevention, account linking |
| M11 Ads | Unimplemented | Provider setup and verified rewards/continuation |
| M12 Purchases | Native StoreKit verification, restore and refund handling for two route packs | Live product setup/device acceptance; Remove Ads product |
| M13 Kids | Slower paths, robot explorer, verified facts and illustrated stickers | Device/human/parental review |
| M14 Polish | Illustrated backpacker/menu, licensed display type, prototype audio, pauseable travel, safe-area scrolling, reduced motion/high contrast | Full skeletal character animation, device visual/performance and listening/haptics QA |
| M15 Challenges | Validated local PR1 codes and identical-path replay | Hosted links and native link handling |
| M16 Share cards | Illustrated 720×1000 PNG and clipboard code | Native iPhone share sheet |
| M17 Analytics | Local bounded events, session/run timing and scoped funnel report | Consent-aware remote analytics and real retention/revenue study |

## Verification

Seven headless Godot suites passed: core 1,143; scene 156; progression 3,487; modes 364 or more depending on route choices; mobile UI 20; polish 16; animations/timer 36. Python reporting checks passed (3). Rendered mode tests passed at 375×667 and 390×844; mobile dialogs were also checked down to 320×568. Illustrated cards and Kids rewards were inspected. Desktop rendering does not establish iPhone performance.

Backend typecheck and 151 tests passed. Tests cover Godot-generated compatibility fixtures, ownership, revoked sessions, malformed and impossible replays, score reconstruction, duplicate submissions, passport isolation, and retry manifests across midnight. Real local HTTP smoke tests exercised sign-in, submit, board, sync, refresh and sign-out. Godot's real-backend integration suite passed 19 checks, including actual in-game verified score display. These use development users, not customer evidence.

See [iPhone validation](iphone-validation.md) for native export/build status. Broad destination coverage was explicitly approved by the user on 2026-10-02; see [destination notes](destinations.md). Active runs do not resume after process termination. Client replay verification does not establish human play or prevent automated bots. Online playback is opt-in; the default exported game stays offline.

The latest reference graphics pass is documented in [visual assets](visual-assets.md). The 3D tiles remain interactive; the scenery and main backpacker are illustrated assets. Native export includes the new art/font. Earlier device-lock and human-validation limitations still apply.

The latest requested thinking/jump/fall/celebration/pocket/passport/stamp sequence is implemented with a 16-pose atlas and pauseable passport animation. New balance-v2 runs add a 10-second decision clock per playable row; legacy challenge and ranked rules remain versioned. Rendered animation checks passed (36), and a real online timeout/score submission passed.

## Latest country expansion

The user approved broad coverage: 197 destinations, including all listed countries and Dubai under UAE. One bundled geography snapshot feeds Godot and Convex. Searchable picker/passport, capital rewards, land-border routing, regional illustrated scenery and catalog-version compatibility are implemented. Existing five-country ranked retries remain intact. See [destination coverage](destinations.md).

Latest seven-suite regression: core 1,143; scene 348; progression 5,676; modes 364; mobile 20; polish 208; animations/timer 36. Backend typecheck and 154 tests passed, including a full 3,940-event hard Daily and coexistence with old same-day challenges. Real HTTP smoke and 19-check Godot/backend integration passed. Sixteen scenery variants and Dubai picker/passport/sticker screens were rendered. No hosted deployment or physical-device performance acceptance is claimed.

## Additional destination packs — 2026-10-02

250 free countries and territories, a separately purchased 24-destination Special Expeditions route (16 landmarks plus eight fantasy worlds), and an independently purchased eight-destination Cinema Worlds route. Total passport coverage: 282 destinations. Ranked Daily retains its immutable 197-country catalog. All 32 paid locations have dedicated illustrated scenes across eight atlases. Territory progress beyond 200 stamps now persists. Native StoreKit purchase/restore/refund integration is included; App Store Connect product configuration and device purchase acceptance remain pending. See [purchase setup](purchases.md).

This continuation passed 10,427 Godot checks, three Python tests, 155 backend tests/typecheck, real local HTTP smoke, 19 online integration checks, and rendered destination/payment checks. Signed iPhone build and 282-destination exported-pack loading passed. Native device purchases and performance remain unverified.

## Preview, Infinite and collection UI — 2026-10-02

New balance-v3 games use a three-second preview across modes. Old v1/v2 challenges and rankings retain their rules; new boards separate b3. Infinite now uses a dedicated original dreamscape without country labels. A geographic 2D map pins completed countries/territories, and the passport presents illustrated stamped paper pages with navigation and search. World map and passport UI are implemented; account recovery and physical-device validation remain pending.

## Enjoyment pass — 2026-10-02

All five approved proposals are implemented: three short adventure routes/badges, cosmetic jump streaks, missed-step/proximity retry feedback, animated background ambience, and collection covers with regional map progress. Covers and badges persist locally and never grant purchase access or scoring advantages. Nine Godot suites, three Python tests, rendered 95-check gameplay verification, 19 real backend integration checks, signed native build and exported-pack inspection passed. Real player enjoyment and device performance remain to be tested.

## Standing-stone pressure feedback — 2026-10-02

Progressive timed fissures, fresh pressure after landing, initial-platform collapse and whole occupied-row timeout drops are implemented. Pause/preview/jump timing and score verification stay unchanged; Reduced Motion retains static crack/collapse feedback. Rendered animation checks passed (47 assertions); the final headless animation suite passed 52, adding crack-freeze, legacy and Reduced Motion checks.

## Adventure, collection and friend expansion — 2026-10-02

Implemented the approved continuation: separate Adventure Play with Norwegian ice drift, Brazilian/Greek moving bridges, Moon low gravity and underwater buoyancy; Special pack ownership still gates paid adventures. Standard and competitive mechanics stay versioned. Moving tiles freeze during jumps and pause, and the decision clock still resets after landing.

MY TRAVEL ROOM displays up to six selected earned souvenirs; WARDROBE equips earned outfit tints, hats and backpack colors, with a live character preview. Both persist locally and reject unearned selections on reload. These are cosmetic variations of the existing character artwork.

Challenge sharing now copies a self-contained `passport-run://challenge/…` installed-app link containing the same path and up to 512 successful-step timings. Imported local friend ghosts report progress and appear only on already visited safe stones, never revealing future lanes. Longer recordings explicitly end at the cap; ghosts are not verified ranked opponents. iPhone exports register the scheme and include a native receiver that opens challenge review. Public hosted/universal links and a native share sheet remain pending.

Adventure and paid destinations have skippable, pauseable cinematic artwork arrivals before memorization, with Reduced Motion support. Physical-device testing is intentionally deferred to the user; no device acceptance or live purchase is claimed. Latest signed project: `/private/tmp/passport-native-travel-expansion/PassportRun.xcodeproj`. Regenerate with `python3 tools/export_iphone.py /private/tmp/passport-native-travel-expansion`, then build/run through Xcode. See [native link notes](../ios/native/README.md).

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

### Travel life features

- World Champion unlocks after all 250 free countries/territories are discovered, in either gameplay mode. The celebration includes confetti, a journey recap and the player's arranged souvenirs. It appears on return to the menu until acknowledged and can be replayed later.
- Travel Buddies selects Pip (bird), Orbit (robot), Ember (baby dragon), or solo travel. The choice persists and companions react during memory-path and Balloon Tour play. Reduced motion and pause stop companion motion.
- Souvenir sets unlock room displays: SPACE/MOON/MARS/SATURN, CA/NO/IS, and FR/IT/ES. The room shows set progress and lets earned displays be equipped.
- Today's journal uses the existing UTC daily boundary, records completed destinations, flawless finishes, personal bests, souvenirs, badges, travelers and set rewards. It persists across restarts and resets with the day.
- Room and album exports render standalone 720×1000 PNGs in user storage. Desktop opens the saved file in the file manager. Native iOS share-sheet delivery is not implemented.
- `tests/test_travel_life.gd` exercises save/reload, reward gating, rollover, champion unlock/acknowledgement, screens and companion reactions; with a display it also verifies PNG exports.
