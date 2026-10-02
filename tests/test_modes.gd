extends SceneTree

var game: Node3D
var checks: int = 0
var failures: int = 0
var render: bool = false
var suffix: String = ""

func _initialize() -> void:
	render = DisplayServer.get_name() != "headless"
	create_timer(120).timeout.connect(func(): push_error("Mode test timeout"); quit(1))
	run_all.call_deferred()

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func wait(seconds: float = 0.08) -> void:
	await create_timer(seconds).timeout

func capture(name: String) -> void:
	if render:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + name + suffix + ".png")

func tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = root.get_final_transform() * point
		event.pressed = pressed
		Input.parse_input_event(event)

func finish_preview() -> void:
	if game.run.phase == RunState.Phase.READY:
		game.start_preview()
	game.preview_remaining = 0.001
	await wait(0.6 if render else 0.03)

func cross_country() -> void:
	game.config.jump_seconds = 0.005
	await finish_preview()
	for row in game.config.row_count:
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Accept next safe tile")
		await wait(0.02)
	await wait(0.6)
	expect(game.run.phase == RunState.Phase.COMPLETE, "Country completed")

func run_all() -> void:
	root.size = Vector2i(480, 900)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var size := argument.trim_prefix("--size=").split("x")
			root.size = Vector2i(int(size[0]), int(size[1]))
			suffix = "-" + argument.trim_prefix("--size=")
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://mode-test" + suffix + ".json"
	for ending in ["", ".bak", ".tmp", ".events"]:
		DirAccess.remove_absolute(game.save_path + ending)
	root.add_child(game)
	await wait()
	await capture("10-main-menu")
	expect(game.profile.home_country.is_empty(), "No inferred home country")
	game.menu.request_mode("world")
	expect(game.menu.pending_mode == "world", "Home selection required")
	await wait()
	await capture("11-home-country")
	# Country picker order: heading, subtitle, search, US, FR, ...
	tap(game.menu.content.get_child(4).get_global_rect().get_center())
	await wait()
	expect(game.session.mode == "world" and game.session.current_country() == "FR", "Touch selecting France starts World Tour")
	game.start_preview()
	await wait()
	await capture("12-france-preview")
	await cross_country()
	expect(game.profile.discoveries == ["FR"] and game.session.banked_tiles == 10, "Completion stamps and banks exact score")
	await capture("13-country-complete")
	var tour_seed: int = game.session.seed_value
	var seen: Array[String] = ["FR"]
	while not game.session.choices().is_empty():
		var destination: String = game.session.choices()[0]
		game.travel_to(destination)
		expect(game.travel.active, "Country choice opens a skippable travel sequence")
		game.travel.finish()
		seen.append(destination)
		await wait()
		await capture("country-" + destination)
		await cross_country()
	expect(game.session.completed_countries == 5 and game.session.banked_tiles == 50, "Whole five-country tour completes")
	expect(game.profile.discoveries.size() == 5, "Five unique stamps")
	expect(game.session.seed_value == tour_seed, "Travel does not mutate run identity")
	await capture("14-tour-complete")
	if render:
		var card_path := "user://test-share" + suffix + ".png"
		var card_error: Error = await ShareCard.save_card(game, game.session, game.total_score(), game.hud, card_path)
		expect(card_error == OK, "Share card saves a real PNG")
		var card_image := Image.load_from_file(card_path)
		expect(card_image.get_size() == Vector2i(720, 1000), "Share card export dimensions")
		card_image.save_png("res://artifacts/22-share-card" + suffix + ".png")
	game.return_to_menu()
	game.menu.show_passport()
	await wait()
	await capture("15-passport")
	game.menu.show_records()
	await wait()
	await capture("16-records")
	game.menu.show_settings()
	await wait()
	await capture("17-settings")
	for key in GameCatalog.DIFFICULTIES:
		game.start_game("world", key)
		game.start_preview()
		await wait()
		var count: int = 0
		for tile in game.grid.tiles:
			if tile.state == PathTile.State.REVEALED:
				count += 1
			var point: Vector2 = game.camera.unproject_position(tile.global_position)
			expect(point.x > 0 and point.x < game.hud.root.size.x and point.y > 195 and point.y < game.hud.footer_panel.get_global_rect().position.y, "Every difficulty fits preview")
		expect(count == game.config.row_count, "One safe tile per row for " + key)
		await capture("difficulty-" + key)
		await finish_preview()
		game.config.jump_seconds = 0.03
		tap(game.camera.unproject_position(game.grid.position_for(0, game.run.safe_lane(0))))
		await wait(0.08)
		expect(game.run.completed_rows == 1, "Touch input works for " + key)
	game.start_game("infinite", "easy")
	var seed_value: int = game.run.path_seed
	game.config.jump_seconds = 0.005
	await finish_preview()
	for row in 34:
		if game.run.phase == RunState.Phase.PREVIEW:
			await finish_preview()
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Infinite accepts streamed row")
		await wait(0.02)
		expect(game.grid.tiles.size() <= 33, "Infinite resident tile bound")
	expect(game.run.completed_rows == 34 and game.run.path.size() == 10, "Infinite progression avoids growing path arrays")
	await capture("18-infinite")
	game.choose_tile(34, (game.run.safe_lane(34) + 1) % 3)
	await wait(1.2)
	expect(game.run.phase == RunState.Phase.FAILED, "Infinite failure reaches results")
	game.restart(false, true)
	expect(game.run.path_seed == seed_value and game.run.completed_rows == 0, "Infinite retry restarts same route from zero")
	expect(game.profile.records.get("infinite:easy", 0) == 34, "Infinite best saved independently")
	game.start_game("daily", "hard")
	var daily_seed: int = game.session.seed_value
	var daily_route: Array = game.session.fixed_route.duplicate()
	game.restart(true, false)
	expect(game.session.seed_value == daily_seed and game.session.fixed_route == daily_route, "Daily cannot randomize on retry")
	await capture("19-daily")
	game.start_game("kids", "hard")
	expect(game.config.lane_count == 3 and game.config.row_count == 6 and game.config.preview_seconds == 8, "Kids overrides competitive difficulty")
	await cross_country()
	for control in game.hud.modal_actions.get_children():
		expect("CHALLENGE" not in control.text, "Kids excludes sharing actions")
	await capture("20-kids-stamp")
	game.start_game("tutorial", "easy")
	expect(game.config.row_count == 3, "Tutorial is a short interactive route")
	await cross_country()
	expect(game.profile.tutorial_done, "Tutorial completion saved")
	game.profile.settings.high_contrast = true
	game.profile.settings.reduced_motion = true
	game.start_game("world", "easy")
	game.start_preview()
	expect(game.grid.tile_at(0, game.run.safe_lane(0)).green.albedo_color == Color("f7df3b"), "High contrast setting applied")
	await capture("21-high-contrast")
	game.imported_challenge = ChallengeCode.decode(ChallengeCode.encode(99, "moderate", RoutePlanner.standardized("JP", 99), 20))
	game.start_game("challenge", "moderate")
	expect(game.session.current_country() == "JP" and game.run.path_seed == 99 and game.session.target == 20, "Imported challenge overrides home, seed, and target")
	game.return_to_menu()
	var reloaded := PlayerProfile.new(game.save_path)
	expect(reloaded.discoveries.size() == 5 and reloaded.records.has("world:easy"), "End-to-end progress survives a fresh profile instance")
	print("Mode checks: ", checks, "; failures: ", failures)
	game.queue_free()
	await wait(0.25)
	quit(1 if failures else 0)
