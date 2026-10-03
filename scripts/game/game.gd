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
var decision_remaining := GameCatalog.DECISION_SECONDS
var failure_reason := ""
var celebrating := false
var parcel: SouvenirParcel
var passport_stamp: PassportStamp
var purchase: RoutePurchase
var cinema_purchase: RoutePurchase
var cinema_start := "HOBBIT_VILLAGE"
var trip_id := "europe"
var jump_streak := 0
var failed_countries: Array[String] = []
var special_start := "EVEREST"
var adventure_start := "NO"
var friend_steps: Array[int] = []
var selected_decision_ms := 0
var ghost: FriendGhost
var extra_stage: TravelStage
var completed_stops: Array[String] = []
var player_slot := 0
var link_poll := 0.0
var arcade: BalloonArcade

func _ready() -> void:
	var soak := Autoplay.requested()
	if soak: save_path = Autoplay.SAVE
	config = GameCatalog.difficulty("easy")
	profile = PlayerProfile.new(save_path)
	telemetry = LocalTelemetry.new(save_path + ".events")
	telemetry.track("session_started")
	# Dev/soak instrumentation only; App Store builds skip the periodic disk writes.
	if OS.is_debug_build() or soak: add_child(PerfLog.new(save_path + ".perf.csv", func(): return "arcade" if arcade else "menu" if menu and menu.root.visible else session.mode))
	audio = GameAudio.new()
	add_child(audio)
	audio.apply_settings(profile.settings)
	grid = TileGrid.new()
	grid.name = "TileGrid"
	add_child(grid)
	camera = Camera3D.new()
	camera.name = "CameraRig"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 48.0
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
	menu.base_save_path = save_path
	menu.player_slot_requested.connect(switch_player_slot)
	menu.profile_reload_requested.connect(func(): switch_player_slot(player_slot, false))
	travel = TravelTransition.new()
	add_child(travel)
	travel.profile = profile
	travel.setup(hud)
	travel.arrived.connect(func(): load_country(true))
	parcel = SouvenirParcel.new()
	add_child(parcel)
	parcel.setup(hud)
	passport_stamp = PassportStamp.new()
	add_child(passport_stamp)
	passport_stamp.setup(hud)
	passport_stamp.stamped.connect(func(): traveler.play_animation("stamp"); audio.play_cue(profile.activities.custom.sound))
	passport_stamp.finished.connect(finish_celebration)
	purchase = RoutePurchase.new()
	add_child(purchase)
	menu.purchase = purchase
	purchase.changed.connect(menu.purchase_changed)
	purchase.changed.connect(func():
		if not has_paid_access() and not menu.root.visible:
			return_to_menu()
			menu.show_special_route()
	)
	cinema_purchase = RoutePurchase.new(RoutePurchase.CINEMA_PRODUCT_ID)
	add_child(cinema_purchase)
	menu.cinema_purchase = cinema_purchase
	cinema_purchase.changed.connect(menu.purchase_changed)
	cinema_purchase.changed.connect(func():
		if not has_paid_access() and not menu.root.visible:
			return_to_menu()
			menu.show_cinema_route()
	)
	var character_purchase := RoutePurchase.new("com.serhansari.passportrun.travelers")
	add_child(character_purchase)
	menu.character_purchase = character_purchase
	character_purchase.message = "Traveler purchases are available on iPhone. World Champion is earned by clearing the world."
	character_purchase.changed.connect(func():
		profile.character_pack_unlocked = character_purchase.unlocked
		if menu.root.visible and menu.wardrobe_page: menu.show_wardrobe()
	)
	menu.adventure_requested.connect(func(id: String): adventure_start = id; start_game("adventure", profile.difficulty))
	menu.activity_sound_requested.connect(func(key: String):
		if key.begins_with("destination:"): audio.play_destination(key.trim_prefix("destination:"))
		else: audio.play_cue(key)
	)
	menu.activity_route_requested.connect(func(data: Dictionary):
		if not valid_activity(data): return
		imported_challenge = data
		menu.active_turn = data.get("kind") == "multiplayer"
		start_game("expedition", data.get("difficulty", profile.difficulty))
	)
	menu.trip_requested.connect(func(id: String): trip_id = id; start_game("trip", profile.difficulty))
	menu.cinema_requested.connect(func(id: String): cinema_start = id; start_game("cinema", profile.difficulty))
	menu.special_requested.connect(func(id: String): special_start = id; start_game("special", profile.difficulty))
	menu.arcade_requested.connect(start_arcade)
	menu.arcade_practice_requested.connect(func(id: String): start_arcade("practice", id))
	menu.start_requested.connect(start_game)
	menu.challenge_requested.connect(func(data: Dictionary): imported_challenge = data; start_game("challenge", data.difficulty))
	menu.settings_changed.connect(apply_accessibility)
	hud.lane_requested.connect(func(lane: int): choose_tile(run.completed_rows, lane))
	apply_accessibility()
	hud.start_requested.connect(start_preview)
	hud.retry_requested.connect(func(): restart(false, true))
	hud.new_path_requested.connect(func(): restart(true, true))
	hud.pause_requested.connect(pause_game)
	hud.resume_requested.connect(resume_game)
	hud.menu_requested.connect(return_to_menu)
	restart(true, false)
	menu.show_main()
	if soak: add_child(Autoplay.new(self))
	get_viewport().size_changed.connect(func():
		if run.phase in [RunState.Phase.READY, RunState.Phase.PREVIEW]:
			set_overview()
		else:
			follow_player()
	)

func start_game(mode: String, difficulty_key: String) -> void:
	var is_retry := not retry_run_id.is_empty()
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
	friend_steps.clear()
	online = requested_online
	if mode == "adventure" and adventure_start not in GameCatalog.DESTINATIONS: return
	if mode == "special" or (mode == "adventure" and adventure_start in GameCatalog.PREMIUM_DESTINATIONS) or (mode in ["challenge", "expedition"] and imported_challenge.get("route", []).any(func(id): return id in GameCatalog.PREMIUM_DESTINATIONS)):
		if not purchase.unlocked:
			menu.show_special_route()
			return
	if mode == "cinema" or (mode == "adventure" and adventure_start in GameCatalog.CINEMA_DESTINATIONS) or (mode in ["challenge", "expedition"] and imported_challenge.get("route", []).any(func(id): return id in GameCatalog.CINEMA_DESTINATIONS)):
		if not cinema_purchase.unlocked:
			menu.show_cinema_route()
			return
	if mode not in ["world", "infinite", "daily", "kids", "tutorial", "challenge", "special", "cinema", "trip", "adventure", "expedition"]:
		return
	if mode in ["world", "kids"] and profile.home_country not in GameCatalog.FREE_DESTINATIONS:
		menu.pending_mode = mode
		menu.show_countries()
		return
	if mode == "challenge" and imported_challenge.is_empty():
		return
	if not is_retry:
		failed_countries.clear()
	completed_stops.clear()
	session.begin(mode, difficulty_key, adventure_start if mode == "adventure" else special_start if mode == "special" else (cinema_start if mode == "cinema" else profile.home_country), randi_range(1, PathGenerator.MODULUS - 2), {"route": TravelGoals.TRIPS[trip_id].route} if mode == "trip" else imported_challenge)
	if mode in ["world", "kids"]: session.resume_world(profile.discoveries)
	var requested_route: Array = issued.route if requested_online else session.fixed_route
	if mode in ["daily", "challenge", "trip", "expedition"] and not profile.can_visit_route(requested_route):
		reject_locked_destination()
		return
	if mode in ["special", "cinema", "adventure"] and not profile.can_visit(session.current_country()):
		reject_locked_destination()
		return
	if online:
		session.balance_version = int(issued.balanceVersion)
		session.seed_value = int(issued.seed)
		session.date = issued.date
		session.fixed_route.assign(issued.route)
		replay.begin(issued.runId)
	else:
		replay.begin("")
	retry_run_id = ""
	config = GameCatalog.difficulty(session.difficulty, session.balance_version)
	if mode == "tutorial":
		config = GameCatalog.difficulty("easy")
		config.row_count = 3
	load_country(false)
	if mode in ["expedition", "special", "cinema", "adventure"]:
		travel.begin("", session.current_country(), profile.settings.reduced_motion, true)
	telemetry.track("run_started", metadata())
	if mode in ["tutorial", "infinite", "daily", "kids"]:
		telemetry.track(mode + "_started", metadata())

func cancel_motion() -> void:
	if parcel: parcel.cancel()
	celebrating = false
	if passport_stamp:
		passport_stamp.cancel()
	if is_instance_valid(traveler):
		traveler.animation_paused = false
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
	# A travel retry resets the active country's tiles, never the journey's departure.
	if session.mode in ["world", "kids", "special", "cinema", "trip", "adventure", "expedition"] and run.phase != RunState.Phase.COMPLETE:
		session.seed_value = next_seed
		friend_steps.resize(mini(friend_steps.size(), session.banked_tiles))
		load_country(auto_preview)
		telemetry.track("run_retried", metadata())
		return
	completed_stops.clear()
	# A daily retry stays pinned to the UTC date it started, even across midnight.
	var old_date := session.date
	var old_route: Array[String] = session.fixed_route.duplicate()
	session.begin(session.mode, session.difficulty, adventure_start if session.mode == "adventure" else special_start if session.mode == "special" else (cinema_start if session.mode == "cinema" else profile.home_country), next_seed, {"route": TravelGoals.TRIPS[trip_id].route} if session.mode == "trip" else imported_challenge)
	if session.mode == "daily" and not old_date.is_empty():
		session.date = old_date
		session.seed_value = next_seed
		session.fixed_route = old_route
	friend_steps.clear()
	load_country(auto_preview)
	if session.mode != "practice":
		telemetry.track("run_retried", metadata())

func load_country(auto_preview: bool) -> void:
	cancel_motion()
	menu.root.hide()
	hud.root.show()
	jump_streak = 0
	hud.phase_hint.modulate = Color.WHITE
	segment_start = 0
	country_awarded = false
	failure_reason = ""
	decision_remaining = GameCatalog.DECISION_SECONDS
	config = GameCatalog.difficulty(session.difficulty, session.balance_version) if session.mode != "tutorial" else config
	var stage_data := TravelExtras.stage(imported_challenge.get("kind", ""), imported_challenge.get("key", "")) if session.mode == "expedition" else {}
	if not stage_data.is_empty(): config.row_count = int(stage_data.get("rows", 7 if imported_challenge.kind == "secret" else config.row_count))
	run.reset(session.path_seed(), config, session.mode == "infinite")
	grid.destination_id = "INFINITE" if session.mode == "infinite" else session.current_country()
	grid.layout = DestinationTheme.layout(grid.destination_id) if session.balance_version >= 3 and not grid.destination_id.is_empty() else "classic"
	if session.mode == "adventure":
		if session.current_country() in ["MOON", "SPACE", "MARS"]:
			config.jump_height = 3.0
			config.jump_seconds = 0.75
		elif session.current_country() == "UNDERWATER":
			config.jump_height = 2.0
			config.jump_seconds = 0.7
	if not stage_data.is_empty(): grid.layout = stage_data.layout
	grid.moving = session.mode == "adventure" and DestinationTheme.style(grid.destination_id) in ["jungle", "ocean"]
	if session.mode == "expedition" and imported_challenge.get("kind") == "transport": grid.moving = imported_challenge.get("key") in ["boat", "cable_car"] and not profile.settings.reduced_motion
	grid.transport_kind = imported_challenge.get("key", "") if session.mode == "expedition" and imported_challenge.get("kind") == "transport" else ""
	grid.climb_step = 0.16 if not stage_data.is_empty() and stage_data.layout == "climb" else 0.0
	grid.build(config)
	hud.configure_lanes(config.lane_count)
	if is_instance_valid(extra_stage): extra_stage.queue_free()
	extra_stage = TravelStage.new()
	extra_stage.kind = imported_challenge.get("kind", "") if session.mode == "expedition" else ""
	extra_stage.key = imported_challenge.get("key", "")
	extra_stage.rows = config.row_count
	extra_stage.reduced_motion = profile.settings.reduced_motion
	add_child(extra_stage)
	if is_instance_valid(traveler):
		remove_child(traveler)
		traveler.queue_free()
	traveler = Traveler.new()
	traveler.buddy_kind = profile.travel_buddy
	traveler.kids = session.mode == "kids"
	traveler.reduced_motion = profile.settings.reduced_motion
	passport_stamp.ink_color = Color("276e62") if profile.activities.custom.ink == "jade" else Color("285f86") if profile.activities.custom.ink == "ocean" else Color("a24c40")
	traveler.weather = profile.activities.custom.weather
	traveler.buddy_accessory = profile.activities.accessories.get(profile.travel_buddy, false)
	traveler.victory_pose = profile.activities.custom.pose
	traveler.character_id = profile.equipped_character()
	traveler.customization = profile.character_style.duplicate()
	traveler.destination_theme = DestinationTheme.style(grid.destination_id)
	traveler.name = "Player"
	add_child(traveler)
	traveler.position = Vector3(0, 0.03, 0.6)
	if is_instance_valid(ghost): ghost.queue_free()
	ghost = FriendGhost.new()
	ghost.game = self
	ghost.decisions = imported_challenge.get("ghost", []) if session.mode == "challenge" else []
	add_child(ghost)
	rebuild_environment()
	if grid.climb_step > 0: environment.finish_position.y = grid.position_for(config.row_count - 1, 0).y
	audio.play_destination("INFINITE" if session.mode == "infinite" else session.current_country())
	set_overview()
	hud.show_ready(config.lane_count, config.row_count)
	hud.destination.text = "INFINITE MEMORY" if session.mode == "infinite" else GameCatalog.country_name(session.current_country()) if not session.current_country().is_empty() else "PASSPORT RUN"
	hud.update_score(0, config.row_count)
	if not session.current_country().is_empty():
		hud.phase_title.text = GameCatalog.country_name(session.current_country())
		hud.phase_hint.text = ("Score to beat: %d" % session.target) if session.mode == "challenge" else "Remember the path. Reach your destination."
	if session.mode == "infinite":
		hud.phase_title.text = "Infinite Memory"
		hud.phase_hint.text = "Same path after every fall. Go a little farther."
	elif session.mode == "trip":
		hud.phase_hint.text = "%s · Country %d of 3" % [TravelGoals.TRIPS[trip_id].name, session.country_index + 1]
	elif session.mode == "expedition":
		hud.phase_hint.text = "%s · Stop %d / %d" % [imported_challenge.get("name", "Expedition"), session.country_index + 1, session.fixed_route.size()]
	elif session.mode == "tutorial":
		hud.phase_title.text = "Your first three steps"
	if not stage_data.is_empty():
		hud.destination.text = stage_data.name
		hud.phase_title.text = stage_data.name
		hud.phase_hint.text += " · " + ("Watch the moving platforms." if grid.moving else "Find the scenic path.")
	telemetry.track("country_started", metadata())
	if session.mode == "adventure":
		hud.phase_hint.text = adventure_hint()
	if auto_preview:
		start_preview()

func rebuild_environment() -> void:
	if is_instance_valid(environment):
		remove_child(environment)
		environment.queue_free()
	environment = TestEnvironment.new()
	environment.reduced_motion = profile.settings.reduced_motion
	environment.config = config
	environment.country_id = session.current_country()
	environment.endless = session.mode in ["infinite", "tutorial", "practice"]
	environment.name = "EnvironmentRoot"
	add_child(environment)
	environment.atmosphere.weather = profile.activities.custom.weather
	environment.atmosphere.time_of_day = profile.activities.custom.time
	environment.atmosphere.confetti_color = profile.activities.custom.confetti
	if session.mode == "infinite":
		environment.position.z = -segment_start * config.row_spacing

func set_overview() -> void:
	var depth: float = (config.row_count + 1) * config.row_spacing
	var focus := Vector3(0, 0, -segment_start * config.row_spacing - depth / 2)
	var screen := get_viewport().get_visible_rect().size
	var top := 155.0 if screen.x > screen.y else 200.0
	var bottom := screen.y - (140.0 if screen.x > screen.y else 170.0)
	var direction := Vector3(0, 0.72, 0.69).normalized()
	var distance := 18.0
	var target_y: float = (top + bottom) / 2
	# Fit the complete preview at every difficulty; play moves closer to the traveler.
	for attempt in 48:
		camera.position = focus + direction * distance
		camera.look_at(focus)
		camera.position += camera.basis.y * ((0.5 - target_y / screen.y) * 2 * distance * tan(deg_to_rad(camera.fov / 2)))
		var fits := true
		for row in [segment_start, segment_start + config.row_count - 1]:
			for lane in [0, config.lane_count - 1]:
				for offset in [Vector3(-1, 0, -1), Vector3(1, 0, 1)]:
					var point := camera.unproject_position(grid.position_for(row, lane) + offset)
					fits = fits and point.x > 16 and point.x < screen.x - 16 and point.y > top and point.y < bottom
		var boots := camera.unproject_position(Vector3(0, 0, -segment_start * config.row_spacing + 0.8))
		fits = fits and boots.y < bottom
		if fits:
			break
		distance *= 1.06

func start_preview() -> void:
	if paused or travel.active or not run.begin_preview():
		return
	preview_remaining = config.preview_seconds
	grid.reveal_run(run, segment_start, profile.settings.high_contrast)
	hud.overlay.hide()
	hud.show_preview()
	hud.update_preview(preview_remaining, config.preview_seconds)

func _process(delta: float) -> void:
	link_poll += delta
	if OS.get_name() == "iOS" and link_poll > 0.5:
		link_poll = 0
		var path := "user://passport-challenge.txt"
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			var link := file.get_as_text() if file and file.get_length() <= 24576 else ""
			file = null
			DirAccess.remove_absolute(path)
			open_challenge_link(link)
	if is_instance_valid(extra_stage): extra_stage.frozen = paused or menu.root.visible
	if grid: grid.frozen = paused or menu.root.visible or run.phase != RunState.Phase.PLAY
	if is_instance_valid(environment) and environment.atmosphere:
		environment.atmosphere.frozen = paused or menu.root.visible
	if paused or (menu and menu.root.visible):
		return
	if run.phase == RunState.Phase.PREVIEW:
		preview_remaining = maxf(0, preview_remaining - delta)
		hud.update_preview(preview_remaining, config.preview_seconds)
		if preview_remaining <= 0:
			grid.hide_path()
			run.finish_preview()
			update_play_hud()
			reset_decision_clock()
			follow_player()
		return
	if run.phase == RunState.Phase.PLAY and session.balance_version >= 2:
		decision_remaining = maxf(0, decision_remaining - delta)
		if session.mode == "adventure":
			if grid.moving and run.completed_rows > 0:
				traveler.position = standing_tile().position + Vector3.UP * 0.03
			elif DestinationTheme.style(session.current_country()) == "ice":
				traveler.position = Vector3(standing_tile().position.x + (GameCatalog.DECISION_SECONDS - decision_remaining) * 0.075, traveler.position.y, traveler.position.z)
		hud.update_decision(decision_remaining, GameCatalog.DECISION_SECONDS)
		standing_tile().set_pressure(1.0 - decision_remaining / GameCatalog.DECISION_SECONDS)
		traveler.pressure = 1.0 - decision_remaining / GameCatalog.DECISION_SECONDS
		if decision_remaining <= 0 and run.time_out():
			failure_reason = "timeout"
			var tile: PathTile = standing_tile()
			fall(tile)

func standing_tile() -> PathTile:
	return grid.tile_at(run.completed_rows - 1, run.selected_lane) if run.completed_rows > 0 else environment.starting_tile

func reset_decision_clock() -> void:
	decision_remaining = GameCatalog.DECISION_SECONDS
	standing_tile().set_pressure(0)
	traveler.pressure = 0
	traveler.play_animation("thinking")
	if session.balance_version >= 2:
		hud.update_decision(decision_remaining, GameCatalog.DECISION_SECONDS)

func update_play_hud() -> void:
	hud.show_play(run.completed_rows, config.row_count)
	if session.mode == "infinite":
		hud.score.text = str(run.completed_rows)
		hud.timer_label.text = "NEXT STEP · %d" % (run.completed_rows + 1)
		hud.timer_bar.value = float(run.completed_rows % config.row_count) / config.row_count
	elif session.mode != "practice" and session.mode != "tutorial":
		hud.phase_title.text = GameCatalog.country_name(session.current_country())

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(arcade): return
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
	if not has_paid_access():
		return false
	if session.balance_version >= 2 and decision_remaining <= 0:
		return false
	if paused or travel.active or not run.select(row, lane, config.lane_count):
		return false
	selected_decision_ms = int(round((GameCatalog.DECISION_SECONDS - decision_remaining) * 1000))
	replay.select(0 if session.mode == "infinite" else session.country_index, row, lane, int(round((GameCatalog.DECISION_SECONDS - decision_remaining) * 1000)))
	traveler.play_animation("jump")
	hud.timer_label.text = "JUMPING…"
	telemetry.track("tile_selected", {"row": row, "lane": lane, "mode": session.mode})
	audio.play_cue("jump")
	var start := traveler.position
	var destination := grid.tile_at(row, lane).position + Vector3(0, 0.03, 0)
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
		if friend_steps.size() < 512 and session.mode != "kids": friend_steps.append(selected_decision_ms)
		tile.set_state(PathTile.State.CORRECT)
		jump_streak += 1
		audio.play_streak(jump_streak)
		vibrate(15)
		update_play_hud()
		hud.phase_hint.text = "PERFECT STREAK · %d" % jump_streak
		hud.phase_hint.modulate = Color("ffde8a") if jump_streak >= 3 else Color.WHITE
		if jump_streak % 3 == 0 and not profile.settings.reduced_motion:
			traveler.body.scale = Vector3.ONE * 1.08
			create_tween().tween_property(traveler.body, "scale", Vector3.ONE, 0.2)
		if run.phase == RunState.Phase.COMPLETE:
			celebrate()
		elif session.mode == "infinite" and run.completed_rows % config.row_count == 0:
			next_infinite_segment()
		else:
			reset_decision_clock()
			follow_player()
	else:
		fall(tile)

func next_infinite_segment() -> void:
	segment_start = run.completed_rows
	grid.build(config, segment_start - 1, config.row_count + 1)
	grid.tile_at(segment_start - 1, run.selected_lane).set_state(PathTile.State.CORRECT)
	# Rebase scenery per chunk; the path seed never changes with the environment.
	rebuild_environment()
	set_overview()
	run.phase = RunState.Phase.READY
	start_preview()

func follow_player() -> void:
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	var aspect: float = get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y
	var factor: float = maxf(1.0, (config.lane_count * config.lane_spacing + 1.0) / (aspect * 14.0))
	var center_x := grid.position_for(run.completed_rows, 0).x + (config.lane_count - 1) * config.lane_spacing / 2.0
	var camera_position := Vector3(center_x, traveler.position.y + 8.0 * factor, traveler.position.z + 12.0 * factor)
	if run.phase == RunState.Phase.COMPLETE:
		camera_position.x = traveler.position.x
		camera_position.y = 9.0 * factor
	var rotation := Vector3(-atan2(8.0, 17.5), 0, 0)
	if profile.settings.reduced_motion:
		camera.position = camera_position
		camera.rotation = rotation
		return
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "position", camera_position, 0.5)
	camera_tween.tween_property(camera, "rotation", rotation, 0.5)

func fall(tile: PathTile = null) -> void:
	if session.mode == "expedition" and imported_challenge.get("kind") == "multiplayer":
		menu.multiplayer_scores[str(player_slot)] = total_score()
		menu.active_turn = false
	if not session.current_country().is_empty() and session.current_country() not in failed_countries:
		failed_countries.append(session.current_country())
	hud.show_falling()
	traveler.play_animation("fall")
	if failure_reason == "timeout":
		hud.phase_title.text = "Time’s up!"
		hud.phase_hint.text = "Choose your next tile within 10 seconds."
	if session.mode == "kids":
		hud.phase_title.text = "Almost!"
		hud.phase_hint.text = "Great try. Remember it and go again."
	var correct_tile := grid.tile_at(run.completed_rows, run.safe_lane(run.completed_rows))
	if correct_tile:
		correct_tile.set_state(PathTile.State.REVEALED)
		hud.phase_hint.text = "The checkmark shows the step you missed."
	var collapsing: Array[PathTile] = []
	if tile:
		if failure_reason == "timeout" and tile.row >= 0:
			for lane in config.lane_count:
				collapsing.append(grid.tile_at(tile.row, lane))
		else:
			collapsing.append(tile)
	for stone in collapsing:
		stone.set_state(PathTile.State.CRACKING)
	audio.play_cue("fall")
	vibrate(55)
	telemetry.track("decision_timeout" if failure_reason == "timeout" else "wrong_tile", metadata())
	var token: int = generation
	var start := traveler.position
	var positions: Array[Vector3] = []
	for stone in collapsing:
		positions.append(stone.position)
	active_tween = create_tween()
	if profile.settings.reduced_motion or not tile:
		active_tween.tween_interval(config.crack_seconds)
	else:
		active_tween.tween_property(tile, "rotation:z", 0.055, config.crack_seconds / 2)
		active_tween.tween_property(tile, "rotation:z", -0.045, config.crack_seconds / 2)
	active_tween.tween_callback(func():
		for stone in collapsing:
			stone.set_state(PathTile.State.FALLING)
			if profile.settings.reduced_motion:
				stone.hide()
	)
	active_tween.tween_method(func(progress: float):
		if not profile.settings.reduced_motion:
			traveler.position = start + Vector3(0, -9 * progress * progress, 0)
			traveler.pose_fall(progress)
			for index in collapsing.size():
				var stone := collapsing[index]
				stone.position = positions[index] + Vector3((index - collapsing.size() / 2.0) * 0.35 * progress, -11 * progress * progress, 0)
				stone.rotation.z = progress * (0.4 if index % 2 == 0 else -0.4)
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
		if failure_reason == "timeout":
			hud.modal_title.text = "Time’s up!"
			hud.modal_body.text += "\nEach new row gives you 10 seconds."
		return
	var body := "%d tiles · %d destinations\nSame path. Another chance." % [total_score(), session.completed_countries]
	if failure_reason == "timeout":
		body += "\nTime ran out. Each new row gives you 10 seconds."
	if session.mode in ["world", "kids", "trip", "special", "cinema", "adventure", "expedition"]:
		body += "\nContinue in " + GameCatalog.country_name(session.current_country()) + "."
	if session.mode == "infinite":
		body = "%d tiles remembered\nRetry starts at step 1\nwith the exact same path." % run.completed_rows
	if session.mode == "tutorial":
		body = "Remember the checkmarks,\nthen tap the next row."
	if session.mode != "infinite":
		var remaining := config.row_count - run.completed_rows
		body += "\n%d %s from your next stamp!" % [remaining, "jump" if remaining == 1 else "jumps"]
	var actions: Array = [{"text": "TRY AGAIN", "primary": true, "callback": func(): restart(false, true)}]
	if session.mode == "infinite":
		actions.append({"text": "NEW PATH", "callback": func(): restart(true, true)})
	elif session.mode in ["world", "daily", "challenge"]:
		actions.append({"text": "SHARE LINK + SAVE CARD", "callback": share_challenge})
	if session.mode == "expedition" and imported_challenge.get("kind") == "multiplayer":
		actions.append({"text": "NEXT PLAYER", "callback": func(): switch_player_slot((player_slot + 1) % menu.player_count); TravelExtrasUI.new(menu).show("multiplayer")})
	actions.append({"text": "MAIN MENU", "callback": return_to_menu})
	hud.show_journey_result("Great try!", body, actions)

func celebrate() -> void:
	if session.current_country() not in failed_countries:
		environment.atmosphere.celebration_remaining = 2.0
	celebrating = true
	hud.show_celebration()
	follow_player()
	var token: int = generation
	var start := traveler.position
	var destination := environment.finish_position
	traveler.play_animation("jump")
	audio.play_cue("jump")
	active_tween = create_tween()
	active_tween.tween_method(func(progress: float):
		traveler.position = start.lerp(destination, progress)
		if not profile.settings.reduced_motion:
			traveler.position += Vector3.UP * sin(progress * PI) * config.jump_height
			traveler.pose_jump(progress)
	, 0.0, 1.0, 0.5)
	active_tween.tween_callback(func():
		traveler.position = destination
		audio.play_cue("land")
		follow_player()
		traveler.play_animation("celebrate")
	)
	active_tween.tween_interval(0.2 if profile.settings.reduced_motion else 0.55)
	active_tween.tween_callback(func(): traveler.play_animation("pocket"))
	active_tween.tween_interval(0.15 if profile.settings.reduced_motion else 0.35)
	active_tween.tween_callback(func():
		if token != generation:
			return
		traveler.play_animation("passport")
		if session.mode in ["practice", "tutorial"]:
			finish_celebration()
		else:
			passport_stamp.present(session.current_country(), camera.unproject_position(traveler.position + Vector3(0, 1, 0)), profile.settings.reduced_motion)
	)

func finish_celebration() -> void:
	if not celebrating or run.phase != RunState.Phase.COMPLETE:
		return
	celebrating = false
	traveler.play_animation("celebrate")
	if session.mode == "practice":
		hud.show_result(true, run.completed_rows, config.row_count)
	elif session.mode == "tutorial":
		profile.tutorial_done = true
		profile.save()
		telemetry.track("tutorial_completed")
		hud.show_journey_result("You’ve got it!", "Remember. Jump. Explore.", [{"text": "START MY JOURNEY", "primary": true, "callback": func(): menu.pending_mode = "world"; menu.show_countries()}])
	else:
		complete_country()

func complete_country() -> void:
	if country_awarded:
		return
	country_awarded = true
	var rare_earned := false
	session.complete_country(config.row_count)
	completed_stops.append(session.current_country())
	profile.discover(session.current_country())
	profile.record_destination(session.current_country(), "jump", config.row_count)
	profile.note_completion(session.current_country(), "easy" if session.mode == "expedition" and imported_challenge.get("kind") in ["city", "landmark", "secret", "transport"] else session.difficulty, session.current_country() not in failed_countries, session.mode == "expedition" and imported_challenge.get("kind") == "weekly" and imported_challenge.get("week") == TravelActivities.week_key())
	if session.current_country() not in failed_countries:
		profile.award_badge("perfect:" + session.current_country())
		rare_earned = profile.earn_rare(session.current_country(), "gold")
	save_record()
	telemetry.track("country_completed", metadata())
	telemetry.flush()
	if session.mode == "expedition":
		profile.finish_extra_stage(imported_challenge.get("kind", ""), imported_challenge.get("key", ""), session.current_country())
	var options := session.choices()
	profile.advance_missions(session.current_country(), session.current_country() not in failed_countries, session.mode == "trip" and options.is_empty())
	if options.size() > 1:
		telemetry.track("destination_choice_shown", metadata())
	var actions: Array = []
	for destination in options:
		var id: String = destination
		actions.append({"text": ("FLY TO " if options.size() > 1 else "CONTINUE TO ") + GameCatalog.country_name(id).to_upper(), "primary": true, "callback": func(): travel_to(id)})
	if profile.world_champion() and not profile.champion_seen:
		actions.append({"text": "WORLD CHAMPION CELEBRATION", "primary": true, "callback": return_to_menu})
	var title := "Passport stamped!"
	var body := "%s\n%d %s · %d tiles" % [GameCatalog.country_name(session.current_country()), session.completed_countries, "destination" if session.completed_countries == 1 else "destinations", session.banked_tiles]
	for character in profile.last_unlocked_characters:
		body += "\nTRAVELER UNLOCKED · " + CharacterStyle.CHARACTERS[character].name
	body += "\nSouvenir collected: " + DestinationTheme.souvenir(session.current_country())
	if rare_earned: body += "\nRARE GOLD KEEPSAKE FOUND!"
	body += "\nDaily missions: %d / 3 complete" % profile.mission_count()
	if session.current_country() not in failed_countries:
		body += "\nFLAWLESS COUNTRY · Perfect-jump badge earned!"
	if session.mode == "kids":
		body += "\nSticker collected!\n" + CountryRewards.fact(session.current_country())
	if options.is_empty():
		telemetry.track("run_completed", metadata())
		telemetry.flush()
		title = "Journey complete!"
		body += "\nYou crossed the whole route."
		profile.record_recap(imported_challenge.get("name", "My " + session.mode.capitalize() + " journey") if session.mode == "expedition" else "My " + session.mode.capitalize() + " journey", completed_stops, session.banked_tiles)
		actions.append({"text": "WATCH JOURNEY MOVIE", "callback": func(): return_to_menu(); TravelExtrasUI.new(menu).show("recaps", str(profile.extras.recaps.size() - 1))})
		if session.mode == "expedition" and imported_challenge.get("kind") == "festival" and imported_challenge.get("festival") == TravelExtras.festival_key():
			var token := "festival:" + TravelExtras.festival_key()
			if token not in profile.extras.completed:
				profile.extras.completed.append(token)
				profile.activities.rewards[token] = TravelExtras.festival().keepsake
				profile.save()
		if session.mode == "expedition" and imported_challenge.get("kind") == "multiplayer":
			menu.multiplayer_scores[str(player_slot)] = session.banked_tiles
			menu.active_turn = false
			actions.append({"text": "NEXT PLAYER", "callback": func(): switch_player_slot((player_slot + 1) % menu.player_count); TravelExtrasUI.new(menu).show("multiplayer")})
		if session.mode == "expedition" and imported_challenge.get("kind") == "city":
			for secret in TravelExtras.SECRETS:
				if TravelExtras.SECRETS[secret].requires == imported_challenge.get("key"):
					var key: String = secret
					actions.append({"text": "EXPLORE HIDDEN VIEWPOINT", "callback": func(): return_to_menu(); TravelExtrasUI.new(menu).launch("secret", key)})
		if session.mode == "trip":
			profile.award_badge("trip:" + trip_id)
			body += "\nAdventure badge earned! Find it in Collection Goals."
		if session.mode == "challenge":
			body += "\n" + ("You beat the target!" if total_score() > session.target else "Target matched!" if total_score() == session.target else "Target: %d" % session.target)
		actions.append({"text": "PLAY AGAIN", "primary": true, "callback": func(): restart(false, true)})
	if options.size() <= 1 and session.mode not in ["kids", "adventure", "expedition"]:
		actions.append({"text": "SHARE LINK + SAVE CARD", "callback": share_challenge})
	actions.append({"text": "MAIN MENU", "callback": return_to_menu})
	hud.show_journey_result(title, body, actions)
	parcel.present(session.current_country(), int(profile.souvenir_counts.get(session.current_country(), 1)), profile.settings.reduced_motion)
	if options.is_empty() and online:
		submit_online()

func travel_to(id: String) -> void:
	if travel.active or run.phase != RunState.Phase.COMPLETE or not country_awarded or id not in session.choices():
		return
	if not profile.can_visit(id):
		reject_locked_destination()
		return
	var departure := session.current_country()
	if not session.travel_to(id):
		return
	telemetry.track("destination_selected", {"country": id, "mode": session.mode})
	if id not in GameCatalog.DESTINATIONS[departure].neighbors:
		telemetry.track("long_haul_selected", {"country": id, "mode": session.mode})
	audio.play_cue("travel")
	travel.begin(departure, id, profile.settings.reduced_motion, id in GameCatalog.PREMIUM_DESTINATIONS or id in GameCatalog.CINEMA_DESTINATIONS)

func total_score() -> int:
	return session.banked_tiles + (0 if country_awarded else run.completed_rows)

func save_record() -> void:
	if session.mode not in ["practice", "tutorial"]:
		profile.record(session.mode, session.difficulty, total_score(), session.date)

func copy_challenge() -> void:
	var route := session.challenge_route()
	if route.is_empty():
		return
	var code := ChallengeCode.encode(session.challenge_seed(), session.difficulty, route, total_score(), session.balance_version, friend_steps)
	DisplayServer.clipboard_set(ChallengeCode.link(code))
	hud.modal_body.text = "Challenge link copied.\nSend it to a friend to replay\nthe same route and path."
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

func has_paid_access() -> bool:
	if is_instance_valid(arcade):
		return (arcade.route_kind != "special" or purchase.unlocked) and (arcade.route_kind != "cinema" or cinema_purchase.unlocked)
	if session.mode == "adventure":
		var id := session.current_country()
		if id in GameCatalog.PREMIUM_DESTINATIONS and not purchase.unlocked: return false
		if id in GameCatalog.CINEMA_DESTINATIONS and not cinema_purchase.unlocked: return false
	var route: Array = session.fixed_route if session.mode in ["challenge", "expedition"] else []
	if (session.mode == "special" or route.any(func(id): return id in GameCatalog.PREMIUM_DESTINATIONS)) and not purchase.unlocked:
		return false
	if (session.mode == "cinema" or route.any(func(id): return id in GameCatalog.CINEMA_DESTINATIONS)) and not cinema_purchase.unlocked:
		return false
	return true

func metadata() -> Dictionary:
	return {"mode": session.mode, "difficulty": session.difficulty, "country": session.current_country(), "row": run.completed_rows, "score": total_score(), "countries": session.completed_countries, "seed": session.seed_value, "version": PathGenerator.VERSION, "balance_version": session.balance_version}

func vibrate(milliseconds: int) -> void:
	if profile.settings.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)

func return_to_menu() -> void:
	close_arcade()
	if celebrating:
		finish_celebration()
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
	if is_instance_valid(arcade):
		arcade.set_paused(true)
		return
	if paused or menu.root.visible or (run.phase in [RunState.Phase.FAILED, RunState.Phase.COMPLETE] and not travel.active and not celebrating):
		return
	paused = true
	traveler.animation_paused = true
	passport_stamp.set_paused(true)
	travel.set_paused(true)
	for tween in [active_tween, camera_tween]:
		if tween and tween.is_valid():
			tween.pause()
	audio.set_paused(true)
	hud.show_pause()
	if not session.current_country().is_empty(): hud.add_action("PHOTO MODE", false, open_photo_mode)

func resume_game() -> void:
	if is_instance_valid(arcade):
		arcade.set_paused(false)
		return
	if not paused:
		return
	paused = false
	traveler.animation_paused = false
	passport_stamp.set_paused(false)
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
			if is_instance_valid(arcade): arcade.save_checkpoint()
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
		if value.get("homeCountry", "") in GameCatalog.FREE_DESTINATIONS:
			profile.home_country = value.homeCountry
		for id in value.discoveries:
			if id is String and id in GameCatalog.DESTINATIONS and id not in profile.discoveries:
				profile.discoveries.append(id)
		profile.save()

func adventure_hint() -> String:
	var theme := DestinationTheme.style(session.current_country())
	if theme == "ice": return "SLIPPERY ICE · Your feet drift while you decide."
	if grid.moving: return "MOVING BRIDGES · Aim for the moving stone."
	if session.current_country() in ["MOON", "SPACE", "MARS"]: return "LOW GRAVITY · Float higher and longer."
	if session.current_country() == "UNDERWATER": return "BUOYANT JUMPS · Drift through the deep."
	return "ADVENTURE PLAY · Local scores, no ranked points."

func open_challenge_link(link: String) -> bool:
	if ChallengeCode.decode(link).is_empty(): return false
	return_to_menu()
	menu.show_challenge()
	menu.challenge_input.text = link
	return true

func start_arcade(kind: String, destination: String = "") -> void:
	if kind not in ["world", "special", "cinema", "daily", "practice"]: return
	if kind == "practice" and destination not in profile.discoveries:
		reject_locked_destination()
		return
	if (kind == "special" or (kind == "practice" and destination in GameCatalog.PREMIUM_DESTINATIONS)) and not purchase.unlocked:
		menu.show_special_route()
		return
	if (kind == "cinema" or (kind == "practice" and destination in GameCatalog.CINEMA_DESTINATIONS)) and not cinema_purchase.unlocked:
		menu.show_cinema_route()
		return
	if kind == "world" and profile.home_country not in GameCatalog.FREE_DESTINATIONS:
		menu.pending_arcade = kind
		menu.show_countries()
		return
	if kind == "daily" and not profile.can_visit(BalloonArcade.daily_destination(GameCatalog.today_utc())):
		reject_locked_destination()
		return
	return_to_menu()
	paused = true
	menu.root.hide()
	hud.hide()
	audio.set_paused(false)
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	arcade = BalloonArcade.new()
	arcade.profile = profile
	arcade.audio = audio
	arcade.style = hud
	arcade.route_kind = kind
	if kind == "practice":
		arcade.route.assign([destination])
	elif kind == "daily":
		arcade.configure_daily(Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system())).substr(0, 10))
	elif kind == "world":
		arcade.route = profile.tour_route()
		arcade.country_index = RoutePlanner.next_uncleared(arcade.route, profile.discoveries)
	else:
		arcade.route.assign(GameCatalog.PREMIUM_DESTINATIONS.keys() if kind == "special" else GameCatalog.CINEMA_DESTINATIONS.keys())
		arcade.country_index = RoutePlanner.next_uncleared(arcade.route, profile.discoveries)
	arcade.exited.connect(return_to_menu)
	layer.add_child(arcade)

func close_arcade() -> void:
	if not is_instance_valid(arcade): return
	arcade.save_checkpoint()
	profile.record(arcade.record_mode(), "moderate" if arcade.route_kind == "daily" else profile.difficulty, arcade.score)
	var layer := arcade.get_parent()
	arcade = null
	layer.queue_free()
	paused = false
	hud.show()
	audio.set_paused(false)

func reject_locked_destination() -> void:
	return_to_menu()
	menu.show_locked_destination()

func open_photo_mode() -> void:
	if not paused: pause_game()
	menu.photo_return = func(): menu.root.hide(); hud.overlay.show(); menu.photo_return = Callable()
	TravelActivityUI.new(menu).show("photo", session.current_country())

func valid_activity(data: Dictionary) -> bool:
	var route: Variant = data.get("route")
	if not route is Array or not profile.can_visit_route(route): return false
	if data.get("kind") in ["city", "landmark", "transport", "secret"]:
		var entry := TravelExtras.stage(data.kind, data.get("key", ""))
		return not entry.is_empty() and route == [entry.country] and TravelExtras.unlocked(profile, data.kind, data.key)
	if data.get("kind") == "festival": return data.get("festival") == TravelExtras.festival_key() and route == TravelExtras.festival().route
	if data.get("kind") == "multiplayer":
		return data.get("difficulty") in GameCatalog.DIFFICULTIES and data.get("seed") is int and data.seed > 0 and data.seed < PathGenerator.MODULUS - 1
	if data.get("kind") == "branch":
		if route.size() != 1 or not data.get("branches") is Array or data.branches.size() != 2: return false
		var seen: Array = route.duplicate()
		for group in data.branches:
			if not group is Array or group.size() != 2 or not profile.can_visit_route(group): return false
			for id in group:
				if id in seen: return false
				seen.append(id)
	return true

func apply_accessibility() -> void:
	audio.apply_settings(profile.settings)
	hud.text_scale = profile.settings.text_scale
	hud.large_controls = profile.settings.large_controls
	hud.apply_text_scale()
	menu.apply_menu_accessibility()
	if is_instance_valid(arcade): arcade.profile = profile

func switch_player_slot(slot: int, save_current: bool = true) -> void:
	if slot not in [0, 1, 2, 3] or menu.export_busy: return
	close_arcade()
	cancel_motion()
	if save_current: profile.save()
	player_slot = slot
	profile = PlayerProfile.new(save_path if slot == 0 else save_path + ".player" + str(slot))
	profile.character_pack_unlocked = menu.character_purchase.unlocked
	menu.profile = profile
	menu.player_slot = slot
	menu.active_turn = false
	menu.photo_return = Callable()
	travel.profile = profile
	telemetry.flush()
	telemetry = LocalTelemetry.new(profile.file_path + ".events")
	online = false
	run.phase = RunState.Phase.READY
	hud.overlay.hide()
	apply_accessibility()
	menu.show_main()
