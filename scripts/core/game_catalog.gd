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

static var backdrop_cache: Dictionary = {}
static var world_backdrops: Texture2D = preload("res://assets/world-backdrops.png")

static func backdrop(id: String) -> Texture2D:
	if id not in COUNTRIES:
		id = "FR"
	if id not in backdrop_cache:
		if id in LEGACY_COUNTRIES:
			backdrop_cache[id] = load("res://assets/backdrops/" + id + ".png")
		else:
			var texture := AtlasTexture.new()
			texture.atlas = world_backdrops
			var cell := Vector2(world_backdrops.get_size()) / 4.0
			var index := int(COUNTRIES[id].art)
			texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
			texture.filter_clip = true
			backdrop_cache[id] = texture
	return backdrop_cache[id]

static func sorted_countries() -> Array:
	var ids := COUNTRIES.keys()
	ids.sort_custom(func(a: String, b: String): return country_name(a) < country_name(b))
	return ids

static func difficulty(key: String) -> DifficultyConfig:
	var resource: DifficultyConfig = load("res://resources/" + (key if key in DIFFICULTIES or key == "kids" else "easy") + ".tres")
	return resource.duplicate()

static func country_name(id: String) -> String:
	return str(COUNTRIES.get(id, {"name": "Practice Island"}).name)

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
