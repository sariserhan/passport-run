extends SceneTree

var game: Node3D
var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): push_error("Polish test timeout"); quit(1))
	run_tests.call_deferred()

func wait(seconds: float = 0.08) -> void:
	await create_timer(seconds).timeout

func run_tests() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://polish-test-profile.json"
	root.add_child(game)
	await wait()
	game.profile.home_country = "FR"
	game.start_game("world", "easy")
	game.start_preview()
	game.preview_remaining = 0.001
	game.config.jump_seconds = 0.005
	await wait()
	for row in game.config.row_count:
		game.choose_tile(row, game.run.safe_lane(row))
		await wait(0.02)
	await wait(0.6)
	var id: String = game.session.choices()[0]
	game.travel_to(id)
	expect(game.travel.active, "Country selection starts travel")
	var index: int = game.session.country_index
	game.travel_to(id)
	expect(game.session.country_index == index, "Repeated departure cannot advance twice")
	expect(not game.choose_tile(0, 0), "Travel blocks tile movement")
	game.pause_game()
	var progress: float = game.travel.flight.value
	await wait(0.15)
	expect(game.paused and game.travel.flight.value == progress, "Pause freezes travel animation")
	game.resume_game()
	await wait(0.1)
	expect(game.travel.root.visible and game.travel.flight.value > progress, "Resume continues travel")
	game.travel.finish()
	await wait()
	expect(not game.travel.active and game.run.phase == RunState.Phase.PREVIEW, "Skip lands once and starts destination preview")
	var generation: int = game.generation
	game.travel.finish()
	expect(game.generation == generation, "Repeated skip cannot reload destination")
	game.travel.begin(id, "JP", false)
	game.return_to_menu()
	await wait(2.1)
	expect(game.menu.root.visible and not game.travel.active, "Ending run cancels pending arrival callback")
	game.start_game("kids", "hard")
	expect(game.traveler.kids, "Kids uses cosmetic explorer robot")
	for country in GameCatalog.COUNTRIES:
		expect(not CountryRewards.fact(country).is_empty(), "Every available country has a verified reward fact")
	game.profile.discover("FR")
	game.menu.show_stickers()
	await wait()
	expect(game.menu.content.get_children().any(func(child): return child is TravelArtwork), "Existing passport discovery unlocks sticker artwork")
	game.profile.settings.reduced_motion = true
	game.menu.root.hide()
	game.travel.begin("FR", "JP", true)
	await wait(0.25)
	expect(not game.travel.active, "Reduced-motion travel finishes quickly")
	game.queue_free()
	await wait()
	print("Polish checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
