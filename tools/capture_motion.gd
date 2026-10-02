extends SceneTree

const OUTPUT := "/private/tmp/passport-motion-frames"
var game: Node3D
var frame_index := 0

func _initialize() -> void:
	create_timer(40).timeout.connect(func(): quit(1))
	capture_demo.call_deferred()

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func record(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if game.paused:
			game.resume_game()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + "/frame-%04d.png" % frame_index)
		frame_index += 1
		await wait(1.0 / 30.0)

func begin_play() -> void:
	game.start_game("world", "easy")
	game.start_preview()
	game.preview_remaining = 0.001
	await wait(0.7)
	if game.paused:
		game.resume_game()

func capture_demo() -> void:
	root.size = Vector2i(390, 844)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://motion-capture-profile.json"
	root.add_child(game)
	await wait(0.2)
	game.profile.home_country = "FR"
	await begin_play()
	await record(3.2)
	assert(game.choose_tile(0, game.run.safe_lane(0)))
	await record(0.65)
	assert(game.choose_tile(1, (game.run.safe_lane(1) + 1) % 3))
	await record(1.55)
	await begin_play()
	game.config.jump_seconds = 0.005
	for row in game.config.row_count:
		assert(game.choose_tile(row, game.run.safe_lane(row)))
		while game.run.phase == RunState.Phase.JUMPING:
			await process_frame
	await record(3.1)
	assert(game.country_awarded)
	game.queue_free()
	await process_frame
	print("Captured ", frame_index, " rendered motion frames to ", OUTPUT)
	quit()
