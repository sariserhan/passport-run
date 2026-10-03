extends SceneTree
var checks := 0
var failures := 0
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-walk-test.json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 game.profile.choose_start_country("FR")
 game.start_arcade("world")
 var arcade: BalloonArcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.freeze = 100
 arcade.invincible = 100
 arcade.mechanic = "stone"
 arcade.set_control("▶",true)
 var x := arcade.player_x
 arcade.simulate(0.1)
 expect(is_equal_approx(arcade.walk_clock, (arcade.player_x-x)*8/110), "Gait follows distance traveled")
 var ordinary_distance := arcade.walk_clock
 arcade.player_x = 360
 arcade.walk_clock = 0
 arcade.collect("boots")
 arcade.simulate(0.1)
 expect(arcade.walk_clock > ordinary_distance, "Quick boots increase cadence")
 arcade.effects.clear()
 arcade.collect("heavy")
 arcade.player_x = 360
 arcade.walk_clock = 0
 arcade.simulate(0.1)
 expect(arcade.walk_clock < ordinary_distance, "Heavy boots slow cadence")
 arcade.effects.clear()
 arcade.player_x = 694
 var before := arcade.walk_clock
 arcade.simulate(0.1)
 expect(arcade.walk_clock == before and arcade.walk_speed == 0, "Pushing against wall does not walk in place")
 arcade.player_x = 360
 arcade.mechanic = "ice"
 arcade.slide_speed = 240
 arcade.set_control("▶",false)
 before = arcade.walk_clock
 arcade.simulate(0.1)
 expect(arcade.walk_clock > before and arcade.walk_speed > 0, "Ice sliding keeps legs animated after release")
 arcade.mechanic = "stone"
 arcade.set_control("▶",true)
 arcade.collect("gun")
 arcade.fire_held = true
 before = arcade.walk_clock
 arcade.simulate(0.1)
 expect(arcade.shot_time > 0 and arcade.walk_clock > before, "Walking continues while firing")
 arcade.set_paused(true)
 before = arcade.walk_clock
 arcade.simulate(0.5)
 expect(arcade.walk_clock == before, "Pause freezes gait")
 arcade.set_paused(false)
 arcade.coop = true
 arcade.layout()
 arcade.begin_round()
 arcade.freeze = 100
 arcade.invincible = 100
 arcade.mechanic = "stone"
 arcade.set_control("P2 ◀",true)
 arcade.simulate(0.1)
 expect(arcade.partner_walk > 0 and arcade.partner_facing < 0, "P2 advances gait and faces left")
 arcade.hit()
 before = arcade.walk_clock
 arcade.simulate(0.1)
 expect(arcade.walk_clock == before and arcade.walk_speed == 0, "A fatal hit stops walking motion")
 expect(arcade.walking_frame(0) == 0 and arcade.walking_frame(7) == 7 and arcade.walking_frame(8) == 0, "Eight-frame cycle loops")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390,844)
  arcade.coop = false
  arcade.layout()
  arcade.begin_round()
  arcade.freeze = 100
  arcade.invincible = 0
  arcade.mechanic = "stone"
  arcade.set_control("▶",true)
  arcade.weapon = "gun"
  arcade.weapon_time = 100
  arcade.fire_held = true
  DirAccess.make_dir_recursive_absolute("/tmp/passport-walk-frames")
  for index in 48:
   if index == 24: arcade.set_control("▶",false); arcade.set_control("◀",true)
   arcade.simulate(1.0/24)
   await process_frame
   await RenderingServer.frame_post_draw
   var capture := root.get_texture().get_image()
   capture.save_png("/tmp/passport-walk-frames/%03d.png" % index)
   if index == 12: capture.save_png("res://artifacts/arcade-walking-v2.png")
 game.queue_free()
 await process_frame
 print("Arcade walk checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
