class_name LocalTelemetry
extends RefCounted

var events: Array = []
var file_path: String
var session_id := Crypto.new().generate_random_bytes(8).hex_encode()
var run_id := ""
var run_started_at := 0

func _init(path: String = "user://events.json") -> void:
	file_path = path
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file and file.get_length() < 524288:
			var parser := JSON.new()
			if parser.parse(file.get_as_text()) != OK:
				return
			var previous: Variant = parser.data
			if previous is Array:
				events = previous.slice(-500)

func track(event: String, metadata: Dictionary = {}) -> void:
	if event in ["run_started", "run_retried"]:
		run_id = Crypto.new().generate_random_bytes(8).hex_encode()
		run_started_at = Time.get_ticks_msec()
	var entry := {"event": event, "at": int(Time.get_unix_time_from_system()), "session_id": session_id}
	if not run_id.is_empty():
		entry.run_id = run_id
		entry.elapsed_ms = Time.get_ticks_msec() - run_started_at
	# Fixed allowlist: no player names, contact details, location, or free-form user input.
	for key in ["mode", "difficulty", "country", "row", "lane", "score", "countries", "seed", "version", "balance_version"]:
		if metadata.has(key):
			entry[key] = metadata[key]
	events.append(entry)
	if events.size() > 500:
		events.pop_front()

func flush() -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(events))
