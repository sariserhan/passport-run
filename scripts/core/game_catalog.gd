class_name GameCatalog
extends RefCounted

const BALANCE_VERSION := 2
const DECISION_SECONDS := 10.0
const DIFFICULTIES := ["easy", "moderate", "hard"]
const CATALOG_VERSION := 2
const LEGACY_COUNTRIES := {
	"US": {"neighbors": ["FR"]}, "FR": {"neighbors": ["TR"]},
	"EG": {"neighbors": ["TR"]}, "TR": {"neighbors": ["FR", "EG"]}, "JP": {"neighbors": []},
}
static var COUNTRIES: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/destinations.json"))

static var PREMIUM_DESTINATIONS: Dictionary = premium_catalog()
static var CINEMA_DESTINATIONS: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/cinema.json"))
static var FREE_DESTINATIONS: Dictionary = destination_catalog(false)
static var DESTINATIONS: Dictionary = destination_catalog(true)
static var backdrop_cache: Dictionary = {}
static var world_backdrops: Texture2D = preload("res://assets/world-backdrops.png")
static var fantasy_backdrops := [preload("res://assets/fantasy-0.png"), preload("res://assets/fantasy-1.png")]
static var cinema_backdrops := [preload("res://assets/cinema-0.png"), preload("res://assets/cinema-1.png")]
static var landmark_backdrops := [preload("res://assets/landmarks-0.png"), preload("res://assets/landmarks-1.png"), preload("res://assets/landmarks-2.png"), preload("res://assets/landmarks-3.png")]

static func premium_catalog() -> Dictionary:
	var result: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/landmarks.json"))
	result.merge(JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/fantasy.json")))
	return result

static func destination_catalog(include_premium: bool) -> Dictionary:
	var result := COUNTRIES.duplicate(true)
	result.merge(JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/territories.json")))
	if include_premium:
		result.merge(PREMIUM_DESTINATIONS.duplicate(true))
		result.merge(CINEMA_DESTINATIONS.duplicate(true))
	for id in result:
		for neighbor in result[id].neighbors.duplicate():
			if id not in result[neighbor].neighbors:
				result[neighbor].neighbors.append(id)
	return result

static func stamp_code(id: String) -> String:
	return str(DESTINATIONS.get(id, {}).get("stamp", id))

static func backdrop(id: String) -> Texture2D:
	if id not in DESTINATIONS:
		id = "FR"
	if id not in backdrop_cache:
		if id in LEGACY_COUNTRIES:
			backdrop_cache[id] = load("res://assets/backdrops/" + id + ".png")
		else:
			var texture := AtlasTexture.new()
			var destination: Dictionary = DESTINATIONS[id]
			var columns: int = 2 if destination.has("landmark_atlas") or destination.has("fantasy_atlas") or destination.has("cinema_atlas") else 4
			if destination.has("cinema_atlas"):
				texture.atlas = cinema_backdrops[int(destination.cinema_atlas)]
			elif destination.has("fantasy_atlas"):
				texture.atlas = fantasy_backdrops[int(destination.fantasy_atlas)]
			else:
				texture.atlas = landmark_backdrops[int(destination.landmark_atlas)] if columns == 2 else world_backdrops
			var cell := Vector2(texture.atlas.get_size()) / columns
			var index := int(destination.art)
			texture.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
			texture.filter_clip = true
			backdrop_cache[id] = texture
	return backdrop_cache[id]

static func sorted_destinations(premium: bool = false) -> Array:
	var ids := PREMIUM_DESTINATIONS.keys() if premium else FREE_DESTINATIONS.keys()
	ids.sort_custom(func(a: String, b: String): return country_name(a) < country_name(b))
	return ids

static func difficulty(key: String) -> DifficultyConfig:
	var resource: DifficultyConfig = load("res://resources/" + (key if key in DIFFICULTIES or key == "kids" else "easy") + ".tres")
	return resource.duplicate()

static func country_name(id: String) -> String:
	return str(DESTINATIONS.get(id, {"name": "Practice Island"}).name)

static func derived_seed(base: int, index: int) -> int:
	return (posmod(base, PathGenerator.MODULUS - 1) + index * 104729) % (PathGenerator.MODULUS - 1)

static func daily_seed(date: String, difficulty_key: String) -> int:
	# Stable text hash, independent of platform hash functions. UTC date is the contract.
	var value: int = 5381
	for byte in ("passport-daily-v1:" + date + ":" + difficulty_key).to_utf8_buffer():
		value = (value * 33 + byte) % (PathGenerator.MODULUS - 1)
	return value

static func today_utc() -> String:
	return Time.get_date_string_from_system(true)
