extends SceneTree

var game: Node3D
var checks: int = 0
var failures: int = 0
var screenshots: bool = false
var test_size := Vector2i(480, 900)
var suffix := ""

func _initialize() -> void:
	screenshots = DisplayServer.get_name() != "headless"
	create_timer(45).timeout.connect(func(): push_error("Scene test timeout"); quit(1))
	run_tests.call_deferred()

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func capture(name: String) -> void:
	if screenshots:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + name + suffix + ".png")

func tap(point: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = root.get_final_transform() * point
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = root.get_final_transform() * point
	up.pressed = false
	Input.parse_input_event(up)

func tap_tile(row: int, lane: int) -> void:
	var point: Vector2 = game.camera.unproject_position(game.grid.position_for(row, lane))
	tap(point)

func run_tests() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var parts := argument.trim_prefix("--size=").split("x")
			test_size = Vector2i(int(parts[0]), int(parts[1]))
			suffix = "-" + argument.trim_prefix("--size=")
	root.size = test_size
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://scene-test-profile.json"
	for suffix_to_delete in ["", ".bak", ".tmp", ".events"]:
		DirAccess.remove_absolute(game.save_path + suffix_to_delete)
	root.add_child(game)
	await wait(0.3)
	game.run.path_seed = 817294
	game.restart(false, false)
	await wait(0.1)
	expect(game.grid.tiles.size() == 30, "Grid has 30 tiles")
	await capture("01-ready")
	tap(game.hud.begin_button.get_global_rect().get_center())
	await process_frame
	expect(game.run.phase == RunState.Phase.PREVIEW, "Start button responds to real touch event")
	if game.run.phase != RunState.Phase.PREVIEW:
		print("Button bounds: ", game.hud.begin_button.get_global_rect(), "; viewport: ", root.size)
		quit(1)
		return
	var revealed: int = 0
	for tile in game.grid.tiles:
		if tile.state == PathTile.State.REVEALED:
			revealed += 1
	expect(revealed == 10, "Exactly one safe tile per row is revealed")
	expect(not game.choose_tile(0, 0), "Preview rejects movement")
	for tile in game.grid.tiles:
		var projected: Vector2 = game.camera.unproject_position(tile.global_position)
		expect(projected.y > 195 and projected.y < game.hud.footer_panel.get_global_rect().position.y - 10, "Every preview row fits between HUD panels")
	await capture("02-preview")
	game.pause_game()
	var remaining: float = game.preview_remaining
	await wait(0.15)
	expect(game.preview_remaining == remaining, "Pause freezes preview clock")
	await capture("03-pause")
	game.resume_game()
	game.preview_remaining = 0.03
	await wait(0.7)
	expect(game.run.phase == RunState.Phase.PLAY, "Preview ends automatically")
	for tile in game.grid.tiles:
		expect(tile.state == PathTile.State.NORMAL and not tile.marker.visible, "All tiles hide safe indicators")
	await capture("04-play")
	tap_tile(1, 0)
	await process_frame
	expect(game.run.phase == RunState.Phase.PLAY, "Future row touch is ignored")
	tap_tile(0, game.run.path[0])
	await process_frame
	expect(game.run.phase == RunState.Phase.JUMPING, "Next row touch starts jump")
	expect(not game.choose_tile(0, game.run.path[0]), "Double tap cannot queue jump")
	await wait(0.45)
	expect(game.run.completed_rows == 1, "Correct landing advances exactly once")
	await wait(0.55)
	await capture("05-landing")
	tap_tile(1, (game.run.path[1] + 1) % 3)
	await wait(0.48)
	expect(game.run.phase == RunState.Phase.FALLING, "Wrong tile triggers fall")
	await capture("06-cracking")
	await wait(0.35)
	await capture("07-falling")
	await wait(0.65)
	expect(game.run.phase == RunState.Phase.FAILED, "Fall finishes in results")
	expect(game.hud.overlay.visible, "Failure results visible")
	await capture("08-results")
	var original_path: Array = game.run.path.duplicate()
	tap(game.hud.modal_actions.get_child(0).get_global_rect().get_center())
	await process_frame
	expect(game.run.phase == RunState.Phase.PREVIEW, "Retry button starts another preview")
	expect(game.run.path == original_path, "Retry retains exact path")
	game.preview_remaining = 0.01
	await wait(0.65)
	for row in 10:
		tap_tile(row, game.run.path[row])
		await wait(0.95)
		expect(game.run.completed_rows == row + 1, "Touch path completes row " + str(row))
	expect(game.run.phase == RunState.Phase.COMPLETE, "Full path completed through touch events")
	await capture("09-complete")
	var baseline_nodes: int = game.get_tree().get_node_count()
	var baseline_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for attempt in 30:
		game.restart(false, false)
		await process_frame
		await process_frame
		expect(game.grid.get_child_count() == 30, "Restart clears old tiles")
		expect(game.run.path == original_path, "Repeated retry preserves path")
	expect(game.get_tree().get_node_count() <= baseline_nodes, "Scene node count stays bounded across 30 restarts")
	expect(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= baseline_orphans, "No orphan nodes across retries")
	# Restart during a jump must invalidate old callbacks and restore all transforms.
	game.start_preview()
	game.preview_remaining = 0.01
	await wait(0.1)
	game.choose_tile(0, game.run.path[0])
	game.restart(false, false)
	await wait(0.6)
	expect(game.run.phase == RunState.Phase.READY and game.run.completed_rows == 0, "Restart cancels in-flight movement callbacks")
	print("Scene checks: ", checks, "; failures: ", failures)
	game.queue_free()
	await wait(0.25)
	quit(1 if failures else 0)
