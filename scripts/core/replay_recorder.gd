class_name ReplayRecorder
extends RefCounted

const MAX_EVENTS := 4096
var run_id := ""
var events: Array[Dictionary] = []
var started_at: int = 0
var overflow := false

func begin(id: String) -> void:
	run_id = id
	events.clear()
	started_at = Time.get_ticks_msec()
	overflow = false

func select(country_index: int, row: int, lane: int) -> void:
	if run_id.is_empty() or overflow:
		return
	if events.size() >= MAX_EVENTS:
		overflow = true
		return
	events.append({"countryIndex": country_index, "row": row, "lane": lane, "atMs": Time.get_ticks_msec() - started_at})

func submission() -> Dictionary:
	if run_id.is_empty() or overflow:
		return {}
	return {"runId": run_id, "events": events.duplicate(true), "endedAtMs": Time.get_ticks_msec() - started_at}
