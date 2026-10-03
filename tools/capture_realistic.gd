extends SceneTree

var game

func _initialize() -> void:
 create_timer(60).timeout.connect(func(): quit(1))
 run.call_deferred()

func capture(name: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/realistic-" + name + ".png")

func run() -> void:
 root.size = Vector2i(390, 844)
 root.content_scale_size = root.size
 var path := "user://realistic-capture.json"
 for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path + suffix)
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = path
 root.add_child(game)
 await create_timer(1).timeout
 game.profile.choose_start_country("FR")
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 game.start_game("world", "easy")
 game.start_preview()
 await create_timer(0.2).timeout
 if game.paused: game.resume_game()
 assert(game.traveler.portrait.texture.resource_path == "res://assets/realistic/memory-explorer.png")
 await capture("memory-france")
 game.return_to_menu()
 game.start_game("kids", "easy")
 game.start_preview()
 await create_timer(0.2).timeout
 if game.paused: game.resume_game()
 assert(game.traveler.portrait.texture.resource_path == "res://assets/realistic/robot-explorer.png")
 await capture("kids-explorer")
 game.return_to_menu()
 game.start_game("infinite", "easy")
 game.start_preview()
 await create_timer(0.2).timeout
 if game.paused: game.resume_game()
 await capture("infinite")
 game.return_to_menu()
 for id in ["TH", "AF", "NZ", "AD"]:
  # Dedicated QA profile: override its start to inspect geographically varied scenes.
  game.profile.home_country = id
  game.profile.arcade_saves.clear()
  game.start_arcade("world")
  game.arcade.set_physics_process(false)
  game.arcade.begin_round()
  game.arcade.queue_redraw()
  await capture("destination-" + id)
  game.return_to_menu()
 game.queue_free()
 await process_frame
 print("Realistic memory/Kids/Infinite and destination captures passed.")
 quit()
