class_name TileGrid
extends Node3D

var tiles: Array[PathTile] = []
var config: DifficultyConfig
var first_row: int = 0
var destination_id := ""
var layout := "classic"
var moving := false
var frozen := true
var motion_clock := 0.0

func build(settings: DifficultyConfig, start_row: int = 0, count: int = -1) -> void:
	first_row = start_row
	config = settings
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tiles.clear()
	for row in range(start_row, start_row + (config.row_count if count < 0 else count)):
		for lane in config.lane_count:
			var tile := PathTile.new()
			add_child(tile)
			tile.build(row, lane, config.tile_size)
			if not destination_id.is_empty(): tile.apply_destination(destination_id)
			tile.position = position_for(row, lane)
			if layout == "bridge":
				var wood := MeshFactory.material(Color("6f5747"))
				MeshFactory.box(tile.decoration, Vector3(0.2, 0.6, config.tile_size.z), Vector3(-0.55, -0.6, 0), wood)
				MeshFactory.box(tile.decoration, Vector3(0.2, 0.6, config.tile_size.z), Vector3(0.55, -0.6, 0), wood)
				if lane == 0 or lane == config.lane_count - 1:
					var side := -1.0 if lane == 0 else 1.0
					MeshFactory.box(tile.decoration, Vector3(0.07, 0.75, 0.07), Vector3(side * 1.1, 0.18, 0), wood)
					MeshFactory.box(tile.decoration, Vector3(0.05, 0.05, config.row_spacing), Vector3(side * 1.1, 0.45, 0), wood)
			tiles.append(tile)

func position_for(row: int, lane: int) -> Vector3:
	var bend := sin((row + 1) * 0.45) * 0.65 if layout in ["curve", "bridge"] else 0.0
	var height := (1.0 - cos((row + 1) * 0.35)) * 0.22 if layout == "climb" else 0.0
	return Vector3((lane - (config.lane_count - 1) / 2.0) * config.lane_spacing + bend, height, -(row + 1) * config.row_spacing)

func _process(delta: float) -> void:
	if not moving or frozen: return
	motion_clock += delta
	for tile in tiles:
		tile.position = position_for(tile.row, tile.lane) + Vector3(sin(motion_clock * 1.2 + tile.row * 0.25) * 0.55, 0, 0)

func tile_at(row: int, lane: int) -> PathTile:
	return tiles[(row - first_row) * config.lane_count + lane]

func reveal(path: Array[int]) -> void:
	for tile in tiles:
		tile.set_state(PathTile.State.REVEALED if path[tile.row] == tile.lane else PathTile.State.NORMAL)

func hide_path() -> void:
	for tile in tiles:
		tile.set_state(PathTile.State.NORMAL)

func reveal_run(run: RunState, from_row: int, high_contrast: bool = false) -> void:
	for tile in tiles:
		tile.green.albedo_color = Color("f7df3b") if high_contrast else Color("97e85f")
		if tile.row >= from_row:
			tile.set_state(PathTile.State.REVEALED if run.safe_lane(tile.row) == tile.lane else PathTile.State.NORMAL)
