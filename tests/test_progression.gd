extends SceneTree

var checks: int = 0
var failures: int = 0
const SAVE := "user://progression-test.json"

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(SAVE + suffix)
	# Random-access infinite generation must preserve the existing finite generator contract.
	for lanes in [3, 4, 5]:
		var finite := PathGenerator.generate(817294, lanes, 1000)
		for row in 1000:
			expect(finite[row] == PathGenerator.lane_at(817294, lanes, row), "Random access preserves v1 at row " + str(row))
		expect(PathGenerator.lane_at(90, lanes, 1000000) < lanes, "Far row supports constant-memory lookup")
	for key in GameCatalog.DIFFICULTIES:
		var config := GameCatalog.difficulty(key)
		expect(config.lane_count == 3 + GameCatalog.DIFFICULTIES.find(key), "Difficulty lane counts")
		expect(config.preview_seconds == {"easy": 5.0, "moderate": 3.0, "hard": 2.0}[key], "Difficulty preview durations")
	# Every starting country must reach every destination without repetitions or dead ends.
	for id in GameCatalog.COUNTRIES:
		for seed_value in [0, 88, 817294]:
			var route := RoutePlanner.standardized(id, seed_value)
			expect(route.size() == GameCatalog.COUNTRIES.size() and route[0] == id, "Complete route from any home")
			var unique: Dictionary = {}
			for country in route:
				unique[country] = true
			expect(unique.size() == GameCatalog.COUNTRIES.size(), "No repeated countries")
			expect(route == RoutePlanner.standardized(id, seed_value), "Route reproducibility")
	for id in ["DE", "IT", "RU", "CN", "AE", "AU", "NO", "BR", "AR", "GR", "ES", "PT", "SA", "BG", "MN", "KZ", "KR", "TH", "ID", "MY", "PH", "MX", "CA", "NL", "TN", "MA", "ZA", "KE", "NG", "CL", "BO", "CO", "VE", "PY", "UY", "JM"]:
		expect(id in GameCatalog.COUNTRIES, "Requested destination included: " + id)
	for id in GameCatalog.COUNTRIES:
		expect(GameCatalog.backdrop(id) != null, "Every destination has illustrated scenery: " + id)
		for neighbor in GameCatalog.COUNTRIES[id].neighbors:
			expect(neighbor in GameCatalog.COUNTRIES and id in GameCatalog.COUNTRIES[neighbor].neighbors, "Reciprocal known border: " + id + "/" + str(neighbor))
	var full_code := ChallengeCode.encode(88, "hard", RoutePlanner.standardized("FR", 88), GameCatalog.COUNTRIES.size() * 20)
	var full_challenge := ChallengeCode.decode(full_code)
	expect(full_challenge.get("route", []).size() == GameCatalog.COUNTRIES.size(), "Full world challenge fits code limit")
	var planner := RoutePlanner.new()
	planner.start("TR", 10)
	expect(not planner.travel_to("JP"), "Cannot travel before completing country")
	planner.complete_current()
	expect(not planner.travel_to("invalid"), "Reject arbitrary destinations")
	var profile := PlayerProfile.new(SAVE)
	profile.home_country = "TR"
	profile.difficulty = "hard"
	profile.settings.reduced_motion = true
	profile.discover("FR")
	profile.discover("FR")
	profile.record("infinite", "easy", 123)
	profile.record("infinite", "hard", 45)
	profile.record("infinite", "easy", 5)
	profile.save()
	var restored := PlayerProfile.new(SAVE)
	expect(restored.home_country == "TR" and restored.difficulty == "hard", "Preferences survive reload")
	expect(restored.discoveries == ["FR"] and restored.history.size() == 2, "Unique stamps separate from travel history")
	expect(restored.records["infinite:easy"] == 123 and restored.records["infinite:hard"] == 45, "Record segregation and monotonic bests")
	expect(restored.anonymous_id == profile.anonymous_id, "Anonymous identity persists")
	expect(restored.settings.reduced_motion, "Accessibility settings persist")
	restored.home_country = "JP"
	restored.save()
	expect(PlayerProfile.new(SAVE).discoveries == ["FR"], "Changing home preserves passport")
	var corrupt := FileAccess.open(SAVE, FileAccess.WRITE)
	corrupt.store_string("interrupted write")
	corrupt.close()
	var recovered := PlayerProfile.new(SAVE)
	expect(recovered.home_country == "TR" and recovered.discoveries == ["FR"], "Corrupt primary save recovers previous backup")
	var route := RoutePlanner.standardized("FR", 88)
	var code := ChallengeCode.encode(88, "hard", route, 80)
	var challenge := ChallengeCode.decode(code)
	expect(challenge.seed == 88 and challenge.difficulty == "hard" and challenge.route == route and challenge.target_score == 80, "Challenge round trip")
	for invalid in ["", "hello", "PR9.aaaa", "PR1."]:
		expect(ChallengeCode.decode(invalid).is_empty(), "Reject malformed challenge")
	for mutation in [{"generator_version": 99}, {"seed": -1}, {"seed": 1.5}, {"difficulty": "kids"}, {"route": ["FR", "FR"]}, {"starting_country": "EG"}, {"target_score": 1e12}, {"route": ["XX"]}]:
		var bad: Dictionary = challenge.duplicate(true)
		bad.merge(mutation, true)
		expect(ChallengeCode.decode("PR1." + Marshalls.utf8_to_base64(JSON.stringify(bad))).is_empty(), "Reject invalid challenge field")
	var first := JourneySession.new()
	var second := JourneySession.new()
	first.begin("daily", "hard", "US", 1)
	second.begin("daily", "hard", "JP", 999)
	expect(first.seed_value == second.seed_value and first.fixed_route == second.fixed_route and first.current_country() == "FR", "Daily identity ignores home and device randomness")
	expect(GameCatalog.daily_seed("2026-10-02", "hard") != GameCatalog.daily_seed("2026-10-03", "hard"), "Daily changes at UTC date boundary")
	expect(GameCatalog.daily_seed("2026-10-02", "hard") != GameCatalog.daily_seed("2026-10-02", "easy"), "Daily difficulties segregated")
	first.begin("challenge", "easy", "JP", 999, challenge)
	expect(first.seed_value == 88 and first.difficulty == "hard" and first.fixed_route == route, "Challenge session honors payload")
	var telemetry := LocalTelemetry.new(SAVE + ".events")
	for i in 600:
		telemetry.track("tile_selected", {"row": i, "email": "never persist this"})
	expect(telemetry.events.size() == 500 and not telemetry.events.back().has("email"), "Telemetry bounded and metadata allowlisted")
	telemetry.flush()
	expect(LocalTelemetry.new(SAVE + ".events").events.size() == 500, "Local events survive reload")
	print("Progression checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
