extends SceneTree
const SAVE := "user://travel-batch-test.json"
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: failures += 1; push_error(message)
func _initialize() -> void:
 create_timer(90).timeout.connect(func(): push_error("Travel batch timeout"); quit(1))
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(375, 667) if "--small" in OS.get_cmdline_user_args() else Vector2i(390, 844)
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 var profile := PlayerProfile.new(SAVE)
 check(not profile.switch_room_space("gallery"), "Room expansion stays locked")
 check(not profile.answer_knowledge("FR", "Paris"), "Quiz requires a completed country")
 check(not profile.answer_hunt("JP"), "Wrong clue answer earns nothing")
 check(profile.answer_hunt("FR"), "Correct clue can be solved")
 for id in ["FR", "JP", "IS", "ID", "NO", "FI", "CA", "US", "IT", "ES", "PH", "EG"]: profile.discover(id)
 profile.note_completion("FR", "easy", true)
 check(profile.activities.hunt == 1, "Solved clue requires destination completion for treasure")
 check(profile.activities.mastery.FR == 1, "Easy clear earns bronze")
 profile.note_completion("FR", "hard", false)
 check(profile.activities.mastery.FR == 1, "Failed Hard cannot earn gold")
 profile.note_completion("JP", "kids", true)
 check(profile.activities.mastery.JP == 1, "Kids completion does not earn competitive mastery")
 profile.note_completion("FR", "moderate", true)
 check(profile.activities.mastery.FR == 2, "Flawless Moderate earns silver")
 profile.note_completion("FR", "hard", true)
 check(profile.activities.mastery.FR == 3, "Flawless Hard earns gold")
 profile.travel_buddy = "bird"
 for id in TravelActivities.BUDDY_QUESTS.bird.route: profile.note_completion(id, "easy", true)
 check(profile.activities.accessories.get("bird", false), "Buddy quest earns its accessory")
 check(profile.answer_knowledge("FR", "Paris"), "Correct knowledge answer earns sticker")
 var rewards: int = profile.journal_today().rewards.size()
 profile.answer_knowledge("FR", "Paris")
 check(profile.journal_today().rewards.size() == rewards, "Knowledge sticker cannot be farmed")
 var week := TravelActivities.expedition()
 for id in week.route: profile.note_completion(id, "easy", true, true)
 check(profile.activities.weekly.rewarded, "Complete weekly expedition earns keepsake")
 profile.activity_tick("photo")
 profile.room_interact("lamp")
 check(profile.bingo_today().lines.size() > 0, "Actual activities complete bingo lines")
 var original := profile.room_display.duplicate()
 check(profile.switch_room_space("balcony"), "Earned balcony opens")
 profile.room_display.assign(["JP"])
 profile.room_decor.wallpaper = "sky"
 profile.save()
 profile.switch_room_space("main")
 check(profile.room_display == original, "Main room arrangement preserved separately")
 profile.switch_room_space("balcony")
 check(profile.room_display == ["JP"] and profile.room_decor.wallpaper == "sky", "Balcony retains its own arrangement")
 profile.activities.custom.nickname = "Explorer"
 profile.activities.custom.ink = "jade"
 profile.activities.custom.weather = "snow"
 profile.activities.custom.time = "sunset"
 profile.activities.custom.confetti = "ocean"
 profile.activities.scrapbook.append({"title": "My northern memories", "countries": ["NO", "IS", "FI", "CA"], "note": "The world feels bigger with a little friend beside me.", "layout": "grid"})
 profile.save()
 var loaded := PlayerProfile.new(SAVE)
 check(loaded.activities.rewards.size() >= 3, "Adventure rewards persist separately from weekly boards")
 check(loaded.activities.mastery.FR == 3 and loaded.activities.knowledge == ["FR"], "Mastery and stickers reload")
 check(loaded.activities.custom.nickname == "Explorer" and loaded.activities.custom.ink == "jade", "Passport preferences reload")
 check(loaded.activities.scrapbook.size() == 1 and loaded.activities.spaces.size() == 2, "Scrapbook and spaces reload")
 check(not loaded.activities.timeline.is_empty(), "Timeline stores actual milestones")
 var session := JourneySession.new()
 session.begin("expedition", "easy", "FR", 1, {"route": ["FR", "IT", "ES"]})
 check(session.current_country() == "FR" and session.choices() == ["IT"], "Optional routes use fixed traversal")
 check(TravelActivities.week_key("2026-10-04") != TravelActivities.week_key("2026-10-05"), "Weekly goals roll on Monday")
 var hud := GameHUD.new()
 var menu := MenuUI.new()
 root.add_child(hud)
 root.add_child(menu)
 menu.setup(loaded, hud)
 for page in ["hub", "arrival", "souvenirs", "quests", "scrapbook", "weekly", "photo", "passport", "mastery", "hunt", "bingo", "lounge", "timeline", "weather", "knowledge", "celebrations", "checklist"]:
  TravelActivityUI.new(menu).show(page, "0" if page == "scrapbook" else "")
  await process_frame
  await process_frame
  check(menu.content.get_global_rect().end.x <= menu.root.size.x - 20, "Screen fits phone width: " + page)
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/batch-" + page + ("-small" if root.size.y < 800 else "") + ".png")
 menu.show_room()
 await process_frame
 if DisplayServer.get_name() != "headless":
  check(await TravelPicture.save_picture(menu, loaded, "photo", "FR", "res://artifacts/batch-photo-export.png", {"pose": "jump", "caption": "A new adventure", "frame": "gold"}) == OK, "Photo exports")
  check(await TravelPicture.save_picture(menu, loaded, "scrapbook", "0", "res://artifacts/batch-scrapbook-export.png") == OK, "Scrapbook exports")
  check(await TravelPicture.save_picture(menu, loaded, "room", "", "res://artifacts/batch-balcony-export.png") == OK, "Expanded room exports")
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 print("Travel batch checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
