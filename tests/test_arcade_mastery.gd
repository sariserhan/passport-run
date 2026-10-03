extends SceneTree

var failures := 0
var checks := 0
var game
var arcade: BalloonArcade
var path := "user://arcade-mastery-" + DisplayServer.get_name() + ".json"

func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 create_timer(120).timeout.connect(func(): quit(1))
 run.call_deferred()

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/realistic-" + name + ".png")

func run() -> void:
 root.size = Vector2i(390, 844)
 root.content_scale_size = root.size
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = path
 root.add_child(game)
 await process_frame
 game.profile.choose_start_country("FR")
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 if DisplayServer.get_name() != "headless": await create_timer(1.0).timeout
 game.start_arcade("world")
 arcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.freeze = 100
 arcade.simulate(0.1)
 expect(is_equal_approx(arcade.country_time, 0.1), "Destination time advances during play")
 arcade.hit()
 expect(arcade.country_retries == 1, "A failed attempt counts toward the destination result")
 arcade.retry_round()
 expect(arcade.country_retries == 1 and arcade.country_time >= 0.1, "Retry retains failed-attempt time and retry count")
 arcade.set_paused(true)
 var elapsed := arcade.country_time
 arcade.simulate(10)
 arcade.set_paused(false)
 arcade.simulate(3)
 expect(arcade.country_time == elapsed, "Pause and countdown do not inflate clear time")
 arcade.balls.assign([arcade.make_ball(Vector2(60, 90), 0, 1)])
 arcade.pickups.clear()
 game.profile.arcade_daily = {"date": GameCatalog.today_utc(), "pops": 29, "bosses": 0, "no_drops": 0}
 arcade.pop_ball(0)
 expect(game.profile.arcade_daily.pops == 30 and arcade.country_combo == 1 and arcade.country_pops == 1, "Pops advance combo statistics and today's goal")
 expect(PlayerProfile.new(path).arcade_daily.pops == 30, "A completed daily goal persists with its pop checkpoint")
 var count: int = game.profile.arcade_drop_journal.size()
 arcade.balls.assign([arcade.make_ball(Vector2(60, 90), 0, 1)])
 arcade.freeze = 100
 arcade.pickups.assign([{"kind": "heavy", "position": Vector2(arcade.player_x, arcade.floor_y - 20), "age": 0.0}])
 arcade.simulate(0.01)
 expect("heavy" in game.profile.arcade_drop_journal and game.profile.arcade_drop_journal.size() == count + 1, "Collecting a real drop reveals only its journal entry")
 var loaded := PlayerProfile.new(path)
 expect("heavy" in loaded.arcade_drop_journal, "Journal discovery persists")
 var saved := ArcadeCheckpoint.decode(loaded.arcade_saves.world, arcade)
 expect(saved.pickups.is_empty(), "The journal checkpoint never restores the already collected drop")
 arcade.collect("heavy")
 expect(game.profile.arcade_drop_journal.size() == count + 1, "Duplicate collections do not duplicate journal pages")
 arcade.collect("bogus")
 expect("bogus" not in game.profile.arcade_drop_journal, "Invalid drops remain hidden")
 arcade.save_checkpoint()
 game.return_to_menu()
 game.menu.show_arcade_drop_journal()
 expect(game.menu.content.get_children().any(func(node): return node is Label and "Heavy boots" in node.text), "The journal shows collected drops")
 expect(not game.menu.content.get_children().any(func(node): return node is Label and "Piercing laser" in node.text), "The journal keeps uncollected effects secret")
 await capture("drop-journal")
 game.start_arcade("world")
 arcade = game.arcade
 arcade.set_physics_process(false)
 expect(arcade.country_retries == 1 and arcade.country_pops == 1 and arcade.country_time >= elapsed, "Destination statistics survive a close and reopen")
 arcade.set_paused(false)
 arcade.simulate(3)
 for stop in 3:
  if stop > 0: game.profile.discover(arcade.route[stop - 1]) # Fixture: each earlier stop is stamped.
  arcade.country_index = stop
  arcade.round_index = 2
  arcade.begin_round()
  var boss: Dictionary = arcade.balls[0]
  var previous: Vector2 = boss.velocity
  arcade.queue_boss_pattern(boss, true)
  expect(boss.warning == 0.85 and boss.velocity == previous and arcade.balls.size() == 1, "Every boss pattern warns before attacking")
  arcade.update_boss_attacks(0.85)
  if stop == 0:
   expect(boss.pattern == "charge" and boss.velocity.x == -previous.x * 1.25 and boss.dash_time > 0, "Sweep boss executes its warned charge")
  elif stop == 1:
   expect(boss.pattern == "bounce" and boss.velocity.y < previous.y and boss.velocity.x == previous.x, "Bounce boss executes a high jump without an unannounced charge")
  else:
   expect(boss.pattern == "summoner" and arcade.balls.size() == 5 and arcade.balls[1].behavior == "dodge", "Summoner calls its distinctive four-minion wave")
   var positions := {}
   for minion in arcade.balls.slice(1): positions[minion.position] = true
   expect(positions.size() == 4, "The summoner's four minions arrive at separate warned positions")
  expect(not boss.bounce_pending and not boss.charge_pending, "Boss attacks execute once")
  arcade.queue_boss_pattern(boss)
  var checkpoint := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
  expect(not checkpoint.is_empty() and checkpoint.balls[0].pattern == boss.pattern, "Every boss pattern and warning can be recovered")
  if stop == 1: await capture("bounce-boss")
  if stop == 2: await capture("swarm-boss")
 arcade.country_index = 0
 arcade.round_index = 0
 arcade.begin_round()
 arcade.country_time = 80
 arcade.country_retries = 0
 arcade.country_combo = 5
 arcade.country_pops = 28
 for round in 3:
  arcade.balls.clear()
  arcade.challenge = ""
  arcade.clear_round()
  if round < 2: arcade.next_round()
 expect(game.profile.arcade_mastery["FR:easy"] == 3, "A fast first-try strong-combo clear earns Gold")
 expect("Clear time: 1:20" in arcade.destination_result() and "Retries: 0" in arcade.destination_result() and "×5" in arcade.destination_result(), "Destination results show time, retries and best combo")
 expect(game.profile.arcade_daily.no_drops == 0, "Collected drops disqualify the no-drop daily goal")
 arcade.finish_stamp()
 await capture("destination-results")
 game.profile.award_arcade_medal("FR", "easy", false, 1)
 game.profile.award_arcade_medal("FR", "moderate", true, 2)
 expect(game.profile.arcade_mastery["FR:easy"] == 3 and game.profile.arcade_mastery["FR:moderate:coop"] == 2, "Mastery never downgrades and difficulty/co-op medals stay separate")
 expect(ArcadeProgress.medal(150, 0, 5) == 3 and ArcadeProgress.medal(151, 0, 5) == 2 and ArcadeProgress.medal(210, 2, 3) == 2 and ArcadeProgress.medal(211, 0, 9) == 1 and ArcadeProgress.medal(-1, 0, 9) == 1, "Medal thresholds and older-save eligibility are explicit")
 var legacy := ArcadeCheckpoint.decode(ArcadeCheckpoint.capture(arcade), arcade)
 for field in ["country_time", "country_retries", "country_combo", "country_pops", "country_start_score"]: legacy.erase(field)
 var bytes := var_to_bytes(legacy)
 var encoded := JSON.stringify({"size": bytes.size(), "data": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_ZSTD))})
 var old_state := ArcadeCheckpoint.decode(encoded, arcade)
 expect(not old_state.is_empty() and old_state.country_time == -1.0, "Old checkpoints remain loadable without inventing a full destination time")
 arcade.country_time = -1.0
 expect("BRONZE" in arcade.destination_result() and "unavailable" in arcade.destination_result(), "Older saved destinations explain their limited medal eligibility")
 arcade.country_time = 80.0
 game.profile.arcade_daily.date = "2000-01-01"
 expect(game.profile.arcade_daily_progress().pops == 0, "Daily goals reset on the next UTC date")
 game.profile.note_arcade_goal("bosses")
 for index in 4: game.profile.note_arcade_goal("bosses")
 expect(game.profile.arcade_daily.bosses == 1, "Daily goals stop at their target")
 game.return_to_menu()
 game.menu.show_arcade_daily_goals()
 await capture("daily-goals")
 game.menu.show_arcade_mastery()
 await capture("mastery")
 game.start_arcade("practice", "FR")
 arcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 var mastery: Dictionary = game.profile.arcade_mastery.duplicate()
 var daily: Dictionary = game.profile.arcade_daily.duplicate()
 var journal: Array[String] = game.profile.arcade_drop_journal.duplicate()
 arcade.balls.assign([arcade.make_ball(Vector2(60,90), 0, 1)])
 arcade.pop_ball(0)
 arcade.collect("laser")
 arcade.round_index = 2
 arcade.clear_round()
 expect(game.profile.arcade_mastery == mastery and game.profile.arcade_daily == daily and game.profile.arcade_drop_journal == journal, "Practice preserves mastery, daily goals and discovery journal")
 game.return_to_menu()
 game.start_arcade("world")
 arcade = game.arcade
 arcade.set_physics_process(false)
 arcade.begin_round()
 arcade.freeze = 100
 game.profile.settings.arcade_swap = true
 game.profile.settings.arcade_large = true
 arcade.layout()
 expect(arcade.controls.get_child(2).position.x == 0 and arcade.control_height() == 88, "Control preferences put the larger fire button on the left")
 for screen in [Vector2i(320,568), Vector2i(390,844), Vector2i(844,390), Vector2i(667,375)]:
  root.size = screen
  root.content_scale_size = screen
  await process_frame
  for team in [false,true]:
   arcade.coop = team
   arcade.layout()
   expect(arcade.notice.get_rect().end.y <= arcade.arena().position.y, "Round instructions stay on the dark header without covering the arena")
   for row in [arcade.controls,arcade.partner_controls] if team else [arcade.controls]:
    for button in row.get_children():
     expect(button.size.y == 88 and row.get_global_rect().encloses(button.get_global_rect()), "Large controls remain inside their safe-area row")
    expect(not row.get_child(0).get_rect().intersects(row.get_child(2).get_rect()), "Swapped fire and movement buttons do not overlap")
  if screen == Vector2i(844,390): await capture("large-landscape-controls")
 root.size = Vector2i(390,844)
 root.content_scale_size = root.size
 arcade.coop = false
 arcade.layout()
 arcade.begin_round()
 arcade.freeze = 100
 arcade.balls.assign([arcade.make_ball(Vector2(100, 100), 2, 1)])
 var tap := InputEventScreenTouch.new()
 tap.pressed = true
 tap.index = 7
 tap.position = arcade.controls.get_child(2).get_global_rect().get_center()
 arcade._input(tap)
 arcade.simulate(0.01)
 expect(arcade.wires.size() > 0 and "FIRE ↑" in arcade.touches.values(), "A tap on the swapped fire button fires the weapon")
 tap.pressed = false
 arcade._input(tap)
 expect(arcade.touches.is_empty(), "Releasing the swapped button clears its touch")
 await capture("gameplay")
 game.profile.save()
 expect(PlayerProfile.new(path).settings.arcade_swap and PlayerProfile.new(path).settings.arcade_large, "Control preferences survive reload")
 var dirty_path := path + ".invalid"
 var dirty := FileAccess.open(dirty_path, FileAccess.WRITE)
 dirty.store_string(JSON.stringify({"version": PlayerProfile.SCHEMA_VERSION, "arcade_mastery": {"FR:easy": 90, "UNKNOWN:easy": 3, "FR:easy:bogus": 2, "FR:hard": "Gold"}, "arcade_drop_journal": ["heavy", "heavy", "bogus", 8], "arcade_daily": {"date": GameCatalog.today_utc(), "pops": -8, "bosses": 90, "no_drops": "complete"}, "settings": {"arcade_swap": "left", "arcade_large": 88}}))
 dirty.close()
 var cleaned := PlayerProfile.new(dirty_path)
 expect(cleaned.arcade_mastery == {"FR:easy": 3} and cleaned.arcade_drop_journal == ["heavy"], "Profile loading rejects unknown mastery keys, invalid types and duplicate journal entries")
 expect(cleaned.arcade_daily.pops == 0 and cleaned.arcade_daily.bosses == 1 and cleaned.arcade_daily.no_drops == 0 and not cleaned.settings.arcade_swap and not cleaned.settings.arcade_large, "Daily counts and control preferences load with bounded types")
 DirAccess.remove_absolute(dirty_path)
 game.return_to_menu()
 game.menu.show_main()
 await capture("menu")
 game.queue_free()
 await process_frame
 print("Arcade mastery/graphics checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)
