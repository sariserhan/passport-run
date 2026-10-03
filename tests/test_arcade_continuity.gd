extends SceneTree

var checks := 0
var failures := 0
var game
var arcade: BalloonArcade
var SAVE := "user://arcade-continuity-" + DisplayServer.get_name() + ".json"

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()

func open_game() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	game.profile.settings.music = 0.0
	game.profile.settings.sound = 0.0
	game.audio.apply_settings(game.profile.settings)

func open_arcade() -> void:
	game.start_arcade("world")
	arcade = game.arcade
	arcade.set_physics_process(false)

func encode(state: Dictionary) -> String:
	var bytes := var_to_bytes(state)
	return JSON.stringify({"size": bytes.size(), "data": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_ZSTD))})

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/arcade-continuity-" + name + ".png")

func run() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
	await open_game()
	var daily := BalloonArcade.daily_destination(GameCatalog.today_utc())
	game.profile.choose_start_country("JP" if daily != "JP" else "FR")
	var route: Array[String] = game.profile.tour_route()
	expect(game.profile.can_visit(route[0]) and not game.profile.can_visit(route[1]), "Only the current guided stop is accessible")
	var previous_backdrop: Texture2D = game.environment.get_node("Scenery/Backdrop").texture
	game.adventure_start = route[10]
	game.start_game("adventure", "easy")
	expect(game.menu.root.visible and game.environment.get_node("Scenery/Backdrop").texture == previous_backdrop, "Standalone entry cannot reveal future scenery")
	game.imported_challenge = {"seed": 23, "difficulty": "easy", "route": [route[0], route[10]], "target_score": 0, "balance_version": 1}
	game.start_game("challenge", "easy")
	expect(game.menu.root.visible, "A challenge cannot reveal a future stop later in its route")
	game.trip_id = "europe"
	game.start_game("trip", "easy")
	expect(game.menu.root.visible, "Short trips cannot bypass guided discoveries")
	game.start_game("daily", "easy")
	expect(game.menu.root.visible, "The immutable world daily stays locked before its stops are reached")
	game.start_arcade("daily")
	expect(not is_instance_valid(game.arcade), "Daily arcade cannot reveal an unreached destination")
	game.purchase.unlocked = true # Test-only entitlement; scenery gating is independent.
	var paid: Array = GameCatalog.PREMIUM_DESTINATIONS.keys()
	game.special_start = paid[5]
	game.start_game("special", "easy")
	expect(game.menu.root.visible, "Ownership does not permit skipping paid scenery")
	game.menu.show_special_route()
	expect(game.menu.content.find_children("*", "TravelArtwork", true, false).is_empty(), "Locked pack cards have no scenery previews")
	game.special_start = paid[0]
	game.start_game("special", "easy")
	expect(not game.menu.root.visible and game.session.current_country() == paid[0], "Ownership permits the current paid-route stop")
	game.return_to_menu()
	open_arcade()
	arcade.begin_round()
	arcade.round_index = 1
	arcade.begin_round()
	arcade.challenge = "flood"
	arcade.remaining = 17.25
	arcade.score = 2350
	arcade.round_score = 1800
	arcade.coins = 63
	arcade.round_coins = 51
	arcade.player_x = 246.0
	arcade.collect("laser")
	arcade.collect("upgrade")
	arcade.collect("rapid")
	arcade.starting_time = true
	arcade.starting_freeze = true
	arcade.starting_weapon = "laser"
	arcade.coop = true
	arcade.partner_x = 520.0
	arcade.layout()
	arcade.balls.assign([arcade.make_ball(Vector2(100, 160), 1, -1)])
	arcade.pickups.assign([{"position": Vector2(120, 190), "kind": "time", "age": 2.0}])
	arcade.fire()
	var balls := arcade.balls.duplicate(true)
	var wires := arcade.wires.duplicate(true)
	var pickups := arcade.pickups.duplicate(true)
	var platforms := arcade.platforms.duplicate()
	var rng_state := arcade.rng.state
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	game.queue_free()
	await process_frame
	await open_game()
	game.profile.difficulty = "hard"
	open_arcade()
	expect(arcade.resumed and arcade.phase == BalloonArcade.Phase.PAUSED and arcade.round_index == 1, "Reopening an app resumes the exact round paused")
	expect(arcade.score == 2350 and arcade.round_score == 1800 and arcade.coins == 63 and arcade.round_coins == 51, "Scores, coins and retry baselines survive closing")
	expect(arcade.remaining == 17.25 and arcade.player_x == 246 and arcade.partner_x == 520 and arcade.coop, "Timer and both players survive closing")
	expect(arcade.weapon == "laser" and arcade.weapon_level == 2 and arcade.effects.has("rapid") and arcade.weapon_time == 18, "Active weapon upgrades and drop timers survive closing")
	expect(arcade.starting_time and arcade.starting_freeze and arcade.starting_weapon == "laser", "Purchased supplies survive closing")
	expect(arcade.balls == balls and arcade.wires == wires and arcade.pickups == pickups and arcade.platforms == platforms and arcade.rng.state == rng_state, "Exact balloons, projectiles, pickups, platforms and random state survive closing")
	expect(game.profile.difficulty == "easy", "A saved round retains its original difficulty")
	var remaining := arcade.remaining
	arcade.simulate(1)
	expect(arcade.remaining == remaining and not arcade.left_held and arcade.touches.is_empty(), "Saved-round screen freezes gameplay and clears held input")
	await capture("resume")
	arcade.set_paused(false)
	arcade.simulate(3.0) # Resume countdown does not advance the saved simulation.
	arcade.balls.assign([arcade.make_ball(Vector2(100, 120), 0, 1)])
	arcade.freeze = 30
	arcade.wires.clear()
	arcade.set_control("◀", true)
	expect(arcade.controls.get_child(0).get_meta("control_active"), "Held movement has immediate pressed feedback")
	arcade.set_control("◀", false)
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.pressed = true
	touch.position = arcade.controls.get_child(0).get_global_rect().get_center()
	arcade._input(touch)
	var fire_touch := InputEventScreenTouch.new()
	fire_touch.index = 5
	fire_touch.pressed = true
	fire_touch.position = arcade.controls.get_child(2).get_global_rect().get_center()
	arcade._input(fire_touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = arcade.controls.get_child(1).get_global_rect().get_center()
	arcade._input(drag)
	expect(not arcade.controls.get_child(0).get_meta("control_active") and arcade.controls.get_child(1).get_meta("control_active") and arcade.controls.get_child(2).get_meta("control_active"), "Sliding movement changes direction while the other thumb keeps firing")
	await capture("controls-portrait")
	drag.position = Vector2(0, 0)
	arcade._input(drag)
	expect(not arcade.controls.get_child(1).get_meta("control_active") and "FIRE ↑" in arcade.touches.values(), "Sliding outside movement clears it without releasing fire")
	arcade._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(arcade.phase == BalloonArcade.Phase.PAUSED and arcade.touches.is_empty() and not arcade.controls.get_child(2).get_meta("control_active"), "Backgrounding saves, pauses and clears all touch feedback")
	arcade.set_paused(false)
	arcade.simulate(3.0) # Resume countdown does not advance the saved simulation.
	arcade.balls.assign([arcade.make_ball(Vector2(arcade.partner_x, arcade.floor_y - 35), 0, 1)])
	arcade.freeze = 30
	arcade.simulate(0.01)
	expect(arcade.phase == BalloonArcade.Phase.FAILED, "Frozen balloons still kill either co-op player on contact")
	game.return_to_menu()
	open_arcade()
	expect(arcade.phase == BalloonArcade.Phase.FAILED, "Closing after death retains the retry state")
	arcade.begin_round()
	expect(arcade.coins == 51 and arcade.score == 1800 and arcade.starting_weapon == "laser", "Retrying a saved failure rolls back only the failed attempt")
	var state := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
	expect(not state.is_empty(), "A freshly generated checkpoint validates")
	var bad := state.duplicate(true)
	bad.country_index = 10
	bad.country = route[10]
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "A checkpoint cannot bypass locked scenery")
	bad = state.duplicate(true)
	bad.coins = "broken"
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "Corrupt checkpoint types cannot overwrite live state")
	bad = state.duplicate(true)
	bad.kind = "cinema"
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "Checkpoints cannot cross route kinds")
	bad = state.duplicate(true)
	bad.day = "2000-01-01"
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "A checkpoint cannot cross daily dates")
	bad = state.duplicate(true)
	bad.home = route[1]
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "A checkpoint cannot change the permanent starting country")
	bad = state.duplicate(true)
	bad.wires = [{"kind": "laser", "x": 100.0, "top": 100.0, "bottom": 500.0, "age": 0.0}]
	expect(ArcadeCheckpoint.decode(encode(bad), arcade).is_empty(), "Incomplete projectile state cannot crash a resumed round")
	expect(ArcadeCheckpoint.decode("{}", arcade).is_empty() and ArcadeCheckpoint.decode(JSON.stringify({"size": 200000.0, "data": ""}), arcade).is_empty(), "Malformed and oversized saves are rejected")
	arcade.challenge = "swarm"
	arcade.remaining = 25
	arcade.collect("time")
	expect(arcade.remaining == 13, "Time rewards shorten survival rounds")
	arcade.collect("shrink_time")
	expect(arcade.remaining == 25, "Time curses lengthen survival rounds")
	arcade.coop = false
	arcade.layout()
	arcade.country_index = 0
	arcade.round_index = 2
	arcade.begin_round()
	arcade.balls.clear()
	arcade.simulate(0.01)
	expect(arcade.stamp_pending and arcade.stamp.active and not arcade.panel.visible, "A cleared destination first earns its passport stamp")
	expect(str(arcade.coins) + " coins" in arcade.stats.text and str(arcade.score) + " pts" in arcade.stats.text, "Stamp celebration immediately shows its awarded score and coins")
	await create_timer(0.8).timeout
	await capture("stamp")
	arcade.next_round()
	expect(arcade.country_index == 0 and not arcade.arrival.active, "Travel waits for the stamp celebration")
	arcade.finish_stamp()
	arcade.parcel.reduced_motion = true
	arcade.parcel.open_or_finish()
	arcade.parcel.open_or_finish()
	arcade.next_round()
	arcade.coins = 100
	expect(arcade.buy_upgrade("time") == false and not arcade.buy_upgrade("heart") and not arcade.buy_upgrade("shield"), "Owned time boosts and obsolete protection cannot be bought")
	game.return_to_menu()
	open_arcade()
	expect(arcade.phase == BalloonArcade.Phase.CLEAR and arcade.panel.has_meta("travel") and arcade.coins == 100, "The supply shop and its balance survive leaving")
	var old_backdrop := arcade.backdrop
	arcade.next_round()
	expect(arcade.phase == BalloonArcade.Phase.TRAVEL and not arcade.arrival.artwork.revealed and arcade.backdrop == old_backdrop, "Travel starts with a silhouette over the old location")
	await capture("mystery")
	await create_timer(1.25).timeout
	expect(arcade.arrival.artwork.revealed, "The short arrival animation reveals the earned next scenery")
	await capture("reveal")
	arcade.arrival.finish()
	expect(arcade.country_index == 1 and arcade.round_index == 0 and arcade.backdrop == GameCatalog.backdrop(route[1]), "Arrival starts the next stop exactly once")
	arcade.arrival.finish()
	expect(arcade.country_index == 1, "Repeated arrival signals cannot skip stops")
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	await process_frame
	arcade.set_control("FIRE ↑", true)
	for row in [arcade.controls, arcade.partner_controls]:
		for button in row.get_children():
			expect(button.size.y >= 72 and button.get_global_rect().end.x <= root.size.x, "Phone controls stay large and inside the landscape screen")
	expect(arcade.controls.get_child(2).size.x > arcade.controls.get_child(1).size.x, "Fire has a wider thumb target separated from movement")
	await capture("controls-landscape")
	arcade.coop = true
	arcade.layout()
	expect(arcade.controls.get_global_rect().end.x < arcade.partner_controls.position.x and arcade.arena().end.y < arcade.controls.position.y, "Landscape co-op keeps both control sets apart and below the arena")
	await capture("controls-coop-landscape")
	arcade.coop = false
	arcade.layout()
	var before_resize := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
	game.return_to_menu()
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	await process_frame
	open_arcade()
	expect(arcade.phase == BalloonArcade.Phase.PAUSED and arcade.balls[0].position.is_equal_approx(before_resize.balls[0].position * Vector2(1, arcade.floor_y / before_resize.floor)), "A different orientation rescales saved balloons without restarting")
	game.profile.discoveries.append(daily) # Test fixture: unlock today's scenery for replay.
	game.start_arcade("daily")
	arcade = game.arcade
	arcade.set_physics_process(false)
	arcade.begin_round()
	arcade.coins = 9
	arcade.score = 42
	game.return_to_menu()
	open_arcade()
	expect(arcade.country_index == 1 and arcade.coins == 100 and game.profile.arcade_saves.has("daily:" + GameCatalog.today_utc()), "Switching tours preserves separate world and current daily checkpoints")
	game.return_to_menu()
	game.start_arcade("daily")
	arcade = game.arcade
	arcade.set_physics_process(false)
	expect(arcade.phase == BalloonArcade.Phase.PAUSED and arcade.coins == 9 and arcade.score == 42 and not arcade.coop, "Daily resumes its own fixed solo run")
	arcade.phase = BalloonArcade.Phase.CLEAR
	arcade.round_index = 2
	arcade.next_round()
	expect(not is_instance_valid(game.arcade) and not game.profile.arcade_saves.has("daily:" + GameCatalog.today_utc()), "Finishing a tour removes only its completed checkpoint")
	expect(FileAccess.open(SAVE, FileAccess.READ).get_length() < 262144, "Bounded tour saves remain readable by the profile loader")
	game.queue_free()
	await process_frame
	print("Arcade continuity checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
