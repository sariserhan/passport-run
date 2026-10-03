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
 game.save_path = "user://arcade-turn-test.json"
 root.add_child(game)
 await process_frame
 game.start_arcade("world")
 var arcade: BalloonArcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.freeze = 100
 arcade.invincible = 100
 arcade.mechanic = "stone"
 expect(is_equal_approx(arcade.side_scale(1), 1) and is_equal_approx(arcade.side_scale(-1), -1), "Side profile is mirrored at completed turns")
 expect(is_equal_approx(arcade.side_scale(0), 0.85), "Mid-turn keeps the side profile visible without displaying a front pose")
 expect(arcade.side_scale(0.25) > 0 and arcade.side_scale(-0.25) < 0, "Turn mirrors the side profile without changing its pose")
 arcade.set_control("▶",true)
 arcade.simulate(0.1)
 arcade.set_control("▶",false)
 arcade.set_control("◀",true)
 arcade.simulate(1.0/60)
 expect(arcade.facing < 0 and arcade.visual_facing > 0 and arcade.visual_facing < 1, "Reversal starts intermediate turn instead of snapping")
 expect(arcade.slide_speed > 0 and arcade.slide_speed < 240, "Reversal brakes existing momentum before moving left")
 var turning := arcade.visual_facing
 arcade.set_paused(true)
 arcade.simulate(1)
 expect(arcade.visual_facing == turning, "Pause freezes a partial turn")
 arcade.set_paused(false)
 arcade.set_control("◀",true)
 arcade.simulate(0.3)
 expect(arcade.visual_facing == -1 and arcade.slide_speed < 0, "Turn completes with leftward motion")
 arcade.set_control("◀",false)
 arcade.set_control("▶",true)
 arcade.simulate(0.03)
 var partial := arcade.visual_facing
 arcade.set_control("▶",false)
 arcade.set_control("◀",true)
 arcade.simulate(0.02)
 expect(arcade.visual_facing < partial and arcade.visual_facing > -1, "Rapid direction change reverses an ongoing turn smoothly")
 game.profile.settings.reduced_motion = true
 arcade.set_control("◀",false)
 arcade.set_control("▶",true)
 arcade.simulate(0.01)
 expect(arcade.visual_facing == 1, "Reduced Motion skips supplementary rotation")
 game.profile.settings.reduced_motion = false
 arcade.coop = true
 arcade.layout()
 arcade.begin_round()
 arcade.freeze = 100
 arcade.set_control("P2 ◀",true)
 arcade.simulate(0.02)
 expect(arcade.partner_visual_facing > -1 and arcade.partner_visual_facing < 1, "P2 also smoothly flips its side profile")
 arcade.simulate(0.3)
 expect(arcade.partner_visual_facing == -1, "P2 turn completes")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390,844)
  arcade.coop = false
  arcade.layout()
  arcade.begin_round()
  arcade.mechanic = "stone"
  arcade.freeze = 100
  arcade.invincible = 0
  arcade.set_control("▶",true)
  DirAccess.make_dir_recursive_absolute("/tmp/passport-turn-frames")
  for index in 72:
   if index == 24: arcade.set_control("▶",false); arcade.set_control("◀",true)
   if index == 48: arcade.set_control("◀",false); arcade.set_control("▶",true)
   arcade.simulate(1.0/60)
   await process_frame
   await RenderingServer.frame_post_draw
   var capture := root.get_texture().get_image()
   capture.save_png("/tmp/passport-turn-frames/%03d.png" % index)
   if index == 30: capture.save_png("res://artifacts/arcade-turning.png")
 game.queue_free()
 await process_frame
 print("Arcade turn checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
