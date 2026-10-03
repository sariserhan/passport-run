class_name ChallengeCode
extends RefCounted

const PREFIX := "PR1."

static func encode(seed_value: int, difficulty_key: String, route: Array[String], target: int, balance_version: int = GameCatalog.BALANCE_VERSION, ghost: Array[int] = []) -> String:
	var data := {"generator_version": PathGenerator.VERSION, "seed": seed_value, "difficulty": difficulty_key, "route": route, "starting_country": route[0], "target_score": target}
	data.balance_version = balance_version
	if not ghost.is_empty(): data.ghost = ghost.slice(0, mini(target, 512))
	return PREFIX + Marshalls.utf8_to_base64(JSON.stringify(data))

static func link(code: String) -> String:
	return "passport-run://challenge/" + code.uri_encode()

static func decode(code: String) -> Dictionary:
	code = code.strip_edges()
	if code.begins_with("passport-run://challenge/"):
		code = code.trim_prefix("passport-run://challenge/").uri_decode()
	if not code.begins_with(PREFIX) or code.length() > 8192:
		return {}
	var encoded := code.trim_prefix(PREFIX)
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9+/]+={0,2}$")
	if encoded.length() % 4 != 0 or pattern.search(encoded) == null:
		return {}
	var raw := Marshalls.base64_to_raw(encoded)
	for byte in raw:
		if byte > 126 or byte < 32 and byte not in [9, 10, 13]:
			return {}
	var parser := JSON.new()
	if parser.parse(raw.get_string_from_ascii()) != OK:
		return {}
	var value: Variant = parser.data
	if not value is Dictionary:
		return {}
	var data: Dictionary = value
	var balance: Variant = data.get("balance_version", 1)
	if not (balance is int or balance is float) or (balance != 1 and balance != 2 and balance != 3):
		return {}
	data.balance_version = int(data.get("balance_version", 1))
	if data.get("generator_version") != PathGenerator.VERSION or data.get("difficulty") not in GameCatalog.DIFFICULTIES:
		return {}
	for key in ["seed", "target_score"]:
		if not (data.get(key) is int or data.get(key) is float):
			return {}
		if float(data[key]) != floor(float(data[key])) or data[key] < 0 or data[key] > 10000000 and key == "target_score":
			return {}
	if data.seed >= PathGenerator.MODULUS - 1:
		return {}
	if not data.get("route") is Array or data.route.is_empty() or data.route.size() > GameCatalog.DESTINATIONS.size():
		return {}
	var unique: Array = []
	for id in data.route:
		if not id is String or id not in GameCatalog.DESTINATIONS or id in unique:
			return {}
		unique.append(id)
	if data.get("starting_country") != data.route[0]:
		return {}
	if data.target_score > data.route.size() * GameCatalog.difficulty(data.difficulty).row_count:
		return {}
	if data.has("ghost"):
		if not data.ghost is Array or data.ghost.size() > mini(int(data.target_score), 512): return {}
		for decision in data.ghost:
			if not (decision is int or decision is float) or decision != floor(decision) or decision < 0 or decision >= 10000: return {}
		var timings: Array[int] = []
		timings.assign(data.ghost)
		data.ghost = timings
	return data
