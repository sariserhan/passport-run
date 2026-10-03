extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	var game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://journey-privacy-test.json"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
	root.add_child(game)
	await process_frame
	game.profile.settings.music = 0
	game.profile.settings.sound = 0
	game.audio.apply_settings(game.profile.settings)
	game.start_arcade("world")
	expect(not is_instance_valid(game.arcade) and game.menu.pending_arcade == "world", "A new balloon player must choose a starting country once")
	expect(not game.profile.choose_start_country("MOON"), "Paid places cannot become starting countries")
	for child in game.menu.content.get_children():
		if child is Button and child.get_meta("destination_id", "") == "JP":
			child.pressed.emit()
			break
	var arcade: BalloonArcade = game.arcade
	arcade.set_physics_process(false)
	expect(game.profile.home_country == "JP" and arcade.route[0] == "JP", "Choosing a country saves it and continues the pending balloon tour")
	expect(not game.profile.choose_start_country("FR"), "A second starting-country selection is rejected")
	var restored := PlayerProfile.new(game.save_path)
	expect(restored.home_country == "JP" and not restored.choose_start_country("FR"), "The starting-country lock survives reload")
	var failed_save := PlayerProfile.new("user://missing-privacy-directory/profile.json")
	expect(not failed_save.choose_start_country("JP") and failed_save.home_country.is_empty(), "Failed persistence does not falsely lock a country")
	var route := arcade.route.duplicate()
	expect(route.size() == 250 and route == RoutePlanner.tour("JP"), "The game plans the complete stable route")
	var first_map := arcade.panel.find_children("*", "PassportWorldMap", true, false)[0] as PassportWorldMap
	expect(first_map.route == ["JP"], "The start map reveals no future stops")
	var scenery := arcade.backdrop
	arcade.next_round()
	expect(arcade.country_index == 0 and arcade.round_index == 0 and arcade.backdrop == scenery, "A player cannot advance from the ready screen")
	arcade.begin_round()
	arcade.next_round()
	expect(arcade.country_index == 0 and arcade.round_index == 0, "A player cannot skip an unfinished round")
	for stage in 3:
		arcade.balls.clear()
		if arcade.challenge in ["swarm", "no_fire"]: arcade.remaining = 0
		arcade.simulate(0.01)
		expect(arcade.phase == BalloonArcade.Phase.CLEAR and arcade.backdrop == scenery, "The current scenery remains until its rounds are passed")
		if stage < 2: arcade.next_round()
	arcade.finish_stamp()
	arcade.parcel.reduced_motion = true
	arcade.parcel.open_or_finish()
	arcade.parcel.open_or_finish()
	arcade.next_round()
	expect(arcade.country_index == 0 and arcade.backdrop == scenery, "Travel supplies still shows the completed destination")
	arcade.next_round()
	expect(arcade.phase == BalloonArcade.Phase.TRAVEL and not arcade.arrival.artwork.revealed and arcade.backdrop == scenery, "Travel begins with a mystery silhouette")
	arcade.arrival.finish()
	expect(arcade.country_index == 1 and arcade.backdrop == GameCatalog.backdrop(route[1]), "Only clearing the current destination reveals the next scenery")
	game.return_to_menu()
	game.profile.difficulty = "hard"
	game.start_arcade("world")
	arcade = game.arcade
	arcade.set_physics_process(false)
	expect(arcade.route == route and arcade.country_index == 1, "Leaving and changing difficulty preserves route order and resumes the saved round")
	var resumed_map := arcade.panel.find_children("*", "PassportWorldMap", true, false)[0] as PassportWorldMap
	expect(resumed_map.route == route.slice(0, 2), "The resumed map reveals only reached stops")
	game.return_to_menu()
	game.menu.show_main()
	expect(game.menu.home_button.disabled and "LOCKED" in game.menu.home_button.text, "The main menu cannot change the saved starting country")
	game.menu.show_countries()
	expect(game.menu.home_button.disabled and game.profile.home_country == "JP", "Reopening the picker cannot bypass the lock")
	game.menu.show_settings()
	expect(not game.menu.content.get_children().any(func(child): return child is Button and "CHANGE HOME" in child.text), "Settings contains no change-country action")
	game.menu.show_special_route()
	expect(game.menu.content.find_children("*", "TravelArtwork", true, false).is_empty(), "Undiscovered paid destinations do not leak scenery in pack previews")
	var first := JourneySession.new()
	var second := JourneySession.new()
	first.begin("world", "easy", "JP", 111)
	second.begin("world", "hard", "JP", 222)
	for index in 10:
		expect(first.current_country() == route[index] and second.current_country() == route[index], "Memory tours use the same game-decided route independently of difficulty and path seed")
		first.complete_country(10)
		second.complete_country(20)
		expect(first.choices().size() == 1 and second.choices().size() == 1, "Players receive a single onward destination")
		first.travel_to(first.choices()[0])
		second.travel_to(second.choices()[0])
	if DisplayServer.get_name() != "headless":
		game.menu.show_arcade()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/journey-start-locked.png")
	game.queue_free()
	await process_frame
	print("Journey privacy checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
