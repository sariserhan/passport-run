class_name TravelActivityUI
extends RefCounted
var menu: MenuUI
var profile: PlayerProfile
func _init(owner: MenuUI) -> void:
 menu = owner
 profile = owner.profile
func text(value: String, size: int = 18) -> Label: return menu.copy(value, size)
func button(value: String, callback: Callable) -> Button: return menu.action(value, false, callback)
func picker(options: Array, selected: String, changed: Callable) -> OptionButton:
 var control := OptionButton.new()
 control.custom_minimum_size.y = 54
 control.add_theme_font_size_override("font_size", 18)
 for value in options:
  control.add_item(str(value).capitalize())
  control.set_item_metadata(control.item_count - 1, value)
  if str(value) == selected: control.select(control.item_count - 1)
 control.item_selected.connect(func(index): changed.call(control.get_item_metadata(index)))
 menu.content.add_child(control)
 return control
func countries(earned: bool = true) -> Array:
 return profile.discoveries.duplicate() if earned else GameCatalog.FREE_DESTINATIONS.keys()
func country_picker(ids: Array, chosen: String, callback: Callable) -> OptionButton:
 var control := OptionButton.new()
 control.custom_minimum_size.y = 54
 for id in ids:
  control.add_item(GameCatalog.country_name(id))
  control.set_item_metadata(control.item_count - 1, id)
  if id == chosen: control.select(control.item_count - 1)
 control.item_selected.connect(func(index): callback.call(control.get_item_metadata(index)))
 menu.content.add_child(control)
 return control
func route(ids: Array, name: String, kind: String = "optional") -> void:
 if not profile.can_visit_route(ids): return
 menu.activity_route_requested.emit({"route": ids, "name": name, "kind": kind, "week": TravelActivities.week_key()})
func route_button(ids: Array, name: String, kind: String = "optional") -> void:
 var play := button("TRAVEL · " + name, func(): route(ids, name, kind))
 play.disabled = not profile.can_visit_route(ids)
 if play.disabled: text("Complete these stops on your World Tour first: " + ", ".join(ids.map(func(id): return GameCatalog.country_name(id))), 16)
func show(page: String, argument: String = "") -> void:
 menu.clear({"hub": "More adventures", "arrival": "Country arrivals", "souvenirs": "Living souvenirs", "quests": "Buddy adventures", "scrapbook": "My travel scrapbook", "weekly": "Weekly expedition", "photo": "Traveler’s photo mode", "passport": "My personal passport", "mastery": "Destination mastery", "hunt": "Souvenir treasure hunt", "bingo": "Travel bingo", "lounge": "Departure lounge", "timeline": "My travel timeline", "weather": "Weather & time", "knowledge": "Knowledge stickers", "celebrations": "My celebrations", "checklist": "Discovery checklist"}.get(page, "Travel activities"), "Your passport, your memories, your next adventure.")
 match page:
  "hub": hub()
  "arrival": arrival(argument)
  "souvenirs": souvenirs(argument)
  "quests": quests()
  "scrapbook": scrapbook(argument)
  "weekly": weekly()
  "photo": photo(argument)
  "passport": passport()
  "mastery": mastery()
  "hunt": hunt()
  "bingo": bingo()
  "lounge": lounge()
  "timeline": timeline()
  "weather": weather()
  "knowledge": knowledge(argument)
  "celebrations": celebrations()
  "checklist": checklist()
 button("BACK", menu.show_main if page == "hub" else func(): show("hub"))
func hub() -> void:
 for entry in [["arrival", "Country arrival scenes"], ["souvenirs", "Interactive souvenirs"], ["quests", "Buddy adventures"], ["scrapbook", "Travel scrapbook"], ["weekly", "This week’s expedition"], ["photo", "Photo mode"], ["passport", "Personalize my passport"], ["mastery", "Destination mastery"], ["hunt", "Treasure hunt"], ["bingo", "Travel bingo"], ["lounge", "Departure lounge"], ["timeline", "Travel timeline"], ["weather", "Weather & time of day"], ["knowledge", "Knowledge stickers"], ["celebrations", "Celebration choices"], ["checklist", "Discovery checklist"]]:
  var key: String = entry[0]
  button(entry[1], func(): show(key))
 button("INTERACT WITH MY ROOM", menu.show_room)
 if not profile.activities.rewards.is_empty():
  text("My adventure rewards", 23)
  for reward in profile.activities.rewards.values(): text("★ " + str(reward), 17)
func arrival(id: String) -> void:
 if id.is_empty(): id = profile.home_country if profile.home_country in GameCatalog.FREE_DESTINATIONS else "FR"
 country_picker(GameCatalog.FREE_DESTINATIONS.keys(), id, func(value): show("arrival", value))
 var art := TravelArtwork.new()
 art.country_id = id
 art.weather = profile.activities.custom.weather
 art.time_of_day = profile.activities.custom.time
 art.custom_minimum_size.y = 240
 menu.content.add_child(art)
 text("WELCOME TO " + GameCatalog.country_name(id).to_upper(), 25)
 text(CountryRewards.fact(id))
 if profile.travel_buddy != "none":
  var buddy := BuddyPreview.new()
  buddy.kind = profile.travel_buddy
  buddy.weather = profile.activities.custom.weather
  buddy.elapsed = 7
  buddy.reduced_motion = profile.settings.reduced_motion
  menu.content.add_child(buddy)
 button("HEAR THIS DESTINATION’S MUSIC", func(): menu.activity_sound_requested.emit("destination:" + id))
 route_button([id], GameCatalog.country_name(id))
func souvenirs(id: String) -> void:
 if profile.discoveries.is_empty(): text("Bring home a souvenir by completing a destination."); return
 if id not in profile.discoveries: id = profile.discoveries[0]
 country_picker(countries(), id, func(value): show("souvenirs", value))
 var card := SouvenirCard.new()
 card.destination_id = id
 card.quantity = profile.souvenir_counts.get(id, 1)
 card.rare_variants = profile.rare_keepsakes.get(id, [])
 menu.content.add_child(card)
 var story := text("Tap your keepsake to discover its story.")
 button("TELL ME ITS STORY", func(): story.text = DestinationTheme.souvenir(id) + " · " + CountryRewards.fact(id))
 button("WAKE UP THIS KEEPSAKE", func():
  menu.activity_sound_requested.emit("stamp")
  if not profile.settings.reduced_motion:
   var tween := card.create_tween()
   tween.tween_property(card, "modulate", Color("ffe29b"), 0.2)
   tween.tween_property(card, "modulate", Color.WHITE, 0.3)
   tween.tween_property(card, "rotation", 0.035, 0.12)
   tween.tween_property(card, "rotation", 0.0, 0.12)
 )
func quests() -> void:
 for kind in TravelActivities.BUDDY_QUESTS:
  var quest: Dictionary = TravelActivities.BUDDY_QUESTS[kind]
  var done: Array = profile.activities.buddy_progress.get(kind, [])
  text(quest.name, 23)
  text("Travel with " + BuddyPersonality.FRIENDS[kind].name + ": " + ", ".join(quest.route.map(func(id): return ("✓ " if id in done else "○ ") + GameCatalog.country_name(id))))
  text("Reward: " + quest.reward + (" · Equipped!" if profile.activities.accessories.get(kind, false) else ""))
  var key: String = kind
  button("BRING " + BuddyPersonality.FRIENDS[kind].name.to_upper(), func(): profile.travel_buddy = key; profile.save(); show("quests"))
  route_button(quest.route, quest.name)
func scrapbook(selected: String) -> void:
 text("Create up to 20 pages with four destination pictures, stamps and a personal note. Choose a grid or a stacked album layout.")
 for index in profile.activities.scrapbook.size():
  var key := str(index)
  button(profile.activities.scrapbook[index].title, func(): show("scrapbook", key))
 if profile.discoveries.is_empty(): text("Your first stamp unlocks scrapbook making."); return
 var index := int(selected) if not selected.is_empty() else -1
 var draft: Dictionary = profile.activities.scrapbook[index].duplicate(true) if index >= 0 and index < profile.activities.scrapbook.size() else {"title": "My travels", "note": "", "countries": [profile.discoveries[0]], "layout": "grid"}
 var title := LineEdit.new()
 title.text = draft.title
 title.max_length = 48
 title.placeholder_text = "Page title"
 title.custom_minimum_size.y = 54
 title.text_changed.connect(func(value): draft.title = value)
 menu.content.add_child(title)
 var note := TextEdit.new()
 note.text = draft.note
 note.placeholder_text = "A memory worth keeping…"
 note.custom_minimum_size.y = 120
 note.text_changed.connect(func(): draft.note = note.text.left(240))
 menu.content.add_child(note)
 picker(["grid", "stack"], draft.layout, func(value): draft.layout = value)
 var picked := text("Pictures: " + ", ".join(draft.countries.map(func(id): return GameCatalog.country_name(id))))
 country_picker(countries(), draft.countries[0] if not draft.countries.is_empty() else "", func(value):
  if value in draft.countries: draft.countries.erase(value)
  elif draft.countries.size() < 4: draft.countries.append(value)
  picked.text = "Pictures: " + ", ".join(draft.countries.map(func(id): return GameCatalog.country_name(id)))
 )
 text("Choose a country to add it or remove it. Up to four pictures.", 16)
 button("SAVE PAGE", func():
  if index >= 0: profile.activities.scrapbook[index] = draft.duplicate(true)
  elif profile.activities.scrapbook.size() < 20: profile.activities.scrapbook.append(draft.duplicate(true))
  profile.save()
  show("scrapbook", str(index if index >= 0 else profile.activities.scrapbook.size() - 1))
 )
 if index >= 0:
  var preview := TravelScrapbook.new()
  preview.profile = profile
  preview.page = profile.activities.scrapbook[index]
  menu.content.add_child(preview)
  button("SHARE PAGE", func(): menu.export_picture("scrapbook", str(index)))
  button("DELETE PAGE", func(): profile.activities.scrapbook.remove_at(index); profile.save(); show("scrapbook"))
func weekly() -> void:
 var week := TravelActivities.expedition()
 text(week.name, 26)
 text("Week " + TravelActivities.week_key() + " · Changes each Monday at 00:00 UTC")
 text(" → ".join(week.route.map(func(id): return GameCatalog.country_name(id))))
 text("Complete all three stops on this expedition to earn " + week.reward + ".")
 var completed: Array = profile.activities.weekly.get("countries", []) if profile.activities.weekly.get("week") == TravelActivities.week_key() else []
 text("%d / 3 stops completed this week" % completed.size())
 route_button(week.route, week.name, "weekly")
func photo(id: String) -> void:
 var ids := countries()
 if id in GameCatalog.DESTINATIONS and id not in ids: ids.append(id)
 if ids.is_empty(): text("Complete a destination or use Photo Mode from the pause screen."); return
 if id not in ids: id = ids[0]
 var state := {"id": id, "pose": profile.activities.custom.pose, "frame": "classic", "caption": profile.activities.custom.motto}
 var preview := TravelPhoto.new()
 preview.profile = profile
 preview.destination_id = id
 preview.pose = state.pose
 preview.caption = state.caption
 preview.buddy = profile.travel_buddy
 menu.content.add_child(preview)
 country_picker(ids, id, func(value): state.id = value; preview.destination_id = value; preview.queue_redraw())
 picker(["wave", "jump", "cheer"], state.pose, func(value): state.pose = value; preview.pose = value; preview.queue_redraw())
 picker(["classic", "gold", "ocean"], state.frame, func(value): state.frame = value; preview.frame = value; preview.queue_redraw())
 var caption := LineEdit.new()
 caption.max_length = 80
 caption.text = state.caption
 caption.custom_minimum_size.y = 54
 caption.text_changed.connect(func(value): state.caption = value; preview.caption = value; preview.queue_redraw())
 menu.content.add_child(caption)
 button("SAVE & SHARE PHOTO", func():
  menu.photo_draft = state.duplicate()
  menu.export_picture("photo", state.id)
 )
 if menu.photo_return.is_valid(): button("RETURN TO MY PAUSED GAME", menu.photo_return)
func passport() -> void:
 for field in ["nickname", "motto"]:
  text(field.capitalize())
  var key: String = field
  var input := LineEdit.new()
  input.text = profile.activities.custom[field]
  input.max_length = 32 if field == "nickname" else 80
  input.custom_minimum_size.y = 54
  input.text_changed.connect(func(value): profile.activities.custom[key] = value.strip_edges(); profile.save())
  menu.content.add_child(input)
 text("Stamp ink")
 picker(["ruby", "jade", "ocean"], profile.activities.custom.ink, func(value): profile.activities.custom.ink = value; profile.save())
 button("CHOOSE MY EARNED COVER", menu.show_goals)
 button("VIEW MY PASSPORT", menu.show_passport)
func mastery() -> void:
 text("Bronze: complete a destination. Silver: flawless Moderate memory play. Gold: flawless Hard memory play. Balloon Tour medals also count.")
 for id in profile.discoveries:
  text(GameCatalog.country_name(id) + " · " + ["Unranked", "Bronze", "Silver", "Gold"][int(profile.activities.mastery.get(id, 0))], 20)
 button("FIND MY NEXT OBJECTIVE", func(): show("checklist"))
func hunt() -> void:
 if profile.activities.hunt >= TravelActivities.HUNTS.size(): text("Every treasure found! Your journal and timeline hold the discoveries.", 24); return
 var clue: Dictionary = TravelActivities.HUNTS[profile.activities.hunt]
 text("Treasure %d / %d" % [profile.activities.hunt + 1, TravelActivities.HUNTS.size()], 24)
 text(clue.clue, 22)
 var answer := {"id": GameCatalog.FREE_DESTINATIONS.keys()[0]}
 country_picker(GameCatalog.FREE_DESTINATIONS.keys(), answer.id, func(value): answer.id = value)
 var result := text("Solve the clue, then complete its destination to find the treasure.")
 button("CHECK MY ANSWER", func():
  if profile.answer_hunt(answer.id): show("hunt")
  else: result.text = "Try another country. Your progress is safe."
 )
 if profile.activities.hunt_solved:
  text("Clue solved! Now complete " + GameCatalog.country_name(clue.id) + ".", 23)
  route_button([clue.id], "Find " + clue.reward)
func bingo() -> void:
 text("Nine optional goals each week. Complete a row, column or diagonal to earn its travel sticker.")
 var board := profile.bingo_today()
 var grid := GridContainer.new()
 grid.columns = 3
 grid.add_theme_constant_override("h_separation", 6)
 grid.add_theme_constant_override("v_separation", 6)
 menu.content.add_child(grid)
 for goal in TravelActivities.BINGO:
  var cell := Label.new()
  cell.text = "%s\n%d / %d" % [goal[1], int(board.get(goal[0], 0)), goal[2]]
  cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  cell.custom_minimum_size = Vector2(90, 104)
  cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  cell.add_theme_color_override("font_color", Color("9bddbb") if int(board.get(goal[0], 0)) >= goal[2] else Color("fff2d6"))
  var panel := PanelContainer.new()
  var border := StyleBoxFlat.new()
  border.bg_color = Color("204b50") if int(board.get(goal[0], 0)) >= goal[2] else Color("263a43")
  border.border_color = Color("9bddbb")
  border.set_border_width_all(1)
  border.set_corner_radius_all(8)
  border.content_margin_left = 6
  border.content_margin_right = 6
  border.content_margin_top = 6
  border.content_margin_bottom = 6
  panel.add_theme_stylebox_override("panel", border)
  panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  panel.add_child(cell)
  grid.add_child(panel)
 text("%d / 8 lines completed · Week %s" % [board.lines.size(), TravelActivities.week_key()], 21)
func lounge() -> void:
 var scene := TravelLounge.new()
 scene.profile = profile
 menu.content.add_child(scene)
 text("Your suitcase is packed. Choose your next departure.", 22)
 button("BOARD THE WORLD TOUR", func(): menu.request_mode("world"))
 button("WEEKLY DEPARTURE", func(): show("weekly"))
 button("BUDDY ADVENTURE", func(): show("quests"))
 button("TREASURE EXPEDITION", func(): show("hunt"))
 button("CHOOSE A DISCOVERED STOP", func(): show("checklist"))
func timeline() -> void:
 if profile.activities.timeline.is_empty():
  text("Your next adventure starts this timeline. Earlier stamps remain in your passport.")
  for id in profile.discoveries.slice(0, 10): text("Earlier journey · " + GameCatalog.country_name(id))
 var events: Array = profile.activities.timeline.duplicate()
 events.reverse()
 for event in events: text(event.date + " · " + event.text)
func weather() -> void:
 text("Choose the atmosphere for your travels and photos. Weather stays in the sky so the path remains clear.")
 picker(["clear", "rain", "snow"], profile.activities.custom.weather, func(value): profile.activities.custom.weather = value; profile.save(); show("weather"))
 picker(["day", "sunrise", "sunset", "night"], profile.activities.custom.time, func(value): profile.activities.custom.time = value; profile.save(); show("weather"))
 var art := TravelArtwork.new()
 art.country_id = profile.discoveries[0] if not profile.discoveries.is_empty() else "FR"
 art.weather = profile.activities.custom.weather
 art.time_of_day = profile.activities.custom.time
 art.custom_minimum_size.y = 260
 menu.content.add_child(art)
func knowledge(id: String) -> void:
 var ids := countries().filter(func(value): return not TravelActivities.question(value).is_empty())
 if ids.is_empty(): text("Complete a country to unlock a gentle learning challenge."); return
 if id not in ids: id = ids[0]
 country_picker(ids, id, func(value): show("knowledge", value))
 var quiz := TravelActivities.question(id)
 text(quiz.prompt, 24)
 var result := text("Optional learning · Your run and scores are unaffected.")
 for option in quiz.options:
  var answer: String = option
  button(option, func(): result.text = "Correct! " + GameCatalog.country_name(id) + " knowledge sticker earned." if profile.answer_knowledge(id, answer) else "Try again. There is no penalty.")
 if id in profile.activities.knowledge: text("★ Knowledge sticker collected")
func celebrations() -> void:
 text("Victory pose")
 picker(["wave", "jump", "cheer"], profile.activities.custom.pose, func(value): profile.activities.custom.pose = value; profile.save())
 text("Confetti colors")
 picker(["gold", "ocean", "forest"], profile.activities.custom.confetti, func(value): profile.activities.custom.confetti = value; profile.save(); show("celebrations"))
 text("Favorite sound")
 picker(["stamp", "land", "team"], profile.activities.custom.sound, func(value): profile.activities.custom.sound = value; profile.save(); menu.activity_sound_requested.emit(value))
 var preview := WorldCelebration.new()
 preview.palette = profile.activities.custom.confetti
 preview.reduced_motion = profile.settings.reduced_motion
 menu.content.add_child(preview)
func checklist() -> void:
 var objective := "Try a weekly expedition or complete a treasure clue."
 for id in profile.tour_route():
  if id not in profile.discoveries and profile.can_visit(id): objective = "Complete " + GameCatalog.country_name(id) + " on your World Tour to earn its first souvenir."; break
 if objective.begins_with("Try"):
  for id in profile.discoveries:
   if int(profile.activities.mastery.get(id, 0)) < 3: objective = "Earn " + ("Gold on Hard" if profile.activities.mastery.get(id, 0) == 2 else "Silver on Moderate") + " with a flawless finish in " + GameCatalog.country_name(id) + "."; break
 text("Next objective: " + objective, 21)
 var search := LineEdit.new()
 search.placeholder_text = "Search destinations"
 search.custom_minimum_size.y = 54
 menu.content.add_child(search)
 var rows := VBoxContainer.new()
 menu.content.add_child(rows)
 var state := {"ids": GameCatalog.DESTINATIONS.keys(), "page": 0}
 var update := func():
  for child in rows.get_children(): rows.remove_child(child); child.queue_free()
  for id in state.ids.slice(state.page * 20, state.page * 20 + 20):
   var name := Label.new()
   name.text = GameCatalog.country_name(id) + (" · ✓ Souvenir" if id in profile.discoveries else " · ○ Souvenir") + "\nMastery: " + ["None", "Bronze", "Silver", "Gold"][int(profile.activities.mastery.get(id, 0))] + " · Rare: %d / 2" % profile.rare_keepsakes.get(id, []).size() + (" · ★ Knowledge" if id in profile.activities.knowledge else "")
   name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
   rows.add_child(name)
   var key: String = id
   var play := menu.style.button("TRAVEL TO " + GameCatalog.country_name(id), false)
   play.custom_minimum_size.y = 54
   play.disabled = not profile.can_visit(id) or id not in GameCatalog.FREE_DESTINATIONS
   play.pressed.connect(func(): route([key], GameCatalog.country_name(key)))
   rows.add_child(play)
 search.text_changed.connect(func(value): state.ids = GameCatalog.DESTINATIONS.keys().filter(func(id): return value.to_lower() in GameCatalog.country_name(id).to_lower()); state.page = 0; update.call())
 button("PREVIOUS PAGE", func(): state.page = maxi(0, state.page - 1); update.call())
 button("NEXT PAGE", func(): state.page = mini(maxi(0, (state.ids.size() - 1) / 20), state.page + 1); update.call())
 update.call()
