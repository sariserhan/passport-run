extends SceneTree
var checks := 0
var failures := 0
var game: Node3D
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/balloon-" + name + ".png")
func _initialize() -> void:
 create_timer(90).timeout.connect(func(): quit(1))
 run.call_deferred()
func run() -> void:
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://balloon-test-" + DisplayServer.get_name() + ".json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 root.size = Vector2i(390, 844)
 root.content_scale_size = Vector2i(390, 844)
 game.profile.home_country = "AF"
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 game.menu.show_arcade()
 await capture("menu")
 game.start_arcade("special")
 expect(not is_instance_valid(game.arcade) and game.menu.special_page, "Paid arcade retains Special entitlement gate")
 game.start_arcade("cinema")
 expect(not is_instance_valid(game.arcade) and game.menu.cinema_page, "Cinema arcade has its separate gate")
 game.start_arcade("world")
 var arcade: BalloonArcade = game.arcade
 expect(arcade.route.size() == 250 and arcade.route[0] == "AF", "Arcade visits every free destination from chosen home")
 expect(game.paused and not game.hud.visible, "Arcade isolates memory gameplay")
 expect(arcade.backdrop == GameCatalog.backdrop("AF"), "Arcade uses the same unique destination background")
 await capture("start-map")
 arcade.begin_round()
 arcade.set_physics_process(false)
 expect(arcade.fire(), "Harpoon launches")
 expect(not arcade.fire(), "Basic wire is limited while active")
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.player_x, arcade.floor_y - 50), 2, 1)])
 arcade.simulate(0.01)
 expect(arcade.balls.size() == 2 and arcade.balls[0].tier == 1, "A wire splits a large balloon into two medium balloons")
 expect(arcade.wires.is_empty(), "A hit consumes the harpoon")
 arcade.pop_ball(0)
 expect(arcade.balls.size() == 3 and arcade.balls[-1].tier == 0, "Medium balloons split into small balloons")
 var count := arcade.balls.size()
 arcade.pop_ball(arcade.balls.size() - 1)
 expect(arcade.balls.size() == count - 1, "Small balloons disappear")
 arcade.double_wire = 10
 arcade.cooldown = 0
 expect(arcade.fire(), "Double wire first shot")
 arcade.cooldown = 0
 expect(arcade.fire(), "Double wire second shot")
 arcade.freeze = 2
 var previous: Vector2 = arcade.balls[0].position
 arcade.simulate(0.01)
 expect(arcade.balls[0].position == previous, "Freeze stops balloon motion")
 arcade.set_control("◀", true)
 var player: float = arcade.player_x
 arcade.simulate(0.1)
 expect(arcade.player_x < player, "Held touch control moves the explorer")
 arcade.set_control("◀", false)
 await process_frame
 var move_touch := InputEventScreenTouch.new()
 move_touch.index = 0
 move_touch.pressed = true
 move_touch.position = arcade.controls.get_child(0).get_global_rect().get_center()
 arcade._input(move_touch)
 var fire_touch := InputEventScreenTouch.new()
 fire_touch.index = 1
 fire_touch.pressed = true
 fire_touch.position = arcade.controls.get_child(2).get_global_rect().get_center()
 arcade._input(fire_touch)
 expect(arcade.touches.size() == 2, "Two independent touches can move and fire together")
 move_touch.pressed = false
 arcade._input(move_touch)
 expect(arcade.touches.size() == 1 and "FIRE ↑" in arcade.touches.values(), "Releasing movement keeps the firing finger held")
 fire_touch.pressed = false
 arcade._input(fire_touch)
 expect(arcade.touches.is_empty(), "Touch release clears held controls")
 arcade.set_paused(true)
 var remaining: float = arcade.remaining
 arcade.simulate(1)
 expect(arcade.remaining == remaining and arcade.phase == BalloonArcade.Phase.PAUSED, "Pause freezes timer and simulation")
 arcade.set_paused(false)
 arcade.invincible = 0
 arcade.shield = true
 arcade.hit()
 expect(arcade.lives == 3 and not arcade.shield, "Shield absorbs one collision")
 arcade.hit()
 expect(arcade.lives == 3, "Damage grace prevents repeated hits")
 arcade.invincible = 0
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.player_x, arcade.floor_y - 35), 0, 1)])
 arcade.wires.clear()
 arcade.freeze = 0
 arcade.simulate(0.01)
 expect(arcade.lives == 2, "Actual balloon-player collision removes one life")
 arcade.invincible = 0
 arcade.lives = 1
 arcade.hit()
 expect(arcade.phase == BalloonArcade.Phase.FAILED, "Last hit ends the round")
 arcade.begin_round()
 expect(arcade.score == arcade.round_score and arcade.lives == 3, "Retry rolls back failed-round score")
 arcade.remaining = 0.001
 arcade.simulate(0.01)
 expect(arcade.phase == BalloonArcade.Phase.FAILED, "Timeout ends the round")
 arcade.begin_round()
 arcade.invincible = 0
 arcade.simulate(0.01)
 await capture("play")
 for stage in 3:
  arcade.balls.clear()
  arcade.simulate(0.01)
  expect(arcade.phase == BalloonArcade.Phase.CLEAR, "No balloons means a completed round")
  expect(("AF" in game.profile.discoveries) == (stage == 2), "Only all three rounds award a destination stamp")
  if stage < 2: arcade.next_round()
 await capture("stamped")
 var restored := PlayerProfile.new(game.save_path)
 expect("AF" in restored.discoveries and restored.records.has("balloon:easy"), "Arcade stamp and separate local record persist")
 expect("AF" in restored.daily_progress().countries and not restored.daily_progress().flawless, "Arcade stamps count toward missions without mislabeling a damaged run flawless")
 arcade.next_round()
 expect(arcade.country_index == 1 and arcade.round_index == 0, "Next destination resets round count")
 expect(arcade.backdrop == GameCatalog.backdrop(arcade.route[1]), "Every destination changes arcade scenery")
 expect(game.audio.music_destination == arcade.route[1], "Arcade music follows the destination")
 arcade.round_index = 1
 arcade.begin_round()
 arcade.set_physics_process(false)
 arcade.freeze = 4
 arcade.balls.assign([arcade.make_ball(Vector2(360, arcade.platforms[0].position.y - 60), 0, 1)])
 arcade.fire()
 for step in 12: arcade.simulate(0.1)
 expect(arcade.balls.size() == 1, "A platform blocks the harpoon from hitting a balloon above it")
 arcade.pickups.assign([{"position": Vector2(arcade.player_x, arcade.floor_y - 20), "kind": "shield", "age": 0.0}])
 arcade.simulate(0.01)
 expect(arcade.shield and arcade.pickups.is_empty(), "Walking over a pickup grants its power")
 game.return_to_menu()
 expect(not is_instance_valid(game.arcade) and not game.paused and game.hud.visible, "Exit restores memory-mode controls")
 # Test-only entitlement simulation; no saved premium ownership or checkout bypass.
 game.purchase.unlocked = true
 game.start_arcade("special")
 expect(game.arcade.route.size() == 24 and game.has_paid_access(), "Owned Special pack opens its arcade backgrounds")
 game.purchase.unlocked = false
 game.purchase.changed.emit()
 expect(not is_instance_valid(game.arcade) and game.menu.special_page, "Revoked ownership closes the paid arcade route")
 game.cinema_purchase.unlocked = true
 game.start_arcade("cinema")
 expect(game.arcade.route.size() == 8, "Owned Cinema pack has its own eight-destination tour")
 game.return_to_menu()
 game.cinema_purchase.unlocked = false
 var map := PassportWorldMap.new()
 map.route.assign(["FR", "IT", "ES"])
 map.discoveries.assign(["FR", "IT", "ES"])
 game.menu.content.add_child(map)
 map.size = Vector2(358, 230)
 expect(map.route_segments().size() == 2, "Consecutive pins are connected")
 map.route.assign(["JP", "US"])
 expect(map.route_segments().size() == 2, "Date-line crossing splits into two short lines")
 map.route.assign(["FR", "FR", "FAKE", "IT"])
 expect(map.route_segments().size() == 1, "Duplicate and invalid pins do not add bogus connections")
 game.profile.discover("IT")
 game.profile.discover("ES")
 game.menu.show_world_map()
 await capture("passport-map")
 game.start_game("world", "easy")
 expect(game.run.phase == RunState.Phase.READY, "Memory game remains playable after arcade")
 game.queue_free()
 await process_frame
 print("Balloon and route-map checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
