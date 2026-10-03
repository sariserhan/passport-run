extends SceneTree

var failures := 0
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error(label)

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var path := "user://souvenir-character-test.json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)
 var profile := PlayerProfile.new(path)
 check(profile.equipped_character() == "classic", "Default explorer")
 check(CharacterStyle.character_unlocked("backpacker", profile.discoveries), "Girl backpacker starts available")
 check(not CharacterStyle.character_unlocked("champion", profile.discoveries, true), "Purchase cannot bypass world completion")
 profile.discover("FR")
 profile.discover("FR")
 check(profile.souvenir_counts.FR == 2 and profile.discoveries.size() == 1, "Repeat clears award copies without duplicate discoveries")
 check(profile.room_display == ["FR"], "First souvenir automatically placed")
 profile.character_id = "backpacker"
 profile.save()
 var restored := PlayerProfile.new(path)
 check(restored.souvenir_counts.FR == 2 and restored.equipped_character() == "backpacker", "Rewards and selected character survive reload")
 restored.character_id = "polar"
 check(restored.equipped_character() == "classic", "Locked character cannot be equipped")
 restored.character_pack_unlocked = true
 check(restored.equipped_character() == "polar", "Verified purchase unlocks character")
 restored.save()
 check(PlayerProfile.new(path).equipped_character() == "classic", "Saved selection does not grant purchase entitlement")
 var all: Array[String] = []
 all.assign(GameCatalog.FREE_DESTINATIONS.keys())
 check(CharacterStyle.character_unlocked("champion", all), "Whole world unlocks champion")
 all.pop_back()
 check(not CharacterStyle.character_unlocked("champion", all), "Missing last country blocks champion")
 for id in CharacterStyle.CHARACTERS:
  check(CharacterStyle.character_texture(id) != null, "Character art exists")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390, 844)
  var game = load("res://scenes/game.tscn").instantiate()
  game.save_path = path
  root.add_child(game)
  await process_frame
  game.profile.character_id = "backpacker"
  game.menu.show_wardrobe()
  await create_timer(0.2).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/girl-backpacker-wardrobe.png")
  game.queue_free()
  await process_frame
 var traveler := Traveler.new()
 traveler.character_id = "backpacker"
 root.add_child(traveler)
 await process_frame
 check(traveler.portrait.hframes == 1 and not traveler.portrait.region_enabled, "Girl backpacker uses distinct sprite")
 traveler.pose_jump(0.5)
 traveler.pose_fall(0.5)
 check(traveler.portrait.frame == 0, "New character poses keep atlas selection intact")
 traveler.queue_free()
 await process_frame
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)
 print("Souvenir and character checks: failures=", failures)
 quit(1 if failures else 0)
