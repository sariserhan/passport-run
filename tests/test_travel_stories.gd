extends SceneTree
const SAVE := "user://travel-stories-test.json"
var failures := 0
func check(value: bool, message: String) -> void:
 if not value: failures += 1; push_error(message)
func _initialize() -> void:
 create_timer(60).timeout.connect(func(): push_error("Travel stories timeout"); quit(1))
 run.call_deferred()
func run() -> void:
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 var profile := PlayerProfile.new(SAVE)
 check(not profile.earn_rare("FR", "gold"), "Unvisited destinations cannot earn rare keepsakes")
 check(not RoomDecor.unlocked("trophy", "Europe", profile.discoveries), "Regional trophy starts locked")
 var counts := TravelMilestones.progress(profile.discoveries)
 var total := 0
 for name in counts: total += counts[name].total
 check(total == GameCatalog.FREE_DESTINATIONS.size(), "Continents cover every free destination exactly once")
 var europe: Array[String] = []
 for id in GameCatalog.FREE_DESTINATIONS:
  if TravelMilestones.continent(id) == "Europe": europe.append(id)
 for id in europe.slice(0, europe.size() - 1): profile.discover(id)
 check("Europe" not in TravelMilestones.earned(profile.discoveries), "Region waits for last territory")
 profile.discover(europe.back())
 check("Europe" in TravelMilestones.earned(profile.discoveries), "Region completes")
 check("Europe explorer trophy" in profile.journal_today().rewards, "Trophy recorded in journal")
 profile.discover("FR")
 profile.advance_missions("FR", true, false)
 check(profile.earn_rare("FR", "gold"), "Flawless reward can be earned")
 check(not profile.earn_rare("FR", "gold"), "Rare reward is unique")
 check(profile.earn_rare("FR", "crystal"), "Second variant retained")
 profile.room_decor.furniture = "desk"
 profile.room_decor.lighting = "warm"
 profile.room_decor.map = "world"
 profile.room_decor.buddy_bed = "nest"
 profile.room_decor.trophy = "Europe"
 profile.regions_seen.append("Europe")
 profile.save()
 var loaded := PlayerProfile.new(SAVE)
 check(loaded.rare_keepsakes.FR.size() == 2 and loaded.regions_seen == ["Europe"], "Rare rewards and acknowledged regions reload")
 check(loaded.room_decor == profile.room_decor, "All earned room features persist")
 var today := GameCatalog.today_utc()
 var page := loaded.journal_page(today)
 check("FR" in page.countries and page.rewards.size() > 0 and page.moments.size() > 0, "Journal postcard preserves stamps, moment and rewards")
 loaded.journal_pages["2020-01-01"] = page.duplicate(true)
 loaded.journal_pages["2020-01-01"].date = "2020-01-01"
 loaded.save()
 loaded = PlayerProfile.new(SAVE)
 check(loaded.journal_page("2020-01-01").countries == page.countries, "Historical postcard reloads")
 for i in 35: loaded.journal_pages["2019-01-%02d" % i] = {"date": "2019-01-%02d" % i, "countries": [], "moments": [], "rewards": []}
 loaded.save()
 check(loaded.journal_pages.size() == 30 and today in loaded.journal_pages, "Archive remains bounded and retains recent page")
 var long_entries: Array = []
 for i in 100: long_entries.append("A".repeat(150) + str(i))
 for date in loaded.journal_pages:
  if date != today: loaded.journal_pages[date] = {"date": date, "countries": ["FR"], "moments": long_entries.duplicate(), "rewards": long_entries.duplicate()}
 check(loaded.save(), "Full archive saves")
 var full := PlayerProfile.new(SAVE)
 check(full.journal_pages.size() == 30 and full.rare_keepsakes.FR.size() == 2, "Full archive remains readable with existing rewards")
 check(BuddyPersonality.message("bird", "thinking", 6) != BuddyPersonality.message("robot", "thinking", 6), "Idle personalities differ")
 check(BuddyPersonality.offset("bird", "celebrate", 1) != BuddyPersonality.offset("dragon", "celebrate", 1), "Celebration movement differs")
 var hud := GameHUD.new()
 var menu := MenuUI.new()
 root.add_child(hud)
 root.add_child(menu)
 menu.setup(loaded, hud)
 for screen in [menu.show_buddies, menu.show_regions, menu.show_rare_challenges, menu.show_journal, menu.show_replay]:
  screen.call()
  await process_frame
 var replay: JourneyReplay
 for child in menu.content.get_children():
  if child is JourneyReplay: replay = child
 check(replay != null and replay.route == loaded.discoveries, "Replay preserves first-completion order")
 replay.playing = false
 var old := replay.index
 replay._process(2)
 check(replay.index == old, "Paused replay holds its stop")
 replay.playing = true
 replay._process(2)
 check(replay.index == old + 1, "Replay advances to next stamped destination")
 replay.seek.value = replay.route.size() - 1
 check(replay.index == replay.route.size() - 1 and replay.keepsake.destination_id == replay.route.back(), "Scrub shows correct souvenir")
 loaded.settings.reduced_motion = true
 menu.show_replay()
 await process_frame
 for child in menu.content.get_children():
  if child is JourneyReplay: check(not child.playing and child.map.progress == 1, "Reduced motion starts replay paused")
 if DisplayServer.get_name() != "headless":
  check(await TravelPicture.save_picture(menu, loaded, "journal", today, "res://artifacts/travel-stories-postcard.png") == OK, "Postcard exports")
  check(await TravelPicture.save_picture(menu, loaded, "room", "", "res://artifacts/travel-stories-room.png") == OK, "Expanded room exports")
  menu.show_replay()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/travel-stories-replay.png")
 menu.show_region_celebration("Europe")
 await process_frame
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 print("Travel stories: ", failures, " failures")
 quit(1 if failures else 0)
