# Passport Run — agent handoff

Start here. Read `spec.md`, then this file, then run the project before changing it.

## macOS continuation update — 2026-10-02

Read [docs/iphone-validation.md](docs/iphone-validation.md) for the latest evidence and exact next action. Godot 4.5.2 and its matching iOS template are now installed on this Mac. Xcode detects a paired available physical iPhone. The inherited four suites passed here; after safe-area/result-layout fixes, all five headless suites and rendered mode/mobile UI checks passed.

An iPhone-only Xcode export preset and temporary original app icon now exist. Export preflight is blocked by the missing Apple Team ID and bundle identifier, which have been requested from the user. No native build, device run, signing, or TestFlight validation has occurred. The historical Linux evidence and remaining milestone scope below still apply.

## User intent and authorization

The user wants Passport Run built from the supplied specification and two reference images. The first iteration followed spec section 93 and stopped at M0–M2. The user subsequently asked: **“you finish what you can and write a passover to an agent where they should continue and what's been completed.”** That instruction authorized continued offline implementation beyond the original first-build boundary. Do not reimpose the superseded M0–M2-only stop.

The first mobile target is **iPhone**. The user confirmed they have a **Mac with Xcode and a physical iPhone**. The current agent worked on Linux and could not connect to that Mac/device. No iOS build, signing, physical-device performance, or TestFlight verification has happened.

The intended engine is Godot 4.x and language GDScript. The implementation was built and tested on **Godot 4.5.2 standard edition**, using the Compatibility renderer. Do not replace it with a website, Unity, or Unreal. Preferred backend remains Convex; no backend is implemented or provisioned.

## What exists now

This is a playable **offline five-country prototype**, not the finished commercial game.

- Portrait 3D tile game with a temporary backpacker, preview/checkmark reveal, hidden path, validated next-row tapping, jumping, cracking/collapse/fall, results, retry, pause, and focus interruption handling.
- Main menu, searchable explicit home-country selection, interactive three-row tutorial, and Easy/Moderate/Hard selection.
- Difficulty resources: Easy 3 lanes / 10 rows / 5 seconds; Moderate 4 / 14 / 3; Hard 5 / 20 / 2. Kids uses 3 / 6 / 8 and a slower jump.
- World Tour through five destinations with country completion, non-repeating route choices, demo regional preference and long-haul choices, completed-country count, and total tiles. A tour ends after its five unique countries.
- Five temporary procedural environment variants: US city towers, France open tower, Egypt pyramids/desert color, Turkey domes/minarets, Japan pagoda/cherry-colored trees. They share a coastal test set and are **not final assets or polished country scenes**.
- Infinite Memory with versioned random-access path generation, bounded tile windows, successive preview sections, score by tiles, unchanged path on retry, and optional new seed. Environment selection changes by 50-row bands, applied at the next section transition.
- Offline Daily World Tour: UTC date + difficulty deterministically select the seed, fixed starting country France, route, and tile paths. A retry stays pinned to the original date even if midnight passes. This is **not server-authoritative or ranked**.
- Persistent passport stamps (one per country), recent travel history (bounded to 200), saved home/difficulty/accessibility/audio preferences, anonymous local identity, and separate local best records by mode/difficulty/date.
- Save-file schema v1, validated loading, temp-file replacement, previous-valid backup recovery, and a visible save-error message in the menu.
- Kids Adventure with simpler paths, encouraging messages, and no sharing actions, public profiles, or chat. It shares the passport with other local modes.
- Reduced-motion and high-contrast options, music/effects volume, haptics toggle; original synthesized prototype music and sound cues. Device vibration and subjective audio quality remain unverified.
- Portable `PR1.` challenge codes: validated payload includes starting country, exact route, seed, difficulty, generator version, and target. Import replays identical paths. Copy-to-clipboard sharing is implemented. Codes are **unsigned local data**, not trusted online scores or public links.
- Local 720×1000 PNG share card with branding, score, difficulty, route, and invitation. This is a text-based prototype card, **without the planned character/backdrop art or native share sheet**.
- Bounded device-local gameplay event log (500 events, allowlisted metadata) and `tools/summarize_events.py`. Nothing is uploaded. This is **not the production retention/monetization dashboard**.

## Where to resume, in order

### 1. Open on the Mac and verify the actual iPhone build

Import `project.godot` into Godot 4.5.2, run with F5, and run the checks below. Install matching export templates, add an iOS export preset, and enter the user's Apple Team ID and a bundle identifier they control. Export outside the source tree, open the generated Xcode project, set signing, and run on the connected iPhone.

The account-specific Team ID/bundle ID have not been supplied and are not guessed in this repo. Do not ask for passwords or private signing keys. Use the locally configured Xcode account if available. Official workflow: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html

Record device model, iOS version, cold-start time, sustained frame times/thermal behavior, memory after repeated retries/country transitions, actual notch/home-indicator clearance, one-handed tap comfort, focus interruptions, audio/mute behavior, and haptics. Target 60 FPS remains unverified. Automated desktop portrait tests are not an iPhone acceptance PASS.

Pay special attention to **Hard's 20-row / 2-second preview**: it fits on screen, but both readability and difficulty need real human testing. The orthographic overview prioritizes seeing the whole route; the reference images have more cinematic perspective and larger characters. Tune camera/layout with actual playtesting before investing in production art.

### 2. Finish the gameplay/product polish gaps

- Replace procedural placeholder character/environments with optimized original assets and proper animation. Current art deliberately differs substantially from the supplied references.
- Add polished stamp/travel/celebration transitions and region rewards once the geographic data supports them. Country switching is currently direct, without the proposed map/airplane sequence.
- Expand the five-node demo graph to a curated regional graph only when validation supports expansion. The current graph permits prototype-only jumps such as US → France; it is not a complete geographic model.
- Decide whether Infinite's section-by-section preview is the desired final memory loop. It is currently documented and deterministic; do not silently change seeded challenge semantics.
- Active-run resumption after process termination is **not implemented**. Preferences, stamps, history, and best completed/ended-run scores persist; partially completed active journeys restart. The spec makes active route persistence conditional.
- Add verified Kids facts/stickers, an appropriate character, and any parental controls actually required by the release plan. No country facts are currently shown, so none have been represented as verified.
- The tutorial is offered prominently but is optional; World Tour can go straight to country selection. Decide whether to enforce first-run tutorial order after playtesting.
- Split `scripts/game/game.gd` further if adding network/ads/replay logic; keep those concerns out of the tile and scenery modules.

### 3. Implement Convex and authoritative competitive play

No `convex/` directory, deployment, environment variables, authenticated network client, or verified leaderboards exist. Load the Convex-specific coding skill before editing Convex code if that skill is available to you.

Use the spec's player/run/daily/leaderboard/challenge/purchase models. A suitable Godot boundary is an `HTTPRequest` client to narrow HTTP endpoints backed by Convex functions. Preserve offline play.

- Establish anonymous server sessions safely. The local profile UUID is an identifier, **not authentication**; never trust an arbitrary claimed UUID for account ownership.
- Publish canonical daily manifests with UTC date, difficulty, starting country, fixed route, seed, generator version, and immutable balance version.
- Add a bounded run-event recorder appropriate for deterministic replay verification. The existing 500-event diagnostic log is **not** a complete replay proof and is not secure.
- Validate next-row order, safe lane, path/route, timing, difficulty, session ownership, continue count, and score before adding ranked entries. Separate all difficulty/mode/date boards. Never publish the local best dictionary as verified rankings.
- Port the generator with integer-safe modular arithmetic. JavaScript `Number` multiplication cannot safely reproduce all 31-bit modular products: use `BigInt` or an equivalent exact algorithm. Preserve the golden fixtures.
- Sync passport/history/preferences with a documented conflict policy. Account recovery/Better Auth remains later work.
- The existing `generator_version = 1` and difficulty keys are used by saved challenge codes. Freeze v1 presets or introduce an explicit balance version with backwards-compatible loading before changing old challenge rules.

### 4. Add real mobile integrations

- M11: rewarded/interstitial provider, verified reward callback, legitimate checkpoint continuation, configurable frequency, unavailable-ad fallback. **No ad code, provider IDs, fake rewards, or interstitial scaffolding exists.**
- M12: `remove_ads_forever` in-app product, platform transaction verification, restoration, and entitlement sync. **No purchases or local premium flags exist.**
- M15: hosted challenge IDs/URLs, universal links/app links, platform opening behavior, and share conversion tracking. Current manual PR1 code entry is a local substitute.
- M16: native share sheet for the code/link and PNG. On desktop the PNG can be opened via Settings → Open user data folder. On iPhone it is saved in the app sandbox but is not yet exported to Photos or a share sheet. Fix that before calling mobile sharing complete.
- M17: consent/age-appropriate remote analytics, acquisition/retention and revenue funnels, retry/session/route reports, then validation with real players. The local report cannot establish D1 retention or ad/share conversion.

Do not add fake leaderboard entries, simulated purchases, or buttons that imply live services are available. The current UI explicitly calls scores local.

## Project map

| Path | Responsibility |
| --- | --- |
| `project.godot`, `scenes/game.tscn` | Portrait configuration and root scene |
| `scripts/game/game.gd` | Mode orchestration, input, camera, tween lifecycle, completion/failure |
| `scripts/core/run_state.gd` | Per-path phase validation and row progression |
| `scripts/core/path_generator.gd` | Version 1 finite and constant-memory random-access generation |
| `resources/*.tres` | Difficulty presets |
| `scripts/core/game_catalog.gd` | Country metadata, difficulty lookup, daily seed/derived country seeds |
| `scripts/core/route_planner.gd` | Temporary graph traversal and long-haul options |
| `scripts/core/journey_session.gd` | World/Daily/challenge identity, route, total tiles |
| `scripts/core/player_profile.gd` | Save validation, backup/recovery, preferences, stamps, records |
| `scripts/core/challenge_code.gd` | PR1 payload codec and strict local validation |
| `scripts/core/local_telemetry.gd` | Bounded local diagnostic events |
| `scripts/game/tile*.gd`, `traveler.gd` | Tile windows, states, original placeholder character |
| `scripts/game/test_environment.gd` | Temporary country geometry; no progression logic |
| `scripts/game/audio_manager.gd` | Original synthesized music/cues and volume/focus handling |
| `scripts/ui/menu_ui.gd`, `game_hud.gd` | Menu/onboarding/passport/settings and gameplay/results UI |
| `scripts/ui/share_card.gd` | Local PNG generation through a SubViewport |
| `tests/`, `tools/check.sh` | Automated acceptance/regression checks |
| `artifacts/` | Rendered QA evidence, not runtime assets |

## Tests and observed results

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh
```

The script imports the project first so a fresh checkout has Godot's global-class cache. It then runs:

1. `test_core.gd`: 1,143 checks for the original path/phase/input invariants.
2. `test_scene.gd`: 149 checks through native touch dispatch, complete/fail/retry, preview bounds, and 30 resets.
3. `test_progression.gd`: 3,487 checks, including random-access/finite parity over 1,000 rows per lane count; route completeness from all homes; save recovery; separate records; challenge rejection; daily identity; and telemetry bounds.
4. `test_modes.gd`: at least 346 checks (some depend on the number of generated destination options) for the five-country tour, persistent stamps, every difficulty, Infinite section streaming/retry, daily retry identity, Kids, tutorial, and accessibility.

All four suites passed headlessly after the expanded implementation. Rendered mode flows passed at **480×900, 390×844, and 375×667**. The final 480×900 rendered run also validated share-card PNG dimensions and exited without resource errors. The only remaining message in that run was that the Xvfb driver cannot set VSync.

To reproduce screenshots on a Mac or another desktop with a display:

```sh
/path/to/godot --path . --script tests/test_modes.gd
/path/to/godot --path . --script tests/test_modes.gd -- --size=390x844
/path/to/godot --path . --script tests/test_modes.gd -- --size=375x667
```

The tests use distinct test save files; they do not reset the player's `profile.json`. Their helpers accelerate jumps/previews for long scenario coverage. They verify state and interaction mechanics, not whether the default timing is enjoyable.

Audio playback is disabled in headless tests. Rendered tests exercise audio lifecycle using a dummy audio driver; listening quality still needs human verification.

Useful screenshots: `10-main-menu.png`, `12-france-preview.png`, `difficulty-hard.png`, `15-passport.png`, `20-kids-stamp-375x667.png`, `22-share-card.png`.

## Runtime data and compatibility details

Godot `user://` contains `profile.json`, `.bak`, `profile.json.events`, and `passport-run-share.png` after sharing. On macOS, use Godot's **Project → Open User Data Folder**, or the in-game desktop Settings action. No sensitive credentials are stored.

Profile schema is v1. Do not change it without a migration and corrupt/older-save tests. Local challenge codes have no signature and are intentionally untrusted. Daily seed identity is stable across devices only when their UTC dates and generator/balance versions agree; offline users can manipulate their clock. Online ranking must resolve this on the server.

The path generator normalizes the seed as `seed % (2147483647 - 1) + 1`, then applies `state = state * 48271 % 2147483647` and `lane = state % lanes`. Row indexes and lanes are zero-based internally. Seed `817294`, three lanes, first ten rows: `[2, 2, 2, 2, 0, 0, 2, 1, 2, 0]`.

In Infinite, only the current preview section plus the standing row is instantiated; the v1 random-access generator computes future safe lanes without retaining an unbounded array. Frame/memory profiling on an actual iPhone is still required.

## Environment and transfer notes

There was no Git repository configured in the workspace; no commits, pushes, deployments, messages to other people, or live-service mutations were performed. The source and docs are the deliverable.

Linux validation used a temporary runtime at `/tmp/passport-tools/Godot_v4.5.2-stable_linux.x86_64`, Xvfb, and two display libraries unpacked under `/tmp/passport-tools/libs`. These are not project dependencies and will not transfer to a Mac. Install Godot normally there.

The shell sandbox in this environment failed before execution with `mountinfo path is not absolute`; read/write/test shell commands used reviewed escalation. This is an environment issue, not a requirement to run Godot unsandboxed on the next machine.

Keep `spec.md`, the two original reference images, source `.gd` files, `.uid` files, `.tres`, `.tscn`, and documentation. `.godot/` is generated and should not be transferred. `artifacts/` is optional QA evidence. No secrets or signing material are needed in the project archive.
