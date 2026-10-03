extends SceneTree

var failures := 0
var checks := 0
var game
var arcade: BalloonArcade
var save_path := "user://arcade-features-" + DisplayServer.get_name() + ".json"

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()

func open_tour() -> void:
	game.start_arcade("world")
	arcade = game.arcade
	arcade.set_physics_process(false)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/arcade-features-" + name + ".png")

func clear_round() -> void:
	arcade.balls.clear()
	if arcade.challenge in ["swarm", "no_fire"]: arcade.remaining = 0
	arcade.simulate(0.01)

func run() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save_path + suffix)
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = save_path
	root.add_child(game)
	await process_frame
	game.profile.choose_start_country("FR")
	game.profile.settings.music = 0.0
	game.profile.settings.sound = 0.0
	game.audio.apply_settings(game.profile.settings)
	if DisplayServer.get_name() != "headless": await create_timer(1.0).timeout
	game.profile.records["balloon:easy"] = 1000
	open_tour()
	arcade.begin_round()
	arcade.score = 1000
	arcade.update_stats()
	expect(not arcade.best_beaten, "Tying an existing score is not a personal best")
	arcade.score = 1100
	arcade.update_stats()
	expect(arcade.best_beaten and arcade.best_before == 1000 and arcade.feedback.visible and "PERSONAL BEST" in arcade.feedback.text, "Passing the previous score announces a personal best during play")
	await capture("personal-best")
	arcade.score = 1200
	arcade.update_stats()
	expect("1100" in arcade.feedback.text, "Personal-best celebration occurs once per attempt")
	arcade.coins = 27
	arcade.round_coins = 20
	arcade.hit()
	expect(arcade.phase == BalloonArcade.Phase.FAILED and arcade.quick_retry.visible and arcade.death_time > 0 and not arcade.panel.visible, "Retry is immediately available during the death animation")
	await capture("instant-retry")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.index = 2
	touch.position = arcade.quick_retry.get_global_rect().get_center()
	arcade._input(touch)
	expect(arcade.phase == BalloonArcade.Phase.PLAY and arcade.score == 0 and arcade.coins == 20 and not arcade.quick_retry.visible, "One tap retries immediately with the original round balances")
	expect(arcade.country_failed and arcade.lives == 1 and not arcade.panel.visible, "Retry preserves first-try failure and shows no repeated instructions")
	expect(not arcade.best_beaten and arcade.best_before == 1200, "Retry compares against the best score just recorded rather than replaying its celebration")
	arcade.hit()
	var retry_key := InputEventKey.new()
	retry_key.physical_keycode = KEY_R
	retry_key.pressed = true
	arcade._unhandled_input(retry_key)
	expect(arcade.phase == BalloonArcade.Phase.PLAY, "Keyboard retry works before the death animation finishes")
	arcade.round_index = 2
	arcade.begin_round()
	arcade.score = 1300
	arcade.update_stats()
	var boss: Dictionary = arcade.balls[0]
	var old_velocity: Vector2 = boss.velocity
	arcade.pop_ball(0)
	arcade.pop_ball(0)
	expect(arcade.balls.size() == 1 and boss.warning == 0.85 and boss.charge_pending and boss.minions_pending == 2 and boss.velocity == old_velocity, "Armor thresholds warn before changing velocity or spawning minions")
	await capture("boss-warning")
	arcade.freeze = 10
	arcade.simulate(0.1)
	expect(boss.warning == 0.85 and arcade.balls.size() == 1, "Freeze holds a boss's warned attack")
	arcade.freeze = 0
	arcade.set_paused(true)
	var before := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
	arcade.set_paused(false)
	expect(arcade.phase == BalloonArcade.Phase.COUNTDOWN and arcade.countdown.visible and arcade.countdown_label.text == "3", "Resume starts a visible three-second countdown")
	await capture("resume-countdown")
	arcade.set_control("▶", true)
	expect(not arcade.fire() and not arcade.right_held, "Countdown blocks movement and shots")
	var pause_touch := InputEventScreenTouch.new()
	pause_touch.pressed = true
	pause_touch.index = 5
	pause_touch.position = arcade.pause_button.get_global_rect().get_center()
	arcade._input(pause_touch)
	expect(arcade.phase == BalloonArcade.Phase.PAUSED, "An independent touch can pause the countdown")
	arcade.set_paused(false)
	arcade.simulate(2)
	expect(arcade.countdown_label.text == "1" and arcade.remaining == before.remaining and arcade.balls == before.balls and arcade.rng.state == before.rng, "Countdown freezes the timer, balloons, warning and random state")
	arcade._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(arcade.phase == BalloonArcade.Phase.PAUSED and not arcade.countdown.visible, "Backgrounding safely pauses a countdown")
	arcade.set_paused(false)
	arcade.simulate(3)
	expect(arcade.phase == BalloonArcade.Phase.PLAY and not arcade.countdown.visible and boss.warning == 0.85, "Returning restarts the full countdown and preserves the entire attack warning")
	arcade.update_boss_attacks(0.84)
	expect(arcade.balls.size() == 1 and boss.velocity == old_velocity, "The warning remains actionable until its deadline")
	arcade.update_boss_attacks(0.02)
	expect(arcade.balls.size() == 3 and boss.velocity.x == -old_velocity.x * 1.25 and not boss.charge_pending, "A warned charge and minion spawn execute once after the deadline")
	arcade.queue_boss_attack(boss, false, 1)
	game.return_to_menu()
	open_tour()
	boss = arcade.balls[0]
	expect(arcade.phase == BalloonArcade.Phase.PAUSED and boss.warning == 0.85 and boss.minions_pending == 1 and arcade.best_beaten and arcade.best_before == 1200, "Reopening retains warned attacks and personal-best history")
	expect(not arcade.feedback.visible, "Reloading does not repeat an already-announced personal best")
	var legacy := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
	for field in ArcadeCheckpoint.NEW_FIELDS: legacy.erase(field)
	for ball in legacy.balls:
		for field in ["warning", "charge_pending", "minions_pending"]: ball.erase(field)
	var bytes := var_to_bytes(legacy)
	var encoded := JSON.stringify({"size": bytes.size(), "data": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_ZSTD))})
	var old_state := ArcadeCheckpoint.decode(encoded, arcade)
	expect(not old_state.is_empty() and old_state.country_drops == -1, "Older saved rounds remain usable without falsely claiming a no-drops achievement")
	arcade.set_paused(false)
	arcade.simulate(3)
	game.profile.arcade_pops = 99
	arcade.balls.assign([arcade.make_ball(Vector2(100, 100), 0, 1)])
	arcade.pop_ball(0)
	expect(game.profile.arcade_pops == 100 and "arcade:100_pops" in game.profile.badges, "The hundredth lifetime pop earns its badge")
	var restored := PlayerProfile.new(save_path)
	expect(restored.arcade_pops == 100 and "arcade:100_pops" in restored.badges, "Pop count and reward persist together with the popped-ball checkpoint")
	expect(CharacterStyle.unlocked("outfit", "balloon_sky", restored.discoveries, restored.badges), "100 Pops unlocks an existing wardrobe entry")
	expect(not CharacterStyle.unlocked("outfit", "balloon_gold", restored.discoveries), "Destinations alone cannot unlock achievement outfits")
	game.profile.character_style.outfit = "balloon_sky"
	game.profile.save()
	expect(PlayerProfile.new(save_path).character_style.outfit == "balloon_sky", "An earned equipped outfit survives reload")
	arcade.collect("time")
	clear_round()
	expect("arcade:clean_boss" not in game.profile.badges and "arcade:no_drops" not in game.profile.badges, "Failed rounds and collected drops disqualify their achievements")
	arcade.finish_stamp()
	arcade.parcel.reduced_motion = true
	arcade.parcel.open_or_finish()
	arcade.parcel.open_or_finish()
	arcade.next_round()
	arcade.next_round()
	arcade.arrival.finish()
	expect(not arcade.country_failed and arcade.country_drops == 0, "A new destination resets its achievement eligibility")
	for stage in 3:
		clear_round()
		if stage < 2: arcade.next_round()
	expect("arcade:clean_boss" in game.profile.badges and "arcade:no_drops" in game.profile.badges and arcade.earned_badges.size() == 2, "A clean no-drops destination awards both badges")
	arcade.finish_stamp()
	arcade.parcel.reduced_motion = true
	arcade.parcel.open_or_finish()
	arcade.parcel.open_or_finish()
	await capture("achievement-rewards")
	var badges: Array[String] = game.profile.badges.duplicate()
	var discoveries: Array[String] = game.profile.discoveries.duplicate()
	var history: Array[String] = game.profile.history.duplicate()
	var missions: Dictionary = game.profile.daily_missions.duplicate(true)
	var total_pops: int = game.profile.arcade_pops
	var main_best: int = game.profile.records["balloon:easy"]
	game.return_to_menu()
	var journey: String = game.profile.arcade_saves.world
	var future: String = game.profile.tour_route()[5]
	game.start_arcade("practice", future)
	expect(not is_instance_valid(game.arcade) and game.profile.arcade_saves.world == journey, "Practice refuses future scenery without altering the saved journey")
	game.menu.show_arcade_practice()
	expect(game.menu.content.get_children().filter(func(node): return node is Button and node.text.begins_with("PRACTICE ")).size() == discoveries.size(), "Practice lists only stamped destinations")
	for button in game.menu.content.get_children():
		if button is Button and button.text == "PRACTICE FRANCE":
			button.pressed.emit()
			break
	arcade = game.arcade
	arcade.set_physics_process(false)
	expect(arcade.route_kind == "practice" and arcade.route == ["FR"] and not arcade.resumed, "The practice picker opens a separate fresh three-round replay")
	await capture("practice")
	arcade.begin_round()
	for stage in 3:
		arcade.balls.assign([arcade.make_ball(Vector2(100, 100), 0, 1)])
		arcade.pop_ball(0)
		clear_round()
		if stage < 2: arcade.next_round()
	expect(not arcade.stamp_pending and arcade.phase == BalloonArcade.Phase.CLEAR and arcade.earned_badges.is_empty(), "Practice completes without stamps or achievement awards")
	arcade.next_round()
	expect(not is_instance_valid(game.arcade) and game.profile.arcade_saves.world == journey, "Finishing practice preserves the main journey checkpoint byte for byte")
	expect(game.profile.badges == badges and game.profile.discoveries == discoveries and game.profile.history == history and game.profile.daily_missions == missions and game.profile.arcade_pops == total_pops, "Practice preserves badges, passport history, missions and lifetime pops")
	expect(game.profile.records["balloon:easy"] == main_best and game.profile.arcade_practice_records.has("balloon-practice:FR:easy"), "Practice records remain separate from tour personal bests")
	expect(PlayerProfile.new(save_path).arcade_practice_records == game.profile.arcade_practice_records, "Separate practice bests survive profile reload")
	var main_records: Dictionary = game.profile.records.duplicate()
	for index in 200: game.profile.arcade_practice_records["balloon-practice:fixture-" + str(index) + ":easy"] = index
	game.profile.record("balloon-practice:FR", "easy", 5000)
	expect(game.profile.records == main_records and game.profile.arcade_practice_records.size() == 200, "The bounded practice history never evicts tour or memory best scores")
	open_tour()
	expect(arcade.country_index == 1 and arcade.round_index == 2 and arcade.phase == BalloonArcade.Phase.CLEAR, "Returning from practice resumes the same journey destination and round")
	game.return_to_menu()
	game.menu.show_arcade_achievements()
	await capture("achievements")
	game.menu.show_wardrobe()
	expect(game.menu.content.get_children().any(func(node): return node is Button and "Sky Balloon Explorer" in node.text and "EQUIPPED" in node.text), "Earned balloon rewards can be equipped in the existing wardrobe")
	game.profile.discoveries.append("MOON") # Test fixture: scenery discovery never grants purchase access.
	game.start_arcade("practice", "MOON")
	expect(not is_instance_valid(game.arcade) and game.menu.special_page, "Practice retains the Special pack ownership gate")
	game.profile.discoveries.append("WIZARD_CASTLE")
	game.start_arcade("practice", "WIZARD_CASTLE")
	expect(not is_instance_valid(game.arcade) and game.menu.cinema_page, "Practice retains the separate Cinema ownership gate")
	game.queue_free()
	await process_frame
	print("Arcade feature checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
