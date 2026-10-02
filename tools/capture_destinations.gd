extends SceneTree

var game: Node3D

func _initialize() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	run_capture.call_deferred()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run_capture() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://destination-capture.json"
	root.add_child(game)
	await process_frame
	game.profile.settings.music = 0.0
	game.profile.settings.sound = 0.0
	game.profile.discoveries.clear()
	game.menu.show_countries()
	game.menu.content.get_child(2).text = "Dubai"
	game.menu.content.get_child(2).text_changed.emit("Dubai")
	await process_frame
	var matches := 0
	for child in game.menu.content.get_children():
		if child is Button and child.visible and child.text.begins_with("AE "):
			matches += 1
	assert(matches == 1, "Dubai search finds the UAE destination")
	await capture("29-dubai-search")
	for id in ["DE", "IT", "RU", "CN", "AE", "AU", "NO", "BR", "GR", "ES", "MN", "TH", "KE", "BO", "MX", "JM"]:
		game.return_to_menu()
		game.profile.home_country = id
		game.start_game("world", "easy")
		game.start_preview()
		await create_timer(0.2).timeout
		assert(game.session.current_country() == id)
		await capture("destination-" + id)
	game.return_to_menu()
	game.profile.discover("AE")
	game.menu.show_passport()
	game.menu.content.get_child(2).text = "Dubai"
	game.menu.content.get_child(2).text_changed.emit("Dubai")
	await capture("30-dubai-passport")
	game.menu.show_stickers()
	await capture("31-dubai-sticker")
	game.queue_free()
	await process_frame
	print("Destination rendering and Dubai search checks passed; 19 screenshots captured.")
	quit()
