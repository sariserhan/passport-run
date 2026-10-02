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

func begin(selected_mode: String, selected_difficulty: String, home: String, new_seed: int, challenge: Dictionary = {}) -> void:
	mode = selected_mode
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
	elif mode == "challenge":
		seed_value = int(challenge.seed)
		difficulty = challenge.difficulty
		fixed_route.assign(challenge.route)
		target = int(challenge.target_score)
	elif mode in ["world", "kids"]:
		planner.start(home, seed_value)

func current_country() -> String:
	if mode in ["world", "kids"]:
		return planner.current()
	if not fixed_route.is_empty():
		return fixed_route[country_index]
	if mode == "infinite":
		return GameCatalog.COUNTRIES.keys()[country_index % GameCatalog.COUNTRIES.size()]
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
		return planner.choices()
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
