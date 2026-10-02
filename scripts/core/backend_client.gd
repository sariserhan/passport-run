class_name BackendClient
extends Node

var base_url := ""
var token := ""
var refresh_token := ""
var last_error := ""
var authenticated_at := 0
var session_path := "user://online-session.json"

func setup(url: String) -> void:
	token = ""
	refresh_token = ""
	authenticated_at = 0
	url = url.trim_suffix("/")
	# Bearer credentials only travel over HTTPS, or loopback during local development.
	var pattern := RegEx.new()
	pattern.compile("^(https://[A-Za-z0-9.-]+(:[0-9]+)?|http://(127\\.0\\.0\\.1|localhost):[0-9]+)$")
	base_url = url if pattern.search(url) else ""
	if not base_url.is_empty() and FileAccess.file_exists(session_path):
		var file := FileAccess.open(session_path, FileAccess.READ)
		if file and file.get_length() < 4096:
			var parser := JSON.new()
			if parser.parse(file.get_as_text()) == OK and parser.data is Dictionary:
				var session: Dictionary = parser.data
				if session.get("url") == base_url and session.get("refreshToken") is String:
					refresh_token = session.refreshToken

func configured() -> bool:
	return not base_url.is_empty()

func call_function(kind: String, path: String, args: Dictionary, authenticated: bool = true) -> Dictionary:
	last_error = ""
	if not configured() or kind not in ["action", "query", "mutation"]:
		last_error = "Online play is not configured."
		return {}
	var request := HTTPRequest.new()
	request.timeout = 8.0
	request.body_size_limit = 262144
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authenticated and not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var error := request.request(base_url + "/api/" + kind, headers, HTTPClient.METHOD_POST, JSON.stringify({"path": path, "args": args, "format": "json"}))
	if error != OK:
		request.queue_free()
		last_error = "Connection unavailable. Offline modes are still ready."
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		last_error = "Connection unavailable. Offline modes are still ready."
		return {}
	var parser := JSON.new()
	if parser.parse(response[3].get_string_from_utf8()) != OK or not parser.data is Dictionary:
		last_error = "The server returned an invalid response."
		return {}
	var result: Dictionary = parser.data
	if result.get("status") != "success":
		last_error = "The server could not verify this request."
		return {}
	return {"value": result.get("value")}

func authenticate() -> bool:
	if not token.is_empty() and Time.get_ticks_msec() - authenticated_at < 300000:
		return true
	token = ""
	var args := {"provider": "anonymous"} if refresh_token.is_empty() else {"refreshToken": refresh_token}
	var response := await call_function("action", ("devAuth:signIn" if base_url.begins_with("http://") else "auth:signIn"), args, false)
	if response.is_empty() and not refresh_token.is_empty():
		refresh_token = ""
		response = await call_function("action", ("devAuth:signIn" if base_url.begins_with("http://") else "auth:signIn"), {"provider": "anonymous"}, false)
	var value: Variant = response.get("value")
	if not value is Dictionary or not value.get("tokens") is Dictionary:
		return false
	var tokens: Dictionary = value.tokens
	if not tokens.get("token") is String or not tokens.get("refreshToken") is String:
		return false
	authenticated_at = Time.get_ticks_msec()
	token = tokens.token
	refresh_token = tokens.refreshToken
	var file := FileAccess.open(session_path + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"url": base_url, "refreshToken": refresh_token}))
		file.close()
		DirAccess.rename_absolute(session_path + ".tmp", session_path)
	return true

func begin_run(mode: String, difficulty: String, retry_id: String = "") -> Dictionary:
	if not await authenticate():
		return {}
	var args := {"mode": mode, "difficulty": difficulty}
	if not retry_id.is_empty():
		args.retryRunId = retry_id
	var response := await call_function("mutation", "runs:begin", args)
	var value: Variant = response.get("value")
	if not value is Dictionary or value.get("generatorVersion") != 1 or value.get("balanceVersion") != 1 or not value.get("runId") is String or value.get("difficulty") != difficulty or value.get("mode") != mode:
		return {}
	if not (value.get("seed") is int or value.get("seed") is float) or value.seed < 0 or value.seed >= PathGenerator.MODULUS - 1 or float(value.seed) != floor(float(value.seed)):
		return {}
	if not value.get("route") is Array or not value.get("date") is String:
		return {}
	if mode == "daily":
		if value.route.size() != 5 or value.route[0] != "FR" or value.seed != GameCatalog.daily_seed(value.date, difficulty):
			return {}
		var expected: Array = RoutePlanner.standardized("FR", int(value.seed))
		if value.route != expected:
			return {}
	elif not value.route.is_empty():
		return {}
	return value
