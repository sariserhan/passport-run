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
	DirAccess.remove_absolute("user://landscape-check.json.perf.csv")
	root.add_child(game)
	await settle()
	var perf: PerfLog = game.find_children("*", "PerfLog", false, false)[0]
	perf._process(PerfLog.INTERVAL)
	var perf_lines := Array(FileAccess.get_file_as_string("user://landscape-check.json.perf.csv").strip_edges().split("\n")).filter(func(line): return ",hitch@" not in line)
	expect(perf_lines.size() == 2 and perf_lines[1].split(",")[1] == "menu" and perf_lines[1].split(",").size() == 8, "Device performance log records a labelled sample")
	game.profile.settings.reduced_motion = true
	game.profile.home_country = "AF"
	game.profile.settings.music = 0.0
	game.audio.apply_settings(game.profile.settings)
	game.start_game("world", "easy")
	for attempt in 4:
		game.show_failure()
		await process_frame
	expect(game.ads.failures == 4 and game.ads.last_due, "The memory-game failure screen counts toward the every-4th ad")
	await process_frame
	expect(not game.ads.banner_wanted, "No banner during play or on the results screen")
	game.return_to_menu()
	await process_frame
	expect(game.ads.banner_wanted, "Menu screens show the bottom banner")
	game.menu.set_banner_pixels(150)
	expect(game.menu.banner_padding > 0 and game.menu.safe_margin.get_theme_constant("margin_bottom") >= 38 + game.menu.banner_padding, "The menu leaves room for the banner")
	game.menu.set_banner_pixels(0)
	game.remove_ads.unlocked = true
	await process_frame
	expect(not game.ads.banner_wanted, "Remove Ads hides the menu banner")
	game.remove_ads.unlocked = false
	for physical in [Vector2i(844,390), Vector2i(667,375), Vector2i(390,844)]:
		root.size = physical
		await settle()
		expect(root.get_visible_rect().size.y >= 480, "Scaling preserves touch target size")
		game.return_to_menu()
		await capture("menu-%dx%d" % [physical.x, physical.y])
		expect(game.menu.hero.visible == (physical.x < physical.y), "Main menu key art only takes space in portrait")
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
		if physical.x > physical.y:
			expect(game.arcade.arena().size.y > game.arcade.size.y * 0.5, "Landscape arcade header leaves most of the height to the arena")
			game.arcade.notice.text = "SWEEP BOSS · Watch the charge arrow\nLEVEL 12 · STONE\nMystery drops · Collect / avoid in Pause\nOne more line"
			await process_frame
			expect(game.arcade.notice.get_global_rect().end.y <= game.arcade.arena().position.y, "Landscape round notice stays in the header row, even when long")
		await capture("arcade-%dx%d" % [physical.x, physical.y])
	game.queue_free()
	await settle()
	print("Landscape checks; failures: ", failures)
	quit(1 if failures else 0)
