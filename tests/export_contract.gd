extends SceneTree

func _initialize() -> void:
	var data := {"lanes": [], "routes": [], "daily": [], "balance": {}}
	for seed_value in [0, 1, 88, 817294, 2147483645]:
		for lanes in [3, 4, 5]:
			for row in [0, 1, 9, 49, 999, 1000000]:
				data.lanes.append({"seed": seed_value, "lanes": lanes, "row": row, "lane": PathGenerator.lane_at(seed_value, lanes, row)})
		for home in GameCatalog.LEGACY_COUNTRIES:
			data.routes.append({"home": home, "seed": seed_value, "route": RoutePlanner.standardized(home, seed_value, 1)})
	for difficulty_key in GameCatalog.DIFFICULTIES:
		var config := GameCatalog.difficulty(difficulty_key, 1)
		data.balance[difficulty_key] = {"lanes": config.lane_count, "rows": config.row_count, "previewMs": roundi(config.preview_seconds * 1000), "jumpMs": roundi(config.jump_seconds * 1000)}
		for date in ["2026-10-02", "2026-10-03", "infinite-v1"]:
			data.daily.append({"date": date, "difficulty": difficulty_key, "seed": GameCatalog.daily_seed(date, difficulty_key)})
	var file := FileAccess.open("res://backend/tests/fixtures/v1.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	quit()
