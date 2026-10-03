extends SceneTree
var checks := 0
var failures := 0
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func rendered_head_center(rendered: Image, background: Image, region: Rect2i) -> float:
 region = region.intersection(Rect2i(Vector2i.ZERO, rendered.get_size()))
 var left := region.end.x
 var right := region.position.x - 1
 for y in range(region.position.y, region.end.y):
  for x in range(region.position.x, region.end.x):
   var actual := rendered.get_pixel(x, y)
   var original := background.get_pixel(x, y)
   if absf(actual.r - original.r) + absf(actual.g - original.g) + absf(actual.b - original.b) > 0.15:
    left = mini(left, x)
    right = maxi(right, x)
 return float(left + right) / 2 if right >= left else -1.0

func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-turn-test.json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 if DisplayServer.get_name() != "headless": await create_timer(1.0).timeout
 game.profile.choose_start_country("FR")
 game.start_arcade("world")
 var arcade: BalloonArcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.freeze = 100
 arcade.invincible = 100
 arcade.mechanic = "stone"
 expect(is_equal_approx(arcade.side_scale(1), 1) and is_equal_approx(arcade.side_scale(-1), -1), "Side profile is mirrored at completed turns")
 expect(is_equal_approx(arcade.side_scale(0), 1), "Direction changes never squash the character")
 expect(arcade.side_scale(0.25) > 0 and arcade.side_scale(-0.25) < 0, "Turn mirrors the side profile without changing its pose")
 for step in range(0, 9):
  for direction in [-1.0, 1.0]:
   var data := RealisticArt.explorer_frame(step)
   var source := arcade.realistic_source(step)
   var target := arcade.realistic_target(step, 360, direction)
   var anchor := Vector2(data.anchor_x - data.bounds[0], data.head_top - data.bounds[1])
   var sole: float = data.sole - data.bounds[1]
   expect(is_equal_approx(target.position.x + (source.size.x - anchor.x if direction < 0 else anchor.x) / source.size.x * absf(target.size.x), 360), "Every realistic frame keeps its body at the player position")
   expect(is_equal_approx(target.position.y + sole / source.size.y * target.size.y, arcade.floor_y), "Every realistic walking frame stays on the floor")
   expect(is_equal_approx(target.position.y + anchor.y / source.size.y * target.size.y, arcade.floor_y - 132), "Realistic walking and idle frames have no vertical bob")
 arcade.set_control("▶",true)
 arcade.simulate(0.1)
 arcade.set_control("▶",false)
 arcade.set_control("◀",true)
 arcade.simulate(1.0/60)
 expect(arcade.facing < 0 and arcade.visual_facing > -1 and arcade.visual_facing < 1, "Reversal begins a short anchored pivot")
 expect(arcade.slide_speed > 0 and arcade.slide_speed < 240, "Reversal brakes existing momentum before moving left")
 var turning := arcade.visual_facing
 arcade.set_paused(true)
 arcade.simulate(1)
 expect(arcade.visual_facing == turning, "Pause freezes a partial turn")
 arcade.set_paused(false)
 arcade.simulate(3.0) # Resume countdown does not advance the saved simulation.
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
 expect(arcade.visual_facing < partial and arcade.visual_facing > -1, "Rapid direction changes smoothly reverse the ongoing pivot")
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
 expect(arcade.partner_visual_facing > -1 and arcade.partner_visual_facing < 1, "P2 also uses a brief planted-foot turn")
 arcade.simulate(0.3)
 expect(arcade.partner_visual_facing == -1, "P2 turn completes")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390,844)
  root.content_scale_size = Vector2i(390,844)
  await process_frame
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
   if arcade.phase == BalloonArcade.Phase.PAUSED:
    arcade.set_paused(false)
    arcade.simulate(3.0)
   arcade.simulate(1.0/60)
   arcade.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   var capture := root.get_texture().get_image()
   capture.save_png("/tmp/passport-turn-frames/%03d.png" % index)
   if index == 26: capture.save_png("res://artifacts/arcade-turning-smooth.png")
  # Render every atlas frame at one fixed world position in both directions.
  arcade.player_x = -1000
  arcade.shot_time = 0
  arcade.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  var background := root.get_texture().get_image()
  var play := arcade.arena()
  var world_scale := play.size / Vector2(arcade.WORLD.x, arcade.world_height)
  var expected_x := play.position.x + 360 * world_scale.x
  var head_region := Rect2i(Vector2i(play.position + Vector2(280, arcade.floor_y - 132) * world_scale), Vector2i(Vector2(160, 22) * world_scale))
  arcade.player_x = 360
  for direction in [-1.0, -0.5, 0.0, 0.5, 1.0]:
   arcade.visual_facing = direction
   for step in 9:
    arcade.walk_clock = step % 8
    arcade.walk_speed = 0 if step == 8 else 120
    arcade.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    var anchored := root.get_texture().get_image()
    expect(absf(rendered_head_center(anchored, background, head_region) - expected_x) <= 2, "Rendered character stays anchored across gait %d and turn %.2f (offset %.2f)" % [step, direction, rendered_head_center(anchored, background, head_region) - expected_x])
    anchored.save_png("/tmp/passport-turn-frames/anchored-%s-%d.png" % ["left" if direction < 0 else "right", step])
 game.queue_free()
 await process_frame
 print("Arcade turn checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
