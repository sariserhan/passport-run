extends SceneTree

var checks := 0
var failures := 0
var game: Node3D

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): push_error("Online smoke test timeout"); quit(1))
	run_tests.call_deferred()

func run_tests() -> void:
	var client := BackendClient.new()
	client.session_path = "user://online-test-session.json"
	root.add_child(client)
	client.setup("http://example.com:3210")
	expect(not client.configured(), "Reject insecure non-loopback backend")
	client.setup("https://example.com/path")
	expect(not client.configured(), "Reject backend URLs with paths")
	client.token = "old-token"
	client.refresh_token = "old-refresh"
	client.setup("http://127.0.0.1:3210")
	expect(client.token.is_empty() and client.refresh_token != "old-refresh", "Changing backend never forwards previous credentials")
	expect(await client.authenticate(), "Real Convex anonymous authentication succeeds")
	var issued := await client.begin_run("daily", "easy")
	expect(not issued.is_empty(), "Godot receives canonical server daily manifest")
	if issued.is_empty():
		print(client.last_error)
		quit(1)
		return
	expect(issued.balanceVersion == 2, "New server manifests use the timed balance rules")
	var recorder := ReplayRecorder.new()
	recorder.begin(issued.runId)
	await create_timer(5.05).timeout
	var lane := PathGenerator.lane_at(int(issued.seed), 3, 0)
	recorder.select(0, 0, lane)
	await create_timer(0.45).timeout
	var response := await client.call_function("mutation", "runs:submit", recorder.submission())
	expect(response.get("value", {}).get("score", -1) == 1, "Real server accepts timed Godot safe-lane replay")
	var duplicate := await client.call_function("mutation", "runs:submit", recorder.submission())
	expect(duplicate.is_empty(), "Real server rejects repeated submission")
	var retry := await client.begin_run("daily", "easy", issued.runId)
	expect(retry.get("seed") == issued.seed and retry.get("date") == issued.date and retry.get("route") == issued.route, "Server retry retains manifest identity")
	var synced := await client.call_function("mutation", "players:syncPassport", {"homeCountry": "FR", "discoveries": ["FR"]})
	expect(synced.get("value", {}).get("discoveries", []) == ["FR"], "Godot passport sync uses authenticated server ownership")
	var recorder_limit := ReplayRecorder.new()
	recorder_limit.begin("test")
	for index in ReplayRecorder.MAX_EVENTS + 1:
		recorder_limit.select(0, index, 0)
	expect(recorder_limit.overflow and recorder_limit.submission().is_empty(), "Overflow never submits a truncated proof")
	ProjectSettings.set_setting("network/backend_url", "http://127.0.0.1:3210")
	game = load("res://scenes/game.tscn").instantiate()
	game.save_path = "user://online-game-test-profile.json"
	game.backend_session_path = "user://online-game-test-session.json"
	root.add_child(game)
	await process_frame
	await game.start_game("online_daily", "easy")
	expect(game.online and game.session.mode == "daily", "Explicit online mode uses a server-issued game run")
	game.start_preview()
	await create_timer(5.1).timeout
	expect(game.choose_tile(0, game.run.safe_lane(0)), "Online gameplay accepts safe next tile")
	await create_timer(0.45).timeout
	expect(game.choose_tile(1, (game.run.safe_lane(1) + 1) % 3), "Online failure recorded through real gameplay")
	await create_timer(1.8).timeout
	expect("Server verified: 1 tiles" in game.hud.modal_body.text, "Actual game result reports server verification")
	game.return_to_menu()
	expect(not game.online and game.menu.root.visible, "Online failure can return to offline menu")
	await game.start_game("online_daily", "easy")
	game.start_preview()
	await create_timer(5.1).timeout
	await create_timer(10.1).timeout
	await create_timer(1.8).timeout
	expect(game.failure_reason == "timeout" and game.run.phase == RunState.Phase.FAILED, "Real online run enforces the 10-second first-row deadline")
	expect("Server verified: 0 tiles" in game.hud.modal_body.text, "Server accepts actual timed-out zero-score run")
	game.return_to_menu()
	game.network_busy = true
	game.return_to_menu()
	game.start_game("infinite", "easy")
	expect(not game.network_busy and not game.online and game.session.mode == "infinite", "Cancelling online preparation immediately permits offline play")
	game.queue_free()
	ProjectSettings.set_setting("network/backend_url", "")
	client.queue_free()
	await process_frame
	print("Online integration checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
