class_name MenuUI
extends CanvasLayer

signal start_requested(mode: String, difficulty: String)
signal challenge_requested(data: Dictionary)
signal settings_changed
signal home_country_selected(id: String)
signal difficulty_selected(key: String)
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
	for item in [["world", "WORLD TOUR"], ["infinite", "INFINITE MEMORY"], ["daily", "DAILY WORLD TOUR"], ["kids", "KIDS ADVENTURE"]]:
		var mode: String = item[0]
		mode_buttons[mode] = action(item[1], mode == "world", func(): request_mode(mode))
	action("CINEMA WORLDS · SEPARATE PAID ROUTE", false, show_cinema_route)
	action("SPECIAL EXPEDITIONS · PAID ROUTE", false, show_special_route)
	copy("Daily: same UTC date + difficulty = same route. Scores are local until online rankings are connected.", 15)
	if online_available:
		copy("Online play uses an anonymous account and syncs your passport.", 15)
		action("ONLINE DAILY", false, func(): start_requested.emit("online_daily", profile.difficulty))
		action("ONLINE INFINITE", false, func(): start_requested.emit("online_infinite", profile.difficulty))
		action("ONLINE RANKINGS", false, func(): online_records_requested.emit())
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
			control.visible = query.to_lower() in (control.text + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower()
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
	var panels: Dictionary = {}
	for id in GameCatalog.DESTINATIONS:
		var visited: bool = id in profile.discoveries
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", style.panel_style(Color("fff6df") if visited else Color("28546b"), 12))
		var text_label := style.label("  %s   %s\n  %s" % [id, GameCatalog.country_name(id), "STAMPED · " + str(GameCatalog.DESTINATIONS[id].region) if visited else "Waiting to be discovered"], 19, GameHUD.INK if visited else Color("c4dce5"))
		text_label.custom_minimum_size.y = 82
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(text_label)
		content.add_child(panel)
		panels[id] = panel
	search.text_changed.connect(func(query: String):
		for id in panels:
			panels[id].visible = query.to_lower() in (id + " " + GameCatalog.country_name(id) + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower()
	)
	if profile.discoveries.size() == GameCatalog.DESTINATIONS.size():
		copy("WORLD EXPLORER · Every destination sticker collected!", 21)
	action("MY TRAVEL STICKERS", false, show_stickers)
	copy("Recent journey", 22)
	var names: Array[String] = []
	for id in profile.history.slice(-12):
		names.append(GameCatalog.country_name(id))
	copy(" → ".join(names) if not names.is_empty() else "Complete a destination to collect your first stamp.")
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
	clear("Challenge a friend", "Paste a PR1 challenge code to play the exact same route and path. These are local challenges, without verified online rankings.")
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
			cards[id].visible = query.to_lower() in (GameCatalog.country_name(id) + " " + str(GameCatalog.DESTINATIONS[id].aliases)).to_lower()
	)
	action("BACK", false, show_main)

func purchase_changed() -> void:
	if cinema_page and root.visible:
		show_cinema_route()
	elif special_page and root.visible:
		show_special_route()
