extends SceneTree
var failures := 0
const SAVE := "user://travel-life-test.json"
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 create_timer(60).timeout.connect(func(): push_error("Travel life timeout"); quit(1))
 run.call_deferred()
func run() -> void:
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 var profile := PlayerProfile.new(SAVE)
 check(not profile.world_champion(), "New player is not champion")
 check(not RoomDecor.unlocked("display", "winter", profile.discoveries), "Winter starts locked")
 for id in ["CA", "NO", "IS"]:
  profile.discover(id)
  profile.advance_missions(id, true, false)
 check(RoomDecor.unlocked("display", "winter", profile.discoveries), "Winter set unlocks decoration")
 check("Winter corner" in profile.journal_today().rewards, "Set reward appears today")
 var reward_count: int = profile.journal_today().rewards.size()
 profile.discover("IS")
 check(profile.journal_today().rewards.size() == reward_count, "Repeat visit does not repeat newly unlocked rewards")
 for key in TravelCollections.SETS:
  for id in TravelCollections.SETS[key].route: check(id in GameCatalog.DESTINATIONS, "Set destination exists")
 profile.travel_buddy = "dragon"
 profile.room_decor.display = "winter"
 profile.save()
 var loaded := PlayerProfile.new(SAVE)
 check(loaded.travel_buddy == "dragon" and loaded.room_decor.display == "winter", "Buddy and earned decor reload")
 check(loaded.daily_progress().countries.size() == 3 and loaded.journal_today().moments.size() == 3, "Daily journal reloads")
 loaded.travel_journal.date = "2000-01-01"
 check(loaded.journal_today().rewards.is_empty(), "New day clears old rewards")
 for id in GameCatalog.FREE_DESTINATIONS:
  if id != "AQ": loaded.discover(id)
 check(not loaded.world_champion(), "One missing country keeps champion locked")
 loaded.discover("AQ")
 for id in TravelCollections.SETS.space.route: loaded.discover(id)
 check(RoomDecor.unlocked("display", "space", loaded.discoveries), "Space set unlocks space display")
 check(loaded.world_champion() and "world:champion" in loaded.badges, "Full free route earns champion")
 loaded.champion_seen = true
 loaded.save()
 check(PlayerProfile.new(SAVE).champion_seen, "Celebration acknowledgement persists")
 var hud := GameHUD.new()
 var menu := MenuUI.new()
 root.add_child(hud)
 root.add_child(menu)
 menu.setup(loaded, hud)
 menu.show_buddies()
 menu.show_journal()
 menu.show_room()
 await process_frame
 menu.show_album()
 await process_frame
 menu.show_champion()
 await process_frame
 for kind in ["bird", "robot", "dragon"]:
  var traveler := Traveler.new()
  traveler.buddy_kind = kind
  root.add_child(traveler)
  traveler.play_animation("celebrate")
  await process_frame
  check(traveler.buddy_face.text == "♥", "Buddy cheers")
  traveler.play_animation("fall")
  await process_frame
  check(traveler.buddy_face.text == "!", "Buddy reacts to fall")
  traveler.queue_free()
 if DisplayServer.get_name() != "headless":
  check(await TravelPicture.save_picture(menu, loaded, "room", "", "res://artifacts/travel-life-room.png") == OK, "Room exports PNG")
  check(await TravelPicture.save_picture(menu, loaded, "album", "FR", "res://artifacts/travel-life-album.png") == OK, "Album exports PNG")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/travel-life-champion.png")
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 print("Travel life: ", failures, " failures")
 quit(1 if failures else 0)
