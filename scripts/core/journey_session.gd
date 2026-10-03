class_name JourneySession
extends RefCounted

var mode: String = "practice"
var difficulty: String = "easy"
var seed_value: int = 1
var date: String = ""
var planner := RoutePlanner.new()
var fixed_route: Array[String] = []
var country_index: int = 0
var completed_countries: int = 0
var banked_tiles: int = 0
var target: int = 0
var balance_version: int = GameCatalog.BALANCE_VERSION

func begin(selected_mode: String, selected_difficulty: String, home: String, new_seed: int, challenge: Dictionary = {}) -> void:
	mode = selected_mode
	balance_version = int(challenge.get("balance_version", 1)) if mode == "challenge" else GameCatalog.BALANCE_VERSION
	difficulty = "kids" if mode == "kids" else selected_difficulty
	seed_value = new_seed
	country_index = 0
	completed_countries = 0
	banked_tiles = 0
	fixed_route.clear()
	target = 0
	date = ""
	if mode == "daily":
		date = GameCatalog.today_utc()
		seed_value = GameCatalog.daily_seed(date, difficulty)
		fixed_route = RoutePlanner.standardized("FR", seed_value)
	elif mode in ["special", "cinema"]:
		var places := GameCatalog.PREMIUM_DESTINATIONS.keys() if mode == "special" else GameCatalog.CINEMA_DESTINATIONS.keys()
		var start := maxi(0, places.find(home))
		fixed_route.assign(places.slice(start) + places.slice(0, start))
	elif mode == "adventure":
		fixed_route.assign([home])
	elif mode in ["trip", "expedition"]:
		fixed_route.assign(challenge.get("route", []))
	elif mode == "challenge":
		seed_value = int(challenge.seed)
		difficulty = challenge.difficulty
		fixed_route.assign(challenge.route)
		target = int(challenge.target_score)
	elif mode in ["world", "kids"]:
		planner.include_territories = true
		planner.start(home, GameCatalog.daily_seed("guided-tour-v1", home))

func current_country() -> String:
	if mode in ["world", "kids"]:
		return planner.current()
	if not fixed_route.is_empty():
		return fixed_route[country_index]
	return ""

func path_seed() -> int:
	return seed_value if mode == "infinite" else GameCatalog.derived_seed(seed_value, country_index)

func complete_country(rows: int) -> void:
	banked_tiles += rows
	completed_countries += 1
	if mode in ["world", "kids"]:
		planner.complete_current()

func choices() -> Array[String]:
	if mode in ["world", "kids"]:
		return planner.choices().slice(0, 1)
	var result: Array[String] = []
	if country_index + 1 < fixed_route.size():
		result.append(fixed_route[country_index + 1])
	return result

func travel_to(id: String) -> bool:
	if id not in choices():
		return false
	if mode in ["world", "kids"] and not planner.travel_to(id):
		return false
	country_index += 1
	return true

func challenge_route() -> Array[String]:
	if not fixed_route.is_empty():
		return fixed_route.duplicate()
	return planner.route.duplicate()
