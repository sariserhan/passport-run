class_name Autoplay
extends Node

# Device soak test. Runs only when user://autoplay.json exists, e.g. {"minutes": 12}.
# Game swaps to an isolated save first, so the player's passport is never touched.
# Alternates memory World Tour and Balloon Tour; PerfLog records the frame data.
const TRIGGER := "user://autoplay.json"
const SAVE := "user://autoplay-profile.json"

var game: Node
var minutes := 12.0
var cycle := 3.0
var elapsed := 0.0
var think := 0.0
var stuck := 0.0
var last_state := ""
var rng := RandomNumberGenerator.new()

static func requested() -> bool:
	return FileAccess.file_exists(TRIGGER)

func _init(owner_game: Node) -> void:
	game = owner_game
	var settings = JSON.parse_string(FileAccess.get_file_as_string(TRIGGER))
	if settings is Dictionary:
		minutes = clampf(float(settings.get("minutes", minutes)), 1, 60)
		cycle = clampf(float(settings.get("cycle", cycle)), 0.5, 30)
	rng.seed = 7

func _ready() -> void:
	game.profile.home_country = "FR"
	game.profile.tutorial_done = true
	game.profile.settings.music = 0.0
	game.audio.apply_settings(game.profile.settings)

func _process(delta: float) -> void:
	elapsed += delta
	think -= delta
	if elapsed >= minutes * 60:
		DirAccess.remove_absolute(TRIGGER)
		print("AUTOPLAY_DONE")
		game.get_tree().quit()
		return
	if is_instance_valid(game.arcade):
		play_arcade(delta)
	else:
		play_memory()
	var state := "%s/%d/%s" % [game.run.phase, game.run.completed_rows, game.arcade.phase if is_instance_valid(game.arcade) else -1]
	stuck = 0.0 if state != last_state else stuck + delta
	last_state = state
	if stuck > 25: # an unexpected screen; start over rather than wedge the soak
		stuck = 0.0
		if is_instance_valid(game.arcade): game.close_arcade()
		game.return_to_menu()

func memory_turn() -> bool:
	return fmod(elapsed / 60.0, cycle * 2) < cycle

func play_memory() -> void:
	if think > 0: return
	think = rng.randf_range(0.6, 1.4)
	if game.menu.root.visible:
		if memory_turn(): game.start_game("world", "moderate")
		else: game.start_arcade("world")
		return
	if game.paused: game.resume_game()
	if game.run.phase == RunState.Phase.READY and not game.hud.modal_actions.is_visible_in_tree():
		game.start_preview()
		return
	if game.run.phase == RunState.Phase.PLAY:
		var row: int = game.run.completed_rows
		var lane: int = game.run.safe_lane(row)
		if rng.randf() < 0.08: lane = (lane + 1) % game.config.lane_count
		game.choose_tile(row, lane)
		return
	press_focused(game.hud.modal_actions)
	if not memory_turn() and game.hud.modal_actions.is_visible_in_tree(): game.return_to_menu()

func play_arcade(delta: float) -> void:
	var arcade: BalloonArcade = game.arcade
	if arcade.phase == BalloonArcade.Phase.PLAY:
		var target := arcade.player_x
		var nearest := INF
		for ball in arcade.balls:
			if absf(ball.position.x - arcade.player_x) < nearest:
				nearest = absf(ball.position.x - arcade.player_x)
				target = ball.position.x
		arcade.set_control("◀", target < arcade.player_x - 12)
		arcade.set_control("▶", target > arcade.player_x + 12)
		arcade.set_control("FIRE ↑", nearest < 40)
		return
	if think > 0: return
	think = 1.0
	if arcade.phase == BalloonArcade.Phase.FAILED and arcade.quick_retry.visible:
		arcade.retry_round()
	elif memory_turn():
		game.close_arcade()
	else:
		var buttons := arcade.panel.find_children("*", "Button", true, false)
		if arcade.panel.visible and not buttons.is_empty(): buttons[0].pressed.emit()

func press_focused(container: Control) -> void:
	if not container.is_visible_in_tree() or container.get_child_count() == 0: return
	var button := container.get_child(0) as Button
	if button and not button.disabled: button.pressed.emit()
