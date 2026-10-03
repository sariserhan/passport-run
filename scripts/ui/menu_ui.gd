class_name MenuUI
extends CanvasLayer

signal activity_route_requested(data: Dictionary)
signal activity_sound_requested(key: String)
var photo_draft: Dictionary = {}
var photo_return := Callable()
signal start_requested(mode: String, difficulty: String)
signal challenge_requested(data: Dictionary)
signal settings_changed
signal home_country_selected(id: String)
signal difficulty_selected(key: String)
signal trip_requested(id: String)
signal adventure_requested(id: String)
signal arcade_requested(kind: String)
signal arcade_practice_requested(id: String)
signal cinema_requested(id: String)
signal special_requested(id: String)
signal online_records_requested
var export_busy := false
var online_available := false
var revision := 0
var purchase: RoutePurchase
var character_purchase: RoutePurchase
var wardrobe_page := false
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
var pending_arcade: String = ""
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
	artwork.texture = preload("res://assets/realistic/menu.png")
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
	wardrobe_page = false
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
	if profile.world_champion() and not profile.champion_seen:
		show_champion()
		return
	var pending_regions := TravelMilestones.earned(profile.discoveries).filter(func(name): return name not in profile.regions_seen)
	if not pending_regions.is_empty():
		show_region_celebration(pending_regions[0])
		return
	clear("PASSPORT\nRUN", "Remember the path. Travel the world.")
	var title: Label = content.get_child(0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("ffda65"))
	var hero := TextureRect.new()
	hero.texture = preload("res://assets/realistic/menu.png")
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.custom_minimum_size.y = 210
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(hero)
	home_button = action("Start: " + GameCatalog.country_name(profile.home_country) + " · LOCKED" if profile.home_country in GameCatalog.FREE_DESTINATIONS else "CHOOSE YOUR START · ONE TIME", false, show_countries)
	home_button.disabled = profile.home_country in GameCatalog.FREE_DESTINATIONS
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
		if mode == "daily" and not profile.can_visit_route(GameCatalog.COUNTRIES.keys()):
			mode_buttons[mode].text = "? · DAILY WORLD TOUR · REACH ITS STOPS FIRST"
			mode_buttons[mode].disabled = true
	action("MORE ADVENTURES & CREATIVE TOOLS", false, func(): TravelActivityUI.new(self).show("hub"))
	action("DEPARTURE LOUNGE", false, func(): TravelActivityUI.new(self).show("lounge"))
	action("COLLECTION GOALS", false, show_goals)
	action("MY TRAVEL ROOM", false, show_room)
	action("MY TRAVEL ALBUM", false, show_album)
	action("TRAVEL BUDDIES", false, show_buddies)
	action("TODAY’S TRAVEL JOURNAL", false, show_journal)
	if profile.world_champion(): action("WORLD CHAMPION · RELIVE YOUR JOURNEY", false, show_champion)
	action("REGIONAL TROPHIES", false, show_regions)
	action("RARE KEEPSAKE CHALLENGES", false, show_rare_challenges)
	action("REPLAY MY JOURNEY", false, show_replay)
	action("CHARACTER QUESTS", false, show_character_quests)
	action("EXPLORER WARDROBE", false, show_wardrobe)
	action("DAILY TRAVEL MISSIONS", false, show_missions)
	action("CINEMA WORLDS · SEPARATE PAID ROUTE", false, show_cinema_route)
	action("SPECIAL EXPEDITIONS · PAID ROUTE", false, show_special_route)
	copy("Daily: same UTC date + difficulty = same route. Scores are local until online rankings are connected.", 15)
	if online_available:
		copy("Online play uses an anonymous account and syncs your passport.", 15)
		var daily_online := action("ONLINE DAILY", false, func(): start_requested.emit("online_daily", profile.difficulty))
		daily_online.disabled = not profile.can_visit_route(GameCatalog.COUNTRIES.keys())
		if daily_online.disabled: daily_online.text = "? · ONLINE DAILY · REACH ITS STOPS FIRST"
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
	if profile.home_country in GameCatalog.FREE_DESTINATIONS:
		var mode := pending_mode
		var kind := pending_arcade
		pending_mode = ""
		pending_arcade = ""
		if not kind.is_empty(): arcade_requested.emit(kind)
		elif not mode.is_empty(): start_requested.emit(mode, profile.difficulty)
		else: show_main()
		return
	clear("Where should your\njourney begin?", "Choose once. Your starting country is permanent. We plan the route; clear each destination to reveal the next.")
	var search := LineEdit.new()
	search.placeholder_text = "Search countries and territories"
	search.custom_minimum_size.y = 54
	search.add_theme_font_size_override("font_size", 20)
	content.add_child(search)
	var buttons: Array[Button] = []
	for id in GameCatalog.sorted_destinations():
		var country: String = id
		var control := action(country + "   " + GameCatalog.country_name(country), country == profile.home_country, func():
			if not profile.choose_start_country(country):
				copy(profile.last_error if not profile.last_error.is_empty() else "Your starting country is already locked.")
				return
			home_country_selected.emit(country)
			if not pending_arcade.is_empty():
				var kind := pending_arcade
				pending_arcade = ""
				arcade_requested.emit(kind)
			elif not pending_mode.is_empty():
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
	action("BACK", false, func(): pending_mode = ""; pending_arcade = ""; show_main())

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
	book.profile = profile
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
	action("MY TRAVEL ALBUM", false, show_album)
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
	for item in [["reduced_motion", "Reduced motion"], ["high_contrast", "High-contrast path preview"], ["haptics", "Vibration on supported devices"], ["arcade_swap", "Balloon fire button on the left"], ["arcade_large", "Larger balloon touch controls"]]:
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
	copy("Starting country: " + GameCatalog.country_name(profile.home_country) + " · permanent" if profile.home_country in GameCatalog.FREE_DESTINATIONS else "Choose your starting country when you begin your first tour.", 15)
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
		if place in profile.discoveries:
			var artwork := TravelArtwork.new()
			artwork.country_id = place
			artwork.show_traveler = false
			artwork.custom_minimum_size.y = 145
			card.add_child(artwork)
		else:
			card.add_child(style.label("? · Scenery revealed when you reach this destination", 17, GameHUD.CREAM))
		var play := style.button("PLAY " + GameCatalog.country_name(place).to_upper() if manager and manager.unlocked else "LOCKED · ROUTE PACK REQUIRED", manager and manager.unlocked)
		play.disabled = not manager or not manager.unlocked or manager.busy or not profile.can_visit(place)
		if manager and manager.unlocked and not profile.can_visit(place): play.text = "? · REACH THIS STOP TO UNLOCK"
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
		var play := action("START " + trip.name.to_upper() if profile.can_visit_route(trip.route) else "? · REACH THESE STOPS TO UNLOCK", true, func(): trip_requested.emit(trip_key))
		play.disabled = not profile.can_visit_route(trip.route)
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
	clear("My souvenirs", "%d keepsakes collected\nEvery completed destination earns a local keepsake. Repeat clears earn another copy." % profile.discoveries.size())
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
			card.quantity = int(profile.souvenir_counts.get(id, 1))
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
		var play := action(item[1] if profile.can_visit(id) else "? · SPECIAL MECHANIC · REACH THIS STOP FIRST", true, func(): adventure_requested.emit(id))
		play.disabled = not profile.can_visit(id)
	action("BACK", false, show_main)

func show_wardrobe() -> void:
	clear("Explorer wardrobe", "Choose a human, animal, space or fantasy traveler. Explore to unlock more, or buy the traveler pack. Clear every world destination for World Champion.")
	wardrobe_page = true
	copy(CharacterStyle.CHARACTERS[profile.equipped_character()].name, 24)
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
	actor.character_id = profile.equipped_character()
	actor.customization = profile.character_style.duplicate()
	actor.reduced_motion = profile.settings.reduced_motion
	viewport.add_child(actor)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 1.4, 3.0)
	camera.look_at(Vector3(0, 1.3, 0))
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 0, 0)
	viewport.add_child(light)
	copy("Travelers", 23)
	copy("Clear all %d world destinations to unlock World Champion." % GameCatalog.FREE_DESTINATIONS.size(), 17)
	var previous_group := ""
	for id in CharacterStyle.CHARACTERS:
		var key: String = id
		var item: Dictionary = CharacterStyle.CHARACTERS[id]
		var group: String = item.get("group", "Human travelers")
		if group != previous_group:
			copy(group, 23)
			previous_group = group
		var earned := CharacterStyle.character_unlocked(id, profile.discoveries, profile.character_pack_unlocked)
		var portrait := TextureRect.new()
		portrait.texture = CharacterStyle.character_texture(id)
		portrait.custom_minimum_size = Vector2(0, 130)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(portrait)
		var label: String = item.name + (" · EQUIPPED" if profile.equipped_character() == id else " · EQUIP" if earned else " · CLEAR THE WORLD" if item.has("world") else " · %d destinations, quest or pack" % item.count if id in CharacterQuests.QUESTS else " · %d destinations or character pack" % item.count)
		var button := action(label, earned, func(): profile.character_id = key; profile.save(); show_wardrobe())
		button.disabled = not earned or profile.equipped_character() == id
	if character_purchase:
		copy(character_purchase.message, 17)
		var buy := action("BUY TRAVELER PACK " + character_purchase.price, true, character_purchase.purchase)
		buy.disabled = character_purchase.busy or character_purchase.price.is_empty() or character_purchase.unlocked
		var restore := action("RESTORE CHARACTER PURCHASE", false, character_purchase.restore)
		restore.disabled = character_purchase.busy or not character_purchase.store
	if CharacterStyle.CHARACTERS[profile.equipped_character()].get("fantasy_art", false):
		copy("This traveler wears its own signature gear. Outfit colors still apply.", 17)
	for kind in ["outfit", "hat", "backpack"]:
		copy(kind.capitalize(), 23)
		var items: Dictionary = CharacterStyle.OUTFITS if kind == "outfit" else CharacterStyle.HATS if kind == "hat" else CharacterStyle.BACKPACKS
		for id in items:
			var key: String = id
			var group: String = kind
			var earned := CharacterStyle.unlocked(kind, id, profile.discoveries, profile.badges)
			var name: String = items[id].name if kind != "backpack" else (TravelGoals.TRIPS[id].cover if id in TravelGoals.TRIPS else "Classic")
			var label := name + (" · EQUIPPED" if profile.character_style[kind] == id else " · LOCKED" if not earned else " · EQUIP")
			if not earned:
				if items[id] is Dictionary and items[id].has("badge"):
					copy("Unlock: " + ArcadeAchievements.BADGES[items[id].badge].name, 17)
				else: label += " · %d destinations" % items[id].count if kind != "backpack" else " · finish collection goal"
			var button := action(label, earned, func(): profile.character_style[group] = key; profile.save(); show_wardrobe())
			button.disabled = not earned or profile.character_style[kind] == id
	action("CHARACTER QUESTS", false, show_character_quests)
	action("BACK", false, show_main)

func show_room() -> void:
	clear("My travel room", "Drag keepsakes to arrange them. Hang three country postcards and decorate with rewards from your travels.")
	var room := SouvenirRoom.new()
	room.destinations = profile.room_display.duplicate()
	room.postcards = profile.room_postcards.duplicate()
	room.decor = profile.room_decor.duplicate()
	room.rare_keepsakes = profile.rare_keepsakes.duplicate(true)
	room.buddy_kind = profile.travel_buddy
	room.profile = profile
	room.positions = profile.room_positions.duplicate(true)
	room.souvenir_selected.connect(func(id: String): TravelActivityUI.new(self).show("souvenirs", id))
	room.arrangement_changed.connect(func(points: Dictionary): profile.room_positions = points; profile.save())
	content.add_child(room)
	copy("Room spaces", 23)
	for space in [["main", "Travel room", 0], ["balcony", "Balcony", 6], ["nook", "Reading nook", 12], ["gallery", "Expedition gallery", 20]]:
		var key: String = space[0]
		var button := action(("✓ " if profile.activities.room.space == key else "") + space[1] + (" · %d destinations" % space[2] if profile.discoveries.size() < space[2] else ""), false, func(): profile.switch_room_space(key); show_room())
		button.disabled = profile.discoveries.size() < space[2]
	action("SWITCH THE LAMPS", false, func(): profile.room_interact("lamp"); room.queue_redraw())
	if profile.room_decor.furniture == "armchair": action("SIT / STAND", false, func(): profile.room_interact("seated"); room.queue_redraw())
	if profile.room_decor.buddy_bed != "none": action("WAKE / REST MY BUDDY", false, func(): profile.room_interact("resting"); room.queue_redraw())
	action("EXPORT ROOM PICTURE", false, func(): export_picture("room"))
	copy("Souvenir sets", 23)
	for key in TravelCollections.SETS:
		var names: Array[String] = []
		for id in TravelCollections.SETS[key].route: names.append(("✓ " if id in profile.discoveries else "○ ") + GameCatalog.country_name(id))
		copy(TravelCollections.SETS[key].name + " · " + ", ".join(names), 17)
	action("RESET SOUVENIR POSITIONS", false, func(): profile.room_positions.clear(); profile.save(); show_room())
	copy("Decorate your room", 23)
	for kind in RoomDecor.ITEMS:
		var group: String = kind
		copy(kind.capitalize(), 18)
		var choices := OptionButton.new()
		choices.custom_minimum_size.y = 54
		choices.add_theme_font_size_override("font_size", 18)
		for id in RoomDecor.ITEMS[kind]:
			var item: Dictionary = RoomDecor.ITEMS[kind][id]
			var earned := RoomDecor.unlocked(kind, id, profile.discoveries)
			choices.add_item(item.name + ("" if earned else (" · Complete its souvenir set" if kind == "display" else " · Complete this region" if kind == "trophy" else " · %d destinations" % item.count)))
			var index := choices.item_count - 1
			choices.set_item_metadata(index, id)
			choices.set_item_disabled(index, not earned)
			if profile.room_decor[kind] == id: choices.select(index)
		choices.item_selected.connect(func(index: int):
			var id: String = choices.get_item_metadata(index)
			if RoomDecor.unlocked(group, id, profile.discoveries):
				profile.room_decor[group] = id
				profile.save()
				room.decor = profile.room_decor.duplicate()
				room.layout()
		)
		content.add_child(choices)
	copy("Souvenirs · %d / 6 displayed" % room.destinations.size(), 23)
	if room.destinations.size() == 6: copy("Remove a keepsake to make room for another.", 17)
	if profile.discoveries.is_empty(): copy("Your shelves are waiting for your first adventure.")
	for id in profile.discoveries:
		var key: String = id
		var button := action(("✓ " if id in room.destinations else "+ ") + GameCatalog.country_name(id) + " · " + DestinationTheme.souvenir(id), false, func():
			if key in profile.room_display:
				profile.room_display.erase(key)
				profile.room_positions.erase(key)
			elif profile.room_display.size() < 6: profile.room_display.append(key)
			profile.save()
			show_room()
		)
		button.disabled = room.destinations.size() == 6 and id not in room.destinations
	copy("Wall postcards · %d / 3 hung" % profile.room_postcards.size(), 23)
	for id in profile.discoveries:
		var key: String = id
		var button := action(("✓ " if id in profile.room_postcards else "+ ") + GameCatalog.country_name(id) + " postcard", false, func():
			if key in profile.room_postcards: profile.room_postcards.erase(key)
			elif profile.room_postcards.size() < 3: profile.room_postcards.append(key)
			profile.save()
			show_room()
		)
		button.disabled = profile.room_postcards.size() == 3 and id not in profile.room_postcards
	action("MY SOUVENIRS", false, show_souvenirs)
	action("MY TRAVEL ALBUM", false, show_album)
	action("BACK", false, show_main)

func show_character_quests() -> void:
	clear("Character quests", "Collect the stamps in each themed quest to unlock its traveler. Your existing stamps count. Milestone and traveler-pack unlocks still work.")
	for id in CharacterQuests.QUESTS:
		var quest: Dictionary = CharacterQuests.QUESTS[id]
		var complete := CharacterQuests.complete(id, profile.discoveries)
		copy(("★ " if complete else "○ ") + quest.name, 24)
		var portrait := TextureRect.new()
		portrait.texture = CharacterStyle.character_texture(id)
		portrait.custom_minimum_size.y = 110
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(portrait)
		copy("Reward: " + CharacterStyle.CHARACTERS[id].name + " · %d / %d" % [CharacterQuests.count(id, profile.discoveries), quest.route.size()], 18)
		for country in quest.route:
			copy(("✓ " if country in profile.discoveries else "○ ") + GameCatalog.country_name(country), 17)
		if complete: copy("QUEST COMPLETE · Equip your traveler in the wardrobe.", 17)
		elif quest.route.any(func(place): return place in GameCatalog.PREMIUM_DESTINATIONS or place in GameCatalog.CINEMA_DESTINATIONS):
			copy("These stops are on special routes. You can also use the destination milestone or traveler pack.", 17)
	action("CONTINUE WORLD TOUR", true, func(): request_mode("world"))
	action("EXPLORER WARDROBE", false, show_wardrobe)
	action("BACK", false, show_main)

func show_album() -> void:
	clear("My travel album", "Country pictures, keepsakes, facts and personal bests from your completed destinations.")
	var search := LineEdit.new()
	search.placeholder_text = "Find a country or souvenir"
	search.custom_minimum_size.y = 54
	content.add_child(search)
	var state := {"ids": profile.discoveries.duplicate(), "index": 0}
	var counter := copy("")
	var page := VBoxContainer.new()
	content.add_child(page)
	var navigation := HBoxContainer.new()
	content.add_child(navigation)
	var previous := style.button("← PREVIOUS", false)
	var next := style.button("NEXT →", true)
	for button in [previous, next]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(button)
	var update := func():
		for child in page.get_children():
			page.remove_child(child)
			child.queue_free()
		previous.disabled = state.index <= 0
		next.disabled = state.index + 1 >= state.ids.size()
		counter.text = "Complete a destination to start your album." if profile.discoveries.is_empty() else "No matching destinations." if state.ids.is_empty() else "Page %d of %d" % [state.index + 1, state.ids.size()]
		if not state.ids.is_empty():
			var album := TravelAlbumPage.new()
			album.destination_id = state.ids[state.index]
			album.profile = profile
			page.add_child(album)
	previous.pressed.connect(func(): state.index -= 1; update.call())
	next.pressed.connect(func(): state.index += 1; update.call())
	search.text_changed.connect(func(query: String):
		state.ids = profile.discoveries.filter(func(id): return query.is_empty() or query.to_lower() in (GameCatalog.country_name(id) + " " + DestinationTheme.souvenir(id)).to_lower())
		state.index = 0
		update.call()
	)
	update.call()
	action("EXPORT THIS ALBUM PAGE", false, func():
		if not state.ids.is_empty(): export_picture("album", state.ids[state.index])
	)
	action("MY TRAVEL ROOM", false, show_room)
	action("MY PASSPORT", false, show_passport)
	action("BACK", false, show_main)

func show_arcade() -> void:
	clear("Balloon Tour", "Clear three rounds at each destination to reveal the next. Your route is planned for you. One balloon hit ends the game.\nMove ◀ ▶ and FIRE ↑. Keyboard: arrows or A/D + Space. Co-op: P2 uses J/L + K. Mystery drops can help or hurt; collect or avoid them in Pause.")
	if profile.home_country in GameCatalog.FREE_DESTINATIONS:
		copy("Start: " + GameCatalog.country_name(profile.home_country) + " · permanent", 17)
	var daily := action("DAILY ARCADE" if profile.can_visit(BalloonArcade.daily_destination(GameCatalog.today_utc())) else "? · DAILY ARCADE · REACH THIS STOP FIRST", false, func(): arcade_requested.emit("daily"))
	daily.disabled = not profile.can_visit(BalloonArcade.daily_destination(GameCatalog.today_utc()))
	action("WORLD BALLOON TOUR · 250 DESTINATIONS", true, func(): request_arcade("world"))
	action("SPECIAL BALLOON TOUR · EXPEDITIONS PACK", false, func(): arcade_requested.emit("special"))
	action("CINEMA BALLOON TOUR · CINEMA PACK", false, func(): arcade_requested.emit("cinema"))
	action("PRACTICE VISITED DESTINATIONS", false, show_arcade_practice)
	action("BALLOON ACHIEVEMENTS", false, show_arcade_achievements)
	action("BALLOON DAILY GOALS", false, show_arcade_daily_goals)
	action("MYSTERY-DROP JOURNAL", false, show_arcade_drop_journal)
	action("DESTINATION MASTERY", false, show_arcade_mastery)
	if profile.home_country not in GameCatalog.FREE_DESTINATIONS:
		action("CHOOSE STARTING COUNTRY · ONE TIME", false, show_countries)
	action("BACK", false, show_main)

func request_arcade(kind: String) -> void:
	if kind == "world" and profile.home_country not in GameCatalog.FREE_DESTINATIONS:
		pending_arcade = kind
		show_countries()
		return
	arcade_requested.emit(kind)

func show_arcade_practice() -> void:
	clear("Balloon practice", "Replay a stamped destination. Your tour, coins, achievements and passport stay where you left them. Practice has separate local best scores.")
	if profile.discoveries.is_empty(): copy("Earn your first passport stamp to unlock practice.")
	for id in profile.discoveries:
		var place: String = id
		var owned := (id not in GameCatalog.PREMIUM_DESTINATIONS or (purchase and purchase.unlocked)) and (id not in GameCatalog.CINEMA_DESTINATIONS or (cinema_purchase and cinema_purchase.unlocked))
		var button := action("PRACTICE " + GameCatalog.country_name(id).to_upper() if owned else "PACK REQUIRED · " + GameCatalog.country_name(id).to_upper(), owned, func(): arcade_practice_requested.emit(place))
		button.disabled = not owned
	action("BACK", false, show_arcade)

func show_arcade_achievements() -> void:
	clear("Balloon achievements", "%d lifetime pops · Tour attempts count; practice does not. Rewards appear in your Explorer wardrobe." % profile.arcade_pops)
	for id in ArcadeAchievements.BADGES:
		var badge: Dictionary = ArcadeAchievements.BADGES[id]
		copy(("★ " if id in profile.badges else "○ ") + badge.name, 23)
		copy(badge.description, 17)
		copy("Reward: " + CharacterStyle.OUTFITS[badge.outfit].name, 16)
	action("EXPLORER WARDROBE", true, show_wardrobe)
	action("BACK", false, show_arcade)

func show_arcade_daily_goals() -> void:
	var progress := profile.arcade_daily_progress()
	clear("Balloon daily goals", "Three goals for " + progress.date + " UTC. Tour attempts count; practice does not. New goals reset at midnight UTC.")
	var complete := 0
	for key in ArcadeProgress.DAILY:
		var goal: Array = ArcadeProgress.DAILY[key]
		var done: bool = progress[key] >= goal[1]
		complete += int(done)
		copy(("★ " if done else "○ ") + goal[0], 22)
		copy("%d / %d" % [progress[key], goal[1]], 18)
	copy("DAILY EXPLORER · All three complete" if complete == 3 else "%d of 3 completed" % complete, 21)
	action("BACK", false, show_arcade)

func show_arcade_drop_journal() -> void:
	clear("Mystery-drop journal", "%d / %d discovered. Collect a mystery drop during your tour to reveal its effects here. Every falling drop keeps the same sealed appearance." % [profile.arcade_drop_journal.size(), ArcadeProgress.DROPS.size()])
	for kind in ArcadeProgress.DROPS:
		if kind in profile.arcade_drop_journal:
			copy(ArcadeProgress.DROPS[kind][0], 22)
			copy(ArcadeProgress.DROPS[kind][1], 17)
		else:
			copy("? · Undiscovered drop", 20)
	action("BACK", false, show_arcade)

func show_arcade_mastery() -> void:
	clear("Destination mastery", "Medals are saved separately for each difficulty and solo/co-op. Bronze: clear three rounds. Silver: at most 2 retries, 3:30 total play time and a ×3 combo. Gold: zero retries, 2:30 total play time and a ×5 combo. Failed-attempt time counts. Practice gives feedback without awarding medals.")
	if profile.discoveries.is_empty(): copy("Your first destination medal awaits.")
	for id in profile.discoveries:
		copy(GameCatalog.country_name(id), 23)
		var highest := 0
		for key in profile.arcade_mastery:
			if key.begins_with(id + ":"): highest = maxi(highest, profile.arcade_mastery[key])
		if highest > 0:
			var medal_image := TextureRect.new()
			medal_image.texture = RealisticArt.medal(highest)
			medal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			medal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			medal_image.custom_minimum_size.y = 100
			content.add_child(medal_image)
		for difficulty in GameCatalog.DIFFICULTIES:
			var solo: int = profile.arcade_mastery.get(ArcadeProgress.mastery_key(id, difficulty, false), 0)
			var team: int = profile.arcade_mastery.get(ArcadeProgress.mastery_key(id, difficulty, true), 0)
			copy("%s · Solo: %s · Co-op: %s" % [difficulty.capitalize(), ArcadeProgress.MEDALS[solo], ArcadeProgress.MEDALS[team]], 16)
	action("BACK", false, show_arcade)

func show_locked_destination() -> void:
	clear("A mystery awaits", "Reach this destination in your tour first. Its scenery stays hidden until you clear the previous stop.")
	action("CONTINUE MY BALLOON TOUR", true, func(): request_arcade("world"))
	action("BACK", false, show_main)

func show_buddies() -> void:
	clear("Travel buddies", "Choose a tiny friend to accompany your travels. They cheer, jump and react with you.")
	for friend in BuddyPersonality.FRIENDS:
		var preview := BuddyPreview.new()
		preview.kind = friend
		preview.reduced_motion = profile.settings.reduced_motion
		content.add_child(preview)
		copy(BuddyPersonality.FRIENDS[friend].name + " · " + BuddyPersonality.FRIENDS[friend].description, 18)
	for id in ["none", "bird", "robot", "dragon"]:
		var key: String = id
		action(("✓ " if profile.travel_buddy == id else "") + {"none": "Travel solo", "bird": "Pip · Little bird", "robot": "Orbit · Floating robot", "dragon": "Ember · Baby dragon"}[id], false, func(): profile.travel_buddy = key; profile.save(); show_buddies())
	action("BACK", false, show_main)

func show_journal() -> void:
	clear("Daily travel journal", GameCatalog.today_utc() + " · UTC")
	var postcard := TravelJournalPostcard.new()
	postcard.page = profile.journal_page(GameCatalog.today_utc())
	content.add_child(postcard)
	action("SHARE TODAY’S POSTCARD", false, func(): export_picture("journal", GameCatalog.today_utc()))
	var dates := profile.journal_pages.keys()
	dates.sort()
	dates.reverse()
	for date in dates:
		if date != GameCatalog.today_utc():
			var key: String = date
			action("POSTCARD · " + key, false, func(): show_journal_postcard(key))
	var countries: Array = profile.daily_progress().countries
	copy("Today’s completed countries", 23)
	if countries.is_empty(): copy("Your next journey starts today’s page.")
	for id in countries: copy(GameCatalog.country_name(id), 18)
	var journal := profile.journal_today()
	for field in ["moments", "rewards"]:
		copy("Best moments" if field == "moments" else "New rewards", 23)
		if journal[field].is_empty(): copy("Keep traveling to fill this section.", 17)
		for entry in journal[field]: copy(entry, 18)
	action("BACK", false, show_main)

func show_champion() -> void:
	clear("WORLD CHAMPION", "Every country and territory in the free World Tour completed. Your passport tells an extraordinary story.")
	var celebration := WorldCelebration.new()
	celebration.reduced_motion = profile.settings.reduced_motion
	celebration.palette = profile.activities.custom.confetti
	content.add_child(celebration)
	var art := TravelArtwork.new()
	art.country_id = profile.history.back() if not profile.history.is_empty() else "FR"
	art.custom_minimum_size.y = 250
	content.add_child(art)
	copy("★ WORLD CHAMPION ★", 32)
	copy("%d destinations · %d souvenirs collected" % [profile.discoveries.size(), profile.souvenir_counts.values().reduce(func(total, count): return total + int(count), 0)], 22)
	copy("Your journey", 23)
	var names: Array[String] = []
	for id in profile.discoveries.slice(0, 12): names.append(GameCatalog.country_name(id))
	copy(" → ".join(names) + (" → … +%d more destinations" % (profile.discoveries.size() - 12) if profile.discoveries.size() > 12 else ""), 17)
	copy("Your souvenir collection", 23)
	var room := SouvenirRoom.new()
	room.destinations = profile.room_display.duplicate()
	room.postcards = profile.room_postcards.duplicate()
	room.decor = profile.room_decor.duplicate()
	room.rare_keepsakes = profile.rare_keepsakes.duplicate(true)
	room.buddy_kind = profile.travel_buddy
	room.profile = profile
	room.positions = profile.room_positions.duplicate(true)
	content.add_child(room)
	action("CELEBRATE & CONTINUE", true, func(): profile.champion_seen = true; profile.save(); show_main())

func export_picture(kind: String, id: String = "") -> void:
	if export_busy: return
	export_busy = true
	var message := copy("Preparing your picture…", 17)
	var filename := "passport-run-" + kind + ".png"
	var path := "user://" + filename
	var error: Error = await TravelPicture.save_picture(self, profile, kind, id, path, photo_draft)
	if error == OK and kind == "photo":
		profile.activity_tick("photo")
		profile.timeline_note("Travel photo · " + GameCatalog.country_name(id))
		profile.save()
	if error == OK and OS.get_name() == "iOS":
		var state: String = await NativePictureShare.request(self, filename)
		if is_instance_valid(message): message.text = "Choose an app in the share sheet." if state == "opened" else "Picture shared." if state == "shared" else "Sharing cancelled. Your picture is saved." if state == "cancelled" else "Picture saved. The share sheet could not open; try sharing again."
	else:
		if is_instance_valid(message): message.text = "Picture saved: " + ProjectSettings.globalize_path(path) if error == OK else "Could not save picture. Please try again."
		if error == OK and OS.has_feature("desktop"): OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
	export_busy = false

func show_journal_postcard(date: String) -> void:
	clear("My travel postcard", date + " · UTC")
	var postcard := TravelJournalPostcard.new()
	postcard.page = profile.journal_page(date)
	content.add_child(postcard)
	action("SHARE THIS POSTCARD", false, func(): export_picture("journal", date))
	action("BACK", false, show_journal)

func show_regions() -> void:
	clear("Regional trophies", "Complete every free country and territory in a region to earn its explorer trophy.")
	var counts := TravelMilestones.progress(profile.discoveries)
	for name in TravelMilestones.CONTINENTS:
		copy("%s · %d / %d" % [name, counts[name].completed, counts[name].total], 23)
		if name in TravelMilestones.earned(profile.discoveries):
			var key: String = name
			action("★ RELIVE " + name.to_upper(), false, func(): show_region_celebration(key))
	action("MY TRAVEL ROOM", false, show_room)
	action("BACK", false, show_main)

func show_region_celebration(name: String) -> void:
	clear(name + " EXPLORER", "Every country and territory in " + name + " completed. Your explorer trophy is ready for your room!")
	var celebration := WorldCelebration.new()
	celebration.reduced_motion = profile.settings.reduced_motion
	celebration.palette = profile.activities.custom.confetti
	content.add_child(celebration)
	var map := PassportWorldMap.new()
	map.discoveries.assign(profile.discoveries.filter(func(id): return id in GameCatalog.FREE_DESTINATIONS and TravelMilestones.continent(id) == name))
	content.add_child(map)
	copy("★ " + name + " explorer trophy", 28)
	action("DISPLAY MY TROPHY", true, func():
		profile.room_decor.trophy = name
		if name not in profile.regions_seen: profile.regions_seen.append(name)
		profile.save()
		show_room()
	)
	action("CONTINUE", false, func():
		if name not in profile.regions_seen: profile.regions_seen.append(name)
		profile.save()
		show_main()
	)

func show_rare_challenges() -> void:
	clear("Hidden keepsakes", "Optional challenges reward rare versions of each destination’s souvenir. Normal souvenirs are always yours when you finish.")
	copy("Gold · Complete a memory-path destination without any failed attempt.", 21)
	copy("Crystal · Clear all three Balloon Tour rounds at a destination without retries or collecting mystery drops. Practice does not earn keepsakes.", 21)
	if profile.discoveries.is_empty(): copy("Complete a destination to start your rare collection.")
	for id in profile.discoveries:
		var owned: Array = profile.rare_keepsakes.get(id, [])
		copy(GameCatalog.country_name(id) + " · " + ("★ Gold" if "gold" in owned else "○ Gold") + " · " + ("★ Crystal" if "crystal" in owned else "○ Crystal"), 18)
	action("MY TRAVEL ALBUM", false, show_album)
	action("BACK", false, show_main)

func show_replay() -> void:
	clear("My journey replay", "Follow your passport stamps in the order you first earned them. Pause, change speed or scrub to a favorite destination.")
	var replay := JourneyReplay.new()
	replay.profile = profile
	content.add_child(replay)
	action("BACK", false, show_main)
