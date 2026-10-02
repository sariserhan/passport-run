# Passport Run

A playable **Godot 4.5.2 / GDScript memory adventure**, built from `spec.md` and the two supplied image references. iPhone is the first mobile test target. Offline play works independently; optional competition uses the local Convex backend.

**Continuing agent: read [HANDOFF.md](HANDOFF.md) first.** It covers user decisions, everything implemented, remaining milestones, file ownership, tests, and the next work in order.

## Play

1. Install Godot 4.5.2 (standard edition).
2. Import `project.godot` and press **F5**.
3. Try **Learn the Path**, select your home country and difficulty, then start a mode.
4. Remember the checked tiles during preview. When they disappear, choose a tile in the next row within 10 seconds. Landing safely resets the clock; pauses and jumps freeze it.
5. Retry after falling to replay the same path. Infinite also offers a new path. Pause or Escape suspends the run; End Run returns to the menu.

Modes: **World Tour**, **Infinite Memory**, **Daily World Tour**, and **Kids Adventure**. The prototype has five destinations, a persistent passport/history, local records, accessibility/audio settings, manually shared challenge codes, and locally exported share cards.

![France path preview](artifacts/12-france-preview-375x667.png)

The visuals now follow the supplied references with illustrated destinations, a detailed backpacker sprite, rounded stone tiles and a perspective camera. See [visual assets and remaining animation limits](docs/visual-assets.md). Audio is original prototype audio. Thinking/jumping/falling character poses, country celebration with a passport-stamping sequence, illustrated travel, Kids stickers/facts and share cards are included. Authenticated server manifests, replay-verified rankings and passport discovery sync work against a real local Convex backend; see [backend setup](backend/README.md). Online buttons appear only when a backend URL is configured. Hosted deployment, ads, purchases, public challenge URLs, native sharing and device acceptance remain unfinished.

## Checks

```sh
GODOT_BIN=/path/to/godot ./tools/check.sh
```

On macOS:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh
```

Tests import a fresh project first, then check the core game, actual touch-event dispatch, complete/fail/retry, local saves and recovery, seed compatibility, routes, mode transitions, and bounded infinite streaming. They use separate test profiles.

Rendered QA and screenshots:

```sh
godot --path . --script tests/test_modes.gd
godot --path . --script tests/test_modes.gd -- --size=390x844
godot --path . --script tests/test_modes.gd -- --size=375x667
```

Summarize a local gameplay log:

```sh
python3 tools/summarize_events.py '/path/to/Godot/user/data/profile.json.events'
```

The report covers the last 500 local events; it is not a population retention dashboard. In-game desktop Settings can open the user data folder.

## Run on the iPhone

The user confirmed access to a Mac and physical iPhone. On the Mac:

1. Install Godot 4.5.2's matching export templates via **Editor → Manage Export Templates**.
2. Use the included **iPhone** export preset. It uses the verified local development Team ID and `com.serhansari.passportrun`; replace these for another developer account.
3. Export to an empty folder outside the source tree, using a filename such as `PassportRun` without spaces.
4. Open the exported Xcode project, configure signing, choose the connected iPhone, and build/run.
5. Check safe areas, one-handed taps, all difficulty previews, repeated retries/transitions, frame time, audio, and background/resume behavior.

No private signing credentials are committed. Godot export and unsigned Xcode compilation succeeded on this Mac. See the [official Godot iOS export instructions](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html) and [current iPhone validation status](docs/iphone-validation.md) for device/signing evidence.

## Useful files

- [Agent handoff](HANDOFF.md)
- [Milestone status and test evidence](docs/build-status.md)
- [Original specification](spec.md)
- `resources/` — difficulty tuning
- `scripts/core/` — game state, progression, save/challenge contracts
- `scripts/game/` — playable scene and temporary 3D/audio assets
- `scripts/ui/` — menu, HUD and share card
- `artifacts/` — rendered screenshots; excluded from runtime imports
