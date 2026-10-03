extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	var client := BackendClient.new()
	client.session_path = "user://start-country-sync-test-session.json"
	for suffix in ["", ".tmp"]: DirAccess.remove_absolute(client.session_path + suffix)
	root.add_child(client)
	client.setup("http://127.0.0.1:3210")
	expect(await client.authenticate(), "Local backend accepts a fresh anonymous player")
	var first := await client.call_function("mutation", "players:syncPassport", {"homeCountry": "JP", "discoveries": ["JP"]})
	expect(first.get("value", {}).get("homeCountry") == "JP", "The first online starting-country choice is persisted")
	var second := await client.call_function("mutation", "players:syncPassport", {"homeCountry": "FR", "discoveries": ["FR"]})
	expect(second.get("value", {}).get("homeCountry") == "JP", "Later sync cannot replace the starting country")
	expect(second.get("value", {}).get("discoveries", []) == ["JP", "FR"], "Locking the starting country still merges passport progress")
	var empty := await client.call_function("mutation", "players:syncPassport", {"homeCountry": "", "discoveries": []})
	expect(empty.get("value", {}).get("homeCountry") == "JP", "An empty sync cannot erase the starting-country lock")
	client.queue_free()
	await process_frame
	print("Starting country sync checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
