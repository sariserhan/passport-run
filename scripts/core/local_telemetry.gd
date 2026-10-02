class_name LocalTelemetry
extends RefCounted

var events: Array = []
var file_path: String

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
	var entry := {"event": event, "at": int(Time.get_unix_time_from_system())}
	# Fixed allowlist: no player names, contact details, location, or free-form user input.
	for key in ["mode", "difficulty", "country", "row", "lane", "score", "countries", "seed", "version"]:
		if metadata.has(key):
			entry[key] = metadata[key]
	events.append(entry)
	if events.size() > 500:
		events.pop_front()

func flush() -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(events))
