extends SceneTree
var failures := 0
var checks := 0
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-difficulty-test.json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 game.profile.choose_start_country("FR")
 game.start_arcade("world")
 var arcade: BalloonArcade = game.arcade
 arcade.set_physics_process(false)
 var previous_speed := 0.0
 var previous_count := 0
 var previous_time := 100.0
 var previous_interval := 10.0
 var previous_hp := 0
 for destination in [0, 4, 12, 24, 60, 120, 249]:
  arcade.country_index = destination
  arcade.round_index = 0
  arcade.begin_round()
  var speed: float = absf(arcade.balls[0].velocity.x)
  expect(speed > previous_speed, "Every later tour stage is faster")
  expect(arcade.balls.size() >= previous_count and arcade.balls.size() <= 6, "Opening balloon pressure rises within a safe bound")
  expect(arcade.remaining <= previous_time and arcade.remaining >= 55, "Time budget tightens with a playable lower bound")
  for ball in arcade.balls:
   expect(ball.position.x >= ball.radius and ball.position.x <= 720 - ball.radius, "Crowded waves spawn inside arena")
  if destination == 24 and DisplayServer.get_name() != "headless":
   root.size = Vector2i(390,844)
   arcade.freeze = 30
   arcade.simulate(0.01)
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/arcade-difficulty.png")
  previous_speed = speed
  previous_count = arcade.balls.size()
  previous_time = arcade.remaining
  arcade.round_index = 2
  arcade.begin_round()
  expect(arcade.balls[0].hp >= previous_hp and arcade.balls[0].hp <= 21, "Boss health escalates within a bound")
  expect(arcade.wave_interval(false) < previous_interval, "Boss reinforcements arrive faster later")
  previous_hp = arcade.balls[0].hp
  previous_interval = arcade.wave_interval(false)
  var hp: int = arcade.balls[0].hp
  var coins_before := arcade.coins
  arcade.fail_round("test")
  arcade.begin_round()
  expect(arcade.balls[0].hp == hp and arcade.coins == coins_before, "Retry preserves level difficulty and coin baseline")
 arcade.country_index = 0
 arcade.round_index = 0
 arcade.begin_round()
 var opening_speed: float = absf(arcade.balls[0].velocity.x)
 arcade.round_index = 1
 arcade.begin_round()
 expect(absf(arcade.balls[0].velocity.x) > opening_speed, "Rounds increase speed within each destination")
 # Test fixture: daily gameplay rules only unlock after reaching the destination.
 game.profile.discover(BalloonArcade.daily_destination(GameCatalog.today_utc()))
 game.start_arcade("daily")
 arcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 expect(arcade.tour_pressure() == 0 and arcade.remaining == 80 and arcade.balls.size() == 1, "Daily retains shared fixed rules")
 game.queue_free()
 await process_frame
 print("Arcade difficulty checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
