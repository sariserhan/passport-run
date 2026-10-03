extends SceneTree

var failures := 0
func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	for frame in 8: await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/landscape-" + name + ".png")

func run() -> void:
	expect(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_SENSOR, "Phone supports portrait and landscape rotation")
	var game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://landscape-check.json"
	root.add_child(game)
	await settle()
	game.profile.settings.reduced_motion = true
	game.profile.home_country = "AF"
	game.profile.settings.music = 0.0
	game.audio.apply_settings(game.profile.settings)
	for physical in [Vector2i(844,390), Vector2i(667,375), Vector2i(390,844)]:
		root.size = physical
		await settle()
		expect(root.get_visible_rect().size.y >= 480, "Scaling preserves touch target size")
		game.return_to_menu()
		await capture("menu-%dx%d" % [physical.x, physical.y])
		game.start_game("world", "hard")
		await settle()
		expect(not game.menu.root.visible, "Memory run is active during layout checks")
		game.set_overview()
		var screen := root.get_visible_rect().size
		var top := 155.0 if screen.x > screen.y else 200.0
		var bottom := screen.y - (140.0 if screen.x > screen.y else 170.0)
		for row in [0, game.config.row_count - 1]:
			for lane in [0, game.config.lane_count - 1]:
				var point: Vector2 = game.camera.unproject_position(game.grid.position_for(row,lane))
				expect(point.y > top and point.y < bottom, "Preview tiles fit between landscape HUD and controls")
		await capture("preview-%dx%d" % [physical.x, physical.y])
		game.start_preview()
		game.preview_remaining = 0
		game._process(0)
		game.follow_player()
		await settle()
		await capture("play-%dx%d" % [physical.x, physical.y])
	game.return_to_menu()
	game.start_arcade("world")
	game.arcade.begin_round()
	game.arcade.set_physics_process(false)
	game.arcade.collect("sticky")
	game.arcade.fire()
	var points: int = game.arcade.score
	for physical in [Vector2i(844,390), Vector2i(390,844), Vector2i(667,375)]:
		root.size = physical
		await settle()
		expect(game.arcade.score == points and game.arcade.weapon == "sticky", "Rotation preserves current round and weapon")
		expect(game.arcade.world_height > 300 and game.arcade.controls.get_global_rect().end.y < game.arcade.size.y, "Arcade arena and touch controls fit")
		await capture("arcade-%dx%d" % [physical.x, physical.y])
	game.queue_free()
	await settle()
	print("Landscape checks; failures: ", failures)
	quit(1 if failures else 0)
