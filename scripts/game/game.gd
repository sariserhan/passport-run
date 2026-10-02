extends Node3D

@export var save_path: String = "user://profile.json"
@export var backend_session_path: String = "user://online-session.json"
var config: DifficultyConfig
var run := RunState.new()
var session := JourneySession.new()
var profile: PlayerProfile
var telemetry: LocalTelemetry
var grid: TileGrid
var traveler: Traveler
var camera: Camera3D
var environment: TestEnvironment
var hud: GameHUD
var menu: MenuUI
var audio: GameAudio
var preview_remaining: float = 0.0
var active_tween: Tween
var camera_tween: Tween
var generation: int = 0
var paused: bool = false
var segment_start: int = 0
var country_awarded: bool = false
var imported_challenge: Dictionary = {}
var sharing: bool = false
var travel: TravelTransition
var backend: BackendClient
var replay := ReplayRecorder.new()
var online := false
var network_busy := false
var retry_run_id := ""

func _ready() -> void:
	config = GameCatalog.difficulty("easy")
	profile = PlayerProfile.new(save_path)
	telemetry = LocalTelemetry.new(save_path + ".events")
	telemetry.track("session_started")
	audio = GameAudio.new()
	add_child(audio)
	audio.apply_settings(profile.settings)
	grid = TileGrid.new()
	grid.name = "TileGrid"
	add_child(grid)
	camera = Camera3D.new()
	camera.name = "CameraRig"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 400
	add_child(camera)
	camera.make_current()
	hud = GameHUD.new()
	hud.name = "UI"
	add_child(hud)
	menu = MenuUI.new()
	add_child(menu)
	backend = BackendClient.new()
	add_child(backend)
	backend.session_path = backend_session_path
	backend.setup(str(ProjectSettings.get_setting("network/backend_url", "")))
	menu.online_available = backend.configured()
	menu.online_records_requested.connect(show_online_records)
	menu.home_country_selected.connect(func(id: String): telemetry.track("home_country_selected", {"country": id}))
	menu.difficulty_selected.connect(func(key: String): telemetry.track("difficulty_selected", {"difficulty": key}))
	menu.setup(profile, hud)
	travel = TravelTransition.new()
	add_child(travel)
	travel.setup(hud)
	travel.arrived.connect(func(): load_country(true))
	menu.start_requested.connect(start_game)
	menu.challenge_requested.connect(func(data: Dictionary): imported_challenge = data; start_game("challenge", data.difficulty))
	menu.settings_changed.connect(func(): audio.apply_settings(profile.settings))
	hud.start_requested.connect(start_preview)
	hud.retry_requested.connect(func(): restart(false, true))
	hud.new_path_requested.connect(func(): restart(true, true))
	hud.pause_requested.connect(pause_game)
	hud.resume_requested.connect(resume_game)
	hud.menu_requested.connect(return_to_menu)
	restart(true, false)
	menu.show_main()
	get_viewport().size_changed.connect(func():
		if run.phase in [RunState.Phase.READY, RunState.Phase.PREVIEW]:
			set_overview()
		else:
			follow_player()
	)

func start_game(mode: String, difficulty_key: String) -> void:
	if network_busy:
		return
	var requested_online := mode.begins_with("online_")
	mode = mode.trim_prefix("online_") if requested_online else mode
	var issued: Dictionary = {}
	if requested_online:
		if mode not in ["daily", "infinite"]:
			return
		network_busy = true
		cancel_motion()
		menu.root.hide()
		hud.show_journey_result("Preparing your run…", "Connecting to the score server.", [{"text": "BACK TO OFFLINE PLAY", "callback": return_to_menu}])
		var token := generation
		issued = await backend.begin_run(mode, difficulty_key, retry_run_id)
		if token != generation:
			return
		if issued.is_empty():
			return_to_menu()
			menu.copy(backend.last_error if not backend.last_error.is_empty() else "Online run unavailable. Offline play is ready.")
			return
		await sync_online_passport()
		if token != generation:
			return
		network_busy = false
	online = requested_online
	if mode not in ["world", "infinite", "daily", "kids", "tutorial", "challenge"]:
		return
	if mode in ["world", "kids"] and profile.home_country.is_empty():
		menu.pending_mode = mode
		menu.show_countries()
		return
	if mode == "challenge" and imported_challenge.is_empty():
		return
	session.begin(mode, difficulty_key, profile.home_country, randi_range(1, PathGenerator.MODULUS - 2), imported_challenge)
	if online:
		session.seed_value = int(issued.seed)
		session.date = issued.date
		session.fixed_route.assign(issued.route)
		replay.begin(issued.runId)
	else:
		replay.begin("")
	retry_run_id = ""
	config = GameCatalog.difficulty(session.difficulty)
	if mode == "tutorial":
		config = GameCatalog.difficulty("easy")
		config.row_count = 3
		config.preview_seconds = 5
	load_country(false)
	telemetry.track("run_started", metadata())
	if mode in ["tutorial", "infinite", "daily", "kids"]:
		telemetry.track(mode + "_started", metadata())

func cancel_motion() -> void:
	if travel:
		travel.cancel()
	generation += 1
	paused = false
	for tween in [active_tween, camera_tween]:
		if tween and tween.is_valid():
			tween.kill()
	audio.set_paused(false)

func restart(new_path: bool = false, auto_preview: bool = true) -> void:
	if online:
		retry_run_id = replay.run_id
		start_game("online_" + session.mode, session.difficulty)
		return
	var next_seed: int = session.seed_value
	if session.mode == "practice":
		next_seed = run.path_seed
	if new_path and session.mode not in ["daily", "challenge"]:
		next_seed = randi_range(1, PathGenerator.MODULUS - 2)
	# A daily retry stays pinned to the UTC date it started, even across midnight.
	var old_date := session.date
	var old_route: Array[String] = session.fixed_route.duplicate()
	session.begin(session.mode, session.difficulty, profile.home_country, next_seed, imported_challenge)
	if session.mode == "daily" and not old_date.is_empty():
		session.date = old_date
		session.seed_value = next_seed
		session.fixed_route = old_route
	load_country(auto_preview)
	if session.mode != "practice":
		telemetry.track("run_retried", metadata())

func load_country(auto_preview: bool) -> void:
	cancel_motion()
	menu.root.hide()
	hud.root.show()
	segment_start = 0
	country_awarded = false
	run.reset(session.path_seed(), config, session.mode == "infinite")
	grid.build(config)
	if is_instance_valid(traveler):
		remove_child(traveler)
		traveler.queue_free()
	traveler = Traveler.new()
	traveler.kids = session.mode == "kids"
	traveler.name = "Player"
	add_child(traveler)
	traveler.position = Vector3(0, 0.03, 0.6)
	rebuild_environment()
	set_overview()
	hud.show_ready(config.lane_count, config.row_count)
	hud.update_score(0, config.row_count)
	if not session.current_country().is_empty():
		hud.phase_title.text = GameCatalog.country_name(session.current_country())
		hud.phase_hint.text = ("Score to beat: %d" % session.target) if session.mode == "challenge" else "Remember the path. Reach your destination."
	if session.mode == "infinite":
		hud.phase_title.text = "Infinite Memory"
		hud.phase_hint.text = "Same path after every fall. Go a little farther."
	elif session.mode == "tutorial":
		hud.phase_title.text = "Your first three steps"
	telemetry.track("country_started", metadata())
	if auto_preview:
		start_preview()

func rebuild_environment() -> void:
	if is_instance_valid(environment):
		remove_child(environment)
		environment.queue_free()
	environment = TestEnvironment.new()
	environment.config = config
	environment.country_id = session.current_country()
	environment.endless = session.mode == "infinite"
	environment.name = "EnvironmentRoot"
	add_child(environment)
	if session.mode == "infinite":
		environment.position.z = -segment_start * config.row_spacing

func set_overview() -> void:
	var depth: float = (config.row_count + 1) * config.row_spacing
	var focus := Vector3(0, 0, -segment_start * config.row_spacing - depth / 2)
	camera.position = focus + Vector3(0, 31, 31)
	camera.look_at(focus)
	# Leave room for the HUD, fitting the entire path at every difficulty.
	camera.size = maxf(37.0, depth * 0.7072 / 0.51)

func start_preview() -> void:
	if paused or travel.active or not run.begin_preview():
		return
	preview_remaining = config.preview_seconds
	grid.reveal_run(run, segment_start, profile.settings.high_contrast)
	hud.overlay.hide()
	hud.show_preview()
	hud.update_preview(preview_remaining, config.preview_seconds)

func _process(delta: float) -> void:
	if paused or (menu and menu.root.visible):
		return
	if run.phase == RunState.Phase.PREVIEW:
		preview_remaining = maxf(0, preview_remaining - delta)
		hud.update_preview(preview_remaining, config.preview_seconds)
		if preview_remaining <= 0:
			grid.hide_path()
			run.finish_preview()
			update_play_hud()
			follow_player()

func update_play_hud() -> void:
	hud.show_play(run.completed_rows, config.row_count)
	if session.mode == "infinite":
		hud.score.text = str(run.completed_rows)
		hud.timer_label.text = "NEXT STEP · %d" % (run.completed_rows + 1)
		hud.timer_bar.value = float(run.completed_rows % config.row_count) / config.row_count
	elif session.mode != "practice" and session.mode != "tutorial":
		hud.phase_title.text = GameCatalog.country_name(session.current_country())

func _unhandled_input(event: InputEvent) -> void:
	if menu.root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()
		return
	if paused or run.phase != RunState.Phase.PLAY:
		return
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	else:
		return
	var origin := camera.project_ray_origin(point)
	var end := origin + camera.project_ray_normal(point) * 350
	var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.collider is PathTile:
		var tile: PathTile = result.collider
		choose_tile(tile.row, tile.lane)

func choose_tile(row: int, lane: int) -> bool:
	if paused or travel.active or not run.select(row, lane, config.lane_count):
		return false
	replay.select(0 if session.mode == "infinite" else session.country_index, row, lane)
	telemetry.track("tile_selected", {"row": row, "lane": lane, "mode": session.mode})
	audio.play_cue("jump")
	var start := traveler.position
	var destination := grid.position_for(row, lane) + Vector3(0, 0.03, 0)
	var token: int = generation
	active_tween = create_tween()
	active_tween.tween_method(func(progress: float):
		var height: float = 0.15 if profile.settings.reduced_motion else config.jump_height
		traveler.position = start.lerp(destination, progress) + Vector3.UP * sin(progress * PI) * height
		if not profile.settings.reduced_motion:
			traveler.pose_jump(progress)
	, 0.0, 1.0, config.jump_seconds)
	active_tween.tween_callback(func():
		if token == generation:
			land(row, lane)
	)
	return true

func land(row: int, lane: int) -> void:
	var tile := grid.tile_at(row, lane)
	if run.land():
		tile.set_state(PathTile.State.CORRECT)
		audio.play_cue("land")
		vibrate(15)
		update_play_hud()
		if run.phase == RunState.Phase.COMPLETE:
			celebrate()
		elif session.mode == "infinite" and run.completed_rows % config.row_count == 0:
			next_infinite_segment()
		else:
			follow_player()
	else:
		fall(tile)

func next_infinite_segment() -> void:
	segment_start = run.completed_rows
	grid.build(config, segment_start - 1, config.row_count + 1)
	grid.tile_at(segment_start - 1, run.selected_lane).set_state(PathTile.State.CORRECT)
	# Rebase scenery per chunk; the path seed never changes with the environment.
	session.country_index = int(run.completed_rows / 50)
	rebuild_environment()
	set_overview()
	run.phase = RunState.Phase.READY
	start_preview()

func follow_player() -> void:
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	var focus := Vector3(0, 0, traveler.position.z - 6.5)
	var camera_position := focus + Vector3(0, 18, 17)
	var size: float = maxf(23.5, (config.lane_count * config.lane_spacing + 2) / (get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y))
	if profile.settings.reduced_motion:
		camera.position = camera_position
		camera.size = size
		camera.rotation = Vector3(-atan2(18.0, 17.0), 0, 0)
		return
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "position", camera_position, 0.5)
	camera_tween.tween_property(camera, "size", size, 0.5)
	camera_tween.tween_property(camera, "rotation", Vector3(-atan2(18.0, 17.0), 0, 0), 0.5)

func fall(tile: PathTile) -> void:
	hud.show_falling()
	if session.mode == "kids":
		hud.phase_title.text = "Almost!"
		hud.phase_hint.text = "Great try. Remember it and go again."
	tile.set_state(PathTile.State.CRACKING)
	audio.play_cue("fall")
	vibrate(55)
	telemetry.track("wrong_tile", metadata())
	var token: int = generation
	var start := traveler.position
	var tile_start := tile.position
	active_tween = create_tween()
	if profile.settings.reduced_motion:
		active_tween.tween_interval(config.crack_seconds)
	else:
		active_tween.tween_property(tile, "rotation:z", 0.055, config.crack_seconds / 2)
		active_tween.tween_property(tile, "rotation:z", -0.045, config.crack_seconds / 2)
	active_tween.tween_callback(func(): tile.set_state(PathTile.State.FALLING))
	active_tween.tween_method(func(progress: float):
		if not profile.settings.reduced_motion:
			traveler.position = start + Vector3(0, -9 * progress * progress, 0)
			traveler.pose_fall(progress)
			tile.position = tile_start + Vector3(0.5 * progress, -11 * progress * progress, 0)
			tile.rotation.z = progress * 0.65
	, 0.0, 1.0, config.fall_seconds)
	active_tween.tween_callback(func():
		if token == generation:
			run.phase = RunState.Phase.FAILED
			save_record()
			telemetry.track("run_failed", metadata())
			telemetry.flush()
			show_failure()
			if online:
				submit_online()
	)

func show_failure() -> void:
	if session.mode == "practice":
		hud.show_result(false, run.completed_rows, config.row_count)
		return
	var body := "%d tiles · %d countries\nSame path. Another chance." % [total_score(), session.completed_countries]
	if session.mode == "infinite":
		body = "%d tiles remembered\nRetry starts at step 1\nwith the exact same path." % run.completed_rows
	if session.mode == "tutorial":
		body = "Remember the checkmarks,\nthen tap the next row."
	var actions: Array = [{"text": "TRY AGAIN", "primary": true, "callback": func(): restart(false, true)}]
	if session.mode == "infinite":
		actions.append({"text": "NEW PATH", "callback": func(): restart(true, true)})
	elif session.mode in ["world", "daily", "challenge"]:
		actions.append({"text": "COPY CODE + SAVE CARD", "callback": share_challenge})
	actions.append({"text": "MAIN MENU", "callback": return_to_menu})
	hud.show_journey_result("Great try!", body, actions)

func celebrate() -> void:
	var token: int = generation
	var start := traveler.position
	audio.play_cue("stamp")
	active_tween = create_tween()
	active_tween.tween_method(func(progress: float):
		if not profile.settings.reduced_motion:
			traveler.position = start + Vector3.UP * sin(progress * PI) * 0.7
			traveler.pose_jump(progress)
	, 0.0, 1.0, 0.5)
	active_tween.tween_callback(func():
		if token != generation:
			return
		if session.mode == "practice":
			hud.show_result(true, run.completed_rows, config.row_count)
		elif session.mode == "tutorial":
			profile.tutorial_done = true
			profile.save()
			telemetry.track("tutorial_completed")
			hud.show_journey_result("You’ve got it!", "Remember. Jump. Explore.", [{"text": "START MY JOURNEY", "primary": true, "callback": func(): menu.pending_mode = "world"; menu.show_countries()}])
		else:
			complete_country()
	)

func complete_country() -> void:
	if country_awarded:
		return
	country_awarded = true
	session.complete_country(config.row_count)
	profile.discover(session.current_country())
	save_record()
	telemetry.track("country_completed", metadata())
	telemetry.flush()
	var options := session.choices()
	if options.size() > 1:
		telemetry.track("destination_choice_shown", metadata())
	var actions: Array = []
	for destination in options:
		var id: String = destination
		actions.append({"text": ("FLY TO " if options.size() > 1 else "CONTINUE TO ") + GameCatalog.country_name(id).to_upper(), "primary": true, "callback": func(): travel_to(id)})
	var title := "Passport stamped!"
	var body := "%s\n%d %s · %d tiles" % [GameCatalog.country_name(session.current_country()), session.completed_countries, "country" if session.completed_countries == 1 else "countries", session.banked_tiles]
	if session.mode == "kids":
		body += "\nSticker collected!\n" + CountryRewards.fact(session.current_country())
	if options.is_empty():
		telemetry.track("run_completed", metadata())
		telemetry.flush()
		title = "Journey complete!"
		body += "\nYou crossed the whole route."
		if session.mode == "challenge":
			body += "\n" + ("You beat the target!" if total_score() > session.target else "Target matched!" if total_score() == session.target else "Target: %d" % session.target)
		actions.append({"text": "PLAY AGAIN", "primary": true, "callback": func(): restart(false, true)})
	if options.size() <= 1 and session.mode != "kids":
		actions.append({"text": "COPY CODE + SAVE CARD", "callback": share_challenge})
	actions.append({"text": "MAIN MENU", "callback": return_to_menu})
	hud.show_journey_result(title, body, actions)
	if options.is_empty() and online:
		submit_online()

func travel_to(id: String) -> void:
	if travel.active or run.phase != RunState.Phase.COMPLETE or not country_awarded or id not in session.choices():
		return
	var departure := session.current_country()
	if not session.travel_to(id):
		return
	telemetry.track("destination_selected", {"country": id, "mode": session.mode})
	if id not in GameCatalog.COUNTRIES[departure].neighbors:
		telemetry.track("long_haul_selected", {"country": id, "mode": session.mode})
	audio.play_cue("travel")
	travel.begin(departure, id, profile.settings.reduced_motion)

func total_score() -> int:
	return session.banked_tiles + (0 if country_awarded else run.completed_rows)

func save_record() -> void:
	if session.mode not in ["practice", "tutorial"]:
		profile.record(session.mode, session.difficulty, total_score(), session.date)

func copy_challenge() -> void:
	var route := session.challenge_route()
	if route.is_empty():
		return
	var code := ChallengeCode.encode(session.seed_value, session.difficulty, route, total_score())
	DisplayServer.clipboard_set(code)
	hud.modal_body.text = "Challenge code copied.\nSend it to a friend to replay\nthe same route and path."
	telemetry.track("challenge_created", metadata())

func share_challenge() -> void:
	if sharing:
		return
	sharing = true
	var token := generation
	copy_challenge()
	var error: Error = await ShareCard.save_card(self, session, total_score(), hud)
	if token == generation:
		if error == OK:
			hud.modal_body.text = "Code copied. Share card saved.\nOpen the user data folder\nfrom Settings to find the PNG."
		else:
			hud.modal_body.text = "Code copied. The share image\ncould not be saved here."
	sharing = false

func metadata() -> Dictionary:
	return {"mode": session.mode, "difficulty": session.difficulty, "country": session.current_country(), "row": run.completed_rows, "score": total_score(), "countries": session.completed_countries, "seed": session.seed_value, "version": PathGenerator.VERSION}

func vibrate(milliseconds: int) -> void:
	if profile.settings.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)

func return_to_menu() -> void:
	network_busy = false
	online = false
	save_record()
	telemetry.track("run_ended", metadata())
	telemetry.flush()
	cancel_motion()
	run.phase = RunState.Phase.READY
	hud.overlay.hide()
	menu.show_main()

func pause_game() -> void:
	if paused or menu.root.visible or (run.phase in [RunState.Phase.FAILED, RunState.Phase.COMPLETE] and not travel.active):
		return
	paused = true
	travel.set_paused(true)
	for tween in [active_tween, camera_tween]:
		if tween and tween.is_valid():
			tween.pause()
	audio.set_paused(true)
	hud.show_pause()

func resume_game() -> void:
	if not paused:
		return
	paused = false
	travel.set_paused(false)
	hud.overlay.hide()
	for tween in [active_tween, camera_tween]:
		if tween and tween.is_valid():
			tween.play()
	audio.set_paused(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(menu):
			pause_game()
			profile.save()
			telemetry.flush()
			if audio:
				audio.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if is_instance_valid(audio) and not paused:
			audio.set_paused(false)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if profile:
			profile.save()
			telemetry.flush()

func submit_online() -> void:
	var submission := replay.submission()
	if submission.is_empty():
		hud.modal_body.text += "\nThis run exceeded the ranking recorder limit. Your local score is saved."
		return
	var token := generation
	if not await backend.authenticate():
		if token == generation and online:
			hud.modal_body.text += "\nScore saved locally; online verification unavailable."
		return
	var response := await backend.call_function("mutation", "runs:submit", submission)
	if token != generation or not online:
		return
	var value: Variant = response.get("value")
	if value is Dictionary and value.get("score") == total_score():
		hud.modal_body.text += "\nServer verified: %d tiles" % int(value.score)
	else:
		hud.modal_body.text += "\nScore saved locally; online verification unavailable."

func show_online_records() -> void:
	menu.clear("Online rankings", "Server-verified scores. Difficulty and mode have separate boards.")
	menu.action("BACK", true, menu.show_main)
	var token := generation
	var revision := menu.revision
	for mode in ["daily", "infinite"]:
		for key in GameCatalog.DIFFICULTIES:
			var response := await backend.call_function("query", "runs:leaderboard", {"mode": mode, "difficulty": key}, false)
			if token != generation or not menu.root.visible or revision != menu.revision:
				return
			menu.copy("%s · %s" % [mode.capitalize(), key.capitalize()], 23)
			var rows: Variant = response.get("value")
			if rows is Array and not rows.is_empty():
				for index in rows.size():
					menu.copy("%d. %s · %d tiles" % [index + 1, rows[index].displayName, int(rows[index].score)])
			else:
				menu.copy("No verified scores yet." if rows is Array else "Rankings unavailable.")

func sync_online_passport() -> void:
	var response := await backend.call_function("mutation", "players:syncPassport", {"homeCountry": profile.home_country, "discoveries": profile.discoveries})
	var value: Variant = response.get("value")
	if value is Dictionary and value.get("discoveries") is Array:
		for id in value.discoveries:
			if id is String and id in GameCatalog.COUNTRIES and id not in profile.discoveries:
				profile.discoveries.append(id)
		profile.save()
