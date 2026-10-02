extends SceneTree

var game: Node3D
var checks := 0
var failures := 0
var render := false

func _initialize() -> void:
	render = DisplayServer.get_name() != "headless"
	create_timer(60).timeout.connect(func(): push_error("Animation test timeout"); quit(1))
	run_tests.call_deferred()

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func wait(seconds: float = 0.05) -> void:
	await create_timer(seconds).timeout

func until(test: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.paused:
			game.resume_game()
		if test.call():
			return
	expect(false, "Expected animation state was not reached")

func capture(name: String) -> void:
	if render:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func start_play(mode: String = "world") -> void:
	game.start_game(mode, "easy")
	game.start_preview()
	game.preview_remaining = 0.001
	await until(func(): return game.run.phase == RunState.Phase.PLAY)

func clear_country() -> void:
	game.config.jump_seconds = 0.005
	for row in game.config.row_count:
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Animated character accepts safe row")
		await until(func(): return game.run.phase != RunState.Phase.JUMPING)

func run_tests() -> void:
	root.size = Vector2i(390, 844)
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://animation-test-profile.json"
	for ending in ["", ".bak", ".tmp", ".events"]:
		DirAccess.remove_absolute(game.save_path + ending)
	root.add_child(game)
	await wait()
	game.profile.home_country = "FR"
	await start_play()
	expect(game.session.balance_version == 2, "New runs use timed balance version 2")
	expect(game.decision_remaining > 9.8 and game.decision_remaining <= 10, "Preview gives a fresh 10-second decision window")
	game.traveler._process(0.85)
	expect(game.traveler.portrait.frame in [1, 2, 3], "Waiting cycles through thoughtful poses")
	await capture("24-thinking")
	game._process(9.1)
	expect(game.decision_remaining > 0 and game.decision_remaining < 1, "Decision clock counts down on playable row")
	game.pause_game()
	var remaining: float = game.decision_remaining
	var animation_time: float = game.traveler.animation_clock
	game._process(3)
	await wait(0.1)
	expect(game.decision_remaining == remaining and game.traveler.animation_clock == animation_time, "Pause freezes countdown and character animation")
	game.resume_game()
	expect(game.choose_tile(0, game.run.safe_lane(0)), "Choice before deadline starts jump")
	game._process(3)
	expect(game.decision_remaining == remaining, "Jump does not consume decision time")
	await wait(0.12)
	expect(game.traveler.portrait.frame in [4, 5, 6, 7], "Jump changes to actual jump poses")
	await capture("25-jumping")
	await until(func(): return game.run.phase == RunState.Phase.PLAY)
	expect(game.run.completed_rows == 1 and game.decision_remaining > 9.8, "Landing advances once and resets 10 seconds")
	game.decision_remaining = 0
	expect(not game.choose_tile(1, game.run.safe_lane(1)), "Expired clock rejects a late choice")
	game._process(0.01)
	expect(game.run.phase == RunState.Phase.FALLING and game.failure_reason == "timeout", "Expired row ends with a timed fall")
	await wait(0.5)
	expect(game.traveler.portrait.frame >= 12, "Falling uses flailing character poses")
	await capture("26-falling")
	await until(func(): return game.run.phase == RunState.Phase.FAILED)
	expect(game.total_score() == 1 and "10 seconds" in game.hud.modal_body.text, "Timeout preserves earned score and explains the rule")
	await start_play()
	game.decision_remaining = 0
	game._process(0.01)
	await until(func(): return game.run.phase == RunState.Phase.FAILED)
	expect(game.total_score() == 0, "Initial platform timeout works without a tile or phantom score")
	var route: Array[String] = ["FR"]
	var old := ChallengeCode.decode(ChallengeCode.encode(5, "easy", route, 0, 1))
	game.imported_challenge = old
	await start_play("challenge")
	game._process(11)
	expect(game.session.balance_version == 1 and game.run.phase == RunState.Phase.PLAY, "Legacy challenge keeps untimed rules")
	var new_code := ChallengeCode.decode(ChallengeCode.encode(5, "easy", route, 0))
	expect(new_code.balance_version == 2, "New challenge code carries timed rules")
	await start_play()
	await clear_country()
	expect(game.celebrating and not game.country_awarded, "Completion starts celebration before passport award")
	await until(func(): return game.traveler.animation == "pocket")
	expect(game.traveler.portrait.frame == 9, "Celebration reaches into pocket for passport")
	await capture("27-passport-pocket")
	await until(func(): return game.passport_stamp.active)
	expect(game.traveler.animation == "passport" and game.traveler.portrait.frame == 10, "Character presents open passport")
	game.pause_game()
	expect(not game.passport_stamp.book.visible and game.traveler.animation_paused, "Passport animation pauses behind pause dialog")
	await wait(0.2)
	expect(game.passport_stamp.mark == 0, "Paused passport cannot stamp early")
	game.resume_game()
	await until(func(): return game.passport_stamp.mark >= 1)
	expect(game.traveler.portrait.frame == 11, "Character presses stamp onto passport")
	await capture("28-passport-stamped")
	await until(func(): return game.country_awarded)
	expect(game.profile.discoveries == ["FR"] and game.session.banked_tiles == 10, "Stamp awards actual completed country and score")
	game.finish_celebration()
	expect(game.profile.history.size() == 1 and game.session.banked_tiles == 10, "Repeated completion cannot double-award")
	game.passport_stamp.present("JP", Vector2.ZERO, false)
	game.return_to_menu()
	await wait(1.5)
	expect(not game.passport_stamp.active and game.profile.discoveries == ["FR"], "Leaving cancels pending stamp without awarding another country")
	game.profile.settings.reduced_motion = true
	await start_play()
	var frame: int = game.traveler.portrait.frame
	game.traveler._process(3)
	expect(game.traveler.portrait.frame == frame, "Reduced motion suppresses idle gesture cycling")
	game.queue_free()
	await wait()
	print("Animation/timer checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
