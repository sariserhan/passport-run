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
 check(CharacterStyle.CHARACTERS.size() == 24, "Roster includes 12 humans and 12 new travelers")
 check(not CharacterStyle.character_unlocked("fox", profile.discoveries), "First animal requires a successful destination")
 check(CharacterStyle.character_unlocked("astronaut", profile.discoveries, true), "Verified traveler pack includes astronaut")
 check(not CharacterStyle.character_unlocked("invalid", profile.discoveries, true), "Unknown purchased character rejected")
 check(CharacterStyle.character_unlocked("backpacker", profile.discoveries), "Girl backpacker starts available")
 check(not CharacterStyle.character_unlocked("champion", profile.discoveries, true), "Purchase cannot bypass world completion")
 profile.discover("FR")
 profile.discover("FR")
 check(profile.souvenir_counts.FR == 2 and profile.discoveries.size() == 1, "Repeat clears award copies without duplicate discoveries")
 check(profile.room_display == ["FR"], "First souvenir automatically placed")
 check(CharacterStyle.character_unlocked("fox", profile.discoveries), "First clear unlocks fox")
 check(not CharacterStyle.character_unlocked("cat", profile.discoveries), "Repeat clear does not bypass unique discovery milestone")
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
 var art_keys: Array[String] = []
 for id in CharacterStyle.CHARACTERS:
  var texture := CharacterStyle.character_texture(id) as AtlasTexture
  check(texture != null, "Character art exists")
  var key := texture.atlas.resource_path + str(texture.region)
  check(key not in art_keys, "Each traveler uses distinct atlas art")
  art_keys.append(key)
  var actor := Traveler.new()
  actor.character_id = id
  actor.customization = {"outfit": "trail", "hat": "sun", "backpack": "europe"}
  root.add_child(actor)
  await process_frame
  actor.pose_jump(0.5)
  actor.pose_fall(0.5)
  if CharacterStyle.CHARACTERS[id].get("fantasy_art", false):
   check(actor.body.get_child_count() == 1, "Animal/fantasy gear stays intact without human accessory overlays")
   check(actor.portrait.texture == CharacterStyle.motion_texture(id, 5), "New traveler fall pose appears in gameplay")
  actor.queue_free()
  await process_frame
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(390, 844)
  var game = load("res://scenes/game.tscn").instantiate()
  game.save_path = path
  root.add_child(game)
  await process_frame
  # Test fixture grants discoveries, never production purchase entitlements.
  game.profile.discoveries.assign(GameCatalog.FREE_DESTINATIONS.keys().slice(0, 80))
  if "FR" not in game.profile.discoveries: game.profile.discoveries.append("FR")
  for id in ["fox", "astronaut", "dragon"]:
   game.profile.character_id = id
   game.menu.show_wardrobe()
   await create_timer(0.2).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/" + id + "-wardrobe.png")
   game.start_arcade("practice", "FR")
   check(is_instance_valid(game.arcade) and game.profile.equipped_character() == id, "Selected traveler enters arcade")
   game.arcade.begin_round()
   await create_timer(0.2).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/" + id + "-arcade.png")
   game.return_to_menu()
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
