extends SceneTree
var failures := 0
var checks := 0
var game
var arcade: BalloonArcade
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-return-test.json"
 root.add_child(game)
 await process_frame
 game.profile.settings.sound = 0
 game.start_arcade("world")
 arcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.balls.assign([arcade.make_ball(Vector2(200,100),0,1)])
 arcade.balls[0].armor = 1
 arcade.pop_ball(0)
 expect(arcade.coins == 1 and arcade.particles.size() == 18, "Burst earns spendable coin and stronger particles")
 arcade.phase = BalloonArcade.Phase.CLEAR
 arcade.round_index = 2
 arcade.coins = 100
 arcade.next_round()
 expect(arcade.country_index == 0 and arcade.panel.visible, "Destination clear opens supplies before travel")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390,844)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/arcade-supplies.png")
 expect(arcade.buy_upgrade("heart") and arcade.coins == 70, "Heart purchase deducts exactly its price")
 expect(arcade.buy_upgrade("shield") and arcade.coins == 45, "Shield purchase succeeds")
 expect(arcade.buy_upgrade("laser") and arcade.coins == 5, "Weapon selection spends coins")
 expect(not arcade.buy_upgrade("heart"), "Insufficient balance rejected")
 arcade.travel_choice = "detour"
 arcade.next_round()
 expect(arcade.country_index == 1 and arcade.lives == 1 and arcade.shield and arcade.weapon == "laser", "Travel starts destination with bought supplies")
 expect(arcade.balls[0].armor == 2, "Hard detour has armor")
 arcade.balls.assign([arcade.make_ball(Vector2(200,100),0,1)])
 arcade.balls[0].armor = 1
 arcade.pop_ball(0)
 expect(arcade.coins == 7, "Detour doubles pop coins")
 arcade.fail_round("test")
 arcade.begin_round()
 expect(arcade.coins == 5, "Retry rolls back round coins")
 arcade.balls.assign([arcade.make_ball(Vector2(200,100),1,1)])
 arcade.balls[0].armor = 2
 arcade.pop_ball(0)
 expect(arcade.balls.size() == 1 and arcade.balls[0].armor == 1 and arcade.balls[0].flash > 0, "Armored balloon needs a second hit")
 arcade.pop_ball(0)
 expect(arcade.balls.size() == 2, "Broken armor then splits")
 arcade.balls.assign([arcade.make_ball(Vector2(200,100),1,1)])
 arcade.balls[0].behavior = "timed"
 arcade.balls[0].age = 4.99
 arcade.freeze = 0
 arcade.simulate(0.02)
 expect(arcade.balls.size() == 2, "Timed balloons split without granting pop rewards")
 arcade.balls.assign([arcade.make_ball(Vector2(300,100),0,1,"zigzag")])
 arcade.balls[0].velocity = Vector2.ZERO
 arcade.simulate(0.1)
 expect(arcade.balls[0].position.x != 300, "Zigzag adds lateral weaving")
 arcade.balls.assign([arcade.make_ball(Vector2(300,100),0,1)])
 arcade.balls[0].behavior = "dodge"
 arcade.balls[0].velocity = Vector2.ZERO
 arcade.wires.assign([{"x":310.0,"top":300.0,"bottom":arcade.floor_y,"age":0.0,"kind":"wire"}])
 arcade.simulate(0.01)
 expect(arcade.balls[0].position.x < 300, "Dodge balloon moves away from approaching arrow")
 arcade.coop = true
 arcade.starting_weapon = "wire"
 arcade.begin_round()
 arcade.freeze = 30
 for index in 4:
  arcade.wires.clear()
  arcade.cooldown = 0
  arcade.partner_cooldown = 0
  expect(arcade.fire() and arcade.fire(arcade.partner_x), "Both players can shoot simultaneously")
 expect(arcade.team_charge == 0 and arcade.notice.text.begins_with("TEAM BURST"), "Four synchronized pairs trigger team attack")
 var score_before := arcade.score
 var coins_before := arcade.coins
 arcade.player_down = true
 arcade.partner_x = arcade.player_x
 arcade.simulate(2.1)
 expect(arcade.score == score_before + 500 and arcade.coins == coins_before + 10, "Rescue grants team bonus")
 arcade.wires.clear()
 arcade.cooldown = 0
 arcade.partner_cooldown = 0
 arcade.team_charge = 0
 arcade.last_shooter = -1
 arcade.fire()
 arcade.clock += 0.3
 arcade.fire(arcade.partner_x)
 expect(arcade.team_charge == 0, "Shots outside sync window do not charge")
 arcade.challenge = "no_fire"
 arcade.cooldown = 0
 arcade.partner_cooldown = 0
 expect(not arcade.fire() and not arcade.fire(arcade.partner_x), "Team attack respects no-fire challenge")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(844,390)
  arcade.layout()
  arcade.challenge = ""
  arcade.simulate(0.01)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/arcade-team.png")
 arcade.configure_daily("2026-10-03")
 var daily_route := arcade.route.duplicate()
 var daily_weapon := arcade.starting_weapon
 var modifier := arcade.daily_modifier
 arcade.configure_daily("2026-10-03")
 expect(arcade.route == daily_route and arcade.starting_weapon == daily_weapon and arcade.daily_modifier == modifier, "Daily manifest repeats deterministically")
 game.start_arcade("daily")
 arcade = game.arcade
 arcade.set_physics_process(false)
 expect(arcade.route.size() == 1 and not arcade.coop, "Daily is one free destination in solo mode")
 arcade.begin_round()
 expect(arcade.remaining == 80 and arcade.weapon in BalloonArcade.WEAPONS, "Daily fixed time and weapon")
 var speed_before: Vector2 = arcade.balls[0].velocity
 game.profile.difficulty = "hard"
 arcade.begin_round()
 expect(arcade.balls[0].velocity == speed_before and arcade.remaining == 80, "Daily ignores personal difficulty")
 arcade.round_index = 2
 arcade.begin_round()
 expect(arcade.balls[0].hp == 7, "Daily boss health fixed")
 arcade.round_index = 0
 arcade.begin_round()
 expect(arcade.record_mode().begins_with("balloon-daily:"), "Daily records separate by UTC date")
 arcade.phase = BalloonArcade.Phase.CLEAR
 arcade.round_index = 2
 expect(not arcade.buy_upgrade("heart"), "Daily cannot buy tour upgrades")
 if DisplayServer.get_name() != "headless":
  arcade.phase = BalloonArcade.Phase.PLAY
  arcade.simulate(0.01)
  root.size = Vector2i(390,844)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/arcade-daily.png")
 arcade.score = 12345
 var record_key := arcade.record_mode() + ":moderate"
 game.return_to_menu()
 var restored := PlayerProfile.new(game.save_path)
 expect(restored.records.get(record_key, 0) >= 12345, "Daily score survives profile reload")
 game.queue_free()
 await process_frame
 print("Arcade return checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)
