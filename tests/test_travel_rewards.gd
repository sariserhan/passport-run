extends SceneTree

const SAVE := "user://travel-rewards-test.json"
var failures := 0
var checks := 0
var game: Node3D

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 create_timer(60).timeout.connect(func(): push_error("Travel reward test timeout"); quit(1))
 run.call_deferred()

func until(predicate: Callable) -> void:
 var deadline := Time.get_ticks_msec() + 6000
 while not predicate.call() and Time.get_ticks_msec() < deadline:
  await process_frame
  if game and game.paused: game.resume_game()
 check(predicate.call(), "Expected reward/gameplay state")

func capture(name: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/rewards-" + name + ("-small" if root.size.y < 800 else "") + ".png")

func run() -> void:
 root.size = Vector2i(375, 667) if "--small" in OS.get_cmdline_user_args() else Vector2i(390, 844)
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 var profile := PlayerProfile.new(SAVE)
 check(not RoomDecor.unlocked("plant", "fern", profile.discoveries), "Decor starts locked")
 var quest_notified := false
 for id in ["NO", "IS", "FI", "FR"]:
  profile.discover(id)
  if id == "FI": quest_notified = "penguin" in profile.last_unlocked_characters
 check(quest_notified, "Quest completion announces newly unlocked traveler")
 check("penguin" not in profile.last_unlocked_characters, "Only newly earned travelers are announced by the most recent clear")
 check(CharacterQuests.complete("penguin", profile.discoveries), "Snow quest counts previous stamps")
 check(CharacterStyle.character_unlocked("penguin", profile.discoveries), "Quest unlocks traveler before generic milestone")
 check(not CharacterStyle.character_unlocked("astronaut", profile.discoveries), "Unfinished quest remains locked")
 for id in CharacterQuests.QUESTS:
  for destination in CharacterQuests.QUESTS[id].route:
   check(destination in GameCatalog.DESTINATIONS, "Quest destination exists")
 var fantasy: Array[String] = ["WIZARD_CASTLE", "WIZARD_VILLAGE", "ENCHANTED_FOREST"]
 check(CharacterStyle.character_unlocked("wizard", fantasy), "Fantasy quest unlocks wizard")
 check(not CharacterQuests.complete("unknown", fantasy), "Unknown quests rejected")
 profile.room_decor = {"wallpaper": "sky", "shelves": "walnut", "plant": "fern", "rug": "ocean"}
 profile.room_positions = {"FR": [0.25, 0.65], "NO": [-8, 8], "IS": ["bad", 0], "UNKNOWN": [0, 0]}
 profile.room_postcards.assign(["FR", "NO", "FR", "UNKNOWN", "IS", "FI"])
 profile.record_destination("FR", "arcade", 120)
 profile.record_destination("FR", "arcade", 90)
 profile.record_destination("FR", "jump", 12)
 profile.record_destination("UNKNOWN", "arcade", 100)
 var restored := PlayerProfile.new(SAVE)
 check(restored.room_decor == {"wallpaper": "sky", "shelves": "oak", "plant": "fern", "rug": "none", "display": "none"}, "Only earned room decoration persists")
 check(Vector2(restored.room_positions.FR[0], restored.room_positions.FR[1]).is_equal_approx(Vector2(0.25, 0.65)) and Vector2(restored.room_positions.NO[0], restored.room_positions.NO[1]).is_equal_approx(Vector2(0, 1)) and "IS" not in restored.room_positions and "UNKNOWN" not in restored.room_positions, "Room coordinates persist and invalid data is cleaned")
 check(restored.room_postcards == ["FR", "NO", "IS"], "Only three unique earned postcards persist")
 check(restored.destination_records.FR.arcade == 120 and restored.destination_records.FR.jump == 12 and "UNKNOWN" not in restored.destination_records, "Album stores personal bests for earned destinations")
 for id in CharacterStyle.CHARACTERS:
  for pose in 6:
   var texture := CharacterStyle.motion_texture(id, pose) as AtlasTexture
   check(texture.region.size.x > 0 and texture.region.size.y > 0 and texture.atlas.get_size().x >= texture.region.end.x and texture.atlas.get_size().y >= texture.region.end.y, "Motion pose fits its atlas")
 var actor := Traveler.new()
 actor.character_id = "fox"
 root.add_child(actor)
 await process_frame
 actor.play_animation("walk")
 actor._process(0.01)
 var first: Texture2D = actor.portrait.texture
 actor._process(0.16)
 check(actor.portrait.texture != first, "Walking alternates actual limb/tail poses")
 actor.animation_paused = true
 var clock := actor.animation_clock
 actor._process(0.5)
 check(actor.animation_clock == clock, "Pause freezes motion")
 actor.animation_paused = false
 actor.reduced_motion = true
 actor._process(0.5)
 check(actor.animation_clock == clock, "Reduced Motion disables cycling")
 actor.play_animation("celebrate")
 check(actor.portrait.texture == CharacterStyle.motion_texture("fox", 4), "Victory has distinct pose even with Reduced Motion")
 actor.pose_jump(0.2)
 check(actor.portrait.texture == CharacterStyle.motion_texture("fox", 2), "Jump pose")
 actor.pose_jump(0.9)
 check(actor.portrait.texture == CharacterStyle.motion_texture("fox", 3), "Landing pose")
 actor.pose_fall(0.8)
 check(actor.portrait.texture == CharacterStyle.motion_texture("fox", 5), "Falling pose")
 actor.queue_free()
 var dragon := Traveler.new()
 dragon.character_id = "dragon"
 root.add_child(dragon)
 await process_frame
 dragon.pose_jump(0.05)
 var wing_up: Texture2D = dragon.portrait.texture
 dragon.pose_jump(0.2)
 check(dragon.portrait.texture != wing_up, "Dragon alternates open and folded wings during jumps")
 dragon.queue_free()
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = SAVE
 root.add_child(game)
 await process_frame
 game.menu.show_room()
 await process_frame
 var room: SouvenirRoom
 for child in game.menu.content.get_children():
  if child is SouvenirRoom: room = child
 check(room != null, "Room is accessible")
 var choices: Array = game.menu.content.get_children().filter(func(child): return child is OptionButton)
 check(choices.size() == 5, "Room has five decoration selectors including themed displays")
 choices[0].item_selected.emit(0)
 check(game.profile.room_decor.wallpaper == "sand" and room.decor.wallpaper == "sand", "Wallpaper selector updates saved and visible room")
 choices[0].item_selected.emit(1)
 choices[2].item_selected.emit(0)
 check(game.profile.room_decor.wallpaper == "sky" and game.profile.room_decor.plant == "none", "Each selector updates its own decoration category")
 choices[2].item_selected.emit(1)
 var before: Vector2 = room.get_child(0).position
 var touch := InputEventScreenTouch.new()
 touch.index = 0
 touch.position = before + Vector2(10, 10)
 touch.pressed = true
 room._gui_input(touch)
 var drag := InputEventScreenDrag.new()
 drag.index = 0
 drag.position = before + Vector2(80, 70)
 room._gui_input(drag)
 touch.pressed = false
 room._gui_input(touch)
 check(not room.positions.is_empty() and room.dragging == null, "Touch dragging saves arrangement")
 var saved_positions: Dictionary = PlayerProfile.new(SAVE).room_positions
 check(saved_positions.size() == game.profile.room_positions.size(), "Drag change preserves saved arrangement size")
 for id in game.profile.room_positions:
  var saved: Array = saved_positions.get(id, [-1, -1])
  var point: Array = game.profile.room_positions[id]
  check(Vector2(saved[0], saved[1]).is_equal_approx(Vector2(point[0], point[1])), "Drag change reaches durable profile save")
 await capture("decorated-room")
 game.menu.show_album()
 await process_frame
 var album: TravelAlbumPage
 for child in game.menu.content.get_children():
  if child is VBoxContainer:
   for page in child.get_children():
    if page is TravelAlbumPage: album = page
 check(album != null and album.destination_id in game.profile.discoveries, "Album contains earned destination page")
 var search: LineEdit
 for child in game.menu.content.get_children():
  if child is LineEdit: search = child
 search.text = "France"
 search.text_changed.emit("France")
 await process_frame
 for child in game.menu.content.get_children():
  if child is VBoxContainer:
   for page in child.get_children():
    if page is TravelAlbumPage: album = page
 check(album.destination_id == "FR" and album.get_children().any(func(child): return child is Label and child.text == "Best balloon score: 120 pts"), "Album search finds the correct country and durable best score")
 await capture("travel-album")
 game.menu.show_character_quests()
 await process_frame
 check(game.menu.content.get_children().any(func(child): return child is Label and "Snow Passport" in child.text), "Quest screen shows themed progress")
 await capture("character-quests")
 game.parcel.present("FR", 2, true)
 check(game.parcel.active and not game.parcel.card.visible, "Parcel begins closed")
 await capture("parcel-closed")
 game.parcel.open_or_finish()
 check(game.parcel.opened and game.parcel.card.visible and not game.parcel.button.disabled, "Reduced Motion reveals earned souvenir instantly")
 await capture("parcel-open")
 game.parcel.open_or_finish()
 check(not game.parcel.active, "Keep souvenir dismisses parcel")
 game.parcel.present("FR", 2, false)
 game.parcel.open_or_finish()
 game.parcel.cancel()
 await create_timer(0.5).timeout
 check(not game.parcel.active and game.parcel.card == null, "Cancelled animation cannot resurrect parcel")
 game.parcel.present("UNKNOWN", 1, false)
 check(not game.parcel.active, "Invalid reward destination rejected")
 game.profile.home_country = "FR"
 game.profile.character_id = "fox"
 game.start_game("world", "easy")
 game.start_preview()
 game.preview_remaining = 0.001
 game.config.jump_seconds = 0.01
 await until(func(): return game.run.phase == RunState.Phase.PLAY)
 for row in game.config.row_count:
  game.config.jump_seconds = 0.3 if row == 0 else 0.01
  check(game.choose_tile(row, game.run.safe_lane(row)), "Successful country path accepts step")
  if row == 0: await capture("fox-jump")
  await until(func(): return game.run.phase in [RunState.Phase.PLAY, RunState.Phase.COMPLETE])
 await until(func(): return game.parcel.active)
 var completed: String = game.session.current_country()
 var quantity: int = game.profile.souvenir_counts[completed]
 check(PlayerProfile.new(SAVE).souvenir_counts[completed] == quantity, "Jump reward persisted before reveal")
 game.complete_country()
 check(game.profile.souvenir_counts[completed] == quantity, "Repeated completion callback cannot duplicate reward")
 game.parcel.open_or_finish()
 await create_timer(0.5).timeout
 game.parcel.open_or_finish()
 game.return_to_menu()
 game.start_arcade("world")
 game.arcade.round_index = 2
 game.arcade.begin_round()
 game.arcade.phase = BalloonArcade.Phase.PLAY
 game.arcade.clear_round()
 game.arcade.finish_stamp()
 check(game.arcade.parcel.active, "Arcade destination has a souvenir parcel")
 var index: int = game.arcade.country_index
 game.arcade.next_round()
 check(game.arcade.country_index == index, "Parcel blocks accidental next-destination input")
 game.arcade.parcel.open_or_finish()
 await create_timer(0.5).timeout
 game.arcade.parcel.open_or_finish()
 check(not game.arcade.parcel.active, "Arcade parcel can be kept")
 game.return_to_menu()
 var practice_quantity: int = game.profile.souvenir_counts.FR
 game.start_arcade("practice", "FR")
 game.arcade.round_index = 2
 game.arcade.begin_round()
 game.arcade.phase = BalloonArcade.Phase.PLAY
 game.arcade.clear_round()
 check(not game.arcade.parcel.active and game.profile.souvenir_counts.FR == practice_quantity, "Practice neither opens a parcel nor awards souvenirs")
 game.return_to_menu()
 game.queue_free()
 await process_frame
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SAVE + suffix)
 print("Travel reward checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
