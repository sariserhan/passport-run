# App Store listing draft

Paste-ready fields for App Store Connect. Character limits are Apple's; counts were checked when this was written. Everything here describes the current offline build: no online leaderboards, ads or accounts. Do not add memory-health or medical claims (spec §2).

## Name (30 max)

Passport Run: Memory Travel

## Subtitle (30 max)

Memory paths around the world

## Promotional text (170 max)

Memorize the safe stones, jump across, and stamp your passport in 250 countries and territories. Plus a balloon-popping arcade tour with local co-op.

## Keywords (100 max, comma-separated, no spaces)

memory,brain,puzzle,travel,world,countries,geography,passport,focus,kids,family,arcade,balloon,path

## Description (4000 max)

A memory game disguised as a world adventure.

Watch the path, remember which stones are safe, then jump across before the stone under your feet cracks. Make it to the far side and the traveler pulls out a passport and stamps the country. Then it's on to the next one.

TRAVEL THE WORLD
• Start from your home country and travel through its neighbors, with long-haul flights across oceans
• 250 countries and territories, each with its own scenery and original music
• Collect passport stamps, souvenirs and regional trophies, and pin your travels on the world map

CHOOSE YOUR CHALLENGE
• Easy, Moderate and Hard paths with longer rows and shorter previews
• Daily paths that are the same for every player that day
• Infinite Memory: how far can you go on one endless path?
• Challenge a friend with a link to the exact same path

BALLOON TOUR ARCADE
• Pop splitting balloons across a world tour, with bosses, mystery drops and upgradable weapons
• Play solo or local co-op on one screen

FOR THE WHOLE FAMILY
• Kids Mode with simpler paths, a friendly robot and country facts
• Reduced motion, high contrast, larger controls and adjustable text size
• Plays fully offline: no account and no ads

EXTRA DESTINATIONS (optional purchases)
• Special Expeditions: famous landmarks plus fantasy worlds like the Moon and Mars
• Cinema Worlds: eight original movie-inspired destinations
• Traveler Pack: extra animal, space and fantasy travelers
Each pack is a one-time purchase and unlocks only its own content.

Play. Travel. Remember. Have fun.

## Other fields

| Field | Suggested answer |
| --- | --- |
| Primary category | Games › Puzzle |
| Secondary category | Games › Family |
| Age rating | 4+ (no violence, no user-generated content shared online, no web access) |
| Kids Category | Optional. Purchases and every share sheet now sit behind `ParentGate`, a typed multiplication question asked each time. Apple's Kids Category also requires no third-party analytics or ads, which the game already meets. If you opt in, choose the 6–8 or 9–11 band. |
| App Privacy | Data Not Collected. Event logs and the performance log stay on the device; the backend URL is empty, so nothing is sent. Re-answer this if online play is ever turned on. |
| Encryption | Already declared: `ITSAppUsesNonExemptEncryption = false` in the exported Info.plist. |
| In-app purchases | Three non-consumables: `com.serhansari.passportrun.special_routes`, `com.serhansari.passportrun.cinema_worlds` and `com.serhansari.passportrun.travelers` (Traveler Pack). See [purchases](purchases.md). |
| Support URL | https://sariserhan.github.io/passport-run/support.html |
| Privacy policy URL | https://sariserhan.github.io/passport-run/privacy.html |
| Version | 0.1.0, set in `export_presets.cfg`. `tools/release_iphone.sh` stamps a UTC build number. |

Pages source: `site/` on `main`, published from the `gh-pages` branch. Contact goes through GitHub Issues; replace it with an email address if you prefer.

## Screenshots

`tools/capture_store.gd` (run rendered, not headless) writes 6.9-inch iPhone screenshots (1320 × 2868, RGB) to `artifacts/store/`: menu, memorizing the path, jump, Balloon Tour, and passport. App Store Connect scales 6.9-inch screenshots down for smaller iPhones. These are plain gameplay captures with no marketing captions.
