class_name MenuUI
extends CanvasLayer

signal start_requested(mode: String, difficulty: String)
signal challenge_requested(data: Dictionary)
signal settings_changed
signal home_country_selected(id: String)
signal difficulty_selected(key: String)
signal trip_requested(id: String)
signal adventure_requested(id: String)
signal arcade_requested(kind: String)
signal cinema_requested(id: String)
signal special_requested(id: String)
signal online_records_requested
var online_available := false
var revision := 0
var purchase: RoutePurchase
var cinema_purchase: RoutePurchase
var cinema_page := false
var special_page := false

var profile: PlayerProfile
var style: GameHUD
var root: ColorRect
var content: VBoxContainer
var scroll: ScrollContainer
var mode_buttons: Dictionary = {}
var difficulty_picker: OptionButton
var home_button: Button
var challenge_input: TextEdit
var pending_mode: String = ""
var status: Label
var safe_margin: MarginContainer

func setup(saved_profile: PlayerProfile, hud_style: GameHUD) -> void:
	profile = saved_profile
	style = hud_style
	layer = 3
	root = ColorRect.new()
	root.color = Color("153e57")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var artwork := TextureRect.new()
	artwork.texture = preload("res://assets/backdrops/FR.png")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(artwork)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.09, 0.18, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	safe_margin = MarginContainer.new()
	var margins := safe_margin
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + edge, 28)
	margins.add_theme_constant_override("margin_top", 48)
	margins.add_theme_constant_override("margin_bottom", 38)
	root.add_child(margins)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	root.resized.connect(update_safe_area)
	update_safe_area()
	update_safe_area.call_deferred()

func update_safe_area() -> void:
	SafeAreaMargins.apply(safe_margin, root.size, Vector4i(28, 48, 28, 38))

func clear(title: String, subtitle: String) -> void:
	revision += 1
	special_page = false
	cinema_page = false
	root.show()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	mode_buttons.clear()
	scroll.scroll_vertical = 0
	var heading := style.label(title, 34, GameHUD.CREAM)
	heading.add_theme_color_override("font_outline_color", Color("123352"))
	heading.add_theme_constant_override("outline_size", 6)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	copy(subtitle)

func copy(text: String, size: int = 17) -> Label:
	var text_label := style.label(text, size, Color("c4dce5"))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(text_label)
	return text_label

func action(text: String, primary: bool, callback: Callable) -> Button:
	var control := style.button(text, primary)
	control.custom_minimum_size.y = 58
	control.pressed.connect(callback)
	content.add_child(control)
	return control

func show_main() -> void:
	clear("PASSPORT\nRUN", "Remember the path. Travel the world.")
	var title: Label = content.get_child(0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("ffda65"))
	var hero := TextureRect.new()
	hero.texture = preload("res://assets/menu-key-art.png")
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.custom_minimum_size.y = 210
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(hero)
	home_button = action("Start: " + (GameCatalog.country_name(profile.home_country) if not profile.home_country.is_empty() else "Choose your starting destination"), false, func(): show_countries())
	difficulty_picker = OptionButton.new()
	difficulty_picker.custom_minimum_size.y = 52
	difficulty_picker.add_theme_font_size_override("font_size", 19)
	for key in GameCatalog.DIFFICULTIES:
		var config := GameCatalog.difficulty(key)
		difficulty_picker.add_item("%s · %d lanes · %ds preview" % [key.capitalize(), config.lane_count, config.preview_seconds])
	difficulty_picker.select(GameCatalog.DIFFICULTIES.find(profile.difficulty))
	difficulty_picker.item_selected.connect(func(index: int):
		profile.difficulty = GameCatalog.DIFFICULTIES[index]
		difficulty_selected.emit(profile.difficulty)
		profile.save()
	)
	content.add_child(difficulty_picker)
	if not profile.tutorial_done:
		action("LEARN THE PATH", true, func(): start_requested.emit("tutorial", "easy"))
	action("SHORT ADVENTURES · 3 COUNTRIES", true, show_trips)
	action("ADVENTURE PLAY · SPECIAL MECHANICS", false, show_adventures)
	action("BALLOON TOUR · ARCADE", true, show_arcade)
	for item in [["world", "WORLD TOUR"], ["infinite", "INFINITE MEMORY"], ["daily", "DAILY WORLD TOUR"], ["kids", "KIDS ADVENTURE"]]:
		var mode: String = item[0]
		mode_buttons[mode] = action(item[1], mode == "world", func(): request_mode(mode))
	action("COLLECTION GOALS", false, show_goals)
	action("MY TRAVEL ROOM", false, show_room)
	action("EXPLORER WARDROBE", false, show_wardrobe)
	action("DAILY TRAVEL MISSIONS", false, show_missions)
	action("CINEMA WORLDS · SEPARATE PAID ROUTE", false, show_cinema_route)
	action("SPECIAL EXPEDITIONS · PAID ROUTE", false, show_special_route)
	copy("Daily: same UTC date + difficulty = same route. Scores are local until online rankings are connected.", 15)
	if online_available:
		copy("Online play uses an anonymous account and syncs your passport.", 15)
		action("ONLINE DAILY", false, func(): start_requested.emit("online_daily", profile.difficulty))
		action("ONLINE INFINITE", false, func(): start_requested.emit("online_infinite", profile.difficulty))
		action("ONLINE RANKINGS", false, func(): online_records_requested.emit())
	action("WORLD MAP", false, show_world_map)
	action("MY PASSPORT", false, show_passport)
	action("LOCAL RECORDS", false, show_records)
	action("PLAY A CHALLENGE CODE", false, show_challenge)
	action("SETTINGS", false, show_settings)
	if not profile.last_error.is_empty():
		copy(profile.last_error)

func request_mode(mode: String) -> void:
	if mode in ["world", "kids"] and profile.home_country not in GameCatalog.FREE_DESTINATIONS:
		pending_mode = mode
		show_countries()
		return
	start_requested.emit(mode, profile.difficulty)

func show_countries() -> void:
	clear("Where should your\njourney begin?", "Choose a starting point. Changing it keeps all your passport stamps.")
	var search := LineEdit.new()
	search.placeholder_text = "Search countries and territories"
	search.custom_minimum_size.y = 54
	search.add_theme_font_size_override("font_size", 20)
	content.add_child(search)
	var buttons: Array[Button] = []
	for id in GameCatalog.sorted_destinations():
		var country: String = id
		var control := action(country + "   " + GameCatalog.country_name(country), country == profile.home_country, func():
			profile.home_country = country
			home_country_selected.emit(country)
			profile.save()
			if not pending_mode.is_empty():
				var mode := pending_mode
				pending_mode = ""
				start_requested.emit(mode, profile.difficulty)
			else:
				show_main()
		)
		control.set_meta("destination_id", country)
		buttons.append(control)
	search.text_changed.connect(func(query: String):
		for control in buttons:
			var id: String = control.get_meta("destination_id")
			control.visible = query.is_empty() or query.to_lower() in (control.text + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower()
	)
	copy("Geography: mledoze/countries · ODbL 1.0", 15)
	copy("%d destinations to explore: countries and territories. Special places have their own paid route." % GameCatalog.FREE_DESTINATIONS.size(), 15)
	action("BACK", false, func(): pending_mode = ""; show_main())

func show_passport() -> void:
	clear("My passport", "%d / %d destinations discovered" % [profile.discoveries.size(), GameCatalog.DESTINATIONS.size()])
	var search := LineEdit.new()
	search.placeholder_text = "Search your passport"
	search.custom_minimum_size.y = 54
	search.add_theme_font_size_override("font_size", 20)
	content.add_child(search)
	var pages: Array[String] = profile.discoveries.duplicate()
	var state := {"index": 0, "ids": pages}
	var book := PassportPage.new()
	book.cover_id = profile.passport_cover
	content.add_child(book)
	var empty := copy("Complete a destination to receive your first stamped page.")
	var counter := copy("")
	var navigation := HBoxContainer.new()
	content.add_child(navigation)
	var previous := style.button("← PREVIOUS", false)
	var next := style.button("NEXT →", true)
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(previous)
	navigation.add_child(next)
	var update_page := func():
		var ids: Array = state.ids
		book.visible = not ids.is_empty()
		empty.visible = ids.is_empty()
		previous.disabled = state.index <= 0
		next.disabled = state.index + 1 >= ids.size()
		counter.text = "No matching completed destinations" if ids.is_empty() else "Page %d of %d · %s" % [state.index + 1, ids.size(), GameCatalog.country_name(ids[state.index])]
		if not ids.is_empty():
			book.destination_id = ids[state.index]
			book.page_number = profile.discoveries.find(book.destination_id) + 1
			book.queue_redraw()
			counter.text += "\nSouvenir: " + DestinationTheme.souvenir(book.destination_id)
	previous.pressed.connect(func(): state.index -= 1; update_page.call())
	next.pressed.connect(func(): state.index += 1; update_page.call())
	search.text_changed.connect(func(query: String):
		state.ids = pages.filter(func(id: String): return query.is_empty() or query.to_lower() in (id + " " + GameCatalog.country_name(id) + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower())
		state.index = 0
		update_page.call()
	)
	update_page.call()
	if profile.discoveries.size() == GameCatalog.DESTINATIONS.size():
		copy("WORLD EXPLORER · Every destination sticker collected!", 21)
	action("MY TRAVEL STICKERS", false, show_stickers)
	action("MY SOUVENIRS", false, show_souvenirs)
	copy("Recent journey", 22)
	var names: Array[String] = []
	for id in profile.history.slice(-12):
		names.append(GameCatalog.country_name(id))
	copy(" → ".join(names) if not names.is_empty() else "Complete a destination to collect your first stamp.")
	action("BACK", true, show_main)

func show_world_map() -> void:
	clear("My world map", "Gold pins mark completed destinations. Lines follow your recent travel history.")
	var map := PassportWorldMap.new()
	map.discoveries = profile.discoveries.duplicate()
	map.route = profile.history.duplicate()
	content.add_child(map)
	var cleared: Array = profile.discoveries.filter(func(id: String): return id in GameCatalog.FREE_DESTINATIONS)
	copy("%d / %d countries and territories stamped" % [cleared.size(), GameCatalog.FREE_DESTINATIONS.size()], 20)
	if cleared.is_empty():
		copy("Complete your first country to pin it on the map.")
	else:
		for id in cleared:
			copy("● " + GameCatalog.country_name(id), 17)
	copy("Regional progress", 23)
	var regions := TravelGoals.regions(profile.discoveries)
	for region in regions:
		var progress: Dictionary = regions[region]
		if progress.completed > 0:
			copy("%s · %d / %d%s" % [region, progress.completed, progress.total, " · COMPLETE ★" if progress.completed == progress.total else ""], 17)
	copy("Fantasy worlds and special-place stamps are in your passport.", 15)
	action("MY PASSPORT", false, show_passport)
	action("BACK", true, show_main)

func show_stickers() -> void:
	clear("Travel stickers", "Your discoveries become a little collection of the world.")
	if profile.discoveries.is_empty():
		copy("Complete a destination to collect its sticker.")
	for id in GameCatalog.DESTINATIONS:
		if id in profile.discoveries:
			copy(GameCatalog.country_name(id), 23)
			var artwork := TravelArtwork.new()
			artwork.country_id = id
			artwork.show_traveler = false
			artwork.custom_minimum_size.y = 170
			content.add_child(artwork)
			copy(CountryRewards.fact(id))
	action("BACK TO PASSPORT", true, show_passport)

func show_records() -> void:
	clear("Local records", "Your best scores on this device. Different difficulties are scored separately.")
	for key in GameCatalog.DIFFICULTIES:
		copy(key.capitalize(), 24)
		copy("World Tour: %d tiles\nInfinite: %d tiles\nDaily (%s UTC): %d tiles" % [profile.records.get("world:" + key, 0), profile.records.get("infinite:" + key, 0), GameCatalog.today_utc(), profile.records.get("daily:" + key + ":" + GameCatalog.today_utc(), 0)])
	copy("Special Expeditions: %d tiles" % profile.records.get("special:" + profile.difficulty, 0))
	copy("Cinema Worlds: %d tiles" % profile.records.get("cinema:" + profile.difficulty, 0))
	copy("Kids Adventure: %d tiles" % profile.records.get("kids:kids", 0))
	action("BACK", true, show_main)

func show_settings() -> void:
	clear("Settings", "Make the journey comfortable for you.")
	for key in ["music", "sound"]:
		copy("Music volume" if key == "music" else "Sound effects volume", 21)
		var slider := HSlider.new()
		slider.custom_minimum_size.y = 48
		slider.max_value = 1
		slider.step = 0.05
		slider.value = profile.settings[key]
		var setting: String = key
		slider.value_changed.connect(func(value: float): profile.settings[setting] = value; profile.save(); settings_changed.emit())
		content.add_child(slider)
	for item in [["reduced_motion", "Reduced motion"], ["high_contrast", "High-contrast path preview"], ["haptics", "Vibration on supported devices"]]:
		var setting: String = item[0]
		var toggle := CheckButton.new()
		toggle.text = item[1]
		toggle.add_theme_font_size_override("font_size", 19)
		toggle.custom_minimum_size.y = 56
		toggle.button_pressed = profile.settings[setting]
		toggle.toggled.connect(func(value: bool): profile.settings[setting] = value; profile.save(); settings_changed.emit())
		content.add_child(toggle)
	copy("Progress and a bounded gameplay log stay on this device. Online modes connect only when configured. No chat, advertisements, or remote analytics are active.", 15)
	if not OS.has_feature("mobile"):
		action("OPEN USER DATA FOLDER", false, func(): OS.shell_open(ProjectSettings.globalize_path("user://")))
	action("CHANGE HOME COUNTRY", false, show_countries)
	action("REPLAY TUTORIAL", false, func(): start_requested.emit("tutorial", "easy"))
	action("BACK", true, show_main)

func show_challenge() -> void:
	clear("Challenge a friend", "Paste a challenge link or PR1 code to play the same path. Links with a ghost let you race your friend. These are local challenges, without verified online rankings.")
	challenge_input = TextEdit.new()
	challenge_input.custom_minimum_size.y = 170
	challenge_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	challenge_input.placeholder_text = "PR1.…"
	content.add_child(challenge_input)
	status = copy("")
	action("PLAY CHALLENGE", true, func():
		var decoded := ChallengeCode.decode(challenge_input.text)
		if decoded.is_empty():
			status.text = "That code is invalid or uses an unsupported version."
		else:
			challenge_requested.emit(decoded)
	)
	action("BACK", false, show_main)

func show_special_route() -> void:
	show_paid_route(false)

func show_cinema_route() -> void:
	show_paid_route(true)

func show_paid_route(cinema: bool) -> void:
	var manager := cinema_purchase if cinema else purchase
	var destinations := GameCatalog.CINEMA_DESTINATIONS if cinema else GameCatalog.PREMIUM_DESTINATIONS
	clear("Cinema\nWorlds" if cinema else "Special\nExpeditions", "Original movie-inspired worlds. This pack has its own purchase." if cinema else "A separate route through famous landmarks and fantasy worlds.")
	special_page = not cinema
	cinema_page = cinema
	copy("%d destinations · One-time route-pack purchase" % destinations.size(), 20)
	if manager:
		copy(manager.message)
		if manager.busy:
			copy("Please wait…")
		elif not manager.unlocked:
			var buy := action("UNLOCK · " + manager.price if not manager.price.is_empty() else "PURCHASE UNAVAILABLE", true, manager.purchase)
			buy.disabled = manager.price.is_empty()
			var restore := action("RESTORE PURCHASE", false, manager.restore)
			restore.disabled = manager.store == null
	var search := LineEdit.new()
	search.placeholder_text = "Search your destination…"
	search.custom_minimum_size.y = 54
	search.add_theme_font_size_override("font_size", 20)
	content.add_child(search)
	var cards: Dictionary = {}
	var ids := destinations.keys()
	ids.sort_custom(func(a: String, b: String): return GameCatalog.country_name(a) < GameCatalog.country_name(b))
	for id in ids:
		var place: String = id
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		content.add_child(card)
		var heading := style.label(GameCatalog.country_name(place), 23, GameHUD.CREAM)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(heading)
		var artwork := TravelArtwork.new()
		artwork.country_id = place
		artwork.show_traveler = false
		artwork.custom_minimum_size.y = 145
		card.add_child(artwork)
		var play := style.button("PLAY " + GameCatalog.country_name(place).to_upper() if manager and manager.unlocked else "LOCKED · ROUTE PACK REQUIRED", manager and manager.unlocked)
		play.disabled = not manager or not manager.unlocked or manager.busy
		play.pressed.connect(func():
			if cinema: cinema_requested.emit(place)
			else: special_requested.emit(place)
		)
		card.add_child(play)
		cards[place] = card
	search.text_changed.connect(func(query: String):
		for id in cards:
			cards[id].visible = query.is_empty() or query.to_lower() in (GameCatalog.country_name(id) + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower()
	)
	action("BACK", false, show_main)

func purchase_changed() -> void:
	if cinema_page and root.visible:
		show_cinema_route()
	elif special_page and root.visible:
		show_special_route()

func show_trips() -> void:
	clear("Short adventures", "Three countries. One clear finish. Earn an adventure badge.")
	for id in TravelGoals.TRIPS:
		var trip: Dictionary = TravelGoals.TRIPS[id]
		copy(trip.name, 24)
		var names: Array[String] = []
		for country in trip.route: names.append(GameCatalog.country_name(country))
		copy(" → ".join(names), 18)
		copy("★ Adventure badge collected" if "trip:" + id in profile.badges else "Complete all three in one run for your badge.", 16)
		var trip_key: String = id
		action("START " + trip.name.to_upper(), true, func(): trip_requested.emit(trip_key))
	action("BACK", false, show_main)

func show_goals() -> void:
	clear("Collection goals", "Explore the world to earn passport covers. Cosmetics never change your gameplay.")
	var earned := TravelGoals.earned_covers(profile.discoveries)
	for id in TravelGoals.TRIPS:
		var goal: Dictionary = TravelGoals.TRIPS[id]
		copy(goal.name + " · " + goal.cover + " cover", 23)
		for country in goal.route:
			copy(("✓ " if country in profile.discoveries else "○ ") + GameCatalog.country_name(country), 18)
		var cover_key: String = id
		var button := action("EQUIPPED" if profile.passport_cover == id else ("EQUIP " + goal.cover.to_upper() if id in earned else "COMPLETE THESE COUNTRIES TO UNLOCK"), id in earned, func(): profile.passport_cover = cover_key; profile.save(); show_goals())
		button.disabled = id not in earned or profile.passport_cover == id
		if "trip:" + id in profile.badges: copy("★ " + goal.name + " adventure badge", 17)
	copy("First-try country badges: %d" % profile.badges.filter(func(id: String): return id.begins_with("perfect:")).size(), 20)
	action("CLASSIC PASSPORT COVER", false, func(): profile.passport_cover = "classic"; profile.save(); show_goals())
	action("SHORT ADVENTURES", true, show_trips)
	action("MY PASSPORT", false, show_passport)
	action("MY SOUVENIRS", false, show_souvenirs)
	action("BACK", false, show_main)

func show_missions() -> void:
	var progress := profile.daily_progress()
	clear("Daily travel missions", "%s UTC · %d / 3 complete\nFresh goals every day. Play any free route." % [progress.date, profile.mission_count()])
	for item in [[progress.countries.size() >= 3, "Stamp three different destinations", "%d / 3 stamped today" % mini(progress.countries.size(), 3)], [progress.flawless, "Clear a country without falling", "A first-try clear earns this star."], [progress.trip, "Finish a short adventure", "Complete any three-country adventure."]]:
		copy(("★ " if item[0] else "○ ") + item[1], 23)
		copy("COMPLETE" if item[0] else item[2], 17)
	if profile.mission_count() == 3: copy("DAILY EXPLORER · All three stars earned!", 23)
	action("PLAY A SHORT ADVENTURE", true, show_trips)
	action("BACK", false, show_main)

func show_souvenirs() -> void:
	clear("My souvenirs", "%d keepsakes collected\nEvery stamped destination earns its own keepsake." % profile.discoveries.size())
	var search := LineEdit.new()
	search.placeholder_text = "Search your souvenirs"
	search.custom_minimum_size.y = 54
	content.add_child(search)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	content.add_child(list)
	var fill := func(query: String):
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
		for id in profile.discoveries:
			if not query.is_empty() and query.to_lower() not in (GameCatalog.country_name(id) + " " + DestinationTheme.souvenir(id)).to_lower(): continue
			var card := SouvenirCard.new()
			card.destination_id = id
			list.add_child(card)
	if profile.discoveries.is_empty(): copy("Complete a destination to bring home your first souvenir.")
	search.text_changed.connect(fill)
	fill.call("")
	action("MY PASSPORT", false, show_passport)
	action("BACK", false, show_main)

func show_adventures() -> void:
	clear("Adventure Play", "Special mechanics, local scores. Ranked modes keep their usual rules.")
	for item in [["NO", "NORWAY · SLIPPERY ICE"], ["BR", "BRAZIL · MOVING BRIDGES"], ["GR", "GREECE · MOVING SEASIDE STONES"], ["MOON", "MOON · LOW GRAVITY · SPECIAL PACK"], ["UNDERWATER", "UNDERWATER · BUOYANT JUMPS · SPECIAL PACK"]]:
		var id: String = item[0]
		action(item[1], true, func(): adventure_requested.emit(id))
	action("BACK", false, show_main)

func show_wardrobe() -> void:
	clear("Explorer wardrobe", "Earn outfits and hats by exploring. Backpack colors match your earned passport covers.")
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size.y = 240
	holder.stretch = true
	content.add_child(holder)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 240)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	var actor := Traveler.new()
	actor.customization = profile.character_style.duplicate()
	actor.reduced_motion = profile.settings.reduced_motion
	viewport.add_child(actor)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 1.6, 4.5)
	camera.look_at(Vector3(0, 1.3, 0))
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 0, 0)
	viewport.add_child(light)
	for kind in ["outfit", "hat", "backpack"]:
		copy(kind.capitalize(), 23)
		var items: Dictionary = CharacterStyle.OUTFITS if kind == "outfit" else CharacterStyle.HATS if kind == "hat" else CharacterStyle.BACKPACKS
		for id in items:
			var key: String = id
			var group: String = kind
			var earned := CharacterStyle.unlocked(kind, id, profile.discoveries)
			var name: String = items[id].name if kind != "backpack" else (TravelGoals.TRIPS[id].cover if id in TravelGoals.TRIPS else "Classic")
			var label := name + (" · EQUIPPED" if profile.character_style[kind] == id else " · LOCKED" if not earned else " · EQUIP")
			if not earned: label += " · %d destinations" % items[id].count if kind != "backpack" else " · finish collection goal"
			var button := action(label, earned, func(): profile.character_style[group] = key; profile.save(); show_wardrobe())
			button.disabled = not earned or profile.character_style[kind] == id
	action("BACK", false, show_main)

func show_room() -> void:
	clear("My travel room", "Display six favorite souvenirs. Tap an earned keepsake below to add or remove it.")
	var room := SouvenirRoom.new()
	room.destinations = profile.room_display.duplicate()
	content.add_child(room)
	if profile.discoveries.is_empty(): copy("Your shelves are waiting for your first adventure.")
	for id in profile.discoveries:
		var key: String = id
		action(("✓ " if id in room.destinations else "+ ") + GameCatalog.country_name(id), false, func():
			if key in profile.room_display: profile.room_display.erase(key)
			elif profile.room_display.size() < 6: profile.room_display.append(key)
			profile.save()
			show_room()
		)
	action("MY SOUVENIRS", false, show_souvenirs)
	action("BACK", false, show_main)

func show_arcade() -> void:
	clear("Balloon Tour", "Split balloons, survive destination challenges and defeat armored bosses to stamp your passport. Mystery drops upgrade and combine weapons—or curse you. Dodge them or turn collection off in Pause.\nSolo: arrows or A/D + Space. Local co-op: choose it before START; P2 uses J/L + K, or their own touch buttons. Stay near a fallen teammate for 2 seconds to revive.")
	action("DAILY ARCADE · SAME CHALLENGE FOR EVERYONE", false, func(): arcade_requested.emit("daily"))
	action("WORLD BALLOON TOUR · 250 DESTINATIONS", true, func(): arcade_requested.emit("world"))
	action("SPECIAL BALLOON TOUR · EXPEDITIONS PACK", false, func(): arcade_requested.emit("special"))
	action("CINEMA BALLOON TOUR · CINEMA PACK", false, func(): arcade_requested.emit("cinema"))
	action("CHOOSE STARTING COUNTRY", false, show_countries)
	action("BACK", false, show_main)
