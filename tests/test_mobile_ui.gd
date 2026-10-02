extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run_tests.call_deferred()

func settle() -> void:
	for frame in 8:
		await process_frame

func run_tests() -> void:
	var defaults := Vector4i(24, 24, 24, 26)
	var insets := SafeAreaMargins.calculate(Vector2(390, 844), Vector2i(1170, 2532), Rect2i(0, 177, 1170, 2253), defaults)
	expect(insets == Vector4i(24, 71, 24, 46), "Retina notch and home indicator scale into logical UI units")
	expect(SafeAreaMargins.calculate(Vector2(390, 844), Vector2i.ZERO, Rect2i(), defaults) == defaults, "Unavailable safe area keeps usable default margins")
	expect(SafeAreaMargins.calculate(Vector2(844, 390), Vector2i(2532, 1170), Rect2i(177, 0, 2178, 1107), defaults) == Vector4i(71, 24, 71, 33), "Side cutouts use horizontal scale")
	var hud := GameHUD.new()
	root.add_child(hud)
	var profile := PlayerProfile.new("user://mobile-ui-test.json")
	var menu := MenuUI.new()
	root.add_child(menu)
	menu.setup(profile, hud)
	menu.show_main()
	await settle()
	expect(menu.safe_margin.get_theme_constant("margin_top") == 48, "Menu padding initialized without requiring a resize")
	menu.root.hide()
	for viewport_size in [Vector2i(480, 900), Vector2i(390, 844), Vector2i(375, 667), Vector2i(320, 568)]:
		root.size = viewport_size
		await settle()
		var actions: Array = []
		for index in 14:
			actions.append({"text": "DESTINATION %d" % index, "callback": func(): pass})
		hud.show_journey_result("WELCOME TO TURKEY", "Five countries this run.\nA long route summary wraps within this card.\nRemember the path and keep exploring.", actions)
		await settle()
		var card_rect := hud.modal_card.get_global_rect()
		expect(card_rect.position.x >= 19 and card_rect.end.x <= hud.root.size.x - 19, "Result card fits narrow screen: " + str(viewport_size))
		expect(hud.modal_scroll.size.y <= hud.root.size.y - 50, "Results viewport respects top and bottom padding")
		expect(hud.modal_scroll.get_v_scroll_bar().max_value > hud.modal_scroll.size.y, "Long results can scroll to every action")
		hud.modal_actions.get_child(13).grab_focus()
		await settle()
		var last_action: Rect2 = hud.modal_actions.get_child(13).get_global_rect()
		var visible_rect := hud.modal_scroll.get_global_rect()
		expect(last_action.position.y >= visible_rect.position.y and last_action.end.y <= visible_rect.end.y + 1, "Focused final action scrolls into safe viewport")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/mobile-results-%dx%d.png" % [viewport_size.x, viewport_size.y])
	menu.queue_free()
	hud.queue_free()
	await settle()
	print("Mobile UI checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
