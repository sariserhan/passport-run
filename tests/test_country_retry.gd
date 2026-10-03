extends SceneTree
const SAVE := "user://country-retry-test.json"
var game: Node3D
var failures := 0
var checks := 0
func _initialize() -> void:
 create_timer(120).timeout.connect(func(): push_error("Country retry timed out"); quit(1))
 run_all.call_deferred()
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: failures += 1; push_error(message)
func frames(count: int = 3) -> void:
 for i in count:
  await process_frame
  if game and game.paused: game.resume_game()
func play() -> void:
 if game.travel.active: game.travel.finish()
 if game.run.phase == RunState.Phase.READY: game.start_preview()
 game.preview_remaining = 0.001
 await frames(5)
 game.config.jump_seconds = 0.001
 game.config.crack_seconds = 0.001
 game.config.fall_seconds = 0.001
 check(game.run.phase == RunState.Phase.PLAY, "Country preview leads to play")
func complete() -> void:
 await play()
 for row in game.config.row_count:
  check(game.choose_tile(row, game.run.safe_lane(row)), "Safe jump accepted")
  for i in 60:
   await frames(1)
   if game.run.phase != RunState.Phase.JUMPING: break
 for i in 300:
  await frames(1)
  if game.country_awarded: break
 check(game.country_awarded, "Country stamped through actual play")
func fail() -> void:
 await play()
 game.choose_tile(0, (game.run.safe_lane(0) + 1) % game.config.lane_count)
 for i in 60:
  await frames(1)
  if game.run.phase == RunState.Phase.FAILED: break
 check(game.run.phase == RunState.Phase.FAILED, "Wrong jump reaches failure results")
func run_all() -> void:
 root.size = Vector2i(390, 844)
 for suffix in ["", ".tmp", ".bak", ".events"]: DirAccess.remove_absolute(SAVE + suffix)
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = SAVE
 root.add_child(game)
 await frames()
 game.profile.home_country = "DK"
 game.profile.settings.reduced_motion = true
 game.profile.save()
 game.start_game("world", "easy")
 await complete()
 check(game.session.choices() == ["DE"], "Denmark's next guided stop is Germany")
 game.menu.show_main()
 check(game.menu.mode_buttons.world.text == "CONTINUE WORLD TOUR", "Saved progress offers Continue World Tour")
 var resumed := JourneySession.new()
 resumed.begin("world", "easy", "DK", 88)
 resumed.resume_world(game.profile.discoveries)
 check(resumed.current_country() == "DE", "Saved Denmark completion resumes World Tour in Germany")
 check(resumed.banked_tiles == 0 and resumed.completed_countries == 0, "Resume does not invent scores for earlier completed countries")
 check(resumed.challenge_route() == ["DE"], "Resumed challenge excludes countries from earlier sessions")
 var decoded := ChallengeCode.decode(ChallengeCode.encode(resumed.challenge_seed(), "easy", resumed.challenge_route(), 0))
 var friend := JourneySession.new()
 friend.begin("challenge", "easy", "DK", 1, decoded)
 check(friend.current_country() == "DE" and friend.path_seed() == resumed.path_seed(), "Resumed challenge replays Germany with the exact seed")
 var denmark_timings: Array = game.friend_steps.duplicate()
 var denmark_count: int = game.profile.souvenir_counts.DK
 game.menu.root.hide()
 game.travel_to("DE")
 check(game.travel.active, "Denmark completion permits travel to Germany")
 await fail()
 var path: Array = game.run.path.duplicate()
 var seed: int = game.run.path_seed
 game.hud.retry_requested.emit()
 check(game.session.current_country() == "DE", "Try Again stays in Germany")
 check(game.session.country_index == 1 and game.session.banked_tiles == 10 and game.session.completed_countries == 1, "Retry preserves cleared Denmark and banked tiles")
 check(game.run.completed_rows == 0 and game.run.path == path and game.run.path_seed == seed, "Retry resets German steps and preserves its path")
 check(game.completed_stops == ["DK"], "Retry preserves journey recap history")
 check(game.friend_steps == denmark_timings, "Retry retains timings from the cleared country")
 await fail()
 game.hud.retry_requested.emit()
 check(game.session.current_country() == "DE" and game.run.path == path, "Repeated failure still stays in Germany")
 if DisplayServer.get_name() != "headless":
  await frames()
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/germany-retry.png")
 await complete()
 check(game.profile.discoveries == ["DK", "DE"], "Cleared Germany adds its own stamp")
 check(game.profile.souvenir_counts.DK == denmark_count, "Retries do not recollect Denmark's souvenir")
 check(game.session.banked_tiles == 20 and game.completed_stops == ["DK", "DE"], "German clear advances the same journey")
 game.return_to_menu()
 game.start_game("world", "easy")
 check(game.session.current_country() not in ["DK", "DE"] and game.profile.can_visit(game.session.current_country()), "World Tour menu resumes after both saved countries")
 check(game.session.banked_tiles == 0, "New tour session starts its own score")
 for mode in ["kids", "trip", "special", "cinema", "expedition"]:
  game.session.begin(mode, "easy", "DK", 44, {"route": ["DK", "DE"]})
  if mode in ["special", "cinema"]: game.session.fixed_route.assign(["DK", "DE"])
  if mode == "kids":
   game.session.complete_country(6)
   game.session.travel_to("DE")
  else:
   game.session.complete_country(10)
   game.session.country_index = 1
  game.run.phase = RunState.Phase.FAILED
  game.completed_stops.assign(["DK"])
  var previous_seed: int = game.session.path_seed()
  game.restart(false, false)
  check(game.session.current_country() == "DE" and game.session.country_index == 1, mode + " retry retains current destination")
  check(game.run.path_seed == previous_seed and game.completed_stops == ["DK"], mode + " retry keeps seed and journey history")
 # Ranked modes preserve their full-run retry behavior and score accounting.
 game.profile.discoveries.assign(GameCatalog.COUNTRIES.keys())
 for mode in ["daily", "challenge", "infinite"]:
  if mode == "challenge": game.imported_challenge = {"seed": 333, "difficulty": "easy", "route": ["DK", "DE"], "target_score": 0, "balance_version": 3}
  game.start_game(mode, "easy")
  if mode != "infinite": game.session.country_index = 1
  game.run.phase = RunState.Phase.FAILED
  var previous_seed: int = game.session.seed_value
  game.restart(false, false)
  check(game.session.country_index == 0 and game.session.seed_value == previous_seed, mode + " scored retry resets the full run")
 game.queue_free()
 await frames()
 for suffix in ["", ".tmp", ".bak", ".events"]: DirAccess.remove_absolute(SAVE + suffix)
 print("Country retry checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
