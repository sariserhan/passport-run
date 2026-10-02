class_name GameCatalog
extends RefCounted

const BALANCE_VERSION := 2
const DECISION_SECONDS := 10.0
const DIFFICULTIES := ["easy", "moderate", "hard"]
const COUNTRIES := {
	"US": {"name": "United States", "region": "North America", "neighbors": ["FR"], "color": "6398bd"},
	"FR": {"name": "France", "region": "Western Europe", "neighbors": ["TR"], "color": "a98ba9"},
	"EG": {"name": "Egypt", "region": "North Africa", "neighbors": ["TR"], "color": "dcb475"},
	"TR": {"name": "Turkey", "region": "Western Asia", "neighbors": ["FR", "EG"], "color": "78b8c0"},
	"JP": {"name": "Japan", "region": "East Asia", "neighbors": [], "color": "e1a0b4"},
}

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
