class_name PlayerProfile
extends RefCounted

const SCHEMA_VERSION: int = 1
var file_path: String
var home_country: String = ""
var difficulty: String = "easy"
var anonymous_id: String = ""
var tutorial_done: bool = false
var discoveries: Array[String] = []
var history: Array[String] = []
var records: Dictionary = {}
var badges: Array[String] = []
var passport_cover := "classic"
var daily_missions: Dictionary = {}
var character_style := {"outfit": "classic", "hat": "none", "backpack": "classic"}
var character_id := "classic"
var character_pack_unlocked := false
var souvenir_counts: Dictionary = {}
var room_display: Array[String] = []
var arcade_saves: Dictionary = {}
var arcade_pops := 0
var arcade_practice_records: Dictionary = {}
var arcade_mastery: Dictionary = {}
var arcade_drop_journal: Array[String] = []
var arcade_daily: Dictionary = {}
var cached_home := ""
var cached_tour: Array[String] = []
var settings: Dictionary = {"music": 0.35, "sound": 0.65, "reduced_motion": false, "high_contrast": false, "haptics": true, "arcade_swap": false, "arcade_large": false}
var last_error: String = ""

func _init(path: String = "user://profile.json") -> void:
	file_path = path
	anonymous_id = Crypto.new().generate_random_bytes(16).hex_encode()
	load_profile()

func load_profile() -> void:
	var data: Dictionary = read_valid(file_path)
	if data.is_empty():
		data = read_valid(file_path + ".bak")
	if data.is_empty():
		return
	if data.get("home_country", "") in GameCatalog.DESTINATIONS:
		home_country = data.home_country
	if data.get("difficulty", "") in GameCatalog.DIFFICULTIES:
		difficulty = data.difficulty
	if data.get("anonymous_id") is String and data.anonymous_id.length() == 32 and data.anonymous_id.is_valid_hex_number():
		anonymous_id = data.anonymous_id
	tutorial_done = data.get("tutorial_done", false) == true
	if data.get("arcade_pops") is float or data.get("arcade_pops") is int:
		arcade_pops = clampi(int(data.arcade_pops), 0, 10000000)
	arcade_daily = ArcadeProgress.clean_daily(data.get("arcade_daily"), GameCatalog.today_utc())
	if data.get("arcade_drop_journal") is Array:
		for kind in data.arcade_drop_journal:
			if kind is String and kind in ArcadeProgress.DROPS and kind not in arcade_drop_journal: arcade_drop_journal.append(kind)
	if data.get("arcade_mastery") is Dictionary:
		for key in data.arcade_mastery.keys().slice(0, 1692):
			if key is String and ArcadeProgress.valid_mastery_key(key) and (data.arcade_mastery[key] is int or data.arcade_mastery[key] is float): arcade_mastery[key] = clampi(int(data.arcade_mastery[key]), 0, 3)
	if data.get("arcade_saves") is Dictionary:
		for key in data.arcade_saves:
			if key is String and key in ["world", "special", "cinema", "daily:" + GameCatalog.today_utc()] and data.arcade_saves[key] is String and data.arcade_saves[key].length() <= ArcadeCheckpoint.MAX_ENCODED:
				arcade_saves[key] = data.arcade_saves[key]
	for field in ["discoveries", "history"]:
		if data.get(field) is Array:
			for id in data[field].slice(0, 200 if field == "history" else GameCatalog.DESTINATIONS.size()):
				if id is String and id in GameCatalog.DESTINATIONS:
					if field == "history":
						history.append(id)
					elif id not in discoveries:
						discoveries.append(id)
	if data.get("badges") is Array:
		for badge in data.badges.slice(0, 300):
			if badge is String and valid_badge(badge) and badge not in badges: badges.append(badge)
	if data.get("passport_cover", "classic") in TravelGoals.earned_covers(discoveries):
		passport_cover = data.get("passport_cover", "classic")
	for field in ["records", "arcade_practice_records"]:
		if data.get(field) is Dictionary:
			var target: Dictionary = get(field)
			for key in data[field].keys().slice(0, 200):
				if key is String and key.length() <= 64 and (data[field][key] is float or data[field][key] is int):
					target[key] = clampi(int(data[field][key]), 0, 10000000)
	var missions: Variant = data.get("daily_missions")
	if missions is Dictionary and missions.get("date") == GameCatalog.today_utc():
		daily_missions = {"date": missions.date, "countries": [], "flawless": missions.get("flawless") == true, "trip": missions.get("trip") == true}
		if missions.get("countries") is Array:
			for id in missions.countries.slice(0, GameCatalog.DESTINATIONS.size()):
				if id is String and id in discoveries and id not in daily_missions.countries:
					daily_missions.countries.append(id)
		if daily_missions.countries.is_empty():
			daily_missions.flawless = false
			daily_missions.trip = false
	if data.get("character_style") is Dictionary:
		for kind in character_style:
			var id: Variant = data.character_style.get(kind)
			if id is String and CharacterStyle.unlocked(kind, id, discoveries, badges): character_style[kind] = id
	if data.get("character_id") is String and data.character_id in CharacterStyle.CHARACTERS:
		character_id = data.character_id
	if data.get("souvenir_counts") is Dictionary:
		for id in discoveries:
			var amount: Variant = data.souvenir_counts.get(id, 1)
			if amount is int or amount is float: souvenir_counts[id] = clampi(int(amount), 1, 10000000)
	for id in discoveries:
		if id not in souvenir_counts: souvenir_counts[id] = 1
	if data.get("room_display") is Array:
		for id in data.room_display:
			if id is String and id in discoveries and id not in room_display and room_display.size() < 6: room_display.append(id)
	if data.get("settings") is Dictionary:
		for key in settings:
			var value: Variant = data.settings.get(key)
			if key in ["music", "sound"] and (value is int or value is float):
				settings[key] = clampf(float(value), 0, 1)
			elif value is bool and key not in ["music", "sound"]:
				settings[key] = value

func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 262144:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = parser.data
	if data is Dictionary and data.get("version") == SCHEMA_VERSION:
		return data
	return {}

func save() -> bool:
	var data := {"version": SCHEMA_VERSION, "anonymous_id": anonymous_id, "home_country": home_country, "difficulty": difficulty, "tutorial_done": tutorial_done, "discoveries": discoveries, "history": history, "records": records, "badges": badges, "passport_cover": passport_cover, "daily_missions": daily_missions, "character_style": character_style, "room_display": room_display, "settings": settings, "arcade_saves": arcade_saves}
	data["character_id"] = character_id
	data["souvenir_counts"] = souvenir_counts
	data["arcade_pops"] = arcade_pops
	data["arcade_practice_records"] = arcade_practice_records
	data["arcade_mastery"] = arcade_mastery
	data["arcade_drop_journal"] = arcade_drop_journal
	data["arcade_daily"] = arcade_daily
	var file := FileAccess.open(file_path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Progress could not be saved on this device."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	# Keep the previous valid version, then atomically replace the primary save.
	if not read_valid(file_path).is_empty():
		DirAccess.copy_absolute(file_path, file_path + ".bak")
	var error := DirAccess.rename_absolute(file_path + ".tmp", file_path)
	last_error = "" if error == OK else "Progress could not be saved on this device."
	return error == OK

func choose_start_country(id: String) -> bool:
	if home_country in GameCatalog.FREE_DESTINATIONS or id not in GameCatalog.FREE_DESTINATIONS:
		return false
	var previous := home_country
	home_country = id
	if save(): return true
	home_country = previous
	return false

func tour_route() -> Array[String]:
	if home_country not in GameCatalog.FREE_DESTINATIONS: return []
	if cached_home != home_country:
		cached_home = home_country
		cached_tour = RoutePlanner.tour(home_country)
	return cached_tour.duplicate()

func can_visit(id: String) -> bool:
	if id in discoveries: return true
	var free_route := tour_route()
	if not free_route.is_empty() and free_route[RoutePlanner.next_uncleared(free_route, discoveries)] == id: return true
	for catalog in [GameCatalog.PREMIUM_DESTINATIONS, GameCatalog.CINEMA_DESTINATIONS]:
		var ids: Array[String] = []
		ids.assign(catalog.keys())
		if ids[RoutePlanner.next_uncleared(ids, discoveries)] == id: return true
	return false

func can_visit_route(ids: Array) -> bool:
	return not ids.is_empty() and ids.all(func(id): return id is String and can_visit(id))

func discover(id: String) -> void:
	if id not in GameCatalog.DESTINATIONS:
		return
	if id not in discoveries:
		discoveries.append(id)
	souvenir_counts[id] = mini(10000000, int(souvenir_counts.get(id, 0)) + 1)
	if room_display.size() < 6 and id not in room_display: room_display.append(id)
	history.append(id)
	if history.size() > 200:
		history.pop_front()
	save()

func record(mode: String, difficulty_key: String, score: int, date: String = "") -> void:
	var key := mode + ":" + difficulty_key + (":" + date if not date.is_empty() else "")
	var target := arcade_practice_records if mode.begins_with("balloon-practice:") else records
	target[key] = maxi(int(target.get(key, 0)), score)
	while target.size() > 200:
		target.erase(target.keys()[0])
	save()

func best_score(mode: String, difficulty_key: String) -> int:
	var target := arcade_practice_records if mode.begins_with("balloon-practice:") else records
	return int(target.get(mode + ":" + difficulty_key, 0))

func valid_badge(id: String) -> bool:
	return id in ArcadeAchievements.BADGES or (id.begins_with("trip:") and id.trim_prefix("trip:") in TravelGoals.TRIPS) or (id.begins_with("perfect:") and id.trim_prefix("perfect:") in GameCatalog.DESTINATIONS)

func note_arcade_pop() -> bool:
	arcade_pops = mini(10000000, arcade_pops + 1)
	return arcade_pops >= 100 and award_badge("arcade:100_pops", false)

func arcade_daily_progress() -> Dictionary:
	arcade_daily = ArcadeProgress.clean_daily(arcade_daily, GameCatalog.today_utc())
	return arcade_daily

func note_arcade_goal(key: String) -> bool:
	if key not in ArcadeProgress.DAILY: return false
	var progress := arcade_daily_progress()
	var target: int = ArcadeProgress.DAILY[key][1]
	var previous: int = progress[key]
	progress[key] = mini(target, previous + 1)
	return previous < target and progress[key] == target

func discover_arcade_drop(kind: String) -> bool:
	if kind not in ArcadeProgress.DROPS or kind in arcade_drop_journal: return false
	arcade_drop_journal.append(kind)
	return true

func award_arcade_medal(id: String, key: String, coop: bool, medal: int) -> void:
	if id not in GameCatalog.DESTINATIONS or key not in GameCatalog.DIFFICULTIES: return
	var record_key := ArcadeProgress.mastery_key(id, key, coop)
	arcade_mastery[record_key] = maxi(int(arcade_mastery.get(record_key, 0)), clampi(medal, 1, 3))

func award_badge(id: String, persist: bool = true) -> bool:
	if not valid_badge(id) or id in badges: return false
	badges.append(id)
	if persist: save()
	return true

func daily_progress(date: String = "") -> Dictionary:
	if date.is_empty(): date = GameCatalog.today_utc()
	if daily_missions.get("date", "") != date:
		daily_missions = {"date": date, "countries": [], "flawless": false, "trip": false}
	return daily_missions

func advance_missions(id: String, flawless: bool, trip_finished: bool) -> void:
	if id not in discoveries: return
	var progress := daily_progress()
	if id not in progress.countries: progress.countries.append(id)
	progress.flawless = progress.flawless or flawless
	progress.trip = progress.trip or trip_finished
	save()

func mission_count() -> int:
	var progress := daily_progress()
	return int(progress.countries.size() >= 3) + int(progress.flawless) + int(progress.trip)

func equipped_character() -> String:
	return character_id if CharacterStyle.character_unlocked(character_id, discoveries, character_pack_unlocked) else "classic"
