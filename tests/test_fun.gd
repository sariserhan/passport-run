extends SceneTree

var game: Node3D
var checks := 0
var failures := 0
var save_path := "user://fun-test-profile" + ("-render" if DisplayServer.get_name() != "headless" else "-headless") + ".json"

func expect(value: bool, description: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(description)

func until(predicate: Callable) -> void:
 var deadline := Time.get_ticks_msec() + 6000
 while not predicate.call() and Time.get_ticks_msec() < deadline:
  await process_frame
  if game.paused: game.resume_game()
 expect(predicate.call(), "Expected gameplay state")

func capture(name: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/fun-" + name + ".png")

func play() -> void:
 if game.run.phase == RunState.Phase.READY: game.start_preview()
 game.preview_remaining = 0.001
 game.config.jump_seconds = 0.005
 await until(func(): return game.run.phase == RunState.Phase.PLAY)

func cross() -> void:
 await play()
 for row in game.config.row_count:
  expect(game.choose_tile(row, game.run.safe_lane(row)), "Short trip accepts safe jump")
  await until(func(): return game.run.phase != RunState.Phase.JUMPING)
 await until(func(): return game.country_awarded)

func _initialize() -> void:
 create_timer(90).timeout.connect(func(): push_error("Fun test deadline"); quit(1))
 run_tests.call_deferred()

func run_tests() -> void:
 root.size = Vector2i(390, 844)
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save_path + suffix)
 var profile := PlayerProfile.new(save_path)
 expect(TravelGoals.earned_covers(profile.discoveries) == ["classic"], "Covers start locked")
 expect(not profile.award_badge("trip:invalid"), "Unknown badges cannot be saved")
 for id in TravelGoals.TRIPS:
  var session := JourneySession.new()
  session.begin("trip", "easy", "", 77, {"route": TravelGoals.TRIPS[id].route})
  expect(session.fixed_route.size() == 3 and session.fixed_route.all(func(country): return country in GameCatalog.FREE_DESTINATIONS), "Every short trip has three free countries")
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = save_path
 root.add_child(game)
 await process_frame
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.menu.show_trips()
 await capture("short-adventures")
 game.menu.show_goals()
 await capture("goals-locked")
 # Replay fixture: short trips are available for destinations already reached.
 game.profile.discoveries.assign(["FR", "IT", "ES"])
 game.trip_id = "europe"
 game.start_game("trip", "easy")
 var seed_value: int = game.session.seed_value
 expect(game.session.fixed_route == ["FR", "IT", "ES"], "Adventure uses selected route")
 await play()
 for row in 3:
  expect(game.choose_tile(row, game.run.safe_lane(row)), "Streak accepts correct jump")
  await until(func(): return game.run.phase != RunState.Phase.JUMPING)
 expect(game.jump_streak == 3 and "STREAK" in game.hud.phase_hint.text, "Correct jumps build visible streak")
 expect(game.audio.effect.pitch_scale > 1, "Streak sound rises in pitch")
 await capture("streak")
 var motion: float = game.environment.atmosphere.clock
 await create_timer(0.08).timeout
 expect(game.environment.atmosphere.clock > motion, "Scenery moves while playing")
 game.pause_game()
 await create_timer(0.06).timeout
 var paused_motion: float = game.environment.atmosphere.clock
 await create_timer(0.06).timeout
 expect(game.environment.atmosphere.clock == paused_motion, "Scenery freezes with gameplay pause")
 game.resume_game()
 game.choose_tile(3, (game.run.safe_lane(3) + 1) % 3)
 await until(func(): return game.run.phase == RunState.Phase.FAILED)
 expect(game.grid.tile_at(3, game.run.safe_lane(3)).state == PathTile.State.REVEALED, "Failure reveals the missed safe tile")
 expect("7 jumps" in game.hud.modal_body.text, "Failure shows distance to stamp")
 expect("FR" in game.failed_countries, "Failure records first-try status")
 await capture("failure")
 game.restart(false, true)
 expect(game.session.seed_value == seed_value and game.session.fixed_route == ["FR", "IT", "ES"], "Immediate retry preserves trip and path")
 for index in 3:
  await cross()
  if index < 2:
   game.travel_to(game.session.choices()[0])
   game.travel.finish()
 expect(game.session.completed_countries == 3 and game.session.choices().is_empty(), "Adventure finishes after exactly three countries")
 expect("trip:europe" in game.profile.badges and "perfect:FR" not in game.profile.badges and "perfect:IT" in game.profile.badges, "Trip and first-try rewards respect failures")
 expect("europe" in TravelGoals.earned_covers(game.profile.discoveries), "Collection earns cosmetic cover")
 expect(game.profile.mission_count() == 3, "Three-country adventure fulfills all daily missions")
 expect(game.profile.daily_progress().countries.size() == 3, "Daily mission counts distinct earned clears")
 game.profile.advance_missions("IT", true, false)
 expect(game.profile.daily_progress().countries.size() == 3, "Repeating a country does not duplicate daily progress")
 expect(not game.profile.award_badge("trip:europe"), "Repeat completion does not duplicate badge")
 await capture("adventure-complete")
 game.profile.passport_cover = "europe"
 game.profile.save()
 var restored := PlayerProfile.new(save_path)
 expect(restored.passport_cover == "europe" and "trip:europe" in restored.badges, "Cover and badges survive profile reload")
 expect(restored.mission_count() == 3, "Daily mission stars survive profile reload")
 game.return_to_menu()
 game.menu.show_goals()
 await capture("goals-earned")
 game.menu.show_passport()
 await capture("passport-cover")
 game.menu.show_souvenirs()
 await capture("souvenirs")
 expect(game.menu.content.get_children().any(func(child): return child is VBoxContainer and child.get_child_count() == 3 and child.get_child(0) is SouvenirCard), "Earned destinations produce souvenir cards")
 game.menu.show_missions()
 await capture("daily-missions")
 expect(game.menu.content.get_children().any(func(child): return child is Label and "DAILY EXPLORER" in child.text), "Completed daily missions show explorer reward")
 root.size = Vector2i(320, 568)
 game.menu.show_souvenirs()
 await capture("souvenirs-small")
 game.menu.show_missions()
 await capture("daily-missions-small")
 root.size = Vector2i(390, 844)
 restored.daily_progress("2000-01-01")
 expect(restored.mission_count() == 0, "UTC rollover resets mission progress")
 game.menu.show_world_map()
 await capture("regional-map")
 expect(TravelGoals.regions(game.profile.discoveries)[GameCatalog.FREE_DESTINATIONS.FR.region].completed >= 1, "Map regional progress derives from discoveries")
 game.profile.settings.reduced_motion = true
 game.start_game("trip", "easy")
 expect(game.environment.atmosphere.reduced_motion, "Reduced motion disables scenery animation")
 game.queue_free()
 await process_frame
 print("Fun-loop checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
