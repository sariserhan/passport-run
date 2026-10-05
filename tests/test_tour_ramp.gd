extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func ramped(key: String, step: int, kids := false) -> DifficultyConfig:
	var config := GameCatalog.difficulty(key)
	GameCatalog.tour_ramp(config, step, kids)
	return config

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var start := ramped("easy", 0)
	expect(start.row_count == 10 and start.lane_count == 3 and start.preview_seconds == 3.0, "The first countries keep the chosen difficulty")
	expect(ramped("easy", 10).row_count == 11, "Every ten countries adds a row")
	var fifty := ramped("easy", 50)
	expect(fifty.row_count == 15 and fifty.lane_count == 4 and is_equal_approx(fifty.preview_seconds, 2.5), "Country 50 adds a lane and trims the preview")
	var late := ramped("easy", 240)
	expect(late.row_count == 10 + GameCatalog.RAMP_MAX_ROWS and late.preview_seconds == 2.0 and late.lane_count == 4, "Rows and preview are capped late in the tour")
	expect(ramped("hard", 120).lane_count == 5 and ramped("hard", 120).row_count == 26, "Hard keeps five lanes and caps at 26 rows")
	var kids := ramped("kids", 45, true)
	expect(kids.row_count == 6 + 3 and kids.lane_count == 3 and kids.preview_seconds == 3.0, "Kids ramp gently: rows only")
	var unchanged := ramped("moderate", -1)
	expect(unchanged.row_count == 14 and unchanged.lane_count == 4, "Modes without a ramp are untouched")

	var session := JourneySession.new()
	for mode in ["daily", "infinite", "practice", "expedition"]:
		session.begin(mode, "easy", "FR", 7)
		expect(session.ramp_step() == -1, "No ramp in " + mode)
	session.begin("world", "easy", "FR", 7)
	session.country_index = 23
	expect(session.ramp_step() == 23, "World Tour ramps by tour position")
	session.route_start_index = 20
	expect(session.challenge_ramp_start() == 20, "Shared links start the ramp where the shared route starts")

	var route: Array[String] = ["FR", "IT"]
	var code := ChallengeCode.encode(9, "easy", route, 2 * (10 + GameCatalog.RAMP_MAX_ROWS), GameCatalog.BALANCE_VERSION, [], 37)
	var data := ChallengeCode.decode(code)
	expect(data.get("ramp_start") == 37, "Challenge links carry the ramp start")
	session.begin("challenge", "easy", "FR", 9, data)
	session.country_index = 1
	expect(session.ramp_step() == 38, "A friend replays the same ramped rows")
	expect(ChallengeCode.decode(ChallengeCode.encode(9, "easy", route, 2 * (10 + GameCatalog.RAMP_MAX_ROWS))).is_empty(), "Unramped links cannot claim ramped scores")
	var legacy := ChallengeCode.decode(ChallengeCode.encode(9, "easy", route, 5))
	session.begin("challenge", "easy", "FR", 9, legacy)
	expect(not legacy.is_empty() and session.ramp_step() == -1, "Older links without a ramp replay unchanged")
	var bad := ChallengeCode.PREFIX + Marshalls.utf8_to_base64(JSON.stringify({"generator_version": PathGenerator.VERSION, "seed": 9, "difficulty": "easy", "route": route, "starting_country": "FR", "target_score": 1, "balance_version": 3, "ramp_start": -4}))
	expect(ChallengeCode.decode(bad).is_empty(), "Invalid ramp starts are rejected")

	var game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://tour-ramp-test.json"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
	root.add_child(game)
	for frame in 8: await process_frame
	game.profile.choose_start_country("FR")
	game.start_game("world", "easy")
	await process_frame
	expect(game.config.row_count == 10, "World Tour starts at the chosen difficulty")
	game.session.country_index = 50
	game.load_country(false)
	await process_frame
	expect(game.config.row_count == 15 and game.config.lane_count == 4 and game.run.path.size() == 15, "Fifty countries in, the real path is longer and wider")
	game.queue_free()
	await process_frame
	print("Tour ramp checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
