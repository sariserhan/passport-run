class_name PerfLog
extends Node

# Appends one CSV line every INTERVAL seconds so device FPS/memory can be pulled
# off the phone with devicectl after a play session. Local only; never uploaded.
const INTERVAL := 5.0
const MAX_BYTES := 512 * 1024

var path: String
var label: Callable
var elapsed := 0.0
var frames := 0
var worst := 0.0

func _init(log_path: String, scene_label: Callable) -> void:
	path = log_path
	label = scene_label
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	# ponytail: one rotated backup is enough to cover a long play session.
	var existing := FileAccess.open(path, FileAccess.READ)
	if existing and existing.get_length() > MAX_BYTES:
		existing = null
		DirAccess.rename_absolute(path, path + ".old")
	if not existing: write("unix_time,scene,fps,worst_frame_ms,static_mb,video_mb,objects,window")

func _process(delta: float) -> void:
	frames += 1
	worst = maxf(worst, delta)
	elapsed += delta
	if elapsed < INTERVAL: return
	var size := get_viewport().get_visible_rect().size
	write("%d,%s,%.1f,%.1f,%.1f,%.1f,%d,%dx%d" % [Time.get_unix_time_from_system(), label.call(), frames / elapsed, worst * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT), size.x, size.y])
	elapsed = 0.0
	frames = 0
	worst = 0.0

func write(line: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if not file: return
	file.seek_end()
	file.store_line(line)
