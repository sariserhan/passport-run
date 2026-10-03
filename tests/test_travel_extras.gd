extends SceneTree
const SAVE := "user://travel-extras-test.json"
var checks := 0
var failures := 0
var game: Node3D
var render := false
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: failures += 1; push_error(message)
func _initialize() -> void:
 create_timer(150).timeout.connect(func(): push_error("Travel extras timed out"); quit(1))
 run_all.call_deferred()
func frames(count: int = 3) -> void:
 for i in count:
  await process_frame
  if game and game.paused: game.resume_game()
func capture(name: String) -> void:
 if render:
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/extras-" + name + ("-small" if root.size.y < 800 else "") + ".png")
func clean_files() -> void:
 for slot in 4:
  var path := SAVE if slot == 0 else SAVE + ".player" + str(slot)
  for suffix in ["", ".bak", ".tmp", ".restore", ".before-restore", ".events"]: DirAccess.remove_absolute(path + suffix)
func prepare_play() -> void:
 if game.paused: game.resume_game()
 if game.travel.active: game.travel.finish()
 if game.run.phase == RunState.Phase.READY: game.start_preview()
 game.preview_remaining = 0.001
 await frames(4)
 check(game.run.phase == RunState.Phase.PLAY, "Arrival and preview lead to playable stage")
 game.config.jump_seconds = 0.001
func finish_country() -> void:
 await prepare_play()
 while game.run.phase == RunState.Phase.PLAY:
  var lane: int = game.run.safe_lane(game.run.completed_rows)
  if game.paused: game.resume_game()
  if not game.choose_tile(game.run.completed_rows, lane):
   check(false, "Safe next tile rejected: paused=%s, decision=%s, phase=%s" % [game.paused, game.decision_remaining, game.run.phase])
   break
  for i in 60:
   await process_frame
   if game.paused: game.resume_game()
   if game.run.phase != RunState.Phase.JUMPING: break
 for i in 300:
  await process_frame
  if game.country_awarded: break
 check(game.country_awarded, "Actual jumps stamp the destination")
func run_all() -> void:
 render = DisplayServer.get_name() != "headless"
 root.size = Vector2i(375, 667) if "--small" in OS.get_cmdline_user_args() else Vector2i(390, 844)
 clean_files()
 var profile := PlayerProfile.new(SAVE)
 profile.home_country = "FR"
 profile.save()
 check(not TravelExtras.unlocked(profile, "secret", "rooftop"), "Secret viewpoint locked before city clear")
 check(not profile.craft_extra("lantern"), "Crafting requires materials and stamps")
 check(profile.accept_character("mira"), "Character request accepted")
 check(not profile.accept_character("mira"), "Duplicate request cannot erase progress")
 for id in ["FR", "JP", "US", "CH", "IT", "PT", "NO", "FI", "KR", "ES", "EG"]: profile.discover(id)
 for id in ["FR", "JP", "US", "NO", "PT"]: profile.note_completion(id, "easy", true)
 check(profile.extras.characters.mira.rewarded, "Character request rewarded after later travel")
 check(profile.activities.rewards.has("character:mira"), "Character reward belongs to collection")
 check(profile.extras.materials == 5, "Real completion earns crafting materials")
 check(profile.craft_extra("lantern") and profile.extras.materials == 2, "Craft consumes exactly recipe cost")
 check(not profile.craft_extra("lantern") and profile.extras.materials == 2, "Crafted item cannot double-charge")
 profile.room_display.assign(["FR", "JP"])
 profile.room_positions = {"FR": [0.2, 0.7]}
 profile.room_decor.wallpaper = "sky"
 check(profile.save_room_preset("Riverside"), "Preset saves arrangement")
 profile.room_display.assign(["US"])
 profile.room_decor.wallpaper = "sand"
 profile.extras.ornament = "none"
 check(profile.apply_room_preset(0) and profile.room_display == ["FR", "JP"] and profile.extras.ornament == "lantern", "Preset restores keepsakes and crafted decor")
 check(profile.room_positions.FR == [0.2, 0.7] and profile.room_decor.wallpaper == "sky", "Preset restores exact positions and decor")
 check(not profile.finish_extra_stage("city", "paris", "JP"), "Cannot earn stage reward for wrong country")
 var loaded := PlayerProfile.new(SAVE)
 check(loaded.extras.crafted == ["lantern"] and loaded.extras.characters.mira.rewarded, "Crafting and requests persist")
 var backup := PassportBackup.export_text(loaded)
 check(not PassportBackup.inspect(backup).is_empty(), "Portable backup validates")
 check(not PassportBackup.restore(loaded, '{"format":"bad"}'), "Invalid backup leaves progress intact")
 loaded.extras.materials = 88
 loaded.save()
 check(PassportBackup.restore(loaded, backup), "Valid backup restores through validated profile")
 var restored := PlayerProfile.new(SAVE)
 check(restored.extras.materials == 2 and restored.discoveries == profile.discoveries, "Backup restores passport and materials")
 check(restored.read_valid(SAVE + ".bak").extras.materials == 88, "Pre-restore save preserved in backup")
 restored.save()
 check(restored.read_valid(SAVE + ".before-restore").extras.materials == 88, "Previous restore remains recoverable after later saves")
 check(restored.anonymous_id == loaded.anonymous_id, "Restore preserves this device identity")
 var oversized := JSON.stringify({"format": PassportBackup.FORMAT, "profile": {"version": 1, "discoveries": ["FR"], "padding": "x".repeat(PlayerProfile.MAX_PROFILE_BYTES)}})
 check(not PassportBackup.restore(restored, oversized), "Oversized profile cannot silently restore an empty passport")
 var bad := TravelExtras.clean({"materials": -9, "completed": ["secret:fake"], "crafted": ["fake"], "recaps": [{"route": 3}], "presets": [{"room": {"positions": {"FR": ["x", 2]}}}]})
 check(bad.materials == 0 and bad.completed.is_empty() and bad.crafted.is_empty(), "Malformed optional progression is bounded")
 var session := JourneySession.new()
 session.begin("expedition", "easy", "FR", 123, {"kind": "branch", "route": ["FR"], "branches": [["JP", "US"], ["IT", "NO"]]})
 check(session.choices() == ["JP", "US"], "Branch offers two destinations")
 session.complete_country(10)
 check(session.travel_to("US") and session.current_country() == "US", "Chosen branch becomes current stop")
 check(not session.travel_to("JP"), "Unchosen branch not reachable after choice")
 session.complete_country(10)
 check(session.travel_to("NO") and session.choices().is_empty() and session.fixed_route == ["FR", "US", "NO"], "Branch journey ends with actual chosen route")
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = SAVE
 root.add_child(game)
 await frames()
 var menu: MenuUI = game.menu
 for entry in TravelExtras.PAGES:
  TravelExtrasUI.new(menu).show(entry[0])
  await frames()
  check(menu.content.get_global_rect().end.x <= menu.root.size.x - 20, "New screen fits phone: " + entry[0])
  await capture(entry[0])
 game.profile.settings.large_controls = true
 game.profile.settings.text_scale = 1.3
 game.profile.settings.reduced_motion = true
 game.profile.save()
 game.apply_accessibility()
 for entry in TravelExtras.PAGES:
  TravelExtrasUI.new(menu).show(entry[0])
  await frames()
  check(menu.content.get_global_rect().end.x <= menu.root.size.x - 20, "Largest text fits phone: " + entry[0])
  if entry[0] == "accessibility": await capture("accessibility-large")
 var ui := TravelExtrasUI.new(menu)
 ui.launch("city", "paris")
 check(game.session.mode == "expedition" and game.grid.layout == "bridge", "City UI launches themed gameplay")
 await prepare_play()
 check(game.hud.lane_controls.visible and game.hud.lane_controls.get_child(0).custom_minimum_size.y >= 68, "Accessible lane controls are present in play")
 game.hud.lane_controls.get_child(game.run.safe_lane(0)).pressed.emit()
 await frames(5)
 check(game.run.completed_rows == 1, "Numbered lane button drives actual safe jump")
 game.pause_game()
 var old_seed: int = game.run.path_seed
 game.open_photo_mode()
 check(menu.root.visible and game.paused, "Paused photo mode opens")
 menu.photo_return.call()
 check(not menu.root.visible and game.paused and game.run.path_seed == old_seed, "Photo mode preserves paused route")
 game.resume_game()
 while game.run.phase == RunState.Phase.PLAY:
  game.choose_tile(game.run.completed_rows, game.run.safe_lane(game.run.completed_rows))
  await frames(5)
 for i in 300:
  await process_frame
  if game.country_awarded: break
 check("city:paris" in game.profile.extras.completed, "City reward earned through real jumps")
 check(TravelExtras.unlocked(game.profile, "secret", "rooftop"), "City clear discovers hidden viewpoint")
 check(game.profile.extras.recaps[-1].route == ["FR"], "Completed journey automatically assembles recap")
 game.return_to_menu()
 TravelExtrasUI.new(menu).launch("secret", "rooftop")
 check(game.config.row_count == 7 and game.grid.layout == "climb", "Hidden viewpoint is a distinct short path")
 await finish_country()
 check("secret:rooftop" in game.profile.extras.completed, "Hidden route grants viewpoint keepsake")
 game.return_to_menu()
 TravelExtrasUI.new(menu).launch("landmark", "fuji")
 check(game.config.row_count == 12 and game.grid.layout == "climb", "Landmark stage has a custom ascent")
 await prepare_play()
 await capture("fuji-play")
 game.return_to_menu()
 TravelExtrasUI.new(menu).launch("transport", "boat")
 check(not game.grid.moving, "Reduced motion keeps transport platforms still")
 if game.travel.active: game.travel.finish()
 await frames()
 check(game.grid.tile_at(0, game.run.safe_lane(0)).marker.visible, "Transport preview retains its safe checkmark")
 await capture("boat-preview")
 await prepare_play()
 await capture("boat-play")
 game.return_to_menu()
 game.profile.settings.reduced_motion = false
 game.profile.save()
 TravelExtrasUI.new(menu).launch("transport", "boat")
 check(game.grid.moving and game.extra_stage.vehicle != null, "Boat has moving platforms and rendered transport")
 game.return_to_menu()
 check(not game.valid_activity({"kind": "branch", "route": ["FR"], "branches": [["JP", "US"], ["JP", "NO"]]}), "Duplicate branching destinations rejected")
 game.profile.settings.reduced_motion = true
 game.profile.save()
 menu.activity_route_requested.emit({"kind": "branch", "name": "A branching weekend", "route": ["FR"], "branches": [["JP", "US"], ["IT", "NO"]]})
 await finish_country()
 check(game.session.choices() == ["JP", "US"], "Playable completion offers both branches")
 game.travel_to("US")
 await finish_country()
 game.travel_to("NO")
 await finish_country()
 check(game.profile.extras.recaps[-1].route == ["FR", "US", "NO"], "Movie retains actual playable branch choices")
 game.return_to_menu()
 game.switch_player_slot(1)
 check(game.profile.discoveries.is_empty() and game.profile.file_path == SAVE + ".player1", "Second player has independent passport")
 game.profile.home_country = "FR"
 game.profile.activities.custom.nickname = "Player Two"
 game.profile.save()
 menu.activity_route_requested.emit({"kind": "multiplayer", "route": ["FR"], "name": "Match", "seed": 73491, "difficulty": "hard"})
 check(game.session.seed_value == 73491 and game.session.difficulty == "hard", "Local match uses shared seed and difficulty")
 await prepare_play()
 var shared_path: Array = game.run.path.duplicate()
 game.choose_tile(0, (game.run.safe_lane(0) + 1) % game.config.lane_count)
 await frames(5)
 check(menu.multiplayer_scores.get("1", -1) == 0, "Failed multiplayer turn records actual score")
 game.switch_player_slot(0)
 check(game.profile.extras.crafted == ["lantern"] and game.profile.discoveries.size() == 11, "Switching returns first player’s saved room and passport")
 menu.activity_route_requested.emit({"kind": "multiplayer", "route": ["FR"], "name": "Match", "seed": 73491, "difficulty": "hard"})
 check(game.run.path == shared_path, "Different players receive exactly the same match path")
 game.return_to_menu()
 var code_route: Array[String] = ["FR", "JP", "US"]
 var code := ChallengeCode.encode(7373, "moderate", code_route, 0)
 var decoded := ChallengeCode.decode(code)
 check(decoded.route == code_route and decoded.seed == 7373, "Friendly route code round-trips exact order and seed")
 var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
 image.fill(Color("e7b567"))
 var second := Image.create(4, 4, false, Image.FORMAT_RGB8)
 second.fill(Color("286888"))
 var gif := TravelMovie.encode([image, second])
 check(gif.slice(0, 6).get_string_from_ascii() == "GIF89a" and gif[-1] == 0x3b, "Movie encoder writes a complete animated GIF")
 var file := FileAccess.open("res://artifacts/extras-encoder-test.gif", FileAccess.WRITE)
 file.store_buffer(gif); file.close()
 if render:
  check(await TravelMovie.save(menu, game.profile, game.profile.extras.recaps[-1], "res://artifacts/extras-journey-movie.gif") == OK, "Journey movie exports rendered destination frames")
 var before: int = game.profile.discoveries.size()
 var snapshot := PassportBackup.export_text(game.profile)
 game.profile.extras.materials = 92
 game.profile.save()
 check(PassportBackup.restore(game.profile, snapshot), "Second restore succeeds")
 menu.profile_reload_requested.emit()
 check(game.profile.extras.materials != 92 and game.profile.discoveries.size() == before, "UI reload does not overwrite restored progress")
 game.queue_free()
 await frames()
 clean_files()
 print("Travel extras checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
