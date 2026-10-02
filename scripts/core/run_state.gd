class_name RunState
extends RefCounted

enum Phase { READY, PREVIEW, PLAY, JUMPING, FALLING, COMPLETE, FAILED }
var phase: Phase = Phase.READY
var path: Array[int] = []
var path_seed: int = 1
var completed_rows: int = 0
var selected_lane: int = -1
var endless: bool = false
var lane_count: int = 3

func time_out() -> bool:
	if phase != Phase.PLAY:
		return false
	phase = Phase.FALLING
	return true

func reset(new_seed: int, config: DifficultyConfig, is_endless: bool = false) -> void:
	endless = is_endless
	lane_count = config.lane_count
	path_seed = new_seed
	path = PathGenerator.generate(path_seed, config.lane_count, config.row_count)
	completed_rows = 0
	selected_lane = -1
	phase = Phase.READY

func begin_preview() -> bool:
	if phase != Phase.READY:
		return false
	phase = Phase.PREVIEW
	return true

func finish_preview() -> void:
	if phase == Phase.PREVIEW:
		phase = Phase.PLAY

func select(row: int, lane: int, lane_count: int) -> bool:
	if phase != Phase.PLAY or row != completed_rows or lane < 0 or lane >= lane_count:
		return false
	selected_lane = lane
	phase = Phase.JUMPING
	return true

func land() -> bool:
	if phase != Phase.JUMPING:
		return false
	if selected_lane != safe_lane(completed_rows):
		phase = Phase.FALLING
		return false
	completed_rows += 1
	phase = Phase.COMPLETE if not endless and completed_rows == path.size() else Phase.PLAY
	return true

func safe_lane(row: int) -> int:
	return PathGenerator.lane_at(path_seed, lane_count, row) if endless else path[row]
