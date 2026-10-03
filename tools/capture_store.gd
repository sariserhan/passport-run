extends SceneTree

# App Store screenshots at 6.9" iPhone size (1320x2868, 3x of 440x956 logical).
# Isolated save; writes artifacts/store/NN-name.png. Run rendered (not --headless).
const PIXELS := Vector2i(1320, 2868)
var game

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()

func capture(name: String) -> void:
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != PIXELS: image.resize(PIXELS.x, PIXELS.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8) # App Store rejects alpha channels
	image.save_png("res://artifacts/store/%s.png" % name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/store")
	root.size = PIXELS
	root.content_scale_size = PIXELS / 3
	var path := "user://store-capture.json"
	for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path + suffix)
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = path
	root.add_child(game)
	await create_timer(1).timeout
	game.profile.choose_start_country("FR")
	game.profile.tutorial_done = true
	for id in ["FR", "IT", "ES", "JP", "BR", "EG", "IN", "US", "AU"]: game.profile.discover(id)
	game.profile.settings.music = 0.0
	game.profile.settings.sound = 0.0
	game.audio.apply_settings(game.profile.settings)
	game.menu.show_main()
	await capture("01-menu")
	game.start_game("world", "moderate")
	game.start_preview()
	await create_timer(0.4).timeout
	if game.paused: game.resume_game()
	await capture("02-memorize-path")
	game.preview_remaining = 0.001
	while game.run.phase == RunState.Phase.PREVIEW:
		await process_frame
	game.config.jump_seconds = 1.0
	game.choose_tile(0, game.run.safe_lane(0))
	await create_timer(0.35).timeout
	await capture("03-jump")
	game.return_to_menu()
	game.profile.arcade_saves.clear()
	game.start_arcade("world")
	game.arcade.begin_round()
	await create_timer(1.6).timeout
	await capture("04-balloon-tour")
	game.close_arcade()
	game.menu.show_passport()
	await capture("05-passport")
	game.queue_free()
	await process_frame
	print("Store screenshots captured")
	quit()
