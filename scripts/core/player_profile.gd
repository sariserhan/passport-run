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
var settings: Dictionary = {"music": 0.35, "sound": 0.65, "reduced_motion": false, "high_contrast": false, "haptics": true}
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
	if data.get("records") is Dictionary:
		for key in data.records.keys().slice(0, 200):
			if key is String and key.length() <= 64 and (data.records[key] is float or data.records[key] is int):
				records[key] = clampi(int(data.records[key]), 0, 10000000)
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
	var data := {"version": SCHEMA_VERSION, "anonymous_id": anonymous_id, "home_country": home_country, "difficulty": difficulty, "tutorial_done": tutorial_done, "discoveries": discoveries, "history": history, "records": records, "badges": badges, "passport_cover": passport_cover, "settings": settings}
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

func discover(id: String) -> void:
	if id not in GameCatalog.DESTINATIONS:
		return
	if id not in discoveries:
		discoveries.append(id)
	history.append(id)
	if history.size() > 200:
		history.pop_front()
	save()

func record(mode: String, difficulty_key: String, score: int, date: String = "") -> void:
	var key := mode + ":" + difficulty_key + (":" + date if not date.is_empty() else "")
	records[key] = maxi(int(records.get(key, 0)), score)
	while records.size() > 200:
		records.erase(records.keys()[0])
	save()

func valid_badge(id: String) -> bool:
	return (id.begins_with("trip:") and id.trim_prefix("trip:") in TravelGoals.TRIPS) or (id.begins_with("perfect:") and id.trim_prefix("perfect:") in GameCatalog.DESTINATIONS)

func award_badge(id: String) -> bool:
	if not valid_badge(id) or id in badges: return false
	badges.append(id)
	save()
	return true
