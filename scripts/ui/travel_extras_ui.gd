class_name TravelExtrasUI
extends RefCounted
var menu: MenuUI
var profile: PlayerProfile
var ui: TravelActivityUI
func _init(owner: MenuUI) -> void:
 menu = owner
 profile = owner.profile
 ui = TravelActivityUI.new(owner)
func text(value: String, size: int = 18) -> Label: return ui.text(value, size)
func button(value: String, callback: Callable) -> Button: return ui.button(value, callback)
func show(page: String, argument: String = "") -> void:
 var title := "New journeys"
 for entry in TravelExtras.PAGES:
  if entry[0] == page: title = entry[1]
 menu.clear(title, "Explore somewhere new. Make something to remember.")
 match page:
  "hub":
   for entry in TravelExtras.PAGES:
    var key: String = entry[0]
    button(entry[1], func(): show(key))
  "cities": stages("city")
  "landmarks": stages("landmark")
  "transport": stages("transport")
  "secrets": stages("secret")
  "branches": branches()
  "festivals": festivals()
  "characters": characters()
  "crafting": crafting()
  "presets": presets()
  "globe": globe()
  "recaps": recaps(argument)
  "multiplayer": multiplayer()
  "friendly": friendly()
  "accessibility": accessibility()
  "backup": backup()
 button("BACK", menu.show_main if page == "hub" else func(): show("hub"))
func launch(kind: String, key: String) -> void:
 if not TravelExtras.unlocked(profile, kind, key): return
 var stage := TravelExtras.stage(kind, key)
 menu.activity_route_requested.emit({"kind": kind, "key": key, "name": stage.name, "route": [stage.country]})
func stages(kind: String) -> void:
 text("Play a scenic memory stage to earn a special keepsake. Completed destinations and your next World Tour stop are available.")
 if kind == "transport": text("Boats sway sideways; cable-car platforms move along a rising path. Reduced motion keeps platforms still.")
 for key in TravelExtras.catalog(kind):
  var stage := TravelExtras.stage(kind, key)
  var id: String = key
  var art := TravelArtwork.new()
  art.country_id = stage.country
  art.custom_minimum_size.y = 160
  menu.content.add_child(art)
  text(stage.name, 24)
  text("Keepsake: " + stage.keepsake + (" · Collected!" if kind + ":" + key in profile.extras.completed else ""))
  if kind == "secret" and not TravelExtras.unlocked(profile, kind, key): text("Clue: finish " + TravelExtras.CITIES[stage.requires].name + " to find the path.")
  var play := button("EXPLORE " + stage.name.to_upper(), func(): launch(kind, id))
  play.disabled = not TravelExtras.unlocked(profile, kind, key)
func branches() -> void:
 var ids: Array = profile.discoveries.filter(func(id): return id in GameCatalog.FREE_DESTINATIONS)
 text("At each stop, choose between two destinations. Your chosen route becomes your journey movie.")
 if ids.size() < 5: text("Collect five real destination stamps to open branching journeys."); return
 var choices := [ids[0], ids[1], ids[2], ids[3], ids[4]]
 var labels := ["Starting country", "First choice A", "First choice B", "Second choice A", "Second choice B"]
 for i in 5:
  var index: int = i
  text(labels[i])
  ui.country_picker(ids, choices[i], func(id): choices[index] = id)
 var error := text("")
 button("START MY BRANCHING JOURNEY", func():
  var unique := {}
  for id in choices: unique[id] = true
  if unique.size() != 5: error.text = "Choose five different destinations."; return
  menu.activity_route_requested.emit({"name": "My branching journey", "kind": "branch", "route": [choices[0]], "branches": [[choices[1], choices[2]], [choices[3], choices[4]]]})
 )
func festivals() -> void:
 var festival := TravelExtras.festival()
 text(festival.name, 26)
 text("This month · " + TravelExtras.festival_key() + " UTC. The theme rotates on the first day of each month.")
 text("Travel under festival lights through " + " → ".join(festival.route.map(func(id): return GameCatalog.country_name(id))))
 text("Reward: " + festival.keepsake + (" · Collected" if "festival:" + TravelExtras.festival_key() in profile.extras.completed else ""))
 var play := button("JOIN THE FESTIVAL", func(): menu.activity_route_requested.emit({"name": festival.name, "kind": "festival", "festival": TravelExtras.festival_key(), "route": festival.route}))
 play.disabled = not profile.can_visit_route(festival.route)
 if play.disabled: text("Complete the festival destinations on your World Tour to join.")
func characters() -> void:
 for key in TravelExtras.CHARACTERS:
  var character: Dictionary = TravelExtras.CHARACTERS[key]
  var id: String = key
  text(character.name, 25)
  text(character.story)
  var request: Dictionary = profile.extras.characters.get(key, {})
  if request.is_empty(): button("ACCEPT REQUEST", func(): profile.accept_character(id); show("characters"))
  else:
   text(" → ".join(character.route.map(func(country): return ("✓ " if country in request.countries else "○ ") + GameCatalog.country_name(country))))
   text("Thank you! Your " + character.reward + " is in your collection." if request.rewarded else "Reward: " + character.reward)
   ui.route_button(character.route, character.name + "’s request")
func crafting() -> void:
 text("Travel materials: %d. Each completed destination earns one material. Crafting uses materials and keeps your country souvenirs." % profile.extras.materials)
 for key in TravelExtras.RECIPES:
  var recipe: Dictionary = TravelExtras.RECIPES[key]
  var id: String = key
  text(recipe.name, 24)
  text("%d materials · Stamps: %s" % [recipe.cost, ", ".join(recipe.countries.map(func(country): return GameCatalog.country_name(country)))])
  if key in profile.extras.crafted:
   button("DISPLAY IN MY ROOM" + (" · DISPLAYED" if profile.extras.ornament == key else ""), func(): profile.extras.ornament = id; profile.save(); show("crafting"))
  else:
   var craft := button("CRAFT", func(): profile.craft_extra(id); show("crafting"))
   craft.disabled = profile.extras.materials < recipe.cost or not recipe.countries.all(func(country): return country in profile.discoveries)
 button("CLEAR CRAFTED DISPLAY", func(): profile.extras.ornament = "none"; profile.save(); show("crafting"))
 button("VISIT MY ROOM", menu.show_room)
func presets() -> void:
 text("Save up to six room arrangements. Applying a preset changes your current room space; other spaces keep their arrangements.")
 var name := LineEdit.new()
 name.placeholder_text = "Arrangement name"
 name.max_length = 32
 name.custom_minimum_size.y = 56
 menu.content.add_child(name)
 var add := button("SAVE CURRENT ROOM", func(): profile.save_room_preset(name.text if not name.text.strip_edges().is_empty() else "My room " + str(profile.extras.presets.size() + 1)); show("presets"))
 add.disabled = profile.extras.presets.size() >= 6
 for i in profile.extras.presets.size():
  var index: int = i
  text(profile.extras.presets[i].name, 23)
  button("APPLY ARRANGEMENT", func(): profile.apply_room_preset(index); menu.show_room())
  button("DELETE ARRANGEMENT", func(): profile.extras.presets.remove_at(index); profile.save(); show("presets"))
 button("DECORATE ROOM", menu.show_room)
func globe() -> void:
 text("Drag to rotate. Tap a country dot to choose it. Gold dots show your stamps.")
 var view := TravelGlobe.new()
 view.discoveries = profile.discoveries
 menu.content.add_child(view)
 var selected := {"id": profile.home_country if profile.home_country in GameCatalog.FREE_DESTINATIONS else "FR"}
 var heading := text(GameCatalog.country_name(selected.id), 24)
 var play := button("TRAVEL TO SELECTED COUNTRY", func(): ui.route([selected.id], GameCatalog.country_name(selected.id)))
 play.disabled = not profile.can_visit(selected.id)
 view.destination_selected.connect(func(id):
  if id not in GameCatalog.FREE_DESTINATIONS: return
  selected.id = id
  heading.text = GameCatalog.country_name(id) + (" · Complete it on World Tour first" if not profile.can_visit(id) else "")
  play.disabled = not profile.can_visit(id)
 )
 button("ROTATE WEST", func(): view.rotate_by(-50))
 button("ROTATE EAST", func(): view.rotate_by(50))
func recaps(argument: String) -> void:
 text("Completed journeys automatically assemble a movie of the places you visited. Keep the last ten trips; export a short animated GIF to share.")
 if profile.extras.recaps.is_empty(): text("Finish a journey to make your first movie."); return
 var index := clampi(int(argument) if not argument.is_empty() else profile.extras.recaps.size() - 1, 0, profile.extras.recaps.size() - 1)
 for i in profile.extras.recaps.size():
  var selected := str(i)
  button(profile.extras.recaps[i].name + " · " + profile.extras.recaps[i].date, func(): show("recaps", selected))
 var recap: Dictionary = profile.extras.recaps[index]
 text("%d stops · %d tiles" % [recap.route.size(), recap.tiles])
 var movie := JourneyReplay.new()
 movie.profile = profile
 movie.route_override.assign(recap.route)
 menu.content.add_child(movie)
 var status := text("")
 var export := button("EXPORT ANIMATED MOVIE", func():
  if menu.export_busy: return
  menu.export_busy = true
  status.text = "Making your movie…"
  var result: int = await TravelMovie.save(menu, profile, recap, "user://passport-run-movie.gif")
  if result == OK:
   status.text = "Movie saved. " + ("Use the share sheet to save it to Files." if OS.get_name() == "iOS" else "Open your saved files to share it.")
   if OS.get_name() == "iOS": await NativePictureShare.request(menu, "passport-run-movie.gif")
  else: status.text = "Movie could not be saved. Try again."
  menu.export_busy = false
 )
 export.disabled = menu.export_busy
 button("OPEN SAVED FILES", func(): if OS.get_name() != "iOS": OS.shell_open(ProjectSettings.globalize_path("user://")))
func multiplayer() -> void:
 text("Up to four players take turns on this device. Each player keeps a separate passport, room and collection. Match routes use the same difficulty and path.")
 text("Current traveler: Player %d · %s" % [menu.player_slot + 1, profile.activities.custom.nickname], 24)
 for slot in 4:
  var index := slot
  button("SWITCH TO PLAYER %d" % (slot + 1), func(): menu.player_slot_requested.emit(index); TravelExtrasUI.new(menu).show("multiplayer"))
 if profile.home_country.is_empty():
  button("CHOOSE THIS PLAYER’S START", menu.show_countries)
  return
 ui.picker(["two", "three", "four"], {2: "two", 3: "three", 4: "four"}[menu.player_count], func(value): menu.player_count = {"two": 2, "three": 3, "four": 4}[value]; menu.turn_challenge.clear(); menu.multiplayer_scores.clear(); show("multiplayer"))
 var players: Array[PlayerProfile] = []
 for slot in menu.player_count: players.append(PlayerProfile.new(menu.base_save_path if slot == 0 else menu.base_save_path + ".player" + str(slot)))
 var eligible: Array = GameCatalog.FREE_DESTINATIONS.keys().filter(func(id): return players.all(func(player): return player.can_visit(id)))
 text("Shared match · %d players" % menu.player_count)
 if eligible.is_empty(): text("Choose starting countries for every player, then collect a shared destination to play a match."); return
 if menu.turn_challenge.is_empty(): menu.turn_challenge = {"route": [eligible[0]], "seed": 73491, "difficulty": "easy", "name": "Friendly local match", "kind": "multiplayer"}
 ui.country_picker(eligible, menu.turn_challenge.route[0], func(id): menu.turn_challenge.route = [id]; menu.multiplayer_scores.clear())
 ui.picker(GameCatalog.DIFFICULTIES, menu.turn_challenge.difficulty, func(key): menu.turn_challenge.difficulty = key; menu.multiplayer_scores.clear())
 for slot in menu.multiplayer_scores: text("Player %d · %d tiles" % [int(slot) + 1, menu.multiplayer_scores[slot]])
 var play := button("PLAY THIS PLAYER’S TURN", func(): menu.activity_route_requested.emit(menu.turn_challenge.duplicate(true)))
 play.disabled = menu.player_slot >= menu.player_count or not profile.can_visit_route(menu.turn_challenge.route)
 button("NEW MATCH PATH", func(): menu.turn_challenge.seed = randi_range(1, PathGenerator.MODULUS - 2); menu.multiplayer_scores.clear(); show("multiplayer"))
func friendly() -> void:
 text("Choose up to six earned destinations in travel order. Share the code so a friend can play the same route and difficulty.")
 var ids: Array = profile.discoveries.filter(func(id): return id in GameCatalog.FREE_DESTINATIONS)
 if ids.is_empty(): text("Collect your first stamp to create a route."); button("PASTE A FRIEND’S CODE", menu.show_challenge); return
 var draft := {"route": [ids[0]], "difficulty": profile.difficulty, "seed": randi_range(1, PathGenerator.MODULUS - 2)}
 var route_label := text(GameCatalog.country_name(ids[0]))
 ui.country_picker(ids, ids[0], func(id):
  if id in draft.route: draft.route.erase(id)
  elif draft.route.size() < 6: draft.route.append(id)
  route_label.text = " → ".join(draft.route.map(func(country): return GameCatalog.country_name(country)))
 )
 text("Choose a stop to add or remove it.", 16)
 ui.picker(GameCatalog.DIFFICULTIES, draft.difficulty, func(key): draft.difficulty = key)
 var code := TextEdit.new()
 code.custom_minimum_size.y = 110
 code.editable = false
 menu.content.add_child(code)
 button("MAKE & COPY CHALLENGE CODE", func():
  if draft.route.is_empty(): route_label.text = "Choose at least one destination."; return
  var typed: Array[String] = []
  typed.assign(draft.route)
  code.text = ChallengeCode.encode(draft.seed, draft.difficulty, typed, 0)
  DisplayServer.clipboard_set(code.text)
 )
 button("PLAY MY CODE", func():
  var data := ChallengeCode.decode(code.text)
  if not data.is_empty(): menu.challenge_requested.emit(data)
 )
 button("PASTE A FRIEND’S CODE", menu.show_challenge)
func accessibility() -> void:
 text("Larger numbered lane buttons offer another way to choose tiles. Text size applies to menus and gameplay. Reduced motion and high contrast also apply to journey previews.")
 for pair in [["large_controls", "Larger memory-path controls"], ["arcade_large", "Larger balloon controls"], ["reduced_motion", "Reduced motion"], ["high_contrast", "High contrast"]]:
  var key: String = pair[0]
  var control := CheckButton.new()
  control.text = pair[1]
  control.custom_minimum_size.y = 64
  control.button_pressed = profile.settings[key]
  control.toggled.connect(func(value): profile.settings[key] = value; profile.save(); menu.settings_changed.emit())
  menu.content.add_child(control)
 text("Text size")
 ui.picker(["standard", "larger", "largest"], "largest" if profile.settings.text_scale > 1.2 else "larger" if profile.settings.text_scale > 1 else "standard", func(value):
  profile.settings.text_scale = {"standard": 1.0, "larger": 1.15, "largest": 1.3}[value]
  profile.save(); menu.settings_changed.emit(); show("accessibility")
 )
func backup() -> void:
 text("Save a portable copy of this player’s passport, room and collections. Restoring replaces this player’s progress; your previous save is kept locally. Purchases stay with this device’s store account.")
 var field := TextEdit.new()
 field.custom_minimum_size.y = 150
 field.placeholder_text = "Paste a passport backup here to preview it."
 menu.content.add_child(field)
 var status := text("")
 button("CREATE & COPY BACKUP", func():
  field.text = PassportBackup.export_text(profile)
  if field.text.is_empty(): status.text = "Could not save the passport."; return
  DisplayServer.clipboard_set(field.text)
  var file := FileAccess.open("user://" + PassportBackup.FILENAME, FileAccess.WRITE)
  if not file: status.text = "Backup copied; could not write the backup file."; return
  file.store_string(field.text); file.close()
  status.text = "Backup copied and saved as " + PassportBackup.FILENAME
 )
 button("SHARE / OPEN BACKUP FILE", func():
  if not FileAccess.file_exists("user://" + PassportBackup.FILENAME): status.text = "Create a backup first."; return
  if OS.get_name() == "iOS": await NativePictureShare.request(menu, PassportBackup.FILENAME)
  else: OS.shell_open(ProjectSettings.globalize_path("user://"))
 )
 button("PASTE BACKUP", func(): field.text = DisplayServer.clipboard_get())
 button("LOAD MY PREVIOUS SAVE", func():
  var previous := profile.read_valid(profile.file_path + ".before-restore")
  if previous.is_empty(): status.text = "No previous restore is available."; return
  field.text = JSON.stringify({"format": PassportBackup.FORMAT, "profile": previous})
  status.text = "Previous save loaded. Preview it before restoring."
 )
 button("LOAD BACKUP FILE", func():
  var dialog := FileDialog.new()
  dialog.access = FileDialog.ACCESS_FILESYSTEM
  dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
  dialog.filters = PackedStringArray(["*.json ; Passport backup"])
  menu.add_child(dialog)
  dialog.file_selected.connect(func(path):
   var file := FileAccess.open(path, FileAccess.READ)
   if file and file.get_length() <= PlayerProfile.MAX_PROFILE_BYTES + 1024: field.text = file.get_as_text()
   else: status.text = "Backup file is unavailable or too large."
   dialog.queue_free()
  )
  dialog.canceled.connect(dialog.queue_free)
  dialog.popup_centered_ratio(0.85)
 )
 var previewed := {"text": ""}
 var restore := button("RESTORE PREVIEWED BACKUP", func():
  if field.text != previewed.text: return
  if PassportBackup.restore(profile, field.text): menu.profile_reload_requested.emit()
  else: status.text = "Could not restore. Your passport was kept."
 )
 restore.disabled = true
 field.text_changed.connect(func(): restore.disabled = true)
 button("PREVIEW BACKUP", func():
  var data := PassportBackup.inspect(field.text)
  restore.disabled = data.is_empty()
  if data.is_empty(): status.text = "This is not a valid Passport Run backup."; return
  previewed.text = field.text
  status.text = "Ready to restore %d stamps for %s. Your current %d stamps will be replaced." % [data.discoveries.size(), TravelActivities.clean(data.get("activities")).custom.nickname, profile.discoveries.size()]
 )
