extends SceneTree

# Opens every menu/activity/journey screen at phone sizes, reports controls that spill
# past the screen edge, and (rendered runs) saves artifacts/screens/<size>-<screen>.png.
const SIZES := [Vector2i(375, 667), Vector2i(390, 844), Vector2i(844, 390)]
const MENU := ["show_main", "show_countries", "show_passport", "show_world_map", "show_stickers", "show_records", "show_settings", "show_challenge", "show_special_route", "show_cinema_route", "show_trips", "show_goals", "show_missions", "show_souvenirs", "show_adventures", "show_wardrobe", "show_room", "show_character_quests", "show_album", "show_arcade", "show_arcade_practice", "show_arcade_achievements", "show_arcade_daily_goals", "show_arcade_drop_journal", "show_arcade_mastery", "show_buddies", "show_journal", "show_regions", "show_rare_challenges", "show_replay"]
const ACTIVITIES := ["hub", "arrival", "souvenirs", "quests", "scrapbook", "weekly", "passport", "mastery", "hunt", "bingo", "lounge", "timeline", "weather", "knowledge", "celebrations", "checklist"]

var problems: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	for frame in 6:
		await process_frame

func audit(menu: MenuUI, name: String, size: Vector2i) -> void:
	await settle()
	var width := root.get_visible_rect().size.x
	for node in menu.content.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x < 1: continue
		var rect := control.get_global_rect()
		if rect.end.x > width + 1 or rect.position.x < -1:
			problems.append("%dx%d %s: %s '%s' spans %d..%d of %d" % [size.x, size.y, name, control.get_class(), control.get("text") if control.get("text") else control.name, rect.position.x, rect.end.x, width])
			break
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/screens/%dx%d-%s.png" % [size.x, size.y, name])

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/screens")
	DirAccess.remove_absolute("user://screen-sweep.json")
	var hud := GameHUD.new()
	root.add_child(hud)
	var profile := PlayerProfile.new("user://screen-sweep.json")
	profile.home_country = "FR"
	profile.tutorial_done = true
	for id in ["FR", "IT", "ES", "DE", "JP", "BR", "AF"]: profile.discover(id)
	var menu := MenuUI.new()
	root.add_child(menu)
	menu.setup(profile, hud)
	for size in SIZES:
		root.size = size
		for screen in MENU:
			menu.call(screen)
			await audit(menu, screen.trim_prefix("show_"), size)
		for page in ACTIVITIES:
			TravelActivityUI.new(menu).show(page)
			await audit(menu, "activity-" + page, size)
		TravelExtrasUI.new(menu).show("hub")
		await audit(menu, "journeys-hub", size)
		for entry in TravelExtras.PAGES:
			TravelExtrasUI.new(menu).show(entry[0])
			await audit(menu, "journeys-" + entry[0], size)
	for problem in problems: print("OVERFLOW ", problem)
	print("Screen sweep: %d screens x %d sizes; overflow: %d" % [MENU.size() + ACTIVITIES.size() + TravelExtras.PAGES.size() + 1, SIZES.size(), problems.size()])
	quit(1 if problems else 0)
