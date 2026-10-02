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
