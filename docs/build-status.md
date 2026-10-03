# Build status — 2026-10-02

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
