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

func wait_for_landing() -> void:
	for frame in 120:
		await process_frame
		if game.paused:
			game.resume_game()
		if game.run.phase != RunState.Phase.JUMPING:
			return

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
	if game.paused:
		game.resume_game()
	if game.run.phase == RunState.Phase.READY:
		game.start_preview()
	game.preview_remaining = 0.001
	for frame in 120:
		await process_frame
		if game.paused:
			game.resume_game()
		if game.run.phase != RunState.Phase.PREVIEW:
			break
	expect(game.run.phase == RunState.Phase.PLAY, "Preview finishes before selecting tiles (paused=%s)" % game.paused)

func cross_country() -> void:
	game.config.jump_seconds = 0.005
	await finish_preview()
	for row in game.config.row_count:
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Accept next safe tile")
		await wait_for_landing()
	var celebration_deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < celebration_deadline:
		await process_frame
		if game.paused:
			game.resume_game()
		if not game.celebrating:
			break
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
	# Search makes the expanded picker usable on phone-sized screens.
	game.menu.content.get_child(2).text = "France"
	game.menu.content.get_child(2).text_changed.emit("France")
	await wait()
	for control in game.menu.content.get_children():
		if control is Button and control.text.begins_with("FR "):
			tap(control.get_global_rect().get_center())
			break
	await wait()
	for key in ["easy", "moderate", "hard", "kids"]:
		expect(GameCatalog.difficulty(key).preview_seconds == 3, "All new modes memorize for three seconds")
		expect(GameCatalog.difficulty(key, 2).preview_seconds == {"easy": 5, "moderate": 3, "hard": 2, "kids": 8}[key], "Legacy previews remain compatible")
	expect(game.session.mode == "world" and game.session.current_country() == "FR", "Touch selecting France starts World Tour")
	game.start_preview()
	await wait()
	await capture("12-france-preview")
	await cross_country()
	expect(game.profile.discoveries == ["FR"] and game.session.banked_tiles == 10, "Completion stamps and banks exact score")
	await capture("13-country-complete")
	var tour_seed: int = game.session.seed_value
	var seen: Array[String] = ["FR"]
	while seen.size() < 5 and not game.session.choices().is_empty():
		var destination: String = game.session.choices()[0]
		game.travel_to(destination)
		expect(game.travel.active, "Country choice opens a skippable travel sequence")
		game.travel.finish()
		seen.append(destination)
		await wait()
		await capture("country-" + destination)
		await cross_country()
	expect(game.session.completed_countries == 5 and game.session.banked_tiles == 50, "Five-country sample banks completion")
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
	var book: PassportPage = game.menu.content.get_children().filter(func(child): return child is PassportPage)[0]
	expect(book.destination_id == game.profile.discoveries[0] and book.page_number == 1, "Passport opens a completed destination with art and stamp")
	var page_controls: HBoxContainer = game.menu.content.get_children().filter(func(child): return child is HBoxContainer)[0]
	page_controls.get_child(1).pressed.emit()
	expect(book.destination_id == game.profile.discoveries[1] and book.page_number == 2, "Passport turns to the next completed destination")
	page_controls.get_child(0).pressed.emit()
	expect(book.destination_id == game.profile.discoveries[0], "Passport turns back")
	var passport_search: LineEdit = game.menu.content.get_children().filter(func(child): return child is LineEdit)[0]
	passport_search.text_changed.emit("France")
	expect(book.visible and book.destination_id == "FR", "Passport search finds a stamped illustrated page")
	passport_search.text_changed.emit("not-a-destination")
	expect(not book.visible, "Passport search never creates unearned stamps")
	passport_search.text_changed.emit("")
	expect(book.visible and book.destination_id == game.profile.discoveries[0], "Clearing search restores passport pages")
	await wait()
	await capture("15-passport")
	game.menu.show_world_map()
	await wait()
	var map: PassportWorldMap = game.menu.content.get_children().filter(func(child): return child is PassportWorldMap)[0]
	expect(map.discoveries == game.profile.discoveries, "World map uses the saved passport")
	for id in game.profile.discoveries:
		expect(PassportWorldMap.GEOGRAPHY.pins.has(id), "Cleared country has real map coordinates")
	if render:
		expect(map.pins.size() == 5, "Map draws a pin for every cleared country")
	await capture("34-world-map")

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
	expect(game.session.current_country().is_empty() and game.hud.destination.text == "INFINITE MEMORY", "Infinite has no country or city label")
	expect(game.environment.get_node("Scenery/Backdrop").texture == TestEnvironment.INFINITE_BACKDROP, "Infinite uses its own scenery")
	var seed_value: int = game.run.path_seed
	game.config.jump_seconds = 0.005
	await finish_preview()
	for row in 34:
		if game.run.phase == RunState.Phase.PREVIEW:
			await finish_preview()
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Infinite accepts streamed row")
		await wait_for_landing()
		expect(game.grid.tiles.size() <= 33, "Infinite resident tile bound")
	expect(game.run.completed_rows == 34 and game.run.path.size() == 10, "Infinite progression avoids growing path arrays")
	expect(game.environment.get_node("Scenery/Backdrop").texture == TestEnvironment.INFINITE_BACKDROP and game.session.current_country().is_empty(), "Infinite keeps its own scenery across chunks")
	await capture("18-infinite")
	game.choose_tile(34, (game.run.safe_lane(34) + 1) % 3)
	await wait(1.2)
	expect(game.run.phase == RunState.Phase.FAILED, "Infinite failure reaches results")
	game.restart(false, true)
	expect(game.run.path_seed == seed_value and game.run.completed_rows == 0, "Infinite retry restarts same route from zero")
	expect(game.profile.records.get("infinite:easy", 0) == 34, "Infinite best saved independently")
	var earned_stamps: Array[String] = game.profile.discoveries.duplicate()
	# Replay fixture: keep the ranked daily manifest intact after its countries are reached.
	game.profile.discoveries.assign(GameCatalog.COUNTRIES.keys())
	game.start_game("daily", "hard")
	var daily_seed: int = game.session.seed_value
	var daily_route: Array = game.session.fixed_route.duplicate()
	game.restart(true, false)
	expect(game.session.seed_value == daily_seed and game.session.fixed_route == daily_route, "Daily cannot randomize on retry")
	await capture("19-daily")
	game.profile.discoveries.assign(earned_stamps)
	game.start_game("kids", "hard")
	expect(game.session.current_country() not in earned_stamps, "Kids journey continues at an uncleared country")
	expect(game.config.lane_count == 3 and game.config.row_count == 6 and game.config.preview_seconds == 3, "Kids overrides competitive difficulty")
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
	earned_stamps = game.profile.discoveries.duplicate()
	game.profile.discoveries.assign(GameCatalog.COUNTRIES.keys())
	game.start_game("challenge", "moderate")
	expect(game.session.current_country() == "JP" and game.run.path_seed == 99 and game.session.target == 20, "Imported challenge overrides home, seed, and target")
	game.profile.discoveries.assign(earned_stamps)
	game.return_to_menu()
	var reloaded := PlayerProfile.new(game.save_path)
	expect(reloaded.discoveries.size() == 6 and reloaded.discoveries == game.profile.discoveries and reloaded.records.has("world:easy"), "End-to-end progress survives a fresh profile instance")
	print("Mode checks: ", checks, "; failures: ", failures)
	game.queue_free()
	await wait(0.25)
	quit(1 if failures else 0)
