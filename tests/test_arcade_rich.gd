extends SceneTree
var checks := 0
var failures := 0
var game: Node3D
var arcade: BalloonArcade
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/arcade-rich-" + name + ".png")
func reset() -> void:
 arcade.begin_round()
 arcade.mechanic = "stone"
 arcade.set_physics_process(false)
 arcade.freeze = 30
 arcade.invincible = 30
 arcade.balls.assign([arcade.make_ball(Vector2(80, 120), 0, 1)])
func _initialize() -> void:
 create_timer(90).timeout.connect(func(): quit(1))
 run.call_deferred()
func run() -> void:
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-rich-" + DisplayServer.get_name() + ".json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 root.size = Vector2i(390,844)
 root.content_scale_size = root.size
 game.profile.home_country = "AF"
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 game.start_arcade("world")
 arcade = game.arcade
 reset()
 for kind in BalloonArcade.WEAPONS:
  reset()
  arcade.collect(kind)
  expect(arcade.fire() and arcade.weapon == kind, "Each weapon can be equipped and fired: " + kind)
  var count := 2 if kind == "double" else 3 if kind == "triple" else 5 if kind == "spread" else 1
  expect(arcade.wires.size() == count, "Weapon produces the correct volley: " + kind)
  if kind == "double": expect(arcade.wires[0].x != arcade.wires[1].x, "Double arrows launch side by side")
  if kind == "gun":
   arcade.simulate(0.01)
   expect(arcade.wires[0].bottom - arcade.wires[0].top == 18, "Gun projectile has a short body rather than a rope")
  await capture(kind)
 reset()
 arcade.collect("sticky")
 arcade.fire()
 for step in 20: arcade.simulate(0.1)
 expect(arcade.wires.size() == 1 and arcade.wires[0].stuck, "Sticky harpoon reaches and holds the ceiling")
 await capture("ceiling-harpoon")
 for step in 35: arcade.simulate(0.1)
 expect(arcade.wires.is_empty(), "Sticky harpoon expires after its ceiling hold")
 reset()
 arcade.collect("gun")
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.player_x, arcade.floor_y - 400), 0, 1)])
 arcade.fire()
 arcade.simulate(0.5)
 expect(arcade.balls.is_empty(), "A fast bullet uses swept collision instead of tunneling through a balloon")
 reset()
 arcade.collect("rocket")
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.player_x, arcade.floor_y - 250), 0, 1), arcade.make_ball(Vector2(arcade.player_x + 45, arcade.floor_y - 250), 0, 1), arcade.make_ball(Vector2(70, 120), 0, 1)])
 arcade.fire()
 arcade.simulate(0.3)
 expect(arcade.balls.size() == 1, "Rocket splash pops nearby balloons without hitting distant ones")
 reset()
 arcade.collect("laser")
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.player_x, arcade.floor_y - 250), 2, 1)])
 arcade.fire()
 arcade.simulate(0.3)
 expect(arcade.balls.size() == 2 and arcade.wires.size() == 1, "Laser pierces rather than disappearing on its first hit")
 reset()
 arcade.collect("double")
 arcade.simulate(18.1)
 expect(arcade.weapon == "wire" and arcade.weapon_time == 0, "Temporary weapons return to the basic harpoon")
 reset()
 arcade.collect("speed")
 var x: float = arcade.balls[0].position.x
 var velocity: float = arcade.balls[0].velocity.x
 arcade.freeze = 0
 arcade.simulate(0.1)
 expect(is_equal_approx(arcade.balls[0].position.x - x, velocity * 0.1 * 1.65), "Speed curse changes actual balloon motion")
 arcade.freeze = 30
 arcade.simulate(8)
 expect(not arcade.effects.has("speed"), "Speed curse wears off")
 reset()
 arcade.collect("multiply")
 expect(arcade.balls.size() == 2, "Multiplication creates extra balloons")
 for step in 7: arcade.collect("multiply")
 expect(arcade.balls.size() <= 40, "Repeated multiplication stays within the phone budget")
 await capture("multiplication")
 reset()
 arcade.collect("reverse")
 arcade.set_control("▶", true)
 var player: float = arcade.player_x
 arcade.simulate(0.1)
 expect(arcade.player_x < player, "Reverse curse changes movement direction")
 arcade.set_control("▶", false)
 reset()
 arcade.collect("jam")
 expect(not arcade.fire(), "Weapon jam temporarily prevents firing")
 arcade.simulate(3.1)
 expect(arcade.fire(), "Firing returns when the jam expires")
 reset()
 arcade.collect("upgrade")
 expect(arcade.weapon == "double" and arcade.weapon_level == 1 and arcade.lives == 1, "Upgrade rewards a stronger weapon while retaining one-hit death")
 var time: float = arcade.remaining
 arcade.collect("time")
 expect(arcade.remaining == time + 12, "Clock adds time")
 arcade.collect("shrink_time")
 expect(arcade.remaining == time, "Bad clock removes time")
 arcade.collect("coin")
 expect(arcade.score >= 750, "Treasure awards bonus points")
 reset()
 arcade.balls.assign([arcade.make_ball(Vector2(200, 150), 2, 1)])
 arcade.collect("bomb")
 expect(arcade.balls.size() == 2 and arcade.balls[0].tier == 1, "Burst bomb splits balloons without gifting a clear")
 reset()
 arcade.pickups.assign([{"position": Vector2(arcade.player_x - 100, arcade.floor_y - 25), "kind": "speed", "age": 0.0}])
 arcade.collect("magnet")
 var pickup_x: float = arcade.pickups[0].position.x
 arcade.simulate(0.1)
 expect(arcade.pickups[0].position.x > pickup_x, "Magnet pulls even risky mystery drops toward the player")
 arcade.pickups.append({"position": Vector2(arcade.player_x + 60, arcade.floor_y - 180), "kind": "gun", "age": 0.0})
 await capture("mystery-drops")
 reset()
 arcade.set_control("▶", true)
 arcade.simulate(0.1)
 var frame := arcade.character_frame()
 arcade.simulate(0.1)
 expect(frame != arcade.character_frame() and arcade.character_frame() < 4, "Walking advances its own animation frames")
 await capture("walking-right")
 arcade.set_control("▶", false)
 arcade.set_control("◀", true)
 arcade.simulate(0.1)
 expect(arcade.facing < 0, "Leftward movement mirrors the walking animation")
 await capture("walking-left")
 arcade.set_control("◀", false)
 arcade.fire()
 expect(arcade.character_frame() in range(4,8), "Harpoon firing uses a throwing animation")
 arcade.simulate(0.1)
 await capture("throwing")
 reset()
 arcade.collect("gun")
 arcade.fire()
 arcade.simulate(0.1)
 expect(arcade.character_frame() in range(8,12), "Gun uses aiming/recoil animation")
 await capture("shooting")
 reset()
 arcade.lives = 1
 arcade.invincible = 0
 arcade.hit()
 expect(arcade.phase == BalloonArcade.Phase.FAILED and arcade.death_time > 0 and not arcade.panel.visible, "Death animates before the retry panel")
 var death_frame := arcade.character_frame()
 arcade.simulate(0.35)
 expect(arcade.character_frame() > death_frame, "Death advances through falling poses")
 await capture("dying")
 arcade.set_paused(true)
 var death_time: float = arcade.death_time
 arcade.simulate(1)
 expect(arcade.death_time == death_time, "Pause freezes death animation")
 arcade.set_paused(false)
 arcade.simulate(1)
 expect(arcade.panel.visible and arcade.death_time == 0, "Retry panel appears after the death sequence")
 arcade.begin_round()
 expect(arcade.weapon == "wire" and arcade.effects.is_empty() and arcade.death_time == 0, "Retry clears all power-ups, curses and death state")
 root.size = Vector2i(320,568)
 root.content_scale_size = root.size
 await process_frame
 arcade.show_panel("MYSTERY BALLOON TOUR", "PLAY", arcade.begin_round)
 await capture("small-phone")
 arcade.begin_round()
 root.size = Vector2i(844,390)
 root.content_scale_size = root.size
 await process_frame
 expect(arcade.world_height > 300, "Landscape layout preserves enough logical height for play")
 await capture("landscape")
 game.queue_free()
 await process_frame
 print("Rich arcade checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
