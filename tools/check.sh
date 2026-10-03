#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
"$GODOT_BIN" --headless --path . --editor --quit
"$GODOT_BIN" --headless --path . --script tests/test_core.gd
"$GODOT_BIN" --headless --path . --script tests/test_scene.gd
"$GODOT_BIN" --headless --path . --script tests/test_progression.gd
"$GODOT_BIN" --headless --path . --script tests/test_modes.gd
"$GODOT_BIN" --headless --path . --script tests/test_mobile_ui.gd
"$GODOT_BIN" --headless --path . --script tests/test_polish.gd
"$GODOT_BIN" --headless --path . --script tests/test_animations.gd
"$GODOT_BIN" --headless --path . --script tests/test_places.gd
"$GODOT_BIN" --headless --path . --script tests/test_fun.gd
python3 tests/test_report.py
"$GODOT_BIN" --headless --path . --script tests/test_music.gd
"$GODOT_BIN" --headless --path . --script tests/test_destination_polish.gd
"$GODOT_BIN" --headless --path . --script tests/test_travel_expansion.gd
python3 tests/test_iphone_export.py
"$GODOT_BIN" --headless --path . --script tests/test_unique_artwork.gd
"$GODOT_BIN" --headless --path . --script tests/test_balloon.gd
"$GODOT_BIN" --headless --path . --script tests/test_arcade_rich.gd
"$GODOT_BIN" --headless --path . --script tests/test_landscape.gd
"$GODOT_BIN" --headless --path . --script tests/test_arcade_adventures.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_return.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_difficulty.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_walk.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_turn.gd

"$GODOT_BIN" --headless --path . --script tests/test_journey_privacy.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_continuity.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_features.gd

"$GODOT_BIN" --headless --path . --script tests/test_arcade_mastery.gd

"$GODOT_BIN" --headless --path . --script tests/test_souvenir_characters.gd

"$GODOT_BIN" --headless --path . --script tests/test_travel_rewards.gd

"$GODOT_BIN" --headless --path . --script tests/test_travel_life.gd

"$GODOT_BIN" --headless --path . --script tests/test_travel_stories.gd

"$GODOT_BIN" --headless --path . --script tests/test_travel_batch.gd

"$GODOT_BIN" --headless --path . --script tests/test_travel_extras.gd

"$GODOT_BIN" --headless --path . --script tests/test_country_retry.gd
