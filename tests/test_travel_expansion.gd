extends SceneTree

var game: Node3D
var checks := 0
var failures := 0
var save := "user://travel-expansion" + ("-render" if DisplayServer.get_name() != "headless" else "-headless") + ".json"

func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func until(predicate: Callable) -> void:
 var end := Time.get_ticks_msec() + 6000
 while not predicate.call() and Time.get_ticks_msec() < end:
  await process_frame
  if game.paused: game.resume_game()
 expect(predicate.call(), "Expected gameplay state")

func capture(name: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/expansion-" + name + ".png")

func play_adventure(id: String) -> void:
 # Replay fixture: these mechanics are tested after reaching their scenery.
 if id not in game.profile.discoveries: game.profile.discoveries.append(id)
 game.adventure_start = id
 game.start_game("adventure", "easy")
 expect(game.travel.active and game.run.phase == RunState.Phase.READY, "Adventure starts with a cinematic arrival")
 game.start_preview()
 expect(game.run.phase == RunState.Phase.READY, "Arrival blocks memorization until landing")
 await capture("arrival-" + id)
 game.travel.finish()
 game.preview_remaining = 0.001
 game.config.jump_seconds = 0.01
 await until(func(): return game.run.phase == RunState.Phase.PLAY)

func _initialize() -> void:
 create_timer(90).timeout.connect(func(): quit(1))
 run.call_deferred()

func run() -> void:
 root.size = Vector2i(390, 844)
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save + suffix)
 var profile := PlayerProfile.new(save)
 expect(not CharacterStyle.unlocked("outfit", "trail", profile.discoveries), "Cosmetics start locked")
 for id in ["FR", "IT", "ES"]: profile.discover(id)
 profile.character_style = {"outfit": "trail", "hat": "sun", "backpack": "europe"}
 profile.room_display.assign(["FR", "IT", "ES", "FAKE"])
 profile.save()
 var restored := PlayerProfile.new(save)
 expect(restored.character_style == profile.character_style and restored.room_display == ["FR", "IT", "ES"], "Earned customization and valid room selections persist")
 profile.character_style.outfit = "cosmic"
 profile.save()
 expect(PlayerProfile.new(save).character_style.outfit == "classic", "Unearned saved cosmetics cannot be equipped")
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = save
 root.add_child(game)
 await process_frame
 game.profile.character_style.outfit = "trail"
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 game.menu.show_room()
 await capture("travel-room")
 expect(game.menu.content.get_children().any(func(child): return child is SouvenirRoom and child.get_child_count() == 3), "Travel room displays selected earned souvenirs")
 game.menu.show_wardrobe()
 await create_timer(0.15).timeout
 await capture("wardrobe")
 game.menu.show_adventures()
 await capture("adventures")
 await play_adventure("NO")
 var before: float = game.traveler.position.x
 await create_timer(0.12).timeout
 expect(game.traveler.position.x > before, "Ice causes real drift while deciding")
 expect(game.traveler.customization.hat == "sun", "Equipped cosmetics appear in gameplay")
 game.return_to_menu()
 await play_adventure("BR")
 expect(game.grid.moving, "Bridge adventure enables moving targets")
 var tile_before: Vector3 = game.grid.tile_at(0, 0).position
 await create_timer(0.12).timeout
 expect(game.grid.tile_at(0, 0).position != tile_before, "Bridge tiles physically move")
 await physics_frame
 var target = game.grid.tile_at(0, game.run.safe_lane(0))
 var screen = game.camera.unproject_position(target.global_position)
 var origin = game.camera.project_ray_origin(screen)
 var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + game.camera.project_ray_normal(screen) * 350, 1))
 expect(hit.get("collider") == target, "Moving bridge retains touch ray selection")
 for row in 2:
  expect(game.choose_tile(row, game.run.safe_lane(row)), "Moving bridge accepts a chosen lane")
  await until(func(): return game.run.phase == RunState.Phase.PLAY)
 expect(game.run.completed_rows == 2, "Moving bridge lands on selected moving surfaces")
 var motion: float = game.grid.motion_clock
 game.pause_game()
 await create_timer(0.06).timeout
 expect(game.grid.motion_clock == motion, "Pause freezes adventure targets")
 game.resume_game()
 await create_timer(0.55).timeout
 await capture("moving-bridge")
 game.return_to_menu()
 game.adventure_start = "MOON"
 game.start_game("adventure", "easy")
 expect(game.menu.special_page and not game.purchase.unlocked, "Moon mechanics retain the paid route gate")
 # Test-only entitlement; no saved premium flag or production checkout bypass.
 game.purchase.unlocked = true
 game.profile.discoveries.append("MOON")
 game.start_game("adventure", "easy")
 expect(game.config.jump_height == 3.0 and game.config.jump_seconds == 0.75, "Moon adventure uses higher, longer jumps")
 await capture("arrival-MOON")
 game.travel.finish()
 game.preview_remaining = 0.001
 await until(func(): return game.run.phase == RunState.Phase.PLAY)
 game.choose_tile(0, game.run.safe_lane(0))
 await create_timer(0.3).timeout
 await capture("moon-jump")
 game.return_to_menu()
 var route: Array[String] = ["FR"]
 var timings: Array[int] = [10, 30, 20]
 var code := ChallengeCode.encode(52, "easy", route, 3, 3, timings)
 var link := ChallengeCode.link(code)
 var decoded := ChallengeCode.decode(link)
 expect(decoded.get("ghost") == timings, "Self-contained app link preserves path and friend timing")
 expect(ChallengeCode.decode("passport-run://challenge/garbage").is_empty(), "Malformed app links are rejected")
 var invalid := decoded.duplicate(true)
 invalid.ghost = [10000]
 expect(ChallengeCode.decode("PR1." + Marshalls.utf8_to_base64(JSON.stringify(invalid))).is_empty(), "Impossible ghost decision times are rejected")
 expect(game.open_challenge_link(link) and game.menu.challenge_input.text == link, "App link opens reviewable challenge import")
 game.imported_challenge = decoded
 game.start_game("challenge", "easy")
 game.start_preview()
 game.preview_remaining = 0.001
 await until(func(): return game.run.phase == RunState.Phase.PLAY)
 await create_timer(0.6).timeout
 expect(game.ghost.progress > 0 and not game.ghost.actor.visible, "A ghost ahead never exposes a future safe lane")
 for row in 3:
  game.choose_tile(row, game.run.safe_lane(row))
  await until(func(): return game.run.phase == RunState.Phase.PLAY)
 expect(game.friend_steps.size() == 3, "Successful steps create a shareable ghost replay")
 await create_timer(0.2).timeout
 expect(game.ghost.actor.visible and game.ghost.progress <= game.run.completed_rows, "Ghost appears only on already visited safe stones")
 await capture("friend-ghost")
 game.pause_game()
 var clock: float = game.ghost.clock
 await create_timer(0.05).timeout
 expect(game.ghost.clock == clock, "Ghost race respects pause")
 game.resume_game()
 game.return_to_menu()
 game.profile.settings.reduced_motion = true
 game.travel.begin("FR", "EVEREST", true, true)
 expect(game.travel.artwork.zoom == 1.0, "Reduced Motion disables cinematic zoom")
 game.travel.cancel()
 game.queue_free()
 await process_frame
 print("Travel expansion checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
