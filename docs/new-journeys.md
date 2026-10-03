# New journeys and workshop

Open **New journeys & workshop** on the main menu, or inside **More adventures & creative tools**. This batch adds all fifteen requested features. Activities use the current traveler’s local passport; existing destination progression and store access checks apply.

| Feature | What you can do |
| --- | --- |
| City stops | Play Paris riverside bridges, Kyoto garden curves, and New York skyline steps. Each has additional scenery and a distinct collectible. |
| Branching journeys | With five real stamps, build a three-stop trip with two choices at each departure. The actual choices determine the saved route and recap. |
| Landmark challenges | Play an eight-step Eiffel climb, twelve-step Fuji ascent, or nine-step pyramid passage, with landmark scenery and exclusive keepsakes. |
| Local transport | Travel on Alpine train, Venice boat, Lisbon tram, and Norwegian cable-car platforms. Deck rails and vehicles distinguish the stages; boat and cable-car platforms move unless reduced motion is enabled. |
| Hidden scenic routes | Clearing each city reveals an optional seven-step garden, rooftop, or harbor viewpoint. The result screen offers the hidden route immediately, and the routes remain available in the hub. |
| Travel festivals | Lantern Evenings, Winter Lights, and Summer Music rotate monthly in UTC. Complete the active festival’s two-country route to earn that month’s keepsake. These are local seasonal themes, not live hosted events. |
| Traveling characters | Accept Mira, Leo, and Nia’s requests; later country completions advance their stories and unlock their permanent rewards. |
| Souvenir crafting | Destination completions earn travel materials. Spend them on a postcard lantern, star mobile, or terrarium after collecting the required stamps. Crafted objects can appear in room pictures. Original souvenirs stay in the collection. |
| Room design presets | Save up to six named arrangements, including displayed souvenirs, positions, postcards, earned decorations, and a crafted object. Apply a preset to the active room space or delete it. |
| Interactive world globe | Rotate an orthographic globe with a finger, mouse, or buttons. Tap country pins to choose a destination. Gold pins mark collected stamps; replay access stays gated. |
| Journey recap movies | Finishing a journey automatically stores its visited route, date, and tile count. Play any of the last ten journeys, seek through its stops, or export an animated GIF. Export samples up to twelve stops, including the first and last, at 240×450; in-game playback retains the full route. |
| Local multiplayer turns | Four local save slots keep separate passports, rooms, and collections. Choose a two-, three-, or four-player match using a destination accessible to everyone. Players share route, difficulty, and seed, take turns, and compare tile scores. Failure results and completed turns offer the next player. The match board is held for the current app session; player progress persists. |
| Friendly challenge codes | Build an ordered route of up to six earned destinations and choose its difficulty. Copy a PR1 code, play it, or paste a friend’s code through the existing challenge flow. Codes preserve the exact path seed and use offline scores. |
| Accessibility | Enable larger numbered memory-path controls, larger balloon controls, reduced motion, high contrast, and three text sizes. Lane buttons select the same tiles as direct touches. |
| Offline save backup | Create a JSON file or copy a portable backup, load/paste and preview it, then explicitly restore the active traveler. Restore validates through the normal profile loader and preserves device identity and store entitlements. The previous save is retained separately and can be loaded from the backup page for recovery. |

Short scenic stages grant their own keepsakes and ordinary completion progress; they do not award Silver/Gold difficulty mastery for shortened paths. Existing memory-path failures and Balloon Tour’s fatal first collision are preserved. New features do not require a network service.

## Verification

`tests/test_travel_extras.gd` exercises actual city and hidden-route jumps, branching departures, recap routes, accessible lane-button input, paused photo return, independent save slots, equal multiplayer paths, crafting costs, request rewards, preset restoration, malformed data, backup replacement/recovery, screen width, and GIF export. Display runs capture all fifteen screens at 390×844 and 375×667. Exported multi-frame GIFs are decoded independently with Pillow.

The iOS sharing bridge also accepts the generated movie and backup filenames as file URLs. `tools/check_iphone_sharing.py` runs the exact native bridge in an isolated simulator test app, checking picture, backup, and movie sheet presentation and cancellation callbacks. It does not verify actual recipient delivery or installation of the full updated Godot game on a physical iPhone. Backup text copy/paste is available on all platforms; filesystem browsing depends on the platform’s available file access.
