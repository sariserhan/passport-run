extends SceneTree

var checks := 0
var failures := 0
var render := false
const SAVE := "user://places-test-profile.json"

# Native StoreKit contract simulation exists only in this excluded test file.
class TestStore extends RefCounted:
	signal product_info_received(info: Dictionary)
	signal transaction_state_changed(transaction: Dictionary)
	signal synchronized
	var owned := false
	var product_id := RoutePurchase.PRODUCT_ID
	var error := ""
	var purchase_state := 7
	var restore_owned := false
	func request_product_info(_id: String) -> Signal:
		product_info_received.emit.call_deferred({"product_id": product_id, "error": error, "is_purchased": owned, "localized_price": "$4.99"})
		return product_info_received
	func purchase_product(_id: String, _quantity: int) -> Signal:
		owned = purchase_state == 4
		transaction_state_changed.emit.call_deferred({"product_id": product_id, "transaction_state": purchase_state})
		return transaction_state_changed
	func sync() -> Signal:
		owned = restore_owned
		synchronized.emit.call_deferred()
		return synchronized

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
		for node in root.get_children():
			if node.has_method("resume_game") and node.paused:
				node.resume_game()
	expect(predicate.call(), "Gameplay reaches expected state")

func _initialize() -> void:
	render = DisplayServer.get_name() != "headless"
	create_timer(60).timeout.connect(func(): push_error("Special-route test timed out"); quit(1))
	run_tests.call_deferred()

func capture(name: String) -> void:
	if render:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run_tests() -> void:
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	expect(GameCatalog.COUNTRIES.size() == 197 and GameCatalog.FREE_DESTINATIONS.size() == 250 and GameCatalog.DESTINATIONS.size() == 282, "Ranked countries, free destinations and paid route totals")
	for id in GameCatalog.DESTINATIONS:
		expect(GameCatalog.backdrop(id) != null, "Every destination has scenery: " + id)
		expect(not CountryRewards.fact(id).is_empty(), "Every destination has reward text: " + id)
		expect(GameCatalog.stamp_code(id).length() <= 3, "Readable passport mark: " + id)
		for neighbor in GameCatalog.DESTINATIONS[id].neighbors:
			expect(neighbor in GameCatalog.DESTINATIONS and id in GameCatalog.DESTINATIONS[neighbor].neighbors, "Reciprocal location metadata: " + id)
	for id in GameCatalog.FREE_DESTINATIONS:
		expect(id not in GameCatalog.PREMIUM_DESTINATIONS and id not in GameCatalog.CINEMA_DESTINATIONS, "Free catalog excludes paid locations")
		expect(GameCatalog.FREE_DESTINATIONS[id].neighbors.all(func(n): return n in GameCatalog.FREE_DESTINATIONS), "Free travel links exclude paid locations")
	expect("AQ" in GameCatalog.FREE_DESTINATIONS and "HK" in GameCatalog.FREE_DESTINATIONS and "GL" in GameCatalog.FREE_DESTINATIONS, "More territories are playable free")
	var session := JourneySession.new()
	session.begin("world", "easy", "GL", 88)
	while not session.choices().is_empty():
		session.complete_country(10)
		expect(session.travel_to(session.choices()[0]), "Free tour travels through real session choices")
	expect(session.challenge_route().size() == 250, "Free tour reaches every country/territory")
	var mixed: Array[String] = []
	mixed.assign(GameCatalog.DESTINATIONS.keys())
	var code := ChallengeCode.encode(88, "hard", mixed, 5480)
	expect(ChallengeCode.decode(code).get("route", []) == mixed, "Long mixed-location challenge decodes without truncation")
	for home in ["EVEREST", "SAHARA", "UNDERWATER", "SPACE", "MOON", "MARS"]:
		session.begin("special", "hard", home, 88)
		expect(session.fixed_route.size() == 24 and session.current_country() == home, "Separate special route starts at " + home)
		expect(session.fixed_route.all(func(id): return id in GameCatalog.PREMIUM_DESTINATIONS), "Paid route contains only special destinations")
		session.complete_country(20)
		expect(session.travel_to(session.choices()[0]), "Special route advances after completion")
	session.begin("daily", "hard", "MOON", 88)
	expect(session.fixed_route.size() == 197 and "EVEREST" not in session.fixed_route, "Daily retains immutable country-only catalog")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(SAVE + suffix)
	var profile := PlayerProfile.new(SAVE)
	profile.home_country = "FR"
	profile.discoveries.assign(GameCatalog.DESTINATIONS.keys())
	expect(profile.save(), "Full expanded passport saves")
	var restored := PlayerProfile.new(SAVE)
	expect(restored.discoveries.size() == 282, "All stamps beyond the old 200 limit survive reload")
	restored.discover("SAHARA")
	expect(restored.discoveries.size() == 282 and restored.history.back() == "SAHARA", "Special-place repeat adds history without duplicate stamps")
	restored.discover("NOT_A_PLACE")
	expect(restored.discoveries.size() == 282, "Unknown place cannot award a stamp")
	var game = load("res://scenes/game.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	game.profile.settings.music = 0.0
	game.profile.settings.sound = 0.0
	expect(not game.purchase.unlocked, "Saved passport stamps cannot unlock paid access")
	game.start_game("special", "easy")
	expect(game.menu.special_page and game.session.mode != "special", "Direct paid-mode entry is gated")
	await capture("32-special-route-locked")
	game.imported_challenge = ChallengeCode.decode(ChallengeCode.encode(88, "easy", ["FR", "MOON"], 0))
	game.start_game("challenge", "easy")
	expect(game.menu.special_page and game.session.mode != "challenge", "A challenge code cannot bypass payment")
	game.menu.show_countries()
	for child in game.menu.content.get_children():
		if child is Button and child.has_meta("destination_id"):
			expect(child.get_meta("destination_id") in GameCatalog.FREE_DESTINATIONS, "Home picker excludes all premium starts")
	var store := TestStore.new()
	game.purchase.store = store
	store.transaction_state_changed.connect(game.purchase.on_transaction)
	await game.purchase.refresh()
	expect(not game.purchase.unlocked and game.purchase.price == "$4.99", "Product availability does not grant ownership")
	store.product_id = "another_product"
	store.owned = true
	await game.purchase.refresh()
	expect(not game.purchase.unlocked and game.purchase.price.is_empty(), "Wrong product cannot grant ownership")
	store.product_id = RoutePurchase.PRODUCT_ID
	store.owned = false
	await game.purchase.refresh()
	await game.purchase.purchase()
	expect(not game.purchase.unlocked and "cancelled" in game.purchase.message, "Cancelled purchase keeps route locked")
	store.purchase_state = 2
	await game.purchase.purchase()
	expect(not game.purchase.unlocked and "approval" in game.purchase.message, "Pending approval keeps route locked")
	store.restore_owned = true
	await game.purchase.restore()
	expect(game.purchase.unlocked, "Restore rechecks native current entitlement")
	game.start_game("cinema", "easy")
	expect(game.menu.cinema_page and game.session.mode != "cinema", "Special ownership cannot unlock Cinema Worlds")
	await capture("33-cinema-route-locked")
	game.imported_challenge = ChallengeCode.decode(ChallengeCode.encode(88, "easy", ["WIZARD_CASTLE"], 0))
	game.start_game("challenge", "easy")
	expect(game.menu.cinema_page and game.session.mode != "challenge", "Cinema challenge cannot bypass its separate purchase")
	var cinema_store := TestStore.new()
	cinema_store.product_id = RoutePurchase.CINEMA_PRODUCT_ID
	cinema_store.restore_owned = true
	game.cinema_purchase.store = cinema_store
	cinema_store.transaction_state_changed.connect(game.cinema_purchase.on_transaction)
	await game.cinema_purchase.restore()
	game.cinema_start = "WIZARD_CASTLE"
	game.start_game("cinema", "easy")
	expect(game.session.mode == "cinema" and game.session.fixed_route.size() == 8 and game.session.current_country() == "WIZARD_CASTLE", "Cinema ownership unlocks eight cinematic worlds")
	if render:
		for id in GameCatalog.CINEMA_DESTINATIONS:
			game.cinema_start = id
			game.start_game("cinema", "easy")
			game.start_preview()
			await create_timer(0.10).timeout
			await capture("cinema-" + id)
	cinema_store.owned = false
	game.cinema_purchase.on_transaction({"product_id": RoutePurchase.CINEMA_PRODUCT_ID, "transaction_state": 1})
	expect(not game.cinema_purchase.unlocked and game.purchase.unlocked, "Cinema refund preserves separate Special ownership")
	game.special_start = "MOON"
	game.start_game("special", "easy")
	expect(game.session.mode == "special" and game.session.current_country() == "MOON", "Verified ownership permits separate Moon route")
	var route: Array = game.session.fixed_route.duplicate()
	game.restart(false, false)
	expect(game.session.current_country() == "MOON" and game.session.fixed_route == route, "Paid retry preserves starting location and route")
	if render:
		for id in GameCatalog.PREMIUM_DESTINATIONS:
			game.special_start = id
			game.start_game("special", "easy")
			game.start_preview()
			await create_timer(0.10).timeout
			await capture("special-" + id)
	game.special_start = "EVEREST"
	game.start_game("special", "easy")
	game.start_preview()
	game.preview_remaining = 0.001
	game.config.jump_seconds = 0.005
	await until(func(): return game.run.phase == RunState.Phase.PLAY)
	for row in game.config.row_count:
		expect(game.choose_tile(row, game.run.safe_lane(row)), "Paid route accepts safe jump")
		await until(func(): return game.run.phase != RunState.Phase.JUMPING)
	var deadline := Time.get_ticks_msec() + 6000
	while not game.country_awarded and Time.get_ticks_msec() < deadline:
		await process_frame
		if game.paused:
			game.resume_game()
	expect(game.country_awarded and game.profile.history.back() == "EVEREST", "Paid gameplay runs celebration and records the actual landmark stamp")
	game.travel_to(game.session.choices()[0])
	game.travel.finish()
	expect(game.session.current_country() == "SAHARA", "Paid route travels from Everest to the desert")
	store.owned = false
	game.purchase.on_transaction({"product_id": RoutePurchase.PRODUCT_ID, "transaction_state": 1})
	expect(not game.purchase.unlocked and game.menu.special_page and game.menu.root.visible, "Refund immediately removes paid gameplay access")
	expect(not game.choose_tile(0, 0), "Expired ownership cannot keep playing through a direct input")
	await game.cinema_purchase.restore()
	game.start_game("special", "easy")
	expect(game.cinema_purchase.unlocked and not game.purchase.unlocked and game.menu.special_page, "Cinema ownership cannot unlock Special Expeditions")
	await process_frame
	game.queue_free()
	await process_frame
	print("Special place/payment checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
