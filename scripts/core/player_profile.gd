class_name PlayerProfile
extends RefCounted

const SCHEMA_VERSION: int = 1
const MAX_PROFILE_BYTES := 2097152 # Includes the bounded 30-day postcard archive.
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
var last_unlocked_characters: Array[String] = []
var room_display: Array[String] = []
var room_decor: Dictionary = RoomDecor.DEFAULTS.duplicate()
var room_positions: Dictionary = {}
var room_postcards: Array[String] = []
var destination_records: Dictionary = {}
var arcade_saves: Dictionary = {}
var arcade_pops := 0
var arcade_practice_records: Dictionary = {}
var arcade_mastery: Dictionary = {}
var arcade_drop_journal: Array[String] = []
var arcade_daily: Dictionary = {}
var cached_home := ""
var cached_tour: Array[String] = []
var settings: Dictionary = {"music": 0.35, "sound": 0.65, "reduced_motion": false, "high_contrast": false, "haptics": true, "arcade_swap": false, "arcade_large": false, "large_controls": false, "text_scale": 1.0}
var travel_buddy := "bird"
var champion_seen := false
var travel_journal: Dictionary = {}
var journal_pages: Dictionary = {}
var regions_seen: Array[String] = []
var rare_keepsakes: Dictionary = {}
var activities: Dictionary = TravelActivities.clean({})
var extras: Dictionary = TravelExtras.clean({})
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
	activities = TravelActivities.clean(data.get("activities"))
	extras = TravelExtras.clean(data.get("extras"))
	travel_buddy = data.get("travel_buddy", "bird") if data.get("travel_buddy", "bird") in ["none", "bird", "robot", "dragon"] else "bird"
	if data.get("regions_seen") is Array:
		for name in data.regions_seen:
			if name is String and name in TravelMilestones.CONTINENTS and name not in regions_seen: regions_seen.append(name)
	if data.get("rare_keepsakes") is Dictionary:
		for id in data.rare_keepsakes:
			if id is String and id in GameCatalog.DESTINATIONS and data.rare_keepsakes[id] is Array:
				var variants: Array[String] = []
				for variant in data.rare_keepsakes[id]:
					if variant in ["gold", "crystal"] and variant not in variants: variants.append(variant)
				rare_keepsakes[id] = variants
	if data.get("journal_pages") is Dictionary:
		var dates: Array = data.journal_pages.keys().filter(func(key): return key is String and key.length() == 10 and key.substr(4, 1) == "-" and key.substr(7, 1) == "-")
		dates.sort()
		for date in dates.slice(maxi(0, dates.size() - 30)):
			var page: Variant = data.journal_pages[date]
			if page is Dictionary:
				var clean := {"date": date, "countries": [], "moments": [], "rewards": []}
				for field in ["countries", "moments", "rewards"]:
					if page.get(field) is Array:
						for value in page[field].slice(0, GameCatalog.DESTINATIONS.size() if field == "countries" else 100):
							if value is String and (field != "countries" or value in GameCatalog.DESTINATIONS): clean[field].append(value.left(160))
				journal_pages[date] = clean
	champion_seen = data.get("champion_seen", false) == true
	var journal: Variant = data.get("travel_journal")
	if journal is Dictionary and journal.get("date") == GameCatalog.today_utc():
		travel_journal = {"date": journal.date, "moments": [], "rewards": []}
		for field in ["moments", "rewards"]:
			if journal.get(field) is Array:
				for entry in journal[field].slice(0, 100):
					if entry is String: travel_journal[field].append(entry.left(160))
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
	if data.get("room_decor") is Dictionary:
		for kind in room_decor:
			var id: Variant = data.room_decor.get(kind)
			if id is String and RoomDecor.unlocked(kind, id, discoveries): room_decor[kind] = id
	if data.get("room_positions") is Dictionary:
		for id in room_display:
			var point: Variant = data.room_positions.get(id)
			if point is Array and point.size() == 2 and point.all(func(value): return (value is int or value is float) and is_finite(float(value))):
				room_positions[id] = [clampf(point[0], 0, 1), clampf(point[1], 0, 1)]
	if data.get("room_postcards") is Array:
		for id in data.room_postcards:
			if id is String and id in discoveries and id not in room_postcards and room_postcards.size() < 3: room_postcards.append(id)
	if data.get("destination_records") is Dictionary:
		for id in discoveries:
			var record: Variant = data.destination_records.get(id)
			if record is Dictionary:
				var clean := {}
				for key in ["jump", "arcade"]:
					var score: Variant = record.get(key)
					if score is int or score is float: clean[key] = clampi(int(score), 0, 10000000)
				if not clean.is_empty(): destination_records[id] = clean
	if data.get("settings") is Dictionary:
		for key in settings:
			var value: Variant = data.settings.get(key)
			if key in ["music", "sound", "text_scale"] and (value is int or value is float):
				settings[key] = clampf(float(value), 1, 1.3) if key == "text_scale" else clampf(float(value), 0, 1)
			elif value is bool and key not in ["music", "sound", "text_scale"]:
				settings[key] = value

	for id in discoveries: activities.mastery[id] = maxi(1, int(activities.mastery.get(id, 0)))
	for id in activities.mastery.keys():
		if id not in discoveries: activities.mastery.erase(id)
	for id in rare_keepsakes.keys():
		if id not in discoveries: rare_keepsakes.erase(id)
	if world_champion() and "world:champion" not in badges: badges.append("world:champion")

func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_PROFILE_BYTES:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = parser.data
	if data is Dictionary and data.get("version") == SCHEMA_VERSION:
		return data
	return {}

func save() -> bool:
	snapshot_journal()
	var data := {"version": SCHEMA_VERSION, "anonymous_id": anonymous_id, "home_country": home_country, "difficulty": difficulty, "tutorial_done": tutorial_done, "discoveries": discoveries, "history": history, "records": records, "badges": badges, "passport_cover": passport_cover, "daily_missions": daily_missions, "character_style": character_style, "room_display": room_display, "settings": settings, "arcade_saves": arcade_saves}
	data["travel_buddy"] = travel_buddy
	data["champion_seen"] = champion_seen
	data["travel_journal"] = travel_journal
	data["journal_pages"] = journal_pages
	data["regions_seen"] = regions_seen
	data["rare_keepsakes"] = rare_keepsakes
	data["activities"] = activities
	data["extras"] = extras
	data["character_id"] = character_id
	data["souvenir_counts"] = souvenir_counts
	data["room_decor"] = room_decor
	data["room_positions"] = room_positions
	data["room_postcards"] = room_postcards
	data["destination_records"] = destination_records
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
	last_unlocked_characters.clear()
	if id not in GameCatalog.DESTINATIONS:
		return
	var previous_regions := TravelMilestones.earned(discoveries)
	var previous_sets := TravelCollections.earned(discoveries)
	var first_visit := id not in discoveries
	var locked: Array[String] = []
	for character in CharacterStyle.CHARACTERS:
		if not CharacterStyle.character_unlocked(character, discoveries, character_pack_unlocked): locked.append(character)
	if id not in discoveries:
		discoveries.append(id)
	for character in locked:
		if CharacterStyle.character_unlocked(character, discoveries, character_pack_unlocked):
			last_unlocked_characters.append(character)
			journal_note("rewards", "Traveler: " + CharacterStyle.CHARACTERS[character].name)
	for name in TravelMilestones.earned(discoveries):
		if name not in previous_regions:
			journal_note("rewards", name + " explorer trophy")
			timeline_note(name + " explorer trophy earned")
	if first_visit:
		journal_note("rewards", DestinationTheme.souvenir(id))
		timeline_note("Passport stamped · " + GameCatalog.country_name(id))
	for collection in TravelCollections.earned(discoveries):
		if collection not in previous_sets: journal_note("rewards", TravelCollections.SETS[collection].name)
	if world_champion() and "world:champion" not in badges: award_badge("world:champion", false)
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
	return id == "world:champion" or id in ArcadeAchievements.BADGES or (id.begins_with("trip:") and id.trim_prefix("trip:") in TravelGoals.TRIPS) or (id.begins_with("perfect:") and id.trim_prefix("perfect:") in GameCatalog.DESTINATIONS)

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
	var reward_name: String = "World Champion" if id == "world:champion" else ArcadeAchievements.BADGES[id].name if id in ArcadeAchievements.BADGES else TravelGoals.TRIPS[id.trim_prefix("trip:")].name + " adventure badge" if id.begins_with("trip:") else GameCatalog.country_name(id.trim_prefix("perfect:")) + " perfect-jump badge"
	journal_note("rewards", reward_name)
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
	journal_note("moments", GameCatalog.country_name(id) + (" · Flawless finish!" if flawless else " · Destination completed"))
	if trip_finished: journal_note("moments", "A whole trip completed!")
	progress.flawless = progress.flawless or flawless
	progress.trip = progress.trip or trip_finished
	save()

func mission_count() -> int:
	var progress := daily_progress()
	return int(progress.countries.size() >= 3) + int(progress.flawless) + int(progress.trip)

func equipped_character() -> String:
	return character_id if CharacterStyle.character_unlocked(character_id, discoveries, character_pack_unlocked) else "classic"

func record_destination(id: String, mode: String, score: int) -> void:
	if id not in discoveries or mode not in ["jump", "arcade"]: return
	var record: Dictionary = destination_records.get(id, {})
	if score > int(record.get(mode, 0)):
		journal_note("moments", "%s · Best %s: %d" % [GameCatalog.country_name(id), mode, score])
	record[mode] = maxi(int(record.get(mode, 0)), clampi(score, 0, 10000000))
	destination_records[id] = record
	save()

func world_champion() -> bool:
	return GameCatalog.FREE_DESTINATIONS.keys().all(func(id): return id in discoveries)

func journal_today() -> Dictionary:
	if travel_journal.get("date", "") != GameCatalog.today_utc():
		travel_journal = {"date": GameCatalog.today_utc(), "moments": [], "rewards": []}
	return travel_journal

func journal_note(kind: String, value: String) -> void:
	var entries: Array = journal_today()[kind]
	if value not in entries: entries.append(value)
	while entries.size() > 100: entries.pop_front()

func snapshot_journal() -> void:
	if travel_journal.get("date", "") != GameCatalog.today_utc(): return
	var page := travel_journal.duplicate(true)
	page["countries"] = daily_progress().countries.duplicate()
	journal_pages[page.date] = page
	var dates := journal_pages.keys()
	dates.sort()
	while dates.size() > 30: journal_pages.erase(dates.pop_front())

func journal_page(date: String) -> Dictionary:
	if date == GameCatalog.today_utc():
		journal_today()
		snapshot_journal()
	return journal_pages.get(date, {"date": date, "countries": [], "moments": [], "rewards": []}).duplicate(true)

func earn_rare(id: String, variant: String) -> bool:
	if id not in discoveries or variant not in ["gold", "crystal"]: return false
	var owned: Array = rare_keepsakes.get(id, [])
	if variant in owned: return false
	owned.append(variant)
	rare_keepsakes[id] = owned
	journal_note("rewards", GameCatalog.country_name(id) + (" · Golden keepsake" if variant == "gold" else " · Crystal keepsake"))
	save()
	return true

func timeline_note(text: String) -> void:
	activities.timeline.append({"date": GameCatalog.today_utc(), "text": text.left(160)})
	while activities.timeline.size() > 500: activities.timeline.pop_front()

func bingo_today() -> Dictionary:
	if activities.bingo.get("week") != TravelActivities.week_key():
		activities.bingo = {"week": TravelActivities.week_key(), "lines": []}
	return activities.bingo

func activity_tick(key: String) -> void:
	var board := bingo_today()
	for goal in TravelActivities.BINGO:
		if goal[0] == key: board[key] = mini(goal[2], int(board.get(key, 0)) + 1)
	for index in TravelActivities.LINES.size():
		if index not in board.lines and TravelActivities.LINES[index].all(func(cell): return int(board.get(TravelActivities.BINGO[cell][0], 0)) >= TravelActivities.BINGO[cell][2]):
			board.lines.append(index)
			activities.rewards["bingo:" + TravelActivities.week_key() + ":" + str(index)] = "Travel bingo · Line %d sticker" % (index + 1)
			journal_note("rewards", "Travel bingo · Line %d sticker" % (index + 1))
			timeline_note("Travel bingo line completed")

func note_completion(id: String, key: String, flawless: bool, weekly_run: bool = false, arcade_medal: int = 0) -> void:
	if id not in discoveries: return
	note_extra_completion(id)
	var medal := arcade_medal if arcade_medal > 0 else (3 if key == "hard" and flawless else 2 if key == "moderate" and flawless else 1)
	var old := int(activities.mastery.get(id, 0))
	activities.mastery[id] = maxi(old, medal)
	if medal > old:
		journal_note("rewards", GameCatalog.country_name(id) + " · " + ["", "Bronze", "Silver", "Gold"][medal] + " mastery")
		timeline_note(GameCatalog.country_name(id) + " mastery reached " + ["", "Bronze", "Silver", "Gold"][medal])
	activity_tick("countries")
	if flawless:
		activity_tick("flawless")
		if not activities.timeline.any(func(event): return event.text == "My first flawless finish"): timeline_note("My first flawless finish")
	if medal >= 2: activity_tick("mastery")
	if travel_buddy in TravelActivities.BUDDY_QUESTS:
		activity_tick("buddy")
		var quest: Dictionary = TravelActivities.BUDDY_QUESTS[travel_buddy]
		var completed: Array = activities.buddy_progress.get(travel_buddy, [])
		if id in quest.route and id not in completed: completed.append(id)
		activities.buddy_progress[travel_buddy] = completed
		if completed.size() == quest.route.size() and not activities.accessories.get(travel_buddy, false):
			activities.accessories[travel_buddy] = true
			activities.rewards["buddy:" + travel_buddy] = quest.reward
			journal_note("rewards", BuddyPersonality.FRIENDS[travel_buddy].name + " · " + quest.reward)
			timeline_note(quest.name + " completed")
	var hunt_index: int = activities.hunt
	if hunt_index < TravelActivities.HUNTS.size() and activities.hunt_solved and id == TravelActivities.HUNTS[hunt_index].id:
		activities.rewards["hunt:" + str(hunt_index)] = TravelActivities.HUNTS[hunt_index].reward
		var treasure: String = TravelActivities.HUNTS[hunt_index].reward
		journal_note("rewards", treasure)
		timeline_note("Treasure found · " + treasure)
		activity_tick("hunt")
		activities.hunt += 1
		activities.hunt_solved = false
	if weekly_run:
		if activities.weekly.get("week") != TravelActivities.week_key(): activities.weekly = {"week": TravelActivities.week_key(), "countries": [], "rewarded": false}
		var week := TravelActivities.expedition()
		if id in week.route and id not in activities.weekly.countries: activities.weekly.countries.append(id)
		if week.route.all(func(place): return place in activities.weekly.countries) and not activities.weekly.rewarded:
			activities.weekly.rewarded = true
			activities.rewards["weekly:" + TravelActivities.week_key()] = week.reward
			journal_note("rewards", week.reward)
			timeline_note(week.name + " expedition completed")
			activity_tick("expedition")
	save()

func answer_hunt(id: String) -> bool:
	if activities.hunt >= TravelActivities.HUNTS.size() or id != TravelActivities.HUNTS[activities.hunt].id: return false
	activities.hunt_solved = true
	save()
	return true

func answer_knowledge(id: String, answer: String) -> bool:
	var question := TravelActivities.question(id)
	if id not in discoveries or question.is_empty() or answer != question.answer: return false
	if id not in activities.knowledge:
		activities.knowledge.append(id)
		journal_note("rewards", GameCatalog.country_name(id) + " knowledge sticker")
		timeline_note("Knowledge sticker · " + GameCatalog.country_name(id))
		activity_tick("knowledge")
		save()
	return true

func room_interact(action: String) -> void:
	if action not in ["lamp", "seated", "resting"]: return
	activities.room[action] = not activities.room[action]
	activity_tick("room")
	save()

func switch_room_space(space: String) -> bool:
	var required := {"main": 0, "balcony": 6, "nook": 12, "gallery": 20}
	if space not in required or discoveries.size() < required[space]: return false
	activities.spaces[activities.room.space] = {"decor": room_decor.duplicate(), "display": room_display.duplicate(), "postcards": room_postcards.duplicate(), "positions": room_positions.duplicate(true)}
	activities.room.space = space
	var slot: Dictionary = activities.spaces.get(space, {})
	room_decor = RoomDecor.DEFAULTS.duplicate()
	if slot.get("decor") is Dictionary:
		for key in room_decor:
			var value: Variant = slot.decor.get(key)
			if value is String and RoomDecor.unlocked(key, value, discoveries): room_decor[key] = value
	room_display.clear()
	room_postcards.clear()
	room_positions.clear()
	for field in ["display", "postcards"]:
		if slot.get(field) is Array:
			var target: Array = room_display if field == "display" else room_postcards
			for id in slot[field]:
				if id is String and id in discoveries and id not in target and target.size() < (6 if field == "display" else 3): target.append(id)
	if slot.get("positions") is Dictionary:
		for id in room_display:
			var point: Variant = slot.positions.get(id)
			if point is Array and point.size() == 2 and point.all(func(value): return (value is int or value is float) and is_finite(float(value))): room_positions[id] = [clampf(point[0], 0, 1), clampf(point[1], 0, 1)]
	return save()

func finish_extra_stage(kind: String, key: String, country: String) -> bool:
	var entry := TravelExtras.stage(kind, key)
	if entry.is_empty() or entry.country != country or not TravelExtras.unlocked(self, kind, key): return false
	var token := kind + ":" + key
	if token in extras.completed: return false
	extras.completed.append(token)
	activities.rewards[token] = entry.keepsake
	timeline_note("Collected " + entry.keepsake)
	return save()

func note_extra_completion(id: String) -> void:
	extras.materials = mini(999, extras.materials + 1)
	for key in extras.characters:
		var request: Dictionary = extras.characters[key]
		if id in TravelExtras.CHARACTERS[key].route and id not in request.countries: request.countries.append(id)
		if request.countries.size() == TravelExtras.CHARACTERS[key].route.size() and not request.rewarded:
			request.rewarded = true
			activities.rewards["character:" + key] = TravelExtras.CHARACTERS[key].reward
			timeline_note("Helped " + TravelExtras.CHARACTERS[key].name)
	save()

func accept_character(key: String) -> bool:
	if key not in TravelExtras.CHARACTERS or key in extras.characters: return false
	extras.characters[key] = {"countries": [], "rewarded": false}
	return save()

func craft_extra(key: String) -> bool:
	if key not in TravelExtras.RECIPES or key in extras.crafted: return false
	var recipe: Dictionary = TravelExtras.RECIPES[key]
	if extras.materials < recipe.cost or not recipe.countries.all(func(id): return id in discoveries): return false
	var old: int = extras.materials
	var old_ornament: String = extras.ornament
	extras.materials -= recipe.cost
	extras.crafted.append(key)
	extras.ornament = key
	if save(): return true
	extras.materials = old
	extras.crafted.erase(key)
	extras.ornament = old_ornament
	return false

func room_snapshot() -> Dictionary:
	return {"display": room_display.duplicate(), "decor": room_decor.duplicate(), "postcards": room_postcards.duplicate(), "positions": room_positions.duplicate(true)}

func save_room_preset(name: String) -> bool:
	if extras.presets.size() >= 6: return false
	extras.presets.append({"name": name.strip_edges().left(32), "room": room_snapshot(), "ornament": extras.ornament})
	return save()

func apply_room_preset(index: int) -> bool:
	if index < 0 or index >= extras.presets.size(): return false
	var preset: Dictionary = extras.presets[index]
	var room := TravelExtras.clean_room(preset.room)
	room_display.assign(room.display.filter(func(id): return id in discoveries))
	room_postcards.assign(room.postcards.filter(func(id): return id in discoveries))
	room_positions = room.positions
	for kind in room.decor:
		room_decor[kind] = room.decor[kind] if RoomDecor.unlocked(kind, room.decor[kind], discoveries) else RoomDecor.DEFAULTS[kind]
	extras.ornament = preset.ornament if preset.ornament in extras.crafted else "none"
	return save()

func record_recap(name: String, ids: Array, tiles: int) -> void:
	if ids.is_empty(): return
	extras.recaps.append({"name": name.left(64), "date": GameCatalog.today_utc(), "route": ids.duplicate(), "tiles": tiles})
	extras.recaps = extras.recaps.slice(-10)
	save()
