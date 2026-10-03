extends SceneTree

var game: Node3D
var checks := 0
var failures := 0
const SAVE := "user://destination-polish-test.json"

func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func until(predicate: Callable) -> void:
 var deadline := Time.get_ticks_msec() + 6000
 while not predicate.call() and Time.get_ticks_msec() < deadline:
  await process_frame
  if game.paused: game.resume_game()
 expect(predicate.call(), "Gameplay reaches expected phase")

func capture(name: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/destination-" + name + ".png")

func _initialize() -> void:
 create_timer(90).timeout.connect(func(): quit(1))
 run.call_deferred()

func run() -> void:
 root.size = Vector2i(390, 844)
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 for id in GameCatalog.DESTINATIONS:
  expect(not DestinationTheme.souvenir(id).is_empty(), "Every destination has a keepsake")
  expect(DestinationTheme.style(id) in DestinationTheme.COLORS, "Every destination has a visual theme")
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = SAVE
 root.add_child(game)
 await process_frame
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 for id in ["NO", "EG", "JP", "TH", "FR"]:
  game.profile.home_country = id
  game.start_game("world", "hard")
  expect(game.grid.tiles[0].theme == DestinationTheme.style(id), "Tiles match the country")
  expect(game.audio.music_destination == id, "Country entry changes the soundtrack")
  expect(game.environment.atmosphere.destination_theme == DestinationTheme.style(id), "Scenery effects match the country")
  game.start_preview()
  for tile in game.grid.tiles:
   var point: Vector2 = game.camera.unproject_position(tile.global_position)
   expect(point.x > 0 and point.x < root.size.x and point.y > 195 and point.y < game.hud.footer_panel.get_global_rect().position.y, "Themed Hard previews fit between HUD panels")
  await capture(id + "-preview")
  game.preview_remaining = 0.001
  game.config.jump_seconds = 0.005
  await until(func(): return game.run.phase == RunState.Phase.PLAY)
  for row in 3:
   var lane: int = game.run.safe_lane(row)
   var point: Vector2 = game.camera.unproject_position(game.grid.position_for(row, lane))
   var ray := PhysicsRayQueryParameters3D.create(game.camera.project_ray_origin(point), game.camera.project_ray_origin(point) + game.camera.project_ray_normal(point) * 1000)
   ray.collision_mask = 1
   var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
   expect(not hit.is_empty() and hit.collider == game.grid.tile_at(row, lane), "Bent/elevated tiles remain reachable by touch ray")
   expect(game.choose_tile(row, lane), "Themed path accepts the next jump")
   await until(func(): return game.run.phase == RunState.Phase.PLAY)
   expect(game.traveler.position.distance_to(game.grid.position_for(row, lane) + Vector3.UP * 0.03) < 0.01, "Traveler lands on the themed stone surface")
  game.decision_remaining = 2.5
  await process_frame
  expect(game.traveler.pressure > 0.65 and game.traveler.reaction.visible, "Character reacts to the cracking stone")
  await create_timer(0.55).timeout
  for lane in game.config.lane_count:
   var target: Vector2 = game.camera.unproject_position(game.grid.position_for(3, lane))
   expect(target.x > 12 and target.x < game.get_viewport().get_visible_rect().size.x - 12, "Every next-row lane remains visible in the follow camera: %s %s" % [id, target])
  await capture(id + "-reaction")
  var time: float = game.traveler.animation_clock
  game.pause_game()
  await create_timer(0.05).timeout
  expect(game.traveler.animation_clock == time, "New personality motion respects pause")
  game.resume_game()
  game.traveler.play_animation("celebrate")
  game.traveler._process(0.15)
  expect(game.traveler.body.rotation.z != 0 or game.traveler.body.position.y != 0, "Theme celebrations animate the character")
  game.return_to_menu()
 game.profile.settings.reduced_motion = true
 game.profile.home_country = "JP"
 game.start_game("world", "easy")
 game.start_preview()
 game.preview_remaining = 0.001
 await until(func(): return game.run.phase == RunState.Phase.PLAY)
 game.decision_remaining = 1.0
 await process_frame
 var body_position: Vector3 = game.traveler.body.position
 await create_timer(0.05).timeout
 expect(game.traveler.body.position == body_position and game.traveler.reaction.visible, "Reduced Motion retains the static warning without fidgeting")
 game.return_to_menu()
 game.start_game("infinite", "easy")
 expect(game.grid.destination_id == "INFINITE" and game.grid.tiles[0].theme == "space", "Infinite has its own themed stones")
 await capture("infinite")
 var old_position: Vector3 = game.grid.position_for(0, 0)
 game.imported_challenge = {"seed": 10, "difficulty": "easy", "route": ["FR"], "target_score": 0, "balance_version": 1}
 game.return_to_menu()
 game.profile.discoveries.append("FR") # Legacy geometry test replays a reached stop.
 game.start_game("challenge", "easy")
 expect(game.grid.layout == "classic" and game.grid.position_for(0, 0).y == 0, "Legacy challenge geometry stays flat")
 expect(old_position != game.grid.position_for(0, 0), "New routes use destination path variation")
 game.queue_free()
 await process_frame
 print("Destination polish checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
