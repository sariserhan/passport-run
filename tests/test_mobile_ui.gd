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

func pointer(point: Vector2, down: bool, motion: bool = false) -> void:
	var event: InputEventMouse = InputEventMouseMotion.new() if motion else InputEventMouseButton.new()
	event.position = root.get_final_transform() * point
	event.global_position = event.position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	if motion:
		event.relative = root.get_final_transform().basis_xform(Vector2(0, -20))
	else:
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
	Input.parse_input_event(event)

func check_touch_scroll(menu: MenuUI) -> void:
	# Touch emulation makes ScrollContainer use its phone drag path on desktop/headless.
	Input.emulate_touch_from_mouse = true
	var probe := menu.action("SWIPE PROBE", false, func(): pass)
	menu.content.move_child(probe, 2)
	await settle()
	var presses := [0]
	probe.pressed.connect(func(): presses[0] += 1)
	var point := probe.get_global_rect().get_center()
	pointer(point, true)
	await process_frame
	pointer(point, false)
	await settle()
	expect(presses[0] == 1, "Tapping a menu button still presses it")
	pointer(point, true)
	await process_frame
	for step in 15:
		point.y -= 20
		pointer(point, true, true)
		await process_frame
	pointer(point, false)
	await settle()
	expect(menu.scroll.scroll_vertical > 0, "Swiping up from a menu button scrolls the main menu")
	expect(presses[0] == 1, "A swipe does not press the button it started on")
	Input.emulate_touch_from_mouse = false
	probe.queue_free()
	menu.show_settings()
	await settle()
	var sliders := menu.content.find_children("*", "HSlider", true, false)
	expect(not sliders.is_empty() and sliders.all(func(slider): return slider.mouse_filter == Control.MOUSE_FILTER_STOP), "Settings sliders keep their drag instead of scrolling the page")
	menu.show_room()
	await settle()
	expect(menu.safe_margin.size.x <= root.get_visible_rect().size.x + 1, "Travel room dropdowns stay inside a phone-width page")
	menu.show_main()
	await settle()

func check_globe_swipe() -> void:
	# Phones send a touch plus an emulated mouse event; the globe must rotate once per swipe.
	var globe := TravelGlobe.new()
	root.add_child(globe)
	globe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var transform := root.get_final_transform()
	var down := InputEventScreenTouch.new()
	down.position = transform * Vector2(200, 160)
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.position = transform * Vector2(300, 160)
	drag.relative = transform.basis_xform(Vector2(100, 0))
	Input.parse_input_event(drag)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.position = drag.position
	Input.parse_input_event(up)
	await process_frame
	expect(is_equal_approx(globe.longitude, 100.0 / maxf(100, globe.size.x) * 4), "One touch swipe rotates the globe once")
	globe.queue_free()

func check_backdrop_lifetime() -> void:
	# The backdrop cache holds 8; a page drawing more destinations in one frame used to
	# free an early card's texture before the frame rendered, leaving a white card.
	GameCatalog.backdrop_cache.clear()
	var box := VBoxContainer.new()
	root.add_child(box)
	box.size = Vector2(300, 400)
	var ids := ["FR", "JP", "EG", "BR", "IT", "ES", "DE", "IN", "MX", "AU"]
	for id in ids:
		var art := TravelArtwork.new()
		art.country_id = id
		art.custom_minimum_size.y = 20
		box.add_child(art)
	var first: WeakRef = weakref(GameCatalog.backdrop(ids[0]))
	await settle()
	expect(first.get_ref() != null, "Drawn destination artwork stays loaded while its card is on screen")
	box.queue_free()

func check_parent_gate() -> void:
	var results: Array = []
	for attempt in ["wrong", "right", "cancel"]:
		var outcome := [null]
		var waiter := func(): outcome[0] = await ParentGate.ask(root)
		waiter.call()
		await process_frame
		var gate: ParentGate = root.find_children("*", "ParentGate", false, false)[0]
		if attempt == "cancel":
			gate.answered.emit(false)
		else:
			gate.field.text = str(gate.answer + (1 if attempt == "wrong" else 0))
			gate.submit()
		await process_frame
		results.append(outcome[0])
	expect(results == [false, true, false], "Parent gate passes only the correct answer: " + str(results))
	await settle()
	expect(root.find_children("*", "ParentGate", false, false).is_empty(), "Parent gate closes after answering")

func check_ad_rule() -> void:
	var ads := AdService.new()
	var due: Array = []
	for attempt in 8:
		ads.note_failure("world")
		due.append(ads.last_due)
	expect(due == [false, false, false, true, false, false, false, true], "An ad is due on every 4th failure: " + str(due))
	for mode in ["kids", "tutorial", "kids", "kids"]:
		ads.note_failure(mode)
		expect(not ads.last_due, "Kids Mode and the tutorial never count toward ads")
	ads.remove_ads = RoutePurchase.new(AdService.PRODUCT_ID)
	ads.remove_ads.unlocked = true
	for attempt in 4: ads.note_failure("arcade")
	expect(not ads.last_due and ads.failures == 8, "Remove Ads stops forced ads")
	ads.remove_ads.free()
	ads.free()
	expect(str(ProjectSettings.get_setting(AdService.UNIT_SETTING)).begins_with("ca-app-pub-4959375849193463/") and str(ProjectSettings.get_setting(AdService.BANNER_SETTING)).begins_with("ca-app-pub-4959375849193463/"), "Real AdMob units are configured for release builds")
	expect(AdService.unit_id(AdService.UNIT_SETTING, AdService.TEST_UNIT) == AdService.TEST_UNIT and AdService.unit_id(AdService.BANNER_SETTING, AdService.TEST_BANNER) == AdService.TEST_BANNER, "Debug builds only ever request Google's test ads")

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
	await check_touch_scroll(menu)
	await check_backdrop_lifetime()
	await check_parent_gate()
	check_ad_rule()
	menu.root.hide()
	await check_globe_swipe()
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
