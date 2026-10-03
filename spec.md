# Passport Run — Product & Build Specification

## Latest approved destination scope — 2026-10-02

The user explicitly requests broad country coverage, superseding the five-country expansion gate in the original spec. Ship 197 travel destinations: the existing five, all explicitly requested countries, the remaining independent entries, Palestine, Taiwan and Kosovo. Dubai is presented under United Arab Emirates. Every destination supports gameplay, home selection, travel, passport stamps and rewards. Use land-border neighbors with long-haul flights for islands. Regional illustrated scenery may be shared; do not claim every country has a unique landmark painting. Preserve existing five-country ranked runs and challenge routes with catalog versioning.

### Additional approved routes — 2026-10-02

250 free countries and territories, a separately purchased 24-destination Special Expeditions route (16 landmarks plus eight fantasy worlds), and an independently purchased eight-destination Cinema Worlds route. Total passport coverage: 282 destinations. Ranked Daily retains its immutable 197-country catalog. Special Expeditions includes Everest, Sahara, underwater, space, Moon and Mars. Cinema Worlds contains original scenes inspired by Lord of the Rings, Harry Potter, dinosaur adventures and Wonderland. Each pack uses its own one-time non-consumable Apple purchase; buying one never unlocks the other. Free country travel excludes paid places. Paid challenge codes require the relevant ownership. Every completed destination uses the same jump, celebration and passport-stamp mechanics.

## Latest approved destination enjoyment expansion — 2026-10-02

All six proposed additions are approved: destination-specific stones/effects, fuller instrumental music and transitions, collectible souvenirs, varied paths, daily travel missions, and character personality.

- Countries and special worlds use ice, sand, lantern, jungle, ocean, space, magic, lava or stone palettes with decorative effects. Three visual path families add gentle curves, wooden bridge details or small elevation changes. Lane choices, preview duration, timer, scoring and replay rules stay the same; legacy challenge layouts stay flat.
- Original destination music has longer repeating melodic phrases, chord progression, bass, arpeggios and percussion, with a pauseable 1.2-second crossfade. Both players respect volume/mute, and the previous track is released when the transition ends.
- Every earned passport stamp also earns a named souvenir. The searchable souvenir collection and current passport page show earned keepsakes; no additional purchase or currency is required.
- Three daily missions reset at UTC midnight: stamp three distinct destinations, clear a country first try, and finish a short adventure. Progress survives restarts, duplicate clears do not inflate counts, and all missions can be completed on free routes. Three stars earn the Daily Explorer celebration; missions do not award ranked points.
- Idle glance/breathing, a static warning plus worried motion as the stone cracks, and theme-specific celebration movement add personality. Pause freezes motion; Reduced Motion retains the static warning.

## Latest approved destination music — 2026-10-02

Each destination has its own original looping instrumental melody, with region-inspired scales, timbres and rhythms. Desert, mountain, underwater, space and cinema/fantasy destinations use themed arrangements. Infinite has a dedicated space-style track. Music switches on destination entry, remains uninterrupted on same-destination retries and Infinite sections, and respects music volume, mute and pause. These are synthesized originals, not licensed traditional recordings or movie soundtracks.

## Latest approved finish landing — 2026-10-02

After clearing the final row of a finite path, the character jumps onto the solid finish stone before celebrating, taking out the passport and stamping the completed destination. Reduced Motion keeps the move to the finish without the jump arc. Completion scoring and timing stay unchanged.

## Latest approved pressure feedback — 2026-10-02

While deciding, the stone underneath the player develops progressive surface fissures in proportion to the ten-second decision clock. At expiry, every stone in the occupied row cracks and falls together, taking the character with it. Before the first jump, the full starting platform is the occupied surface and collapses on timeout. Successful landing resets crack growth on the new stone. Preview, jumping, pause, travel and completion freeze the decision clock; legacy untimed rules remain untimed. Wrong-tile failures retain their single-stone collapse. Reduced Motion shows the cracks and hides the collapsed row without shaking/dropping movement. Score/replay rules are unchanged.

## Latest approved enjoyment pass — 2026-10-02

Implement all five proposed improvements: short three-country adventures with a clear finish and badge; cosmetic correct-jump streak effects and rising notes; reveal the missed step and show jumps remaining with immediate same-path retry; subtle animated clouds, birds, water glints and world-appropriate ambient effects; collection goals awarding passport covers with regional map progress. First-try country clears receive a cosmetic badge and celebration particles. Rewards never change previews, paths, scoring or ranked fairness. Scenery pauses with gameplay and honors Reduced Motion.

## Latest approved preview and collection UI — 2026-10-02

New games use a three-second memorization preview in every mode, including Kids and tutorial. Balance v3 preserves balance-v1/v2 challenge and ranked timing, and competitive boards separate these versions. The ten-second per-row decision rule remains unchanged. Infinite uses its own dreamscape, with no country/city scenery or label. Add a 2D world map pinning cleared real countries/territories from durable passport discoveries. The passport uses bound paper visa pages: every completed destination gets scenery and a completion stamp, with page navigation and earned-page search.

## Latest approved rules — 2026-10-02

- The visual direction must follow the supplied reference images: detailed destination scenery, a backpacker, a perspective stone path, and polished mobile presentation.
- Character animation includes thinking while waiting, jump preparation/airborne/landing, falling, and country celebration. On completing a country, the character takes a passport from its pocket, opens it, and stamps the completed country before showing the result.
- Each playable row gives the user **10 seconds to choose a tile**. The first countdown starts after memorization. A successful landing on the next row resets it to 10 seconds. Preview, jumping, pause/focus interruption, travel, and celebrations do not consume this decision time. Expiry ends the run with the earned score preserved.
- These timed rules are **balance version 2**. Previously issued balance-v1 challenges/ranked runs retain their untimed rules; generator-v1 paths and difficulty presets stay unchanged. Competitive boards separate balance versions.

## 1. Product Summary

### Problem

Most casual mobile games are designed only to kill time. Many parents also dislike games that feel mindless, while adults increasingly like short games that challenge memory, attention, and concentration.

At the same time, memory-training apps often feel clinical, repetitive, or boring.

### What We Are Building

Build a polished mobile-first memory game where the player:

1. Memorizes a safe path across rows of tiles.
2. Jumps from tile to tile without falling.
3. Completes paths to travel from country to country.
4. Starts their World Tour from a chosen home country.
5. Travels primarily through geographically nearby countries.
6. Occasionally makes long-haul jumps into a new world region.
7. Collects passport stamps and discovers countries.
8. Competes through daily challenges, infinite memory runs, and leaderboards.
9. Can challenge friends on identical seeded paths.
10. Has fun while exercising visual memory, sequencing, focus, and recall.

The game should feel like a fun travel adventure first and a memory challenge second.

### Customer / Audience

Primary audiences:

- casual mobile gamers
- adults interested in memory challenges
- competitive leaderboard players
- children, through a dedicated Kids Mode
- parents looking for games that feel more mentally engaging than ordinary casual games

---

# 2. Working Name

## Passport Run

Primary tagline:

> Challenge your memory. Train your focus. Travel the world.

Secondary positioning:

> Play. Travel. Remember. Have fun.

Parent-facing positioning:

> A colorful memory adventure where kids practice attention, sequencing, and recall while they play.

Do not make unverified medical or cognitive-health claims.

Avoid:

- prevents memory loss
- increases IQ
- treats ADHD
- prevents dementia
- medically improves the brain

Allowed positioning:

- memory challenge
- exercise your recall
- challenge your concentration
- practice visual memory
- pattern-memory game
- focus challenge

---

# 3. Platforms

Primary:

- iOS
- Android

Secondary after validation:

- Web
- CrazyGames
- Poki

The game must therefore be designed with portability in mind.

---

# 4. Engine and Technical Stack

## Game Engine

Use:

**Godot 4.x**

Preferred language:

**GDScript**

Reasons:

- mobile-friendly
- lightweight
- good 3D support
- Android/iOS export
- Web export possible
- appropriate for this game's scale

Do not introduce Unity or Unreal unless explicitly instructed later.

---

# 5. Backend

Preferred backend:

**Convex**

Authentication:

Do not require account creation during first launch.

Use an anonymous device/player identity initially.

Better Auth may be added later for:

- account recovery
- cross-device sync
- social profiles

Backend responsibilities:

- anonymous player records
- home-country preference
- daily seeds
- leaderboard submissions
- run validation metadata
- country discovery
- world-route progression
- progression sync
- challenge links
- purchase entitlement synchronization
- analytics metadata where appropriate

Game mechanics must remain functional offline except for features requiring network access.

---

# 6. Core Gameplay Concept

The player faces rows of tiles.

Only one tile in each row is safe.

Example Easy row:

```text
[ X ] [ ✓ ] [ X ]
```

Moderate:

```text
[ X ] [ X ] [ ✓ ] [ X ]
```

Hard:

```text
[ X ] [ X ] [ X ] [ ✓ ] [ X ]
```

The player must memorize which tile is safe for every row.

Before crossing begins:

1. safe path is revealed
2. player observes it
3. safe indicators disappear
4. all tiles become visually identical
5. player begins crossing

Player taps the tile they want to jump onto.

Correct:

- character jumps
- tile stays solid
- continue

Incorrect:

- character lands
- tile breaks/disappears
- character falls
- run/level fails

Controls must be extremely simple.

No virtual joystick.

Use:

**Tap the destination tile.**

One-hand portrait gameplay must work comfortably.

---

# 7. Camera

Use a third-person elevated camera behind the character.

Requirements:

- clearly show next available row
- player can distinguish all available lane choices
- camera follows smoothly as player progresses
- avoid excessive camera movement
- no motion that makes memorization unfair

Country environments should remain visible around and behind the tile path.

---

# 8. Difficulty Modes

There are three standard difficulties.

## Easy

- 3 lanes
- approximately 8–10 rows per early country
- longer preview
- aimed at beginners and younger children
- forgiving pacing

Initial suggested preview:

5 seconds

## Moderate

- 4 lanes
- approximately 12–15 rows
- shorter preview
- normal game mode

Initial suggested preview:

3 seconds

## Hard

- 5 lanes
- approximately 20 rows
- short preview
- aimed at advanced players

Initial suggested preview:

2 seconds

These values must be configurable and tested.

Do not hardcode balance constants throughout the codebase.

Create a difficulty configuration resource/data structure.

---

# 9. Game Modes

Implement these primary modes.

## Mode A — World Tour

Primary progression mode.

World Tour should feel like an actual journey around the world rather than a random sequence of unrelated levels.

The player begins from a selected home country.

Example:

```text
Home Country: Turkey

Turkey
↓
Greece
↓
Bulgaria
↓
Romania
↓
Hungary
↓
Austria
```

Completing countries gradually moves the player through nearby regions.

After completing a region or reaching a travel milestone, the game may offer a long-haul flight to another region.

Example:

```text
EUROPE LEG COMPLETE

Choose your next journey:

✈ Asia
✈ North Africa
```

The travel system should make country progression itself feel rewarding.

Primary World Tour scoring:

- countries reached during one run
- tiles crossed
- longest continuous journey
- unique countries visited
- regions completed

---

# 10. Home Country Selection

During onboarding, ask the player:

> Where should your journey begin?

Display searchable country selection.

Do not automatically infer the player's nationality or home country from location.

The player explicitly chooses.

Store:

```text
home_country_id
```

Examples:

```text
United States
Turkey
Brazil
Japan
France
Nigeria
Australia
```

The player may change their home country later from Settings/Profile, but changing it must not erase passport progress.

The home country determines the default starting point for future World Tour journeys.

---

# 11. Geographic World Routing

World Tour should primarily progress geographically.

Do not fully randomize the country sequence.

Preferred rule:

**Nearby countries most of the time, occasional long-haul travel between regions.**

Example USA journey:

```text
USA
↓
Canada
↓
Mexico
↓
Guatemala
↓
Costa Rica
↓
Colombia
```

Example Turkey journey:

```text
Turkey
↓
Greece
↓
Bulgaria
↓
Romania
↓
Hungary
↓
Austria
```

Example Japan journey:

```text
Japan
↓
South Korea
↓
China
↓
Vietnam
↓
Thailand
```

Routes do not need to represent actual travel visas, border crossings, or political arrangements.

This is a game journey system.

---

# 12. Country Neighbor Graph

Do not hardcode a single global linear country order.

Create a country graph.

Suggested representation:

```text
country_id
display_name
region
continent
neighbor_ids[]
travel_hub_weight
```

Example:

```json
{
  "country_id": "TR",
  "display_name": "Turkey",
  "region": "Southeastern Europe / Western Asia",
  "neighbor_ids": ["GR", "BG", "GE"]
}
```

The production dataset can later be expanded.

For countries with islands or limited land borders, use sensible nearby travel relationships rather than literal land borders only.

Example:

Japan may connect to:

- South Korea
- China
- Taiwan
- Philippines

Use a curated travel-neighbor graph rather than purely geometric distance.

---

# 13. Route Generation

World Tour route generation should use:

```text
home country
+
visited countries
+
current region
+
neighbor graph
+
route seed
```

Goals:

- avoid repeating the same country within a run
- favor geographically logical movement
- provide route variety between runs
- avoid impossible dead ends
- allow eventual access to every country

Suggested weighting:

```text
70–85% nearby/regional progression
15–30% long-haul opportunity
```

Exact percentages must be configurable and playtested.

---

# 14. Long-Haul Travel

Do not keep players trapped inside one region indefinitely.

After:

- completing a regional milestone
- reaching a certain number of countries
- reaching a major city/hub
- or exhausting nearby unvisited countries

offer long-haul travel.

Example:

```text
EUROPE COMPLETE

Where next?

✈ SOUTH AMERICA
✈ ASIA
```

The player chooses one of two or three destinations/regions.

This gives the player agency while preserving geographic progression.

---

# 15. Player Route Choice

At important travel milestones, allow destination choices.

Example:

```text
NEXT FLIGHT

Tokyo 🇯🇵
or
Cairo 🇪🇬
```

The player chooses.

Both choices should be valid for progression.

This means different players can gradually develop different passports and travel histories.

Do not present a choice after every country.

Use it at meaningful travel milestones.

---

# 16. World Tour Fairness

World Tour is personalized and therefore does not need to be directly comparable across every player.

World Tour leaderboards may rank:

- number of countries in one run
- tiles survived
- regions completed

But route difficulty can differ.

Therefore, highly competitive fair ranking should primarily happen in:

- Daily Challenge
- seeded Friend Challenges
- Infinite seeded events

These use identical paths/routes.

---

# 17. Daily World Tour

Daily Challenge must remain standardized.

Every player receives:

- same starting country
- same country route
- same tile seed
- same difficulty rules

for that day's challenge.

Example:

```text
DAILY WORLD TOUR

Start: France
Route:
France → Belgium → Netherlands → Germany → Poland
```

Every player gets the same route.

This makes rankings fair.

---

# 18. Friend Challenge Route

When a player shares a challenge, store:

```text
starting_country
country_route
seed
difficulty
generator_version
target_score
```

The friend must receive the exact same:

- countries
- order
- path
- difficulty
- generator version

Friend Challenge is therefore a true head-to-head comparison.

---

# 19. Country Progression

The long-term game goal is:

**Visit as much of the world as possible.**

Eventually support approximately 195 countries.

Do not build 195 countries before validation.

Initial build:

1. USA
2. France
3. Egypt
4. Turkey
5. Japan

For the initial prototype, route logic can use these countries as demo destinations even though full geographic connectivity is not yet present.

Each environment should visually communicate the destination.

Examples:

France:
- Eiffel Tower-inspired skyline composition
- Paris-style environment
- French visual cues

Egypt:
- desert
- pyramids
- warm atmospheric lighting

Turkey:
- Istanbul-inspired skyline
- Bosphorus-style visual environment
- recognizable architecture cues

Japan:
- Tokyo or traditional Japanese-inspired environment
- cherry blossom or neon city variants later

USA:
- recognizable American city/travel visual

Avoid copyrighted branded assets if licensing would be required.

Use original/stylized assets.

---

# 20. Passport Collection

Create an in-game passport.

Example:

```text
PASSPORT

🇺🇸 USA      ✓
🇲🇽 Mexico   ✓
🇧🇷 Brazil   ✓
🇫🇷 France   ✓
🇹🇷 Turkey   ✓
🇯🇵 Japan    🔒

Countries Visited
27 / 195
```

Countries can be visited over multiple runs.

Two separate concepts:

## Run Progress

How many countries player reached without losing.

Example:

> 17 countries this run

## Collection Progress

How many unique countries player has ever visited.

Example:

> 61 / 195 countries discovered

This distinction is important.

---

# 21. Travel History

Store a lightweight travel-history view.

Example:

```text
YOUR JOURNEY

Turkey
→ Greece
→ Bulgaria
→ Romania
→ Hungary
→ Austria
→ Japan
→ South Korea
```

This gives the player a personal travel story.

Later, allow players to view:

- countries visited
- route history
- regions completed
- longest trip
- favorite/start country

---

# 22. Region Completion

Group countries into logical gameplay regions.

Examples:

- North America
- Central America
- Caribbean
- South America
- Western Europe
- Northern Europe
- Eastern Europe
- Middle East
- North Africa
- Sub-Saharan Africa
- Central Asia
- South Asia
- East Asia
- Southeast Asia
- Oceania

Do not get stuck on geopolitical categorization during V1.

Use a practical gameplay-oriented internal grouping.

Completing a region may award:

- passport badge
- cosmetic item
- route choice
- long-haul flight

---

# 23. Infinite Memory Mode

Build an endless mode.

There is no country-ending path limit.

Rows continue indefinitely.

Each row contains one safe tile.

Most important rule:

**The safe route remains exactly the same after death.**

Example:

```text
Row 1 = lane 3
Row 2 = lane 1
Row 3 = lane 4
Row 4 = lane 4
Row 5 = lane 2
...
```

If player dies at row 37:

- restart from beginning
- rows 1–37 remain identical
- player gradually memorizes farther and farther

This creates the primary loop:

```text
Attempt 1 → row 7
Attempt 2 → row 12
Attempt 3 → row 19
Attempt 4 → row 31
Attempt 5 → row 44
```

Failure teaches the player the path.

---

# 24. Infinite Mode Environments

Infinite Mode may still use world-travel visuals.

Environment can change every configurable number of rows.

Example:

```text
Rows 1–50: France
Rows 51–100: Egypt
Rows 101–150: Japan
```

Environment changes must not change the seeded safe path.

The player's score is based on rows/tiles, not countries.

---

# 25. Seeded Path Generation

Infinite paths must use deterministic seeded generation.

Example:

```text
seed = 817294
```

Given:

- seed
- difficulty
- version

the exact path must always regenerate identically.

Do not store thousands of individual safe-lane values.

Generate them deterministically.

Ensure future game updates do not silently change old challenge paths.

Include a path-generator version value.

Example:

```text
generator_version = 1
```

Challenge identity should include:

```text
seed
difficulty
generator_version
```

---

# 26. Daily Challenge

Every day generates a deterministic path.

All players receive the same path for each difficulty.

Example:

```text
Date: 2026-10-02
Difficulty: Hard
Seed: 10592817
```

Everyone playing Daily Hard gets the same route.

Leaderboard example:

```text
DAILY HARD

1. Kaito     487
2. Mia       421
3. Serhan    397
4. Alex      365
```

Daily Challenge resets every calendar day.

Store historic leaderboard results if practical.

---

# 27. Infinite Difficulty Leaderboards

Separate leaderboards by difficulty.

Never compare Easy scores directly to Hard scores.

Leaderboards:

- Infinite Easy
- Infinite Moderate
- Infinite Hard
- Daily Easy
- Daily Moderate
- Daily Hard

Later:

- weekly
- monthly
- all-time
- friends-only

---

# 28. Kids Mode

Add a dedicated Kids Mode inside the same app.

Do not build a separate application initially.

Kids Mode should emphasize:

- fun
- encouragement
- simple memory practice
- travel discovery
- reduced frustration

## Kids Mode Settings

Initially:

- 3 lanes
- fewer rows
- longer preview
- slower pacing
- more visual guidance
- brighter presentation
- softer failure experience

Failure language should avoid:

> YOU LOST

Prefer:

> Almost! Let's try again.

or:

> Great try! Remember the path and go again.

## Kids Mode Characters

Prioritize:

- animals
- explorer
- astronaut
- robot
- cartoon traveler

## Country Rewards

Kids Mode should offer frequent rewards:

- passport stamps
- stickers
- country facts
- character accessories

Example after France:

> France 🇫🇷  
> The Eiffel Tower is in Paris.

Keep facts short.

Country facts must be factually verified before production release.

## Kids Safety

Kids Mode must not include:

- open chat
- messaging strangers
- unrestricted profile text
- public personal information
- uncontrolled usernames

Public leaderboard can be disabled in Kids Mode or use anonymous generated names.

Example:

> HappyPanda42

Add parental controls later if required.

---

# 29. Characters

Characters are cosmetic.

Never give characters gameplay advantages.

Do not create:

- longer preview characters
- safe-tile bonuses
- extra lives tied to paid characters
- speed bonuses affecting leaderboards

All competitive players must operate under identical gameplay conditions.

Initial character:

- Backpacker

Later characters:

- Explorer
- Tourist
- Business Traveler
- Robot
- Ninja
- Astronaut
- Pirate
- animal characters

Character animations:

- idle
- anticipation
- jump
- landing
- success
- celebration
- stumble
- fall
- panic/fall animation

Use one compatible animation skeleton where possible.

---

# 30. Audio and Music

Music is important.

The game should feel cheerful and adventurous.

## Main Menu

Use:

- upbeat travel/adventure theme

## Gameplay

Use:

- light background music
- subtle tension as player progresses

## Countries

Eventually give destinations distinctive musical flavor.

Do not copy copyrighted music.

Do not rely on stereotypical caricatures of national music.

Use original compositions with subtle regional instrumentation where appropriate.

## Sound Effects

Required:

- tile selection
- jump
- landing
- tile crack
- tile collapse
- fall
- passport stamp
- country complete
- new record
- leaderboard milestone
- airplane/travel transition
- UI interactions

Failure should feel funny/satisfying rather than punishing.

---

# 31. Falling Experience

Falling should be entertaining.

Wrong tile:

1. character lands
2. tile cracks
3. short pause
4. tile collapses
5. character reacts
6. character falls
7. camera briefly follows
8. failure/results UI appears

Different environments can eventually have different fall destinations:

- clouds
- water
- canyon
- snow
- jungle
- city
- desert
- ocean

Do not make the fall too long.

It should remain satisfying after repeated failures.

---

# 32. Country Completion Sequence

Upon finishing a country's final row:

1. character reaches destination platform
2. celebratory animation
3. destination name appears
4. passport stamp animation
5. optional short country fact
6. score update
7. determine next geographically logical destination
8. if milestone reached, optionally show destination choice
9. transition to next country

Example:

```text
WELCOME TO JAPAN 🇯🇵

Country #14
14-country streak

[Continue Journey]
```

Keep transitions fast.

Do not make users wait through long cinematics.

---

# 33. Travel Transition

Country changes should feel like travel.

Potential transition:

```text
passport stamp
↓
small map animation
↓
airplane travels along curved route
↓
next destination appears
```

Keep this sequence short.

Target:

approximately 2–4 seconds, skippable after repeated use if needed.

---

# 34. World Map

Eventually include a simplified world map showing:

- home country
- visited countries
- current location
- route traveled
- possible next destinations

This should support the travel fantasy.

Do not make the map mandatory for M0–M2.

---

# 35. Social / Viral System

Virality must be designed into the product.

Do not rely on paid advertising.

After a strong run:

```text
🌍 24 COUNTRIES
🔥 389 TILES
🏆 TOP 3.8%

Can you beat me?
```

Provide share action.

Generate challenge link:

```text
passportrun.com/c/8DF92
```

A friend opening the challenge should see:

```text
Serhan reached 389 tiles on Hard.

Can you beat 389?

[PLAY CHALLENGE]
```

The friend must receive the same:

- starting country
- route
- seed
- difficulty
- generator version

This makes the challenge fair.

---

# 36. Share Cards

Generate visually appealing share cards.

Include:

- character
- country backdrop
- score
- countries visited
- current/final country
- difficulty
- route summary where practical
- rank/percentile if available
- call-to-action

Example:

```text
PASSPORT RUN

I visited 27 countries
without falling.

Turkey → Greece → Bulgaria → Romania → ...

Hard Mode
Top 4% today

Can you beat me?
```

Do not require login to create a share card.

---

# 37. Monetization Strategy

Primary monetization:

**Advertising**

Secondary:

**One-time purchases and cosmetics**

Do not make core gameplay pay-to-win.

---

# 38. Rewarded Ads

Rewarded ads should be the highest-priority ad format.

Best use:

Player fails after reaching a meaningful point.

Display:

```text
You reached JAPAN 🇯🇵

18 countries
342 tiles

[RESTART]

[WATCH AD TO CONTINUE]
```

If player watches the rewarded ad:

Resume at:

- beginning of current country
- or most recent legitimate checkpoint

Do not revive directly on the exact failed tile.

The player should still need memory skill.

---

# 39. Interstitial Ads

Use forced interstitial ads conservatively.

Do not show an interstitial after every death.

Initial rule:

- approximately every 2–3 completed/failing runs

But frequency must be configurable and tested.

Never interrupt:

- mid-jump
- mid-country
- path preview
- active memorization
- important reward animation

Show ads only at natural breaks.

---

# 40. Remove Ads

Implement:

**Remove Ads Forever**

One-time purchase.

Suggested starting price:

**$4.99**

Potential test:

**$5.99**

Do not make simple ad removal a subscription.

Removing ads should disable:

- forced interstitial ads

Rewarded ads remain available because they are voluntary.

Example:

A Remove Ads owner may still choose:

> Watch an ad to continue.

---

# 41. Future Premium Content

Potential future purchases:

- character packs
- outfits
- trails
- passport covers
- celebration animations
- premium visual themes

Possible expansion packs:

- Ancient Civilizations
- Wonders of the World
- Islands
- Space Journey
- Fantasy Kingdoms
- Underwater World

Do not paywall ordinary real-world countries in V1.

The core goal of visiting the world should remain accessible.

---

# 42. Subscription

Do not launch with a subscription.

A future subscription is acceptable only if there is meaningful recurring content.

Possible:

**Explorer Pass**

Potential benefits:

- monthly cosmetics
- special worlds
- bonus challenge modes
- exclusive themes
- ad-free status
- premium passport

Do not add until retention and audience justify it.

---

# 43. App Store Positioning

Do not market as:

> another hypercasual game

Primary message:

> A memory game disguised as a world adventure.

Example description:

> Memorize the safe path, jump across the tiles, and travel from country to country without falling. Start from your chosen home country and see how far around the world your memory can take you.

> Choose your difficulty, compete on daily identical paths, collect passport stamps, climb the leaderboards, and discover new destinations.

> Play. Travel. Remember. Have fun.

---

# 44. Parent Positioning

For parents:

> Passport Run turns memory practice into a colorful travel adventure.

Focus messaging on:

- attention
- sequencing
- visual recall
- concentration
- fun
- geography discovery

Do not claim scientifically proven cognitive improvement unless independently validated later.

---

# 45. Visual Style

Use a polished stylized 3D aesthetic.

Target:

- colorful
- friendly
- modern
- clean
- globally appealing
- readable on small mobile screens

Avoid:

- hyperrealism
- dark/gritty visual style
- complicated UI
- excessive particle effects
- clutter

Reference feel:

- polished casual mobile game
- high-quality stylized environments
- friendly animation

Do not clone another game's art style.

---

# 46. Orientation

Primary orientation:

**Portrait**

Reason:

- one-handed gameplay
- easy tile tapping
- mobile casual-game behavior
- social-video-friendly screenshots

Landscape support is not necessary for initial V1.

---

# 47. Core Scene Architecture

Suggested Godot structure:

```text
GameRoot
├── GameModeManager
├── RunManager
├── DifficultyManager
├── PathGenerator
├── WorldRouteManager
├── CountryGraph
├── CountryManager
├── TileGrid
│   ├── Row
│   └── Tile
├── Player
├── CameraRig
├── EnvironmentRoot
├── AudioManager
├── EffectsManager
├── UI
│   ├── HUD
│   ├── PreviewUI
│   ├── FailureUI
│   ├── CountryCompleteUI
│   ├── DestinationChoiceUI
│   ├── PassportUI
│   ├── WorldMapUI
│   ├── LeaderboardUI
│   ├── MainMenuUI
│   └── StoreUI
├── MonetizationManager
├── NetworkManager
└── AnalyticsManager
```

Keep modules decoupled.

---

# 48. WorldRouteManager Responsibilities

WorldRouteManager must:

- read player's home country
- track current country
- track visited countries
- select valid neighboring destinations
- avoid repetition where possible
- determine long-haul opportunities
- generate destination choices
- provide deterministic routes for Daily/Friend Challenge modes
- serialize route state

Do not mix tile-generation logic into route-generation logic.

---

# 49. Path Data

Example structure:

```gdscript
class_name PathDefinition

var seed: int
var generator_version: int
var lane_count: int
var row_count: int
var safe_lanes: Array[int]
```

For finite levels:

```text
safe_lanes = [1,2,0,1,1,2,0,...]
```

For infinite:

generate lazily by row using deterministic RNG.

---

# 50. Tile States

Each tile should support:

```text
HIDDEN_SAFE_STATE
REVEALED_SAFE
NORMAL
SELECTED
CORRECT
WRONG
CRACKING
FALLING
DISABLED
```

Animations should be driven by state rather than duplicated logic.

---

# 51. Player Movement

Player should not use free movement.

Player chooses destination tile.

Movement system calculates:

- jump arc
- duration
- facing
- landing position

Do not allow player to jump between arbitrary world coordinates.

Input:

```text
selected lane
```

Result:

```text
player jumps to next row, selected lane
```

This preserves deterministic gameplay.

---

# 52. Input Validation

Ignore input when:

- character already jumping
- preview active
- level complete
- fail sequence active
- ad showing
- transition active

Prevent multi-tap exploits.

---

# 53. Country Environment Interface

Country environments should plug into a common interface.

Example:

```gdscript
CountryEnvironment
- country_id
- display_name
- region
- environment_scene
- ambient_audio
- background_music
- passport_icon
- completion_effect
```

Country scenes must not contain gameplay logic.

---

# 54. Country Data

Suggested country data model:

```text
country_id
display_name
continent
region
neighbors[]
travel_connections[]
environment_scene
passport_asset
enabled
```

Keep geography/travel graph separate from visual scenes.

This allows the route system to expand before every country has final art.

---

# 55. Backend Data Model

Suggested Convex entities.

## players

```text
id
anonymousId
displayName
homeCountryId
createdAt
lastSeenAt
countriesVisited[]
regionsCompleted[]
bestEasy
bestModerate
bestHard
kidsModeEnabled
removeAdsEntitlement
```

## runs

```text
id
playerId
mode
difficulty
startingCountryId
currentCountryId
route[]
seed
generatorVersion
score
countriesVisited
tilesCompleted
startedAt
completedAt
continueCount
```

## dailyChallenges

```text
date
difficulty
startingCountryId
route[]
seed
generatorVersion
```

## leaderboardEntries

```text
playerId
displayName
mode
difficulty
seed
score
date
verified
```

## challenges

```text
challengeCode
creatorId
startingCountryId
route[]
seed
difficulty
generatorVersion
targetScore
createdAt
```

## purchases

```text
playerId
platform
productId
transactionReference
verified
createdAt
```

Never trust purchase status sent directly by client.

---

# 56. Anti-Cheat

Leaderboards must not blindly accept client-reported scores.

V1 anti-cheat should include at least:

- valid seed
- valid route
- generator version
- difficulty
- expected maximum row progression
- run duration sanity checks
- impossible jump-rate rejection
- invalid country progression rejection
- signed/session-aware submission where practical

Later:

- deterministic replay data
- event hashes
- server-side verification

Do not over-engineer anti-cheat before launch.

---

# 57. Analytics

Analytics is critical.

Track:

## Acquisition

```text
install
first_launch
home_country_selected
tutorial_started
tutorial_completed
```

## Gameplay

```text
run_started
run_failed
run_completed
tile_selected
wrong_tile
country_started
country_completed
destination_choice_shown
destination_selected
region_completed
long_haul_started
infinite_started
daily_started
```

## Retention

Track:

- D1
- D3
- D7
- D30

## Engagement

Track:

- sessions per day
- average session length
- runs per session
- tiles per run
- countries per run
- retry rate
- failure row distribution
- average countries before long-haul
- destination-choice behavior

## Monetization

```text
rewarded_offer_shown
rewarded_accepted
rewarded_completed
interstitial_shown
remove_ads_viewed
remove_ads_purchased
```

## Viral

```text
share_clicked
challenge_created
challenge_opened
challenge_started
challenge_completed
```

## Kids Mode

```text
kids_mode_started
kids_run_started
kids_country_completed
```

Do not collect unnecessary sensitive child information.

---

# 58. Core Success Metrics

The prototype should be judged by numbers, not whether the team personally likes it.

Important:

## Retention

Primary:

**D1 retention**

Strong early signal target:

approximately 30%+ would be encouraging.

Do not treat this as a guaranteed benchmark.

## Retry Behavior

Measure:

- percentage of players immediately retrying after failure
- runs per session

If players are not retrying, the core mechanic is not working.

## Rewarded Ad Acceptance

Measure:

- continue offer impressions
- acceptance percentage
- completion percentage

## Sharing

Measure:

- challenge links created
- challenge conversion rate

## Progression

Measure:

- countries reached
- passport completion behavior
- home-country route completion
- region completion
- destination-choice engagement

---

# 59. MVP Scope

Do not build the full dream immediately.

V1 should contain only:

- one polished traveler character
- portrait gameplay
- tile-grid system
- 3/4/5 lane difficulty
- path preview
- path hiding
- correct/wrong tile behavior
- falling
- restart
- World Tour
- home-country selection
- initial route logic
- nearby-country progression
- basic long-haul destination selection
- Infinite Mode
- daily seeded challenge
- five countries
- passport
- leaderboard
- anonymous identity
- rewarded continue
- interstitial infrastructure
- one-time Remove Ads product
- analytics
- sound effects
- background music
- basic challenge links
- basic share card

Do NOT build yet:

- all 195 countries
- multiplayer
- chat
- complex social network
- clans
- large skin marketplace
- subscription
- elaborate story
- hundreds of characters
- advanced powerups
- PvP real-time racing

---

# 60. Development Milestones

## M0 — Technical Foundation

Build:

- Godot project
- portrait mobile configuration
- basic scene architecture
- configurable difficulty resources
- test environment
- temporary character
- temporary tiles

Acceptance:

- launches in editor
- launches on at least one target mobile device
- stable 60 FPS target on ordinary modern device
- clean project structure

---

# 61. M1 — Core Tile Gameplay

Build:

- rows
- lanes
- safe tile
- player jumping
- wrong tile collapse
- player falling
- restart

Acceptance:

- player can tap one tile in next row
- character jumps correctly
- correct tile advances
- incorrect tile fails
- input cannot break movement
- level restarts correctly
- no memory leaks or duplicate nodes after repeated restarts

---

# 62. M2 — Memory Reveal System

Build:

- generated safe path
- path reveal
- reveal timer
- hide path
- play phase

Acceptance:

- all safe tiles can be previewed
- preview duration varies by difficulty
- after preview all tiles look identical
- safe path remains internally unchanged

---

# 63. M3 — Difficulty Modes

Build:

Easy:
3 lanes

Moderate:
4 lanes

Hard:
5 lanes

Acceptance:

- selectable from menu
- correct lane counts
- configurable preview times
- separate scores
- separate leaderboard metadata

---

# 64. M4 — Infinite Memory

Build:

- seeded deterministic infinite path
- row streaming
- restart from beginning
- same path after death
- score = farthest row

Acceptance:

Given identical:

```text
seed
difficulty
generator_version
```

path must be identical across repeated runs.

---

# 65. M5 — Country System

Build first five environments:

- USA
- France
- Egypt
- Turkey
- Japan

Build:

- country completion
- environment switching
- country label
- passport stamp

Acceptance:

- completing path moves to next destination
- previous environment unloads cleanly
- passport records visit
- run country count increments

---

# 66. M6 — Home Country + Route System

Build:

- home-country selection
- country graph
- route manager
- nearby-destination selection
- basic long-haul rule
- route persistence

Acceptance:

- player chooses starting country
- World Tour begins there
- next destination is selected from valid route relationships
- countries do not immediately repeat
- route survives app restart during an active saved run if run persistence is enabled

For five-country prototype, use a temporary curated graph.

---

# 67. M7 — World Tour

Build:

- sequence of countries
- continuous run
- geographic route progression
- long-haul transition
- destination choice at milestone
- run statistics
- failure results

Acceptance:

Player can:

```text
start from chosen home country
↓
complete country
↓
travel to valid next country
↓
continue through route
↓
receive long-haul destination choice
↓
select next region
↓
continue journey
↓
fail
↓
see countries reached
```

---

# 68. M8 — Passport

Build:

- unique visited-country tracking
- passport screen
- current completion count
- locked/unvisited destinations
- travel history

Acceptance:

- unique destination counted once
- survives app restart
- visual country stamp appears
- route history can display at least recent destinations

---

# 69. M9 — Daily Challenge

Build:

- daily backend seed
- standardized starting country
- standardized country route
- separate seed by difficulty
- date-specific leaderboard

Acceptance:

Two devices using same:

```text
date + difficulty
```

receive identical:

- start country
- route
- tile path

---

# 70. M10 — Leaderboards

Build:

- daily
- infinite
- Easy/Moderate/Hard segregation

Acceptance:

- score submits
- visible rankings
- impossible/basic-invalid submissions rejected
- anonymous player names supported

---

# 71. M11 — Monetization

Integrate mobile ad provider.

Primary candidates:

- AdMob or compatible mediation stack

Build:

- rewarded continue
- interstitial
- ad-frequency configuration
- ad failure fallback

Acceptance:

If ad unavailable:

- game must continue
- no player lockout
- no endless loading

Rewarded continuation only activates after verified reward callback.

---

# 72. M12 — Remove Ads Purchase

Implement product:

```text
remove_ads_forever
```

Suggested launch price:

```text
$4.99 USD
```

Acceptance:

After purchase:

- forced interstitials stop
- entitlement survives restart
- entitlement restores on reinstall/account restoration where platform allows
- rewarded ads remain available voluntarily

---

# 73. M13 — Kids Mode

Build:

- Kids Mode toggle
- simplified UI
- 3 lanes
- longer preview
- reduced row count
- friendly failure messaging
- anonymous safe identity
- optional country facts

Acceptance:

Kids Mode must not expose:

- open chat
- personal profile text
- public contact information

---

# 74. M14 — Audio & Polish

Build:

- menu theme
- gameplay theme
- effects
- passport stamp
- success/failure audio
- travel transition audio
- character animations
- country transition effects

Acceptance:

Audio:

- loops cleanly
- respects mute settings
- resumes correctly after app focus changes

---

# 75. M15 — Viral Challenge System

Build challenge URL.

Challenge contains:

```text
startingCountryId
route
seed
difficulty
generatorVersion
targetScore
challengeId
```

Acceptance:

Opening challenge:

- launches correct mode
- starts in same country
- loads exact same country sequence
- loads exact same tile route
- displays score to beat

---

# 76. M16 — Share Cards

Generate a share image with:

- player's score
- countries
- route summary
- difficulty
- branding
- challenge CTA

Acceptance:

- generated locally or through safe backend rendering
- does not expose personal information
- share action opens native sharing UI on supported platforms

---

# 77. M17 — Analytics Validation Build

Instrument all required events.

Create a test dashboard/report for:

- onboarding funnel
- home-country choices
- retry rate
- D1
- run length
- wrong-row heatmap
- destination choices
- long-haul choices
- rewarded-ad conversion
- share conversion

Do not release broadly without working analytics.

---

# 78. Monetization Philosophy

The game must remain enjoyable without spending money.

Never:

- sell safe paths
- sell memory hints on competitive leaderboard runs
- allow paid characters to improve score
- make paid players mechanically stronger
- force constant ads

Money should come from:

1. player volume
2. rewarded ads
3. reasonable interstitials
4. one-time Remove Ads
5. cosmetics
6. future premium worlds/content

---

# 79. Ad Flow

Recommended failure flow:

```text
Player falls
↓
Failure animation
↓
Results
↓
Offer:

[Restart]

[Watch Ad — Continue Journey]
```

If Continue selected:

```text
rewarded ad
↓
ad completes successfully
↓
resume from beginning of current country/checkpoint
```

If ad fails:

```text
show:
"Ad unavailable right now."

Return player to results.
```

Never trap the user.

---

# 80. Revenue Goal

Do not design around a guaranteed revenue figure.

Revenue depends on:

- DAU
- geography
- retention
- rewarded-ad acceptance
- ad fill
- session frequency
- store conversion

Primary business objective is:

> Create enough retention and repeated sessions that each active player naturally generates monetizable ad opportunities.

First meaningful scale target:

**10,000 DAU**

Do not assume it will happen automatically.

The product must earn this through retention and distribution.

---

# 81. Distribution Strategy

Because the founder does not want a business requiring cold sales or a large advertising budget, distribution must be built into the game.

Primary organic loops:

## App Store Discovery

Good screenshots, ASO, ratings, retention.

## Friend Challenges

```text
I reached 219.
Beat me.
```

## Travel Share Cards

Example:

```text
I traveled from Turkey to Japan
without falling.

14 countries.
Can you beat me?
```

## Daily Challenge

Users return and compare.

## Browser Portals

If mobile core proves fun:

- CrazyGames
- Poki

These can provide additional distribution and advertising monetization.

---

# 82. Core Product Principle

This should not feel like:

> memorize 20 numbers and tap blocks

It should feel like:

> I started from home and I'm trying to see how far around the world my memory can take me.

The travel layer is essential.

The geographic progression is essential.

The passport is essential.

The country progression is essential.

The competition is essential.

The tile mechanic alone is not enough differentiation.

---

# 83. Game Identity

The identity is:

**Travel + Memory + Competition + Collection**

Not:

**Glass bridge clone**

Not:

**Generic tile game**

Not:

**Fake-money gambling game**

Do not include real-money wagering.

---

# 84. Design Goal

A new player should understand the game within approximately five seconds.

The first experience should communicate:

1. choose where journey begins
2. remember highlighted path
3. path disappears
4. tap safe tiles
5. reach destination
6. travel onward

No long tutorial text.

Use animation and interaction.

---

# 85. Tutorial

Tutorial should be interactive.

Example:

```text
MEMORIZE THE SAFE TILES
```

Show 3-lane × 3-row route.

Then:

```text
NOW FOLLOW THE PATH
```

Player taps.

If correct:

```text
Great!
```

If wrong:

Allow instant retry.

Tutorial target:

under one minute.

After tutorial:

```text
WHERE SHOULD YOUR JOURNEY BEGIN?
```

Player chooses home country.

---

# 86. Performance Requirements

Target:

- 60 FPS on normal supported mobile devices
- low memory usage
- fast restart
- minimal load between countries
- compressed mobile-friendly assets

Do not load every country's assets simultaneously.

Use asynchronous/preloaded transitions where appropriate.

---

# 87. Save System

Persist locally:

- settings
- sound/music preference
- difficulty
- home country
- country discoveries
- regions completed
- travel history
- best local scores
- Kids Mode preference
- purchase entitlement cache
- anonymous ID

Sync important data to backend when connected.

Game should remain playable offline where possible.

---

# 88. Accessibility

Include:

- music volume
- sound-effects volume
- mute
- vibration/haptics toggle
- reduced motion option
- high-contrast safe-path preview option if needed
- readable fonts
- clear touch targets

Do not rely solely on color to indicate safe tiles during preview.

Use:

- glow
- symbol
- animation
- shape cue

---

# 89. Haptics

Use subtle haptic feedback:

Correct landing:
small tap.

Wrong landing:
stronger impact.

Country complete:
short celebratory pattern.

Long-haul departure:
optional subtle travel pulse.

Allow user to disable haptics.

---

# 90. Future Features — Not V1

Keep architecture capable of supporting later:

- continent events
- seasonal destinations
- route achievements
- friends leaderboard
- family mode
- classroom mode
- travel trivia
- additional memory types
- reverse routes
- fog mode
- timed mode
- moving tiles
- speed mode
- special challenge modes
- tournaments
- achievement system
- streak rewards
- cosmetics shop
- premium worlds
- Explorer Pass
- map-based route planning
- unlockable airports/travel hubs

Do not implement until data supports expansion.

---

# 91. Validation Gate

After the five-country build is playable, stop adding major content.

Test real players.

Measure:

- tutorial completion
- home-country selection completion
- retry rate
- average runs/session
- average session duration
- Easy/Moderate/Hard selection
- World Tour usage
- Infinite usage
- country progression
- destination-choice engagement
- D1 retention
- challenge sharing
- rewarded-ad acceptance

If retry and retention are poor:

fix gameplay before adding more countries.

Do not respond to poor metrics by creating 100 more environments.

---

# 92. Kill / Continue Criteria

Do not define success only as downloads.

Promising signals:

- players repeatedly retry
- meaningful D1 retention
- players progress farther across sessions
- players care about reaching new countries
- players use destination choices
- leaderboard engagement
- Daily Challenge return behavior
- meaningful rewarded-ad acceptance
- challenge links actually bring friends

Warning signs:

- most players quit after one failure
- tutorial abandonment
- players do not care where they travel
- players never use Infinite
- players do not care about passport progression
- Continue-ad offer rarely accepted
- challenge sharing near zero

Iterate based on these.

---

# 93. First Build Instruction to Agent

Start with M0–M2 only.

Do NOT begin backend, ads, countries, passports, route systems, leaderboards, or store functionality yet.

Build the smallest playable vertical slice:

```text
Portrait Godot game
↓
1 character
↓
3 lanes
↓
10 rows
↓
one safe tile per row
↓
preview safe path
↓
hide path
↓
tap destination tile
↓
jump
↓
correct = continue
↓
wrong = tile breaks + fall
↓
results
↓
instant retry
```

Use temporary low-poly assets where necessary.

The objective is to answer one question first:

> Is remembering and crossing the path actually fun?

Once M0–M2 are stable, proceed milestone-by-milestone.

Do not skip acceptance criteria.

Do not label a milestone PASS without demonstrating its acceptance requirements.

---

# 94. Final Product Vision

A player opens Passport Run.

They choose:

**World Tour**

The game asks:

> Where should your journey begin?

They choose:

**Turkey**

Their journey starts:

```text
Turkey
→ Greece
→ Bulgaria
→ Romania
→ Hungary
→ Austria
```

At the end of that leg:

```text
EUROPE JOURNEY COMPLETE

Where next?

✈ Japan
✈ Egypt
```

They choose Japan.

They see a short safe path.

They memorize it.

The path disappears.

They jump.

They survive.

They reach Japan.

Their passport gets stamped.

They continue to South Korea.

Then another country.

At country 14 they make one mistake.

The tile cracks.

They fall.

The game shows:

```text
14 COUNTRIES
287 TILES
NEW RECORD

Top 6% today

Turkey → Greece → Bulgaria → Romania → ... → Japan

[RESTART]

[WATCH AD TO CONTINUE]

[CHALLENGE A FRIEND]
```

They choose Continue or Retry.

Later they open Infinite Mode and try to memorize farther than yesterday.

Their friend receives:

> Serhan reached 287 on Hard on this exact route. Can you beat him?

Their child can play Kids Mode with simpler paths, friendly characters, longer previews, and country discovery.

The business earns through:

- rewarded ads
- conservative interstitials
- one-time Remove Ads purchase
- later cosmetics and premium expansions

The product should feel:

**fun first, mentally engaging second, monetized naturally rather than aggressively.**

## Adventure, collection and friend expansion — 2026-10-02

Implemented the approved continuation: separate Adventure Play with Norwegian ice drift, Brazilian/Greek moving bridges, Moon low gravity and underwater buoyancy; Special pack ownership still gates paid adventures. Standard and competitive mechanics stay versioned. Moving tiles freeze during jumps and pause, and the decision clock still resets after landing.

MY TRAVEL ROOM displays up to six selected earned souvenirs; WARDROBE equips earned outfit tints, hats and backpack colors, with a live character preview. Both persist locally and reject unearned selections on reload. These are cosmetic variations of the existing character artwork.

Challenge sharing now copies a self-contained `passport-run://challenge/…` installed-app link containing the same path and up to 512 successful-step timings. Imported local friend ghosts report progress and appear only on already visited safe stones, never revealing future lanes. Longer recordings explicitly end at the cap; ghosts are not verified ranked opponents. iPhone exports register the scheme and include a native receiver that opens challenge review. Public hosted/universal links and a native share sheet remain pending.

Adventure and paid destinations have skippable, pauseable cinematic artwork arrivals before memorization, with Reduced Motion support. Physical-device testing is intentionally deferred to the user; no device acceptance or live purchase is claimed. Latest signed project: `/private/tmp/passport-native-travel-expansion/PassportRun.xcodeproj`. Regenerate with `python3 tools/export_iphone.py /private/tmp/passport-native-travel-expansion`, then build/run through Xcode. See [native link notes](ios/native/README.md).

Rendered feature checks passed (37); screenshots are `artifacts/expansion-*.png`. Signed generic-iPhone build passed. All 12 Godot regression suites and four Python checks passed; the real local Godot/backend integration passed 19 checks. Exported native resource-pack loading passed.

## Unique destination artwork — 2026-10-03

The user requires a unique image for every destination. Afghanistan had incorrectly inherited a Thai-temple regional scene; it now has its own Hindu Kush-inspired valley painting at `assets/backdrops/AF.png`. All other shared free-country scenery is replaced: 244 distinct paintings across 16 atlases plus six dedicated country PNGs. With the existing 32 paid scenes, every one of the 282 destinations resolves to a different image. Infinite retains its separate dreamscape.

`GameCatalog.backdrop()` prioritizes dedicated PNGs, then the stable ID-to-atlas/cell mapping in `resources/geography/artwork.json`, then existing paid artwork. Every gameplay/passport/sticker/travel surface already uses this lookup. Atlases load on demand. Country data, routes, catalog and balance versions are unchanged. Generated images are stylized country-inspired compositions; they are not exact landmark photographs. Full prompts and built-in imagegen provenance are recorded in `docs/unique-artwork-prompts.md`.

`tests/test_unique_artwork.gd` checks all 282 resolved images, region bounds, uniqueness and the Afghanistan correction; added to `tools/check.sh`. Rendered 390×844 checks capture AF, TH, IN, PK, IR, MY, GL, AQ and passport in `artifacts/unique-*.png`. Physical-device acceptance remains deferred to the user.

## Balloon Tour arcade and connected map — 2026-10-03

Added **BALLOON TOUR · ARCADE** to the main menu, inspired by [Pang's balloon-splitting world tour and connected map](https://gamingpicks.wordpress.com/2014/05/31/classic-games-pang-arcade-1989/). The reference article, gameplay image and `pana_map.png` were inspected. No reference screenshots, music or original sprites were copied into the game.

This separate single-player mode uses left/right movement and upward harpoons. Large balloons split into two medium ones; medium into two small ones; small balloons pop. Three rounds per destination introduce additional balloons and a blocking platform. Lives, hit grace, a 90-second round timer, shield/freeze/double-wire pickups, pause, retry and local scores are implemented. Retry rolls back failed-round points. Keyboard arrows/A/D and Space work; independent touch indices support holding movement and FIRE together. Responsive geometry keeps balloons circular in portrait and landscape.

World route uses the existing border/flight planner and includes all 250 free countries/territories, beginning at the chosen home. Special (24) and Cinema (8) routes keep their independent verified-entitlement gates, including ownership revocation during arcade play. Every round uses `GameCatalog.backdrop` and existing destination music. Three successful rounds earn the shared passport stamp, souvenir/cosmetic progress and daily destination mission; a damaged/timed-out country cannot receive the flawless mission. Arcade records use `balloon:<difficulty>` and are local, separate from verified memory scores. Active arcade runs do not resume after app termination.

The passport map connects recent saved completion history. Arcade arrival/results show a connected upcoming itinerary with the current destination highlighted. Routes wrap at the date line instead of drawing across the map. Fantasy/paid locations without geographic pins remain in the passport rather than receiving invented map coordinates. Other gameplay retains its memory rules.

This is a playable original adaptation with three pickup types, not a complete reproduction of Pang's weapons, animals or two-player mode. Those extra mechanics and multiplayer are outside this first arcade implementation. User physical-device testing remains pending.

## Expanded mystery arcade — 2026-10-03

Balloon Tour now has walking, upward throwing, blaster recoil and hit/falling/death poses. Death plays before retry; pause freezes it. Eight weapons include the basic wire, double/triple arrows, ceiling-sticking harpoon, rapid blaster, spread shot, piercing laser and splash rocket. Special weapons last 18 seconds. All 22 drop outcomes share the same question-mark appearance until collected. Helpful drops include shield, freeze, slow balloons, quick boots, heart, time, coins, bomb and magnet; hazards include faster/multiplied balloons, heavy boots, reversed controls, a short weapon jam and lost time. Multiplication caps its immediate wave at 40 balloons; splitting descendants can increase that count. Rounds use 85/80/75 seconds by difficulty, with speed and balloon count increasing along the tour. Combo points and burst particles provide feedback. Existing destination artwork, music, passport stamps and paid-route gates remain integrated. Screenshots: `artifacts/arcade-rich-*.png`. Physical-device testing remains pending.

## Balloon Tour adventures and local co-op — 2026-10-03

All six approved additions are implemented in the existing arcade. Round one is balloon clearing, round two rotates through 25-second swarm survival, no-fire dodging and rising-water clearing challenges, and round three is an armored boss. Bosses take 5/7/9 hits by difficulty, shed armor, reverse/increase movement and spawn faster waves below half health. A passport stamp requires finishing all three rounds, including remaining boss minions.

DestinationTheme drives sandy gusts, icy movement inertia, underwater gravity/bubbles and space/Moon low gravity, with themed floors and the existing unique destination artwork/music. Repeated weapons upgrade to level three and fire faster. Different weapons inherit a modifier from the preceding weapon: extra volley, ceiling attachment, piercing, blast or rapid fire. Examples include ceiling-sticking blasters and explosive double arrows; upgrades expire with the weapon. All drops retain the same question mark. Pause exposes collect/avoid; Q toggles it on desktop. Three consecutive beneficial mystery collections award 500 points; a curse breaks that chain.

Select LOCAL CO-OP on the arcade's arrival screen, then START. P1 uses arrows/A/D + Space; P2 uses J/L + K, or each player's dedicated touch row. Players move independently and share the weapon arsenal/pickup effects. A fallen player can be revived by a teammate staying within 70 logical units for two seconds, within a 15-second deadline. Both falling ends the round. Hearts revive a fallen teammate or grant a shield to a healthy team. Co-op records use `balloon-coop:<difficulty>`, including menu exits. This is local shared-screen co-op; online networking and second-device pairing were not added. Screenshots: `artifacts/arcade-adventure-*.png`.
