class_name TileGrid
extends Node3D

var tiles: Array[PathTile] = []
var config: DifficultyConfig
var first_row: int = 0

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
			tile.position = position_for(row, lane)
			tiles.append(tile)

func position_for(row: int, lane: int) -> Vector3:
	return Vector3((lane - (config.lane_count - 1) / 2.0) * config.lane_spacing, 0, -(row + 1) * config.row_spacing)

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
